# Upstream — `calendar`

**Name:** Calendar
**Source:** https://github.com/liamcain/obsidian-calendar-plugin
**Tag pinned:** `1.5.10`
**Release URL:** https://github.com/liamcain/obsidian-calendar-plugin/releases/tag/1.5.10
**License:** MIT (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `1.5.10`
**minAppVersion:** `0.9.11`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `7fb339e9cf9fdbe5a801fa2b8ab85b366b5b3777fbd193cbc8728bc27711d125` |
| `manifest.json` | `f3e9581338648512baa12d5b458490f7fd367918f7bdb6bd86171ce57be7d08b` |


The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/calendar/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/liamcain/obsidian-calendar-plugin/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

Last stable upstream release (2021-04-01). Plugin is in maintenance mode but widely used. No `styles.css` shipped.
