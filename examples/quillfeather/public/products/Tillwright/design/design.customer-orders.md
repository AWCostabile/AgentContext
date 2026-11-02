# Tillwright design: customer orders

_source:_ public/products/Tillwright/history/rulings.till-and-orders.md ORDER1–ORDER3 2026-10-20
_reviewed:_ 2026-11-02

A customer order is a book a customer asked for that the shop does not hold. Tillwright tracks
it from the request to the collection.

## The life of an order

1. **Placed.** At the till or the orders screen: the title, the customer's name, and a phone
   number or an email address. An optional deposit is taken as an ordinary till transaction.
2. **Reserved.** The first copy of that title received after the order was placed is reserved
   for it, oldest order first. The receiving screen shows "for an order" beside the line.
3. **Notified.** The customer gets one text or email at the moment of reservation. The message
   names the shop, the title and the date the hold ends.
4. **Collected**, or **released**. A sale of the reserved copy closes the order. After fourteen
   days without collection the reservation lapses and the copy returns to available stock.

## Effect on stock

A reserved copy stays in on hand (it is on the premises) but leaves available stock, so the till
warns before selling it to someone else. Reservations are not movements: they live beside the
stock ledger and never change a count.

## Deposits

The shop sets whether a deposit is asked for and how much. A deposit is refunded at the till
like any other refund; a lapsed order keeps its deposit until a staff member refunds or keeps it.
