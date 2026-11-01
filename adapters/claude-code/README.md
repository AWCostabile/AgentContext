# Claude Code

The adapter for the Claude Code harness. Its payload is described in
[payload/README.md](./payload/README.md) and is not in this repository yet.

## 1. What the adapter enforces

- **A pre-write tier guard hook.** A write or edit under an immutable tier is refused before it
  happens.
- **An orient hook at session start.** It prints the work journal, so a session opens knowing what is
  in flux.
- **Skills.** `/file` files a leaf with its row and tags as one action. `/find` searches by tag or
  keyword. `/cure` runs the linter and repairs what it finds. `/kickoff` writes a paste-ready prompt
  from a plan. `/retro` runs a retrospective over a block of landed work.
- **Subagents** for lookups, filing, review and retrospectives.
- **Output styles** for the different modes of a session.
- **Rules loaded by path.** The grammar and tier rules enter a session only when it touches matching
  files.
- **The orchestration documents.** `KICKOFF.md`, `CLOSEOUT.md` and `WORKER.md` set the ground rules
  for a session that runs other agents.
- **A one-line `CLAUDE.md`** that imports the core's instruction with `@AGENTS.md`.

## 2. What the core degrades to without it

The linter and convention stand in for the pre-write hook, so tier violations are caught at lint time
rather than at write time. Search and filing are run by hand. Nothing else is lost in the data: every
leaf, index and tag is the same with or without the adapter.

## 3. What a port must reproduce

To be filled when the payload lands.
