# Agent instructions

This repository is a knowledge tree: what this organisation knows, in a shape agents and new hires
align to from the first prompt, at low token cost. `public/` is what is true and is committed here.
`private/` is how the work was run on one machine: a nested git repository this one ignores.

## How to read

1. Read `.conf` first. It says how to speak to this user and which catalogs and private branches
   exist. Its keys are explained in `common/.conf.example`.
2. If `private/journal/latest.md` exists, read it before anything else: what is in flux, what last
   landed, what is next. If it is absent, this machine holds no development-cycle records. Say so
   rather than guessing at the state of the work.
3. Descend `.index.md` files from the table below. Never glob-crawl the tree.
4. Resolve tags with `bash common/scripts/find.sh <tag...>`, then expand and descend.
5. If a branch has a `.agent`, read it before reading from or writing to that branch.
6. **Read a project on first touch, and not before.** The workspace holds this tree and its
   repositories side by side. Your session opens with this tree's instruction alone. The first
   time you touch another project of the workspace, read its `.agents/.id.meta` when it has one
   (its identity: an id, a name, a date, never a path), then that project's own instruction file,
   then nothing more of it until you work there. A project you never enter costs the session
   nothing.

**To learn the state of a product, start at its feature log**: `public/<catalog>/<Product>/features/`,
one leaf per area, each opening with a **State today** paragraph. Follow its links into `design/` and
`history/`.

| Index | Purpose |
| ----- | ------- |
| [Public](./public/.index.md) | what is true: per-product rulings, design, feature log, research; shared tools; misc |
| [Private — the development cycle on this machine](./private/.index.md) | only where this machine has one: plans, kickoffs, PR bodies, retros, the journal |
| [Templates](./common/templates/.index.md) | copy these to make a new branch, leaf or product |
| [Scripts](./common/scripts/.index.md) | `find.sh` search; `cure.sh` the linter; `smell.sh` the smells; `review.sh` the agenda |
| [Rules](./common/rules/.index.md) | the grammar and tier rules as plain documents |

## Where to write

**Route by KIND, not by topic.**

- Ruling, design, feature-log entry, research: `public/`.
- Plan, kickoff, PR body, PR appendix, retro, epic, ledger, journal entry: `private/`.
- A thought with no home yet: one dated line in `private/journal/inbox.md`, under **Mine** when
  it is the user's, under **Candidates** when you propose it should become a ruling, a design
  change or a feature-log line. The user promotes or drops each item; you file nothing from it on
  your own.

Write in the deepest matching branch. **Leaf + Contents row + tags is one action**; in the private
tree it ends with one commit. Copy new branches from `common/templates/branch`, and new products from
`common/templates/product` (its private mirror from `common/templates/product-mirror`), filling in every
placeholder.

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
  is editable until its "Landed as" is filled; a kickoff prompt is rewritten in place until an agent
  has run from it, then frozen, a later prompt added below it.
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

The tree checks itself in two layers, and [HYGIENE.md](./common/HYGIENE.md) is the contract of both:

- `bash common/scripts/cure.sh` lints the structure: every branch indexed and tagged, every leaf referenced,
  every link resolving, nothing under `public/` pointing into `private/`, every catalog in `.conf`
  present. A broken invariant is a FAIL and the exit code counts them; `--fast` skips the advisory
  scans.
- `bash common/scripts/smell.sh` hunts what is probably wrong and needs judgement: a stale design or feature
  leaf, a design or history leaf nothing cites, a dead tag, an index row that no longer matches its
  leaf's title, process vocabulary in `public/`, a retired spelling, an inbox item left too long. Every
  finding is a WARN to fix or to record a reason for.
- `bash common/scripts/review.sh` prints the agenda the two imply in about thirty lines and writes nothing:
  the verdict, the smell summary, the inbox, the stale and uncited leaves, the retro pressure, the
  branches without an upstream, the newest journal entry; `--brief` is one line of counts.
- `bash common/scripts/find.sh -b <leaf>` lists every file that cites a leaf (its index row marked), and
  `-f <key>` the files carrying a `_<key>:_` marker line with its value (`-f reviewed`,
  `-f 'reviewed<2026-01-01'`): what cites this, and what is due, without a grep.

Both read `.conf` and treat an absent `private/` as normal. Run the linter after filing several
leaves and before merging a branch: zero fails, every smell fixed or reasoned. The grammar the checks
enforce is written out in [common/rules/](./common/rules/.index.md).

The core files this tree received from the template (`common/scripts/`, `common/rules/`, `common/templates/`, `.vscode/`,
this file, `common/HYGIENE.md`, `README.md`, `common/.conf.example`) are listed with their hashes in `common/.agentcontext`,
with the release they came from. A later release is pulled in with the template's deployer in update
mode, which replaces what was never edited here and reports what was; the procedure is the "How to
update" section of the template's `SETUP.md`, at the `upstream=` address the manifest names. Nothing
filed in `public/` or `private/` is ever touched by it.
