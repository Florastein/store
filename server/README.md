# Store OTP Email Worker

A Node.js / Cloudflare Workers-compatible Worker that sends **email OTP (one-time
password)** codes using [EmailJS](https://www.emailjs.com).

It runs on the Cloudflare Workers runtime (ESM) and uses `@emailjs/nodejs` to
deliver emails. Credentials are injected via Worker **secrets / bindings** and
never committed to the repo.

---

## Endpoints

| Method | Path          | Description                                             |
|--------|---------------|---------------------------------------------------------|
| `POST` | `/send-otp`   | Send an OTP email. Body: `{ "email": "...", "name"?: "...", "purpose"?: "..." }` |
| `POST` | `/verify-otp` | Verify a previously sent OTP. Body: `{ "email": "...", "otp": "123456", "purpose"?: "..." }` |
| `OPTIONS` | `/`        | CORS preflight for browser clients.                     |

### `POST /send-otp`

```jsonc
// request
{ "email": "user@example.com", "name": "Jane", "purpose": "email_confirmation" }

// 200 response
{ "success": true, "message": "OTP email sent.", "purpose": "email_confirmation" }
```

- The OTP is always generated server-side and is never returned by the API.
- `purpose` supports `email_confirmation`, `password_reset`, and `login`.
- Omitting `purpose` defaults to `email_confirmation` for backwards compatibility.
- OTPs are persisted in KV with a 5-minute expiry (when `OTP_KV` is bound).

### `POST /verify-otp`

```jsonc
// request
{ "email": "user@example.com", "otp": "483920", "purpose": "email_confirmation" }

// 200 (valid)  OR  401 (invalid/expired)
{ "success": true, "valid": true, "purpose": "email_confirmation" }
```

The verification purpose must match the purpose used to request the code.
Requires the `OTP_KV` binding. A verified OTP is deleted so it can't be reused.

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
   - `{{to_email}}` — recipient
   - `{{to_name}}` — recipient name / email
   - `{{email_subject}}` — purpose-specific subject
   - `{{email_eyebrow}}` — compact category label
   - `{{email_heading}}` — purpose-specific heading
   - `{{email_intro}}` — purpose-specific explanation
   - `{{email_action}}` — action associated with the code
   - `{{security_note}}` — purpose-specific safety copy
   - `{{otp_code}}` — the OTP code
   - `{{otp_purpose}}` — stable purpose identifier
   - `{{otp_expiry_minutes}}` — expiry (e.g. `5`)
   - `{{from_name}}` — sender display name (e.g. `Store`)
5. In **Account → Security**, enable **API calls for non-browser applications**
   (required for the Node SDK).
6. Grab your Service ID, Template ID, Public Key, and Private Key.

The production email uses inline CSS and no JavaScript because mail clients
strip scripts. Open `email-template/preview.html` in a browser to inspect all
three variants using the small JavaScript purpose switcher.

### 2. Install dependencies

```bash
cd server
npm install
```

### 3. Configure secrets

For **local development**, copy `.dev.vars.example` → `.dev.vars` and fill in
the values:

```bash
cp .dev.vars.example .dev.vars
```

For **deployment**, set each value as a Cloudflare secret:

```bash
npx wrangler secret put EMAILJS_SERVICE_ID
npx wrangler secret put EMAILJS_TEMPLATE_ID
npx wrangler secret put EMAILJS_PUBLIC_KEY
npx wrangler secret put EMAILJS_PRIVATE_KEY
```

### 4. KV namespace

If you want OTP verification / rate limiting, create a KV namespace and update
`kv_namespaces.id` in `wrangler.jsonc`:

```bash
npx wrangler kv namespace create OTP_KV
```

---

## Local development

```bash
npm run dev            # wrangler dev, uses .dev.vars
curl -X POST http://localhost:8787/send-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","name":"Jane","purpose":"login"}'
```

## Deploy

```bash
npm run deploy         # dev/main environment
npm run deploy:prod    # production environment
```

---

## Environment variables / bindings

| Binding                 | Kind      | Required | Description                                    |
|-------------------------|-----------|----------|------------------------------------------------|
| `EMAILJS_SERVICE_ID`    | secret    | yes      | EmailJS service ID                             |
| `EMAILJS_TEMPLATE_ID`   | secret    | yes      | EmailJS OTP template ID                        |
| `EMAILJS_PUBLIC_KEY`    | secret    | yes      | EmailJS public key                             |
| `EMAILJS_PRIVATE_KEY`   | secret    | yes      | EmailJS private key (recommended for security) |
| `OTP_EMAIL_FROM`        | var       | no       | Sender display name (default: `Store`)         |
| `OTP_KV`                | KV binding| no       | KV for OTP persistence + rate limiting         |

> **Security:** Never use the *public* key alone for server–server sends. The
> private key must live only in Worker secrets. Keep `.dev.vars` out of git.
