---
name: codex-rescue
description: When Claude is unavailable, hits a hard block, or repeatedly fails the same task, hand it to OpenAI Codex CLI with full vault context. Vault is plain markdown — model-portable. Use after 2+ failed attempts, on persistent API errors, or when the operator says "ask Codex".
---

# /codex-rescue

The vault is model-portable. If Claude can't finish, Codex can.

## When to run

- Claude has attempted the same task ≥2 times and produced incorrect or incomplete output
- An Anthropic API error persists across retries
- Operator says "consult Codex", "second opinion", "ask Codex"
- A long investigation has stalled

## Prerequisites

- Codex CLI installed: `npm install -g @openai/codex`
- `OPENAI_API_KEY` available (in `.env` or env)
- Codex authenticated: `codex login`

If anything missing, prompt the operator. Don't fail silently.

## Phases

### 1. Capture state

Write `system/intake/codex-rescue-{YYYY-MM-DD-HH-MM}.md`:

```markdown
---
type: source
source-kind: intake
date: 2026-04-26
processed: false
---

# Codex Rescue Brief

## What we're trying to do
{operator's most recent ask + the original task}

## What's been attempted
- {attempt 1: approach + outcome}
- {attempt 2: approach + outcome}

## Files touched
- {path 1} — {purpose}

## Where we got stuck
{specific failure mode, error message, or unanswered question}

## Success criteria
{operator's bar for "done"}

## Vault context
- Project: `{project-path}` (if applicable)
- Spec: `{spec-path}` (if applicable)
- Relevant rules: {list}
```

### 2. Hand off

Run Codex with the brief as context:

```bash
codex --cd $CLAUDE_PROJECT_DIR exec "$(cat system/intake/codex-rescue-...md)"
```

Or interactive:

```bash
codex --cd $CLAUDE_PROJECT_DIR
```

Stay in the loop — summarize Codex's output back into the conversation.

### 3. Verify

When Codex returns:
- Read the output. Does it meet success criteria?
- Run any tests, lint, or verification the spec requires.
- If good, apply it. If not, decide: another Codex iteration, escalate to operator, or back to Claude.

### 4. Log

The hook fires `source-processed` when the brief flips `processed: true`. Manual log entry not required.

## Output

- Brief path
- Codex result, summarized
- Whether result was applied, and to which files
- Next action if Codex didn't resolve

## What NOT to do

- Don't run Codex without writing the brief. Codex with no context is just another stuck model.
- Don't apply Codex output without reading it.
- Don't loop forever. After 2 Codex passes that don't resolve, escalate to operator.
- Don't strip vault context from the brief. Codex needs to see the rules and project state.
