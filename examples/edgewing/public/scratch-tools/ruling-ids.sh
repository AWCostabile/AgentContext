#!/usr/bin/env bash
# ruling-ids.sh [prefix]: every ruling and bill-clause id in the tree, with the leaf that holds it.
# Reads public/*/*/history/rulings.*.md, constitution/history/rulings/ and constitution/bills/.
set -u
prefix=${1:-}
for f in public/*/*/history/rulings.*.md constitution/history/rulings/rulings.*.md constitution/bills/bill.*.md; do
  [ -f "$f" ] || continue
  sed -n 's/^- \*\*\([A-Z][A-Z]*[0-9][0-9]*\)\.\*\* \(.\{0,60\}\).*$/\1\t\2/p' "$f" |
    while IFS="$(printf '\t')" read -r id text; do
      case "$id" in "$prefix"*) printf '%-6s %s  %s\n' "$id" "$f" "$text" ;; esac
    done
done
