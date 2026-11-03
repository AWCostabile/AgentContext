# The constitution module

Starting law about how a knowledge tree governs itself. The core ships the grammar and the tier rules as plain instructions (`common/rules/`, `common/HYGIENE.md`, `AGENTS.md`) and works without this module. The module adds what the core leaves unwritten: why those rules hold, how they change, and how a piece of agent-run work is briefed, launched and closed.

## What it holds

`tree/` is what an instance receives at `constitution/`, a third tree beside `public/` and `private/`, in the same branch grammar:

- **Law in three tiers.** `bills/` is prospective law, empty until the first bill is filed. `history/rulings/` is enacted law: eight leaves of seed rulings, one per theme, about 130 in all, each a short sentence with a stable id. `articles/` is current law: eleven articles, one per subject, each citing the seed rulings it rests on.
- **The process half.** `process/` holds a kickoff guide, the ground rules for each reader of an orchestrated wave (the orchestrating session, every delegated agent, and the orchestrating session at the close), a template for a product's code standards, and a kickoff template.

The seed rulings are written for no particular organisation: they are a reasonable default, drawn from practice, that you are expected to edit. No file in the module names an agent harness; where an article needs enforcement a harness may provide, it says "the pre-write guard an adapter provides", and states what holds without one.

## Adopting it

1. From a release, run `bash init.sh --adopt constitution --target <instance>`: it lays `tree/` at `<instance>/constitution/` and records the module in the instance's manifest, so an update replaces a seed still exactly as shipped and keeps every leaf you have changed.
2. Read `constitution/articles/article.constitution.md` first, then the seed rulings.
3. Keep what applies; delete what does not. Delete a whole rulings leaf, a single ruling, or an article whose rulings you dropped, and remove its Contents row in the same action. Amend a ruling's wording or a default number (caps, budgets, round limits) to what you will hold.
4. Change each kept rulings leaf's `_status:_ seed — adopt, amend or delete` line to `_status:_ adopted YYYY-MM-DD`, and fill its manifest row's Created with the same date. The status line is what freezes a leaf: a pre-write guard that refuses edits under `constitution/history/` lets a leaf through while its first lines still read `_status:_ seed`, so prune and amend before you change the line, never after. Articles carry no status line: they stay current law and are edited as the law moves.
5. Add a row for `constitution/.index.md` to the index table of the instance's root `AGENTS.md`. That file is tracked by the template's updater, which will report the edit as local and keep it.
6. Run `bash common/scripts/cure.sh`. The linter does not walk `constitution/`, so also check that every relative link in it resolves; the articles link out to `common/rules/`, `common/HYGIENE.md` and `AGENTS.md` as they sit at the instance root.

Adoption is the one moment the rulings are edited. From then on they are immutable, and every change to the process is a bill first: filed in `constitution/bills/`, amended in place while the work proves it, enacted by the owner as a new rulings leaf, and distilled into the articles in the same action.

## Not adopting it

Delete this directory. Nothing in the core refers to it, and the core's `common/rules/` and `common/HYGIENE.md` stay the whole of the instance's law.
