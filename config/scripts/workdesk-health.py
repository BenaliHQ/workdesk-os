#!/usr/bin/env python3
"""Read-only local capability and backup exceptions. Does not contact providers."""
import argparse
import datetime as dt
import json
from pathlib import Path
import shutil
import subprocess
import time


def backup_status(pending, commit_age, push_pending_age, marker_known, head_pushed):
    issues = []
    if commit_age is None:
        issues.append("commit-history-unavailable")
    elif pending and commit_age > 1800:
        issues.append("pending-changes-no-commit-30m")
    if not marker_known:
        issues.append("push-marker-unavailable")
    elif not head_pushed and push_pending_age is None:
        issues.append("push-ancestry-unverified")
    elif not head_pushed and push_pending_age > 7200:
        issues.append("unpushed-commit-older-than-2h")
    return issues


def inspect(vault):
    def git(*args):
        r = subprocess.run(["git", "-C", str(vault), *args], capture_output=True, text=True)
        return r.stdout.strip() if r.returncode == 0 else None
    now = time.time()
    head = git("rev-parse", "HEAD")
    stamp = git("log", "-1", "--format=%ct")
    commit_age = max(0, int(now) - int(stamp)) if stamp else None
    pending = git("status", "--porcelain")
    marker_path = git("rev-parse", "--git-path", "last-backup-push")
    marker = Path(marker_path) if marker_path else None
    if marker and not marker.is_absolute(): marker = vault / marker
    pushed = marker.read_text().strip() if marker and marker.is_file() else None
    age = None
    if pushed and head != pushed:
        ancestry = subprocess.run(["git", "-C", str(vault), "merge-base", "--is-ancestor", pushed, "HEAD"], capture_output=True)
        if ancestry.returncode == 0:
            stamps = git("log", "--reverse", "--format=%ct", pushed + "..HEAD")
            age = max(0, int(now) - int(stamps.splitlines()[0])) if stamps else None
    issues = backup_status(bool(pending), commit_age, age, bool(pushed), head == pushed)
    plugin = vault / '.obsidian/community-plugins.json'
    data = vault / '.obsidian/plugins/obsidian-git/data.json'
    try:
        enabled = 'obsidian-git' in json.loads(plugin.read_text())
        settings = json.loads(data.read_text())
        auto_pull = bool(settings.get('autoPullOnBoot') or settings.get('autoPullInterval', 0))
        cadence = settings.get('autoSaveInterval')
        if not enabled: issues.append('automatic-commit-plugin-disabled')
        if auto_pull: issues.append('automatic-pull-enabled')
    except (OSError, ValueError, TypeError):
        enabled = auto_pull = cadence = None
        issues.append('backup-plugin-state-unavailable')
    if pending is None: issues.append('working-tree-unavailable')
    if not (Path.home()/'.claude/hooks/verify-send-phrase.py').is_file(): issues.append('email-verifier-missing')
    if not (Path.home()/'.claude/email-send-phrase').is_file(): issues.append('email-phrase-not-provisioned')
    return {
        'as_of': dt.datetime.now(dt.timezone.utc).isoformat(),
        'host': __import__('socket').gethostname(),
        'vault': str(vault),
        'status': 'attention' if issues else 'no-local-exception-detected',
        'exceptions': issues,
        'backup': {'commit_age_seconds': commit_age, 'pending_change_count': len(pending.splitlines()) if pending is not None else None,
                   'head_matches_local_push_receipt': bool(head and pushed and head == pushed), 'oldest_unpushed_age_seconds': age,
                   'automatic_commits_enabled': enabled, 'commit_interval_minutes': cadence, 'automatic_pull_enabled': auto_pull},
        'tools_on_this_path': {name: bool(shutil.which(name)) for name in ['claude','codex','gws','qbo','qmd','ntn','keep-markdown','infisical']},
        'safety': {'codex_wiring_present': (vault/'.codex/hooks.json').is_file(),
                   'verifier_present': (Path.home()/'.claude/hooks/verify-send-phrase.py').is_file(),
                   'phrase_present': (Path.home()/'.claude/email-send-phrase').is_file(),
                   'runtime_certification': 'see implementation receipts; file presence is not protection'},
        'limits': ['No remote freshness or visibility check performed.', 'Sleep/offline time is not subtracted; inspect host availability before escalating an age warning.',
                   'Tool presence does not establish account readiness.', 'No secrets or provider payloads were read.']}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--vault', type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    print(json.dumps(inspect(args.vault.resolve()), indent=2))
