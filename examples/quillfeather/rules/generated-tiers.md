# Generated tiers

_applies to:_ any branch a generator writes, such as a code map a module regenerates from a
repository

The core ships no generator. A module that adds one lays down a tier under a product branch
and obeys this contract, so that readers can trust the tier and nobody maintains it by hand.

- Only the branch's own `.index.md` prose (above its Contents table), its `.tags` and its
  `.agent` are authored. Everything else is generator output.
- Never hand-edit a generated file. Regenerate it with the command the branch's `.agent` names.
  If a generated file is wrong, fix the generator or the source it was extracted from, regenerate,
  and say so in the report.
- Regenerate a tier when the change that moved its source lands, not before: a tier that
  describes an unmerged branch misleads every reader on the main one.
- The linter's advisory checks (leaf length, table width) skip a generated tier when the
  module says so; the structural checks never do.
- Commit only what the generator says is data; caches and rendered views are git-ignored.
