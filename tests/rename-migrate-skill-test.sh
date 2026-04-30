#!/usr/bin/env bash
# rename-migrate-skill-test.sh — verify the v1.2.2 → v1.2.3 migration that
# removes the legacy /migrate skill.
#
# Three scenarios:
#   1. Operator's /migrate skill matches defaults (unchanged) → cleanly removed.
#   2. Operator customized /migrate → archived to .legacy-skills/.
#   3. Already migrated (skill absent) → no-op exit 0.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/migrations/1.2.2-to-1.2.3-rename-migrate-to-update.sh"

PASS=0
FAIL=0
assert() {
  local label="$1"; shift
  if "$@"; then printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else printf '  FAIL  %s\n' "$label"; FAIL=$((FAIL+1))
  fi
}

# ---- Scenario 1: unchanged operator copy → clean removal --------------------

echo "Scenario 1: operator's /migrate skill matches defaults (unchanged)"
T1="$(mktemp -d)"
mkdir -p "$T1/skills/migrate" "$T1/defaults/skills/migrate"
echo "shipped content" | tee "$T1/skills/migrate/SKILL.md" "$T1/defaults/skills/migrate/SKILL.md" >/dev/null

WORKDESK_VAULT="$T1" WORKDESK_WD="$T1" bash "$SCRIPT" >/dev/null

assert "skills/migrate/SKILL.md removed"   test ! -f "$T1/skills/migrate/SKILL.md"
assert "skills/migrate/ dir removed"       test ! -d "$T1/skills/migrate"
assert "no archive directory created"      test ! -d "$T1/.legacy-skills"
assert "defaults/skills/migrate untouched" test -f "$T1/defaults/skills/migrate/SKILL.md"

rm -rf "$T1"

# ---- Scenario 2: operator customized → archived -----------------------------

echo
echo "Scenario 2: operator customized /migrate → archived"
T2="$(mktemp -d)"
mkdir -p "$T2/skills/migrate" "$T2/defaults/skills/migrate"
echo "shipped content" > "$T2/defaults/skills/migrate/SKILL.md"
echo "operator customized this" > "$T2/skills/migrate/SKILL.md"

WORKDESK_VAULT="$T2" WORKDESK_WD="$T2" bash "$SCRIPT" >/dev/null

assert "operator's skill removed from skills/migrate" test ! -f "$T2/skills/migrate/SKILL.md"
assert ".legacy-skills directory created"             test -d "$T2/.legacy-skills"
ARCHIVED="$(ls "$T2/.legacy-skills" 2>/dev/null | head -n 1 || true)"
assert "archive file present"                         test -n "$ARCHIVED"
assert "archive preserves operator content" \
       grep -q "operator customized this" "$T2/.legacy-skills/$ARCHIVED"

rm -rf "$T2"

# ---- Scenario 3: idempotency ------------------------------------------------

echo
echo "Scenario 3: idempotency — re-run on already-migrated state"
T3="$(mktemp -d)"
mkdir -p "$T3/defaults/skills/migrate"
echo "shipped" > "$T3/defaults/skills/migrate/SKILL.md"

WORKDESK_VAULT="$T3" WORKDESK_WD="$T3" bash "$SCRIPT" >/dev/null

assert "second run: no error, no changes"   test ! -d "$T3/.legacy-skills"
assert "second run: defaults still intact" test -f "$T3/defaults/skills/migrate/SKILL.md"

rm -rf "$T3"

# ---- Result -----------------------------------------------------------------

echo
echo "Result: $PASS passed, $FAIL failed"
exit $(( FAIL > 0 ? 1 : 0 ))
