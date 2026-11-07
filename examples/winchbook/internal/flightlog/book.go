package flightlog

import (
	"encoding/json"
	"net/http"
	"time"

	"example.com/winchbook/internal/queue"
)

// Book is the day's flight log, kept on the tablet until it is synced.
type Book struct {
	// Dir is where the day's sheet is written.
	Dir     string
	entries []Entry
}

// Open returns the book kept under dir.
func Open(dir string) *Book {
	return &Book{Dir: dir}
}

// Launch takes the front of a method's line into the log as an airborne entry.
func (b *Book) Launch(l *queue.Line, m queue.Method, at time.Time) (Entry, bool) {
	s, ok := l.Next(m)
	if !ok {
		return Entry{}, false
	}
	e := Entry{Glider: s.Glider, Pilot: s.Pilot, Method: string(m), Launched: at}
	b.entries = append(b.entries, e)
	return e, true
}

// Land closes the newest airborne entry for a glider.
func (b *Book) Land(glider string, at time.Time) bool {
	for i := len(b.entries) - 1; i >= 0; i-- {
		if b.entries[i].Glider == glider && b.entries[i].Airborne() {
			b.entries[i].Landed = at
			return true
		}
	}
	return false
}

// Handler serves the day's sheet as JSON.
func Handler(b *Book, l *queue.Line) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(b.entries)
	})
}
