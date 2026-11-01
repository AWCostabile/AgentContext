# Claude Code payload

Not in this repository yet. The deployer's `--adapter claude-code` will copy this directory verbatim
into the instance root. It will hold:

- the pre-write tier guard hook;
- the orient hook that prints the journal at session start;
- the skills `/file`, `/find`, `/cure`, `/kickoff` and `/retro`;
- the subagents;
- the output styles;
- the grammar and tier rules, set up to load by path;
- the orchestration documents `KICKOFF.md`, `CLOSEOUT.md` and `WORKER.md`;
- a one-line `CLAUDE.md` that imports `AGENTS.md` with `@AGENTS.md`.
