# Scripts: what will arrive

Not in this repository yet. This directory will hold:

- `cure.sh`: the structural linter. It fails when an invariant of the tree is broken.
- `smell.sh`: the heuristic smells. It warns and never fails.
- `find.sh`: tag and keyword search. It resolves tags to ranked branches, each labelled with its tree.
- `lib-manifest.sh`: shared parsing of Contents tables.
- `lib-scopes.sh`: shared resolution of which trees and private branches are in scope, read from
  `.conf`.
