<!--
  _article:_ constitution/articles/article.bills-and-laws.md, constitution/articles/article.branch-grammar.md
  Bills-branch template: copy as the `.index.md` of a `bills/` branch (beside a `.tags`
  from `common/templates/branch/.tags`), replace every `{{ }}` and remove this comment. The
  Contents carries the five bill columns; rows are newest first, and an enacted or
  withdrawn bill keeps its row, "Enacted as" filled.
-->

# Bills

Prospective law for {{tree — the constitution, or the product's name}}, one bill per plan, named by the plan numbering (`bill.<YYYY-MM>-<n>.<slug>.md`)
and filed before the work starts. A bill is citable and buildable from the kickoff on and EDITABLE:
a clause the build proves wrong is corrected in place with a dated amendment line. The owner enacts
it — copied verbatim into `history/rulings/` as `rulings.<slug>.md`, the bill's status pointing at
the law, {{the articles | the design tier}} updated in the same action — or it is withdrawn. Rows newest first.

## Contents

| File | Plan | Created | Status | Enacted as |
| ---- | ---- | ------- | ------ | ---------- |
| [Bill {{MM}}-{{n}} — {{title}}](./bill.{{YYYY-MM}}-{{n}}.{{slug}}.md) | Plan {{MM}}-{{n}} | {{YYYY-MM-DD}} | bill | — |
