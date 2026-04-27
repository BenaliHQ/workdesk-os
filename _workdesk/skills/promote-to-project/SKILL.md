---
name: promote-to-project
description: Upgrade an action in gtd/actions/next/ into a full project folder under gtd/projects/ (or initiative under atlas/initiatives/ if it has an engagement/area parent). Re-runs the relevant POBO phases minimally and rewrites references.
---

# /promote-to-project

The "default to action" rule says: when ambiguous, create an action; promote later if it earns it. This skill is the promotion path.

## Invocation

- `/promote-to-project {action-slug}` — promote a specific action
- `/promote-to-project --auto` — scan `gtd/actions/next/` for actions older than 14 days with multiple touch events; propose candidates

## Phases

### 1. Read the action

Read `gtd/actions/next/{slug}.md`. Note `parent:`, `source:`, body description.

### 2. Decide target

- `parent:` resolves to an engagement (`atlas/clients/`, `atlas/businesses/`, etc.) or an area → target is `atlas/initiatives/{slug}/`
- `parent:` empty or another project → target is `gtd/projects/{slug}/`

### 3. Run mini-POBO

Walk the operator through a compressed POBO:

- **Outcome** — what does success look like? (Carry over from action body if explicit.)
- **Principles** — any non-negotiables? (May be empty.)
- **Brainstorm** — what else needs to happen beyond the next action?
- **Organize** — what are the 2-5 phases? Which is current?

Confirm whether to use `--lite` shape (3 fields only) or full POBO.

### 4. Scaffold

Create the 8-item folder. Populate `_brief.md`, `_status.md`, `plan.md` from the mini-POBO output. The promoted action is the current next action; carry it into `_status.md`.

Frontmatter on `_brief.md`:
- For projects: `expected-cadence: biweekly`
- For initiatives: `expected-cadence: weekly`, `engagement:` or `area:` populated

### 5. Rewrite the original action

The original `gtd/actions/next/{slug}.md` becomes a child of the new project/initiative:
- Update `parent:` to point at the new `_brief.md`
- Keep `source:` as-is

### 6. Rewrite inbound references

Find any other notes referencing the original action via `[[...]]` and update them to reference the new `_brief.md` if the original meaning was "the project this action belongs to" rather than "this specific action." Operator confirms ambiguous cases.

### 7. Log

Hooks fire `project-created` (or `initiative-created`) automatically. No manual logging.

## What NOT to do

- Don't promote actions younger than ~7 days unless the operator explicitly asks. The default-to-action principle is intentional.
- Don't drop the original action. The promoted action is the project's first next action.
- Don't skip the parent test. If parent is engagement/area, target is initiatives, not projects.
