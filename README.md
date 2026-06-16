# Resend

A **transactional-email operator** as a skill for Claude Code (and any agent that
supports skills — OpenCode, Codex, Cursor). Send mail, stand up a verified
**sending domain** with correct DKIM/SPF, and — because Resend is outbound-only —
wire up real inbound (`contact@yourdomain` → your inbox) via Cloudflare Email
Routing and Gmail "Send mail as".

```
[have key] → send / batch
[new domain] → add → DNS (DKIM/SPF/return-path) → verify → send
[real inbox] → + Cloudflare Email Routing (receive) → + Gmail send-as (reply-as)
```

## How it works

1. **Sends** transactional mail via the Resend API or SMTP (`scripts/resend.sh`
   wraps send/batch/status), once a domain is verified.
2. **Sets up a sending domain** — adds it, lays down DKIM + SPF + return-path DNS
   (Cloudflare "Auto configure" or manual/API), verifies. The return-path lives on
   a `send.` subdomain so it never collides with an apex SPF.
3. **Closes the loop** (optional) — pairs with **Cloudflare Email Routing** so
   inbound `contact@` forwards to a real inbox, and sets up Gmail "Send mail as"
   so you can reply as the address. One human gate: clicking a verify link.
4. **Validates** with a roundtrip test (send out + send to the address) and
   delivery-status checks, then reports.

## Install

```bash
npx add-skill Gamma-Software/resend-skill           # all detected agents
npx add-skill Gamma-Software/resend-skill --global  # globally
```

Or manually:

```bash
git clone https://github.com/Gamma-Software/resend-skill.git
ln -s "$PWD/resend-skill" ~/.claude/skills/resend   # or copy it
```

## Usage

Just ask — it auto-triggers ("set up Resend", "send a test email", "add email
sending to my app", "verify a domain in Resend", "set up contact@ on my domain",
"wire Gmail send-as") or when you paste a `re_...` key — or run `/resend`.

Set the key in the environment first:

```bash
export RESEND_API_KEY=re_xxx
```

| Agent | Global path | Project path |
|-------|-------------|--------------|
| Claude Code | `~/.claude/skills/resend/` | `.claude/skills/resend/` |
| OpenCode | `~/.config/opencode/skill/resend/` | `.opencode/skill/resend/` |
| Codex | `~/.codex/skills/resend/` | `.codex/skills/resend/` |
| Cursor | `~/.cursor/skills/resend/` | `.cursor/skills/resend/` |

## Structure

```
resend-skill/
├── SKILL.md                      # the skill (frontmatter + procedure)
├── scripts/
│   └── resend.sh                 # Resend API wrapper (send, domains, verify, status)
├── references/
│   ├── sending.md                # batch, HTML, attachments, SMTP, idempotency, webhooks
│   ├── domain-setup.md           # DNS records explained, regions, DMARC alignment
│   └── receiving.md              # Cloudflare Email Routing pairing + Gmail send-as
└── evals/
    └── evals.json                # trigger evals
```

## Requirements

- A Resend account + API key (`re_...`) in `$RESEND_API_KEY`.
- `curl` + `python3` (the script wrapper). Stock macOS bash 3.2 OK.
- Optional inbound: a domain on Cloudflare (for Email Routing).

## License

MIT
