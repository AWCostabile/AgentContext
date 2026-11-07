// Command winchbook serves the launch queue and the day's flight log to the launch-point tablet.
package main

import (
	"log"
	"net/http"
	"os"

	"example.com/winchbook/internal/flightlog"
	"example.com/winchbook/internal/queue"
)

// defaultAddr is where the service listens when none is configured.
const defaultAddr = "localhost:7420"

func main() {
	addr := os.Getenv("WINCHBOOK_ADDR")
	if addr == "" {
		addr = defaultAddr
	}
	book := flightlog.Open(os.Getenv("WINCHBOOK_DATA"))
	line := queue.New(queue.MethodsFrom(os.Getenv("WINCHBOOK_METHODS")))
	http.Handle("/queue", queue.Handler(line))
	http.Handle("/log", flightlog.Handler(book, line))
	log.Fatal(http.ListenAndServe(addr, nil))
}
