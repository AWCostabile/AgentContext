# How AgentContext works

The method behind the template, in full. The README is the short version; this is the deep dive, section by section, for anyone deciding whether the method fits their organisation or wanting to understand an instance they have been handed.

## The problem it solves

Every new agent session and every new hire starts cold. The knowledge they need is scattered across chat logs, old pull requests and one person's head, so they guess, or someone spends an afternoon explaining it again. Pasting everything into a giant instruction file does not help: it costs tokens on every prompt, it goes stale, and nobody can tell which paragraph still holds.

This method gives everyone one knowledgebase to align to from the first prompt, at low token cost. A reader opens a short root file, descends a few small indexes, and reads only the one or two leaves that answer the question. A decision made in March is still findable in November, along with what replaced it.

## Two trees

An instance has two trees with different audiences.

- **`public/` is what is true.** Your products, how they work, what was decided, what the company is. It is committed to the instance repository and everyone on the team reads it.
- **`private/` is how the work was run.** Plans, kickoff prompts, pull-request bodies, retros, the journal of what is in flux. It belongs to one machine: a nested git repository of its own, sitting inside the instance, which the parent repository ignores wholly.

A fresh clone has no `private/`, and that is normal. A teammate can read all of `public/` and never meet a broken link.

## The branch grammar

The tree is recursive. Every directory, at any depth and in both trees, is a **branch** made of:

- one `.index.md`: a heading, up to about five lines of context, and a `## Contents` table with one row per child;
- one `.tags`: three to six lowercase search tags, one per line, in the words a searcher would use;
- single-topic **leaves**: plain Markdown files, each about one thing.

For example:

```
public/products/Invoicer/design/
  .index.md          "Invoicer design", then a Contents table
  .tags              invoicer, design, how-it-works
  design.billing.md  one subject, about 120 lines at most
```

Two habits keep this cheap:

- **Reading means descending.** Start at the root file and follow `.index.md` files down. When you do not know where something lives, resolve its tags with the search tool rather than crawling directories.
- **Writing is one action.** A leaf, its Contents row and any new tags land together, in the deepest branch that fits. A leaf with no row cannot be found; a row with no leaf is a lie.

The grammar is written out as plain documents an instance carries under `rules/`, and `HYGIENE.md` lists every check the linter makes against it.

## The tiers

A branch's tier says who may write in it and how.

**Provenance** is added verbatim and never edited. The record of what happened stays exactly as it happened, so that anything citing it can rely on it.

**Current law** is edited as the truth moves. It is the present-tense answer, and it wins when it disagrees with an older record, saying what it supersedes and why.

**Generated** output is written only by its generator. A code map, say, is regenerated when the change that moved its source lands, and never patched by hand.

Two public branches of every product show the first two apart:

- `history/` holds **rulings**: the decisions as they were made, in the words they were made in. "Refunds are issued to the original payment method, never as credit." That sentence is provenance. If you change your mind, you add a new ruling; you do not edit the old one.
- `design/` holds **current law**: one leaf per subsystem saying how it works today, naming the rulings it rests on. A new teammate reads `design/`; `history/` is there to answer "why".

Corrections go forward. When a landed record turns out wrong, the fix goes in current law, never in the record. Leaves are never deleted or moved either: a retired leaf is marked archived, so anything pointing at it still resolves.

## Links run one way

Private leaves may link into `public/` freely. Nothing under `public/` may link to, or cite the path of, a private record, because it would resolve on exactly one machine. The linter fails a public leaf that does.

There is one sanctioned crossing. **What a change achieved crosses into the feature log; how it was run never does.** Each product has a `features/` branch, one leaf per area, opening with a **State today** paragraph and followed by dated entries. An entry says what is now true of the product:

> **2026-03-04** — Invoices can be split across two payment methods. See the billing design leaf.

It never mentions the plan, the sprint or who asked. So `public/` stays a reflection of what is, and the feature log is the way in: to learn the state of a product, start there and follow its links. The one citable trace of delivery is a merged pull request, or the heading it leaves in a generated change log.

## The private mirror

`private/` repeats the product branches of `public/` under the same paths, and adds a journal. Its layout is deliberately flat:

```
private/
  products/Invoicer/
    plans/        implementation briefs
    kickoffs/     the prompts that launched them
    prs/          one record per pull request
    appendices/   the audit tables behind those records
  journal/
    latest.md     what is in flux, last landed, next open
    entries/  epics/  ledgers/  retros/  reflections/
```

`plans/`, `kickoffs/`, `prs/`, `appendices/` and `journal/retros/` are the immutable tiers of the private tree. Records in them group by month (`2026-03/`). `latest.md` is rewritten as work moves, and a session reads it before anything else. The repository runs on one trunk, with one commit per filing action, and is pushed to a private remote as a backup if one exists.

## Catalogs

You choose the top-level buckets of your catalog. Set them in `.conf`:

```
CATALOGS="products projects"
```

A software shop might use `apps sites`; a consultancy might use `clients`. Each entry becomes a branch of `public/` and of `private/`. Tools read the names from `.conf` and never spell them.

## What an instance tells an agent

`AGENTS.md` at an instance's root is the one instruction every agent session reads first: read `.conf`, read the journal's status page if this machine has one, descend indexes and never crawl, resolve tags with the search tool, obey a branch's standing orders, route a new document by its kind, write a leaf with its row and its tags as one action, and the laws above. It stays short because the law lives in `rules/` and the checks in `HYGIENE.md`. The core never names an agent harness; an adapter adds what one harness can enforce.

## Deploying and updating

`init.sh`, at the root of a release, is the one deployer and the one unpack. Given a target directory and a `.conf`, it copies the skeleton, resolves every placeholder from your catalogs and your details, runs `git init` inside the private mirror, writes the workspace file and the editor settings, and records a manifest. It is bash, because the agent that runs it has bash wherever it runs. `--adapter <name>` lays one adapter's payload onto the tree; with no flag it lays down the neutral core and prints the list of adapters, never picking one. `SETUP.md` is the run-sheet an agent follows to do all of this: one command and one check per step, and the questions to ask first.

The manifest, `.agentcontext` at the instance root, is what makes updates safe. It names the release installed and hashes every core file: the scripts, the rules, the templates, the editor settings, the instruction and the hygiene document. `init.sh --update --ref <tag>` fetches a later release and, file by file, replaces what you never edited, keeps what you did and tells you so, adds what is new, and reports what the release dropped. It never touches `public/`, `private/`, `.conf` or the workspace file.

## Adapters

The core is plain Markdown and works with any tool that can read a file. Its entry point is `AGENTS.md`, and it never refers to an adapter. An adapter adds what one particular agent harness can enforce on top of it: a guard that refuses a write into an immutable tier, a lint after every write, orientation at session start, the detection of a kickoff prompt, skills and agent profiles.

Adapters are keyed by harness, not by model. Each one lives in `adapters/<harness>/` as a README and a `payload/`, and the payload is copied verbatim into your instance.

- **Claude Code** is the one written adapter.
- **Codex**, **Cursor** and **Gemini CLI** are stubs. Each doubles as a porting spec, listing what a port has to reproduce.

The core works without any adapter. The linter and convention replace pre-write enforcement: a tier violation is caught at lint time rather than at write time, and search and filing are run by hand. No data is lost.

## Modules

`modules/` holds optional additions, adopted or deleted per instance.

**The constitution** is the tree's law about itself, as starting law you adopt or delete. It carries a seed set of generic rulings (how a tree is structured, what is immutable, how the private and shared trees relate, how a decision becomes law, how a piece of agent-led work is briefed, run and closed, what hygiene means, how commits and pull requests are shaped, how delegated agents are budgeted), the articles that distil them into current law, and the process half: a kickoff guide, ground rules for the orchestrating session, the delegated agent and the close-out, and a code-standards template. Adopting it is one copy, `modules/constitution/tree/` to `<instance>/constitution/`; from then on a change to the process is a bill first, and the owner enacts it.

**The codebase module** reads a product's repository with one command and writes a generated code map under the product's branch (its areas, the surfaces it exposes and one symbols leaf per area, every location a `path:line`), with a `--check` that reports drift. It is never hand-edited, only regenerated when the change that moved the source lands, and it needs Python 3.10 or later. Extractors are keyed by language; TypeScript and Go ship.

**The change-log module** is a GitHub Actions workflow that rewrites every merged pull request into one squash commit, a bubble merge and an entry in `CHANGE_LOG.md` built from the pull request's title and its commit subjects. It is the reason commit subjects take one of seven prefixes and read as product updates, and it is what makes a merged pull request citable from the tree. This repository runs the same workflow on itself.

**The graphify module** keeps one [Graphify](https://github.com/Graphify-Labs/graphify) knowledge graph per repository in a generated `graphs/` tier at the instance root, so an agent asks the graph who calls what before it greps. The graph lives in the tree, not in the repository it describes: the repository's `graphify-out/` is a link (a directory junction on Windows, a symlink elsewhere) into the tree's git-ignored working layer, so graphify's own commit hooks rebuild there without dirtying the tree, and one script rebuilds every graph offline, from scratch, and commits one snapshot per repository. The repositories are named in `.conf`, a version pin makes the graphs reproducible across machines, and `check` reports a stale snapshot or a drifted index.

**The context-retention module** gives every project in the workspace a per-clone identity, `.agents/.id.meta`: an id, a name and a date, never a path, and never committed, because committing it would hand one user's identity to every clone. Two concerns meet in it. A project can move: people rename and move folders, and an agent harness that files a project's memory and history under its path then treats the folder as a stranger; the module keeps a map in the user's home and reports a move, and an adapter turns the report into its harness's repair. And a session should open with its own instruction: the instance's `AGENTS.md` asks the agent to read a sibling project's identity and instruction the first time it touches that project, not at start, so a repository the session never enters costs it nothing; an adapter enforces that where its harness allows.

## The worked example

`examples/quillfeather/` is a small fictional startup's filled tree, deployed by the deployer and then filled by hand, so that you can see what the indexes look like with something in them: start at [its reader page](./examples/quillfeather/README.md). Its two products carry generated code maps, made by the codebase module from the two fictional source repositories beside it, `examples/tillwright/` and `examples/spinecard/`.

## How this repository checks itself

`tools/deploy-smoke.sh` deploys a throwaway instance from the committed tree, lints it, updates it and proves the refusals, lays an adapter down and boots it headless, lints every example and regenerates every code map with a drift check, and proves the change-log module's file is the workflow this repository runs. `bash scripts/cure.sh --root template` and `bash scripts/smell.sh --root template` lint the skeleton itself. Nothing in the repository names a real organisation, product, place or person; the examples are invented.
