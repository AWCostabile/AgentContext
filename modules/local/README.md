# The local module

A branch of the private tree that belongs to the user rather than to the work: their ideas, what
they want an agent to remember about how they like to work, and plans not yet ready for a
product's branch.

```
private/local/
  .agent        the conduct: the user's own, never copied out without their say
  ideas/        brainstorming and concepts not yet placed anywhere
  memories/     the user's preferences and what they want remembered
  plans/        concrete planning, before it is ready for a product's branch
```

## Why it is a module

The core keeps two trees honest: `public/` for what is true, `private/` for how the work was run.
A personal branch is neither. It is an opinion a team may decline (some keep nothing about a
person in a tree at all), and it is a tier with conduct of its own: what lives here is the user's,
nothing from it is copied or paraphrased into `public/` or anywhere shareable without the user's
say in the current session, and it records the user's ideas, never assessments of the user. Its
`.agent` states that conduct; read it before writing here.

The branch is freeform. Its three branches carry an index and tags so search can reach them, and
below them it is organised however serves the user. The linter never walks it:
`common/scripts/lib-scopes.sh` lists `local` among the freeform private branches, beside `mod` and
`temp`. Only its own row in `private/.index.md` is checked, as every child of the private root is.

## Adoption

From a release, `bash init.sh --adopt local --target <instance>` lays `tree/` at
`<instance>/private/local/` and records the module in the instance's manifest, so an update
refreshes a file still exactly as shipped and keeps every file you have changed. It refuses an
instance with no private tree and writes nothing. Two things the deployer never does, and you do:

1. **Add its row to `private/.index.md`'s Contents table.** Until you do, `cure.sh` fails the
   private root with C03, `orphan (not in private/.index.md): private/local`. A row such as:
   ```md
   | [Local](./local/.index.md) | the user's own ideas, memories and plans: read its `.agent` first |
   ```
2. **Add `local` to `PRIVATE_SCOPES` in `.conf`.** The scope list is the private branches search
   covers by default: with `local` in it, `find.sh` and the tools that read `search_dirs` include
   the branch in every search; without it, the branch is reached only by `find.sh -p`, which
   searches all of `private/` regardless. `.conf` is a fact about one machine, so the choice is
   yours on each.

Commit the branch in the private tree as any other filing: one commit per action, path-scoped.

## Not adopting it

Nothing in the core refers to the module. The freeform name stays reserved in `lib-scopes.sh`, so
a `private/local/` you lay down by hand is treated exactly as the adopted one; the deployer then
neither records nor refreshes it.
