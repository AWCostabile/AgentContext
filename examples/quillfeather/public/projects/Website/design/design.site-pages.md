# Website design: pages, prices and the trial form

_source:_ public/projects/Website/history/rulings.website.md SITE1–SITE3 2026-10-20
_reviewed:_ 2026-11-02

The website is a static site: Markdown pages in the repository, built to plain HTML, deployed from
the main branch on every merge. It has no database and runs no code on a server.

## Pages

| Page | Says |
| ---- | ---- |
| Home | what Quillfeather makes, for whom, and the trial button |
| Tillwright | the till, stock and customer orders, with screenshots |
| Spinecard | the recommendation cards, with a printed sheet photographed |
| Pricing | the monthly price per till and per shop, read from the price file |
| Trial | the trial form |

## Prices

Every price lives in one data file, `prices.yaml`, keyed by product and plan. A page shows a price
only through the price include, so a price change is one edit to one file. A page that types a
price fails the site's build check.

## The trial form

Three fields: the shop's name, a contact email, the number of tills. Submitting it sends one email
to the team inbox through the hosting service's form handler. The site keeps no copy and sets no
tracking cookie.
