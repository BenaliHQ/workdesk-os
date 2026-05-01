#!/usr/bin/env bash
# session-end-session-dump.sh
#
# SessionEnd hook. Exports the Claude Code transcript JSONL to a raw
# markdown file in system/session-log/{date}-{time}-{session_id}-raw.md.
#
# /extract --summarize {raw-file} produces the final summarized note.
# This hook does NOT summarize — it only exports.

set -euo pipefail
IFS=$'\n\t'

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
  # M3: parse the JSONL transcript with python's json module rather than
  # regex/awk. Each line is a JSON object; we extract role + the
  # concatenated text of any string content blocks. Malformed lines are
  # skipped silently — the engine should never lose a session over a
  # single bad line.
  TRANSCRIPT="$transcript" /usr/bin/python3 - <<'PY'
import json, os, sys

path = os.environ["TRANSCRIPT"]
last_role = None
try:
    f = open(path, "r", encoding="utf-8", errors="replace")
except OSError:
    sys.exit(0)

with f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except (json.JSONDecodeError, ValueError):
            continue

        # Claude Code transcript shape: {"message": {"role": ..., "content": ...}}
        # plus older flat shapes {"role": ..., "content": ...}. Tolerate both.
        msg = obj.get("message") if isinstance(obj.get("message"), dict) else obj
        if not isinstance(msg, dict):
            continue
        role = msg.get("role")
        if role not in ("user", "assistant"):
            continue

        content = msg.get("content")
        chunks = []
        if isinstance(content, str):
            chunks.append(content)
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict):
                    t = block.get("text")
                    if isinstance(t, str):
                        chunks.append(t)
                elif isinstance(block, str):
                    chunks.append(block)
        text = "\n".join(c for c in chunks if c).strip()
        if not text:
            continue

        if role != last_role:
            print(f"## {role.capitalize()}\n")
            last_role = role
        print(text)
        print()
PY
} > "$out" 2>/dev/null

exit 0
