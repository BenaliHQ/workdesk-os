# Writing Style

Global writing preferences from operator feedback. These apply across all skills and workflows — not just the skill where the correction was made.

## When this applies

- Writing any content on behalf of the operator (emails, proposals, content drafts, summaries)
- Drafting communications or documents that represent the operator's voice
- Any output the operator will read or send externally

## Voice

- Short, warm, direct. No filler.
- Pull actual writing voice from Gmail history before drafting external communications.
- Match the operator's tone — professional but not corporate, confident but not arrogant.

## Words and phrases to avoid

- "leverage" — use "use" or "apply"

*(This list grows from operator corrections. The Stop hook appends [STYLE] entries here.)*

## Terminal output — file references

When referencing vault files in terminal output (summaries, reports, audit results, plan displays), always use clickable Obsidian URI links so the operator can open the file in a new Obsidian tab by clicking.

Format: `[display name](obsidian://open?vault=khalils-vault&file=path/to/note)` (no `.md` extension in the path).

Examples:
- `[taylor-doe](obsidian://open?vault=khalils-vault&file=atlas/people/taylor-doe)`
- `[2026-03-28-daily-plan](obsidian://open?vault=khalils-vault&file=intel/briefings/daily/2026-03-28-daily-plan)`
- `[Dudley](obsidian://open?vault=khalils-vault&file=atlas/companies/dudley)`

This applies to ALL terminal output — daily plans displayed in conversation, audit reports, entity matching summaries, processing reports, status updates. Every file reference should be clickable.

## What to do

- Before drafting external-facing content, review this file for current style guidance.
- When the operator corrects writing style during any skill execution, the correction applies globally — not just to the current deliverable.
- The Stop hook routes [STYLE] corrections to this file automatically.

## What NOT to do

- Do not use words on the avoid list, even when they seem technically accurate.
- Do not adopt a generic "AI assistant" tone. Match the operator's actual voice.
- Do not over-qualify statements with hedging language ("it could potentially be argued that...").
