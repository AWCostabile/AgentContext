# Generated tiers: one writer, honest output, and how the linters treat them

_source:_ history/rulings/rulings.tiers-and-records.md TR1, TR3, TR9–TR13; history/rulings/rulings.hygiene-and-gates.md HG4
_reviewed:_ 2026-11-02

A generated tier is a branch whose leaves a program writes from a source: a map of a codebase's
public names, a graph of who calls what, a catalogue extracted from a schema. The core ships no
generator. The contract any module that adds one obeys is
[rules/generated-tiers.md](../../rules/generated-tiers.md); this article says why it holds, and
what it adds.

## One writer

A generated tier has one writer, a named generator; the branch's index prose, its tags and its
standing orders are the only authored files (TR9). The standing orders name the command that
regenerates the tier. The pre-write guard an adapter provides, where one exists, refuses any
other write there, the same way it refuses writes under the immutable tiers (TR3).

A generated file is never edited by hand. When it is wrong, the generator or the source it read
is fixed and the tier regenerated, and the report says which. A hand patch is overwritten by the
next run, and the defect returns silently.

## Honest output

A reader trusts a generated leaf only if it says what it could not see (TR10):

- whatever the generator could not parse is listed in the leaf, so absence of a name is never
  mistaken for absence of the thing;
- a location is plain `path:line` text, never a link and never a machine-specific path, so the
  same source generates the same leaf on any machine;
- no secret value is ever emitted: environment and configuration surfaces list names, never
  values;
- extracted text is neutralised so it can form neither a link nor a template placeholder;
- the drift check compares extracted content only, ignoring the leaf's own provenance line
  (date, commit, tool version), so a rerun over unchanged source rewrites nothing.

## When it regenerates

A tier regenerates when the change that moved its source lands, as one step of the landing,
never for an unmerged branch: a tier that describes a branch nobody has merged misleads every
reader of the main line (TR11). The generator's drift check is the alarm between landings, and
the full lint reports drift as advisory.

## Reproducible and offline

Generator tooling runs offline, is pinned to a named version, and produces the same output from
the same source; it moves only when the owner re-pins it (TR12). A generator never reads a
language through the wrong grammar: a source it cannot parse correctly is skipped and listed,
because a partial answer can be trusted and a wrong one cannot.

## Where it lives

Generated output about a product lives in the tree, under the product's branch, not in the
product's repository, which commits at most the generator's ignore file and one pointer line in
its instruction file (TR13). Where an instance keeps two generated tiers over one codebase (say,
one of names and one of relations), each answers its own question and the two never overlap.

## The linters

The advisory checks (leaf length and table width) skip a generated tier when the module that adds
it says so, in the same change (HG4). The structural checks never skip it: a dead link, an orphan
leaf or a private citation in a generated leaf fails like any other, and the fix belongs in the
generator or its source, never in the leaf. A process-vocabulary or retired-term smell in a
generated leaf is fixed the same way, at the source.
