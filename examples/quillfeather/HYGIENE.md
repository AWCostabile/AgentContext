# Hygiene

The tree checks itself in two layers, and this file is the single reference for both:

| Layer | Script | Verdict | Meaning |
| ----- | ------ | ------- | ------- |
| Invariants | `bash scripts/cure.sh` | FAIL | the structure is broken: fix it mechanically, no judgement needed |
| Invariants, advisory | `bash scripts/cure.sh` | WARN | probably wrong: judge it, fix it, or record why it stands |
| Smells | `bash scripts/smell.sh` | WARN | probably wrong: judge it, fix it, or record why it stands |
| Either | either | INFO | a fact worth knowing, not a finding |

Run `cure.sh` first, then `smell.sh`. Both are report-only: nothing edits the tree but a person
or an agent following the rectifications below. Both take `--root <dir>` (the directory holding
`public/` and `.conf`; default the current directory). `cure.sh --fast` skips the advisory scans
and keeps every FAIL; `smell.sh --quiet` prints the summary only, and `smell.sh --today YYYY-MM-DD`
judges the calendar smells (S01, S21) as of that date. `cure.sh` exits with its FAIL count,
`smell.sh` with its smell count (capped at 255). `bash scripts/review.sh` prints both verdicts and
the agenda they imply in about thirty lines (`--brief` one line of counts); it writes nothing, makes
no check of its own, and exits with the FAIL count. The conventions the checks enforce are
stated in [AGENTS.md](AGENTS.md) and the grammar documents under `rules/`:
[branch grammar](rules/branch-grammar.md), [provenance tiers](rules/provenance-tiers.md),
[design tier](rules/design-tier.md) and [feature log](rules/feature-log.md).

**Two trees, one grammar.** Both scripts lint `public/` always, and the private mirror
(`private/`, a nested repository the parent ignores) whenever this machine has one: every
top-level private branch except the freeform `local/`, `mod/` and `temp/`. An absent `private/`
is never an error, so `public/` must lint clean on a fresh clone. A fix inside `private/` ends
with one commit of the private repository. Besides the trees, `cure.sh` reads the root documents
for dead links only: every `*.md` at the root, `rules/*.md`, `scripts/.index.md` and
`templates/.index.md`. `templates/` is never linted as a branch, because it carries `{{ }}`
placeholders for good.

**Template mode.** With no `.conf` at the root, the root is the skeleton itself, and both
scripts say so in their header line. Every link, tag, Contents row or cell carrying a `{{ }}`
placeholder is then skipped by every check, S09 is not evaluated, and the placeholder branch
`catalog/` stands for every `CATALOGS` entry, so C14 is not evaluated either. With a `.conf`, a
placeholder is residue (S09).

**Verbatim copies.** The immutable provenance roots hold records copied verbatim:
`public/**/history/`, and in the private tree any `plans/`, `kickoffs/`, `prs/` or `appendices/`
branch and `journal/retros/`. A leaf listed in a provenance manifest (an index whose Contents
table has a `Landed as` column) is verbatim too. These keep their source bytes and their original
links: C04 does not resolve their links, C09 reports their private citations as INFO, S07 and
S09 skip them, and S13 and S18 never look there. Their indexes are authored and stay in scope.

**Moved stubs.** A sanctioned move leaves a small leaf at the old path so every citation keeps
resolving: its H1 is the moved leaf's, and its status line reads
`_status:_ archived YYYY-MM-DD — moved to <new path>`. It is a pointer by design, so the smells
that judge a leaf's substance skip it (S01, S02, S08, S12), while S05 and S16 read it like any
archived leaf.

## Invariants

Owned by `scripts/cure.sh`. Ids are stable; a missing number is a retired check.

| Id | Invariant | Verdict |
| --- | --------- | ------- |
| C01 | every branch directory has a `.index.md`; `public/` and `private/` each have their own | FAIL |
| C02 | every branch below a tree root has a non-empty `.tags`; a line that is not one lowercase `[a-z0-9-]` tag is a WARN | FAIL |
| C03 | every leaf and child directory is referenced by its branch index | FAIL |
| C04 | every relative link resolves, in both trees and the root documents; a root document's link into `private/` is conditional on the machine and skipped; verbatim copies keep their original links | FAIL |
| C05 | leaves over 120 lines are promotion candidates | WARN |
| C06 | Contents tables over 15 data rows are split candidates | WARN |
| C07 | exact singular/plural tag pairs fragment search | WARN |
| C08 | the `private` tag never appears under `public/` | FAIL |
| C09 | links run one way: nothing under `public/` links into `private/` or cites the path of a private record (`private/<path>.md`); a citation inside verbatim provenance is counted as INFO, never failed | FAIL |
| C14 | every `CATALOGS` entry in `.conf` has its `public/<catalog>/` branch; one INFO line when `.conf` has no `CATALOGS` key; not evaluated in template mode | FAIL |

**Rectifying C05 and C06.** Promote or split per the [branch grammar](rules/branch-grammar.md).
The core has no generated tier; a module that adds one exempts it from these two advisory checks
in the same change ([generated tiers](rules/generated-tiers.md)). The FAIL-class checks never
exempt anything.

**Rectifying C09.** Never by copying the private record into `public/`. If the leaf needs a
decision recorded in the private record, lift that decision verbatim into a public rulings leaf
and cite that; if the citation only narrates how the work was run, drop it. Naming the private
tree structurally (`private/`, `private/journal/`) is legal; a path to a record is not.

**Rectifying C14.** Create the branch from `templates/branch`, or remove the entry from
`CATALOGS` if the catalog was dropped.

## Smells

`smell.sh` prints `[SMELL Sxx] <path>: <signal>` per finding, then a per-id summary whose first
line carries `landed-since-retro=<n>`. Ids are stable; a missing number is a retired check.

### S01 — stale leaf

- **Signal:** a `_reviewed:_ YYYY-MM-DD` older than its tier's window: `design/` 90 days,
  `features/` 90 days, `research/` 180 days.
- **Why it matters:** `design/` is current law and a feature-log leaf's State today is the way
  in; one nobody has re-read against later rulings or the product may be quietly wrong. A
  research leaf is a study and only ages out of relevance, so its window is longer.
- **Detection:** the `_reviewed:_` date against today, or against `--today`.
- **Rectification:**
  1. Re-verify it. A design leaf: read the ruling its `_source:_` names, then every later ruling
     on the same subject, then the product it describes. Is it contradicted, duplicated
     elsewhere, in the wrong tier, or describing code that no longer has that shape? A feature
     leaf: read State today against the product. A research leaf: does its question still stand?
  2. If it still holds, bump `_reviewed:_` to today. If a newer ruling amends it, edit the law,
     cite the ruling in `_source:_`, and bump the date.
  3. If it is superseded outright, archive it ([Archiving](#archiving)).
- **Deliberate exceptions:** none. A stale leaf is either re-verified or archived.

### S02 — leaf without provenance

- **Signal:** a `design/` leaf missing `_source:_` or `_reviewed:_`; a `features/` leaf missing
  `_reviewed:_`. A `research/` leaf may carry `_reviewed:_` and is never asked to.
- **Why it matters:** a design leaf distils a ruling; an uncited one cannot be re-verified or
  trusted ([design tier](rules/design-tier.md)). A feature-log leaf with no review date can
  never go stale, which is to say nobody is ever asked to re-read it
  ([feature log](rules/feature-log.md)).
- **Detection:** lines starting `_source:_` and `_reviewed:_`.
- **Rectification:**
  1. A design leaf: find the ruling it distils (`bash scripts/find.sh -k <topic>`) and add
     `_source:_ <rulings path and ids>` and `_reviewed:_ YYYY-MM-DD` directly under the H1,
     after any `_status:_` line. If no ruling exists, the content is opinion, not law: move it
     to `research/`.
  2. A feature leaf: read State today against the product and add `_reviewed:_ YYYY-MM-DD`
     directly under the H1.
- **Deliberate exceptions:** none.

### S03 — dead tag

- **Signal:** a `.tags` entry that occurs nowhere in the branch's index, its leaves, its child
  indexes or its path.
- **Why it matters:** `find.sh` ranks matches by live occurrence count; a tag with no hits still
  matches but ranks last, so the branch is found late or not at all.
- **Detection:** whole word, case-insensitive; a hyphen matches `-`, `_` or a space; a trailing
  `s` is optional on either side; the branch path counts as a substring.
- **Rectification:**
  1. If the tag is a deliberate searcher's synonym, use the word once in the index's context
     lines so search weighting sees it.
  2. If it describes nothing beneath the branch, delete it.
  3. If the content moved, move the tag with it.
- **Deliberate exceptions:** a synonym the index cannot naturally carry may stand, reasoned in
  the report.

### S04 — tag fragmentation

- **Signal:** a tag used in exactly one `.tags` tree-wide that has a near neighbour: edit
  distance 1 (or 2, when both are five letters or more and share their first three), a shared
  stem of four letters or more covering 80 % of the shorter tag, or the initials of a hyphenated
  tag.
- **Why it matters:** two spellings of one concept split search results in half.
- **Detection:** Levenshtein distance over the whole vocabulary; exact singular/plural pairs
  belong to C07 and are skipped.
- **Rectification:** `bash scripts/find.sh -l`, keep the form with more uses, rewrite the
  minority `.tags` files to it.
- **Deliberate exceptions:** two genuinely different concepts that happen to look alike; leave
  them standing with a one-line reason.

### S05 — index row drift

- **Signal:** a Contents row whose link text no longer equals the target leaf's H1.
- **Why it matters:** readers choose leaves from index rows; a row with an old title misroutes
  them.
- **Detection:** the first link of each row against the target's first `# ` line, normalised for
  whitespace, escaped `\|` and the ` _(archived)_` suffix. A target with no H1 is skipped.
- **Rectification:** decide which side is right (usually the H1, edited last) and update the
  other in the same action.
- **Deliberate exceptions:** none; rename the H1 rather than keep a short label.

### S06 — manifest gaps

- **Signal:** a provenance manifest row whose `Landed as` says `unmerged` or `unknown`, or whose
  `Created` cell does not start with `YYYY-MM-DD`.
- **Why it matters:** a manifest is the audit trail from a record to the change it produced; a gap
  means the trail was never closed.
- **Detection:** cells split on unescaped `|`.
- **Rectification:**
  1. Find the landing in the product repository's history (the merged pull request, or its
     change-log heading) and fill the cell.
  2. Fill `Created` from the record's own date line or its first commit.
  3. If the work never landed, write `— (abandoned: <reason>)` so the gap is closed on purpose.
- **Deliberate exceptions:** none. A record still in flight carries `—`, which is not a gap.

### S07 — CRLF

- **Signal:** a `\r` in an authored `*.md` of either tree, under `templates/`, or at the root.
- **Why it matters:** CRLF files diff as whole-file rewrites and break anchored searches.
- **Detection:** awk in binary mode, because the Windows ports of gawk and grep strip `\r`
  unless told not to. Verbatim copies are excluded: CRLF there is source fidelity.
- **Rectification:** convert the file to LF, and make sure the repository's `.gitattributes`
  stores and checks out LF so it stays that way.
- **Deliberate exceptions:** none outside the verbatim tiers.

### S08 — empty or shell leaf

- **Signal:** a leaf with three or fewer non-blank lines, or headings only; an index with no
  content.
- **Why it matters:** a shell costs a row, a read and a search hit while telling the reader
  nothing.
- **Detection:** non-blank and non-heading line counts.
- **Rectification:** write the leaf, or delete it and its row in one action.
- **Deliberate exceptions:** a placeholder the product template mandates (a `glossary.md` with no
  terms yet) until it fills; moved stubs, which are skipped.

### S09 — template residue

- **Signal:** `{{` or `}}` in an authored file of either tree, `.tags` and `.agent` included.
  Instances only: not evaluated in template mode.
- **Why it matters:** an unfilled placeholder is a branch nobody finished creating.
- **Detection:** a count of placeholder lines per file; verbatim copies are excluded, since a
  product document may legitimately contain a `{{ }}` templating language.
- **Rectification:** replace every placeholder as the template's own comment says, and remove
  that comment while there.
- **Deliberate exceptions:** none.

### S10 — unindexed `.agent`

- **Signal:** a branch carries `.agent`, but its `.index.md` never tells the reader to read it.
- **Why it matters:** a `.agent` file holds standing orders to read before the branch is
  touched; an index that stays silent lets readers skip them.
- **Detection:** the literal `.agent` in the index; covers both trees and `private/.agent`.
- **Rectification:** add a context line telling the reader to read `.agent` before working
  here, with one clause on what it governs.
- **Deliberate exceptions:** none.

### S11 — cross-branch row

- **Signal:** a Contents row linking outside its branch (`../`, or a grandchild leaf) instead of
  a sibling leaf or a child's `.index.md`.
- **Why it matters:** the tree is navigated by descending indexes; a row that jumps sideways
  breaks the grammar and rots when its target moves.
- **Detection:** every link in a table row; provenance manifests are exempt, since their rows
  may cite the product repository.
- **Rectification:** link the child branch's `.index.md` and let the reader descend; or move the
  content so row and leaf share a branch; or turn the pointer into a prose "see also" line.
- **Deliberate exceptions:** none in Contents tables; prose cross-references are fine.

### S12 — duplicate leaf basename

- **Signal:** the same leaf filename in two branches. `glossary.md` and the per-product
  `features.<area>.md` leaves and a generated tier's `codebase.*.md` leaves are ignored, and moved
  stubs are skipped (a stub shares its name
  with the leaf it points at).
- **Why it matters:** two `notes.md` files are indistinguishable in search results and in
  citations by filename.
- **Detection:** a basename count over every leaf.
- **Rectification:** if they are one topic, merge them under the deeper branch and archive the
  other; if not, rename one to a self-describing name and update its row in the same action.
- **Deliberate exceptions:** parallel per-product files with a shared purpose; prefer
  product-prefixed names anyway.

### S13 — retired vocabulary

- **Signal:** a term from `scripts/retired-terms.txt` in a live document: a `design/` leaf, a
  `glossary.md`, or the root `AGENTS.md`, `HYGIENE.md` or `README.md`.
- **Why it matters:** law written in a retired spelling teaches every reader to produce the
  refused form.
- **Detection:** a fixed, case-sensitive substring per line; verbatim copies are never scanned,
  since they legitimately record the old names. The file is `term<TAB>replacement<TAB>source`,
  one entry per line; a line starting `# ` is a comment. When the tree has no
  `scripts/retired-terms.txt` of its own, the list beside `smell.sh` is used.
- **Rectification:** replace the term with the listed spelling; the source column names what to
  read first. If the old term must be mentioned (a migration note), quote it in backticks with
  the word "retired" on the same line, and leave it standing.
- **Deliberate exceptions:** the migration-note case above.

### S14 — oversized index context

- **Signal:** more than five prose lines between an index's H1 and its Contents table (metadata
  lines such as `_status:_` and HTML comments do not count).
- **Why it matters:** an index is read at every descent; context that grows into an essay taxes
  every query that passes through.
- **Detection:** the non-blank line count before `## Contents` or the first table row.
- **Rectification:** move the detail into a leaf and leave a one-line pointer; keep only what
  applies to everything beneath the branch.
- **Deliberate exceptions:** none.

### S16 — archive marker mismatch

- **Signal:** a leaf with `_status:_ archived` whose index row lacks ` _(archived)_`, the reverse,
  or an archived status line without a date and a reason.
- **Why it matters:** readers skip archived leaves by the row marker and trust the leaf's own line
  when they open it; the two must agree or one audience is misled.
- **Detection:** the status line against `_status:_ archived YYYY-MM-DD — <reason>`, and against
  the row's suffix.
- **Rectification:** follow [Archiving](#archiving) exactly; both edits are one action.
- **Deliberate exceptions:** none.

### S17 — retrospective overdue

- **Signal:** three or more provenance manifest rows whose `Landed as` cell carries a date newer
  than the newest retrospective leaf, or three or more landed rows and no retrospective yet.
- **Why it matters:** a retrospective turns landed work into rulings and lessons; three landings
  without one means the knowledge is sitting in records nobody has distilled.
- **Detection:** evaluated only where a private tree exists. The newest
  `retro.YYYY-MM-DD.<slug>.md` under `private/journal/retros/` (any month branch) sets the
  baseline; with none, every landed row counts. A cell naming several landings counts once, at
  its latest date; a moved stub's row is skipped, so the record counts once, at its new home. The
  count is always printed as `landed-since-retro=<n>`, fired or not.
- **Rectification:** run a retrospective over the window and file it as
  `retro.YYYY-MM-DD.<slug>.md` in its month branch under `private/journal/retros/`, row and leaf
  in one action. The new leaf resets the baseline.
- **Deliberate exceptions:** a block of work still in flight, when the retrospective that would
  close it is already planned; note the expected date where the work is tracked and cite that in
  the report.

### S18 — process vocabulary in the public tree

- **Signal:** an authored leaf or index under `public/` using the vocabulary of how work is run:
  epic, sprint, retro or retrospective, or a plan, wave or phase followed by its number.
- **Why it matters:** `public/` describes what the products and the organisation ARE, not the
  day-to-day work that produced them. A reader who never saw that work must lose nothing, and a
  record of it lives in somebody's private tree where a teammate cannot follow it.
- **Detection:** case-insensitive whole words, one finding per file with its line count. Plan,
  wave and phase alone are ordinary product words and never match. Out of scope: verbatim copies,
  which keep the vocabulary they were written in, and manifest indexes, whose link texts are those
  records' own titles.
- **Rectification:**
  1. Say what is true instead of when or how it was scheduled ("ships with the new formats", not
     the name of the batch of work that shipped them).
  2. If delivery provenance matters, cite what exists in the codebase's own history: a merged
     pull request of the product repository, which any teammate can find.
- **Deliberate exceptions:** a standing practice described as such in a design leaf (how the
  product is verified or released) is product knowledge, not a work record, but it still names no
  particular block of work.

### S20 — uncited leaf

- **Signal:** a `design/` or `history/` leaf under `public/` that no file cites beyond its own
  branch index.
- **Why it matters:** a design leaf is current law; one nothing reads is law nobody follows, or
  a subject that belongs in another leaf. A history leaf is provenance; one nothing rests on is
  a ruling that was never distilled into `design/`, or a record whose law has moved on without
  saying so.
- **Detection:** the citation rule of `find.sh -b`: the leaf's basename anywhere in another
  file's text, a Markdown link or a bare path alike (S12 keeps these basenames unique), in every
  authored file of both trees except moved stubs. `features/`, `research/` and the private tree
  are never judged: a feature-log leaf is an entry point and need not be cited. Archived leaves
  and moved stubs are skipped.
- **Rectification:**
  1. A design leaf: cite it where it is read, from the feature log's State today or from the
     design leaf whose subject touches it; if nothing does, its subject may belong inside
     another leaf, or it is superseded: archive it ([Archiving](#archiving)).
  2. A history leaf: distil it, so the design leaf that holds the law names it in `_source:_`;
     if the law has moved on, the design leaf that supersedes it should say what it supersedes.
- **Deliberate exceptions:** a ruling made and then reversed by a later ruling, which the later
  ruling cites: it is cited, and the check is quiet. A freshly filed design leaf whose
  feature-log entry waits for a merge may stand until the landing, reasoned in the report.

### S21 — inbox item overdue

- **Signal:** a `- YYYY-MM-DD — <text>` item in `private/journal/inbox.md` older than 14 days.
- **Why it matters:** the inbox is the one cheap landing for a thought mid-session, and cheap
  only because every item leaves it soon: promoted into a leaf, a ruling, a design change or a
  feature-log line, or dropped. An item that sits is a decision nobody made.
- **Detection:** the date at the head of the item against today, or against `--today`; private
  tree only, and only when the file exists.
- **Rectification:** triage the item with the user: file it properly (leaf, row and tags as one
  action, or the ruling, design change or feature-log line it was a candidate for) and remove
  the line, or drop it. Nothing is filed from the inbox by an agent on its own.
- **Deliberate exceptions:** none. An item that needs more time is a question for a ledger, not
  an inbox line.

## Archiving

Archiving marks a leaf as superseded without losing it. Both edits are one action:

1. Add, as the line directly under the leaf's H1:
   `_status:_ archived YYYY-MM-DD — <reason, naming what supersedes it>`.
2. Append ` _(archived)_` to the link text of the leaf's Contents row.

Archived leaves stay in place, stay tagged and stay searchable; readers skip them unless asked
for history. S16 keeps the two markers in step, and S05 ignores the suffix when comparing titles.
Verbatim provenance is never archived: it is already history. A leaf is never deleted or moved
silently; a merge or a promotion leaves an archived pointer behind.

## Adding a smell

A convention written in one place and checked nowhere drifts. When a convention is decided (in a
`design/` leaf, in `AGENTS.md` or in a `rules/` document), the same change:

1. adds a section here with the next free id, all five headings filled;
2. adds the check to `scripts/smell.sh`, emitting `Sxx<TAB>message`, as a single awk or grep pass
   over the file set (the script runs on every review and must stay fast on a large tree);
3. confirms on a scratch copy of the tree that the new check fires exactly once on one seeded
   case, and stays silent on the skeleton in template mode;
4. for a vocabulary decision, adds a `term<TAB>replacement<TAB>source` line to
   `scripts/retired-terms.txt` instead of a new id: S13 already carries it.

A smell that turns out to be an invariant (never legitimately standing) moves to `cure.sh` as the
next free `C` id and is retired here, never silently dropped.

## Review cadence

| When | Run | Who |
| ---- | --- | --- |
| after any filing session | `bash scripts/cure.sh --fast` | the filing agent |
| before merging a branch | `bash scripts/cure.sh`, then `bash scripts/smell.sh`: zero FAILs, every smell fixed or reasoned | whoever raises the merge |
| after every landing | the `landed-since-retro` count in the summary; a retrospective at three | whoever records the landing |
| weekly | `bash scripts/review.sh`: the agenda; each line acted on or reasoned | the user |
| quarterly | S01: every `design/` and `features/` leaf's `_reviewed:_` re-verified or archived; research at its longer window | the tree's maintainer |
| whenever a branch's smell count grew since the last report | a re-verification pass over that branch | the tree's maintainer |

Record each standing smell in the review report with its one-line reason. A reason repeated in
three reports running is a candidate for a deliberate-exception clause above.
