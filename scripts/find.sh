#!/bin/bash
# find.sh — search the knowledge tree by tag, keyword, backlink or marker field.
#
# Modes:
#   bash common/scripts/find.sh <tag...>          resolve tags -> ranked branch paths
#   bash common/scripts/find.sh -x <dir>          expand: show a branch's tags + index head
#   bash common/scripts/find.sh -l                list the tag vocabulary with usage counts
#   bash common/scripts/find.sh -k <keyword...>   grep index lines (keywords ANDed, case-insensitive)
#   bash common/scripts/find.sh -b <leaf>         backlinks: every file in scope that cites the leaf;
#                                          its own branch index is marked "(index row)"
#   bash common/scripts/find.sh -f <key>          fields: every file whose marker line `_<key>:_ <value>`
#                                          sits under its H1, with the value (path TAB value);
#                                          -f '<key>=<value>' those equal to it, -f '<key><<value>'
#                                          and -f '<key>><value>' compare the value as text, which
#                                          orders dates (quote the argument: < and > are the shell's)
#   bash common/scripts/find.sh --refs <prefix> [--moves <file>]
#                                          every mention of a path prefix (`scripts/`, a file
#                                          path) across public/, all of private/ and the root
#                                          *.md, one line per hit: path:line TAB link|mention TAB
#                                          the spelling; a link is resolved from its file, a
#                                          mention is the bare path. --moves names a file of
#                                          "<old> <new>" pairs (the template's MOVES): a hit a
#                                          pair reaches gains a fourth field, its new spelling.
#                                          Exits 0 with or without hits
# Flags:
#   -a            with -k: also search leaf bodies (default: .index.md files only)
#   -p            search EVERYTHING under private/, whatever .conf says
#   --root <dir>  the tree root to search (the directory holding public/ and .conf);
#                 default the current directory. -r <dir> is a synonym.
#
# -x takes a branch path relative to the root (`-x public/misc`); a path from the
# current directory that lies inside the root is accepted too (`--root blueprint
# -x blueprint/public`). -b takes a leaf the same two ways, or a bare basename when one
# leaf in scope carries it (an ambiguous basename lists the candidates and asks for a path).
#
# Scope: public/ always, plus the private branches .conf's PRIVATE_SCOPES opts in to
# (lib-scopes.sh). Unset or empty means public-only, which is what a fresh clone gets;
# a missing private/ is never an error. The reference branch common/reference/ is searched
# beside them when it exists. Each tag result ends with its tree (public | private | common).
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

usage() { sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^#//; s/^ //'; }

# --root is a long option, which getopts cannot parse: lift it (and its synonym) out first
ARGS=()
REFS="" MOVES_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root|-r) [ $# -ge 2 ] || { echo "$1 needs a directory" >&2; exit 2; }
               ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "no such directory: $2" >&2; exit 2; }
               shift 2 ;;
    --refs)    [ $# -ge 2 ] && [ -n "$2" ] || { echo "--refs needs a path prefix: --refs scripts/" >&2; exit 2; }
               REFS=$2; shift 2 ;;
    --moves)   [ $# -ge 2 ] || { echo "--moves needs a file of <old> <new> pairs" >&2; exit 2; }
               [ -f "$2" ] || { echo "--moves: no such file: $2" >&2; exit 2; }
               MOVES_FILE="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2 ;;
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
if [ -n "$REFS" ]; then
  [ "$MODE" = tags ] && [ $# -eq 0 ] || { echo "--refs takes one prefix and no other mode (see --help)" >&2; exit 2; }
  MODE=refs
elif [ -n "$MOVES_FILE" ]; then
  echo "--moves goes with --refs (see --help)" >&2; exit 2
fi
cd "$ROOT" || exit 1
[ -d public ] || { echo "no public/ directory under $ROOT — pass --root <tree root>" >&2; exit 2; }
. "$SCRIPT_DIR/lib-scopes.sh"

if [ $PRIVATE -eq 1 ]; then SCOPES=$(search_dirs all); else SCOPES=$(search_dirs); fi
# the tree's reference branch answers beside the trees, labelled common
[ -d common/reference ] && SCOPES="$SCOPES common/reference"
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
      tree = (index($3, "private") == 1) ? "private" : (index($3, "common/") == 1) ? "common" : "public"
      printf "%s  %s  [%s/%s tags, %s hits]  %s\n", $3, $4, $1, m, $2, tree }'
    ;;

  refs)
    # every *.md of public/, all of private/ and the root documents; .git never read
    mapfile -t RFILES < <({ find public private -type f -name '*.md' ! -path '*/.git/*' 2>/dev/null
                            for f in *.md; do [ -f "$f" ] && printf '%s\n' "$f"; done; } | LC_ALL=C sort)
    [ ${#RFILES[@]} -gt 0 ] || exit 0
    awk -v prefix="$REFS" -v moves="$MOVES_FILE" '
      # norm: a path with its . and .. segments collapsed; "\001" when it climbs out of the root
      function norm(p,   n, a, i, k, s, out) {
        n = split(p, a, "/"); k = 0
        for (i = 1; i <= n; i++) {
          if (a[i] == "" || a[i] == ".") continue
          if (a[i] == "..") { if (k == 0) return "\001"; k--; continue }
          s[++k] = a[i]
        }
        out = ""; for (i = 1; i <= k; i++) out = out (i > 1 ? "/" : "") s[i]
        if (p ~ /\/$/ && out != "") out = out "/"
        return out
      }
      # moved: a root-relative path through every MOVES pair, as init.sh --update moves it
      function moved(p,   i) {
        for (i = 1; i <= nm; i++) {
          if (mo[i] ~ /\/$/) { if (index(p, mo[i]) == 1) p = mn[i] substr(p, length(mo[i]) + 1) }
          else if (p == mo[i]) p = mn[i]
        }
        return p
      }
      # rel: the relative spelling of root-relative <to> from directory <from> ("" the root)
      function rel(from, to,   na, nb, a, b, i, j, out) {
        na = (from == "") ? 0 : split(from, a, "/"); nb = split(to, b, "/")
        i = 1; while (i <= na && i < nb && a[i] == b[i]) i++
        out = ""; for (j = i; j <= na; j++) out = out "../"
        for (j = i; j <= nb; j++) out = out b[j] (j < nb ? "/" : "")
        return out
      }
      function hit(kind, spelled, now) {
        printf "%s:%d\t%s\t%s", FILENAME, FNR, kind, spelled
        if (nm > 0 && now != "") printf "\t%s", now
        printf "\n"
      }
      BEGIN {
        PATHCH = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/~-"
        if (moves != "") while ((getline l < moves) > 0) {
          sub(/\r$/, "", l)
          if (l ~ /^[ \t]*(#|$)/) continue
          split(l, w, /[ \t]+/); if (w[1] == "" || w[2] == "") continue
          nm++; mo[nm] = w[1]; mn[nm] = w[2]
        }
      }
      FNR == 1 { dir = FILENAME; if (!sub(/\/[^\/]*$/, "", dir)) dir = "" }
      {
        sub(/\r$/, "")
        line = $0; rest = $0
        # links: each target resolved from the file to a root-relative path
        while (match(rest, /\]\([^)]*\)/)) {
          t = substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH)
          sub(/[ \t].*$/, "", t); sub(/^</, "", t); sub(/>$/, "", t); sub(/#.*$/, "", t)
          if (t == "" || t ~ /^[a-z]+:/ || t ~ /^\//) continue
          r = norm((dir == "" ? "" : dir "/") t)
          if (r == "\001" || index(r, prefix) != 1) continue
          m = moved(r)
          hit("link", t, (m != r) ? rel(dir, m) : "")
        }
        # bare mentions: the prefix where a path starts, outside every link target
        gsub(/\]\([^)]*\)/, "]", line)
        while ((i = index(line, prefix)) > 0) {
          before = (i > 1) ? substr(line, i - 1, 1) : ""
          if (before != "" && index(PATHCH, before)) { line = substr(line, i + 1); continue }
          j = i; while (j <= length(line) && index(PATHCH, substr(line, j, 1))) j++
          tok = substr(line, i, j - i); line = substr(line, j)
          sub(/[.]+$/, "", tok)
          m = moved(tok)
          hit("mention", tok, (m != tok) ? m : "")
        }
      }' "${RFILES[@]}"
    exit 0
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
