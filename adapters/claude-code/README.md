# Claude Code

The adapter for the Claude Code harness. Its payload, and what each file is, is described in
[payload/README.md](./payload/README.md); `init.sh --adapter claude-code` lays it onto an
instance.

## 1. What the adapter enforces

- **A pre-write tier guard.** A `PreToolUse` hook refuses a Write or Edit into an immutable
  tier before it happens: `public/**/history/`, `constitution/history/`, and in the private tree
  `prs/`, `appendices/` and `journal/retros/`. A branch's own `.index.md`, `.tags` and `.agent`
  stay writable, and so does a PR body whose `_landed as:_` line still reads `—`. A leaf under
  any `history/` whose first twelve lines carry a line starting `_status:_ seed` is prospective
  law, not yet enacted, and stays writable until the owner changes that line on adoption.
  `KNOWLEDGE_TREE_TIER_OVERRIDE=1` lets a deliberate exception through.
- **A lint after every write.** A `PostToolUse` hook runs `scripts/cure.sh --fast` after any
  write into the trees, `templates/`, `AGENTS.md` or `README.md`, and hands the FAIL lines back
  to the session to fix in the same action.
- **Orientation at session start.** A `SessionStart` hook hands the session the tree's lint
  verdict, the one-line brief of `scripts/review.sh` when the instance has it (the smell count,
  the inbox, the stale and uncited leaves, the retro pressure, the unpushed branches, the newest
  journal entry), the journal's status page, the retro pressure, and every repository's branch,
  sync state and unpushed branches, in at most 45 lines.
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
- **The start prompt is the instance's own instruction.** The settings set
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` to `0`: on this harness a directory added to the
  session (a workspace folder, `--add-dir`) otherwise has its instruction file loaded at session
  start, flag or no flag — measured here at about 13k tokens for a 45 KB instruction, every
  session, whether or not the session enters that repository. With the flag at `0` the harness
  loads nothing of a sibling, at start or later.
- **A sibling's instruction on first touch.** A `PostToolUse` hook on the file tools and Bash
  watches for a path under a workspace sibling (the folders the instance's workspace file names)
  and, the first time one is touched in a session, hands the session that sibling's
  `.agents/.id.meta` line and its `CLAUDE.md` (or `AGENTS.md`, when `CLAUDE.md` is the one-line
  import of it) as additional context. Once per session per sibling; a sibling never entered costs
  nothing. This is `AGENTS.md`'s first-touch rule, done for the agent.
- **A moved project's history re-attached.** With the context-retention module adopted, a
  `SessionStart` hook runs its check over the instance and the workspace folders. This harness
  files a project's transcripts and auto memory under `<config>/projects/<encoded path>/`, so a
  moved folder loses its resume list and its `MEMORY.md`; the hook derives the old and the new
  directory names (every character outside `[A-Za-z0-9]` becomes a hyphen, a rule it first checks
  against its own transcript path), and moves the old directory's files into the new one — a
  rename when the new one does not exist yet, a merge that never overwrites otherwise — then says
  in one line what it re-attached. When the rule does not reproduce the session's own directory it
  only says where the old material sits. It also hands the session the instance's own identity
  line. Without the module the hook is silent.
- **The prompt-cache lifetime, measured.** `cache-ttl.sh`, beside the payload and never in it,
  runs one cheap probe and reads the usage block: an hour, or five minutes. The run-sheet's
  retention step runs it; with `--apply` on a five-minute result it writes `promptCacheTtl` and
  `subagentPromptCacheTtl` as `1h` into the instance's `.claude/settings.local.json` and probes
  again, so the user knows whether the account grants the hour.

## 2. What the core degrades to without it

The linter and convention stand in for the pre-write guard: a tier violation is caught when
`scripts/cure.sh` and `scripts/smell.sh` run, not when the write is attempted. Orientation is
reading `private/journal/latest.md` by hand, as `AGENTS.md` instructs. Search and filing are
run by hand from `AGENTS.md` and `rules/`. Kickoffs carry their ground rules by pointer line
alone. A sibling's instruction is read by the agent itself on first touch, as `AGENTS.md` asks;
a moved project is reported by the module's `check` and repaired by hand from its README. No
data is lost: every leaf, index and tag is the same with or without the adapter.

## 3. What a port must reproduce

A port is held to the checklist in [Contributing](../README.md#contributing), item by item; this
adapter is its reference, and nothing of the list is restated here. What meets each item in this
payload: the entry point is `CLAUDE.md`; orientation is the `orient` hook; the reading order is
left to `AGENTS.md` and prompted by the orient context; the start prompt and the first-touch read
are the settings' `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=0` and the `sibling-instruction`
hook; a moved project is the `retention` hook over the module's `check`; the pre-write guard is
`guard-tiers`; the lint after write is `lint-on-write`; kickoff detection is `classify-mode`; the
two postures are the output styles; the five procedures are the skills; the delegated roles are
the agent profiles; the rules by path are the six loaders under `.claude/rules/`; the ground rules
are `KICKOFF.md`, `WORKER.md` and `CLOSEOUT.md`; and every hook exits 0 on any failure of its own.
