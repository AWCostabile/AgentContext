# Adapters

An adapter adds what one agent harness can enforce on top of the neutral core. The core stays usable
without any of them.

## The contract

- **Keyed by harness, not by model.** An adapter is about the tool running the agent, not the model
  behind it.
- **Each adapter is a `README.md` and a `payload/`.** Stubs carry the README only.
- **The payload is copied verbatim** into the instance root by the deployer's `--adapter <name>`.
- **The deployer is the one unpack.** No adapter has its own installer.
- **The neutral core never references an adapter.** Its entry point is `AGENTS.md`.

## The adapters

| Adapter | Status |
| ------- | ------ |
| [Claude Code](./claude-code/README.md) | written; its payload is not in this repository yet |
| [Codex](./codex/README.md) | stub, no payload |
| [Cursor](./cursor/README.md) | stub, no payload |
| [Gemini CLI](./gemini-cli/README.md) | stub, no payload |

## What every adapter README says

Three sections are required, in this order:

1. **What the adapter enforces.** What the harness does for the method once the payload is in place.
2. **What the core degrades to without it.** What stands in for that enforcement, and what is lost.
3. **What a port must reproduce.** The behaviour another harness has to match to count as a port.

A stub carries section 3 filled from the written adapter, so it doubles as a porting spec.
