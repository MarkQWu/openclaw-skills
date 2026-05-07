---
name: short-drama-remake
description: Analyze reference short-drama scripts or screen-recorded prompt workflows, ingest long/partial scripts into project files, extract the commercial story skeleton, and help with Red Fruit/Douyin-style skin-swap remakes, episode outlines, hook/s爽点 analysis, and shooting-ready scripts. Optionally create staged copy-paste prompts only when the user explicitly asks for 提示词, prompt chain, or a full workflow.
---

# Short Drama Remake

> License: SKILL.md, agents metadata, scripts, and bundled code are MIT; references are gobuildit methodology documentation with all rights reserved except use as part of this skill distribution.

## Core Rule

Treat "1:1 remake" as **story-function replication**, not copying protected expression. Preserve the reference script's emotional rhythm, episode function, misdirection, reveal timing,爽点, and hooks; replace names, dialogue, scene specifics, professions, world rules, props, and surface events.

Match the user's current working language by default. If the user writes in Chinese, respond in Chinese; if the user writes in English, respond in English. Keep screenplay headings, dialogue, prompts, and audits in that same working language unless the user explicitly asks for another language. English skill instructions are internal control text; do not let them leak into screenplay language, character dialogue, headings, or user-facing prompts.

If the source text, screenshot, or video frame is unclear, mark the uncertain part as `[待确认]` instead of inventing it.

## Stage Contract

Keep each stage dependent on the previous artifact. If the user asks for a downstream stage without enough upstream material, state exactly what is missing and provide a copy-paste command to generate it. Do not silently invent missing skeletons, concepts, or outlines.

Required upstream artifacts:

- **Concept generation** requires a reusable skeleton table or equivalent拆解.
- **Project planning** requires the skeleton plus a selected concept number or concept text.
- **Episode outlining** requires the skeleton plus the selected project plan.
- **Script drafting** requires the project plan plus the target episode outline and episode number.

If the user provides a file path, read it. If the conversation already contains the needed artifact, use it and name the artifact being used.

Source scope gates override stage readiness. A `基于已提供集数的样本骨架` can unlock only sample/opening concepts unless `allow_full_series_concepts` is true. `complete` means the source coverage appears complete; it does not replace post-ingest checks or progressive reading.

## Source Ingest And File Gates

For long script files (`.docx`, `.pdf`, `.txt`, `.md`), prefer running [scripts/split_short_drama_source.py](scripts/split_short_drama_source.py) before analysis. The script creates the standard project structure, `manifest.yaml`, `00_source/source-index.json`, source modules, episode files, and 10-episode bundles. If the script is unavailable or cannot read the format, fall back to manual progressive reading and state the limitation.

The default minimum granularity is **episode**. Do not split into scenes by default. Only do scene-level analysis for a target episode when the user asks for single-episode revision, shooting breakdown, or scene-level review.

The script is a reading aid, not a substitute for reading. `source-index.json` and `episode-map.md` are navigation and evidence layers; their `[待确认]` fields are not facts. Before extracting a reusable skeleton, read `manifest.yaml`, `00_source/source-index.json`, `00_source/synopsis.md`, `00_source/story-outline.md`, `00_source/characters.md`, `00_source/episode-outline.md`, `00_source/episode-map.md`, and the first 10-episode bundle. For complete sources, roll through later bundles before finalizing the full-series skeleton.

Always inspect `source-index.json.scope` or `manifest.yaml.gates`:

- `complete`: full-series skeleton claims are allowed only after progressive reading across the whole source.
- `partial`: only sample/opening-segment analysis is allowed. Do not claim full-series structure, middle/late reversals, ending payoffs, or complete commercial model.
- `incomplete` or `unknown`: state the limitation and mark unverified full-series claims as `[待确认]`.

If the user only provides the first 3/5/10 episodes, a trial read, sample chapters, or a fragment, label the output as `基于已提供集数的样本骨架`. Do not present it as a full-series skeleton unless the missing source is later provided.

For PDFs, check `source-index.json.heading_diagnostics` and `validation.warnings`. PDFs often contain both a `分集梗概` heading run and a formal script heading run; a successful split is not enough if the selected run or episode count conflicts with the declared source range.

For the standard project structure, ingest modes, validation checks, and the authoritative downstream reading matrix, read [references/ingest-and-file-management.md](references/ingest-and-file-management.md) when the task involves long files, partial files, PDF extraction, project-file organization, or continuity management.

## Functional Replacement

Preserve episode **function**, not the reference's event template. At every remake stage, check whether the output merely renames the original surface events. When that happens, replace the event mechanics while keeping the same dramatic job.

Use this distinction:

- Keep: humiliation before recognition, false safety before real crisis, public proof, delayed reveal,反噬, next-case hook.
- Replace: exact venue, ceremony type, death method, proof device, family secret mechanics, profession, prop, dialogue beat, and visual business.

For each selected concept, perform a second-layer replacement pass before outlining: ask what the new genre naturally provides, then redesign the concrete incidents from that genre rather than copying the reference's incident order.

## Workflow

1. **Ingest the reference**
   - If the user provides a script, read it directly or through ingest-generated source files before generating creative artifacts.
   - For long script files, ingest into `00_source/` first when possible, then progressively read the generated files.
   - For partial sources, state that only a sample/opening skeleton can be extracted.
   - If the user provides a video, extract metadata, sample key frames, and transcribe/OCR when available. Use visible prompts and outputs as evidence.
   - State what was actually observed and what is uncertain.

2. **拆骨架 before writing**
   - Analyze story core, power relations, episode function, emotional curve,爽点, reversals, and payment/retention hooks.
   - Do not rewrite yet.

3. **Make a reusable skeleton table**
   - Per episode: function, protagonist pressure, antagonist action, viewer emotion,爽点/憋屈点, hook, what to preserve, what to replace.

4. **换皮不换骨**
   - Generate multiple concept skins that keep the skeleton but change genre, world, identities, power tokens, scenes, and dialogue logic.
   - Favor simple high-conflict premises suitable for Red Fruit/Douyin users.
   - Diversify the concepts by audience, production cost, genre distance, and conflict engine.
   - Include a short risk note when a concept is too close to the reference or too expensive/confusing to shoot.

5. **Deepen selected concept**
   - Produce project plan, logline, audience, world rules, character bios, relationship map, protagonist oppression source, comeback resource, key props, and first 10 episodes.
   - Explain the replacement logic for the core resource, power system, public proof scene, antagonist profit model, and long-term emotional hook.
   - Include a雷同风险自检 that lists which surface elements must still be changed before scripting.

6. **Write detailed episode outlines**
   - For each episode, use 起、承、转、合.
   - Include exact episode function and ending hook.
   - Make each episode script-ready: visible opening conflict, pressure action, reversal action, concrete prop/evidence, and a shootable ending image.
   - Avoid outlines that only restate the project plan. Each episode needs new incident detail.

7. **Draft shooting-ready script**
   - Use scene headings, cast, props, visible action, character-fit scene-functional dialogue, and SFX.
   - Dialogue must fit the speaker's identity, power position, emotional state, relationship, and current scene objective.
   - Every line should carry at least one function: pressure, counterattack, information, misdirection, reveal, hook, or emotional release.
   - Place exposition inside conflict, props, actions, interruptions, opponent questions, or visible reactions.
   - Avoid novelistic inner monologue. Use V.O. only for fast setup.
   - Ensure the first 10 seconds enter conflict.
   - If the user does not specify length, keep a single episode focused on its assigned episode function, usually 3-5 scenes.
   - Do not spend the first episode explaining the full mythology; reveal only what the scene conflict needs.

8. **Audit and strengthen**
   - Review as a short-drama platform editor.
   - Cut dead dialogue, increase pressure, clarify hooks, and rewrite weak scenes.
   - Judge dialogue by character fit, scene pressure, plot function, and short-drama rhythm.
   - Check stage leakage: if a script draft starts doing concept planning or if a concept list starts writing full scenes, return it to the requested stage.
   - Check remake distance: preserve the emotional/functional skeleton while increasing the distance of specific incidents from the reference.

## Continuation Guidance

Always end substantial outputs with `下一步可执行指令`. Give 2-4 exact copy-paste prompts, matched to the current stage. These are instructions the user can send directly in the next turn, not vague suggestions.

Rules:
- Write each option as a complete user prompt, preferably inside a fenced `text` block or inline code.
- Replace placeholders with known project names, concept numbers, episode numbers, or file names when available.
- If the next stage has one clearly best path, label it `推荐下一步`.
- Do not write only "可以继续生成..." or "建议深化..." without a complete instruction.
- If `manifest.yaml.gates.allow_full_series_concepts` is false or the artifact is labeled `样本骨架`, the next-step prompts must either ask for the missing full source or explicitly say `基于已提供集数`. Do not offer full-series concepts, full project plans, or full-series claims from partial material.

- After **reference skeleton / 骨架表**:
  - For partial/sample skeletons: `基于已提供集数的样本骨架，生成 10 个样本创意方向。每个方向只判断开局冲突、人物关系、权力凭证、前 N 集可复刻节奏和雷同风险；中后段反转、终局爽点和完整商业模型均标为 [待确认]。`
  - For complete skeletons: `基于上面的完整可复刻骨架，生成 10 个彻底换皮的短剧创意方向。每个方向包含剧名、题材、一句话卖点、主角身份、男主身份、核心反派、关键权力凭证、前 10 集节奏和最大爽点。`
  - For complete skeletons: `把上面的可复刻骨架压缩成 20 集版本，保留原来的剧情功能、情绪节奏、爽点位置和结尾钩子。`
  - `指出上面参考剧本最值得复刻的 5 个爽点机制，并说明每个机制适合换成哪些现代/古装/奇幻表皮。`
- After **10 concepts**:
  - `深化第【编号】个创意，输出完整项目策划案：剧名、类型、一句话卖点、目标受众、核心爽点、故事梗概、世界观、人设、人物关系网、前 10 集大纲和每集钩子。`
  - `对比第【编号】和第【编号】个创意，从开局冲突、用户理解成本、爽点密度、拍摄成本、长线付费钩子判断哪个更适合红果/抖音。`
- After **project plan**:
  - `基于这个项目，生成前 10 集详细集纲。每集用起、承、转、合写清楚开场冲突、主角受压、反派动作、爽点/憋屈点、具体证据/道具和结尾钩子。`
  - `强化这个项目的开局 3 集，让冲突更快、误会更狠、反派更可恨、结尾钩子更强，并说明改动理由。`
- After **episode outline**:
  - `把第【集数】集写成正式短剧剧本，严格使用：剧名、集数、场次、出场人物、主要道具、可拍摄动作、角色台词、SFX。`
  - `审查前 10 集集纲，找出节奏拖慢、爽点不清、钩子不够强的地方，并给出修改后的集纲版本。`
- After **script draft**:
  - `以红果/抖音短剧审稿人标准，检查并强化这集剧本。重点看开局 10 秒、台词是否符合人物设定和场景压力、反派压迫感、爽点释放和结尾钩子。`
  - `继续写第【下一集】集，必须直接承接上一集结尾钩子，并保持同样的格式、节奏和人物口吻。`

Do not leave the user at a dead end. If the latest request is ambiguous, recommend the most logical next stage instead of asking broad questions.

## Prompt Library

Read [references/prompt-chain.md](references/prompt-chain.md) only when the user explicitly asks for complete staged prompts, reusable copy-paste prompts, or a full workflow. If the user asks only for a skeleton,拆解,换皮 direction,集纲, or script, do not append the prompt library by default.

## Output Standards

- Lead with the conclusion or next usable artifact.
- Keep stages separate; do not collapse analysis, concepting, outlining, and scripting into one prompt unless the user explicitly asks for a single all-in-one prompt.
- Do not output staged prompts unless the user's latest request explicitly includes words such as `提示词`, `prompt`, `分阶段`, `工作流`, or `可复制`.
- End substantial outputs with `下一步可执行指令` and exact copy-paste prompts.
- When creating prompts, include placeholders such as `【填写编号】`, `【粘贴参考剧本】`, and `【填写集数】`.
- For script drafts, enforce clear formatting:
  - `剧名：`
  - `集数：`
  - `场 X-XX：内/外 时间 地点`
  - `【出场人物】`
  - `【主要道具】`
  - `△ 可拍摄动作`
  - `角色名（动作/神态）：台词`
  - `[SFX：音效/画面提示]`
