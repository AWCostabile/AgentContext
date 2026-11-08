#!/bin/bash
# simulate.sh — lay walkable instances into dist/ from this repository's WORKING TREE, so the
# deployer's states can be opened and read in an editor: a fresh instance with every module
# adopted, and an instance of the last release brought across by --update and --adopt. Each
# instance's deployer output is saved beside it as <name>.log. dist/ is git-ignored, never
# copied into an instance and never committed; every run starts it afresh.
#
# Usage: bash tests/tools/simulate.sh   (from anywhere; no arguments)
#
# Exits 0 when every step ran, 1 at the first step that did not (its log says why).

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$REPO" || exit 1
DIST="$REPO/dist" INIT="$REPO/init.sh" OLDREL=v0.4.0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/simulate.XXXXXX") || exit 1
trap 'rm -rf "$WORK"' EXIT

step() {   # step <log> <title> <command...>: run it, log it, stop on a failure
  local log=$1 title=$2 rc
  shift 2
  printf '\n$ %s\n' "$title" >> "$log"
  "$@" >> "$log" 2>&1; rc=$?
  [ $rc -eq 0 ] || { printf 'simulate: %s failed (exit %s); see %s\n' "$title" "$rc" "${log#"$REPO"/}" >&2; exit 1; }
}
lint() {   # lint <instance> <log>: the instance's own linters, their verdict lines logged
  printf '\n$ bash common/scripts/cure.sh && bash common/scripts/smell.sh --quiet\n' >> "$2"
  (cd "$1" && bash common/scripts/cure.sh | tail -n 1 && bash common/scripts/smell.sh --quiet | tail -n 1) >> "$2" 2>&1
}
local_by_hand() {   # local_by_hand <instance>: the local module's two hand steps, as SETUP.md's step 12 says
  [ -d "$1/private/local" ] || return 0
  printf '%s\n' "| [Local](./local/.index.md) | personal: the user's own ideas, memories and plans; its .agent governs; never shared |" >> "$1/private/.index.md" \
    && sed -i 's/^PRIVATE_SCOPES="\(.*\)"$/PRIVATE_SCOPES="\1 local"/' "$1/.conf"
}

rm -rf "$DIST" && mkdir -p "$DIST" || exit 1
sed -e 's/^CATALOGS=.*/CATALOGS="products projects"/' "$REPO/blueprint/common/.conf.example" > "$WORK/my.conf"
MODULES=()
for d in "$REPO"/modules/*/; do
  m=${d%/}; m=${m##*/}
  [ "$m" = change-log ] || MODULES+=("$m")   # the one module that belongs to a repository
done

# -- fresh: the working tree deployed with the adapter, every module adopted --------------------
F="$DIST/fresh" LOG="$DIST/fresh.log"
: > "$LOG"
step "$LOG" "init.sh --target dist/fresh --conf my.conf --name Fresh --adapter claude-code" \
  bash "$INIT" --from "$REPO" --target "$F" --conf "$WORK/my.conf" --name Fresh --adapter claude-code
for m in "${MODULES[@]}"; do
  step "$LOG" "init.sh --adopt $m --target dist/fresh" bash "$INIT" --adopt "$m" --target "$F" --from "$REPO"
done
step "$LOG" "add the local row to private/.index.md and local to PRIVATE_SCOPES, as SETUP.md says" local_by_hand "$F"
lint "$F" "$LOG"

# -- migrated: an instance of the last release, modules copied in by hand, brought across ---------
M="$DIST/migrated" LOG="$DIST/migrated.log"
: > "$LOG"
if ! git rev-parse -q --verify "refs/tags/$OLDREL^{commit}" >/dev/null 2>&1; then
  printf 'simulate: %s is not tagged here: dist/migrated not laid\n' "$OLDREL" | tee -a "$LOG" >&2
else
  OV=${OLDREL#v} OLD="$WORK/AgentContext-${OLDREL#v}"
  git archive --format=tar --prefix="AgentContext-$OV/" "$OLDREL" | tar -x -C "$WORK"
  sed -e 's/^CATALOGS=.*/CATALOGS="products projects"/' "$OLD/template/.conf.example" > "$WORK/old.conf"
  step "$LOG" "$OLDREL's own init.sh --target dist/migrated --name Migrated --adapter claude-code" \
    bash "$OLD/init.sh" --from "$OLD" --target "$M" --conf "$WORK/old.conf" --name Migrated --adapter claude-code
  sed -i "s/^ref=.*/ref=$OLDREL/" "$M/.agentcontext"   # as a release archive would record it
  step "$LOG" "copy graphify to modules/ and the constitution to constitution/ by hand, as $OLDREL's run-sheet did" \
    sh -c 'mkdir -p "$1/modules" && cp -R "$2/modules/graphify" "$1/modules/graphify" && cp -R "$2/modules/constitution/tree" "$1/constitution"' _ "$M" "$OLD"
  step "$LOG" "edit rules/branch-grammar.md and one seed ruling, as a user would" \
    sh -c 'printf "%s\n" "" "A local note." >> "$1/rules/branch-grammar.md" && sed -i "s/^_status:_ seed.*$/_status:_ adopted 2026-01-01/" "$1/constitution/history/rulings/rulings.tree-structure.md"' _ "$M"
  step "$LOG" "init.sh --update --target dist/migrated --from <this working tree>" \
    bash "$INIT" --update --target "$M" --from "$REPO"
  for m in graphify constitution local linkcheck; do
    step "$LOG" "init.sh --adopt $m --target dist/migrated" bash "$INIT" --adopt "$m" --target "$M" --from "$REPO"
  done
  step "$LOG" "add the local row to private/.index.md and local to PRIVATE_SCOPES, as SETUP.md says" local_by_hand "$M"
  lint "$M" "$LOG"
fi

cat > "$DIST/README.md" <<EOF
# dist: walkable instances

Laid by \`bash tests/tools/simulate.sh\` from the working tree as it stood on $(date '+%Y-%m-%d %H:%M');
git-ignored, rebuilt from scratch on every run. Each instance's deployer output is in the \`.log\` beside it.

- \`fresh/\`: deployed with the Claude Code adapter, then every module but change-log adopted with
  \`init.sh --adopt\`, the local module's row and scope then added by hand. Read \`common/.agentcontext\`
  for the \`module=\` lines and the hashes.
- \`migrated/\`: deployed by $OLDREL's own \`init.sh\`, graphify and the constitution copied in by hand,
  one rule and one ruling edited, then \`--update\` from the working tree, \`--adopt\` for those two and,
  fresh, for local and linkcheck, and the local row and scope added by hand. Its log shows
  the \`moved\` and \`kept\` lines, the hand copy recorded or moved, and the guide named.

Run an instance's own tools from inside it: \`bash common/scripts/cure.sh\`, \`bash common/scripts/find.sh -l\`.
EOF
printf 'dist/fresh/ and dist/migrated/ laid; logs in dist/*.log, a note in dist/README.md\n'
