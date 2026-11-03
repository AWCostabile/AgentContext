# Seed rulings: shared and private

_status:_ adopted 2026-11-04

What the shared tree may know and what stays on one machine: the private tree as a nested
repository, the one direction of reference, the posture of shared prose, the feature log as the
one routine crossing, and where each kind of record lives. The articles on
[tree structure](../../articles/article.tree-structure.md),
[the feature log](../../articles/article.feature-log.md) and
[the work journal](../../articles/article.work-journal.md) rest on these.

- **SP1.** The shared tree holds what is true of the organisation and its products; the private
  tree is one machine's working memory of how the work was run.
- **SP2.** The private tree mirrors the shared tree's product branches under the same paths and
  the same grammar, so the tier rules carry over by path.
- **SP3.** The private tree is a nested repository the parent ignores wholly, never a submodule,
  and the parent records nothing about what is inside it.
- **SP4.** An absent private tree is normal: every tool treats it as the ordinary case, the shared
  tree lints clean without it, and which private branches search covers by default is a machine
  setting whose empty value means the shared tree only.
- **SP5.** Links run one way: a private leaf links into the shared tree freely, and nothing shared
  links to, or cites the path of, a private record; the linter fails such a link.
- **SP6.** Shared prose describes what is, never how or when the work was scheduled, and carries
  no process vocabulary.
- **SP7.** The one citable trace of delivery in the shared tree is a merged change of the
  product's own repository, its pull request or its change-log heading, cited as provenance and
  never as narrative; an unmerged branch is not cited.
- **SP8.** The process-vocabulary check exempts immutable records, the instruction documents at
  the root and the constitution, whose subject is the process; the rest of the posture binds
  them all the same.
- **SP9.** The feature log is the one routine crossing from private to shared: what a change
  achieved, never how it was run; anything more crosses only on the owner's say-so.
- **SP10.** The feature log keeps one leaf per product area, each a State today paragraph followed
  by dated entries of two to four sentences, newest first, under ISO-week headers.
- **SP11.** The list of feature-log areas belongs to the owner; an entry that fits no area is
  raised, never an area invented.
- **SP12.** A change earns a feature-log entry only if something became true of the product; a
  documentation-only change earns none.
- **SP13.** The status page of active work lives in the private journal, and the root instruction
  carries only a static pointer to it.
- **SP14.** The private repository runs on one trunk, with one commit per filing action, history
  never rewritten, a tag per landing, and a remote kept only as a backup that is never
  force-pushed.
- **SP15.** A plan, kickoff or appendix lives with the product the work is most about; a
  pull-request body lives with the repository whose pull request it describes; and a mirror's
  pull-request index says where the counterpart body of the same work lives.
- **SP16.** The constitution's private mirror holds only the records of changes to the governing
  process, which change rarely; the tree's day-to-day records live with its own project.
