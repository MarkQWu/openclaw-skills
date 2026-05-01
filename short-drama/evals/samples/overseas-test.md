# Sample: 海外 Billionaire Romance（overseas-test）

> Eval 固定 input。跑法：先 `/出海` 切换 mode，然后 `/开始` → `/创作方案` → `/角色开发` → `/目录` → `/分集 1` → `/自检 1`，对照 `assertions.md` 逐条验证。
> 题材选 ReelShort/DramaBox 已验证爆款元素（Billionaire + Secret Identity），目的：验证 mode=overseas 工艺资产收回是否真生效（13 条 hard-rules + 4-Phase 20-Beat + ReelShort 90s 规格 + 中式直译禁区）。

---

## state（.drama-state.json 等价）

```json
{
  "mode": "overseas",
  "language": "en-US",
  "medium": "ai_live",
  "platform": "reelshort",
  "monetization": "IAP",
  "stage": "ep1-write",
  "title": "The CEO's Hidden Heir",
  "genre": "Billionaire Romance + Secret Baby",
  "subgenre": "Western contemporary · female-frequency"
}
```

## /开始 输入（已 /出海 切换后）

```
Genre: Billionaire Romance with Secret Baby
Female Lead: Ava Sinclair (28, single mom working as a hotel housekeeper, daughter is 4 years old)
Male Lead: Damien Cross (32, billionaire CEO of Cross Industries, doesn't know he has a daughter)
Setup: Ava had a one-night stand with Damien 5 years ago. He left without contact info. She gave birth alone, raised the daughter while working low-wage jobs. Now she takes a job at his hotel — they recognize each other in the lobby in EP1.
Target platform mode: ReelShort 90-second episodes, IAP first paywall at EP11
```

## creative-plan.md 摘要（/创作方案 期望产出）

- **Core conflict**: Ava must protect her daughter's existence from Damien (who would take custody) while financial collapse forces her to keep this job
- **4-Phase 20-Beat structure** (Gwen Hayes):
  - Phase 1 (Beats 1-5, EP1-15): Adhesion — recognition / forced proximity / first paywall hook
  - Phase 2 (Beats 6-10, EP16-30): Deepening — daughter discovered / Damien's POV reveal / second paywall
  - Phase 3 (Beats 11-15, EP31-45): Retreat — custody threat / Ava runs / midpoint of love
  - Phase 4 (Beats 16-20, EP46-60): Earned union — billionaire grovel + daughter accepts dad
- **Hard rules compliance check** (from `references/overseas/hard-rules.md`):
  - Rule 4: NO humiliation→power male arc (Damien is established alpha from EP1, not a "loser → CEO" arc)
  - Rule 5: NO civilian killing (Damien is dark but doesn't murder unrelated people)
  - Rule 6: NO chemical/drug-induced intimacy (the past one-night stand was sober mutual consent)
- **Hook for EP1 (90s ReelShort target)**:
  - 0-3s: Ava's hands trembling as she pushes a cleaning cart through the marble lobby
  - 3-15s: She looks up — Damien Cross (recognized instantly) walking toward her with an entourage
  - 15-60s: Brief eye-contact freeze → Damien's stride hesitates → Ava's coworker addresses him → he forces neutrality
  - 60-90s (Button): Ava's phone rings — daughter's daycare. As she rushes out, Damien sees her cleaning name tag clearly, expression unreadable. End on his face.
- **Paywall plan**: EP11 first paywall = the moment Damien decides to investigate Ava (= start of "discovery of daughter" arc)

## 期望 /分集 1 通过的 assertion

- [x] **A1** N/A（出海模式，Billionaire Romance 不在 anchor 覆盖的国内 13 题材内 → anchor 字段可不出现）
- [x] **A2** 前 1/3 字数有冲突/钩子词（"trembling" / "frozen" / "hidden" 等英文等价）
- [x] **A3** Hollywood 格式：≥2 个 INT./EXT. 场景头 + ≥1 个 WIDE SHOT/CLOSE-UP；**0** 命中中式 humiliation→power 弧禁词（赘婿/逆袭/打脸/废柴/战神）
- [x] **A4** 自检 7 维度齐全
- [x] **A5** dramatic-truth 4 症状触发（Ava 内心独白如有长台词应被扫）
- [x] **A6** 中式表达扣分扫描（如模型生成时被中文母语污染产出"心如刀绞""星眸"等直译，自检应标记）

## 不通过的常见原因（debug 提示）

- A3 fail（Hollywood 格式缺失）：output-templates.md `#分集出海模式` 引用断 → 检查 SKILL.md L274
- A3 fail（禁词命中）：references/overseas/anti-patterns.md 没被加载 → 检查 SKILL.md `/出海` 命令 v1.19.0 新增的"强制加载 references/overseas/ 全 4 文件"是否真生效
- A5 fail：dramatic-truth.md 不读 → 国内/海外都会失败的 silent-fail
- A6 fail：anti-patterns.md 禁词表未生效 → 自检阶段不识别中式直译

## 主观人工裁定项（不计 assertion 通过/不通过，但记录）

- voice 是否真像 Western 角色（vs 中式翻译腔）？
- Damien 的"alpha but not abusive" 边界是否守住？
- 90s 节奏是否真适配 ReelShort（vs 国内 2 分钟节奏挤进去）？

人工评分 1-10 各一项，记录到 baseline 文件。
