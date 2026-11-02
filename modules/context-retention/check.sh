#!/bin/bash
# check.sh — the context-retention module's own check: proves meta.sh end to end in a throwaway
# HOME with a fake instance and two fake projects, so nothing it does touches the user's map or
# git configuration. Exits with its fail count.
#
# Usage: bash modules/context-retention/check.sh    (from the template checkout or an instance root)
#
# It proves: init writes the identity once (a rerun keeps it) and never writes a path; the file is
# the closed shape; the projects come from the instance's workspace file; the excludes line lands
# on a yes (the key set when it was unset) and not on a no, and never twice; check reports a moved
# project once and then current, a copied project as a copy, a malformed file as a fail, a project
# with no identity as information; list prints the map; the refusals write nothing; a non-
# interactive init without an answer writes nothing to git; the instance still lints.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
META_SH="$HERE/meta.sh"
LIB=""
for c in "$HERE/../../scripts/lib-scopes.sh" "$HERE/../../template/scripts/lib-scopes.sh" "$PWD/scripts/lib-scopes.sh"; do
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

TMP=$(mktemp -d "${TMPDIR:-/tmp}/retention-check.XXXXXX") || { echo "cannot create a temporary directory" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
HOME_T="$TMP/home" INST="$TMP/instance" A="$TMP/lantern" B="$TMP/Beacon Works"
MAP="$HOME_T/.config/agentcontext/projects" IGN="$HOME_T/.config/git/ignore"
digest() { (cd "$1" && find . -type f ! -path '*/.git/*' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum); }
# every run sees the throwaway HOME and no XDG override, and stdin is not a terminal
run() { (cd "$INST" && HOME="$HOME_T" XDG_CONFIG_HOME= bash "$META_SH" "$@" 2>&1 < /dev/null); }
G=(git -c user.name=check -c user.email=check@example.invalid -c core.autocrlf=false -c core.safecrlf=false)

echo "== context-retention module check — $(date '+%Y-%m-%d %H:%M') =="

# -- the fake instance and two projects beside it -----------------------------------------------
mkdir -p "$HOME_T" "$INST/scripts" "$INST/public/products" "$A/src" "$B"
cp "$LIB" "$INST/scripts/lib-scopes.sh"
printf '%s\n' 'CATALOGS="products"' > "$INST/.conf"
printf '%s\n' '# Public' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' \
  '| [Products](./products/.index.md) | the products |' > "$INST/public/.index.md"
printf '%s\n' '# Products' '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' > "$INST/public/products/.index.md"
printf '%s\n' products > "$INST/public/products/.tags"
printf '%s\n' '{' '  "folders": [' '    { "name": "Knowledge Tree", "path": "." },' \
  '    { "name": "Knowledge Tree (Private)", "path": "./private" },' \
  '    { "name": "lantern", "path": "../lantern" },' '    { "name": "Beacon", "path": "../Beacon Works" },' \
  '    { "name": "gone", "path": "../gone" }' '  ]' '}' > "$INST/Example.code-workspace"
HAVE_GIT=0
if command -v git >/dev/null 2>&1; then
  "${G[@]}" -C "$A" init -q && printf '%s\n' 'export function lamp() {}' > "$A/src/lamp.ts" && "${G[@]}" -C "$A" add -A && "${G[@]}" -C "$A" commit -qm first && HAVE_GIT=1
fi

# -- 1. init over the workspace, the excludes question answered no --------------------------------
out=$(run init --no); rc=$?
check "init --no exits 0${rc:+ (rc=$rc: $(printf '%s\n' "$out" | grep -E '^\[FAIL\]|^refused|^usage' | head -n 1))}" '[ $rc -eq 0 ]'
check "the instance and both workspace folders have .agents/.id.meta; the missing folder is skipped" \
  '[ -f "$INST/.agents/.id.meta" ] && [ -f "$A/.agents/.id.meta" ] && [ -f "$B/.agents/.id.meta" ] && [ ! -e "$TMP/gone" ]'
check "the file is the closed shape: id=, name=, created= and nothing else" \
  '[ "$(cut -d= -f1 "$A/.agents/.id.meta" | tr "\n" " ")" = "id name created " ] && [ "$(wc -l < "$A/.agents/.id.meta")" -eq 3 ]'
check "the id is <slug>-<6 hex> and the name the slug; a folder with a space and capitals slugs cleanly" \
  'grep -qE "^id=lantern-[0-9a-f]{6}$" "$A/.agents/.id.meta" && grep -qx "name=lantern" "$A/.agents/.id.meta" && grep -qE "^id=beacon-works-[0-9a-f]{6}$" "$B/.agents/.id.meta"'
check "no path anywhere in the identity files" '! grep -qiE "/|\\\\" "$INST/.agents/.id.meta" "$A/.agents/.id.meta" "$B/.agents/.id.meta"'
check "the map records all three with their paths" \
  '[ -f "$MAP" ] && [ "$(wc -l < "$MAP")" -eq 3 ] && grep -q "^lantern-[0-9a-f]\{6\}	lantern	.*/lantern	" "$MAP" && grep -q "	beacon-works	.*/Beacon Works	" "$MAP"'
check "the no path printed the reason and wrote nothing to git" \
  'printf "%s\n" "$out" | grep -q "must never be committed" && [ ! -f "$IGN" ] && ! HOME="$HOME_T" git config --global --get core.excludesFile >/dev/null 2>&1'
if [ $HAVE_GIT -eq 1 ]; then
  check "a project git does not ignore it is warned about" 'printf "%s\n" "$out" | grep -q "^\[WARN\] lantern: git does not ignore"'
fi
idA=$(sed -n 's/^id=//p' "$A/.agents/.id.meta")

# -- 2. a rerun keeps the identity; a non-interactive run with no answer writes nothing ------------
before=$(digest "$TMP")
out=$(run init); rc=$?
check "a second init exits 0, keeps every id and writes nothing (no terminal, no answer: not written)" \
  '[ $rc -eq 0 ] && [ "$(digest "$TMP")" = "$before" ] && printf "%s\n" "$out" | grep -q "no terminal to ask on"'

# -- 3. the yes path ------------------------------------------------------------------------------
out=$(run init --yes); rc=$?
check "init --yes sets core.excludesFile when it was unset and writes the one line" \
  '[ $rc -eq 0 ] && [ "$(HOME="$HOME_T" git config --global --get core.excludesFile)" = "~/.config/git/ignore" ] && [ "$(cat "$IGN")" = ".agents/.id.meta" ]'
if [ $HAVE_GIT -eq 1 ]; then
  check "git now ignores the file in the project" '(cd "$A" && HOME="$HOME_T" git check-ignore -q .agents/.id.meta)'
fi
out=$(run init --yes); rc=$?
check "a third init --yes appends nothing twice" '[ $rc -eq 0 ] && [ "$(grep -c "id.meta" "$IGN")" -eq 1 ] && printf "%s\n" "$out" | grep -q "already ignores"'
printf '%s\n' '*.log' > "$IGN"; HOME="$HOME_T" git config --global --unset core.excludesFile
out=$(run init --yes); rc=$?
check "with the key unset and the default file present, the line is appended to it and its lines kept" \
  '[ $rc -eq 0 ] && grep -qx "\*.log" "$IGN" && grep -qx ".agents/.id.meta" "$IGN"'

# -- 4. check: current, then a move, then current again -------------------------------------------
out=$(run check); rc=$?
check "check after init: 0 fails, every project current" '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep -c "^\[ OK \]")" -eq 3 ]'
mv "$A" "$TMP/lamp"; sed -i.bak 's|"\.\./lantern"|"../lamp"|' "$INST/Example.code-workspace" && rm -f "$INST/Example.code-workspace.bak"
out=$(run check); rc=$?
check "check reports the moved project once, with the old and the new path, as a warning" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[WARN\] lantern: $idA moved — was at .*lantern, now at .*lamp"'
out=$(run check --porcelain); rc=$?
check "a second check sees it current; --porcelain prints tab-separated rows only" \
  '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep -c "^ok	$idA	")" -eq 1 ] && ! printf "%s\n" "$out" | grep -q "^\["'
check "the map now carries the new path" 'grep -q "^$idA	lantern	.*lamp	" "$MAP"'

# -- 5. a copy, a malformed file, a project without an identity ------------------------------------
cp -R "$TMP/lamp" "$TMP/lamp-copy"
out=$(run check ../lamp-copy); rc=$?
check "a copied folder is reported as a copy, not a move, and the map keeps the original" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "a copy, not a move" && grep -q "^$idA	lantern	.*/lamp	" "$MAP"'
printf 'id=%s\npath=/somewhere\n' "$idA" > "$TMP/lamp-copy/.agents/.id.meta"
out=$(run check ../lamp-copy); rc=$?
check "a file outside the closed shape is a fail" '[ $rc -eq 1 ] && printf "%s\n" "$out" | grep -q "not the closed shape"'
mkdir -p "$TMP/plain"
out=$(run check ../plain); rc=$?
check "a project with no identity is information, not a fail" '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[INFO\] .*no .agents/.id.meta"'
out=$(run init --name 'Bad Name' ../plain --no); rc=$?
check "a slug outside [a-z0-9-] is refused" '[ $rc -eq 2 ]'

# -- 6. list, and the refusals write nothing ------------------------------------------------------
out=$(run list); rc=$?
check "list prints the map with one row per id" '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep -c "^  [a-z-]*-[0-9a-f]\{6\} ")" -eq 3 ]'
before=$(digest "$TMP")
out=$(cd "$TMP" && HOME="$HOME_T" bash "$META_SH" list 2>&1); rc=$?
check "a root with no .conf is refused (exit 2) with nothing written" '[ $rc -eq 2 ] && [ "$(digest "$TMP")" = "$before" ]'
out=$(run frobnicate); rc=$?
check "an unknown verb is a usage error (exit 2)" '[ $rc -eq 2 ]'

# -- 7. the instance still lints ---------------------------------------------------------------------
if [ -n "$CURE" ]; then
  out=$(cd "$INST" && bash "$CURE" --fast 2>&1); rc=$?
  check "cure.sh over the instance: 0 fails${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
else
  info "no cure.sh beside the module: the lint step is not run"
fi

echo "== context-retention module check: $FAIL fail(s) =="
exit $FAIL
