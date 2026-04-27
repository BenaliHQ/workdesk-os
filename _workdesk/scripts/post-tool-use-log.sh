#!/usr/bin/env bash
# post-tool-use-log.sh
#
# Categorizes a tool call against the 11 V1 semantic event classes and
# appends one line to system/events/{YYYY-MM}.md. Drops anything that
# doesn't match. The narrowing is intentional — see plan §"Event logging".
#
# Concurrency: shlock(1) preferred; falls back to atomic mkdir locking
# on .events.lock.d/. Lock contention beyond 3 retries drops the entry
# and warns to stderr (operations succeed; the log is observability).
#
# Latency budget: < 50ms p95.

set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${CLAUDE_PROJECT_DIR:-$(cd "$DIR/../.." && pwd)}"
EVENTS_DIR="$VAULT/system/events"
MONTH=$(date '+%Y-%m')
EVENTS_FILE="$EVENTS_DIR/$MONTH.md"
LOCK_DIR="$EVENTS_DIR/.events.lock.d"

input="$(cat)"
[[ -z "$input" ]] && exit 0

# Parse the three flat fields we need with bash regex — no external
# interpreter, sub-millisecond cost. Falls back to empty on no match.
tool=""
path=""
cmd=""
re_tool='"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)"'
re_path='"file_path"[[:space:]]*:[[:space:]]*"([^"]*)"'
re_npath='"notebook_path"[[:space:]]*:[[:space:]]*"([^"]*)"'
re_cmd='"command"[[:space:]]*:[[:space:]]*"((\\.|[^"\\])*)"'

[[ "$input" =~ $re_tool  ]] && tool="${BASH_REMATCH[1]}"
[[ "$input" =~ $re_path  ]] && path="${BASH_REMATCH[1]}"
[[ -z "$path" && "$input" =~ $re_npath ]] && path="${BASH_REMATCH[1]}"
[[ "$input" =~ $re_cmd   ]] && cmd="${BASH_REMATCH[1]}"

[[ -z "$tool" ]] && exit 0

# --- categorize ------------------------------------------------------------

event_class=""
target=""

case "$tool" in
  Write)
    case "$path" in
      */gtd/projects/*/_brief.md)        event_class="project-created";    target="$path" ;;
      */atlas/initiatives/*/_brief.md)   event_class="initiative-created"; target="$path" ;;
      */atlas/areas/*/_brief.md)         event_class="object-created";     target="$path" ;;
      */atlas/clients/*/_brief.md|\
      */atlas/businesses/*/_brief.md|\
      */atlas/teams/*/_brief.md|\
      */atlas/labs/*/_brief.md|\
      */atlas/disciplines/*/_brief.md|\
      */atlas/collaborations/*/_brief.md|\
      */atlas/departments/*/_brief.md)
                                          event_class="object-created";     target="$path" ;;
      */atlas/meetings/*.md|\
      */atlas/decisions/*.md|\
      */atlas/people/*.md|\
      */atlas/companies/*.md|\
      */atlas/content/*.md)
                                          event_class="object-created";     target="$path" ;;
      */gtd/actions/next/*.md)            event_class="action-promoted";    target="$path" ;;
      */intel/briefings/*.md|\
      */intel/vault-improvements/*.md|\
      */intel/observations/*.md|\
      */intel/research/*.md)
                                          event_class="signal-generated";   target="$path" ;;
      */_workdesk/objects/*.md|\
      */_workdesk/signals/*.md|\
      */_workdesk/sources/*.md|\
      */_workdesk/practices/*.md|\
      */_workdesk/rules/*.md|\
      */_workdesk/tools/*.md|\
      */_workdesk/templates/*.md|\
      */_workdesk/skills/*/SKILL.md)
                                          event_class="declaration-changed"; target="$path" ;;
    esac
    ;;
  Edit|MultiEdit)
    case "$path" in
      */_workdesk/objects/*.md|\
      */_workdesk/signals/*.md|\
      */_workdesk/sources/*.md|\
      */_workdesk/practices/*.md|\
      */_workdesk/rules/*.md|\
      */_workdesk/tools/*.md|\
      */_workdesk/templates/*.md|\
      */_workdesk/skills/*/SKILL.md)
                                          event_class="declaration-changed"; target="$path" ;;
      */_workdesk/onboarding-state.md)    event_class="onboarding-phase-completed"; target="$path" ;;
      */system/transcripts/*.md|\
      */system/intake/*.md)               event_class="source-processed";   target="$path" ;;
    esac
    ;;
  Bash)
    # action-completed: move from gtd/actions/{next,waiting}/ to gtd/archive/actions/
    if printf '%s' "$cmd" | grep -Eq '\bmv\b.*gtd/actions/(next|waiting)/.*gtd/archive/actions'; then
      event_class="action-completed"
      target=$(printf '%s' "$cmd" | grep -oE 'gtd/actions/(next|waiting)/[^ ]+' | head -1)
    # object-archived: container folder → its _archive/ counterpart, or projects → archive/projects
    elif printf '%s' "$cmd" | grep -Eq '\bmv\b.*gtd/projects/.*gtd/archive/projects'; then
      event_class="object-archived"
      target=$(printf '%s' "$cmd" | grep -oE 'gtd/projects/[^ ]+' | head -1)
    elif printf '%s' "$cmd" | grep -Eq '\bmv\b.*atlas/(initiatives|clients|businesses|areas|teams|labs|disciplines|collaborations|departments)/.*_archive'; then
      event_class="object-archived"
      target=$(printf '%s' "$cmd" | grep -oE 'atlas/[^ ]+' | head -1)
    fi
    ;;
esac

[[ -z "$event_class" ]] && exit 0

# --- write with locking ----------------------------------------------------

mkdir -p "$EVENTS_DIR" 2>/dev/null || exit 0
[[ -f "$EVENTS_FILE" ]] || printf "# Events — %s\n\n" "$MONTH" > "$EVENTS_FILE"

# 5-second de-dup: if the last line in the file matches (event-class, target),
# skip. Cheap, single tail call.
if [[ -f "$EVENTS_FILE" ]]; then
  last=$(tail -n 1 "$EVENTS_FILE" 2>/dev/null || true)
  if printf '%s' "$last" | grep -qF " | $event_class | $target | "; then
    last_ts=$(printf '%s' "$last" | awk '{print $1, $2}')
    last_epoch=$(date -j -f '%Y-%m-%d %H:%M' "$last_ts" '+%s' 2>/dev/null || echo 0)
    now_epoch=$(date '+%s')
    if (( now_epoch - last_epoch < 5 )); then
      exit 0
    fi
  fi
fi

# Acquire lock (best-effort).
acquired=0
for attempt in 1 2 3; do
  if command -v shlock >/dev/null 2>&1; then
    if shlock -p $$ -f "$EVENTS_DIR/.events.lock" 2>/dev/null; then acquired=1; break; fi
  else
    if mkdir "$LOCK_DIR" 2>/dev/null; then acquired=1; break; fi
  fi
  sleep 0.05
done

if (( acquired == 0 )); then
  echo "post-tool-use-log: lock contention; dropped $event_class $target" >&2
  exit 0
fi

ts=$(date '+%Y-%m-%d %H:%M')
printf '%s | %s | %s | ok\n' "$ts" "$event_class" "$target" >> "$EVENTS_FILE"

# Release lock.
if command -v shlock >/dev/null 2>&1; then
  rm -f "$EVENTS_DIR/.events.lock"
else
  rmdir "$LOCK_DIR" 2>/dev/null || true
fi

exit 0
