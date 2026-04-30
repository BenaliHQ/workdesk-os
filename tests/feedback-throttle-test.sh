#!/usr/bin/env bash
# feedback-throttle-test.sh — verify file-issue.sh's throttle math.
#
# Submit-path testing requires actually filing GitHub issues, so it's
# excluded. The throttle logic is the load-bearing piece worth testing.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/config/scripts/file-issue.sh"

PASS=0
FAIL=0
assert() {
  local label="$1"; shift
  if "$@"; then printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else printf '  FAIL  %s\n' "$label"; FAIL=$((FAIL+1))
  fi
}
assert_match() {
  local label="$1" haystack="$2" needle="$3"
  if printf '%s' "$haystack" | grep -q -- "$needle"; then
    printf '  PASS  %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '  FAIL  %s\n         needle: %s\n         haystack: %s\n' "$label" "$needle" "$haystack"
    FAIL=$((FAIL+1))
  fi
}

# ---- Scenario 1: empty state → ok=true, count=0 -----------------------------

echo "Scenario 1: no prior submissions"
T1="$(mktemp -d)"
mkdir -p "$T1/config/state"
result=$(CLAUDE_PROJECT_DIR="$T1" "$SCRIPT" throttle-check)
assert_match "count_24h is 0" "$result" '"count_24h": 0'
assert_match "ok is true"     "$result" '"ok": true'
rm -rf "$T1"

# ---- Scenario 2: under limit ------------------------------------------------

echo
echo "Scenario 2: 5 recent submissions, limit 20"
T2="$(mktemp -d)"
mkdir -p "$T2/config/state"
# Inject 5 ISO timestamps from the last hour.
python3 -c "
import json
from datetime import datetime, timezone, timedelta
now = datetime.now(timezone.utc)
subs = [(now - timedelta(minutes=10*i)).isoformat().replace('+00:00','Z') for i in range(5)]
json.dump({'submissions': subs}, open('$T2/config/state/feedback-throttle.json','w'))
"
result=$(CLAUDE_PROJECT_DIR="$T2" "$SCRIPT" throttle-check)
assert_match "count_24h is 5" "$result" '"count_24h": 5'
assert_match "ok is true"     "$result" '"ok": true'
rm -rf "$T2"

# ---- Scenario 3: at limit ---------------------------------------------------

echo
echo "Scenario 3: 20 recent submissions (at limit)"
T3="$(mktemp -d)"
mkdir -p "$T3/config/state"
python3 -c "
import json
from datetime import datetime, timezone, timedelta
now = datetime.now(timezone.utc)
subs = [(now - timedelta(minutes=30*i)).isoformat().replace('+00:00','Z') for i in range(20)]
json.dump({'submissions': subs}, open('$T3/config/state/feedback-throttle.json','w'))
"
result=$(CLAUDE_PROJECT_DIR="$T3" "$SCRIPT" throttle-check)
assert_match "count_24h is 20" "$result" '"count_24h": 20'
assert_match "ok is false"     "$result" '"ok": false'
rm -rf "$T3"

# ---- Scenario 4: old submissions (>24h) excluded ----------------------------

echo
echo "Scenario 4: 5 old submissions (>24h), 2 recent → count = 2"
T4="$(mktemp -d)"
mkdir -p "$T4/config/state"
python3 -c "
import json
from datetime import datetime, timezone, timedelta
now = datetime.now(timezone.utc)
old = [(now - timedelta(hours=30+i)).isoformat().replace('+00:00','Z') for i in range(5)]
recent = [(now - timedelta(hours=2*i)).isoformat().replace('+00:00','Z') for i in range(2)]
json.dump({'submissions': old + recent}, open('$T4/config/state/feedback-throttle.json','w'))
"
result=$(CLAUDE_PROJECT_DIR="$T4" "$SCRIPT" throttle-check)
assert_match "count_24h is 2" "$result" '"count_24h": 2'
assert_match "ok is true"     "$result" '"ok": true'
rm -rf "$T4"

# ---- Scenario 5: throttle-record appends ------------------------------------

echo
echo "Scenario 5: throttle-record appends and persists"
T5="$(mktemp -d)"
mkdir -p "$T5/config/state"
CLAUDE_PROJECT_DIR="$T5" "$SCRIPT" throttle-record >/dev/null
sleep 1
CLAUDE_PROJECT_DIR="$T5" "$SCRIPT" throttle-record >/dev/null
result=$(CLAUDE_PROJECT_DIR="$T5" "$SCRIPT" throttle-check)
assert_match "count_24h is 2 after two records" "$result" '"count_24h": 2'
assert "throttle file exists"             test -f "$T5/config/state/feedback-throttle.json"
rm -rf "$T5"

# ---- Result -----------------------------------------------------------------

echo
echo "Result: $PASS passed, $FAIL failed"
exit $(( FAIL > 0 ? 1 : 0 ))
