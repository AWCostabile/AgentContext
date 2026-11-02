# Examples

Worked examples: filled instances of the template, each deployed by `init.sh` and then filled by
hand, so that a reader can see indexes with something in them. Every name in them is invented.

| Example | What it shows |
| ------- | ------------- |
| [Quillfeather: a worked example](./quillfeather/README.md) | a six-person bookshop-software company: two products and a website designed, ruled and logged; a plan in flight with its kickoff, pull-request record and journal |

Each example is linted by `tools/deploy-smoke.sh`: `cure.sh` and `smell.sh` must come back clean
on it, and no placeholder may be left outside its `templates/`.
