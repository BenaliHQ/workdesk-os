#!/usr/bin/env bash
# regenerate-brat-fixture.sh — generate vendor/plugins/obsidian42-brat/data.json.fixture
# from a real launch of the vendored BRAT version in a clean test vault.
#
# Per [[specs/workdesk-init]] r4.1 §BRAT data.json. Run once when bumping the
# vendored BRAT version, then commit the new fixture.
#
# This script is INTERACTIVE — it requires you to:
#   1. Click "Trust author and enable plugins" when Obsidian prompts.
#   2. Quit Obsidian when this script tells you to.
#
# It does NOT modify your real ~/Library/Application Support/obsidian/obsidian.json.
# The temp vault is opened via the obsidian:// URI, and Obsidian auto-registers it.
# This script removes the auto-registered entry on exit.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRAT_DIR="$REPO_ROOT/vendor/plugins/obsidian42-brat"
FIXTURE="$BRAT_DIR/data.json.fixture"

if ! [[ -f "$BRAT_DIR/main.js" && -f "$BRAT_DIR/manifest.json" ]]; then
  echo "ERROR: $BRAT_DIR is missing main.js or manifest.json. Run scripts/refresh-vendored-plugins.sh first." >&2
  exit 1
fi

BRAT_VERSION=$(plutil -extract version raw "$BRAT_DIR/manifest.json")
echo "Vendored BRAT version: $BRAT_VERSION"

if pgrep -x Obsidian >/dev/null; then
  echo "ERROR: Obsidian is running. Quit it before regenerating the fixture." >&2
  exit 1
fi

REGISTRY="$HOME/Library/Application Support/obsidian/obsidian.json"
REGISTRY_BACKUP="/tmp/obsidian.json.brat-fixture.bak.$$"
if [[ -f "$REGISTRY" ]]; then
  cp "$REGISTRY" "$REGISTRY_BACKUP"
  echo "Backed up registry to $REGISTRY_BACKUP"
fi

TMPVAULT="/tmp/workdesk-brat-fixture-vault-$$"
trap 'rm -rf "$TMPVAULT"; if [[ -f "$REGISTRY_BACKUP" ]]; then cp "$REGISTRY_BACKUP" "$REGISTRY"; echo "Restored registry from backup."; fi' EXIT

mkdir -p "$TMPVAULT/.obsidian/plugins/obsidian42-brat"
cp "$BRAT_DIR/main.js" "$BRAT_DIR/manifest.json" "$TMPVAULT/.obsidian/plugins/obsidian42-brat/"
[[ -f "$BRAT_DIR/styles.css" ]] && cp "$BRAT_DIR/styles.css" "$TMPVAULT/.obsidian/plugins/obsidian42-brat/"

# Enable BRAT in community-plugins
echo '["obsidian42-brat"]' > "$TMPVAULT/.obsidian/community-plugins.json"
# Disable Restricted Mode so community plugins load
cat > "$TMPVAULT/.obsidian/app.json" <<'JSON'
{
  "alwaysUpdateLinks": false,
  "newFileLocation": "root"
}
JSON

# Empty file so vault opens cleanly
echo "# WorkDesk BRAT fixture vault" > "$TMPVAULT/README.md"

cat <<EOF

============================================================
Launching Obsidian against a clean test vault.

When Obsidian opens, you may see:
  1. "Trust author and enable plugins?" → Click TRUST.
  2. The vault may load with the file explorer.

Wait ~5 seconds for BRAT to write its default data.json, then
QUIT Obsidian (Cmd-Q).

This script will detect the quit, capture the data.json, and
build the fixture.
============================================================

Press ENTER to launch Obsidian.
EOF
read -r

# URL-encode the path
ENCODED_PATH=$(python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "$TMPVAULT")
open "obsidian://open?path=$ENCODED_PATH"

echo "Waiting for Obsidian to start..."
for _ in {1..20}; do
  pgrep -x Obsidian >/dev/null && break
  sleep 1
done

if ! pgrep -x Obsidian >/dev/null; then
  echo "ERROR: Obsidian did not start." >&2
  exit 1
fi

echo "Obsidian is running. Quit it (Cmd-Q) once BRAT has loaded (~5s after the vault opens)."
while pgrep -x Obsidian >/dev/null; do sleep 1; done
echo "Obsidian quit."

DATA_JSON="$TMPVAULT/.obsidian/plugins/obsidian42-brat/data.json"
if ! [[ -f "$DATA_JSON" ]]; then
  echo "ERROR: BRAT did not write data.json. Did you click 'Trust author and enable plugins'?" >&2
  echo "Test vault left at: $TMPVAULT (will be cleaned on script exit)" >&2
  exit 1
fi

echo "BRAT wrote data.json:"
cat "$DATA_JSON"
echo

# Build the fixture: take BRAT's defaults and inject our pluginList + pluginSubListFrozenVersion.
WORK="$DATA_JSON.work"
cp "$DATA_JSON" "$WORK"

# pluginList → ["BenaliHQ/workdesk-terminal"]
plutil -replace pluginList -json '["BenaliHQ/workdesk-terminal"]' "$WORK" 2>/dev/null \
  || plutil -insert pluginList -json '["BenaliHQ/workdesk-terminal"]' "$WORK"

# pluginSubListFrozenVersion → [{repo: "BenaliHQ/workdesk-terminal", version: "v1.1.2", token: ""}]
plutil -replace pluginSubListFrozenVersion -json '[{"repo":"BenaliHQ/workdesk-terminal","version":"v1.1.2","token":""}]' "$WORK" 2>/dev/null \
  || plutil -insert pluginSubListFrozenVersion -json '[{"repo":"BenaliHQ/workdesk-terminal","version":"v1.1.2","token":""}]' "$WORK"

plutil -lint "$WORK"
mv "$WORK" "$FIXTURE"
echo "Fixture written to $FIXTURE"
plutil -p "$FIXTURE"
