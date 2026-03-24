# openclaw-skills

gobuildit 社区精选 Skills，兼容 Claude Code 和 OpenClaw。

## 一键安装

前置条件：已安装 [git](https://git-scm.com)。

**Mac / Linux：**

```bash
curl -fsSL https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.sh | bash
```

**Windows（请使用 PowerShell，不支持 cmd）：**

```powershell
irm https://raw.githubusercontent.com/MarkQWu/openclaw-skills/main/install.ps1 | iex
```

安装后关闭当前会话，重新打开 Claude Code / OpenClaw，输入 `/开始` 即可使用。

> 已安装过？再跑一次同样的命令会自动更新到最新版。

## Skills 列表

| Skill | 说明 | 命令 |
|-------|------|------|
| [爆款剧本工坊](./short-drama/) | 微短剧剧本创作（50-100集），支持国内/出海双模式 | `/开始` `/创作方案` `/角色开发` `/目录` `/分集` `/自检` `/合规` `/导出` |

## 更新日志

### 2026-03-24 · 爆款剧本工坊 v1.1

**新增：真实感检查体系**（基于甲方实战反馈提炼）

- `/开始` 新增**故事捕获**：先问用户有没有故事想法，有则以此为骨架，不被题材模板覆盖
- `/创作方案` 新增**主题意图确认**、**社交场景预设**、**双层结构**（表面走向 vs 真实走向，适合反转型剧本）
- `/角色开发` 新增**称呼关系表**（N×N 矩阵，防止称呼混乱）、**角色盲点/弱点**（避免脸谱化）、**表面功能 vs 真实功能**
- `/分集` 质量要求新增 5 条真实感检查（称呼逻辑、因果触发、关系生活化、转折铺垫、场景逻辑）
- `/自检` 台词+连贯性维度嵌入真实感子检查项
- 新增 `references/realism-checklist.md` 参考文档，含多题材适用性矩阵

**更名**：short-drama → 爆款剧本工坊 | Drama Workshop

## 致谢

- 爆款剧本工坊基于 [0xsline/short-drama](https://github.com/0xsline/short-drama)（MIT License）定制
