import type { DurableObjectState } from '@cloudflare/workers-types';

interface HitBody {
  limit?: number;
  windowMs?: number;
}

export class RateLimitDurableObject {
  constructor(private readonly state: DurableObjectState) {}

  async fetch(request: Request): Promise<Response> {
    if (request.method !== 'POST') {
      return this.json({ error: 'Method not allowed' }, 405);
    }

    const body = await request.json<HitBody>();
    const limit = body.limit;
    const windowMs = body.windowMs;
    if (!Number.isInteger(limit) || !Number.isInteger(windowMs) || limit! < 1 || windowMs! < 1000) {
      return this.json({ error: 'Invalid rate-limit configuration' }, 400);
    }

    const now = Date.now();
    const storedWindowStart = (await this.state.storage.get<number>('windowStart')) ?? now;
    let count = (await this.state.storage.get<number>('count')) ?? 0;
    const windowStart = now - storedWindowStart >= windowMs! ? now : storedWindowStart;
    if (windowStart === now) {
      count = 0;
    }

    if (count >= limit!) {
      return this.json({
        ok: false,
        retryAfterMs: Math.max(1, windowMs! - (now - windowStart)),
      }, 429);
    }

    count += 1;
    await this.state.storage.put({ windowStart, count });
    return this.json({ ok: true, remaining: limit! - count, retryAfterMs: 0 });
  }

  private json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
