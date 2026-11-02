#!/bin/bash
# init.sh — deploy a knowledge-tree instance from this template, or update one.
#
# Usage:
#   init.sh --target <dir> [--conf <file>] [--name <RepositoryName>]
#           [--from <dir|archive.tar.gz>] [--no-private] [--sibling <RepoName>]...
#           [--adapter <name>] [--dry-run]
#   init.sh --update --target <dir> (--ref <tag> | --from <dir|archive.tar.gz>) [--dry-run]
#   init.sh --help
#
# Install (the first form) copies the skeleton to <dir>, resolves its placeholders from a
# .conf, initialises the private tree as a repository of its own, writes the workspace
# file and records the manifest .agentcontext.
#   --target <dir>    the instance: must not exist, or be empty, or hold only a .conf
#   --conf <file>     the .conf to deploy with; default <dir>/.conf. Required keys:
#                     CATALOGS, MY_NAME, MY_NICK, MY_PRONOUNS, MY_ROLE, MY_USER.
#                     PRIVATE_SCOPES absent: written as the catalogs plus journal;
#                     ORCH_BUDGET absent: written as full
#   --name <name>     the repository name; default the basename of <dir>. The workspace
#                     file is <name>.code-workspace
#   --from <src>      the template: a directory holding template/, scripts/, adapters/,
#                     or a .tar.gz of one; default the directory init.sh lives in
#   --no-private      no private tree: private/ is not copied
#   --sibling <name>  add the sibling repository ../<name> to the workspace; repeatable
#   --adapter <name>  lay the payload of adapters/<name>/ onto the instance; with no
#                     flag the adapter list is printed and none is picked
#   --dry-run         print every file it would write, and write nothing
#
# Update (the second form) brings the core files of an instance up to another release:
# scripts/, rules/, templates/, .vscode/, AGENTS.md, HYGIENE.md, README.md, .conf.example
# and the adapter's payload. A core file edited locally is kept and reported, never overwritten;
# public/, private/, .conf, .gitignore, .gitattributes and the workspace file are never
# touched.
#   --ref <tag>       fetch that release of the upstream repository
#   --from <src>      take the release from a local directory or .tar.gz instead
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
MODE=install TARGET="" CONF="" NAME="" FROM="" REF="" ADAPTER="" NO_PRIVATE=0 DRY=0
SIBLINGS=()
need_value() { [ $# -ge 2 ] && [ -n "$2" ] || refuse "$1 needs a value (see --help)"; }
while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)    usage; exit 0 ;;
    --update)     MODE=update ;;
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
  [ -z "$REF" ] || refuse "--ref is for --update only"
else
  [ -z "$CONF$NAME$ADAPTER" ] && [ $NO_PRIVATE -eq 0 ] && [ ${#SIBLINGS[@]} -eq 0 ] \
    || refuse "--update takes only --target, --ref or --from, and --dry-run"
  { [ -n "$REF" ] && [ -z "$FROM" ]; } || { [ -z "$REF" ] && [ -n "$FROM" ]; } \
    || refuse "--update needs exactly one of --ref <tag> and --from <dir|archive.tar.gz>"
  [ -d "$TARGET" ] && [ -f "$TARGET/.agentcontext" ] \
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
# extract_archive <file>: prints the directory holding template/AGENTS.md
extract_archive() {
  local t d
  t=$(mktmp)
  tar --force-local -xzf "$1" -C "$t" 2>/dev/null || refuse "cannot extract $1"
  if [ -f "$t/template/AGENTS.md" ]; then printf '%s' "$t"; return 0; fi
  for d in "$t"/*/; do
    [ -f "$d/template/AGENTS.md" ] && { printf '%s' "${d%/}"; return 0; }
  done
  printf '%s' "$t"
}
SRC_REF=working-tree
if [ -z "$FROM" ] && [ "$MODE" = install ]; then
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
[ -f "$SRC/template/AGENTS.md" ] || refuse "not a template source (no template/AGENTS.md): ${FROM:-$SRC}"
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
CORE_DIRS="scripts rules templates .vscode"
CORE_FILES="AGENTS.md HYGIENE.md README.md .conf.example"
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
    [ -d "$SRC/template/$d" ] && { mkdir -p "$dest/$d" && cp -R "$SRC/template/$d/." "$dest/$d/" || return 1; }
  done
  for f in $CORE_FILES; do
    [ -f "$SRC/template/$f" ] && { cp "$SRC/template/$f" "$dest/$f" || return 1; }
  done
  resolve_tree_name "$dest/README.md" "$3" || return 1
  mkdir -p "$dest/scripts" && cp -R "$SRC/scripts/." "$dest/scripts/" || return 1
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
# core_list <root> <adapter>: the core paths present under <root>, sorted
core_list() {
  local root=$1 d f
  (
    cd "$root" || exit 1
    for d in $CORE_DIRS; do [ -d "$d" ] && find "$d" -type f; done
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

# =====================================================================================
# update
# =====================================================================================
if [ "$MODE" = update ]; then
  TARGET=$(cd "$TARGET" && pwd)
  declare -A RECORDED UP LOCAL HEADER
  body=0
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    if [ $body -eq 0 ]; then
      [ -z "$line" ] && { body=1; continue; }
      HEADER[${line%%=*}]=${line#*=}
    else
      [ -n "$line" ] || continue
      RECORDED[${line:66}]=${line:0:64}
    fi
  done < "$TARGET/.agentcontext"
  INST_ADAPTER=${HEADER[adapter]:-}
  # the instance's name: its workspace file's, else the directory's
  INST_NAME=""
  for w in "$TARGET"/*.code-workspace; do
    [ -f "$w" ] && { INST_NAME=$(basename "$w" .code-workspace); break; }
  done
  [ -n "$INST_NAME" ] || INST_NAME=$(basename "$TARGET")

  UPDIR=$(mktmp)
  lay_core "$UPDIR" "$INST_ADAPTER" "$INST_NAME" || die "cannot lay out the release's core files (nothing written)"
  while IFS= read -r l; do UP[${l:66}]=${l:0:64}; done < <(core_list "$UPDIR" "$INST_ADAPTER" | hashes "$UPDIR")
  present=()
  for p in "${!RECORDED[@]}" "${!UP[@]}"; do [ -f "$TARGET/$p" ] && present+=("$p"); done
  while IFS= read -r l; do
    [ -n "$l" ] && LOCAL[${l:66}]=${l:0:64}
  done < <(printf '%s\n' "${present[@]}" | LC_ALL=C sort -u | grep -v '^$' | hashes "$TARGET")

  n_rep=0 n_kept=0 n_add=0 n_rm=0
  WRITE=() NEWHASH=()
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    rec=${RECORDED[$p]:-} up=${UP[$p]:-} loc=${LOCAL[$p]:-}
    if [ -n "$rec" ] && [ -z "$up" ]; then
      say "removed-upstream $p"; n_rm=$((n_rm + 1)); continue
    fi
    if [ -z "$rec" ]; then
      if [ -z "$loc" ] || [ "$loc" = "$up" ]; then
        say "added $p"; n_add=$((n_add + 1)); [ -z "$loc" ] && WRITE+=("$p")
      else
        say "kept $p (exists locally)"; n_kept=$((n_kept + 1))
      fi
      NEWHASH+=("$up  $p"); continue
    fi
    if [ "$loc" = "$up" ]; then
      NEWHASH+=("$up  $p")                            # identical: silent
    elif [ "$loc" = "$rec" ]; then
      say "replaced $p"; n_rep=$((n_rep + 1)); WRITE+=("$p"); NEWHASH+=("$up  $p")
    else
      if [ -z "$loc" ]; then say "kept $p (deleted locally)"; else say "kept $p (changed locally)"; fi
      n_kept=$((n_kept + 1)); NEWHASH+=("$rec  $p")   # the last pristine version stays recorded
    fi
  done < <(printf '%s\n' "${!RECORDED[@]}" "${!UP[@]}" | LC_ALL=C sort -u)
  summary="update: $n_rep replaced, $n_kept kept, $n_add added, $n_rm removed-upstream"
  if [ $DRY -eq 1 ]; then
    say "$summary"
    say "dry-run: nothing written to $TARGET"
    exit 0
  fi
  done_n=0
  for p in "${WRITE[@]}"; do
    { mkdir -p "$TARGET/$(dirname "$p")" && cp "$UPDIR/$p" "$TARGET/$p"; } \
      || die "writing $p; $done_n file(s) before it were written, the manifest was not rewritten"
    done_n=$((done_n + 1))
  done
  manifest_tmp="$TARGET/.agentcontext.tmp"
  {
    say "upstream=${HEADER[upstream]:-$UPSTREAM}"
    say "ref=$SRC_REF"
    say "installed=${HEADER[installed]:-unknown}"
    [ -n "$INST_ADAPTER" ] && say "adapter=$INST_ADAPTER"
    say "updated=$TODAY"
    say ""
    printf '%s\n' "${NEWHASH[@]}" | LC_ALL=C sort -k2
  } > "$manifest_tmp" && mv "$manifest_tmp" "$TARGET/.agentcontext" \
    || die "rewriting .agentcontext; $done_n core file(s) were written"
  say "$summary"
  say "manifest: ref=$SRC_REF, ${#NEWHASH[@]} core files"
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
  [ -f "$TARGET/.conf" ] || refuse "no .conf: copy template/.conf.example, fill it, pass --conf"
  CONF="$TARGET/.conf"
fi
[ -f "$CONF" ] || refuse "no .conf: $CONF does not exist; copy template/.conf.example, fill it, pass --conf"
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
cp -R "$SRC/template/." "$STAGE/" || die "copying the skeleton (nothing written)"
cp "$CONF" "$STAGE/.conf" || die "cannot read $CONF"   # a .conf.example never shadows it
resolve_tree_name "$STAGE/README.md" "$NAME" || die "naming the reader page (nothing written)"
[ $NO_PRIVATE -eq 1 ] && rm -rf "$STAGE/private"
mkdir -p "$STAGE/scripts" && cp -R "$SRC/scripts/." "$STAGE/scripts/" || die "copying scripts/ (nothing written)"
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
  say "upstream=$UPSTREAM"
  say "ref=$SRC_REF"
  say "installed=$TODAY"
  [ -n "$ADAPTER" ] && say "adapter=$ADAPTER"
  say ""
  printf '%s\n' "$CORE"
} > "$STAGE/.agentcontext"

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
