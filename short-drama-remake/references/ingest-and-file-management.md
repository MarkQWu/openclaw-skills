# Ingest And File Management

Use this reference when the user provides a long script file, a partial script, a PDF, or asks how project files should be managed.

## Default Directory Contract

```text
project/
  manifest.yaml
  00_source/
    original/
    extracted/source.md
    source-index.json
    synopsis.md
    story-outline.md
    characters.md
    episode-outline.md
    episode-map.md
    bundles/eps_001-010.md
    episodes/ep_001.md
  01_skeleton/reference-skeleton.md
  02_concepts/concepts-10.md
  02_concepts/selected-concept.md
  03_plan/project-bible.md
  04_outlines/
  05_scripts/
  06_state/project-state.md
  07_review/
  08_export/
```

`00_source/` is evidence. Do not overwrite it with rewritten content. Downstream creative artifacts belong in later folders.

For formal ingest, write into a new empty project directory. Use `--force` only for throwaway tests; do not reuse a non-empty output directory for a real project because old episode or bundle files may remain and be misread later.

## Ingest Modes

- `complete`: source coverage appears complete: detected episodes match the declared range, start at 1, have no gaps, and no partial marker is present. It is not an analysis-ready flag. Full-series skeleton claims are allowed only after post-ingest checks and progressive reading.
- `partial`: filename or content indicates first episodes, trial read, sample chapters, fragment, or 10 or fewer detected episodes without a full synopsis/story-outline/characters/episode-outline package. Only sample/opening analysis is allowed.
- `incomplete`: filename declares a larger range than detected, detected episodes have gaps, or detected episodes do not start at 1. Do not claim full-series structure.
- `unknown`: no explicit total episode count and no strong completion evidence. Treat full-series claims as unverified.

Gate priority:

```text
source gate > stage contract > continuation guidance > prompt library
```

A sample skeleton satisfies only the skeleton stage for the supplied episodes. It does not unlock full-series concepts, complete project planning, middle/late reversal claims, or ending payoff claims.

If `manifest.yaml.gates.allow_full_skeleton` is false, output must say:

```text
以下判断仅基于已提供的第 X-Y 集；中后段反转、终局爽点和完整商业模型均为 [待确认]。
```

## Script Use

Run:

```text
python3 scripts/split_short_drama_source.py SOURCE_FILE --out PROJECT_DIR
```

Supported formats: `.md`, `.txt`, `.docx`, `.pdf` when text extraction works.

The script must only split to episode-level by default:

- `episodes/ep_XXX.md`
- `bundles/eps_001-010.md`
- `source-index.json`
- `episode-map.md`

Do not create scene files by default. If a target episode needs scene-level work, analyze that single episode in context without changing the global source structure.

## Required Post-Ingest Checks

After running the script, inspect:

```text
manifest.yaml
00_source/source-index.json
00_source/synopsis.md
00_source/story-outline.md
00_source/characters.md
00_source/episode-outline.md
00_source/episode-map.md
00_source/bundles/eps_001-010.md
```

Check:

- `ingest_mode`
- `scope.completeness`
- `gates`
- `declared_episode_range`
- `detected_episode_range`
- `missing_episodes`
- `heading_diagnostics.duplicate_heading_runs`
- `section_detection`
- `validation.warnings`

If a module is missing, inspect `00_source/extracted/source.md` before saying the source does not contain it. The parser may miss uncommon headings.

## PDF Risk Rules

PDF extraction is lower confidence than `.docx` or plain text.

Common PDF failure modes:

- `分集梗概` contains 第1-80集 headings and the formal script also contains 第1-80集 headings, causing double count.
- Page headers, watermarks, and footer fragments mix into dialogue.
- Scene headings may appear before episode headings after extraction.
- Extracted line order may shift.

If `heading_diagnostics.run_count > 1`, verify the selected run is the formal script run by checking that `episodes/ep_001.md` contains formal markers such as `人物：`, `1-1`, and dialogue/action text. The summary run should remain in `episode-outline.md`.

## Progressive Reading

For `complete` sources:

1. Read `manifest.yaml` and `source-index.json`.
2. Read `synopsis.md`, `story-outline.md`, `characters.md`, `episode-outline.md`, and `episode-map.md`.
3. Deep-read `bundles/eps_001-010.md`.
4. Roll through later bundles by tens. Do not finalize full-series skeleton from only the first bundle.
5. For major skeleton claims, reference evidence from `episode-outline.md`, `episode-map.md`, or specific `episodes/ep_XXX.md`.

For `partial`, `incomplete`, or `unknown` sources:

1. Read all available source modules and episode files.
2. Label the output as sample/opening/incomplete analysis.
3. Mark all inferred middle/late/ending structure as `[待确认]`.
4. Provide the next instruction asking for the missing full source if the user wants a full-series skeleton.

## Downstream Reading Matrix

This matrix is the authoritative reading contract for downstream stages.

Concept generation:

```text
01_skeleton/reference-skeleton.md
00_source/synopsis.md
00_source/story-outline.md
00_source/characters.md
00_source/episode-outline.md
```

Project plan:

```text
01_skeleton/reference-skeleton.md
02_concepts/selected-concept.md
00_source/synopsis.md
00_source/story-outline.md
00_source/characters.md
```

Episode outline:

```text
01_skeleton/reference-skeleton.md
03_plan/project-bible.md
00_source/episode-outline.md
06_state/project-state.md
04_outlines/existing outlines when present
```

Script draft:

```text
03_plan/project-bible.md
04_outlines/target-episode-outline.md
05_scripts/previous episode when present
06_state/project-state.md
00_source/episodes/target reference episode when relevant
00_source/episodes/adjacent or referenced episodes when continuity depends on them
```

## Continuity State

Create or update `06_state/project-state.md` when moving into original outlining or script drafting. Keep it concise and reusable across episodes:

```text
# Project State

## Series Bible
- premise:
- rules:
- core promise:

## Character Ledger
- name:
  - current goal:
  - knows:
  - hides:
  - voice:
  - relationship changes:

## Plot Ledger
- completed:
- active:
- blocked:

## Open Loops
- id:
  - planted in:
  - payoff target:
  - status:

## Props And Rules
- prop/rule:
  - owner:
  - status:
  - limits:

## Episode Cursor
- latest written episode:
- current hook:
- next required payoff:
```

Before writing a later episode, read `project-state.md`. After writing, update what changed: who knows what, relationship shifts, prop status, released爽点, new伏笔, paid-off伏笔, and next hook.

## Validation Checklist

Before trusting an ingest:

- Episode count matches declared range when declared.
- Episode numbers are contiguous.
- First, tenth, eleventh, and final episode boundaries are spot checked.
- `episode-outline.md` contains the summary sequence, not formal script text.
- `episodes/ep_001.md` contains formal script text, not only a one-line summary.
- PDF duplicate heading runs are explained.
- Missing modules were checked against `extracted/source.md`.
- `episode-map.md` `[待确认]` fields are not used as facts.
- Partial sources are not promoted to full-series skeletons.
