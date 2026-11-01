# The branch grammar: why it is one shape, and how a leaf moves or grows

_source:_ history/rulings/rulings.tree-structure.md TS3–TS16
_reviewed:_ 2026-11-02

The grammar itself (branches, indexes, the Contents shapes, reading by descent, writing as one
action, tags, standing orders, the archive form and promotion) is stated as an instruction in
[rules/branch-grammar.md](../../rules/branch-grammar.md), and the checks that enforce it in
[HYGIENE.md](../../HYGIENE.md). This article does not restate them. It carries what the rule
leaves out: why the grammar takes the shape it does, and the procedures for a move and a
promotion, which are rare enough to need their reasoning beside them.

## One shape at every depth

Every directory beneath every tree is a branch, read and written the same way (TS3). One shape
means one reading habit, one filing habit and one linter, whatever the depth or the tree. The
index is short because it is read at every descent: an H1, at most five lines that apply to
everything beneath, and a Contents table whose link text is each child's own H1 (TS4), so a
reader picks a child by the same words the child calls itself.

Two Contents shapes exist because two kinds of branch exist (TS5). An authored branch says what
each child is for. A provenance branch keeps a manifest, whose "Landed as" column is the audit
trail from a record to the merged change it produced. A bills branch keeps its own columns
([bills and laws](./article.bills-and-laws.md)).

## Reading and filing

Reading by descent is cheap because each step reads one small index (TS6). A crawl reads
everything to find one thing, and it rewards a tree whose indexes have rotted. Filing as one
action (TS7) is the other half: a leaf with no row cannot be found by descent, and a row with no
leaf is a false promise. Tags are written for the person searching, not the author (TS8),
because the author already knows where the leaf is.

A branch that needs special handling says so in a standing-orders file, `.agent`, which its
index points at (TS9). Generated tiers carry one, and so does the private tree's root.

## Never delete, never move

Paths are cited by filename: from product repositories, from rulings, from current law, and
from records that can never be edited to follow a rename. A filed leaf therefore stays where it
was filed (TS10). To retire one it is archived in place, as the rule and HYGIENE's "Archiving"
spell it. Archive is the strongest verdict: an archived leaf stays searchable, and readers skip
it unless they are asked for history.

## The sanctioned move

A move is the exception, and it is ruled before it is made (TS11). The procedure:

1. A bill names the move: what goes where, and why the old place no longer serves.
2. A dry-run link resolver measures, before anything moves, every link into the moved leaves
   and every relative link inside them.
3. The move is made whole, in one pass and one commit. Nothing in a moved leaf changes except
   the relative links that must be retargeted to keep resolving to the same files when the
   move changes the leaf's depth, and that holds for verbatim records too.
4. A stub is left at every old path: the moved leaf's H1, then
   `_status:_ archived YYYY-MM-DD — moved to <new path>`. A stub serves links into the moved
   location, never links out of it.
5. Editable citers are updated to the new path; immutable citers are never touched, and resolve
   through the stub.
6. A stub never points at a stub: when a leaf moves twice, the earlier stub is retargeted to
   the final home.

## Promotion

A leaf is promoted into a branch when it passes about 120 lines, needs sub-sections that other
indexes link to, or gains three or more siblings on its topic (TS12): a same-named directory is
created, the content split into leaves, its summary moved into the new `.index.md`, the original
archived, and every referring row repointed. Promotion is how the grammar stays shallow where
the subject is thin and deep where it is rich, without anyone planning the depth in advance.

## Months, the journal, and names that never collide

Dated records group into month branches keyed on their Created date (TS13), so no branch grows
without bound and a record is found by when it was made. The journal's layout is fixed (TS14)
because the tools and the ground rules spell its paths. A branch that is written in is never
named like an immutable tier (TS15): the journal's dated entries live in `entries/`, not
`history/`, so the guard on immutable paths never refuses an ordinary write.

A branch made from a template keeps no placeholder (TS16). In an instance the smell S09 finds
one; in this tree a reviewing agent does, since the linter does not walk `constitution/`.
