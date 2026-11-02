#!/bin/bash
# graphs.sh — the graphify module: one Graphify knowledge graph per repository, kept in the
# tree's generated graphs/ tier.
#
# graphs/ is GENERATED. This script is its only writer: every graph.json, the Contents rows of
# graphs/.index.md and graphs/.agent come from here, and nothing under graphs/ is hand-edited
# (the prose above the Contents table and .tags are authored, scaffolded once and never
# rewritten). Re-runnable like scripts/cure.sh: one [ OK ] / [WARN] / [FAIL] line per
# finding, and the exit code is the number of FAILs (2 for a usage error or a refusal, when
# nothing was written).
#
# Two layers per slug, so a repository's own graphify hooks can never dirty this tree:
#   graphs/<slug>/live/        git-ignored. <repository>/graphify-out is a LINK into it (a
#                              directory junction on Windows, a symlink elsewhere), so the scan,
#                              graphify's post-commit and post-checkout hooks and the query
#                              server's per-project lookup all read and write THIS directory.
#   graphs/<slug>/graph.json   committed. Written by `scan` alone, as a copy of the live graph it
#                              has just rebuilt from scratch: a deliberate snapshot, stamped by
#                              graphify with the commit it was built at.
#
# Usage (from the instance root, the directory holding .conf):
#   bash modules/graphify/graphs.sh home <slug>...    home a repository: seed its .graphifyignore
#                                                     (never rewritten once present), ignore
#                                                     graphify-out/ in its .gitignore, link its
#                                                     graphify-out into graphs/<slug>/live/,
#                                                     scaffold graphs/ and the instance's own
#                                                     .gitignore block. Idempotent.
#   bash modules/graphify/graphs.sh scan [<slug>...]  regenerate every homed repository (or the
#                                                     named ones): a from-scratch, code-only,
#                                                     offline extract into live/, the snapshot
#                                                     copied up, registered in the user's global
#                                                     graph, the index rows rewritten
#   bash modules/graphify/graphs.sh check [<slug>...] report only: the links, the tool and its
#                                                     pin, staleness against each repository's
#                                                     HEAD, index drift. Writes nothing.
#   bash modules/graphify/graphs.sh                   = scan
# Options:
#   --root <dir>   the instance root; default the current directory
#   --force        scan: bypass graphify's parse cache too (every scan already rebuilds the graph)
#   --no-global    scan: do not register the snapshot in ~/.graphify/global-graph.json
#
# .conf keys (read through scripts/lib-scopes.sh; never spelled here):
#   GRAPHS="<slug>=<path> ..."   the repositories, one word each: a slug ([a-z0-9-]) and the
#                                repository's path relative to the instance root (`../<name>`
#                                for a sibling in the workspace; `.` for the instance itself)
#   GRAPHIFY_VERSION=<x.y.z>     optional. When set, scan refuses any other graphify on PATH, so
#                                the same source gives the same graph on every machine; unset,
#                                the version that ran is recorded in the index row and reported
#
# A repository is HOMED when it carries a .graphifyignore at its root; scan skips an unhomed one
# and says so. graphify itself: https://github.com/Graphify-Labs/graphify, the package graphifyy.

set -u

VERB=""; SLUGS=(); ROOT=""; FORCE=0; GLOBAL=1
while [ $# -gt 0 ]; do
  case "$1" in
    home|scan|check) [ -z "$VERB" ] || { echo "usage: one verb (home, scan or check)" >&2; exit 2; }; VERB=$1 ;;
    --root) [ $# -ge 2 ] || { echo "usage: --root <dir>" >&2; exit 2; }; ROOT=$2; shift ;;
    --force) FORCE=1 ;;
    --no-global) GLOBAL=0 ;;
    -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "usage: unknown option $1" >&2; exit 2 ;;
    *) SLUGS+=("$1") ;;
  esac
  shift
done
[ -z "$VERB" ] && VERB=scan
[ -z "$ROOT" ] && ROOT=$PWD
ROOT=$(cd "$ROOT" 2>/dev/null && pwd) || { echo "usage: --root $ROOT is not a directory" >&2; exit 2; }
[ -f "$ROOT/.conf" ] || { echo "refused: $ROOT holds no .conf — run from the instance root or pass --root" >&2; exit 2; }
[ -f "$ROOT/scripts/lib-scopes.sh" ] || { echo "refused: $ROOT/scripts/lib-scopes.sh is missing — the module runs inside an instance of the template" >&2; exit 2; }
# shellcheck source=/dev/null
. "$ROOT/scripts/lib-scopes.sh"
[ "$VERB" = home ] && [ ${#SLUGS[@]} -eq 0 ] && { echo "usage: home <slug>..." >&2; exit 2; }

FAIL=0; WARN=0
ok()   { printf '[ OK ] %s\n' "$1"; }
info() { printf '[INFO] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) WIN=1 ;; *) WIN=0 ;; esac
PY=""
for p in python3 python py; do
  "$p" -I -c 'import json' >/dev/null 2>&1 && { PY=$p; break; }
done

GRAPHS_DIR="$ROOT/graphs"
SELF="modules/graphify/graphs.sh"

# -- the repositories, from .conf -----------------------------------------------------------------
declare -A REPO_PATH=() REPO_TITLE=()
ORDER=()
for word in $(conf_key GRAPHS); do
  slug=${word%%=*}; path=${word#*=}
  if [ "$slug" = "$word" ] || [ -z "$slug" ] || [ -z "$path" ]; then
    echo "refused: GRAPHS entry '$word' is not <slug>=<path>" >&2; exit 2
  fi
  case "$slug" in *[!a-z0-9-]*) echo "refused: slug '$slug' — lowercase [a-z0-9-] only" >&2; exit 2 ;; esac
  [ -n "${REPO_PATH[$slug]:-}" ] && { echo "refused: slug '$slug' listed twice in GRAPHS" >&2; exit 2; }
  case "$path" in /*|?:*) abs=$path ;; *) abs="$ROOT/$path" ;; esac
  REPO_PATH[$slug]=$abs
  if [ "$path" = . ]; then REPO_TITLE[$slug]=${ROOT##*/}; else t=${path%/}; REPO_TITLE[$slug]=${t##*/}; fi
  ORDER+=("$slug")
done
if [ ${#ORDER[@]} -eq 0 ]; then
  echo "refused: .conf has no GRAPHS entry — add GRAPHS=\"<slug>=../<repository> ...\" (one word per repository)" >&2; exit 2
fi
for s in "${SLUGS[@]}"; do
  [ -n "${REPO_PATH[$s]:-}" ] || { echo "refused: unknown slug '$s' — GRAPHS names: ${ORDER[*]}" >&2; exit 2; }
done
[ ${#SLUGS[@]} -eq 0 ] && SLUGS=("${ORDER[@]}")

# -- paths and links ------------------------------------------------------------------------------
# A path as the platform compares it: resolved, and on Windows its drive-letter spelling in
# lower case, since a junction's target comes back as an MSYS mount alias.
canon() {
  local p
  p=$(cd "$1" 2>/dev/null && pwd -P) || return 1
  if [ $WIN -eq 1 ]; then cygpath -w "$p" | tr 'A-Z\\' 'a-z/'; else printf '%s' "$p"; fi
}
# link state: prints "absent", "link <target>" or "dir"
link_state() {
  if [ -L "$1" ]; then printf 'link %s' "$(readlink "$1")"
  elif [ -e "$1" ]; then printf 'dir'
  else printf 'absent'; fi
}
make_link() {   # make_link <link> <target dir>; the target must exist
  if [ $WIN -eq 1 ]; then
    MSYS_NO_PATHCONV=1 cmd /c mklink /J "$(cygpath -w "$1")" "$(cygpath -w "$2")" >/dev/null 2>&1
  else
    ln -s "$2" "$1"
  fi
}
drop_link() {   # drop_link <link>: removes the link, never what it points at
  if [ $WIN -eq 1 ] && [ -d "$1" ]; then MSYS_NO_PATHCONV=1 cmd /c rmdir "$(cygpath -w "$1")" >/dev/null 2>&1
  else rm "$1"; fi
}

# <repository>/graphify-out must be a link into graphs/<slug>/live/. On home, a real directory
# there (a standalone graphify run before adoption) is moved into live/ when live/ is empty and
# replaced by the link; any other target is refused. On scan and check it is only judged.
ensure_link() {   # ensure_link <slug> <repo> <live> <create: 0|1>
  local slug=$1 repo=$2 live=$3 create=$4 link="$2/graphify-out" state target
  state=$(link_state "$link")
  case "$state" in
    absent)
      [ $create -eq 1 ] || { fail "$slug: $link is missing — run: bash $SELF home $slug"; return 1; }
      mkdir -p "$live"
      make_link "$link" "$live" || { fail "$slug: could not link $link -> $live"; return 1; }
      ok "$slug: linked graphify-out -> graphs/$slug/live/"; return 0 ;;
    dir)
      [ $create -eq 1 ] || { fail "$slug: $link is a real directory, not a link — run: bash $SELF home $slug"; return 1; }
      if [ -d "$live" ] && [ -n "$(ls -A "$live" 2>/dev/null)" ]; then
        fail "$slug: $link is a real directory and graphs/$slug/live/ is not empty — merge or remove one of them by hand"; return 1
      fi
      mkdir -p "$(dirname "$live")" && rm -rf "$live" && mv "$link" "$live" || { fail "$slug: could not move $link into graphs/$slug/live/"; return 1; }
      make_link "$link" "$live" || { fail "$slug: moved the directory into graphs/$slug/live/ but could not link $link back to it"; return 1; }
      ok "$slug: moved the existing graphify-out/ into graphs/$slug/live/ and linked it"; return 0 ;;
    link*)
      target=${state#link }
      [ $create -eq 1 ] && [ ! -d "$live" ] && mkdir -p "$live"   # a link made before live/ existed
      if [ -d "$live" ] && [ "$(canon "$link")" = "$(canon "$live")" ]; then
        ok "$slug: graphify-out -> graphs/$slug/live/"; return 0
      fi
      fail "$slug: $link links to '$target', not graphs/$slug/live/ — remove that link and run home again"; return 1 ;;
  esac
}

# -- the authored and ignored files home lays down ---------------------------------------------
# A line is appended only when absent, so a rerun writes nothing and a hand-edited file keeps
# its edits. The block the instance's .gitignore needs: everything under graphs/<slug>/ except
# the snapshot, and the instance's own graphify-out/ should it home itself.
ensure_lines() {   # ensure_lines <file> <marker line> <lines...>: append the lines when the marker is absent
  local f=$1 marker=$2; shift 2
  [ -f "$f" ] && grep -qxF -- "$marker" "$f" && return 1
  { [ -f "$f" ] && [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ] && printf '\n'; [ -f "$f" ] && [ -s "$f" ] && printf '\n'; printf '%s\n' "$@"; } >> "$f"
  return 0
}
home_instance() {
  if ensure_lines "$ROOT/.gitignore" 'graphs/*/*' \
    "# Graphify output ($SELF): graph.json is committed; the rendering, the" \
    "# incremental-scan state and the cache are not. graphify-out/ is this repository's own" \
    "# link into graphs/<slug>/live/, created by the script only once the tree is homed." \
    'graphs/*/*' '!graphs/*/graph.json' '/graphify-out/'; then
    ok ".gitignore: the graphs/ block appended"
  fi
  mkdir -p "$GRAPHS_DIR"
  if [ ! -f "$GRAPHS_DIR/.index.md" ]; then
    printf '%s\n' '# Graphs' '' \
      'Graphify knowledge graphs, one subdirectory per repository slug. `graph.json` is the committed' \
      'snapshot; `live/` beside it is git-ignored and is what the repository'"'"'s `graphify-out/` link points' \
      'at, so the scan, graphify'"'"'s own hooks and the query server all work there and a hook rebuild never' \
      'dirties this tree. Read [`.agent`](./.agent) before working here: the rows below are generated by' \
      "\`$SELF\` and never hand-edited." '' '## Contents' '' '| File | Purpose |' '| ---- | ------- |' > "$GRAPHS_DIR/.index.md"
    ok "graphs/.index.md scaffolded"
  fi
  if [ ! -s "$GRAPHS_DIR/.tags" ]; then
    printf '%s\n' graphs graphify knowledge-graph code > "$GRAPHS_DIR/.tags"; ok "graphs/.tags scaffolded"
  fi
  write_agent
}
home_repo() {   # home_repo <slug>
  local slug=$1 repo=${REPO_PATH[$1]} live="$GRAPHS_DIR/$1/live" ign
  [ -d "$repo" ] || { fail "$slug: repository not found at $repo"; return 1; }
  ign="$repo/.graphifyignore"
  if [ ! -f "$ign" ]; then
    printf '%s\n' \
      '# Graphify scan exclusions (gitignore syntax; merged over .gitignore, which is honoured too).' \
      "# The graph itself lives in the knowledge tree's graphs/$slug/; graphify-out/ here is a link" \
      "# into it and must never be scanned as source. Regenerate with $SELF there." \
      'graphify-out/' 'node_modules/' 'build/' 'dist/' > "$ign"
    ok "$slug: .graphifyignore seeded (edit it: what the scan should skip)"
  fi
  if ensure_lines "$repo/.gitignore" 'graphify-out/' \
    "# Graphify: a link into the knowledge tree's graphs/$slug/ ($SELF there)" 'graphify-out/'; then
    ok "$slug: graphify-out/ ignored in its .gitignore"
  fi
  [ -d "$repo/.git" ] || info "$slug: $repo is not a git repository — graphify records no commit for it"
  ensure_link "$slug" "$repo" "$live" 1
}

# -- graph facts and the generated texts -----------------------------------------------------------
# prints: nodes edges communities commit   (or nothing when the file cannot be read)
graph_facts() {
  [ -n "$PY" ] || { printf '? ? ? ?'; return 0; }
  "$PY" -I - "$1" <<'PYEOF'
import json, sys
try:
    g = json.load(open(sys.argv[1], encoding="utf-8"))
    nodes = g.get("nodes", [])
    edges = g.get("links", g.get("edges", []))
    comms = {n.get("community") for n in nodes if n.get("community") is not None}
    print(len(nodes), len(edges), len(comms), g.get("built_at_commit") or "-")
except Exception:
    pass
PYEOF
}
repo_head() { git -C "$1" rev-parse HEAD 2>/dev/null; }
tool_version() {
  command -v graphify >/dev/null 2>&1 || return 1
  graphify --version 2>&1 | head -n 1 | sed -nE 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p'
}
# the Contents rows, from what exists on disk, in GRAPHS order
index_rows() {
  # Reproducible from the committed files alone (no mtime, no machine fact), so `check` on a
  # fresh clone agrees with the machine that scanned: the counts, the commit graphify stamped,
  # and the pin when .conf carries one.
  local s f
  for s in "${ORDER[@]}"; do
    f="$GRAPHS_DIR/$s/graph.json"; [ -f "$f" ] || continue
    read -r nodes edges comms commit <<< "$(graph_facts "$f")"
    [ -n "${nodes:-}" ] || { nodes='?'; edges='?'; comms='?'; commit='-'; }
    printf '| [%s/graph.json](./%s/graph.json) | %s — %s nodes, %s edges, %s communities; built at %s (graphify %s, code-only) |\n' \
      "$s" "$s" "${REPO_TITLE[$s]}" "$nodes" "$edges" "$comms" "$commit" "${PIN:-unpinned}"
  done
}
index_text() {   # the authored prose kept, the table rewritten
  local idx="$GRAPHS_DIR/.index.md"
  awk '/^\| File \| Purpose \|$/ { print; getline; print; exit } { print }' "$idx"
  index_rows
}
agent_text() {
  printf '%s\n' "Generated by $SELF (Graphify, code-only, offline) — never hand-edit anything here, the index rows included; graph.json is the committed snapshot, live/ is the git-ignored working layer each repository's graphify-out/ link points at. Rebuild with \`bash $SELF scan\`; \`check\` reports without writing; \`home <slug>\` links a repository. The prose above the Contents table and .tags are authored."
}
write_agent() {
  local a="$GRAPHS_DIR/.agent" want
  want=$(agent_text)
  if [ ! -f "$a" ] || [ "$(cat "$a")" != "$want" ]; then printf '%s\n' "$want" > "$a"; ok "graphs/.agent written"; fi
}
write_index() {
  local idx="$GRAPHS_DIR/.index.md" want
  want=$(index_text)
  if [ "$(cat "$idx")" != "$want" ]; then printf '%s\n' "$want" > "$idx"; ok "graphs/.index.md rows rewritten"; else ok "graphs/.index.md unchanged"; fi
}

# -- the tool and its pin ----------------------------------------------------------------------------
PIN=$(conf_key GRAPHIFY_VERSION)
HINT='uv tool install "graphifyy[mcp]'"${PIN:+==$PIN}"'"'
TOOL_OK=0; HAVE=""
check_tool() {
  if ! HAVE=$(tool_version); then fail "graphify is not on PATH — install with: $HINT"; return 1; fi
  if [ -n "$PIN" ] && [ "$HAVE" != "$PIN" ]; then
    fail "graphify $HAVE on PATH, GRAPHIFY_VERSION pins $PIN — install with: $HINT (or move the pin)"; return 1
  fi
  if [ -n "$PIN" ]; then ok "graphify $HAVE (pinned)"; else info "graphify $HAVE, unpinned — set GRAPHIFY_VERSION=$HAVE in .conf so every machine builds the same graph"; fi
  TOOL_OK=1
}

# -- run ----------------------------------------------------------------------------------------------
echo "== graphs — Graphify knowledge graphs ($VERB) — $(date '+%Y-%m-%d %H:%M') =="
case "$VERB" in
  home)
    home_instance
    for s in "${SLUGS[@]}"; do home_repo "$s"; done
    write_index ;;
  check)
    if HAVE=$(tool_version); then
      if [ -n "$PIN" ] && [ "$HAVE" != "$PIN" ]; then fail "graphify $HAVE on PATH, GRAPHIFY_VERSION pins $PIN"; else ok "graphify $HAVE${PIN:+ (pinned)}"; fi
    else warn "graphify is not on PATH — install with: $HINT"; fi
    for s in "${SLUGS[@]}"; do
      repo=${REPO_PATH[$s]}; live="$GRAPHS_DIR/$s/live"; snap="$GRAPHS_DIR/$s/graph.json"
      [ -d "$repo" ] || { fail "$s: repository not found at $repo"; continue; }
      [ -f "$repo/.graphifyignore" ] || { info "$s: not homed ($repo has no .graphifyignore) — run: bash $SELF home $s"; continue; }
      ensure_link "$s" "$repo" "$live" 0 || continue
      [ -f "$snap" ] || { warn "$s: homed but never scanned (no graphs/$s/graph.json) — run: bash $SELF scan $s"; continue; }
      read -r nodes edges comms commit <<< "$(graph_facts "$snap")"
      [ -n "${nodes:-}" ] || { fail "$s: graphs/$s/graph.json is not a readable graph"; continue; }
      head=$(repo_head "$repo")
      if [ -n "$head" ] && [ "$commit" != "-" ] && [ "${head#"$commit"}" = "$head" ]; then
        warn "$s: snapshot built at ${commit:0:12}, repository HEAD is ${head:0:12} — stale, run: bash $SELF scan $s"
      else
        ok "$s: $nodes nodes, $edges edges, $comms communities, built at ${commit:0:12}"
      fi
      if [ -f "$live/graph.json" ]; then
        read -r _ _ _ lcommit <<< "$(graph_facts "$live/graph.json")"
        [ "${lcommit:-}" != "$commit" ] && info "$s: the live layer is at ${lcommit:0:12} (a hook rebuild); the snapshot is what is committed"
      fi
    done
    if [ -d "$GRAPHS_DIR" ] && [ -f "$GRAPHS_DIR/.index.md" ]; then
      [ "$(cat "$GRAPHS_DIR/.index.md")" = "$(index_text)" ] && ok "graphs/.index.md matches the graphs on disk" || fail "graphs/.index.md drifts from the graphs on disk — run: bash $SELF scan"
      [ "$(cat "$GRAPHS_DIR/.agent" 2>/dev/null)" = "$(agent_text)" ] && ok "graphs/.agent is current" || fail "graphs/.agent drifts — run: bash $SELF scan"
    else
      warn "graphs/ is not scaffolded — run: bash $SELF home <slug>"
    fi ;;
  scan)
    check_tool
    [ -d "$GRAPHS_DIR" ] && [ -f "$GRAPHS_DIR/.index.md" ] || { fail "graphs/ is not scaffolded — run: bash $SELF home <slug> first"; }
    if [ $TOOL_OK -eq 1 ] && [ -f "$GRAPHS_DIR/.index.md" ]; then
      for s in "${SLUGS[@]}"; do
        repo=${REPO_PATH[$s]}; live="$GRAPHS_DIR/$s/live"; snap="$GRAPHS_DIR/$s/graph.json"
        [ -d "$repo" ] || { fail "$s: repository not found at $repo"; continue; }
        [ -f "$repo/.graphifyignore" ] || { info "$s: not homed ($repo has no .graphifyignore) — skipped; run: bash $SELF home $s"; continue; }
        ensure_link "$s" "$repo" "$live" 0 || continue
        # Always from scratch: graphify MERGES into an existing graph.json (its "existing layer"
        # is preserved), and a hook rebuild also extracts markdown offline, so an incremental run
        # over the hook's output would carry foreign nodes into the committed snapshot. The parse
        # cache stays: it is keyed by file hash and only makes the rebuild faster. --force drops it.
        for stale in graph.json manifest.json .graphify_analysis.json; do rm -f "$live/$stale"; done
        args=(extract "$repo" --code-only); [ $FORCE -eq 1 ] && args+=(--force)
        (cd "$repo" && graphify "${args[@]}" 2>&1 | sed 's/^/       /'; exit "${PIPESTATUS[0]}"); rc=$?
        [ $rc -eq 0 ] || { fail "$s: graphify extract exited $rc"; continue; }
        [ -f "$live/graph.json" ] || { fail "$s: the scan wrote no $live/graph.json"; continue; }
        # a forced run makes graphify back the previous output up into a dated folder; every run
        # here is from scratch, so there is nothing to roll back to
        for d in "$live"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]; do [ -d "$d" ] && rm -rf "$d"; done
        cp "$live/graph.json" "$snap" || { fail "$s: could not copy the snapshot up"; continue; }
        read -r nodes edges comms commit <<< "$(graph_facts "$snap")"
        ok "$s: scanned — ${nodes:-?} nodes, ${edges:-?} edges, ${comms:-?} communities at ${commit:0:12}; snapshot graphs/$s/graph.json"
        if [ $GLOBAL -eq 1 ]; then
          if graphify global add "$snap" --as "$s" >/dev/null 2>&1; then ok "$s: registered in the global graph"; else warn "$s: graphify global add failed (the snapshot is written)"; fi
        fi
      done
      write_agent
      write_index
    fi ;;
esac
echo "== graphs: $FAIL fail(s), $WARN warning(s) =="
exit $FAIL
