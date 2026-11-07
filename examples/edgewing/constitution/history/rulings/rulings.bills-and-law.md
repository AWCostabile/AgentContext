# Seed rulings: bills and law

_status:_ adopted 2026-11-04

How law is proposed, built from, corrected, enacted or withdrawn, and how the files that enforce
it stay bound to it. The articles on [the constitution](../../articles/article.constitution.md)
and [bills and laws](../../articles/article.bills-and-laws.md) rest on these.

- **BL1.** Law has three tiers: bills, prospective and editable; rulings, enacted and immutable;
  and current law distilled from them, the articles for the tree and the design leaves for a
  product.
- **BL2.** A ruling made in a scoping conversation is filed as a bill, not as law; the kickoff
  cites the bill and the work is built from it.
- **BL3.** A bill is amended in place: a clause the build proves wrong, impossible or miscounted is
  corrected where it stands, with a dated amendment line beneath it, and no addendum record is
  filed.
- **BL4.** Every bill ends with a "Not ruled" list of the questions its round saw and left open,
  so a later reader can tell an unruled gap from a settled default.
- **BL5.** Only the owner enacts a bill: at the walkthrough of a build, or at the pull-request
  review of a documentation-only change; no session enacts one alone.
- **BL6.** Enactment is one action and one commit: the bill's status set, the bill copied verbatim
  into the rulings with its H1 and ids unchanged, its manifest row added, every dependant
  re-sourced, and the linter at zero failures.
- **BL7.** Current law cites enacted law, or an open bill marked as pending enactment, and never
  an enacted or withdrawn bill.
- **BL8.** A bill is named `bill.<YYYY-MM>-<n>.<slug>.md` after its plan and enacted as
  `rulings.<slug>.md`; its index row carries Plan, Created, Status and Enacted as.
- **BL9.** Law runs forward only: rulings already enacted stay law, and no bill is reconstructed
  for them.
- **BL10.** Every count stated in a bill or an immutable record is measured first, or omitted.
- **BL11.** A bill that fails is withdrawn with a dated reason; nothing is copied into the
  rulings, and any leaf that cited it is re-sourced or archived.
- **BL12.** A bill is not stale by age; it is overdue when its plan has landed and its status still
  reads bill.
- **BL13.** Every operative file cites the article it implements, and every article cites the
  ruling or open bill it rests on, so an instruction can be traced to its law.
- **BL14.** A change to the constitution is a bill that also names the operative files it will
  change, and the constitution amends itself the same way, with no special case.
- **BL15.** An operative rule edited with no bill behind it is a quiet amendment: a smell, fixed by
  a bill or a revert and never by a matching edit to the article.
- **BL16.** A default an orchestrator took is recorded as a default taken and becomes law only
  once the owner has said yes to it; silence is not a ruling.
- **BL17.** A clause that states a mechanism is marked "verify first" and names the spike that
  proves it; a clause that names positions, keys or sections rests on a read-only derivation
  spike whose output is pasted into the bill.
- **BL18.** A reflection proposes and a retrospective disposes: every proposal in the window is
  taken up, deferred or declined, and the retrospective's recommendations become bill clauses
  or declined rows at the next scoping conversation.
