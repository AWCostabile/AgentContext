# Provenance tiers

_applies to:_ `public/**/history/`; in the private tree `plans/`, `kickoffs/`, `prs/`,
`appendices/` and `journal/retros/`

These branches hold records added verbatim. They are immutable, in both trees, by path:

| Tier | Tree | Holds |
| ---- | ---- | ----- |
| `public/**/history/` | public | rulings: the decisions as they were made |
| `private/**/plans/` | private mirror | implementation briefs, grouped by month |
| `private/**/kickoffs/` | private mirror | the prompts that launched them; append-only |
| `private/**/prs/` | private mirror | one record per pull request: how a change was delivered |
| `private/**/appendices/` | private mirror | the audit tables behind a PR body |
| `private/journal/retros/` | private journal | retrospectives, grouped by the month of the run |

- Never edit a record's body. Only ADD a record (copy it verbatim, add its manifest row in the
  same action) or correct a manifest row.
- The two bodies that are not yet records: a plan whose manifest row's "Landed as" is `—` is
  editable until it lands; a PR body whose `_landed as:_` line reads `—` is amended in place to
  stay true to its branch while the pull request is open. The landing freezes both.
- A kickoff leaf is append-only: a later prompt goes below the last; an earlier one is never
  rewritten.
- Name a PR body with its plan's number and its branch: `pr.<YYYY-MM>-<n>.<branch-slug>.md`,
  the branch name with its type prefix dropped and its PascalCase kebabbed, opening with
  `_branch:_ <type>/<Name>` under the H1. Keep `prs/` for bodies only; an audit table that backs
  a body is an appendix, `appendices/<YYYY-MM>/<form>.<YYYY-MM>-<n>.<slug>.md`, opening with
  the body it accompanies.
- File every record of a plan under the plan's month (its Created date), not the month the pull
  request was raised. A piece of work with no plan takes the next counter of its month.
- Never edit a filed retro; a later retro corrects it.
- Correct landed content forward: write a `design/` leaf citing the ruling it rests on; never
  edit the source record.
- A decision found inside a private record is lifted verbatim into a public rulings leaf and
  cited from there; the private path is never cited.
- Write a PR body as an impersonal codebase record: what the change achieves, brief design whys
  welcome; no personal names, no first person, no references to plans or rulings, no vocabulary
  of how the work was scheduled. File one for every pull request before it is raised, in the
  mirror of the repository it is raised against, with its feature-log entry drafted in the
  journal entry beside it.
