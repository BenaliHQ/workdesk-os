# Upstream — `workdesk-terminal`

**Name:** WorkDesk Terminal
**Source:** https://github.com/BenaliHQ/workdesk-terminal
**Tag pinned:** `v1.1.2`
**Release URL:** https://github.com/BenaliHQ/workdesk-terminal/releases/tag/v1.1.2
**License:** MIT (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `1.1.2`
**minAppVersion:** `0.15.0`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `749540db26490870df2853996337e7f9c61c5f1bd4ca7a1725f043676cffeb4e` |
| `manifest.json` | `1dad06537b0d3e730ca5834bcf9c45dc2e8db234e385fd33b279e004a0093787` |
| `styles.css` | `4d8af4512900100544d10a1809e9fcca62242beeeee32f93cfb10a4c74da8c2a` |

The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/workdesk-terminal/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/BenaliHQ/workdesk-terminal/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

Metadata-only fork of `internetvin/internetvin-terminal` v1.1.2, created 2026-04-28. Zero behavior changes from upstream. This is the **only plugin BRAT actively manages** — new `BenaliHQ/workdesk-terminal` releases flow to operators on next Obsidian launch via BRAT `updateAtStartup`. Iteration loop documented at [[specs/workdesk-init]] §Iteration loop for workdesk-terminal.
