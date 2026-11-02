#!/usr/bin/env bash
# Runs claude-account against a fake HOME with made-up logins; never touches the real one.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/.claude"

ca() { HOME="$T" python3 "$REPO/bin/claude-account" "$@"; }

login() {  # login <user>: what a browser login leaves on disk
  printf '{"claudeAiOauth":{"accessToken":"tok-%s","refreshToken":"ref-%s"}}' "$1" "$1" \
    > "$T/.claude/.credentials.json"
  printf '{"keep":"shared","oauthAccount":{"accountUuid":"%s","organizationUuid":"org","emailAddress":"%s@x","organizationName":"Org"}}' "$1" "$1" \
    > "$T/.claude.json"
}

token() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["claudeAiOauth"]["accessToken"])' "$1"; }

fail=0
check() {  # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then echo "ok   $1"; else echo "FAIL $1: expected '$2', got '$3'"; fail=1; fi
}

login alice
ca save work >/dev/null
check "save stores the login" "tok-alice" "$(token "$T/.claude/accounts/work/credentials.json")"

ca use personal >/dev/null
check "new name signs out" "no" "$([[ -f $T/.claude/.credentials.json ]] && echo yes || echo no)"

login bob
ca sync >/dev/null
check "first login is saved under the pending name" "tok-bob" "$(token "$T/.claude/accounts/personal/credentials.json")"

# Claude Code renews tokens while running; the switch must keep the renewed ones.
printf '{"claudeAiOauth":{"accessToken":"tok-bob-2","refreshToken":"ref-bob-2"}}' > "$T/.claude/.credentials.json"
ca use work >/dev/null
check "switching loads the target login" "tok-alice" "$(token "$T/.claude/.credentials.json")"
check "switching saves the renewed login" "tok-bob-2" "$(token "$T/.claude/accounts/personal/credentials.json")"
check "other config keys survive" "shared" "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["keep"])' "$T/.claude.json")"

ca use personal >/dev/null
check "switching back needs no login" "tok-bob-2" "$(token "$T/.claude/.credentials.json")"
check "list marks the active account" "* personal" "$(ca | grep '^\*' | awk '{print $1, $2}')"
check "saved files are private" "600" "$(stat -c %a "$T/.claude/accounts/personal/credentials.json")"

exit $fail
