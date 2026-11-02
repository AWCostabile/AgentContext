#!/bin/bash
# cache-ttl.sh — which prompt-cache lifetime this harness's sessions get, from one probe.
# Not part of the payload: never copied into an instance; the run-sheet runs it at setup.
#
# Usage: bash adapters/claude-code/cache-ttl.sh [<instance dir>] [--apply]
#
# The harness caches the prompt between turns for five minutes by default on an API key or a
# cloud provider, and for an hour on a subscription within its plan. An orchestrating session
# that waits on a delegated job past the cache's lifetime pays a cold write of its whole prompt
# on the next turn, so the hour matters for agent-run work. One cheap probe tells which lifetime
# a session gets: the reply's usage block counts the cache write under
# cache_creation.ephemeral_1h_input_tokens or .ephemeral_5m_input_tokens.
#
# With an instance directory, the probe runs there with the instance's project and local
# settings, so a lifetime set in them is what is measured. With --apply and a five-minute
# result, the keys `promptCacheTtl` and `subagentPromptCacheTtl` are written as "1h" into
# <instance>/.claude/settings.local.json (merged into what is there; that file is this
# machine's, never committed) and the probe runs again to prove the change took. The keys are
# honoured from Claude Code 2.1.242; an older build ignores them, and the second probe says so.
#
# Exit 0: the hour. Exit 1: five minutes. Exit 3: not run; stdout carries the reason.
set -u
INST=""; APPLY=0
for a in "$@"; do
  case "$a" in --apply) APPLY=1 ;; -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; *) INST=$a ;; esac
done
command -v claude >/dev/null 2>&1 || { echo "the claude CLI is not on PATH"; exit 3; }
PY=""
for c in python3 python py; do "$c" -c pass >/dev/null 2>&1 && { PY=$c; break; }; done
[ -n "$PY" ] || { echo "no Python to read the probe's JSON"; exit 3; }
[ -z "$INST" ] || [ -d "$INST" ] || { echo "no instance directory: $INST"; exit 3; }
T=""; command -v timeout >/dev/null 2>&1 && T="timeout 120"

probe() {   # prints "1h <n>" or "5m <n>" (n = tokens written), or "? <reason>"
  # a nonce in the system prompt makes every probe a cache WRITE; a repeat of the same prefix
  # within the lifetime would be a hit and count nothing
  local reply rc args=(-p "Reply with exactly OK." --output-format json --max-turns 1 --model haiku --no-session-persistence
    --append-system-prompt "cache probe $RANDOM$RANDOM$RANDOM")
  [ -n "$INST" ] && args+=(--setting-sources project,local)
  reply=$(cd "${INST:-.}" && env -u CLAUDECODE $T claude "${args[@]}" 2>&1 < /dev/null); rc=$?
  [ $rc -eq 0 ] || { printf '? the probe failed (exit %s): %s' "$rc" "$(printf '%s' "$reply" | head -n 1 | cut -c1-120)"; return; }
  printf '%s' "$reply" | "$PY" -I -c '
import json, sys
try:
    d = json.loads(sys.stdin.read()); cc = (d.get("usage") or {}).get("cache_creation") or {}
    h, m = int(cc.get("ephemeral_1h_input_tokens") or 0), int(cc.get("ephemeral_5m_input_tokens") or 0)
    if h == 0 and m == 0: print("? the probe wrote nothing to the cache (a hit, or caching off); run it again")
    else: print(("1h %d" % h) if h >= m else ("5m %d" % m))
except Exception as e:
    print("? the reply was not the JSON expected (%s)" % e.__class__.__name__)
'
}

echo "claude $(claude --version 2>/dev/null | head -n 1 | cut -d' ' -f1)"
read -r ttl n <<< "$(probe)"
case "$ttl" in
  '?') echo "prompt cache: not measured — $n"; exit 3 ;;
  1h) echo "prompt cache: 1h ($n tokens written at the one-hour lifetime) — an orchestrator can wait on a job for up to an hour without a cold re-mount"; exit 0 ;;
esac
echo "prompt cache: 5m ($n tokens written at the five-minute lifetime) — a session that waits longer than five minutes between turns re-writes its whole prompt; ORCH_BUDGET=lean keeps the waits short, and \"promptCacheTtl\": \"1h\" asks for the hour where the account allows it"
[ $APPLY -eq 1 ] && [ -n "$INST" ] || exit 1

LOCAL="$INST/.claude/settings.local.json"
mkdir -p "$INST/.claude" || { echo "cannot create $INST/.claude"; exit 3; }
"$PY" -I -c '
import json, os, sys
p = sys.argv[1]
d = {}
if os.path.isfile(p):
    with open(p, encoding="utf-8") as f:
        d = json.load(f)
d["promptCacheTtl"] = "1h"; d["subagentPromptCacheTtl"] = "1h"
with open(p, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=2); f.write("\n")
' "$LOCAL" || { echo "could not write $LOCAL"; exit 3; }
echo "written: promptCacheTtl and subagentPromptCacheTtl = \"1h\" in $LOCAL (this machine's file; the instance's .gitignore should keep it out)"
read -r ttl n <<< "$(probe)"
case "$ttl" in
  1h) echo "prompt cache after the change: 1h ($n tokens) — the setting took"; exit 0 ;;
  5m) echo "prompt cache after the change: still 5m ($n tokens) — the account does not grant the hour, or this build predates the setting (2.1.242); ask the account's administrator, and keep ORCH_BUDGET=lean"; exit 1 ;;
  *) echo "prompt cache after the change: not measured — $n"; exit 3 ;;
esac
