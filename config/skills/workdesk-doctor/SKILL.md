---
name: workdesk-doctor
description: Verifies WorkDesk OS runtime behavior (hooks, locks, latency, session-end export) that filesystem self-check cannot see. Run on first Claude Code session after bootstrap, and any time something feels off. Onboarding pauses until doctor passes.
---

# /workdesk-doctor

Bootstrap is filesystem-only. Doctor proves runtime. Run after every bootstrap, after every `config/settings.json` edit, and any time a hook seems wrong.

## When to run

- First Claude Code session after bootstrap
- After editing `config/settings.json` or any hook script
- When `/onboarding` reports an environment-check failure
- Any time a hook fires unexpectedly or doesn't fire when expected

## Phases

### 1. PreToolUse personal-lock

Probe the hook by attempting deniable operations against `personal/`:

- Try `Write` to `personal/_doctor-probe.md` → must be denied
- Try `Edit` to an existing file under `personal/` → must be denied (skip if no file exists)
- Try `MultiEdit` to a path under `personal/` → must be denied
- Try `Bash mv personal/_doctor-probe.md /tmp/` → must be denied
- Try `Bash echo hi >> personal/test.md` → must be denied
- Try `Bash tee personal/test.md` → must be denied

Each probe expects an explicit `permissionDecision: deny` from the hook. Record which probes passed.

### 2. PostToolUse semantic logging

Write a synthetic atlas note (e.g., `atlas/meetings/_doctor-probe.md`) and verify:

- `system/events/{YYYY-MM}.md` gains an `object-created` line
- The line includes the timestamp, event class, target, and result

Then delete the probe and the event line.

### 3. SessionStart scan

Read `config/state/session-entry.md`. Verify it was written within the last 5 minutes (proof the hook fired this session). If absent or stale, the hook is broken or `config/settings.json` is misconfigured.

### 4. SessionEnd vs Stop fallback

Decide which raw session-log path is active. Procedure:

- Look in `system/session-log/` for `*-raw.md` files written in the last 24 hours
- Count files per `session_id`
- If multiple files share a `session_id` and any has `complete: false`, `Stop` upsert mode is active — write `config/state/doctor.md` with `stop-fallback: enabled`
- If files appear only at session end with `complete: true`, `SessionEnd` is active — write `stop-fallback: disabled`

### 5. Hook latency

Run `config/scripts/bench-hooks.sh`. Record p95 and the budget check. If p95 exceeds the 50ms budget, record it as a warning — do NOT fail the overall doctor run. Hook latency is a perf signal, not a correctness invariant; cold-cache first runs can exceed the budget without any user-visible problem.

### 6. Session-entry intake scan

Confirm `config/state/session-entry.md` reflects current `system/transcripts/`, `system/intake/`, and `system/session-log/` reality:

- Drop a synthetic `system/transcripts/_doctor-probe.md` with `processed: false`
- Trigger a fresh scan (re-source the script directly, since you're already in-session)
- Verify the probe shows up in `unprocessed.transcripts`
- Delete the probe

## Output

Write `config/state/doctor.md`:

```yaml
---
last-run: 2026-04-26 09:30
result: pass | fail | partial
checks:
  pre-tool-use-personal-lock: pass | fail
  post-tool-use-event-log: pass | fail
  session-start-scan: pass | fail
  session-end-or-stop-fallback: SessionEnd | Stop
  hook-latency-p95-ms: 12
  session-entry-intake-scan: pass | fail
stop-fallback: enabled | disabled
---
```

Then summarize in chat:
- Pass: "Runtime green." (One line. Don't suggest the next skill — `/onboarding` invokes doctor inline; standalone doctor runs are diagnostic, not handoffs.)
- Fail: list each failed check with the exact repair command. Pause until operator reruns.

## What NOT to do

- Don't proceed past a fail. Failed runtime is the whole point of this skill.
- Don't summarize without writing `config/state/doctor.md` — onboarding reads that file.
- Don't run probes that mutate operator content. Use `_doctor-probe` files only and clean up after.
