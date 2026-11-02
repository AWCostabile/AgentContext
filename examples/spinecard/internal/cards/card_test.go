package cards

import (
	"strings"
	"testing"
)

func TestNewRefusesALongRecommendation(t *testing.T) {
	if _, err := New("9780000000002", strings.Repeat("a", MaxWords+1), "Robin"); err != ErrTooLong {
		t.Fatalf("got %v, want ErrTooLong", err)
	}
}
