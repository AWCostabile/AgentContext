#!/bin/bash
# check.sh — the scripts against the fixture tree. tests/fixture/ is a small deployed-shaped
# tree (a .conf, one product, a misc branch, a private tree) carrying one deliberate defect
# per check id beside sound branches: a branch without an index, one without tags, an orphan
# leaf, a dead link, a public leaf citing a private record, a stale review date, a design leaf
# without a source, a dead tag, an overdue inbox item, an uncited design leaf, a retired
# spelling, and so on, one file per id. This script runs cure.sh, smell.sh, find.sh and
# review.sh over it and asserts:
#   - every C and S id fires on exactly the file planted for it and nowhere else;
#   - the verdict, the smell summary and its per-id cells match;
#   - find.sh's tag, -k, -x, -b and -f modes answer with the expected lines;
#   - review.sh's agenda and --brief line carry the expected counts, and its exit code is
#     cure.sh's fail count.
# The calendar smells are judged as of 2026-11-03 (smell.sh --today), so the run is the same
# on any day. Deterministic, bash only, seconds to run; the deploy smoke runs it as a section,
# so a change to a check cannot land without the fixture that proves it. Never copied into an
# instance: the deployer's core lists do not name tests/.
#
# The fixture's shape is the law here: a check that fires where it was not planted is a
# defect in the check or a cascade in the fixture, and either is fixed before this passes.
# Two plantings are deliberate pairs (S01 on a design and a research leaf, to prove the
# windows differ; S02 on a design and a features leaf), and three ids name the place that
# carries the defect rather than a leaf: S06 and S16 name the index holding the row, S17 the
# retros branch, S12 the duplicated basename.
#
# Usage: bash tests/check.sh   (from anywhere; no arguments)
# Exit: the number of failed assertions.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
FX="$REPO/tests/fixture"
TODAY=2026-11-03

FAIL=0
ok()    { printf '[ OK ] %s\n' "$1"; }
fail()  { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }
check() { if eval "$2"; then ok "$1"; else fail "$1"; fi; }
# same <label> <expected> <actual>: equal, or a diff under the FAIL line
same() {
  if [ "$2" = "$3" ]; then ok "$1"; else
    fail "$1"
    diff <(printf '%s\n' "$2") <(printf '%s\n' "$3") | grep -E '^[<>]' | sed 's/^</       expected: /; s/^>/       actual:   /'
  fi
}
e() { printf '%s\t%s\n' "$1" "$2"; }   # one expected finding: id TAB file

echo "== script check over tests/fixture — $(date '+%Y-%m-%d %H:%M') =="
[ -f "$FX/.conf" ] || { fail "the fixture exists at $FX"; exit 1; }

# -- 1. cure.sh: the invariants ------------------------------------------------------------------
cure=$(bash "$REPO/scripts/cure.sh" --root "$FX" 2>&1); crc=$?
actual=$(printf '%s\n' "$cure" | awk '
  /^\[FAIL\] missing index: /          { print "C01\t" $4; next }
  /^\[FAIL\] missing or empty tags: /  { print "C02\t" $6; next }
  /^\[WARN\] malformed tags in /       { print "C02\t" $5; next }
  /^\[FAIL\] orphan \(not in /         { sub(/^.*\): /, ""); print "C03\t" $0; next }
  /^\[FAIL\] dead link in /            { print "C04\t" $5; next }
  /^\[WARN\] promotion candidate /     { sub(/^.*: /, ""); print "C05\t" $0; next }
  /^\[WARN\] split candidate /         { sub(/^.*: /, ""); print "C06\t" $0; next }
  /^\[WARN\] near-duplicate tags: /    { print "C07\t" $4 " " $6; next }
  /^\[FAIL\] .private. tag found under public\/: / { print "C08\t" $7; next }
  /^\[FAIL\] one-way link broken: /    { print "C09\t" $5; next }
  /^\[FAIL\] catalog /                 { print "C14\t" $3; next }
  /^\[FAIL\]|^\[WARN\]/                { print "??\t" $0 }' | sort)
expected=$({
  e C01 public/misc/branches/nolist/.index.md
  e C02 public/misc/branches/notags/.tags
  e C03 public/misc/leaves/orphan.md
  e C04 public/misc/leaves/deadlink.md
  e C05 public/misc/leaves/long.md
  e C06 public/misc/branches/wide/.index.md
  e C07 "'lamp' 'lamps'"
  e C08 public/misc/branches/leaky/.tags
  e C09 public/misc/leaves/private-cite.md
  e C14 "'ghosts'"
} | sort)
same "cure.sh: every invariant fires on its planted file and nowhere else" "$expected" "$actual"
check "cure.sh: VERDICT 7 fail(s), 3 warning(s), exit 7" \
  'printf "%s\n" "$cure" | grep -q "^== VERDICT: 7 fail(s), 3 warning(s) ==$" && [ $crc -eq 7 ]'
fast=$(bash "$REPO/scripts/cure.sh" --root "$FX" --fast 2>&1)
check "cure.sh --fast: the same 7 fails and no advisory warning" \
  'printf "%s\n" "$fast" | grep -q "^== VERDICT: 7 fail(s), 0 warning(s) ==$"'

# -- 2. smell.sh: the smells, as of the fixture's day ------------------------------------------------
smell=$(bash "$REPO/scripts/smell.sh" --root "$FX" --today "$TODAY" 2>&1); src=$?
actual=$(printf '%s\n' "$smell" | awk '/^\[SMELL / { id = substr($2, 1, 3); f = $3; sub(/:.*$/, "", f); print id "\t" f }' | sort)
expected=$({
  e S01 public/products/Lantern/design/design.stale.md
  e S01 public/products/Lantern/research/research.old.md
  e S02 public/products/Lantern/design/design.unsourced.md
  e S02 public/products/Lantern/features/features.undated.md
  e S03 public/misc/branches/deadtag/.tags
  e S04 public/misc/branches/reciept/.tags
  e S05 public/misc/branches/drift/.index.md
  e S06 public/products/Lantern/history/.index.md
  e S07 public/misc/leaves/crlf.md
  e S08 public/misc/leaves/shell.md
  e S09 public/misc/leaves/residue.md
  e S10 public/misc/branches/agentless/.agent
  e S11 public/misc/branches/crossrow/.index.md
  e S12 notes.md
  e S13 public/products/Lantern/design/design.retired.md
  e S14 public/misc/branches/prose/.index.md
  e S16 public/misc/leaves/.index.md
  e S17 private/journal/retros/
  e S18 public/misc/leaves/vocabulary.md
  e S20 public/products/Lantern/design/design.uncited.md
  e S21 private/journal/inbox.md
} | sort)
same "smell.sh: every smell fires on its planted file and nowhere else" "$expected" "$actual"
n=$(printf '%s\n' "$expected" | wc -l | tr -d ' ')
check "smell.sh: SUMMARY $n smell(s), landed-since-retro=3, exit $n" \
  'printf "%s\n" "$smell" | grep -q "^== SUMMARY: $n smell(s) — landed-since-retro=3 ==$" && [ $src -eq $n ]'
# the per-id cells of the summary table against the expected counts (every id, fired or not)
cells=$(printf '%s\n' "$smell" | sed -n '/^== SUMMARY/,$p' | grep -oE 'S[0-9][0-9] [A-Za-z./ -]*[0-9]+' | sed -E 's/^(S[0-9][0-9]) .* ([0-9]+)$/\1 \2/' | sort)
want=$(for id in S01 S02 S03 S04 S05 S06 S07 S08 S09 S10 S11 S12 S13 S14 S16 S17 S18 S20 S21; do
         printf '%s %s\n' "$id" "$(printf '%s\n' "$expected" | grep -c "^$id"$'\t')"; done | sort)
same "smell.sh: the summary table's cells match the findings, id by id" "$want" "$cells"
check "smell.sh: the two windows differ — research.oil.md (reviewed 2026-07-01) is quiet at 180 days while design.stale.md fires at 90" \
  '! printf "%s\n" "$smell" | grep -q "research.oil.md" && printf "%s\n" "$smell" | grep -q "design.stale.md: design leaf last reviewed 2024-01-01"'
check "smell.sh: S21 and S01 carry the item's age as of --today" \
  'printf "%s\n" "$smell" | grep -q "inbox item of 2025-01-01 (671 days old; the window is 14)"'
check "smell.sh: --today refuses a malformed date with exit 2" \
  'bash "$REPO/scripts/smell.sh" --root "$FX" --today 2026-1-3 >/dev/null 2>&1; [ $? -eq 2 ]'
same "smell.sh: the planted CRLF leaf really carries carriage returns" "6" "$(awk -v BINMODE=3 '/\r$/' "$FX/public/misc/leaves/crlf.md" | wc -l | tr -d ' ')"

# -- 3. find.sh: the five modes --------------------------------------------------------------------------
F() { bash "$REPO/scripts/find.sh" --root "$FX" "$@" 2>&1; }
same "find.sh -b <basename>: the files citing design.wick.md, its index row marked" \
  "$(printf '%s\n' 'public/products/Lantern/design/.index.md  (index row)' 'public/products/Lantern/features/features.lighting.md')" \
  "$(F -b design.wick.md)"
same "find.sh -b: a ruling cited by bare path from three design leaves, a link and its index row" \
  "$(printf '%s\n' 'public/products/Lantern/design/design.retired.md' 'public/products/Lantern/design/design.uncited.md' 'public/products/Lantern/design/design.wick.md' 'public/products/Lantern/features/features.lighting.md' 'public/products/Lantern/history/.index.md  (index row)')" \
  "$(F -b rulings.wick.md)"
out=$(F -b notes.md); rc=$?
check "find.sh -b: an ambiguous basename lists both leaves and exits 2" \
  '[ $rc -eq 2 ] && printf "%s\n" "$out" | grep -q "names 2 leaves" && printf "%s\n" "$out" | grep -q "public/misc/leaves/notes.md" && printf "%s\n" "$out" | grep -q "public/products/Lantern/research/notes.md"'
same "find.sh -b <path>: a leaf cited by its index row alone" "public/misc/leaves/.index.md  (index row)" "$(F -b public/misc/leaves/sound.md)"
same "find.sh -f reviewed: every leaf carrying the marker, with its value" \
  "$(printf '%s\n' \
    "$(printf 'public/products/Lantern/design/design.retired.md\t2026-11-01')" \
    "$(printf 'public/products/Lantern/design/design.stale.md\t2024-01-01')" \
    "$(printf 'public/products/Lantern/design/design.uncited.md\t2026-11-01')" \
    "$(printf 'public/products/Lantern/design/design.unsourced.md\t2026-11-01')" \
    "$(printf 'public/products/Lantern/design/design.wick.md\t2026-11-01')" \
    "$(printf 'public/products/Lantern/features/features.lighting.md\t2026-11-01')" \
    "$(printf 'public/products/Lantern/research/research.oil.md\t2026-07-01')" \
    "$(printf 'public/products/Lantern/research/research.old.md\t2025-01-01')")" \
  "$(F -f reviewed)"
same "find.sh -f 'reviewed<2026-01-01': the two old dates, compared as text" \
  "$(printf 'public/products/Lantern/design/design.stale.md\t2024-01-01\npublic/products/Lantern/research/research.old.md\t2025-01-01')" \
  "$(F -f 'reviewed<2026-01-01')"
same "find.sh -f updated: a private leaf in a configured scope" "$(printf 'private/journal/latest.md\t2026-11-01')" "$(F -f updated)"
same "find.sh -f 'status=enacted 2026-01-10': equality on a value with a space" \
  "$(printf 'public/products/Lantern/history/rulings.wick.md\tenacted 2026-01-10')" "$(F -f 'status=enacted 2026-01-10')"
out=$(F -f 'reviewed>2027-01-01'); rc=$?
check "find.sh -f: no match exits 1 and names the key and the comparison" '[ $rc -eq 1 ] && printf "%s\n" "$out" | grep -q "no file in scope carries _reviewed:_ > 2027-01-01"'
out=$(F -k 'dead tag')
check "find.sh -k: the two index lines carrying 'dead tag', with file and line number" \
  '[ "$(printf "%s\n" "$out" | wc -l | tr -d " ")" = 2 ] && printf "%s\n" "$out" | grep -q "^public/misc/branches/.index.md:[0-9]*:| \[Deadtag\]" && printf "%s\n" "$out" | grep -q "^public/misc/branches/deadtag/.index.md:[0-9]*:"'
out=$(F -k brass glass)
check "find.sh -k: two keywords are ANDed on one line" \
  '[ "$(printf "%s\n" "$out" | wc -l | tr -d " ")" = 1 ] && printf "%s\n" "$out" | grep -q "^public/products/Lantern/.index.md:3:A lantern: brass, glass"'
out=$(F -k zeppelin); rc=$?
check "find.sh -k: a word found in no index exits 1 and suggests -a" '[ $rc -eq 1 ] && printf "%s\n" "$out" | grep -q "no matches. Try -a"'
same "find.sh -x: a branch's tags and the head of its index" \
  "$(printf 'tags: misc, receipt\n--- public/misc/.index.md ---\n# Misc')" "$(F -x public/misc | head -n 3)"
check "find.sh -l: the dead tag is counted once" 'F -l | grep -q "^  1  zeppelin$"'
out=$(F lantern)
check "find.sh <tag>: both trees' Lantern branches answer, each labelled with its tree" \
  'printf "%s\n" "$out" | grep -q "^public/products/Lantern  .*  public$" && printf "%s\n" "$out" | grep -q "^private/products/Lantern  .*  private$"'

# -- 4. review.sh: the agenda ------------------------------------------------------------------------------
brief=$(bash "$REPO/scripts/review.sh" --root "$FX" --brief --today "$TODAY" 2>&1); rc=$?
same "review.sh --brief: one line of counts" \
  "review: cure 7 fail(s) · smells $n · inbox 2 (oldest 671d) · questions 2 (oldest 154d) · stale 2 · uncited 1 · overdue 1 · landed-since-retro 3 · unpushed 0 repo(s) · newest entry 2026-01-20" \
  "$brief"
check "review.sh: the exit code is cure.sh's fail count" '[ $rc -eq 7 ]'
full=$(bash "$REPO/scripts/review.sh" --root "$FX" --today "$TODAY" 2>&1)
check "review.sh: the agenda names the inbox, the retro pressure and the newest entry, under thirty lines" \
  'printf "%s\n" "$full" | grep -q "^Inbox: 2 item(s) (2 mine, 0 candidates); oldest 2025-01-01, 671 day(s) old$" && printf "%s\n" "$full" | grep -q "^Retro: 3 landed; no retro filed yet$" && printf "%s\n" "$full" | grep -q "^Journal: newest entry 2026-01-20 (private/journal/entries/2026-01/2026-01-20.wick-lit.md)$" && [ "$(printf "%s\n" "$full" | wc -l | tr -d " ")" -le 30 ]'
check "review.sh: the stale, uncited and overdue lines carry their ages" \
  'printf "%s\n" "$full" | grep -q "^  S01  public/products/Lantern/design/design.stale.md (1037 days ago; the window is 90)$" && printf "%s\n" "$full" | grep -q "^  S20  public/products/Lantern/design/design.uncited.md$" && printf "%s\n" "$full" | grep -q "^  S21  private/journal/inbox.md (671 days old; the window is 14)$"'
check "review.sh: the questions line counts the open lines only, oldest first, and names one past a quarter" \
  'printf "%s\n" "$full" | grep -qx "Questions: 2 open; oldest 2026-06-01, 154 day(s) old — over a quarter (should a lantern carry a second glass — a bill)"'
before=$(cd "$FX" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum)
check "review.sh wrote nothing to the fixture" '[ "$(cd "$FX" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum)" = "$before" ]'

# -- 5. the fixture is never laid into an instance ----------------------------------------------------------
check "init.sh's core lists do not name tests/" '! grep -E "^CORE_(DIRS|FILES)=" "$REPO/init.sh" | grep -q tests'

echo "== script check: $FAIL fail(s) =="
exit $FAIL
