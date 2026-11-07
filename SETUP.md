# Setting up a knowledge tree

This is a run-sheet. It is written for a coding agent working on a user's machine, and it reads just as well for a person at a terminal. Every step has a **Run** line and a **Check** line: run the command, then confirm the check against what is now on disk before moving to the next step. Nothing here asks you to read another file and work out what to do; when a step refuses, stop and tell the user what it said.

The pinned release is `v0.4.0`. Replace it everywhere below if the user names another.

## Before you start: ask the user

Ask these questions first and keep the answers; several steps use them.

1. **Where** should the tree live? A path to a directory that does not exist yet, or is empty. This becomes the instance; its basename becomes the repository name unless the user gives one.
2. **What is the organisation called**, and how does the user want to be addressed (name, short name, pronouns, role, user name)? These fill the `MY_` lines of `.conf`.
3. **What are the catalogs**: the top-level buckets of `public/`, named in the user's own words, for example `products projects`, `apps sites`, or `clients`. Each becomes one branch of `public/` and of `private/`.
4. **A private tree on this machine, or not?** Yes for the person who runs the work (plans, kickoffs, pull-request records, the journal); no for a reader-only clone.
5. **An adapter, or none?** An adapter adds what one agent harness can enforce on top of the plain tree. With none, the tree works on convention and the linter. The deployer prints the list of adapters it ships; pick one of those names or leave it out.
6. **How the agent should speak**: how technical (`beginner`, `junior`, `mid`, `senior`) and in what tone (`casual`, `direct`, `friendly`, `reserved`). These fill the `AI_` lines.
7. **Which repositories sit beside the tree?** The folder names of the product repositories the tree will describe, each a sibling directory of the instance. They become the workspace file's folders at deploy (step 3), and every later step that reads "the repository beside the instance, as the workspace sees it" reads that file.

## 0. Requirements

**Run**

```
bash --version | head -1 && git --version && curl --version | head -1 && tar --version | head -1
```

**Check**: four version lines. On Windows these come from Git Bash; run every command below in it. A missing tool is the user's to install before step 1.

## 1. Fetch the release

Work in a scratch directory the user is happy to delete afterwards.

**Run**

```
curl -fsSL https://github.com/AWCostabile/AgentContext/archive/refs/tags/v0.4.0.tar.gz | tar xz
```

**Check**: a directory `AgentContext-0.4.0/` exists and holds `init.sh`, `template/AGENTS.md`, `scripts/cure.sh` and `adapters/`. (GitHub names the archive's top directory after the tag without its `v`.) Nothing else has been written anywhere.

## 2. Write the `.conf`

**Run**

```
cp AgentContext-0.4.0/template/.conf.example ./my.conf
```

Then edit `my.conf` from the user's answers: the `AI_` lines, the `MY_` lines and `CATALOGS`. Leave `PRIVATE_SCOPES` and `ORCH_BUDGET` as they are unless the user asked for something specific; the deployer derives `PRIVATE_SCOPES` from the catalogs when it is absent.

**Check**

```
grep -E '^(AI_TECHNICALITY|AI_TONE|MY_NAME|MY_NICK|MY_PRONOUNS|MY_ROLE|MY_USER|CATALOGS)=' my.conf | wc -l
```

prints `8`, and `grep '^CATALOGS=' my.conf` shows the user's catalogs in quotes.

## 3. Deploy

**Run** (drop `--no-private` if the user wants a private tree; add `--adapter <name>` if they chose one; add `--name <RepositoryName>` if the directory's basename is not the name they want; one `--sibling <name>` per repository from the seventh answer)

```
bash AgentContext-0.4.0/init.sh --target <path> --conf ./my.conf --sibling <name>
```

**Check**: the output ends with `done: <path>` followed by the adapter list. Then:

```
grep -rlE '\{\{[A-Za-z]' --exclude-dir=.git <path> | grep -v '/templates/'
```

prints nothing: no placeholder is left outside the templates directory (the core documents mention the placeholder syntax itself, which is why the check looks for a brace pair followed by a letter). `<path>/public/` holds one directory per catalog and no `catalog/`; `<path>/.agentcontext` exists and its `ref=` line names the release; `<path>/<RepositoryName>.code-workspace` exists and its `folders` name the tree, the private tree when there is one, and each `--sibling`; with a private tree, `<path>/private/.git` exists.

If the deployer refuses, it exits 2 and the last line of its error output, prefixed `init.sh:`, says why: a non-empty target, a missing `.conf` key, a catalog name that is not lowercase letters, digits and hyphens, an adapter with no payload in this release. Fix the cause and run it again; it builds the instance in a staging directory and writes nothing to the target when it refuses.

## 4. Verify the tree

**Run**

```
cd <path> && bash common/scripts/cure.sh && bash common/scripts/smell.sh --quiet && bash common/scripts/find.sh -l
```

**Check**: `cure.sh` ends with `== VERDICT: 0 fail(s), 0 warning(s) ==`; `smell.sh` ends with `== SUMMARY: 0 smell(s)`; `find.sh -l` lists the tree's tags with their counts. Anything else is a deployer defect: tell the user and keep the output.

## 5. Make it a repository

**Run**

```
cd <path> && git init -b main && git add -A && git commit -m "chore: a knowledge tree from the template"
```

**Check**: `git status --short` prints nothing. `cat .gitignore` names `/private/` and `/.conf`: the private tree is a repository of its own that this one ignores, and `.conf` is this machine's. With a private tree, `git -C private status` reports a repository on `main` with everything untracked; it takes its first commit when the user files something there.

## 6. Open it

**Run**: open `<path>/<RepositoryName>.code-workspace` in the editor. It holds the tree and, when present, the private tree as two folders; `.vscode/` carries the recommended extensions and the settings for Markdown and search.

**Check**: the editor shows `AGENTS.md` at the root. That file is the instruction every agent session in this tree reads first. The tree is usable from here: the user's first product is `common/templates/product` copied into a catalog. The steps below are optional modules, in the order they are best adopted: what concerns the instance and this machine first, then the process law, then the repository's workflow, then the two generated tiers with their installs.

## 7. Project context retention (optional)

The context-retention module gives every project in the workspace a per-clone identity, `.agents/.id.meta` (an id, a name and a date, never a path), so an agent can keep a project's memory and history when the folder is renamed or moved, and the instance's `AGENTS.md` keeps a session's start prompt to this tree's own instruction, reading a sibling's on first touch. An instance works without it. This step asks the user for each setting rather than taking it; ask these three and keep the answers:

1. **Ignore `.agents/.id.meta` in git's global excludes?** Recommended: yes. The file is one user's identity for the folder and must never be committed; in a clone it would hand the same identity to everyone. Git's global excludes ignore it everywhere for this user alone, without touching any repository's `.gitignore`. `init` prints this reason again and asks before it writes; a no leaves the file visible to git in every project that does not ignore it itself.
2. **Which folders get an identity?** By default the instance and every folder its workspace file names (the siblings from the seventh opening answer). The user may name fewer; a folder they skip is reported by `check` as having none, never failed.
3. **Keep the start prompt to this tree's own instruction?** Measure first, and quote the number:

```
cd <path> && for f in ../*/CLAUDE.md ../*/AGENTS.md; do [ -f "$f" ] && wc -c < "$f"; done | awk '{ s += $1 } END { printf "%d bytes, about %d tokens of sibling instruction per session\n", s, s / 4 }'
```

   That is what every session would pay to load the siblings' instruction files at start, whether or not it enters those repositories (a `CLAUDE.md` that only imports its `AGENTS.md` is counted twice, so the figure is an upper bound). With the Claude Code adapter the deployed settings already keep them out (`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` at `0`) and a hook hands a sibling's instruction over the first time the session touches it; a user who wants everything loaded at start removes that `env` line from `.claude/settings.json`. Without an adapter the rule stands in `AGENTS.md` alone.

**Run** (from the instance root; `--yes` or `--no` carries the first answer when the user is not at the terminal)

```
cp -R AgentContext-0.4.0/modules/context-retention <path>/common/modules/context-retention && cd <path>
bash common/modules/context-retention/meta.sh init
```

Pass the folders from the second answer as paths after `init` when the user named fewer than the workspace file does.

**Check**: `<path>/.agents/.id.meta` exists and is exactly three lines, `id=`, `name=` and `created=`, with no path in it; each named folder has one too; `bash common/modules/context-retention/meta.sh check` ends with `0 fail(s)` and one `[ OK ]` line per project; `bash common/modules/context-retention/meta.sh list` prints one row per project with its path; with a yes to the first question, `git -C <path> status --short` does not list `.agents/`, and `git config --global core.excludesFile` names a file containing the line `.agents/.id.meta`. Nothing of this is committed: the identity is this user's, and the map is this machine's.

**With the Claude Code adapter, measure the prompt-cache lifetime too.** An orchestrating session that waits on a delegated job for longer than the cache lives pays a cold write of its whole prompt on its next turn; the harness caches for five minutes by default on an API key or a cloud provider, and for an hour on a subscription within its plan.

```
bash AgentContext-0.4.0/adapters/claude-code/cache-ttl.sh <path>
```

**Check**: the second line reads `prompt cache: 1h …` or `prompt cache: 5m …`. On `5m`, ask the user whether to try for the hour: `… cache-ttl.sh <path> --apply` writes `promptCacheTtl` and `subagentPromptCacheTtl` as `"1h"` into `<path>/.claude/settings.local.json` (this machine's file; add `.claude/settings.local.json` to the instance's `.gitignore` if `git check-ignore` does not already ignore it) and probes again. If the second probe still says `5m`, the account does not grant the hour or the build predates the setting (Claude Code 2.1.242): tell the user to ask their account's administrator, and keep `ORCH_BUDGET=lean` in `.conf`, which keeps an orchestrator's waits short.

## 8. Adopt the constitution module (optional)

The constitution is the tree's law about itself: starting rulings, the articles that distil them, and the process half (a kickoff guide, ground rules by reader, a code-standards template). An instance works without it; with it, every later change to the process starts as a bill. Ask the user; a team that will run agent-led work wants it.

**Run**

```
cp -R AgentContext-0.4.0/modules/constitution/tree <path>/constitution && cd <path> && bash common/scripts/cure.sh
```

Then add one row to the index table in `<path>/AGENTS.md`, after the Rules row:

```
| [Constitution](./constitution/.index.md) | the tree's law about itself: bills, the seed rulings, the articles, the process half |
```

**Check**: `<path>/constitution/.index.md`, `constitution/history/rulings/`, `constitution/articles/` and `constitution/process/` exist; `cure.sh` still ends with 0 fails; `constitution/README.md` does not exist (the module's README stays in the release, only `tree/` is copied).

Then prune: the seed rulings ship with `_status:_ seed — adopt, amend or delete` under each H1, and the user keeps what applies and strikes the rest before the first commit. When a leaf is as the user wants it, change that line to `_status:_ adopted YYYY-MM-DD`; the status line is what freezes it (an adapter's pre-write guard lets a seed leaf be edited and blocks an adopted one). The adoption steps in `AgentContext-0.4.0/modules/constitution/README.md` walk the same ground. Commit.

## 9. Adopt the change-log module (optional)

The change-log module is a GitHub Actions workflow for any repository the user keeps on GitHub, the instance itself or a product's: every merged pull request becomes one squash commit, a bubble merge and an entry in `CHANGE_LOG.md` built from the pull request's title and its commit subjects. It is what makes a merged pull request citable from the tree. Ask the user which repositories should carry it.

**Run** (in each such repository, on `main`)

```
mkdir -p .github/workflows && cp AgentContext-0.4.0/modules/change-log/post-merge.yml .github/workflows/post-merge.yml
git add .github/workflows/post-merge.yml && git commit -m "chore: the post-merge workflow squashes, bubble-merges and logs each pull request"
```

Then the user adds a repository secret named `ACTION_TOKEN` (a fine-grained personal access token with Contents: read and write on that repository) under Settings, Secrets and variables, Actions, and checks three settings: "Allow merge commits" on, "Automatically delete head branches" off, and force pushes to `main` allowed for their account if the branch is protected. The agent cannot do these; say exactly what to click.

**Check**: `.github/workflows/post-merge.yml` is on `main` and is identical to the module's file (`cmp` prints nothing); the secret exists; the next merged pull request leaves `main` with a `merge: pull request #<n>` bubble and a `CHANGE_LOG.md` whose first heading is that pull request's title. Every clone then re-syncs with `git fetch && git reset --hard origin/main`, never a pull. `modules/change-log/README.md` says what the workflow asks of commit subjects.

## 10. Adopt the codebase module (optional)

The codebase module keeps a generated code map of a product's repository in the tree: its source areas, the surfaces it exposes and one symbols leaf per area, every location a `path:line`. An instance works without it. Ask the user which products have a repository worth mapping; the repository sits beside the instance, as the workspace sees it.

**Run** (from the instance root, once per product; `<repository>` is the product's checkout beside it)

```
cp -R AgentContext-0.4.0/modules/codebase <path>/common/modules/codebase && cd <path>
python common/modules/codebase/codebase.py --repo ../<repository> --into public/<catalog>/<Product>/codebase \
  --profile ../<repository>/codebase.profile.json --write-agent
```

Write the profile first, at the repository's root: the product's name, its areas (a name and the path prefixes it claims) and the surfaces the map lists. `common/modules/codebase/README.md` gives the shape; without a profile each top-level directory is an area. Then add one row to the product's `.index.md`:

```
| [<Product> code base](./codebase/.index.md) | the generated code map: areas, surfaces, symbols; never hand-edited |
```

and replace the tier's scaffold `.tags` with the words a searcher would use for that code.

**Check**: `public/<catalog>/<Product>/codebase/` holds `.index.md`, `.tags`, `.agent`, `codebase.map.md`, `codebase.surfaces.md` and one `codebase.<area>.md` per area; the command `.agent` names, run again with `--check`, ends with no drift; `cure.sh` still ends with 0 fails. Commit.

The tier is regenerated with that command at the landing of the change that moved the source, and never hand-edited. Python 3.10 or later is the module's one requirement.

## 11. Adopt the graphify module (optional)

The graphify module keeps one Graphify knowledge graph per repository in the tree, under `graphs/<slug>/`, and links each repository's `graphify-out/` back into it, so an agent asks the graph who calls what before it greps and the repository's own graphify hooks never dirty the tree. An instance works without it. Ask the user which repositories to graph; each sits beside the instance, as the workspace sees it.

**Run** (from the instance root; `<slug>` a short lowercase name per repository)

```
cp -R AgentContext-0.4.0/modules/graphify <path>/common/modules/graphify && cd <path>
printf 'GRAPHS="<slug>=../<repository>"\n' >> .conf
bash common/modules/graphify/graphs.sh home <slug>
uv tool install "graphifyy[mcp]" && graphify install
bash common/modules/graphify/graphs.sh scan
```

`home` seeds the repository's `.graphifyignore` and its `graphify-out/` ignore line, links `graphify-out` into `graphs/<slug>/live/` (a junction on Windows, a symlink elsewhere), scaffolds `graphs/` and appends the `graphs/` block to the instance's `.gitignore`. The user edits the seeded `.graphifyignore` (dependencies, build output, generated code; `graphify-out/` stays). Then add one row to the table in `AGENTS.md`:

```
| [Graphs](./graphs/.index.md) | one Graphify knowledge graph per repository: query it before grepping |
```

The install line is the user's: `graphify install` registers the `/graphify` skill with their assistant (`--platform <name>` for one other than its default), and the query server is registered once over `~/.graphify/global-graph.json`, which `scan` keeps current; `modules/graphify/README.md` says how. Pin the version `scan` reports with `GRAPHIFY_VERSION=` in `.conf` so every machine builds the same graph.

**Check**: `bash common/modules/graphify/graphs.sh check` ends with 0 fails and the snapshot current; `graphs/.index.md` carries one row per repository with its counts and commit; in each repository `git status` shows only `.graphifyignore` and the `.gitignore` line as new, never `graphify-out/`; `cure.sh` still ends with 0 fails. Commit `graphs/` here and the two files there.

The snapshot is regenerated with `scan` at the landing of the change that moved the source, never hand-edited; the live layer may run ahead through the repository's hooks, and `check` says when it does.

## How to update

A release of the template changes the core files an instance received: everything under `common/` (`scripts/`, `rules/`, `templates/`, `HYGIENE.md`, `.conf.example`), `.vscode/`, `AGENTS.md`, `README.md` and an adapter's payload. It never changes what the user has filed: `public/`, `private/`, `.conf`, the workspace file. The manifest `common/.agentcontext` records the release installed and a hash of every core file, so the update can tell a file the user edited from one they left alone. (An instance deployed before the common directory keeps its manifest at the root; the update reads it there and rewrites it under `common/`.)

Always run the update with the **new** release's `init.sh`: an older one cannot read a newer layout. When the update keeps a file, it names the migration guides that apply (`migrations/<version>.md` in the template repository, one per release, read in order from the instance's own); they say what to finish by hand.

**Run** (with the new tag; the deployer fetches that release itself)

```
curl -fsSL https://github.com/AWCostabile/AgentContext/archive/refs/tags/<tag>.tar.gz | tar xz
bash AgentContext-<tag without v>/init.sh --update --target <path> --ref <tag>
```

**Check**: the report ends with `update: N moved, N replaced, N kept, N added, N removed-upstream` and then `manifest: ref=<tag>, N core files`, one line per file above them:

- `moved <old> -> <new>`: a core file the release moved (its `MOVES` file lists them), never edited by the user: written at the new path, the old one removed with any directory it leaves empty. It is the only thing the update deletes;
- `kept <old> (changed locally; moved to <new>)`: a moved file the user edited; it stays at its old path, the release's copy is written at the new one, and the user brings the change across and deletes the old file;
- `replaced`: a core file the user never edited, now the new release's version;
- `kept … (changed locally)`: a core file the user edited; it is left as it was, and the user merges   the release's version by hand if they want it (`deleted locally` and `exists locally` are the same outcome for a file the user removed, or created before the release shipped one);
- `added`: a core file new in this release;
- `removed-upstream`: a core file the release no longer ships; the local copy stays.

After the summary, `run bash common/scripts/cure.sh: N kept file(s) may name moved paths` means an edited root document (an `AGENTS.md`, say) still names old paths, and `guide: migrations/<version>.md` names each guide to read. Then run step 4 again (`cure.sh` at 0 fails) and commit:

```
cd <path> && git add -A && git commit -m "chore: core files updated to <tag>"
```

`--dry-run` before `--target` prints the report and writes nothing, which is the way to preview.

## What the deployer fills

The skeleton carries `{{ }}` placeholders. The deployer resolves every one outside `common/templates/`:

| Placeholder | Becomes |
| --- | --- |
| `{{catalog}}`, `{{Catalog}}` | one branch per `CATALOGS` entry, under `public/` and `private/`, the placeholder `catalog/` removed |
| `{{REPOSITORY_NAME}}` | the workspace file's name; a sibling repository folder only with `--sibling <name>` |
| `{{YYYY-MM-DD}}` | the install date, in the journal |
| the status page's fields | `nothing yet`, and `none` for unpushed branches |
| an example Contents row whose target is a placeholder | removed; the table keeps its header |
| a `.tags` line that is a placeholder | removed |
| the skeleton's set-up comments | removed; the deployer did what they describe |

`common/templates/` keeps its placeholders on purpose: those files are copied by hand when a branch or a product is added, and the linter never reads them as part of the tree.

## When a step refuses

| Message | Meaning | What to do |
| --- | --- | --- |
| `target is not empty: <path> holds …` | the path exists and holds files other than `.conf` | choose another path, or empty it |
| `no .conf: copy blueprint/common/.conf.example, fill it, pass --conf` | neither `--conf` nor `<path>/.conf` was found | step 2 |
| `missing key <KEY> in <conf>` | a required `.conf` line is absent or empty | fill it and run again |
| `bad catalog …` | a `CATALOGS` entry is not `[a-z0-9-]`, is repeated, or is reserved (`catalog`, `misc`, `scratch-tools`) | rename it in `.conf` |
| `adapter '<name>' has no payload in this release` | the adapter is a stub; the list printed above it says which are written | leave `--adapter` out, or pick one marked `written` |
| `no .agentcontext at target: …` | `--update` on a directory that was not deployed by this tool | deploy fresh, or write the manifest by hand from a known release |
| `not a template source (no blueprint/AGENTS.md)` | `--from` points at something that is not a release | check the extracted directory's name and contents |
