---
layer: structure
control: creative_guidance
authority_id: short-drama.creative-intent-ledger
canonical_path: references/creative-intent-ledger.md
read_when: /开始 after seedIdea capture, /策划 before story architecture, /分集 and /自检 when diagnosing story drift
---

# 原始冲动记录（Creative Intent Ledger）

`Creative Intent Ledger` 用来保留项目最初为什么值得写。它不是评分表，也不是 hard gate；它是创作过程中的方向锚，防止后续为了套模板、补规则、追热点，把故事最初的情绪发动机洗掉。

## 存放位置

写入 `brainstorm.md#原始冲动记录`。不要写进 `.drama-state.json`，避免把创作判断字段混入运行状态。

## 字段

| 字段 | 记录什么 | 最小写法 |
|---|---|---|
| 原始前提 | 用户最早给出的故事种子、画面、关系或设问 | “替嫁新娘被全家轻视，却发现总裁也在伪装” |
| 核心关系 | 故事最想燃烧的主关系或对立关系 | “被迫绑定的夫妻，互相试探后结盟” |
| 爽感引擎 | 观众持续看的情绪机制 | “女主每次被轻视，都会用更高阶的信息差反杀” |
| 结局偏好 | 用户明示或推断出的收束方向 | “复仇完成后保留爱情，不走纯虐” |
| 不可牺牲点 | 后续重构、降本、换媒介时不能删掉的东西 | “女主必须主动赢，不靠男主代打” |

## 使用规则

1. `/开始` 在保存方向草案后生成第一版 Ledger；如果信息不足，用 `[待确认]`，不要臆造。
2. `/策划` 生成故事骨架前先读取 Ledger，用它校验主题意图、核心冲突、付费卡点和结局设计是否同向。
3. `/分集` 偏离既定人设或爽感时，先判断是合理演化还是背离 Ledger。合理演化可继续，背离则提示用户确认。
4. `/自检` 可以把“背离原始冲动”列为 soft risk；只有同时触发 OOC、事实矛盾、合规、不可拍或媒介不匹配时才升级为 hard gate。
5. Ledger 可追加版本，不覆写历史。新需求与旧 Ledger 冲突时，记录“变更原因”，再继续。

## 判断边界

- Ledger 不是模板配方。它保护的是故事最初的情绪、关系和不可牺牲点，不要求每集机械重复原始设定。
- Ledger 不压过 hard gates。合规、事实、格式、项目状态、媒介硬规则仍优先。
- Ledger 不替代商业生命力评分。爽点密度、节奏、主线、可拍性仍按 `quality-rubric.md` 评估。
