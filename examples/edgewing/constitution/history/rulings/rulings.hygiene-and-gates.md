# Seed rulings: hygiene and gates

_status:_ adopted 2026-11-04

How the tree checks itself, how the files every session loads stay small, the tools that check
what the linters cannot see, and how a product's code is held to a written standard with an
adversarial review before its pull request. The articles on
[hygiene](../../articles/article.hygiene.md) and [rigour](../../articles/article.rigour.md)
rest on these.

- **HG1.** The tree checks itself in two layers: invariants, true or broken, which fail the tree;
  and smells, heuristics that something is probably wrong, which a person judges.
- **HG2.** One reference document holds every check's id, signal and rectification, and the
  scripts that run the checks are report-only.
- **HG3.** A check reports FAIL, WARN or INFO; the linter's exit code is its failure count, and
  its fast mode runs every FAIL check while skipping the advisory ones.
- **HG4.** Advisory checks skip the generated tiers, which nobody maintains by hand; every FAIL
  check scans them.
- **HG5.** The fast linter runs on every write where the harness allows it and at session start;
  the full linter and the smells run after several filings and before a branch merges.
- **HG6.** A smell is added only with law to cite and lands only once everything complies with it,
  so it never fires on the state it was written to end; a smell that stands after judgement is
  recorded with its reason, never silenced.
- **HG7.** A file every session loads is capped by a number the linter reads, never by a
  guideline; a repository's instruction file defaults to 300 lines.
- **HG8.** A ground-rules file's cap is its measured length rounded up to the next ten, plus twenty
  lines of headroom (a default), and is raised only by a bill.
- **HG9.** A repository's instruction file is a short instruction over the tree: what the
  repository is, where its law lives, the conventions that bite, its pins and gates, and a table
  from subsystem to design leaf; it carries no history of the work.
- **HG10.** An instruction file over its cap is distilled, never cut: every contract in it is kept,
  promoted to a named design leaf, or dropped with a reason, in a table that accounts for every
  line.
- **HG11.** A contract that exists only in an instruction file is ratified by the owner, leaf by
  leaf of its destination, before a design leaf may rest on it.
- **HG12.** Proof is printed by the tool that ran it and copied from there, never reconstructed
  from a log; every maintenance script is listed in the scripts index.
- **HG13.** A landing stamps its manifest rows with one command that is idempotent, never
  overwrites a different value and keeps each file's line endings; a session's orientation shows
  each repository's newest landing, and warns when its temporary directory grows past a
  threshold.
- **HG14.** A product's code standard is a rule catalog in the shared tree, as current law; what a
  sweep or review found is a private findings ledger whose rows are open, fixed, cleared or
  declined.
- **HG15.** A catalog rule carries an id, the rule in one sentence, its source, its detection, the
  shapes its false positives take, the form a dismissal takes, and its tier: hard (a script
  alone decides), suspect (a script flags and an agent confirms or clears; the default) or
  judgement (only a reading agent finds it).
- **HG16.** An exemption lives in the code beside the line it excuses, with its reason; an
  exemption without a reason is itself a finding.
- **HG17.** A product gets one full baseline sweep before its linter is built: reviewers over
  shards grouped by subsystem, every finding checked by an agent told to disprove it, survivors
  clustered by root cause; it repeats only when a retrospective finds the catalog missing too
  much.
- **HG18.** A linter is built from the rules the sweep showed recur, and keeps a baseline of known
  debt: a new violation blocks, and the baseline burns down.
- **HG19.** Before a pull request is raised, a reviewing agent asks of every change whether it is
  justified, whether it could reuse what exists, and whether it is the second copy of something
  that should now be shared; a reuse claim cites `path:line`, findings are graded blocking or
  consider and capped at five (a default), and style a formatter owns is never commented on.
- **HG20.** The orchestrator answers every blocking finding, accepted with a rider or declined with
  a reason; a later round reviews only the rider's diff and the findings still open; the loop
  stops when a round returns nothing blocking or at its round cap, two by default; consider
  findings go to the owner and never start a rider; the owner is the final arbiter.
