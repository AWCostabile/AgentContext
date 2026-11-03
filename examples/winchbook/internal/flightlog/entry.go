// Package flightlog records each launch and landing for the day's sheet.
package flightlog

import "time"

// Entry is one flight, from the launch to the landing.
type Entry struct {
	// Glider is the registration flown.
	Glider   string
	// Pilot is the member in command.
	Pilot    string
	// Method is the launch used, as the queue spelled it.
	Method   string
	// Launched is when the glider left the ground.
	Launched time.Time
	// Landed is zero while the glider is still airborne.
	Landed   time.Time
}

// Airborne reports whether the flight has not yet landed.
func (e Entry) Airborne() bool {
	return e.Landed.IsZero()
}

// Minutes is the flight's length, rounded down; zero while airborne.
func (e Entry) Minutes() int {
	if e.Airborne() {
		return 0
	}
	return int(e.Landed.Sub(e.Launched) / time.Minute)
}
