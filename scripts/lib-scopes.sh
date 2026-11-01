#!/bin/bash
# lib-scopes.sh — which trees, private branches and catalogs are in scope, read once.
#
# Source it with ROOT set to the tree root (the directory holding public/ and .conf).
# Every function prints paths relative to ROOT and spawns at most a handful of
# processes: on Windows each spawn costs about 15 ms, and the scripts that source this
# run on every write.
#
# public/   what is true. Always present, always in scope.
# private/  how the work was run, as known on ONE machine: a nested git repository the
#           parent ignores wholly. It may be absent (a fresh clone has none), and that
#           is never an error: every private function below then prints nothing.
#
#   conf_key KEY       the value of KEY in .conf, quotes stripped; nothing when .conf
#                      or the key is absent
#   template_mode      true when the root has no .conf: the skeleton itself, where every
#                      {{ }} placeholder is expected and skipped by the checks
#   catalogs           the words of .conf's CATALOGS (the top-level buckets of public/)
#   private_scopes     the words of .conf's PRIVATE_SCOPES (the private branches search
#                      covers by default); nothing when unset or empty: public-only
#   search_dirs [all]  "public", plus private/<scope> for each configured scope that
#                      exists (and private/.index.md, so index search sees the private
#                      root); with "all", every top-level private branch (find.sh -p)
#   mirror_dirs        the private branches that follow the branch grammar and are
#                      linted: every top-level private directory except the freeform ones.
#                      Presence-driven, not scope-driven: a tree that exists is kept
#                      sound whether or not it is searched.
#   has_mirror         true when private/ holds an instantiated mirror
#   verbatim_path P    true when P lies in an immutable provenance root, where records
#                      are copied verbatim: public/**/history/, and in the private tree
#                      any plans/, kickoffs/, prs/ or appendices/ branch and
#                      journal/retros/. An index is never verbatim (it is authored).
#                      Leaves listed in a manifest are the second signal; the scripts
#                      test that themselves, from the index text they already hold.
#
# Freeform private directories keep their own conduct (.agent) and are never linted.
FREEFORM_PRIVATE="local mod temp"

has_mirror() { [ -f "$ROOT/private/.index.md" ]; }

template_mode() { [ ! -f "$ROOT/.conf" ]; }

conf_key() {
  [ -f "$ROOT/.conf" ] || return 0
  local line
  line=$(grep -E "^[[:space:]]*$1=" "$ROOT/.conf" 2>/dev/null | tail -n 1)
  [ -n "$line" ] || return 0
  line=${line#*=}
  line=${line%$'\r'}
  line=${line//\"/}
  line=${line//\'/}
  printf '%s' "$line"
}

# true when .conf names the key at all (even with an empty value)
conf_has_key() { [ -f "$ROOT/.conf" ] && grep -qE "^[[:space:]]*$1=" "$ROOT/.conf" 2>/dev/null; }

catalogs()       { local w; for w in $(conf_key CATALOGS); do printf '%s\n' "$w"; done; }
private_scopes() { local w; for w in $(conf_key PRIVATE_SCOPES); do printf '%s\n' "$w"; done; }

_private_top_dirs() {
  local d name
  for d in "$ROOT"/private/*/; do
    [ -d "$d" ] || continue
    name=${d%/}; name=${name##*/}
    printf '%s\n' "$name"
  done
}

search_dirs() {
  local mode=${1:-} s any=0
  printf 'public\n'
  [ -d "$ROOT/private" ] || return 0
  if [ "$mode" = all ]; then
    for s in $(_private_top_dirs); do printf 'private/%s\n' "$s"; any=1; done
  else
    for s in $(private_scopes); do
      [ -d "$ROOT/private/$s" ] && { printf 'private/%s\n' "$s"; any=1; }
    done
  fi
  [ $any -eq 1 ] && [ -f "$ROOT/private/.index.md" ] && printf 'private/.index.md\n'
  return 0
}

mirror_dirs() {
  has_mirror || return 0
  local s
  for s in $(_private_top_dirs); do
    case " $FREEFORM_PRIVATE " in *" $s "*) continue ;; esac
    printf 'private/%s\n' "$s"
  done
}

verbatim_path() {
  case "$1" in
    */.index.md) return 1 ;;
    public/*)  case "/${1#public/}" in */history/*) return 0 ;; esac ;;
    private/*) case "/${1#private/}" in
                 */plans/*|*/kickoffs/*|*/prs/*|*/appendices/*|/journal/retros/*) return 0 ;;
               esac ;;
  esac
  return 1
}
