# Rulings: the stock ledger

Ruled on 2026-10-20, when two customer shops reported on-hand counts that drifted from the
shelves after a week of returns and corrections. The question was where a count comes from and
who may change it.

- **STOCK1.** An on-hand count is never stored. It is the sum of the title's movements in the
  stock ledger, computed when asked for.
- **STOCK2.** A movement is one of five kinds: receipt, sale, return, transfer, adjustment.
  There is no sixth kind; anything else is an adjustment with a reason.
- **STOCK3.** A movement is never edited or deleted. A mistake is corrected by a later
  movement that reverses it.
- **STOCK4.** New titles are keyed by their thirteen-digit ISBN. A secondhand copy, or a title
  with no ISBN, gets a shop-local code with the prefix `QF-`, printed on its label.
- **STOCK5.** An adjustment needs a reason chosen from a short list (damaged, lost, found,
  miscounted) and the name of the staff member who made it.
