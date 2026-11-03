# The knowledge tree: three trees, and one direction of reference

_source:_ history/rulings/rulings.tree-structure.md TS1–TS2; history/rulings/rulings.shared-and-private.md SP1–SP9, SP13
_reviewed:_ 2026-11-02

The knowledge tree is three trees in one repository. `public/` is what is true: what was ruled,
how things work, what the organisation is. `private/` is the development cycle as known on one
machine: how the work was run. `constitution/` is the tree's law about itself
([the constitution](./article.constitution.md)). All three obey one
[branch grammar](./article.branch-grammar.md); what differs is what may live in each and which
way a reference may point (TS1).

## What each tree holds

`public/` carries each product's rulings, its current law under `design/`, its feature log,
its research, and the branches that belong to the organisation rather than to a product. It
is a living reflection of the products and the organisation as they are (SP1).

`constitution/` carries the tree's own bills, rulings and articles, and the process documents
under `process/`. It is committed like `public/` and bound by the same one-way rule (TS2).

`private/` carries the records of the work: the briefs that scope a change, the prompts that
launch it, the pull-request bodies that describe it, the work journal, the ledgers that span
products, and the retrospectives written over landed work. It repeats `public/`'s product
branches under the same paths, so the tier rules carry over by path (SP2).

A machine with no `private/` is normal. Every tool treats its absence as the ordinary case, and
a session there has no development-cycle state to read and says so (SP4).

## The private tree is a nested repository

The parent repository ignores `private/` wholly and records nothing about it: no submodule, no
gitlink (SP3). It is a repository of its own, initialised in place, which gives the records
versioning and an optional private remote as backup while keeping them out of everything the
parent publishes. How it is run is [the work journal](./article.work-journal.md)'s.

## The one direction of reference

A private leaf may link into `public/` and `constitution/` freely. A public or constitutional
leaf never links to, or cites the path of, a private record (SP5). For `public/` this is an
invariant: the linter's C09 fails any link or citation into `private/`, and reports one inside
verbatim provenance as INFO, since a record cannot be edited to fix it. The constitution is
outside the linter's walk and keeps the rule by review.

The reason is the reader with no private tree: a new teammate, a fresh clone. A leaf that
pointed into `private/` would resolve on exactly one machine.

## The one crossing

What a change achieved crosses into the [feature log](./article.feature-log.md); how it was run
never does (SP9). Nothing else crosses without the owner saying so. A decision found inside a
private record is lifted verbatim into a public rulings leaf, which current law then cites
([the tiers](./article.tiers.md)).

## What shared prose may not know

Every authored leaf under `public/` describes what is, not how it came to be: no trace of the
day-to-day work and no reference to a record of it (SP6). The smell S18 reports the vocabulary
of how work is run in authored public leaves. It never looks at verbatim records, which keep the
words they were written in, nor at the root instruction documents, nor at `constitution/`, which
sits outside `public/` by construction: an article describes what a kickoff or a retrospective
is, and the words are its subject (SP8). The exemption is from the smell, not from the posture.
An article never narrates how a particular change was delivered and never cites a private record.

The one citable trace of delivery is the product repository's own history, which any teammate
can find: a merged pull request or the change-log heading it landed as, cited as provenance and
never as narrative (SP7). An unmerged branch or an open pull request is not yet history.

## Where active work is read

What is in flux is a fact about one machine, so the status page, `latest.md`, lives at the
root of `private/journal/`, and the root `AGENTS.md` carries only a static pointer to it
(SP13). Search scope is a machine setting: `.conf`'s `PRIVATE_SCOPES` lists the private branches
the search tool covers by default, and an empty value means `public/` only (SP4).

## Adopting the module

An instance that adopts the constitution adds one row for `constitution/.index.md` to the index
table of its root `AGENTS.md`. That file is a core file the template's updater tracks, so the
edit is reported as local on the next update and kept.
