# Seed rulings: agents and budgets

_status:_ seed — adopt, amend or delete

How an orchestrating session delegates, what a delegated agent may do to a repository, how much
context a job may spend, and how several writers share one machine. The article on
[the wave ground rules](../../articles/article.wave-ground-rules.md), the work-journal article's
concurrency section and the process documents rest on these.

- **AG1.** One surface per implementation job; the full test battery stays with the orchestrator,
  and a delegated agent reruns only the tests it touched.
- **AG2.** A job briefed as fitting one context is sized before it is spawned.
- **AG3.** A delegated agent aims at about 300k tokens and may run to 500–600k with care (defaults,
  tuned per harness and model); it never reaches a context compaction, and hands back at its last
  commit boundary instead.
- **AG4.** Every git write names its repository; a command that writes checks its working
  directory first; a call that depends on a changed directory is never paired with another; a
  manifest row is edited by an exact-string replace in a script, never by a stream editor.
- **AG5.** Concurrency is the normal case: each agent writes under its own scratch subdirectory,
  commits on a shared checkout are path-scoped, and a wave's writes go to a worktree when
  another branch is in flux on the shared checkout.
- **AG6.** While another session is active on the machine, a coordinating session writes no shared
  private file; an isolated leaf with a path-scoped commit is safe.
- **AG7.** Long-running servers a wave needs run in a visible window from the start, never in a
  background task with a time cap.
- **AG8.** An idle notification gets no reply unless something changed.
- **AG9.** A delegated agent never invents: when the brief conflicts with the code, a gate fails,
  or a clause cannot be built as written, it stops and reports, and a bill clause it must
  deviate from gets a dated amendment line named in its report.
- **AG10.** A delegated agent's final message is data for its orchestrator: the outcome first,
  then the evidence, then a short block of the decisions, gotchas and invariants worth keeping.
- **AG11.** Agent profiles are operative files and cite the articles they implement; orchestration
  settings share one configuration prefix, `ORCH_`.
- **AG12.** Under a lean budget the orchestrator works inline, delegates only where a job's reading
  would outgrow its own context, keeps working while delegated jobs run in the background, and
  scales the close-out ceremony down to one short record.
- **AG13.** Where a session's prompt cache expires sooner than the work between its turns, the
  orchestrator keeps the session warm with a cheap periodic action rather than letting a long
  context go cold.
