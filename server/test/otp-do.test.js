// DO state-transition tests using a fake in-memory Durable Object storage.
// Covers begin/commit, abort-preserves-prior, cooldown, reservation mismatch,
// max-5 attempts, and consume-once.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OtpDurableObject } from '../src/otp-do.js';

/** Minimal in-memory stand-in for DurableObjectStorage. */
function fakeStorage() {
  const map = new Map();
  return {
    map,
    async get(key) {
      if (Array.isArray(key)) {
        return new Map(key.map((k) => [k, map.get(k)]));
      }
      return map.get(key);
    },
    async put(key, value) {
      if (typeof key === 'object' && !Array.isArray(key) && key !== null) {
        for (const [k, v] of Object.entries(key)) {
          if (v === null || v === undefined) map.delete(k);
          else map.set(k, v);
        }
      } else {
        map.set(key, value);
      }
    },
    async delete(key) {
      map.delete(key);
    },
  };
}

/** Construct a DO around the fake storage and invoke an RPC action. */
function makeDo() {
  const storage = fakeStorage();
  const state = { storage };
  const do_ = new OtpDurableObject(state);
  async function rpc(action, body = {}) {
    const req = new Request(`https://otp-do/?action=${action}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const res = await do_.fetch(req);
    return { status: res.status, body: await res.json() };
  }
  return { do_, storage, rpc };
}

const OTP_HASH = 'a'.repeat(64);
const OTP_HASH_2 = 'b'.repeat(64);
const PURPOSE = 'login';

test('beginIssue claims reservation for a fresh email', async () => {
  const { rpc, storage } = makeDo();
  const res = await rpc('beginIssue', {
    reservationId: 'r1',
    otpHash: OTP_HASH,
    purpose: PURPOSE,
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  // Reservation id + staged fields are claimed; authoritative keys untouched.
  assert.equal(storage.map.get('reservationId'), 'r1');
  assert.equal(storage.map.get('stagedReservationOtpHash'), OTP_HASH);
  assert.equal(storage.map.get('stagedReservationPurpose'), PURPOSE);
  assert.equal(storage.map.has('otpHash'), false);
  assert.equal(storage.map.has('purpose'), false);
  assert.deepEqual(res.body, { ok: true, retryAfterMs: 0 });
});

test('commitIssue persists staged digest/expiry/attempts/consume-once and clears reservation', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  const res = await rpc('commitIssue', { reservationId: 'r1' });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  assert.equal(storage.map.has('reservationId'), false);
  assert.equal(storage.map.has('stagedReservationOtpHash'), false);
  assert.equal(storage.map.has('stagedReservationPurpose'), false);
  assert.equal(storage.map.get('otpHash'), OTP_HASH);
  assert.equal(storage.map.get('purpose'), PURPOSE);
  assert.equal(storage.map.get('attempts'), 0);
  assert.equal(storage.map.get('consumed'), false);
  assert.ok(storage.map.get('issuedAt') > 0);
  assert.ok(storage.map.get('expiresAt') > storage.map.get('issuedAt'));
  assert.ok(storage.map.get('lastSentAt') > 0);
});

test('commitIssue with wrong reservation id is rejected and clears nothing', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  // Attempt to commit with a DIFFERENT reservation id + different hash/purpose.
  const res = await rpc('commitIssue', {
    reservationId: 'WRONG',
    otpHash: 'c'.repeat(64),
    purpose: 'evil',
  });
  assert.equal(res.status, 409);
  assert.equal(res.body.ok, undefined);
  // Reservation + staged fields intact; nothing authoritative written.
  assert.equal(storage.map.get('reservationId'), 'r1');
  assert.equal(storage.map.get('stagedReservationOtpHash'), OTP_HASH);
  assert.equal(storage.map.has('otpHash'), false);
});

test('commitIssue does not accept caller-substituted otpHash/purpose even with correct id', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  // Pass a matching reservationId but a DIFFERENT hash/purpose in the body.
  const res = await rpc('commitIssue', {
    reservationId: 'r1',
    otpHash: 'c'.repeat(64),
    purpose: 'evil',
  });
  assert.equal(res.status, 200);
  // The staged (authoritative) values from beginIssue win, NOT the caller's.
  assert.equal(storage.map.get('otpHash'), OTP_HASH);
  assert.equal(storage.map.get('purpose'), PURPOSE);
  assert.equal(storage.map.get('stagedReservationOtpHash'), undefined);
  assert.equal(storage.map.has('stagedReservationOtpHash'), false);
});

test('commitIssue without a reservation is rejected (no silent success)', async () => {
  const { rpc } = makeDo();
  const res = await rpc('commitIssue', { reservationId: 'nope' });
  assert.equal(res.status, 409);
  assert.equal(res.body.ok, undefined);
});

test('abortIssue clears only its matching reservation and preserves prior OTP', async () => {
  const { rpc, storage, do_ } = makeDo();
  // First issue commits successfully (authoritative OTP + cooldown).
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  await rpc('commitIssue', { reservationId: 'r1' });
  assert.equal(storage.map.get('otpHash'), OTP_HASH);

  // Explicitly elapse the cooldown so a second begin is NOT blocked (status 200).
  storage.map.set('lastSentAt', Date.now() - 120_000);
  const oldLastSentAt = storage.map.get('lastSentAt'); // value abort must preserve
  const second = await fetchRpc(do_, 'beginIssue', {
    reservationId: 'r2',
    otpHash: OTP_HASH_2,
    purpose: PURPOSE,
  });
  assert.equal(second.status, 200);
  // A NEW staged hash is in place; the authoritative hash is still the old one.
  assert.equal(storage.map.get('stagedReservationOtpHash'), OTP_HASH_2);
  assert.equal(storage.map.get('otpHash'), OTP_HASH);

  // The second attempt's delivery fails -> abort.
  const res = await rpc('abortIssue', { reservationId: 'r2' });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);

  // Prior authoritative OTP + cooldown preserved; staged fields cleared.
  assert.equal(storage.map.has('reservationId'), false);
  assert.equal(storage.map.has('stagedReservationOtpHash'), false);
  assert.equal(storage.map.has('stagedReservationPurpose'), false);
  assert.equal(storage.map.get('otpHash'), OTP_HASH);
  assert.equal(storage.map.get('purpose'), PURPOSE);
  assert.equal(storage.map.get('lastSentAt'), oldLastSentAt);
});

test('abortIssue with mismatched id is ignored but does not disturb state', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  const res = await rpc('abortIssue', { reservationId: 'OTHER' });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.ignored, true);
  assert.equal(storage.map.get('reservationId'), 'r1'); // untouched
});

test('cooldown blocks a second beginIssue until lastSentAt expires', async () => {
  // We can't control Date.now() inside the real DO without mocking the global,
  // so we assert the cooldown path returns retryAfterMs > 0 right after commit.
  const { rpc } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  await rpc('commitIssue', { reservationId: 'r1' });

  const res = await rpc('beginIssue', { reservationId: 'r2', otpHash: OTP_HASH_2, purpose: PURPOSE });
  assert.equal(res.status, 429);
  assert.equal(res.body.ok, false);
  assert.ok(res.body.retryAfterMs > 0);
});

test('a fresh beginIssue after commit success is allowed when cooldown elapsed', async () => {
  const { storage, do_ } = makeDo();
  const now = Date.now();
  await beginCommit(do_, 'r1', OTP_HASH, PURPOSE);
  // Rewrite lastSentAt far in the past so cooldown is over.
  storage.map.set('lastSentAt', now - 120_000);
  const res = await fetchRpc(do_, 'beginIssue', {
    reservationId: 'r2',
    otpHash: OTP_HASH_2,
    purpose: PURPOSE,
  });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
});

test('concurrent in-flight reservation returns 409', async () => {
  const { rpc } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  const res = await rpc('beginIssue', { reservationId: 'r2', otpHash: OTP_HASH_2, purpose: PURPOSE });
  assert.equal(res.status, 409);
  assert.equal(res.body.ok, undefined);
  assert.equal(res.body.inFlight, true);
});

test('verify: correct OTP consumes once', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  await rpc('commitIssue', { reservationId: 'r1' });

  const ok = await rpc('verify', { secret: OTP_HASH });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.ok, true);
  assert.equal(ok.body.purpose, PURPOSE);
  assert.ok(ok.body.expiresAt > 0);

  // Consume-once: second attempt with same correct hash is rejected.
  const again = await rpc('verify', { secret: OTP_HASH });
  assert.equal(again.status, 422);
  assert.equal(again.body.error, 'ALREADY_USED');
  assert.equal(storage.map.get('consumed'), true);
});

test('verify: wrong OTP increments attempts and caps at 5', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  await rpc('commitIssue', { reservationId: 'r1' });

  // 5 wrong attempts: all return INVALID_OTP (attempts goes 1→2→3→4→5).
  // On the 5th call (attempts=4→5), consumed is set to true.
  for (let i = 1; i <= 5; i++) {
    const res = await rpc('verify', { secret: `wrong${i}` });
    assert.equal(res.status, 422);
    assert.equal(res.body.error, 'INVALID_OTP');
  }
  assert.equal(storage.map.get('consumed'), true);

  // Even the correct hash is rejected after the OTP is invalidated.
  const after = await rpc('verify', { secret: OTP_HASH });
  assert.equal(after.body.error, 'ALREADY_USED');
});

test('verify: no active OTP returns uniform failure', async () => {
  const { rpc } = makeDo();
  const res = await rpc('verify', { secret: OTP_HASH });
  assert.equal(res.status, 422);
  assert.equal(res.body.error, 'NO_ACTIVE_OTP');
});

test('verify with missing/empty hash does not consume attempt budget', async () => {
  const { rpc, storage } = makeDo();
  await rpc('beginIssue', { reservationId: 'r1', otpHash: OTP_HASH, purpose: PURPOSE });
  await rpc('commitIssue', { reservationId: 'r1' });
  const res = await rpc('verify', { secret: '' });
  assert.equal(res.body.error, 'MISSING_HASH');
  assert.equal(storage.map.get('attempts'), 0);
});

/* -------- helpers -------- */
async function beginCommit(do_, reservationId, otpHash, purpose) {
  await fetchRpc(do_, 'beginIssue', { reservationId, otpHash, purpose });
  await fetchRpc(do_, 'commitIssue', { reservationId });
}

async function fetchRpc(do_, action, body) {
  const req = new Request(`https://otp-do/?action=${action}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const res = await do_.fetch(req);
  return { status: res.status, body: await res.json() };
}