# The constitution: three tiers of law, and the files that enforce it

_source:_ history/rulings/rulings.tree-structure.md TS1–TS2; history/rulings/rulings.bills-and-law.md BL1, BL5–BL7, BL13–BL15; history/rulings/rulings.agents-and-budgets.md AG11
_reviewed:_ 2026-11-02

The knowledge tree governs itself. Its law about its own shape, and the process that keeps the
work honest (how law is proposed, enacted, amended and enforced), is filed in a tree of its own,
`constitution/`, beside the two trees that hold the organisation's knowledge and its working
records. This article says what the constitution is, how it binds the files that act on it, and
how it changes.

## Three trees

| Tree | Holds | Committed by |
| --- | --- | --- |
| `public/` | what is true of the organisation and its products | the instance repository |
| `private/` | how the work was run, on one machine | a nested repository, ignored by the parent |
| `constitution/` | the tree's law about itself and the governing process | the instance repository |

All three speak one [branch grammar](./article.branch-grammar.md) (TS1). The tree's own law is
not filed as a product under `public/`: it is not a product, and the vocabulary of the process
is its subject rather than a narration of work (TS2). The constitution obeys the one direction
of reference exactly as `public/` does ([tree structure](./article.tree-structure.md)).

## Three tiers of law

- **`bills/`**: prospective law, written in a scoping conversation, cited from the kickoff of
  the work that builds it, and editable until it is enacted or withdrawn
  ([bills and laws](./article.bills-and-laws.md)).
- **`history/rulings/`**: enacted law, immutable. A ruling is added verbatim with a manifest
  row and never edited ([the tiers](./article.tiers.md)).
- **`articles/`**: current law, one article per subject, each citing the rulings it rests on and
  saying what it supersedes. An article is to the constitution what a `design/` leaf is to a
  product (BL1).

A product takes bills too, under `public/<catalog>/<Product>/bills/`, enacted into that
product's `history/` and distilled into its `design/`. The constitution's own development
records (the plans and pull-request bodies that change the process) live in the private
mirror at `private/constitution/`, made from the product-mirror template when the first arrives.

## Adoption

The rulings this module ships are seed law: generic, written for no one organisation, and
marked `_status:_ seed`. Adopting them is the one moment they are edited. The owner deletes the
rulings and articles that do not apply, amends the ones that do, then changes each kept leaf's
status line to `_status:_ adopted YYYY-MM-DD` and fills its manifest row's Created with that
date. The status line is what freezes a leaf: a pre-write guard lets a seed leaf through and
refuses an adopted one. From then on the rulings are immutable and every change to the process
is a bill first (BL5).

## The enforcement layer

The operative files are the files a session or a tool actually loads, and they are where the
constitution acts. They stay where the tooling finds them, state an instruction (what to do)
and leave the reasoning to the article they implement:

| Operative file | Implements |
| --- | --- |
| `AGENTS.md` at the root | the constitution as a whole |
| `common/rules/branch-grammar.md`, `common/templates/` | [tree structure](./article.tree-structure.md), [the branch grammar](./article.branch-grammar.md) |
| `common/rules/provenance-tiers.md`, `common/rules/design-tier.md` | [the tiers](./article.tiers.md) |
| `common/rules/generated-tiers.md` | [generated tiers](./article.generated-tiers.md) |
| `common/rules/feature-log.md` | [the feature log](./article.feature-log.md) |
| `common/rules/active-work.md` | [the work journal](./article.work-journal.md) |
| `common/HYGIENE.md`, `common/scripts/` | [hygiene](./article.hygiene.md) |
| `constitution/process/` | [the wave ground rules](./article.wave-ground-rules.md), [rigour](./article.rigour.md) |
| what an adapter lays down: guards, agent profiles, commands | the article each enforces (AG11) |

An operative file written for this instance cites its article near its top (BL13):

- a Markdown file: `_article:_ constitution/articles/article.<slug>.md`, comma-separated where
  it implements several;
- a script: a comment line `# constitution: articles/article.<slug>.md` near its header, in the
  language's own comment syntax;
- a template tree: once, in its root index's header comment; its copies carry no citation.

The core files a template release installs carry no citation line, so that an update can
replace them cleanly; the table above is their citation. The core linter does not check the
chain. An instance that wants it proven adds a check as `common/HYGIENE.md` describes ("Adding a
smell"); until then a reviewing agent checks it at every enactment.

## Citation forms

- An article opens with `_source:_ history/rulings/rulings.<slug>.md <ids>`, several leaves
  separated by `;`, superseded rulings listed too, then `_reviewed:_ YYYY-MM-DD`.
- An article citing an open bill writes `_source:_ bills/bill.<YYYY-MM>-<n>.<slug>.md <ids>
  (bill — pending enactment)`; never an enacted or withdrawn bill (BL7).
- Inside an article, a sentence that rests on one ruling cites its id in parentheses, as this
  one does (BL13).

## Amendment

A change to the constitution is a bill like any other, and it also names the operative files it
will change. Its enactment is one action: the ruling added verbatim, the articles rewritten from
it, the named operative files updated, and the linter at zero failures as the proof (BL6, BL14).
The constitution amends itself the same way, with no special case, this article included.

An operative rule edited with no bill behind it is a **quiet amendment**: the instruction now
says something the law does not (BL15). It is a smell, and the fix is a bill or a revert of the
edit, never a matching edit to the article. A commit that edits an operative file names, in its
body, the article it serves; one that cannot is changing the law and needs a bill.
