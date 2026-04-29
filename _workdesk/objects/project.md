---
type: object-type-definition
name: project
zone: gtd
location: gtd/projects/
shape: container
folder-structure: 8-item
naming: kebab-slug
version: 1.0
---

# Object Type: project

Multi-session operator attention. Bounded outcome with multiple steps; or a personal-focus standing project. Lives at `gtd/projects/{slug}/`.

## Folder structure (8-item, per per-project-accounting rule)

```
gtd/projects/{slug}/
  _brief.md       # Purpose, Principles, Outcome, Vision (POBO output)
  _status.md      # Current phase, next action, open items, last_updated
  plan.md         # POBO plan snapshot — phases + intended steps
  notes/          # running captures
  reference/      # source material
  specs/          # build specs
  deliverables/   # final outputs
  _archive/       # retired material
```

Code projects add a 9th item: `repo/`.

## Frontmatter on `_brief.md`

```yaml
---
type: project
status: active                              # active | archived | someday
expected-cadence: biweekly                  # weekly | biweekly | monthly | none
last-touched: 2026-04-26
source: "[[...]]"                           # how this project came into being
created: 2026-04-26
last_updated: 2026-04-26
author: claude | operator
---
```

`expected-cadence: none` disables stale-context checks. Default `biweekly`.

## Lifecycle

- Created via `/pobo` (full) or `/pobo --lite` (3-field stub)
- `_brief.md` immutable once written; updates flow through `_status.md`
- Archive: `mv gtd/projects/{slug} gtd/archive/projects/{year}/{slug}` — agent rewrites inbound `parent:` links in same operation

## Detection

`[REVIEW]` to propose creation when:
- An action created two sessions in a row carries the same parent intention (e.g., "draft proposal for Acme") — propose promotion to project via `/promote-to-project`
- Operator says "I want to start working on X" and X is multi-session

## Matching

- New `_brief.md` written → emit `project-created` event
- Status changes update only `_status.md`, never `_brief.md`
- POBO `plan.md` updates increment `last_updated`
