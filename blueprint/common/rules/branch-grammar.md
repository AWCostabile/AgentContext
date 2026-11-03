# Branch grammar

_applies to:_ every `.index.md` and `.tags`, and everything under `common/templates/`

One grammar at every depth, in both trees. `public/` is indexed by `public/.index.md`, the
private mirror by `private/.index.md`.

## Two trees: route by kind, not by topic

- `public/` is what is true: rulings, design, the feature log, research, glossaries, and the
  branches that belong to the organisation rather than to one product. Committed here.
- `private/` is how the work was run on one machine: plans, kickoffs, PR bodies and their
  appendices, retros, epics, ledgers, journal entries. It mirrors the product branches of
  `public/` under the same paths (`private/<catalog>/<Product>/`) and adds `private/journal/`.
  A nested git repository the parent ignores wholly; create one from the skeleton. Its
  `local/`, `mod/` and `temp/` are freeform (own `.agent`), never linted.
- An authored `public/` leaf carries no process vocabulary (plan, kickoff, epic, sprint, retro,
  a numbered stage of work) and cites no record of the work. The one citable delivery trace is
  a merged pull request of the product's repository.
- Links run one way: private leaves may link into `public/`; nothing under `public/` links to,
  or cites the path of, a private record. Never edit an immutable record that already does; its
  branch index carries a one-line note instead.
- `.conf`'s `PRIVATE_SCOPES` says which private branches `find.sh` searches by default;
  `find.sh -p` searches all of `private/`.

## Branches, indexes, leaves

- A branch is a directory with exactly one `.index.md` and one `.tags`, plus leaves: single-topic
  `.md` files. The index is an H1, up to about five lines of context, then a `## Contents` table
  whose link text is each document's own H1.
- Contents shapes: authored `| File | Purpose |`; provenance (`history/`, the private immutable
  roots, the journal's ledgers) `| File | Kind | Created | Dates | Landed as |`, with `—` in
  "Landed as" while unlanded.
- Read by descending `.index.md` files from the root; never glob-crawl. Resolve tags with
  `bash common/scripts/find.sh <tag...>`, then expand and descend.
- Write a leaf in the deepest matching branch. Leaf, Contents row and `.tags` are ONE action; in
  the private tree the action ends with one commit of the private repository. Copy new branches
  from `common/templates/branch`, new products from `common/templates/product`, and replace every `{{ }}`
  placeholder, the template comment included.
- Group `plans/`, `kickoffs/`, `prs/` and `appendices/` by month (`YYYY-MM/`, keyed on the
  Created date); a month's first filing creates its branch.
- Name plans `plan.<YYYY-MM>-<n>.<product>-<slug>.md` and kickoffs
  `kickoffs.<YYYY-MM>-<n>.<slug>.md`: `<n>` is one counter per month across all products, in
  filing order, repeated in the H1. Never rename an older plan. A plan's kickoff, PR body,
  appendices and closing journal entry file under the plan's month and carry its number.
- Keep the journal's layout: `latest.md` at its root; `entries/<YYYY-MM>/`, `epics/`,
  `ledgers/`, `retros/<YYYY-MM>/`, `reflections/<YYYY-MM>/`.
- Never delete or move a filed leaf. To retire one, put
  `_status:_ archived YYYY-MM-DD — <reason, pointing at what supersedes it>` directly under its
  H1 and append ` _(archived)_` to its Contents-row link text. A move needs a decision naming it
  and leaves a stub at the old path.
- Promote a leaf past about 120 lines, or one that needs sub-sections linked from elsewhere, or
  one with three or more siblings on its topic: a same-named directory, the content split into
  leaves, a summary in its `.index.md`, the original archived, every referring row repointed.

## Tags

- Every branch below a tree root has `.tags`: one lowercase `[a-z0-9-]` tag per line, no commas.
- Never put the `private` tag under `public/`. Mirror branches reuse the public vocabulary.
- Write three to six tags in the searcher's vocabulary: the asker's own phrasing and the synonyms
  the text does not use. Run `bash common/scripts/find.sh -l` and reuse a tag before inventing a variant.
- When a branch's new material keeps using a word its tags lack, add it in the same action.

## `.agent` standing orders

If a branch has a `.agent`, read it before reading from or writing to that branch.
