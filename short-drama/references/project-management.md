# 项目管理（Project Management）

本文件定义 short-drama skill v1.13.0 起的**活跃项目指针架构**。所有 `/开始` / `/新建` / `/分集` / `/自检` 等命令均依赖此规范。

## 核心架构变更（v1.13.0）

放弃 v1.10-v1.12 的 **cwd-based 项目隔离**（依赖用户切换工作目录），改为 **scan-based + state.projectName** 架构：

- **`/开始` 扫描 `~/short-drama-projects/*/` 列出所有项目**，用户显式选择要操作哪本
- **选中后 LLM 用绝对路径读写** `~/short-drama-projects/<projectName>/`，cwd 完全不再影响
- **WorkBuddy 用户零切换**：不再需要 `cd` 或改 WorkBuddy 工作目录
- **跨 session 继承**：每次 `/开始` 都让用户显式选，不依赖隐式记忆

## 项目目录约定

### 默认位置

所有项目统一在 `~/short-drama-projects/<项目名>/`。路径由 `pathlib.Path.home() / "short-drama-projects" / project_name` 解析，跨平台自动展开（macOS/Linux/Windows）。

### 项目内文件清单

见 SKILL.md 「工作目录」section。所有产出走绝对路径。

## 项目名验证（`/新建` 必走）

拒绝并要求重输的 case：

| 情形 | 错误提示 |
|---|---|
| 空字符串 / 仅空格 | "项目名不能为空" |
| 含路径分隔符 `/` `\` | "项目名不能含路径分隔符" |
| 含 Windows 非法字符 `:` `*` `?` `"` `<` `>` `|` | "项目名含非法字符（Windows 不允许 `:*?\"<>|`）" |
| 是 `.` 或 `..` | "项目名不能是 . 或 .." |
| 长度 > 50 字符 | "项目名超长，确认继续？" |

**合法处理**：两端空格自动 trim；允许中文、数字、英文字母、常见标点（`-` `_` 等）、空格（中间）；emoji 允许但 `/项目列表` 展示可能乱码。

## /开始 扫描 + 列表行为（v1.13.0）

```
/开始 → 扫 ~/short-drama-projects/*/ 收集合法 .drama-state.json
  │
  ├─ 0 项目 + cwd 有 state（v1.10-v1.12 老用户 fallback）
  │   → 加载 cwd state，询问"[1] 就地继续 / [2] 迁移到标准位置"
  │   → 选 2 执行 mv + state 补 projectName 字段
  │
  ├─ 0 项目 + cwd 无 state
  │   → 询问项目名 → 走 /新建 语义
  │
  ├─ 1 项目
  │   → "欢迎回来《X》阶段 Y 进度 N/M。继续？[Y/新建]"
  │
  └─ ≥2 项目（按 mtime 降序列表）
      → "1. 《A》阶段(mtime)
          2. 《B》阶段(mtime)
          ...
          N+1. 新建一本
          
          回复数字或新剧名"
      → 数字选项目 / 新剧名走 /新建
```

**选中后分支**：

- `currentStep` 非空（在建项目）→ 欢迎回来 + 展示进度 + 等下一步命令，不进 Step 3
- `currentStep` 为空（`/新建` 刚建的 stub）→ "欢迎来到《X》" + 直接进 Step 3 锁定观众

**活跃项目锚定**：选中后 LLM 本会话所有产出走绝对路径 `~/short-drama-projects/<projectName>/`。不再读写 cwd。

## /新建 stub state 模板（18 字段完整）

`/新建 <项目名>` 写入 `~/short-drama-projects/<项目名>/.drama-state.json`：

```json
{
  "projectName": "<项目名>",
  "dramaTitle": "<项目名>",
  "currentStep": "",
  "genre": [],
  "audience": "",
  "tone": "",
  "totalEpisodes": 0,
  "completedEpisodes": [],
  "characterCardsGenerated": [],
  "storyboardedEpisodes": [],
  "qualityScores": {},
  "language": "zh-CN",
  "mode": "domestic",
  "shotDensity": "",
  "seedIdea": "",
  "logline": "",
  "settingBibleStatus": "none",
  "bibleScope": [],
  "researchIntensity": ""
}
```

**关键**：必须写 **18 字段全集** 而非仅 2 字段，否则下游 Step 5 存 state 时 overwrite 会丢字段。

## 重名保护（`/新建` 强制，防覆盖<USER_REDACTED> 25 集）

`/新建 X` 前检查 `~/short-drama-projects/X/.drama-state.json`：

| state 状态 | 行为 |
|---|---|
| 存在 + 合法 JSON + `currentStep` 非空（在建项目）| **拒绝**：`"《X》已存在（阶段 Y, 进度 N/M）。继续用 /开始 选该项目，或换新名"` |
| 存在 + 合法 JSON + `currentStep` 为空（stub 残留）| 安全覆盖（前次 `/新建` 中断遗留）|
| 存在 + 损坏/非法 JSON | 询问"state 文件损坏，是否覆盖重建？" |
| 不存在 | 正常建 |

## State 写入协议（强制，防数据损坏）

所有修改 `.drama-state.json` 的操作 **必须** Read-Modify-Write：

```python
# 正确（merge 语义）
state = json.load(open(path))
state["currentStep"] = "创作方案"
state["genre"] = ["古装"]
json.dump(state, open(path, "w"), ensure_ascii=False, indent=2)

# ❌ 错误（overwrite 会丢失其他字段）
json.dump({"currentStep": "创作方案", "genre": ["古装"]}, open(path, "w"))
```

**禁止** 使用 Write 工具直接用部分字段 overwrite state。违反 = 数据损坏。

## 活跃项目识别 fallback（用户未显式 /开始）

用户直接输入 `/分集 N`、`/自检 N` 等命令而未先 `/开始`：

1. 本会话 LLM context 已加载过活跃项目 → 沿用
2. 否则扫 `~/short-drama-projects/*/` 按 mtime desc：
   - 1 个 → 自动加载 + "当前加载《X》（唯一项目）"
   - ≥2 个 → 自动加载 **最近修改** + 明确告知："当前加载《X》（最近项目 mtime），如需切换用 `/开始` 重选"
3. 列表为空 → "请先 `/开始` 或 `/新建 <项目名>`"

## 向后兼容 fallback（v1.10-v1.12 老用户迁移）

`/开始` 扫描为空但 cwd 有 `.drama-state.json`（<USER_REDACTED>《<PROJECT_REDACTED>》等老项目）：

1. 加载 cwd state，展示进度
2. 询问两个选项：
   - **[1] 就地继续（兼容模式）**：保留在原 cwd，不迁移。但 `/项目列表` 看不到此项目，后续切换项目会错位
   - **[2] 迁移到标准位置（推荐）**：将 cwd 所有项目文件（`.drama-state.json` + `episodes/` + `creative-plan.md` + 其他）移到 `~/short-drama-projects/<dramaTitle>/`，state 追加 `projectName` 字段
3. 选 2 后继续"欢迎回来"流程

**老 state 补齐 `projectName`**：v1.10-v1.12 的 state 没有 `projectName` 字段。迁移时用 `dramaTitle` 值填入，确保新版架构识别。

## /项目列表 实现约定

调用 `python3 {skill目录}/scripts/list_projects.py`：

1. 扫 `~/short-drama-projects/*/`，支持 `--dir` 自定义路径
2. 读关键字段：`projectName` / `dramaTitle` / `currentStep` / `completedEpisodes` / `totalEpisodes`
3. `currentStep` 为空标记为 `-（未开始）`区分 stub 项目
4. mtime 排序，输出 Markdown/JSON 表格
5. 无匹配项目 → "暂无项目，使用 `/开始` 或 `/新建` 创建"

## /项目状态 实现约定

在活跃项目上下文中：

1. 读活跃项目 `.drama-state.json`
2. 按 `output-templates.md#README` 模板生成 `~/short-drama-projects/<projectName>/README.md`（绝对路径，不依赖 cwd）
3. 输出"README.md 已更新"

## 跨平台路径处理（强制）

- 所有 Python 脚本用 `pathlib.Path` 而非字符串拼接
- `~` 展开用 `Path.home()` 或 `Path.expanduser()`
- 中文路径确保 UTF-8（Python 3 默认，Windows 某些 shell 需 `encoding='utf-8'`）
- shebang 统一 `#!/usr/bin/env python3`

## 反模式（禁止）

- 硬编码绝对路径（如 `/Users/xxx/short-drama-projects/`）
- cwd-based 项目隔离（v1.10-v1.12 遗留，已废弃）
- Write 直接 overwrite `.drama-state.json`（违反 State 写入协议）
- `/新建` 不做重名保护（会覆盖用户在建项目）

## 迭代记录

- 2026-04-20 v1.12.0 首版：cwd-based 项目目录约定 + 向后兼容 + `/项目列表` `/项目状态`
- 2026-04-20 v1.12.1：`/新建 <项目名>` 独立命令替换 `/开始 --new` flag
- 2026-04-20 v1.13.0：**架构重做**。放弃 cwd-based，改为 scan-based + state.projectName。修复 4 个 🔴 bug：
  - Bug 1：`/新建 <已存在项目名>` 重名覆盖 → 加重名保护
  - Bug 2：Step 5 保存 state 丢字段 → 加「State 写入协议」强制 Read-Modify-Write
  - Bug 3：`/开始 --new` 一小时窗口兼容 → `/开始` 扫描 + 列表，即使用户误输 `--new` 也能从列表找到项目
  - Bug 4：WorkBuddy 默认 cwd 死局 → 完全不再依赖 cwd，用户零切换
  - 新增老用户兼容 fallback（v1.10-v1.12 cwd-state 自动迁移或就地继续两选项）
