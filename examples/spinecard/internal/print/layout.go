package print

import (
	"html"
	"io"
)

// Slot names one position on a sheet, counted from the top left by rows.
type Slot struct {
	Row, Column int
}

// SlotOf returns the slot of the i-th card on a sheet.
func SlotOf(i int) Slot {
	return Slot{Row: i / 2, Column: i % 2}
}

// Write renders sheets as one printable page: a grid of cards with thin cut lines.
func Write(w io.Writer, sheets []Sheet) error {
	if _, err := io.WriteString(w, "<!doctype html><link rel=stylesheet href=/sheet.css>"); err != nil {
		return err
	}
	for _, s := range sheets {
		io.WriteString(w, "<div class=sheet>")
		for _, c := range s.Cards {
			io.WriteString(w, "<div class=card>"+html.EscapeString(c.Words)+"</div>")
		}
		io.WriteString(w, "</div>")
	}
	return nil
}
