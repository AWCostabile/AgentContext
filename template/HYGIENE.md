# Hygiene

Not in this repository yet. This file will describe the linter's two layers, check by check:

- **Invariants, which fail.** `scripts/cure.sh` reports a broken structural rule, such as a leaf with
  no Contents row, a broken relative link, a public link into the private tree, or a missing `.tags`.
  The tree should stay clean of these.
- **Smells, which warn.** `scripts/smell.sh` reports what is probably wrong and needs a human to
  judge, such as process vocabulary in a public leaf or a leaf that has grown too long.
