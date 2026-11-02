# Seed rulings: waves, kickoffs and close-out

_status:_ seed — adopt, amend or delete

How a piece of orchestrated work (a wave) is launched, run and ended: the kickoff and the ground
rules it leans on, the gate report, the owner's walkthrough, the two moments of close-out and
landing, and the branching of work that spans several waves. The article on
[the wave ground rules](../../articles/article.wave-ground-rules.md) and the process documents
rest on these.

- **WK1.** A scoping conversation that produces a plan ends with its kickoff, filed beside the
  plan in the private mirror.
- **WK2.** A kickoff is short and states only what is particular to its wave; the ground rules
  carry every invariant, and a kickoff overrides one only explicitly, by name.
- **WK3.** The ground rules are split by reader, the orchestrator at the start, every delegated
  agent, and the orchestrator at the close, and nothing is restated across them.
- **WK4.** Every rule in the ground rules carries a source line naming the ruling it rests on.
- **WK5.** Each reader reaches its ground rules through a pointer line in its prompt; a harness
  that can inject them may do so, but the pointer line is the mechanism.
- **WK6.** A kickoff pins its brief at the brief's commit, so a later amendment shows in one log.
- **WK7.** A gate is phrased as a proof of what it cares about, never as the spelling of a
  command.
- **WK8.** A wave opens with a gate report and its ordered scope, confirmed by the owner before the
  first write; a session that cannot find the brief its kickoff names stops and says so.
- **WK9.** Nothing a build produced enters an immutable tier until the owner has walked the build.
  The walkthrough is on by default, sits after the proof run and before the close-out check and
  the final review round, and a wave with nothing to walk opts out in one line with its reason.
- **WK10.** While the owner walks, the orchestrator states the running total at each rider; the
  growth is named once, in one sentence, and the owner decides.
- **WK11.** A wave has two moments, close-out (the branch finished, its pull request not raised)
  and the landing (the pull request merged), each with its own filings; neither alone is the
  other.
- **WK12.** When an epic's last row closes, its retrospective runs in the same action, or the
  journal records why it is deferred and until when.
- **WK13.** Work that spans several waves in one repository runs as one plan on stacked branches:
  the first wave off main, a single-commit squash of it that is never pushed, the next wave off
  that squash, and a rebase of the later wave onto main once the first merges, the tree proven
  identical across the rebase.
- **WK14.** A stacked wave starts on the earlier wave's green proof without waiting for its
  walkthrough; what waits for the walk is what the walk gates, never the line of code.
- **WK15.** A worktree releases its branch when its last agent is done with it, never under an
  agent still committing there, and is removed only after its pull request merges.
- **WK16.** A breakage one repository's change causes in another is recorded as a ledger row,
  closed by the change that fixes it and never removed.
- **WK17.** Agents never push; the owner raises the pull request, so the whole change is
  reviewed before it exists anywhere else.
- **WK18.** Documentation rides the change: a contract document changes in the commits that change
  the behaviour it describes.
