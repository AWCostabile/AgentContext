#!/bin/bash
# guard-tiers.sh — PreToolUse (Write|Edit|MultiEdit): refuse a write into an immutable
# tier of the knowledge tree before it happens (common/rules/provenance-tiers.md).
#
#   public/**/history/**        rulings, added verbatim with a manifest row
#   constitution/history/**     the same tier in the constitution, where it is adopted
#   private/**/prs/**           PR bodies; a body whose `_landed as:_` line still reads
#                               `—` is amendable while its pull request is open
#   private/**/appendices/**    the audit tables behind a PR body
#   private/journal/retros/**   retrospectives; a later retro corrects an earlier one
#
# Each branch's own .index.md, .tags and .agent stay writable: manifest rows and tags
# are authored. plans/ and kickoffs/ are not blocked here: an unlanded plan is still
# editable and a kickoff prompt is rewritten until an agent has run from it, both by rule
# rather than by path.
# Override: KNOWLEDGE_TREE_TIER_OVERRIDE=1 allows the write, for a deliberate, stated
# exception.
#
# Reads the hook JSON on stdin. Exit 2 with one stderr line blocks the tool; every
# other path exits 0 (allow): a broken hook must never wedge a session.
set -u
[ "${KNOWLEDGE_TREE_TIER_OVERRIDE:-0}" = "1" ] && exit 0

HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HOOKDIR/../.." && { pwd -W 2>/dev/null || pwd; })"

PY=""
for c in python3 python py; do
  "$c" -c pass >/dev/null 2>&1 && { PY="$c"; break; }
done
[ -z "$PY" ] && exit 0

rel=$("$PY" "$HOOKDIR/relpath.py" "$ROOT" 2>/dev/null) || exit 0
[ -z "$rel" ] && exit 0

lc=${rel,,}
case "${lc##*/}" in .index.md|.tags|.agent) exit 0 ;; esac

# A seed ruling is prospective law, not yet enacted: a leaf under any history/ whose first
# twelve lines carry `_status:_ seed` stays writable until the owner changes that line.
case "$lc" in
  */history/*|history/*)
    if [ -f "$ROOT/$rel" ] && head -n 12 "$ROOT/$rel" | grep -q -m1 '^_status:_ seed'; then exit 0; fi ;;
esac

reason=""
case "$lc" in
  public/*/history/*|constitution/history/*)
    reason="history/ is an immutable provenance tier (common/rules/provenance-tiers.md): add a record verbatim with cp plus a manifest row, never Write/Edit it" ;;
  private/*/prs/*)
    # An unlanded PR body is not yet a record: its own `_landed as:_` line reads `—`.
    if [ -f "$ROOT/$rel" ] && grep -q -m1 -E '^_landed as:_ (—|-) *$' "$ROOT/$rel"; then exit 0; fi
    reason="prs/ is an immutable provenance tier (common/rules/provenance-tiers.md): add a body verbatim with cp plus a manifest row; a landed body is corrected forward, never edited" ;;
  private/*/appendices/*|private/journal/retros/*)
    reason="this is an immutable provenance tier (common/rules/provenance-tiers.md): add a record verbatim with cp plus a manifest row, never Write/Edit it" ;;
esac
[ -z "$reason" ] && exit 0

echo "BLOCKED $rel: $reason; set KNOWLEDGE_TREE_TIER_OVERRIDE=1 for a deliberate, stated exception." >&2
exit 2
