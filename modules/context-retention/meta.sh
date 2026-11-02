#!/bin/bash
# meta.sh — the context-retention module: a per-clone identity every project in the workspace
# carries, so an agent can keep a project's memory and history when the folder moves.
#
# The identity file, .agents/.id.meta, holds an identity and never a path (three key=value lines,
# nothing else):
#   id=<slug>-<6 hex>   the project's stable id, minted once by init
#   name=<slug>         the slug, as the workspace names the folder
#   created=YYYY-MM-DD
# It is a WORKSPACE file, never committed: one user's identity must not reach every clone. init
# asks, once, to add it to git's global excludes (core.excludesFile), and writes that one line
# only on an explicit yes. A project's own .gitignore is never touched.
#
# The map, ~/.config/agentcontext/projects, is where paths live: one tab-separated line per id —
# id, name, the last path seen, the date it was seen. check compares a project's current path
# with the one recorded for its id and reports a move; a harness adapter turns that report into
# whatever its own memory and history need. The map is a machine fact and stays in the home.
#
# Usage (from the instance root, the directory holding .conf):
#   bash modules/context-retention/meta.sh init [<path>...]   write .agents/.id.meta where absent
#                                                            (creating .agents/), record each in the
#                                                            map, and ask the excludes question once
#   bash modules/context-retention/meta.sh check [<path>...]  report each project: current, moved,
#                                                            first seen, or without an identity;
#                                                            update the map (exit code: the fails)
#   bash modules/context-retention/meta.sh list                print the map
# With no <path>, the projects are this instance and every folder its workspace file names
# (`<Name>.code-workspace` at the root; `.` and `./private` are the instance itself).
# Options:
#   --root <dir>     the instance root; default the current directory
#   --name <slug>    init, one path: the slug to use instead of the folder's name
#   --yes | --no     init: the excludes question answered without a prompt (a non-interactive run
#                    with neither answers no, and says so)
#   --porcelain      check: one tab-separated line per project for a hook to read —
#                    ok|moved|new|copied|absent|bad <TAB> id <TAB> path [<TAB> old path]
# Exit codes as the core's scripts: 0 clean, the number of fails otherwise, 2 for a usage error
# or a refusal when nothing was written.
#
# Nothing here names an agent harness. What a harness does with a reported move is its adapter's.

set -u

VERB=""; PATHS=(); ROOT=""; NAME=""; ANSWER=""; PORCELAIN=0
while [ $# -gt 0 ]; do
  case "$1" in
    init|check|list) [ -z "$VERB" ] || { echo "usage: one verb (init, check or list)" >&2; exit 2; }; VERB=$1 ;;
    --root) [ $# -ge 2 ] || { echo "usage: --root <dir>" >&2; exit 2; }; ROOT=$2; shift ;;
    --name) [ $# -ge 2 ] || { echo "usage: --name <slug>" >&2; exit 2; }; NAME=$2; shift ;;
    --yes) ANSWER=yes ;;
    --no) ANSWER=no ;;
    --porcelain) PORCELAIN=1 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "usage: unknown option $1" >&2; exit 2 ;;
    *) PATHS+=("$1") ;;
  esac
  shift
done
[ -z "$VERB" ] && { echo "usage: init | check | list (see --help)" >&2; exit 2; }
[ -z "$ROOT" ] && ROOT=$PWD
ROOT=$(cd "$ROOT" 2>/dev/null && pwd) || { echo "usage: --root $ROOT is not a directory" >&2; exit 2; }
[ -f "$ROOT/.conf" ] || { echo "refused: $ROOT holds no .conf — run from the instance root or pass --root" >&2; exit 2; }
[ -f "$ROOT/scripts/lib-scopes.sh" ] || { echo "refused: $ROOT/scripts/lib-scopes.sh is missing — the module runs inside an instance of the template" >&2; exit 2; }
# shellcheck source=/dev/null
. "$ROOT/scripts/lib-scopes.sh"
[ -n "$NAME" ] && { [ "$VERB" = init ] && [ ${#PATHS[@]} -eq 1 ]; } || [ -z "$NAME" ] || { echo "usage: --name goes with init and exactly one <path>" >&2; exit 2; }
case "$NAME" in *[!a-z0-9-]*) echo "usage: --name '$NAME' — lowercase [a-z0-9-] only" >&2; exit 2 ;; esac

FAIL=0; WARN=0
ok()   { [ $PORCELAIN -eq 1 ] || printf '[ OK ] %s\n' "$1"; }
info() { [ $PORCELAIN -eq 1 ] || printf '[INFO] %s\n' "$1"; }
warn() { [ $PORCELAIN -eq 1 ] || printf '[WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
fail() { [ $PORCELAIN -eq 1 ] || printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
row()  { [ $PORCELAIN -eq 0 ] || { local IFS=$'\t'; printf '%s\n' "$*"; }; }

case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN=0 ;; esac
SELF="modules/context-retention/meta.sh"
ID_FILE=".agents/.id.meta"
MAP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/agentcontext"
MAP="$MAP_DIR/projects"
TODAY=$(date '+%Y-%m-%d')

# -- paths ---------------------------------------------------------------------------------------
# A path as the map records it: resolved, and on Windows in its drive-letter spelling with
# forward slashes (what every tool on the platform agrees on). Compared case-insensitively there.
canon() {
  local p
  p=$(cd "$1" 2>/dev/null && pwd -P) || return 1
  if [ $WIN -eq 1 ]; then cygpath -m "$p"; else printf '%s' "$p"; fi
}
same_path() {
  if [ $WIN -eq 1 ]; then [ "$(printf '%s' "$1" | tr 'A-Z' 'a-z')" = "$(printf '%s' "$2" | tr 'A-Z' 'a-z')" ]
  else [ "$1" = "$2" ]; fi
}
slug_of() {   # the folder's name, lowercased, anything outside [a-z0-9-] folded to one hyphen
  printf '%s' "${1##*/}" | tr 'A-Z' 'a-z' | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//'
}
hex6() {
  local h
  h=$(od -An -N3 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
  [ ${#h} -eq 6 ] || h=$(printf '%06x' $(( (RANDOM * 32768 + RANDOM) % 16777216 )))
  printf '%s' "$h"
}

# The projects: the arguments, or the instance and the folders its workspace file names.
workspace_projects() {
  local ws p
  printf '%s\n' "$ROOT"
  for ws in "$ROOT"/*.code-workspace; do
    [ -f "$ws" ] || continue
    while IFS= read -r p; do
      case "$p" in .|./private|private|./*/private) continue ;; esac
      case "$p" in /*|?:*) ;; *) p="$ROOT/$p" ;; esac
      [ -d "$p" ] && printf '%s\n' "$p"
    done < <(sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*$/\1/p' "$ws")
  done
}
if [ ${#PATHS[@]} -eq 0 ] && [ "$VERB" != list ]; then
  while IFS= read -r p; do PATHS+=("$p"); done < <(workspace_projects)
fi

# -- the identity file ----------------------------------------------------------------------------
# read_id <dir>: sets ID NAME_IN CREATED from <dir>/.agents/.id.meta; returns 1 when absent, 2 when
# the shape is not the closed one (a key outside the three, a missing id, a stray line).
read_id() {
  local f="$1/$ID_FILE" line key val
  ID=""; NAME_IN=""; CREATED=""
  [ -f "$f" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    [ -z "$line" ] && continue
    key=${line%%=*}; val=${line#*=}
    [ "$key" = "$line" ] && return 2
    case "$key" in
      id) ID=$val ;; name) NAME_IN=$val ;; created) CREATED=$val ;;
      *) return 2 ;;
    esac
  done < "$f"
  [ -n "$ID" ] || return 2
  case "$ID" in *[!a-z0-9-]*) return 2 ;; esac
  return 0
}
write_id() {   # write_id <dir> <id> <name>
  mkdir -p "$1/.agents" || return 1
  printf 'id=%s\nname=%s\ncreated=%s\n' "$2" "$3" "$TODAY" > "$1/$ID_FILE"
}

# -- the map --------------------------------------------------------------------------------------
# map_lookup <id>: prints "name<TAB>path<TAB>seen" for the id, nothing when unknown
map_lookup() {
  [ -f "$MAP" ] || return 0
  awk -F'\t' -v id="$1" '$1 == id { print $2 "\t" $3 "\t" $4 }' "$MAP" | tail -n 1
}
# map_put <id> <name> <path>: replace the id's line, or append one; the file is rewritten whole
map_put() {
  local tmp
  mkdir -p "$MAP_DIR" || { fail "cannot create $MAP_DIR"; return 1; }
  [ -f "$MAP" ] || : > "$MAP"
  tmp=$(mktemp "$MAP_DIR/.projects.XXXXXX") || return 1
  awk -F'\t' -v id="$1" '$1 != id' "$MAP" > "$tmp"
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$TODAY" >> "$tmp"
  mv "$tmp" "$MAP"
}

# -- the excludes question (init) -----------------------------------------------------------------
# The file git reads for the user's own ignores: core.excludesFile when set (a leading ~ expanded),
# else the default git itself falls back to, $XDG_CONFIG_HOME/git/ignore or ~/.config/git/ignore.
excludes_file() {
  local f
  f=$(git config --global --get core.excludesFile 2>/dev/null)
  if [ -n "$f" ]; then
    case "$f" in "~/"*) f="$HOME/${f#\~/}" ;; esac
    printf '%s' "$f"; return 0
  fi
  printf '%s' "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"; return 1
}
globally_ignored() {   # true when the excludes file already carries the line
  local f; f=$(excludes_file) || true
  [ -f "$f" ] && grep -qxE -- "(\*\*/)?\.agents/\.id\.meta" "$f"
}
ASKED=0
ask_excludes() {
  [ $ASKED -eq 1 ] && return 0; ASKED=1
  if globally_ignored; then ok "git already ignores $ID_FILE globally ($(excludes_file))"; return 0; fi
  local f key_set=1 answer="$ANSWER"
  f=$(excludes_file) || key_set=0
  printf '%s\n' \
    "" \
    "$ID_FILE is one user's identity for the folder and must never be committed: in a clone it" \
    "would hand the same identity to everyone. Ignoring it per project would mean editing every" \
    "repository's .gitignore; git's GLOBAL excludes ignore it everywhere for this user alone." \
    "Recommended: yes." \
    "  the excludes file: $f$([ $key_set -eq 1 ] || printf ' (core.excludesFile is unset; it would be created and the key set)')" \
    "  the line:          $ID_FILE" ""
  if [ -z "$answer" ]; then
    if [ -t 0 ]; then
      printf 'Add %s to the global excludes? [y/N] ' "$ID_FILE"; read -r answer </dev/tty 2>/dev/null || answer=""
    else
      info "no terminal to ask on: not written (pass --yes to add the line, --no to stop being asked)"; answer=no
    fi
  fi
  case "$answer" in
    y|Y|yes|YES|Yes)
      mkdir -p "$(dirname "$f")" || { fail "cannot create $(dirname "$f")"; return 1; }
      if [ $key_set -eq 0 ]; then
        git config --global core.excludesFile '~/.config/git/ignore' || { fail "git config --global core.excludesFile failed"; return 1; }
        ok "core.excludesFile set to ~/.config/git/ignore"
      fi
      { [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ] && printf '\n'; printf '%s\n' "$ID_FILE"; } >> "$f" || { fail "cannot write $f"; return 1; }
      ok "$ID_FILE added to $f" ;;
    *) info "$ID_FILE is not ignored globally — a project that does not ignore it would commit it" ;;
  esac
}

# -- the verbs --------------------------------------------------------------------------------------
init_one() {
  local dir=$1 path slug id
  path=$(canon "$dir") || { fail "$dir: not a directory"; return 1; }
  slug=${NAME:-$(slug_of "$path")}
  [ -n "$slug" ] || { fail "$path: no slug can be made from the folder's name; pass --name"; return 1; }
  read_id "$path"; case $? in
    0) ok "$slug: $ID_FILE present (id $ID); kept" ;;
    2) fail "$slug: $path/$ID_FILE is not the closed shape (id=, name=, created= and nothing else) — fix or remove it"; return 1 ;;
    1) id="$slug-$(hex6)"
       write_id "$path" "$id" "$slug" || { fail "$slug: cannot write $path/$ID_FILE"; return 1; }
       ok "$slug: $ID_FILE written (id $id)"
       ID=$id ;;
  esac
  map_put "$ID" "$slug" "$path"
  if [ -d "$path/.git" ] && command -v git >/dev/null 2>&1; then
    git -C "$path" check-ignore -q "$ID_FILE" 2>/dev/null || warn "$slug: git does not ignore $ID_FILE in $path — it would be committed (answer yes below, or ignore it yourself)"
  fi
}
check_one() {
  local dir=$1 path rec rname rpath
  path=$(canon "$dir") || { fail "$dir: not a directory"; row absent - "$dir"; return 1; }
  read_id "$path"; case $? in
    1) info "$path: no $ID_FILE — run: bash $SELF init $dir"; row absent - "$path"; return 0 ;;
    2) fail "$path/$ID_FILE is not the closed shape (id=, name=, created= and nothing else)"; row bad - "$path"; return 1 ;;
  esac
  rec=$(map_lookup "$ID")
  if [ -z "$rec" ]; then
    ok "${NAME_IN:-$ID}: $ID first seen at $path; recorded"; row new "$ID" "$path"
  else
    rname=${rec%%$'\t'*}; rpath=${rec#*$'\t'}; rpath=${rpath%%$'\t'*}
    if same_path "$rpath" "$path"; then
      ok "${NAME_IN:-$rname}: $ID at $path"; row ok "$ID" "$path"
    else
      # the recorded folder still there with the same id is a copy, not a move
      local id nm oid; id=$ID; nm=$NAME_IN; oid=""
      [ -d "$rpath" ] && read_id "$rpath" && oid=$ID
      ID=$id; NAME_IN=$nm
      if [ -n "$oid" ] && [ "$oid" = "$ID" ]; then
        warn "${NAME_IN:-$rname}: $ID is at $rpath too — a copy, not a move; remove $path/$ID_FILE and run init there for an id of its own"
        row copied "$ID" "$path" "$rpath"; return 0
      fi
      warn "${NAME_IN:-$rname}: $ID moved — was at $rpath, now at $path; whatever a harness filed under the old path is still there"
      row moved "$ID" "$path" "$rpath"
    fi
  fi
  map_put "$ID" "${NAME_IN:-$rname}" "$path"
}

[ $PORCELAIN -eq 1 ] || echo "== context retention ($VERB) — $TODAY =="
case "$VERB" in
  init)
    for p in "${PATHS[@]}"; do init_one "$p"; done
    ask_excludes ;;
  check)
    for p in "${PATHS[@]}"; do check_one "$p"; done ;;
  list)
    if [ -f "$MAP" ]; then
      info "$MAP (id, name, last path, last seen):"
      awk -F'\t' '{ printf "  %-28s %-16s %s  %s\n", $1, $2, $3, $4 }' "$MAP"
    else
      info "no map yet at $MAP — run: bash $SELF init"
    fi ;;
esac
[ $PORCELAIN -eq 1 ] || echo "== context retention: $FAIL fail(s), $WARN warning(s) =="
exit $FAIL
