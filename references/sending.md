# Sending — beyond the one-liner

The core send is `POST https://api.resend.com/emails`. `scripts/resend.sh send`
covers the plain-text case; the API does more.

## Full payload

```json
{
  "from": "Acme <contact@yourdomain.com>",
  "to": ["a@x.com"],
  "cc": ["b@x.com"],
  "bcc": ["c@x.com"],
  "reply_to": "support@yourdomain.com",
  "subject": "Hello",
  "html": "<p>Hi <strong>there</strong></p>",
  "text": "Hi there",
  "headers": { "X-Entity-Ref-ID": "abc" },
  "tags": [{ "name": "category", "value": "welcome" }],
  "attachments": [
    { "filename": "invoice.pdf", "content": "<base64>" }
  ]
}
```

- Provide **both** `html` and `text` when you can — text is the fallback and helps
  deliverability.
- `attachments[].content` is base64; or pass `path` with a public URL.
- Always set `text` even for HTML mails — bare HTML looks spammy to filters.

## Idempotency

Pass an `Idempotency-Key` header to make a retry safe (no duplicate send):

```bash
curl -X POST https://api.resend.com/emails \
  -H "Authorization: Bearer $RESEND_API_KEY" \
  -H "Idempotency-Key: welcome-user-1234" \
  -H "Content-Type: application/json" --data '{...}'
```

## Batch

Up to 100 messages in one call at `POST /emails/batch` (array of email objects).
Each gets its own `id`. Good for fan-out; respects per-plan rate limits.

## SMTP transport

Anything that speaks SMTP (app frameworks, Gmail "Send mail as", CI) can send
through Resend instead of the REST API:

| field | value |
|-------|-------|
| host | `smtp.resend.com` |
| port | `587` (STARTTLS) or `465` (TLS) |
| username | `resend` |
| password | your API key (`re_...`) |

The API key is the SMTP password. Same DKIM/SPF, same verified-domain rule.

## Delivery + events

- `GET /emails/{id}` → `last_event` (`delivered`, `bounced`, `delivery_delayed`,
  `complained`). `scripts/resend.sh status <id>`.
- For real-time, configure a **webhook** in the Resend dashboard
  (`email.delivered`, `email.bounced`, …) → your endpoint. Better than polling for
  production.

## Rate limits & errors

- Default is a few requests/sec; `429` = back off. Bulk → use batch + spacing.
- `403` on send almost always = `from` domain not verified (or wrong region).
- `422` = malformed payload (missing `from`/`to`/`subject`, bad address).
