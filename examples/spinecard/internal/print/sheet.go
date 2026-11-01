// Package print lays cards out on a sheet of plain card stock and serves it to the browser.
package print

import (
	"net/http"
	"time"

	"example.com/spinecard/internal/cards"
)

// PerSheet is how many cards a sheet holds: two columns of four.
const PerSheet = 8

// Sheet is one page of cards. A short sheet leaves its other slots blank.
type Sheet struct {
	Cards []*cards.Card
}

// Sheets splits cards into sheets of PerSheet, in order, never repeating a card.
func Sheets(all []*cards.Card) []Sheet {
	var out []Sheet
	for len(all) > 0 {
		n := min(PerSheet, len(all))
		out = append(out, Sheet{Cards: all[:n]})
		all = all[n:]
	}
	return out
}

// Blanks counts the empty slots on a sheet.
func (s Sheet) Blanks() int { return PerSheet - len(s.Cards) }

// Handler serves the queued cards as one printable page; the browser's own dialog prints it.
func Handler(cat cards.Catalog, queued func() []*cards.Card) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var ready []*cards.Card
		for _, c := range queued() {
			if c.Fill(cat, time.Now()) == nil {
				ready = append(ready, c)
			}
		}
		w.Header().Set("Content-Type", "text/html")
		_ = Write(w, Sheets(ready))
	})
}
