# WORKER.md — every subagent's ground rules, as this harness runs them

An orchestrator spawned you with this file as your prompt's pointer line. The neutral rules
are the constitution module's `constitution/process/ground-rules.worker.md`: read it first;
nothing in it is restated here. Where the module is not adopted, your prompt and the
repository's own instruction file are the rules. This file says only what the Claude Code
harness adds. Your prompt says what the job is.

## Commits

- **No attribution trailer** while `.claude/process/KICKOFF.md`'s "Attribution trailers" line reads `off`:
  it overrides the harness's per-session reminder to add a `Co-Authored-By` line.
  (source: constitution/history/rulings/rulings.commits-and-pull-requests.md)
- **A fixup is a plain commit**: `git -C <repo> commit --fixup=<sha> -- <paths>`. Never run
  `rebase -i` yourself: folding is the orchestrator's, at close-out.
  (source: constitution/history/rulings/rulings.commits-and-pull-requests.md)

## The shell

- **Every git write is `git -C <path> …`.** Your working directory resets between Bash
  calls; a `cd` in one call is gone in the next. Use absolute paths throughout.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- **No interactive commands**: no editor, no `-i` flags, nothing that waits on a prompt.
- **A command that writes files runs where you can see its target**: check the path first.

## Scratch and other writers

- **Your scratch is the subdirectory your prompt names**, under the session scratchpad;
  never a shared name there. Another agent may be committing to the same branch: commit
  path-scoped, and touch only the paths your prompt gives you.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- **The tree's hooks run for you too**: `guard-tiers` refuses a write into an immutable tier,
  and `lint-on-write` hands back FAIL lines to fix in the same action.

## The budget

- Aim at about 300k tokens of context; run to 500–600k only with care; **never reach a
  context compaction**. Hand back at your last commit boundary instead, listing what is left.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- Delegate nothing further unless your prompt says you may.

## Stop and report

You cannot ask the orchestrator a question mid-job: a conflict between the brief and the
code, a failing gate, or a clause that cannot be built as written ends the job with a report.
(source: constitution/history/rulings/rulings.agents-and-budgets.md)

## The report

Your final message is the only thing the orchestrator receives: lead with the outcome, then
the evidence (files touched, commands run and what they said, commits made), and end with
exactly this block, which a hook may harvest into memory:

```
## Insights
- <decisions made and why, gotchas hit, invariants found: one to six bullets>
- <or the single bullet: none>
```

(source: constitution/history/rulings/rulings.agents-and-budgets.md)
