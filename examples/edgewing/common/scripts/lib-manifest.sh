#!/bin/bash
# lib-manifest.sh — read the landing dates out of the tree's provenance manifests.
#
# For tools that need to know what landed and when: an orientation hook that prints
# the last landing, or a retrospective that assembles the window since the last retro.
# Source it with ROOT set to the tree root; every function runs a fixed handful of
# processes whatever the tree's size (no process per file: Windows spawns are slow).
#
#   manifest_landed_rows   one line per manifest row whose "Landed as" cell holds a
#                          date:  <latest YYYY-MM-DD> TAB <index path> TAB <link text>
#                          TAB <Landed-as cell>
#   last_retro_leaf        path of the newest retro.YYYY-MM-DD.<slug>.md in any tree
#                          (newest by the date in its name), or nothing
#   retro_leaf_date        the YYYY-MM-DD in a retro leaf's name
#
# Both trees are read: public/, and the private mirror when this machine has one
# (lib-scopes.sh mirror_dirs), where the development-cycle manifests and the retros
# live. With no private tree the functions simply see less; never an error.
#
# A manifest is an .index.md whose Contents table has a "Landed as" column
# (| File | Kind | Created | Dates | Landed as |). Parsing rules:
#   - a cell may contain escaped pipes (`\|`, as in a change-log heading); they are
#     unescaped before the row is split so the column count stays right. The awk below
#     finds them with index() on an octal-spelled backslash, because a gawk regex `\|`
#     is alternation;
#   - one cell may name several landings (`;`-separated); the row's date is the LATEST;
#   - an unlanded row (`—`) has no date and is dropped;
#   - a row whose leaf is a moved stub (`_status:_ archived … moved to …`) is dropped:
#     the record is counted once, at its new home's row;
#   - only the last cell is read for dates, never Created or Dates.

. "$(dirname "${BASH_SOURCE[0]}")/lib-scopes.sh"

# The trees that carry manifests, relative to $ROOT
_manifest_trees() {
  printf '%s\n' public
  mirror_dirs
}

manifest_landed_rows() {
  (
    cd "$ROOT" || exit 0
    trees=$(_manifest_trees)
    # the moved-stub test smell.sh uses, one grep over every tree
    moved=" $(grep -rlE --include='*.md' '^_status:_[ \t]*archived .*moved to ' $trees 2>/dev/null | tr '\n' ' ') "
    grep -rl -F '| Landed as |' --include=.index.md $trees 2>/dev/null \
      | xargs -r grep -H '^| \[' 2>/dev/null \
      | awk -v moved="$moved" '{
          i = index($0, ":"); f = substr($0, 1, i - 1); row = substr($0, i + 1)
          if (match(row, /\]\(\.\/[^)]*\)/)) {            # the leaf the row links, beside its index
            leaf = f; sub(/\/[^\/]*$/, "", leaf); leaf = leaf "/" substr(row, RSTART + 4, RLENGTH - 5)
            if (index(moved, " " leaf " ")) next
          }
          while ((p = index(row, "\134|")) > 0)   # "\134" = backslash; a literal one is lexed away
            row = substr(row, 1, p - 1) "\001" substr(row, p + 2)
          n = split(row, c, "|")
          if (n < 7) next    # leading empty, File, Kind, Created, Dates, Landed as, trailing
          cell = c[6]; gsub(/\001/, "|", cell); gsub(/^ +| +$/, "", cell)
          latest = ""; s = cell
          while (match(s, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
            d = substr(s, RSTART, RLENGTH); if (d > latest) latest = d
            s = substr(s, RSTART + RLENGTH)
          }
          if (latest == "") next
          title = c[2]; sub(/^ *\[/, "", title); sub(/\]\(.*$/, "", title); gsub(/\001/, "|", title)
          print latest "\t" f "\t" title "\t" cell
        }'
  )
}

last_retro_leaf() {
  (
    cd "$ROOT" || exit 0
    find $(_manifest_trees) -type f -name 'retro.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].*.md' \
      -printf '%f\t%p\n' 2>/dev/null | sort -r | head -n 1 | cut -f2
  )
}

retro_leaf_date() {
  local base=${1##*/}
  base=${base#retro.}
  printf '%s\n' "${base:0:10}"
}
