#!/usr/bin/env bash
# bench-hooks.sh — verifies p95 hook latency stays under 50ms.
#
# Fires the PostToolUse hook 50 times with a synthetic Write payload,
# measures wall time per invocation, sorts, and prints p50/p95/p99.
#
# M4: bench writes go to an isolated scratch vault under $TMPDIR, never
# to the real CLAUDE_PROJECT_DIR. The hook still resolves its EVENTS_DIR
# from CLAUDE_PROJECT_DIR, so we override CLAUDE_PROJECT_DIR for the
# duration of the bench. The scratch dir is removed on exit.

set -euo pipefail
IFS=$'\n\t'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$DIR/post-tool-use-log.sh"

[[ -x "$HOOK" ]] || { echo "hook not executable: $HOOK"; exit 1; }

# Build an isolated scratch vault. The hook reads CLAUDE_PROJECT_DIR to
# decide where to log; pointing it at the scratch dir means production
# state at the real vault stays untouched even if the bench runs against
# a live install.
SCRATCH=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/workdesk-bench.XXXXXX")
cleanup() { rm -rf "$SCRATCH" 2>/dev/null || true; }
trap cleanup EXIT INT TERM HUP

mkdir -p "$SCRATCH/system/events"
export CLAUDE_PROJECT_DIR="$SCRATCH"

payload='{"tool_name":"Write","tool_input":{"file_path":"'"$SCRATCH"'/atlas/meetings/bench-test.md"}}'

times=()
for _ in $(seq 1 50); do
  start=$(/usr/bin/python3 -c 'import time;print(int(time.time()*1000000))')
  printf '%s' "$payload" | "$HOOK" >/dev/null 2>&1 || true
  end=$(/usr/bin/python3 -c 'import time;print(int(time.time()*1000000))')
  times+=($(( (end - start) / 1000 )))   # ms
done

sorted=($(printf '%s\n' "${times[@]}" | sort -n))
n=${#sorted[@]}
p50=${sorted[$(( n / 2 ))]}
p95=${sorted[$(( n * 95 / 100 ))]}
p99=${sorted[$(( n * 99 / 100 ))]}

echo "post-tool-use-log latency (n=$n):"
echo "  p50: ${p50}ms"
echo "  p95: ${p95}ms"
echo "  p99: ${p99}ms"

if (( p95 > 50 )); then
  echo "WARN: p95 exceeds 50ms budget"
else
  echo "OK: p95 within 50ms budget"
fi
exit 0
