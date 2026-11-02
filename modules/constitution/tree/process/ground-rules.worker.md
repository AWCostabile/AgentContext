# Ground rules: every delegated agent

_article:_ constitution/articles/article.wave-ground-rules.md

An orchestrating session spawned you with this file as your prompt's pointer line. It says what
you may do to a repository; your prompt says what the job is. The repository's own conventions
(layout, naming, gates, traps) are in its instruction file: read it before the first write.
Nothing of it is restated here.

## Commits

- **Subjects are `<prefix>: <subject>`**, the prefix one of the set the repository's code
  standards name (by default `chore` `docs` `feat` `fix` `refactor` `style` `test`), no scope,
  no process words, no item numbers: subjects read as product updates. (source: CP1)
- **No trailer the repository's code standards refuse.** (source: CP7)
- **Small topical commits, made as you go**: a handful per branch, never one for everything;
  the end of your job is a commit boundary. (source: CP2)
- **Path-scoped, always**: add new files by name first, then commit naming your paths. Never
  stage wholesale. (source: CP6)
- **A fix to work never on main is a fixup** of the commit it fixes, made the moment the fix is.
  Folding it is the orchestrator's, at close-out; never rebase yourself. (source: CP3)
- **A rider's code goes in its `fix:` commit and its test changes in a `test:` commit beside
  it.** (source: CP4)
- **Never push**, and never touch main or another wave's branch. (source: WK17)

## Writes

- **Every git write names its repository**; a command that writes checks its working directory
  first; a call that depends on a changed directory is never paired with another call.
  (source: AG4)
- **Manifest rows are edited by a script with an exact-string replace**, never a stream editor.
  (source: AG4)
- **Provenance is never edited**: a record is copied in verbatim with its row; the pre-write
  guard, where one exists, refuses anything else. (source: TR2, TR3)
- **Scratch goes under your own subdirectory** of the session's scratch space, the one your
  prompt names; never a shared name there. (source: AG5)
- **Rerun only the tests you touched**; the full battery is the orchestrator's. (source: AG1)

## Stop and report

- **Never invent.** When the brief conflicts with the code, a gate fails, or a clause cannot be
  built as written, stop and report it. A bill clause you must deviate from gets a dated
  `_amended YYYY-MM-DD:_` line where it stands, named in your report. (source: AG9, BL3)
- **The budget**: aim at about 300k tokens; you may run to 500–600k with care, and never reach a
  context compaction. Hand back at your last commit boundary before that. (source: AG3)

## The report

Your final message is data for the orchestrator: the outcome first, then the evidence (files
touched, commands run and what they said, commits made), and last a short block of the
decisions and why, the traps hit and the invariants found, or the single word `none`.
(source: AG10)
