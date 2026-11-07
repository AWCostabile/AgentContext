# The change-log module

A GitHub Actions workflow that turns every merged pull request into one squash commit, a bubble
merge and a change-log entry, so a repository's `main` reads as a list of landed changes and its
`CHANGE_LOG.md` is generated, never written by hand. This repository runs the same workflow on
itself; `.github/workflows/post-merge.yml` here is a byte-for-byte copy of the file in this
directory, and the deploy smoke proves they match.

## What it does

When a pull request into `main` is merged, the workflow:

1. reads the merge GitHub just made and undoes it on `main`;
2. squashes the branch into one commit titled `<pull request title> (#<number>)`;
3. merges that commit back with `--no-ff` as `merge: pull request #<number>`, so the graph shows
   one bubble per pull request;
4. prepends an entry to `CHANGE_LOG.md`, `## <title> [ _<time, UTC>_ ]` followed by one bullet
   per commit subject of the branch, and commits it as `docs: update change log for pull request
   #<number>`;
5. force-pushes `main`, replaces the remote branch with its squashed form, and deletes it.

The merge and change-log commits are authored as the pull request's author through the account's
noreply address, so GitHub attributes them like an ordinary squash merge.

## What it asks of a repository

- **Commit subjects are the change-log bullets.** Each takes one of the seven prefixes (`chore:`
  `docs:` `feat:` `fix:` `refactor:` `style:` `test:`), no scope, and reads as a product update;
  a branch is a handful of such commits, never one mega-commit. The pull request's title becomes
  the heading, so it is human-readable (`Feature | Deployer`).
- **One secret, `ACTION_TOKEN`:** a token with write access to the repository's contents (a
  fine-grained personal access token scoped to the repository, Contents: read and write). The
  default `GITHUB_TOKEN` may not force-push the default branch.
- **Repository settings:** keep "Allow merge commits" on, since the workflow reads the two parents
  of the merge GitHub creates; leave "Automatically delete head branches" off, since the workflow
  deletes the branch itself; if `main` is protected, allow force pushes for the token's account.
- **After a merge, every local clone re-syncs** with `git fetch` and `git reset --hard origin/main`,
  never a pull or merge of a stale `main`: the workflow rewrote it.
- **Stacked branches rebase with `--onto`.** A branch stacked on another waits for its base to
  merge, then moves with `git rebase --onto origin/main <base's last commit> <branch>`; keeping a
  one-commit squash of the base below each stacked branch makes that mechanical.

## Adopting it

1. Copy `post-merge.yml` from this directory to `<repository>/.github/workflows/post-merge.yml`
   and commit it on `main` (a pull request merged before the file is on `main` is not rewritten).
2. Add the `ACTION_TOKEN` secret under the repository's settings, Secrets and variables, Actions.
3. Check the three settings above.
4. Merge the next pull request and read `CHANGE_LOG.md` on `main`.

Seeding a change log for pull requests merged before adoption is a one-off rewrite of `main` by
the same recipe, best done once and force-pushed with `--force-with-lease`.

## Where it sits in the method

The knowledge tree never cites a plan or a branch from a public leaf; the one citable trace of
delivery is a merged pull request or its change-log heading. This workflow is what makes that
heading exist. The `common/rules/feature-log.md` document and the constitution module's code-standards
template both assume it or something like it.
