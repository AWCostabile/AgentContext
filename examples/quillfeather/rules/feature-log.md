# The feature log

_applies to:_ `public/**/features/`

`public/<catalog>/<Product>/features/` holds one leaf per AREA of the product and is the way in:
to learn the state of a product, start here. `design/` stays the answer to "how does it work".

- The area list is the owner's call. Never add, rename or merge an area to fit an entry; propose
  it.
- Leaf shape: an H1; directly under it `_reviewed:_ YYYY-MM-DD`, the date someone last read
  State today against the product (bump it when you do: the smell linter asks for the line and
  judges it stale at 90 days, as it does a design leaf's); a **State today** paragraph (edited as
  the product moves); then dated entries newest first under ISO-week headers
  (`## 2026-W39 · Sep 21–27`), only weeks that have entries.
- An entry is a bold date and two to four sentences on what is NOW TRUE of the codebase,
  linking the `design/` leaf and the rulings leaf. Append only; correct with a later entry and
  let State today absorb it.
- Write no plan, kickoff, epic, sprint or retro, and no numbered stage of work; no branch names;
  no personal names or first person; no ruling numbers in prose (link the rulings leaf).
- End an entry, if at all, with a merged pull request of the product's repository, as
  provenance, never narrative. Never cite an unmerged branch or an open pull request.
- Link into `public/` only; never to a plan, PR body, retro or journal path.
- Name the area's headline features in its index row's Purpose cell; the link text is the leaf's
  H1 (`<Product>: <Area>`).
- Draft the entry at close-out inside the journal entry; append it here only when the product's
  pull request merges, dated by the merge. One entry per touched area. Ask "did something become
  true of the product?": a change that only realigned documentation earns none.
- Promote a leaf past about 120 lines: older weeks move to a `features.<area>.<year>.md`
  sibling; State today stays in the area leaf.
