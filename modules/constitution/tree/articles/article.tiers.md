# The tiers: provenance, current law, generated, and how records are named

_source:_ history/rulings/rulings.tiers-and-records.md TR1–TR9, TR14–TR17; history/rulings/rulings.shared-and-private.md SP15–SP16; history/rulings/rulings.commits-and-pull-requests.md CP8–CP11
_reviewed:_ 2026-11-02

A branch's tier says who may write in it and how. Three kinds exist in every tree, keyed by path
(TR1): provenance records added once and never edited, current law edited as the truth moves,
and generated output that only its generator writes. The instructions are
[common/rules/provenance-tiers.md](../../common/rules/provenance-tiers.md) and
[common/rules/design-tier.md](../../common/rules/design-tier.md); this article holds the reasoning and what
those rules do not cover.

## Provenance: added verbatim, never edited

| Tier | Tree | Holds |
| --- | --- | --- |
| `public/**/history/` | public | a product's enacted rulings |
| `constitution/history/` | constitution | the tree's enacted rulings about itself |
| `private/**/plans/`, `kickoffs/` | private | plans by month; the prompts that launched them |
| `private/**/prs/`, `appendices/` | private | pull-request bodies; the audit tables behind them |
| `private/journal/retros/` | private | retrospectives, by month of the run |

- A record is added by copying it in verbatim, with its manifest row in the same action; its
  body is never edited, and only the row may be corrected (TR2).
- Where the agent harness can refuse a write before it happens, the pre-write guard an adapter
  provides refuses edits under these paths. It has one named override, for a deliberate
  exception that the commit using it states. Where no guard exists, the linter and review catch
  the violation after the fact; no data is lost, only the moment of the catch (TR3).
- A plan is editable until its row's "Landed as" is filled; a kickoff leaf is append-only,
  because agents were launched from its earlier prompts verbatim; a retrospective is corrected
  by a later one (TR4). A pull-request body is amended in place while its pull request is open,
  and freezes when the landing stamps it (CP11).

Records are cited by filename and id from commits, contracts and current law, and the
distillation into current law depends on none of them changing under it. So **corrections go
forward** (TR5): wrong landed content is corrected in current law, citing what corrects it,
never in the record. A decision found in a private record is lifted verbatim into a rulings leaf
and cited from there (TR6).

## Current law: `design/` and `articles/`

A product's current law is its `design/` tier; the constitution's is `articles/`, the same tier
under its constitutional name. In both:

- one subject per leaf, at most about 120 lines, promoted past that;
- provenance under the H1: `_source:_` naming the rulings and ids it rests on, superseded ones
  listed too, and `_reviewed:_`, the date someone last confirmed it against its law (TR7). A
  source is a rulings leaf of a committed tree, or an open bill; never a private path;
- when it contradicts `history/`, the leaf wins and says what it supersedes and why. Silent
  divergence is a defect (TR8);
- a superseded leaf is archived, never deleted.

## Generated

A generated tier has one writer and is never edited by hand. Its contract is
[generated tiers](./article.generated-tiers.md).

## How the records are named

The forms are the rule's (`plan.<YYYY-MM>-<n>.<product>-<slug>.md`,
`kickoffs.<YYYY-MM>-<n>.<slug>.md`, `pr.<YYYY-MM>-<n>.<branch-slug>.md`). What it leaves out:

- **The counter** is one per month across every product, in filing order, repeated in the H1
  and spoken as `<month>-<n>`. Work with no plan, such as a hotfix or a rider that outgrew its
  plan, takes the next counter of its month: a plan of one row (TR14).
- **An operational record** that belongs to a plan's work (the bill its round filed, the
  enactment, the landing's filings) reuses that plan's counter with a role suffix:
  `pr.<YYYY-MM>-<n>.<slug>-enactment.md`, `-bill`, `-landing`. One that belongs to no plan takes
  the next counter (TR15). Every pull request has a body, an operational one short (CP8).
- **An appendix** is named by its form first: `closeout.<YYYY-MM>-<n>.<slug>.md`,
  `review.<YYYY-MM>-<n>.<slug>.md`; never with the body's `pr.` prefix (TR17).
- **Forward only**: records filed before a naming form keep their names (TR16).

## Where each record lives

- A plan, a kickoff or an appendix lives with the product the work is most about, even when the
  pull request that carried it was raised against another repository (SP15).
- A pull-request body lives with the repository whose pull request it describes, in that
  repository's mirror: the place a reader opens for that project. It is an impersonal record
  of what the change achieves, its first line naming the branch (CP9, CP10). Where one piece of work raised
  pull requests in two repositories, each mirror's `prs/` index says where the other body is.
- The constitution's mirror holds only the records of changes to the governing process; the
  tree's day-to-day work files under its own project's mirror (SP16).
- The journal keeps what spans products by nature: entries, epics, ledgers, retrospectives and
  reflections ([the work journal](./article.work-journal.md)).
