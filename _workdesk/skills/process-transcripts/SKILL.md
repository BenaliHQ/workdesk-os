---
name: process-transcripts
description: Process unprocessed transcripts in system/transcripts/ into atlas/meetings, atlas/decisions, atlas/people updates, and gtd/inbox proposals. Operator-confirmed per transcript. Honors the matching rule, the inbox flood guard, and source-documentation.
---

# /process-transcripts

Move raw transcripts through the extraction pipeline into structured vault notes. Operator confirms each transcript before processing. Never auto-process in the background.

## Invocation

- `/process-transcripts` — interactive, one transcript at a time
- `/process-transcripts {path}` — process a specific transcript
- `/process-transcripts --all` — process every unprocessed transcript without per-file confirmation (use sparingly)

## Phases (per transcript)

### 1. Read source

Read the transcript file. Verify frontmatter has `processed: false`. If `processed: true`, skip.

### 2. Mid-ingest checkpoint (high-stakes only)

If the transcript matches any of:
- title contains `[HIGH STAKES]`
- attendees include external advisors (operator-tagged)
- engagement is in operator-marked high-stakes list

Pause and present the extraction plan: meeting note path, decisions to consider, people to update, action proposals. Operator confirms or redirects.

For routine transcripts, skip the checkpoint.

### 3. Create the meeting note

`atlas/meetings/{YYYY-MM-DD}-{topic-slug}.md` per `_workdesk/objects/meeting.md`:

- Frontmatter: type, date, attendees (wikilinks where person notes exist), transcript backlink, source, engagement (if any), created, last_updated
- Body: Discussion (with claim-level inline citations as needed), Decisions, Action items

### 4. Apply matching

Update each touched entity in the same pass:

- **Attendees** — for each existing person note, add new context with inline footnote citation. For attendees without a person note, decide:
  - ≥2 meetings within 30 days → propose `[REVIEW]` for person note creation
  - Single mention → use plain text, don't propose
- **Decisions** — durable decisions get standalone `atlas/decisions/{date}-{slug}.md` notes (`[REVIEW]` proposals, subject to cap). Routine decisions stay inline on the meeting note.
- **Action items** — propose `gtd/actions/next/` creations via `[REVIEW]` (with `parent:` resolved to the engagement, project, or area), subject to flood guard

### 5. Flip source state

Update transcript frontmatter:
- `processed: true`
- `processed-into:` list with backlinks to meeting note and any standalone decisions

### 6. Log

Hook fires `source-processed` and `object-created` events automatically. No manual log entry needed.

## Confidentiality

If the engagement is a client, apply `client-confidentiality`:
- Internal traceability stays
- Any content draft proposed from this meeting must anonymize
- Add a `[QUESTION]` if any insight is unusually identifiable

## What NOT to do

- Don't fabricate attendees from a calendar event when the transcript doesn't list them.
- Don't fill timeline gaps. If the transcript jumps topics, don't reconstruct what was missed.
- Don't ship more than 7 `[REVIEW]` proposals per session. Batch the rest.
- Don't process a transcript without operator confirmation in interactive mode.
