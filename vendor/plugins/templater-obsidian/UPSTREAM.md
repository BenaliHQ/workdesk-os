# Upstream — `templater-obsidian`

**Name:** Templater
**Source:** https://github.com/SilentVoid13/Templater
**Tag pinned:** `2.19.3`
**Release URL:** https://github.com/SilentVoid13/Templater/releases/tag/2.19.3
**License:** AGPL-3.0 (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `2.19.3`
**minAppVersion:** `1.12.2`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `4727fcbadd91d6c5097727b4c16d531f590a379659dcd817fdef9be9d3786b98` |
| `manifest.json` | `37c5715b07f5edaddbb2e8e5a7e88cdbe0885f9e1c11e168db396f5987bd07b6` |
| `styles.css` | `f7d4ee5bd4ec1d032eda1f4e1da481e713c57af964ec1e55d31494f086068d1e` |

The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/templater-obsidian/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/SilentVoid13/Templater/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

AGPL-3.0 license. We vendor the unmodified release artifacts; we do not modify or fork. Distribution alongside MIT-licensed workdesk-os is permitted under AGPL §10 (each component remains under its own license).
