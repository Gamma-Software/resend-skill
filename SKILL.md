---
name: resend
description: Send and operate transactional email with Resend — send/batch emails via the API or SMTP, add and verify a sending domain (DKIM/SPF/return-path, auto-config for Cloudflare), check delivery status, pair with Cloudflare Email Routing for inbound forwarding, and wire Gmail "Send mail as". Trigger on "set up Resend", "send a (test) email", "add email sending to my app/Worker", "add/verify a domain in Resend", "set up contact@ on my domain", "wire Gmail send-as", "transactional email", or a `re_...` API key.
---

# Resend

Operate [Resend](https://resend.com) for a project: send transactional mail, and
stand up a custom **sending domain** with correct email auth. Resend handles
**outbound only** — for a real `contact@yourdomain` inbox you pair it with a
forwarder (Cloudflare Email Routing) and/or Gmail "Send mail as". This skill
covers all three.

```
[have RESEND_API_KEY] → send / batch                              (outbound, minutes)
[new domain] → add domain → DNS (DKIM/SPF/return-path) → verify → send
[want a real inbox] → + Cloudflare Email Routing (receive) → + Gmail send-as (reply-as)
```

The key is the whole story: **send** is one API call once a domain is verified;
the rest is DNS + one human gate (clicking a verification link).

## 0. Prerequisites — the API key

Every call needs a Resend API key (`re_...`). **Read it from the environment, never
hardcode or commit it.**

```bash
export RESEND_API_KEY=re_xxx        # the user provides this
```

If the user pastes a key in chat, use it for the task but tell them it's now in
the transcript and to **rotate it** if that matters. Never write it into a file,
a commit, or memory.

The bundled `scripts/resend.sh` wraps the common calls (it reads `$RESEND_API_KEY`):

```bash
scripts/resend.sh domains                       # list domains + status
scripts/resend.sh domain-add <domain> [region]  # add a sending domain (region: us-east-1|eu-west-1|sa-east-1)
scripts/resend.sh domain <id>                    # show one domain + its required DNS records
scripts/resend.sh verify <id>                    # ask Resend to re-check DNS / verify
scripts/resend.sh send <from> <to> <subject> <text>
scripts/resend.sh status <email-id>              # delivery state (last_event)
```

## 1. Send (domain already verified)

Confirm the domain is `verified` first (`scripts/resend.sh domains`). Then a send
is one POST to `https://api.resend.com/emails`:

```bash
scripts/resend.sh send "Name <contact@yourdomain.com>" "user@example.com" \
  "Subject" "Body text."
```

- `from` MUST be on a **verified** domain you own in Resend; the display name is free.
- Sending is an **outward action** — if it isn't an obvious self-test, show the
  `from`/`to`/`subject` and confirm before firing (especially to real recipients
  or in bulk). A test to the user's own address needs no ceremony.
- Returns an email `id`; check delivery with `scripts/resend.sh status <id>`
  (`last_event`: `delivered`, `bounced`, `complained`, …).
- Batch/HTML/attachments/idempotency and the SMTP transport are in
  `references/sending.md`.

## 2. Set up a sending domain

Full DNS detail (record meanings, alignment, regions, return-path) lives in
`references/domain-setup.md` — read it before doing this. Short path:

1. **Add** the domain: `scripts/resend.sh domain-add yourdomain.com eu-west-1`
   (pick the region nearest the sender; it's **immutable** after creation).
2. **DNS** — Resend returns DKIM + SPF + return-path records:
   - On **Cloudflare**, the dashboard's **"Auto configure"** button pushes them
     straight into the zone (fastest). Otherwise add them by hand (or via the
     Cloudflare API — see `references/domain-setup.md`).
   - Keep the return-path on its **own subdomain** (default `send.`) so its SPF
     doesn't collide with an apex SPF you use for inbound.
3. **Verify**: `scripts/resend.sh verify <id>`, then poll `scripts/resend.sh domain <id>`
   until `status: verified`. DKIM is what makes DMARC pass via alignment — SPF on
   the return-path subdomain is for the bounce path, not the visible `From`.

## 3. Receiving — pair with Cloudflare Email Routing (optional)

Resend does **not** forward inbound mail to a human inbox (its inbound feature is
webhook-to-app). To actually *receive* `contact@yourdomain` in Gmail, use
**Cloudflare Email Routing** alongside Resend. They coexist cleanly: CF owns the
apex **MX** (receiving), Resend sends via the `send.` subdomain (no MX clash).
Step-by-step (enable, destination verify, forward rules, ripping out a prior
provider's MX/SPF) is in `references/receiving.md`.

## 4. Reply *as* the address — Gmail "Send mail as" (optional)

So the user can reply as `contact@yourdomain` from Gmail. The Resend API key
**is** the SMTP password:

- Host `smtp.resend.com`, port `587` (STARTTLS) or `465` (TLS), user `resend`,
  password = the API key.
- Gmail → Settings → **Accounts → Send mail as → Add** → that SMTP. Gmail emails a
  verification link to the address — it arrives via the Cloudflare forward (§3),
  click it. This is a **human gate**: you can't click it for them.

## 5. Validate — don't declare success blind

- `scripts/resend.sh domains` shows the domain `verified`.
- **Roundtrip test** proves both directions with two sends:
  - send `from` a verified address `to` the user's real inbox → proves sending
    (DKIM/SPF). Confirm it lands in **inbox, not spam** (DMARC alignment).
  - if §3 is set up, send `to` `contact@yourdomain` → `last_event: delivered`
    means the forwarder's MX accepted it; confirm it reaches the inbox.
- Check `scripts/resend.sh status <id>` is `delivered`, not `bounced`.

## 6. Report

Summarize: domain + region + verify status, which records were added (and how —
auto-config vs manual), receiving/forwarding wiring if any, the Gmail send-as
state (done vs human-gate pending), and the roundtrip test result. Flag any
exposed key for rotation.

## Gotchas (these bit in practice)

- **`from` must be a verified domain** — sending from an unverified domain 403s.
- **Region is immutable** — chosen at domain creation; recreate to change.
- **Don't enable Resend "Receiving"** if you're forwarding via Cloudflare — it
  grabs the apex MX and fights the forwarder.
- **Return-path SPF ≠ apex SPF.** Resend's SPF goes on `send.` (subdomain), so it
  never conflicts with an apex SPF used by an inbound provider.
- **DMARC** passes via **DKIM alignment** (`d=yourdomain`), not the return-path
  SPF. A new domain can keep `p=quarantine`; watch the first sends land in inbox,
  loosen to `p=none` only if legitimate mail quarantines.
- **Subaddress destinations** (`you+tag@gmail.com`) must match **exactly** in
  downstream rules — a forwarder rule to the no-tag address won't match.
