# BRAT `data.json` fixture — generation procedure

`data.json.fixture` is the seed value the orchestrator copies into
`<vault>/.obsidian/plugins/obsidian42-brat/data.json` during install. It is
generated from a real launch of the vendored BRAT version (currently `2.0.4`),
not hand-written, so the schema matches whatever defaults BRAT writes on first
load. Per [[specs/workdesk-init]] r4.1 §BRAT data.json.

## When to regenerate

- Bumping the vendored BRAT version (e.g., 2.0.4 → 2.0.5).
- Whenever `init.sh`'s pre-write version check would otherwise fail.

## Procedure

```bash
scripts/regenerate-brat-fixture.sh
```

The script:

1. Verifies the vendored BRAT version from `vendor/plugins/obsidian42-brat/manifest.json`.
2. Backs up `~/Library/Application Support/obsidian/obsidian.json` (restored on exit).
3. Creates a clean test vault at `/tmp/workdesk-brat-fixture-vault-<pid>/` with
   the vendored BRAT pre-installed and enabled in `community-plugins.json`.
4. Launches Obsidian via the `obsidian://open?path=...` URI.
5. Waits for you to:
   - **Click "Trust author and enable plugins"** in the modal.
   - Wait ~5 seconds for BRAT to load and write its default `data.json`.
   - **Quit Obsidian** (Cmd-Q).
6. Captures BRAT's written `data.json`.
7. Sets `pluginList` to `["BenaliHQ/workdesk-terminal"]` and
   `pluginSubListFrozenVersion` to `[{"repo":"BenaliHQ/workdesk-terminal","version":"v1.1.2","token":""}]`
   via `plutil -replace`. All other keys (BRAT defaults — `updateAtStartup`,
   `ribbonIconEnabled`, etc.) pass through untouched.
8. Lints the result and writes it to `data.json.fixture` in this directory.
9. Restores the registry backup and removes the temp vault.

After the script exits, `git diff vendor/plugins/obsidian42-brat/data.json.fixture`
should show only the values you intended to change. Commit the diff.

## Why "real launch" instead of hand-typed schema

Codex r2 review (NEEDS-CHANGES) flagged that exact-key-match validation against
a hand-typed schema breaks whenever upstream BRAT adds a default field
(e.g., `ribbonIconEnabled`). A fixture generated from the real plugin captures
whatever the current version's defaults are and is forward-compatible with new
optional keys. The orchestrator's validation is required-keys-present + correct
target values, with extras allowed.
