#!/usr/bin/env bash
# update-check-test.sh — verify check-for-updates.sh logic.
#
# Network-dependent paths use a stub HTTP via WORKDESK_REPO pointing to a
# non-existent repo, so curl fails fast and we exercise the offline path.
# Cache and notice paths are tested by hand-writing the cache JSON.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/config/scripts/check-for-updates.sh"

PASS=0
FAIL=0
assert_match() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -q -- "$needle"; then
    printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '  FAIL  %s\n         needle: %s\n         got: %s\n' "$label" "$needle" "$haystack"
    FAIL=$((FAIL+1))
  fi
}
assert_empty() {
  local label="$1" haystack="$2"
  if [[ -z "$haystack" ]]; then
    printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '  FAIL  %s\n         got: %s\n' "$label" "$haystack"
    FAIL=$((FAIL+1))
  fi
}

# ---- Scenario 1: network failure → silent, no notice, false ----------------

echo "Scenario 1: unreachable repo (offline simulation)"
T1="$(mktemp -d)"
mkdir -p "$T1/config/state"
echo "1.2.4" > "$T1/config/VERSION"
result=$(WORKDESK_REPO="non-existent-org-xyz/no-such-repo" \
         CLAUDE_PROJECT_DIR="$T1" "$SCRIPT" check 2>&1)
notice=$(WORKDESK_REPO="non-existent-org-xyz/no-such-repo" \
         CLAUDE_PROJECT_DIR="$T1" "$SCRIPT" notice 2>&1)
assert_match "check returns valid JSON" "$result" '"current-version"'
assert_match "current-version is 1.2.4" "$result" '"current-version": "1.2.4"'
assert_match "update-available is false" "$result" '"update-available": false'
assert_empty "no notice on offline" "$notice"
rm -rf "$T1"

# ---- Scenario 2: cached state, update available -----------------------------

echo
echo "Scenario 2: cache says update available (no network needed)"
T2="$(mktemp -d)"
mkdir -p "$T2/config/state"
echo "1.2.3" > "$T2/config/VERSION"
# Hand-write a fresh (within 24h) cache so the script doesn't hit the network.
python3 -c "
import json
from datetime import datetime, timezone
now = datetime.now(timezone.utc).isoformat().replace('+00:00','Z')
json.dump({
    'last-check': now,
    'latest-version': '1.2.4',
    'current-version': '1.2.3',
    'update-available': True,
}, open('$T2/config/state/update-check.json','w'))
"
result=$(CLAUDE_PROJECT_DIR="$T2" "$SCRIPT" check)
notice=$(CLAUDE_PROJECT_DIR="$T2" "$SCRIPT" notice)
assert_match "check reads cached state" "$result" '"latest-version": "1.2.4"'
assert_match "notice surfaces version"  "$notice" 'v1.2.4'
assert_match "notice says /update"      "$notice" '/update'
assert_match "notice shows current"     "$notice" "v1.2.3"
rm -rf "$T2"

# ---- Scenario 3: cached state, no update available --------------------------

echo
echo "Scenario 3: cache says up-to-date (no notice expected)"
T3="$(mktemp -d)"
mkdir -p "$T3/config/state"
echo "1.2.4" > "$T3/config/VERSION"
python3 -c "
import json
from datetime import datetime, timezone
now = datetime.now(timezone.utc).isoformat().replace('+00:00','Z')
json.dump({
    'last-check': now,
    'latest-version': '1.2.4',
    'current-version': '1.2.4',
    'update-available': False,
}, open('$T3/config/state/update-check.json','w'))
"
notice=$(CLAUDE_PROJECT_DIR="$T3" "$SCRIPT" notice)
assert_empty "no notice when up-to-date" "$notice"
rm -rf "$T3"

# ---- Scenario 4: stale cache triggers refresh attempt -----------------------

echo
echo "Scenario 4: cache >24h old triggers refresh (offline-safe)"
T4="$(mktemp -d)"
mkdir -p "$T4/config/state"
echo "1.2.4" > "$T4/config/VERSION"
# Cache is 30h old, claiming an update available — refresh attempt with a
# bad repo will fail silently, leaving the old cache in place.
python3 -c "
import json
from datetime import datetime, timezone, timedelta
old = (datetime.now(timezone.utc) - timedelta(hours=30)).isoformat().replace('+00:00','Z')
json.dump({
    'last-check': old,
    'latest-version': '99.99.99',
    'current-version': '1.2.4',
    'update-available': True,
}, open('$T4/config/state/update-check.json','w'))
"
result=$(WORKDESK_REPO="non-existent-org-xyz/no-such-repo" \
         CLAUDE_PROJECT_DIR="$T4" "$SCRIPT" check)
# After offline refresh attempt, cache is unchanged (still says 99.99.99).
# This proves the refresh fails silently rather than wiping good cache.
assert_match "stale cache preserved when refresh fails" "$result" '"latest-version": "99.99.99"'
rm -rf "$T4"

# ---- Result -----------------------------------------------------------------

echo
echo "Result: $PASS passed, $FAIL failed"
exit $(( FAIL > 0 ? 1 : 0 ))
