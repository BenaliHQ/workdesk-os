#!/usr/bin/env bash
# obsidian-defaults-paths.sh — verify every path referenced inside
# config/obsidian-defaults/*.json resolves to a real file or directory
# in the shipped tarball.
#
# Catches the v1.2.8 class of bug: canonical .obsidian/ config pointing
# at a template path that bootstrap doesn't actually create.
#
# Approach:
#   1. Run scripts/release.sh --dry-run to build the tarball into dist/.
#   2. Extract the tarball to a tmp dir.
#   3. Walk every JSON under extracted/workdesk/obsidian-defaults/.
#   4. For each `template` (file) and `templates_folder` (dir) field —
#      including nested folder_templates[].template — assert the path
#      resolves under extracted/workdesk/.
#   5. Exit non-zero if any path is broken.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

WORK="$(mktemp -d -t obsidian-paths.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

printf '== building tarball (dry-run) ==\n'
scripts/release.sh --dry-run >/dev/null

VERSION="$(head -n 1 config/VERSION | tr -d '[:space:]')"
TARBALL="dist/workdesk-os-${VERSION}.tar.gz"
[[ -f "$TARBALL" ]] || { printf 'tarball missing: %s\n' "$TARBALL" >&2; exit 1; }

printf '== extracting %s ==\n' "$TARBALL"
mkdir -p "$WORK/extracted"
tar -xzf "$TARBALL" -C "$WORK/extracted"

WORKDESK="$WORK/extracted/workdesk"
DEFAULTS="$WORKDESK/obsidian-defaults"

if [[ ! -d "$DEFAULTS" ]]; then
  printf 'obsidian-defaults/ missing from tarball — nothing to validate\n' >&2
  printf 'NOTE: this is a fail. If you intentionally removed obsidian-defaults, delete this test too.\n' >&2
  exit 1
fi

printf '== validating paths ==\n'

FAIL=0

# Resolve a path declared inside obsidian-defaults to its post-apply location.
#
# Paths in obsidian-defaults JSON are relative to the operator's vault root.
# After `/update`, files from the tarball's workdesk/ tree land at
# <vault>/config/. So a declared path of "config/templates/daily-note.md"
# resolves to <tarball>/workdesk/templates/daily-note.md (strip the
# leading "config/").
#
# Policy: every path in obsidian-defaults MUST start with "config/". The
# canonical config ships shipped files; pointing at operator zones
# (personal/, atlas/, etc.) means we're referencing something the
# operator is supposed to own and create — which downstream operators
# won't have. v1.2.8 shipped with `intel/reference/templates/...`,
# leaked from operator-specific customization, and broke every install.
resolve_path() {
  local rel="$1"
  if [[ "$rel" == config/* ]]; then
    echo "$WORKDESK/${rel#config/}"
  else
    echo "OUTSIDE_CONFIG"
  fi
}

check_file() {
  local field="$1" rel="$2" json_path="$3"
  if [[ -z "$rel" || "$rel" == "null" ]]; then return 0; fi
  local resolved
  resolved="$(resolve_path "$rel")"
  if [[ "$resolved" == "OUTSIDE_CONFIG" ]]; then
    printf '  FAIL  %s -> %s (path must start with config/)\n         declared in: %s\n' \
      "$field" "$rel" "$json_path" >&2
    FAIL=$((FAIL+1))
    return 0
  fi
  if [[ ! -f "$resolved" ]]; then
    printf '  FAIL  %s -> %s (file)\n         declared in: %s\n         resolved to: %s\n' \
      "$field" "$rel" "$json_path" "$resolved" >&2
    FAIL=$((FAIL+1))
  else
    printf '  PASS  %s -> %s (file)\n' "$field" "$rel"
  fi
}

check_dir() {
  local field="$1" rel="$2" json_path="$3"
  if [[ -z "$rel" || "$rel" == "null" ]]; then return 0; fi
  local resolved
  resolved="$(resolve_path "$rel")"
  if [[ "$resolved" == "OUTSIDE_CONFIG" ]]; then
    printf '  FAIL  %s -> %s (path must start with config/)\n         declared in: %s\n' \
      "$field" "$rel" "$json_path" >&2
    FAIL=$((FAIL+1))
    return 0
  fi
  if [[ ! -d "$resolved" ]]; then
    printf '  FAIL  %s -> %s (dir)\n         declared in: %s\n         resolved to: %s\n' \
      "$field" "$rel" "$json_path" "$resolved" >&2
    FAIL=$((FAIL+1))
  else
    printf '  PASS  %s -> %s (dir)\n' "$field" "$rel"
  fi
}

while IFS= read -r json; do
  rel_json="${json#$DEFAULTS/}"
  printf '  scanning obsidian-defaults/%s\n' "$rel_json"

  # Pull paths via python (reliable JSON parsing).
  while IFS=$'\t' read -r kind value; do
    case "$kind" in
      template)         check_file "template"         "$value" "$rel_json" ;;
      templates_folder) check_dir  "templates_folder" "$value" "$rel_json" ;;
      folder_template)  check_file "folder_templates[].template" "$value" "$rel_json" ;;
    esac
  done < <(python3 -c "
import json, sys
d = json.load(open('$json'))
for k in ('template', 'templates_folder'):
    v = d.get(k)
    if isinstance(v, str):
        print(f'{k}\t{v}')
for ft in d.get('folder_templates', []) or []:
    t = ft.get('template') if isinstance(ft, dict) else None
    if isinstance(t, str):
        print(f'folder_template\t{t}')
")
done < <(find "$DEFAULTS" -type f -name '*.json')

if (( FAIL > 0 )); then
  printf '\n%d broken path(s). Fix obsidian-defaults JSON or ensure the referenced file ships.\n' "$FAIL" >&2
  exit 1
fi

printf '\nall obsidian-defaults paths resolve\n'
