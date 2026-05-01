#!/usr/bin/env bash
# json-get.sh — extract a single field from JSON on stdin.
#
# Avoids requiring jq. Tries plutil (macOS native) first, falls back to a
# best-effort sed/awk parser for shallow string fields.
#
# Usage:  echo "$json" | json-get.sh fieldname
#         json-get.sh fieldname < file.json
#
# Field paths are dot-separated, e.g. "tool_input.file_path".
# Returns empty string if the field is missing or extraction fails.

set -euo pipefail
IFS=$'\n\t'

field="${1:-}"
[[ -z "$field" ]] && { echo ""; exit 0; }

input="$(cat)"
[[ -z "$input" ]] && { echo ""; exit 0; }

if [[ -x /usr/bin/plutil ]]; then
  # plutil -extract takes a key path with dots and reads from stdin via -.
  out=$(/usr/bin/plutil -extract "$field" raw -o - - <<<"$input" 2>/dev/null || true)
  if [[ -n "$out" ]]; then
    printf '%s' "$out"
    exit 0
  fi
fi

# Fallback: shallow parse for top-level string fields only.
leaf="${field##*.}"
printf '%s' "$input" \
  | /usr/bin/awk -v k="$leaf" '
      BEGIN { RS=","; }
      {
        if (match($0, "\"" k "\"[[:space:]]*:[[:space:]]*\"[^\"]*\"")) {
          v = substr($0, RSTART, RLENGTH)
          sub(".*: *\"", "", v)
          sub("\"$", "", v)
          print v
          exit
        }
      }
    '
