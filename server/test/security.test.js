// Tests for the pure validation/security-sensitive logic.
// Plain JS because the installed Node build cannot run .ts directly, nor does it
// ship @types/node. We compile src/*.ts to .test-dist/src/*.js (see the "test"
// npm script) and run node:test against the compiled output.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateOtp, constantTimeEquals, hashOtp, generateProof } from '../src/index.js';
import { constantTimeEquals as docte } from '../src/otp-do.js';

test('generateOtp returns 6-digit numeric strings', () => {
  for (let i = 0; i < 1000; i++) {
    const otp = generateOtp();
    assert.match(otp, /^\d{6}$/);
  }
});

test('generateOtp is reasonably uniform across digits (rejection sampling)', () => {
  const counts = new Map();
  for (let i = 0; i < 2000; i++) {
    const otp = generateOtp();
    for (const ch of otp) {
      counts.set(ch, (counts.get(ch) ?? 0) + 1);
    }
  }
  const total = [...counts.values()].reduce((a, b) => a + b, 0);
  assert.equal(total, 2000 * 6);
  const expected = total / 10;
  for (const ch of '0123456789') {
    const count = counts.get(ch) ?? 0;
    assert.ok(Math.abs(count - expected) < expected * 0.25, `digit ${ch} count ${count}`);
  }
});

test('generateOtp output differs across calls (high entropy)', () => {
  const set = new Set();
  for (let i = 0; i < 100; i++) set.add(generateOtp());
  assert.ok(set.size > 95);
});

test('constantTimeEquals matches exact strings and rejects mismatches', () => {
  assert.equal(constantTimeEquals('abc', 'abc'), true);
  assert.equal(constantTimeEquals('abc', 'abd'), false);
  assert.equal(constantTimeEquals('abc', 'abcd'), false);
  assert.equal(constantTimeEquals('', ''), true);
  assert.equal(constantTimeEquals('', 'a'), false);
});

test('constantTimeEquals is deterministic for equal hex digests', () => {
  const a = 'a1b2c3';
  const b = 'a1b2c3';
  const c = 'a1b2c4';
  assert.equal(constantTimeEquals(a, b), true);
  assert.equal(constantTimeEquals(a, c), false);
});

test('DO constantTimeEquals behaves the same', () => {
  assert.equal(docte('xyz', 'xyz'), true);
  assert.equal(docte('xyz', 'xyw'), false);
  assert.equal(docte('x', 'xyz'), false);
});

test('hashOtp is deterministic, SHA-256, and distinct across OTPs', async () => {
  const secret = 'an-otp-secret-that-is-at-least-32-chars-long';
  const h1 = await hashOtp('123456', secret);
  const h2 = await hashOtp('123456', secret);
  const h3 = await hashOtp('654321', secret);
  assert.equal(h1, h2);
  assert.notEqual(h1, h3);
  assert.match(h1, /^[0-9a-f]{64}$/);
});

test('hashes cannot be inverted to recover the OTP', async () => {
  const secret = 'an-otp-secret-that-is-at-least-32-chars-long';
  const otp = '000000';
  const h = await hashOtp(otp, secret);
  assert.notEqual(h, otp);
  assert.equal(h.includes(otp), false);
});

test('generateProof returns a signed token binding email, purpose, exp, and nonce', async () => {
  const secret = 'an-otp-secret-that-is-at-least-32-chars-long';
  const proof = await generateProof({
    email: 'user@example.com',
    purpose: 'login',
    secret,
    now: 1_700_000_000_000,
  });

  const [version, payloadB64, sig] = proof.split('.');
  assert.equal(version, '1');
  assert.ok(payloadB64.length > 0);
  assert.match(sig, /^[0-9a-f]{64}$/);

  const payload = JSON.parse(Buffer.from(payloadB64, 'base64url').toString('utf8'));
  assert.equal(payload.email, 'user@example.com');
  assert.equal(payload.purpose, 'login');
  assert.equal(payload.exp, 1_700_000_000_000 + 5 * 60 * 1000);
  assert.match(payload.nonce, /^[0-9a-f]{32}$/);
  assert.ok(payload.iat === undefined || payload.iat === undefined); // no iat field; exp fixed
});

test('generateProof nonces differ across calls', async () => {
  const secret = 'an-otp-secret-that-is-at-least-32-chars-long';
  const p1 = await generateProof({ email: 'a@example.com', purpose: 'login', secret });
  const p2 = await generateProof({ email: 'a@example.com', purpose: 'login', secret });
  const decode = (p) => JSON.parse(Buffer.from(p.split('.')[1], 'base64url').toString('utf8'));
  assert.notEqual(p1, p2);
  assert.notEqual(decode(p1).nonce, decode(p2).nonce);
});