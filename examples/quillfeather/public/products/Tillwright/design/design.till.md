# Tillwright design: the till

_source:_ public/products/Tillwright/history/rulings.till-and-orders.md TILL1–TILL3 2026-10-20
_reviewed:_ 2026-11-02

The till is the counter screen: it scans books, takes payment and prints the receipt. It is
built to keep selling when the shop's connection drops.

## Offline first

- Every sale is written to the till's own store before anything else. The store is a single
  file on the till machine and holds at least thirty days of sales.
- A background sender passes stored sales to the shop's ledger in the order they were made.
  A sale the ledger has already seen (same sale number) is acknowledged and skipped, so a
  resend is harmless.
- The till shows a small "offline: 12 sales waiting" badge while sales are queued. Nothing else
  about selling changes.

## Payment

- Card payments go through the card terminal on the counter, which has its own connection.
  The till never sees a card number; it records the terminal's approval code.
- Cash and card sales complete offline. Gift-card redemption needs the balance from the ledger,
  so it waits for the connection and the till says so.

## Sale numbers and receipts

A sale number is made on the till: the till's letter, the date and a counter, for example
`B-20261030-0042`. It is printed on the receipt, so a receipt is valid before the sale reaches
the ledger, and a return can find its sale on any till once it has.

## What it does not do

The till keeps no stock count of its own. When offline it sells a book it cannot see in the
ledger cache as a "title not found" line, which the stock screen reconciles later.
