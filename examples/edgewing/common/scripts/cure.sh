#!/bin/bash
# cure.sh — lint the knowledge tree's structural invariants. Report-only.
#
# Two trees, one grammar. public/ is always linted. The private mirror (private/, a
# nested repository the parent ignores) is linted when it exists: every top-level
# private branch except the freeform local/, mod/ and temp/ (lib-scopes.sh). An absent
# private/ is never an error: public/ must lint clean on a fresh clone. common/HYGIENE.md
# describes every check, its verdict and how to rectify it.
#
# Template mode: with no .conf at the root, the root is the skeleton itself. Every
# link, tag or Contents cell carrying a {{ }} placeholder is then skipped, and the
# placeholder branch catalog/ stands for every CATALOGS entry. With a .conf, a
# placeholder is residue, which smell.sh reports.
#
# Invariants (ids are stable; a missing number is a retired check):
#   C01  every branch directory has a .index.md (public/ and private/ included)
#   C02  every branch below a tree root has a non-empty .tags file: one lowercase
#        [a-z0-9-] tag per line, no commas (a malformed line is a WARN)
#   C03  every leaf file and child directory is referenced by its branch index
#   C04  every relative link in *.md resolves, in both trees and in the root documents
#        (*.md at the root, common/HYGIENE.md, common/rules/*.md, common/scripts/.index.md, common/templates/.index.md). Links
#        into private/ from the root documents are conditional on the machine and are
#        skipped; {{ }} targets are skipped. Verbatim provenance (lib-scopes.sh
#        verbatim_path, and every leaf listed in a manifest, an index whose Contents
#        table has a "Landed as" column) keeps its original links, so only its index
#        rows are checked
#   C05  leaves over 120 lines are promotion candidates (WARN)
#   C06  Contents tables over 15 data rows are split candidates (WARN)
#   C07  exact singular/plural tag pairs fragment search (WARN)
#   C08  the `private` tag never appears under public/
#   C09  links run one way: nothing under public/ links into private/ or cites the
#        path of a private record (`private/<path>.md`). Citations inside verbatim
#        provenance are counted as INFO, never failed: the record is immutable, and
#        the citation resolves only on a machine holding the private tree
#   C14  every CATALOGS entry in .conf has its public/<catalog>/ branch (not checked in
#        template mode; one INFO line when .conf has no CATALOGS key)
#
# Usage: bash common/scripts/cure.sh [--root <dir>] [--fast]
#   --root <dir>  the tree root to lint (the directory holding public/ and .conf);
#                 default the current directory
#   --fast        skip the advisory scans (C05, C06, C07: WARN-only); every FAIL-class
#                 invariant still runs. For hooks that only need the verdict.
# Exit code: the number of FAILs (0 = structurally sound).
#
# The loops deliberately avoid one process per file (bash string tests, one grep or
# wc over the whole file set): on Windows each spawn costs about 15 ms and a real tree
# has hundreds of files, while a write hook needs the verdict in a few seconds.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(pwd)"

FAST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --fast) FAST=1; shift ;;
    --root) [ $# -ge 2 ] || { echo "--root needs a directory" >&2; exit 2; }
            ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "no such directory: $2" >&2; exit 2; }
            shift 2 ;;
    -h|--help) sed -n '2,42p' "$0" | sed 's/^#//; s/^ //'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$ROOT" || exit 2
[ -d public ] || { echo "no public/ directory under $ROOT — pass --root <tree root>" >&2; exit 2; }
. "$SCRIPT_DIR/lib-scopes.sh"

FAIL=0 WARN=0
ok()   { printf '[ OK ] %s\n' "$1"; }
info() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

TMPL=0; template_mode && TMPL=1
# MIRROR holds the private top-level branches that follow the grammar; private/ itself
# is a branch indexed by private/.index.md, as public/ is by public/.index.md.
mapfile -t MIRROR < <(mirror_dirs)
TREES="public"
has_mirror && TREES="public + private"
MODE="instance"; [ $TMPL -eq 1 ] && MODE="template mode"

echo "== cure — knowledge-tree lint ($TREES, $MODE) — $(date '+%Y-%m-%d %H:%M')$([ $FAST -eq 1 ] && echo ' (fast)') =="

branch_dirs() {
  find public -type d
  if has_mirror; then
    printf 'private\n'
    [ ${#MIRROR[@]} -gt 0 ] && find "${MIRROR[@]}" -type d
  fi
  return 0
}
md_files() {   # NUL-separated, for xargs -0
  find public -type f -name "$1" -print0
  if has_mirror; then
    { [ "$1" = '*.md' ] || [ "$1" = '.index.md' ]; } && printf 'private/.index.md\0'
    [ ${#MIRROR[@]} -gt 0 ] && find "${MIRROR[@]}" -type f -name "$1" -print0
  fi
  return 0
}
# The root documents: dead links only, never linted as branches. common/templates/ carries
# {{ }} forever, so only its index is read.
ROOT_DOCS=()
for f in *.md common/HYGIENE.md common/rules/*.md common/scripts/.index.md common/templates/.index.md; do
  [ -f "$f" ] && ROOT_DOCS+=("$f")
done

# a placeholder line, skipped in template mode
placeholder() { [ $TMPL -eq 1 ] && [[ "$1" == *'{{'* || "$1" == *'}}'* ]]; }

# -- C01, C02 & C03: branch indexes, tags, and referenced children --------------
missing=0 untagged=0 orphans=0
while IFS= read -r d; do
  idx="$d/.index.md"
  if [ ! -f "$idx" ]; then
    fail "missing index: $idx"
    missing=$((missing + 1))
    continue
  fi
  if [ "$d" != "public" ] && [ "$d" != "private" ]; then
    if [ ! -s "$d/.tags" ]; then
      fail "missing or empty tags: $d/.tags"
      untagged=$((untagged + 1))
    else
      while IFS= read -r t || [ -n "$t" ]; do
        t=${t%$'\r'}  # .tags may be CRLF; read keeps the \r
        placeholder "$t" && continue
        case "$t" in *[!a-z0-9-]*)
          warn "malformed tags in $d/.tags — one lowercase [a-z0-9-] tag per line, no commas"
          break ;;
        esac
      done < "$d/.tags"
    fi
  fi
  idxtext=$(<"$idx")
  for child in "$d"/* "$d"/.[!.]*; do
    [ -e "$child" ] || continue
    name=${child##*/}
    case "$name" in .index.md|.tags|.agent|.keep|.git|.gitattributes|.gitignore|.vscode) continue ;; esac
    if [[ "$idxtext" != *"$name"* ]]; then
      fail "orphan (not in $idx): $child"
      orphans=$((orphans + 1))
    fi
  done
done < <(branch_dirs)
[ "$missing" -eq 0 ] && ok "every branch has a .index.md"
[ "$untagged" -eq 0 ] && ok "every branch has a non-empty .tags"
[ "$orphans" -eq 0 ] && ok "every leaf and child branch is referenced by its index"

# -- C04: link resolution (and the link half of C09) ---------------------------
dead=0 oneway=0
declare -A manifest  # dir -> 1 when its index is a "Landed as" manifest
is_manifest_dir() {
  if [ -z "${manifest[$1]+x}" ]; then
    manifest[$1]=0
    [ -f "$1/.index.md" ] && [[ "$(<"$1/.index.md")" == *'| Landed as |'* ]] && manifest[$1]=1
  fi
  [ "${manifest[$1]}" = 1 ]
}
# a verbatim provenance leaf: under an immutable root, or listed in a manifest
is_verbatim() {
  verbatim_path "$1" && return 0
  [ "${1##*/}" != .index.md ] && is_manifest_dir "${1%/*}"
}
while IFS= read -r line; do
  f=${line%%:*}
  target=${line#*:}
  dir=${f%/*}
  [ "$dir" = "$f" ] && dir=.
  case "$f" in public/*|private/*) is_verbatim "$f" && continue ;; esac
  target=${target#](}
  target=${target%)}
  target=${target#<}
  target=${target%>}
  target=${target%%#*}
  [ -z "$target" ] && continue
  case "$target" in
    http*|mailto*|/*|*'{{'*|*'}}'*) continue ;;
  esac
  resolved="$dir/$target"
  case "$f" in
    public/*)
      case "$resolved" in
        *private/*)
          fail "one-way link broken: $f links into private/ -> $target"
          oneway=$((oneway + 1))
          continue ;;
      esac ;;
    private/*) ;;
    *)  # a root document: a link into private/ is conditional on the machine having one
      case "$resolved" in *private/*) continue ;; esac ;;
  esac
  if [ ! -e "$resolved" ]; then
    fail "dead link in $f -> $target"
    dead=$((dead + 1))
  fi
done < <({ md_files '*.md'; [ ${#ROOT_DOCS[@]} -gt 0 ] && printf '%s\0' "${ROOT_DOCS[@]}"; } \
         | xargs -0 grep -oHE '\]\([^)]+\)' 2>/dev/null)
[ "$dead" -eq 0 ] && ok "all relative links resolve"

# -- C09: one way — no private record is cited from public/ ---------------------
exempt=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  f=${line%%:*}
  cite=${line#*:}
  if is_verbatim "$f"; then exempt=$((exempt + 1)); continue; fi
  fail "one-way link broken: $f cites a private record -> $cite"
  oneway=$((oneway + 1))
done < <(find public -type f -name '*.md' -print0 | xargs -0 grep -oHE 'private/[A-Za-z0-9_./-]*\.md' 2>/dev/null)
[ "$oneway" -eq 0 ] && ok "links run one way: nothing under public/ points into private/"
[ "$exempt" -gt 0 ] && info "$exempt private citation(s) inside immutable provenance under public/ — they resolve only on a machine holding the private tree"

if [ $FAST -eq 0 ]; then
  # -- C05: promotion candidates -----------------------------------------------
  big=0
  while read -r lines f; do
    [ "$f" = "total" ] && continue
    case "$f" in */.index.md) continue ;; esac
    if [ "$lines" -gt 120 ]; then
      warn "promotion candidate ($lines lines): $f"
      big=$((big + 1))
    fi
  done < <(md_files '*.md' | xargs -0 wc -l 2>/dev/null)
  [ "$big" -eq 0 ] && ok "no leaves over 120 lines"

  # -- C06: split candidates ---------------------------------------------------
  wide=0
  while IFS= read -r line; do
    f=${line%:*}
    rows=${line##*:}
    if [ "$rows" -gt 17 ]; then  # 15 data rows + header + separator
      warn "split candidate ($((rows - 2)) rows): $f"
      wide=$((wide + 1))
    fi
  done < <(md_files '.index.md' | xargs -0 grep -cH '^|' 2>/dev/null)
  [ "$wide" -eq 0 ] && ok "no Contents tables over 15 rows"

  # -- C07: near-duplicate tags ------------------------------------------------
  declare -A seen
  while IFS= read -r t; do
    t=${t%$'\r'}
    placeholder "$t" && continue
    [ -n "$t" ] && seen[$t]=1
  done < <(md_files '.tags' | xargs -0 cat 2>/dev/null)
  dups=0
  for t in "${!seen[@]}"; do
    if [ -n "${seen[${t}s]+x}" ]; then
      warn "near-duplicate tags: '$t' and '${t}s' — unify to one form across the tree"
      dups=$((dups + 1))
    fi
  done
  [ "$dups" -eq 0 ] && ok "no near-duplicate tags (singular/plural)"
fi

# -- C08: private tag leakage --------------------------------------------------
leaks=0
while IFS= read -r tf; do
  [ -z "$tf" ] && continue
  fail "'private' tag found under public/: $tf — move this content to private/"
  leaks=$((leaks + 1))
done < <(find public -type f -name '.tags' -print0 | xargs -0 grep -liE '^private[[:space:]]*$' 2>/dev/null)
[ "$leaks" -eq 0 ] && ok "no 'private' tags under public/"

# -- C14: every catalog named in .conf has its public branch -------------------
# In template mode the placeholder branch catalog/ stands for every entry: not checked.
if [ $TMPL -eq 0 ]; then
  if ! conf_has_key CATALOGS; then
    info "no CATALOGS key in .conf — catalog branches not checked"
  else
    absent=0 ncat=0
    for c in $(catalogs); do
      ncat=$((ncat + 1))
      if [ ! -d "public/$c" ]; then
        fail "catalog '$c' (.conf CATALOGS) has no branch: public/$c/"
        absent=$((absent + 1))
      fi
    done
    [ "$absent" -eq 0 ] && ok "every CATALOGS entry has its public/ branch ($ncat named)"
  fi
fi

echo "== VERDICT: $FAIL fail(s), $WARN warning(s) =="
exit "$FAIL"
