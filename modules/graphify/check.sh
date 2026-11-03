#!/bin/bash
# check.sh — the graphify module's own check: proves graphs.sh end to end in a throwaway
# instance, with a SHIM graphify on PATH, so the check runs on a machine with no graphify
# installed and never touches a real graph. Exits with its fail count.
#
# Usage: bash modules/graphify/check.sh    (from the template checkout or an instance root)
#
# It builds one fake instance (a .conf, the core lib, a .gitignore as the deployer writes it)
# and one fake repository beside it, then proves: home lays down the four things and links
# graphify-out into graphs/<slug>/live/; a rerun writes nothing; a standalone graphify-out/
# directory is moved into live/ and linked; a link elsewhere is refused; an unknown slug is
# refused with nothing written; scan with no graphify on PATH fails with the install hint and
# writes nothing; a pinned version refuses another; scan over the shim snapshots the graph,
# writes the index row and registers nothing it should not; a rerun is byte-identical; check
# reports the snapshot current, then stale after a new commit; the instance lints clean.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GRAPHS_SH="$HERE/graphs.sh"
LIB=""
for c in "$HERE/../../scripts/lib-scopes.sh" "$HERE/../../blueprint/scripts/lib-scopes.sh" "$PWD/scripts/lib-scopes.sh"; do
  [ -f "$c" ] && { LIB=$c; break; }
done
[ -n "$LIB" ] || { echo "cannot find scripts/lib-scopes.sh beside the module" >&2; exit 2; }
CURE=""
for c in "$HERE/../../scripts/cure.sh" "$PWD/scripts/cure.sh"; do [ -f "$c" ] && { CURE=$c; break; }; done

FAIL=0
ok()   { printf '[ OK ] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '[INFO] %s\n' "$1"; }
check() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/graphify-check.XXXXXX") || { echo "cannot create a temporary directory" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
INST="$TMP/instance" REPO="$TMP/lantern" SHIM="$TMP/bin"
# a digest of every file under a directory, links read as links, to prove a run wrote nothing
digest() { (cd "$1" && find . \( -type f -o -type l \) ! -path '*/.git/*' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum); }
link_target() { readlink "$1"; }
same_dir() { [ "$(cd "$1" 2>/dev/null && pwd -P)" = "$(cd "$2" 2>/dev/null && pwd -P)" ]; }

echo "== graphify module check — $(date '+%Y-%m-%d %H:%M') =="

# -- the fake instance and repository ---------------------------------------------------------------
mkdir -p "$INST/scripts" "$INST/public/products" "$REPO/src"
cp "$LIB" "$INST/scripts/lib-scopes.sh"
printf '%s\n' 'CATALOGS="products"' 'GRAPHS="lantern=../lantern"' > "$INST/.conf"
printf '%s\n' "# This machine's development-cycle tree: a repository of its own." "/private/" \
  "# This machine's settings: who the user is and what search covers." "/.conf" > "$INST/.gitignore"
printf '%s\n' '# Public' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' \
  '| [Products](./products/.index.md) | the products |' > "$INST/public/.index.md"
printf '%s\n' '# Products' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' > "$INST/public/products/.index.md"
printf '%s\n' products > "$INST/public/products/.tags"
printf '%s\n' 'export function lamp() { return 1; }' > "$REPO/src/lamp.ts"
printf '%s\n' 'node_modules/' > "$REPO/.gitignore"
HAVE_GIT=0
G=(git -c user.name=check -c user.email=check@example.invalid -c core.autocrlf=false -c core.safecrlf=false)
if command -v git >/dev/null 2>&1; then
  "${G[@]}" -C "$REPO" init -q && "${G[@]}" -C "$REPO" add -A && "${G[@]}" -C "$REPO" commit -qm "first" && HAVE_GIT=1
fi
run() { (cd "$INST" && bash "$GRAPHS_SH" "$@" 2>&1); }
# PATH without any directory that holds a graphify, for the not-installed case; every other tool stays
NOGRAPHIFY=$(IFS=:; for d in $PATH; do [ -x "$d/graphify" ] || [ -x "$d/graphify.exe" ] || printf '%s:' "$d"; done)

# -- 1. home ------------------------------------------------------------------------------------------
out=$(run home lantern); rc=$?
check "home exits 0${rc:+ (rc=$rc: $(printf '%s\n' "$out" | grep -E '^\[FAIL\]|^refused|^usage' | head -n 1))}" '[ $rc -eq 0 ]'
check "home seeds the repository's .graphifyignore with graphify-out/ in it" 'grep -qx "graphify-out/" "$REPO/.graphifyignore"'
check "home appends graphify-out/ to the repository's .gitignore and keeps its lines" \
  'grep -qx "graphify-out/" "$REPO/.gitignore" && grep -qx "node_modules/" "$REPO/.gitignore"'
check "home links graphify-out into graphs/lantern/live/" '[ -L "$REPO/graphify-out" ] && same_dir "$REPO/graphify-out" "$INST/graphs/lantern/live"'
check "home appends the graphs/ block to the instance's .gitignore and keeps the deployer's lines" \
  'grep -qx "graphs/\*/\*" "$INST/.gitignore" && grep -qx "!graphs/\*/graph.json" "$INST/.gitignore" && grep -qx "/graphify-out/" "$INST/.gitignore" && grep -qx "/private/" "$INST/.gitignore"'
check "home scaffolds graphs/.index.md, .tags and .agent" '[ -f "$INST/graphs/.index.md" ] && [ -s "$INST/graphs/.tags" ] && [ -f "$INST/graphs/.agent" ]'
check "the scaffold index has a Contents table with no row yet" \
  'grep -q "^| File | Purpose |$" "$INST/graphs/.index.md" && [ "$(grep -c "graph.json" "$INST/graphs/.index.md")" -eq 1 ]'

# -- 2. a rerun writes nothing ------------------------------------------------------------------------
before=$(digest "$TMP")
out=$(run home lantern); rc=$?
check "a second home exits 0 and writes nothing" '[ $rc -eq 0 ] && [ "$(digest "$TMP")" = "$before" ]'
check "no line was appended twice" '[ "$(grep -cx "graphify-out/" "$REPO/.gitignore")" -eq 1 ] && [ "$(grep -cx "graphs/\*/\*" "$INST/.gitignore")" -eq 1 ]'
printf '%s\n' '# mine' 'graphify-out/' 'vendor/' > "$REPO/.graphifyignore"
mine=$(sha256sum "$REPO/.graphifyignore")
run home lantern >/dev/null 2>&1
check "an existing .graphifyignore is never rewritten" '[ "$(sha256sum "$REPO/.graphifyignore")" = "$mine" ]'

# -- 3. check before any scan -------------------------------------------------------------------------
out=$(PATH="$SHIM:$PATH" run check); rc=$?
check "check after home: 0 fails, the unscanned repository a warning" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[WARN\] lantern: homed but never scanned"'

# -- 4. a standalone graphify-out/ directory is adopted -------------------------------------------------
(cd "$REPO" && { if [ -d graphify-out ] && [ -L graphify-out ]; then case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) MSYS_NO_PATHCONV=1 cmd /c rmdir "$(cygpath -w "$REPO/graphify-out")" ;; *) rm graphify-out ;; esac; fi; })
rm -rf "$INST/graphs/lantern/live"
mkdir -p "$REPO/graphify-out" && printf '%s\n' '{"nodes":[],"links":[]}' > "$REPO/graphify-out/old.json"
out=$(run home lantern); rc=$?
check "a real graphify-out/ is moved into live/ and replaced by the link" \
  '[ $rc -eq 0 ] && [ -L "$REPO/graphify-out" ] && [ -f "$INST/graphs/lantern/live/old.json" ]'
rm -f "$INST/graphs/lantern/live/old.json"

# -- 5. the refusals -----------------------------------------------------------------------------------
mkdir -p "$TMP/elsewhere"
(cd "$REPO" && case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) MSYS_NO_PATHCONV=1 cmd /c rmdir "$(cygpath -w "$REPO/graphify-out")" >/dev/null; MSYS_NO_PATHCONV=1 cmd /c mklink /J "$(cygpath -w "$REPO/graphify-out")" "$(cygpath -w "$TMP/elsewhere")" >/dev/null ;; *) rm graphify-out; ln -s "$TMP/elsewhere" graphify-out ;; esac)
before=$(digest "$INST")
out=$(run home lantern); rc=$?
check "a graphify-out linked elsewhere is refused and the instance untouched" \
  '[ $rc -eq 1 ] && printf "%s\n" "$out" | grep -q "^\[FAIL\] lantern: .*links to" && [ "$(digest "$INST")" = "$before" ]'
(cd "$REPO" && case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) MSYS_NO_PATHCONV=1 cmd /c rmdir "$(cygpath -w "$REPO/graphify-out")" >/dev/null ;; *) rm graphify-out ;; esac)
run home lantern >/dev/null 2>&1
before=$(digest "$TMP")
out=$(run home beacon); rc=$?
check "an unknown slug is refused (exit 2) with nothing written" '[ $rc -eq 2 ] && printf "%s\n" "$out" | grep -q "^refused: unknown slug" && [ "$(digest "$TMP")" = "$before" ]'
out=$(run scan --root "$TMP/elsewhere"); rc=$?
check "a root with no .conf is refused (exit 2)" '[ $rc -eq 2 ]'
out=$(PATH="$NOGRAPHIFY" run scan); rc=$?
check "scan with no graphify on PATH fails with the install hint and writes nothing" \
  '[ $rc -ge 1 ] && printf "%s\n" "$out" | grep -q "uv tool install \"graphifyy\[mcp\]\"" && [ "$(digest "$TMP")" = "$before" ]'

# -- 6. the shim: a graphify that writes a small graph through the link ---------------------------------
mkdir -p "$SHIM"
cat > "$SHIM/graphify" <<'SHIM'
#!/bin/bash
# a stand-in graphify: --version, extract (writes graph.json and manifest.json into
# ./graphify-out, stamped with the repository's HEAD) and global add (a no-op)
case "${1:-}" in
  --version) echo "graphify ${GRAPHIFY_SHIM_VERSION:-1.2.3}" ;;
  extract)
    commit=$(git rev-parse HEAD 2>/dev/null || echo "-")
    mkdir -p graphify-out
    printf '{"built_at_commit":"%s","directed":false,"graph":{},"hyperedges":[],"links":[{"source":"a","target":"b"}],"multigraph":false,"nodes":[{"id":"a","community":0},{"id":"b","community":0},{"id":"c","community":1}]}\n' "$commit" > graphify-out/graph.json
    printf '{}\n' > graphify-out/manifest.json
    mkdir -p graphify-out/cache && printf 'x' > graphify-out/cache/entry ;;
  global) exit 0 ;;
  *) echo "shim: unknown $*" >&2; exit 1 ;;
esac
SHIM
chmod +x "$SHIM/graphify"
printf '%s\n' 'GRAPHIFY_VERSION=9.9.9' >> "$INST/.conf"
before=$(digest "$TMP")
out=$(PATH="$SHIM:$PATH" run scan); rc=$?
check "a pinned GRAPHIFY_VERSION refuses another graphify and writes nothing" \
  '[ $rc -ge 1 ] && printf "%s\n" "$out" | grep -q "pins 9.9.9" && printf "%s\n" "$out" | grep -q "graphifyy\[mcp\]==9.9.9" && [ "$(digest "$TMP")" = "$before" ]'
sed -i.bak 's/^GRAPHIFY_VERSION=.*/GRAPHIFY_VERSION=1.2.3/' "$INST/.conf" && rm -f "$INST/.conf.bak"

# -- 7. scan over the shim ----------------------------------------------------------------------------
out=$(PATH="$SHIM:$PATH" run scan); rc=$?
check "scan exits 0 over the shim${rc:+ (rc=$rc: $(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
check "the live layer holds the scan and the snapshot is its copy" \
  '[ -f "$INST/graphs/lantern/live/graph.json" ] && cmp -s "$INST/graphs/lantern/live/graph.json" "$INST/graphs/lantern/graph.json"'
check "the index row carries the counts, the commit and the pin" \
  'grep -q "^| \[lantern/graph.json\](./lantern/graph.json) | lantern — 3 nodes, 1 edges, 2 communities; built at " "$INST/graphs/.index.md" && grep -q "(graphify 1.2.3, code-only) |$" "$INST/graphs/.index.md"'
check "the authored prose above the Contents table survives the rewrite" 'grep -q "^# Graphs$" "$INST/graphs/.index.md" && grep -q "never hand-edited" "$INST/graphs/.index.md"'
before=$(digest "$INST")
out=$(PATH="$SHIM:$PATH" run scan); rc=$?
check "a rerun over unchanged source is byte-identical" '[ $rc -eq 0 ] && [ "$(digest "$INST")" = "$before" ]'
out=$(PATH="$SHIM:$PATH" run check); rc=$?
check "check reports the snapshot current and the index matching" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[ OK \] lantern: 3 nodes" && printf "%s\n" "$out" | grep -q "^\[ OK \] graphs/.index.md matches"'
if [ $HAVE_GIT -eq 1 ]; then
  printf '%s\n' 'export function wick() { return 2; }' > "$REPO/src/wick.ts"
  "${G[@]}" -C "$REPO" add -A && "${G[@]}" -C "$REPO" commit -qm "second"
  out=$(PATH="$SHIM:$PATH" run check); rc=$?
  check "check warns the snapshot stale after a new commit, as a warning not a fail" \
    '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[WARN\] lantern: snapshot built at .* stale"'
else
  info "no git: the staleness warning is not checked"
fi
printf '%s\n' '| [ghost/graph.json](./ghost/graph.json) | a row nobody generated |' >> "$INST/graphs/.index.md"
out=$(PATH="$SHIM:$PATH" run check); rc=$?
check "a hand-added index row is reported as drift" '[ $rc -ge 1 ] && printf "%s\n" "$out" | grep -q "graphs/.index.md drifts"'
PATH="$SHIM:$PATH" run scan >/dev/null 2>&1
check "scan repairs the index" '! grep -q ghost "$INST/graphs/.index.md"'

# -- 8. the instance still lints (graphs/ sits beside public/, outside the linted trees) ----------------
if [ -n "$CURE" ]; then
  out=$(cd "$INST" && bash "$CURE" --fast 2>&1); rc=$?
  check "cure.sh over the instance: 0 fails${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
else
  info "no cure.sh beside the module: the lint step is not run"
fi

echo "== graphify module check: $FAIL fail(s) =="
exit $FAIL
