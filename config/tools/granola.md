---
tool: Granola
slug: granola
category: transcription
class: seeded
connected: false
added-on: 2026-04-29
connector: app
preferred-for: []
confirmed-by-operator: false
---

## What it is

Local macOS app that captures meeting audio and produces structured notes + transcripts. Common transcription source for in-person and 1:1 meetings.

## Best practices

- Granola records locally; the data is on the operator's Mac, not a cloud sync.
- Raw transcripts and Granola's structured notes both end up in the local app data directory; WorkDesk's transcript-processing skill reads from there.
- Pair with WorkDesk's `/process-transcripts` to land meeting notes in `atlas/meetings/` and extract people, decisions, actions into `atlas/`.

## Connection notes

**Install:** download from https://www.granola.ai (macOS only).

**Verification:** `~/Library/Application Support/com.granola.app/` exists.

**Data location:** Granola stores its database under that Application Support path. WorkDesk's transcript-processing skill reads from there directly — no API key, no auth.

## Linked use cases

- transcript processing → meeting notes
