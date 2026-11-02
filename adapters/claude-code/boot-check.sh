#!/bin/bash
# boot-check.sh — the deploy smoke's headless boot of a deployed Claude Code instance.
# Not part of the payload: never copied into an instance.
#
# Usage: bash adapters/claude-code/boot-check.sh <instance dir>
#
# Starts the harness non-interactively inside the instance, with the instance's own
# project settings only (no user or machine hooks), and asks for the first line of the
# context its SessionStart hook handed over. In a fresh instance that line is the orient
# hook's tree verdict: "Knowledge tree orient — cure.sh --fast: == VERDICT: …".
#
# Exit 0: booted, and the reply carries the verdict line. Exit 1: booted, and it did not.
# Exit 3: not run; stdout carries the reason (no CLI on PATH, the call failed or timed out).
set -u
INST=${1:-}
[ -d "$INST" ] || { echo "no instance directory: ${INST:-<none>}"; exit 3; }
command -v claude >/dev/null 2>&1 || { echo "the claude CLI is not on PATH"; exit 3; }

T=""
command -v timeout >/dev/null 2>&1 && T="timeout 120"
PROMPT="Reply with exactly the first line of the additional context your session start hook gave you, and nothing else."
# A nested launch from inside a running session is refused unless its marker is unset.
reply=$(cd "$INST" && env -u CLAUDECODE $T claude -p "$PROMPT" --output-format text --max-turns 1 \
  --setting-sources project --no-session-persistence 2>&1); rc=$?
if [ $rc -ne 0 ]; then
  echo "the headless call failed (exit $rc): $(printf '%s' "$reply" | head -n 1 | cut -c1-160)"
  exit 3
fi
printf '%s\n' "$reply" | head -n 3
printf '%s' "$reply" | grep -qE 'VERDICT|cure' && exit 0
exit 1
