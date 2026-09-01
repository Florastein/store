# Store OTP Email Worker

A Cloudflare Worker that sends **email OTP (one-time password)** codes using
[EmailJS](https://www.emailjs.com), with a strongly consistent
[Durable Object](https://developers.cloudflare.com/durable-objects/) backing
all OTP / rate-limit / verification state.

It runs on the Cloudflare Workers runtime (ESM, TypeScript) and uses
`@emailjs/nodejs` to deliver emails. Credentials are injected via Worker
**secrets / bindings** and never committed to the repo.

---

## Security model

OTP lifecycle state lives **only** in a Durable Object — never in KV, never in
plaintext in request/response, never caller-selected, and never based on
untrusted timestamps.

### OTP generation and storage

- **OTP generation** is uniform 6-digit via Web Crypto **rejection sampling**
  (no modulo bias). The plaintext value is sent to the recipient via EmailJS
  and is **never** persisted or returned by any endpoint.
- **OTP storage** is an **HMAC-SHA-256 digest** keyed with `OTP_SECRET` (≥ 32
  characters). The plaintext OTP is never stored.
- **Verification** compares the HMAC of the submitted code against the stored
  digest using a **constant-time** comparison.
- **Max 5 failed attempts**; the OTP is then invalidated and no further
  attempts are possible until a new code is issued.
- **Consume-once**: a verified OTP is marked consumed and cannot be reused.

### Atomic issue / commit / abort

OTP lifecycle operations go through an atomic reservation pattern per
normalized email+purpose. Critically, `beginIssue` **never** overwrites the
authoritative OTP/cooldown keys — the pending digest/purpose live in separate
*staged* reservation fields so an abort or stale-reservation cleanup can discard
an in-flight send without destroying a previously committed OTP:

1. **`beginIssue(reservationId, otpHash, purpose)`** — atomically checks the
   resend cooldown (60 s) and whether another send is already in-flight. If
   clear, claims a reservation slot using a unique caller-generated reservation
   id and stores the digest/purpose under **staged** reservation keys
   (`stagedReservationOtpHash`, `stagedReservationPurpose`). The authoritative
   `otpHash`/`purpose`/`lastSentAt` keys are left untouched. Uses `Date.now()`
   internally; never accepts caller timestamps.
2. **(EmailJS delivery happens here.)**
3. **`commitIssue(reservationId)`** — reads the staged digest/purpose bound to
   the matching reservation and promotes them to authoritative `otpHash`/
   `purpose`, along with expiry, zeroed attempts, `consumed=false` and
   `lastSentAt`, **only** if the reservation id matches. The body carries only
   `reservationId`, so a caller cannot substitute a different digest or purpose.
   Returns success only if commit succeeds; the API must **never** report send
   success if commit fails.
4. **`abortIssue(reservationId)`** — clears only the matching reservation id and
   its staged fields, preserving any prior authoritative OTP and prior cooldown
   (`lastSentAt`) so a failed delivery neither leaves a stale valid OTP without
   an email nor blocks the user.

Stale reservations (id + staged fields) self-expire after 30 seconds to avoid
deadlocks on worker crashes.

### Verification proof (trust boundary)

`POST /verify-otp` returns `valid: true` **plus an HMAC-signed proof token**:

```
format:  "1." payloadB64 "." signatureHex
payload: { email, purpose, exp, nonce }
```

`email` is the **normalized** (lowercased, trimmed) email. `purpose` is the
purpose string. `exp` is a fixed 5-minute TTL set at verification time. `nonce`
is a fresh random 16-byte hex value generated per verification.

The HMAC is signed with `OTP_SECRET` so only a trusted backend sharing that
secret can verify the proof.

A bare boolean alone does **not** create a Firebase session. The intended flow:

1. The client calls `/verify-otp` and receives the short-lived proof.
2. The client forwards the proof to a **trusted backend** (not the client).
3. The backend verifies the proof signature with `OTP_SECRET`, checks `exp`,
   and checks it has not seen the `nonce` before (replay protection). Then it
   performs the actual Firebase session creation (e.g. `createSessionCookie`,
   `Firebase Admin SDK` email-link sign-in, or minting a Firebase custom token).

> **Remaining Firebase work (out of scope here):** minting a Firebase session /
> custom token after proof verification. This Worker does not depend on the
> Firebase Admin SDK.

### Abuse protection on `/send-otp`

`/send-otp` requires an opaque installation `deviceFingerprint`. The Worker
applies independent fixed-window limits of 5 requests per device and 20 per IP
every 10 minutes, in addition to the existing 60-second per-email cooldown.
Identifiers are SHA-256 hashed before they are used as Durable Object names.

Turnstile is optional defense-in-depth. When both `TURNSTILE_SECRET_KEY` and a
request `turnstileToken` are present, the token is verified with siteverify.

### CORS and Origin policy

The Worker returns `Access-Control-Allow-Origin: *` on API and preflight
responses, allowing browser requests from every origin.

### Secret validation

All required secrets (`EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`,
`EMAILJS_PUBLIC_KEY`, `EMAILJS_PRIVATE_KEY`, `OTP_SECRET`) are validated on
every request. `OTP_SECRET` must be at least 32 characters.

---

## Endpoints

| Method | Path          | Description                                             |
|--------|---------------|---------------------------------------------------------|
| `POST` | `/send-otp`   | Send an OTP email. Body: `{ email, name?, purpose?, deviceFingerprint, turnstileToken? }` |
| `POST` | `/verify-otp` | Verify a previously sent OTP. Body: `{ email, otp, purpose? }` |
| `OPTIONS` | `/`        | CORS preflight; all origins are allowed.               |

### `POST /send-otp`

```jsonc
// request
{
  "email": "user@example.com",
  "name": "Jane",
  "purpose": "email_confirmation",
  "deviceFingerprint": "opaque-installation-id",
  "turnstileToken": "<optional-turnstile-widget-token>"
}

// 200 response
{ "success": true, "message": "OTP email sent.", "purpose": "email_confirmation" }
```

- The OTP is always generated **server-side** and is **never returned**.
- `purpose` supports `email_confirmation`, `password_reset`, and `login`.
  Omitting `purpose` defaults to `email_confirmation`.
- Requires a 20–128 character opaque `deviceFingerprint`.

### `POST /verify-otp`

```jsonc
// request
{ "email": "user@example.com", "otp": "483920", "purpose": "email_confirmation" }

// 200 (valid)
{ "success": true, "valid": true, "purpose": "email_confirmation", "proof": "1.<payload>.<sig>" }

// 422 (uniform failure)
{ "success": false, "valid": false, "message": "The verification code is invalid or expired." }
```

All verification failures return the same HTTP `422` status and the same public
message. The internal reason (e.g. `NO_ACTIVE_OTP`, `ALREADY_USED`, `EXPIRED`,
`INVALID_OTP`, `MAX_ATTEMPTS`) is logged server-side without email PII.

---

## Setup

### 1. EmailJS account

1. Create an [EmailJS](https://www.emailjs.com) account and connect an email service.
2. Open `email-template/emailjs-template.html`, copy the complete document, and
   paste it into the EmailJS template's HTML editor.
3. Configure the EmailJS template fields:
   - **To Email**: `{{to_email}}`
   - **Subject**: `{{email_subject}}`
   - **From Name**: `{{from_name}}`
4. The Worker supplies these escaped dynamic variables:
   `{{to_email}}`, `{{to_name}}`, `{{email_subject}}`, `{{email_eyebrow}}`,
   `{{email_heading}}`, `{{email_intro}}`, `{{email_action}}`,
   `{{security_note}}`, `{{otp_code}}`, `{{otp_purpose}}`,
   `{{otp_expiry_minutes}}`, `{{from_name}}`.
5. In **Account → Security**, enable **API calls for non-browser applications**.
6. Grab your Service ID, Template ID, Public Key, and Private Key.

### 2. Install dependencies

```bash
cd server
npm install
```

### 3. Configure secrets

For **local development**, copy `.dev.vars.example` → `.dev.vars` and fill in
the required values. Turnstile configuration is optional.

For **deployment**, set each value as a Cloudflare secret:

```bash
npx wrangler secret put EMAILJS_SERVICE_ID
npx wrangler secret put EMAILJS_TEMPLATE_ID
npx wrangler secret put EMAILJS_PUBLIC_KEY
npx wrangler secret put EMAILJS_PRIVATE_KEY
npx wrangler secret put OTP_SECRET        # >= 32 chars, e.g. openssl rand -hex 32
# Optional defense-in-depth:
npx wrangler secret put TURNSTILE_SECRET_KEY
```

> `OTP_SECRET` is the HMAC key used to hash stored OTPs and to sign the
> verification proof. Generate it with `openssl rand -hex 32`. Keep it in sync
> with your trusted backend that verifies proofs and tracks nonce replay.

### 4. Durable Objects

The Worker uses the `OTP_DO` and `RATE_LIMIT_DO` Durable Object bindings. These
are declared in `wrangler.jsonc`. No KV namespace is needed.

---

## Local development

```bash
npm run dev            # wrangler dev, uses .dev.vars
```

Example without Turnstile:
```bash
curl -X POST http://localhost:8787/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","name":"Jane","purpose":"login","deviceFingerprint":"local_device_fingerprint_12345"}'
```

## Type checking / tests

```bash
npm run typecheck      # tsc --noEmit (strict)
npm test               # node --test: crypto/validation logic + DO state transitions
```

## Deploy

```bash
npm run deploy         # dev/main environment
```

---

## Environment variables / bindings

| Binding                 | Kind          | Required | Description                                    |
|-------------------------|---------------|----------|------------------------------------------------|
| `EMAILJS_SERVICE_ID`    | secret        | yes      | EmailJS service ID                             |
| `EMAILJS_TEMPLATE_ID`   | secret        | yes      | EmailJS OTP template ID                        |
| `EMAILJS_PUBLIC_KEY`    | secret        | yes      | EmailJS public key                             |
| `EMAILJS_PRIVATE_KEY`   | secret        | yes      | EmailJS private key (recommended for security) |
| `OTP_SECRET`            | secret        | yes      | HMAC key for OTP hashing + proof signing (≥ 32 chars) |
| `TURNSTILE_SECRET_KEY`  | secret        | no       | Optional Turnstile secret key                  |
| `OTP_EMAIL_FROM`        | var           | no       | Sender display name (default: `Store`)         |
| `OTP_DO`                | DO binding    | yes      | Durable Object for OTP/cooldown state          |
| `RATE_LIMIT_DO`         | DO binding    | yes      | Device/IP fixed-window rate limiting           |

> **Security:**
> - Never use the *public* key alone for server–server sends. The private key
>   must live only in Worker secrets.
> - Keep `.dev.vars` out of git.
> - CORS permits requests from every browser origin.
> - Device fingerprints are client-generated installation identifiers, not
>   trusted authentication. IP and per-email limits remain essential layers.

---

## Design notes

- `src/index.ts` — Worker entrypoint: routing, input validation, secret
  validation, optional Turnstile, CORS, EmailJS delivery, and signed proofs.
- `src/rate-limit-do.ts` — atomic fixed-window device and IP rate limiting.
- `src/otp-do.ts` — `OtpDurableObject`: atomic `beginIssue`/`commitIssue`/
  `abortIssue` lifecycle, attempt counting, consume-once, expiry. `beginIssue`
  stages the digest/purpose in reservation keys and never overwrites
  authoritative `otpHash`/`purpose`/`lastSentAt`; `commitIssue` promotes the
  staged values bound to the matching reservation (body carries only
  `reservationId`). All timestamps are server-generated (`Date.now()`); no
  caller timestamps are accepted. Stale reservations self-expire after 30s.
- EmailJS's internal `storageProvider` is a separate in-memory map and never
  stores OTPs.
- `test/security.test.js` — pure crypto and validation logic tests.
- `test/otp-do.test.js` — DO state-transition tests with fake in-memory storage.
