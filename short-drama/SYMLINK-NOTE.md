# Symlink Notice — 短剧 skill 双端管理

> 自 2026-04-28 起，Codex 端 (`~/.codex/skills/short-drama/`) 是 symlink 指向本目录 (`~/.claude/skills/short-drama/`)。

## ⚠️ 不要在 Codex 端本地编辑

Codex 端任何"修改"实际都是修改本目录。请只在 `~/.claude/skills/short-drama/` 编辑。

## 验证 symlink

```bash
readlink ~/.codex/skills/short-drama
# 应输出：/Users/gobuildit/.claude/skills/short-drama
```

月度软验证（防 Codex 升级覆盖）见 `~/.claude/plans/agents-md-two-layer-migration-2026-04-28.md` §11.5。

## 历史

迁移前 Codex 端为 copy（VERSION 1.19.1），落后 Claude 端 (1.20.0) 一个版本。原 copy 已移到 `~/.claude/.trash/2026-04-28_codex-short-drama-pre-symlink/`，30 天后清理。

## short-drama-overseas

同样以 symlink 方式从 `~/.claude/skills/short-drama-overseas/` 暴露到 Codex 端。
