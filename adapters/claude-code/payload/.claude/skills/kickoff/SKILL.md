---
name: kickoff
description: Generate the paste-ready kickoff prompt for an orchestrated piece of work from its plan and its bill, with the real gate values read from the repositories. Needs the constitution module. Use when asked to "write the kickoff", "generate a kickoff prompt", "prepare the brief", or whenever a scoping conversation has produced a plan.
argument-hint: "<plan leaf path | plan name> [--repo <name>]"
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git -C:*), Bash(git rev-parse:*), Bash(bash common/scripts/find.sh:*)
---

# Generate a kickoff

**This skill depends on the constitution module.** When `constitution/` is absent from the
tree root, say so and write the kickoff by hand from the plan, following the anatomy in
`.claude/process/KICKOFF.md`; stop here.

Arguments: `$ARGUMENTS` (`--repo` names the repository the work happens in; otherwise the
plan says).

1. **Read the guide.** `constitution/process/kickoff-guide.md` is the law of a kickoff's
   anatomy and gates; this skill only drives it.
2. **Resolve the leaves.** A path is used as given; a name resolves per `/find` to the plan
   leaf in the product's private mirror (`private/<catalog>/<Product>/plans/<YYYY-MM>/`)
   and to the bill the plan names. Read the plan's section for this piece of work and the
   clause ids it cites, not the whole documents.
3. **Pin the brief.** `git -C private log -1 --format=%h -- <plan path under private/>`:
   the commit the kickoff's `Brief:` line names, so a later amendment shows in one `git log`.
4. **Read the gate values, read-only, never fetched**: the repository's `main` and its
   distance from its upstream (`git -C <repo> rev-parse --short main`, `… origin/main`), and
   every version constant or shape the plan builds on, reported as `file:line`.
5. **Fill `constitution/process/templates/kickoff.md`.** Every placeholder replaced, its
   guidance comments dropped, its first two lines verbatim. Each gate is phrased as a PROOF of
   what it cares about, never as the spelling of a command; every plan clause marked
   **verify first** becomes a gate naming the spike that proves it. State only what is
   particular to this piece of work: nothing `.claude/process/KICKOFF.md` or the guide already says. Role
   words only ("the owner", "agents"), never a personal name.
6. **Output** the prompt in one fenced block, then one line OUTSIDE it: the model
   recommendation and what the work gates on.
7. **File it only when asked**, through `/file` (kind `kickoff`, beside its plan's month and
   number). A prompt no agent has run from yet is regenerated where it stands; one an agent
   has run from is frozen, and a later prompt for the same plan goes below it.
