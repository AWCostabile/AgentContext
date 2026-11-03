# Bill 2026-11-2 — delegated agents

_status:_ bill · _plan:_ 2026-11-2, the plan after the first, not yet written · _proposed:_ 2026-11-04 by the owner, at the constitution's adoption

Edgewing adopted seven of the template's eight seed rulings leaves and deleted the eighth, agents
and budgets, whole. Its numbers were written for a larger team with longer sessions than
Edgewing runs, and several of its rulings answer problems Edgewing does not have: long-running
servers behind a time cap, idle notifications, keeping a cold prompt cache warm. This bill
proposes the delegation law Edgewing will hold instead, smaller and with its own numbers, to be
proven by the first plan that runs under it and enacted at that plan's walk. Until then the
articles and the process files cite it as a bill pending enactment.

## DA — how a delegated agent works

- **DA1.** One surface per implementation job; the full test battery stays with the
  orchestrator, and a delegated agent reruns only the tests it touched. The baseline battery is
  green on the main line before the first change.
- **DA2.** A job briefed as fitting one context is sized before it is spawned: its reading
  listed, its writes named.
- **DA3.** A delegated agent aims at about 200k tokens and may run to 350k with care; it never
  reaches a context compaction, and hands back at its last commit boundary instead.
- **DA4.** Every git write names its repository; a command that writes checks its working
  directory first; a manifest row is edited by an exact-string replace in a script, never by a
  stream editor.
- **DA5.** Each delegated agent writes under its own scratch subdirectory, named in its prompt,
  and its commits on a shared checkout are path-scoped.
- **DA6.** While another session is active on the machine, a coordinating session writes no shared
  private file; an isolated leaf with a path-scoped commit is safe.
- **DA7.** A delegated agent never invents: when the brief conflicts with the code, a gate fails,
  or a clause cannot be built as written, it stops and reports, and a bill clause it must
  deviate from gets a dated amendment line named in its report.
- **DA8.** A delegated agent's final message is data for its orchestrator: the outcome first,
  then the evidence, then a short block of the decisions, traps and invariants worth keeping.
- **DA9.** Agent profiles are operative files and cite the articles they implement; orchestration
  settings share one configuration prefix, `ORCH_`.
- **DA10.** Edgewing runs `ORCH_BUDGET=lean`: the orchestrator works inline, delegates only where
  a job's reading would outgrow its own context, keeps working while a delegated job runs, and
  closes out with one short record.

## The caps, measured again

Adoption cut three rules from the orchestrator's ground rules and one step from the close-out's.
Measured after the cut: `ground-rules.orchestrator.md` 73 lines (cap 100),
`ground-rules.worker.md` 52 (cap 80), `ground-rules.closeout.md` 75 (cap 100). No cap moves.

## Not ruled

- Whether a second implementation tier, a cheaper agent for mechanical edits, earns a ruling of
  its own or stays a profile choice.
- What replaces the seed's keep-alive if a session's prompt cache proves shorter than Edgewing's
  waits; the seed's rule was not carried over.
- Whether the token numbers in DA3 hold for the reviewing agent too, or it gets its own.
