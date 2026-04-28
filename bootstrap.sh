#!/usr/bin/env bash
# WorkDesk OS bootstrap — V1
#
# Mac-only. Greenfield (empty vault) only. No mandatory third-party
# integrations. Filesystem-only — runtime checks happen via /workdesk-doctor
# in the first Claude Code session after install.
#
# Usage:
#   ./bootstrap.sh /path/to/empty-vault
#   ./bootstrap.sh --dry-run /path/to/empty-vault

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift
fi

# ============================================================================
# helpers
# ============================================================================

c_red()    { printf "\033[31m%s\033[0m" "$*"; }
c_green()  { printf "\033[32m%s\033[0m" "$*"; }
c_yellow() { printf "\033[33m%s\033[0m" "$*"; }
c_dim()    { printf "\033[2m%s\033[0m" "$*"; }

step()  { echo ""; echo "$(c_green "==>") $1"; }
note()  { echo "    $(c_dim "$1")"; }
warn()  { echo "    $(c_yellow "warn:") $1"; }
fail()  { echo "    $(c_red "error:") $1"; exit 1; }

# ============================================================================
# 1. preflight — verify macOS
# ============================================================================

step "WorkDesk OS bootstrap"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo ""
  echo "    WorkDesk OS V1 is Mac-only."
  echo "    Linux probably works (similar Unix) but isn't officially supported."
  echo "    Windows users — V2 will support Windows. See README for status."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_WD="$SCRIPT_DIR/_workdesk"
[[ -d "$SOURCE_WD" ]] || fail "_workdesk/ not found at $SOURCE_WD"

# ============================================================================
# 2. verify target vault is empty per the allow-list
# ============================================================================

TARGET="${1:-}"
[[ -z "$TARGET" ]] && fail "usage: ./bootstrap.sh /path/to/empty-vault"
TARGET="${TARGET/#\~/$HOME}"

step "Verifying target vault is empty"
note "Target: $TARGET"

if [[ ! -d "$TARGET" ]]; then
  if (( DRY_RUN )); then
    note "Target does not exist — would create."
  else
    note "Target does not exist — creating."
    mkdir -p "$TARGET" || fail "could not create $TARGET"
  fi
fi

# Allow-list: .obsidian/, .DS_Store, .git/, .gitignore, single empty README.md
shopt -s dotglob nullglob
allowed=("$TARGET/.obsidian" "$TARGET/.DS_Store" "$TARGET/.git" "$TARGET/.gitignore" "$TARGET/README.md")

for entry in "$TARGET"/*; do
  name="$(basename "$entry")"
  case "$name" in
    .obsidian|.DS_Store|.git|.gitignore) continue ;;
    README.md)
      # Only OK if empty
      if [[ -s "$entry" ]]; then
        echo ""
        echo "    This vault has existing content (README.md is non-empty)."
        echo "    WorkDesk OS V1 only supports fresh installs."
        echo "    Options: start a new vault, or wait for V2 migration."
        exit 1
      fi
      continue
      ;;
    *)
      echo ""
      echo "    This vault has existing content: $name"
      echo "    WorkDesk OS V1 only supports fresh installs."
      echo "    Options: start a new vault, or wait for V2 migration."
      exit 1
      ;;
  esac
done
shopt -u dotglob nullglob

note "Vault is empty — proceeding."

# ============================================================================
# 3. runtime dependency contract
# ============================================================================

step "Verifying macOS-provided runtime dependencies"

required=(
  /bin/bash /usr/bin/plutil /usr/bin/stat /bin/mkdir /bin/ln /bin/chmod
  /usr/bin/find /usr/bin/sed /usr/bin/awk
)
for t in "${required[@]}"; do
  [[ -x "$t" ]] || fail "missing required tool: $t"
done

if [[ -x /usr/bin/shlock ]]; then
  note "shlock: present"
else
  note "shlock: absent (will use atomic mkdir locking)"
fi

note "All required tools present."

# ============================================================================
# Dry-run exit: preflight passed, preview the install and stop.
# ============================================================================

if (( DRY_RUN )); then
  step "Dry run — would install:"
  note "Five-zone skeleton: personal/ atlas/ gtd/ intel/ system/"
  note "_workdesk/ control plane (skills, rules, declarations, scripts)"
  note "_workdesk/defaults/ V1 baseline snapshot (for V2 3-way merge)"
  note ".claude → _workdesk/ symlink"
  note "gtd/inbox/$(date '+%Y-%m-%d')-welcome.md"
  note "system/events/$(date '+%Y-%m').md (bootstrap-install-completed)"
  note "_workdesk/state/signals.json (vault-improvements suppressed 14 days)"
  echo ""
  echo "    $(c_green "✓") Dry run complete — no changes made."
  echo "    Re-run without --dry-run to install."
  exit 0
fi

# ============================================================================
# 4. create five-zone folder skeleton
# ============================================================================

step "Creating five-zone folder skeleton"

mkdir -p \
  "$TARGET/personal/daily" \
  "$TARGET/atlas/meetings" \
  "$TARGET/atlas/decisions" \
  "$TARGET/atlas/people" \
  "$TARGET/atlas/initiatives" \
  "$TARGET/atlas/areas" \
  "$TARGET/gtd/inbox" \
  "$TARGET/gtd/actions/next" \
  "$TARGET/gtd/actions/waiting" \
  "$TARGET/gtd/projects" \
  "$TARGET/gtd/recurring/schedules" \
  "$TARGET/gtd/recurring/checklists" \
  "$TARGET/gtd/someday/actions" \
  "$TARGET/gtd/someday/projects" \
  "$TARGET/gtd/archive/projects" \
  "$TARGET/gtd/archive/actions" \
  "$TARGET/intel/briefings/daily" \
  "$TARGET/intel/briefings/weekly" \
  "$TARGET/intel/vault-improvements" \
  "$TARGET/intel/research" \
  "$TARGET/intel/observations" \
  "$TARGET/system/intake" \
  "$TARGET/system/transcripts" \
  "$TARGET/system/session-log" \
  "$TARGET/system/events" \
  "$TARGET/system/media"

note "Five zones in place: personal/ atlas/ gtd/ intel/ system/"

# ============================================================================
# 5. create _workdesk/ structure (real directory) + copy artifacts
# ============================================================================

step "Installing _workdesk/ control plane"

mkdir -p "$TARGET/_workdesk"
rsync -a "$SOURCE_WD/" "$TARGET/_workdesk/"

# Snapshot the V1 baseline so V2 update can 3-way merge.
mkdir -p "$TARGET/_workdesk/defaults"
rsync -a --delete \
  --exclude=defaults \
  --exclude=snapshots \
  --exclude=state \
  "$SOURCE_WD/" "$TARGET/_workdesk/defaults/"

mkdir -p "$TARGET/_workdesk/snapshots"

# Fix permissions on hook scripts.
chmod +x "$TARGET/_workdesk/scripts/"*.sh 2>/dev/null || warn "chmod on hook scripts failed"

note "_workdesk/ installed (skills, rules, declarations, scripts, defaults)"

# ============================================================================
# 6. .claude symlink → _workdesk
# ============================================================================

step "Creating .claude symlink"

cd "$TARGET"
if [[ -e .claude && ! -L .claude ]]; then
  fail ".claude exists and is not a symlink — refusing to overwrite"
fi
[[ -L .claude ]] && rm .claude
ln -s _workdesk .claude
note ".claude → _workdesk/"
cd - >/dev/null

# ============================================================================
# 7. seed welcome inbox item
# ============================================================================

step "Seeding welcome inbox item"

WELCOME="$TARGET/gtd/inbox/$(date '+%Y-%m-%d')-welcome.md"
cat > "$WELCOME" <<EOF
---
type: inbox-item
prefix: REVIEW
target: ""
source: "bootstrap"
created: $(date '+%Y-%m-%d')
---

Welcome to WorkDesk OS. Two steps to begin:

1. Run \`/workdesk-doctor\` to verify runtime hooks and locks.
2. Run \`/onboarding\` to set up your role mix and active contexts (~10 minutes, six phases).

Then \`/daily-ops\` tomorrow morning, and \`/weekly-review\` at the end of the week.
EOF

note "Welcome item: $WELCOME"

# ============================================================================
# 8. bootstrap-install-completed event
# ============================================================================

step "Logging bootstrap-install-completed"

MONTH=$(date '+%Y-%m')
EVENTS_FILE="$TARGET/system/events/$MONTH.md"
[[ -f "$EVENTS_FILE" ]] || printf "# Events — %s\n\n" "$MONTH" > "$EVENTS_FILE"
printf "%s | bootstrap-install-completed | %s | ok\n" "$(date '+%Y-%m-%d %H:%M')" "$TARGET" >> "$EVENTS_FILE"

# Also seed signals.json suppression date (today + 14 days for vault-improvements).
SUPPRESS_UNTIL=$(date -j -v+14d '+%Y-%m-%d' 2>/dev/null || date -d '+14 days' '+%Y-%m-%d')
SIGNALS_JSON="$TARGET/_workdesk/state/signals.json"
mkdir -p "$(dirname "$SIGNALS_JSON")"
cat > "$SIGNALS_JSON" <<EOF
{
  "daily-plan": { "last-fired": null },
  "weekly-review": { "last-fired": null },
  "vault-improvements": { "last-fired": null, "suppressed-until": "$SUPPRESS_UNTIL" }
}
EOF

note "vault-improvements suppressed until $SUPPRESS_UNTIL"

# ============================================================================
# 9. filesystem self-check
# ============================================================================

step "Filesystem self-check"

errs=0
check_dir()  { [[ -d "$1" ]] || { warn "missing directory: $1"; errs=$((errs+1)); }; }
check_file() { [[ -f "$1" ]] || { warn "missing file: $1"; errs=$((errs+1)); }; }
check_exec() { [[ -x "$1" ]] || { warn "not executable: $1"; errs=$((errs+1)); }; }

# Required directories
for d in personal atlas gtd intel system _workdesk; do check_dir "$TARGET/$d"; done

# settings.json valid JSON
if ! /usr/bin/plutil -convert json -o /dev/null "$TARGET/_workdesk/settings.json" 2>/dev/null; then
  warn "_workdesk/settings.json is not valid JSON"; errs=$((errs+1))
fi

# Hook scripts executable
for s in json-get pre-tool-use-personal-lock post-tool-use-log session-entry-scan session-end-session-dump stop-session-snapshot bench-hooks; do
  check_exec "$TARGET/_workdesk/scripts/$s.sh"
done

# .claude symlink resolves
if ! [[ -L "$TARGET/.claude" && -d "$TARGET/.claude" ]]; then
  warn ".claude symlink does not resolve"; errs=$((errs+1))
fi

# Write access in non-personal zones
PROBE="$TARGET/system/intake/_bootstrap-probe-$$"
if printf 'probe' > "$PROBE" 2>/dev/null; then
  rm -f "$PROBE"
else
  warn "could not write to system/intake/"; errs=$((errs+1))
fi

# Verify json-get.sh works without jq
test_payload='{"tool_name":"Write","tool_input":{"file_path":"/tmp/x.md"}}'
got=$(printf '%s' "$test_payload" | "$TARGET/_workdesk/scripts/json-get.sh" tool_name 2>/dev/null || true)
if [[ "$got" != "Write" ]]; then
  warn "json-get.sh failed to extract a known field (got: '$got')"
  errs=$((errs+1))
fi

if (( errs > 0 )); then
  echo ""
  echo "    $(c_red "Bootstrap incomplete:") $errs check(s) failed."
  echo "    Review the warnings above. Common fixes:"
  echo "      - Ensure the source repo is intact (re-clone if needed)"
  echo "      - chmod +x $TARGET/_workdesk/scripts/*.sh"
  echo "      - Re-create .claude symlink: cd $TARGET && rm .claude && ln -s _workdesk .claude"
  exit 1
fi

# ============================================================================
# done
# ============================================================================

step "Done"
echo ""
echo "    $(c_green "✓") WorkDesk OS V1 installed at $TARGET"
echo ""
echo "    Next steps:"
echo "      1. cd $TARGET"
echo "      2. claude"
echo "      3. /workdesk-doctor"
echo "      4. /onboarding"
echo "      5. /daily-ops tomorrow morning, /weekly-review at week end"
echo ""
