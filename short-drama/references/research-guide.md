# 考据 Research Guide

> short-drama skill 的考据机制说明文档。`/考据` 命令的方法论、检索策略、信源准入规则、反模式清单。

## 核心原则

短剧专业题材（医疗/法律/历史朝代/金融/警务/科研/工程/电竞/餐饮等）必须建立 `setting-bible.md`，剧本中**每一处具体专业细节都能映射到 bible 一条**。bible 不存在或细节无法映射 → 自检第 8 维度（考据可追溯性）打 0 分或扣分至 ≤3 分。

**底线：宁可标 `[虚构]` 白名单，绝不编造伪知识。**（违反全局 CLAUDE.md「绝不编造事实」硬规则）

---

## 双轨资料源

| 模式 | 命令 | 适用场景 |
|------|------|---------|
| auto | `/考据 auto` | 默认入口，WebSearch + WebFetch 自动建 bible |
| import | `/考据 import {路径}` | 用户已有甲方资料/学术 PDF/剧研报告 |
| view | `/考据 view` | 打印当前 bible，便于审查 |
| lock | `/考据 lock` | 锁定 bible，后续 /分集 不允许任何 [虚构] 标注 |

---

## WebSearch 双通道 query 策略（修订 1）

每个厚型题材的检索分两条并行通道，确保规则系统和原典定义都拿到：

### 通道 A：综述/二手通道（拿规则系统、术语解释）

适合查"X 朝代的官制是什么"、"急诊抢救流程是什么"这类**规则提取型**问题。检索目标：高校学术分析、机构权威综述、行业百科长文。

**示例 query 模板：**
- 历史：`{朝代} {主题} 制度 综述 site:edu.cn`
- 医疗：`{病种} {场景} guideline 中华医学会`
- 法律：`{法律领域} 程序 司法解释 中国法学`
- 金融：`{金融工具} 监管框架 银保监会`

### 通道 B：原典/一手通道（拿权威定义、具体数字）

适合查"贞观三年到底有没有这个官名"、"成人 CPR 按压频率到底是多少"这类**精度验证型**问题。检索目标：一手史料、专业数据库。

**示例 query 模板：**
- 历史：`{人物/事件} site:ctext.org` / `site:shidianguji.com` / `site:gj.cangshu.cn`
- 医疗：`{术语} site:ncbi.nlm.nih.gov` / `site:pubmed.ncbi.nlm.nih.gov` / `site:uptodate.com`
- 法律：`{条款} site:court.gov.cn` / `site:npc.gov.cn`
- 金融：`{规则} site:csrc.gov.cn` / `site:cbirc.gov.cn`

**两条通道并行**，每个核心字段（官名/术语/数字）至少 1 条来自通道 B 才算"高置信度"。

---

## 权威源加权表（修订 2）

WebSearch / WebFetch 拿到结果后，按域名打权重，bible 字段写入前需通过准入门槛。

| 权重 | 类型 | 示例域名 |
|------|------|---------|
| 3 | 一手史料 / 一手医学库 | ctext.org / shidianguji.com / gj.cangshu.cn / 国图 / ncbi.nlm.nih.gov / pubmed.ncbi.nlm.nih.gov / uptodate.com |
| 2 | 高校 + 政府 + 学术机构 | *.edu.cn / *.gov.cn / 中研院 / 行业协会（cem.org.cn / pumch.cn） |
| 1 | 严肃媒体 / 学术转载 | 澎湃 / 爱思想 / 观察者 / 丁香园 / MedSci |
| 0 | 通用百科 | 百度百科 / 维基百科（不计入加权和，可作旁证） |
| -1 | 黑名单（伪知识高发区） | csdn.net / qulishi.com / huatu.com / haohuanjiao / health.baidu.com / 39健康网 |

### bible 字段 verified 准入门槛

每条 bible 字段聚合的来源权重和需 **≥ 6 且至少 1 条权重 3** → 标 `verified: true`，否则标 `[待人工核源]`：

- ✅ 通过：1 条权重 3 + 2 条权重 2 = 7 → verified
- ✅ 通过：1 条权重 3 + 1 条权重 2 + 1 条权重 1 = 6 → verified
- ❌ 不过：3 条权重 2 = 6（无权重 3） → [待人工核源]
- ❌ 不过：1 条权重 3 + 1 条权重 1 = 4 → [待人工核源]

**黑名单源（权重 -1）若与高权重源冲突 → 整条字段标 `[来源冲突·待复核]`，不写入 bible。**

---

## PDF / 不可达源 fallback（修订 3）

WebSearch 命中权威源但实际无法取回时（医疗题材 30%+ 权威源是 PDF），按以下流程降级：

1. **PDF 二进制**：尝试 pdftotext / pdfplumber 预处理（如环境无库则跳过到 2）
2. **SSL / socket 错误**：2 次重试；失败则切换镜像源（如 NCBI ↔ PMC、丁香园 ↔ MedSci/brainmed）
3. **全部失败**：bible 字段降级写入"该来源[fetch-failed]：仅能引用标题/摘要"，权重计算时按通用百科（0）处理
4. **关键事实只有 fetch-failed 一条来源** → 字段标 `[待人工核源]`，不算 verified

详见 `references/research-fallback.md`。

---

## 短朝 / 冷门时段盲区（修订 4）

通用百科对短朝代覆盖严重不足。当 seedIdea 命中 `references/short-dynasties.md` 列出的朝代/时段时，**强制走原典通道**（《XX 书》《XX 实录》本纪/列传），不允许只靠综述源。

匹配触发提示：
> [盲区警告] {朝代}（享国 {N} 年）属冷门时段，通用百科覆盖不足。本次考据强制读取一手史料：{建议来源列表}。预计耗时增加。

---

## 元题材（避坑/吐槽）非学术路径（修订 5）

bible 的「已知雷区」字段**不**适合用学术权威源。雷区本质是"读者能识别出的不真实细节"，路径如下：

| 题材 | 雷区源头 |
|------|---------|
| 医疗 | 丁香园专家专栏 / 知乎医生答主 / 微博医生大 V |
| 历史 | 豆瓣长评（剧评区）/ B 站考据 up（"XX 剧考据"系列）/ 历史类微信公众号 |
| 法律 | 知乎法律答主 / 律师专业号 / 最高法案例库（反向） |
| 金融 | 雪球长文 / 同花顺研报 / 首席经济学家观点 |
| 科研 | 科研圈知乎话题 / 集智俱乐部 / 知识分子 |

不套学术权威标准。该字段 verified 门槛降为：**至少 2 条独立来源即可**（不要求权重 3）。

---

## bible 字段规范

详见 `references/setting-bible-template.md`。核心字段：

- 元信息（题材/时代/资料来源/生成方式/置信度）
- 核心规则系统（含「物资清单」「大事件处置补丁」子字段，修订 6）
- 术语表（每条：定义 + 来源 + 使用场景）
- 时代/场景常识锚点
- 已知雷区
- 虚构白名单

---

## import 模式资料解析规则

### 支持格式

- **md / txt**：直接 Read，按 setting-bible-template 重组结构
- **pdf**：提示用户「飞书导出 md / 用 pdfplumber 转 md 后再 import」，不直接处理
- **url**：转换为 WebFetch 调用，但权重按权威源加权表计算（不豁免黑名单）
- **doc / docx**：建议导出 md 后 import

### 提取流程

1. Read 用户提供文件
2. 按 setting-bible-template.md 的 6 个 section 提取/重组
3. 缺失字段询问用户：补充 / 接受空 / 切换 auto 模式补全
4. 写入 setting-bible.md，状态 = import
5. 列出"用户资料未覆盖但 setting-bible-template 必需"的字段清单

### 混合模式（hybrid）

`/考据 import {路径}` 后再跑 `/考据 auto` → 状态升级为 hybrid，auto 仅补 import 缺失字段，不覆盖已有字段。

---

## 反模式（AI 最容易编造的"知识"）

写作中以下模式最容易触发 Goodhart's Law（指标变目标即被优化到失真）和「编造事实」违规，自检第 8 维度命中此类模式直接降至 ≤3 分（参考 quality-rubric.md 雷区否决项）：

### 历史/时代题材

- 编造**精确年份**（"贞观七年三月初九"）—— bible 无明确出处的具体日期一律改为模糊（"贞观初年"）
- 编造**官职名 + 品级**（"从五品下著作佐郎"）—— 必须能映射到 bible 官制表
- 编造**俸禄/物价数字**（"月俸三十贯"）—— 朝代物价数据极难考，宁可不写
- 错用**朝代专属称谓**（南齐用「公子」而非「郎君」、宋代用「老爷」而非「相公」）

### 医疗题材

- 编造**药物剂量**（"地塞米松 5mg"）—— 必须查 UpToDate/中华医学会指南
- 编造**抢救参数**（"除颤 200J 双相波"）—— 心律失常类型决定能量
- 错用**抢救节奏口诀**（编造"急救六步走"等）—— 实际有 BLS/ACLS 标准
- 编造**血型/血制品配比**（"O 阴血浆 4 单位"）—— 配比有标准（红细胞:血浆 1:1）

### 法律题材

- 编造**法条编号**（"刑法第三百零七条第二款"）—— 查 npc.gov.cn / pkulaw
- 错用**程序术语**（混用"传唤"和"拘传"、"羁押"和"逮捕"）
- 编造**判决结果**（"无期徒刑改判十年"）—— 改判规则有限制

### 金融题材

- 编造**收益率/手续费**（"年化 8.6%、申购费 1.5%"）
- 错用**金融工具**（混用期权和期货、混用做空和卖空）
- 编造**监管细则**（"证监会 2023 年第 37 号公告"）

### 通用编造模式

- **5 句一具体数字**（凑节奏的虚假精度）
- **AI 喜欢的"专业感"词汇**（"基于...原理"、"按照...流程"、"根据...规定"等套话）
- **概念词代替场景词**（"严格按照诊疗规范" vs "查血常规、做心电图、上心电监护"）

---

## research-cache/ 缓存规则

`/考据 auto` 跑完后将所有 WebSearch / WebFetch 原始返回缓存到 `research-cache/`：

```
research-cache/
├── search-{topic-slug}-{YYYYMMDD-HHMMSS}.json    # 检索结果
├── fetch-{url-slug}-{YYYYMMDD-HHMMSS}.md         # 抓取正文
└── manifest.json                                   # 索引
```

**作用**：
1. bible 字段标 verified 时引用具体缓存文件
2. 后续 /考据 auto 跑同主题时优先读缓存（避免重复 WebSearch）
3. 用户怀疑某条 bible 字段时可以查证

---

## 流程总结

```
/考据 auto
  ↓
1. 读 .drama-state.json：题材 + seedIdea + logline
  ↓
2. 题材匹配 short-dynasties.md → 是冷门 → 强制原典通道
  ↓
3. 双通道 query 并行 WebSearch（通道 A：综述/二手；通道 B：原典/一手）
  ↓
4. 高权重结果 WebFetch（PDF/SSL 失败走 fallback）
  ↓
5. 按 setting-bible-template.md 填充字段，每条聚合权重 ≥6 → verified
  ↓
6. 列出 [待人工核源] / [虚构白名单] / [来源冲突] 项让用户决定
  ↓
7. 写入 setting-bible.md + research-cache/
  ↓
8. 状态更新为 auto
```

```
/考据 import {路径}
  ↓
1. Read 文件（pdf 提示先转 md）
  ↓
2. 按 setting-bible-template 重组
  ↓
3. 列缺失字段供用户决定
  ↓
4. 写入 setting-bible.md，状态 = import
```
