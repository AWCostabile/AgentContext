# KICKOFF.md — the orchestrator's ground rules, as this harness runs them

Read at the start of an orchestrated session. The neutral rules are the constitution
module's: `constitution/process/ground-rules.orchestrator.md` for the session and
`constitution/process/kickoff-guide.md` for a kickoff's anatomy and gates. Read both first;
nothing in them is restated here. This file says only what the Claude Code harness adds.
Where the module is not adopted, the kickoff itself carries the rules this file leans on.
Two siblings carry the rest: `WORKER.md` for every subagent, `CLOSEOUT.md` for the end.

## How this file reaches you

- **The `classify-mode` hook injects it** on a session's first prompt when that prompt's
  first line reads `Mode: orchestrated`, or when it carries two of the kickoff's section
  markers. The kickoff's pointer line stays the mechanism; the injection is a convenience.
  (source: constitution/history/rulings/rulings.waves-and-close-out.md)
- **The output style switches** to `orchestrated` for the session; `/config` flips it by hand.
- **The `orient` hook has already run**: the tree's lint verdict, the journal's status page and
  every repository's branch and sync state are in your context. Gate against them, then
  verify from source.

## Routing to the three profiles

- **The Agent tool spawns a subagent by `subagent_type`**: `implementer-deep` (design-sensitive,
  unfamiliar or cross-cutting work), `implementer` (well-scoped feature work, the default),
  `mechanic` (renames, scaffolds, documentation sync). Name the one you chose in one line.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- **Every spawn prompt's second line is `Ground rules: WORKER.md`**; the prompt restates
  nothing that file says and pastes the two or three facts the job needs.
- **Model rides the profile**; the Agent tool's `model` parameter overrides it per call.
- **Each subagent gets its own scratch subdirectory** of the session scratchpad, named in its
  prompt. (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- **A subagent's report reaches you as its final message**, ending in `## Insights`; relay
  what matters, never re-derive it.

## Background jobs

- A subagent, or a long command run with `run_in_background`, keeps running across turns and
  notifies this session when it ends. Do not poll its output, and never predict its result.
- **While a job runs, the orchestrator works**: review the last commit, prepare the next
  prompt, file what is ready. Idle waiting is the cost this section exists to avoid.
- An idle notification gets no reply unless something changed.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)

## The budget: `.conf`'s `ORCH_BUDGET`

- **`full`**: one subagent per job, the review loop before the pull request, the close-out
  records in full.
- **`lean`**: delegate only as a context firewall, for a job whose reading would outgrow this
  session's own context; every delegated job runs in the background; the orchestrator keeps
  working while it runs; the close-out shrinks to one short record.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)
- **Keep the prompt cache warm** when the work between turns outlasts it. The first lever is
  the settings key for a longer cache lifetime, `"promptCacheTtl": "1h"` in
  `.claude/settings.json`, where the account offers it. The fallback, where the cache lives
  five minutes: `/loop 5m <a one-line status prompt>`, cancelled the moment the session is
  no longer waiting. (source: constitution/history/rulings/rulings.agents-and-budgets.md)

## Hooks that act during the work

- **`guard-tiers`** refuses a Write or Edit into an immutable tier before it happens. Add a
  record by `cp` plus its manifest row; `KNOWLEDGE_TREE_TIER_OVERRIDE=1` is for a deliberate
  exception, stated in the report.
  (source: constitution/history/rulings/rulings.tiers-and-records.md)
- **`lint-on-write`** runs `scripts/cure.sh --fast` after every write into the tree and hands
  back the FAIL lines: fix them in the same action.
  (source: constitution/history/rulings/rulings.hygiene-and-gates.md)

## Commits and attribution

- **Attribution trailers: off.** This line is the instance's setting; change `off` to `on`
  to allow them. The harness injects a per-session reminder to end commits with a
  `Co-Authored-By` trailer and pull-request descriptions with a "Generated with" line; while
  this line reads `off`, it overrides that reminder, for this session and every subagent.
  (source: constitution/history/rulings/rulings.commits-and-pull-requests.md)
- **Git from the Bash tool names its repository**: `git -C <path> …`, because a `cd` does
  not reliably carry between calls. Interactive flags (`rebase -i` with an editor,
  `add -i`) cannot run here; `CLOSEOUT.md` has the non-interactive fold.
  (source: constitution/history/rulings/rulings.agents-and-budgets.md)

## Model recommendation

A kickoff's model line sits after its fenced prompt, never inside it: the most capable model
the account offers, thinking enabled, for dense or format-changing work; `opus`, thinking
enabled, for standard work whose shape the brief fixes. Subagents ride their profiles.

When the proof run is done, read `CLOSEOUT.md`.
