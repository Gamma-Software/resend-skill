# Receiving — pair Resend (send) with Cloudflare Email Routing (receive)

Resend is outbound-only for human inboxes. To actually receive
`contact@yourdomain` and read it in Gmail, put **Cloudflare Email Routing** in
front. They split cleanly:

- **Cloudflare** owns the apex **MX** → forwards inbound to your real inbox.
- **Resend** sends via the `send.` subdomain → no MX clash with Cloudflare.

Requires the domain's DNS to be on Cloudflare (nameservers pointed at CF).

## Tokens / permissions

Cloudflare splits these across permission scopes, and the API is fiddly:

- **Zone › DNS › Edit** — add/remove records (the Mailgun-sweep, manual record
  add). A normal user API token (`cfut_`).
- **Zone › Email Routing Rules › Edit** — create forward rules via API.
- **Enable Email Routing, manage destination addresses** — needs an
  account-scoped permission most tokens lack. In practice: **do the enable +
  destination-verify in the dashboard**, then script only the rules. An
  account-owned token (`cfat_`) verifies at
  `/accounts/{id}/tokens/verify`, not `/user/tokens/verify`.

## Steps

1. **Enable** (dashboard): Cloudflare → **Email → Email Routing → Get started**.
   CF adds its own MX (`route1/2/3.mx.cloudflare.net`), a CF DKIM TXT
   (`cf2024-1._domainkey`), and an apex SPF `v=spf1 include:_spf.mx.cloudflare.net
   ~all`. If a previous provider's MX exists (Mailgun, etc.), let CF **replace** it.

2. **Destination address** (dashboard, human gate): **Destination Addresses →
   Create** → the real inbox (e.g. `you+tag@gmail.com`) → click the verify link CF
   emails there. Rules to an **unverified** address fail with `code 2054`.
   **Use the exact string** — a `+tag` subaddress must match exactly later.

3. **Forward rules** (API, with the rules token):

   ```bash
   ACC=cfat_xxx   # Email Routing Rules: Edit
   ZONE=<zone-id>
   DEST="you+tag@gmail.com"   # MUST equal the verified destination exactly
   for u in contact hello support; do
     curl -s -X POST \
       "https://api.cloudflare.com/client/v4/zones/$ZONE/email/routing/rules" \
       -H "Authorization: Bearer $ACC" -H "Content-Type: application/json" \
       --data "{\"name\":\"$u\",\"enabled\":true,
         \"matchers\":[{\"type\":\"literal\",\"field\":\"to\",\"value\":\"$u@yourdomain.com\"}],
         \"actions\":[{\"type\":\"forward\",\"value\":[\"$DEST\"]}]}"
   done
   ```

   Leave the **catch-all** rule on `drop` unless you want every unmatched address
   forwarded.

4. **Sweep the old provider** (DNS-edit token): CF's enable replaces the apex MX +
   apex SPF, but leaves the old DKIM (e.g. `pic._domainkey`) and any tracking
   CNAME (e.g. `email → mailgun.org`). Delete those by id. Fix the DMARC `rua` if
   it points at the old provider.

## Don't enable Resend "Receiving"

Resend's own inbound feature delivers to a **webhook/app**, not a forwarded inbox,
and it wants the apex MX — which would fight Cloudflare. Leave it off for the
"read it in Gmail" use case.

## Verify the loop

- Send via Resend **to** `contact@yourdomain` → `last_event: delivered` means
  Cloudflare's MX accepted it → it forwards to the inbox. Confirm arrival.
- Send via Resend **from** `contact@yourdomain` to the real inbox → proves the
  outbound half. Both landing in **inbox (not spam)** = alignment is clean.
