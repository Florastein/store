/**
 * Store Email OTP Worker
 *
 * A Cloudflare Worker that sends one-time-password (OTP) emails via EmailJS.
 *
 * Compatible with the Cloudflare Workers runtime (ESM). EmailJS credentials and
 * rate-limiting state are provided through Worker bindings – never hardcode
 * credentials in source code.
 *
 * Required bindings (see wrangler.jsonc):
 *   - EMAILJS_SERVICE_ID  : EmailJS service ID (secret)
 *   - EMAILJS_TEMPLATE_ID : EmailJS OTP template ID (secret)
 *   - EMAILJS_PUBLIC_KEY  : EmailJS public key (secret)
 *   - EMAILJS_PRIVATE_KEY : EmailJS private key (secret)
 *   - OTP_EMAIL_FROM      : display name used for the sender (variable)
 *   - OTP_KV              : KV namespace used to persist OTPs + rate limit state
 *
 * Endpoints:
 *   POST /send-otp    -> { email, name?, purpose? }  (sends OTP email)
 *   POST /verify-otp  -> { email, otp, purpose? }    (validates a sent OTP)
 *   OPTIONS           -> CORS preflight
 */

import emailjs from '@emailjs/nodejs';

const DEFAULT_TTL_SECONDS = 300; // 5 minutes
const RESEND_THROTTLE_SECONDS = 60; // prevent OTP spam per email (KV TTL min is 60)
const DEFAULT_OTP_PURPOSE = 'email_confirmation';

const OTP_CONTENT_BY_PURPOSE = Object.freeze({
  email_confirmation: Object.freeze({
    subject: 'Confirm your email address',
    eyebrow: 'EMAIL CONFIRMATION',
    heading: 'Confirm it’s really you',
    intro:
      'Use the verification code below to confirm your email address and finish setting up your Store account.',
    action: 'confirm your email address',
    securityNote:
      'If you did not create a Store account, you can safely ignore this email.',
  }),
  password_reset: Object.freeze({
    subject: 'Reset your Store password',
    eyebrow: 'PASSWORD RESET',
    heading: 'Reset your password',
    intro:
      'Use the verification code below to continue resetting your Store password.',
    action: 'reset your password',
    securityNote:
      'If you did not request a password reset, secure your account and ignore this email.',
  }),
  login: Object.freeze({
    subject: 'Your Store login code',
    eyebrow: 'SECURE LOGIN',
    heading: 'Complete your login',
    intro:
      'Use the verification code below to securely sign in to your Store account.',
    action: 'complete your login',
    securityNote:
      'If you did not try to sign in, do not share this code and review your account security.',
  }),
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

/**
 * A StorageProvider that satisfies EmailJS's expectations on runtimes without
 * `localStorage` (Cloudflare Workers). It persists to KV when available and
 * falls back to an in-memory Map for local development.
 */
function createStorageProvider(env) {
  const kv = env?.OTP_KV;

  // Lazy-initialise a shared in-memory map once per isolate so that it survives
  // multiple calls within the same warm Worker instance.
  if (!globalThis.__emailjsMemoryStore) {
    globalThis.__emailjsMemoryStore = new Map();
  }
  const memoryMap = globalThis.__emailjsMemoryStore;

  const memory = {
    async get(key) {
      return memoryMap.get(key) ?? null;
    },
    async set(key, value) {
      memoryMap.set(key, String(value));
    },
    async remove(key) {
      memoryMap.delete(key);
    },
  };

  if (!kv) {
    return memory;
  }

  return {
    async get(key) {
      return kv.get(key, 'text');
    },
    async set(key, value) {
      await kv.put(key, String(value), {
        expirationTtl: DEFAULT_TTL_SECONDS,
      });
    },
    async remove(key) {
      await kv.delete(key);
    },
  };
}

function json(body, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
      ...extraHeaders,
    },
  });
}

function randomOtp(length = 6) {
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  let otp = '';
  for (const b of bytes) {
    otp += String(b % 10);
  }
  return otp;
}

function isString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function normalizePurpose(value) {
  const purpose = value ?? DEFAULT_OTP_PURPOSE;
  if (!isString(purpose) || !OTP_CONTENT_BY_PURPOSE[purpose]) {
    throw new HttpError(
      400,
      'Field `purpose` must be one of: email_confirmation, password_reset, login.',
    );
  }
  return purpose;
}

function otpKey(email, purpose) {
  return `otp:${purpose}:${email.trim().toLowerCase()}`;
}

async function buildMessage(env, { email, otp, name, purpose }) {
  const serviceId = env.EMAILJS_SERVICE_ID;
  const templateId = env.EMAILJS_TEMPLATE_ID;

  if (!serviceId || !templateId) {
    throw new HttpError(
      500,
      'EmailJS service or template is not configured on the server.',
    );
  }

  const content = OTP_CONTENT_BY_PURPOSE[purpose];
  const recipientName = isString(name) ? name.trim() : email.trim();
  const templateParams = {
    to_email: email.trim(),
    to_name: recipientName,
    email_subject: content.subject,
    email_eyebrow: content.eyebrow,
    email_heading: content.heading,
    email_intro: content.intro,
    email_action: content.action,
    security_note: content.securityNote,
    otp_code: otp,
    otp_purpose: purpose,
    otp_expiry_minutes: String(Math.floor(DEFAULT_TTL_SECONDS / 60)),
    from_name: env.OTP_EMAIL_FROM || 'Store',
  };

  await emailjs.send(serviceId, templateId, templateParams, {
    publicKey: env.EMAILJS_PUBLIC_KEY,
    privateKey: env.EMAILJS_PRIVATE_KEY,
    storageProvider: createStorageProvider(env),
  });
}

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

async function handleSendOtp(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    throw new HttpError(400, 'Request body must be valid JSON.');
  }

  const email = body?.email;
  if (!isString(email)) {
    throw new HttpError(400, 'Field `email` is required.');
  }
  if (!isValidEmail(email)) {
    throw new HttpError(400, 'Field `email` must be a valid email address.');
  }

  const purpose = normalizePurpose(body?.purpose);
  const otp = randomOtp();
  const name = body?.name;
  if (name !== undefined && !isString(name)) {
    throw new HttpError(400, 'Field `name` must be a non-empty string.');
  }

  const kv = env?.OTP_KV;
  if (kv) {
    // Rate limit: one OTP per address within RESEND_THROTTLE_SECONDS.
    const rateKey = `rate:${email.trim().toLowerCase()}`;
    const lastSent = await kv.get(rateKey);
    const now = Date.now();
    if (lastSent && now - Number(lastSent) < RESEND_THROTTLE_SECONDS * 1000) {
      throw new HttpError(429, 'Please wait before requesting another code.');
    }

    // Persist the OTP so a /verify endpoint (or the app) can validate it.
    await kv.put(otpKey(email, purpose), otp, {
      expirationTtl: DEFAULT_TTL_SECONDS,
    });

    await kv.put(rateKey, String(now), {
      expirationTtl: RESEND_THROTTLE_SECONDS,
    });
  }

  await buildMessage(env, { email, otp, name, purpose });

  return json({
    success: true,
    message: 'OTP email sent.',
    purpose,
  });
}

async function handleVerifyOtp(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    throw new HttpError(400, 'Request body must be valid JSON.');
  }

  const email = body?.email;
  const code = body?.otp;
  const purpose = normalizePurpose(body?.purpose);
  if (!isString(email) || !isValidEmail(email)) {
    throw new HttpError(400, 'A valid `email` is required.');
  }
  if (!isString(code)) {
    throw new HttpError(400, 'Field `otp` is required.');
  }
  if (!/^\d{6}$/.test(code.trim())) {
    throw new HttpError(400, 'Field `otp` must be a 6-digit code.');
  }

  const kv = env?.OTP_KV;
  if (!kv) {
    throw new HttpError(
      500,
      'OTP verification requires the OTP_KV binding to be configured.',
    );
  }

  const key = otpKey(email, purpose);
  const stored = await kv.get(key);
  if (stored === null) {
    throw new HttpError(404, 'No active OTP found for this email. Request a new code.');
  }

  const valid = stored.trim() === code.trim();
  if (valid) {
    await kv.delete(key);
  }

  return json({ success: valid, valid, purpose }, valid ? 200 : 401);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const method = request.method;

    if (method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (method === 'POST' && url.pathname === '/send-otp') {
      try {
        return await handleSendOtp(request, env);
      } catch (err) {
        if (err instanceof HttpError) {
          return json({ success: false, message: err.message }, err.status);
        }
        console.error('[send-otp] unexpected error:', err?.name, err?.message, err?.stack?.split('\n').slice(0, 3).join(' '));
        return json(
          { success: false, message: 'Failed to send the OTP email.' },
          500,
        );
      }
    }

    if (method === 'POST' && url.pathname === '/verify-otp') {
      try {
        return await handleVerifyOtp(request, env);
      } catch (err) {
        if (err instanceof HttpError) {
          return json({ success: false, message: err.message }, err.status);
        }
        console.error('OTP verify error:', err);
        return json({ success: false, message: 'Failed to verify the OTP.' }, 500);
      }
    }

    return json(
      {
        success: false,
        message: 'Not found. Available endpoints: POST /send-otp, POST /verify-otp.',
      },
      404,
    );
  },
};
