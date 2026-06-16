#!/usr/bin/env bash
# resend.sh — thin wrapper over the Resend API (https://resend.com/docs/api-reference).
# Reads the key from $RESEND_API_KEY. Outputs compact, greppable lines (not raw JSON).
#
#   export RESEND_API_KEY=re_xxx
#   ./resend.sh domains
#   ./resend.sh domain-add example.com eu-west-1
#   ./resend.sh domain <domain-id>
#   ./resend.sh verify <domain-id>
#   ./resend.sh send "Name <from@example.com>" to@x.com "Subject" "Body text"
#   ./resend.sh status <email-id>
#
# Targets stock macOS bash 3.2 + BSD tools. Needs curl + python3.
set -euo pipefail

API="https://api.resend.com"
: "${RESEND_API_KEY:?set RESEND_API_KEY (re_...) in the environment}"

# api <METHOD> <path> [json-body]
api() {
  local method="$1"; local path="$2"; local body="${3:-}"
  if [ -n "$body" ]; then
    curl -fsS -X "$method" "$API$path" \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      --data "$body"
  else
    curl -fsS -X "$method" "$API$path" \
      -H "Authorization: Bearer $RESEND_API_KEY"
  fi
}

# pyjson <python-expr-over-`d`> — reads stdin JSON into `d`, prints the expression
pyjson() { python3 -c "import sys,json
d=json.load(sys.stdin)
$1"; }

cmd="${1:-}"; shift || true
case "$cmd" in
  domains)
    api GET /domains | pyjson "
for x in (d.get('data') or []):
    print(x.get('id'), x.get('name'), x.get('region'), x.get('status'))"
    ;;

  domain-add)
    name="${1:?usage: domain-add <domain> [region]}"; region="${2:-us-east-1}"
    api POST /domains "{\"name\":\"$name\",\"region\":\"$region\"}" | pyjson "
print('id', d.get('id'))
print('name', d.get('name'), '| region', d.get('region'), '| status', d.get('status'))
print('--- DNS records to add ---')
for r in (d.get('records') or []):
    print(r.get('type'), r.get('name'), '->', r.get('value'), '| pri', r.get('priority',''), '| ttl', r.get('ttl',''))"
    ;;

  domain)
    id="${1:?usage: domain <domain-id>}"
    api GET "/domains/$id" | pyjson "
print('name', d.get('name'), '| region', d.get('region'), '| status', d.get('status'))
for r in (d.get('records') or []):
    print(' ', r.get('record'), r.get('type'), r.get('name'), '->', str(r.get('value'))[:60], '| status', r.get('status'))"
    ;;

  verify)
    id="${1:?usage: verify <domain-id>}"
    api POST "/domains/$id/verify" >/dev/null && echo "verify requested for $id (poll: domain $id)"
    ;;

  send)
    from="${1:?usage: send <from> <to> <subject> <text>}"; to="${2:?}"; subj="${3:?}"; text="${4:?}"
    body=$(python3 -c "import json,sys; print(json.dumps({'from':sys.argv[1],'to':[sys.argv[2]],'subject':sys.argv[3],'text':sys.argv[4]}))" "$from" "$to" "$subj" "$text")
    api POST /emails "$body" | pyjson "print('id', d.get('id') or d)"
    ;;

  status)
    id="${1:?usage: status <email-id>}"
    api GET "/emails/$id" | pyjson "
print('to', d.get('to'), '| last_event', d.get('last_event'), '| subject', d.get('subject'))"
    ;;

  *)
    echo "usage: resend.sh {domains|domain-add|domain|verify|send|status} ..." >&2
    exit 1
    ;;
esac
