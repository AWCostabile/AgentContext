# Rulings: the till and customer orders

Ruled on 2026-10-20, with the stock ledger rulings, after a customer shop lost an afternoon of
sales during a broadband outage. Two questions: what the till does without a connection, and
how a book ordered for a customer is held for them.

- **TILL1.** The till works offline. A sale is written to the till's own store first and sent
  to the shop's ledger when the connection returns, oldest first.
- **TILL2.** A card payment needs the terminal, never the connection. Cash and card sales both
  complete offline; only gift-card redemption waits for the connection.
- **TILL3.** A receipt carries the sale's own number, made on the till, so a customer's receipt
  is valid before the sale reaches the ledger.
- **ORDER1.** A customer order reserves the first matching copy received after it is placed.
  The reserved copy is not on sale and does not count as available stock.
- **ORDER2.** The customer is told by text or email, whichever they gave, the moment the copy
  is received. The shop holds it for fourteen days, then it returns to the shelf.
- **ORDER3.** A deposit is optional and set by the shop. A refunded deposit is a till
  transaction like any other.
