---
started: ""
phases:
  environment-check: pending
  role-map: pending
  context-setup: pending
  tool-setup: pending
  first-daily-plan: pending
  graduation: pending
version: 1.0
---

# Onboarding State

`/onboarding` updates this file as it runs. Resuming `/onboarding` picks up at the first non-`complete` phase.

Phase status values: `pending`, `incomplete`, `complete`.

- `pending` — not yet started
- `incomplete` — started but interrupted (re-running resumes here)
- `complete` — finished cleanly

Editing the `_workdesk/onboarding-state.md` file flipping any phase to `complete` emits an `onboarding-phase-completed` event.
