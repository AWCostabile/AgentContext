# Cursor

Stub, no payload. A port to this harness is held to the checklist in
[Contributing](../README.md#contributing); the written [Claude Code adapter](../claude-code/README.md)
is the reference implementation of it.

## 1. What the adapter enforces

Not written; the core stands alone.

## 2. What the core degrades to without it

Not written; the core stands alone. The linter and convention stand in for every enforcement in
the checklist: a tier violation is caught when `scripts/cure.sh` runs, not when it is written; a
sibling's instruction is read by the agent on first touch, as `AGENTS.md` asks.

## 3. What a port must reproduce

Each item of [Contributing](../README.md#contributing), answered in the pull request that adds the
payload: the file that meets it, or the line in section 2 that leaves it to convention.
