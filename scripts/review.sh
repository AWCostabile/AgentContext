#!/bin/bash
# review.sh — the review agenda: what the tree's own checks say today, in about thirty
# lines, for the person who keeps the tree. Report-only: it writes nothing.
#
# It reuses the output of the scripts an instance already has and re-implements no check:
#   the VERDICT of cure.sh --fast            is the structure sound?
#   the summary table of smell.sh            what needs judgement, by id
#   the inbox                                how many items wait, and the oldest one's age
#   the S01, S20 and S21 findings            the stale leaves, the uncited law, the overdue items
#   landed-since-retro (lib-manifest.sh)     how many landings since the newest retrospective
#   the branches without an upstream         in the instance repository and the private tree
#   the newest journal entry                 when the journal last recorded a landing
# With no private tree the private rows are simply absent, never an error.
#
# Usage: bash common/scripts/review.sh [--root <dir>] [--brief] [--today <YYYY-MM-DD>]
#   --root <dir>  the tree root (the directory holding public/ and .conf); default the
#                 current directory
#   --brief       one line of counts, for a session's orientation
#   --today <d>   handed to smell.sh: judge the calendar smells as of that date
# Exit code: the FAIL count of cure.sh (0 unless the structure is broken); a smell is
# never a failure here.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(pwd)"
BRIEF=0
TODAY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "--root needs a directory" >&2; exit 2; }
            ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "no such directory: $2" >&2; exit 2; }
            shift 2 ;;
    --brief) BRIEF=1; shift ;;
    --today) [ $# -ge 2 ] || { echo "--today needs a date" >&2; exit 2; }
             TODAY=$2; shift 2 ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^#//; s/^ //'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$ROOT" || exit 2
[ -d public ] || { echo "no public/ directory under $ROOT — pass --root <tree root>" >&2; exit 2; }
. "$SCRIPT_DIR/lib-manifest.sh"   # sources lib-scopes.sh

g() { timeout 5 git -C "$@" 2>/dev/null; }

# -- the two linters, run once each ------------------------------------------------
cure=$(bash "$SCRIPT_DIR/cure.sh" --root "$ROOT" --fast 2>/dev/null); FAILS=$?
verdict=$(printf '%s\n' "$cure" | grep '^== VERDICT' | tail -n 1)
smell=$(bash "$SCRIPT_DIR/smell.sh" --root "$ROOT" ${TODAY:+--today "$TODAY"} 2>/dev/null) || true
summary=$(printf '%s\n' "$smell" | sed -n '/^== SUMMARY/,$p')
nsmell=$(printf '%s\n' "$summary" | sed -n 's/^== SUMMARY: \([0-9]*\) smell.*/\1/p')
landed=$(printf '%s\n' "$summary" | sed -n 's/.*landed-since-retro=\([0-9]*\).*/\1/p')
count_id() { printf '%s\n' "$smell" | grep -c "^\[SMELL $1\]"; }
n01=$(count_id S01); n20=$(count_id S20); n21=$(count_id S21)
# a finding, condensed to its path and the parenthesis that carries its age
findings() {
  printf '%s\n' "$smell" | awk -v ids="$1" '
    BEGIN { n = split(ids, a, " "); for (i = 1; i <= n; i++) want["[SMELL " a[i] "]"] = a[i] }
    $1 " " $2 in want {
      id = want[$1 " " $2]; rest = substr($0, length($1 " " $2) + 2)
      path = rest; sub(/:.*$/, "", path)
      age = ""; if (match(rest, /\([0-9][^)]*\)/)) age = " " substr(rest, RSTART, RLENGTH)   # the parenthesis carrying an age
      printf "  %s  %s%s\n", id, path, age
    }'
}

# -- the inbox ----------------------------------------------------------------------
INBOX=private/journal/inbox.md
inbox_line="Inbox: none"; inbox_brief="inbox 0"
if has_mirror && [ -f "$INBOX" ]; then
  read -r n_items n_mine n_cand oldest age < <(awk -v today="$TODAY" '
    BEGIN { if (today != "") { split(today, t, "-"); now = mktime(t[1] " " t[2] " " t[3] " 0 0 0") } else now = systime() }
    { sub(/\r$/, "") }
    /^## / { sec = tolower($2) }
    /^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {
      n++; if (sec == "mine") m++; else if (sec == "candidates") c++
      d = substr($0, 3, 10); if (oldest == "" || d < oldest) oldest = d
    }
    END {
      age = 0
      if (oldest != "") { split(oldest, o, "-"); age = int((now - mktime(o[1] " " o[2] " " o[3] " 0 0 0")) / 86400) }
      print n + 0, m + 0, c + 0, (oldest == "" ? "-" : oldest), age
    }' "$INBOX")
  if [ "$n_items" -eq 0 ]; then
    inbox_line="Inbox: empty"
  else
    inbox_line="Inbox: $n_items item(s) ($n_mine mine, $n_cand candidates); oldest $oldest, $age day(s) old"
    inbox_brief="inbox $n_items (oldest ${age}d)"
  fi
fi

# -- the retro pressure --------------------------------------------------------------
retro_line=""
if has_mirror; then
  last=$(last_retro_leaf)
  if [ -n "$last" ]; then retro_line="Retro: $landed landed since $(retro_leaf_date "$last") (last retro: $last)"
  else retro_line="Retro: $landed landed; no retro filed yet"; fi
fi

# -- branches without an upstream, in the instance and the private tree ----------------
unpushed=()
for d in "$ROOT" "$ROOT/private"; do
  [ -e "$d/.git" ] || continue
  name=${d##*/}; [ "$d" = "$ROOT/private" ] && name="private"
  local_only=""
  while IFS='|' read -r ref up; do
    [ -z "$ref" ] && continue
    case "$ref" in main|master) continue ;; esac
    [ -z "$up" ] && local_only+="${local_only:+, }$ref"
  done < <(g "$d" for-each-ref --format='%(refname:short)|%(upstream:short)' refs/heads)
  [ -n "$local_only" ] && unpushed+=("  $name: $local_only")
done

# -- the newest journal entry ---------------------------------------------------------
journal_line="" newest_date="none"
if has_mirror && [ -d private/journal/entries ]; then
  newest=$(find private/journal/entries -type f -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*.md' -printf '%f\t%p\n' 2>/dev/null | sort -r | head -n 1)
  if [ -n "$newest" ]; then newest_date=${newest:0:10}; journal_line="Journal: newest entry $newest_date (${newest#*	})"
  else journal_line="Journal: no entries yet"; fi
fi

# -- print ---------------------------------------------------------------------------------
if [ $BRIEF -eq 1 ]; then
  brief="review: cure $FAILS fail(s) · smells ${nsmell:-?} · $inbox_brief · stale $n01 · uncited $n20 · overdue $n21"
  has_mirror && brief+=" · landed-since-retro ${landed:-0}"
  brief+=" · unpushed ${#unpushed[@]} repo(s)"
  [ -n "$journal_line" ] && brief+=" · newest entry $newest_date"
  printf '%s\n' "$brief"
  exit "$FAILS"
fi

echo "== review — ${ROOT##*/} — $(date '+%Y-%m-%d')${TODAY:+ (as of $TODAY)} =="
echo "Structure: ${verdict:-cure.sh gave no verdict}"
printf '%s\n' "$summary" | sed 's/^== SUMMARY: /Smells: /; s/ ==$//'
echo "$inbox_line"
if [ $((n01 + n20 + n21)) -gt 0 ]; then
  echo "Stale, uncited, overdue (S01, S20, S21):"
  findings "S01 S20 S21" | head -n 12
  [ $((n01 + n20 + n21)) -gt 12 ] && echo "  … and $((n01 + n20 + n21 - 12)) more: bash common/scripts/smell.sh"
fi
[ -n "$retro_line" ] && echo "$retro_line"
if [ ${#unpushed[@]} -gt 0 ]; then
  echo "Branches without an upstream:"
  printf '%s\n' "${unpushed[@]}"
fi
[ -n "$journal_line" ] && echo "$journal_line"
exit "$FAILS"
