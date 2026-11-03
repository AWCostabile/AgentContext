package queue

// Join puts a slot at the back of its method's line. A glider already waiting is refused.
func (l *Line) Join(s Slot) bool {
	for _, waiting := range l.slots[s.Method] {
		if waiting.Glider == s.Glider {
			return false
		}
	}
	l.slots[s.Method] = append(l.slots[s.Method], s)
	return true
}

// Next takes the front slot of a method's line, if any is waiting.
func (l *Line) Next(m Method) (Slot, bool) {
	waiting := l.slots[m]
	if len(waiting) == 0 {
		return Slot{}, false
	}
	l.slots[m] = waiting[1:]
	return waiting[0], true
}

// Waiting returns how many slots stand in a method's line.
func (l *Line) Waiting(m Method) int {
	return len(l.slots[m])
}
