# Adapters

An adapter adds what one agent harness can enforce on top of the neutral core. The core stays usable
without any of them.

## The contract

- **Keyed by harness, not by model.** An adapter is about the tool running the agent, not the model
  behind it.
- **Each adapter is a `README.md` and a `payload/`.** Stubs carry the README only.
- **An adapter may ship a `boot-check.sh`** beside its payload, never inside it: the deploy smoke
  runs it against a deployed instance to boot the harness headless, and reads exit 3 as "not run".
- **The payload is copied verbatim** into the instance root by the deployer's `--adapter <name>`.
- **The deployer is the one unpack.** No adapter has its own installer.
- **The neutral core never references an adapter.** Its entry point is `AGENTS.md`.

## The adapters

| Adapter | Status |
| ------- | ------ |
| [Claude Code](./claude-code/README.md) | written |
| [Codex](./codex/README.md) | stub, porting spec in section 3 |
| [Cursor](./cursor/README.md) | stub, porting spec in section 3 |
| [Gemini CLI](./gemini-cli/README.md) | stub, porting spec in section 3 |

## What every adapter README says

Three sections are required, in this order:

1. **What the adapter enforces.** What the harness does for the method once the payload is in place.
2. **What the core degrades to without it.** What stands in for that enforcement, and what is lost.
3. **What a port must reproduce.** The behaviour another harness has to match to count as a port.

Section 3 cites the checklist below rather than restating it; a stub's section 3 is that
citation alone, so every port is held to one list.

## Contributing

An adapter is a port of one list: the behaviours an agent is expected to show when it operates
out of a deployed instance of this method. The core's `AGENTS.md` asks for them of every agent;
an adapter makes its harness enforce, automate or prompt for as many as it can, and its README's
section 2 says which fall back to convention. A port counts as one when it answers each item:

1. **The entry point.** The harness's own instruction file loads the core's `AGENTS.md` (an
   import, or a one-line pointer) and adds nothing of its own to the method.
2. **Orientation at session start.** The agent opens with the tree's bearings, in at most about
   45 lines: the `cure.sh --fast` verdict; `private/journal/latest.md` when it exists; with a
   private tree, the count of manifest rows landed since the newest retro
   (`scripts/lib-manifest.sh`); one line per repository (this one, its private tree, each sibling
   with a `.git`) with branch and ahead/behind; the local branches with no upstream.
3. **The reading order.** `.conf` first; the journal's status page when this machine has one;
   indexes descended, never crawled; tags resolved with `scripts/find.sh`; a branch's `.agent`
   obeyed before reading or writing there. These are `AGENTS.md`'s own; a harness that cannot
   enforce them still leaves them to the agent, and says so.
4. **The start prompt is the instance's own instruction, and a sibling is read on first touch.**
   No other workspace project's instruction is loaded at session start. The first time the agent
   touches a sibling — a tool's path falls under one of the folders the instance's workspace
   file names — it reads that sibling's `.agents/.id.meta` when present (its identity: an id, a
   name, a date, never a path) and then its instruction file, once per session per sibling. A
   harness that can watch tool paths hands both over as context at that moment; one that cannot
   leaves the read to the agent.
5. **A moved project is noticed.** With the context-retention module adopted, the module's
   `check` runs at session start over the instance and the workspace folders. Where the harness
   files a project's memory or history under a key derived from its path, the adapter re-attaches
   them under the new path, or names where the old material sits; where it files nothing by path,
   the check's one line is enough.
6. **The pre-write guard.** A write or edit into `public/**/history/`, `constitution/history/`, or
   the private tree's `prs/`, `appendices/` and `journal/retros/` is refused before it lands, with
   one line naming the path and the rule. `.index.md`, `.tags` and `.agent` are never refused; a
   PR body whose `_landed as:_` line reads `—` is never refused; an environment variable lets a
   deliberate exception through. Plans and kickoffs are not refused by path.
7. **The lint after write.** After a write into `public/`, `private/`, `templates/`,
   `constitution/`, `AGENTS.md` or `README.md`, `scripts/cure.sh --fast` runs and its FAIL lines
   and verdict reach the agent; nothing is reported when the tree is sound.
8. **Kickoff detection.** On a session's first prompt only, a first line of `Mode: orchestrated`,
   or two of the markers WORKING DIRECTORIES, HARD RULE, VERIFY RATHER THAN ASSUME, CLOSE-OUT,
   SETTLE WITH, puts `KICKOFF.md` in the agent's context and switches it to the orchestrated
   posture; `Mode: scoping` keeps the default.
9. **Two postures.** A scoping posture by default, whose register follows `.conf`'s `AI_TONE` and
   `AI_TECHNICALITY`, and an orchestrated posture for kickoff sessions that honours `ORCH_BUDGET`.
10. **The five procedures** as commands or equivalents: file (leaf, row and tags as one action,
    routed by kind, ending with `cure.sh --fast` and one private commit), find (tags, then
    keywords, then expand and descend), cure (both linters, repairs per `HYGIENE.md`, standing
    smells reported with reasons), kickoff (from a plan and its bill with the constitution
    module's kickoff template, degrading to a hand-written kickoff without it), and retro (a
    window of landed work assembled, then a retrospective leaf with computed numbers).
11. **The delegated roles**: a read-only lookup, a filer, a read-only leaf reviewer, a read-only
    code reviewer whose findings cite `path:line`, a retrospective writer, and three
    implementation tiers (design-sensitive, standard, mechanical), each ending its report with an
    `## Insights` block.
12. **Rules loaded by path.** Touching a governed path brings the matching `rules/<name>.md` into
    the agent's attention, by pointer, never by copy.
13. **The orchestration ground rules**, one file per reader (orchestrator at the start, every
    delegated agent, orchestrator at the close), saying only what the harness adds to the neutral
    process documents, with each rule's source named.
14. **Every hook fails open.** A missing interpreter, a slow repository or a malformed input
    degrades to silence or to "?"; no hook ever wedges a session.

The shape is the contract above: a `README.md` with the three sections, a `payload/` the deployer
copies verbatim, an optional `boot-check.sh` beside it, and a row in the table. Open the
adapter's pull request with the checklist answered item by item, naming the file in the payload
that meets each one, or the line in section 2 that says it is left to convention.
