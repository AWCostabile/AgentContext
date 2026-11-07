#!/bin/bash
# retention.sh — SessionStart: the context-retention module's check for the instance and the
# workspace's projects, and the repair of what this harness filed under a project's OLD path.
#
# The module (common/modules/context-retention/meta.sh) reports that project <id> was last seen at one
# path and is now at another. This harness files a project's transcripts and auto memory under
# <config>/projects/<encoded path>/, so a moved project is a stranger to the resume picker and
# to MEMORY.md. The hook derives the old and the new encoded names (every character outside
# [A-Za-z0-9] becomes a hyphen), checks the rule against its own transcript_path, and moves the
# old directory's files into the new one — a rename when the new one does not exist yet, a merge
# that never overwrites otherwise — then says what it did in one line of additional context. When
# the rule does not reproduce this session's own directory, it only says where the old material
# sits. ~/.claude.json's per-project entry (trust, allowed tools) is left alone: the harness asks
# once more and rewrites it.
#
# Also hands the session the instance's own identity line, so the first-touch read of
# .agents/.id.meta is done. Degrades to nothing when the module is absent. Emits JSON only; on
# any problem, nothing. Exits 0.
set -u
HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HOOKDIR/../.." && pwd)"
[ -f "$ROOT/common/modules/context-retention/meta.sh" ] || exit 0
PY=""
for c in python3 python py; do
  "$c" -c pass >/dev/null 2>&1 && { PY="$c"; break; }
done
[ -z "$PY" ] && exit 0
# The check runs here, in the shell the hook runs in, and its rows reach the Python body
# through the environment: a Python child resolving `bash` on Windows may find another bash.
RETENTION_ROWS=$(cd "$ROOT" && timeout 20 bash common/modules/context-retention/meta.sh check --porcelain 2>/dev/null)
export RETENTION_ROWS
timeout 10 "$PY" -I "$HOOKDIR/retention.py" "$ROOT" 2>/dev/null
exit 0
