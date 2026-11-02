// Package store keeps lamps in memory. It is safe for one writer.
package store

import "sort"
import "sync"

// Mode says how a lamp is lit.
type Mode int

// The modes a lamp can be in.
const (
	// Off is the zero mode.
	Off Mode = iota
	On
	Blinking
)

var (
	// ErrMissing is returned when a lamp is not on the board.
	ErrMissing = errorString("missing lamp")
	maxLamps   = 64
)

// Store holds the board.
type Store struct {
	// Path is where the board is saved.
	Path  string `json:"path"`
	lamps map[string]Mode
	sync.Mutex
}

// Reader reads lamps.
type Reader interface {
	// Get returns one lamp's mode.
	Get(id string) (Mode, error)
	Lister
}

// Lister lists lamp ids.
type Lister interface {
	IDs() []string
}

type errorString string

func (e errorString) Error() string { return string(e) }

// New opens a store at path.
func New(path string) *Store {
	return &Store{Path: path, lamps: map[string]Mode{}}
}

// Get returns the mode of lamp id, or ErrMissing.
func (s *Store) Get(id string) (Mode, error) {
	m, ok := s.lamps[id]
	if !ok {
		return Off, ErrMissing
	}
	return m, nil
}

// Len counts the lamps.
func (s *Store) Len() int { return len(s.lamps) }

// IDs lists the lamps, sorted.
func (s *Store) IDs() []string {
	out := make([]string, 0, len(s.lamps))
	for id := range s.lamps {
		out = append(out, id)
	}
	sort.Strings(out)
	return out
}
