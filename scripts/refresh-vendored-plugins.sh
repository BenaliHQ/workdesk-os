#!/usr/bin/env bash
# refresh-vendored-plugins.sh — re-pull pinned upstream plugin artifacts and
# recompute SHA256s into each plugin's UPSTREAM.md.
#
# Usage:
#   scripts/refresh-vendored-plugins.sh                 # re-pull all 7 at current pins
#   scripts/refresh-vendored-plugins.sh <plugin-id> <tag>  # bump one plugin to a new tag
#
# After running, manually update Tag pinned / Release URL / Retrieved /
# Manifest version / minAppVersion fields in the affected UPSTREAM.md files
# and bump the workdesk-os tag if the install contract changed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR_ROOT="$REPO_ROOT/vendor/plugins"

# id repo tag artifacts...
PLUGINS=(
  "templater-obsidian|SilentVoid13/Templater|2.19.3|main.js manifest.json styles.css"
  "obsidian-minimal-settings|kepano/obsidian-minimal-settings|8.2.2|main.js manifest.json styles.css"
  "custom-sort|SebastianMC/obsidian-custom-sort|3.1.6|main.js manifest.json"
  "calendar|liamcain/obsidian-calendar-plugin|1.5.10|main.js manifest.json"
  "periodic-notes|liamcain/obsidian-periodic-notes|0.0.17|main.js manifest.json styles.css"
  "obsidian42-brat|TfTHacker/obsidian42-brat|2.0.4|main.js manifest.json styles.css"
  "workdesk-terminal|BenaliHQ/workdesk-terminal|v1.1.2|main.js manifest.json styles.css"
)

refresh_one() {
  local id="$1" repo="$2" tag="$3" assets="$4"
  local dir="$VENDOR_ROOT/$id"
  echo "==> $id ($repo @ $tag)"
  mkdir -p "$dir"
  for asset in $assets; do
    curl -fsSL "https://github.com/$repo/releases/download/$tag/$asset" -o "$dir/$asset"
    local sha
    sha=$(shasum -a 256 "$dir/$asset" | awk '{print $1}')
    echo "    $asset  $sha"
  done
  echo "    ↪ Update SHA256 table + Tag/Release/Retrieved/Manifest fields in $dir/UPSTREAM.md"
}

if [[ $# -eq 2 ]]; then
  TARGET_ID="$1"; TARGET_TAG="$2"
  for entry in "${PLUGINS[@]}"; do
    IFS='|' read -r id repo tag assets <<<"$entry"
    if [[ "$id" == "$TARGET_ID" ]]; then
      refresh_one "$id" "$repo" "$TARGET_TAG" "$assets"
      exit 0
    fi
  done
  echo "Unknown plugin id: $TARGET_ID" >&2
  exit 1
fi

for entry in "${PLUGINS[@]}"; do
  IFS='|' read -r id repo tag assets <<<"$entry"
  refresh_one "$id" "$repo" "$tag" "$assets"
done

echo
echo "Done. Review diffs, update UPSTREAM.md SHA tables, commit."
