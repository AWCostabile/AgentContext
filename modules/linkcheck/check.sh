#!/bin/bash
# check.sh — the linkcheck module's own check: proves linkcheck.sh end to end over a throwaway
# instance with a stand-in curl on PATH, so no network is reached. Exits with its fail count.
#
# Usage: bash modules/linkcheck/check.sh    (from the template checkout or an instance root)
#
# The stand-in answers from a table of "<url> <code> [<code for a GET>]" lines (an unlisted url
# answers 000) and logs one "<HEAD|GET> <url>" line per call. It proves: the dead occurrences
# reported with their code, file and line, and the live ones not; trailing punctuation and a
# Markdown link's ) trimmed, a ) the url opened kept; a url cited three times asked once; a 405
# asked again with a GET; .linkcheckignore skipping a prefix, never asked; the default scope
# reaching the private branches PRIVATE_SCOPES names and no other, --all reaching every one; an
# explicit file and directory; the exit code the dead count, 0 when none, capped at 125; the
# refusals (no curl on PATH, no .conf, an unknown option, a missing path) exit 2; the marker
# lines find.sh -f reads; the fixture never written to.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINKCHECK="$HERE/linkcheck.sh"
LIB=""
for c in "$HERE/../../scripts/lib-scopes.sh" "$HERE/../../blueprint/scripts/lib-scopes.sh" "$PWD/scripts/lib-scopes.sh" "$HERE/../scripts/lib-scopes.sh" "$PWD/common/scripts/lib-scopes.sh"; do
  [ -f "$c" ] && { LIB=$c; break; }
done
[ -n "$LIB" ] || { echo "cannot find scripts/lib-scopes.sh beside the module" >&2; exit 2; }
FIND=""
for c in "$HERE/../../scripts/find.sh" "$PWD/scripts/find.sh" "$HERE/../scripts/find.sh" "$PWD/common/scripts/find.sh"; do [ -f "$c" ] && { FIND=$c; break; }; done

FAIL=0
ok()   { printf '[ OK ] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
check() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/linkcheck-check.XXXXXX") || { echo "cannot create a temporary directory" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
INST="$TMP/instance" BIN="$TMP/bin" LOG="$TMP/curl.log" TABLE="$TMP/table"
digest() { (cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum); }
# a run from <dir>, the stand-in first on PATH, a fresh log
run_in() { local d=$1; shift; : > "$LOG"; (cd "$d" && PATH="$BIN:$PATH" CURL_STUB_TABLE="$TABLE" CURL_STUB_LOG="$LOG" bash "$LINKCHECK" "$@" 2>&1 < /dev/null); }
run() { run_in "$INST" "$@"; }
asked() { grep -cxF "$1 $2" "$LOG"; }   # asked <HEAD|GET> <url>: how many calls the stand-in logged so

echo "== linkcheck module check — $(date '+%Y-%m-%d %H:%M') =="

# -- the stand-in curl ----------------------------------------------------------------------------
mkdir -p "$BIN"
printf '%s\n' '#!/bin/bash' \
  '# a stand-in curl: the code for the url from $CURL_STUB_TABLE, as -w %{http_code} prints it' \
  'url="" verb=GET code=000' \
  'for a in "$@"; do case "$a" in -I) verb=HEAD ;; http://*|https://*) url=$a ;; esac; done' \
  'printf "%s %s\n" "$verb" "$url" >> "$CURL_STUB_LOG"' \
  'while read -r u c g; do' \
  '  [ "$u" = "$url" ] || continue' \
  '  code=$c; [ "$verb" = GET ] && [ -n "$g" ] && code=$g' \
  '  break' \
  'done < "$CURL_STUB_TABLE"' \
  'printf "%s" "$code"' > "$BIN/curl"
chmod +x "$BIN/curl"
printf '%s\n' \
  'https://live.example.test/lantern 200' 'https://live.example.test/beacon 301' 'https://live.example.test/sound 200' \
  'https://dead.example.test/guide 404' 'https://headless.example.test/api 405 200' \
  'https://wiki.example.test/Term_(usage) 200' 'https://private-dead.example.test/ 404' \
  'https://journal-dead.example.test/ 500' > "$TABLE"

# -- the fixture instance ---------------------------------------------------------------------------
mkdir -p "$INST/common/scripts" "$INST/public/products" "$INST/private/products" "$INST/private/journal"
cp "$LIB" "$INST/common/scripts/lib-scopes.sh"
[ -n "$FIND" ] && cp "$FIND" "$INST/common/scripts/find.sh"
printf '%s\n' 'CATALOGS="products"' 'PRIVATE_SCOPES="products"' > "$INST/.conf"
printf '%s\n' '# Public' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' \
  '| [Products](./products/.index.md) | the products |' > "$INST/public/.index.md"
printf '%s\n' '# Products' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' \
  '| [Lantern](./lantern.md) | a source leaf |' '| [Beacon](./beacon.md) | cites the guide |' \
  '| [Sound](./sound.md) | live links only |' > "$INST/public/products/.index.md"
printf '%s\n' products > "$INST/public/products/.tags"
printf '%s\n' '# Lantern' '' '_url:_ https://live.example.test/lantern' '_accessed:_ 2026-01-15' '' \
  'The [guide](https://dead.example.test/guide). Another source: https://gone.example.test/x,' \
  'and the same guide again: <https://dead.example.test/guide>.' \
  'An archive at https://skip.example.test/old/page is ignored.' \
  'HEAD is refused at https://headless.example.test/api; the term is https://wiki.example.test/Term_(usage)).' \
  > "$INST/public/products/lantern.md"
printf '%s\n' '# Beacon' '' 'See "https://dead.example.test/guide" and https://live.example.test/beacon.' > "$INST/public/products/beacon.md"
printf '%s\n' '# Sound' '' 'Only https://live.example.test/sound here.' > "$INST/public/products/sound.md"
printf '%s\n' '# Private' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' \
  '| [Products](./products/.index.md) | the mirror |' '| [Journal](./journal/.index.md) | the journal |' > "$INST/private/.index.md"
printf '%s\n' '# Products — private mirror' '' 'A note: https://private-dead.example.test/' > "$INST/private/products/.index.md"
printf '%s\n' '# Journal' '' 'A note: https://journal-dead.example.test/' > "$INST/private/journal/.index.md"
printf '%s\n' '# archives we keep, never asked' '' '  https://skip.example.test/  ' > "$INST/.linkcheckignore"
before=$(digest "$INST")

# -- 1. the default scope ---------------------------------------------------------------------------
out=$(run); rc=$?
printf '%s\n' "$out" > "$TMP/default.txt"
expect=$(printf '%s\n' 'DEAD 404 private/products/.index.md:3 https://private-dead.example.test/' \
  'DEAD 404 public/products/beacon.md:3 https://dead.example.test/guide' \
  'DEAD 404 public/products/lantern.md:6 https://dead.example.test/guide' \
  'DEAD 000 public/products/lantern.md:6 https://gone.example.test/x' \
  'DEAD 404 public/products/lantern.md:7 https://dead.example.test/guide')
check "the dead occurrences, each with its code, file and line, and nothing live reported" '[ "$(grep "^DEAD " "$TMP/default.txt")" = "$expect" ]'
check "the summary: 5 dead in 3 files, 8 urls asked, 1 ignored" \
  '[ "$(tail -n 1 "$TMP/default.txt")" = "linkcheck: 5 dead link(s) in 3 file(s), 8 url(s) asked, 1 ignored" ]'
check "the exit code is the dead count" '[ $rc -eq 5 ]'
check "a url cited three times is asked once" \
  '[ "$(asked HEAD https://dead.example.test/guide)" -eq 1 ] && [ "$(asked GET https://dead.example.test/guide)" -eq 0 ]'
check "a 405 is asked again with a GET (one HEAD, one GET), and the GET's 200 is live" \
  '[ "$(asked HEAD https://headless.example.test/api)" -eq 1 ] && [ "$(asked GET https://headless.example.test/api)" -eq 1 ] && ! grep -q headless "$TMP/default.txt"'
check "only the 405 is asked again: 8 HEAD calls and 1 GET" '[ "$(grep -c "^HEAD " "$LOG")" -eq 8 ] && [ "$(grep -c "^GET " "$LOG")" -eq 1 ]'
check "a ) the url opened is kept; a Markdown link's ) and trailing punctuation are dropped" \
  '[ "$(asked HEAD "https://wiki.example.test/Term_(usage)")" -eq 1 ] && ! cut -d" " -f2 "$LOG" | grep -v "^https://wiki\." | grep -q "[).,;:>\"]$"'
check "the ignored prefix is never asked" '! grep -q skip.example.test "$LOG"'
check "a private branch PRIVATE_SCOPES does not name is not reached" '! grep -q journal-dead "$LOG"'

# -- 2. --all, explicit paths, no dead ------------------------------------------------------------
out=$(run --all); rc=$?
check "--all reaches every private branch: the journal's dead link reported, exit 6" \
  '[ $rc -eq 6 ] && printf "%s\n" "$out" | grep -qxF "DEAD 500 private/journal/.index.md:3 https://journal-dead.example.test/" && printf "%s\n" "$out" | grep -qxF "linkcheck: 6 dead link(s) in 4 file(s), 9 url(s) asked, 1 ignored"'
out=$(run public/products/beacon.md private/journal/); rc=$?
check "explicit paths, a file and a directory, are the whole scope: 2 dead, 3 urls asked" \
  '[ $rc -eq 2 ] && [ "$(printf "%s\n" "$out" | grep -c "^DEAD ")" -eq 2 ] && printf "%s\n" "$out" | grep -q "^DEAD 500 private/journal/" && [ "$(grep -c . "$LOG")" -eq 3 ]'
out=$(run_in "$INST/public" --root .. products/sound.md); rc=$?
check "a path from the current directory under --root, every link live: exit 0" \
  '[ $rc -eq 0 ] && [ "$out" = "linkcheck: 0 dead link(s) in 0 file(s), 1 url(s) asked, 0 ignored" ]'

# -- 3. the cap ---------------------------------------------------------------------------------------
CAP="$TMP/many"
mkdir -p "$CAP/common/scripts" "$CAP/public"
cp "$LIB" "$CAP/common/scripts/lib-scopes.sh"
printf '%s\n' 'CATALOGS=""' > "$CAP/.conf"
for i in $(seq 1 130); do printf 'line %d: https://dead.example.test/guide\n' "$i"; done > "$CAP/public/many.md"
out=$(run_in "$CAP"); rc=$?
check "130 dead occurrences: every one reported, the exit code capped at 125" \
  '[ $rc -eq 125 ] && [ "$(printf "%s\n" "$out" | grep -c "^DEAD ")" -eq 130 ] && printf "%s\n" "$out" | grep -qxF "linkcheck: 130 dead link(s) in 1 file(s), 1 url(s) asked, 0 ignored"'

# -- 4. the refusals -----------------------------------------------------------------------------------
mkdir -p "$TMP/nocurl" "$TMP/bare"
out=$(cd "$INST" && PATH="$TMP/nocurl" "$BASH" "$LINKCHECK" 2>&1 < /dev/null); rc=$?
check "no curl on PATH is refused with exit 2, saying so" '[ $rc -eq 2 ] && printf "%s\n" "$out" | grep -q "no curl on PATH"'
out=$(run --root "$TMP/bare"); rc=$?
check "a root with no .conf is refused with exit 2" '[ $rc -eq 2 ] && printf "%s\n" "$out" | grep -q "holds no .conf"'
out=$(run --frobnicate); rc=$?
check "an unknown option is a usage error (exit 2)" '[ $rc -eq 2 ]'
out=$(run no/such/file.md); rc=$?
check "a path that does not exist is a usage error (exit 2)" '[ $rc -eq 2 ]'
check "a refusal asks nothing" '[ ! -s "$LOG" ]'
out=$(run --help); rc=$?
check "--help prints the header and exits 0" '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "linkcheck: <n> dead link(s)"'

# -- 5. the sources convention, and nothing written ------------------------------------------------------
if [ -n "$FIND" ]; then
  out=$(cd "$INST" && bash common/scripts/find.sh -f url 2>&1 < /dev/null); rc=$?
  check "find.sh -f url lists the leaf with its _url:_ marker" \
    '[ $rc -eq 0 ] && [ "$out" = "public/products/lantern.md	https://live.example.test/lantern" ]'
  out=$(cd "$INST" && bash common/scripts/find.sh -f 'accessed<2026-06-01' 2>&1 < /dev/null); rc=$?
  check "find.sh -f 'accessed<date' finds the source last read before it" \
    '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -qxF "public/products/lantern.md	2026-01-15"'
else
  info "no find.sh beside the module: the marker-line query is not run"
fi
check "the fixture instance was never written to" '[ "$(digest "$INST")" = "$before" ]'

echo "== linkcheck module check: $FAIL fail(s) =="
exit $FAIL
