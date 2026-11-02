# Claude Code payload

Everything in this directory except this README is copied verbatim onto an instance's root by
the deployer's `--adapter claude-code`, and listed with its hash in the instance's manifest so
an update can replace what was never edited: a one-line `CLAUDE.md` importing `AGENTS.md`; the
orchestration ground rules `KICKOFF.md`, `WORKER.md` and `CLOSEOUT.md`, each saying only what
this harness adds to the constitution module's neutral process documents; and `.claude/`, which
holds `settings.json` (the default output style, the hook registrations and a read-only
permission allow-list), the four hooks (`orient`, `classify-mode`, `guard-tiers`,
`lint-on-write`) with their path helper, the skills `/file`, `/find`, `/cure`, `/kickoff` and
`/retro` with the retro's window script under `tools/`, the subagent profiles (`librarian`,
`filer`, `scrutinizer`, `skeptic`, `brainiac`, and the three implementer tiers), the `scoping`
and `orchestrated` output styles, and six rule loaders that point a session at `rules/<name>.md`
when it touches the paths that rule governs.
