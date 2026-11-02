# AgentContext

A template for keeping what your organisation knows in one git repository, in a shape that coding
agents and new hires can both read. It ships a method and an empty structure. You clone it, deploy
it once, and fill it with your own products, decisions and designs. It is written for a founder or
a small team, and it is MIT licensed.

## The problem it solves

Every new agent session and every new hire starts cold. The knowledge they need is scattered across
chat logs, old pull requests and one person's head, so they guess, or someone spends an afternoon
explaining it again. Pasting everything into a giant instruction file does not help: it costs tokens
on every prompt, it goes stale, and nobody can tell which paragraph still holds.

This method gives everyone one knowledgebase to align to from the first prompt, at low token cost.
A reader opens a short root file, descends a few small indexes, and reads only the one or two leaves
that answer the question. A decision made in March is still findable in November, along with what
replaced it.

## Getting it

The quickest way is to hand the job to your coding agent. Paste this into it, with your own path
and organisation filled in:

```
Set up a knowledge tree for <organisation> at <path>, from the AgentContext template.
Fetch https://raw.githubusercontent.com/AWCostabile/AgentContext/v0.3.0/SETUP.md and follow it
as a run-sheet: ask me its questions first, then run each step's command and confirm its check
before moving on. If a step refuses, stop and show me what it said.
```

`SETUP.md` is written for exactly that reader: every step is one command and one check, and it
ends with how to pull a later release into your tree without touching what you have filed. To
read the template itself:

```
git clone https://github.com/AWCostabile/AgentContext.git
```

The `template/` directory is the skeleton. It maps onto the root of your deployed copy, which is
called an instance below: `template/public/` becomes `public/` in your instance.

## Two trees

An instance has two trees with different audiences.

- **`public/` is what is true.** Your products, how they work, what was decided, what the company
  is. It is committed to the instance repository and everyone on the team reads it.
- **`private/` is how the work was run.** Plans, kickoff prompts, pull-request bodies, retros, the
  journal of what is in flux. It belongs to one machine: a nested git repository of its own, sitting
  inside the instance, which the parent repository ignores wholly.

A fresh clone has no `private/`, and that is normal. A teammate can read all of `public/` and never
meet a broken link.

## The branch grammar

The tree is recursive. Every directory, at any depth and in both trees, is a **branch** made of:

- one `.index.md`: a heading, up to about five lines of context, and a `## Contents` table with one
  row per child;
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

- **Reading means descending.** Start at the root file and follow `.index.md` files down. When you
  do not know where something lives, resolve its tags with the search tool rather than crawling
  directories.
- **Writing is one action.** A leaf, its Contents row and any new tags land together, in the deepest
  branch that fits. A leaf with no row cannot be found; a row with no leaf is a lie.

## The tiers

A branch's tier says who may write in it and how.

**Provenance** is added verbatim and never edited. The record of what happened stays exactly as it
happened, so that anything citing it can rely on it.

**Current law** is edited as the truth moves. It is the present-tense answer, and it wins when it
disagrees with an older record, saying what it supersedes and why.

Two public branches of every product show the difference:

- `history/` holds **rulings**: the decisions as they were made, in the words they were made in.
  "Refunds are issued to the original payment method, never as credit." That sentence is provenance.
  If you change your mind, you add a new ruling; you do not edit the old one.
- `design/` holds **current law**: one leaf per subsystem saying how it works today, naming the
  rulings it rests on. A new teammate reads `design/`; `history/` is there to answer "why".

Corrections go forward. When a landed record turns out wrong, the fix goes in current law, never in
the record. Leaves are never deleted or moved either: a retired leaf is marked archived, so anything
pointing at it still resolves.

## Links run one way

Private leaves may link into `public/` freely. Nothing under `public/` may link to, or cite the path
of, a private record, because it would resolve on exactly one machine.

There is one sanctioned crossing. **What a change achieved crosses into the feature log; how it was
run never does.** Each product has a `features/` branch, one leaf per area, opening with a **State
today** paragraph and followed by dated entries. An entry says what is now true of the product:

> **2026-03-04** — Invoices can be split across two payment methods. See the billing design leaf.

It never mentions the plan, the sprint or who asked. So `public/` stays a reflection of what is, and
the feature log is the way in: to learn the state of a product, start there and follow its links.

## The private mirror

`private/` repeats the product branches of `public/` under the same paths, and adds a journal. Its
layout is deliberately flat:

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

`plans/`, `kickoffs/`, `prs/`, `appendices/` and `journal/retros/` are the immutable tiers of the
private tree. Records in them group by month (`2026-03/`). `latest.md` is rewritten as work moves,
and a session reads it before anything else. The repository runs on one trunk, with one commit per
filing action.

## Catalogs

You choose the top-level buckets of your catalog. Set them in `.conf`:

```
CATALOGS="products projects"
```

A software shop might use `apps sites`; a consultancy might use `clients`. Each entry becomes a branch of
`public/` and of `private/`. Tools read the names from `.conf` and never spell them.

## Adapters

The core is plain Markdown and works with any tool that can read a file. Its entry point is
`AGENTS.md`, and it never refers to an adapter. An adapter adds what one particular agent harness
can enforce on top of it.

Adapters are keyed by harness, not by model. Each one lives in `adapters/<harness>/` as a README and
a `payload/`, and the payload is copied verbatim into your instance.

- **Claude Code** is the one written adapter.
- **Codex**, **Cursor** and **Gemini CLI** are stubs. Each doubles as a porting spec, listing what a
  port has to reproduce.

The core works without any adapter. The linter and convention replace pre-write enforcement: a tier
violation is caught at lint time rather than at write time, and search and filing are run by hand.
No data is lost.

## Deploying

`init.sh`, at the root of a release, is the one deployer and the one unpack. Given a target
directory and a `.conf`, it copies the skeleton, resolves every placeholder from your catalogs and
your details, runs `git init` inside the private mirror, writes the workspace file and the editor
settings, and records a manifest. It is bash, because the agent that runs it has bash wherever it
runs. `--adapter <name>` lays one adapter's payload onto the tree; with no flag it lays down the
neutral core and prints the list of adapters, never picking one.

The manifest, `.agentcontext` at the instance root, is what makes updates safe. It names the release
installed and hashes every core file: the scripts, the rules, the templates, the editor settings,
the instruction and the hygiene document. `init.sh --update --ref <tag>` fetches a later release and,
file by file, replaces what you never edited, keeps what you did and tells you so, adds what is new,
and reports what the release dropped. It never touches `public/`, `private/`, `.conf` or the
workspace file. The full procedure is the last section of `SETUP.md`.

## Modules and examples

`modules/` holds optional additions. It will hold a constitution: starting law about how the tree
governs itself, which you may adopt or delete. `examples/` will hold a small fictional startup's
filled tree, so that you can see what the indexes look like with something in them.

## What is here today

- The method, in this file, and the instruction an instance receives, in `template/AGENTS.md`.
- The full skeleton of an instance, in `template/`: indexes, tags, and the branch, leaf, rule and
  product templates.
- The core scripts, in `scripts/`: `cure.sh` the structural linter, `smell.sh` the heuristic smells,
  `find.sh` tag and keyword search, and the two libraries they share. They read `.conf` and treat an
  absent `private/` as normal. This repository runs them over its own skeleton as its one check:
  `bash scripts/cure.sh --root template`.
- The contract of every check, in `template/HYGIENE.md`, and the grammar and tier rules as plain
  documents, in `template/rules/`.
- The deployer, `init.sh`, with its update mode and the manifest it keeps; the run-sheet `SETUP.md`
  that drives it; and `tools/deploy-smoke.sh`, which deploys a throwaway instance, lints it, updates
  it and proves the refusals, as this repository's gate.
- The adapter contract, with four adapter directories whose READMEs describe them.

Not in this repository yet: the adapter payloads (the tier guard among them), the constitution
module and the worked example.

## Licence

MIT. See [LICENSE](./LICENSE).
