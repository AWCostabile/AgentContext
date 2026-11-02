#!/bin/bash
# sibling-instruction.sh — PostToolUse (Read|Edit|Write|MultiEdit|Glob|Grep|Bash): the
# first-touch read of a workspace sibling, done for the session.
#
# The instance's settings leave CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD at 0, so a sibling
# repository's instruction file is not loaded at session start (an added directory's instruction
# otherwise loads at start, flag or no flag, on this harness). The harness does not load it later
# either: with the flag at 0, reading a file in the sibling brings nothing in. This hook does what
# AGENTS.md asks of the agent: the first time a tool's path falls under a workspace sibling, it
# hands the session that sibling's `.agents/.id.meta` line and its instruction file (CLAUDE.md,
# or AGENTS.md when CLAUDE.md is the one-line import of it) as additional context — once per
# session per sibling, recorded in a marker file keyed by session id. The siblings are the
# folders the instance's workspace file names; a sibling the session never enters costs nothing.
# Emits JSON only; on any problem, nothing. Always exits 0.
set -u
HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HOOKDIR/../.." && pwd)"
PY=""
for c in python3 python py; do
  "$c" -c pass >/dev/null 2>&1 && { PY="$c"; break; }
done
[ -z "$PY" ] && exit 0
timeout 10 "$PY" -I "$HOOKDIR/sibling-instruction.py" "$ROOT" 2>/dev/null
exit 0
