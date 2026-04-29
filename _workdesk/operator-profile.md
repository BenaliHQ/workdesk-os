---
name: ""
role-mix: []
primary-contexts:
  engagements: []
  areas: []
enabled-tools: []
preferred-naming:
  engagements: "kebab-case"
  people: "first-last"
daily-planning-style: "morning"
week-start: "monday"
first-30-days-mode: active
created: ""
last_updated: ""
version: 1.0
---

# Operator Profile

This file is populated by `/onboarding`. It captures the operator's role mix, active contexts, enabled tools, and preferences. Signals (daily-plan, weekly-review, vault-improvements) read this file to scope and tone their output.

Edit directly, or run `/onboarding --update-profile` to walk through changes interactively.

## Role mix

`role-mix` is an ordered list. Order matters for tonality — the first role drives daily-plan voice. A user can be `[consultant, founder, parent]` simultaneously.

Allowed values (extend via convention, not enforcement):
- `consultant`
- `founder`
- `employee`
- `researcher`
- `creative`
- `parent`
- `personal`

## Primary contexts

- `engagements` — canonical `_brief.md` wikilinks to active engagement instances (clients, businesses, teams, labs, disciplines)
- `areas` — canonical `_brief.md` wikilinks to active `atlas/areas/*` instances

## Enabled tools

Detected and verified by `/onboarding` Phase 4. Missing tools never block — they just degrade signals that depend on them.

## first-30-days-mode

`active` during the guided first 14 days. Flips to `graduated` once: onboarding complete + ≥1 weekly-review generated + at least one of (project, recurring item, processed transcript) exists.
