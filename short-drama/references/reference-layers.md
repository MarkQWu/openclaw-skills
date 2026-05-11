# Reference Layers

> Phase 4 first-pass classification. This file does not move or rename any
> reference. It only gives maintainers one place to see each document's primary
> layer before metadata and hard-gate refactors.

## Layer Definitions

| Layer | Purpose | Hard-gate bias |
|---|---|---|
| `foundation` | Runtime safety, state, release/update, compliance, research truth, output contract | Can contain blocking rules when evidence is objective |
| `structure` | Story architecture, genre positioning, hooks, paywall, rhythm, character function | Usually soft-to-hard depending on command and evidence |
| `craft` | Line-level and scene-level writing craft, polish, realism, quality rubric | Mostly soft rubric unless it triggers OOC, unfilmable output, format failure, or factual contradiction |
| `modes` | Medium, market, or command-mode specific overlays | Can override baseline rules only inside its declared mode |
| `templates` | Reusable output formats, forms, prompt skeletons, and project artifacts | Contractual for formatting, non-authoritative for method |

## Classification

### Foundation

| Reference | Primary role |
|---|---|
| `compliance-checklist.md` | Content safety and platform red lines |
| `format-control.md` | Command-level output and script format contract |
| `project-management.md` | Project state schema, active project routing, write safety |
| `research-fallback.md` | Research fallback behavior when search/tools are unavailable |
| `research-guide.md` | Research workflow and factual grounding |
| `update-mechanism.md` | `/更新` behavior and repository-level update policy |
| `used-lines-protocol.md` | Reuse prevention and line-level continuity hygiene |

### Structure

| Reference | Primary role |
|---|---|
| `anchor-library.md` | Genre anchor examples and emotional reference pool |
| `anchor-trigger.md` | Anchor activation logic for planning and episodes |
| `genre-guide.md` | Genre taxonomy, audience fit, and configuration choices |
| `hook-design.md` | Episode-ending hook types and placement strategy |
| `opening-rules.md` | Opening structure and first-episode entry patterns |
| `paywall-design.md` | Paid-episode pressure and cliffhanger architecture |
| `plot-types.md` | Plot type selection and structural archetypes |
| `rhythm-curve.md` | Episode and full-series pacing shape |
| `satisfaction-matrix.md` | Audience payoff mapping |
| `short-dynasties.md` | Dynasty/setting shorthand for structure and premise work |
| `villain-design.md` | Antagonist function, pressure, and escalation design |

### Craft

| Reference | Primary role |
|---|---|
| `dramatic-truth.md` | Dialogue truth, anti-trailer-speak, and polish audit |
| `quality-rubric.md` | Scoring rubric and quality dimensions |
| `quality-rules.md` | Quality constraints and recurring failure patterns |
| `realism-checklist.md` | Plausibility, causality, and grounded behavior checks |
| `roundtable-figures.md` | Character voice and roundtable reference figures |
| `script-element-extraction.md` | Dialogue, scene, insert, shot, and parenthetical extraction pipeline |
| `vertical-drama-craft.md` | Vertical-drama line, scene, and information-density craft |

### Modes

| Reference | Primary role |
|---|---|
| `ai-live-rules.md` | `medium=ai_live` production constraints |
| `comic-rules.md` | `medium=comic` production constraints |
| `imitation-protocol.md` | `/仿写` compatibility and reference adaptation flow |
| `storyboard-guide.md` | Storyboard and video prompt generation guide |
| `storyboard-rules.md` | Storyboard command constraints and checks |
| `overseas/anti-patterns.md` | Overseas mode failure patterns |
| `overseas/dialogue-craft.md` | Overseas dialogue craft and platform conventions |
| `overseas/hard-rules.md` | Overseas mode non-negotiable constraints |
| `overseas/platform-knowledge.md` | Overseas platform and market reference |

### Templates

| Reference | Primary role |
|---|---|
| `brainstorm.md` | Isomorphic story ideation skeleton |
| `output-templates.md` | User-facing command output templates and `/帮助` source |
| `setting-bible-template.md` | Setting bible artifact template |

## Non-Markdown Utility In References

| Path | Current status | Phase 4 note |
|---|---|---|
| `condense-source.py` | Utility script stored under `references/` | Needs a later ownership decision: move to `scripts/`, declare as allowed reference utility, or retire |

## Hard-Gate Metadata Coverage

These references now carry explicit metadata fields:
`layer`, `control`, `authority_id`, `canonical_path`, and `read_when`.

| Reference | Control | Read when |
|---|---|---|
| `format-control.md` | `hard_gate` | Every command before output generation |
| `project-management.md` | `hard_gate` | `/开始`, `/新建`, `/分集`, `/自检`, and any command that reads or writes project state |
| `compliance-checklist.md` | `hard_gate` | `/自检`, `/导出`, and publishability/platform risk checks |
| `research-guide.md` | `hard_gate` | `/考据` and thick-topic script generation that relies on domain facts |
| `research-fallback.md` | `hard_gate` | `/考据 auto` when WebSearch, WebFetch, PDF, or source access fails |
| `update-mechanism.md` | `hard_gate` | Every skill activation update check and explicit `/更新` command |
| `ai-live-rules.md` | `hard_gate` | `medium=ai_live` or missing medium |
| `comic-rules.md` | `hard_gate` | `medium=comic` |
| `overseas/hard-rules.md` | `hard_gate` | `mode=overseas` before `/开始`, `/分集`, and `/自检` |

## Next Metadata Pass

The next Phase 4 pass should add per-document metadata to hard-gate candidates:

```yaml
layer: foundation|structure|craft|modes|templates
control: hard_gate|soft_rubric|creative_guidance|template_contract
authority_id: short-drama.<stable-id>
canonical_path: references/<path>
read_when: <command or condition>
```
