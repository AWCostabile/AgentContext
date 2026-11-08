# The wave ground rules: three files, each for the reader that needs it

_source:_ history/rulings/rulings.waves-and-close-out.md WK1–WK18; history/rulings/rulings.agents-and-budgets.md AG1–AG13; history/rulings/rulings.commits-and-pull-requests.md CP1–CP7; history/rulings/rulings.hygiene-and-gates.md HG8
_reviewed:_ 2026-11-02

A wave is a piece of implementation work run by an orchestrating session from a kickoff, much
of it done by agents the session delegates to. What every wave inherits (the invariants, the
gate shape, the commit discipline, the close-out) is written once, in the ground-rules files
under `constitution/process/`, so a kickoff states only what is particular to its wave and a
spawn prompt only what is particular to its job (WK2). This article is the law those files
enforce; each of them cites it.

## Three readers, three files

The ground rules are split by the party that reads them, and a reader loads its own file and
nothing it does not need (WK3):

| File | Reader | Holds |
| --- | --- | --- |
| [ground-rules.orchestrator.md](../process/ground-rules.orchestrator.md) | the orchestrating session, at the first prompt | the hard rules, the gate report, the rules of running a wave |
| [ground-rules.worker.md](../process/ground-rules.worker.md) | every delegated agent, from its spawn prompt | the commit shape, the write discipline, stop-and-report, the budget, the report |
| [ground-rules.closeout.md](../process/ground-rules.closeout.md) | the orchestrating session, when the proof run is done | the two moments, the walkthrough, the fold and the check, the review loop, the filings, the landing |

**Nothing is restated across the three.** A rule lives in the file of the party that acts on
it; another file that needs it points there. The worker's file points at the repository's own
instruction file for conventions instead of repeating them, and none of the three restates an
article. Every rule carries a source line naming the ruling it rests on, so an instruction can
be traced to its law without reading its history (WK4). How a kickoff and its brief are written
is the [kickoff guide](../process/kickoff-guide.md)'s.

## How each file reaches its reader

A pointer line is the mechanism (WK5). A kickoff's second line is
`Ground rules: constitution/process/ground-rules.orchestrator.md`, and every spawn prompt's
second line is the same with `ground-rules.worker.md`. The orchestrator's file ends by pointing
at the close-out file, which is read when the proof run is done and not before, because nothing
in it acts earlier. An adapter may also load a file when it detects a kickoff's first line, but
nothing depends on it: a session that only reads its prompt still finds its rules. Agent
profiles that delegated agents run under carry the worker's pointer line too (AG11).

## The caps

Each file is loaded whole by every session or agent that reads it, so each is capped by a number
the linter reads. A cap is the file's measured length rounded up to the next ten, plus twenty
lines of headroom, and it is raised only by a bill (HG8):

| File | Measured as shipped | Cap |
| --- | --- | --- |
| `ground-rules.orchestrator.md` | 78 | 100 |
| `ground-rules.worker.md` | 52 | 80 |
| `ground-rules.closeout.md` | 77 | 100 |

An instance that edits a file measures it again and sets its cap by the same method, in the bill
that makes the edit. A file that would outgrow its cap is carrying law again: the reasoning moves
into an article, and the file keeps the instruction.

## The kickoff

- A scoping conversation that produces a plan ends with its kickoff (WK1).
- A kickoff never repeats an invariant, and overrides one only explicitly, by name (WK2).
- A kickoff pins its brief at the brief's private commit, so a later amendment shows in one log
  (WK6).
- A gate is phrased as a proof of what it cares about, never as a command's spelling (WK7), and
  the first output of a wave is the gate report, confirmed before the first write (WK8).

## Running the wave

- One surface per implementation job; the full battery stays with the orchestrator, and a
  delegated agent reruns only the tests it touched (AG1).
- A job briefed as fitting one context is sized before it is spawned (AG2); a delegated agent
  works to a token budget and hands back at a commit boundary rather than reach a compaction
  (AG3).
- Every git write names its repository and checks where it runs (AG4); concurrency is the
  normal case, so scratch, commits and worktrees are kept apart by construction (AG5, AG6).
- Long-running servers run in a visible window, and an idle notification gets no reply (AG7,
  AG8).
- A delegated agent stops and reports rather than invent, and its final message is data (AG9,
  AG10).
- `ORCH_BUDGET` scales the delegation and the ceremony, and a short cache window is bridged by
  keeping the session warm (AG12, AG13).

## Commits

Subjects read as product updates (CP1); commits are small and made as the work goes (CP2); a fix
to unreleased work is a fixup folded at close-out (CP3); a rider's code and tests are separate
commits (CP4); review fixes describe the fix (CP5); every commit is path-scoped (CP6); and the
close-out check enforces what instruction alone did not (CP7). The prefix set and the refused
trailers are each product's, in its [code standards](../process/templates/code-standards.md).

## The wave's end

The walkthrough gates the immutable tiers (WK9) and its riders are counted aloud (WK10). A wave
has two moments, close-out and the landing (WK11), and an epic's close runs its retrospective
(WK12). Work spanning several waves stacks its branches (WK13), and a stacked wave starts on the
earlier one's green proof (WK14). A worktree releases its branch when its last agent is done
(WK15); a cross-repository breakage is a ledger row (WK16); agents never push (WK17); and
documentation rides the change that alters what it describes (WK18).
