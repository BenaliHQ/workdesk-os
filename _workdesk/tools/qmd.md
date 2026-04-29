---
tool: qmd
slug: qmd
category: cli
class: first-class
connected: false
added-on: 2026-04-29
connector: cli
preferred-for: []
confirmed-by-operator: false
---

## What it is

Hybrid semantic + keyword search over the vault's markdown files. Surfaces conceptually related notes, not just literal matches. Multiple WorkDesk skills (briefings, research, intel, transcripts) call `qmd query` to find related context.

## Best practices

- `qmd query "topic"` — short, focused topic phrases work best for semantic search.
- `qmd status` — check index health when results look stale.
- Use `grep` for literal string searches; use `qmd` for "what notes are about this idea?"
- Re-vectorization runs periodically to keep results fresh — see Connection notes.

## Connection notes

**Install:** `brew install qmd` (or document the actual install path the operator uses).

**Verification:** `command -v qmd` succeeds AND `qmd status` returns healthy.

**Vectorization runner — open question.** qmd needs a periodic process to re-vectorize the vault as files change. Where the runner lives (`_workdesk/scripts/`? a launchd plist? cron?), how often it runs, and whether `/workdesk-doctor` checks freshness — TBD for V1.1. Tracked in `atlas/projects/workdesk/specs/onboarding-redesign.md` Open Items §7.

## Linked use cases

- *(filled in as skills declare they use qmd)*
