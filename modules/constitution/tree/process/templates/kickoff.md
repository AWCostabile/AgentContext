<!--
  _article:_ constitution/articles/article.wave-ground-rules.md
  Kickoff template: the paste-ready first prompt of an orchestrated wave. The first two lines
  are fixed: an adapter may detect the first and load the orchestrator's ground rules; the
  second points at them for a session where nothing does. The ground rules carry every
  invariant, so write here ONLY what is particular to the wave (constitution/process/
  kickoff-guide.md says what each line holds). Replace every `{{ }}`, drop the guidance
  comments and this header. Role words: "the owner", "agents". Gates carry real numbers read
  from the repositories when the kickoff is written, each phrased as a proof of what it cares
  about, never as a command's spelling. A model or effort recommendation goes in the sentence
  after the fenced prompt, never inside it. A fictional example follows the template.
-->

Mode: orchestrated
Ground rules: constitution/process/ground-rules.orchestrator.md (read before anything else)
Wave: {{wave name}} ({{gated on … | not gated}})
Brief: {{the <Product> mirror's plans/<YYYY-MM>/plan.<YYYY-MM>-<n>.<product>-<slug>.md (section)}} @ {{the brief's private commit}}
Bill: {{bill path (ids in play)}}
Repo: {{repository the work happens in}} (branch {{name}} off {{main | the earlier wave's squash}}); {{read-only repositories}}
Walkthrough: {{required — at <moment> | not required — <reason>}}
Hard-rule overrides:
- {{the wave's own law only: declared format changes, expected version bumps, out of scope}}
Gates (report before any write):
1. main clean at or past {{commit}}; {{pins read from source, with their values}}
2. {{the shapes the wave builds on, as they exist today}}
3. {{baseline: the battery green on main; anything to capture before the first change}}
<!-- every clause the bill marks "verify first" becomes a gate naming the spike that proves it -->
Read (in order): {{sections, not whole documents, beyond the repository's instruction file}}
Scope: {{0 gates → 1 … → 2 … → n proof}}
Settle with the owner: {{the questions that stop; defaults taken otherwise}}
Close-out specifics: {{proof artifacts to name; expected ledger rows; documents to update}}

<!-- Example: a fictional invoicing product, a mid-sized feature wave. -->

```
Mode: orchestrated
Ground rules: constitution/process/ground-rules.orchestrator.md (read before anything else)
Wave: split payments (not gated)
Brief: the Invoicer mirror's plans/2026-03/plan.2026-03-2.invoicer-split-payments.md (Scope) @ 4e1c9a0
Bill: public/products/Invoicer/bills/bill.2026-03-2.split-payments.md (SPLIT1–SPLIT6)
Repo: invoicer (branch feature/SplitPayments off main); billing-gateway read-only
Walkthrough: required — after the proof phase: one invoice split across two methods, then refunded
Hard-rule overrides:
- The stored invoice format gains a payments list; the export schema's version moves from 4 to 5.
- Out of scope: partial refunds across methods (named in the bill's Not ruled list).
Gates (report before any write):
1. main clean at or past 9b2f310; export schema version 4 in src/export/schema.ts
2. Invoice.payment is a single method today; the refund path reads it in src/refunds/refund.ts
3. The test battery green on main, 212 tests; capture the three golden export files before the first change
Read (in order): the bill; design/design.billing.md "Payment methods"; the brief's Scope section
Scope: 0 gates → 1 the payments list in the model → 2 the refund path → 3 the export at version 5 → 4 proof
Settle with the owner: rounding of an uneven split; defaults taken otherwise
Close-out specifics: name the golden-file comparison in the body; one ledger row expected for billing-gateway
```
