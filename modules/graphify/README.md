# The graphify module

One [Graphify](https://github.com/Graphify-Labs/graphify) knowledge graph per repository, kept in the
tree as a generated tier. A graph answers who-calls, what-imports and shortest-path questions about a
codebase in one query, where grepping takes ten; the module keeps each graph beside the knowledge it
describes, lets the repository's own tooling rebuild it without dirtying the tree, and commits one
reproducible snapshot per repository.

```
graphs/
  .index.md            authored prose, then one generated Contents row per graph
  .tags  .agent
  <slug>/graph.json    the committed snapshot
  <slug>/live/         git-ignored: the working layer graphify reads and writes
```

The repository itself tracks three things and never a graph of its own: a `.graphifyignore` (the
homing marker, and what the scan skips), a `graphify-out/` line in its `.gitignore`, and
`graphify-out/` itself, which is a **link** into `graphs/<slug>/live/` (a directory junction on
Windows, a symlink elsewhere). So the scan, graphify's post-commit and post-checkout hooks and the
query server's per-project lookup all work in one directory, and a hook rebuild lands in the ignored
layer. The snapshot moves only when `scan` is run.

## Requirements

Bash and the core's `common/scripts/lib-scopes.sh` (the module runs inside an instance). For the scan,
graphify itself, the Python tool `graphifyy` (two y's: the package is `graphifyy`, the command
`graphify`):

```sh
    uv tool install "graphifyy[mcp]"    # the CLI, with its MCP server (or: pipx install "graphifyy[mcp]")
    graphify install                    # register the /graphify skill with your AI assistant
```

`graphify install` takes `--platform <name>` for assistants other than its default, and `--project`
to install into the current repository instead of the user profile; the Graphify README lists the
platforms. Python is also what the module reads a graph's counts with; without it the index rows say
`?`. Homing and checking need no graphify at all.

## Running it

From the instance root, with the module copied to `common/modules/graphify/`:

```sh
    bash common/modules/graphify/graphs.sh home <slug>...     home a repository (idempotent)
    bash common/modules/graphify/graphs.sh scan [<slug>...]   regenerate every homed graph, or the named ones
    bash common/modules/graphify/graphs.sh check [<slug>...]  report only; writes nothing
```

| Verb | What it does |
| ---- | ------------ |
| `home` | seeds the repository's `.graphifyignore` (never rewritten once present), appends `graphify-out/` to its `.gitignore`, links its `graphify-out` into `graphs/<slug>/live/`, scaffolds `graphs/` (`.index.md`, `.tags`, `.agent`) and appends the `graphs/` block to the instance's own `.gitignore`. A standalone `graphify-out/` directory from before adoption is moved into `live/` and replaced by the link; a link pointing anywhere else is refused. |
| `scan` | per homed repository: deletes the live graph, manifest and analysis, runs `graphify extract <repository> --code-only` (tree-sitter only, offline, no API key), copies `live/graph.json` up to `graphs/<slug>/graph.json`, registers the snapshot in the user's global graph (`graphify global add`, skipped with `--no-global`), and rewrites the index rows and `.agent`. `--force` bypasses graphify's parse cache too. |
| `check` | the links, the tool and its pin, each snapshot against its repository's HEAD (stale is a warning), the index and `.agent` against the graphs on disk (drift is a fail). |

Options: `--root <dir>` the instance root (default the current directory). Exit 0 clean, the number
of fails otherwise, 2 for a usage error or a refusal when nothing was written. An unhomed repository
is skipped by `scan` and `check` and named, never scanned.

## The `.conf` keys

```
    GRAPHS="lantern=../lantern beacon=../beacon"   # <slug>=<path>, one word per repository
    GRAPHIFY_VERSION=0.9.65                        # optional pin
```

`GRAPHS` names each repository by a slug (`[a-z0-9-]`, the subdirectory under `graphs/`) and its
path relative to the instance root: `../<name>` for a sibling in the workspace, `.` for the
instance itself. Nothing else spells a repository. `GRAPHIFY_VERSION`, when set, makes `scan` refuse
any other graphify on PATH, so the same source gives the same graph on every machine; unset, the
scan reports the version it ran and says how to pin it. The index row records the pin.

## Adopting it

1. Copy `modules/graphify/` from a release to `<instance>/common/modules/graphify/`.
2. Add `GRAPHS=` to `.conf`, one `<slug>=<path>` per repository.
3. Run `home <slug>` for each; edit the seeded `.graphifyignore` (what the scan should skip:
   dependencies, build output, generated code; `graphify-out/` stays).
4. Add `graphs/` to the index table of the instance's `AGENTS.md`:
   ```md
       | [Graphs](./graphs/.index.md) | one Graphify knowledge graph per repository: query it before grepping |
   ```
   and the two `files.exclude` entries to the workspace file if its template predates the module:
   `"**/graphify-out": true` and `"**/.graphifyignore": true`.
5. Install graphify, run `scan`, commit `graphs/` and, in each repository, its `.graphifyignore` and
   `.gitignore` line.
6. Optionally, in each repository, `graphify hook install`: its post-commit and post-checkout
   rebuilds then land in the ignored live layer through the link, and `check` reports when the
   live graph is ahead of the snapshot.

Register the query server with your assistant once, over the global graph, so one server answers
for every repository and resolves each through its `graphify-out/` link: the stdio server is the
`graphify-mcp` entry point (`python -m graphify.serve` is the same thing) given
`~/.graphify/global-graph.json`, the file `scan` keeps current. The Graphify README shows the
registration command for each assistant.

## The tier contract

The tier obeys the generated-tiers rule of the core (`common/rules/generated-tiers.md`):

- **One writer.** Every `graph.json`, every Contents row of `graphs/.index.md` and `graphs/.agent`
  are written by `graphs.sh`. The prose above the Contents table and `.tags` are authored: the
  script scaffolds them once and never rewrites them.
- **Always from scratch.** graphify merges into an existing `graph.json` rather than replacing it,
  and a hook rebuild also extracts documents, so an incremental run over the hook's output would
  carry foreign nodes into the committed snapshot. `scan` deletes the live graph before every
  extract; the parse cache stays, keyed by file hash, and only makes the rebuild faster.
- **Code only, and offline.** Every scan runs the tree-sitter extractors alone, with no API key and
  no semantic pass. Markdown is a document type to the extractor and is skipped, so a tree of
  documents such as the instance itself yields little; scanning the instance (`GRAPHS` entry `.`) is
  allowed, not expected.
- **Regenerate at the landing** of the change that moved the source, never for an unmerged branch;
  the live layer may run ahead through the hooks, and the snapshot is what is committed.
- **Reproducible from the committed files.** The index row carries the counts, the commit graphify
  stamped and the pin, never a date or a machine fact, so `check` on a fresh clone agrees with the
  machine that scanned.
- **Ignored by the tree, not by the instance.** `graphs/*/*` is ignored except `graphs/*/graph.json`;
  the deployer's `.gitignore` gains that block at the first `home`.

## How the tree treats the tier

`graphs/` sits at the instance root beside `public/`, outside the two linted trees: the structural
linter never asks `graphs/<slug>/` for an index of its own, and `find.sh` does not search it. It is
reached from the `AGENTS.md` table and from its own `.index.md`, whose rows are the one place the
graphs are described.

## The check

`bash modules/graphify/check.sh` builds a throwaway instance and a small repository beside it,
puts a stand-in `graphify` on PATH that writes a three-node graph, and proves the module end to end
without a real install: the four things `home` lays down and the link; a rerun that writes nothing;
a pre-existing `graphify-out/` adopted; a link elsewhere, an unknown slug, a missing tool and a
mismatched pin each refused with nothing written; the scan, the snapshot, the index row; a rerun
byte-identical; `check` current, then stale after a commit; a hand-added row reported as drift;
the instance linting clean. It exits with its fail count. The deploy smoke runs it.
