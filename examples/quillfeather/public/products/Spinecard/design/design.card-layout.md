# Spinecard design: the card and its sheet

_source:_ public/products/Spinecard/history/rulings.card-printing.md CARD1–CARD4 2026-10-20
_reviewed:_ 2026-11-02

A card is a small printed recommendation that sits under a book on the shelf. Spinecard composes
it from a Tillwright title and a staff member's words, and prints it on plain card stock.

## What a card says

| Line | Comes from |
| ---- | ---------- |
| Title and author | Tillwright, read at the moment of printing |
| The recommendation | typed by a staff member, at most 280 characters |
| The signature | the staff member's first name, from their Tillwright login |
| Price and date | Tillwright's price at the moment of printing, and that day's date |

Spinecard stores only the recommendation text and who wrote it. Everything else is read fresh
from Tillwright each time a card is printed, so a reprint picks up a new price.

## Refusals

- A title Tillwright does not hold cannot get a card; the search only offers held titles.
- A recommendation over 280 characters is refused with the count shown. It is never truncated,
  because a cut sentence on a shelf reads worse than no card.

## The sheet

Eight cards to a sheet of plain card stock, two columns of four, with thin cut lines. The sheet
prints from the browser's own print dialog; no driver or label printer is needed. A sheet with
fewer than eight cards leaves the rest blank rather than repeating a card.

## Staleness

The printed date sits beside the price. Shops sort their card list by that date to find cards
whose price may have changed.
