# Ground rules: the orchestrating session at the close

_article:_ constitution/articles/article.wave-ground-rules.md, constitution/articles/article.rigour.md, constitution/articles/article.tiers.md

Read this when the wave's proof run is done. The orchestrator's ground rules governed until now;
the worker's still govern every delegated agent, the riders included.

## Two moments

A wave has two moments, each with its own filings: **close-out**, the branch finished and the
pull request not yet raised; and **the landing**, the pull request merged. Neither alone is the
other. (source: WK11)

## The walkthrough

- **Nothing the wave produced enters an immutable tier** (the pull-request body, the close-out
  record, the review report, the bill's enactment) until the owner has walked the build. The
  kickoff's `Walkthrough:` line says when, or why not. (source: WK9)
- **It sits after the proof run and before the close-out check and the final review round**, so
  the riders it spawns are checked and reviewed with the rest. (source: WK9)
- **When the walk ends, state the running total of its riders**; name the growth once, in one
  sentence, and let the owner decide. (source: WK10)
- **The owner enacts the bill**: at the walkthrough of a build wave, or at the pull-request
  review of a documentation-only one; one action, one commit. List every dated amendment the
  build made to the bill. (source: BL5, BL6, BL3)

## The fold, then the check

- **Fold first**, once no agent is still committing to the branch: every fixup folds into its
  target, non-interactively. Folding rewrites hashes, so it runs before the check. The private
  repository is never folded. (source: CP3)
- **The close-out check comes next**, over every repository the wave committed to. Fix every hard
  hit and rerun until none remain; an agent triages the suspect listing alone, never the log,
  fixing a real hit and dismissing a false one with its reason. (source: CP7)

## The review loop

Where the product has adopted it, a reviewing agent reviews the branch after the check and
before the owner raises the pull request. (source: HG19)

- Answer every **blocking** finding: accepted, with a rider, or declined, with a one-line reason.
  (source: HG20)
- A later round reviews only the rider's diff and the findings still open. (source: HG20)
- Stop when a round returns nothing blocking, or at `ORCH_REVIEW_ROUNDS` (default 2); at the cap,
  file the open findings beside the pull-request body for the owner. (source: HG20)
- **Consider** findings go to the owner and never start a rider. (source: HG20)
- Rider commits describe the fix, never the review round. (source: CP5)

## Close-out filings

| Filing | Where it lands |
| --- | --- |
| Pull-request body: what the change achieves, its proof, its deferrals; first line names the branch | `private/<catalog>/<Repository>/prs/<YYYY-MM>/`, the repository the pull request is raised against, under the plan's month; filed before the pull request is raised (source: SP15, CP8, CP9, CP10) |
| Feature-log entries, one per area touched | drafted inside the journal entry; appended at the landing (source: SP10, WK11) |
| Close-out check verdict and review report | appendices in the product's mirror, `closeout.` and `review.` by form (source: TR17) |
| Journal: the dated entry, `latest.md`, the epic row `[~]` | `private/journal/` (source: WK11) |
| The private repository, committed as filed, pushed if it has a remote | `private/`, trunk only, never forced (source: SP14) |
| The branch, unpushed | the product repository; the owner raises the pull request (source: WK17) |

Under `ORCH_BUDGET=lean` the body, the journal entry and the drafted feature-log entries are the
whole of it: no appendices. (source: DA10)

## The landing

When the pull request has merged:

1. The drafted feature-log entries appended to the product's `features/`, dated by the merge.
   (source: WK11)
2. "Landed as" stamped on every manifest row the wave filed, in every tree, by one idempotent
   command where the instance has one. (source: HG13)
3. The epic row `[x]` with its pull request and commit; the retrospective when the row closes
   an epic. (source: WK12)
4. `latest.md` rewritten, and the private repository tagged `landed/<date>-<slug>`.
   (source: SP14)
5. Every generated tier the change moved regenerated, now and not before. (source: TR11)
