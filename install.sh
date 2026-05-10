#!/usr/bin/env bash
# gobuildit 社区 Skills 一键安装
set -euo pipefail

REPO_GITHUB="https://github.com/MarkQWu/drama-workshop-skills.git"
REPO_MIRROR="https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills.git"
CACHE="$HOME/.claude/.skill-repos/drama-workshop-skills"
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
OPENCLAW_SKILLS_DIR="$HOME/.openclaw/skills"

echo "=== gobuildit Skills 安装器 ==="
echo ""

timestamp() {
  date +"%Y%m%d-%H%M%S"
}

migrate_embedded_trash() {
  local skills_dir="$1"
  local trash_dir="$skills_dir/.trash"

  if [ ! -d "$trash_dir" ]; then
    return 0
  fi

  # WorkBuddy may recursively scan every SKILL.md under skills/. Keep backups
  # outside the scanned skills tree so old skills cannot shadow current ones.
  local owner_dir
  owner_dir="$(dirname "$skills_dir")"
  local safe_root="$owner_dir/.skill-trash"
  local dest="$safe_root/from-skills-trash-$(timestamp)"

  mkdir -p "$safe_root"
  if [ -e "$dest" ]; then
    dest="$dest-$$"
  fi

  if mv "$trash_dir" "$dest" 2>/dev/null; then
    echo "  已迁移旧备份: $trash_dir → $dest"
  else
    echo "  警告：无法迁移 $trash_dir，请手动移出 skills 目录，避免旧 skill 被扫描。" >&2
  fi
}

if ! command -v git >/dev/null 2>&1; then
  echo "错误：未找到 git。请先安装 Git 后重新运行本安装命令。" >&2
  echo "" >&2
  echo "Mac 可运行：xcode-select --install" >&2
  echo "或安装 Homebrew 后运行：brew install git" >&2
  echo "Windows 可让 AI agent 运行：winget install --id Git.Git -e --source winget" >&2
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
  echo "错误：GitHub 下载失败。请打开全局代理后重新运行安装命令。" >&2
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
  mv "$dir" "$dir.backup-$(timestamp)" 2>/dev/null || return 1
  try_clone "$dir"
}

# Clone 或更新仓库到缓存目录
mkdir -p "$(dirname "$CACHE")"
if [ -d "$CACHE/.git" ]; then
  try_pull "$CACHE"
else
  [ -d "$CACHE" ] && mv "$CACHE" "$CACHE.backup-$(timestamp)" 2>/dev/null || true
  try_clone "$CACHE"
fi

if [ ! -d "$CACHE" ]; then
  echo ""
  echo "错误：下载失败。请确认已安装 Git，并打开全局代理后重新运行安装命令。" >&2
  exit 1
fi

# 检测平台并安装到对应目录
installed=0
targets=()

# Claude Code
if [ -d "$HOME/.claude" ]; then
  mkdir -p "$CLAUDE_SKILLS_DIR"
  targets+=("$CLAUDE_SKILLS_DIR")
fi

# OpenClaw / WorkBuddy
for ocdir in "$HOME/.openclaw" "$HOME/.workbuddy"; do
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
  migrate_embedded_trash "$skills_dir"
  for d in "$CACHE"/*/; do
    if [ -f "$d/SKILL.md" ]; then
      skill_name="$(basename "$d")"
      target="$skills_dir/$skill_name"
      if [ -e "$target" ] || [ -L "$target" ]; then
        safe_root="$(dirname "$skills_dir")/.skill-trash"
        mkdir -p "$safe_root"
        mv "$target" "$safe_root/reinstall-$skill_name-$(timestamp)" 2>/dev/null || {
          echo "  警告：无法备份旧目录 $target，请关闭占用它的程序后重试。" >&2
          continue
        }
      fi
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
if [ -f "$CACHE/short-drama/VERSION" ]; then
  version="$(head -1 "$CACHE/short-drama/VERSION" 2>/dev/null)"
else
  for d in "$CACHE"/*/; do
    if [ -f "$d/VERSION" ]; then
      version="$(head -1 "$d/VERSION" 2>/dev/null)"
      break
    fi
  done
fi
if [ -z "$version" ] && command -v git >/dev/null 2>&1; then
  version=$(git -C "$CACHE" log -1 --format="%h" 2>/dev/null || echo "unknown")
fi
[ -z "$version" ] && version="unknown"

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
  echo "WorkBuddy 用户：需要从工作空间移除/关闭当前项目再重新打开，单独新建对话可能仍沿用旧 skill 缓存。"
  echo "这不会删除 ~/short-drama-projects/ 下的剧本项目。"
else
  echo "警告：未找到任何 Skill，请检查仓库内容。"
fi
