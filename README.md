# openclaw-skills

gobuildit 社区精选 Claude Code Skills。

## 安装方式

### 安装全部 skills

```bash
git clone https://github.com/MarkQWu/openclaw-skills.git ~/.claude/skills/openclaw-skills
```

### 只安装单个 skill

```bash
# 以短剧编剧为例
git clone --depth 1 --filter=blob:none --sparse https://github.com/MarkQWu/openclaw-skills.git ~/.claude/skills/openclaw-skills
cd ~/.claude/skills/openclaw-skills
git sparse-checkout set short-drama
```

安装后重启 Claude Code 即可使用。

## Skills 列表

| Skill | 说明 | 命令 |
|-------|------|------|
| [short-drama](./short-drama/) | 微短剧剧本创作（50-100集），支持国内/出海双模式 | `/开始` `/创作方案` `/角色开发` `/目录` `/分集` `/自检` `/合规` `/导出` |

## 致谢

- short-drama 基于 [0xsline/short-drama](https://github.com/0xsline/short-drama)（MIT License）定制
