# CLOSEOUT.md — the orchestrator's close-out, as this harness runs it

Read when the proof run is done. The neutral rules are the constitution module's
`constitution/process/ground-rules.closeout.md`: the walkthrough, the fold, the close-out
check, the review loop, the filings and the landing. Read it first; nothing in it is restated
here. This file says only what the Claude Code harness adds. `.claude/process/WORKER.md` still governs every
subagent, the riders included.

## The fold, from the Bash tool

- **The editor cannot open here**, so the autosquash runs with a no-op sequence editor, once
  no agent is still committing to the branch:
  `GIT_SEQUENCE_EDITOR=true git -C <repo> rebase -i --autosquash main`.
  (source: constitution/history/rulings/rulings.commits-and-pull-requests.md)
- **A plain `fix:` commit that should fold** moves beneath its target by a sequence-editor
  script instead of `true`: a small script in the session scratchpad that rewrites the todo
  file, its path given to `GIT_SEQUENCE_EDITOR` in the form git can execute on this machine.
- The fold rewrites hashes, so it runs before the close-out check. The private repository's
  history is never folded.

## The review loop

- **The `skeptic` profile reviews the branch** through the Agent tool, read-only, at most five
  findings each citing `path:line`; hand it the repository, the range, the round and what the
  change answers to. Answer every blocking finding in its report before filing it.
  (source: constitution/history/rulings/rulings.hygiene-and-gates.md)
- **A rider** for an accepted finding is an ordinary subagent job, routed like any other.
- Under `ORCH_BUDGET=lean`, the loop and the records shrink as the neutral rules' lean
  posture says.

## Filing the records

- **Write a record in the scratchpad, then add it**: `cp` it into its immutable tier and add
  its manifest row in the same action. The `guard-tiers` hook refuses a Write there.
  (source: constitution/history/rulings/rulings.tiers-and-records.md)
- **A PR body is the one exception**: while its `_landed as:_` line reads `—`, the hook lets it
  be amended in place, so it stays true to its branch while the pull request is open.
- **Use `/file`** (or the `filer` subagent) for every leaf, so its Contents row, tags and the
  private repository's commit come with it.
- **Use `/retro`** when the landing closes an epic's last row; it hands the window to the
  `historian` subagent. (source: constitution/history/rulings/rulings.waves-and-close-out.md)

## Releasing the branch

- **A worktree releases its branch** when its last agent is done with it:
  `git -C <worktree> checkout --detach`, so the owner can check the branch out to walk it,
  push it and raise its pull request. Never under an agent still committing there.
  (source: constitution/history/rulings/rulings.waves-and-close-out.md)
- **Nothing is pushed by this session.** The owner raises the pull request.

## The end of the session

The session's own final message ends with `## Insights`: the decisions and why, the gotchas
hit, the invariants found. (source: constitution/history/rulings/rulings.agents-and-budgets.md)
