#!/usr/bin/env bash
# gobuildit 社区 Skills 一键安装
set -euo pipefail

REPO="https://github.com/MarkQWu/openclaw-skills.git"
TARGET="$HOME/.claude/skills/openclaw-skills"

echo "=== gobuildit Skills 安装器 ==="
echo ""

# 检查 git
if ! command -v git &>/dev/null; then
  echo "错误：未找到 git，请先安装 git"
  exit 1
fi

# 安装或更新
if [ -d "$TARGET" ]; then
  echo "检测到已安装，正在更新..."
  git -C "$TARGET" pull --ff-only
else
  echo "正在安装到 $TARGET ..."
  mkdir -p "$(dirname "$TARGET")"
  git clone "$REPO" "$TARGET"
fi

echo ""
echo "安装成功！重启 Claude Code 后输入 /开始 即可使用短剧编剧 Skill"
echo ""
echo "已安装的 Skills："
for d in "$TARGET"/*/; do
  [ -f "$d/SKILL.md" ] && echo "  - $(basename "$d")"
done
