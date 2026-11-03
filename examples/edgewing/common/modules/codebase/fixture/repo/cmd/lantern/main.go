// Command lantern serves the lamp board.
package main

import (
	"fmt"
	"os"

	"example.com/lantern/internal/store"
)

// version is set at build time.
var version = "dev"

func main() {
	s := store.New(os.Getenv("LANTERN_DATA"))
	fmt.Println("lantern", version, s.Len())
}
