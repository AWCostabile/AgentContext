package queue

import (
	"encoding/json"
	"net/http"
)

// Handler serves the line: GET lists each method's slots, POST joins one.
func Handler(l *Line) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			var s Slot
			if err := json.NewDecoder(r.Body).Decode(&s); err != nil || !l.Join(s) {
				w.WriteHeader(http.StatusConflict)
				return
			}
		}
		json.NewEncoder(w).Encode(l.slots)
	})
}
