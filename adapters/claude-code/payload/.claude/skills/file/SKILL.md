---
name: file
description: File knowledge into the tree as a leaf with its Contents row and tags in ONE action. Use when asked to "file this", "add a leaf", "record this decision/fact/ruling", "note this for later", "file the PR body / plan / kickoff", or when durable knowledge surfaces mid-task.
argument-hint: "<topic or path> [--branch <dir>]"
allowed-tools: Bash(bash scripts/find.sh:*), Bash(bash scripts/cure.sh:*), Bash(git -C private:*), Bash(cp:*), Read, Glob, Grep
---

# File a leaf

Target: `$ARGUMENTS` (`--branch <dir>` pins the branch; otherwise resolve it). The grammar
is `rules/branch-grammar.md`; this skill is its one-action procedure.

1. **Route by KIND; this decides the TREE before anything else** (`AGENTS.md`, "Where to
   write"):

   | Kind | Tree | Home |
   | ---- | ---- | ---- |
   | ruling | public | the product's `history/rulings/`: added verbatim (`cp` plus a manifest row), never Written |
   | design · research · glossary · organisation-wide fact | public | the matching branch; `design/` per `rules/design-tier.md` |
   | feature-log entry | public | `public/<catalog>/<Product>/features/features.<area>.md`, only when the pull request merges (`rules/feature-log.md`) |
   | bill | constitution | only where the constitution module is adopted; its own process documents say where and how |
   | plan · kickoff | private | `private/<catalog>/<Product>/plans/<YYYY-MM>/plan.<YYYY-MM>-<n>.<product>-<slug>.md`; kickoffs under `kickoffs/<YYYY-MM>/` with the plan's number |
   | PR body · appendix | private | the product mirror's `prs/<YYYY-MM>/` or `appendices/<YYYY-MM>/`, the plan's month (`rules/provenance-tiers.md`) |
   | journal entry · epic · ledger · retro · reflection | private | `private/journal/` per `rules/active-work.md` |

   A private kind on a machine with no `private/` tree: STOP and say so; never file it
   publicly instead.
2. **Locate the branch.** `bash scripts/find.sh -l` for the vocabulary, then
   `bash scripts/find.sh <tags>` in the words a searcher would type (`-p` when the private
   scope is off). Propose the deepest matching branch and a leaf name in the shape its
   siblings use. No branch fits: create one from `templates/branch/` and replace every
   placeholder.
3. **Respect the tier.** Immutable tiers take records verbatim: `cp` the file in, never
   Write or Edit it (the `guard-tiers` hook refuses). A landed plan is frozen.
4. **Read `.agent`** when `bash scripts/find.sh -x <branch>` reports one.
5. **Write the leaf** from `templates/branch/leaf.md`: an H1, one topic, at most about 120
   lines. A `design/` leaf carries `_source:_` and `_reviewed:_` under its H1. **A public leaf
   never links to, or cites the path of, anything under `private/`.**
6. **Add the Contents row** to the branch's `.index.md` in the same action: `File | Purpose`,
   or the manifest columns where the table has them (Landed as `—` until it lands).
7. **Extend `.tags`** when the leaf keeps using a word the tags lack; reuse before inventing.
8. **Run `bash scripts/cure.sh --fast`**: 0 FAILs, fixed in the same action.
9. **A private filing ends with ONE commit of the private repository**, path-scoped:
   `git -C private add <new files>` then `git -C private commit -m "<subject>" -- <paths>`;
   never `add -A`. The parent repository is never committed by this skill.
10. **Report** the leaf path(s), the index row(s), any tags added and the private commit.
