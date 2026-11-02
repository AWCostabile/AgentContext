# Modules

Optional additions, adopted or deleted per instance. The core never depends on one, and no module names an agent harness.

| Module | What it adds |
| ------ | ------------ |
| [Constitution](./constitution/README.md) | the tree's law about itself: seed rulings, articles that cite them, a place for bills, and the process half (a kickoff guide, ground rules for each reader of an orchestrated piece of work, a code-standards template). Adopt it by copying `constitution/tree/` to an instance's `constitution/` and pruning it; delete it if the core's `rules/` are enough. |
| [Codebase](./codebase/README.md) | a generated code map of a product's repository: one command writes `codebase/` under the product's branch (its source areas, the surfaces it exposes, and one symbols leaf per area, every location a `path:line`), with a TypeScript and a Go extractor, a `--check` drift gate and a fixture check. Adopt it by copying `codebase/` to an instance's `modules/codebase/`; Python 3.10+ is all it needs. |
