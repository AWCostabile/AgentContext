---
name: find
description: Search the knowledge tree by tag or keyword and open the right leaf. Use when asked to "find where X is filed", "which branch covers Y", "search the knowledge tree", "resolve tags", "what do we have on Z", or before reading any leaf whose location is unknown.
argument-hint: "<tag...> | -k <keyword...> | -x <dir> | -l"
allowed-tools: Bash(bash scripts/find.sh:*), Read, Glob, Grep
---

# Find in the knowledge tree

Arguments: `$ARGUMENTS`

1. **Tags first.** `bash scripts/find.sh $ARGUMENTS`: tags resolve to ranked branches, each
   shown with its full tag set and its tree. `-l` lists the vocabulary when the right tag is
   unknown.
2. **Then keywords.** No hit: retry with `-k <keyword>` (index lines), then `-k -a` (leaf
   bodies too).
3. **Expand and descend.** `bash scripts/find.sh -x <top hit>`: read its tags, any `.agent`
   notice and the head of its index. Read the `.agent` first when one is reported, then the
   leaf whose Contents row matches. Skip rows marked `_(archived)_` unless the question is
   historical.

Never glob-crawl or grep a tree wholesale: the indexes are the search structure. Search
covers `public/` and the private branches `.conf`'s `PRIVATE_SCOPES` opts in to; `-p`
searches all of `private/`. A question about what is TRUE is answered from `public/`; one
about how the work was RUN from `private/`, and when this machine has no private tree, say
so instead of guessing.

Answer with the path(s) and the matching Contents row(s).
