# Ground rules: the orchestrating session

_article:_ constitution/articles/article.wave-ground-rules.md

Read this before anything else when a kickoff's second line points here. A kickoff states only
what is particular to its wave; everything below applies unless the kickoff overrides a rule
explicitly, by name. Every delegated agent reads
[ground-rules.worker.md](./ground-rules.worker.md); this session reads
[ground-rules.closeout.md](./ground-rules.closeout.md) when the proof run is done. A kickoff's
anatomy is the [kickoff guide](./kickoff-guide.md)'s. The product's own conventions are in its
repository's instruction file.

## Hard rules

- **Agents never push; the owner raises the pull request**, so the whole change is reviewed
  before it exists anywhere else. (source: WK17)
- **The tiers hold in every tree**: provenance is added verbatim with its manifest row and never
  edited; a landed plan is frozen. (source: TR2, TR4)
- **Links run one way, and process never crosses**: nothing shared links to or cites a private
  record; the one thing a wave distils into `public/` is the feature-log entry. (source: SP5, SP9)
- **Knowledge lands in the right tree**: what is now true of a product in `public/`; what is now
  true of the tree itself in `constitution/`; how the wave was run in `private/`, committed as it
  is filed. (source: TS1, SP14)
- **Confirm before code**: the gate report, the ordered scope and any design proposal are
  confirmed by the owner before the first write. (source: WK8)

## Verify rather than assume

Every wave opens with a gate report, before any write. A gate is phrased as a proof of what it
cares about ("a working interpreter: it runs an empty script"), never as a command's spelling;
a clause the bill marks **verify first** is a gate naming the spike that proves it.
(source: WK7, BL17)

1. **The brief exists at its pinned commit.** A session that cannot find the brief its kickoff
   names stops and says so; a brief amended since its pin is read again. (source: WK6, WK8)
2. **Main is clean at or past the commit the kickoff names.** Behind it, stop: the world moved
   since the brief. (source: WK8)
3. **Pins and versions are read from source**, never from the brief; a mismatch is reported,
   never reconciled silently. (source: WK7)
4. **The shapes the wave builds on exist as described**: the files, keys and constants named.
   (source: WK7)
5. **The branch**: created off main, or, for a later wave of a stacked plan, off the earlier
   wave's squash. If it already exists, stop and ask: resuming is the owner's call.
   (source: WK13)
6. **The baseline is green** before the first change: the product's battery passes on main.
   (source: AG1)
7. **Report** all of the above with the ordered scope, then wait. (source: WK8)

## Running the wave

- **Phase boundaries are commit boundaries**, and this session's own commits obey the worker's
  commit rules. (source: CP2)
- **The full battery stays with this session**, green at every phase boundary; one surface per
  implementation job, and a delegated agent reruns only the tests it touched. (source: AG1)
- **Every spawn prompt's second line is the worker's pointer line**,
  `Ground rules: constitution/process/ground-rules.worker.md`, and the prompt restates nothing
  that file says; it names the agent's own scratch subdirectory. (source: WK5, AG5)
- **A job briefed as fitting one context is sized** before it is spawned. (source: AG2)
- **An idle notification gets no reply** unless something changed. (source: AG8)
- **Long-running servers run in a visible window** from the start, never in a background task
  with a time cap. (source: AG7)
- **Concurrency is the normal case**: a wave's writes go to a worktree when another branch is in
  flux on the shared checkout, and no shared private file is written while another session is
  active on the machine. (source: AG5, AG6)
- **A worktree releases its branch** when its last agent is done with it, never under one still
  committing, and is removed only after its pull request merges. (source: WK15)
- **A default this session took stays "defaults taken" in the brief**, lifted into a bill only
  once the owner has said yes to it. Silence is not a ruling. (source: BL16)
- **A breakage this wave causes in another repository is a ledger row**, recorded when found and
  never removed. (source: WK16)
- **Documentation rides the change**: a contract document changes in the commit that changes the
  behaviour it describes. (source: WK18)
- **Under `ORCH_BUDGET=lean`**, work inline, delegate only where a job's reading would outgrow
  this context, keep working while delegated jobs run in the background, and keep the close-out
  to one short record. (source: AG12)
- **Where the prompt cache expires sooner than the gaps between turns**, keep the session warm
  with a cheap periodic action rather than letting a long context go cold. (source: AG13)
- **When the proof run is done**, read the close-out ground rules. (source: WK3)
