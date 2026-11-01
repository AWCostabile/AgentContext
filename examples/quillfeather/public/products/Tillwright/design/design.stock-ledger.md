# Tillwright design: the stock ledger

_source:_ public/products/Tillwright/history/rulings.stock-ledger.md STOCK1–STOCK5 2026-10-20
_reviewed:_ 2026-11-02

The stock ledger is the one record of what a shop holds. Every other figure Tillwright shows
(on hand, available, on order) is computed from it.

## Movements

A movement is one row: a title, a quantity (positive in, negative out), a kind, a time, the
till or screen it came from, and the staff member. There are five kinds:

| Kind | Quantity | Written by |
| ---- | -------- | ---------- |
| receipt | positive | the receiving screen, one row per title per delivery |
| sale | negative | the till, when a sale reaches the ledger |
| return | positive | the till, when a customer returns a book |
| transfer | either | the transfer screen, a pair of rows between two branches of one shop |
| adjustment | either | the stock screen, with a reason and a name |

An adjustment's reason is one of damaged, lost, found or miscounted. A stocktake writes one
adjustment per title whose shelf count differs from the ledger, reason "miscounted".

## Counts

- **On hand** is the sum of a title's movements. It is computed on read and cached for a minute;
  nothing writes it.
- **Available** is on hand minus the copies reserved by customer orders (see the customer-orders
  design leaf).
- A row is never edited or deleted. The stock screen's "undo" writes the reversing movement.

## Keys

A new title is keyed by its thirteen-digit ISBN. A secondhand copy, or a title with none, gets a
shop-local code: `QF-` and six digits, unique within the shop and printed on the copy's label.
Two copies of one secondhand edition share a code only if the shop says so at receipt.
