# Cursor

Stub, no payload. Its section 3 is the porting spec: the list a port to this harness is checked
against, the same list as the written [Claude Code adapter](../claude-code/README.md)'s.

## 1. What the adapter enforces

Not written; the core stands alone.

## 2. What the core degrades to without it

Not written; the core stands alone. The linter and convention stand in for every enforcement in
the list below: a tier violation is caught when `scripts/cure.sh` runs, not when it is written.

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
