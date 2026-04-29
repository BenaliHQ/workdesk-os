# Upstream — `obsidian-minimal-settings`

**Name:** Minimal Theme Settings
**Source:** https://github.com/kepano/obsidian-minimal-settings
**Tag pinned:** `8.2.2`
**Release URL:** https://github.com/kepano/obsidian-minimal-settings/releases/tag/8.2.2
**License:** MIT (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `8.2.2`
**minAppVersion:** `1.11.1`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `8aa9350977fca098f56cea444eb672942e10fcaeb9b07aceb05a3d5368aa742b` |
| `manifest.json` | `cc07b2a08a2128acab9f678f2fdc1a0492b370be928d6ddfb1df1ae4b376667a` |
| `styles.css` | `50084760da927a5bf5ac1b9d3b960dc52e1d0a3bf690e54df8f4d76f8212628c` |

The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/obsidian-minimal-settings/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/kepano/obsidian-minimal-settings/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

Configures the Minimal theme. The Minimal theme itself (kepano/obsidian-minimal) is not vendored here — it is installed during `/onboarding` (Phase B). Until the theme is present, this plugin loads but has no visible effect.
