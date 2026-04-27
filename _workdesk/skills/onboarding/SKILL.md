---
name: onboarding
description: Six-phase guided orientation for a freshly bootstrapped vault. Captures the operator's role mix, scaffolds active contexts, detects optional tools, generates the first daily plan, and graduates to normal use. Idempotent and resumable. Sub-commands --status, --restart, --update-profile.
---

# /onboarding

V1 onboarding is six phases, each writing results as it goes. If interrupted, partial work is preserved and resuming picks up at the first non-`complete` phase. Self-sufficient — videos optional.

## Sub-commands

- `/onboarding` — resume from incomplete phase, or run full flow first time
- `/onboarding --status` — show what's been configured
- `/onboarding --restart` — wipe `_workdesk/onboarding-state.md` with confirmation; vault content untouched
- `/onboarding --update-profile` — interactive profile edit (post-graduation safe)

## Detection

Run proactively when:
- `_workdesk/onboarding-state.md` exists with any phase still `pending` or `incomplete`
- AND operator has not dismissed onboarding this session

Confirmation guard: running `/onboarding` after graduation says: *"Onboarding complete. Use --restart to redo everything (vault content is safe), or --update-profile to adjust role mix."*

## Phases

### 1. Environment check

Read `_workdesk/state/doctor.md`. If `result: pass` is not present or `last-run` is older than the current session, pause and instruct operator to run `/workdesk-doctor` first. No questions yet.

Confirm `_workdesk/` resolves and report what's already in place. Read-only.

Mark phase `complete` in `_workdesk/onboarding-state.md`.

### 2. Role map

Capture mixed-persona profile.

> *"Which of these describe how you spend your time? Pick one or more — order matters for daily-plan tonality."*

Options: `consultant`, `founder`, `employee`, `researcher`, `creative`, `parent`, `personal`.

Write `_workdesk/operator-profile.md` `role-mix:` and `name:` (also ask for name). No JTBD interview yet.

Mark phase `complete`.

### 3. Context setup

Always: create `atlas/areas/` instances based on the role mix. Examples by role:
- consultant → `atlas/areas/finance/`, `atlas/areas/pipeline/`, `atlas/areas/health/`
- founder → `atlas/areas/hiring/`, `atlas/areas/runway/`, `atlas/areas/ops/`
- employee → `atlas/areas/role/`, `atlas/areas/career/`
- researcher → `atlas/areas/methods/`, `atlas/areas/teaching/`
- creative → `atlas/areas/studio/`, `atlas/areas/audience/`
- parent → `atlas/areas/household/`, `atlas/areas/family/`, `atlas/areas/health/`

Ask: *"Want to scaffold these areas? You can skip any."* Operator confirms or skips per item.

Optional engagement containers per role mix (per the role-map prompt table in the plan):
- consultant → `atlas/clients/`
- founder → `atlas/businesses/`
- employee → `atlas/teams/` or `atlas/departments/`
- researcher → `atlas/labs/` or `atlas/collaborations/`
- creative → `atlas/disciplines/` (or user-named)

Operator picks zero or more. For each chosen container, ask for one initial instance name to seed (or skip seeding).

Each new `_brief.md` uses the 4-item structure (areas/engagements) or 8-item (initiatives — not created here). Frontmatter sets `expected-cadence` defaults, `last-touched` to today.

Update `operator-profile.md` `primary-contexts.engagements` and `primary-contexts.areas` with canonical `_brief.md` wikilinks.

Mark phase `complete`.

### 4. Tool setup

Detect and verify optional connectors. For each:

- **Granola** — check `~/Library/Application Support/com.granola.app/` exists; smoke test = list folder
- **Google Workspace (`gws`)** — `command -v gws` + `gws auth status`
- **qmd** — `command -v qmd` + `qmd status`
- **Defuddle** — `command -v defuddle` + parse a known-good URL
- **Codex CLI** — `command -v codex`

For each: present, run smoke test, record result in `enabled-tools`. Missing tools never block — they degrade the signals that depend on them.

Mark phase `complete`.

### 5. First daily plan

Generate `intel/briefings/daily/{today}-daily-plan.md` from whatever data exists:
- **Rich data** path: full plan via daily-plan signal anchors
- **Sparse data** path: 7-step fallback chain
- **Cold start** path: setup-oriented plan ("Nothing scheduled. First steps: …")

Update `_workdesk/state/signals.json` `daily-plan.last-fired` to today.

Mark phase `complete`.

### 6. Graduation

Two-action close:

> *"Use the daily-plan tomorrow morning. Run `/weekly-review` at end of week."*

Set `vault-improvements.suppressed-until` in `_workdesk/state/signals.json` to `today + 14 days`. Tell the operator the system will start surfacing improvement proposals in 2 weeks.

Mark phase `complete`. Emit final summary.

## Output

- Areas + engagement containers created (paths)
- Tools detected (names)
- Daily plan path
- Suppression date for vault-improvements
- Next two suggested actions

## What NOT to do

- Don't skip Phase 1. Doctor must pass first.
- Don't scaffold areas/containers the operator declined. Idempotent re-runs respect prior choices.
- Don't write to `personal/`. The lock is hard.
- Don't fabricate contexts — if operator says "I'll add later", leave gaps and continue.
- Don't auto-trigger meta-skills during onboarding except for the area/container scaffolds described above.
