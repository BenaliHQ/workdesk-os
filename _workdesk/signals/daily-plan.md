---
type: signal-declaration
name: daily-plan
shape: briefing
output-folder: intel/briefings/daily/
naming: "{YYYY-MM-DD}-daily-plan"
schedule: daily
version: 1.0
---

# Signal: daily-plan

Generate today's daily plan. Be contextual and timely. Pull whatever's relevant for what's happening today, regardless of how far back the source is. No hardcoded windows; do graph traversal from today's anchors.

## Purpose

Operator opens Claude Code in the morning (or whenever they start) and the daily plan is either freshly generated or the cue to generate it.

## Anchors

Zones (read from vault):
- today's calendar events (via `gws calendar +agenda --today` if a calendar tool is connected per `_workdesk/tools/`)
- today's daily note (if exists; otherwise most recent in `personal/daily/`)
- `gtd/inbox/` items (with backlog warning if >20 unresolved)
- active `gtd/projects/*/_status.md` (status `active`, `last-touched` recent)
- due `gtd/recurring/schedules/` items (`status: active` AND `next_due <= today`)

Tools (try if connected per `_workdesk/tools/<slug>.md` `connected: true`; degrade silently if not):
- `gws calendar` (today + next 3 days)
- `gws gmail` (unread)

## Traversal

1. For each person on today's calendar: fetch their note + last meeting (no time cap)
2. For each project referenced today: fetch `_status` + recent meetings tied to it
3. Surface stale work: projects whose `last-touched` exceeds `1.5 × expected-cadence` (where `expected-cadence: none` is excluded)

## Sparse-data fallback chain

Try in order; layers with no data are silently skipped:

1. Calendar commitments (today + tomorrow)
2. `gtd/actions/next/` (sorted by `parent:` recency)
3. Due recurring items from `gtd/recurring/schedules/`
4. Active project `_status.md` summaries
5. Today's daily note
6. Unread inbox items (with backlog warning if >20)
7. Stale contexts needing attention

If all 7 layers return empty (true cold-start), produce a **setup-oriented plan**: "Nothing scheduled and nothing in next-actions. First steps to seed the vault: …" — never a hollow report.

## Output

`intel/briefings/daily/{YYYY-MM-DD}-daily-plan.md`:

```yaml
---
type: signal
shape: briefing
date: 2026-04-26
sources: ["[[...]]", "[[...]]"]
schedule: daily
---
```

Body sections:
1. Today's commitments + relevant context for each
2. Projects to advance + where you left off
3. Stalled items needing attention
4. Inbox items awaiting triage

Tonality respects `_workdesk/operator-profile.md` `role`, `work-mode`, and `first-30-days-mode`. During `first-30-days-mode: active`, lean toward setup-oriented guidance ("you have 2 active projects; weekly-review will surface stale ones"). If `role` or `work-mode` is empty (early state), default to neutral.

## Schedule mechanism

`SessionStart` reads `_workdesk/state/signals.json`. If `daily-plan.last-fired` is before local midnight (today 00:00), session-entry adds a notice proposing `/daily-ops`. After a successful write, the skill updates `daily-plan.last-fired` to today.

## Detection (proactive proposal beyond the daily schedule)

Surface ad-hoc generation when:
- Operator asks "what's on my plate" or equivalent
- Mid-day context shift (long break) and existing daily-plan is stale relative to new calendar events

## ## Learnings

(Empty. Operator corrections during execution land here.)
