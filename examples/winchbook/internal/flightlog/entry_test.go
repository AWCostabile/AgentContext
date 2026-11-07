package flightlog

import (
	"testing"
	"time"
)

func TestMinutesWhileAirborne(t *testing.T) {
	e := Entry{Launched: time.Now()}
	if e.Minutes() != 0 {
		t.Fatal("an airborne flight has no length yet")
	}
}
