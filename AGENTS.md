# AgentContext

Orientation for an agent working ON this template repository, not in a deployed instance. It holds
a vendor-neutral, MIT-licensed knowledge-tree method: the method and an empty structure, never a
filled instance.

- `README.md`: the method, for a reader who has never seen it.
- `template/`: the skeleton; it maps onto a deployed instance's root. `template/AGENTS.md` is the
  instruction an instance receives. Do not duplicate it here.
- `adapters/`: one directory per agent harness. `modules/`: optional additions. `examples/`: a
  filled tree.
- `scripts/`: the core scripts an instance receives (the linter, the smells, search). This
  repository runs them over its own skeleton: `bash scripts/cure.sh --root template` and
  `bash scripts/smell.sh --root template` must stay clean; `template/scripts/.index.md` is the
  instance's index of them.

**The standing rule:** nothing in this repository may name a real organisation, its products or its
people, and no file here knows of any: examples are fictional and generic, and
`scripts/retired-terms.txt` ships empty.

Do not add a `.gitignore` directly under `template/`: ignoring `private/` there would make this
repository ignore `template/private/`. An instance's own `.gitignore` is written when it is deployed.

Commit subjects use exactly one of `chore:` `docs:` `feat:` `fix:` `refactor:` `style:` `test:`, with
no scope. There is no generated change log.
