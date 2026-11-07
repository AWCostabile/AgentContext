# Winchbook design: the launch line and the day's log

_source:_ public/products/Winchbook/history/rulings.launch-line.md LINE1–LINE6 2026-10-14
_reviewed:_ 2026-11-04

The launch point is the end of the field where gliders wait to be launched. Winchbook runs on one
tablet there: it keeps the order gliders go up in, and writes each flight into the day's log as it
happens.

## One line per method

A club launches by winch, behind a tow plane (aerotow), or both. Winchbook keeps one line per
method in use that day, set when the tablet starts; a club that names no method runs a winch line
only. The lines are independent: the winch and the tug each take the front of their own line.

| A slot holds | Comes from |
| ------------ | ---------- |
| The glider | its registration, typed or picked from the club's fleet |
| The pilot | the member flying, by membership number |
| The method | the line it joined |
| The instructor | set only when the flight is a lesson |

## Joining and refusals

- A slot joins at the back of its method's line.
- A glider already waiting in a line is refused a second place in it, so a double tap at the
  tablet never sends one glider up twice. The refusal is shown, never silently ignored.
- A glider may wait in both lines at once: a pilot who will take whichever launch comes first.

## Launching into the log

When the winch driver or the tug pilot calls ready, the front slot of that line leaves the queue
and becomes an entry in the day's log, airborne, stamped with the launch time. Nothing is written
to the log before the launch: a slot that leaves the line unlaunched leaves no trace.

## Landing

A landing closes the newest airborne entry for that glider and stamps the landing time. The
flight's length is whole minutes, rounded down, and an airborne flight has none yet. A landing
for a glider with no airborne entry is refused.

## No signal

The far end of an airfield rarely has a signal. The queue and the log live on the tablet; nothing
in launching or landing waits on a network. The log is kept under the tablet's data directory
until it is synced.

How a change to all of this is committed and reviewed: [Winchbook code standards](./design.code-standards.md).
