# Adapters

An adapter adds what one agent harness can enforce on top of the neutral core. The core stays usable
without any of them.

## The contract

- **Keyed by harness, not by model.** An adapter is about the tool running the agent, not the model
  behind it.
- **Each adapter is a `README.md` and a `payload/`.** Stubs carry the README only.
- **An adapter may ship a `boot-check.sh`** beside its payload, never inside it: the deploy smoke
  runs it against a deployed instance to boot the harness headless, and reads exit 3 as "not run".
- **The payload is copied verbatim** into the instance root by the deployer's `--adapter <name>`.
- **The deployer is the one unpack.** No adapter has its own installer.
- **The neutral core never references an adapter.** Its entry point is `AGENTS.md`.

## The adapters

| Adapter | Status |
| ------- | ------ |
| [Claude Code](./claude-code/README.md) | written |
| [Codex](./codex/README.md) | stub, porting spec in section 3 |
| [Cursor](./cursor/README.md) | stub, porting spec in section 3 |
| [Gemini CLI](./gemini-cli/README.md) | stub, porting spec in section 3 |

## What every adapter README says

Three sections are required, in this order:

1. **What the adapter enforces.** What the harness does for the method once the payload is in place.
2. **What the core degrades to without it.** What stands in for that enforcement, and what is lost.
3. **What a port must reproduce.** The behaviour another harness has to match to count as a port.

A stub carries section 3 filled from the written adapter, so it doubles as a porting spec.
