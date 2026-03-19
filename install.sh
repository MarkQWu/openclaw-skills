#!/usr/bin/env bash
# gobuildit 社区 Skills 一键安装
set -euo pipefail

REPO="https://github.com/MarkQWu/openclaw-skills.git"
CACHE="$HOME/.claude/.skill-repos/openclaw-skills"
SKILLS_DIR="$HOME/.claude/skills"

echo "=== gobuildit Skills 安装器 ==="
echo ""

# 检查 git
if ! command -v git &>/dev/null; then
  echo "错误：未找到 git，请先安装 git（https://git-scm.com）"
  exit 1
fi

# Clone 或更新仓库到缓存目录
mkdir -p "$SKILLS_DIR"
if [ -d "$CACHE" ]; then
  echo "检测到已安装，正在更新..."
  if ! git -C "$CACHE" pull --ff-only 2>/dev/null; then
    echo "更新失败（本地有改动），正在重新安装..."
    rm -rf "$CACHE"
    git clone "$REPO" "$CACHE"
  fi
else
  echo "正在下载..."
  mkdir -p "$(dirname "$CACHE")"
  git clone "$REPO" "$CACHE"
fi

# 将每个 skill 目录复制到 ~/.claude/skills/ 下（扁平化，保证一层可被发现）
installed=0
for d in "$CACHE"/*/; do
  if [ -f "$d/SKILL.md" ]; then
    skill_name="$(basename "$d")"
    target="$SKILLS_DIR/$skill_name"
    rm -rf "$target"
    cp -r "$d" "$target"
    echo "  已安装: $skill_name"
    installed=$((installed + 1))
  fi
done

echo ""
if [ "$installed" -gt 0 ]; then
  echo "安装成功！共 $installed 个 Skill。"
  echo "关闭当前 Claude Code / OpenClaw 会话，重新打开后输入 /开始 即可使用。"
else
  echo "警告：未找到任何 Skill，请检查仓库内容。"
fi
