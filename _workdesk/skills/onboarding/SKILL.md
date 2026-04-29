---
name: onboarding
description: Six-phase guided orientation for a freshly bootstrapped vault. Captures the operator's role mix, scaffolds active contexts, detects optional tools, generates the first daily plan, and graduates to normal use. Idempotent and resumable. Sub-commands --status, --restart, --update-profile.
---

# /onboarding

V1 onboarding is six phases, each writing results as it goes. If interrupted, partial work is preserved and resuming picks up at the first non-`complete` phase. Self-sufficient — videos optional.

## Style — pacing and tone

This is a guided conversation, not a form. Hard rules:

- **One question per turn.** Ask one thing, wait for the answer, then ask the next. Never stack two questions in one message.
- **Snappy.** Short sentences. Plain words. No bureaucratic preambles ("I need your input here", "Question 1 —", baseline status dumps).
- **Frame each phase in one line before the first question.** Not three paragraphs. One line. Then the question.
- **Back-and-forth pace.** Treat it like a chat with someone next to you, not a wizard form.
- **Do not pre-fill answers from external context.** If you can see the operator's name or context from `~/.claude/CLAUDE.md`, an env var, the vault path, or anywhere else outside the onboarding flow itself — ignore it for the purpose of asking. Ask the question fresh. Operators will tell you if they want to short-circuit ("yeah, that's me"). Inferring up front feels presumptuous and breaks trust on the first interaction.
- **No baseline-state dumps before questions.** Don't list what's already in `atlas/` or what doctor returned before asking the next question. The operator doesn't need a status report; they need the next step.
- **Explain just-in-time.** When a phase introduces a new concept (engagement, area, signal, source), give a one-sentence explanation right before the first question that depends on it. Not a glossary up front.

### Opener

The very first message of a fresh `/onboarding` session is a single short paragraph:

> *"Let's get your WorkDesk set up. Six quick phases — environment check, your role, your contexts, optional tools, your first daily plan, then we're done. I'll walk you through one step at a time. Ready?"*

Wait for the operator to say go (or anything affirmative). Then start Phase 1. If they decline, say "Run `/onboarding` whenever you're ready" and stop.

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

Frame in one line, then ask one question at a time. Two questions in this phase: name, then role mix. Do not ask both at once.

**Frame:**

> *"Phase 2: I'll learn a little about how you work so the daily plan feels right."*

**Q1 — name:**

> *"What name should I use in your daily plans and briefings?"*

Wait for answer. Do not proceed until you have a name. Do not pull a name from `~/.claude/CLAUDE.md`, vault path, git config, or anywhere else.

**Q2 — role mix.** Once you have the name, send a separate message:

> *"How do you mostly spend your time? Pick one or more, and put them in order — the first one shapes the tone of your daily plan."*
>
> *"Options: consultant, founder, employee, researcher, creative, parent, personal."*

Wait for answer. If the operator gives a single role, accept it. If they list several, accept the order they gave.

**Confirm and write:**

> *"Got it — [name], [role-mix]. Saving that now."*

Write `_workdesk/operator-profile.md` with `name:` and `role-mix:`. No JTBD interview yet.

Mark phase `complete`.

### 3. Context setup

Two ideas in this phase: **areas** (ongoing parts of life/work) and **engagements** (specific people/orgs/clients you work with). Explain one at a time, just before asking. Do not dump both glossaries up front.

**Frame:**

> *"Phase 3: let's set up your contexts — the things you'll come back to over and over."*

**Sub-step 3a — areas.** Send a message that explains "area" in one sentence, then asks once:

> *"An **area** is an ongoing part of your life or work that doesn't end — like finance, health, or your team. Based on your role mix I'd suggest these starter areas: [list 2–3 from the role-mix table below]. Want me to scaffold them? You can drop any you don't want, or add others."*

Role → suggested areas:
- consultant → `finance`, `pipeline`, `health`
- founder → `hiring`, `runway`, `ops`
- employee → `role`, `career`
- researcher → `methods`, `teaching`
- creative → `studio`, `audience`
- parent → `household`, `family`, `health`
- personal → no defaults; ask what areas matter to them

Wait for the operator to confirm/edit the list. Scaffold only what they confirm at `atlas/areas/<name>/_brief.md` with the 4-item structure.

**Sub-step 3b — engagements.** Once areas are done, send a separate message:

> *"An **engagement** is a specific relationship — a client, a business you run, a team you're part of. Different from areas: engagements have a shape (people, meetings, history). Based on your role mix you'd typically use [container, e.g. `atlas/clients/` for consultants]. Want to set this up now? You can also skip and add later."*

Role → suggested container:
- consultant → `atlas/clients/`
- founder → `atlas/businesses/`
- employee → `atlas/teams/` or `atlas/departments/`
- researcher → `atlas/labs/` or `atlas/collaborations/`
- creative → `atlas/disciplines/` (or user-named)

If they skip, mark and move on. If they want to set it up, ask for **one** starter instance name (not a list — one). Scaffold that one. If they want more after, they can do another now or do it later.

Each new `_brief.md` uses the 4-item structure. Frontmatter sets `expected-cadence` defaults, `last-touched` to today.

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

**Do not invoke `/daily-ops` or `/weekly-review`.** Onboarding produces a minimal first-day plan inline. The full daily-plan signal pipeline is a post-onboarding skill the operator runs themselves tomorrow morning.

**Frame:**

> *"Phase 5: I'll drop a simple plan in `intel/briefings/daily/` so you can see where they live. Tomorrow you'll run `/daily-ops morning` to get the real one."*

Write `intel/briefings/daily/{today}-daily-plan.md` as a short cold-start-style plan: a single section "Getting started with WorkDesk" listing the 2–3 most useful next actions for a fresh vault (e.g., "open today's daily note in `personal/daily/`", "explore `atlas/`"). No calendar, no email, no signal anchors — those depend on tools we haven't wired and skills we shouldn't invoke yet.

Update `_workdesk/state/signals.json` `daily-plan.last-fired` to today.

Mark phase `complete`.

### 6. Graduation

Snappy wrap. One short message.

> *"You're set up. Tomorrow morning, run `/daily-ops morning` for your real daily plan. End of the week, try `/weekly-review`. I'll start surfacing vault-improvement suggestions in two weeks."*

Do not run those skills now — just point at them.

Set `vault-improvements.suppressed-until` in `_workdesk/state/signals.json` to `today + 14 days`.

Mark phase `complete`. Emit a short final summary (areas + engagements created, tools enabled, daily plan path, suppression date). Three lines max.

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
- Don't invoke `/daily-ops` or `/weekly-review` during the flow. Phase 5 produces a minimal cold-start plan inline; Phase 6 only points at those skills for the operator to run themselves later.
- Don't stack questions. One question per turn, always. If you're about to write "Question 1 — ... Question 2 — ..." in a single message, stop and split it.
- Don't dump baseline state ("atlas/ has X, Y, Z. Doctor green.") before asking the next question. The operator doesn't need a status report between steps.
- Don't pre-fill answers from external context (CLAUDE.md, env vars, vault path, git config). Ask the question fresh.
