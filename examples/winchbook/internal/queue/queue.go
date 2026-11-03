// Package queue keeps the order in which gliders are launched.
package queue

import "strings"

// Method is how a glider leaves the ground: by winch or behind a tow plane.
type Method string

// The launch methods a club may run.
const (
	Winch   Method = "winch"
	Aerotow Method = "aerotow"
)

// Slot is one glider waiting at the launch point.
type Slot struct {
	// Glider is the registration painted on the fin.
	Glider     string
	// Pilot is the member flying, by membership number.
	Pilot      string
	// Method is the launch asked for.
	Method     Method
	// Instructor is set when the flight is a lesson.
	Instructor string
}

// Line is the launch queue: one ordered line per method in use today.
type Line struct {
	methods []Method
	slots   map[Method][]Slot
}

// New returns an empty line over the given methods.
func New(methods []Method) *Line {
	return &Line{methods: methods, slots: map[Method][]Slot{}}
}

// MethodsFrom reads a comma-separated method list; an empty list means winch only.
func MethodsFrom(spec string) []Method {
	if spec == "" {
		return []Method{Winch}
	}
	var out []Method
	for _, m := range strings.Split(spec, ",") {
		out = append(out, Method(strings.TrimSpace(m)))
	}
	return out
}
