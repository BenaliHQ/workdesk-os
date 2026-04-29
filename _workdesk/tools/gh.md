---
tool: GitHub CLI
slug: gh
category: code-deploy
class: recommended
connected: false
added-on: 2026-04-29
connector: cli
preferred-for: []
confirmed-by-operator: false
---

## What it is

GitHub's official CLI. Manages repos, PRs, issues, releases, and workflows from the terminal. Useful for any code project that lives in a GitHub repo.

## Best practices

- `gh pr create` — open PRs from the branch you're on without leaving the terminal.
- `gh pr list` / `gh pr view` — check PR state and discussion.
- `gh release create` — tag releases with attached artifacts (BRAT pulls these for plugin updates).
- `gh auth status` — verify you're authenticated.

## Connection notes

**Install:** `brew install gh` on macOS, or see https://cli.github.com.

**Verification:** `command -v gh` succeeds AND `gh auth status` shows logged in.

**Auth:** `gh auth login` — uses browser-based OAuth. Stores token in macOS Keychain.

## Linked use cases

- *(filled in as skills declare they use gh)*
