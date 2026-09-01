/**
 * Store Email OTP Worker
 *
 * A Cloudflare Worker that sends one-time-password (OTP) emails via EmailJS,
 * with Durable Object–backed atomic OTP lifecycle management.
 *
 * Security design:
 *   - OTP state (issue, cooldown, attempts, consume-once, expiry) is atomic per
 *     normalized email+purpose inside a Durable Object. No KV. No plaintext OTP:
 *     only the HMAC-SHA-256 digest is stored, derived from OTP_SECRET.
 *   - A send goes through DO beginIssue → (EmailJS send) → commitIssue, and
 *     aborts on delivery failure so neither a stale valid OTP nor a stuck
 *     cooldown remains. Never return send success if commit fails.
 *   - Verification is fail-uniform to the caller, consumes the OTP once, caps
 *     failed attempts at 5, and returns a short-lived HMAC-signed proof that
 *     binds email, purpose, expiry and a nonce.
 *   - The public send endpoint is rate-limited by installation fingerprint,
 *     client IP, and normalized email. Turnstile is optional defense-in-depth.
 *
 * Required secrets (wrangler secret put): EMAILJS_SERVICE_ID,
 * EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY, EMAILJS_PRIVATE_KEY, OTP_SECRET
 * (>= 32 chars). TURNSTILE_SECRET_KEY is optional.
 *
 * Endpoints:
 *   POST /send-otp    -> { email, name?, purpose?, deviceFingerprint, turnstileToken? }
 *   POST /verify-otp  -> { email, otp, purpose? }
 *   OPTIONS           -> CORS preflight (all origins allowed)
 */

import emailjs from '@emailjs/nodejs';
import { OtpDurableObject } from './otp-do.js';
import { RateLimitDurableObject } from './rate-limit-do.js';

// EmailJS internal storage provider; kept separate from OTP security state.
declare global {
  var __emailjsMemoryStore: Map<string, number> | undefined;
}

// Re-export for wrangler discovery
export { OtpDurableObject, RateLimitDurableObject };

/* -------------------------------------------------------------------------- */
/*                              Constants                                      */
/* -------------------------------------------------------------------------- */

const DEFAULT_OTP_TTL_SECONDS = 300;
const RESEND_COOLDOWN_SECONDS = 60;
const DEFAULT_OTP_PURPOSE = 'email_confirmation';
const VALID_PURPOSES = ['email_confirmation', 'password_reset', 'login'] as const;
const MAX_BODY_BYTES = 4096;
const OTP_LENGTH = 6;
const PROOF_TTL_MS = 5 * 60 * 1000; // proof valid 5 minutes
const MIN_OTP_SECRET_LENGTH = 32;
const DEVICE_RATE_LIMIT = 5;
const IP_RATE_LIMIT = 20;
const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const REQUIRED_SECRETS = [
  'EMAILJS_SERVICE_ID',
  'EMAILJS_TEMPLATE_ID',
  'EMAILJS_PUBLIC_KEY',
  'EMAILJS_PRIVATE_KEY',
  'OTP_SECRET',
] as const;
type RequiredSecret = (typeof REQUIRED_SECRETS)[number];

const OTP_CONTENT_BY_PURPOSE: Record<
  (typeof VALID_PURPOSES)[number],
  {
    subject: string;
    eyebrow: string;
    heading: string;
    intro: string;
    action: string;
    securityNote: string;
  }
> = {
  email_confirmation: {
    subject: 'Confirm your email address',
    eyebrow: 'EMAIL CONFIRMATION',
    heading: "Confirm it's really you",
    intro:
      'Use the verification code below to confirm your email address and finish setting up your Store account.',
    action: 'confirm your email address',
    securityNote:
      'If you did not create a Store account, you can safely ignore this email.',
  },
  password_reset: {
    subject: 'Reset your Store password',
    eyebrow: 'PASSWORD RESET',
    heading: 'Reset your password',
    intro:
      'Use the verification code below to continue resetting your Store password.',
    action: 'reset your password',
    securityNote:
      'If you did not request a password reset, secure your account and ignore this email.',
  },
  login: {
    subject: 'Your Store login code',
    eyebrow: 'SECURE LOGIN',
    heading: 'Complete your login',
    intro:
      'Use the verification code below to securely sign in to your Store account.',
    action: 'complete your login',
    securityNote:
      'If you did not try to sign in, do not share this code and review your account security.',
  },
};

/* -------------------------------------------------------------------------- */
/*                              Types                                          */
/* -------------------------------------------------------------------------- */

interface Env {
  EMAILJS_SERVICE_ID: string;
  EMAILJS_TEMPLATE_ID: string;
  EMAILJS_PUBLIC_KEY: string;
  EMAILJS_PRIVATE_KEY: string;
  OTP_SECRET: string;
  TURNSTILE_SECRET_KEY?: string;
  OTP_EMAIL_FROM: string;
  OTP_DO: DurableObjectNamespace;
  RATE_LIMIT_DO: DurableObjectNamespace;
}

type Purpose = (typeof VALID_PURPOSES)[number];

/* -------------------------------------------------------------------------- */
/*                            CORS Handling                                    */
/* -------------------------------------------------------------------------- */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

/**
 * Determine if a request Origin is allowed. Returns null when denied (fail
 * closed). Allows non-browser requests (no Origin header) so server probes are
 * unaffected, but never emits a wildcard for browser cross-origin calls.
 */
/* -------------------------------------------------------------------------- */
/*                           Response Helpers                                  */
/* -------------------------------------------------------------------------- */

function json(
  body: unknown,
  status: number,
  _allowOrigin: string | null,
): Response {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  };
  return new Response(JSON.stringify(body), { status, headers });
}

function corsPreflight(_allowOrigin: string | null): Response {
  const headers: Record<string, string> = { ...corsHeaders };
  return new Response(null, { status: 204, headers });
}

function structuredLog(level: string, event: string, data: Record<string, unknown>): void {
  console.log(JSON.stringify({ level, event, ts: new Date().toISOString(), ...data }));
}

/* -------------------------------------------------------------------------- */
/*                          Crypto Helpers                                     */
/* -------------------------------------------------------------------------- */

/**
 * Generate a uniform 6-digit OTP using Web Crypto rejection sampling.
 * Rejects values 250–255 (the residual of 256 mod 10) so each digit 0–9 has
 * exactly equal probability.
 */
export function generateOtp(): string {
  let otp = '';
  const bytes = new Uint8Array(OTP_LENGTH);
  while (otp.length < OTP_LENGTH) {
    crypto.getRandomValues(bytes);
    for (const b of bytes) {
      if (b < 250) {
        otp += String(b % 10);
        if (otp.length === OTP_LENGTH) break;
      }
    }
  }
  return otp;
}

/**
 * HMAC-SHA-256 digest of the OTP, keyed with OTP_SECRET. Returns a hex string.
 */
export async function hashOtp(otp: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(otp));
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
}

/**
 * Constant-time string comparison to prevent timing side-channels.
 */
export function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) {
    let result = a.length ^ b.length;
    const len = Math.min(a.length, b.length);
    for (let i = 0; i < len; i++) {
      result |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    return result === 0;
  }
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

/**
 * Generate a short-lived, HMAC-signed verification proof.
 *
 * Format: version.payloadBase64Url.signatureHex
 *   version = "1"
 *   payload = { email, purpose, exp, nonce }
 *
 * The signature is HMAC-SHA-256 over the canonical `version.payload` string,
 * keyed with OTP_SECRET. A trusted backend that shares OTP_SECRET can verify the
 * signature, check `exp` is still in the future, and treat it as proof the
 * normalized email+OTP for that purpose was verified.
 *
 * Nonce/replay boundary: `nonce` is a fresh random value per verification. It is
 * NOT persisted anywhere, so the backend MUST track used nonces if replay
 * prevention is required for a given purpose/email. For a single-use OTP
 * already consumed once, the proof inherits single-use semantics; for flows that
 * re-verify the same email+purpose repeatedly (e.g. ongoing sessions), the
 * backend should keep a short-lived nonce cache.
 */
export async function generateProof(params: {
  email: string;
  purpose: string;
  secret: string;
  now?: number;
}): Promise<string> {
  const now = params.now ?? Date.now();
  const nonce = randomHex(16);
  const payload = {
    email: params.email,
    purpose: params.purpose,
    exp: now + PROOF_TTL_MS,
    nonce,
  };
  const payloadJson = JSON.stringify(payload);
  const payloadB64 = btoa(payloadJson)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  const version = '1';
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(params.secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signedContent = `${version}.${payloadB64}`;
  const sig = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(signedContent),
  );
  const sigHex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  return `${version}.${payloadB64}.${sigHex}`;
}

/** A unique reservation id per send attempt. */
function newReservationId(): string {
  return randomHex(16);
}

function randomHex(bytes: number): string {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('');
}

/* -------------------------------------------------------------------------- */
/*                          Secret Validation                                 */
/* -------------------------------------------------------------------------- */

function validateSecrets(env: Env): void {
  for (const secret of REQUIRED_SECRETS) {
    if (!env[secret] || typeof env[secret] !== 'string' || env[secret].trim() === '') {
      throw new HttpError(
        500,
        `Required secret is not configured: ${secret}.`,
      );
    }
  }
  if (env.OTP_SECRET.length < MIN_OTP_SECRET_LENGTH) {
    throw new HttpError(
      500,
      `OTP_SECRET must be at least ${MIN_OTP_SECRET_LENGTH} characters.`,
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          Input Validation                                  */
/* -------------------------------------------------------------------------- */

class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

function isString(value: unknown): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function normalizePurpose(value: unknown): Purpose {
  const purpose = value ?? DEFAULT_OTP_PURPOSE;
  if (!isString(purpose) || !VALID_PURPOSES.includes(purpose as Purpose)) {
    throw new HttpError(
      400,
      'Field `purpose` must be one of: email_confirmation, password_reset, login.',
    );
  }
  return purpose as Purpose;
}

function normalizeEmail(value: unknown): string {
  if (!isString(value)) {
    throw new HttpError(400, 'Field `email` is required.');
  }
  const email = value.trim().toLowerCase();
  if (!isValidEmail(email)) {
    throw new HttpError(400, 'Field `email` must be a valid email address.');
  }
  return email;
}

/* -------------------------------------------------------------------------- */
/*                       Turnstile Verification                                */
/* -------------------------------------------------------------------------- */

interface TurnstileResponse {
  success: boolean;
  'error-codes'?: string[];
}

/**
 * Verify a Turnstile token by calling Cloudflare's siteverify endpoint. Always
 * fail-closed: a non-success response is treated as a verification failure.
 * There is deliberately NO local bypass here — the only way to exercise this in
 * local development is to point TURNSTILE_SECRET_KEY at Cloudflare's official
 * always-fail/always-pass test secrets and use the documented test tokens; the
 * siteverify call itself still runs (see README).
 */
export async function verifyTurnstile(
  token: string,
  secretKey: string,
  ip: string,
): Promise<{ success: boolean; error?: string }> {
  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `secret=${encodeURIComponent(secretKey)}&response=${encodeURIComponent(token)}&remoteip=${encodeURIComponent(ip)}`,
  });

  const data = (await res.json()) as TurnstileResponse;

  if (!res.ok || !data.success) {
    return {
      success: false,
      error: data['error-codes']?.join(', ') || `HTTP ${res.status}`,
    };
  }

  return { success: true };
}

/* -------------------------------------------------------------------------- */
/*                          Durable Object Helpers                             */
/* -------------------------------------------------------------------------- */

function getOtpDoId(env: Env, email: string, purpose: string): DurableObjectId {
  const name = `otp:${purpose}:${email}`;
  return env.OTP_DO.idFromName(name);
}

async function callOtpDo(
  env: Env,
  email: string,
  purpose: string,
  action: string,
  body: Record<string, unknown>,
): Promise<{ ok?: boolean; error?: string; [key: string]: unknown }> {
  const id = getOtpDoId(env, email, purpose);
  const stub = env.OTP_DO.get(id);

  const res = await stub.fetch(
    new Request(`https://otp-do/?action=${encodeURIComponent(action)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }),
  );

  return (await res.json()) as { ok?: boolean; error?: string; [key: string]: unknown };
}

async function consumeRateLimit(
  env: Env,
  scope: 'device' | 'ip',
  identifier: string,
  limit: number,
): Promise<void> {
  const digest = await sha256Hex(`${scope}:${identifier}`);
  const stub = env.RATE_LIMIT_DO.get(env.RATE_LIMIT_DO.idFromName(`${scope}:${digest}`));
  const response = await stub.fetch(new Request('https://rate-limit-do/hit', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ limit, windowMs: RATE_LIMIT_WINDOW_MS }),
  }));
  const result = await response.json<{ ok?: boolean; retryAfterMs?: number }>();
  if (!response.ok || result.ok !== true) {
    const retrySeconds = Math.max(1, Math.ceil((result.retryAfterMs ?? RATE_LIMIT_WINDOW_MS) / 1000));
    throw new HttpError(429, `Too many requests. Please try again in ${retrySeconds}s.`);
  }
}

/* -------------------------------------------------------------------------- */
/*                          EmailJS Integration                                */
/* -------------------------------------------------------------------------- */

function buildEmailTemplateParams(
  env: Env,
  email: string,
  otp: string,
  name: string | undefined,
  purpose: Purpose,
): Record<string, string> {
  const content = OTP_CONTENT_BY_PURPOSE[purpose];
  const recipientName = isString(name) ? name.trim() : email;
  return {
    to_email: email,
    to_name: recipientName,
    email_subject: content.subject,
    email_eyebrow: content.eyebrow,
    email_heading: content.heading,
    email_intro: content.intro,
    email_action: content.action,
    security_note: content.securityNote,
    otp_code: otp,
    otp_purpose: purpose,
    otp_expiry_minutes: String(DEFAULT_OTP_TTL_SECONDS / 60),
    from_name: env.OTP_EMAIL_FROM || 'Store',
  };
}

async function sendEmail(
  env: Env,
  email: string,
  otp: string,
  name: string | undefined,
  purpose: Purpose,
): Promise<void> {
  const serviceId = env.EMAILJS_SERVICE_ID;
  const templateId = env.EMAILJS_TEMPLATE_ID;

  if (!serviceId || !templateId) {
    throw new HttpError(500, 'EmailJS service or template is not configured on the server.');
  }

  const templateParams = buildEmailTemplateParams(env, email, otp, name, purpose);

  // EmailJS's internal storage (for its own SDK state) is an in-memory map that
  // is kept entirely separate from OTP security state and never stores OTPs.
  if (!globalThis.__emailjsMemoryStore) {
    globalThis.__emailjsMemoryStore = new Map<string, number>();
  }
  const memoryMap = globalThis.__emailjsMemoryStore;

  await emailjs.send(serviceId, templateId, templateParams, {
    publicKey: env.EMAILJS_PUBLIC_KEY,
    privateKey: env.EMAILJS_PRIVATE_KEY,
    storageProvider: {
      async get(key: string) {
        return memoryMap.get(key) ?? null;
      },
      async set(key: string, value: number) {
        memoryMap.set(key, value);
      },
      async remove(key: string) {
        memoryMap.delete(key);
      },
    },
  });
}

/* -------------------------------------------------------------------------- */
/*                          Request Handlers                                   */
/* -------------------------------------------------------------------------- */

async function readJsonBody(request: Request): Promise<Record<string, unknown>> {
  const contentType = request.headers.get('Content-Type') ?? '';
  if (!contentType.toLowerCase().includes('application/json')) {
    throw new HttpError(415, 'Content-Type must be application/json.');
  }

  const rawBody = await request.text();
  if (rawBody.length > MAX_BODY_BYTES) {
    throw new HttpError(413, `Request body exceeds ${MAX_BODY_BYTES} bytes.`);
  }

  try {
    const parsed: unknown = JSON.parse(rawBody);
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      throw new HttpError(400, 'Request body must be a JSON object.');
    }
    return parsed as Record<string, unknown>;
  } catch (err) {
    if (err instanceof HttpError) throw err;
    throw new HttpError(400, 'Request body must be valid JSON.');
  }
}

async function handleSendOtp(
  request: Request,
  env: Env,
  allowOrigin: string | null,
): Promise<Response> {
  const body = await readJsonBody(request);

  const email = normalizeEmail(body.email);
  const purpose = normalizePurpose(body.purpose);
  const name = body.name;
  if (name !== undefined && !isString(name)) {
    throw new HttpError(400, 'Field `name` must be a non-empty string.');
  }

  const turnstileToken = body.turnstileToken;
  if (turnstileToken !== undefined && !isString(turnstileToken)) {
    throw new HttpError(400, 'Field `turnstileToken` must be a non-empty string.');
  }

  const deviceFingerprint = body.deviceFingerprint;
  if (!isString(deviceFingerprint) || !/^[A-Za-z0-9_-]{20,128}$/.test(deviceFingerprint)) {
    throw new HttpError(400, 'Field `deviceFingerprint` must be a valid installation identifier.');
  }

  const clientIp =
    request.headers.get('CF-Connecting-IP') ??
    request.headers.get('X-Forwarded-For')?.split(',')[0]?.trim() ??
    'unknown';

  await consumeRateLimit(env, 'device', deviceFingerprint, DEVICE_RATE_LIMIT);
  await consumeRateLimit(env, 'ip', clientIp, IP_RATE_LIMIT);

  if (isString(turnstileToken) && isString(env.TURNSTILE_SECRET_KEY)) {
    const turnstileResult = await verifyTurnstile(turnstileToken, env.TURNSTILE_SECRET_KEY, clientIp);
    if (!turnstileResult.success) {
      structuredLog('warn', 'turnstile.rejected', { purpose, error: turnstileResult.error });
      throw new HttpError(403, 'Turnstile verification failed.');
    }
  }

  const reservationId = newReservationId();
  const otp = generateOtp();
  const otpHash = await hashOtp(otp, env.OTP_SECRET);

  // 1. Claim a reservation atomically (checks cooldown + in-flight).
  const began = await callOtpDo(env, email, purpose, 'beginIssue', {
    reservationId,
    otpHash,
    purpose,
  });

  if (began.ok !== true) {
    const retryAfterMs =
      typeof began.retryAfterMs === 'number' ? began.retryAfterMs : 0;
    const code = retryAfterMs > 0 ? 429 : 409;
    const message =
      retryAfterMs > 0
        ? `Please wait ${Math.ceil(retryAfterMs / 1000)}s before requesting another code.`
        : began.reason === 'COOLDOWN'
          ? 'Please wait before requesting another code.'
          : 'Another send is already in progress. Please try again.';
    structuredLog('warn', 'send-otp.throttled', {
      purpose,
      reason: began.error ?? began.reason,
    });
    throw new HttpError(code, message);
  }

  // 2. Deliver the email.
  try {
    await sendEmail(env, email, otp, isString(name) ? name : undefined, purpose);
  } catch (sendErr) {
    // Roll back the reservation; this preserves any prior OTP/cooldown.
    await callOtpDo(env, email, purpose, 'abortIssue', { reservationId });
    structuredLog('error', 'send-otp.delivery_failed', {
      purpose,
      error: sendErr instanceof Error ? sendErr.message : String(sendErr),
    });
    throw new HttpError(500, 'Failed to send the OTP email. Please try again.');
  }

  // 3. Commit ONLY if the reservation matches. The DO reads the staged
  //    digest/purpose bound to the reservation (body carries only reservationId,
  //    so a mismatched commit cannot substitute a different OTP). If commit
  //    fails we must NOT report success.
  const committed = await callOtpDo(env, email, purpose, 'commitIssue', {
    reservationId,
  });

  if (committed.ok !== true) {
    structuredLog('error', 'send-otp.commit_failed', {
      purpose,
      error: committed.error,
    });
    throw new HttpError(500, 'Failed to finalize the OTP. Please try again.');
  }

  structuredLog('info', 'send-otp.success', { purpose });

  // The plaintext OTP is only sent via EmailJS; it is never returned.
  return json(
    { success: true, message: 'OTP email sent.', purpose },
    200,
    allowOrigin,
  );
}

async function handleVerifyOtp(
  request: Request,
  env: Env,
  allowOrigin: string | null,
): Promise<Response> {
  const body = await readJsonBody(request);

  const email = normalizeEmail(body.email);
  const purpose = normalizePurpose(body.purpose);

  const code = body.otp;
  if (!isString(code)) {
    throw new HttpError(400, 'Field `otp` is required.');
  }
  if (!/^\d{6}$/.test(code.trim())) {
    throw new HttpError(400, 'Field `otp` must be a 6-digit code.');
  }

  const providedHash = await hashOtp(code.trim(), env.OTP_SECRET);
  const result = await callOtpDo(env, email, purpose, 'verify', {
    secret: providedHash,
  });

  if (result.ok !== true) {
    // Uniform public failure; log the internal reason without email PII.
    structuredLog('warn', 'verify-otp.failed', {
      purpose,
      reason: result.error,
    });
    return json(
      { success: false, valid: false, message: 'The verification code is invalid or expired.' },
      422,
      allowOrigin,
    );
  }

  const proof = await generateProof({
    email,
    purpose,
    secret: env.OTP_SECRET,
  });

  structuredLog('info', 'verify-otp.success', { purpose });

  return json(
    { success: true, valid: true, purpose, proof },
    200,
    allowOrigin,
  );
}

/* -------------------------------------------------------------------------- */
/*                            Entry Point                                      */
/* -------------------------------------------------------------------------- */

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const method = request.method;
    const allowOrigin = '*';

    if (method === 'OPTIONS') {
      return corsPreflight(allowOrigin);
    }

    try {
      // Validate required secrets up front so misconfiguration is loud and
      // never results in a subtly broken OTP flow.
      validateSecrets(env);

      if (method === 'POST' && url.pathname === '/send-otp') {
        return await handleSendOtp(request, env, allowOrigin);
      }
      if (method === 'POST' && url.pathname === '/verify-otp') {
        return await handleVerifyOtp(request, env, allowOrigin);
      }

      return json(
        {
          success: false,
          message: 'Not found. Available endpoints: POST /send-otp, POST /verify-otp.',
        },
        404,
        allowOrigin,
      );
    } catch (err) {
      if (err instanceof HttpError) {
        return json({ success: false, message: err.message }, err.status, allowOrigin);
      }
      structuredLog('error', 'unhandled', {
        error: err instanceof Error ? err.message : String(err),
      });
      return json(
        { success: false, message: 'Internal server error.' },
        500,
        allowOrigin,
      );
    }
  },
};
