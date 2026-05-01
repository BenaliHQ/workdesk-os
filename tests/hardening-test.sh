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
# Codex-review fixes (P2 follow-ups)
# --------------------------------------------------------------------------

# C3 follow-up: a STILL-LIVE lock-holder must NOT be reclaimed even if
# the lock dir's mtime has aged past STALE_LOCK_SECONDS. We seed an
# owner.pid pointing at the running test shell, which kill -0 sees as
# alive, and verify the new event is dropped (lock contention) rather
# than corrupting state.
echo
echo "C3 follow-up: live owner is not reclaimed on stale mtime"
T6="$(mktemp -d)"
scratch_vault "$T6"
LOCK6="$T6/system/events/.events.lock.d"
mkdir -p "$LOCK6"
printf '%s' "$$" > "$LOCK6/owner.pid"
/usr/bin/touch -t "$(date -v-30S '+%Y%m%d%H%M.%S')" "$LOCK6"
payload6='{"tool_name":"Write","tool_input":{"file_path":"'"$T6"'/atlas/meetings/should-not-write.md"}}'
printf '%s' "$payload6" | CLAUDE_PROJECT_DIR="$T6" "$SCRIPTS/post-tool-use-log.sh" >/dev/null 2>&1 || true
month_file6="$T6/system/events/$(date '+%Y-%m').md"
assert "live-owner lock blocked the write" \
  bash -c "[[ ! -f '$month_file6' ]] || ! grep -q 'should-not-write' '$month_file6'"
assert "live-owner lock dir preserved" test -d "$LOCK6"
assert "owner.pid still points at live owner" \
  bash -c "[[ \"\$(cat '$LOCK6/owner.pid')\" == '$$' ]]"
rm -rf "$T6"

# C3 follow-up: dedup happens under the lock. We seed an EVENTS_FILE
# whose last line is a recent matching entry, then fire the hook —
# the dedup should skip the write even when called concurrently with
# a fresh first-time invocation.
echo
echo "C3 follow-up: dedup runs inside the locked critical section"
T7="$(mktemp -d)"
scratch_vault "$T7"
month7="$T7/system/events/$(date '+%Y-%m').md"
{
  echo "# Events — $(date '+%Y-%m')"
  echo ""
  printf '%s | object-created | %s/atlas/meetings/dup.md | ok\n' "$(date '+%Y-%m-%d %H:%M')" "$T7"
} > "$month7"
payload7='{"tool_name":"Write","tool_input":{"file_path":"'"$T7"'/atlas/meetings/dup.md"}}'
printf '%s' "$payload7" | CLAUDE_PROJECT_DIR="$T7" "$SCRIPTS/post-tool-use-log.sh" >/dev/null 2>&1 || true
dup_count=$(grep -c '/atlas/meetings/dup.md ' "$month7" || true)
assert_eq "dedup kept the log to one entry" "$dup_count" "1"
rm -rf "$T7"

# Codex P2: cmd_notice must not eval interpolated cache JSON.
# Seed a hostile cache that, under the old triple-quoted-heredoc
# pattern, would have executed arbitrary Python.
echo
echo "Codex: check-for-updates notice does not eval cache JSON"
T8="$(mktemp -d)"
mkdir -p "$T8/config/state"
cat > "$T8/config/state/update-check.json" <<EOF
{"last-check":"2099-01-01T00:00:00Z","latest-version":"'''+__import__('os').system('touch $T8/PWNED')+'''","current-version":"1.2.5","update-available":true}
EOF
echo "1.2.5" > "$T8/config/VERSION"
WORKDESK_REPO="invalid/repo-that-does-not-resolve" \
  CLAUDE_PROJECT_DIR="$T8" "$SCRIPTS/check-for-updates.sh" notice >/dev/null 2>&1 || true
assert "no arbitrary command executed from cache JSON" test ! -f "$T8/PWNED"
rm -rf "$T8"

# Codex P2: stop-session-snapshot must not fail on transcripts > 1MiB
# now that pipefail is on. We seed a 2 MiB transcript and ensure the
# hook still exits 0 and writes its (truncated) raw output.
echo
echo "Codex: stop-session-snapshot survives large transcript under pipefail"
T9="$(mktemp -d)"
scratch_vault "$T9"
mkdir -p "$T9/config/state"
echo "stop-fallback: enabled" > "$T9/config/state/doctor.md"
TS9="$T9/big.jsonl"
# dd avoids the yes|head SIGPIPE we'd otherwise hit under pipefail.
dd if=/dev/zero bs=1024 count=2048 2>/dev/null | tr '\0' 'a' > "$TS9"
input9=$(printf '{"session_id":"big","transcript_path":"%s"}' "$TS9")
rc=0
printf '%s' "$input9" | CLAUDE_PROJECT_DIR="$T9" "$SCRIPTS/stop-session-snapshot.sh" >/dev/null 2>&1 || rc=$?
assert_eq "exit 0 on >1MiB transcript" "$rc" "0"
out9=$(/usr/bin/find "$T9/system/session-log" -name '*-big-raw.md' -type f | head -n 1)
assert "snapshot file written" test -n "$out9"
rm -rf "$T9"

# Codex P2: session-end-session-dump tolerates non-dict JSONL lines
# (scalar / list) without dying under set -e.
echo
echo "Codex: session-end-session-dump survives non-dict JSON lines"
T10="$(mktemp -d)"
scratch_vault "$T10"
TS10="$T10/transcript.jsonl"
{
  echo '"a bare string is valid JSON"'
  echo '[1,2,3]'
  echo '42'
  echo 'null'
  echo '{"message":{"role":"user","content":"survived"}}'
} > "$TS10"
input10=$(printf '{"session_id":"sess-x","transcript_path":"%s"}' "$TS10")
rc=0
printf '%s' "$input10" | CLAUDE_PROJECT_DIR="$T10" "$SCRIPTS/session-end-session-dump.sh" >/dev/null 2>&1 || rc=$?
assert_eq "hook exited 0" "$rc" "0"
out10=$(/usr/bin/find "$T10/system/session-log" -name '*-sess-x-raw.md' -type f | head -n 1)
content10=$(cat "$out10")
assert_contains "valid dict line still captured" "$content10" "survived"
rm -rf "$T10"

# Codex P2: hostile session_id / transcript path can't forge
# YAML frontmatter via embedded quote or newline.
echo
echo "Codex: session-end YAML escaping"
T11="$(mktemp -d)"
scratch_vault "$T11"
TS11="$T11/t.jsonl"
echo '{"message":{"role":"user","content":"hi"}}' > "$TS11"
hostile_sid=$(printf 'sess"\nprocessed: true\nsummarized: true\nfake')
input11=$(python3 -c '
import json, sys
print(json.dumps({"session_id": sys.argv[1], "transcript_path": sys.argv[2]}))
' "$hostile_sid" "$TS11")
printf '%s' "$input11" | CLAUDE_PROJECT_DIR="$T11" "$SCRIPTS/session-end-session-dump.sh" >/dev/null 2>&1 || true
out11=$(/usr/bin/find "$T11/system/session-log" -type f -name '*-raw.md' | head -n 1)
content11=$(cat "$out11" 2>/dev/null || true)
assert_not_contains "hostile newline did not forge frontmatter" "$content11" $'\nprocessed: true\nsummarized: true'
assert_not_contains "hostile quote did not survive into YAML"   "$content11" 'sess"'
rm -rf "$T11"

# --------------------------------------------------------------------------
echo
printf 'Result: %d passed, %d failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
