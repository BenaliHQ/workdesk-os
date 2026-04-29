# Upstream — `obsidian42-brat`

**Name:** BRAT (Beta Reviewers Auto-update Tool)
**Source:** https://github.com/TfTHacker/obsidian42-brat
**Tag pinned:** `2.0.4`
**Release URL:** https://github.com/TfTHacker/obsidian42-brat/releases/tag/2.0.4
**License:** MIT (preserved as `./LICENSE`)
**Retrieved:** 2026-04-28
**Manifest version:** `2.0.4`
**minAppVersion:** `1.11.4`

## Artifact SHA256

| File | sha256 |
|---|---|
| `main.js` | `377ca69a94d7450ce87505730f3f577698c7c2f6254ff48c983d76eb8cebfaa6` |
| `manifest.json` | `626401be774d374e87f6fc45630d79da28516ccc024059b9979edcf0cc3f41da` |
| `styles.css` | `aee502d367417d0975d83a9ccd4769d3d2af047ef9516241ae20b86a90debc30` |

The orchestrator (`init.sh`, per [[specs/workdesk-init]] r4.1) verifies each
artifact's SHA256 against this file before installing into
`<vault>/.obsidian/plugins/obsidian42-brat/`.

## Refresh procedure

1. Identify the new upstream tag.
2. Download `main.js`, `manifest.json`, and `styles.css` (when present)
   from `https://github.com/TfTHacker/obsidian42-brat/releases/download/<new-tag>/`.
3. Replace the files in this directory.
4. Recompute SHA256s with `shasum -a 256` and update the table above.
5. Update `Tag pinned`, `Release URL`, `Retrieved`, `Manifest version`,
   and `minAppVersion` fields.
6. Bump the workdesk-os tag if the install path's contract changed
   (e.g., minAppVersion increase forces an Obsidian-version bump in init.sh).

## Notes

Vendored alongside its **`data.json.fixture`**, generated from a real launch of BRAT v2.0.4 in a clean test vault per [[specs/workdesk-init]] r4.1 §BRAT data.json. The orchestrator copies the fixture to `<vault>/.obsidian/plugins/obsidian42-brat/data.json` after verifying the vendored manifest version is exactly `2.0.4`. Regenerating the fixture: see `data.json.fixture.README.md` in this directory.
