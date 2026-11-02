# The codebase module

A code map of a product's repository, kept in the knowledge tree as a generated tier. One command reads the repository and writes `codebase/` under the product's branch:

- `codebase.map.md`: the source areas, their file counts, the languages read, and every file no extractor read ("Not extracted");
- `codebase.surfaces.md`: what the repository exposes: its entry points, the names each area exports, a named file's exports, the environment variable names it reads;
- `codebase.<area>.md`: one symbols leaf per source area, one table per file: each top-level declaration, exported or not, a type's members as `Type.member`, the declaration's signature and the first sentence of its doc comment.

Every location is a `path:line` code span. Names only: never the value of a constant, a string or an environment variable. A reader of the tier learns where a thing is declared and what it is called before opening the repository, and the tier says what it could not read, so the absence of a name is never mistaken for the absence of the thing.

## Requirements

Python 3.10 or later, standard library only. The extractors are line parsers written in Python; nothing else is installed or run, and the same source gives the same tier on any machine. Git is optional: under git the file set is what `git ls-files` lists (tracked, and untracked but not ignored); without it the repository is walked. Either way hidden paths and `node_modules/`, `vendor/`, `dist/` and `build/` are left out, so the two agree.

## Running it

From the instance root, with the module copied to `modules/codebase/` (or from a checkout of this template):

```sh
    python modules/codebase/codebase.py --repo ../<repository> \
        --into public/<catalog>/<Product>/codebase --profile <profile.json> --write-agent
```

| Option | Meaning |
| ------ | ------- |
| `--repo` | the repository root to read; never written to, and `--into` may not lie inside it |
| `--into` | the tier directory; created with a scaffold `.index.md` and `.tags` when absent |
| `--lang <name>` | run only this extractor; repeatable; default every extractor that runs by default |
| `--profile <file>` | a JSON file naming the areas and the surfaces (below); optional |
| `--check` | compare the tier with the source and write nothing; exit 1 on drift, naming each leaf |
| `--write-agent` | write the tier's `.agent` with the command that regenerates it |

Exit 0 clean, 1 drift or a failure, 2 a usage error or a refusal (nothing written). Run `--write-agent` from the instance root: the command it records uses paths relative to where it ran.

## The profile

Without a profile, each top-level directory holding source files is an area (root files are the `root` area) and the surfaces leaf lists entry points and exported names per area. A profile is a closed shape; an unknown key is refused:

```json
    {
      "name": "Product",
      "areas": [{"name": "server", "paths": ["server/"]}, {"name": "web", "paths": ["src/", "public/"]}],
      "surfaces": {"entry-points": true, "exports-per-area": true,
                   "exports-of": ["src/index.ts"], "env-keys": true}
    }
```

`name` titles every leaf (default the repository's name). An area's `paths` are prefixes; the longest match wins, and a file no area claims falls back to its top-level directory's area. An area name is lowercase `[a-z0-9-]`, and never `map` or `surfaces`. `surfaces` lists exactly the sections the surfaces leaf carries.

## Extractors

| Name | Reads | By default |
| ---- | ----- | ---------- |
| `typescript` | `*.ts` `*.tsx` `*.mts` `*.cts` `*.js` `*.jsx` `*.mjs` `*.cjs` | yes |
| `go` | `*.go` except `*_test.go` | yes |
| `go-tests` | `*_test.go` | only when named: `--lang go --lang go-tests` |

Each extractor's module says what its parser sees and what it does not. A file whose braces do not balance, a top-level line outside the grammar, an import that could not be read, or a file that is not UTF-8 is listed under "Not extracted" with the file named. A file of a language with no extractor is listed there too, by extension, never parsed by another language's grammar.

**Adding a language** is one module in `extractors/` and one `register()` line in `extractors/__init__.py`. The module exposes `NAME`, `LANGUAGE`, `PATTERNS`, `DEFAULT` and `extract(root, rel)`, returning the fact set `extractors/common.py` defines (symbols with kind, name, line, signature and summary; imports; exports; environment names; entry reasons; notes); optionally `EXCLUDE`, `identity()` and `entries()` for repository-level facts. Use `common.summary_of` for summaries and `common.scrub` for signatures, so every language reads alike and no string literal reaches a leaf. Add a file of the language to the fixture and regenerate `fixture/expected/` in the same change.

## The tier contract

The tier obeys the generated-tiers rule of the core (`rules/generated-tiers.md` in an instance):

- **One writer.** Every `codebase.*.md` leaf and every Contents row of the tier's `.index.md` is written by `codebase.py`. The prose above the Contents table, `.tags` and `.agent` are authored: the generator creates them when absent and never rewrites them (`.agent` only with `--write-agent`). Never hand-edit a generated leaf; fix the extractor or the source and regenerate.
- **Regenerate at the landing** of the change that moved the source, never for an unmerged branch. `.agent` names the command.
- **The drift gate** is `--check`. It compares extracted content only: the one `_generated:_ <date> from <repository> @ <commit> · codebase.py <version>` line under each leaf's H1 never counts, and a rerun over unchanged source leaves every file byte-identical.
- **Never deleted.** A leaf whose area left the source is replaced by an archived stub and its row marked ` _(archived)_`, so a citation of it keeps resolving. A continuation part (`codebase.<area>.<n>.md`) is pagination, not a leaf anyone cites: it is removed when the source no longer fills it. Cite an area by its first part.

## How the tree treats the tier

The linters treat it as any branch. The structural checks hold as they do everywhere, and the advisory ones are met by construction: a leaf that would pass 110 lines is split into parts, each part linked from its area's one Contents row, and the generator warns when the Contents table passes 15 rows, which a profile fixes by grouping areas. Every link a generated leaf carries is a sibling link in the index; extracted text is neutralised so it forms neither a link nor a placeholder.

File the tier once: create `public/<catalog>/<Product>/codebase/` by running the generator with `--write-agent`, then add its row to the product's index:
```md
    | [<Product> code base](./codebase/.index.md) | the generated code map: areas, surfaces, symbols per area |
```

## The worked example

The example instance carries two generated tiers: `examples/quillfeather/public/products/Tillwright/codebase/` from the TypeScript repository `examples/tillwright/`, and `…/Spinecard/codebase/` from the Go repository `examples/spinecard/` (run with `--lang go`). Each source has its `codebase.profile.json` at its root, and each tier's `.agent` names the command, run from this repository's root. The deploy smoke runs every such command with `--check`.

## The check

`bash modules/codebase/check.sh` regenerates the invented repository under `fixture/repo/` with `fixture/profile.json`, compares the result with `fixture/expected/` byte for byte (provenance lines excepted), runs `--check` against it, proves the walk and `git ls-files` agree and that a rerun rewrites nothing, then changes one source line in a copy and expects the drift to be reported. It exits with its fail count. When the generator's output changes on purpose, regenerate the expected tier and review its diff:

```sh
    python modules/codebase/codebase.py --repo modules/codebase/fixture/repo \
        --into modules/codebase/fixture/expected --profile modules/codebase/fixture/profile.json
```
