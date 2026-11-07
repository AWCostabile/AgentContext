<!--
  _article:_ constitution/articles/article.bills-and-laws.md, constitution/articles/article.branch-grammar.md
  Bill template: the prospective law of ONE plan, filed in a scoping conversation as its
  rulings are made — `constitution/bills/` for the tree's own law, `public/<catalog>/<Product>/bills/`
  for a product's — and named after the plan it carries, `bill.<YYYY-MM>-<n>.<slug>.md`.
  While its status reads `bill` it is edited IN PLACE: a clause the build proves wrong is
  corrected where it stands with a dated `_amended <YYYY-MM-DD>:_` line beneath it, never
  by a new leaf. The owner enacts it (copied verbatim into the tree's `history/rulings/` as
  `rulings.<slug>.md`, the status becoming `enacted → <law path>`) or it is withdrawn.
  A clause that states a mechanism is marked **verify first**. Replace every `{{ }}`,
  repeat the id prefix as each section's heading, and remove this comment.
-->

# Bill {{MM}}-{{n}} — {{title}}

_status:_ bill · _plan:_ Plan {{MM}}-{{n}} · _proposed:_ {{YYYY-MM-DD}} by the owner in a scoping
conversation · _enacted as:_ — ({{when it is enacted: at the walkthrough, or at the pull-request review of a docs-only wave}})

{{One paragraph: the owner's purpose, in their words where they gave them, and what the bill
proposes.}}

## {{PFX}} — {{section title}}

- **{{PFX}}1.** {{One clause per bullet: what is now law once enacted.}}
- **{{PFX}}2.** {{A clause that states a mechanism ends **verify first**, and the plan names the spike that proves it.}}

## Not ruled

- {{A question the round saw and left open, so a later session can tell an unruled gap from a settled default.}}
