---
type: object-type-definition
name: meeting
zone: atlas
location: atlas/meetings/
shape: atomic
naming: "{YYYY-MM-DD}-{topic-slug}"
version: 1.0
---

# Object Type: meeting

Single record of a real interaction. Always traceable to a transcript or live session. Universal — ships pre-built.

## Format

```yaml
---
type: meeting
status: active
date: 2026-04-26
attendees: ["[[atlas/people/martin-holland]]", "..."]
transcript: "[[system/transcripts/2026-04-26-dudley-weekly]]"
source: "[[system/transcripts/2026-04-26-dudley-weekly]]"
engagement: "[[atlas/clients/dudley/_brief]]"           # optional, if engagement-tied
created: 2026-04-26
last_updated: 2026-04-26
author: claude
---
```

Body sections:
- **Discussion** — what was talked about, with claim-level inline citations to the transcript when accumulating from multiple sources
- **Decisions** — bulleted, each linked to its `atlas/decisions/{slug}` if it merits its own note
- **Action items** — bulleted, each linked to its `gtd/actions/next/{slug}` once created

## Detection

Meetings are not auto-created. They are produced by `/process-transcripts` after operator confirms the proposal in `gtd/inbox/`.

## Matching

When a meeting note is created:
- Update each attendee's person note with the relevant context (per matching rule)
- Create or update `atlas/decisions/` for any decisions that merit standalone notes
- Create `[REVIEW]` items for proposed action creations (subject to the 7-per-session cap)
- Set source's `processed-into:` backlink to point at the meeting note

## Confidentiality

If the engagement is a client, the `client-confidentiality` rule applies — internal traceability stays, external-facing content (drafts published from this meeting) anonymizes.
