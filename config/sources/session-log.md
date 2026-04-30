---
type: source-declaration
name: session-log
zone: system
location: system/session-log/
naming: "{YYYY-MM-DD}-{HH-MM}-{session-id}-raw.md (raw) | {YYYY-MM-DD}-{slug}.md (summary)"
move-after-processing: false
version: 1.0
---

# Source: session-log

Two-phase Claude session capture.

## Phase 1 — Raw export (hook-driven)

`SessionEnd` hook (`config/scripts/session-end-session-dump.sh`) writes the raw conversation to `system/session-log/{date}-{time}-{session-id}-raw.md` with:

```yaml
---
type: source
source-kind: session-log
date: 2026-04-26
session-id: abc123
transcript-path: "/Users/.../.claude/projects/.../abc123.jsonl"
processed: false
summarized: false
complete: true
---

# Conversation
[Reconstructed from transcript JSONL.]
```

Fallback: if `SessionEnd` is unreliable, the `Stop` hook (`stop-session-snapshot.sh`) upserts ONE file per `session_id` with `complete: false`. `/workdesk-doctor` decides which path is active.

## Phase 2 — `/extract --summarize {raw-file}`

Operator-invoked. Writes the final summarized note to `system/session-log/{date}-{slug}.md`:

```yaml
---
type: session-log
date: 2026-04-26
duration: ~90 min
source: "[[system/session-log/2026-04-26-09-30-abc123-raw]]"
---

# Summary
[3-5 sentences. What happened, decided, changed.]

# Conversation
[Verbatim, every turn.]
```

After write, flips raw file's `summarized: true` and adds the summary path to `processed-into:`.

## Detection (proactive proposal)

`session-entry-scan.sh` surfaces unsummarized raw files. Skill drops a `[REVIEW]` item proposing `/extract --summarize {raw-file}`.

## Retention

Both raw and summary persist forever. No archive policy.
