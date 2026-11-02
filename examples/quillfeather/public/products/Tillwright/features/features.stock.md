# Tillwright: Stock

_reviewed:_ 2026-11-02

**State today.** A shop's stock is a ledger of movements (receipts, sales, returns, transfers
and adjustments), and every count Tillwright shows is computed from it; nothing stores a count.
New titles are keyed by ISBN, secondhand copies by a shop-local code printed on their label.
Stocktakes write one adjustment per differing title. How it works:
[the stock ledger](../design/design.stock-ledger.md); why:
[the stock-ledger rulings](../history/rulings.stock-ledger.md).

## 2026-W44 · Oct 26–Nov 1

**2026-10-27** — On-hand counts are computed from the stock ledger on every read instead of being
stored, so a correction can no longer leave a count out of step with the shelves. A correction is
a reversing movement; the stock screen's undo writes one. See
[the stock ledger](../design/design.stock-ledger.md) and
[its rulings](../history/rulings.stock-ledger.md). Tillwright #7.
