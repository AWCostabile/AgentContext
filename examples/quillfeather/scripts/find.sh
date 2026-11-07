#!/bin/bash
# find.sh — search the knowledge tree by tag, keyword, backlink or marker field.
#
# Modes:
#   bash scripts/find.sh <tag...>          resolve tags -> ranked branch paths
#   bash scripts/find.sh -x <dir>          expand: show a branch's tags + index head
#   bash scripts/find.sh -l                list the tag vocabulary with usage counts
#   bash scripts/find.sh -k <keyword...>   grep index lines (keywords ANDed, case-insensitive)
#   bash scripts/find.sh -b <leaf>         backlinks: every file in scope that cites the leaf;
#                                          its own branch index is marked "(index row)"
#   bash scripts/find.sh -f <key>          fields: every file whose marker line `_<key>:_ <value>`
#                                          sits under its H1, with the value (path TAB value);
#                                          -f '<key>=<value>' those equal to it, -f '<key><<value>'
#                                          and -f '<key>><value>' compare the value as text, which
#                                          orders dates (quote the argument: < and > are the shell's)
# Flags:
#   -a            with -k: also search leaf bodies (default: .index.md files only)
#   -p            search EVERYTHING under private/, whatever .conf says
#   --root <dir>  the tree root to search (the directory holding public/ and .conf);
#                 default the current directory. -r <dir> is a synonym.
#
# -x takes a branch path relative to the root (`-x public/misc`); a path from the
# current directory that lies inside the root is accepted too (`--root template
# -x template/public`). -b takes a leaf the same two ways, or a bare basename when one
# leaf in scope carries it (an ambiguous basename lists the candidates and asks for a path).
#
# Scope: public/ always, plus the private branches .conf's PRIVATE_SCOPES opts in to
# (lib-scopes.sh). Unset or empty means public-only, which is what a fresh clone gets;
# a missing private/ is never an error. Each tag result ends with its tree
# (public | private).
#
# A citation (-b) is any occurrence of the leaf's basename in another file's text, a
# Markdown link or a bare path alike, because the smell linter keeps leaf basenames unique
# (S12). The names S12 exempts are per product (glossary.md, features.*.md, codebase.*.md):
# such a leaf is cited by a file under the same product branch, in either tree, that
# names it, or by any file spelling its product-qualified tail (<Product>/<tier>/<name>).
#
# Tag resolution ranks branches by how many requested tags their .tags file declares
# (one lowercase tag per line), tie-broken by how often those terms occur in the
# branch's own index and leaves, computed live: weights are never stored, so they
# cannot rot. Each result prints the branch's full tag set: enough to pick a
# candidate, then find.sh -x <dir>, then read.
#
# grep -x is avoided throughout: Git Bash's GNU grep aborts on the -x/-i combination;
# an anchored regex (^tag$) is the portable equivalent.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALLER_DIR="$(pwd)"
ROOT="$CALLER_DIR"

usage() { sed -n '2,45p' "$0" | sed 's/^#//; s/^ //'; }

# --root is a long option, which getopts cannot parse: lift it (and its synonym) out first
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --root|-r) [ $# -ge 2 ] || { echo "$1 needs a directory" >&2; exit 2; }
               ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "no such directory: $2" >&2; exit 2; }
               shift 2 ;;
    --help) usage; exit 0 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

MODE=tags ALL=0 PRIVATE=0 EXPAND="" LEAF="" FIELD=""
while getopts "klx:b:f:aph" opt; do
  case $opt in
    k) MODE=grep ;;
    l) MODE=list ;;
    x) MODE=expand; EXPAND=$OPTARG ;;
    b) MODE=backlinks; LEAF=$OPTARG ;;
    f) MODE=fields; FIELD=$OPTARG ;;
    a) ALL=1 ;;
    p) PRIVATE=1 ;;
    h|*) usage; exit 0 ;;
  esac
done
shift $((OPTIND - 1))
cd "$ROOT" || exit 1
[ -d public ] || { echo "no public/ directory under $ROOT — pass --root <tree root>" >&2; exit 2; }
. "$SCRIPT_DIR/lib-scopes.sh"

if [ $PRIVATE -eq 1 ]; then SCOPES=$(search_dirs all); else SCOPES=$(search_dirs); fi
SCOPES=$(printf '%s ' $SCOPES)
# what to suggest when nothing matched: -p only helps where it would widen the search
WIDER=""
[ $PRIVATE -eq 0 ] && [ -d private ] && WIDER=", or -p for all of private/"

show_tags() { tr -d '\r' < "$1" | tr '\n' ',' | sed 's/,$//; s/,/, /g'; }

case $MODE in
  list)
    find $SCOPES -type f -name '.tags' -exec cat {} + 2>/dev/null \
      | tr -d '\r' | grep -vE '^$' | sort | uniq -c | sort -rn \
      | awk '{ printf "%3d  %s\n", $1, $2 }'
    ;;

  expand)
    d=${EXPAND%/}
    if [ ! -d "$d" ]; then
      # a path given from the caller's directory: re-express it relative to the root
      abs=$(cd "$CALLER_DIR" 2>/dev/null && cd "$d" 2>/dev/null && pwd) || abs=""
      case "$abs" in
        "$ROOT") d=. ;;
        "$ROOT"/*) d=${abs#"$ROOT"/} ;;
        *) echo "no such directory under $ROOT: $d" >&2; exit 2 ;;
      esac
    fi
    [ -f "$d/.tags" ] && echo "tags: $(show_tags "$d/.tags")"
    [ -f "$d/.agent" ] && echo "NOTE: .agent present — read it before working here"
    idx="$d/.index.md"
    if [ -f "$idx" ]; then
      echo "--- $idx ---"
      sed -n '1,20p' "$idx"
    else
      echo "no index at $idx" >&2
      exit 1
    fi
    ;;

  backlinks)
    leaf=${LEAF#./}
    if [ ! -f "$leaf" ]; then
      # a path given from the caller's directory, re-expressed relative to the root
      abs=$(cd "$CALLER_DIR" 2>/dev/null && [ -f "$leaf" ] && cd "$(dirname "$leaf")" && printf '%s/%s' "$(pwd)" "$(basename "$leaf")") || abs=""
      case "$abs" in
        "$ROOT"/*) leaf=${abs#"$ROOT"/} ;;
        *)
          case "$leaf" in */*) echo "no such leaf under $ROOT: $leaf" >&2; exit 2 ;; esac
          # a bare basename: the one leaf in scope that carries it
          mapfile -t cands < <(find $SCOPES -type f -name "$leaf" 2>/dev/null | sort)
          if [ ${#cands[@]} -eq 0 ]; then
            echo "no leaf named $leaf in scope$WIDER." >&2; exit 1
          elif [ ${#cands[@]} -gt 1 ]; then
            { echo "$leaf names ${#cands[@]} leaves in scope — pass the path of one:"; printf '  %s\n' "${cands[@]}"; } >&2; exit 2
          fi
          leaf=${cands[0]} ;;
      esac
    fi
    base=${leaf##*/}
    dir=${leaf%/*}
    # the names S12 exempts are per product: qualify them by product (the header says why)
    product="" tail=""
    case "$base" in
      glossary.md)          product=${dir##*/}; tail="$product/$base" ;;
      features.*|codebase.*) pdir=${dir%/*}; product=${pdir##*/}; tail="$product/${dir##*/}/$base" ;;
    esac
    results=$(
      grep -rlF --include='*.md' -- "$base" $SCOPES 2>/dev/null | grep -vxF -- "$leaf" | sort -u \
        | while IFS= read -r f; do
            if [ -n "$product" ]; then
              case "/$f/" in */"$product"/*) ;; *) grep -qF -- "$tail" "$f" || continue ;; esac
            fi
            if [ "$f" = "$dir/.index.md" ]; then printf '%s  (index row)\n' "$f"; else printf '%s\n' "$f"; fi
          done
    )
    if [ -z "$results" ]; then
      echo "nothing in scope cites $leaf$WIDER." >&2
      exit 1
    fi
    printf '%s\n' "$results"
    ;;

  fields)
    key=$FIELD op="" val=""
    case "$key" in
      *=*)   op="="; val=${key#*=}; key=${key%%=*} ;;
      *'<'*) op="<"; val=${key#*<}; key=${key%%<*} ;;
      *'>'*) op=">"; val=${key#*>}; key=${key%%>*} ;;
    esac
    [ -n "$key" ] || { echo "-f needs a key: -f reviewed, -f 'reviewed<2026-01-01'" >&2; exit 2; }
    results=$(
      find $SCOPES -type f -name '*.md' 2>/dev/null | sort | xargs -r awk -v key="$key" -v op="$op" -v val="$val" '
        FNR == 1 { seen = 0; inhead = 0 }
        { sub(/\r$/, "") }
        !seen { if ($0 ~ /^# /) { seen = 1; inhead = 1 } next }
        !inhead { nextfile }
        /^[ \t]*$/ { next }
        /^_[^_]+:_/ {
          k = $0; sub(/^_/, "", k); sub(/:_.*$/, "", k)
          v = $0; sub(/^_[^_]+:_[ \t]*/, "", v)
          if (k == key && (op == "" || (op == "=" && v == val) || (op == "<" && v < val) || (op == ">" && v > val)))
            print FILENAME "\t" v
          next
        }
        { inhead = 0; nextfile }'
    )
    if [ -z "$results" ]; then
      echo "no file in scope carries _${key}:_${op:+ $op $val}$WIDER." >&2
      exit 1
    fi
    printf '%s\n' "$results"
    ;;

  tags)
    if [ $# -eq 0 ]; then
      usage
      exit 2
    fi
    results=$(
      while IFS= read -r tf; do
        d=$(dirname "$tf")
        n=0
        for t in "$@"; do
          grep -qiE -- "^${t}[[:space:]]*\$" "$tf" && n=$((n + 1))   # [[:space:]] absorbs a CRLF's \r
        done
        [ "$n" -gt 0 ] || continue
        # weight: live occurrence count of the requested terms in this
        # branch's own markdown (index + leaves, non-recursive)
        w=0
        for t in "$@"; do
          c=$(cat "$d"/.index.md "$d"/*.md 2>/dev/null | grep -ioE -- "\b${t}\b" | wc -l)
          w=$((w + c))
        done
        printf '%d\t%d\t%s\t(%s)\n' "$n" "$w" "$d" "$(show_tags "$tf")"
      done < <(find $SCOPES -type f -name '.tags' 2>/dev/null) | sort -t"$(printf '\t')" -k1,1rn -k2,2rn
    )
    if [ -z "$results" ]; then
      echo "no branches match tags: $*. Try -k for keyword search$WIDER." >&2
      exit 1
    fi
    printf '%s\n' "$results" | awk -F'\t' -v m="$#" '{
      tree = (index($3, "private") == 1) ? "private" : "public"
      printf "%s  %s  [%s/%s tags, %s hits]  %s\n", $3, $4, $1, m, $2, tree }'
    ;;

  grep)
    if [ $# -eq 0 ]; then
      usage
      exit 2
    fi
    if [ $ALL -eq 1 ]; then
      FILES=$(find $SCOPES -type f -name '*.md' 2>/dev/null)
    else
      FILES=$(find $SCOPES -type f -name '.index.md' 2>/dev/null)
    fi
    TOTAL=0
    for f in $FILES; do
      results=$(grep -inH -- "$1" "$f" 2>/dev/null)
      for kw in "${@:2}"; do
        [ -z "$results" ] && break
        results=$(printf '%s\n' "$results" | grep -i -- "$kw")
      done
      if [ -n "$results" ]; then
        printf '%s\n' "$results" | tr -d '\r'
        TOTAL=$((TOTAL + $(printf '%s\n' "$results" | wc -l)))
      fi
    done
    if [ "$TOTAL" -eq 0 ]; then
      echo "no matches. Try -a (leaf bodies)$WIDER." >&2
      exit 1
    fi
    ;;
esac
