# Feature entries across products

[`feature-entries.sh`](./feature-entries.sh) lists every dated entry of every feature log in the
tree, newest first, one line each: the date, the area leaf's title and the entry's first sentence.
It answers "what changed across all our products lately?" without opening each leaf.

```
bash public/scratch-tools/feature-entries.sh                    # everything
bash public/scratch-tools/feature-entries.sh --since 2026-10-28 # a recent window
```

It reads only `public/*/*/features/features.*.md`, so it works on a fresh clone with no private
tree. It finds entries by their bold date at the start of a line, the shape the feature-log rule
sets; an entry written any other way is skipped silently.
