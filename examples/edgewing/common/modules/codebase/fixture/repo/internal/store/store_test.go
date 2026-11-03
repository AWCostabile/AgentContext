package store

import "testing"

func TestGetMissing(t *testing.T) {
	if _, err := New("").Get("x"); err != ErrMissing {
		t.Fatal(err)
	}
}
