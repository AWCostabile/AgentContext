# Hygiene: how the tree checks itself

_source:_ history/rulings/rulings.hygiene-and-gates.md HG1–HG13; history/rulings/rulings.shared-and-private.md SP8; history/rulings/rulings.bills-and-law.md BL13, BL15; history/rulings/rulings.commits-and-pull-requests.md CP7
_reviewed:_ 2026-11-02

The tree lints itself in two layers (HG1). An **invariant** is a structural fact that is either
true or broken, and breaking one fails the tree. A **smell** is a heuristic that something is
probably wrong, which a person judges. [HYGIENE.md](../../common/HYGIENE.md) is the single reference
for both: every check's id, what it reports and how to rectify it (HG2). The scripts are
report-only: nothing edits the tree but a person or an agent following a rectification. This
article holds the reasoning; the catalogue is HYGIENE's alone.

## Verdicts

- **FAIL** is for what the grammar or the law forbids outright. The linter's exit code is the
  number of failures, and zero is the definition of structurally sound (HG3).
- **WARN** is advisory maintenance: a leaf or a table past its size, near-duplicate tags.
- **INFO** reports what is legal but worth knowing, such as a private citation inside verbatim
  provenance, which resolves only on a machine holding the private tree.
- The fast mode runs every FAIL check and skips the advisory ones: a guard needs only the
  verdict, and must be quick enough to run on every write.
- The advisory checks skip a generated tier when the module that adds it says so, because nobody
  maintains a generated leaf by hand and a warning that fires forever trains readers to ignore
  warnings. Every FAIL check still scans it (HG4).

## When they run

- **On every write** into the tree, where the harness can run a command after a write, the
  fast linter runs and hands any failure straight back to the session (HG5).
- **At session start**, the fast verdict is part of what the session reads first.
- **After several filings and before a branch merges**, the full linter, then the smells, then
  the repairs. HYGIENE's "Review cadence" table is the schedule.

## Adding a check

A smell is added only with law to cite: a ruling, an article or a design leaf (HG6). It lands
only once everything complies, so it never fires on the state it was written to end, and it is
added the way HYGIENE's "Adding a smell" says. A smell that stands after judgement is recorded as
standing, with its reason, never silenced.

## The caps

A file every session loads is a cost every session pays, so it is capped by a number the linter
reads, not by a guideline (HG7): a guideline is ignored the first time a section is appended,
and a number is not. The defaults:

- a repository's root instruction file: 300 lines;
- each ground-rules file: its measured length rounded up to the next ten, plus twenty lines of
  headroom, raised only by a bill ([the wave ground rules](./article.wave-ground-rules.md)).

The core ships no cap check. An instance that adopts the caps adds one smell that reads a table
of files and caps, a missing file treated as absent and never as a failure.

## Instruction files

A repository's instruction file is a short instruction over the tree (HG9): what the repository
is; where its law lives, named by path; the conventions and traps that bite while working there;
the pins a contributor bumps and the gates a change clears, each stated once; and a table from
subsystem to design leaf. It carries no history of the work: no record of what landed when, no
plan or ruling trails. A file over its cap is distilled, never cut (HG10): every contract in it
is kept as instruction, promoted to a named design leaf, or dropped with a reason, in a table
that accounts for every line. A contract that existed only in the instruction file has no ruling
behind it, so the owner ratifies it, leaf by leaf of its destination, before a design leaf rests
on it (HG11).

## The process-vocabulary exemption

The smell S18 reports the vocabulary of how work is run in authored leaves under `public/`. It
does not reach verbatim records, the root instruction documents, or `constitution/` (SP8). The
exemption is from the smell, not from the posture: an article describes what the process is, and
never how a particular change was delivered.

## The chain of law

Every operative file cites its article, and every article cites its rulings (BL13;
[the constitution](./article.constitution.md)). The core linter checks neither link and does not
walk `constitution/`; an instance proves the chain by adding a check, or by a reviewing agent at
each enactment. An operative rule edited with no bill behind it is the quiet amendment (BL15):
a smell whose fix is a bill or a revert, never a matching edit to the article.

## The tools beside the linters

Some things the linters cannot see: the commits a branch carries, the records a landing owes,
the state a session wakes into. Where an instance builds tools for them, they are filed under
`public/scratch-tools/` with a usage leaf each, and listed in the scripts index (HG12):

- **The close-out check** runs over a branch before its pull request is raised. A script
  detects; an agent reads only the suspect listing it prints, never the whole log; hard hits
  fail the run; a dismissal keys on the commit subject or hash so it survives a fold (CP7).
- **The landing stamp** fills each manifest row's "Landed as" from the merged change's heading:
  idempotent, never overwriting a different value, keeping each file's line endings (HG13). It
  is the one sanctioned write into a provenance index, and it touches the cell, never the record.
- **The orientation** a session reads at start shows each repository's newest landing beside its
  branch, so a status page that still calls a merged branch unpushed contradicts itself on
  screen; and it warns when the session's temporary directory grows past a threshold, the first
  guard against a runaway writer (HG13).
- **Proof is printed** by the tool that ran it and copied from its output, never reconstructed
  from a log after the fact (HG12).
