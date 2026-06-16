# Domain setup — DNS, auth, and what each record is for

Adding a domain (`POST /domains`) returns a set of DNS records. Add them to the
zone, then verify. Understanding them avoids cargo-culting.

## The records Resend gives you

| record | host (example) | purpose |
|--------|----------------|---------|
| TXT (DKIM) | `resend._domainkey` | **DKIM public key**. Signs mail as `d=yourdomain` → this is what makes **DMARC pass by alignment**. The load-bearing one. |
| TXT (SPF) | `send` (subdomain) | SPF for the **return-path** subdomain: `v=spf1 include:amazonses.com ~all`. Authorizes the bounce path, not the visible `From`. |
| MX | `send` (subdomain) | Return-path / bounce handling: `feedback-smtp.<region>.amazonses.com`. On the **subdomain**, so it never clashes with your apex MX. |

Resend sends via SES under the hood, hence `amazonses.com` in SPF and the
feedback MX.

## Region (immutable)

`region` is fixed at creation: `us-east-1`, `eu-west-1`, or `sa-east-1`. Pick the
one nearest the bulk of your recipients / your app. To change it you delete and
re-add the domain (new DNS records). EU data residency → `eu-west-1`.

## Return-path on a subdomain — why it matters

Resend defaults the return-path to `send.yourdomain.com`. Keep it.

- Its SPF lives at `send.` — **independent** of any SPF at the apex.
- That means you can run an **inbound provider on the apex** (e.g. Cloudflare
  Email Routing sets an apex SPF `v=spf1 include:_spf.mx.cloudflare.net ~all`)
  with **zero conflict**. Two SPF records on two different names, both valid.
- If you instead put the return-path at the apex, its SPF would fight the
  inbound provider's apex SPF (only one SPF TXT per name is legal).

## Auto-config on Cloudflare

If the domain's DNS is on Cloudflare, the Resend domain page has an **"Auto
configure"** button: it talks to Cloudflare and writes all the records into the
zone for you. Fastest, least error-prone. After it runs, hit **Verify** in Resend.

## Manual DNS via the Cloudflare API

If not using auto-config, add each record. Example (DKIM TXT), DNS-only:

```bash
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" \
  -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
  --data '{"type":"TXT","name":"resend._domainkey","content":"p=MIGf...","ttl":1}'
```

Repeat for the `send` SPF TXT and the `send` MX (set `priority`). Token needs
**Zone › DNS › Edit**.

## DMARC

Resend doesn't require a DMARC record, but you want one for the apex:

```
_dmarc  TXT  "v=DMARC1; p=quarantine; adkim=r; aspf=r; rua=mailto:you@yourdomain.com"
```

- Passes because **DKIM aligns** (`d=yourdomain`), even though the return-path SPF
  is on a subdomain (relaxed alignment `aspf=r`).
- New domain: `p=quarantine` is fine; if any legitimate mail quarantines while you
  validate, drop to `p=none`, then tighten later.

## Verify checklist

1. `scripts/resend.sh domain <id>` → every record `status: verified`.
2. `scripts/resend.sh domains` → domain `status: verified`.
3. Send a test to your own inbox; confirm **inbox, not spam**, and that the
   message shows DKIM `PASS` + DMARC `PASS` in the raw headers.
