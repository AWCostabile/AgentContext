# Modules

Optional additions, adopted or deleted per instance. The core never depends on one, and no module names an agent harness.

| Module | What it adds |
| ------ | ------------ |
| [Constitution](./constitution/README.md) | the tree's law about itself: seed rulings, articles that cite them, a place for bills, and the process half (a kickoff guide, ground rules for each reader of an orchestrated piece of work, a code-standards template). Adopt it by copying `constitution/tree/` to an instance's `constitution/` and pruning it; delete it if the core's `rules/` are enough. |
| [Codebase](./codebase/README.md) | a generated code map of a product's repository: one command writes `codebase/` under the product's branch (its source areas, the surfaces it exposes, and one symbols leaf per area, every location a `path:line`), with a TypeScript and a Go extractor, a `--check` drift gate and a fixture check. Adopt it by copying `codebase/` to an instance's `modules/codebase/`; Python 3.10+ is all it needs. |
| [Change log](./change-log/README.md) | a GitHub Actions workflow that rewrites every merged pull request into one squash commit, a bubble merge and a `CHANGE_LOG.md` entry built from the pull request's title and its commit subjects. Adopt it by copying `post-merge.yml` to a repository's `.github/workflows/` and adding one secret; this repository runs the same copy on itself. |
| [Graphify](./graphify/README.md) | one Graphify knowledge graph per repository, kept as a generated `graphs/` tier at the instance root: `home` links a repository's `graphify-out` into the tree (a junction on Windows, a symlink elsewhere) and seeds its ignore files, `scan` rebuilds each graph offline and commits one snapshot, `check` reports links, pin, staleness and drift. Adopt it by copying `graphify/` to an instance's `modules/graphify/` and naming the repositories in `.conf`; bash and the `graphifyy` tool are all it needs. |
