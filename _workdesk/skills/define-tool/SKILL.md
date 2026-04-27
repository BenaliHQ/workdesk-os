---
name: define-tool
description: Meta-skill — scaffold a new tool integration (CLI binary, MCP server, or HTTP API) so Claude can use it. Installs it, writes a tool reference, registers it in the operator profile's enabled-tools, and verifies via smoke test.
---

# /define-tool

Tools are how Claude reaches outside the vault. Defining a tool installs it (when possible), documents it, and wires it into the system.

## Detection clause

Surface proactively when:
- A workflow has failed ≥2 times in 14 days because of missing capability ("I can't read your Slack" recurring)
- The operator pastes data manually that a tool could fetch (calendar events, emails, transcripts)

Ask: *"You've pasted {data type} from {source} a few times this week. Want to wire it up so I can fetch it directly?"*

## JTBD-first interview

1. **What tool?** Name + purpose — the capability gap it fills.
2. **How does Claude reach it?** CLI binary, MCP server, or HTTP API.
3. **Authentication?** API key (where? always `.env`), OAuth, none.
4. **Common commands?** 5-10 most-used invocations with examples.
5. **Limitations?** What it can't do, what fails silently, what's flaky.
6. **Detection clause** — when should Claude propose using this tool proactively?

## Install

Pick install method based on tool type:

- **CLI** — Run install command (Homebrew, npm, pip, curl). Verify with `which {binary}`.
- **MCP** — Add entry to `.mcp.json` at vault root. Operator restarts Claude Code to load.
- **API** — Add key to `.env` (operator pastes; never commit). Confirm `.gitignore` includes `.env`.

If install fails, document the manual steps and surface to operator.

## Scaffold

Create `_workdesk/rules/tools/{name}.md` (matching the existing tool reference shape — see `_workdesk/rules/tools/obsidian-cli.md`):

```markdown
# {Tool Name} — Tool Reference

{One-paragraph description and when to use}

## Access Method

{CLI binary path / MCP server name / API base URL}

## Common Commands

| Command | What it does | Example |
|---|---|---|
| ... | ... | ... |

## Known Limitations

- ...

## Common Mistakes

- ...

## Authentication

{None / API key in .env / OAuth flow}

## Detection clause

{When Claude should propose using this tool proactively}
```

## Update operator-profile.md

Append the tool name to `enabled-tools:` if smoke test passed.

## Verify

Run a smoke test command from the reference. On success, log the install via PostToolUse hook (which fires on the tool reference write — `declaration-changed` event).

If smoke test fails, mark the tool as `pending` in `enabled-tools` with a comment explaining the failure.

## What NOT to do

- Don't commit secrets. `.env` only, `.gitignore` enforced.
- Don't write a tool reference for a tool that isn't installed and verified. Untested docs lie.
- Don't define a tool that overlaps an existing one — check `_workdesk/rules/tools/` first.
- Don't skip the detection clause. A tool nobody knows when to use is dead weight.
