#!/usr/bin/env bash
# rename-migration-test.sh — verify the v1.2.0 → v1.2.1 rename migration.
#
# Three scenarios:
#   1. Real _workdesk/ + .claude symlink → migration moves to config/, leaves
#      legacy _workdesk → config symlink, retargets .claude.
#   2. Re-run on already-migrated state → no-op exit 0.
#   3. config/ already exists with different content + _workdesk also present
#      → migration refuses, exits 1, leaves both untouched.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/migrations/1.2.0-to-1.2.1-rename-workdesk-to-config.sh"

PASS=0
FAIL=0
assert() {
  local label="$1"; shift
  if "$@"; then printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else printf '  FAIL  %s\n' "$label"; FAIL=$((FAIL+1))
  fi
}

# ---- Scenario 1: clean migration ---------------------------------------------

echo "Scenario 1: clean migration"
T1="$(mktemp -d)"
mkdir -p "$T1/_workdesk/skills/alpha" "$T1/_workdesk/scripts"
echo "alpha content" > "$T1/_workdesk/skills/alpha/SKILL.md"
( cd "$T1" && ln -s _workdesk .claude )

WORKDESK_VAULT="$T1" bash "$SCRIPT" >/dev/null

assert "config/ exists as real dir"        test -d "$T1/config" -a ! -L "$T1/config"
assert "_workdesk is now a symlink"        test -L "$T1/_workdesk"
assert "_workdesk symlink points to config" test "$(readlink "$T1/_workdesk")" = "config"
assert "config/skills/alpha/SKILL.md preserved" \
       grep -q "alpha content" "$T1/config/skills/alpha/SKILL.md"
assert ".claude retargeted to config"      test "$(readlink "$T1/.claude")" = "config"
assert "_workdesk path still resolves (via symlink)" \
       grep -q "alpha content" "$T1/_workdesk/skills/alpha/SKILL.md"

rm -rf "$T1"

# ---- Scenario 2: re-run on already-migrated state ----------------------------

echo
echo "Scenario 2: idempotency"
T2="$(mktemp -d)"
mkdir -p "$T2/config/skills/alpha"
echo "alpha content" > "$T2/config/skills/alpha/SKILL.md"
( cd "$T2" && ln -s config _workdesk )

WORKDESK_VAULT="$T2" bash "$SCRIPT" >/dev/null

assert "second run: config/ unchanged"  test -d "$T2/config" -a ! -L "$T2/config"
assert "second run: _workdesk still symlink" test -L "$T2/_workdesk"
assert "second run: content preserved"  grep -q "alpha content" "$T2/config/skills/alpha/SKILL.md"

rm -rf "$T2"

# ---- Scenario 3: refuse to clobber unrelated config/ ------------------------

echo
echo "Scenario 3: refuse to clobber"
T3="$(mktemp -d)"
mkdir -p "$T3/_workdesk/old"
mkdir -p "$T3/config/unrelated"
echo "old data" > "$T3/_workdesk/old/file.md"
echo "unrelated data" > "$T3/config/unrelated/file.md"

set +e
WORKDESK_VAULT="$T3" bash "$SCRIPT" 2>/dev/null
RC=$?
set -e

assert "exits non-zero when config/ already exists" test "$RC" -ne 0
assert "_workdesk preserved on refusal"       grep -q "old data" "$T3/_workdesk/old/file.md"
assert "config/ preserved on refusal"         grep -q "unrelated data" "$T3/config/unrelated/file.md"
assert "no symlink created"                   test ! -L "$T3/_workdesk"

rm -rf "$T3"

# ---- Result -----------------------------------------------------------------

echo
echo "Result: $PASS passed, $FAIL failed"
exit $(( FAIL > 0 ? 1 : 0 ))
