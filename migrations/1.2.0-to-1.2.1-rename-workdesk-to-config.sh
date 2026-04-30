#!/usr/bin/env bash
# 1.2.0 → 1.2.1: rename the control-plane directory from `_workdesk/` to `config/`.
#
# Runs during /migrate apply, between file-merge and finalize. The trick: the
# v1.2.0 migrate.sh that invokes us has hardcoded `_workdesk/` as $WD and
# $DEFAULTS, so we cannot simply move the directory and walk away — finalize
# would then fail to mv $WD/defaults into place. We solve this by leaving a
# legacy symlink `_workdesk -> config` so the in-flight finalize resolves
# through it. A future migration may remove the symlink once we're confident
# nothing else relies on the old path.
#
# Idempotent: if `_workdesk` is already a symlink (we've run before) or if
# `config` already exists, this is a no-op.
#
# Env (set by migrate.sh):
#   WORKDESK_VAULT — vault root
#   WORKDESK_WD    — control-plane directory (still $VAULT/_workdesk on v1.2.0)

set -u

VAULT="${WORKDESK_VAULT:?WORKDESK_VAULT not set}"

OLD="$VAULT/_workdesk"
NEW="$VAULT/config"

# Already migrated — nothing to do.
if [[ -L "$OLD" ]]; then
  echo "rename-workdesk-to-config: already migrated (legacy symlink present)."
  exit 0
fi

# config/ already exists as a real directory and _workdesk doesn't — also a
# no-op (someone fresh-installed v1.2.1+ and is somehow running this anyway).
if [[ -d "$NEW" && ! -d "$OLD" ]]; then
  echo "rename-workdesk-to-config: config/ already in place; nothing to rename."
  exit 0
fi

# Refuse to overwrite an existing config/ that's not ours.
if [[ -e "$NEW" ]]; then
  echo "rename-workdesk-to-config: $NEW already exists. Aborting to avoid clobbering operator data." >&2
  exit 1
fi

# The actual rename.
mv "$OLD" "$NEW"

# Legacy symlink so the calling v1.2.0 migrate.sh finalize step still resolves.
( cd "$VAULT" && ln -sfn config _workdesk )

# Retarget .claude symlink (which was pointing to _workdesk → now needs to
# point to config directly so it doesn't double-hop).
if [[ -L "$VAULT/.claude" ]]; then
  ( cd "$VAULT" && ln -sfn config .claude )
fi

echo "rename-workdesk-to-config: moved $OLD → $NEW; legacy symlink in place; .claude retargeted."
