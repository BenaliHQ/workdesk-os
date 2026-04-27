---
type: object-type-definition
name: decision
zone: atlas
location: atlas/decisions/
shape: atomic
naming: "{YYYY-MM-DD}-{topic-slug}"
version: 1.0
---

# Object Type: decision

A choice made, with rationale, sourced to where it was made. Universal — ships pre-built.

## Format

```yaml
---
type: decision
status: active                                          # active | reversed | superseded
date: 2026-04-26
source: "[[atlas/meetings/2026-04-26-dudley-weekly]]"
participants: ["[[atlas/people/khalil-benalioulhaj]]", "..."]
affects: ["[[atlas/initiatives/dudley-msa-review/_brief]]", "..."]
created: 2026-04-26
last_updated: 2026-04-26
author: claude
---
```

Body sections:
- **Decision** — one sentence
- **Rationale** — why; if not captured, write "Rationale not captured in source"
- **Implications** — what changes downstream
- **Reversal conditions** — what would cause us to revisit (often empty)

## Detection

`[REVIEW]` proposal when:
- A meeting note's "Decisions" section has an entry that merits standalone treatment (high-stakes, cross-engagement, framework-shaping)
- Operator says "we decided X" in a session
- Confidence ≥0.7

Routine decisions stay inline on the meeting note; only durable ones get their own file.

## Matching

When a decision is created:
- Update each affected entity's `_status.md` (per matching rule)
- Link back from the meeting/source
- If the decision reverses an earlier one, set the earlier decision's `status: reversed` and add a `superseded-by:` field
