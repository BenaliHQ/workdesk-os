# Obsidian Defaults

Canonical `.obsidian/` configuration shipped with WorkDesk OS. Bootstrap and `/update` write these files into the operator's vault `.obsidian/` directory so the daily-note flow works on first launch without any manual settings.

## Files

- `core-plugins.json` — enables core plugins WorkDesk OS depends on (notably `daily-notes`).
- `daily-notes.json` — points the core Daily Notes plugin at the canonical folder, format, and template.
- `plugins/templater-obsidian/data.json` — Templater settings: folder template for `personal/daily` so the daily-note template resolves on file creation.

## How they apply

- **New vaults (bootstrap):** files copied into `.obsidian/` before Obsidian first opens. Plugins read fresh config on first load.
- **Existing vaults (`/update`):** files written into `.obsidian/`. Takes effect on the next natural Obsidian launch — no toggle, no restart prompt, no startup script.

## Why no in-process repair

Forcing config refresh inside a running Obsidian instance requires either an app restart (kills the embedded Claude Code terminal) or a Templater startup hack. Both add complexity. Writing files and waiting for the next natural launch is simpler and applies the next time the operator opens Obsidian normally.

## Updating

If the canonical config changes, update the file here and bump the relevant skill (`/update`, `/workdesk-doctor`) to reflect the new schema. The doctor diffs vault `.obsidian/*` against this directory and surfaces drift.
