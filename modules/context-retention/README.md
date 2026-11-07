# The context-retention module

What an agent carries into a session, kept small and kept attached. Two concerns, one module,
because both are about the project an agent is sitting in:

- **A project can move.** People rename and move folders. An agent harness files what it learned
  about a project — its memory, its past conversations — under the project's path, so a moved
  folder is a stranger to it: the history is still on disk, under a name nobody will look for.
  The module gives every project in the workspace a stable identity that does not change when
  the folder does, and reports a move so it can be repaired.
- **A session should open with its own instruction.** A workspace of several repositories carries
  several instruction files. Loading them all at the start of every session costs their tokens
  every time, for repositories the session may never enter. The instance's `AGENTS.md` says what
  to do instead: read a project's identity and its instruction when you first touch that project,
  and not before.

```
<project>/.agents/.id.meta          the identity: three lines, never a path, never committed
~/.config/agentcontext/projects     the map: one line per id — id, name, the last path seen, when
```

## The identity file

`.agents/.id.meta` sits inside a project's `.agents/` directory, the cross-framework home of
agent-facing files (`init` creates the directory when absent). It is a closed shape, `key=value`
lines like `.conf`:

```
id=lantern-3f9a1c
name=lantern
created=2026-11-02
```

`id` is the project's stable identity: its slug and a short random suffix, minted once. `name` is
the slug, as the workspace names the folder. `created` is the day it was minted. Nothing else is
ever written there: no location, no harness key, nothing about the machine. Paths are machine
facts and live in the map in the user's home.

**It is a workspace file and must never be committed.** Committing it would hand one user's
identity to every clone of the repository. The module therefore asks, once, to add
`.agents/.id.meta` to git's **global** excludes, the file `core.excludesFile` names (created at
`~/.config/git/ignore` and the key set when it is unset; appended to when it exists), with the
reason printed first and the strong recommendation that it be ignored. It writes that line only on
an explicit yes. A project's own `.gitignore` is never touched: the file is per user, so the ignore
is too. `init` also asks git whether the file is ignored in each project it touched and warns when
it is not.

## The verbs

From the instance root, with the module copied to `common/modules/context-retention/`:

```sh
    bash common/modules/context-retention/meta.sh init [<path>...]    identities where absent; the excludes question
    bash common/modules/context-retention/meta.sh check [<path>...]   current, moved, copied, first seen, or none
    bash common/modules/context-retention/meta.sh list                 the map
```

With no `<path>`, the projects are the instance itself and every folder the instance's workspace
file (`<Name>.code-workspace` at the root) names, so the workspace stays the one place the
repositories are listed. `init` keeps an identity it finds and never mints a second. `check`
compares each project's current path with the one recorded for its id: the same path is current;
a different path whose old folder is gone is a **move**, reported once with the old and the new
location and then recorded; a different path whose old folder still carries the same id is a
**copy**, reported until the copy is given an id of its own (remove its file and run `init` there).
A file outside the closed shape is a fail; a project with no identity is information, with the
`init` line to run.

Options: `--root <dir>` the instance root (default the current directory); `--name <slug>` with
`init` and one path, the slug to use instead of the folder's name; `--yes` or `--no`, the excludes
question answered without a prompt (a run with no terminal and neither answers no, and says so);
`--porcelain` with `check`, one tab-separated row per project (`ok`, `moved`, `new`, `copied`,
`absent` or `bad`, the id, the path, and for a move or a copy the old path) for a hook to read.
Exit 0 clean, the number of fails otherwise, 2 for a usage error or a refusal when nothing was
written.

## The map

`~/.config/agentcontext/projects` (under `$XDG_CONFIG_HOME` when that is set) is tab-separated,
one line per id: the id, the name, the last path seen (resolved; on Windows in its drive-letter
spelling with forward slashes) and the date it was seen. It is rewritten whole by `init` and
`check`, is a fact about one machine, and is never copied anywhere. `list` prints it.

## Adoption

Copy `modules/context-retention/` into the instance's `common/modules/`, run `init` from the instance root and answer
the excludes question, then run `check` whenever a folder has been renamed or moved, or let an
adapter run it at every session start. The core never depends on the module: an instance without
it loses only the move report and the identity line; the first-touch rule in `AGENTS.md` stands
on its own. Bash and the core's `common/scripts/lib-scopes.sh` are all it needs.

## What an adapter adds

The module names no agent harness and repairs nothing: it says that project `lantern-3f9a1c` was
at one path and is now at another. Where a harness files a project's memory and history under a
key derived from the path, its adapter knows the derivation, and can turn the report into a
repair at session start, or into one line telling the user where the old material sits. The
adapter also owns whatever its harness offers for loading only the instance's own instruction at
start; the rule itself is the core's.

## The check

`bash modules/context-retention/check.sh` builds a throwaway HOME, a fake instance with a
workspace file and two fake projects beside it, and proves the module end to end without touching
the user's map or git configuration: the identity written once and never twice, the closed shape
with no path in it, the projects taken from the workspace file, the excludes line written on a yes
(the key set when it was unset, the default file appended to when it exists) and not on a no, and
never twice; a move reported once and then current; a copy reported as a copy; a malformed file
a fail; an unknown verb and a root with no `.conf` refused with nothing written; the instance still
linting. It exits with its fail count. The deploy smoke runs it.
