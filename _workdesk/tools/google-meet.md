---
tool: Google Meet
slug: google-meet
category: transcription
class: seeded
connected: false
added-on: 2026-04-29
connector: api
preferred-for: []
confirmed-by-operator: false
---

## What it is

Google's video meetings + transcription. When recording is enabled in a Workspace org, Meet attaches transcripts (or "Notes by Gemini" with a Transcript tab) to the calendar event in Google Drive.

## Best practices

- Transcripts are accessed via the Google Workspace CLI (`gws`) — fetch them by calendar event ID.
- Two formats: (1) standalone "Transcript" attachment (single-tab Google Doc), (2) "Notes by Gemini" multi-tab Doc where tab 1 is the verbatim transcript. Always check both.
- Pair with WorkDesk's `/process-transcripts` skill to land meeting notes in `atlas/meetings/` and extract entities.

## Connection notes

**Install:** Google Workspace account with recording/transcription enabled. CLI access via `gws` (operator's separate install).

**Verification:** `gws calendar +agenda --today` returns events; events with transcripts include attachments.

**Auth:** `gws auth login --account <email>` — uses OAuth.

## Linked use cases

- transcript processing → meeting notes
