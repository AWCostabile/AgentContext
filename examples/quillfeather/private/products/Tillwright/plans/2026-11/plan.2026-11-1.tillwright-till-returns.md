# Plan 2026-11-1 — Tillwright: returns at the till

_created:_ 2026-11-01 · _repository:_ tillwright · _branch:_ feature/TillReturns

## What it is for

A customer brings a book back. Today the till can only record a return as a stock adjustment,
which loses the link to the sale and refunds nothing. This plan makes a return a till transaction:
it finds the sale from the receipt, puts the copy back into stock, and refunds the way the customer
paid. It builds on the stock ledger's `return` movement kind and the till's receipt numbers, both
already in place ([the stock ledger](../../../../../public/products/Tillwright/design/design.stock-ledger.md),
[the till](../../../../../public/products/Tillwright/design/design.till.md)).

## HARD RULES

- A return writes one `return` movement per copy and never edits the sale's movements.
- A refund goes back to the payment method the sale used: cash to cash, card through the terminal.
  No store credit in this plan.
- A return without a receipt is out of scope; the till says so and offers nothing.
- Returns work offline, the same way sales do: stored on the till first, sent later.

## Waves

1. **The return screen.** Scan or type a sale number; pick the lines coming back; show the refund.
2. **Refunds.** Cash refund opens the drawer; card refund goes to the terminal as a refund request.
3. **Offline.** A return queued on the till, sent after the sale it refers to.
4. **Proof.** The till's test suite green; a return walked end to end on the demo shop's till.

## Settle with the owner

- Whether a sale older than ninety days can be returned at the till at all.
