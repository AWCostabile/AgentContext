# The day's sheet

_branch:_ feature/DaySheet
_landed as:_ —

The day's flight log is now kept on disk as well as in memory. Every launch and every landing
rewrites the day's sheet, one file per flying day under the tablet's data directory, in the column
order of a club's paper launch sheet, so it prints as the club already reads it. A restart reads
the day's sheet back before the first launch, so a glider airborne at the restart can still land.

## What moved

- A sheet file per flying day, `<data>/<date>.csv`, rewritten whole at every launch and landing.
- The columns: glider, pilot, instructor, method, launched, landed, minutes.
- At start, the day's sheet is read back into the log, airborne entries included.
- The queue is not written: a slot that never launched leaves no trace on the sheet.
- No network is involved at any point.

## Proof

- `go test ./...`: 14 tests pass (3 before, 11 added for the sheet and the restart).
- `gofmt -l .` prints nothing; `go vet ./...` is clean.
- A flying day walked on the demo tablet: twelve launches, the service restarted with two gliders
  airborne, both landed afterwards and the sheet matched the paper copy line for line.
