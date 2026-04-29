---
tool: Vercel CLI
slug: vercel
category: code-deploy
class: recommended
connected: false
added-on: 2026-04-29
connector: cli
preferred-for: []
confirmed-by-operator: false
---

## What it is

Vercel's CLI. Deploys, previews, and manages Vercel projects from the terminal. Useful for any web project hosted on Vercel.

## Best practices

- `vercel` — deploy current directory to a preview URL.
- `vercel --prod` — promote to production.
- `vercel logs <url>` — tail deployment logs.
- `vercel env` — manage env vars per environment.

## Connection notes

**Install:** `npm i -g vercel` or `brew install vercel-cli`.

**Verification:** `command -v vercel` succeeds AND `vercel whoami` returns the logged-in user.

**Auth:** `vercel login` — emails a magic link.

## Linked use cases

- *(filled in as skills declare they use vercel)*
