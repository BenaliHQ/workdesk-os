#!/usr/bin/env bash
# stop-session-snapshot.sh
#
# Stop hook. Optional fallback for when SessionEnd is unreliable.
# Upserts ONE raw file per session_id (never one file per turn).
# /workdesk-doctor decides at install time whether to use SessionEnd
# or this fallback.
#
# Marks complete: false until SessionEnd or doctor declares it complete.

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_GET="$DIR/json-get.sh"
VAULT="${CLAUDE_PROJECT_DIR:-$(cd "$DIR/../.." && pwd)}"
LOG_DIR="$VAULT/system/session-log"
DOCTOR_STATE="$VAULT/_workdesk/state/doctor.md"

# Only run if doctor has explicitly enabled the Stop fallback.
if [[ ! -f "$DOCTOR_STATE" ]] || ! grep -q '^stop-fallback: enabled' "$DOCTOR_STATE" 2>/dev/null; then
  exit 0
fi

input="$(cat)"
session_id=$(printf '%s' "$input" | "$JSON_GET" session_id 2>/dev/null || true)
transcript=$(printf '%s' "$input" | "$JSON_GET" transcript_path 2>/dev/null || true)

[[ -z "$session_id" || -z "$transcript" || ! -f "$transcript" ]] && exit 0

mkdir -p "$LOG_DIR"

# One file per session_id; upsert (overwrite) on every Stop.
out="$LOG_DIR/$(date '+%Y-%m-%d')-${session_id}-raw.md"
{
  echo "---"
  echo "type: source"
  echo "source-kind: session-log"
  echo "date: $(date '+%Y-%m-%d')"
  echo "session-id: $session_id"
  echo "transcript-path: \"$transcript\""
  echo "processed: false"
  echo "summarized: false"
  echo "complete: false"
  echo "---"
  echo ""
  echo "# Conversation (Stop-snapshot, may be partial)"
  echo ""
  cat "$transcript" 2>/dev/null | head -c 1048576
} > "$out"

exit 0
