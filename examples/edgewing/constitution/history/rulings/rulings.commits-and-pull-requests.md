# Seed rulings: commits and pull requests

_status:_ adopted 2026-11-04

The shape of the history a wave leaves behind: commit subjects that read as product updates,
fixes folded before they reach the main line, the close-out check that enforces it, and the body
every pull request carries. The [wave ground rules](../../articles/article.wave-ground-rules.md),
the [tiers](../../articles/article.tiers.md) and each product's code standards rest on these.

- **CP1.** A commit subject is `<prefix>: <subject>`, the prefix one of a fixed set (by default
  `chore` `docs` `feat` `fix` `refactor` `style` `test`) with no scope, and it reads as a product
  update: no process vocabulary, no item or plan numbers.
- **CP2.** Commits are small and topical and made as the work is done; a branch carries a handful,
  never one commit for everything.
- **CP3.** A fix to work that was never on the main line is made as a fixup of the commit it fixes
  and folded before the close-out check; the private repository's history is never folded.
- **CP4.** A rider's code and its test changes go in separate commits, so a fold never meets a file
  that did not exist at its target.
- **CP5.** Commits made in answer to a review describe the fix, never the review round.
- **CP6.** Every commit is path-scoped: new files are added by name, the commit names its paths,
  and nothing is staged wholesale.
- **CP7.** A close-out check scans every commit on the branch: a script detects and an agent
  inspects only its suspect listing. A subject outside the prefix set, or a trailer the
  repository's code standards refuse, is a hard hit; process vocabulary and fold candidates are
  suspect hits, and a dismissal keys on the commit subject or its hash so it survives a fold.
- **CP8.** Every pull request has a body, filed before the pull request is raised; an
  operational one may be short, but it exists.
- **CP9.** A pull-request body is an impersonal record of what the change achieves: no personal
  names or first person, no references to plans or rulings, no vocabulary of how the work was
  scheduled.
- **CP10.** A pull-request body's first line under its H1 names the branch it describes, so it is
  found from the branch name before it lands.
- **CP11.** A pull-request body is amended in place while its pull request is open, and freezes
  when the landing stamps it.
- **CP13.** The commit that enacts a bill names, in its body, the pull request that carries the
  enactment.
