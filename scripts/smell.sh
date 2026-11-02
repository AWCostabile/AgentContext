#!/bin/bash
# smell.sh — hunt the knowledge tree's heuristic smells. Report-only.
#
# cure.sh checks structural INVARIANTS and FAILs; this script hunts SMELLS, things
# that are probably wrong but need judgement, and only warns. HYGIENE.md holds the
# catalog: each smell's signal, why it matters, its rectification and its deliberate
# exceptions.
#
# Two trees, one grammar: public/ is always scanned, and the private mirror is scanned
# when this machine has one (lib-scopes.sh mirror_dirs, never the freeform local/ mod/
# temp/). An absent private/ is never an error; the one smell that is ABOUT the private
# tree (S17: retros live in private/journal/retros/<YYYY-MM>/) is then not evaluated.
#
# Template mode: with no .conf at the root, the root is the skeleton itself. Every tag,
# Contents row or cell carrying a {{ }} placeholder is skipped, and S09 (template
# residue) is not evaluated at all.
#
#   S01 stale design leaf          _reviewed:_ older than 90 days
#   S02 design leaf w/o provenance  missing _source:_ or _reviewed:_
#   S03 dead tag                    .tags entry never occurring in its branch
#   S04 tag fragmentation           singleton tag with a near-neighbour
#   S05 index row drift             Contents link text != target leaf's H1
#   S06 manifest gaps               unmerged/unknown rows, malformed Created
#   S07 CRLF                        \r in an authored *.md
#   S08 empty or shell leaf         <= 3 non-blank lines, or headings only
#   S09 template residue            {{ or }} in either tree (instances only)
#   S10 unindexed .agent            .agent present, index never mentions it
#   S11 cross-branch row            Contents row linking outside its branch
#   S12 duplicate leaf basename     same leaf name in two branches
#   S13 retired vocabulary          retired-terms.txt hits in live documents
#   S14 oversized index context     > 5 prose lines before the Contents table
#   S16 archive marker mismatch     _status:_ archived vs _(archived)_ row
#   S17 retrospective overdue       >= 3 manifest rows landed since the last retro
#   S18 process vocabulary          epic/sprint/retro, numbered plan/wave/phase, in public/
# Ids are stable; a missing number is a retired check.
#
# Usage: bash scripts/smell.sh [--root <dir>] [--quiet]
#   --root <dir>  the tree root to scan (the directory holding public/ and .conf);
#                 default the current directory
#   --quiet       print only the summary
# Exit code: the number of smells found, capped at 255 (0 = clean). The summary line
# also carries landed-since-retro=<n> (S17's count, fired or not).
#
# Host notes: MSYS gawk strips \r unless BINMODE=3 and MSYS grep strips it unless -U,
# so S07 uses awk in binary mode; grep -x is avoided throughout (Git Bash's grep aborts
# on -x/-i); an anchored regex is the equivalent.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(pwd)"
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) [ $# -ge 2 ] || { echo "--root needs a directory" >&2; exit 2; }
            ROOT="$(cd "$2" 2>/dev/null && pwd)" || { echo "no such directory: $2" >&2; exit 2; }
            shift 2 ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) sed -n '2,45p' "$0" | sed 's/^#//; s/^ //'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$ROOT" || exit 2
[ -d public ] || { echo "no public/ directory under $ROOT — pass --root <tree root>" >&2; exit 2; }
. "$SCRIPT_DIR/lib-scopes.sh"
mapfile -t MIRROR < <(mirror_dirs)
MIRROR_ROOT=(); has_mirror && MIRROR_ROOT=(private/.index.md)
TMPL=0; template_mode && TMPL=1

# The tree's own retired vocabulary when it has one, else the list beside this script
TERMS="$ROOT/scripts/retired-terms.txt"
[ -f "$TERMS" ] || TERMS="$SCRIPT_DIR/retired-terms.txt"

IDS="S01 S02 S03 S04 S05 S06 S07 S08 S09 S10 S11 S12 S13 S14 S16 S17 S18"
declare -A COUNT
for id in $IDS; do COUNT[$id]=0; done
TOTAL=0 LANDED=0

# Every check emits "<id>\t<message>" lines; this collects them. A "LANDED" line
# carries S17's raw count for the summary rather than a smell.
emit() {
  local id msg
  while IFS=$'\t' read -r id msg; do
    [ -n "$id" ] || continue
    if [ "$id" = LANDED ]; then LANDED=$msg; continue; fi
    COUNT[$id]=$((COUNT[$id] + 1)); TOTAL=$((TOTAL + 1))
    [ $QUIET -eq 1 ] || printf '[SMELL %s] %s\n' "$id" "$msg"
  done
}

MODE="instance"; [ $TMPL -eq 1 ] && MODE="template mode"
[ $QUIET -eq 1 ] || echo "== smell — knowledge-tree hygiene ($MODE) — $(date '+%Y-%m-%d %H:%M') =="

# Every scanned *.md of both trees
mapfile -t ALL_MD < <({ find public "${MIRROR[@]}" -type f -name '*.md'; printf '%s\n' "${MIRROR_ROOT[@]}"; } | grep -v '^$' | sort)
mapfile -t LEAVES < <(printf '%s\n' "${ALL_MD[@]}" | grep -v '/\.index\.md$')
# A MOVED STUB is the small leaf a sanctioned move leaves at the old path so every
# citation keeps resolving: its _status:_ archived line says "moved to <new path>". It
# is a pointer by design, so the smells that judge a leaf's substance (S01/S02
# provenance, S08 shell leaf, S12 duplicate basename: it shares its name with the leaf
# it points at) skip it. S05 and S16 still read it like any archived leaf.
MOVED=" $(grep -lE '^_status:_[ \t]*archived .*moved to ' "${LEAVES[@]}" /dev/null 2>/dev/null | tr '\n' ' ') "
moved() { case "$MOVED" in *" $1 "*) return 0 ;; esac; return 1; }
mapfile -t TAGFILES < <(find public "${MIRROR[@]}" -type f -name '.tags' | sort)
ROOT_DOCS=()
for f in AGENTS.md HYGIENE.md README.md; do [ -f "$f" ] && ROOT_DOCS+=("$f"); done

# Verbatim provenance copies keep their source bytes (CRLF, {{ }} and all): leaves
# under an immutable root (lib-scopes.sh verbatim_path), and leaves listed in a
# provenance manifest (an index whose Contents table has a "Landed as" column, the
# same test cure.sh uses). Indexes are authored, never verbatim, so they stay in scope.
MANIFEST_DIRS=$(grep -lF '| Landed as |' "${ALL_MD[@]}" /dev/null 2>/dev/null | sed 's|/\.index\.md$||' | tr '\n' ' ')
verbatim() {
  verbatim_path "$1" && return 0
  case "$1" in */.index.md) return 1 ;; esac
  case " $MANIFEST_DIRS " in *" ${1%/*} "*) return 0 ;; esac
  return 1
}
NONVERBATIM=()
for f in "${ALL_MD[@]}"; do verbatim "$f" || NONVERBATIM+=("$f"); done

# -- S01 / S02: design-leaf provenance -----------------------------------------
DESIGN=()
for f in "${LEAVES[@]}"; do
  case "$f" in */design/*) moved "$f" || DESIGN+=("$f") ;; esac
done
if [ ${#DESIGN[@]} -gt 0 ]; then
  emit < <(awk '
    { sub(/\r$/, "") }
    /^_source:_/ { src[FILENAME] = 1 }
    /^_reviewed:_/ {
      if (match($0, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/))
        rev[FILENAME] = substr($0, RSTART, RLENGTH)
    }
    END {
      now = systime()
      for (i = 1; i < ARGC; i++) {
        f = ARGV[i]
        if (!(f in src) || !(f in rev)) {
          miss = (f in src) ? "_reviewed:_" : ((f in rev) ? "_source:_" : "_source:_ and _reviewed:_")
          print "S02\t" f ": design leaf without provenance — missing " miss
          continue
        }
        split(rev[f], d, "-")
        age = int((now - mktime(d[1] " " d[2] " " d[3] " 0 0 0")) / 86400)
        if (age > 90)
          print "S01\t" f ": design leaf last reviewed " rev[f] " (" age " days ago) — re-verify against history/"
      }
    }' "${DESIGN[@]}")
fi

# -- S03: dead tags (one awk per branch; corpus = index + leaves + child indexes)
for tf in "${TAGFILES[@]}"; do
  d=${tf%/.tags}
  corpus=()
  for c in "$d"/.index.md "$d"/*.md "$d"/*/.index.md; do [ -f "$c" ] && corpus+=("$c"); done
  emit < <(awk -v tagsfile="$tf" -v branch="$d" -v tmpl="$TMPL" '
    # A tag counts as present when it occurs as a whole word (case-insensitive;
    # hyphens may be spelled as hyphen, space, or underscore; a trailing s may
    # be present or absent on either side) in the branch index, its leaves, or
    # its child indexes, or anywhere in the branch path.
    function scan(line,  t, re, hits, n, i) {
      n = 0
      for (t in left) {
        re = t; sub(/s$/, "", re); gsub(/-/, "[-_ ]", re)
        if (match(line, "(^|[^a-z0-9])" re "(s|es)?([^a-z0-9]|$)")) hits[++n] = t
      }
      for (i = 1; i <= n; i++) delete left[hits[i]]
    }
    BEGIN {
      while ((getline t < tagsfile) > 0) {
        gsub(/\r/, "", t)
        if (t == "" || (tmpl && t ~ /\{\{|\}\}/)) continue    # a placeholder, in the skeleton
        left[t] = 1
      }
      # path segments are often compound names, so a substring of the branch path is enough
      n = 0; for (t in left) if (index(tolower(branch), t)) hits[++n] = t
      for (i = 1; i <= n; i++) delete left[hits[i]]
    }
    { if (length(left) == 0) exit; scan(tolower($0)) }
    END { for (t in left) print "S03\t" tagsfile ": tag \047" t "\047 never occurs in this branch\047s path, index, leaves, or child indexes" }
  ' "${corpus[@]}")
done

# -- S04: tag fragmentation (singleton tags with a near-neighbour) -------------
if [ ${#TAGFILES[@]} -gt 0 ]; then
  emit < <(awk -v tmpl="$TMPL" '
    function min(a, b) { return a < b ? a : b }
    function lev(a, b,  i, j, la, lb, c, prev, cur, tmp) {
      la = length(a); lb = length(b)
      for (j = 0; j <= lb; j++) prev[j] = j
      for (i = 1; i <= la; i++) {
        cur[0] = i
        for (j = 1; j <= lb; j++) {
          c = (substr(a, i, 1) == substr(b, j, 1)) ? 0 : 1
          cur[j] = min(min(cur[j-1] + 1, prev[j] + 1), prev[j-1] + c)
        }
        for (j = 0; j <= lb; j++) prev[j] = cur[j]
      }
      return prev[lb]
    }
    function initials(t,  n, p, i, s) {
      n = split(t, p, "-"); if (n < 2) return ""
      s = ""; for (i = 1; i <= n; i++) s = s substr(p[i], 1, 1)
      return s
    }
    function prefixlen(a, b,  n, i) {
      n = min(length(a), length(b))
      for (i = 1; i <= n; i++) if (substr(a, i, 1) != substr(b, i, 1)) return i - 1
      return n
    }
    # Why two tags look like fragments of one search term ("" = they do not).
    function near(s, o,  d, m, p, ini) {
      if (s == o "s" || o == s "s") return ""        # exact plurals are cure.sh C07
      m = min(length(s), length(o))
      d = lev(s, o)
      if (m >= 3 && d <= 1) return "edit distance " d
      if (m >= 5 && d == 2 && substr(s, 1, 3) == substr(o, 1, 3)) return "edit distance 2"
      p = prefixlen(s, o)
      if (p >= 4 && p * 10 >= m * 8) return "shared stem \047" substr(s, 1, p) "\047"
      ini = initials(o); if (ini != "" && (s == ini || s == ini "s")) return "abbreviation"
      ini = initials(s); if (ini != "" && (o == ini || o == ini "s")) return "abbreviation"
      return ""
    }
    { gsub(/\r/, ""); if ($0 == "" || (tmpl && /\{\{|\}\}/)) next
      n[$0]++; if (!($0 in where)) where[$0] = FILENAME }
    END {
      for (s in n) {
        if (n[s] != 1) continue
        for (o in n) {
          if (o == s) continue
          key = (s < o) ? s SUBSEP o : o SUBSEP s
          if (key in seen) continue
          why = near(s, o)
          if (why == "") continue
          seen[key] = 1
          print "S04\t" where[s] ": tag \047" s "\047 used once tree-wide — near \047" o "\047 (" n[o] " use" (n[o] == 1 ? "" : "s") ", " why ") — unify to one form or drop the fragment"
        }
      }
    }' "${TAGFILES[@]}")
fi

# -- S17 baseline: the newest retrospective leaf (retro.YYYY-MM-DD.<slug>.md) --
# Retros are development-cycle records and live in the private journal, grouped by
# month (private/journal/retros/<YYYY-MM>/), so the search descends. With no retro
# leaf yet, every landed row counts. With no private tree at all S17 is not
# evaluated (RETRO_ON=0): nothing here could satisfy it.
RETRO_DIR=private/journal/retros
RETRO_ON=0; has_mirror && RETRO_ON=1
RETRO_FILE="" RETRO_DATE=""
if [ -d "$RETRO_DIR" ]; then
  latest=$(find "$RETRO_DIR" -type f -name 'retro.*.md' -printf '%f\n' 2>/dev/null \
    | grep -E '^retro\.[0-9]{4}-[0-9]{2}-[0-9]{2}\.' | sort | tail -1)
  if [ -n "$latest" ]; then RETRO_FILE=$latest; RETRO_DATE=${latest#retro.}; RETRO_DATE=${RETRO_DATE:0:10}; fi
fi

# -- S05 / S06 / S08 / S11 / S14 / S16 / S17: one pass over every *.md ---------
emit < <(awk -v moved="$MOVED" -v retrodate="$RETRO_DATE" -v retrofile="$RETRO_FILE" -v retrodir="$RETRO_DIR" -v retroon="$RETRO_ON" -v tmpl="$TMPL" '
  function dir(p) { sub(/\/[^\/]*$/, "", p); return p }
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  function norm(s) { gsub(/\\\|/, "|", s); gsub(/[ \t]+/, " ", s); return trim(s) }
  function cells(line, out,  n, i) {           # split a table row on unescaped |
    gsub(/\\\|/, "\001", line)
    n = split(line, out, "|")
    for (i = 1; i <= n; i++) { gsub(/\001/, "\\|", out[i]); out[i] = trim(out[i]) }
    return n
  }
  FNR == 1 {
    f = FILENAME; d = dir(f)
    isidx = (f ~ /\/\.index\.md$/)
    infence = 0; incomment = 0; contents = 0; hdr = 0; sep = 0
    nonblank[f] = 0; body[f] = 0; h1[f] = ""; prose[f] = 0
    if (isidx) idxfile[f] = 1; else leaf[f] = 1
  }
  { sub(/\r$/, "") }
  /^```/ { infence = !infence; next }
  /^[ \t]*$/ { next }
  { nonblank[f]++ }
  infence { body[f]++; next }
  /^<!--/ { incomment = 1 }
  incomment { if ($0 ~ /-->/) incomment = 0; next }
  h1[f] == "" && /^# / { h1[f] = substr($0, 3); next }
  /^_status:_[ \t]*archived/ { status[f] = $0 }
  !/^#/ { body[f]++ }
  !isidx { next }
  # ---- index-only bookkeeping below ----
  /^## Contents/ || /^\|/ { contents = 1 }
  !contents { if ($0 !~ /^_[a-z]+:_/ && $0 !~ /^#/) prose[f]++; next }
  /^\|/ {
    if (!hdr) {                                  # header row: locate columns
      hdr = cells($0, c)
      for (i = 1; i <= hdr; i++) {
        if (c[i] == "Created") created[f] = i
        if (c[i] == "Landed as") { landed[f] = i; manifest[d] = 1 }
      }
      next
    }
    if (!sep) { sep = 1; next }                  # separator row
    if (tmpl && $0 ~ /\{\{|\}\}/) next           # a placeholder row, in the skeleton
    nrow++; rowfile[nrow] = f; rowdir[nrow] = d; rowline[nrow] = $0
    if ((f in landed)) {
      nc = cells($0, c)
      cr = (f in created) ? c[created[f]] : ""; la = c[landed[f]]
      why = ""
      if ((f in created) && cr !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) why = "Created \047" cr "\047 is not YYYY-MM-DD"
      if (tolower(la) ~ /unmerged|unknown/) why = why (why == "" ? "" : "; ") "Landed as \047" la "\047"
      # S17: the newest landing date in the cell (ISO dates compare as strings); a moved
      # stub row is skipped: the record counts once, at its new home
      rest = la
      if (match($0, /\]\(\.\/[^)]*\)/) && index(moved, " " d "/" substr($0, RSTART + 4, RLENGTH - 5) " ")) rest = ""
      while (match(rest, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        dt = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
        if (retrodate == "" || dt > retrodate) { landedsince++; break }
      }
      if (why != "") {
        match($0, /\[[^\]]*\]/); nm = (RSTART ? substr($0, RSTART + 1, RLENGTH - 2) : c[2])
        print "S06\t" f ": row \047" nm "\047 — " why
      }
    }
  }
  END {
    if (!retroon) landedsince = 0
    print "LANDED\t" landedsince + 0
    if (landedsince >= 3) {
      if (retrodate == "")
        print "S17\t" retrodir "/: retro overdue: " landedsince " manifest rows landed and no retro yet"
      else
        print "S17\t" retrodir "/: retro overdue: " landedsince " manifest rows landed since " retrodate " (last retro: " retrofile ")"
    }
    for (f in leaf) {
      if (index(moved, " " f " ")) { }          # a moved stub is a pointer by design: no S08
      else if (nonblank[f] <= 3) print "S08\t" f ": empty or shell leaf (" nonblank[f] " non-blank line" (nonblank[f] == 1 ? "" : "s") ")"
      else if (body[f] == 0) print "S08\t" f ": shell leaf — headings only"
      if ((f in status) && status[f] !~ /^_status:_[ \t]*archived[ \t]+[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][ \t]+[—–-]+[ \t]*[^ \t]/)
        print "S16\t" f ": archived status line names no date or successor/reason — expected \047_status:_ archived YYYY-MM-DD — <reason>\047"
    }
    for (f in idxfile) {
      if (nonblank[f] == 0) print "S08\t" f ": empty index"
      if (prose[f] > 5) print "S14\t" f ": " prose[f] " prose lines before the Contents table (limit 5) — move detail into a leaf"
    }
    for (i = 1; i <= nrow; i++) {
      f = rowfile[i]; d = rowdir[i]; line = rowline[i]
      first = 1; rest = line
      while (match(rest, /\]\([^)]+\)/)) {
        t = substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH)
        text = ""
        if (first) {                                   # link text of the first link
          if (match(line, /\[[^\]]*\]\(/)) text = substr(line, RSTART + 1, RLENGTH - 3)
        }
        sub(/#.*$/, "", t); sub(/^<|>$/, "", t)
        if (t == "" || t ~ /^(https?|mailto):/ || t ~ /^\//) { first = 0; continue }
        sub(/^\.\//, "", t)
        if (!(d in manifest)) {
          if (t ~ /(^|\/)\.\.(\/|$)/ || (t ~ /\// && t !~ /^[^\/]+\/\.index\.md$/))
            print "S11\t" f ": row links outside its branch -> " t " — link the child\047s .index.md or a sibling leaf"
        }
        if (first && t !~ /\// && t != ".index.md") {
          target = d "/" t
          rowarch = (text ~ /_\(archived\)_/)
          want = text; sub(/[ \t]*_\(archived\)_[ \t]*$/, "", want)
          if ((target in h1) && h1[target] != "" && norm(want) != norm(h1[target]))
            print "S05\t" f ": row \047" norm(want) "\047 != H1 \047" norm(h1[target]) "\047 in " t
          if ((target in leaf)) {
            if ((target in status) && !rowarch)
              print "S16\t" f ": row for " t " lacks the _(archived)_ marker its leaf carries"
            else if (rowarch && !(target in status))
              print "S16\t" f ": row marks " t " _(archived)_ but the leaf has no _status:_ archived line"
          }
        }
        first = 0
      }
    }
  }' "${ALL_MD[@]}")

# -- S07: CRLF (verbatim copies excluded: CRLF there is source fidelity) ----------
mapfile -t CRLF_SCOPE < <(
  { printf '%s\n' "${NONVERBATIM[@]}"
    [ -d templates ] && find templates -type f -name '*.md'
    find . -maxdepth 1 -type f -name '*.md' | sed 's|^\./||'; } | grep -v '^$'
)
if [ ${#CRLF_SCOPE[@]} -gt 0 ]; then
  emit < <(awk -v BINMODE=3 '/\r$/ { print "S07\t" FILENAME ": CRLF line endings (first at line " FNR ") — store and check out LF" ; nextfile }' \
    "${CRLF_SCOPE[@]}")
fi

# -- S09: template residue (instances only; verbatim copies excluded; .tags/.agent included)
if [ $TMPL -eq 0 ]; then
  mapfile -t S09_SCOPE < <({ printf '%s\n' "${NONVERBATIM[@]}"; find public "${MIRROR[@]}" -type f \( -name '.tags' -o -name '.agent' \); } | grep -v '^$')
  if [ ${#S09_SCOPE[@]} -gt 0 ]; then
    emit < <(grep -cE '\{\{|\}\}' "${S09_SCOPE[@]}" /dev/null 2>/dev/null | grep -v ':0$' \
      | awk -F: '{ print "S09\t" $1 ": " $2 " template placeholder line" ($2 == 1 ? "" : "s") " ({{ }}) left unfilled" }')
  fi
fi

# -- S10: .agent present but never mentioned by its index ----------------------
emit < <(
  while IFS= read -r a; do
    d=${a%/.agent}
    grep -qF '.agent' "$d/.index.md" 2>/dev/null \
      || printf 'S10\t%s: .agent present but %s/.index.md never tells the reader to read it\n' "$a" "$d"
  done < <({ find public "${MIRROR[@]}" -type f -name '.agent' 2>/dev/null
             has_mirror && [ -f private/.agent ] && echo private/.agent; } | sort)
)

# -- S12: duplicate leaf basenames across branches -----------------------------
# Glossaries and feature-log leaves are per-product by design: every product carries a
# glossary.md and features.<area>.md of the same names. A moved stub shares its name
# with the leaf it points at by construction, and is skipped.
emit < <(printf '%s\n' "${LEAVES[@]}" | awk -v moved="$MOVED" '
  { if (index(moved, " " $0 " ")) next                     # a moved stub, not a second leaf
    n = split($0, p, "/"); b = p[n]; if (b == "glossary.md" || b ~ /^features[.]/ || b ~ /^codebase[.]/) next   # per-product by design; a generated tier keeps fixed names
    cnt[b]++; paths[b] = (b in paths) ? paths[b] ", " $0 : $0 }
  END { for (b in cnt) if (cnt[b] > 1) print "S12\t" b ": same leaf name in " cnt[b] " branches — " paths[b] }')

# -- S13: retired vocabulary in live documents ---------------------------------
# Scope: design/ subtrees, the glossaries, and the root documents; never verbatim
# provenance, which legitimately records the old names.
mapfile -t LIVE < <(
  { for f in "${ALL_MD[@]}"; do
      case "$f" in */design/*|*/glossary.md) verbatim "$f" || printf '%s\n' "$f" ;; esac
    done
    printf '%s\n' "${ROOT_DOCS[@]}"; } | grep -v '^$'
)
if [ -f "$TERMS" ] && [ ${#LIVE[@]} -gt 0 ]; then
  emit < <(awk -v terms="$TERMS" '
    BEGIN {
      while ((getline l < terms) > 0) {
        gsub(/\r/, "", l); if (l ~ /^# / || l ~ /^#$/ || l ~ /^[ \t]*$/) continue   # "# " = comment; "#word" = term
        n = split(l, p, "\t"); if (n < 2) continue
        nt++; term[nt] = p[1]; repl[nt] = p[2]; src[nt] = (n >= 3) ? p[3] : "retired-terms.txt"
      }
    }
    { sub(/\r$/, "")
      for (i = 1; i <= nt; i++) if (index($0, term[i]))
        print "S13\t" FILENAME ":" FNR ": retired \047" term[i] "\047 -> \047" repl[i] "\047 (" src[i] ")" }
  ' "${LIVE[@]}")
fi

# -- S14 is in the combined pass above -----------------------------------------

# -- S18: process vocabulary in authored public leaves --------------------------
# public/ reflects what IS, not the day-to-day work that produced it. Scope: every
# non-verbatim *.md under public/. Verbatim records keep the vocabulary they were
# written in, and a manifest INDEX is exempt too (its link texts are those records' own
# H1 titles). "wave", "plan" and "phase" alone are ordinary product words: only the
# numbered forms are work vocabulary.
mapfile -t S18_SCOPE < <(
  for f in "${NONVERBATIM[@]}"; do
    case "$f" in public/*) ;; *) continue ;; esac
    case "$f" in */.index.md) case " $MANIFEST_DIRS " in *" ${f%/.index.md} "*) continue ;; esac ;; esac
    printf '%s\n' "$f"
  done
)
if [ ${#S18_SCOPE[@]} -gt 0 ]; then
  emit < <(grep -ciE '\b(epics?|sprints?|retros?|retrospectives?)\b|\bplan [0-9]|\bwave [0-9]|\bphase [0-9]' "${S18_SCOPE[@]}" /dev/null 2>/dev/null | grep -v ':0$' \
    | awk -F: '{ print "S18\t" $1 ": " $2 " line" ($2 == 1 ? "" : "s") " of process vocabulary (epic/sprint/retro/numbered plan, wave or phase) — public/ describes what is, not how the work was run" }')
fi

# -- summary --------------------------------------------------------------------
echo "== SUMMARY: $TOTAL smell(s) — landed-since-retro=$LANDED =="
printf '   S01 stale design leaf %3d   S02 design leaf w/o provenance %3d   S03 dead tag         %3d   S04 tag fragmentation  %3d\n' \
  "${COUNT[S01]}" "${COUNT[S02]}" "${COUNT[S03]}" "${COUNT[S04]}"
printf '   S05 index row drift   %3d   S06 manifest gaps              %3d   S07 CRLF             %3d   S08 empty/shell leaf   %3d\n' \
  "${COUNT[S05]}" "${COUNT[S06]}" "${COUNT[S07]}" "${COUNT[S08]}"
printf '   S09 template residue  %3d   S10 unindexed .agent           %3d   S11 cross-branch row %3d   S12 duplicate basename %3d\n' \
  "${COUNT[S09]}" "${COUNT[S10]}" "${COUNT[S11]}" "${COUNT[S12]}"
printf '   S13 retired vocab     %3d   S14 oversized index context    %3d   S16 archive mismatch %3d   S17 retro overdue      %3d\n' \
  "${COUNT[S13]}" "${COUNT[S14]}" "${COUNT[S16]}" "${COUNT[S17]}"
printf '   S18 process vocabulary %2d   (rows landed since last retro: %d)\n' "${COUNT[S18]}" "$LANDED"
[ "$TOTAL" -gt 255 ] && exit 255
exit "$TOTAL"
