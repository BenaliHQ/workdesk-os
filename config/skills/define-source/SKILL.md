---
name: define-source
description: Meta-skill — scaffold a new system source type. Sources are raw inputs (transcript, session-log, intake, bookmark, screenshot, etc.) with a processing rule that turns them into atlas/intel/gtd notes. Define identity, format, processing, retention.
---

# /define-source

Sources are how the vault learns. This skill defines a new raw-input type and its processing rule.

## Detection clause

Surface proactively when:
- A new kind of capture starts landing in `system/intake/` regularly (e.g., screenshots from a research project)
- The operator wires up a new tool that produces structured output (Defuddle bookmarks, Granola transcripts)
- vault-improvements identifies a "raw input shape with no processing pipeline"

Ask: *"You've dropped {kind} captures a few times. Want to define a `{type}` source so they auto-route?"*

## JTBD-first interview

1. **What kind of raw input?** Free response.
2. **Where does it come from?** Tool, manual paste, hook, API.
3. **What does an instance look like?** Show an example file/payload.
4. **What does Claude do with it?** Turn into what — atlas note, action, observation?
5. **What's the trigger to process?** Operator confirmation, automatic on drop, session-entry surfacing.
6. **Retention?** Keep forever, archive after N days, delete after N days.

Then formalize:

7. **Folder location** — usually a subfolder under `system/`
8. **Naming convention** — date-prefixed slug, or other
9. **Required frontmatter** — `type`, `source-kind`, `date`, `processed`, `processed-into` always; what else?
10. **Move-after-processing?** `false` (default) or `_archive/{YYYY-MM}/`

## Scaffold

Create:

```
system/{folder}/                        # source folder
config/sources/{type}.md             # declaration
```

### `config/sources/{type}.md` shape

```markdown
---
type: source-declaration
name: {type}
zone: system
location: system/{folder}/
naming: "{pattern}"
move-after-processing: false | "_archive/{YYYY-MM}/"
version: 1.0
---

# Source: {type}

## Format

{Frontmatter + body shape}

## Processing rule

{Step-by-step: read source → produce atlas/intel/gtd notes → flip processed flags → backlinks}

## Retention

{Keep forever, archive policy, delete policy}

## Detection

{When session-entry-scan or other skills surface this source for processing}
```

## Update session-entry-scan.sh

If the new source type lives in a new folder under `system/`, update `config/scripts/session-entry-scan.sh` to scan that folder for unprocessed items. (Or accept that V1 only scans `transcripts/`, `intake/`, `session-log/` and the operator manually invokes processing for V1.x source types.)

## Verify

- [ ] Processing rule is deterministic enough that Claude can execute it without ambiguity
- [ ] Retention policy is explicit
- [ ] Frontmatter shape includes `processed: false` and `processed-into: []`

## What NOT to do

- Don't define a source that overlaps with `transcript`, `session-log`, or `intake`.
- Don't write a processing rule that auto-fires without operator confirmation.
- Don't skip the retention section. Source files persist by default; deviations need explicit opt-in.
