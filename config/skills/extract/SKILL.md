---
name: extract
description: Two modes. Default — log the current Claude Code session to system/session-log/ as a structured summary. With --summarize {raw-file} — convert a hook-exported raw session-log file into the final summary note. Either mode preserves the raw conversation alongside the summary.
---

# /extract

Run at the end of any meaningful session — or on a backlog of unsummarized raw files surfaced by session-entry scan.

## Invocation

- `/extract` — summarize the **current** session in-flight (interactive mode)
- `/extract --summarize {raw-file}` — summarize a hook-exported raw file
- `/extract --auto` — summarize the most recent unsummarized raw file in `system/session-log/`

## Mode 1 — current session (`/extract`)

For when the operator wants to log this session before closing.

Produce `system/session-log/{YYYY-MM-DD}-{topic-slug}.md`:

```yaml
---
type: session-log
date: 2026-04-26
duration: ~{minutes} min
source: "operator-instruction"
session-id: ""              # if known; populated by hook in --summarize mode
---

# Summary
[3-5 sentences. Wikilink-able. What happened, decided, changed.]

# Decisions
- [List of decisions with wikilinks where they got their own note]

# Files changed
- [Bullet list of paths touched]

# Promotion candidate?
[If the session produced framework-shaped, cross-applicable, durable synthesis, prompt: "Promote section X to intel/research/?"]
```

## Mode 2 — summarize a raw file (`/extract --summarize {path}`)

For raw files written by `session-end-session-dump.sh` or `stop-session-snapshot.sh`.

1. Read the raw file. Verify `summarized: false`.
2. Read `transcript-path` and re-extract conversation if needed for fidelity.
3. Write summary to `system/session-log/{YYYY-MM-DD}-{topic-slug}.md` with the format above; preserve the raw file's `session-id`.
4. Flip the raw file's frontmatter: `summarized: true`, append summary path to `processed-into:`.

## Promote-to-wiki prompt

If the session synthesis meets all three:
- framework-shaped (named, applicable beyond this session)
- cross-applicable (relevant to ≥2 contexts)
- durable (still useful 90 days from now)

Then prompt: *"This synthesis looks promotable. Want me to extract section X to `intel/research/{slug}.md`?"*

Operator approves, dismisses, or redirects.

## Sources contract

Per `source-documentation` rule:
- `--summarize` mode: `source:` points at the raw file (`[[system/session-log/...-raw]]`)
- live mode: `source:` is `"operator-instruction, {date}"`

## What NOT to do

- Don't omit the conversation section. Verbatim record is part of the value.
- Don't promote without confirmation. Promotion candidates are proposed, not shipped.
- Don't fabricate a session topic. If unclear, ask the operator for a slug.
