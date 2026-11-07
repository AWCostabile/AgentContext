# Plan 2026-11-1 — Winchbook: the day's sheet

_created:_ 2026-11-02 · _repository:_ winchbook · _branch:_ feature/DaySheet

## What it is for

At the end of a flying day a club copies the log by hand onto its paper launch sheet, because the
log lives only in the tablet's memory and is gone when the service restarts. This plan writes the
day's log to a sheet file under the tablet's data directory as each flight lands, so a restart
loses nothing and the club's treasurer can bill flights from the file. It builds on the log as the
launch-line rulings left it ([the launch line and the day's log](../../../../../public/products/Winchbook/design/design.launch-line.md)).

## HARD RULES

- The sheet is written on the tablet, with no network, as the log is kept today.
- One sheet per flying day, named by its date; a landing rewrites that day's sheet whole, never
  appends a half line.
- A restart reads the day's sheet back, airborne entries included, before the first launch.
- The queue is never written to the sheet: a slot that never launched leaves no trace.

## Steps

1. **The sheet.** Write the day's entries to `<data>/<date>.csv` at every launch and landing.
2. **The restart.** Read the day's sheet back at start, so an airborne glider can still land.
3. **Proof.** `go test ./...` green with the sheet's tests; a day walked on the demo tablet with
   the service restarted mid-afternoon.

## Settle with the owner

- Whether the sheet's columns follow the clubs' paper launch sheet or the treasurer's billing
  export. Settled 2026-11-03: the paper sheet's order, so the club can print it as it is.
