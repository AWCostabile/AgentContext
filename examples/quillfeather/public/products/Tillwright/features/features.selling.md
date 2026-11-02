# Tillwright: Selling

**State today.** The till sells offline: sales are stored on the till and sent to the ledger,
oldest first, when the connection returns, and card payments go through the counter terminal.
Customer orders reserve the first copy received, notify the customer by text or email, and hold
the copy for fourteen days. How it works: [the till](../design/design.till.md) and
[customer orders](../design/design.customer-orders.md); why:
[the till and customer-order rulings](../history/rulings.till-and-orders.md).

## 2026-W44 · Oct 26–Nov 1

**2026-10-30** — A customer order now reserves the first matching copy received and texts or
emails the customer at that moment; an uncollected copy returns to the shelf after fourteen days.
Reserved copies leave available stock, and the till warns before selling one. See
[customer orders](../design/design.customer-orders.md). Tillwright #9.

**2026-10-28** — The till keeps selling without a connection: each sale is stored on the till
first and sent to the ledger when the connection returns, and a resent sale is recognised by its
number. See [the till](../design/design.till.md) and
[its rulings](../history/rulings.till-and-orders.md). Tillwright #8.
