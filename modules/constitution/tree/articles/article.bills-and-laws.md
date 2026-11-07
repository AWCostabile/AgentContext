# Bills and laws: how a ruling is proposed, built from, enacted or withdrawn

_source:_ history/rulings/rulings.bills-and-law.md BL2–BL12, BL16–BL17; history/rulings/rulings.waves-and-close-out.md WK9; history/rulings/rulings.commits-and-pull-requests.md CP8, CP13
_reviewed:_ 2026-11-02

A ruling is not law the moment it is spoken. What a scoping conversation decides is filed as a
**bill**, the plan's prospective law, and the work is built from it; the owner enacts it once
the owner has seen what it produced. Until then the bill may be wrong, and it is corrected where
it stands. This holds for the constitution and for every product alike.

## A ruling starts as a bill

- A ruling made in a scoping conversation is filed as a bill (BL2). The kickoff cites it, agents
  build from it, and it may prove wrong.
- The constitution's bills live in `constitution/bills/`; a product's in
  `public/<catalog>/<Product>/bills/`, a branch made from `common/templates/branch` with the bills
  columns when its first bill arrives. A bill under `public/` is an authored shared leaf: it
  states rules, not schedules, and the smell S18 reads it like any other, so its Plan cell
  carries the counter (`2026-03-2`) without the word.
- A bill is named after its plan, `bill.<YYYY-MM>-<n>.<slug>.md`, and enacted as
  `rulings.<slug>.md`; its index row carries Plan, Created, Status and Enacted as (BL8).
- A bill ends with a **Not ruled** list: the questions the round saw and left open, so a later
  session can tell an unruled gap from a settled default (BL4).
- A clause that states a mechanism is marked **verify first** and names the spike that proves
  it; a clause that names positions, keys or sections rests on a read-only derivation spike run
  in the scoping session, its output pasted into the bill as the evidence (BL17).
- Every count a bill states is measured first, or omitted; "everywhere it is said" is the
  sentence to use when it is not measured (BL10).
- A default an orchestrator took stays "defaults taken" in the brief, and is lifted into a bill
  only once the owner has said yes to that line. Silence is not a ruling (BL16).

## A bill is amended in place

While it is a bill, a clause the build proves wrong, impossible or miscounted is corrected where
it stands, with a dated line directly beneath it (BL3):

    _amended YYYY-MM-DD:_ <what changed, and why>

The bill's own git history is the record of what it said before; no addendum leaf is filed. An
agent that must deviate from a clause writes the amendment line and names it in its report; it
never silently builds something else.

## Who cites a bill

Current law cites law, or an open bill as
`_source:_ <bill path> <ids> (bill — pending enactment)` (BL7). The open-bill form exists
because the operative files a wave builds must cite an article before the bill they rest on is
law. A bill whose status line begins `enacted` or `withdrawn` is no longer a source.

## The owner enacts

Nothing is enacted by a session alone (BL5). The owner enacts a bill at the walkthrough of a
build wave: nothing the wave produced enters an immutable tier until the build has been walked
(WK9). A documentation-only wave, with nothing to walk, opts out in one line and is enacted at
the owner's pull-request review. The branch that carries an enactment has its pull-request body
filed before it is raised (CP8), and the enactment commit names that pull request (CP13).

## Enactment, step by step: one action, one commit

1. **Inventory the dependants**: every design leaf or article whose `_source:_` names the bill
   (`grep -rl 'bills/<bill file>' constitution public`).
2. **Set the bill's status first**: one line, `_status:_ enacted <date> → <law path>`, keeping
   the plan and proposal facts. Done before the copy, it makes the law and the archived bill
   byte-identical, both naming where the law is.
3. **Copy the bill verbatim** into the tier's `history/rulings/rulings.<slug>.md` with a file
   copy, never an editor write, which a pre-write guard refuses there. The ids and the H1 stay
   the bill's own (BL6).
4. **Add the manifest row**, link text equal to the copy's H1, "Landed as" `—` until the pull
   request that carries the enactment merges.
5. **Update the bill's index row**: Status `enacted`, Enacted as the law path in backticks (a
   link would be a cross-branch row).
6. **Re-source every dependant** to the law path and ids, dropping the pending marker, and update
   what the law changes; for a constitutional amendment, the operative files it names.
7. **Tags follow content**: the rulings branch's `.tags` gains the searcher's new words.
8. **Prove it**: the linter at zero failures, no new index, tag or archive smell, and a reviewing
   agent's check that no current law still cites the bill.
9. **Commit once.** The private journal's entry is a separate commit of the private repository.

A bill is not stale by age. It is overdue when its plan has landed and its status line still
reads `bill`: the enactment was owed at that landing (BL12).

## A bill that fails is withdrawn

Its status line becomes `_status:_ withdrawn <date> — <reason>` and its row's Status
`withdrawn`. Nothing is copied into `history/`; a leaf that cited it is re-sourced on the law it
actually rests on, or archived (BL11).

## Forward only

Rulings already enacted are law and stay; no bill is reconstructed for them (BL9). The loop
begins with the first bill filed after adoption.
