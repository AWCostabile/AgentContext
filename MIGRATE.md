# Migrating a knowledge tree across a release

This is a run-sheet for bringing an instance across a release that moves things. It is written for a coding agent working on a user's machine, and it reads just as well for a person at a terminal. Every step has a **Run** line and a **Check** line: run the command, then confirm the check against what is now on disk before moving to the next step. Nothing here asks you to read another file and work out what to do; when a step refuses, stop and tell the user what it said.

The migration never changes the user's working branch: the release's tree is staged first, the changes land on a branch of their own, and the user walks that branch and merges it. Every report it writes stays in the instance's staging directory, `common/staging/`, which ignores its own contents, so nothing of the private tree reaches the shared one.

The pinned release is `v0.6.0`. Replace it everywhere below if the user names another (`AgentContext-0.6.0` drops the `v`).

Every command runs from a scratch directory the user is happy to delete afterwards; `<path>` is the instance (the directory holding `common/` and `public/`).

## 1. Assess

**Run** (first: both repositories must be clean)

```
git -C <path> status --short; [ -d <path>/private/.git ] && git -C <path>/private status --short
```

**Check**: it prints nothing. Anything listed is the user's work in progress: stop and ask them to commit or set it aside, then run it again.

**Run** (fetch the release from the instance's own upstream; it unpacks into `AgentContext-0.6.0/`, the directory every command below spells, and names its release from its own `RELEASE` stamp, whatever the directory is called)

```
curl -fsSL "$(cat <path>/common/.agentcontext <path>/.agentcontext 2>/dev/null | sed -n 's/^upstream=//p' | head -n 1)/archive/refs/tags/v0.6.0.tar.gz" | tar xz
```

**Check**: a directory `AgentContext-0.6.0/` exists and holds `init.sh`, `MOVES` and `scripts/find.sh`.

**Run** (what the release moves, what the user edited, and how much must be read)

```
grep -vE '^[[:space:]]*(#|$)' AgentContext-0.6.0/MOVES
bash AgentContext-0.6.0/init.sh --update --dry-run --target <path> --from AgentContext-0.6.0 > assess.txt; cat assess.txt
{ sed -n 's/^kept \([^ ]*\) (.*/\1/p' assess.txt | while IFS= read -r f; do [ -f "<path>/$f" ] && wc -c < "<path>/$f" | awk '{ print $1 * 2 }'; done; sed -n 's/^guide: //p' assess.txt | while IFS= read -r g; do wc -c < "AgentContext-0.6.0/$g"; done; } | awk '{ s += $1 } END { printf "%d bytes, about %d tokens to read\n", s, s / 4 }'
```

**Check**: the first command prints the release's `<old> <new>` pairs (they are cumulative: a pair the instance crossed in an earlier release is still listed); `assess.txt` ends with the summary line `update: N moved, N replaced, N kept, N added, N removed-upstream`, then one `guide: migrations/<version>.md` line per guide when a file is kept, and last `dry-run: nothing written to <path>`; the third prints one line of bytes and tokens. Each `kept` line of `assess.txt` is a file the user edited, which the release will not overwrite: reading it means reading it beside the release's copy, so the estimate counts it twice, and each `guide:` line once. Tell the user the pairs, the kept files and the estimate before going on.

## 2. Stage

**Run**

```
mkdir -p <path>/common/staging && bash AgentContext-0.6.0/init.sh --update --stage --target <path> --from AgentContext-0.6.0 | tee <path>/common/staging/report.txt
```

**Check**: the last line of `<path>/common/staging/report.txt` is `staged: common/staging/v0.6.0/, N file(s); nothing written outside common/staging/`, and the lines above it are the ones `assess.txt` holds, without its `dry-run:` line (an instance older than the staging directory gains one more line, `laid common/staging/.gitignore: …`). `<path>/common/staging/v0.6.0/` holds the release's tree: every core and module file as the update would place it. `git -C <path> status --short --untracked-files=all` prints nothing, or only `?? common/staging/.gitignore`. If the deployer says `common/staging/v0.6.0/ exists`, an earlier migration was not finished: stop and ask the user.

## 3. Verify

**Run** (every mention of an old name of `MOVES`, across the trees and the root documents)

```
grep -vE '^[[:space:]]*(#|$)' AgentContext-0.6.0/MOVES | awk '{ print $1 }' | LC_ALL=C sort -u | while IFS= read -r old; do bash AgentContext-0.6.0/scripts/find.sh --root <path> --refs "$old" --moves AgentContext-0.6.0/MOVES; done | LC_ALL=C sort -u > <path>/common/staging/refs.md
cut -f2 <path>/common/staging/refs.md | LC_ALL=C sort | uniq -c
```

**Check**: `<path>/common/staging/refs.md` exists (it may be empty: then nothing needs respelling), one hit per line: `<file>:<line>`, a tab, the kind (`link` or `mention`, written `link (verbatim)` or `mention (verbatim)` for a hit inside a record), a tab, the spelling found, a tab, the spelling the release gives it. The count lists how many of each kind. A hit whose kind ends `(verbatim)` is inside a record kept as it was written (a provenance tier, or a leaf a landed manifest lists): it is listed and left, and this sheet never respells it. A hit in a root document (`AGENTS.md`, `README.md`, any file at the instance root) is the update's to replace or the user's to merge, never respelled here. Every other hit under `public/` or `private/` is respelled in step 4.

The report settles everything but the kept files. When `report.txt` has `kept` lines and you can delegate, hand each kept file to its own delegated agent with the two paths, `<path>/<file>` and `<path>/common/staging/v0.6.0/<file>` (for `kept <old> (changed locally; moved to <new>)`, `<path>/<old>` and `<path>/common/staging/v0.6.0/<new>`), and ask for a summary of under twenty lines: what the release changed in the file and what the user changed, and whether the two touch the same lines. Keep the summaries for step 5 and read no tree yourself. Without delegation, run `diff <path>/<file> <path>/common/staging/v0.6.0/<file>` for each pair and summarise it the same way.

**Check**: one summary per `kept` line of `report.txt`.

## 4. Branch

**Run** (each repository's starting point recorded, then a branch named for the release in the instance and, when there is one, in the private repository)

```
printf '%s %s\n' "$(git -C <path> rev-parse HEAD)" "$(git -C <path> branch --show-current)" > <path>/common/staging/base.txt
git -C <path> switch -c migrate/v0.6.0
[ -d <path>/private/.git ] && printf '%s %s\n' "$(git -C <path>/private rev-parse HEAD)" "$(git -C <path>/private branch --show-current)" > <path>/common/staging/base-private.txt && git -C <path>/private switch -c migrate/v0.6.0
```

**Check**: `git -C <path> branch --show-current` prints `migrate/v0.6.0`, and so does `git -C <path>/private branch --show-current` when there is a private repository; `base.txt` (and `base-private.txt`) hold a commit and the branch the user was on.

**Run** (the staged files moved across by the update itself, so the manifest, the moves and the ledger are right; then one commit)

```
bash AgentContext-0.6.0/init.sh --update --target <path> --from AgentContext-0.6.0 > <path>/common/staging/update.txt
(cd <path>/common/staging/v0.6.0 && find . -type f | sed 's|^\./||') | while IFS= read -r p; do cmp -s "<path>/common/staging/v0.6.0/$p" "<path>/$p" || awk -v p="$p" '$1 == "kept" { s = $2; if (match($0, /moved to [^,)]*/)) s = substr($0, RSTART + 9, RLENGTH - 9); if (s == p) f = 1 } END { exit !f }' <path>/common/staging/report.txt || echo "DIFFERS $p"; done
git -C <path> add -A && git -C <path> commit -m "chore: core files updated to v0.6.0"
```

**Check**: `grep '^update: ' <path>/common/staging/update.txt` is the same line as `grep '^update: ' <path>/common/staging/report.txt`; the loop prints nothing: every staged file the report did not keep is now byte for byte in the instance (a `kept` line excuses the one staged path it names exactly: `kept <file> (…)` the file, `kept <old> (…; moved to <new>)` the file at `<new>`); `grep '^ref=' <path>/common/.agentcontext` prints `ref=v0.6.0`; beside the files `update.txt` reports line by line, the commit holds the rewritten manifest `common/.agentcontext` (the report's last line, `manifest: ref=v0.6.0, …`) and two things the update keeps for itself and never reports as `added`: `common/reference/updates.md`, with its one new ledger line, and each guide a `guide:` line names, copied to `common/reference/migrations/`; `git -C <path> status --short` prints nothing.

**Run** (every hit of `refs.md` that is no verbatim record and lies under `public/` or `private/`, respelled in place; then one commit per repository that changed)

```
grep -vE '^[[:space:]]*(#|$)' AgentContext-0.6.0/MOVES | awk '{ print $1 }' | LC_ALL=C sort -u | while IFS= read -r old; do bash AgentContext-0.6.0/scripts/find.sh --root <path> --refs "$old" --moves AgentContext-0.6.0/MOVES --respell; done | LC_ALL=C sort -u > <path>/common/staging/respelled.md
git -C <path> add public && { git -C <path> diff --cached --quiet || git -C <path> commit -m "docs: paths respelled to the v0.6.0 layout"; }
[ -d <path>/private/.git ] && git -C <path>/private add -A && { git -C <path>/private diff --cached --quiet || git -C <path>/private commit -m "docs: paths respelled to the v0.6.0 layout"; }
```

**Check** (the trees changed only where `refs.md` says they were respelled, and the linter is clean)

```
grep -vxFf <path>/common/staging/refs.md <path>/common/staging/respelled.md
{ git -C <path> diff --name-only "$(cut -d' ' -f1 <path>/common/staging/base.txt)" HEAD -- public private; [ -f <path>/common/staging/base-private.txt ] && git -C <path>/private diff --name-only "$(cut -d' ' -f1 <path>/common/staging/base-private.txt)" HEAD | sed 's|^|private/|'; } | LC_ALL=C sort -u | diff - <(cut -f1 <path>/common/staging/respelled.md | sed 's/:[0-9]*$//' | LC_ALL=C sort -u)
(cd <path> && bash common/scripts/cure.sh | tail -n 1)
```

The first two commands print nothing: every respelled hit is a line of `refs.md`, and the files changed under `public/` and `private/` since the starting point are exactly the files `respelled.md` names. `cure.sh` ends with `== VERDICT: 0 fail(s), …`. `git -C <path> status --short` prints nothing, and so does `git -C <path>/private status --short`.

## 5. Hand over

**Run** (what the user walks)

```
git -C <path> log --oneline "$(cut -d' ' -f1 <path>/common/staging/base.txt)"..migrate/v0.6.0
[ -f <path>/common/staging/base-private.txt ] && git -C <path>/private log --oneline "$(cut -d' ' -f1 <path>/common/staging/base-private.txt)"..migrate/v0.6.0
grep -E '^kept |^guide: ' <path>/common/staging/report.txt; grep -F '(verbatim)' <path>/common/staging/refs.md
grep -vE '^[[:space:]]*(#|$)' AgentContext-0.6.0/MOVES | awk '{ print $1 }' | LC_ALL=C sort -u | while IFS= read -r old; do bash AgentContext-0.6.0/scripts/find.sh --root <path> --refs "$old" --moves AgentContext-0.6.0/MOVES; done | LC_ALL=C sort -u | grep -vE '^(public|private)/'
(cd <path> && bash common/scripts/smell.sh | grep -E '^== SUMMARY|^\[SMELL S22\]')
```

Tell the user, in this order: the branch `migrate/v0.6.0` in the instance and, when there is one, in the private repository, with its one or two commits; that the reports beside it are in `<path>/common/staging/` (`report.txt` the deployer's, `refs.md` every mention found, `respelled.md` what was changed), local to this machine and never committed; each kept file with its summary from step 3, the release's copy at `common/staging/v0.6.0/<file>`, to merge by hand on the branch if they want the release's change; each guide named, now in `common/reference/migrations/`; the verbatim hits, left as written; the hits the third command still finds in root documents, searched again now that the update has replaced the ones it owns (read each line before reporting it: a mention can be a link's own text beside a target that is already right, and then nothing is left to do); and the smells: the summary line, and each `[SMELL S22]` line under it, a `public/` leaf reported for spelling a `common/` path (a respelled leaf now does), which is the user's to reword as the tool's name. The user walks `git -C <path> diff <the commit in base.txt> migrate/v0.6.0` and merges the branch into the one `base.txt` names, in each repository, as they merge any branch.

**Check**: the user has the branch names and the list above, and has said they will walk and merge.

**Run** (only once the user says both branches have merged and the kept files are dealt with: the staging directory emptied, its `.gitignore` kept)

```
find <path>/common/staging -mindepth 1 -maxdepth 1 ! -name .gitignore -exec rm -rf {} +
```

**Check**: `ls -A <path>/common/staging` prints `.gitignore` alone, and `git -C <path> status --short` prints nothing. The deployer never empties this directory; this step does, and only after the merge.
