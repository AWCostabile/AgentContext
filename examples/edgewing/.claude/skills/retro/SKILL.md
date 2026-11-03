---
name: retro
description: Run the retrospective over a block of landed work (an epic or several landed plans): assemble the window, hand it to the historian subagent, and print the tree verdicts under its report. Use when asked to "run the retrospective", "review the last block of work", "are we on a healthy trajectory", or "write the retro".
argument-hint: "[--since YYYY-MM-DD | <epic name>]"
allowed-tools: Bash(git log:*), Bash(git for-each-ref:*), Bash(bash common/scripts/*), Bash(bash .claude/tools/retro-window.sh:*), Read, Glob, Grep, Agent
---

# Retrospective

Arguments: `$ARGUMENTS`. Retros are development-cycle records (`common/rules/active-work.md`): on a
machine with no private tree, say so and stop.

1. **Resolve the window.** `--since YYYY-MM-DD` is used as given (until = today). An epic
   name resolves from the `[x]` rows of its leaf in `private/journal/epics/`: the first
   settled date opens the window, the last landed date closes it. No argument: since = the
   date in the name of the newest `private/journal/retros/<YYYY-MM>/retro.*.md`, or the
   `installed=` date in `common/.agentcontext` when no retro exists.
2. **Assemble the block.**
   `bash .claude/tools/retro-window.sh <since> [until] > <scratch>/retro-window.<since>.txt`,
   `<scratch>` the session's scratch directory (or `${TMPDIR:-${TEMP:-/tmp}}`). Read its
   `--` count lines; an empty section 2 means nothing landed: say so and stop.
3. **Hand off.** Launch the `historian` subagent with the scratch file's path, the resolved
   window and the block's name. It writes the retro leaf (private journal), the `design/`
   repairs (public) and the index repairs through `/file`, and returns its report with the
   Trajectory table.
4. **Verdicts.** Run `bash common/scripts/cure.sh --fast` and `bash common/scripts/smell.sh --quiet` and
   print both verdict lines, verbatim, under the historian's report.
5. **Every proposal is disposed of.** When section 5 of the block lists a reflection, the
   retro leaf's "Reflections' proposals" table is mandatory: one row per proposal, each
   `taken up`, `deferred` or `declined`, plus the rows the previous retro left open. A retro
   that returns without it goes back to the historian, never filed short.
