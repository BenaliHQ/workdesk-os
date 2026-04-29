# Upstream — `custom-sort`

**Name:** Custom File Explorer Sorting
**Source:** https://github.com/SebastianMC/obsidian-custom-sort
**Tag pinned:** `3.1.6`
**Release URL:** https://github.com/SebastianMC/obsidian-custom-sort/releases/tag/3.1.6
**License:** GPL-3.0 (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `3.1.6`
**minAppVersion:** `1.7.2`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `8a5c9e8b153c65b717656ed11a9ba9d1022066404157ac2b33a32691bbecb943` |
| `manifest.json` | `4fdc25619e4d258bbca447efa54da902aa38ee24c1e39108b7ef1a4beb28ad88` |


The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/custom-sort/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/SebastianMC/obsidian-custom-sort/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

No `styles.css` shipped in upstream release.
