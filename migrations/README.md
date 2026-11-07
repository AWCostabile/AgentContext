# Migration guides

One guide per release, named for the release it leaves: `0.4.0.md` takes an instance from
`v0.4.0` to the release after it. A guide is written when its next release is cut and is never
edited afterwards. An instance several releases behind reads the guides in order, starting with
its own.

Most of an update needs no guide: `init.sh --update` replaces, adds and moves every core file
the user never edited. A guide is for what the deployer will not do on its own: a file the user
edited, a step that needs a choice. When an update keeps a file, its report ends with one
`guide: migrations/<version>.md` line for each guide from the instance's release onwards (the
`ref=` line of its manifest).

None of this directory is laid into an instance.
