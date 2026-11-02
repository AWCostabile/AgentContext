// Package cards composes recommendation cards from a held title and a staff member's words.
package cards

import (
	"errors"
	"time"
	"unicode/utf8"
)

// MaxWords is the longest recommendation a card carries, in characters.
const MaxWords = 280

// ErrTooLong is returned for a recommendation over MaxWords; it is never truncated.
var ErrTooLong = errors.New("recommendation too long")

// ErrNotHeld is returned for a title the shop does not hold.
var ErrNotHeld = errors.New("title not held")

// Card is one printed recommendation. Only Words and Staff are stored.
type Card struct {
	// Key is the title's ISBN or shop-local code.
	Key   string
	Words string
	Staff string
	// Title is read fresh from the catalog each time the card is printed.
	Title Title
	// Printed is the day the card was printed, shown beside the price.
	Printed time.Time
}

// New makes a card, refusing a recommendation over MaxWords.
func New(key, words, staff string) (*Card, error) {
	if utf8.RuneCountInString(words) > MaxWords {
		return nil, ErrTooLong
	}
	return &Card{Key: key, Words: words, Staff: staff}, nil
}

// Fill reads the card's title from the catalog and stamps the printing date.
func (c *Card) Fill(cat Catalog, now time.Time) error {
	t, ok := cat.Lookup(c.Key)
	if !ok {
		return ErrNotHeld
	}
	c.Title = t
	c.Printed = now
	return nil
}
