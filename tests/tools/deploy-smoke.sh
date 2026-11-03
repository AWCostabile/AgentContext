#!/bin/bash
# deploy-smoke.sh — this repository's gate for the deployer: it deploys throwaway
# instances from the COMMITTED tree, lints them, updates one, proves the refusals, lints
# every worked example as of its snapshot date, runs tests/check.sh, the scripts' own
# check over the fixture tree, updates instances of the last release through the move
# rule onto the common directory, and adopts modules into instances and updates over them.
#
# Usage: bash tests/tools/deploy-smoke.sh   (from anywhere; no arguments)
#
# Prints one [ OK ] / [FAIL] line per assertion ([WARN] and [INFO] never count) and
# exits with the number of fails. Never copied into an instance. Its temporary
# directories are removed on exit.

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$REPO" || exit 1

FAIL=0
ok()   { printf '[ OK ] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
warn() { printf '[WARN] %s\n' "$1"; }
info() { printf '[INFO] %s\n' "$1"; }
check() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }   # check <label> <condition>

TMP=$(mktemp -d "${TMPDIR:-/tmp}/deploy-smoke.XXXXXX") || { echo "cannot create a temporary directory" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
SRC="$TMP/src" CONF="$TMP/my.conf" INIT="$TMP/src/init.sh"

# The placeholder residue of an instance, as init.sh defines it: inside the trees any
# brace pair at all; in the root documents, which name the syntax in prose, a {{ that
# opens a name. templates/ keeps its placeholders on purpose.
residue() {
  (
    cd "$1" || exit 1
    for t in public private; do [ -d "$t" ] && grep -rlE --exclude-dir=.git '\{\{|\}\}' "$t"; done
    grep -rlE '\{\{[A-Za-z]' --exclude-dir=templates --exclude-dir=public --exclude-dir=private \
      --exclude-dir=.git .
  )
}
# a digest of every file under a directory, to prove a run wrote nothing
tree_digest() { (cd "$1" && find . -type f ! -path './private/.git/*' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum); }
# The editor reads its workspace and settings files as JSON with comments, so a full-line
# // comment is stripped before the strict parse.
json_ok() {
  if python -c pass >/dev/null 2>&1; then
    python -I -c 'import json,re,sys; json.loads(re.sub(r"^[ \t]*//.*$", "", open(sys.argv[1], encoding="utf-8").read(), flags=re.M))' "$1"
  elif command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8").replace(/^[ \t]*\/\/.*$/mg, ""))' "$1"
  else
    return 2
  fi
}

echo "== deploy smoke — $(date '+%Y-%m-%d %H:%M') =="

# -- 1. the committed tree is the source -------------------------------------------------
[ -n "$(git status --porcelain)" ] && warn "the worktree is dirty; the smoke proves HEAD, not the worktree"
mkdir -p "$SRC" && git archive HEAD | tar -x -C "$SRC"
check "git archive of HEAD extracted as the source" '[ -f "$INIT" ] && [ -f "$SRC/blueprint/AGENTS.md" ]'

# -- 2. deploy -------------------------------------------------------------------------------
# PRIVATE_SCOPES and ORCH_BUDGET are dropped so the deployer has to derive them.
sed -e 's/^CATALOGS=.*/CATALOGS="products projects"/' -e '/^PRIVATE_SCOPES=/d' -e '/^ORCH_BUDGET=/d' \
  "$REPO/blueprint/common/.conf.example" > "$CONF"
I1="$TMP/instance"
out=$(bash "$INIT" --from "$SRC" --target "$I1" --conf "$CONF" --name Example 2>&1); rc=$?
printf '%s\n' "$out" | sed 's/^/       /'
check "install exits 0" '[ $rc -eq 0 ]'
check "install reports done: <target>" 'printf "%s\n" "$out" | grep -q "^done: $I1\$"'

# -- 3. the instance -----------------------------------------------------------------------
left=$(residue "$I1")
check "no placeholder outside templates/${left:+ (left: $(printf '%s' "$left" | tr '\n' ' '))}" '[ -z "$left" ]'
check "public/products/ and public/projects/ exist, public/catalog/ does not" \
  '[ -f "$I1/public/products/.index.md" ] && [ -f "$I1/public/projects/.index.md" ] && [ ! -e "$I1/public/catalog" ]'
check "private/products/ and private/projects/ exist, private/catalog/ does not" \
  '[ -f "$I1/private/products/.index.md" ] && [ -f "$I1/private/projects/.index.md" ] && [ ! -e "$I1/private/catalog" ]'
check "private/ is a repository of its own" '[ -d "$I1/private/.git" ]'
if [ -f "$I1/Example.code-workspace" ]; then
  json_ok "$I1/Example.code-workspace"; jrc=$?
  if [ $jrc -eq 2 ]; then info "no JSON parser: Example.code-workspace not parsed"
  else check "Example.code-workspace parses as JSON" '[ $jrc -eq 0 ]'; fi
  check "the workspace holds the tree and ./private, no sibling" \
    'grep -c "\"path\":" "$I1/Example.code-workspace" | grep -q "^2$" && ! grep -q "\.\./" "$I1/Example.code-workspace"'
else
  fail "Example.code-workspace exists"
fi
check ".vscode/extensions.json and settings.json present" \
  '[ -f "$I1/.vscode/extensions.json" ] && [ -f "$I1/.vscode/settings.json" ]'
ncore=$(sed '1,/^$/d' "$I1/common/.agentcontext" 2>/dev/null | grep -c .)
check "common/.agentcontext names ref=working-tree and lists $ncore core files (at least 20)" \
  'grep -q "^ref=working-tree$" "$I1/common/.agentcontext" && [ "$ncore" -ge 20 ]'
check ".gitignore names /private/ and /.conf" \
  'grep -q "^/private/$" "$I1/.gitignore" && grep -q "^/\.conf$" "$I1/.gitignore"'
check ".conf gained the derived PRIVATE_SCOPES and ORCH_BUDGET" \
  'grep -q "^PRIVATE_SCOPES=\"products projects journal\"$" "$I1/.conf" && grep -q "^ORCH_BUDGET=full$" "$I1/.conf"'
check "README.md is the reader page, named after the instance, with no placeholder left" \
  '[ -f "$I1/README.md" ] && [ "$(head -n 1 "$I1/README.md")" = "# Example" ] && ! grep -q "{{" "$I1/README.md"'
check "README.md is listed in the manifest as a core file" 'grep -q "  README.md$" "$I1/common/.agentcontext"'
check "no tests/ directory is laid into an instance" '[ ! -e "$I1/tests" ]'
root1=$(ls -A "$I1" | LC_ALL=C sort | tr '\n' ' ')   # the fresh root, judged in section 18

# -- 4. the instance lints clean ----------------------------------------------------------------
cure=$(bash "$I1/common/scripts/cure.sh" --root "$I1" 2>&1); crc=$?
info "cure: $(printf '%s\n' "$cure" | grep '^== VERDICT')"
check "cure.sh reports 0 fails on the instance" '[ $crc -eq 0 ]'
smell=$(bash "$I1/common/scripts/smell.sh" --root "$I1" --quiet 2>&1); src=$?
info "smell: $(printf '%s\n' "$smell" | grep '^== SUMMARY')"
if [ $src -eq 0 ]; then ok "smell.sh reports 0 smells on the instance"
else warn "smell.sh reports $src smell(s):"; bash "$I1/common/scripts/smell.sh" --root "$I1" | grep '^\[SMELL'; fi

# -- 5. an update from the same source changes nothing --------------------------------------------
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
check "update from the same source: 0 moved, 0 replaced, 0 kept, 0 added, 0 removed-upstream" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^update: 0 moved, 0 replaced, 0 kept, 0 added, 0 removed-upstream$"'

# -- 6. a local edit is kept; a dry run writes nothing ----------------------------------------------
printf '%s\n' "A local note." >> "$I1/common/rules/branch-grammar.md"
edited=$(sha256sum < "$I1/common/rules/branch-grammar.md")
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
report=$(printf '%s\n' "$out" | grep '^update: ')
check "a locally edited core file is reported kept, exactly once" \
  '[ $rc -eq 0 ] && [ "$report" = "update: 0 moved, 0 replaced, 1 kept, 0 added, 0 removed-upstream" ] && printf "%s\n" "$out" | grep -q "^kept common/rules/branch-grammar.md (changed locally)$"'
check "the kept file is unchanged" '[ "$(sha256sum < "$I1/common/rules/branch-grammar.md")" = "$edited" ]'
before=$(tree_digest "$I1")
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" --dry-run 2>&1); rc=$?
check "--dry-run prints the same report" '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep "^update: ")" = "$report" ]'
check "--dry-run writes nothing" '[ "$(tree_digest "$I1")" = "$before" ]'

# -- 7. no private tree -------------------------------------------------------------------------------
I2="$TMP/instance2"
out=$(bash "$INIT" --from "$SRC" --target "$I2" --conf "$CONF" --no-private 2>&1); rc=$?
check "--no-private installs, with no private/ directory" '[ $rc -eq 0 ] && [ -d "$I2/public" ] && [ ! -e "$I2/private" ]'
bash "$I2/common/scripts/cure.sh" --root "$I2" >/dev/null 2>&1; crc=$?
check "cure.sh reports 0 fails on the instance without a private tree" '[ $crc -eq 0 ]'

# -- 8. an adapter without a payload refuses ---------------------------------------------------------------
STUB=""
for d in "$SRC"/adapters/*/; do
  [ -d "$d" ] || continue
  [ -n "$(find "${d}payload" -type f ! -path "${d}payload/README.md" 2>/dev/null)" ] && continue
  STUB=${d%/}; STUB=${STUB##*/}; break
done
[ -n "$STUB" ] || STUB=no-such-adapter
I3="$TMP/instance3"
err=$(bash "$INIT" --from "$SRC" --target "$I3" --conf "$CONF" --adapter "$STUB" 2>&1 >/dev/null); rc=$?
check "--adapter $STUB refuses with exit 2, naming it and listing the adapters" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "adapter .$STUB. has no payload in this release" && printf "%s\n" "$err" | grep -qE "(stub|written)$"'
check "nothing written at the refused target" '[ ! -e "$I3" ]'

# -- 9. the other refusals ---------------------------------------------------------------------------------
I4="$TMP/instance4"
mkdir -p "$I4" && printf 'x\n' > "$I4/notes.txt"
err=$(bash "$INIT" --from "$SRC" --target "$I4" --conf "$CONF" 2>&1 >/dev/null); rc=$?
check "a non-empty target refuses with exit 2" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "target is not empty" && [ "$(ls -A "$I4")" = notes.txt ]'
grep -v '^CATALOGS=' "$CONF" > "$TMP/bad.conf"
I5="$TMP/instance5"
err=$(bash "$INIT" --from "$SRC" --target "$I5" --conf "$TMP/bad.conf" 2>&1 >/dev/null); rc=$?
check "a .conf without CATALOGS refuses with exit 2, naming the key" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "missing key CATALOGS" && [ ! -e "$I5" ]'
err=$(bash "$INIT" --update --target "$I5" --from "$SRC" 2>&1 >/dev/null); rc=$?
check "--update on a directory with no .agentcontext refuses with exit 2" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "no .agentcontext at target"'

# -- 10. the first adapter with a payload lays down, and boots -------------------------------------------
# No harness is spelled here: the adapter is the first directory whose payload holds a file
# other than its README, and every assertion is derived from that payload.
ADP=""
for d in "$SRC"/adapters/*/; do
  [ -d "$d" ] || continue
  [ -n "$(find "${d}payload" -type f ! -path "${d}payload/README.md" 2>/dev/null)" ] || continue
  ADP=${d%/}; ADP=${ADP##*/}; break
done
if [ -z "$ADP" ]; then
  info "no adapter has a payload: adapter step not run"
else
  PAY="$SRC/adapters/$ADP/payload"
  I6="$TMP/instance6"
  out=$(bash "$INIT" --from "$SRC" --target "$I6" --conf "$CONF" --adapter "$ADP" 2>&1); rc=$?
  check "--adapter $ADP installs, exit 0" '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^done: $I6\$"'
  root6=$(ls -A "$I6" | LC_ALL=C sort | tr '\n' ' ')   # the fresh root, judged in section 18
  mapfile -t pfiles < <(cd "$PAY" && find . -type f | sed 's|^\./||' | grep -v '^README\.md$' | LC_ALL=C sort)
  missing=""
  for f in "${pfiles[@]}"; do cmp -s "$PAY/$f" "$I6/$f" || missing+="$f "; done
  check "all ${#pfiles[@]} payload files laid down byte for byte${missing:+ (missing or changed: $missing)}" '[ -z "$missing" ]'
  check "the payload README is not laid down" '! cmp -s "$PAY/README.md" "$I6/README.md" 2>/dev/null'
  imports=$(cd "$I6" && for f in *.md; do [ "$(cat "$f")" = "@AGENTS.md" ] && printf '%s ' "$f"; done)
  check "a root instruction file is the one line @AGENTS.md (${imports:-none})" '[ -n "$imports" ]'
  jbad="" jn=0
  for f in "${pfiles[@]}"; do
    case "$f" in *.json) ;; *) continue ;; esac
    json_ok "$I6/$f"; jrc=$?
    [ $jrc -eq 2 ] && { info "no JSON parser: $f not parsed"; continue; }
    jn=$((jn + 1)); [ $jrc -eq 0 ] || jbad+="$f "
  done
  check "$jn payload JSON file(s) parse${jbad:+ (bad: $jbad)}" '[ -z "$jbad" ]'
  mapfile -t hooks < <(cd "$I6" && for f in "${pfiles[@]}"; do case "$f" in *.json) grep -oE '[A-Za-z0-9_./-]*hooks/[A-Za-z0-9_-]+\.sh' "$f" ;; esac; done | sed 's|^.*/\([^/]*/hooks/\)|\1|' | LC_ALL=C sort -u)
  hmiss=""
  for h in "${hooks[@]}"; do [ -f "$I6/$h" ] || hmiss+="$h "; done
  check "the ${#hooks[@]} hook scripts the settings register are present (expected 6)${hmiss:+ (missing: $hmiss)}" \
    '[ ${#hooks[@]} -eq 6 ] && [ -z "$hmiss" ]'
  mlist=$(sed '1,/^$/d' "$I6/common/.agentcontext" 2>/dev/null | awk '{print $2}')
  mmiss=""
  for f in "${pfiles[@]}"; do printf '%s\n' "$mlist" | grep -qF -- "$f" || mmiss+="$f "; done
  check "common/.agentcontext carries adapter=$ADP and lists every payload file${mmiss:+ (unlisted: $mmiss)}" \
    'grep -q "^adapter=$ADP\$" "$I6/common/.agentcontext" && [ -z "$mmiss" ]'
  bash "$I6/common/scripts/cure.sh" --root "$I6" >/dev/null 2>&1; crc=$?
  check "cure.sh reports 0 fails on the instance with the adapter" '[ $crc -eq 0 ]'

  # the headless boot: the adapter's own boot check, when it ships one (exit 3 = not run)
  BOOT="$SRC/adapters/$ADP/boot-check.sh"
  if [ ! -f "$BOOT" ]; then
    info "headless boot not run: adapter $ADP ships no boot-check.sh"
  else
    boot=$(bash "$BOOT" "$I6" 2>&1); brc=$?
    if [ $brc -eq 3 ]; then
      info "headless boot not run: $(printf '%s' "$boot" | head -n 1)"
    else
      printf '%s\n' "$boot" | sed 's/^/       /'
      check "headless boot: the session start context reached the session" '[ $brc -eq 0 ]'
    fi
  fi
fi

# -- 11. every worked example lints clean ------------------------------------------------------------------
# An example is a deployed instance committed under examples/: any directory there holding a
# .conf. The repository's own scripts lint it, and it carries no placeholder outside templates/.
nex=0
for ex in "$SRC"/examples/*/; do
  [ -f "${ex}.conf" ] || continue
  ex=${ex%/}; name=${ex##*/}; nex=$((nex + 1))
  bash "$SRC/scripts/cure.sh" --root "$ex" >/dev/null 2>&1; crc=$?
  check "example $name: cure.sh reports 0 fails" '[ $crc -eq 0 ]'
  # An example is a snapshot: the calendar smells (S01, S21) are judged as of the day its
  # manifest was last written, so the lint is the same on any day.
  asof=$(sed -n 's/^updated=//p' "$ex/.agentcontext" | head -n 1)
  [ -n "$asof" ] || asof=$(sed -n 's/^installed=//p' "$ex/.agentcontext" | head -n 1)
  smells=$(bash "$SRC/scripts/smell.sh" --root "$ex" ${asof:+--today "$asof"} 2>/dev/null | grep '^\[SMELL ' || true)
  check "example $name: smell.sh reports 0 smells as of its snapshot date ${asof:-today}${smells:+ ($(printf '%s\n' "$smells" | head -n 1))}" '[ -z "$smells" ]'
  left=$(grep -rlE '\{\{[A-Za-z]' --exclude-dir=.git "$ex" | grep -v /templates/)
  check "example $name: no placeholder outside templates/${left:+ (left: $(printf '%s' "$left" | tr '\n' ' '))}" '[ -z "$left" ]'
done
[ $nex -eq 0 ] && info "no example holds a .conf: example step not run"

# -- 12. every example code map regenerates without drift ------------------------------------------------
# A generated code map's .agent names the command that wrote it, as run from the repository
# root; that command with --check, run from the source's root, must report no drift. The
# module's own reproducibility check runs beside it.
PY=""
for p in python3 python py; do
  if "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then PY=$p; break; fi
done
if [ -z "$PY" ]; then
  info "no Python 3.10+: code-map step not run"
else
  ncb=0
  for agent in "$SRC"/examples/*/public/*/*/codebase/.agent; do
    [ -f "$agent" ] || continue
    tier=${agent#"$SRC"/}; tier=${tier%/.agent}; ncb=$((ncb + 1))
    cmd=$(sed -n 's|^ *python[0-9]* \(modules/codebase/codebase\.py .*\)$|\1|p' "$agent" | head -n 1)
    if [ -z "$cmd" ]; then fail "code map $tier: its .agent names a codebase.py command"; continue; fi
    out=$(cd "$SRC" && "$PY" $cmd --check 2>&1); rc=$?
    drift=$(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 3 | tr '\n' ' ')
    check "code map $tier: --check reports no drift${drift:+ ($drift)}" '[ $rc -eq 0 ]'
  done
  [ $ncb -eq 0 ] && info "no example carries a code map: code-map drift not checked"
  out=$(PYTHON=$PY bash "$SRC/modules/codebase/check.sh" 2>&1); rc=$?
  check "modules/codebase/check.sh reports 0 fails${rc:+ ($(printf '%s\n' "$out" | tail -n 1))}" '[ $rc -eq 0 ]'
fi

# -- 13. the change-log module is the workflow this repository runs ---------------------------------------
# modules/change-log/post-merge.yml is the one source; .github/workflows/post-merge.yml is its copy.
if cmp -s "$SRC/modules/change-log/post-merge.yml" "$SRC/.github/workflows/post-merge.yml"; then same=1; else same=0; fi
check "the change-log module's workflow and .github/workflows/post-merge.yml are identical" '[ $same -eq 1 ]'

# -- 14. the graphify module: its own check, and homing a repository beside a deployed instance -----------
# The module's check proves the script end to end over a stand-in graphify. Here, on the first
# instance, home links a copy of the example repository into graphs/<slug>/live/, the instance
# still lints, and the workspace the deployer wrote hides the two tooling paths.
out=$(bash "$SRC/modules/graphify/check.sh" 2>&1); rc=$?
check "modules/graphify/check.sh reports 0 fails${rc:+ ($(printf '%s\n' "$out" | tail -n 1))}" '[ $rc -eq 0 ]'
cp -R "$SRC/examples/tillwright" "$TMP/tillwright"
mkdir -p "$I1/common/modules" && cp -R "$SRC/modules/graphify" "$I1/common/modules/graphify"
printf '%s\n' 'GRAPHS="tillwright=../tillwright"' >> "$I1/.conf"
out=$(cd "$I1" && bash common/modules/graphify/graphs.sh home tillwright 2>&1); rc=$?
check "graphify home on the instance exits 0${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]|^refused' | head -n 1))}" '[ $rc -eq 0 ]'
check "graphify-out in the repository links into the instance's graphs/tillwright/live/" \
  '[ -L "$TMP/tillwright/graphify-out" ] && [ "$(cd "$TMP/tillwright/graphify-out" && pwd -P)" = "$(cd "$I1/graphs/tillwright/live" && pwd -P)" ]'
check "the instance's .gitignore keeps graphs/*/graph.json and ignores the rest" \
  'grep -qx "graphs/\*/\*" "$I1/.gitignore" && grep -qx "!graphs/\*/graph.json" "$I1/.gitignore" && grep -qx "/private/" "$I1/.gitignore"'
out=$(cd "$I1" && bash common/scripts/cure.sh --fast 2>&1); rc=$?
check "the homed instance lints with 0 fails${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
check "the deployed workspace hides graphify-out and .graphifyignore" \
  'grep -q "\"\*\*/graphify-out\": true" "$I1/Example.code-workspace" && grep -q "\"\*\*/.graphifyignore\": true" "$I1/Example.code-workspace"'

# -- 15. the context-retention module: its own check, and init on a deployed instance with a throwaway HOME --
# The module's check proves the script in a throwaway HOME with two fake projects. Here, on the first
# instance, init with the excludes question answered no writes the identity and the map and nothing
# to git; the instance still lints; the workspace hides the file; and no identity file is anywhere in
# the committed tree, which the deployer never writes one into.
out=$(bash "$SRC/modules/context-retention/check.sh" 2>&1); rc=$?
check "modules/context-retention/check.sh reports 0 fails${rc:+ ($(printf '%s\n' "$out" | tail -n 1))}" '[ $rc -eq 0 ]'
mkdir -p "$I1/common/modules" && cp -R "$SRC/modules/context-retention" "$I1/common/modules/context-retention"
H="$TMP/home"; mkdir -p "$H"
out=$(cd "$I1" && HOME="$H" XDG_CONFIG_HOME= bash common/modules/context-retention/meta.sh init --no 2>&1 < /dev/null); rc=$?
check "retention init on the instance exits 0 and writes .agents/.id.meta there${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]|^refused|^usage' | head -n 1))}" \
  '[ $rc -eq 0 ] && [ -f "$I1/.agents/.id.meta" ]'
check "the identity is the closed shape, id=<slug>-<6 hex>, name= and created=, with no path" \
  '[ "$(cut -d= -f1 "$I1/.agents/.id.meta" | tr "\n" " ")" = "id name created " ] && grep -qE "^id=[a-z0-9-]+-[0-9a-f]{6}$" "$I1/.agents/.id.meta" && ! grep -q "/" "$I1/.agents/.id.meta"'
check "the no answer wrote nothing to git: no global configuration, no excludes file in the throwaway HOME" \
  '[ ! -f "$H/.gitconfig" ] && [ ! -e "$H/.config/git" ]'
check "the map in the throwaway HOME records the instance by id and path" \
  '[ -f "$H/.config/agentcontext/projects" ] && grep -q "^$(sed -n "s/^id=//p" "$I1/.agents/.id.meta")	" "$H/.config/agentcontext/projects"'
out=$(cd "$I1" && HOME="$H" XDG_CONFIG_HOME= bash common/modules/context-retention/meta.sh check 2>&1 < /dev/null); rc=$?
check "retention check on the instance: 0 fails, the instance current" '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^\[ OK \] .*: .* at "'
out=$(cd "$I1" && bash common/scripts/cure.sh --fast 2>&1); rc=$?
check "the instance with an identity lints with 0 fails${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
check "the deployed workspace hides **/.agents/.id.meta" 'grep -q "\"\*\*/.agents/.id.meta\": true" "$I1/Example.code-workspace"'
check "no identity file anywhere in the committed tree, and the deployer wrote none into a fresh instance" \
  '! git ls-files | grep -q "\.id\.meta$" && [ -z "$(find "$SRC" -name .id.meta)" ] && [ ! -e "$I6/.agents/.id.meta" ]'


# -- 16. the run-sheet's pinned release ships every path it names -------------------------------------------
# SETUP.md names one release and reads every file out of that release's archive; README.md's
# prompt fetches the same release's SETUP.md. A path the sheet names must exist in the release
# it pins: in the tag when it has been cut, in HEAD before it is (the tag is cut from HEAD).
PIN=$(sed -n 's/^The pinned release is `\(v[0-9][0-9.]*\)`.*/\1/p' SETUP.md | head -n 1)
check "SETUP.md declares one pinned release${PIN:+ ($PIN)}" '[ -n "$PIN" ]'
others=$(grep -ohE 'AgentContext-[0-9]+\.[0-9]+\.[0-9]+|AgentContext/v[0-9]+\.[0-9]+\.[0-9]+|tags/v[0-9]+\.[0-9]+\.[0-9]+' README.md SETUP.md \
  | sed -E 's/.*[-/]v?//' | sort -u | tr '\n' ' ')
check "README.md and SETUP.md name no release but the pinned one (found: ${others:-none})" '[ "$others" = "${PIN#v} " ]'
if git rev-parse -q --verify "refs/tags/$PIN^{commit}" >/dev/null 2>&1; then REL="$PIN"; else REL=HEAD; info "$PIN is not tagged yet: its paths are checked against HEAD"; fi
missing=""
for p in $(grep -ohE "AgentContext-${PIN#v}/[A-Za-z0-9_./-]+" SETUP.md | sed "s|^AgentContext-${PIN#v}/||" | sort -u) \
         $(grep -ohE "AgentContext/$PIN/[A-Za-z0-9_./-]+" README.md | sed "s|^AgentContext/$PIN/||" | sort -u); do
  git ls-tree -r --name-only "$REL" -- "$p" | grep -q . || missing="$missing $p"
done
check "every path the run-sheet names under the pinned release exists in $REL${missing:+ (missing:$missing)}" '[ -z "$missing" ]'

# -- 17. the scripts against the fixture tree ----------------------------------------------------------------
# tests/check.sh runs cure.sh, smell.sh, find.sh and review.sh over tests/fixture/ and asserts
# every check fires on the file planted for it and nowhere else; a change to a check cannot
# land without the fixture that proves it. It runs from the archive, so HEAD is what is proved.
out=$(bash "$SRC/tests/check.sh" 2>&1); rc=$?
check "tests/check.sh reports 0 fails${rc:+ ($(printf '%s\n' "$out" | grep -E '^\[FAIL\]' | head -n 1))}" '[ $rc -eq 0 ]'
check "the fixture's CRLF leaf kept its bytes through git archive" \
  '[ "$(awk -v BINMODE=3 "/\r$/" "$SRC/tests/fixture/public/misc/leaves/crlf.md" | wc -l | tr -d " ")" = 6 ]'

# -- 18. the move rule on a v0.4.0 instance, and the fresh root ----------------------------------------------
# v0.4.0 laid its core files at the instance root. An instance deployed by that release's own
# init.sh, from its archive (so its manifest names ref=v0.4.0), is updated by this source's
# init.sh: every untouched core file moves to the path MOVES gives it, the edited one is kept
# where it is, nothing is left at an old path, the manifest lands at common/.agentcontext and
# verifies, and the instance lints. The old paths are read from MOVES, never spelled here.
OLDREL=v0.4.0
if ! git rev-parse -q --verify "refs/tags/$OLDREL^{commit}" >/dev/null 2>&1; then
  info "$OLDREL is not tagged here: the move-rule step not run"
else
  OV=${OLDREL#v}
  ARC="$TMP/AgentContext-$OV.tar.gz"
  git archive --format=tar.gz --prefix="AgentContext-$OV/" "$OLDREL" > "$ARC"
  mkdir -p "$TMP/old" && tar --force-local -xzf "$ARC" -C "$TMP/old"
  OLD="$TMP/old/AgentContext-$OV"
  sed -e '/^PRIVATE_SCOPES=/d' -e '/^ORCH_BUDGET=/d' "$OLD/template/.conf.example" > "$TMP/old.conf"
  mapfile -t MVOLD < <(awk '!/^#/ && NF >= 2 { print $1 }' "$SRC/MOVES")

  # (a) the adapter instance, one core file edited
  I7="$TMP/instance7"
  out=$(bash "$OLD/init.sh" --from "$ARC" --target "$I7" --conf "$TMP/old.conf" --name Old --adapter claude-code 2>&1); rc=$?
  check "$OLDREL's own init.sh deploys an instance from its archive, exit 0" '[ $rc -eq 0 ] && [ -f "$I7/.agentcontext" ]'
  grep -q "^ref=$OLDREL$" "$I7/.agentcontext" || sed -i "s/^ref=.*/ref=$OLDREL/" "$I7/.agentcontext"
  check "the $OLDREL instance's manifest names ref=$OLDREL" 'grep -q "^ref=$OLDREL$" "$I7/.agentcontext"'
  printf '%s\n' "A local note." >> "$I7/rules/branch-grammar.md"
  before=$(tree_digest "$I7")
  out=$(bash "$INIT" --update --target "$I7" --from "$SRC" --dry-run 2>&1); rc=$?
  check "the move rule's --dry-run exits 0 and writes nothing" '[ $rc -eq 0 ] && [ "$(tree_digest "$I7")" = "$before" ]'
  out=$(bash "$INIT" --update --target "$I7" --from "$SRC" 2>&1); rc=$?
  printf '%s\n' "$out" > "$TMP/move.txt"
  nmv=$(grep -c '^moved ' "$TMP/move.txt")
  check "the update from $OLDREL exits 0 and moves $nmv file(s)" '[ $rc -eq 0 ] && [ "$nmv" -ge 1 ]'
  check "the process files and the renamed agents are among the moves" \
    'grep -qx "moved KICKOFF.md -> .claude/process/KICKOFF.md" "$TMP/move.txt" && grep -qx "moved .claude/agents/brainiac.md -> .claude/agents/historian.md" "$TMP/move.txt"'
  check "the edited core file is kept, its release copy at the new path" \
    'grep -qx "kept rules/branch-grammar.md (changed locally; moved to common/rules/branch-grammar.md)" "$TMP/move.txt" && [ -f "$I7/common/rules/branch-grammar.md" ]'
  check "the summary's moved count is the number of moved lines ($nmv)" 'grep -q "^update: $nmv moved, " "$TMP/move.txt"'
  left=""
  for o in "${MVOLD[@]}"; do
    case "$o" in
      rules/) [ "$(ls -A "$I7/rules" 2>/dev/null)" = branch-grammar.md ] || left+="$o " ;;
      *) [ -e "$I7/${o%/}" ] && left+="$o " ;;
    esac
  done
  check "no core file is left at an old path but the edited one${left:+ (left: $left)}" '[ -z "$left" ]'
  empty=$(find "$I7" -type d -empty ! -path "$I7/private/.git/*" | sed "s|^$I7/||" | tr '\n' ' ')
  check "no empty directory is left${empty:+ (empty: $empty)}" '[ -z "$empty" ]'
  check "the manifest moved to common/.agentcontext" '[ -f "$I7/common/.agentcontext" ] && [ ! -e "$I7/.agentcontext" ]'
  (cd "$I7" && sed '1,/^$/d' common/.agentcontext | sha256sum -c --quiet >/dev/null 2>&1); hrc=$?
  check "every hash the moved manifest records verifies" '[ $hrc -eq 0 ]'
  stale=$(sed '1,/^$/d' "$I7/common/.agentcontext" | awk '{ print substr($0, 67) }' | while IFS= read -r p; do
    case "$p" in .agentcontext|common/.agentcontext) printf '%s ' "$p"; continue ;; esac
    for o in "${MVOLD[@]}"; do
      case "$o" in */) case "$p" in "$o"*) printf '%s ' "$p" ;; esac ;; *) [ "$p" = "$o" ] && printf '%s ' "$p" ;; esac
    done
  done)
  check "the manifest lists no old path and not itself${stale:+ (listed: $stale)}" '[ -z "$stale" ]'
  (cd "$I7" && bash common/scripts/cure.sh >/dev/null 2>&1); crc=$?
  (cd "$I7" && bash common/scripts/smell.sh --quiet >/dev/null 2>&1); src=$?
  check "the moved instance lints: cure.sh 0 fails, smell.sh 0 smells" '[ $crc -eq 0 ] && [ $src -eq 0 ]'
  check "the update names the $OV migration guide" 'grep -qx "guide: migrations/$OV.md" "$TMP/move.txt"'
  out=$(bash "$INIT" --update --target "$I7" --from "$SRC" 2>&1); rc=$?
  check "a second update moves nothing" '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^update: 0 moved, "'

  # (b) a kept root document asks for the linter
  I8="$TMP/instance8"
  bash "$OLD/init.sh" --from "$ARC" --target "$I8" --conf "$TMP/old.conf" --no-private >/dev/null 2>&1
  printf '%s\n' "A local note." >> "$I8/AGENTS.md"
  out=$(bash "$INIT" --update --target "$I8" --from "$SRC" 2>&1); rc=$?
  check "a kept AGENTS.md is reported, and the update asks for cure.sh" \
    '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -qx "kept AGENTS.md (changed locally)" && printf "%s\n" "$out" | grep -qx "run bash common/scripts/cure.sh: 1 kept file(s) may name moved paths"'
fi

# (c) the fresh root holds what CD1 lists for its deploy, and nothing else
want1=".conf .gitattributes .gitignore .vscode AGENTS.md Example.code-workspace README.md common private public "
check "the fresh root without an adapter is exactly: $want1" '[ "$root1" = "$want1" ]'
want1b=$(printf '%s\n' $want1 .agents graphs | LC_ALL=C sort | tr '\n' ' ')
now1=$(ls -A "$I1" | LC_ALL=C sort | tr '\n' ' ')
check "with graphify and retention adopted, the root gains graphs/ and .agents/ alone$([ "$now1" = "$want1b" ] || printf " (now: %s)" "$now1")" '[ "$now1" = "$want1b" ]'
if [ "$ADP" = claude-code ]; then
  want6=".claude .conf .gitattributes .gitignore .vscode AGENTS.md CLAUDE.md README.md common instance6.code-workspace private public "
  check "the fresh root with the $ADP adapter is exactly: $want6" '[ "$root6" = "$want6" ]'
else
  info "the first adapter is ${ADP:-none}, not claude-code: its fresh root not judged"
fi

# -- 19. module adoption, and the update over adopted modules -------------------------------------------------
# (a) The first instance carries graphify and context-retention copied in by hand, which its manifest
# never recorded: an update leaves them as they are; --adopt records graphify with nothing copied,
# a file edited beforehand reported as differing and then kept by the next update; a second --adopt
# refuses.
dig_mods() { (cd "$1/common/modules" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum); }
before=$(dig_mods "$I1")
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
check "an update over a manifest with no module= line touches nothing under common/modules/" \
  '[ $rc -eq 0 ] && [ "$(dig_mods "$I1")" = "$before" ] && ! printf "%s\n" "$out" | grep -q "common/modules/"'
printf '%s\n' "A local note." >> "$I1/common/modules/graphify/README.md"
ngf=$(cd "$SRC/modules/graphify" && find . -type f | wc -l | tr -d ' ')
out=$(bash "$INIT" --adopt graphify --target "$I1" --from "$SRC" 2>&1); rc=$?
check "--adopt of a module already in place records it with nothing copied: 1 differs, $((ngf - 1)) match" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -qx "differs common/modules/graphify/README.md" && printf "%s\n" "$out" | grep -q "^recorded graphify, already at common/modules/graphify/: $((ngf - 1)) match, 1 differ, 0 missing"'
check "the manifest carries module=graphify and the release's hash for each of its $ngf files" \
  'grep -qx "module=graphify" "$I1/common/.agentcontext" && [ "$(grep -c "  common/modules/graphify/" "$I1/common/.agentcontext")" -eq "$ngf" ] && grep -q "^$(sha256sum < "$SRC/modules/graphify/README.md" | cut -c1-64)  common/modules/graphify/README.md$" "$I1/common/.agentcontext"'
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
check "the next update keeps the file edited before the adoption" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -qx "kept common/modules/graphify/README.md (changed locally)"'
before=$(tree_digest "$I1")
err=$(bash "$INIT" --adopt graphify --target "$I1" --from "$SRC" 2>&1 >/dev/null); rc=$?
check "a second --adopt of the module refuses with exit 2 and writes nothing" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "already recorded" && [ "$(tree_digest "$I1")" = "$before" ]'

# (b) A fresh instance adopts two modules, one of each kind: a script module and a tree module.
I9="$TMP/instance9"
bash "$INIT" --from "$SRC" --target "$I9" --conf "$CONF" >/dev/null 2>&1
before=$(tree_digest "$I9")
out=$(bash "$INIT" --adopt codebase --target "$I9" --from "$SRC" --dry-run 2>&1); rc=$?
check "--adopt --dry-run exits 0 and writes nothing" '[ $rc -eq 0 ] && [ "$(tree_digest "$I9")" = "$before" ]'
arc=0
for m in constitution codebase; do bash "$INIT" --adopt "$m" --target "$I9" --from "$SRC" >/dev/null 2>&1 || arc=1; done
check "--adopt constitution and --adopt codebase exit 0" '[ $arc -eq 0 ]'
check "the constitution's tree/ is laid at constitution/ byte for byte, its README left in the release" \
  'diff -r -q "$SRC/modules/constitution/tree" "$I9/constitution" >/dev/null && [ ! -e "$I9/constitution/README.md" ]'
check "the codebase module is laid whole at common/modules/codebase/ byte for byte" \
  'diff -r -q "$SRC/modules/codebase" "$I9/common/modules/codebase" >/dev/null'
nct=$(cd "$SRC/modules/constitution/tree" && find . -type f | wc -l | tr -d ' ')
ncb=$(cd "$SRC/modules/codebase" && find . -type f | wc -l | tr -d ' ')
check "the manifest's header names both modules, sorted, and its list hashes their $nct + $ncb files" \
  '[ "$(grep "^module=" "$I9/common/.agentcontext" | tr "\n" " ")" = "module=codebase module=constitution " ] && [ "$(grep -c "  constitution/" "$I9/common/.agentcontext")" -eq "$nct" ] && [ "$(grep -c "  common/modules/codebase/" "$I9/common/.agentcontext")" -eq "$ncb" ]'
(cd "$I9" && sed '1,/^$/d' common/.agentcontext | sha256sum -c --quiet >/dev/null 2>&1); hrc=$?
check "every hash the manifest records verifies" '[ $hrc -eq 0 ]'
(cd "$I9" && bash common/scripts/cure.sh >/dev/null 2>&1); crc=$?
check "the instance with two adopted modules lints with 0 fails" '[ $crc -eq 0 ]'

# (c) The refusals: exit 2 and nothing written. A second source carries a stand-in private-tree
# module and a module with no payload, which this release does not ship.
SRC2="$TMP/src2"; cp -R "$SRC" "$SRC2"
mkdir -p "$SRC2/modules/local/tree" "$SRC2/modules/empty"
printf '%s\n' "# Local" > "$SRC2/modules/local/tree/.index.md"
printf '%s\n' "# Empty" > "$SRC2/modules/empty/README.md"
before=$(tree_digest "$I9")
refused=""
for m in no-such-module change-log constitution empty; do
  err=$(bash "$INIT" --adopt "$m" --target "$I9" --from "$SRC2" 2>&1 >/dev/null); rc=$?
  [ $rc -eq 2 ] || refused+="$m(rc=$rc) "
done
check "an unknown module, change-log, one already recorded and one with no payload refuse with exit 2${refused:+ (not: $refused)}" '[ -z "$refused" ]'
check "the four refusals wrote nothing" '[ "$(tree_digest "$I9")" = "$before" ]'
err=$(bash "$INIT" --adopt change-log --target "$I9" --from "$SRC" 2>&1 >/dev/null)
check "the change-log refusal points at a repository's .github/workflows/" 'printf "%s\n" "$err" | grep -q "\.github/workflows/"'
before=$(tree_digest "$I2")
err=$(bash "$INIT" --adopt local --target "$I2" --from "$SRC2" 2>&1 >/dev/null); rc=$?
check "a private-tree module on an instance without a private tree refuses with exit 2 and writes nothing" \
  '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "goes into the private tree" && [ "$(tree_digest "$I2")" = "$before" ]'

# (d) An update from a source with one changed and one new module file, one removed, one changed
# seed and one changed ruling the user had marked adopted, over one module file edited locally.
R=history/rulings SEED=rulings.hygiene-and-gates.md ADOPTED=rulings.tree-structure.md
printf '%s\n' "" "A line new upstream." >> "$SRC2/modules/codebase/README.md"
printf '%s\n' "A file new upstream." > "$SRC2/modules/codebase/NOTES.md"
rm "$SRC2/modules/codebase/fixture/profile.json"
for f in $SEED $ADOPTED; do printf '%s\n' "" "- **ZZ1.** A ruling new upstream." >> "$SRC2/modules/constitution/tree/$R/$f"; done
sed -i 's/^_status:_ seed.*$/_status:_ adopted 2026-01-01/' "$I9/constitution/$R/$ADOPTED"
printf '%s\n' "# a local edit" >> "$I9/common/modules/codebase/codebase.py"
out=$(bash "$INIT" --update --target "$I9" --from "$SRC2" 2>&1); rc=$?
printf '%s\n' "$out" > "$TMP/modupdate.txt"
check "the update over adopted modules: 0 moved, 2 replaced, 2 kept, 1 added, 1 removed-upstream" \
  '[ $rc -eq 0 ] && grep -qx "update: 0 moved, 2 replaced, 2 kept, 1 added, 1 removed-upstream" "$TMP/modupdate.txt"'
check "the changed module file and the seed still marked seed are replaced" \
  'grep -qx "replaced common/modules/codebase/README.md" "$TMP/modupdate.txt" && grep -qx "replaced constitution/$R/$SEED" "$TMP/modupdate.txt" && grep -q "ZZ1" "$I9/constitution/$R/$SEED"'
check "the locally edited module file and the ruling marked adopted are kept" \
  'grep -qx "kept common/modules/codebase/codebase.py (changed locally)" "$TMP/modupdate.txt" && grep -qx "kept constitution/$R/$ADOPTED (changed locally)" "$TMP/modupdate.txt" && ! grep -q "ZZ1" "$I9/constitution/$R/$ADOPTED"'
check "the new module file is added and the removed one reported, its copy left" \
  'grep -qx "added common/modules/codebase/NOTES.md" "$TMP/modupdate.txt" && grep -qx "removed-upstream common/modules/codebase/fixture/profile.json" "$TMP/modupdate.txt" && [ -f "$I9/common/modules/codebase/fixture/profile.json" ]'
check "both module= lines survive the update" \
  '[ "$(grep "^module=" "$I9/common/.agentcontext" | tr "\n" " ")" = "module=codebase module=constitution " ]'

# (e) A release that no longer ships an adopted module: reported once, its line dropped, its files left.
SRC3="$TMP/src3"; cp -R "$SRC2" "$SRC3"; rm -rf "$SRC3/modules/codebase"
out=$(bash "$INIT" --update --target "$I9" --from "$SRC3" 2>&1); rc=$?
check "a module the release dropped is reported, its module= line dropped, its files left" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -qx "removed-upstream module codebase (its files stay)" && ! grep -qx "module=codebase" "$I9/common/.agentcontext" && grep -qx "module=constitution" "$I9/common/.agentcontext" && [ -f "$I9/common/modules/codebase/codebase.py" ]'

# (f) A v0.4.0 instance: --adopt refuses before its update, and after it finds a module copied in by
# hand at its old place (MOVES), moving every file that matches the release.
if [ -n "${OLD:-}" ] && [ -d "${I7:-}" ]; then
  I10="$TMP/instance10"
  bash "$OLD/init.sh" --from "$ARC" --target "$I10" --conf "$TMP/old.conf" --no-private >/dev/null 2>&1
  before=$(tree_digest "$I10")
  err=$(bash "$INIT" --adopt graphify --target "$I10" --from "$SRC" 2>&1 >/dev/null); rc=$?
  check "--adopt on an instance whose manifest is still at the root refuses with exit 2 and writes nothing" \
    '[ $rc -eq 2 ] && printf "%s\n" "$err" | grep -q "update the instance to this release first" && [ "$(tree_digest "$I10")" = "$before" ]'
  # the hand copy: the release's files, one of them edited by the user
  mkdir -p "$I7/modules" && cp -R "$SRC/modules/context-retention" "$I7/modules/context-retention"
  printf '%s\n' "# a local edit" >> "$I7/modules/context-retention/meta.sh"
  ncr=$(cd "$SRC/modules/context-retention" && find . -type f | wc -l | tr -d ' ')
  out=$(bash "$INIT" --adopt context-retention --target "$I7" --from "$SRC" 2>&1); rc=$?
  printf '%s\n' "$out" > "$TMP/oldadopt.txt"
  check "--adopt finds the hand copy at modules/ through MOVES: $((ncr - 1)) moved, the edited one kept" \
    '[ $rc -eq 0 ] && grep -qx "adopted context-retention from modules/context-retention/: $((ncr - 1)) moved, 1 kept, 0 added" "$TMP/oldadopt.txt" && grep -qx "kept modules/context-retention/meta.sh (differs from the release; moved to common/modules/context-retention/meta.sh)" "$TMP/oldadopt.txt"'
  check "the release's copy of every file is at common/modules/context-retention/" \
    'diff -r -q "$SRC/modules/context-retention" "$I7/common/modules/context-retention" >/dev/null'
  check "the moved files' old paths are gone, the edited one alone left at modules/" \
    '[ "$(cd "$I7/modules" && find . -type f)" = "./context-retention/meta.sh" ]'
  (cd "$I7" && sed '1,/^$/d' common/.agentcontext | sha256sum -c --quiet >/dev/null 2>&1); hrc=$?
  check "the manifest records module=context-retention and every hash verifies" \
    'grep -qx "module=context-retention" "$I7/common/.agentcontext" && [ $hrc -eq 0 ]'
else
  info "no $OLDREL instance: --adopt over a hand copy at the old place not run"
fi

echo "== deploy smoke: $FAIL fail(s) =="
exit $FAIL
