# Upstream — `periodic-notes`

**Name:** Periodic Notes
**Source:** https://github.com/liamcain/obsidian-periodic-notes
**Tag pinned:** `0.0.17`
**Release URL:** https://github.com/liamcain/obsidian-periodic-notes/releases/tag/0.0.17
**License:** MIT (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `0.0.17`
**minAppVersion:** `0.10.11`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `ccf1a18673693d1036fc7614c3af9d23e5edfe425d1053df81dddcc29b1f8b0e` |
| `manifest.json` | `bda29323f75d3b3fcbda489335825b97fe4b574914d04635e9a7e67f2414049c` |
| `styles.css` | `613f3985d4c84900ed2e25d8a46efb7b3ace6889fb71217055084084eb146238` |

The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/periodic-notes/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/liamcain/obsidian-periodic-notes/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

Pinned to `0.0.17` (stable, 2021-09-16) rather than `1.0.0-beta.3` because the beta tag's `manifest.json` still declares `"version": "0.0.17"` upstream — the author never bumped it. Pinning to the beta tag would cause manifest/tag-version mismatch and confuse downstream consumers (BRAT, /workdesk-doctor, support). Revisit when upstream cuts a manifest-correct release.
