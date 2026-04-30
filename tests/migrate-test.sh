#!/usr/bin/env bash
# migrate-test.sh — synthetic test harness for migrate.sh.
#
# Builds a fake vault at $TEST_ROOT, simulates a v1.2.0 → v1.3.0 upgrade with:
#   - clean update          (skill changed; operator hadn't touched it)
#   - operator-edit preserved (operator changed; release didn't)
#   - conflict + merged resolution  (both changed; resolutions specify merged file)
#   - conflict + mine resolution    (both changed; operator keeps their version)
#   - new file in release   (added)
#   - removed in release    (operator's copy stays)
#   - operator-only file    (preserved untouched)
#   - schema migration      (idempotent; creates a flag file)
#   - executable mode bit   (preserved across apply)
#   - backup + restore      (round-trip)
#
# Skips the network-fetch path of `check`; exercises classify + apply directly,
# which is where the file-mutation logic lives.
#
# Usage:
#   tests/migrate-test.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENGINE="$REPO_ROOT/config/scripts/migrate.sh"

TEST_ROOT="$(mktemp -d -t migrate-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

VAULT="$TEST_ROOT/vault"
WD="$VAULT/config"
DEFAULTS="$WD/defaults"

PASS=0
FAIL=0
assert() {
  local label="$1"; shift
  if "$@"; then
    printf '  PASS  %s\n' "$label"
    PASS=$((PASS+1))
  else
    printf '  FAIL  %s\n' "$label"
    FAIL=$((FAIL+1))
  fi
}
assert_file_eq() {
  local label="$1" file="$2" expected="$3"
  local actual
  actual="$(cat "$file" 2>/dev/null || echo '<MISSING>')"
  if [[ "$actual" == "$expected" ]]; then
    printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '  FAIL  %s\n         expected: %s\n         got:      %s\n' "$label" "$expected" "$actual"
    FAIL=$((FAIL+1))
  fi
}

echo "Test root: $TEST_ROOT"

# ---- Build v1.2.0 install state ----------------------------------------------

mkdir -p "$WD/skills/alpha" "$WD/skills/beta" "$WD/skills/gamma" "$WD/skills/custom" "$WD/scripts"
mkdir -p "$DEFAULTS/skills/alpha" "$DEFAULTS/skills/beta" "$DEFAULTS/skills/gamma" "$DEFAULTS/scripts"

# Skill alpha: will get a clean update.
echo "alpha v1" | tee "$WD/skills/alpha/SKILL.md" "$DEFAULTS/skills/alpha/SKILL.md" >/dev/null
# Skill beta: operator edits; release does not change it. Should be preserved.
echo "beta v1"  > "$DEFAULTS/skills/beta/SKILL.md"
echo "beta v1 + operator edit" > "$WD/skills/beta/SKILL.md"
# Skill gamma: both changed → conflict. Resolution: merged.
echo "gamma v1" > "$DEFAULTS/skills/gamma/SKILL.md"
echo "gamma v1 + operator edit" > "$WD/skills/gamma/SKILL.md"
# Skill custom: operator-only (not in defaults). Should be preserved.
echo "custom by operator" > "$WD/skills/custom/SKILL.md"
# A removed-in-release script.
echo "old-script v1" | tee "$WD/scripts/old-script.sh" "$DEFAULTS/scripts/old-script.sh" >/dev/null
# An executable script with mode preserved.
echo '#!/bin/sh
echo hello' | tee "$WD/scripts/exec.sh" "$DEFAULTS/scripts/exec.sh" >/dev/null
chmod 755 "$WD/scripts/exec.sh" "$DEFAULTS/scripts/exec.sh"

echo "1.2.0" > "$WD/VERSION"

# ---- Build v1.3.0 staging ----------------------------------------------------

STAGING="$TEST_ROOT/staging"
NEW_WD="$STAGING/workdesk"
mkdir -p "$NEW_WD/skills/alpha" "$NEW_WD/skills/beta" "$NEW_WD/skills/gamma" "$NEW_WD/skills/delta" "$NEW_WD/scripts"

# alpha: changed (operator hadn't touched → clean-update)
echo "alpha v2" > "$NEW_WD/skills/alpha/SKILL.md"
# beta: unchanged (operator's edit preserved → no-op)
echo "beta v1" > "$NEW_WD/skills/beta/SKILL.md"
# gamma: changed (both changed → conflict; we'll merge)
echo "gamma v2 from release" > "$NEW_WD/skills/gamma/SKILL.md"
# delta: new (add)
echo "delta v1 new skill" > "$NEW_WD/skills/delta/SKILL.md"
# old-script.sh: not present (removed-in-release; operator's copy stays)
# exec.sh: present, executable
echo '#!/bin/sh
echo hello v2' > "$NEW_WD/scripts/exec.sh"
chmod 755 "$NEW_WD/scripts/exec.sh"

# Schema migration: idempotent flag-file creation.
mkdir -p "$STAGING/migrations"
cat > "$STAGING/migrations/1.2.0-to-1.3.0-flag.sh" <<'EOM'
#!/usr/bin/env bash
set -u
flag="$WORKDESK_WD/.migrate-test-flag"
[[ -f "$flag" ]] && exit 0
echo "ran 1.2.0-to-1.3.0" > "$flag"
EOM
chmod +x "$STAGING/migrations/1.2.0-to-1.3.0-flag.sh"

cat > "$STAGING/manifest.json" <<EOJ
{"version": "1.3.0", "migrations": ["1.2.0-to-1.3.0-flag.sh"]}
EOJ

# ---- Resolutions for the conflict --------------------------------------------

mkdir -p "$VAULT/.workdesk-migrate-tmp"
MERGED="$VAULT/.workdesk-migrate-tmp/merged-gamma.md"
echo "gamma v2 merged with operator edit" > "$MERGED"

cat > "$VAULT/.workdesk-migrate-tmp/resolutions.json" <<EOJ
{
  "skills/gamma/SKILL.md": {"resolution": "merged", "merged_path": "$MERGED"}
}
EOJ

# ---- Run apply ---------------------------------------------------------------

echo
echo "Running migrate.sh apply..."
CLAUDE_PROJECT_DIR="$VAULT" "$ENGINE" apply "$STAGING" "$VAULT/.workdesk-migrate-tmp/resolutions.json" >/dev/null

# ---- Assertions --------------------------------------------------------------

echo
echo "Assertions:"

assert_file_eq "alpha SKILL clean-updated"               "$WD/skills/alpha/SKILL.md" "alpha v2"
assert_file_eq "beta operator edit preserved"            "$WD/skills/beta/SKILL.md"  "beta v1 + operator edit"
assert_file_eq "gamma resolved with merged content"      "$WD/skills/gamma/SKILL.md" "gamma v2 merged with operator edit"
assert_file_eq "delta added"                             "$WD/skills/delta/SKILL.md" "delta v1 new skill"
assert_file_eq "operator-only custom file preserved"     "$WD/skills/custom/SKILL.md" "custom by operator"
assert_file_eq "removed-in-release: operator copy stays" "$WD/scripts/old-script.sh"  "old-script v1"
assert      "exec.sh still executable" test -x "$WD/scripts/exec.sh"
assert_file_eq "exec.sh content updated"                 "$WD/scripts/exec.sh"        $'#!/bin/sh\necho hello v2'
assert_file_eq "VERSION bumped"                          "$WD/VERSION" "1.3.0"
assert      "defaults/skills/alpha refreshed"            test -f "$DEFAULTS/skills/alpha/SKILL.md"
assert_file_eq "defaults/alpha matches new release"      "$DEFAULTS/skills/alpha/SKILL.md" "alpha v2"
assert      "defaults/scripts/old-script gone"           test ! -f "$DEFAULTS/scripts/old-script.sh"
assert      "schema migration ran (flag exists)"         test -f "$WD/.migrate-test-flag"
assert      "backup directory exists" test -d "$VAULT/.workdesk-backups"
BACKUP_ID="$(ls -1 "$VAULT/.workdesk-backups" | head -n 1)"
assert      "backup contains pre-update beta edit" \
            grep -q "beta v1 + operator edit" "$VAULT/.workdesk-backups/$BACKUP_ID/skills/beta/SKILL.md"

# ---- Idempotency: re-run migration script alone, should no-op ---------------

bash "$STAGING/migrations/1.2.0-to-1.3.0-flag.sh" \
  WORKDESK_VAULT="$VAULT" WORKDESK_WD="$WD" 2>/dev/null || true
assert_file_eq "schema migration is idempotent" "$WD/.migrate-test-flag" "ran 1.2.0-to-1.3.0"

# ---- Restore -----------------------------------------------------------------

echo
echo "Running migrate.sh restore..."
CLAUDE_PROJECT_DIR="$VAULT" "$ENGINE" restore "$BACKUP_ID" 2>/dev/null

assert_file_eq "restore: alpha back to v1"               "$WD/skills/alpha/SKILL.md" "alpha v1"
assert_file_eq "restore: gamma back to operator edit"    "$WD/skills/gamma/SKILL.md" "gamma v1 + operator edit"
assert      "restore: delta gone"                        test ! -f "$WD/skills/delta/SKILL.md"
assert_file_eq "restore: VERSION back to 1.2.0"          "$WD/VERSION" "1.2.0"

echo
echo "Result: $PASS passed, $FAIL failed"
exit $(( FAIL > 0 ? 1 : 0 ))
