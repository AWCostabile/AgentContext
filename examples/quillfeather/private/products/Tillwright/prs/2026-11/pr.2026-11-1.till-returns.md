# Returns at the till

_branch:_ feature/TillReturns
_landed as:_ —

A return is now a till transaction. The till finds the original sale from the number on its
receipt, puts each returned copy back into stock with a `return` movement, and refunds the way the
customer paid: cash from the drawer, a card through the terminal as a refund request. A return
made offline is stored on the till and sent after the sale it refers to, so the ledger never sees
a return before its sale.

## What moved

- A return screen on the till: scan or type a sale number, tick the lines coming back, confirm.
- One `return` movement per copy, carrying the sale number it reverses. The sale's own movements
  are untouched.
- Cash refunds open the drawer; card refunds are sent to the terminal and recorded with its
  approval code.
- The till's sender orders a queued return after the sale it names, even when both are queued.
- Sales older than ninety days are refused at the till with a message pointing to the stock screen.
- A return without a receipt is refused; there is no store credit.

## Proof

- The till suite: 431 tests pass (412 before, 19 added for returns).
- A cash return and a card return walked end to end on the demo shop's till, online and with the
  network cable pulled; both reached the ledger in order once it was plugged back in.
