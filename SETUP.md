# Setting up a knowledge tree

This is a run-sheet. It is written for a coding agent working on a user's machine, and it reads
just as well for a person at a terminal. Every step has a **Run** line and a **Check** line: run the
command, then confirm the check against what is now on disk before moving to the next step. Nothing
here asks you to read another file and work out what to do; when a step refuses, stop and tell the
user what it said.

The pinned release is `v0.3.0`. Replace it everywhere below if the user names another.

## Before you start: ask the user

Ask these questions first and keep the answers; several steps use them.

1. **Where** should the tree live? A path to a directory that does not exist yet, or is empty. This
   becomes the instance; its basename becomes the repository name unless the user gives one.
2. **What is the organisation called**, and how does the user want to be addressed (name, short
   name, pronouns, role, user name)? These fill the `MY_` lines of `.conf`.
3. **What are the catalogs**: the top-level buckets of `public/`, named in the user's own words, for
   example `products projects`, `apps sites`, or `clients`. Each becomes one branch of `public/` and
   of `private/`.
4. **A private tree on this machine, or not?** Yes for the person who runs the work (plans, kickoffs,
   pull-request records, the journal); no for a reader-only clone.
5. **An adapter, or none?** An adapter adds what one agent harness can enforce on top of the plain
   tree. With none, the tree works on convention and the linter. The deployer prints the list of
   adapters it ships; pick one of those names or leave it out.
6. **How the agent should speak**: how technical (`beginner`, `junior`, `mid`, `senior`) and in what
   tone (`casual`, `direct`, `friendly`, `reserved`). These fill the `AI_` lines.

## 0. Requirements

**Run**

```
bash --version | head -1 && git --version && curl --version | head -1 && tar --version | head -1
```

**Check**: four version lines. On Windows these come from Git Bash; run every command below in it.
A missing tool is the user's to install before step 1.

## 1. Fetch the release

Work in a scratch directory the user is happy to delete afterwards.

**Run**

```
curl -fsSL https://github.com/AWCostabile/AgentContext/archive/refs/tags/v0.3.0.tar.gz | tar xz
```

**Check**: a directory `AgentContext-0.3.0/` exists and holds `init.sh`, `template/AGENTS.md`,
`scripts/cure.sh` and `adapters/`. (GitHub names the archive's top directory after the tag without
its `v`.) Nothing else has been written anywhere.

## 2. Write the `.conf`

**Run**

```
cp AgentContext-0.3.0/template/.conf.example ./my.conf
```

Then edit `my.conf` from the user's answers: the `AI_` lines, the `MY_` lines and `CATALOGS`. Leave
`PRIVATE_SCOPES` and `ORCH_BUDGET` as they are unless the user asked for something specific; the
deployer derives `PRIVATE_SCOPES` from the catalogs when it is absent.

**Check**

```
grep -E '^(AI_TECHNICALITY|AI_TONE|MY_NAME|MY_NICK|MY_PRONOUNS|MY_ROLE|MY_USER|CATALOGS)=' my.conf | wc -l
```

prints `8`, and `grep '^CATALOGS=' my.conf` shows the user's catalogs in quotes.

## 3. Deploy

**Run** (drop `--no-private` if the user wants a private tree; add `--adapter <name>` if they chose
one; add `--name <RepositoryName>` if the directory's basename is not the name they want)

```
bash AgentContext-0.3.0/init.sh --target <path> --conf ./my.conf
```

**Check**: the output ends with `done: <path>` followed by the adapter list. Then:

```
grep -rl '{{' <path> | grep -v '/templates/'
```

prints nothing: no placeholder is left outside the templates directory. `<path>/public/` holds one
directory per catalog and no `catalog/`; `<path>/.agentcontext` exists and names the release;
`<path>/<RepositoryName>.code-workspace` exists; with a private tree, `<path>/private/.git` exists.

If the deployer refuses, it says why on its last line: a non-empty target, a missing `.conf` key, an
adapter with no payload in this release. Fix the cause and run it again; it writes nothing when it
refuses.

## 4. Verify the tree

**Run**

```
cd <path> && bash scripts/cure.sh && bash scripts/smell.sh --quiet && bash scripts/find.sh -l
```

**Check**: `cure.sh` ends with `== VERDICT: 0 fail(s), 0 warning(s) ==`; `smell.sh` ends with
`== SUMMARY: 0 smell(s)`; `find.sh -l` lists the tree's tags with their counts. Anything else is a
deployer defect: tell the user and keep the output.

## 5. Make it a repository

**Run**

```
cd <path> && git init -b main && git add -A && git commit -m "chore: a knowledge tree from the template"
```

**Check**: `git status --short` prints nothing. `cat .gitignore` names `/private/` and `/.conf`:
the private tree is a repository of its own that this one ignores, and `.conf` is this machine's.
With a private tree, `git -C private status` reports a repository on `main` with everything
untracked; it takes its first commit when the user files something there.

## 6. Open it

**Run**: open `<path>/<RepositoryName>.code-workspace` in the editor. It holds the tree and, when
present, the private tree as two folders; `.vscode/` carries the recommended extensions and the
settings for Markdown and search.

**Check**: the editor shows `AGENTS.md` at the root. That file is the instruction every agent
session in this tree reads first, and the user's next step is to copy `templates/product` into a
catalog for their first product.

## How to update

A release of the template changes the core files an instance received: `scripts/`, `rules/`,
`templates/`, `.vscode/`, `AGENTS.md`, `HYGIENE.md`, `.conf.example` and an adapter's payload. It
never changes what the user has filed: `public/`, `private/`, `.conf`, the workspace file. The
manifest `.agentcontext` at the instance root records the release installed and a hash of every
core file, so the update can tell a file the user edited from one they left alone.

**Run** (with the new tag; the deployer fetches that release itself)

```
curl -fsSL https://github.com/AWCostabile/AgentContext/archive/refs/tags/<tag>.tar.gz | tar xz
bash AgentContext-<tag without v>/init.sh --update --target <path> --ref <tag>
```

**Check**: the report ends with `update: N replaced, N kept, N added, N removed-upstream`, one line
per file above it:

- `replaced`: a core file the user never edited, now the new release's version;
- `kept … (changed locally)`: a core file the user edited; it is left as it was, and the user merges
  the release's version by hand if they want it;
- `added`: a core file new in this release;
- `removed-upstream`: a core file the release no longer ships; the local copy stays.

Then run step 4 again (`cure.sh` at 0 fails) and commit:

```
cd <path> && git add -A && git commit -m "chore: core files updated to <tag>"
```

`--dry-run` before `--target` prints the report and writes nothing, which is the way to preview.

## What the deployer fills

The skeleton carries `{{ }}` placeholders. The deployer resolves every one outside `templates/`:

| Placeholder | Becomes |
| --- | --- |
| `{{catalog}}`, `{{Catalog}}` | one branch per `CATALOGS` entry, under `public/` and `private/`, the placeholder `catalog/` removed |
| `{{REPOSITORY_NAME}}` | the workspace file's name; a sibling repository folder only with `--sibling <name>` |
| `{{YYYY-MM-DD}}` | the install date, in the journal |
| the status page's fields | `nothing yet`, and `none` for unpushed branches |
| an example Contents row whose target is a placeholder | removed; the table keeps its header |
| a `.tags` line that is a placeholder | removed |
| the skeleton's set-up comments | removed; the deployer did what they describe |

`templates/` keeps its placeholders on purpose: those files are copied by hand when a branch or a
product is added, and the linter never reads them as part of the tree.

## When a step refuses

| Message | Meaning | What to do |
| --- | --- | --- |
| target is not empty | the path exists and holds files other than `.conf` | choose another path, or empty it |
| no .conf | neither `--conf` nor `<path>/.conf` was found | step 2 |
| missing key `<KEY>` | a required `.conf` line is absent or empty | fill it and run again |
| adapter '<name>' has no payload in this release | the adapter is a stub | leave `--adapter` out, or pick one marked `written` in the list |
| no .agentcontext at target | `--update` on a directory that was not deployed by this tool | deploy fresh, or write the manifest by hand from a known release |
