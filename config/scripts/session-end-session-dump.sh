#!/usr/bin/env bash
# session-end-session-dump.sh
#
# SessionEnd hook. Exports the Claude Code transcript JSONL to a raw
# markdown file in system/session-log/{date}-{time}-{session_id}-raw.md.
#
# /extract --summarize {raw-file} produces the final summarized note.
# This hook does NOT summarize — it only exports.

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_GET="$DIR/json-get.sh"
VAULT="${CLAUDE_PROJECT_DIR:-$(cd "$DIR/../.." && pwd)}"
LOG_DIR="$VAULT/system/session-log"

input="$(cat)"
session_id=$(printf '%s' "$input" | "$JSON_GET" session_id 2>/dev/null || true)
transcript=$(printf '%s' "$input" | "$JSON_GET" transcript_path 2>/dev/null || true)

[[ -z "$session_id" ]] && session_id="unknown"
[[ -z "$transcript" || ! -f "$transcript" ]] && exit 0

mkdir -p "$LOG_DIR"
ts=$(date '+%Y-%m-%d-%H-%M')
out="$LOG_DIR/${ts}-${session_id}-raw.md"

{
  echo "---"
  echo "type: source"
  echo "source-kind: session-log"
  echo "date: $(date '+%Y-%m-%d')"
  echo "session-id: $session_id"
  echo "transcript-path: \"$transcript\""
  echo "processed: false"
  echo "summarized: false"
  echo "complete: true"
  echo "---"
  echo ""
  echo "# Conversation"
  echo ""
  /usr/bin/awk '
    BEGIN { entry=0 }
    /"role"[[:space:]]*:[[:space:]]*"user"/    { entry=1; print "## User\n"; next }
    /"role"[[:space:]]*:[[:space:]]*"assistant"/ { entry=2; print "## Assistant\n"; next }
    {
      if (match($0, /"text"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
        t = substr($0, RSTART, RLENGTH)
        sub(/.*: *"/, "", t)
        sub(/"$/, "", t)
        gsub(/\\n/, "\n", t)
        print t
        print ""
      }
    }
  ' "$transcript"
} > "$out" 2>/dev/null

exit 0
