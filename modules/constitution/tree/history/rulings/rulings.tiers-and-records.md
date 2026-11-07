# Seed rulings: tiers and records

_status:_ seed — adopt, amend or delete

Who may write in a branch and how: the provenance tiers that are added once and never edited,
the current law that is edited as the truth moves, the generated tiers that only a generator
writes, and how the records of the work are numbered and named. The articles on
[the tiers](../../articles/article.tiers.md) and
[generated tiers](../../articles/article.generated-tiers.md) rest on these.

- **TR1.** A branch's tier is keyed by its path, in every tree, and is one of three kinds:
  provenance, added verbatim and never edited; current law, edited as the truth moves; or
  generated, written by its generator alone.
- **TR2.** A provenance record is added verbatim, with its manifest row in the same action, and
  its body is never edited afterwards; only the manifest row may be corrected.
- **TR3.** Where the agent harness can refuse a write before it happens, a guard refuses writes
  under the immutable tiers, with one named override used only for a deliberate exception that
  the commit using it states; where no guard exists, the linter and review catch the violation.
- **TR4.** A plan is editable until its manifest row's "Landed as" is filled and frozen after; a
  kickoff prompt is rewritten in place until an agent has run from it and frozen after, a later
  prompt going below it; a retrospective is never edited, and a later one corrects it.
- **TR5.** Corrections go forward: landed content that is wrong is corrected in current law,
  citing the ruling that corrects it, and never in the record itself.
- **TR6.** A decision found inside a private record is lifted verbatim into a shared rulings leaf
  and cited from there; the private record is never cited.
- **TR7.** A current-law leaf holds one subject and carries, directly under its H1, its source
  (the rulings leaf and ids it rests on, superseded ones included) and the date it was last
  reviewed.
- **TR8.** When current law contradicts a provenance record, current law wins and says what it
  supersedes and why; a silent divergence is a defect.
- **TR9.** A generated tier has one writer, a named generator, and only the branch's index prose,
  tags and standing orders are authored there; a generated file is never edited by hand, and
  when it is wrong the generator or its source is fixed and the tier regenerated.
- **TR10.** A generated tier is honest: whatever the generator could not parse is listed, a
  location is plain `path:line` text with no machine-specific path, no secret value is ever
  emitted, and its drift check ignores its own provenance line.
- **TR11.** A generated tier regenerates when the change that moved its source lands, never for
  an unmerged branch; its drift check is the alarm between landings.
- **TR12.** Generator tooling runs offline, is pinned to a named version and produces the same
  output from the same source; it never reads a language it cannot parse correctly, listing such
  a source as skipped instead.
- **TR13.** Generated output about a product lives in the tree rather than in the product's
  repository, and two generated tiers over one codebase never answer the same question.
- **TR14.** Plans are numbered within their month as `<YYYY-MM>-<n>`, one counter across every
  product in filing order, and every record of a plan files under the plan's month; work with
  no plan takes the next counter of its month, as a plan of one row.
- **TR15.** An operational record that belongs to a plan (its bill, its enactment, its landing)
  reuses the plan's counter with a role suffix; one that belongs to no plan takes the next
  counter.
- **TR16.** Names change forward only: records filed before a naming form keep their names.
- **TR17.** An appendix is named by its form first, then the plan's number and its slug, and
  never carries the prefix of the pull-request body it accompanies.
