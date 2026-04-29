---
tool: Zoom
slug: zoom
category: transcription
class: seeded
connected: false
added-on: 2026-04-29
connector: api
preferred-for: []
confirmed-by-operator: false
---

## What it is

Zoom's cloud recording + transcription. When cloud recording is enabled, transcripts are produced as VTT files attached to the recording in the Zoom web portal.

## Best practices

- Cloud recording must be enabled on the Zoom account — local-only recordings don't get transcripts.
- Transcripts download as VTT (or rendered to plain text). Both work for processing.
- Pair with WorkDesk's `/process-transcripts` skill to land meeting notes.

## Connection notes

**Install:** Zoom account with cloud recording enabled.

**Verification:** browse to https://zoom.us/recording — recordings list should show transcripts available.

**Connection:** TBD for V1.1. Manual download supported today; API-based fetch (Zoom OAuth + recordings API) is a future `/define-tool` integration.

## Linked use cases

- transcript processing → meeting notes
