#!/usr/bin/env bash
# gobuildit 社区 Skills 一键安装
set -euo pipefail

REPO_GITHUB="https://github.com/MarkQWu/openclaw-skills.git"
REPO_MIRROR="https://ghfast.top/https://github.com/MarkQWu/openclaw-skills.git"
CACHE="$HOME/.claude/.skill-repos/openclaw-skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
OPENCLAW_SKILLS_DIR="$HOME/.openclaw/skills"

echo "=== gobuildit Skills 安装器 ==="
echo ""

# 检查 git
if ! command -v git &>/dev/null; then
  echo "错误：未找到 git，请先安装 git（https://git-scm.com）"
  exit 1
fi

# 尝试 clone，GitHub 失败则自动切镜像
try_clone() {
  local dest="$1"
  echo "正在下载..."
  if git clone "$REPO_GITHUB" "$dest" 2>/dev/null; then
    return 0
  fi
  echo "GitHub 连接失败，切换镜像源..."
  if git clone "$REPO_MIRROR" "$dest" 2>/dev/null; then
    # 把 remote 改回 GitHub（镜像只用于首次下载）
    git -C "$dest" remote set-url origin "$REPO_GITHUB"
    return 0
  fi
  echo ""
  echo "错误：下载失败。请开启全局代理后重试，或手动下载：" >&2
  echo "  https://github.com/MarkQWu/openclaw-skills/archive/refs/heads/main.zip" >&2
  return 1
}

# 尝试 pull，GitHub 失败则通过镜像 fetch
try_pull() {
  local dir="$1"
  echo "检测到已安装，正在更新..."
  if git -C "$dir" pull --ff-only 2>/dev/null; then
    return 0
  fi
  # pull 失败：可能是网络问题或本地有改动
  # 先试镜像
  echo "GitHub 连接失败，切换镜像源..."
  git -C "$dir" remote set-url origin "$REPO_MIRROR"
  if git -C "$dir" pull --ff-only 2>/dev/null; then
    git -C "$dir" remote set-url origin "$REPO_GITHUB"
    return 0
  fi
  git -C "$dir" remote set-url origin "$REPO_GITHUB"
  # 镜像也失败，重新 clone
  echo "更新失败，正在重新安装..."
  rm -rf "$dir"
  try_clone "$dir"
}

# Clone 或更新仓库到缓存目录
mkdir -p "$(dirname "$CACHE")"
if [ -d "$CACHE/.git" ]; then
  try_pull "$CACHE"
else
  [ -d "$CACHE" ] && rm -rf "$CACHE"
  try_clone "$CACHE"
fi

# 检测平台并安装到对应目录
installed=0
targets=()

# Claude Code
if [ -d "$HOME/.claude" ]; then
  mkdir -p "$CLAUDE_SKILLS_DIR"
  targets+=("$CLAUDE_SKILLS_DIR")
fi

# OpenClaw / WorkBuddy / Codex CLI / Gemini CLI（统一 ~/<root>/skills 模式）
for ocdir in "$HOME/.openclaw" "$HOME/.workbuddy" "$HOME/.codex" "$HOME/.gemini"; do
  if [ -d "$ocdir" ]; then
    oc_skills="$ocdir/skills"
    mkdir -p "$oc_skills"
    targets+=("$oc_skills")
  fi
done

# 都没检测到，默认装 Claude Code 目录
if [ ${#targets[@]} -eq 0 ]; then
  mkdir -p "$CLAUDE_SKILLS_DIR"
  targets+=("$CLAUDE_SKILLS_DIR")
fi

for skills_dir in "${targets[@]}"; do
  for d in "$CACHE"/*/; do
    if [ -f "$d/SKILL.md" ]; then
      skill_name="$(basename "$d")"
      target="$skills_dir/$skill_name"
      rm -rf "$target"
      cp -r "$d" "$target"
      installed=$((installed + 1))
    fi
  done
done

# 设置可执行权限（bin/ 目录下的脚本）
for skills_dir in "${targets[@]}"; do
  for d in "$skills_dir"/*/; do
    if [ -d "$d/bin" ]; then
      chmod +x "$d/bin/"* 2>/dev/null || true
    fi
  done
done

# 读取版本号（来自仓库 VERSION 文件，由发版流程维护）
version=""
for d in "$CACHE"/*/; do
  if [ -f "$d/VERSION" ]; then
    version="$(head -1 "$d/VERSION" 2>/dev/null)"
    break
  fi
done
[ -z "$version" ] && version=$(git -C "$CACHE" log -1 --format="%h" 2>/dev/null || echo "unknown")

echo ""
if [ "$installed" -gt 0 ]; then
  echo "安装成功！"
  for t in "${targets[@]}"; do
    echo "  → $t"
  done
  echo ""
  echo "版本：$version"
  echo ""
  echo "关闭当前 Claude Code / OpenClaw 会话，重新打开后输入 /开始 即可使用。"
else
  echo "警告：未找到任何 Skill，请检查仓库内容。"
fi
