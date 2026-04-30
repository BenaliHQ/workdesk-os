---
paths:
  - "**/*.md"
---

# QMD — Tool Reference

Hybrid semantic and keyword search over vault markdown files. Use for finding conceptually related notes, not just exact text matches.

## Access Method

CLI command: `/opt/homebrew/bin/qmd` (or just `qmd` if on PATH).

## Common Commands

| Command | What it does | Example |
|---|---|---|
| `qmd query "topic"` | Semantic + keyword hybrid search | `qmd query "client onboarding process"` |
| `qmd status` | Check index health and status | `qmd status` |

## Known Limitations

- Results depend on index freshness — newly created notes may not appear until the index updates.
- Semantic search can surface conceptually related but not literally matching notes — verify relevance before acting on results.

## Common Mistakes

- Using QMD when you need exact text matching — use Grep instead for literal string searches.
- Not running `qmd status` when queries return unexpected results — the index may be stale or unhealthy.
- Using overly long queries — short, focused topic phrases work best for semantic search.

## Authentication

None required. Reads directly from the vault's markdown files.
