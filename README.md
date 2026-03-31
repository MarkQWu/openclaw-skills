# 爆款剧本工坊 | Drama Workshop

**当前版本：v1.5.0**（2026-03-31）· [更新日志](CHANGELOG.md)

用 AI 写能拍的微短剧——从选题到分镜，一条命令链走完。

支持 **Claude Code**、**OpenClaw** 和 **WorkBuddy**。

## 它能做什么

```
你的想法 → /开始 → /创作方案 → /角色开发 → /目录 → /分集 → /自检 → /导出
                                                                         ↓
                                              /角色卡 → /分镜 → 即梦 AI 生成视频
```

**剧本创作**：50-100 集完整微短剧，国内/出海双模式，自带爽点矩阵、付费卡点设计、节奏曲线控制

**质量管控**：AI Slop 检测（台词书面化/情绪转变过平滑/巧合堆砌）、7 维度 70 分自检、不合格阻断导出

**分镜输出**：剧本自动拆解为逐镜分镜表 + [即梦 AI](https://jimeng.jianying.com) prompt，复制粘贴直接生成视频

## 示例输出

**剧本片段**（`/分集` 生成）：

```
## 场次一

**场景：** 内景 · 总裁办公室 · 夜

△ （全景）落地窗外城市灯火，办公桌上摊开的文件被风吹动

**陆砚辰**（头也不抬）："门没锁。"

△ （中景）女主推门进来，手里攥着一张化验单，指节发白

**苏晚宁**（声音发抖）："陆砚辰，你看看这个。"

⚡ △ （特写）化验单上的名字——不是苏晚宁的

> 🎣 本集钩子：化验单上的名字是谁的？
```

**分镜片段**（`/分镜` 生成）：

| 镜号 | 景别 | 镜头运动 | 画面描述 | 角色动作 | 台词/音效 | 时长 | 转场 |
|------|------|---------|---------|---------|----------|------|------|
| 1 | 全景 | 缓推 | 雨夜高层办公室，落地窗外城市霓虹，文件被风吹起 | — | ♪ 低沉钢琴 | 3s | — |
| 2 | 中景→近景 | 跟拍 | 女主推门而入，手攥化验单，指节发白 | 推门，快步走入 | 苏晚宁：陆砚辰，你看看这个 | 4s | 硬切 |
| 3 | 特写 | 固定 | 化验单上的名字——不是苏晚宁的 | — | （无） | 2s | 闪白 |

每个镜头自动生成视频 prompt（即梦 AI「全能多参」模式——上传角色参考图 + 粘贴 prompt，一步生成视频）：

```
镜头 2：
  @图片1 作为角色参考。镜头从门口跟拍，年轻女性快步推门走入办公室，
  右手紧握白色纸张指节泛白，米色风衣下摆随动作摆动，走廊冷白灯光，
  电影质感，4K，同一角色，服装一致，发型不变
```

> 「全能多参」是即梦 Seedance 2.0 的视频生成模式，可以同时上传角色图 + 场景图 + 文字描述，一步出视频。不需要先生成图片再转视频。

## 安装

前置条件：
- 已安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code)、[OpenClaw](https://github.com/nicekate/OpenClaw) 或 [WorkBuddy](https://workbuddy.app) 中的任意一个
- 已安装 [git](https://git-scm.com/downloads)（点击链接下载，一路下一步即可）

### 方式一：一键安装（推荐）

**Mac / Linux**（打开终端，粘贴以下命令）：

```bash
curl -fsSL https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.sh | bash
```

**Windows**（按 `Win+X` → 选「终端」或「PowerShell」，粘贴以下命令）：

```powershell
irm https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.ps1 | iex
```

脚本会自动检测你装了 Claude Code、OpenClaw 还是 WorkBuddy（或多个都装了），把 skill 文件放到对应目录。

### 方式二：手动安装

如果你不想跑脚本，手动复制也行：

**Claude Code 用户：**

```bash
git clone https://github.com/MarkQWu/openclaw-skills.git
cp -r openclaw-skills/short-drama ~/.claude/skills/short-drama
```

**OpenClaw / WorkBuddy 用户：**

```bash
git clone https://github.com/MarkQWu/openclaw-skills.git
# OpenClaw:
cp -r openclaw-skills/short-drama ~/.openclaw/skills/short-drama
# WorkBuddy:
cp -r openclaw-skills/short-drama ~/.workbuddy/skills/short-drama
```

> 没有 skills 目录？先创建：`mkdir -p ~/.openclaw/skills`（或 `~/.workbuddy/skills`）

### 安装完成后

1. **关闭**当前会话
2. **重新打开**一个新会话
3. 输入 `/开始`，看到「选题定位」的引导就说明装好了

### 更新

**v1.5 起支持自动更新检测**：使用任何命令时，skill 会自动检查是否有新版本并提示你。

**方式一：输入 `/更新`**（推荐）

在对话框里直接输入：

```
/更新
```

AI 会检查最新版本，有更新则自动下载安装。更新完**重启会话**即可生效。

> 💡 首次升级到 v1.5 的用户需要先用下面的方式二或三手动更新一次，之后就能用 `/更新` 了。

**方式二：重新跑安装命令**

在**终端**（不是 AI 对话框）里跑：

**Mac / Linux：**

```bash
curl -fsSL https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.sh | bash
```

**Windows**（按 `Win+X` → 选「终端」）：

```powershell
irm https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.ps1 | iex
```

脚本会自动拉取最新版并覆盖旧文件。更新完**重启会话**即可生效。

**方式三：手动更新**

```bash
# 1. 更新缓存（所有平台通用）
git -C ~/.claude/.skill-repos/openclaw-skills pull

# 2. 复制到你的 skills 目录（选对应平台的一行）
cp -r ~/.claude/.skill-repos/openclaw-skills/short-drama ~/.claude/skills/short-drama        # Claude Code
cp -r ~/.claude/.skill-repos/openclaw-skills/short-drama ~/.workbuddy/skills/short-drama     # WorkBuddy
cp -r ~/.claude/.skill-repos/openclaw-skills/short-drama ~/.openclaw/skills/short-drama      # OpenClaw
```

### 常见问题

**Q：安装命令报错 / 下载失败**
A：国内网络可能连不上 GitHub。脚本会自动切换镜像源重试。如果镜像也失败：
1. 开全局代理（VPN 选「全局模式」而非「规则模式」）再重试
2. 或手动下载 zip：[点击下载](https://github.com/MarkQWu/openclaw-skills/archive/refs/heads/main.zip)，解压后把 `short-drama` 文件夹复制到 skills 目录

**Q：装完后输入 `/开始` 没反应**
A：确认关闭了旧会话并重新打开了新会话。Skill 只在新会话启动时加载。

**Q：怎么确认装的是最新版？**
A：输入 `/帮助`，底部会显示版本号。也可以打开 skill 目录下的 `VERSION` 文件查看。

**Q：WorkBuddy 用户怎么安装？**
A：在 PowerShell 终端里跑安装命令（不是在 WorkBuddy 对话框里粘贴）。WorkBuddy 对话框会把命令当聊天处理。

## 使用教程

### 第一次用：5 分钟写出第一集

```
你：/开始
AI：问你想写什么题材的短剧（霸总？甜宠？逆袭？），有故事想法可以直接说

你：我想写一个霸总剧，女主是替嫁新娘
AI：确认题材、受众、集数等配置

你：/创作方案
AI：生成完整故事骨架——三幕结构、付费卡点、爽点分布

你：/角色开发
AI：生成角色档案——每个角色的性格、语言风格、视觉描述、关系图

你：/目录
AI：生成全剧 50-100 集的分集目录，标注哪些是关键集、哪些是付费卡点

你：/分集 1
AI：写出第一集完整剧本——场景、台词、镜头提示全部到位

你：/自检 1
AI：7 个维度打分，告诉你哪里写得好、哪里要改、怎么改
```

### 从剧本到视频素材

```
你：/角色卡
AI：为每个角色生成视觉描述（外貌、穿搭），锁定角色形象一致性

你：/分镜 1
AI：把第一集拆成逐镜头的分镜表，每个镜头附带即梦 AI 的 prompt

→ 打开即梦 AI（jimeng.jianying.com）→ 选「全能参考」模式
→ 上传角色参考图 → 粘贴 prompt → 生成视频
→ 用剪映按分镜表顺序排列 → 加字幕配音 → 成片
```

### 常用技巧

- **批量写**：`/分集 5-8` 一次写 4 集
- **续写**：`/分集 next` 自动写下一集
- **自动修复**：`/自检 3 --fix` 检查完直接帮你改
- **出海模式**：`/出海` 切换英文 + 好莱坞剧本格式
- **只拆分镜**：`/分镜` 可以独立使用，不需要走完剧本全流程，直接粘贴任意文本就能拆

## 命令速查

### 剧本创作

| 命令 | 做什么 |
|------|--------|
| `/开始` | 选题材、定方向（支持自带故事梗概） |
| `/创作方案` | 生成三幕结构 + 爽点矩阵 + 付费卡点规划 |
| `/角色开发` | 角色档案 + 语言风格映射 + 称呼关系表 + 视觉提示词 |
| `/目录` | 全剧分集目录（标注🔥关键集 💰付费卡点集） |
| `/分集 {N}` | 写第 N 集剧本（支持 `/分集 5-8` 批量、`/分集 next` 续写） |
| `/自检 {N}` | 7 维度质量检查 + AI Slop 检测（支持 `--fix` 自动修复） |
| `/合规` | 国内发行合规审核 |
| `/导出` | 打包完整剧本（自检 <30 分的集数会被拦截） |
| `/出海` | 切换英文/好莱坞格式（ReelShort/DramaBox） |

### 分镜 & 视频

| 命令 | 做什么 |
|------|--------|
| `/角色卡` | 生成或导入角色视觉描述，锁定角色外观一致性 |
| `/分镜 {N}` | 剧本→逐镜分镜表 + [即梦 AI](https://jimeng.jianying.com) prompt（可独立使用，不依赖剧本流程） |
| `/工作流` | 打印完整创作→视频链路说明 |

## 工作流全景

```
Step 1  剧本创作        /开始 → /创作方案 → /角色开发 → /目录 → /分集 → /自检
Step 2  角色视觉设定    /角色卡
Step 3  分镜 + Prompt   /分镜 {N} → 复制 Prompt 汇总区
Step 4  视频生成        即梦 AI（jimeng.jianying.com）/ 可灵 / Pika
Step 5  剪辑成片        剪映 / CapCut（按分镜表排列 → 加字幕配音）
```

每个命令都可独立使用，不需要按顺序走完全流程。

## 更新日志

最新版本：**v1.5**（2026-03-31）— 分镜台词保真 + 景别自检

完整更新历史见 [CHANGELOG.md](./CHANGELOG.md)。

## 致谢

基于 [0xsline/short-drama](https://github.com/0xsline/short-drama)（MIT License）定制，由 [gobuildit](https://github.com/MarkQWu) 社区维护。
