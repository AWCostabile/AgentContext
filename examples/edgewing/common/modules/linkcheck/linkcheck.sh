#!/bin/bash
# linkcheck.sh — the linkcheck module: ask every http:// and https:// URL the tree cites, once
# each, and report the dead ones. Report-only: it writes nothing.
#
# Usage (from the instance root, the directory holding .conf):
#   bash common/modules/linkcheck/linkcheck.sh [--all] [--root <dir>] [--max-time <s>] [<path>...]
#   --all           with no <path>: every private branch, whatever .conf says (as find.sh -p)
#   --root <dir>    the instance root; default the current directory
#   --max-time <s>  the seconds one request may take; default 15
#   <path>...       files or directories under the root to check instead of the search scope; a
#                   path is taken from the root, or from the current directory when it lies there
#
# Scope: with no <path>, every .md file under the directories common/scripts/lib-scopes.sh's
# search_dirs prints: public/ and the private branches .conf's PRIVATE_SCOPES names. A directory
# <path> contributes its .md files; a file <path> is read whatever its extension.
#
# Each distinct URL is asked once with curl: a HEAD request following redirects, and a GET when
# the HEAD is answered 405. A code of 000 (no answer) or 400 and above is dead. A URL is cut at
# whitespace and at < > " ` | { } [ ], and its trailing . , ; : > ' " are dropped, as is a ) that
# closes nothing opened inside it (the end of a Markdown link).
#
# .linkcheckignore at the instance root, when present: one URL prefix per line, # comments and
# blank lines skipped. A URL starting with a listed prefix is never asked.
#
# Output: DEAD <code> <file>:<line> <url>, one per occurrence of a dead URL, in file and line
# order, then the summary line
#   linkcheck: <n> dead link(s) in <m> file(s), <k> url(s) asked, <s> ignored
# where <n> counts occurrences and <k> and <s> count distinct URLs.
# Exit code: <n>, capped at 125; 2 for a usage error or a refusal (no .conf, no curl on PATH).
set -u

ROOT="" ALL=0 MAX_TIME=15 PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --all) ALL=1 ;;
    --root) [ $# -ge 2 ] || { echo "usage: --root <dir>" >&2; exit 2; }; ROOT=$2; shift ;;
    --max-time) [ $# -ge 2 ] && [[ $2 =~ ^[1-9][0-9]*$ ]] || { echo "usage: --max-time <seconds>" >&2; exit 2; }; MAX_TIME=$2; shift ;;
    -h|--help) sed -n '2,/^set -u/p' "$0" | sed '$d' | sed 's/^#//; s/^ //'; exit 0 ;;
    -*) echo "usage: unknown option $1" >&2; exit 2 ;;
    *) PATHS+=("$1") ;;
  esac
  shift
done
START=$PWD
[ -z "$ROOT" ] && ROOT=$PWD
ROOT=$(cd "$ROOT" 2>/dev/null && pwd) || { echo "usage: --root $ROOT is not a directory" >&2; exit 2; }
[ -f "$ROOT/.conf" ] || { echo "refused: $ROOT holds no .conf — run from the instance root or pass --root" >&2; exit 2; }
[ -f "$ROOT/common/scripts/lib-scopes.sh" ] || { echo "refused: $ROOT/common/scripts/lib-scopes.sh is missing — the module runs inside an instance of the template" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "refused: no curl on PATH — linkcheck asks every URL with it" >&2; exit 2; }
cd "$ROOT" || exit 2
# shellcheck source=/dev/null
. "$ROOT/common/scripts/lib-scopes.sh"

# -- the files ----------------------------------------------------------------------------------
SCOPE=() FILES=()
if [ ${#PATHS[@]} -eq 0 ]; then
  mode=""; [ $ALL -eq 1 ] && mode=all
  mapfile -t SCOPE < <(search_dirs $mode)
else
  for p in "${PATHS[@]}"; do
    p=${p%/}; p=${p#./}
    if [ -e "$ROOT/$p" ] && [[ $p != /* ]]; then SCOPE+=("$p"); continue; fi
    case "$p" in /*|[A-Za-z]:*) a=$p ;; *) a=$START/$p ;; esac
    if [ -d "$a" ]; then a=$(cd "$a" && pwd)
    elif [ -f "$a" ]; then a=$(cd "${a%/*}" && pwd)/${a##*/}
    else echo "usage: no such file or directory: $p" >&2; exit 2; fi
    case "$a" in
      "$ROOT") SCOPE+=(".") ;;
      "$ROOT"/*) SCOPE+=("${a#"$ROOT"/}") ;;
      *) echo "usage: $p is not under the root $ROOT" >&2; exit 2 ;;
    esac
  done
fi
dirs=()
for s in "${SCOPE[@]}"; do
  if [ -d "$s" ]; then dirs+=("$s"); elif [ -f "$s" ]; then FILES+=("$s"); fi
done
[ ${#dirs[@]} -gt 0 ] && mapfile -t -O "${#FILES[@]}" FILES < <(find "${dirs[@]}" -type f -name '*.md' ! -path '*/.git/*')
[ ${#FILES[@]} -gt 0 ] && mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | sed 's|^\./||' | LC_ALL=C sort -u)

# -- the ignore list ----------------------------------------------------------------------------
IGNORE=()
if [ -f .linkcheckignore ]; then
  while IFS= read -r l || [ -n "$l" ]; do
    l=${l%$'\r'}
    l=${l#"${l%%[![:space:]]*}"}; l=${l%"${l##*[![:space:]]}"}
    [ -z "$l" ] || [ "${l:0:1}" = "#" ] || IGNORE+=("$l")
  done < .linkcheckignore
fi
ignored() { local p; for p in "${IGNORE[@]}"; do [[ $1 == "$p"* ]] && return 0; done; return 1; }

# -- the occurrences ----------------------------------------------------------------------------
trim() {   # trim <url>: sets URL to the URL without the punctuation that follows it in prose
  local u=$1 o c
  while :; do
    case "$u" in
      *[.,\;:\>\'\"]) u=${u%?} ;;
      *\)) o=${u//[^(]/}; c=${u//[^)]/}; if [ ${#c} -gt ${#o} ]; then u=${u%?}; else break; fi ;;
      *) break ;;
    esac
  done
  URL=$u
}
URL_RE='https?://[^][[:space:]<>"`|{}]+'
OCC_FILE=() OCC_LINE=() OCC_URL=() ORDER=()
declare -A SEEN=()
if [ ${#FILES[@]} -gt 0 ]; then
  while IFS= read -r l; do
    [[ $l =~ ^(.*):([0-9]+):(https?://.*)$ ]] || continue
    f=${BASH_REMATCH[1]} n=${BASH_REMATCH[2]}
    trim "${BASH_REMATCH[3]}"; u=$URL
    [[ $u =~ ^https?://.+ ]] || continue
    OCC_FILE+=("$f") OCC_LINE+=("$n") OCC_URL+=("$u")
    [ -n "${SEEN[$u]:-}" ] || { SEEN[$u]=1; ORDER+=("$u"); }
  done < <(printf '%s\0' "${FILES[@]}" | xargs -0 grep -HnoE -- "$URL_RE" 2>/dev/null | tr -d '\r')
fi

# -- ask each distinct URL once -----------------------------------------------------------------
ask() {    # ask <url>: the HTTP code, HEAD first and GET on a 405; 000 when nothing answered
  local code
  code=$(curl -sS -o /dev/null -I -L --max-time "$MAX_TIME" -w '%{http_code}' "$1" 2>/dev/null)
  [ "$code" = 405 ] && code=$(curl -sS -o /dev/null -L --max-time "$MAX_TIME" -w '%{http_code}' "$1" 2>/dev/null)
  [[ $code =~ ^[0-9]{3}$ ]] || code=000
  printf '%s' "$code"
}
declare -A CODE=()
asked=0 skipped=0
for u in "${ORDER[@]}"; do
  if ignored "$u"; then skipped=$((skipped + 1)); continue; fi
  CODE[$u]=$(ask "$u"); asked=$((asked + 1))
done

# -- the report ---------------------------------------------------------------------------------
dead=0
declare -A DEADFILE=()
for i in "${!OCC_URL[@]}"; do
  u=${OCC_URL[$i]}; c=${CODE[$u]:-}
  [ -n "$c" ] || continue
  if [ "$c" = 000 ] || [ "$c" -ge 400 ]; then
    printf 'DEAD %s %s:%s %s\n' "$c" "${OCC_FILE[$i]}" "${OCC_LINE[$i]}" "$u"
    dead=$((dead + 1)); DEADFILE[${OCC_FILE[$i]}]=1
  fi
done
printf 'linkcheck: %d dead link(s) in %d file(s), %d url(s) asked, %d ignored\n' "$dead" "${#DEADFILE[@]}" "$asked" "$skipped"
[ $dead -gt 125 ] && dead=125
exit $dead
