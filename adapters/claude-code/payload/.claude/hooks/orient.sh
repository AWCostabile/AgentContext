#!/bin/bash
# orient.sh — SessionStart: hand the session its bearings in at most 45 lines.
#   (a) the first line: the VERDICT of scripts/cure.sh --fast, so the session opens
#       knowing whether the tree is structurally sound; then, when the instance has
#       scripts/review.sh, its one-line brief: the smell count, the inbox, the stale and
#       uncited leaves, the retro pressure, the unpushed branches, the newest entry
#   (b) the work journal's status page, private/journal/latest.md, when this machine
#       has one; nothing when it does not
#   (c) private tree only: the retro pressure, how many manifest rows landed after
#       the newest retro leaf (scripts/lib-manifest.sh); every landed row counts
#       while no retro exists
#   (d) one line per repository: this one, its nested private repository when
#       present, and every sibling directory with a .git:
#       name  branch  +ahead/-behind (or "no upstream" / "no remote")  dirty-count
#   (e) one line per repository listing local branches with no upstream (main and
#       master excluded)
# Every git call is wrapped in a timeout; a missing or slow sibling degrades to "?"
# rather than failing the hook. Emits JSON only; on any problem, nothing. Exits 0.
set -u
HOOKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HOOKDIR/../.." && pwd)"

PY=""
for c in python3 python py; do
  "$c" -c pass >/dev/null 2>&1 && { PY="$c"; break; }
done
[ -z "$PY" ] && exit 0

g() { timeout 5 git -C "$@" 2>/dev/null; }

text=""
add() { text+="$1"$'\n'; }

# (a) the tree verdict, first
verdict=""
[ -f "$ROOT/scripts/cure.sh" ] \
  && verdict=$(cd "$ROOT" && timeout 30 bash scripts/cure.sh --fast 2>/dev/null | grep '^== VERDICT' | tail -1)
add "Knowledge tree orient — cure.sh --fast: ${verdict:-unavailable}"
if [ -f "$ROOT/scripts/review.sh" ]; then
  brief=$(cd "$ROOT" && timeout 40 bash scripts/review.sh --brief 2>/dev/null | tail -n 1)
  [ -n "$brief" ] && add "$brief"
fi

# (b) the journal, capped so the repository table below always fits
JOURNAL="$ROOT/private/journal/latest.md"
if [ -f "$JOURNAL" ]; then
  add ""
  add "Journal (private/journal/latest.md):"
  while IFS= read -r line; do add "$line"; done < <(
    grep -v '^[[:space:]]*$' "$JOURNAL" | grep -v '^# ' | head -n 16
  )
fi

# (c) the retro pressure: a fact about the private tree, silent without one
if [ -f "$ROOT/scripts/lib-manifest.sh" ]; then
  . "$ROOT/scripts/lib-manifest.sh"
  if has_mirror; then
    last=$(last_retro_leaf)
    if [ -n "$last" ]; then
      since=$(retro_leaf_date "$last")
      n=$(manifest_landed_rows | awk -v s="$since" '$1 > s' | wc -l | tr -d ' ')
      add "Retro: $n landed since $since; last retro: $last"
    else
      n=$(manifest_landed_rows | wc -l | tr -d ' ')
      add "Retro: $n landed; no retro filed yet"
    fi
  fi
fi

# (d) the repositories
add ""
add "Repositories (name  branch  vs upstream  dirty):"
unpushed=""
repos=()
[ -e "$ROOT/.git" ] && repos+=("$ROOT")
[ -d "$ROOT/private/.git" ] && repos+=("$ROOT/private")
for gd in "$ROOT"/../*/.git; do
  [ -e "$gd" ] || continue
  d=${gd%/.git}
  [ "$(cd "$d" && pwd)" = "$ROOT" ] && continue
  repos+=("$d")
done
declare -A seen_common   # git common dir -> first name; worktrees share one ref set
for d in "${repos[@]}"; do
  name=${d##*/}
  [ "$d" = "$ROOT/private" ] && name="${ROOT##*/}/private"
  branch=$(g "$d" rev-parse --abbrev-ref HEAD) || branch=$(g "$d" symbolic-ref --short HEAD) || branch="?"
  if counts=$(g "$d" rev-list --left-right --count '@{u}...HEAD'); then
    behind=${counts%%[[:space:]]*}; ahead=${counts##*[[:space:]]}
    sync="+${ahead}/-${behind}"
  elif [ -z "$(g "$d" remote)" ]; then
    sync="no remote"   # the private repository is trunk-only and may never have one
  else
    sync="no upstream"
  fi
  dirty=$(g "$d" status --porcelain | wc -l | tr -d ' ') || dirty="?"
  common=$(g "$d" rev-parse --path-format=absolute --git-common-dir) || common="$d"
  note=""
  if [ -n "${seen_common[$common]+x}" ]; then
    note="  (worktree of ${seen_common[$common]})"
  else
    seen_common[$common]=$name
  fi
  add "$(printf '  %-20s %-32s %-13s %s dirty%s' "$name" "$branch" "$sync" "$dirty" "$note")"
  [ -n "$note" ] && continue
  local_only=""
  while IFS='|' read -r ref up; do
    [ -z "$ref" ] && continue
    case "$ref" in main|master) continue ;; esac
    [ -z "$up" ] && local_only+="${local_only:+, }$ref"
  done < <(g "$d" for-each-ref --format='%(refname:short)|%(upstream:short)' refs/heads)
  [ -n "$local_only" ] && unpushed+="  $name: $local_only"$'\n'
done

# (e) unpushed branches
if [ -n "$unpushed" ]; then
  add ""
  add "Unpushed local branches:"
  text+="$unpushed"
fi

printf '%s' "$text" | head -n 45 | "$PY" -c '
import json, sys
body = sys.stdin.buffer.read().decode("utf-8", "replace").rstrip()
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": body}}))
' 2>/dev/null
exit 0
