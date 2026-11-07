# Examples

Worked examples: filled instances of the template, each deployed by `init.sh` and then filled by
hand, so that a reader can see indexes with something in them. Every name in them is invented.

| Example | What it shows |
| ------- | ------------- |
| [Quillfeather: a worked example](./quillfeather/README.md) | a six-person bookshop-software company: two products and a website designed, ruled and logged; a plan in flight with its kickoff, pull-request record and journal |
| [Tillwright source](./tillwright/README.md) | a small invented TypeScript repository, the point of sale and stock service the example's Tillwright code map is generated from |
| [Spinecard source](./spinecard/README.md) | a small invented Go repository, the card printer the example's Spinecard code map is generated from |

Each example is linted by `tests/tools/deploy-smoke.sh`: `cure.sh` and `smell.sh` must come back clean
on it, and no placeholder may be left outside its `common/templates/`. The smoke also runs every example
code map's command with `--check`, so a source repository here that changes without its code map
being regenerated fails it.
