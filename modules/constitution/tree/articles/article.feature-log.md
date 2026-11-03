# The feature log: the way in to a product, and the one crossing from private to shared

_source:_ history/rulings/rulings.shared-and-private.md SP6–SP7, SP9–SP12; history/rulings/rulings.waves-and-close-out.md WK11
_reviewed:_ 2026-11-03

Each product has `public/<catalog>/<Product>/features/`, one leaf per area of the product. It
answers "what is the state of billing?" before "what happened in March?", which is why it is
the way in: a reader learning a product starts here and follows its links into `design/` and
`history/`. The leaf shape and what an entry may say are instructions in
[common/rules/feature-log.md](../../common/rules/feature-log.md); this article says why they are so.

## Areas belong to the owner

The area list is the owner's call (SP11). An entry that fits no area is raised with the owner,
never answered by inventing an area, because the list is the product's table of contents as the
owner sees it, and a list that grows by accretion stops being one. A leaf that outgrows about
120 lines promotes its older weeks to a `features.<area>.<year>.md` sibling, and State today
stays in the area leaf.

## State today and the entries

State today is edited as the product moves: it is the one paragraph a newcomer must read. The
dated entries below it are append-only, newest first under ISO-week headers, two to four
sentences each on what is now true (SP10). A later entry corrects an earlier one and State today
absorbs the correction; the log never rewrites its past, so a reader can trust a dated line to
say what was true on that date.

## What an entry may say

The shared tree reflects what is, and the feature log is where that is tested hardest (SP6). An
entry carries no process vocabulary, no branch names, no personal names and no first person,
and no ruling numbers in prose: it links the rulings leaf and the design leaf instead. A reader
who never saw how the work was run loses nothing.

An entry may end with one citation of delivery: a merged pull request of the product's
repository (`Invoicer #12`) or its change-log heading, as provenance and never as narrative
(SP7). An unmerged branch or an open pull request is not yet history and is not cited.

## Read again, as law is

A feature-log leaf carries `_reviewed:_ YYYY-MM-DD` directly under its H1, beside State today:
the date someone last read that paragraph against the product. State today is the one paragraph
a newcomer trusts, so it is judged for freshness as `design/` is, at ninety days, and a leaf
without the line is reported as a design leaf without provenance is. A research leaf may carry
the line and is judged at a longer window, since a study only ages out of relevance. The windows
and the two checks are the hygiene contract's S01 and S02.

## Written in two moments

A change has two moments, and the log is written in both (WK11):

- **At close-out**, the branch finished and the pull request not yet raised, each touched
  area's entry is drafted inside the dated journal entry beside the pull-request body, in the
  private mirror ([the work journal](./article.work-journal.md)).
- **At the landing**, the pull request merged, the drafted entries are appended here, dated by
  the merge.

A change that has not merged is not yet true, and a product's pull request does not carry a file
of the knowledge tree, so the entry waits for the merge. One pull request may touch several
areas, one entry in each. The test for an entry is whether something became true of the
product, not whether something merged: a documentation-only change earns none (SP12).

## The one crossing

The private records say how a change was delivered; the log says what it achieved. That is the
only thing that crosses from the private tree into `public/` as a matter of course (SP9), and
anything more crosses only on the owner's say-so ([tree structure](./article.tree-structure.md)).
