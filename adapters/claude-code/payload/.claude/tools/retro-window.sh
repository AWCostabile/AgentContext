#!/bin/bash
# retro-window.sh — assemble the block of landed work inside a date window, for a
# retrospective (the /retro skill feeds this to the historian subagent). Report-only.
#
#   bash .claude/tools/retro-window.sh <since YYYY-MM-DD> [until YYYY-MM-DD]
#   (until defaults to today; both ends inclusive)
#
# Sections:
#   1. commits per repository: this one, every sibling directory with a .git DIRECTORY
#      (a .git FILE is a worktree and is skipped) and the nested private repository when
#      this machine has one; the current branch and main, deduped by git itself;
#      author dates rendered in UTC, so a landing near midnight sits on one day
#   2. manifest rows across both trees whose "Landed as" cell holds a date inside the
#      window (common/scripts/lib-manifest.sh: the latest date in the cell), the count of
#      RECORDS; several records (plan, PR body, rulings) usually cite one landing
#   3. epic rows: a `[x]` plus a date inside the window, in every epic.*.md leaf
#   4. the most recent retro leaf, or none
#   5. the reflections filed inside the window, every
#      private/journal/reflections/<YYYY-MM>/reflection.<YYYY-MM-DD>.<slug>.md whose
#      filename date falls in it, each with the lines of its Improvements section (the
#      paragraph headed `**Improvements…**` or `Improvements…`, down to the next `## `).
#      A numbered list keeps the file's numbers; a bulleted item is given its ordinal,
#      `- (n)`, so the retro's disposition table can cite every proposal as
#      (reflection, number). A reflection with no such heading prints a loud line.
#
# A missing sibling is skipped silently. One process per concern, never one per file.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/scripts/lib-manifest.sh"

usage() { sed -n '5,6p' "$0"; }
SINCE=${1:-}
UNTIL=${2:-$(date +%F)}
for d in "$SINCE" "$UNTIL"; do
  case "$d" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) usage; exit 2 ;; esac
done

echo "== retro window $SINCE -> $UNTIL =="

# -- 1: commits per repository --------------------------------------------------
echo
echo "== 1. commits (current branch + main, deduped; UTC dates) =="
for d in "$ROOT/" "$ROOT"/../*/ "$ROOT/private/"; do
  d=${d%/}
  [ -d "$d/.git" ] || continue
  [ "$d" != "$ROOT" ] && [ "$(cd "$d" && pwd)" = "$ROOT" ] && continue
  refs="HEAD"
  git -C "$d" show-ref -q --verify refs/heads/main 2>/dev/null && refs="HEAD main"
  log=$(TZ=UTC timeout 10 git -C "$d" log --since="$SINCE 00:00:00" --until="$UNTIL 23:59:59" \
        --date=format-local:%Y-%m-%d --format='%h %ad %s' $refs 2>/dev/null)
  n=$(printf '%s' "$log" | grep -c .)
  name=${d##*/}; [ "$d" = "$ROOT/private" ] && name="${ROOT##*/}/private"
  echo "-- $name ($n)"
  [ -n "$log" ] && printf '%s\n' "$log"
done

# -- 2: manifest rows -----------------------------------------------------------
echo
echo "== 2. manifest rows landed in window (date  index  record) =="
manifest_landed_rows | sort -r | awk -F'\t' -v s="$SINCE" -v u="$UNTIL" '$1 >= s && $1 <= u {
  cnt++; print "  " $1 "  " $2 "  " $3
} END { print "-- " cnt + 0 " records" }'

# -- 3: epic rows ---------------------------------------------------------------
echo
echo "== 3. epic rows marked [x] in window =="
epic_roots=("$ROOT/public")
while IFS= read -r m; do epic_roots+=("$ROOT/$m"); done < <(mirror_dirs)
grep -rHn -F '[x]' --include='epic.*.md' "${epic_roots[@]}" 2>/dev/null | awk -v s="$SINCE" -v u="$UNTIL" -v r="$ROOT/" '{
  i = index($0, ":"); f = substr($0, 1, i - 1); rest = substr($0, i + 1)
  j = index(rest, ":"); ln = substr(rest, 1, j - 1); t = substr(rest, j + 1)
  hit = 0; x = t
  while (match(x, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
    d = substr(x, RSTART, RLENGTH); if (d >= s && d <= u) hit = 1
    x = substr(x, RSTART + RLENGTH)
  }
  if (!hit) next
  if (index(f, r) == 1) f = substr(f, length(r) + 1)
  gsub(/^[ |]+|[ |]+$/, "", t)
  cnt++; print "  " f ":" ln ": " substr(t, 1, 160)
} END { print "-- " cnt + 0 " rows" }'

# -- 4: last retro --------------------------------------------------------------
echo
echo "== 4. most recent retro leaf =="
last=$(last_retro_leaf)
echo "  ${last:-none}"

# -- 5: reflections and their proposals -----------------------------------------
echo
echo "== 5. reflections in window, with their Improvements =="
refl=()
for f in "$ROOT"/private/journal/reflections/*/reflection.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*.md; do
  [ -f "$f" ] || continue
  b=${f##*/reflection.}; d=${b:0:10}
  [[ "$d" < "$SINCE" || "$d" > "$UNTIL" ]] || refl+=("$f")
done
if [ ${#refl[@]} -eq 0 ]; then
  echo "-- 0 reflections, 0 proposals"
else
  awk -v r="$ROOT/" '
    function close_file() {
      if (cur != "" && !found) print "    (NO Improvements heading found: a new shape; read the leaf)"
    }
    FNR == 1 {
      close_file(); cur = FILENAME; found = 0; insec = 0; bul = 0; nref++
      f = FILENAME; if (index(f, r) == 1) f = substr(f, length(r) + 1)
      print "  " f
    }
    /^## / { insec = 0 }
    /^(\*\*)?Improvements/ { insec = 1; found = 1; next }
    insec && /[^[:space:]]/ {
      line = $0
      if (line ~ /^[0-9]+\. /) nprop++
      else if (line ~ /^[-*] /) { nprop++; bul++; line = substr(line, 1, 2) "(" bul ") " substr(line, 3) }
      print "    " line
    }
    END { close_file(); print "-- " nref + 0 " reflections, " nprop + 0 " proposals" }
  ' "${refl[@]}"
fi
