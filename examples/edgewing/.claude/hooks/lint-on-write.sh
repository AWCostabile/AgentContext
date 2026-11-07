#!/bin/bash
# lint-on-write.sh — PostToolUse (Write|Edit|MultiEdit): after a write into the
# knowledge tree (public/, private/, common/templates/, constitution/, AGENTS.md, README.md)
# run the structural lint and hand any [FAIL] lines plus the VERDICT back as
# additionalContext, so the session repairs them in the same action.
# Emits nothing when the tree is sound. Never blocks; always exits 0.
set -u
HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HOOKDIR/../.." && { pwd -W 2>/dev/null || pwd; })"
[ -f "$HOOKDIR/../../common/scripts/cure.sh" ] || exit 0

PY=""
for c in python3 python py; do
  "$c" -c pass >/dev/null 2>&1 && { PY="$c"; break; }
done
[ -z "$PY" ] && exit 0

rel=$("$PY" "$HOOKDIR/relpath.py" "$ROOT" 2>/dev/null) || exit 0
case "$rel" in
  public/*|private/*|common/templates/*|constitution/*|AGENTS.md|README.md) ;;
  *) exit 0 ;;
esac

out=$(cd "$HOOKDIR/../.." && timeout 30 bash common/scripts/cure.sh --fast 2>/dev/null)
report="" nfail=0
while IFS= read -r line; do
  case "$line" in
    "[FAIL]"*) report+="$line"$'\n'; nfail=$((nfail + 1)) ;;
    "== VERDICT"*) report+="$line" ;;
  esac
done <<< "$out"
[ "$nfail" -eq 0 ] && exit 0

printf '%s' "$report" | "$PY" -c '
import json, sys
rel = sys.argv[1]
body = sys.stdin.buffer.read().decode("utf-8", "replace").rstrip()
ctx = "cure.sh --fast after writing " + rel + " (fix in the same action):\n" + body
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": ctx}}))
' "$rel" 2>/dev/null
exit 0
