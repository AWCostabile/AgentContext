# Active work: the journal

_applies to:_ `private/journal/`, and the root `AGENTS.md`

`private/journal/` holds `latest.md` at its root and five branches: `entries/<YYYY-MM>/` (one
dated entry per finished piece of work, written at its close-out, never edited), `epics/`,
`ledgers/`, `retros/<YYYY-MM>/` (by run date) and `reflections/<YYYY-MM>/`. A month's first
filing creates its branch. With no private tree there is no active-work state: say so; never
invent one.

- **At close-out** (branch finished, pull request not raised): file the PR body; append the
  dated journal entry (what was done, where, the proof, each touched area's feature-log entry
  DRAFTED in it); rewrite `latest.md` (in flux, last landed, next open, unpushed branches; at
  most about twelve lines); mark the epic row `[~]`.
- **At the landing** (the product's pull request merged): append the drafted entries to the
  product's `features/`, dated by the merge; stamp "Landed as" on the manifest rows; mark the
  epic row `[x]` with the pull request and commit; rewrite `latest.md`; tag
  `landed/<date>-<slug>`. None of these alone is a landing.
- Never touch the root `AGENTS.md` for status; it points at `latest.md` and is never updated.
- Commit the private repository as you go: one path-scoped commit per filing action, trunk only;
  the vocabulary of plans and pull requests is welcome in its subjects. A private remote is a
  backup only: push at close-out and at the end of a sitting that committed, never force, and
  report a failed push.
- Append kickoff prompts below the last; never rewrite an earlier one. A scoping conversation
  that produces a plan ends with its kickoff filed beside the plan in the product's mirror.
- When an epic row flips to `[x]`, run the retrospective in the same action, or record in the
  journal entry why it is deferred, and until when. Never edit a filed retro.
- While another session is active on this machine, write no shared private file (`latest.md`,
  an epic, a ledger, a plan in flight) from a coordinating session; an isolated leaf with a
  path-scoped commit is safe.
