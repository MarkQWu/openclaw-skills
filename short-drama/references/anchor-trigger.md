# anchor 触发机制（v1.15.0 · MVP）

**目的**：让模型在写本时调用对中文现象级 IP 的 implicit knowledge，提升输出调性，**但不破坏短剧节奏**。

**触发哲学**：anchor 借的是 ① **想象力**（世界观厚度 / 设定颗粒度）② **角色调性** ③ **情绪锚点**。**禁止借**节奏、章节长度、铺垫密度——本剧节奏由【秒级节奏锚点】+【台词≤2 句】+【爽点≥3】等硬约束控制。

## Phase 1 MVP 激活的 5 部 anchor（覆盖 5 题材）

| 题材 | anchor | 借什么 hint |
|---|---|---|
| 都市情感 | 《何以笙箫默》（顾漫）| "克制深情"调性 |
| 重生穿越 | 《庆余年》（猫腻）| 现代灵魂入古代权谋（优先调用范闲 + 叶轻眉遗志主轴）|
| 古装宫廷 | 《后宫·甄嬛传》（流潋紫）| "由柔到狠"女性弧光 |
| 励志逆袭 | 《平凡的世界》（路遥）| 反 AI slop 的真实质感 |
| 悬疑探案 | 《隐秘的角落》（紫金陈）| 非警察视角黑色叙事 |

详见 `references/anchor-library.md`（含 v2 灰度库 28 部 Phase 2 候选）。MVP 5 题材外（霸道总裁 / 甜宠 / 战神归来 / 家庭伦理 / 萌宝 / 软科幻 / 末日重生 / 喜剧 / 玄幻仙侠 / 现代都市异能 / 女频古代）**Phase 1 不触发 anchor**，正常进入下一阶段。

## anchor prompt 模板（生成时 inline 到 prompt）

```
本剧创作借鉴 anchor：
- 《[作品名]》（[作者]）：借[hint 描述]

【重要】只借 anchor 的：① 想象力（世界观厚度）② 角色调性 ③ 情绪锚点
【禁止】借 anchor 的节奏、章节长度、铺垫密度
【硬约束优先】如与节奏锚点冲突，以节奏锚点为准
【禁止复用】不得直接复用 anchor 原台词 / 标志性梗（详见 quality-rules.md anchor 同人化禁用词清单）
【单集约束】本集只体现 anchor 人物**当下弧位的状态**（如"最柔"起点/"最低"低谷/"最冷"克制），不得把跨集弧光（由柔到狠、从底层到巅峰、多年等待等）压缩到单集展开
【爽点类型补丁（v1.17.1 新增）】如本剧题材属"反差爽"类型（隐藏身份 × 反差揭露，如战神归来/赘婿/兵王归来/重生复仇/隐藏身份强者；注意："励志逆袭"≠"反差爽"——《平凡的世界》等靠真本事进阶类不适用本补丁），单集必须保留 ≥1 处让观众感知主角真实身份的信号：
  - 允许形式：OS 一句指向性独白（如"终于来了"/"找到我了"）/ 关键动作细节（熟练度超常的肢体动作）/ 短视线切换（用具体动作承载，如"他看了三秒，锁屏"）
  - 禁用："瞳孔骤缩"/"眼神锐利如刀"等 AI 兜底形容词（详见 quality-rules.md AI 兜底词清单）
  - 与上述【单集约束】不冲突：反差信号是"状态级暗示"不是"弧光展开"
```

## 用户主动调用（C 模式）

用户随时可以说：
- 「换 anchor」/「换成《XX》」 → 修改 `creative-plan.md` 的 anchor 字段后重新写本
- 「不用 anchor」 → 清空 anchor 字段，回到无 anchor 模式
- 「显示 anchor 库」 → 读 `references/anchor-library.md` 列出可选 anchor 给用户

## 失败模式 + 兜底（详见 quality-rules.md）

- **F1 hallucinate**：禁止使用集数 / 章节号；只用人物 + 调性 + 一句话场景描述
- **F2 节奏污染**：自检节奏维度扣分时自动追问"是否被 anchor 节奏污染" → 用户回 Y → 建议 `/分集 N --fix anchor-rhythm` 重写
- **F4 同人化**：自检维度扫描 anchor 禁用词清单 → 命中扣分 + 标 `[anchor 同人化]`

---

## /创作方案 anchor 推荐步骤（仅 MVP 5 题材触发）

如选定题材是 MVP 5 题材之一，**生成内容前**先做 anchor 推荐：

1. 从 `genre-guide.md` 的对应题材 `### anchor 参考` section 读 anchor 候选
2. 基于 `seedIdea` + 题材 + anchor hint，生成推荐句（**严格用此模板**）：
   > 你的 seedIdea「[seedIdea]」结合 [题材] 题材，建议借鉴《[anchor 作品名]》——借的是 [hint]，是否接受？[Y / 换 / N]
3. 处理用户回复：
   - **Y** → 把 anchor 写入 `creative-plan.md` 的 `anchor` 字段（含作品名 + 作者 + hint）
   - **换** → MVP 5 题材每题材仅 1 部 anchor，"换"等同 N（直接进入 N 流程）。Phase 2 灰度库激活后才有第 2 候选
   - **N** → 询问"想自己指定一部吗？（可选，输入作品名跳过推荐 / 回车跳过 anchor）" → 用户输入则记录到 `creative-plan.md` 的 `anchor.userSpecified=true`，不输入则清空 anchor 字段

非 MVP 5 题材 → **跳过 anchor 推荐步骤**直接进入"生成内容"。

## /分集 anchor inline

如 `creative-plan.md` 有 `anchor` 字段（5 题材且用户接受了 anchor 推荐），把上方 **anchor prompt 模板**填入实际 anchor 信息后 inline 到分集生成 prompt。如无 `anchor` 字段（用户回 N / 非 MVP 题材） → 跳过此步骤，按现有流程生成。

## `/分集 N --fix anchor-rhythm` 子命令

如 `/自检` 节奏维度扣分且诊断为 anchor 节奏污染（详见 quality-rules.md），用 `/分集 N --fix anchor-rhythm` 重写——本次生成**临时清空 anchor**（不写入 creative-plan.md，仅本次绕过 anchor），重新生成第 N 集。
