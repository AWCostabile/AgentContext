---
name: cure
description: Lint and heal the knowledge tree. Use when asked to cure, tidy or check the tree, after adding several files, before merging a branch, or when common/scripts/cure.sh or common/scripts/smell.sh reports findings.
allowed-tools: Bash(bash common/scripts/cure.sh:*), Bash(bash common/scripts/smell.sh:*), Bash(bash common/scripts/find.sh:*), Bash(git -C private:*), Read, Glob, Grep
---

# Cure the knowledge tree

Two layers, run in order: `cure.sh` invariants FAIL, `smell.sh` heuristics WARN.
`common/HYGIENE.md` is the contract of both: every check's signal, its rectification and its
deliberate exceptions. Both lint `public/` always and the private mirror when this machine
has one; a fix inside `private/` ends with one path-scoped commit of the private repository.

1. Run `bash common/scripts/cure.sh` from the tree root.
2. Repair every FAIL as `common/HYGIENE.md` prescribes for its id: a missing index or `.tags`, an
   orphan leaf, a dead link. Two never get a mechanical fix:
   - **a `private` tag or a link into `private/` under `public/`**: a privacy boundary. Never
     copy the private record across; lift a ruling verbatim into a public rulings leaf and
     cite that, or drop a citation that only narrates the work. Unsure: ask the user.
   - anything that would delete or move a filed leaf: archive instead.
3. Judge every WARN (length, table width, near-duplicate tags) per `common/HYGIENE.md` and
   `common/rules/branch-grammar.md`; `bash common/scripts/find.sh -l` shows which tag spelling has more
   usages.
4. Re-run `bash common/scripts/cure.sh` until it reports 0 FAILs.
5. Run `bash common/scripts/smell.sh` and judge each `[SMELL Sxx]` per its `common/HYGIENE.md` section:
   apply the mechanical rectifications directly; a content smell (a stale or unsourced
   design leaf, row drift, process vocabulary in `public/`) goes to the user or to the
   `scrutinizer` subagent, whose verdict is applied through `/file`.
6. Re-run `bash common/scripts/smell.sh --quiet`, then report what changed and every smell left
   standing, each with a one-line reason.
