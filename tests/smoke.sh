#!/usr/bin/env bash
# Smoke test for WorkDesk OS bootstrap.
#
# Bootstraps a fresh vault into a tmp dir, asserts required paths exist,
# exercises the personal-lock and post-tool-use-log hooks directly, and
# verifies the dirty-vault refusal path. Ported from the codex sibling
# repo's tests/smoke.sh.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_root="$repo_root/.workdesk-test-vaults"
vault="$test_root/fresh-vault"
dirty="$test_root/dirty-vault"

rm -rf "$test_root"
mkdir -p "$vault" "$dirty"

printf 'existing content\n' > "$dirty/existing.md"

printf '== bootstrap fresh vault ==\n'
"$repo_root/bootstrap.sh" "$vault" >/tmp/workdesk-smoke-bootstrap.out

required_paths=(
  "$vault/_workdesk/settings.json"
  "$vault/_workdesk/scripts/pre-tool-use-personal-lock.sh"
  "$vault/_workdesk/scripts/post-tool-use-log.sh"
  "$vault/_workdesk/skills/workdesk-doctor/SKILL.md"
  "$vault/_workdesk/signals/daily-plan.md"
  "$vault/_workdesk/agents/orchestrator.md"
  "$vault/personal/daily"
  "$vault/atlas/areas"
  "$vault/gtd/recurring/schedules"
  "$vault/intel/briefings/daily"
  "$vault/system/events"
)

for path in "${required_paths[@]}"; do
  [[ -e "$path" ]] || { printf 'missing expected path: %s\n' "$path" >&2; exit 1; }
done

[[ -L "$vault/.claude" ]] || { printf '.claude symlink missing\n' >&2; exit 1; }
/usr/bin/plutil -extract hooks raw -o - "$vault/_workdesk/settings.json" >/dev/null

printf '== personal lock direct probe ==\n'
# This repo's lock uses the JSON permissionDecision contract: always exits 0,
# emits {"hookSpecificOutput":{"permissionDecision":"deny",...}} on stdout.
lock_json='{"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":"'"$vault"'","tool_input":{"command":"touch personal/daily/x.md"}}'
printf '%s' "$lock_json" | "$vault/_workdesk/scripts/pre-tool-use-personal-lock.sh" \
  >/tmp/workdesk-smoke-lock.out 2>/tmp/workdesk-smoke-lock.err
/usr/bin/grep -q '"permissionDecision":"deny"' /tmp/workdesk-smoke-lock.out || {
  printf 'expected personal lock to deny Bash mutation; got: %s\n' "$(cat /tmp/workdesk-smoke-lock.out)" >&2
  exit 1
}

# Read-only Bash on personal/ should be allowed (no deny output).
read_json='{"hook_event_name":"PreToolUse","tool_name":"Bash","cwd":"'"$vault"'","tool_input":{"command":"ls personal/"}}'
printf '%s' "$read_json" | "$vault/_workdesk/scripts/pre-tool-use-personal-lock.sh" \
  >/tmp/workdesk-smoke-lock-read.out 2>/dev/null
if /usr/bin/grep -q '"permissionDecision":"deny"' /tmp/workdesk-smoke-lock-read.out; then
  printf 'read-only Bash on personal/ should not be denied\n' >&2
  exit 1
fi

printf '== event log direct probe ==\n'
event_json='{"hook_event_name":"PostToolUse","tool_name":"Write","cwd":"'"$vault"'","tool_input":{"file_path":"'"$vault"'/atlas/people/jane-doe.md"}}'
printf '%s' "$event_json" | "$vault/_workdesk/scripts/post-tool-use-log.sh"
events_file="$vault/system/events/$(date +%Y-%m).md"
[[ -f "$events_file" ]] || { printf 'event log file missing: %s\n' "$events_file" >&2; exit 1; }
/usr/bin/grep -q 'object-created' "$events_file"

printf '== dirty vault refusal ==\n'
set +e
"$repo_root/bootstrap.sh" "$dirty" \
  >/tmp/workdesk-smoke-dirty.out 2>/tmp/workdesk-smoke-dirty.err
dirty_exit=$?
set -e
if [[ "$dirty_exit" -eq 0 ]]; then
  printf 'dirty vault bootstrap should have failed\n' >&2
  exit 1
fi
/usr/bin/grep -q 'only supports fresh installs' /tmp/workdesk-smoke-dirty.out /tmp/workdesk-smoke-dirty.err

printf 'smoke passed\n'
