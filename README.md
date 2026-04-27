# WorkDesk OS

A giveable Obsidian + Claude Code working surface for knowledge work with AI.

WorkDesk OS turns a fresh vault into a five-zone, agent-guided system that captures your work, surfaces signal, and keeps up with your life. You experience it as furniture — not an application.

> **V1 status.** Mac-only. Greenfield (empty vault) only. The vault content architecture is OS-agnostic; only the install/runtime layer is Mac-specific.

## What ships

**Five zones.** Each zone manages one unit type and has one job.

| Zone | Unit | Job | Agent writes? |
|---|---|---|---|
| `personal/` | practice | Practice management (journal, daily, reading) | Never — read-only |
| `atlas/` | object | Object management — single-source identified | Yes |
| `gtd/` | action | Action management — projects, actions, inbox | Yes |
| `intel/` | signal | Signal management — multi-source synthesis | Yes |
| `system/` | source | Source management — raw inputs + activity infra | Yes (hooks) |

**Six meta-skills** for extending the system without code: `/define-object`, `/define-signal`, `/define-source`, `/define-practice`, `/define-tool`, `/define-rule`.

**Three pre-built signals.** `daily-plan` (rich → sparse → cold-start fallback), `weekly-review` (mandatory, active week 1), `vault-improvements` (suppressed first 14 days).

**Eleven semantic event classes** logged via a `PostToolUse` hook to monthly event files in `system/events/{YYYY-MM}.md`.

**Codex rescue** — vault is plain markdown, model-portable. If Claude is down, `/codex-rescue` packages context for OpenAI Codex CLI.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/BenaliHQ/workdesk-os/main/bootstrap.sh -o bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh /path/to/empty-vault
```

Or clone and run locally:

```bash
git clone https://github.com/BenaliHQ/workdesk-os.git
cd workdesk-os
./bootstrap.sh /path/to/empty-vault
```

The vault must be empty (`.obsidian/`, `.git/`, `.DS_Store`, `.gitignore`, and a single empty `README.md` are tolerated). V1 refuses to install over existing content; V2 ships a `/migrate` skill.

## First session

```bash
cd /path/to/empty-vault
claude
```

Then:

1. `/workdesk-doctor` — verifies hooks, locks, and runtime behavior
2. `/onboarding` — six phases, ~10 minutes, captures your role mix
3. `/daily-ops` — first daily plan
4. `/weekly-review` at end of week 1

## Architecture

| Layer | What | Where |
|---|---|---|
| **Vault content** | Your work | `personal/` `atlas/` `gtd/` `intel/` `system/` |
| **Control plane** | Declarations, scripts, hooks | `_workdesk/` (visible) + `.claude` (symlink) |
| **Skills** | Workflow entry points | `_workdesk/skills/` |
| **Rules** | Hard constraints | `_workdesk/rules/` |
| **Declarations** | Object/signal/source/practice/tool definitions | `_workdesk/{objects,signals,sources,practices,tools}/` |

The `_workdesk/` directory is the visible source of truth. Claude Code reads through `.claude/` (a symlink) for tool compatibility.

## Extending

Six meta-skills cover everything you'll add over time. Each scaffolds a declaration and creates the corresponding vault folder when needed. Each carries a **detection clause** — a deterministic rule for when Claude should propose creating something, not just when you ask.

| Skill | Scaffolds |
|---|---|
| `/define-object` | Atlas content types (book, vendor, deal, anything structured) |
| `/define-signal` | Intel signal types (briefings, observations) |
| `/define-source` | System source types (bookmark, screenshot, ocr) |
| `/define-practice` | Personal practice types (journal, reading log) |
| `/define-tool` | Claude capabilities (CLI, API, MCP server) |
| `/define-rule` | Behavioral constraints |

`/define-skill`, `/define-agent`, `/define-zone` are explicitly **not** in V1.

## Resilience

- **Codex rescue** — vault content is plain markdown, fully portable. `/codex-rescue` hands the active task to OpenAI Codex with full context.
- **Sparse-data daily-plan** — useful output even with no calendar, no transcripts, three manual notes.
- **Hook fallbacks** — `/workdesk-doctor` chooses `SessionEnd` (preferred) or `Stop` (upserted, one file per session_id) for raw transcript export.

## License

MIT. Fork it, ship it, make it yours.

## Source

Plan: [BenaliHQ/workdesk-os-internal/plans/workdesk-os-v1.md](https://github.com/BenaliHQ/workdesk-os-internal). Codex variant: [BenaliHQ/workdesk-os-codex](https://github.com/BenaliHQ/workdesk-os-codex).
