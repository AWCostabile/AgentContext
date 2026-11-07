# The work journal: what is in flux on one machine, and how the private repository is kept

_source:_ history/rulings/rulings.shared-and-private.md SP13–SP14; history/rulings/rulings.tree-structure.md TS14; history/rulings/rulings.waves-and-close-out.md WK11–WK12, WK16; bills/bill.2026-11-2.delegated-agents.md DA5–DA6 (bill — pending enactment); history/rulings/rulings.bills-and-law.md BL18
_reviewed:_ 2026-11-04

What is in flux is a fact about one machine, so it lives in the private tree, in
`private/journal/`. On a machine with no private tree there is no active-work state, and nothing
pretends there is (SP13). The journal's layout, its two moments' filings and its commit rules
are instructions in [common/rules/active-work.md](../../common/rules/active-work.md); this article holds why.

## The layout

The journal's root holds `latest.md`, the status page, beside five branches (TS14):

| Branch | Holds |
| --- | --- |
| `entries/<YYYY-MM>/` | one dated entry per finished wave, written at its close-out and never edited |
| `epics/` | the epics, each grouping the waves of one programme |
| `ledgers/` | what spans products and outlives a wave: a roadmap, a ledger of cross-repository breakages |
| `retros/<YYYY-MM>/` | the retrospectives, by month of the run; append-only provenance |
| `reflections/<YYYY-MM>/` | the sessions' own reflections, by month |

`latest.md` is at most about a dozen lines (in flux, last landed, next open, unpushed branches),
because a session reads it whole before anything else. Its path never moves: the root
instruction, the ground rules and any orientation an adapter prints spell it.

## Two moments, each with its own filings

A wave has two moments (WK11), and none of the filings below alone is a landing:

- **Close-out**: the pull-request body filed in its repository's mirror; the dated journal
  entry (what was done, where, the proof, and each touched area's
  [feature-log](./article.feature-log.md) entry drafted in it); `latest.md` rewritten; the epic
  row marked `[~]`.
- **Landing**: the drafted entries appended to the product's `features/`, dated by the merge;
  "Landed as" stamped on the manifest rows; the epic row marked `[x]` with its pull request and
  commit; `latest.md` rewritten; the private repository tagged `landed/<date>-<slug>`.

The root `AGENTS.md` is touched by neither: its pointer to the journal is static.

A breakage one repository's change causes in another is a ledger row, recorded when it is found,
closed by the change that fixes it and never removed, so the ledger remains the history of what
broke and when it was mended (WK16).

## Epics and the retrospective

When an epic's last row flips to `[x]`, the same action runs the retrospective over it, or the
journal entry records why the retrospective is deferred and until when (WK12). The smell S17
counts landings since the last retrospective as a backstop.

A reflection proposes; a retrospective disposes (BL18). The retrospective's window lists every
reflection filed inside it, and its leaf carries a table with one row per proposal: taken up
(naming the bill clause or the landed change), deferred (naming what it waits on) or declined
(with a one-line reason). A proposal no retrospective has disposed of is carried into the next
one, and each recommendation becomes a bill clause or a declined row at the next scoping
conversation. Nothing a session proposes is left to someone remembering to read it.

## The private repository

The private tree is a repository of its own, run on one trunk (SP14):

- one `main`, no feature branches and no pull requests; history is never rewritten, so it takes
  no fold. A short-lived branch is sanctioned only for a bulk restructure that may need
  abandoning whole;
- one commit per filing action (leaf, row and tags), made as the work is done; the vocabulary
  of plans, waves and pull requests is welcome in its subjects, because this history is the
  process record;
- commits are path-scoped, new files added by name first, never staged wholesale;
- a lightweight tag marks each landing;
- a private remote is a backup and nothing more: never force-pushed, pushed at every close-out
  and at the end of any sitting that committed, a failed push reported and never worked around.

## Concurrency

Concurrency is the normal case (DA5). Each delegated agent writes under its own scratch
subdirectory; on a shared checkout every commit is path-scoped; a wave's writes go to a worktree
when `latest.md` shows another branch in flux there.

While another session is active on the machine, a coordinating session writes no shared private
file: `latest.md`, an epic, a ledger, a plan in flight. An isolated leaf with a path-scoped
commit is safe (DA6).
