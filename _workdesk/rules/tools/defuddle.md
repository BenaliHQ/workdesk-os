# Defuddle — Tool Reference

Clean markdown extraction from web pages. Strips navigation, ads, and clutter. Smaller and more parseable than `WebFetch`.

## Access Method

CLI command: `defuddle` (Node-based; install via `npm install -g defuddle-cli`).

## Common Commands

| Command | What it does | Example |
|---|---|---|
| `defuddle parse <url>` | Print clean markdown of the page | `defuddle parse https://example.com/article` |
| `defuddle parse <url> -o file.md` | Save clean markdown to file | `defuddle parse https://example.com -o /tmp/page.md` |
| `defuddle parse <url> --json` | Return structured JSON (title, byline, content) | `defuddle parse https://example.com --json` |

## When to use

- The user provides a URL to read or summarize
- Reading documentation, articles, blog posts, release notes

## When NOT to use

- Pages requiring authentication or JavaScript-heavy SPAs (use a real browser tool)
- Local files (use `Read`)

## Common Mistakes

- Not falling back to `WebFetch` when Defuddle fails on paywalls or JS-rendered pages
- Forgetting to attribute the source URL on any vault note that uses extracted content (per `source-documentation` rule)

## Authentication

None.
