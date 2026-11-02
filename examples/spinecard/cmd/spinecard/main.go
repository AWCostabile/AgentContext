// Command spinecard serves the card list and prints sheets of recommendation cards.
package main

import (
	"log"
	"net/http"
	"os"

	"example.com/spinecard/internal/cards"
	"example.com/spinecard/internal/print"
)

// defaultAddr is where the service listens when none is configured.
const defaultAddr = "localhost:7310"

// queue holds the cards written since the last sheet was printed.
var queue []*cards.Card

func main() {
	addr := os.Getenv("SPINECARD_ADDR")
	if addr == "" {
		addr = defaultAddr
	}
	shop := cards.NewRemoteCatalog(os.Getenv("TILLWRIGHT_URL"))
	http.Handle("/sheet", print.Handler(shop, func() []*cards.Card { return queue }))
	log.Fatal(http.ListenAndServe(addr, nil))
}
