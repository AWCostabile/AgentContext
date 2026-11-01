# Rulings: the public website

Ruled on 2026-10-20, when the old one-page site was replaced. The questions were what the site is
built with, what it promises, and how a shop starts a trial.

- **SITE1.** The site is static: Markdown pages built to plain HTML, no database and no server
  code. It deploys from the main branch on every merge.
- **SITE2.** Prices are written once, in one data file, and every page that shows a price reads
  that file. A price is never typed into a page.
- **SITE3.** The trial form asks for the shop's name, a contact email and the number of tills,
  and nothing else. It sends one email to the team inbox; the site stores nothing.
