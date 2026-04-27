#!/usr/bin/env bash
# bench-hooks.sh — verifies p95 hook latency stays under 50ms.
#
# Fires the PostToolUse hook 50 times with a synthetic Write payload,
# measures wall time per invocation, sorts, and prints p50/p95/p99.

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$DIR/post-tool-use-log.sh"

[[ -x "$HOOK" ]] || { echo "hook not executable: $HOOK"; exit 1; }

VAULT="${CLAUDE_PROJECT_DIR:-$(cd "$DIR/../.." && pwd)}"
export CLAUDE_PROJECT_DIR="$VAULT"

payload='{"tool_name":"Write","tool_input":{"file_path":"'"$VAULT"'/atlas/meetings/bench-test.md"}}'

times=()
for i in $(seq 1 50); do
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
  exit 1
fi
echo "OK: p95 within 50ms budget"
exit 0
