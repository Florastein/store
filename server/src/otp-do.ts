/**
 * OTP Durable Object
 *
 * Strongly-consistent, atomic per-email+purpose OTP state.
 *
 * All OTP lifecycle operations are serialized through this single object via a
 * unique reservation id. Critically, beginIssue NEVER touches the authoritative
 * otpHash/purpose/lastSentAt keys — it stores them in separate "staged"
 * reservation fields so that abortIssue or stale cleanup can discard the
 * in-flight attempt without destroying a previously committed OTP or cooldown.
 *
 * Lifecycle:
 *
 *   beginIssue(reservationId, otpHash, purpose)
 *     - Atomically checks the resend cooldown AND whether another send is
 *       already in-flight. If clear, stores the reservation id plus STAGED
 *       copies of otpHash/purpose (stagedReservationOtpHash / purpose). The
 *       authoritative otpHash/purpose are untouched.
 *     - Returns 429 (cooldown), 409 (in-flight), or success.
 *
 *   commitIssue(reservationId)
 *     - Reads the staged values bound to the matching reservation and writes
 *       them into the authoritative otpHash/purpose keys, along with expiry,
 *       zeroed attempts, consumed=false, lastSentAt.
 *     - Clears reservation + staged fields. Body contains ONLY reservationId;
 *       the caller cannot substitute a different digest/purpose.
 *
 *   abortIssue(reservationId)
 *     - Clears ONLY the matching reservation id + staged fields. Authoritative
 *       otpHash, purpose, and lastSentAt are left untouched.
 *
 *   verify(providedHash)
 *     - Increments attempts, enforces max-5, consume-once and expiry, and on
 *       success marks consumed. (Proof signing happens in the caller.)
 *
 * Timestamps are NEVER accepted from the caller; the DO uses Date.now().
 *
 * Storage keys (authoritative — only written by commitIssue):
 *   otpHash             – HMAC-SHA-256 hex digest of the OTP
 *   purpose             – purpose string
 *   issuedAt            – epoch-ms when the OTP was issued
 *   expiresAt           – epoch-ms when the OTP expires
 *   attempts            – number of failed verification attempts (int)
 *   consumed            – boolean, true once verified successfully or invalidated
 *   lastSentAt          – epoch-ms of the last successful send (cooldown base)
 *
 * Storage keys (reservation — written by beginIssue, cleared by commit/abort):
 *   reservationId              – current in-flight reservation id or null
 *   reservationExpiresAt       – epoch-ms when the reservation self-expires
 *   stagedReservationOtpHash   – staged digest awaiting commit
 *   stagedReservationPurpose   – staged purpose awaiting commit
 */

import type { DurableObjectState } from '@cloudflare/workers-types';

export interface OtpState {
  otpHash: string | null;
  purpose: string | null;
  issuedAt: number;
  expiresAt: number;
  attempts: number;
  consumed: boolean;
  lastSentAt: number;
  reservationId: string | null;
  reservationExpiresAt: number;
  stagedReservationOtpHash: string | null;
  stagedReservationPurpose: string | null;
}

export interface BeginResult {
  ok: true;
  retryAfterMs: 0;
}

export interface VerifyResult {
  ok: true;
  purpose: string;
  issuedAt: number;
  expiresAt: number;
}

export interface CooldownInfo {
  ok: boolean;
  retryAfterMs: number;
  reason?: string;
  inFlight?: boolean;
}

const DEFAULT_OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes
const RESEND_COOLDOWN_MS = 60 * 1000; // 60 seconds
const MAX_ATTEMPTS = 5;
const RESERVATION_TTL_MS = 30 * 1000; // reservation self-expires after 30s

export class OtpDurableObject {
  private state: DurableObjectState;
  private storage: DurableObjectState['storage'];

  constructor(state: DurableObjectState) {
    this.state = state;
    this.storage = state.storage;
  }

  /** Fetch handler – all DO logic goes through RPC-style fetch calls. */
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const action = url.searchParams.get('action');

    if (request.method !== 'POST') {
      return this.json({ error: 'Method not allowed' }, 405);
    }

    try {
      const body = await request.json<{
        reservationId?: string;
        otpHash?: string;
        purpose?: string;
        secret?: string;
      }>();

      switch (action) {
        case 'beginIssue':
          return this.handleBeginIssue(body);
        case 'commitIssue':
          return this.handleCommitIssue(body);
        case 'abortIssue':
          return this.handleAbortIssue(body);
        case 'verify':
          return this.handleVerify(body);
        case 'getState':
          return this.handleGetState();
        default:
          return this.json({ error: 'Unknown action' }, 400);
      }
    } catch (err) {
      return this.json(
        { error: err instanceof Error ? err.message : 'Internal error' },
        500,
      );
    }
  }

  /**
   * Atomically check cooldown + in-flight reservation, and if clear, claim a
   * reservation slot with the provided (caller-unique) reservation id.
   *
   * The caller-supplied otpHash/purpose are stored under STAGED keys
   * (stagedReservationOtpHash / stagedReservationPurpose) — the authoritative
   * otpHash/purpose/lastSentAt keys are NEVER touched here. This ensures that
   * a failed delivery + abort cannot destroy a previously committed OTP.
   */
  private async handleBeginIssue(body: {
    reservationId?: string;
    otpHash?: string;
    purpose?: string;
  }): Promise<Response> {
    const reservationId = body.reservationId;
    const otpHash = body.otpHash;
    const purpose = body.purpose;

    if (!reservationId || typeof reservationId !== 'string') {
      return this.json({ error: 'reservationId required' }, 400);
    }
    if (!otpHash || typeof otpHash !== 'string') {
      return this.json({ error: 'otpHash required' }, 400);
    }
    if (!purpose || typeof purpose !== 'string') {
      return this.json({ error: 'purpose required' }, 400);
    }

    const now = Date.now();

    // Expire any stale reservation so we don't block forever on a crashed send.
    const [reservationIdCurrent, reservationExpiresAt] = await Promise.all([
      this.storage.get<string>('reservationId'),
      this.storage.get<number>('reservationExpiresAt'),
    ]);
    if (
      reservationIdCurrent &&
      reservationExpiresAt !== undefined &&
      now > reservationExpiresAt
    ) {
      await this.storage.put({
        reservationId: null,
        reservationExpiresAt: null,
        stagedReservationOtpHash: null,
        stagedReservationPurpose: null,
      });
    }

    // Re-check after expiring stale reservation; refresh values.
    const [currentReservation, hasLastSent] = await Promise.all([
      this.storage.get<string>('reservationId'),
      this.storage.get<number>('lastSentAt'),
    ]);
    if (currentReservation) {
      return this.json(
        { error: 'Another send is already in progress.', inFlight: true },
        409,
      );
    }

    // Enforce resend cooldown based on the last successful send.
    const lastSentAt = hasLastSent ?? 0;
    const remaining = RESEND_COOLDOWN_MS - (now - lastSentAt);
    if (remaining > 0) {
      return this.json(
        { ok: false, retryAfterMs: remaining, reason: 'COOLDOWN' } satisfies CooldownInfo,
        429,
      );
    }

    // Claim the reservation slot with staged copies of the digest/purpose.
    // Authoritative keys are left untouched until commitIssue.
    await this.storage.put({
      reservationId,
      reservationExpiresAt: now + RESERVATION_TTL_MS,
      stagedReservationOtpHash: otpHash,
      stagedReservationPurpose: purpose,
    });

    return this.json({ ok: true, retryAfterMs: 0 } satisfies BeginResult);
  }

  /**
   * Persist the issued OTP ONLY if the reservation id matches. Reads the
   * staged digest/purpose from storage (never from the caller body) so a
   * mismatched commit cannot substitute a different hash or purpose.
   *
   * Clears reservation + staged fields. Authoritative lastSentAt is set to now.
   */
  private async handleCommitIssue(body: {
    reservationId?: string;
  }): Promise<Response> {
    const reservationId = body.reservationId;

    if (!reservationId || typeof reservationId !== 'string') {
      return this.json({ error: 'reservationId required' }, 400);
    }

    const [currentReservation, stagedHash, stagedPurpose] = await Promise.all([
      this.storage.get<string>('reservationId'),
      this.storage.get<string>('stagedReservationOtpHash'),
      this.storage.get<string>('stagedReservationPurpose'),
    ]);

    if (currentReservation !== reservationId) {
      return this.json(
        { error: 'Reservation mismatch; request aborted or superseded.' },
        409,
      );
    }

    if (!stagedHash || typeof stagedHash !== 'string') {
      return this.json({ error: 'Staged OTP hash missing; reservation corrupt.' }, 500);
    }
    if (!stagedPurpose || typeof stagedPurpose !== 'string') {
      return this.json({ error: 'Staged purpose missing; reservation corrupt.' }, 500);
    }

    const now = Date.now();

    // Write authoritative values from the staged reservation, clear reservation.
    await this.storage.put({
      reservationId: null,
      reservationExpiresAt: null,
      stagedReservationOtpHash: null,
      stagedReservationPurpose: null,
      otpHash: stagedHash,
      purpose: stagedPurpose,
      issuedAt: now,
      expiresAt: now + DEFAULT_OTP_TTL_MS,
      attempts: 0,
      consumed: false,
      lastSentAt: now,
    });

    return this.json({ ok: true });
  }

  /**
   * Clear ONLY the matching reservation id + staged fields. Authoritative
   * otpHash, purpose, and lastSentAt are left untouched, so a failed delivery
   * rollback neither destroys a valid OTP nor blocks the user.
   */
  private async handleAbortIssue(body: {
    reservationId?: string;
  }): Promise<Response> {
    const reservationId = body.reservationId;
    if (!reservationId || typeof reservationId !== 'string') {
      return this.json({ error: 'reservationId required' }, 400);
    }

    const currentReservation = await this.storage.get<string>('reservationId');
    if (currentReservation !== reservationId) {
      // Already aborted/committed/superseded – treat as a no-op success so the
      // caller can safely roll back.
      return this.json({ ok: true, ignored: true });
    }

    await this.storage.put({
      reservationId: null,
      reservationExpiresAt: null,
      stagedReservationOtpHash: null,
      stagedReservationPurpose: null,
    });

    return this.json({ ok: true });
  }

  /**
   * Verify an OTP attempt. Returns the internal state on success; the caller
   * mints the signed proof. On failure returns a stable internal reason string.
   */
  private async handleVerify(body: {
    secret?: string;
  }): Promise<Response> {
    const { otpHash, purpose, expiresAt, attempts, consumed } =
      await this.readOtpState();

    if (!otpHash) {
      return this.json({ ok: false, error: 'NO_ACTIVE_OTP' }, 422);
    }

    if (consumed) {
      return this.json({ ok: false, error: 'ALREADY_USED' }, 422);
    }

    const now = Date.now();
    if (now > expiresAt) {
      // Invalidate so further attempts are uniformly rejected until re-issue.
      await this.storage.put({ consumed: true });
      return this.json({ ok: false, error: 'EXPIRED' }, 422);
    }

    if (attempts >= MAX_ATTEMPTS) {
      await this.storage.put({ consumed: true, attempts: attempts + 1 });
      return this.json({ ok: false, error: 'MAX_ATTEMPTS' }, 422);
    }

    const providedHash = body.secret;
    if (!providedHash || typeof providedHash !== 'string') {
      // Do not count an empty/garbage attempt to avoid DoS on attempt budget.
      return this.json({ ok: false, error: 'MISSING_HASH' }, 422);
    }

    const newAttempts = attempts + 1;
    await this.storage.put('attempts', newAttempts);

    if (!constantTimeEquals(otpHash, providedHash)) {
      if (newAttempts >= MAX_ATTEMPTS) {
        await this.storage.put({ consumed: true });
      }
      return this.json({ ok: false, error: 'INVALID_OTP' }, 422);
    }

    // Success: mark consumed (consume-once) and report needed fields.
    await this.storage.put({ consumed: true, attempts: newAttempts });

    return this.json({
      ok: true,
      purpose: purpose ?? '',
      issuedAt: (await this.storage.get<number>('issuedAt')) ?? 0,
      expiresAt,
    } satisfies VerifyResult);
  }

  /** Return non-secret diagnostic state. */
  private async handleGetState(): Promise<Response> {
    const { expiresAt, attempts, consumed, issueActive, inFlight } =
      await this.summary();
    return this.json({
      issueActive,
      inFlight,
      attempts,
      consumed,
      expired: expiresAt > 0 && Date.now() > expiresAt,
    });
  }

  private async summary(): Promise<{
    issueActive: boolean;
    inFlight: boolean;
    attempts: number;
    consumed: boolean;
    expiresAt: number;
  }> {
    const { expiresAt, attempts, consumed, reservationId } =
      await this.readOtpState();
    const issueActive = !consumed && expiresAt > 0 && Date.now() < expiresAt;
    return {
      issueActive,
      inFlight: reservationId !== null,
      attempts,
      consumed,
      expiresAt,
    };
  }

  private async readOtpState(): Promise<OtpState> {
    const [
      otpHash,
      purpose,
      issuedAt,
      expiresAt,
      attempts,
      consumed,
      lastSentAt,
      reservationId,
      reservationExpiresAt,
      stagedReservationOtpHash,
      stagedReservationPurpose,
    ] = await Promise.all([
      this.storage.get<string>('otpHash'),
      this.storage.get<string>('purpose'),
      this.storage.get<number>('issuedAt'),
      this.storage.get<number>('expiresAt'),
      this.storage.get<number>('attempts'),
      this.storage.get<boolean>('consumed'),
      this.storage.get<number>('lastSentAt'),
      this.storage.get<string>('reservationId'),
      this.storage.get<number>('reservationExpiresAt'),
      this.storage.get<string>('stagedReservationOtpHash'),
      this.storage.get<string>('stagedReservationPurpose'),
    ]);

    return {
      otpHash: otpHash ?? null,
      purpose: purpose ?? null,
      issuedAt: issuedAt ?? 0,
      expiresAt: expiresAt ?? 0,
      attempts: attempts ?? 0,
      consumed: consumed ?? false,
      lastSentAt: lastSentAt ?? 0,
      reservationId: reservationId ?? null,
      reservationExpiresAt: reservationExpiresAt ?? 0,
      stagedReservationOtpHash: stagedReservationOtpHash ?? null,
      stagedReservationPurpose: stagedReservationPurpose ?? null,
    };
  }

  private json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

/**
 * Constant-time string comparison to prevent timing attacks on the OTP digest.
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
