# The deployer's refusals

When the deployer refuses, it exits 2, writes nothing, and the last line of its error output, prefixed `init.sh:`, is one of these.

| Message | Meaning | What to do |
| --- | --- | --- |
| `target is not empty: <path> holds …` | the path exists and holds files other than `.conf` | choose another path, or empty it |
| `no .conf: copy blueprint/common/.conf.example, fill it, pass --conf` | neither `--conf` nor `<path>/.conf` was found | the template's `SETUP.md`, step 2 |
| `missing key <KEY> in <conf>` | a required `.conf` line is absent or empty | fill it and run again |
| `bad catalog …` | a `CATALOGS` entry is not `[a-z0-9-]`, is repeated, or is reserved (`catalog`, `misc`, `scratch-tools`) | rename it in `.conf` |
| `adapter '<name>' has no payload in this release` | the adapter is a stub; the list printed above it says which are written | leave `--adapter` out, or pick one marked `written` |
| `no .agentcontext at target: …` | `--update` or `--adopt` on a directory that was not deployed by this tool | deploy fresh, or write the manifest by hand from a known release |
| `unknown module '<name>'` | `--adopt` names no module of this release; the list printed above it says which exist | check the spelling against the list |
| `module '<name>' has no payload in this release` | the module directory holds nothing to lay down | pick another module, or another release |
| `module 'change-log' is never adopted into an instance …` | the change-log workflow belongs to a repository | the template's `SETUP.md`, the change-log step: copy `post-merge.yml` by hand |
| `module '<name>' goes into the private tree, and <path> has none` | the module lives in `private/` (the local module), and this instance was deployed with `--no-private` | adopt it on the machine that holds the private tree |
| `module '<name>' is already recorded in common/.agentcontext …` | the module was adopted before | nothing to do: `--update` refreshes it |
| `the manifest is at the instance root, as an older release left it …` | `--adopt` on an instance deployed before the common directory, not yet updated | run the update (the template's `SETUP.md`, "How to update") first, then adopt |
| `not a template source (no blueprint/AGENTS.md)` | `--from` points at something that is not a release | check the extracted directory's name and contents |
