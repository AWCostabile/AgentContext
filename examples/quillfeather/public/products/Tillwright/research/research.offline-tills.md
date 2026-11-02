# How often a bookshop's till loses its connection

Fourteen customer shops reported their connection outages for the four weeks to 2026-10-15,
from their routers' logs and a note kept at the counter. The question behind it: does the till
need to work offline, or is a "please wait" screen enough?

## What the shops reported

| Measure | Result |
| ------- | ------ |
| Shops with at least one outage during opening hours | 11 of 14 |
| Outages during opening hours, all shops | 37 |
| Median outage | 9 minutes |
| Longest outage | 3 hours 40 minutes (a street-works cut) |
| Sales a shop typically makes in a nine-minute window on a Saturday | 4 to 7 |

## What it means

- A "please wait" screen would have turned customers away in most shops in a typical month. The
  till has to complete a sale with no connection.
- Card terminals in all fourteen shops have their own mobile connection, so card payment does
  not depend on the shop's broadband.
- The longest outage is under a day of sales, so a till store sized for thirty days is generous.

This research informed the offline-first till; the decision itself is in
[the till and customer-order rulings](../history/rulings.till-and-orders.md).
