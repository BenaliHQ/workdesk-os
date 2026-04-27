#!/usr/bin/env bash
# session-entry-scan.sh
#
# SessionStart hook. Scans the vault for unprocessed sources and stale
# signal state, writes _workdesk/state/session-entry.md, and emits a
# concise additionalContext payload that core skills consume.
#
# Output contract (Claude Code SessionStart hook):
#   {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${CLAUDE_PROJECT_DIR:-$(cd "$DIR/../.." && pwd)}"
STATE_FILE="$VAULT/_workdesk/state/session-entry.md"
SIGNALS_STATE="$VAULT/_workdesk/state/signals.json"
JSON_GET="$DIR/json-get.sh"

today=$(date '+%Y-%m-%d')
now=$(date '+%Y-%m-%d %H:%M')

# --- scan unprocessed transcripts -----------------------------------------
unprocessed_transcripts=()
if [[ -d "$VAULT/system/transcripts" ]]; then
  while IFS= read -r f; do
    if ! /usr/bin/grep -q '^processed: true' "$f" 2>/dev/null; then
      unprocessed_transcripts+=("$f")
    fi
  done < <(/usr/bin/find "$VAULT/system/transcripts" -maxdepth 2 -type f -name '*.md' 2>/dev/null)
fi

# --- scan intake ----------------------------------------------------------
intake_items=()
if [[ -d "$VAULT/system/intake" ]]; then
  while IFS= read -r f; do
    intake_items+=("$f")
  done < <(/usr/bin/find "$VAULT/system/intake" -maxdepth 2 -type f -name '*.md' 2>/dev/null)
fi

# --- scan unsummarized session-log raw files ------------------------------
unsummarized=()
if [[ -d "$VAULT/system/session-log" ]]; then
  while IFS= read -r f; do
    if ! /usr/bin/grep -q '^summarized: true' "$f" 2>/dev/null; then
      unsummarized+=("$f")
    fi
  done < <(/usr/bin/find "$VAULT/system/session-log" -maxdepth 1 -type f -name '*-raw.md' 2>/dev/null)
fi

# --- check signal staleness ----------------------------------------------
due_signals=()
if [[ -f "$SIGNALS_STATE" ]]; then
  daily_last=$(printf '%s' "$(cat "$SIGNALS_STATE")" | "$JSON_GET" daily-plan.last-fired 2>/dev/null || echo "")
  weekly_last=$(printf '%s' "$(cat "$SIGNALS_STATE")" | "$JSON_GET" weekly-review.last-fired 2>/dev/null || echo "")
  vimp_supp=$(printf '%s' "$(cat "$SIGNALS_STATE")" | "$JSON_GET" vault-improvements.suppressed-until 2>/dev/null || echo "")

  if [[ -z "$daily_last" || "$daily_last" < "$today" ]]; then
    due_signals+=("daily-plan")
  fi

  dow=$(date '+%u')   # 1=Mon..7=Sun
  if [[ "$dow" == "1" || "$dow" == "7" ]]; then
    if [[ -z "$weekly_last" ]] || (( $(date '+%s') - $(date -j -f '%Y-%m-%d' "$weekly_last" '+%s' 2>/dev/null || echo 0) > 518400 )); then
      due_signals+=("weekly-review")
    fi
  fi

  if [[ -n "$vimp_supp" && "$vimp_supp" != "null" && "$vimp_supp" < "$today" ]]; then
    due_signals+=("vault-improvements")
  fi
fi

# --- write state file -----------------------------------------------------
mkdir -p "$(dirname "$STATE_FILE")"
{
  echo "---"
  echo "last-scan: $now"
  echo "unprocessed:"
  echo "  transcripts:"
  for f in "${unprocessed_transcripts[@]:-}"; do [[ -n "$f" ]] && echo "    - \"$f\""; done
  echo "  intake:"
  for f in "${intake_items[@]:-}"; do [[ -n "$f" ]] && echo "    - \"$f\""; done
  echo "  unsummarized-session-logs:"
  for f in "${unsummarized[@]:-}"; do [[ -n "$f" ]] && echo "    - \"$f\""; done
  echo "due-signals:"
  for s in "${due_signals[@]:-}"; do [[ -n "$s" ]] && echo "  - $s"; done
  echo "---"
  echo ""
  echo "# Session Entry Scan ($now)"
} > "$STATE_FILE"

# --- emit additionalContext for Claude Code -------------------------------
ctx="WorkDesk OS session entry: "
ctx+="${#unprocessed_transcripts[@]} unprocessed transcripts, "
ctx+="${#intake_items[@]} intake items, "
ctx+="${#unsummarized[@]} unsummarized session logs. "
if (( ${#due_signals[@]} > 0 )); then
  ctx+="Due signals: $(IFS=,; echo "${due_signals[*]}"). "
else
  ctx+="No signals due. "
fi
ctx+="See _workdesk/state/session-entry.md for full state."

# Escape for JSON.
ctx_json=$(printf '%s' "$ctx" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$ctx")

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx_json}}
EOF
exit 0
