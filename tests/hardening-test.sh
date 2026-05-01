#!/usr/bin/env bash
# hardening-test.sh — exercise the v1.2.6 hardening fixes.
#
# Covers:
#   - C2: settings.json hook commands work when $CLAUDE_PROJECT_DIR has spaces
#   - C4: post-tool-use-log.sh sanitizes hostile file_path before logging
#   - C3: post-tool-use-log.sh's lock is trap-cleaned and stale-lock-aware
#   - M3: session-end-session-dump.sh tolerates malformed JSONL transcripts
#   - M4: bench-hooks.sh writes only to its scratch dir
#   - M2: every config/scripts/*.sh sets `set -euo pipefail`
#
# Each scenario uses an isolated mktemp dir; nothing touches the real vault.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/config/scripts"

PASS=0; FAIL=0
assert() {
  local label="$1"; shift
  if "$@"; then printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else printf '  FAIL  %s\n' "$label"; FAIL=$((FAIL+1))
  fi
}
assert_eq()       { local lbl="$1" got="$2" want="$3"; if [[ "$got" == "$want" ]]; then printf '  PASS  %s\n' "$lbl"; PASS=$((PASS+1)); else printf '  FAIL  %s\n         got:  %q\n         want: %q\n' "$lbl" "$got" "$want"; FAIL=$((FAIL+1)); fi; }
assert_contains() { local lbl="$1" hay="$2" needle="$3"; if [[ "$hay" == *"$needle"* ]]; then printf '  PASS  %s\n' "$lbl"; PASS=$((PASS+1)); else printf '  FAIL  %s\n         needle: %q\n         haystack: %q\n' "$lbl" "$needle" "$hay"; FAIL=$((FAIL+1)); fi; }
assert_not_contains() { local lbl="$1" hay="$2" needle="$3"; if [[ "$hay" != *"$needle"* ]]; then printf '  PASS  %s\n' "$lbl"; PASS=$((PASS+1)); else printf '  FAIL  %s (contained %q)\n' "$lbl" "$needle"; FAIL=$((FAIL+1)); fi; }

scratch_vault() {
  local d="$1"
  mkdir -p "$d/system/events" "$d/config" "$d/atlas/meetings"
}

# --------------------------------------------------------------------------
# M2: every hook script declares the strict shell options.
# --------------------------------------------------------------------------
echo "M2: strict-mode declarations across config/scripts/"
for f in "$SCRIPTS"/*.sh; do
  name="$(basename "$f")"
  assert "$name has set -euo pipefail" grep -q '^set -euo pipefail' "$f"
  assert "$name has IFS reset"          grep -q "^IFS=\$'\\\\n\\\\t'" "$f"
done

# --------------------------------------------------------------------------
# C2: hook scripts work under a vault path containing spaces.
# --------------------------------------------------------------------------
echo
echo "C2: vault paths with spaces"
T1="$(mktemp -d)/Vault With Spaces"
scratch_vault "$T1"
payload='{"tool_name":"Write","tool_input":{"file_path":"'"$T1"'/atlas/meetings/2026-04-30-test.md"}}'
printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$T1" "$SCRIPTS/post-tool-use-log.sh" >/dev/null 2>&1 || true
assert "post-tool-use-log writes a monthly events file under spaced path" \
  test -f "$T1/system/events/$(date '+%Y-%m').md"
month_file="$T1/system/events/$(date '+%Y-%m').md"
assert_contains "logged event mentions the path" "$(cat "$month_file")" "atlas/meetings/2026-04-30-test.md"
rm -rf "$(dirname "$T1")"

# --------------------------------------------------------------------------
# C4: hostile file_path is stripped of control chars and field delimiter
# --------------------------------------------------------------------------
echo
echo "C4: log injection sanitization"
T2="$(mktemp -d)"
scratch_vault "$T2"
# Build a payload whose file_path contains real BEL + real newline +
# pipe characters. We use printf with $'...' to inject the bytes
# directly, so the bash regex in post-tool-use-log.sh captures them
# verbatim — exactly the case sanitization must defend against.
hostile_path=$(printf '%s/atlas/meetings/safe\007name|with|pipes\nfake-event.md' "$T2")
payload2=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$hostile_path")
printf '%s' "$payload2" | CLAUDE_PROJECT_DIR="$T2" "$SCRIPTS/post-tool-use-log.sh" >/dev/null 2>&1 || true
month_file2="$T2/system/events/$(date '+%Y-%m').md"
content2=$(cat "$month_file2")
# Sanitization must drop the BEL, drop the raw newline, and replace `|`.
assert_not_contains "no BEL char in log"             "$content2" $'\007'
assert_not_contains "no raw newline forged a row"    "$content2" $'\nfake-event'
assert_not_contains "no | character in target field" "$content2" "name|with|pipes"
assert_contains    "pipes replaced with underscore"  "$content2" "name_with_pipes"
# Exactly one event line should have been written.
event_lines=$(grep -c '| ok$' "$month_file2" || true)
assert_eq "exactly one log line written" "$event_lines" "1"
rm -rf "$T2"

# --------------------------------------------------------------------------
# C3: stale lock (mtime > 5s) is reclaimed; lock is cleaned by trap.
# --------------------------------------------------------------------------
echo
echo "C3: stale-lock reclamation and trap cleanup"
T3="$(mktemp -d)"
scratch_vault "$T3"
LOCK="$T3/system/events/.events.lock.d"
mkdir -p "$LOCK"
# Make the lock 6 seconds old.
touch -A -000006 "$LOCK" 2>/dev/null || /usr/bin/touch -t "$(date -v-10S '+%Y%m%d%H%M.%S')" "$LOCK"
payload3='{"tool_name":"Write","tool_input":{"file_path":"'"$T3"'/atlas/meetings/stale-lock.md"}}'
printf '%s' "$payload3" | CLAUDE_PROJECT_DIR="$T3" "$SCRIPTS/post-tool-use-log.sh" >/dev/null 2>&1 || true
assert "stale lock was reclaimed and entry written" test -f "$T3/system/events/$(date '+%Y-%m').md"
assert "lock dir cleaned up by trap"                 test ! -d "$LOCK"
rm -rf "$T3"

# --------------------------------------------------------------------------
# M3: session-end-session-dump.sh ignores malformed JSONL lines.
# --------------------------------------------------------------------------
echo
echo "M3: hostile JSONL transcript handling"
T4="$(mktemp -d)"
scratch_vault "$T4"
TS="$T4/transcript.jsonl"
{
  echo '{"message":{"role":"user","content":"hello world"}}'
  echo 'this is not json at all'
  echo '{"message":{"role":"assistant","content":[{"type":"text","text":"hi back"}]}}'
  echo '{"message":{"role":"user","content":[]}}'
  echo '{"role":"assistant","content":"legacy flat shape"}'
} > "$TS"

input4=$(printf '{"session_id":"sess-1","transcript_path":"%s"}' "$TS")
printf '%s' "$input4" | CLAUDE_PROJECT_DIR="$T4" "$SCRIPTS/session-end-session-dump.sh" >/dev/null 2>&1 || true
out_file=$(/usr/bin/find "$T4/system/session-log" -name '*-sess-1-raw.md' -type f | head -n 1)
assert "session log was written" test -n "$out_file"
content4=$(cat "$out_file")
assert_contains "user message captured"      "$content4" "hello world"
assert_contains "assistant block captured"   "$content4" "hi back"
assert_contains "legacy flat shape captured" "$content4" "legacy flat shape"
assert_not_contains "malformed line not in output" "$content4" "this is not json at all"
rm -rf "$T4"

# --------------------------------------------------------------------------
# M4: bench-hooks.sh writes nothing to the supplied CLAUDE_PROJECT_DIR.
# --------------------------------------------------------------------------
echo
echo "M4: bench-hooks isolation"
T5="$(mktemp -d)"
scratch_vault "$T5"
# Pre-create a baseline file we can compare.
echo "baseline" > "$T5/system/events/baseline.md"
# Run bench against this dir; it must NOT add anything to system/events/.
CLAUDE_PROJECT_DIR="$T5" "$SCRIPTS/bench-hooks.sh" >/dev/null 2>&1 || true
events_after=$(/usr/bin/find "$T5/system/events" -type f | LC_ALL=C sort)
assert_eq "only baseline file remains in real events dir" \
  "$events_after" "$T5/system/events/baseline.md"
rm -rf "$T5"

# --------------------------------------------------------------------------
echo
printf 'Result: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
