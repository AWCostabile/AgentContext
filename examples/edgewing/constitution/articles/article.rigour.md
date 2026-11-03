# Rigour: the code standard, the baseline sweep, and the review loop

_source:_ history/rulings/rulings.hygiene-and-gates.md HG14–HG20; history/rulings/rulings.commits-and-pull-requests.md CP5; bills/bill.2026-11-2.delegated-agents.md DA9 (bill — pending enactment); history/rulings/rulings.tiers-and-records.md TR17
_reviewed:_ 2026-11-04

A product's shipped source can be held to a written standard: a rule catalog per product, one
full sweep that grounds it, a linter built from what the sweep proved, and an adversarial review
of every orchestrated branch before its pull request is raised. This article says where each
part lives, the shape it takes, and how the review loop runs. A product adopts as much of it as
it needs; its code standards, a `design.code-standards.md` leaf in its design tier, are where a product
records what it adopted.

## The two homes

- **The catalog is current law** (HG14) and lives in a `rigour/` branch beside the product's
  `design/`: `public/<catalog>/<Product>/rigour/`, made from `common/templates/branch`, each leaf from
  `common/templates/branch/rule.md`. A leaf may hold several rules, grouped by the area or the bug
  class they guard.
- **What a sweep or a review found is a record of the work** and lives in the private mirror at
  the same relative path: the findings ledger, each row **open**, **fixed**, **cleared** (a false
  positive, with the reason) or **declined** (with the owner's reason).

## The rule shape

Every rule carries an id, unique within the catalog and never reused; the rule in one sentence;
its source (the design leaf or repository instruction it enforces); its detection (a pattern, a
structural check, or judgement); its tier; the shapes its false positives plausibly take; and the
form a dismissal takes (HG15). The false-positive shapes are written into the rule so an agent
triaging a hit reads them instead of re-deriving them.

## Three tiers

- **hard**: a script alone decides and a hit blocks. Only for rules with essentially no false
  positives.
- **suspect**: the default. A script flags the line; an agent reads the hit in context with the
  rule's false-positive notes and confirms or clears it. Triage reads flagged lines, not files,
  which is where the saving is.
- **judgement**: no pattern finds it (error handling on untrusted input, resource lifecycle,
  drift from a design leaf); only a reading agent can (HG15).

## Exemptions live in the code

A line that legitimately breaks a rule says why beside it, in the language's own comment syntax:
`allow <rule-id>: <reason>`. An exemption without a reason is itself a finding (HG16). An idiom
the product already uses to say the same thing is named in the rule's false-positive notes and
accepted until the product's linter decides whether to convert it.

## One baseline sweep, then the linter

- **One full read of the shipped source comes before the linter** (HG17): reviewers over shards
  grouped by subsystem, each holding its files, the matching design leaves, the catalog and the
  product's ranked checklist of bug classes; every finding then checked by an agent told to
  disprove it; survivors clustered by root cause. Each confirmed finding maps to an existing rule
  or proposes a new one, its false-positive notes drawn from what the disprovers cleared. The
  sweep yields the first findings ledger and the next catalog version. It repeats only when a
  retrospective finds the catalog missing too much.
- **The checklist is ranked per product**, in the catalog's index. A typical order: crashes on
  untrusted input, then concurrency and state corruption, then resource lifecycle, then drift
  from the design leaves, then maintainability. Style is never on it.
- **The linter is built from evidence** (HG18): it implements the hard and suspect rules the
  sweep showed recur, not the ones someone expected to matter. It lives in the product
  repository beside its other gates and keeps a baseline file of known debt: a new violation
  blocks, and the baseline burns down.

## The reviewing agent

A reviewing agent judges a branch's diff before its pull request (HG19). Its stance: a change
must justify itself, and silence is a valid result. It asks three questions of every change: is
it justified (does it trace to a ruling, a plan row, a bug or a failing test); could it reuse
something that already exists; is it the second copy of something that should now be shared. A
reuse claim names the existing symbol as `path:line`; no citation, no finding. Findings are
graded **blocking** or **consider**, ranked, and capped at five by default; style a linter or
formatter owns is never commented on. Its profile is an operative file and cites this article
(DA9).

## The loop

The review runs after the close-out (proof run, pull-request body written, the walkthrough and
the close-out check done) and before the owner raises the pull request (HG20):

- The orchestrator answers every blocking finding: accepted, with a rider that addresses it, or
  declined, with a one-line reason. It is not bound to obey the reviewer.
- A later round reviews only the rider's diff and the findings still open, and sees the
  orchestrator's reasons; accepted code is not re-litigated.
- The loop ends when a round returns nothing blocking, and never runs more than
  `ORCH_REVIEW_ROUNDS` rounds. At the cap, open findings are filed beside the pull-request body
  for the owner, the final arbiter.
- Consider findings go to the owner and never start a rider of their own. One may be fixed
  inside a rider already running for a blocking finding when the appendix states the exception.
- Rider commits describe the fix, never the review round (CP5).
- The report and the answers are an appendix, `review.<YYYY-MM>-<n>.<branch-slug>.md` (TR17).

## The `ORCH_` settings

Orchestration settings share the `.conf` prefix `ORCH_` (DA9). `ORCH_BUDGET` is in the core's
`common/.conf.example`. An instance that adopts the review loop adds `ORCH_REVIEW_ROUNDS`: default `2`,
and `0` disables the loop. Later loop settings, such as the finding cap, join the same prefix.
