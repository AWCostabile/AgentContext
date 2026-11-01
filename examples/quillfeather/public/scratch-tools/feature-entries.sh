#!/bin/bash
# feature-entries.sh — list every dated feature-log entry across every catalog, newest first.
#
# Usage: bash public/scratch-tools/feature-entries.sh [--since YYYY-MM-DD] [root]
#   root     the tree's root (the directory holding public/); default the current directory
#   --since  only entries dated on or after that day
#
# Prints one line per entry: the date, the feature-log leaf's H1, and the entry's first sentence.

since=0000-00-00
if [ "$1" = "--since" ]; then since=$2; shift 2; fi
root=${1:-.}

find "$root/public" -path '*/features/features.*.md' -type f | while read -r leaf; do
  awk -v since="$since" '
    /^# / && title == "" { title = substr($0, 3); next }
    /^\*\*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\*\*/ {
      date = substr($0, 3, 10)
      if (date < since) next
      text = $0; sub(/^\*\*[^*]*\*\*[^A-Za-z]*/, "", text)
      while (text !~ /\. / && text !~ /\.$/ && (getline more) > 0) text = text " " more
      sub(/\. .*/, ".", text)
      printf "%s  %-26s  %s\n", date, title, text
    }
  ' "$leaf"
done | sort -r
