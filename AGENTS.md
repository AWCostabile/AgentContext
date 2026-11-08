# AgentContext

Orientation for an agent working ON this template repository, not in a deployed instance. It holds a vendor-neutral, MIT-licensed knowledge-tree method: the method and an empty structure, never a filled instance.

- `README.md`: the method, for a reader who has never seen it.
- `blueprint/`: the skeleton; it maps onto a deployed instance's root. `blueprint/AGENTS.md` is the instruction an instance receives. Do not duplicate it here.
- `adapters/`: one directory per agent harness. `modules/`: optional additions. `examples/`: a filled tree.
- `scripts/`: the core scripts an instance receives (the linter, the smells, search, the review agenda). This repository runs them over its own skeleton: `bash scripts/cure.sh --root blueprint` and `bash scripts/smell.sh --root blueprint` must stay clean; an instance receives them as `common/scripts/`, and `blueprint/common/scripts/.index.md` is its index of them.
- `MOVES` and `migrations/`: never laid into an instance. A change that moves or renames a core path adds its `<old> <new>` pair to `MOVES` (pairs are never removed, so a skipped release still moves) and says what is left to the user in the guide of the release it leaves, `migrations/<version>.md`, written once at that release's cut; `--update` applies the one and names the other.
- `tests/`: never laid into an instance. `tests/fixture/` is a small deployed-shaped tree carrying one deliberate defect per check id beside sound branches, and `tests/check.sh` asserts that every C and S id fires on its planted file and nowhere else and that `find.sh` and `review.sh` answer as expected: a change to a check lands with its planted defect and its assertion. `tests/tools/deploy-smoke.sh` is the deployer's gate and runs the check as a section.

**Core or module.** A thing is core when the linter has to know about it, when every instance needs it to keep the two trees honest, or when it is one more mode of a script an instance already receives. A thing is a module when it carries a dependency, a tier of its own, or an opinion about process that a reader-only instance or a team without agents can decline. The linters have no extension seam: a check or a smell is core, or the seam comes first.

**The standing rule:** nothing in this repository may name a real organisation, its products or its people, and no file here knows of any: examples are fictional and generic, and `scripts/retired-terms.txt` ships empty.

**Current law, stated plainly.** The blueprint, the modules and the adapters say what a rule IS, never what it used to be: no amendment lines, no "formerly", no history of a rule's change. An instance deployed tomorrow has no past to be told about; this repository's own commits and change log carry that history.

Do not add a `.gitignore` directly under `blueprint/`: ignoring `private/` there would make this repository ignore `blueprint/private/`. An instance's own `.gitignore` is written when it is deployed.

Commit subjects use exactly one of `chore:` `docs:` `feat:` `fix:` `refactor:` `style:` `test:`, with no scope; each becomes one bullet of `CHANGE_LOG.md`, which the post-merge workflow generates from a pull request's title and its commit subjects. Never edit that file by hand.
