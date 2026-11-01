# Agent instructions

This repository is a knowledge tree: what this organisation knows, in a shape agents and new hires
align to from the first prompt, at low token cost. `public/` is what is true and is committed here.
`private/` is how the work was run on one machine: a nested git repository this one ignores.

## How to read

1. Read `.conf` first. It says how to speak to this user and which catalogs and private branches
   exist. Its keys are explained in `.conf.example`.
2. If `private/journal/latest.md` exists, read it before anything else: what is in flux, what last
   landed, what is next. If it is absent, this machine holds no development-cycle records. Say so
   rather than guessing at the state of the work.
3. Descend `.index.md` files from the table below. Never glob-crawl the tree.
4. Resolve tags with `bash scripts/find.sh <tag...>`, then expand and descend.
5. If a branch has a `.agent`, read it before reading from or writing to that branch.

**To learn the state of a product, start at its feature log**: `public/<catalog>/<Product>/features/`,
one leaf per area, each opening with a **State today** paragraph. Follow its links into `design/` and
`history/`.

| Index | Purpose |
| ----- | ------- |
| [Public](./public/.index.md) | what is true: per-product rulings, design, feature log, research; shared tools; misc |
| [Private — the development cycle on this machine](./private/.index.md) | only where this machine has one: plans, kickoffs, PR bodies, retros, the journal |
| [Templates](./templates/.index.md) | copy these to make a new branch, leaf or product |
| [Scripts](./scripts/.index.md) | `find.sh` search; `cure.sh` the linter; `smell.sh` the smells |
| [Rules](./rules/.index.md) | the grammar and tier rules as plain documents |

## Where to write

**Route by KIND, not by topic.**

- Ruling, design, feature-log entry, research: `public/`.
- Plan, kickoff, PR body, PR appendix, retro, epic, ledger, journal entry: `private/`.

Write in the deepest matching branch. **Leaf + Contents row + tags is one action**; in the private
tree it ends with one commit. Copy new branches from `templates/branch`, and new products from
`templates/product`, replacing every `{{ }}`.

## The laws

- **Links run one way.** Private leaves link into `public/` freely. Nothing under `public/` links to,
  or cites the path of, a private record.
- **The one crossing.** What a change achieved crosses into the feature log, when its pull request
  merges. How it was run never does.
- **`public/` reflects what IS.** It carries no process vocabulary: no plan, wave, phase, sprint,
  kickoff, epic or retro. The one citable trace of delivery is a merged pull request of the product's
  repository.
- **Immutable tiers, by path:** `public/**/history/`, and in the private tree `plans/`, `kickoffs/`,
  `prs/`, `appendices/` and `journal/retros/`. Records are added verbatim with a manifest row. A plan
  is editable until its "Landed as" is filled; a kickoff leaf is append-only.
- **Corrections go forward.** Landed content that is wrong is corrected in current law, never in the
  record.
- **The design tier is current law.** `design/` has one subject per leaf, at most about 120 lines,
  and names the ruling it rests on. When it contradicts `history/`, the leaf wins and says what it
  supersedes and why.
- **Never delete or move a leaf.** Archive it: `_status:_ archived YYYY-MM-DD — <reason>` under its
  H1, and ` _(archived)_` on its Contents row, so citations keep resolving.

## The private tree

Trunk `main` only. One commit per filing action, path-scoped: `git add <new files>`, then
`git commit -m "…" -- <paths>`, never `git add -A`, because this tree may have another writer. History
is never rewritten. A machine with no `private/` is normal, and every tool treats it so. `.conf`'s
`PRIVATE_SCOPES` sets which private branches search covers by default.

## Maintenance

`bash scripts/cure.sh` lints the structure and fails on a broken invariant; `bash scripts/smell.sh`
warns on heuristics; [HYGIENE.md](./HYGIENE.md) describes both. Run the linter after filing several
leaves and before merging.
