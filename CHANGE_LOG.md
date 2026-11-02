## Feature | Change-Log Module [ _2026-11-02 10:02:13 UTC_ ]

- fix: the smoke reads the editor's files as JSON with comments
- docs: the run-sheet and the README describe the change-log module
- test: the deploy smoke proves the repository's workflow is the change-log module's file
- feat: the change-log module — the post-merge workflow any repository adopts with one copy

## Feature | Codebase Module [ _2026-11-02 10:00:31 UTC_ ]

- chore: clean up line spacing of non template files
- docs: the run-sheet pins the release that ships the example and the codebase module
- docs: the run-sheet, the README and the example page describe the codebase module
- chore: the worked example's core files match the template
- test: the deploy smoke regenerates every example code map and proves no drift
- feat: the example's products carry generated code maps
- feat: the example's two fictional source repositories
- docs: a product made from the template lints with no smell
- fix: the duplicate-name smell ignores a generated tier's fixed leaf names
- docs: the modules index names the codebase module
- test: the codebase module's fixture and its reproducibility check
- feat: the Go extractor
- feat: the TypeScript extractor
- feat: the codebase module — a generic code-map generator and its tier contract

## Feature | Worked Example [ _2026-11-02 09:58:17 UTC_ ]

- docs: skeleton wording that reads correctly once deployed
- fix: the smoke reports a stale example design leaf instead of failing on the calendar
- test: the deploy smoke lints every example
- docs: the examples index and the example's reader page
- feat: the example's private tree — a plan, its kickoff, a pull-request record and the journal
- feat: the example's public tree — two products and a site, designed, ruled and logged
- feat: a worked example, a fictional bookshop-tools startup deployed by the template

## Feature | Process Module and Adapter [ _2026-11-02 09:55:25 UTC_ ]

- docs: the run-sheet's module step prunes the seed rulings and sets their status
- docs: the modules index names the constitution and how to adopt it
- feat: the process half — kickoff guide, ground rules by reader, a code-standards template
- feat: the constitution's articles as current law over the seed rulings
- fix: the tier guard lets a seed ruling be pruned until it is adopted
- test: the deploy smoke lays the adapter down and boots it headless
- docs: the adapter READMEs, the written one and three porting specs
- feat: the orchestration ground rules for Claude Code
- feat: the Claude Code payload — hooks, skills, profiles and output styles for an instance
- feat: the constitution module's seed rulings, starting law an instance adopts or deletes
- docs: the README describes the constitution module and the written adapter
- docs: the run-sheet adopts the constitution module and pins the next release

## Feature | Deployer [ _2026-11-02 09:50:35 UTC_ ]

- docs: catalog branches read correctly inside a deployed instance
- docs: the run-sheet matches the deployer as built
- test: the deploy smoke proves install, update and the refusals
- feat: init.sh deploys an instance from the skeleton and a .conf, and updates its core files through a manifest
- feat: editor settings for a deployed instance, and a workspace file that is strict JSON
- refactor: the per-product mirror template moves beside the other templates
- docs: the instance instruction names its manifest and the update path
- docs: the README hands setup to a coding agent and describes the deployer as built
- docs: SETUP.md, the run-sheet an agent follows to deploy and update a tree

## Feature | Core Scripts [ _2026-11-01 14:34:54 UTC_ ]

- docs: every skeleton tag occurs where it points
- docs: the journal root is an authored index
- chore: line endings are stored and checked out as LF
- docs: HYGIENE.md describes the ported checks
- feat: smell.sh guards the template's own vocabulary
- feat: cure.sh lints the two trees and the flat private roots
- feat: find.sh searches a tree from any root
- feat: manifest library reads landing dates from both trees
- feat: scope library reads the catalogs and private scopes from .conf
- chore: .conf.example reserves the orchestration budget key
- docs: the instance instruction and the README say what exists
- docs: the scripts index names the core tools
- docs: a rule-catalog leaf template beside the branch template
- docs: the grammar and tier rules as plain documents

## Feature | Skeleton [ _2026-11-01 12:31:19 UTC_ ]

- docs: placeholder links and tags that survive catalog expansion
- docs: the repository is named AgentContext
- docs: the modules and examples placeholders
- docs: the adapter contract and its four directories
- docs: the deployable public and private skeleton
- docs: the method README, the agent instructions and the MIT licence