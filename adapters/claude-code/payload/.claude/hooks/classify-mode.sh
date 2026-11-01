#!/bin/bash
# classify-mode.sh — UserPromptSubmit: on the FIRST prompt of a session decide
# whether it is a kickoff (an orchestrated piece of work) and, if so, hand the session
# its mode line plus KICKOFF.md as additionalContext. Either route detects it:
#   (a) the first non-blank line reads `Mode: orchestrated ...`
#   (b) two or more of the kickoff section markers appear (case-insensitive):
#       WORKING DIRECTORIES, HARD RULE, VERIFY RATHER THAN ASSUME, CLOSE-OUT, SETTLE WITH
# A first line of `Mode: scoping` keeps the default posture. Later prompts emit
# nothing: a marker file keyed by session_id under ${TMPDIR:-${TEMP:-/tmp}} records
# that the session was classified (markers older than two days are pruned).
# Runs on every prompt, so it stays nearly fork-free: stdin is read once and the
# script itself is tried per interpreter candidate; one that is not a working
# interpreter (a launcher stub) exits non-zero and the next is tried.
# Emits JSON only; on any problem, nothing. Always exits 0.
set -u
HOOKDIR=${BASH_SOURCE[0]%/*}
KICKOFF="$HOOKDIR/../../KICKOFF.md"
[ -f "$KICKOFF" ] || exit 0
input=""
IFS= read -r -d '' input || [ -n "$input" ] || exit 0

for c in python python3 py; do
  command -v "$c" >/dev/null 2>&1 || continue
  "$c" -c '
import glob, json, os, re, sys, time
kickoff = sys.argv[1]
try:
    data = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
except Exception:
    sys.exit(0)
sid = data.get("session_id") or ""
prompt = data.get("prompt") or ""
if not isinstance(sid, str) or not sid or not isinstance(prompt, str):
    sys.exit(0)
tmp = os.environ.get("TMPDIR") or os.environ.get("TEMP") or "/tmp"
marker = os.path.join(tmp, "knowledge-tree-mode." + re.sub(r"[^A-Za-z0-9_.-]", "_", sid))
if os.path.exists(marker):
    sys.exit(0)
try:
    open(marker, "w").close()
    now = time.time()
    for old in glob.glob(os.path.join(tmp, "knowledge-tree-mode.*")):
        if now - os.path.getmtime(old) > 2 * 86400:
            os.remove(old)
except Exception:
    pass
first = next((l.strip() for l in prompt.splitlines() if l.strip()), "")
if re.match(r"(?i)^mode:\s*scoping", first):
    sys.exit(0)
orchestrated = bool(re.match(r"(?i)^mode:\s*orchestrated", first))
if not orchestrated:
    low = prompt.lower()
    markers = ("working directories", "hard rule", "verify rather than assume", "close-out", "settle with")
    orchestrated = sum(1 for m in markers if m in low) >= 2
if not orchestrated:
    sys.exit(0)
with open(kickoff, encoding="utf-8") as f:
    body = f.read().rstrip()
ctx = ("Mode: orchestrated — the scoping posture is suspended for this session; "
       "behave per .claude/output-styles/orchestrated.md.\n\n" + body)
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": ctx}}))
' "$KICKOFF" <<< "$input" 2>/dev/null && break
done
exit 0
