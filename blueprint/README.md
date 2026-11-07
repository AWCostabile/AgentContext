# {{TREE_NAME}}

This repository is a knowledge tree: what this organisation knows, kept as small indexed
Markdown files that a new hire and a coding agent can both read. Nothing here needs a tool to
open; everything is found by descending indexes from this page.

## Where to start

- **The state of a product**: its feature log, `public/<catalog>/<Product>/features/`, one
  leaf per area of the product, each opening with a **State today** paragraph. Follow its links
  into `design/` (how it works today) and `history/` (what was decided, and why).
- **The products themselves**: [public/.index.md](./public/.index.md) lists the catalogs, and
  each catalog lists its products.
- **A term you do not know**: a product's `glossary.md`, one line per term, each pointing at
  the design leaf that holds its law.

## The two trees

- `public/` is what is true: the products, how they work, what was decided, what the company
  is. It is committed here and shared with everyone who clones this repository.
- `private/` is how the work was run on one machine: plans, the prompts that launched them,
  pull-request records, the journal of what is in flux. It is a git repository of its own that
  this one ignores, so a fresh clone has none, and that is normal.

Links run one way: a private page may link here; nothing under `public/` points into
`private/`. What a change achieved crosses into the feature log when its pull request merges;
how it was run never does.

## How to search

From the root, `bash common/scripts/find.sh <tag...>` resolves tags to the branches that carry them,
`-k <word>` greps the indexes, `-b <leaf>` lists every page that cites a leaf, and `-f <key>`
lists the pages carrying a `_<key>:_` line, such as `-f reviewed`. Every directory is a branch
with one `.index.md` and one `.tags`; `find.sh -l` lists the whole tag vocabulary.

## How to file

A new fact goes in the deepest branch that fits, as one action: the leaf, its row in the
branch's `.index.md`, and any new tag in `.tags`. A new branch is copied from
`common/templates/branch`, a new product from `common/templates/product`. A ruling, a design change, a
feature-log entry or a piece of research belongs in `public/`; a plan, a kickoff, a
pull-request record or a journal entry in `private/`. A thought with no home yet goes on one
dated line of `private/journal/inbox.md`, to be filed or dropped later.

## Keeping it honest

`bash common/scripts/cure.sh` fails on a broken shape, `bash common/scripts/smell.sh` warns on what needs
judgement, and `bash common/scripts/review.sh` prints the week's agenda from both.
[HYGIENE.md](./common/HYGIENE.md) explains every check and how to put it right.

## For agents

[AGENTS.md](./AGENTS.md) is the instruction an agent session reads first, and
[common/rules/](./common/rules/.index.md) holds the grammar as plain documents. This page is for people;
it repeats neither.
