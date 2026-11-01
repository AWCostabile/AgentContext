#!/bin/bash
# check.sh — the codebase module's reproducibility check, over its invented fixture.
#
# Usage: bash modules/codebase/check.sh   (from anywhere; no arguments)
#
# 1. Generates the fixture's tier into an empty directory and compares it with
#    fixture/expected/ byte for byte, every `_generated:_` provenance line excepted.
# 2. Runs --check against fixture/expected/ and expects no drift.
# 3. Copies the fixture outside any git checkout and generates again: the walk must
#    produce what `git ls-files` produced.
# 4. Rewrites over unchanged source and expects every file left byte-identical,
#    provenance line included.
# 5. Changes one line of a copied source file and expects --check to report drift,
#    naming the leaf that moved.
#
# Prints one [ OK ] / [FAIL] line per assertion and exits with the number of fails.
# PYTHON=<interpreter> picks the interpreter; otherwise the first Python 3.10+ found.

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FIX="$HERE/fixture"
GEN="$HERE/codebase.py"

FAIL=0
ok()   { printf '[ OK ] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

PY=
for p in ${PYTHON:-} python3 python py; do
  if "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
    PY=$p
    break
  fi
done
[ -n "$PY" ] || { echo '[FAIL] no Python 3.10+ found (set PYTHON=<interpreter>)'; exit 1; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/codebase-check.XXXXXX") || { echo 'cannot create a temporary directory' >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# gen <repo> <into> [extra args] — run the generator, its output kept in $TMP/out.txt
gen() {
  local repo=$1 into=$2
  shift 2
  "$PY" "$GEN" --repo "$repo" --into "$into" --profile "$FIX/profile.json" "$@" >"$TMP/out.txt" 2>&1
}

# same_tier <a> <b> — the same files, equal outside their provenance lines
same_tier() {
  local a=$1 b=$2 f diffs=0
  if [ "$(cd "$a" && ls -A | LC_ALL=C sort)" != "$(cd "$b" && ls -A | LC_ALL=C sort)" ]; then
    echo "  file sets differ: $(cd "$a" && ls -A | tr '\n' ' ')/ $(cd "$b" && ls -A | tr '\n' ' ')"
    return 1
  fi
  for f in $(cd "$a" && ls -A); do
    if ! cmp -s <(grep -v '^_generated:_ ' "$a/$f") <(grep -v '^_generated:_ ' "$b/$f"); then
      echo "  $f differs"
      diffs=$((diffs + 1))
    fi
  done
  [ "$diffs" -eq 0 ]
}

digest() { (cd "$1" && for f in $(ls -A | LC_ALL=C sort); do printf '%s ' "$f"; cksum <"$f"; done); }

echo "== codebase module check ($("$PY" --version 2>&1)) =="

# 1. a fresh generation reproduces expected/
if gen "$FIX/repo" "$TMP/fresh"; then
  ok 'the generator runs over the fixture (exit 0)'
else
  fail "the generator failed over the fixture: $(tail -n 3 "$TMP/out.txt")"
fi
if same_tier "$FIX/expected" "$TMP/fresh"; then
  ok 'a fresh generation matches fixture/expected/, provenance lines excepted'
else
  fail 'a fresh generation differs from fixture/expected/ (regenerate it only if the change is intended)'
fi
if [ "$(grep -c '^_generated:_ ' "$TMP/fresh/codebase.map.md")" = 1 ]; then
  ok 'each leaf carries exactly one provenance line'
else
  fail 'the code map does not carry exactly one provenance line'
fi

# 2. --check finds no drift against expected/
if gen "$FIX/repo" "$FIX/expected" --check; then
  ok '--check reports no drift against fixture/expected/'
else
  fail "--check reports drift against fixture/expected/: $(grep FAIL "$TMP/out.txt" | head -n 3)"
fi

# 3. without git, the walk finds the same files
cp -r "$FIX/repo" "$TMP/repo"
if gen "$TMP/repo" "$TMP/walked" && same_tier "$FIX/expected" "$TMP/walked"; then
  ok 'outside git, the walk generates the same tier'
else
  fail 'outside git, the walk generates a different tier'
fi

# 4. a rerun over unchanged source rewrites nothing
before=$(digest "$TMP/walked")
if gen "$TMP/repo" "$TMP/walked" && [ "$(digest "$TMP/walked")" = "$before" ]; then
  ok 'a rerun over unchanged source leaves every file byte-identical'
else
  fail 'a rerun over unchanged source rewrote a file'
fi

# 5. one changed source line is drift, and the moved leaf is named
sed 's/export function loadConfig(/export function readConfig(/' "$TMP/repo/src/config.ts" >"$TMP/config.ts"
cp "$TMP/config.ts" "$TMP/repo/src/config.ts"
gen "$TMP/repo" "$FIX/expected" --check
rc=$?
if [ "$rc" -eq 1 ] && grep -q 'codebase.web.md drifts' "$TMP/out.txt"; then
  ok 'a changed source line is reported as drift in codebase.web.md (exit 1)'
else
  fail "a changed source line was not reported as drift (exit $rc)"
fi

echo "== $FAIL fail(s) =="
exit "$FAIL"
