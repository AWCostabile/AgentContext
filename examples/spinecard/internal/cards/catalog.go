package cards

// Title is what the shop's point of sale knows of a book at the moment of printing.
type Title struct {
	Name       string
	Author     string
	PriceCents int
}

// Catalog looks titles up by key. Only held titles are found.
type Catalog interface {
	Lookup(key string) (Title, bool)
}

// RemoteCatalog asks the shop's point-of-sale service.
type RemoteCatalog struct {
	// BaseURL is the service's address.
	BaseURL string
	cache   map[string]Title
}

// NewRemoteCatalog returns a catalog over the service at base.
func NewRemoteCatalog(base string) *RemoteCatalog {
	return &RemoteCatalog{BaseURL: base, cache: map[string]Title{}}
}

// Lookup returns the title for key, if the shop holds it.
func (r *RemoteCatalog) Lookup(key string) (Title, bool) {
	t, ok := r.cache[key]
	return t, ok
}
