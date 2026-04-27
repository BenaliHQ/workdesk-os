---
type: object-type-definition
name: initiative
zone: atlas
location: atlas/initiatives/
shape: container
folder-structure: 8-item
naming: kebab-slug
version: 1.0
---

# Object Type: initiative

Multi-session, **engagement-tied or area-tied**, with a **bounded outcome**. Ends. (Standing responsibility lives in `atlas/areas/`; recurring maintenance lives in `gtd/recurring/`.) Use the same 8-item structure as `project`.

## Folder structure

```
atlas/initiatives/{slug}/
  _brief.md, _status.md, plan.md, notes/, reference/, specs/, deliverables/, _archive/
```

## Frontmatter on `_brief.md`

```yaml
---
type: initiative
status: active                                          # active | archived
engagement: "[[atlas/clients/dudley/_brief]]"           # OR area: instead of engagement:
area: ""                                                # exactly one of these populated
expected-cadence: weekly
last-touched: 2026-04-26
source: "[[...]]"
created: 2026-04-26
last_updated: 2026-04-26
author: claude | operator
---
```

Default `expected-cadence: weekly`. Exactly one of `engagement:` and `area:` must be populated.

## Lifecycle

- Created from `/pobo` when scope test detects an engagement parent
- Linked back from the engagement or area `_status.md`
- Archive: `mv atlas/initiatives/{slug} atlas/initiatives/_archive/{year}/{slug}` — agent rewrites inbound `parent:` links in same operation

## The initiative test (strict, prevents sprawl)

- Bounded outcome AND multi-session AND parent (engagement OR area) → initiative
- Bounded outcome, multi-session, no parent → project
- Standing responsibility, no end → area (with recurring items underneath)
- Single session → action

If unsure between project and initiative: pick the one with a parent if a parent exists.

## Detection

`[REVIEW]` proposal when:
- A `/pobo` session names a clear engagement or area context AND has a definite end-state
- Confidence ≥0.7

## Matching

- New `_brief.md` → emit `initiative-created`
- On status change to `archived`, scan and rewrite inbound `parent:` links targeting `_brief`
