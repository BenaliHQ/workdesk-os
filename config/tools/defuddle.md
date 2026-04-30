---
tool: defuddle
slug: defuddle
category: cli
class: first-class
connected: false
added-on: 2026-04-29
connector: cli
preferred-for: []
confirmed-by-operator: false
---

## What it is

Clean markdown extraction from web pages. Strips clutter and navigation, returns just the content. Used by bookmark and intake processing skills to convert web pages into vault-readable notes without burning tokens on noise.

## Best practices

- `defuddle <url>` — extract content as markdown.
- Prefer over WebFetch for any URL the operator wants to read or analyze, especially long articles.
- Output is markdown; pipe directly into `system/_intake/` or a target note.

## Connection notes

**Install:** see [defuddle CLI install instructions]. Typically a single-binary install via package manager.

**Verification:** `command -v defuddle` succeeds.

## Linked use cases

- *(filled in as skills declare they use defuddle)*
