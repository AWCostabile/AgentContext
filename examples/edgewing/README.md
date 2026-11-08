# Edgewing: the edge of the template

Edgewing is an invented two-person company that makes software for volunteer-run gliding clubs:
Winchbook, the tablet at the launch point that keeps the queue of gliders waiting for the winch
or the tug and writes each flight into the day's log. This directory is its knowledge tree, as it
might look on the day it was set up, with everything the template lets an instance carry laid
and in use: the Claude Code adapter, every module the deployer adopts into an instance, a
constitution pruned and adopted with its first bill filed, and a code map generated from the
product's own repository. The company, its people, its product, its clubs and its pull requests
are all fictional.

[Quillfeather](../quillfeather/README.md) is the other worked example: larger in content, with no
adapter and no module. Edgewing is smaller in content and shows the edge instead.

This page is for a reader of the template. It is not part of the instance: an agent working in the
tree starts at [AGENTS.md](./AGENTS.md), as it would in yours. The instance's own reader page, the
one the deployer wrote here, was replaced by this one; the manifest still holds its hash, so an
update reports `README.md` as changed locally and keeps this page.

## How it was made

From the template repository's root:

1. A `.conf` was written from `blueprint/common/.conf.example` for the founder, Robin Placeholder
   (they/them), with the one catalog `products` and the lean orchestration budget.
2. `bash init.sh --target examples/edgewing --conf <that .conf> --name Edgewing --adapter claude-code`
3. `bash init.sh --adopt constitution --target examples/edgewing`, then the same with `codebase`,
   `graphify`, `context-retention`, `local` and `linkcheck`. `--adopt change-log` was refused, by
   design: that workflow belongs to a repository, not to the tree.
4. The private tree's own `.git`, which the deployer initialised, was removed and `.gitignore`
   reduced to a comment, so the snapshot commits `private/` and `.conf` as plain files, as
   Quillfeather does.
5. The constitution was pruned, adopted and given its first bill (below), and the instance's
   `AGENTS.md` given the constitution's row, as `SETUP.md` says. By the same sheet, the local branch was
   given its row in `private/.index.md` and `local` added to `PRIVATE_SCOPES`, the open-questions
   ledger copied into the journal, and a `.linkcheckignore` written at the root.
6. The code map was generated from the small invented repository beside this directory,
   [`examples/winchbook/`](../winchbook/README.md), with the repository's own module:
   `python modules/codebase/codebase.py --repo examples/winchbook --into examples/edgewing/public/products/Winchbook/codebase --profile examples/winchbook/codebase.profile.json --write-agent`
7. Everything else under `public/` and `private/` was filled by hand, following the rules the
   instance received: the product from `common/templates/product`, its private mirror from
   `common/templates/product-mirror`, every placeholder replaced.

## What to look at first

1. **The feature log**: [Winchbook: Launching](./public/products/Winchbook/features/features.launching.md)
   and [Flight log](./public/products/Winchbook/features/features.flight-log.md), each a State today
   paragraph and dated entries ending with the merged pull request.
2. **The design leaf they link**: [the launch line and the day's log](./public/products/Winchbook/design/design.launch-line.md),
   and the [ruling](./public/products/Winchbook/history/rulings.launch-line.md) it rests on.
3. **The constitution in use**: the [bill](./constitution/bills/bill.2026-11-2.delegated-agents.md),
   then [the wave ground rules](./constitution/articles/article.wave-ground-rules.md), an article
   citing it as pending enactment, and Winchbook's
   [code standards](./public/products/Winchbook/design/design.code-standards.md).
4. **The state of the work**: [private/journal/latest.md](./private/journal/latest.md), the plan and
   pull-request record it points to, and the journal entry where the next feature-log entry waits,
   drafted, for its merge.
5. **The adapter**: [`.claude/settings.json`](./.claude/settings.json) and the one-line
   [`CLAUDE.md`](./CLAUDE.md) that imports `AGENTS.md`.

Run the tree's own tools from this directory: `bash common/scripts/cure.sh` and
`bash common/scripts/smell.sh` both come back clean, `bash common/scripts/find.sh launch-line`
finds the branches about the queue, and `bash public/scratch-tools/ruling-ids.sh DA` lists the
bill's clauses.

## Each module, as it sits here

- **The Claude Code adapter** is laid at `.claude/` (hooks, agent profiles, skills, output styles,
  the process files) with `CLAUDE.md` at the root, and recorded as `adapter=claude-code` in
  `common/.agentcontext`. A session opened in this directory runs its hooks: the orientation at
  start, the tier guard before a write, the linter after one. A session opened at the template's
  root and reading files here may load this `CLAUDE.md`, and through it this `AGENTS.md`; the
  template's own instruction still governs that session.
- **The constitution** is at [constitution/](./constitution/.index.md). Seven of the eight seed
  rulings leaves are adopted, each `_status:_ adopted 2026-11-04` with its manifest row's Created
  filled; the agents-and-budgets leaf was deleted whole with its row, one ruling (CP12) was struck
  and one (WK10) amended. What the deleted leaf held is proposed again, smaller, as
  [Bill 2026-11-2](./constitution/bills/bill.2026-11-2.delegated-agents.md), and the articles and
  ground rules that rested on it cite the bill as pending enactment. The code-standards form, in
  `process/templates/`, was filled into Winchbook's design tier. `.conf` carries the review loop's
  `ORCH_REVIEW_ROUNDS`. An update reports each of these files as changed locally and keeps them.
  The open-questions ledger was copied from `process/templates/` to
  [private/journal/ledgers/questions.md](./private/journal/ledgers/questions.md), with one
  question open and one answered, and `common/scripts/review.sh` counts it.
- **The codebase module** is at `common/modules/codebase/`, and its output is
  [Winchbook's code base tier](./public/products/Winchbook/codebase/.index.md): a map, the
  surfaces, one symbols leaf per area. The tier's `.agent` names the command that wrote it, run
  from the template repository's root; an instance runs it from its own root with
  `--repo ../winchbook`.
- **The graphify module** is at `common/modules/graphify/`, adopted and not homed: `.conf` names
  no `GRAPHS`, and there is no `graphs/` branch.
- **The context-retention module** is at `common/modules/context-retention/`, adopted and not
  initialised: no folder carries an identity.
- **The local module** is at [private/local/](./private/local/.index.md): its `.agent`, and the
  ideas, memories and plans branches, empty. Its row was added to `private/.index.md` by hand and
  `local` to `PRIVATE_SCOPES` in `.conf`, so search reaches it by default on this machine; the
  linter checks that row and never walks the branch.
- **The linkcheck module** is at `common/modules/linkcheck/`. The tree cites no outside page yet, so
  `bash common/modules/linkcheck/linkcheck.sh` asks nothing and reports 0 dead links;
  [`.linkcheckignore`](./.linkcheckignore) at the root names one prefix, the club's intranet, that
  is never asked.

## What a committed example cannot hold

An instance can carry three things this snapshot leaves out, because each belongs to a repository,
a user or a machine rather than to a tree anyone may clone:

- **The change-log workflow.** It is a GitHub Actions workflow in each repository's own
  `.github/workflows/`, never adopted into a tree; Winchbook's code standards name it as its
  repository's.
- **`.agents/.id.meta`.** The context-retention module's `meta.sh init` writes one per project:
  one user's identity for the folder, never committed.
- **A `graphs/` snapshot.** The graphify module's `graphs.sh home` links a repository's
  `graphify-out/` into the tree through a junction or symlink, and `scan` writes a real graph;
  neither a link into a source repository nor a scan of an invented one belongs in a snapshot.

## The private tree is a snapshot

In a real instance `private/` is a git repository of its own that the instance ignores, and
`.conf` is ignored too. Here both are committed so you can read them; the example's `.gitignore`
says so.
