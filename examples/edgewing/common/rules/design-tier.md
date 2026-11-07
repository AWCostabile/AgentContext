# The design tier

_applies to:_ `public/**/design/`

A `design/` leaf is current law: the present-tense answer to "how does this work" and "what was
decided".

- One subject per leaf, at most about 120 lines; promote past that (branch grammar).
- Provenance sits directly under the H1: `_source:_ <rulings path> <ids> <date>`, every
  superseded ruling listed too, and `_reviewed:_ YYYY-MM-DD`. Cite a rulings leaf; never a
  private path. A decision found only inside a private record is lifted verbatim into
  `history/` first and cited from there.
- When the leaf contradicts `history/`, the leaf wins. It says what it supersedes and why.
- Archive a superseded leaf, never delete it: `_status:_ archived YYYY-MM-DD — superseded by
  <successor leaf>` under the H1, ` _(archived)_` on its Contents row.
- Corrections to landed provenance are filed here, never back into `history/` or a landed plan.
- A leaf nobody has re-checked in ninety days is re-verified against `history/` and its
  `_reviewed:_` date bumped, or archived. The smell linter counts the days.
