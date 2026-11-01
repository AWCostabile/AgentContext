# Claude Code

The adapter for the Claude Code harness. Its payload, and what each file is, is described in
[payload/README.md](./payload/README.md); `init.sh --adapter claude-code` lays it onto an
instance.

## 1. What the adapter enforces

- **A pre-write tier guard.** A `PreToolUse` hook refuses a Write or Edit into an immutable
  tier before it happens: `public/**/history/`, `constitution/history/`, and in the private tree
  `prs/`, `appendices/` and `journal/retros/`. A branch's own `.index.md`, `.tags` and `.agent`
  stay writable, and so does a PR body whose `_landed as:_` line still reads `—`.
  `KNOWLEDGE_TREE_TIER_OVERRIDE=1` lets a deliberate exception through.
- **A lint after every write.** A `PostToolUse` hook runs `scripts/cure.sh --fast` after any
  write into the trees, `templates/`, `AGENTS.md` or `README.md`, and hands the FAIL lines back
  to the session to fix in the same action.
- **Orientation at session start.** A `SessionStart` hook hands the session the tree's lint
  verdict, the journal's status page, the retro pressure, and every repository's branch, sync
  state and unpushed branches.
- **Kickoff detection.** A `UserPromptSubmit` hook recognises a kickoff on a session's first
  prompt and injects `KICKOFF.md`; the output style switches from `scoping` to `orchestrated`.
- **Skills.** `/file` files a leaf with its row and tags as one action; `/find` searches by tag,
  then keyword; `/cure` runs both linters and repairs what they find; `/kickoff` writes a
  paste-ready prompt from a plan and its bill (it needs the constitution module); `/retro` runs
  a retrospective over a window of landed work.
- **Subagent profiles.** `librarian` (lookups), `filer` (filing), `scrutinizer` (leaf
  hygiene), `skeptic` (pre-pull-request code review), `brainiac` (retrospectives), and three
  implementer tiers, `implementer-deep`, `implementer` and `mechanic`, the orchestration
  ground rules route to.
- **Rules loaded by path.** Six loaders point a session at the grammar or tier rule for the
  paths it is touching, without copying the rule.
- **The orchestration ground rules.** `KICKOFF.md`, `WORKER.md` and `CLOSEOUT.md` add this
  harness's mechanics (routing, background jobs, the lean budget, the prompt-cache keep-alive,
  the attribution setting, the non-interactive fold) to the neutral process documents.
- **A one-line `CLAUDE.md`** that imports the core's instruction with `@AGENTS.md`.

## 2. What the core degrades to without it

The linter and convention stand in for the pre-write guard: a tier violation is caught when
`scripts/cure.sh` and `scripts/smell.sh` run, not when the write is attempted. Orientation is
reading `private/journal/latest.md` by hand, as `AGENTS.md` instructs. Search and filing are
run by hand from `AGENTS.md` and `rules/`. Kickoffs carry their ground rules by pointer line
alone. No data is lost: every leaf, index and tag is the same with or without the adapter.

## 3. What a port must reproduce

A port to another harness counts as one when it matches each of these:

1. **The entry point.** The harness's own instruction file loads the core's `AGENTS.md`
   (an import, or a one-line pointer), and adds nothing of its own to the method.
2. **The pre-write guard.** A write or edit into `public/**/history/`, `constitution/history/`,
   or the private tree's `prs/`, `appendices/` and `journal/retros/` is refused before it
   lands, with one line naming the path and the rule. `.index.md`, `.tags` and `.agent` are
   never refused; a PR body whose `_landed as:_` line reads `—` is never refused; an
   environment variable lets a deliberate exception through. Plans and kickoffs are not
   refused by path.
3. **The lint after write.** After a write into `public/`, `private/`, `templates/`,
   `constitution/`, `AGENTS.md` or `README.md`, `scripts/cure.sh --fast` runs and its FAIL lines
   and verdict reach the agent; nothing is reported when the tree is sound.
4. **The orient context.** At session start the agent receives, in at most about 45 lines: the
   `cure.sh --fast` verdict; `private/journal/latest.md` when it exists; with a private tree,
   the count of manifest rows landed since the newest retro (`scripts/lib-manifest.sh`); one line
   per repository (this one, its private tree, each sibling with a `.git`) with branch and
   ahead/behind; and the local branches with no upstream.
5. **Kickoff detection.** On a session's first prompt only, a first line of `Mode: orchestrated`,
   or two of the markers WORKING DIRECTORIES, HARD RULE, VERIFY RATHER THAN ASSUME, CLOSE-OUT,
   SETTLE WITH, puts `KICKOFF.md` in the agent's context and switches it to the orchestrated
   posture; `Mode: scoping` keeps the default.
6. **Two postures.** A scoping posture by default, whose register follows `.conf`'s `AI_TONE`
   and `AI_TECHNICALITY`, and an orchestrated posture for kickoff sessions that honours
   `ORCH_BUDGET`.
7. **The five procedures** as commands or equivalents: file (leaf, row and tags as one action,
   routed by kind, ending with `cure.sh --fast` and one private commit), find (tags, then
   keywords, then expand and descend), cure (both linters, repairs per `HYGIENE.md`, standing
   smells reported with reasons), kickoff (from a plan and its bill with the constitution
   module's kickoff template, degrading to a hand-written kickoff without it), and retro (a
   window of landed work assembled, then a retrospective leaf with computed numbers).
8. **The delegated roles**: a read-only lookup, a filer, a read-only leaf reviewer, a read-only
   code reviewer whose findings cite `path:line`, a retrospective writer, and three
   implementation tiers (design-sensitive, standard, mechanical), each ending its report with
   an `## Insights` block.
9. **Rules loaded by path.** Touching a governed path brings the matching `rules/<name>.md`
   into the agent's attention, by pointer, never by copy.
10. **The orchestration ground rules**, one file per reader (orchestrator at the start, every
    delegated agent, orchestrator at the close), saying only what the harness adds to the
    neutral process documents, with each rule's source named.
11. **Every hook fails open.** A missing interpreter, a slow repository or a malformed input
    degrades to silence or to "?"; no hook ever wedges a session.
