# Retrospective 2026-11-01 — the October landings

_window:_ 2026-10-20 to 2026-10-31 · _landed:_ Website #3, Tillwright #7, #8, #9, Spinecard #4

**What landed.** Four rulings leaves and their changes: the static website with one price file;
the stock ledger with computed counts; the offline till; customer orders with holds; dated prices
on Spinecard cards. Every change has its feature-log entry and its design leaf.

**What went well.** Writing the rulings first, on one day, made the five changes small: each pull
request built one rulings leaf and nothing else. The offline-till outage survey settled a debate in
an afternoon that had run for weeks.

**What did not.** The stock ledger and the till rulings were filed before anyone checked how
returns would fit; returns needed no new ruling only by luck. Spinecard read the price from
Tillwright without a date until a shop pointed at a stale card.

**For the next block.** Ask "what reverses this?" of every new transaction before ruling it. The
returns plan starts from that question.

**Trajectory.** Healthy: five merges in nine working days, no pull request reopened, every design
leaf reviewed on the day it was written.
