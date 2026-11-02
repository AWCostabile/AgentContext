# AgentContext

Orientation for an agent working ON this template repository, not in a deployed instance. It holds a vendor-neutral, MIT-licensed knowledge-tree method: the method and an empty structure, never a filled instance.

- `README.md`: the method, for a reader who has never seen it.
- `template/`: the skeleton; it maps onto a deployed instance's root. `template/AGENTS.md` is the instruction an instance receives. Do not duplicate it here.
- `adapters/`: one directory per agent harness. `modules/`: optional additions. `examples/`: a filled tree.
- `scripts/`: the core scripts an instance receives (the linter, the smells, search). This repository runs them over its own skeleton: `bash scripts/cure.sh --root template` and `bash scripts/smell.sh --root template` must stay clean; `template/scripts/.index.md` is the instance's index of them.

**Core or module.** A thing is core when the linter has to know about it, when every instance needs it to keep the two trees honest, or when it is one more mode of a script an instance already receives. A thing is a module when it carries a dependency, a tier of its own, or an opinion about process that a reader-only instance or a team without agents can decline. The linters have no extension seam: a check or a smell is core, or the seam comes first.

**The standing rule:** nothing in this repository may name a real organisation, its products or its people, and no file here knows of any: examples are fictional and generic, and `scripts/retired-terms.txt` ships empty.

Do not add a `.gitignore` directly under `template/`: ignoring `private/` there would make this repository ignore `template/private/`. An instance's own `.gitignore` is written when it is deployed.

Commit subjects use exactly one of `chore:` `docs:` `feat:` `fix:` `refactor:` `style:` `test:`, with no scope; each becomes one bullet of `CHANGE_LOG.md`, which the post-merge workflow generates from a pull request's title and its commit subjects. Never edit that file by hand.
