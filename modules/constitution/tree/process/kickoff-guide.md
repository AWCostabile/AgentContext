# The kickoff guide

_article:_ constitution/articles/article.wave-ground-rules.md

How a piece of orchestrated work is briefed, launched, walked, closed out and landed, for
whoever writes the brief and the kickoff. The rules a running session obeys are in the three
ground-rules files beside this guide; this guide says what the documents that start a wave
contain, and why. Rulings are cited by id from `history/rulings/`.

## The brief

A scoping conversation with the owner produces a plan, the brief, filed in the product's private
mirror as `plan.<YYYY-MM>-<n>.<product>-<slug>.md`, and its rulings as a bill
([bills and laws](../articles/article.bills-and-laws.md)). The brief says:

- what the work is for, in a paragraph, and what it gates on;
- the ordered scope: the phases, one line each, ending with a proof phase;
- the shapes it builds on, as they exist today, measured rather than remembered (BL10);
- every clause that states a mechanism, marked **verify first**, with the spike that proves it
  (BL17);
- the defaults taken, kept apart from what the owner ruled (BL16);
- the questions that stop for the owner; "ask if unsure" is standing and never written down.

The conversation ends with the kickoff, filed beside the plan in the mirror's `kickoffs/` (WK1).

## The kickoff

A kickoff is the paste-ready first prompt of the wave, made from
[the kickoff template](./templates/kickoff.md). It is short because the ground rules carry every
invariant; it states what is particular to its wave and overrides an invariant only by name
(WK2). Its lines, in order:

1. **Mode**: `Mode: orchestrated`, which an adapter may detect to load the ground rules.
2. **Ground rules**: `Ground rules: constitution/process/ground-rules.orchestrator.md (read
   before anything else)`, the pointer that delivers them when nothing detects the mode (WK5).
3. **Wave**: its name, and what it gates on.
4. **Brief**: the plan's path and section, pinned at its private commit (WK6).
5. **Bill**: the bill the wave builds from, with the ids in play.
6. **Repo**: where the work happens and on which branch; which repositories are read-only.
7. **Walkthrough**: `required — at <moment>`, or `not required — <reason>` for a wave with
   nothing to walk (WK9).
8. **Hard-rule overrides**: the wave's own law, such as declared format changes or an
   out-of-scope list; never an invariant restated.
9. **Gates**: real numbers read from the repositories when the kickoff is written, each phrased
   as a proof (WK7).
10. **Read**: in order, sections rather than whole documents.
11. **Scope**, **Settle with the owner** and **Close-out specifics**.

A recommendation of which model or effort tier to run belongs in the sentence after the prompt,
for the owner, never inside it.

## The gate report

The session's first output is the gate report: each gate with its evidence, the branch it will
create, and the ordered scope. The owner confirms it before the first write (WK8). A gate that
fails is reported, never worked around: the world moved since the brief.

## The walkthrough

After the proof run the owner walks the build: uses it, in the product, the way its users will.
Nothing the wave produced enters an immutable tier before then (WK9). Each thing the walk turns
up is a rider; the orchestrator states the running total at each one, names the growth once and
lets the owner decide (WK10). A documentation-only wave opts out in one line and is reviewed at
its pull request instead.

## Close-out and the landing

Close-out is the branch finished and the pull request not yet raised: the fold, the close-out
check, the review loop where adopted, then the filings. The landing is the pull request merged:
the feature-log entries appended, the manifest rows stamped, the journal brought up to date
(WK11). [ground-rules.closeout.md](./ground-rules.closeout.md) is the checklist for both.

## The lean posture

`.conf`'s `ORCH_BUDGET` says how much delegation and ceremony a wave affords. Under `full`, the
reference practice, each job goes to a delegated agent, a review loop runs before the pull
request, and the close-out files its appendices. Under `lean` (AG12):

- the orchestrator works inline, and delegates only as a context firewall: when a job's reading
  would outgrow the orchestrator's own context;
- delegated jobs run in the background, and the orchestrator keeps working while they do rather
  than waiting idle;
- the ceremony scales down to one short record: the pull-request body, the journal entry and the
  drafted feature-log entries, with no appendices.

Pick `lean` where idle time is expensive, as when a session's prompt cache expires quickly.

## The keep-alive

Where a session's prompt cache expires sooner than the gaps between its turns (a long wait on a
build, a walk that takes an afternoon), a cold cache makes the next turn re-read the whole
context at full cost. The fallback is a behaviour, not a feature: the orchestrator keeps the
session warm with a cheap periodic action, such as a status check of the job it is waiting on,
for as long as the wait lasts, and lets it go cold only when the wave is parked (AG13).
