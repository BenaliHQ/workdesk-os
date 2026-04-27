---
type: object-type-definition
name: person
zone: atlas
location: atlas/people/
shape: atomic
naming: "{first-last}"
version: 1.0
---

# Object Type: person

A human you interact with. Accumulates evidence across meetings — every claim cites its source. Universal — ships pre-built.

## Format

```yaml
---
type: person
status: active
role: ""                                                # short descriptor
company: "[[atlas/companies/...]]"                     # optional wikilink
engagement: "[[atlas/clients/...]]"                    # if tied to an engagement
source: "[[atlas/meetings/2026-04-22-first-call]]"     # primary/initial source
created: 2026-04-22
last_updated: 2026-04-26
author: claude
---
```

Body sections:
- **Context** — relationship summary, with claim-level inline footnotes for additions across meetings
- **Recent threads** — open conversations, last interaction date

Per the source-documentation rule, frontmatter `source:` records the initial source. Later additions use inline footnotes:

```markdown
Joined the pilot in February.[^1] Champion for MSA review in April.[^2]

[^1]: [[atlas/meetings/2026-02-03-dudley-pilot]]
[^2]: [[atlas/meetings/2026-04-23-dudley-weekly]]
```

## Detection

`[REVIEW]` proposal when:
- A name appears in ≥2 meetings within 30 days and has no person note
- Confidence ≥0.7
- Below threshold (single mention, ambiguous): use plain text in the source note, don't propose

## Matching

When a person note is created or updated from a meeting:
- The meeting's `attendees:` includes a wikilink to the person note
- Updates to a person note must cite the source meeting (inline footnote)
