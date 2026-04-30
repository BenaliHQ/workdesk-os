# `config/tools/` — Tool Inventory

One markdown note per tool the operator uses or that WorkDesk skills know about. Tools are not auto-installed; this folder tracks **what's known**, not what's installed.

## How notes get here

- **Seeded at install.** First-class CLIs (`qmd`, `defuddle`), recommended CLIs (`gh`, `vercel`), and well-known transcription sources (Granola, Google Meet, Zoom, Microsoft Teams) ship with seeded notes. Operator may have these installed or not — `connected: false` until verified.
- **Added during onboarding.** Phase 2 Q5 of `/onboarding` asks the operator to name tools they use. Each named tool gets a note here (or, if seeded, gets `confirmed-by-operator: true`).
- **Added on demand.** Operator can run `/define-tool <name>` later to add a tool, fill connection notes, and wire it up.

## Note shape

```yaml
---
tool: <display name>
slug: <kebab-case-id>
category: cli|transcription|comms|email-calendar|pm|crm|storage|design|code-deploy|finance|other
class: first-class|recommended|seeded|operator-named
connected: <bool>
added-on: <iso-date>
connector: api|cli|mcp|app|unknown
preferred-for: [<use-case>]   # optional
confirmed-by-operator: <bool> # set true when operator names a seeded tool
---

## What it is
## Best practices
## Connection notes
## Linked use cases
```

## Classes

- **first-class** — WorkDesk skills depend on this. Failing to install degrades core functionality.
- **recommended** — Common in operator stacks; WorkDesk knows about it but doesn't require it.
- **seeded** — Pre-known tool with a stub note shipped at install. Operator may or may not use it.
- **operator-named** — Added by operator during onboarding or `/define-tool`. No prior knowledge.
