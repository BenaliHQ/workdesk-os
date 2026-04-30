#!/usr/bin/env bash
# 1.2.2 → 1.2.3: skill renamed from /migrate to /update.
#
# The new skill is shipped as `config/skills/update/SKILL.md` (added by
# file-merge phase). The old `config/skills/migrate/SKILL.md` is no longer
# in the release, so file-merge classifies it as `removed-in-release` and
# leaves the operator's copy alone. This script cleans that copy up so the
# vault doesn't end up with two skills doing the same thing.
#
# If the operator customized their /migrate SKILL.md, we preserve their
# version at config/.legacy-skills/migrate-SKILL.md.<timestamp>.md so it's
# not silently lost.
#
# Idempotent: if migrate/ no longer exists, exit 0.
#
# Env (set by migrate.sh):
#   WORKDESK_VAULT — vault root
#   WORKDESK_WD    — control-plane directory ($VAULT/config in v1.2.1+)

set -u

WD="${WORKDESK_WD:?WORKDESK_WD not set}"

OLD_SKILL="$WD/skills/migrate/SKILL.md"
OLD_DIR="$WD/skills/migrate"
DEFAULTS_SKILL="$WD/defaults/skills/migrate/SKILL.md"

# Already migrated.
if [[ ! -f "$OLD_SKILL" && ! -d "$OLD_DIR" ]]; then
  echo "rename-migrate-to-update: legacy skill already removed."
  exit 0
fi

# If the operator's version differs from what shipped (i.e., they customized
# it), archive instead of delete. cmp returns 0 if identical.
if [[ -f "$OLD_SKILL" ]]; then
  if [[ -f "$DEFAULTS_SKILL" ]] && cmp -s "$OLD_SKILL" "$DEFAULTS_SKILL"; then
    rm -f "$OLD_SKILL"
    echo "rename-migrate-to-update: removed legacy /migrate skill (unchanged from defaults)."
  else
    mkdir -p "$WD/.legacy-skills"
    archive="$WD/.legacy-skills/migrate-SKILL.$(date '+%Y-%m-%d-%H%M%S').md"
    mv "$OLD_SKILL" "$archive"
    echo "rename-migrate-to-update: operator-customized /migrate skill archived to $archive."
  fi
fi

# Remove the now-empty directory if it exists.
if [[ -d "$OLD_DIR" ]]; then
  rmdir "$OLD_DIR" 2>/dev/null || {
    echo "rename-migrate-to-update: $OLD_DIR has remaining files; leaving in place." >&2
  }
fi
