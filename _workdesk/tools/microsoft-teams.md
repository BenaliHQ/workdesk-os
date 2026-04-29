---
tool: Microsoft Teams
slug: microsoft-teams
category: transcription
class: seeded
connected: false
added-on: 2026-04-29
connector: api
preferred-for: []
confirmed-by-operator: false
---

## What it is

Microsoft Teams meetings + transcription. When transcription is enabled, transcripts attach to the meeting in Teams or are accessible via the Microsoft Graph API.

## Best practices

- Transcription must be enabled per-meeting (or org-default) — off by default in many orgs.
- Transcripts surface in the Teams chat thread for the meeting and as VTT via Graph API.
- Pair with WorkDesk's `/process-transcripts` skill.

## Connection notes

**Install:** Microsoft 365 account; Teams transcription enabled.

**Verification:** open a recent meeting in Teams; "Recording & transcript" pane should show the transcript.

**Connection:** TBD for V1.1. Manual export supported today; Graph API fetch is a future `/define-tool` integration.

## Linked use cases

- transcript processing → meeting notes
