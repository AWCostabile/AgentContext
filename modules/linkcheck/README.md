# The linkcheck module

A tree cites the outside world: a vendor's guide, a specification, a standard, an article a
decision rests on. Those pages move and vanish, and a leaf whose source is gone is a claim no one
can check any more. The module asks every `http://` and `https://` URL the tree cites, once each,
and reports the dead ones by file and line. It writes nothing.

## Why it is a module

It needs `curl` and the network, and the core needs neither: every core script runs offline, on a
fresh clone, in a hook, in seconds. A link check is slow, depends on servers the instance does not
control, and gives a different answer tomorrow for the same tree, so it is run by hand or on a
schedule, never as a gate on a write.

## The verbs

From the instance root, with the module adopted at `common/modules/linkcheck/`:

```sh
    bash common/modules/linkcheck/linkcheck.sh                every .md file in the search scope
    bash common/modules/linkcheck/linkcheck.sh --all          the same, with every private branch
    bash common/modules/linkcheck/linkcheck.sh <path>...      those files or directories only
```

The search scope is the one `find.sh` searches, read from `common/scripts/lib-scopes.sh`:
`public/` and the private branches `.conf`'s `PRIVATE_SCOPES` names. `--all` widens it to every
private branch, as `find.sh -p` does. A `<path>` is a file or a directory under the root, taken
from the root or from the current directory; a directory contributes its `.md` files, a file is
read whatever its extension.

Each distinct URL is asked once, however often the tree cites it: a HEAD request that follows
redirects, and a GET when the server answers the HEAD with 405. A code of `000` (no answer within
the time allowed) or 400 and above is dead. A URL ends at whitespace or at any of `` < > " ` | { } [ ] ``,
and the punctuation prose puts after it (`. , ; : > ' "`) is dropped, as is a `)` that closes
nothing the URL opened, which is how a Markdown link `[text](https://…)` ends.

Options: `--root <dir>` the instance root (default the current directory); `--max-time <s>` the
seconds one request may take (default 15).

Output: one line per occurrence of a dead URL, in file and line order, so a dead URL cited twice
is reported twice and asked once:

```
DEAD 404 public/products/lantern/research.md:12 https://example.org/spec/v2
linkcheck: 1 dead link(s) in 1 file(s), 23 url(s) asked, 2 ignored
```

The summary counts dead occurrences, the files holding them, and the distinct URLs asked and
ignored. The exit code is the dead count, capped at 125; 2 for a refusal or a usage error with
nothing asked: no `.conf` at the root, no `curl` on PATH, an unknown option, a path that does not
exist. A run that reports two dead links also exits 2, and is told apart by its summary line.

## .linkcheckignore

A URL that is meant to fail, or that cannot be asked from where the check runs (an intranet host,
a page behind a login, a server that refuses robots), is listed in `.linkcheckignore` at the
instance root: one URL prefix per line, `#` comments and blank lines skipped. A URL starting with a
listed prefix is never asked and is counted as ignored.

```
# the intranet: not reachable from a laptop off the network
https://wiki.internal.example/
```

The file is a shared fact about the tree, committed with it: you create it when the first URL
needs it, the module reads it when it is present, and nothing writes it, the deployer included.

## Citing a source

A leaf that rests on one outside source may say so in marker lines under its H1, which the core's
field query already reads:

```md
# The rendering pipeline

_url:_ https://example.org/spec/v2
_accessed:_ 2026-03-14
```

`bash common/scripts/find.sh -f url` lists every leaf with a source and the URL;
`bash common/scripts/find.sh -f 'accessed<2026-01-01'` the sources last read before a date (quote
the argument: `<` and `>` are the shell's). A dead source is then a link check away, and a stale one
a field query away. The convention is optional: the link check reads every URL in a leaf, marker
or prose.

## Adoption

From a release, `bash init.sh --adopt linkcheck --target <instance>` lays the module at
`<instance>/common/modules/linkcheck/` and records it in the instance's manifest, so an update
refreshes it. It needs bash, `curl` and the core's `common/scripts/lib-scopes.sh`; the core never
depends on it.

## The check

`bash modules/linkcheck/check.sh` builds a throwaway instance with a public tree, two private
branches and a `.linkcheckignore`, puts a stand-in `curl` on PATH that answers from a table and
logs every call, and proves the module end to end without reaching the network: the dead
occurrences with their code, file and line; the punctuation trimmed and a URL's own `)` kept; a
URL cited three times asked once; a 405 asked again with a GET; an ignored prefix never asked; the
default scope reaching only the private branches `PRIVATE_SCOPES` names and `--all` every one; a
file and a directory named on the command line; the exit code the dead count, 0 when none, capped
at 125; the refusals; the marker lines `find.sh -f` reads; the instance never written to. It exits
with its fail count. The deploy smoke runs it.
