#!/bin/bash
# init.sh — deploy a knowledge-tree instance from this template, or update one.
#
# Usage:
#   init.sh --target <dir> [--conf <file>] [--name <RepositoryName>]
#           [--from <dir|archive.tar.gz>] [--no-private] [--sibling <RepoName>]...
#           [--adapter <name>] [--dry-run]
#   init.sh --update --target <dir> (--ref <tag> | --from <dir|archive.tar.gz>) [--dry-run]
#   init.sh --adopt <module> --target <dir> [--ref <tag> | --from <dir|archive.tar.gz>] [--dry-run]
#   init.sh --help
#
# Install (the first form) copies the skeleton to <dir>, resolves its placeholders from a
# .conf, initialises the private tree as a repository of its own, writes the workspace
# file and records the manifest common/.agentcontext.
#   --target <dir>    the instance: must not exist, or be empty, or hold only a .conf
#   --conf <file>     the .conf to deploy with; default <dir>/.conf. Required keys:
#                     CATALOGS, MY_NAME, MY_NICK, MY_PRONOUNS, MY_ROLE, MY_USER.
#                     PRIVATE_SCOPES absent: written as the catalogs plus journal;
#                     ORCH_BUDGET absent: written as full
#   --name <name>     the repository name; default the basename of <dir>. The workspace
#                     file is <name>.code-workspace
#   --from <src>      the template: a directory holding blueprint/, scripts/, adapters/,
#                     or a .tar.gz of one; default the directory init.sh lives in
#   --no-private      no private tree: private/ is not copied
#   --sibling <name>  add the sibling repository ../<name> to the workspace; repeatable
#   --adapter <name>  lay the payload of adapters/<name>/ onto the instance; with no
#                     flag the adapter list is printed and none is picked
#   --dry-run         print every file it would write, and write nothing
#
# Update (the second form) brings the core files of an instance up to another release:
# common/ (scripts/, rules/, templates/, HYGIENE.md, .conf.example), .vscode/, AGENTS.md,
# README.md and the adapter's payload. A core file edited locally is kept and reported, never
# overwritten; public/, private/, .conf, .gitignore, .gitattributes and the workspace file are
# never touched. The paths a release moved are listed in its MOVES file, one "<old> <new>"
# pair per line (a trailing / for a directory prefix): an untouched file at an old name is
# moved, and its old name removed with any directory it leaves empty, the one deletion the
# deployer makes; an edited one stays at its old name beside the release's copy at the new
# one. When a file is kept, the template's migrations/<version>.md guides are named from the
# instance's release onwards. A manifest at the instance root (an older release) is read
# there and rewritten under common/.
#   --ref <tag>       fetch that release of the upstream repository
#   --from <src>      take the release from a local directory or .tar.gz instead
#   --dry-run         print the report, and write nothing
#
# Adopt (the third form) lays one module of the release into an instance and records it in the
# manifest, a module=<name> line and its files hashed with the core's, so --update refreshes it
# file by file as it does the core. A script module goes whole to common/modules/<name>/, the
# constitution's tree/ to constitution/, the local module's tree/ to private/local/ (an instance
# with a private tree only). A module already in place is recorded, nothing copied, each file
# reported as matching the release or differing from it; one at the old place MOVES names for it
# (a module copied in by hand before the common directory) is moved file by file as an update
# moves the core. The change-log module is refused: its workflow goes into a repository's
# .github/workflows/, never an instance. The source defaults to the directory init.sh lives in.
#   --ref <tag>       fetch the module from that release of the upstream repository
#   --from <src>      take it from a local directory or .tar.gz instead
#   --dry-run         print the report, and write nothing
#
# Exit: 0 done; 2 usage or refusal (the reason on stderr, nothing written); 1 failure
# mid-way (what was written is said).

set -o pipefail

UPSTREAM="https://github.com/AWCostabile/AgentContext"
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TODAY=$(date +%F)
REQUIRED_KEYS="CATALOGS MY_NAME MY_NICK MY_PRONOUNS MY_ROLE MY_USER"
# Top-level public/ branches the skeleton already owns; a catalog may not take their name.
RESERVED_CATALOGS="catalog misc scratch-tools"
# The manifest, and where a release before the common directory left it.
MANIFEST=common/.agentcontext OLD_MANIFEST=.agentcontext

TMPS=()
cleanup() { local d; for d in "${TMPS[@]}"; do rm -rf "$d"; done; }
trap cleanup EXIT
mktmp() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/agentcontext.XXXXXX") || die "cannot create a temporary directory"
  TMPS+=("$d")
  printf '%s' "$d"
}

usage()  { awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"; }
refuse() { printf 'init.sh: %s\n' "$*" >&2; exit 2; }
die()    { printf 'init.sh: failed: %s\n' "$*" >&2; exit 1; }
say()    { printf '%s\n' "$*"; }

# -- arguments ------------------------------------------------------------------
MODE=install TARGET="" CONF="" NAME="" FROM="" REF="" ADAPTER="" ADOPT="" NO_PRIVATE=0 DRY=0
SIBLINGS=()
need_value() { [ $# -ge 2 ] && [ -n "$2" ] || refuse "$1 needs a value (see --help)"; }
one_mode()   { [ "$MODE" = install ] || refuse "--update and --adopt are separate runs (see --help)"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)    usage; exit 0 ;;
    --update)     one_mode; MODE=update ;;
    --adopt)      need_value "$@"; one_mode; MODE=adopt ADOPT=$2; shift ;;
    --target)     need_value "$@"; TARGET=$2; shift ;;
    --conf)       need_value "$@"; CONF=$2; shift ;;
    --name)       need_value "$@"; NAME=$2; shift ;;
    --from)       need_value "$@"; FROM=$2; shift ;;
    --ref)        need_value "$@"; REF=$2; shift ;;
    --adapter)    need_value "$@"; ADAPTER=$2; shift ;;
    --sibling)    need_value "$@"; SIBLINGS+=("$2"); shift ;;
    --no-private) NO_PRIVATE=1 ;;
    --dry-run)    DRY=1 ;;
    *)            refuse "unknown argument: $1 (see --help)" ;;
  esac
  shift
done
[ -n "$TARGET" ] || refuse "--target is required (see --help)"
TARGET=${TARGET%/}
if [ "$MODE" = install ]; then
  [ -z "$REF" ] || refuse "--ref is for --update and --adopt only"
else
  [ -z "$CONF$NAME$ADAPTER" ] && [ $NO_PRIVATE -eq 0 ] && [ ${#SIBLINGS[@]} -eq 0 ] \
    || refuse "--$MODE takes only --target, --ref or --from, and --dry-run"
  if [ "$MODE" = update ]; then
    { [ -n "$REF" ] && [ -z "$FROM" ]; } || { [ -z "$REF" ] && [ -n "$FROM" ]; } \
      || refuse "--update needs exactly one of --ref <tag> and --from <dir|archive.tar.gz>"
  else
    [ -z "$REF" ] || [ -z "$FROM" ] || refuse "--adopt takes at most one of --ref <tag> and --from <dir|archive.tar.gz>"
  fi
  [ -d "$TARGET" ] && { [ -f "$TARGET/$MANIFEST" ] || [ -f "$TARGET/$OLD_MANIFEST" ]; } \
    || refuse "no .agentcontext at target: $TARGET was not deployed by init.sh"
fi

# -- the source -------------------------------------------------------------------
# A release name: an archive or directory called AgentContext-<x> names release <x>;
# a host's tag archive drops a leading v before a digit, so it is put back.
release_name() {
  local n=$1
  n=${n%.tar.gz}; n=${n%.tgz}
  n=${n#AgentContext-}
  case "$n" in [0-9]*) n="v$n" ;; esac
  printf '%s' "$n"
}
# extract_archive <file>: prints the directory holding blueprint/AGENTS.md
extract_archive() {
  local t d
  t=$(mktmp)
  tar --force-local -xzf "$1" -C "$t" 2>/dev/null || refuse "cannot extract $1"
  if [ -f "$t/blueprint/AGENTS.md" ]; then printf '%s' "$t"; return 0; fi
  for d in "$t"/*/; do
    [ -f "$d/blueprint/AGENTS.md" ] && { printf '%s' "${d%/}"; return 0; }
  done
  printf '%s' "$t"
}
SRC_REF=working-tree
if [ -z "$FROM" ] && [ -z "$REF" ]; then
  SRC=$SELF_DIR
elif [ -n "$REF" ]; then
  fetch=$(mktmp)
  say "fetching $UPSTREAM/archive/refs/tags/$REF.tar.gz"
  curl -fsSL "$UPSTREAM/archive/refs/tags/$REF.tar.gz" -o "$fetch/release.tar.gz" \
    || die "cannot fetch release '$REF' (nothing written)"
  SRC=$(extract_archive "$fetch/release.tar.gz")
  SRC_REF=$REF
elif [ -f "$FROM" ]; then
  case "$FROM" in *.tar.gz|*.tgz) ;; *) refuse "--from must be a directory or a .tar.gz: $FROM" ;; esac
  SRC=$(extract_archive "$FROM")
  SRC_REF=$(release_name "$(basename "$FROM")")
elif [ -d "$FROM" ]; then
  SRC=$(cd "$FROM" && pwd)
else
  refuse "--from: no such file or directory: $FROM"
fi
[ -f "$SRC/blueprint/AGENTS.md" ] || refuse "not a template source (no blueprint/AGENTS.md): ${FROM:-$SRC}"
# An extracted release directory (no .git) named AgentContext-<x> names its release.
if [ -z "$REF" ] && [ ! -f "$FROM" ] && [ ! -e "$SRC/.git" ]; then
  case "$(basename "$SRC")" in AgentContext-?*) SRC_REF=$(release_name "$(basename "$SRC")") ;; esac
fi

# -- adapters -----------------------------------------------------------------------
# An adapter is written when its payload/ holds a file other than a top-level README.md.
payload_files() {   # payload_files <adapter dir>: payload paths, relative, README excluded
  local p="$1/payload"
  [ -d "$p" ] || return 0
  (cd "$p" && find . -type f | sed 's|^\./||' | grep -v '^README\.md$' | LC_ALL=C sort)
}
adapter_list() {
  local d n
  for d in "$SRC"/adapters/*/; do
    [ -d "$d" ] || continue
    n=${d%/}; n=${n##*/}
    if [ -n "$(payload_files "${d%/}")" ]; then printf '  %-14s written\n' "$n"
    else printf '  %-14s stub\n' "$n"; fi
  done
}

# -- the core -------------------------------------------------------------------------
# common/ is composed from the skeleton's blueprint/common/ and the repository's scripts/.
CORE_DIRS="common .vscode"
CORE_FILES="AGENTS.md README.md"
# The reader page README.md names the instance: the one core file carrying a placeholder,
# resolved wherever the core is laid, so install and update hash the same bytes.
resolve_tree_name() {   # resolve_tree_name <file> <name>
  local content
  [ -f "$1" ] || return 0
  content=$(<"$1")
  printf '%s\n' "${content//\{\{TREE_NAME\}\}/$2}" > "$1"
}
# lay_core <dest> <adapter> <name>: the core files exactly as install places them
lay_core() {
  local dest=$1 d f
  for d in $CORE_DIRS; do
    [ -d "$SRC/blueprint/$d" ] && { mkdir -p "$dest/$d" && cp -R "$SRC/blueprint/$d/." "$dest/$d/" || return 1; }
  done
  for f in $CORE_FILES; do
    [ -f "$SRC/blueprint/$f" ] && { cp "$SRC/blueprint/$f" "$dest/$f" || return 1; }
  done
  resolve_tree_name "$dest/README.md" "$3" || return 1
  mkdir -p "$dest/common/scripts" && cp -R "$SRC/scripts/." "$dest/common/scripts/" || return 1
  [ -n "$2" ] && { lay_payload "$2" "$dest" || return 1; }
  return 0
}
lay_payload() {   # lay_payload <adapter> <dest>
  local p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    mkdir -p "$2/$(dirname "$p")" && cp "$SRC/adapters/$1/payload/$p" "$2/$p" || return 1
  done < <(payload_files "$SRC/adapters/$1")
}
# core_list <root> <adapter>: the core paths present under <root>, sorted; never the manifest
core_list() {
  local root=$1 d f
  (
    cd "$root" || exit 1
    for d in $CORE_DIRS; do [ -d "$d" ] && find "$d" -type f ! -path "$MANIFEST"; done
    for f in $CORE_FILES; do [ -f "$f" ] && printf '%s\n' "$f"; done
    if [ -n "$2" ]; then
      payload_files "$SRC/adapters/$2" | while IFS= read -r f; do [ -f "$f" ] && printf '%s\n' "$f"; done
    fi
  ) | LC_ALL=C sort -u
}
# hashes <root> < paths: "<sha256>  <path>" lines, sha256sum format, sorted by path
hashes() {
  local list=()
  mapfile -t list
  [ ${#list[@]} -gt 0 ] || return 0
  (cd "$1" && sha256sum -- "${list[@]}") \
    | awk '{ h = $1; print h "  " substr($0, length(h) + 3) }' | LC_ALL=C sort -k2
}

# -- modules ----------------------------------------------------------------------------------
# Where each module is adopted: a script module whole under common/modules/<name>/; a tree
# module's tree/ at its own place, the constitution at the root, the local module in the
# private tree. The change-log module is a repository's workflow and is never adopted.
module_dest() {   # module_dest <name>: its directory in an instance
  case "$1" in
    constitution) printf 'constitution' ;;
    local)        printf 'private/local' ;;
    *)            printf 'common/modules/%s' "$1" ;;
  esac
}
module_src() {    # module_src <name>: the directory of the release that is laid
  case "$1" in
    constitution|local) printf '%s' "$SRC/modules/$1/tree" ;;
    *)                  printf '%s' "$SRC/modules/$1" ;;
  esac
}
has_payload() {   # has_payload <name>: a file other than a top-level README.md to lay
  local s
  s=$(module_src "$1")
  [ -d "$s" ] && (cd "$s" && find . -type f | sed 's|^\./||') | grep -qv '^README\.md$'
}
lay_module() {    # lay_module <name> <dest root>
  local d
  d="$2/$(module_dest "$1")"
  mkdir -p "$d" && cp -R "$(module_src "$1")/." "$d/"
}
module_list() {   # module_list <root> <name>: the module's paths present under <root>, sorted
  local d
  d=$(module_dest "$2")
  [ -d "$1/$d" ] || return 0
  (cd "$1" && find "$d" -type f | LC_ALL=C sort)
}
module_names() {  # the modules of the release, one per line, for a refusal's hint
  local d
  for d in "$SRC"/modules/*/; do [ -d "$d" ] && { d=${d%/}; printf '  %s\n' "${d##*/}"; }; done
}

# -- the manifest ------------------------------------------------------------------------------
# A header of key=value lines (upstream, ref, installed, adapter, one module= per adopted
# module, updated), a blank line, and one "<sha256>  <path>" line per recorded file.
declare -A HEADER RECORDED
MODULES=()
read_manifest() {   # read_manifest <instance>: fills MAN_IN, HEADER, MODULES and RECORDED
  local line body=0
  MAN_IN=$MANIFEST
  [ -f "$1/$MANIFEST" ] || MAN_IN=$OLD_MANIFEST
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    if [ $body -eq 0 ]; then
      [ -z "$line" ] && { body=1; continue; }
      case "$line" in
        module=*) MODULES+=("${line#module=}") ;;
        *)        HEADER[${line%%=*}]=${line#*=} ;;
      esac
    else
      [ -n "$line" ] || continue
      RECORDED[${line:66}]=${line:0:64}
    fi
  done < "$1/$MAN_IN"
}
manifest_header() {   # manifest_header <ref> <installed> <adapter> <updated> [<module>...]
  local ref=$1 installed=$2 adapter=$3 updated=$4 m
  shift 4
  say "upstream=${HEADER[upstream]:-$UPSTREAM}"
  say "ref=$ref"
  say "installed=$installed"
  [ -n "$adapter" ] && say "adapter=$adapter"
  for m in $(printf '%s\n' "$@" | grep -v '^$' | LC_ALL=C sort -u); do say "module=$m"; done
  [ -n "$updated" ] && say "updated=$updated"
  say ""
}

# -- MOVES ---------------------------------------------------------------------------------------
MV_OLD=() MV_NEW=()
read_moves() {   # the release's "<old> <new>" pairs, comments and blank lines skipped
  local o n _
  [ -f "$SRC/MOVES" ] || return 0
  while read -r o n _ || [ -n "$o" ]; do
    case "$o" in ''|'#'*) continue ;; esac
    MV_OLD+=("$o"); MV_NEW+=("${n%$'\r'}")
  done < "$SRC/MOVES"
}
moved_path() {   # moved_path <path>: its name in this release, through MOVES
  local p=$1 i o
  for i in "${!MV_OLD[@]}"; do
    o=${MV_OLD[$i]}
    case "$o" in
      */) case "$p" in "$o"*) p=${MV_NEW[$i]}${p#"$o"} ;; esac ;;
      *)  [ "$p" = "$o" ] && p=${MV_NEW[$i]} ;;
    esac
  done
  printf '%s' "$p"
}
old_path() {     # old_path <dir>: the directory a directory pair of MOVES moved to <dir>, else nothing
  local d="$1/" i o n
  for i in "${!MV_OLD[@]}"; do
    o=${MV_OLD[$i]} n=${MV_NEW[$i]}
    [ "${o%/}" != "$o" ] && [ "${n%/}" != "$n" ] || continue
    case "$d" in "$n"*) d=$o${d#"$n"}; printf '%s' "${d%/}"; return 0 ;; esac
  done
}
read_moves

# =====================================================================================
# update
# =====================================================================================
if [ "$MODE" = update ]; then
  TARGET=$(cd "$TARGET" && pwd)
  declare -A UP LOCAL MOVED_TO
  read_manifest "$TARGET"
  INST_ADAPTER=${HEADER[adapter]:-}
  # the instance's name: its workspace file's, else the directory's
  INST_NAME=""
  for w in "$TARGET"/*.code-workspace; do
    [ -f "$w" ] && { INST_NAME=$(basename "$w" .code-workspace); break; }
  done
  [ -n "$INST_NAME" ] || INST_NAME=$(basename "$TARGET")

  UPDIR=$(mktmp)
  lay_core "$UPDIR" "$INST_ADAPTER" "$INST_NAME" || die "cannot lay out the release's core files (nothing written)"
  # an adopted module rides beside the core, file by file; one the release dropped is
  # reported once, and its files as any file the release no longer ships
  MODS_OUT=()
  for m in "${MODULES[@]}"; do
    if has_payload "$m"; then
      lay_module "$m" "$UPDIR" || die "cannot lay out module $m (nothing written)"
      MODS_OUT+=("$m")
    else
      say "removed-upstream module $m (its files stay)"
    fi
  done
  while IFS= read -r l; do UP[${l:66}]=${l:0:64}; done < <(
    { core_list "$UPDIR" "$INST_ADAPTER"; for m in "${MODS_OUT[@]}"; do module_list "$UPDIR" "$m"; done; } \
      | LC_ALL=C sort -u | hashes "$UPDIR")
  present=()
  for p in "${!RECORDED[@]}" "${!UP[@]}"; do [ -f "$TARGET/$p" ] && present+=("$p"); done
  while IFS= read -r l; do
    [ -n "$l" ] && LOCAL[${l:66}]=${l:0:64}
  done < <(printf '%s\n' "${present[@]}" | LC_ALL=C sort -u | grep -v '^$' | hashes "$TARGET")

  n_mv=0 n_rep=0 n_kept=0 n_add=0 n_rm=0 n_rootkept=0
  WRITE=() NEWHASH=() UNLINK=()
  kept() {   # kept <path> <reason>: a kept file reported; a root document counted
    say "kept $1 ($2)"; n_kept=$((n_kept + 1))
    case "$1" in */*) ;; *.md) n_rootkept=$((n_rootkept + 1)) ;; esac
  }

  # -- the move rule: a recorded path the release moved (MOVES) goes to its new name first
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    q=$(moved_path "$p")
    [ "$q" != "$p" ] || continue
    rec=${RECORDED[$p]} up=${UP[$q]:-} loc=${LOCAL[$p]:-}
    unset "RECORDED[$p]"                          # the manifest records new names only
    if [ -z "$up" ]; then say "removed-upstream $p"; n_rm=$((n_rm + 1)); continue; fi
    [ -n "$loc" ] || continue                     # deleted locally: added at the new name below
    if [ -f "$TARGET/$q" ]; then kept "$p" "moved to $q, which exists locally"; continue; fi
    MOVED_TO[$q]=$p; WRITE+=("$q"); NEWHASH+=("$up  $q")
    if [ "$loc" = "$rec" ]; then
      say "moved $p -> $q"; n_mv=$((n_mv + 1)); UNLINK+=("$p")
    else
      kept "$p" "changed locally; moved to $q"
    fi
  done < <(printf '%s\n' "${!RECORDED[@]}" | LC_ALL=C sort)

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -z "${MOVED_TO[$p]:-}" ] || continue        # written by the move rule above
    rec=${RECORDED[$p]:-} up=${UP[$p]:-} loc=${LOCAL[$p]:-}
    if [ -n "$rec" ] && [ -z "$up" ]; then
      say "removed-upstream $p"; n_rm=$((n_rm + 1)); continue
    fi
    if [ -z "$rec" ]; then
      if [ -z "$loc" ] || [ "$loc" = "$up" ]; then
        say "added $p"; n_add=$((n_add + 1)); [ -z "$loc" ] && WRITE+=("$p")
      else
        kept "$p" "exists locally"
      fi
      NEWHASH+=("$up  $p"); continue
    fi
    if [ "$loc" = "$up" ]; then
      NEWHASH+=("$up  $p")                            # identical: silent
    elif [ "$loc" = "$rec" ]; then
      say "replaced $p"; n_rep=$((n_rep + 1)); WRITE+=("$p"); NEWHASH+=("$up  $p")
    else
      if [ -z "$loc" ]; then kept "$p" "deleted locally"; else kept "$p" "changed locally"; fi
      NEWHASH+=("$rec  $p")                           # the last pristine version stays recorded
    fi
  done < <(printf '%s\n' "${!RECORDED[@]}" "${!UP[@]}" | LC_ALL=C sort -u)
  summary="update: $n_mv moved, $n_rep replaced, $n_kept kept, $n_add added, $n_rm removed-upstream"

  # -- what a kept file asks of the user: the linter, and the migration guides
  # A guide is named for the release it leaves; those from the instance's release up to the
  # source's apply. Only a release names a version: a working-tree ref names none.
  ver_lt() { [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n 1)" = "$1" ]; }
  advice() {
    [ $n_mv -gt 0 ] && [ $n_rootkept -gt 0 ] \
      && say "run bash common/scripts/cure.sh: $n_rootkept kept file(s) may name moved paths"
    [ $n_kept -gt 0 ] || return 0
    local from=${HEADER[ref]:-} to="" g v
    case "$from" in v[0-9]*) from=${from#v} ;; *) return 0 ;; esac
    case "$SRC_REF" in v[0-9]*) to=${SRC_REF#v} ;; esac
    while IFS= read -r v; do
      ver_lt "$v" "$from" && continue
      [ -n "$to" ] && ! ver_lt "$v" "$to" && continue
      say "guide: migrations/$v.md"
    done < <(for g in "$SRC"/migrations/[0-9]*.md; do [ -f "$g" ] && basename "$g" .md; done | sort -V)
  }
  if [ $DRY -eq 1 ]; then
    say "$summary"
    advice
    say "dry-run: nothing written to $TARGET"
    exit 0
  fi
  done_n=0
  for p in "${WRITE[@]}"; do
    { mkdir -p "$TARGET/$(dirname "$p")" && cp "$UPDIR/$p" "$TARGET/$p"; } \
      || die "writing $p; $done_n file(s) before it were written, the manifest was not rewritten"
    done_n=$((done_n + 1))
  done
  manifest_tmp="$TARGET/$MANIFEST.tmp"
  mkdir -p "$TARGET/$(dirname "$MANIFEST")" || die "creating $(dirname "$MANIFEST")/; $done_n core file(s) were written"
  {
    manifest_header "$SRC_REF" "${HEADER[installed]:-unknown}" "$INST_ADAPTER" "$TODAY" "${MODS_OUT[@]}"
    printf '%s\n' "${NEWHASH[@]}" | LC_ALL=C sort -k2
  } > "$manifest_tmp" && mv "$manifest_tmp" "$TARGET/$MANIFEST" \
    || die "rewriting $MANIFEST; $done_n core file(s) were written"
  if [ "$MAN_IN" != "$MANIFEST" ]; then
    rm -f "$TARGET/$MAN_IN" || die "removing the old $MAN_IN; $MANIFEST is written"
  fi
  # The one deletion the deployer makes: an old name whose file was the recorded one,
  # then any directory that leaves empty.
  for p in "${UNLINK[@]}"; do
    rm -f "$TARGET/$p" || die "removing $p; $MANIFEST is written"
    d=$(dirname "$p")
    while [ "$d" != . ] && rmdir "$TARGET/$d" 2>/dev/null; do d=$(dirname "$d"); done
  done
  say "$summary"
  advice
  nmod=0
  for l in "${NEWHASH[@]}"; do
    for m in "${MODS_OUT[@]}"; do
      case "${l:66}" in "$(module_dest "$m")"/*) nmod=$((nmod + 1)); break ;; esac
    done
  done
  say "manifest: ref=$SRC_REF, $((${#NEWHASH[@]} - nmod)) core files${MODS_OUT[*]:+, $nmod module files (${MODS_OUT[*]})}"
  exit 0
fi

# =====================================================================================
# adopt
# =====================================================================================
if [ "$MODE" = adopt ]; then
  TARGET=$(cd "$TARGET" && pwd)
  read_manifest "$TARGET"
  [ "$MAN_IN" = "$MANIFEST" ] \
    || refuse "the manifest is at the instance root, as an older release left it: update the instance to this release first (init.sh --update)"
  case "$ADOPT" in
    change-log) refuse "module 'change-log' is never adopted into an instance: copy its post-merge.yml into each repository's .github/workflows/ (SETUP.md, the change-log step)" ;;
    .|..|*/*|*\\*) refuse "--adopt: not a module name: '$ADOPT'" ;;
  esac
  if [ ! -d "$SRC/modules/$ADOPT" ]; then
    { say "modules in this release:"; module_names; } >&2
    refuse "unknown module '$ADOPT'"
  fi
  has_payload "$ADOPT" || refuse "module '$ADOPT' has no payload in this release"
  DEST=$(module_dest "$ADOPT")
  case "$DEST" in
    private/*) [ -d "$TARGET/private" ] || refuse "module '$ADOPT' goes into the private tree, and $TARGET has none" ;;
  esac
  for m in "${MODULES[@]}"; do
    [ "$m" = "$ADOPT" ] && refuse "module '$ADOPT' is already recorded in $MANIFEST: --update refreshes it"
  done

  # The release's copy is staged whole and hashed before anything is written. The module is
  # then fresh (nothing there), present (its directory exists: recorded, nothing copied), or at
  # the old place MOVES names for its directory (moved file by file, as an update moves the core).
  STAGE=$(mktmp)
  lay_module "$ADOPT" "$STAGE" || die "cannot lay out module $ADOPT (nothing written)"
  HASHES=$(module_list "$STAGE" "$ADOPT" | hashes "$STAGE")
  OLDDEST=$(old_path "$DEST")
  if [ -d "$TARGET/$DEST" ]; then how=present
  elif [ -n "$OLDDEST" ] && [ -d "$TARGET/$OLDDEST" ]; then how=old
  else how=fresh; fi
  WRITE=() UNLINK=()
  n_files=0 n_match=0 n_diff=0 n_miss=0 n_mv=0 n_kept=0 n_add=0
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    h=${l:0:64} p=${l:66}; n_files=$((n_files + 1))
    case "$how" in
      fresh) WRITE+=("$p") ;;
      present)
        if [ ! -f "$TARGET/$p" ]; then say "missing $p"; n_miss=$((n_miss + 1))
        elif [ "$(sha256sum < "$TARGET/$p" | cut -c1-64)" = "$h" ]; then say "matches $p"; n_match=$((n_match + 1))
        else say "differs $p"; n_diff=$((n_diff + 1)); fi ;;
      old)
        o=$OLDDEST${p#"$DEST"}
        if [ ! -f "$TARGET/$o" ]; then say "added $p"; n_add=$((n_add + 1)); WRITE+=("$p")
        elif [ "$(sha256sum < "$TARGET/$o" | cut -c1-64)" = "$h" ]; then
          say "moved $o -> $p"; n_mv=$((n_mv + 1)); WRITE+=("$p"); UNLINK+=("$o")
        else
          say "kept $o (differs from the release; moved to $p)"; n_kept=$((n_kept + 1)); WRITE+=("$p")
        fi ;;
    esac
  done <<< "$HASHES"
  case "$how" in
    fresh)   summary="adopted $ADOPT: $n_files file(s) laid at $DEST/" ;;
    present) summary="recorded $ADOPT, already at $DEST/: $n_match match, $n_diff differ, $n_miss missing (nothing copied)" ;;
    old)     summary="adopted $ADOPT from $OLDDEST/: $n_mv moved, $n_kept kept, $n_add added" ;;
  esac
  NEWMAN="$STAGE/.manifest"
  {
    manifest_header "${HEADER[ref]:-unknown}" "${HEADER[installed]:-unknown}" "${HEADER[adapter]:-}" \
      "${HEADER[updated]:-}" "${MODULES[@]}" "$ADOPT"
    { for p in "${!RECORDED[@]}"; do
        case "$p" in "$DEST"/*) continue ;; esac   # the release's hashes stand for the module
        printf '%s  %s\n' "${RECORDED[$p]}" "$p"
      done
      printf '%s\n' "$HASHES"; } | grep -v '^$' | LC_ALL=C sort -k2
  } > "$NEWMAN" || die "staging the manifest (nothing written)"
  if [ $DRY -eq 1 ]; then
    for p in "${WRITE[@]}"; do say "would write $TARGET/$p"; done
    say "$summary"
    say "dry-run: nothing written to $TARGET"
    exit 0
  fi
  done_n=0
  for p in "${WRITE[@]}"; do
    { mkdir -p "$TARGET/$(dirname "$p")" && cp "$STAGE/$p" "$TARGET/$p"; } \
      || die "writing $p; $done_n file(s) before it were written, the manifest was not rewritten"
    done_n=$((done_n + 1))
  done
  cp "$NEWMAN" "$TARGET/$MANIFEST.tmp" && mv "$TARGET/$MANIFEST.tmp" "$TARGET/$MANIFEST" \
    || die "rewriting $MANIFEST; $done_n module file(s) were written"
  for p in "${UNLINK[@]}"; do   # as the move rule: an old name whose file was the release's
    rm -f "$TARGET/$p" || die "removing $p; $MANIFEST is written"
    d=$(dirname "$p")
    while [ "$d" != . ] && rmdir "$TARGET/$d" 2>/dev/null; do d=$(dirname "$d"); done
  done
  say "$summary"
  say "manifest: module=$ADOPT, $n_files file(s) hashed"
  exit 0
fi

# =====================================================================================
# install
# =====================================================================================

# -- the target and the .conf --------------------------------------------------------
if [ -e "$TARGET" ]; then
  [ -d "$TARGET" ] || refuse "target is not empty: $TARGET is a file"
  others=$(cd "$TARGET" && ls -A | grep -v '^\.conf$' | head -n 5 | tr '\n' ' ')
  [ -z "$others" ] || refuse "target is not empty: $TARGET holds ${others% }"
fi
if [ -z "$CONF" ]; then
  [ -f "$TARGET/.conf" ] || refuse "no .conf: copy blueprint/common/.conf.example, fill it, pass --conf"
  CONF="$TARGET/.conf"
fi
[ -f "$CONF" ] || refuse "no .conf: $CONF does not exist; copy blueprint/common/.conf.example, fill it, pass --conf"
[ -n "$NAME" ] || NAME=$(basename "$TARGET")
case "$NAME" in ''|.|..|*/*|*\\*|*\"*) refuse "--name: not a repository name: '$NAME'" ;; esac
for s in "${SIBLINGS[@]}"; do
  case "$s" in *[!A-Za-z0-9._-]*|.|..) refuse "--sibling: not a repository name: '$s'" ;; esac
done

STAGE=$(mktmp)
cp "$CONF" "$STAGE/.conf" || die "cannot read $CONF"
ROOT=$STAGE
. "$SRC/scripts/lib-scopes.sh" || refuse "the source has no readable scripts/lib-scopes.sh"
for k in $REQUIRED_KEYS; do
  [ -n "$(conf_key "$k" | tr -d '[:space:]')" ] || refuse "missing key $k in $CONF"
done
mapfile -t CATS < <(catalogs)
declare -A SEEN
for c in "${CATS[@]}"; do
  case "$c" in [a-z0-9]*) ;; *) refuse "CATALOGS: '$c' is not a lowercase name ([a-z0-9-])" ;; esac
  case "$c" in *[!a-z0-9-]*) refuse "CATALOGS: '$c' is not a lowercase name ([a-z0-9-])" ;; esac
  case " $RESERVED_CATALOGS " in *" $c "*) refuse "CATALOGS: '$c' is a reserved branch name" ;; esac
  [ -z "${SEEN[$c]:-}" ] || refuse "CATALOGS: '$c' is named twice"
  SEEN[$c]=1
done

if [ -n "$ADAPTER" ]; then
  if [ ! -d "$SRC/adapters/$ADAPTER" ] || [ -z "$(payload_files "$SRC/adapters/$ADAPTER")" ]; then
    { say "adapters in this release:"; adapter_list; } >&2
    refuse "adapter '$ADAPTER' has no payload in this release"
  fi
fi

# -- copy ---------------------------------------------------------------------------
cp -R "$SRC/blueprint/." "$STAGE/" || die "copying the skeleton (nothing written)"
cp "$CONF" "$STAGE/.conf" || die "cannot read $CONF"   # a .conf.example never shadows it
resolve_tree_name "$STAGE/README.md" "$NAME" || die "naming the reader page (nothing written)"
[ $NO_PRIVATE -eq 1 ] && rm -rf "$STAGE/private"
mkdir -p "$STAGE/common/scripts" && cp -R "$SRC/scripts/." "$STAGE/common/scripts/" || die "copying scripts/ (nothing written)"
COPIED=$(cd "$STAGE" && find . -type f ! -name .conf ! -name workspace.code-workspace | wc -l | tr -d ' ')

TREES="public"
[ -d "$STAGE/private" ] && TREES="public private"

# edit_file <file> <awk program> [awk args...]: rewrite a file in place through awk
edit_file() {
  local f=$1 prog=$2
  shift 2
  awk "$@" "$prog" "$f" > "$f.tmp" && mv "$f.tmp" "$f" || die "editing $f in the staging copy (nothing written)"
}
AWK_REPL='function repl(s, a, b,   i, out) {
  out = ""
  while ((i = index(s, a)) > 0) { out = out substr(s, 1, i - 1) b; s = substr(s, i + length(a)) }
  return out s
}'

# -- {{catalog}} / {{Catalog}}: one branch per CATALOGS entry ---------------------------
for tree in $TREES; do
  [ -d "$STAGE/$tree/catalog" ] || continue
  for c in "${CATS[@]}"; do
    C="$(printf '%s' "${c:0:1}" | tr '[:lower:]' '[:upper:]')${c:1}"
    cp -R "$STAGE/$tree/catalog" "$STAGE/$tree/$c" || die "copying $tree/catalog (nothing written)"
    while IFS= read -r -d '' f; do
      edit_file "$f" "$AWK_REPL"' { print repl(repl($0, "{{catalog}}", c), "{{Catalog}}", C) }' -v c="$c" -v C="$C"
    done < <(find "$STAGE/$tree/$c" -type f -print0)
  done
  rm -rf "$STAGE/$tree/catalog"
  # the one row linking ./{{catalog}}/.index.md becomes one row per entry, in CATALOGS order
  edit_file "$STAGE/$tree/.index.md" "$AWK_REPL"'
    index($0, "](./{{catalog}}/.index.md)") > 0 {
      n = split(cats, cs, " ")
      for (i = 1; i <= n; i++) {
        C = toupper(substr(cs[i], 1, 1)) substr(cs[i], 2)
        print repl(repl($0, "{{catalog}}", cs[i]), "{{Catalog}}", C)
      }
      next
    }
    { print }' -v cats="${CATS[*]}"
done

# -- the rest of the placeholder table, over the trees ---------------------------------
while IFS= read -r -d '' f; do
  case "$f" in
    */.tags)
      grep -v '{{' "$f" > "$f.tmp"
      [ -s "$f.tmp" ] || { d=${f%/.tags}; printf '%s\n' "${d##*/}" > "$f.tmp"; }
      mv "$f.tmp" "$f" || die "editing $f in the staging copy (nothing written)"
      continue ;;
  esac
  # a leading set-up comment; a Contents row whose link target is a placeholder;
  # the install date; the status page's four fields
  edit_file "$f" "$AWK_REPL"'
    NR == 1 && /^<!--/ { incomment = 1 }
    incomment { if (index($0, "-->") > 0) { incomment = 0; skipblank = 1 } next }
    skipblank && /^[[:space:]]*$/ { next }
    { skipblank = 0 }
    /^\|/ && match($0, /\]\([^)]*\{\{/) { next }
    { line = repl($0, "{{YYYY-MM-DD}}", today) }
    index(line, "{{") > 0 {
      if (index(line, "**In flux:**") == 1)          line = "**In flux:** nothing yet"
      else if (index(line, "**Last landed:**") == 1) line = "**Last landed:** nothing yet"
      else if (index(line, "**Next open:**") == 1)   line = "**Next open:** nothing yet"
      else if (index(line, "**Unpushed branches:**") == 1) line = "**Unpushed branches:** none"
    }
    { print line }' -v today="$TODAY"
done < <(cd "$STAGE" && for t in $TREES; do find "$STAGE/$t" -type f \( -name '*.md' -o -name '.tags' -o -name '.agent' \) -print0; done)

# -- the workspace file: the folders array regenerated, the sibling folder kept only on request
WS_SRC="$STAGE/workspace.code-workspace"
WS="$STAGE/$NAME.code-workspace"
[ -f "$WS_SRC" ] || die "the skeleton has no workspace.code-workspace (nothing written)"
FOLDERS=()
while IFS=$'\t' read -r fname fpath; do
  case "$fpath" in
    *'{{REPOSITORY_NAME}}'*)
      for s in "${SIBLINGS[@]}"; do FOLDERS+=("${fname//\{\{REPOSITORY_NAME\}\}/$s}"$'\t'"${fpath//\{\{REPOSITORY_NAME\}\}/$s}"); done ;;
    ./private|./private/) [ $NO_PRIVATE -eq 0 ] && FOLDERS+=("$fname"$'\t'"$fpath") ;;
    *) FOLDERS+=("$fname"$'\t'"$fpath") ;;
  esac
done < <(awk '
  /"folders"[[:space:]]*:/ { infolders = 1; next }
  infolders && /"name"[[:space:]]*:/ { n = $0; sub(/^[^:]*:[[:space:]]*"/, "", n); sub(/".*$/, "", n) }
  infolders && /"path"[[:space:]]*:/ { p = $0; sub(/^[^:]*:[[:space:]]*"/, "", p); sub(/".*$/, "", p); print n "\t" p }
' "$WS_SRC")
{
  awk '/"folders"[[:space:]]*:/ { print "  \"folders\": ["; exit } { print }' "$WS_SRC"
  for i in "${!FOLDERS[@]}"; do
    sep=","; [ "$i" -eq $((${#FOLDERS[@]} - 1)) ] && sep=""
    printf '    {\n      "name": "%s",\n      "path": "%s"\n    }%s\n' "${FOLDERS[$i]%%$'\t'*}" "${FOLDERS[$i]#*$'\t'}" "$sep"
  done
  printf '  ]\n}\n'
} > "$WS.tmp" && rm -f "$WS_SRC" && mv "$WS.tmp" "$WS" || die "writing the workspace file (nothing written)"

# -- the instance's own root files and the derived .conf keys -------------------------
printf '%s\n' "# This machine's development-cycle tree: a repository of its own." "/private/" \
  "# This machine's settings: who the user is and what search covers." "/.conf" > "$STAGE/.gitignore"
printf '%s\n' "* text=auto eol=lf" > "$STAGE/.gitattributes"
if ! conf_has_key PRIVATE_SCOPES || ! conf_has_key ORCH_BUDGET; then
  [ -n "$(tail -c 1 "$STAGE/.conf")" ] && printf '\n' >> "$STAGE/.conf"
  printf '\n' >> "$STAGE/.conf"
fi
if ! conf_has_key PRIVATE_SCOPES; then
  printf '%s\n' "# Derived by init.sh: the catalogs plus the journal." \
    "PRIVATE_SCOPES=\"${CATS[*]} journal\"" >> "$STAGE/.conf"
fi
if ! conf_has_key ORCH_BUDGET; then
  printf '%s\n' "# Derived by init.sh: the reference practice." "ORCH_BUDGET=full" >> "$STAGE/.conf"
fi

# -- the adapter's payload --------------------------------------------------------------
[ -n "$ADAPTER" ] && { lay_payload "$ADAPTER" "$STAGE" || die "copying the payload of '$ADAPTER' (nothing written)"; }

# -- no placeholder may remain outside templates/ ---------------------------------------
# The trees allow no braces at all (the smell linter's S09). The root documents name the
# placeholder syntax itself in prose, so there a placeholder is a {{ followed by a letter.
residue=$(
  cd "$STAGE" || exit 1
  for t in $TREES; do grep -rlE '\{\{|\}\}' "$t"; done
  grep -rlE '\{\{[A-Za-z]' --exclude-dir=templates --exclude-dir=public --exclude-dir=private .
)
[ -z "$residue" ] || die "deployer defect, placeholders left in: $(printf '%s' "$residue" | tr '\n' ' ')(nothing written)"

# -- the manifest ------------------------------------------------------------------------
CORE=$(core_list "$STAGE" "$ADAPTER" | hashes "$STAGE")
NCORE=$(printf '%s\n' "$CORE" | grep -c .)
{
  manifest_header "$SRC_REF" "$TODAY" "$ADAPTER" ""
  printf '%s\n' "$CORE"
} > "$STAGE/$MANIFEST"

# -- report, or write ----------------------------------------------------------------------
report() {
  say "copied $COPIED files"
  say "catalogs: ${CATS[*]}"
  if [ $NO_PRIVATE -eq 1 ]; then say "private: skipped"; else say "private: initialised"; fi
  say "workspace: $NAME.code-workspace"
  say "manifest: $NCORE core files"
  [ -n "$ADAPTER" ] && say "adapter: $ADAPTER"
}
if [ $DRY -eq 1 ]; then
  (cd "$STAGE" && find . -type f | sed 's|^\./||' | LC_ALL=C sort) | while IFS= read -r f; do
    say "would write $TARGET/$f"
  done
  report | sed 's/^private: initialised$/private: would be initialised/'
  say "dry-run: nothing written to $TARGET"
else
  if [ $NO_PRIVATE -eq 0 ]; then
    git -C "$STAGE/private" init -q -b main 2>/dev/null \
      || { git -C "$STAGE/private" init -q && git -C "$STAGE/private" symbolic-ref HEAD refs/heads/main; } \
      || die "git init in private/ (nothing written)"
  fi
  mkdir -p "$TARGET" || die "cannot create $TARGET (nothing written)"
  cp -R "$STAGE/." "$TARGET/" \
    || die "copying into $TARGET; a partial instance may be there: remove it and run again"
  report
  say "done: $TARGET"
fi
if [ -z "$ADAPTER" ]; then
  say "adapters (none laid down; pass --adapter <name> for a written one):"
  adapter_list
fi
exit 0
