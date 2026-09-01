import test from 'node:test';
import assert from 'node:assert/strict';
import { RateLimitDurableObject } from '../src/rate-limit-do.js';

class MemoryStorage {
  constructor() {
    this.values = new Map();
  }

  async get(key) {
    return this.values.get(key);
  }

  async put(keyOrValues, value) {
    if (typeof keyOrValues === 'string') {
      this.values.set(keyOrValues, value);
      return;
    }
    for (const [key, item] of Object.entries(keyOrValues)) {
      this.values.set(key, item);
    }
  }
}

test('rate limiter rejects hits beyond the configured window limit', async () => {
  const limiter = new RateLimitDurableObject({ storage: new MemoryStorage() });
  const hit = () => limiter.fetch(new Request('https://rate-limit-do/hit', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ limit: 2, windowMs: 60_000 }),
  }));

  assert.equal((await hit()).status, 200);
  assert.equal((await hit()).status, 200);
  const rejected = await hit();
  assert.equal(rejected.status, 429);
  assert.equal((await rejected.json()).ok, false);
});
