---
paths:
  - "**/*.md"
---

# QMD — Tool Reference

Hybrid semantic and keyword search over vault markdown files. Use for finding conceptually related notes, not just exact text matches.

## Access Method

CLI command: `qmd`. Resolve it with `command -v qmd` in the actual agent or job environment; installation paths differ by host. An executable being present does not establish that the intended vault is indexed.

## Common Commands

| Command | What it does | Example |
|---|---|---|
| `qmd query "topic"` | Semantic + keyword hybrid search | `qmd query "client onboarding process"` |
| `qmd status` | Check index health and status | `qmd status` |
| `qmd collection list` | Check configured scope | `qmd collection list` |
| `qmd search "topic" --json` | Keyword search without a model | `qmd search "ownership contract" --json` |
| `qmd multi-get <reference> --json` | Read indexed content as JSON | `qmd multi-get qmd://workdesk/path/to/note.md --json` |

## Readiness and source verification

- Confirm the intended vault path and markdown scope in the collection configuration. An empty collection list is unavailable search coverage, not evidence that the vault contains no relevant notes.
- Check indexed document counts, pending embeddings and the last update. Keyword indexing and embedding completion are separate checks. Do not describe partial embedding coverage as complete semantic search.
- `qmd update` refreshes configured collections; `qmd embed` generates pending embeddings. A periodic runner must have an explicit owner and verified environment. Do not add `--pull` to an index refresh: vault transport is managed separately.
- Before running or scheduling `qmd update`, review every collection in that index. In QMD 2.0.1, a collection's configured `update` shell command runs automatically even without `--pull`. Require no such commands for an index-only refresh, or review and authorize their effects separately. A shared index may contain collections outside the intended vault.
- Results and retrieved content are cached index snapshots. Verify the current source file before citing its current state or editing it. QMD virtual paths can normalize case, spaces and punctuation; do not turn them directly into filesystem paths or Obsidian links without resolving the actual filename.
- Search ranking does not establish source authority. Distinguish raw sources, sourced records, agent analysis and historical notes when using results.

## Known Limitations

The optional `config/scripts/refresh-search.py` runner requires the pinned source-processing Python runtime with PyYAML 6.0.3, explicit absolute Node/QMD/package paths, an existing host-local index, a host-local state directory, and the reviewed configuration SHA-256. Use its `--help` for required arguments. Its companion `verify-search-index.mjs` must be installed beside it. The adapter currently supports QMD 2.0.1; revalidate before changing that version.

Before scheduling, drain other QMD writers, verify the initial index, and route subsequent refreshes through the same runner lock. A completed receipt includes source and full-chunk checks for that observation; it is not a promise that no later edits occurred. Source-only staleness can be retried by a later refresh. Partial embedding, invalid verifier output or an interrupted run requires independent repair/reconciliation. Do not delete a repair marker merely to make a retry run: first establish complete source/chunk coverage and review the failed receipt. The runner never clears repair markers automatically. Preserve the last successful receipt when a newer run fails.

- Results depend on index freshness — newly created notes may not appear until the index updates.
- Semantic search can surface conceptually related but not literally matching notes — verify relevance before acting on results.
- First-use model downloads can mix progress into requested JSON output. Parse the complete response and reject non-JSON output; finish model provisioning separately and retry the read. Do not silently strip arbitrary text to accept an agent receipt.
- In QMD 2.0.1, `get` returns a text document even when passed `--json`; use the documented `multi-get --json` interface for structured retrieval. Verify supported options when changing versions.

## Common Mistakes

- Using QMD when you need exact text matching — use Grep instead for literal string searches.
- Not running `qmd status` when queries return unexpected results — the index may be stale or unhealthy.
- Using overly long queries — short, focused topic phrases work best for semantic search.

## Authentication

None required. Reads directly from the vault's markdown files.
