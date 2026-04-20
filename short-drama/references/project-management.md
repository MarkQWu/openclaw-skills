# 项目管理（Project Management）

本文件定义 short-drama skill 的项目目录约定和向后兼容规则。`/开始` `/项目列表` `/项目状态` 三条命令依赖此规范。

## 项目目录约定

### 默认位置

新项目由 `/开始` 自动创建在 `~/short-drama-projects/<项目名>/`。

- 路径由 `pathlib.Path.home() / "short-drama-projects" / project_name` 解析，跨平台（macOS/Linux/Windows）自动展开
- `<项目名>` 支持中文字符、空格、基础标点；禁止路径分隔符（`/` `\`）、冒号、换行
- `~/short-drama-projects/` 首次使用时由 `/开始` 命令执行 `mkdir -p` 创建

### 项目内文件清单

见 SKILL.md 的「工作目录」section。`brainstorm.md` 和 `README.md` 是本次新增的管理文件，其余为各命令的原有产出。

### WorkBuddy / 受限客户端兼容

WorkBuddy 等客户端无法由 AI 直接执行 `cd` 切换工作目录。`/开始` 创建新项目后需**告知用户手动将 WorkBuddy 的工作目录切换到 `~/short-drama-projects/<项目名>/`**，否则后续命令读写会落在错误目录。

老项目（<USER_REDACTED>《<PROJECT_REDACTED>》25 集等）保持原路径，不强制迁移。

## 向后兼容规则（强制）

`/开始` 首步必须判断当前工作目录状态。支持 `/开始 --new <项目名>` 强制走新建分支（绕过有 state 的自动加载）。

| cwd 状态 | 行为 |
|---|---|
| 有 `.drama-state.json` | 自动加载旧项目，输出"欢迎回来：《{dramaTitle}》，当前阶段 {currentStep}，已完成 {completedCount}/{totalEpisodes}。继续创作：`/分集 {下一集}` 或对应阶段命令。如要新建剧本，切换到其他目录再 `/开始`，或输入 `/开始 --new <新项目名>`"。停在此等用户指令，不进 Step 2（零迁移） |
| 无 `.drama-state.json`，cwd 非空（有其他文件） | 警告"当前目录已有其他文件，继续会在 `~/short-drama-projects/<项目名>/` 新建子目录（不污染当前 cwd）。是否继续？（输入项目名确认 / 回复'取消'退出）"。用户给项目名则走下条分支流程 |
| 无 `.drama-state.json`，cwd 空/不存在 | 询问项目名 → `mkdir -p ~/short-drama-projects/<项目名>/` → 提示用户切换工作目录 → 进入 Step 2 |

**关键原则**：
- 有 state 文件就信任该文件，不硬性要求迁移到标准位置
- 非空 cwd 永远建子目录而不污染——小白用户在桌面直接 `/开始` 也不会产生混乱

## `/项目列表` 实现约定

调用 `python3 {skill目录}/scripts/list_projects.py`，脚本行为：

1. 扫描 `~/short-drama-projects/*/`（默认位置），支持 `--dir <自定义路径>` 覆盖
2. 每个子目录若含 `.drama-state.json`，读取关键字段：`dramaTitle` / `currentStep` / `completedEpisodes` / `totalEpisodes`
3. 取目录 `mtime` 作为最近修改时间
4. 输出 Markdown 表格或纯文本表格（stdout）
5. 无匹配项目时输出"暂无项目，使用 `/开始` 创建第一个项目"

缺失字段用 `-` 占位，不报错。脚本不修改任何文件。

## `/项目状态` 实现约定

在 cwd 为项目目录的前提下：

1. 读取 `.drama-state.json`，不存在则提示"当前目录不是 short-drama 项目，使用 `/开始` 初始化"
2. 根据字段组装 `README.md`，模板见 `output-templates.md#README`
3. 覆盖写入 `README.md`（文件内的"本文件由 `/项目状态` 自动生成"注释说明可被覆盖）
4. 输出"README.md 已更新"

## 跨平台路径处理（强制）

- 所有 Python 脚本使用 `pathlib.Path` 而非字符串拼接
- 涉及 `~` 展开时用 `Path.home()` 或 `Path.expanduser()`
- 中文路径必须确保以 UTF-8 处理（Python 3 默认即 UTF-8，但 Windows 某些 shell 需额外 `encoding='utf-8'`）
- 脚本 shebang 统一 `#!/usr/bin/env python3`

## 反模式（禁止）

- 硬编码绝对路径（如 `/Users/xxx/short-drama-projects/`）
- 假设 skill 和项目在同一目录下（项目目录 ≠ skill 目录）
- `/开始` 直接强制迁移老项目到 `~/short-drama-projects/`
- 在 cwd 已有 `.drama-state.json` 时仍询问项目名

## 迭代记录

- 2026-04-20 首版：新用户 WorkBuddy Windows 提出项目管理诉求，引入项目目录约定 + 向后兼容 + `/项目列表` `/项目状态` 两条命令。
