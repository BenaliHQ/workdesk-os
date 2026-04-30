---
name: ""
role: ""
work-mode: ""
daily-planning-style: "morning"
week-start: "monday"
first-30-days-mode: active
created: ""
last_updated: ""
version: 1.1
---

# Operator Profile

This file is populated by `/onboarding`. It captures the operator's role, work mode, areas of focus, and tools in use. Signals (daily-plan, weekly-review, vault-improvements) read this file to scope and tone their output.

Edit directly, or run `/onboarding --update-profile` to walk through changes interactively.

## Role

Free-text description of what the operator does — populated by Q2 in `/onboarding`. Examples are illustrative, not categorical. The `role:` and `work-mode:` frontmatter fields drive tonality choices in `/daily-ops`.

## Work mode

Free-text description of how the operator's days look (heavy meetings, deep-work, mixed, etc.) — populated by Q3 in `/onboarding`.

## Areas of focus

Durable areas the operator focuses on — domains (finance, ops, design), topics, or kinds of work. Populated by Q4 in `/onboarding`. Listed in the body, not in frontmatter.

## Tools in use

Wikilinks to `_workdesk/tools/<slug>.md` for each tool the operator named in onboarding. New tools are added via `/define-tool`, which writes a tool note and updates this section. Tool notes track connection state separately (`connected: true|false`).

## first-30-days-mode

`active` during the guided first 14 days. Flips to `graduated` once: onboarding complete + ≥1 weekly-review generated + at least one of (project, recurring item, processed transcript) exists. Set by `/weekly-review` graduation check.
