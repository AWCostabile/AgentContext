#!/bin/bash
# deploy-smoke.sh — this repository's gate for the deployer: it deploys throwaway
# instances from the COMMITTED tree, lints them, updates one, and proves the refusals.
#
# Usage: bash tools/deploy-smoke.sh   (from anywhere; no arguments)
#
# Prints one [ OK ] / [FAIL] line per assertion ([WARN] and [INFO] never count) and
# exits with the number of fails. Never copied into an instance. Its temporary
# directories are removed on exit.

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
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
json_ok() {
  if python -c pass >/dev/null 2>&1; then
    python -I -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$1"
  elif command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$1"
  else
    return 2
  fi
}

echo "== deploy smoke — $(date '+%Y-%m-%d %H:%M') =="

# -- 1. the committed tree is the source -------------------------------------------------
[ -n "$(git status --porcelain)" ] && warn "the worktree is dirty; the smoke proves HEAD, not the worktree"
mkdir -p "$SRC" && git archive HEAD | tar -x -C "$SRC"
check "git archive of HEAD extracted as the source" '[ -f "$INIT" ] && [ -f "$SRC/template/AGENTS.md" ]'

# -- 2. deploy -------------------------------------------------------------------------------
# PRIVATE_SCOPES and ORCH_BUDGET are dropped so the deployer has to derive them.
sed -e 's/^CATALOGS=.*/CATALOGS="products projects"/' -e '/^PRIVATE_SCOPES=/d' -e '/^ORCH_BUDGET=/d' \
  "$REPO/template/.conf.example" > "$CONF"
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
ncore=$(sed '1,/^$/d' "$I1/.agentcontext" 2>/dev/null | grep -c .)
check ".agentcontext names ref=working-tree and lists $ncore core files (at least 20)" \
  'grep -q "^ref=working-tree$" "$I1/.agentcontext" && [ "$ncore" -ge 20 ]'
check ".gitignore names /private/ and /.conf" \
  'grep -q "^/private/$" "$I1/.gitignore" && grep -q "^/\.conf$" "$I1/.gitignore"'
check ".conf gained the derived PRIVATE_SCOPES and ORCH_BUDGET" \
  'grep -q "^PRIVATE_SCOPES=\"products projects journal\"$" "$I1/.conf" && grep -q "^ORCH_BUDGET=full$" "$I1/.conf"'

# -- 4. the instance lints clean ----------------------------------------------------------------
cure=$(bash "$I1/scripts/cure.sh" --root "$I1" 2>&1); crc=$?
info "cure: $(printf '%s\n' "$cure" | grep '^== VERDICT')"
check "cure.sh reports 0 fails on the instance" '[ $crc -eq 0 ]'
smell=$(bash "$I1/scripts/smell.sh" --root "$I1" --quiet 2>&1); src=$?
info "smell: $(printf '%s\n' "$smell" | grep '^== SUMMARY')"
if [ $src -eq 0 ]; then ok "smell.sh reports 0 smells on the instance"
else warn "smell.sh reports $src smell(s):"; bash "$I1/scripts/smell.sh" --root "$I1" | grep '^\[SMELL'; fi

# -- 5. an update from the same source changes nothing --------------------------------------------
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
check "update from the same source: 0 replaced, 0 kept, 0 added, 0 removed-upstream" \
  '[ $rc -eq 0 ] && printf "%s\n" "$out" | grep -q "^update: 0 replaced, 0 kept, 0 added, 0 removed-upstream$"'

# -- 6. a local edit is kept; a dry run writes nothing ----------------------------------------------
printf '%s\n' "A local note." >> "$I1/rules/branch-grammar.md"
edited=$(sha256sum < "$I1/rules/branch-grammar.md")
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" 2>&1); rc=$?
report=$(printf '%s\n' "$out" | grep '^update: ')
check "a locally edited core file is reported kept, exactly once" \
  '[ $rc -eq 0 ] && [ "$report" = "update: 0 replaced, 1 kept, 0 added, 0 removed-upstream" ] && printf "%s\n" "$out" | grep -q "^kept rules/branch-grammar.md (changed locally)$"'
check "the kept file is unchanged" '[ "$(sha256sum < "$I1/rules/branch-grammar.md")" = "$edited" ]'
before=$(tree_digest "$I1")
out=$(bash "$INIT" --update --target "$I1" --from "$SRC" --dry-run 2>&1); rc=$?
check "--dry-run prints the same report" '[ $rc -eq 0 ] && [ "$(printf "%s\n" "$out" | grep "^update: ")" = "$report" ]'
check "--dry-run writes nothing" '[ "$(tree_digest "$I1")" = "$before" ]'

# -- 7. no private tree -------------------------------------------------------------------------------
I2="$TMP/instance2"
out=$(bash "$INIT" --from "$SRC" --target "$I2" --conf "$CONF" --no-private 2>&1); rc=$?
check "--no-private installs, with no private/ directory" '[ $rc -eq 0 ] && [ -d "$I2/public" ] && [ ! -e "$I2/private" ]'
bash "$I2/scripts/cure.sh" --root "$I2" >/dev/null 2>&1; crc=$?
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
  check "the ${#hooks[@]} hook scripts the settings register are present (expected 4)${hmiss:+ (missing: $hmiss)}" \
    '[ ${#hooks[@]} -eq 4 ] && [ -z "$hmiss" ]'
  mlist=$(sed '1,/^$/d' "$I6/.agentcontext" 2>/dev/null | awk '{print $2}')
  mmiss=""
  for f in "${pfiles[@]}"; do printf '%s\n' "$mlist" | grep -qF -- "$f" || mmiss+="$f "; done
  check ".agentcontext carries adapter=$ADP and lists every payload file${mmiss:+ (unlisted: $mmiss)}" \
    'grep -q "^adapter=$ADP\$" "$I6/.agentcontext" && [ -z "$mmiss" ]'
  bash "$I6/scripts/cure.sh" --root "$I6" >/dev/null 2>&1; crc=$?
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
  # S01 (a design leaf not re-reviewed in 90 days) fires by the calendar alone, so it is reported, not failed
  smells=$(bash "$SRC/scripts/smell.sh" --root "$ex" 2>/dev/null | grep '^\[SMELL ' || true)
  stale=$(printf '%s\n' "$smells" | grep -c '^\[SMELL S01\]' || true)
  src=$(printf '%s\n' "$smells" | grep -v '^\[SMELL S01\]' | grep -c '^\[SMELL ' || true)
  [ "$stale" -gt 0 ] && info "example $name: $stale design leaf(s) past their review date (S01) — bump _reviewed:_ when the content is re-read"
  check "example $name: smell.sh reports 0 smells other than S01" '[ "$src" -eq 0 ]'
  left=$(grep -rlE '\{\{[A-Za-z]' --exclude-dir=.git "$ex" | grep -v /templates/)
  check "example $name: no placeholder outside templates/${left:+ (left: $(printf '%s' "$left" | tr '\n' ' '))}" '[ -z "$left" ]'
done
[ $nex -eq 0 ] && info "no example holds a .conf: example step not run"

echo "== deploy smoke: $FAIL fail(s) =="
exit $FAIL
