# Seed rulings: tree structure and grammar

_status:_ adopted 2026-11-04

The shape of the knowledge tree: the trees it is made of, the one grammar every branch speaks,
how a reader finds a leaf and a writer files one, and what happens to a leaf that is retired,
moved or outgrown. The articles on [tree structure](../../articles/article.tree-structure.md)
and [the branch grammar](../../articles/article.branch-grammar.md) rest on these.

- **TS1.** The repository holds three trees: a shared tree of what is true, a private tree of how
  the work was run on one machine, and the constitution, the tree's law about itself.
- **TS2.** The tree's own law is not filed as a product; it lives in the constitution, where the
  vocabulary of the process is its subject rather than a narration of work.
- **TS3.** One recursive grammar applies at every depth of every tree: a branch is a directory
  holding exactly one index, one tags file, single-topic leaves and child branches.
- **TS4.** An index is an H1, at most five lines of context that apply to everything beneath it,
  and a Contents table whose link text is each child's own H1.
- **TS5.** An authored branch's Contents table is `| File | Purpose |`; a provenance branch's is
  the manifest `| File | Kind | Created | Dates | Landed as |`, with `—` until the record lands.
- **TS6.** The tree is read by descending indexes from a root and never by crawling directories;
  when the location is unknown, tags resolve to branches through the search tool.
- **TS7.** Filing is one action: the leaf, its Contents row and any new tags land together, in the
  deepest branch that fits, and never one without the others.
- **TS8.** Tags are three to six lowercase words in the searcher's vocabulary, the synonyms the
  text does not use included; an existing tag is reused before a variant is invented, a word new
  material keeps using joins the tags in the same action, mirror branches reuse the shared
  vocabulary, and the tag that marks private information never appears outside the private tree.
- **TS9.** A branch that needs special handling carries a standing-orders file, read before the
  branch is read or written, and its index tells the reader so.
- **TS10.** A filed leaf is never deleted or moved; it is archived in place, with a dated status
  line naming what supersedes it and a marker on its Contents row, so every citation resolves.
- **TS11.** A move is sanctioned only by a ruling that names it and is made whole in one pass. It
  leaves a stub at every old path, a stub never points at a stub, and a move that changes a
  leaf's depth retargets the relative links inside the moved leaf so each resolves to the same
  file as before, changing nothing else in it.
- **TS12.** A leaf is promoted to a branch past 120 lines (a default), when it needs sub-sections
  other indexes link to, or when three or more siblings share its topic; the original is
  archived and every referring row repointed.
- **TS13.** Dated records group into month branches, `YYYY-MM/`, keyed on each record's Created
  date; a month's first filing creates its branch.
- **TS14.** The journal keeps a status page at its root and five branches: entries, epics,
  ledgers, retrospectives and reflections, the dated ones grouped by month.
- **TS15.** A branch that is written in is never named like an immutable tier, so that the guard
  on immutable paths never refuses an ordinary write.
- **TS16.** No template placeholder survives a filing: a branch or leaf copied from a template has
  every placeholder, and the template's own comment, replaced.
