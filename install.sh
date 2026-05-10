#!/usr/bin/env bash
# gobuildit 社区 Skills 一键安装
set -euo pipefail

REPO_GITHUB="${DRAMA_WORKSHOP_REPO_GIT:-https://github.com/MarkQWu/drama-workshop-skills.git}"
REPO_MIRROR="${DRAMA_WORKSHOP_REPO_GIT_MIRROR:-https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills.git}"
REPO_ZIP="${DRAMA_WORKSHOP_REPO_ZIP:-https://github.com/MarkQWu/drama-workshop-skills/archive/refs/heads/main.zip}"
REPO_ZIP_CODELOAD="${DRAMA_WORKSHOP_REPO_ZIP_CODELOAD:-https://codeload.github.com/MarkQWu/drama-workshop-skills/zip/refs/heads/main}"
REPO_ZIP_MIRROR="${DRAMA_WORKSHOP_REPO_ZIP_MIRROR:-https://ghfast.top/https://github.com/MarkQWu/drama-workshop-skills/archive/refs/heads/main.zip}"
REPO_ZIP_CODELOAD_MIRROR="${DRAMA_WORKSHOP_REPO_ZIP_CODELOAD_MIRROR:-https://ghfast.top/https://codeload.github.com/MarkQWu/drama-workshop-skills/zip/refs/heads/main}"
CACHE="${DRAMA_WORKSHOP_CACHE:-$HOME/.claude/.skill-repos/drama-workshop-skills}"
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

download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --connect-timeout 10 --max-time 90 "$url" -o "$dest" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      return 0
    fi
    curl --noproxy '*' -fL --connect-timeout 10 --max-time 90 "$url" -o "$dest" >/dev/null 2>&1
    return $?
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$dest" >/dev/null 2>&1
    return $?
  fi
  return 1
}

try_zip_download() {
  local dest="$1"
  local tmp zip extracted url

  if ! command -v unzip >/dev/null 2>&1; then
    return 1
  fi

  tmp="$(mktemp -d "${TMPDIR:-/tmp}/drama-workshop-skills.XXXXXX")"
  zip="$tmp/main.zip"

  echo "正在下载仓库 zip（不需要 git）..."
  for url in "$REPO_ZIP" "$REPO_ZIP_CODELOAD" "$REPO_ZIP_MIRROR" "$REPO_ZIP_CODELOAD_MIRROR"; do
    if download_file "$url" "$zip"; then
      if unzip -q "$zip" -d "$tmp" 2>/dev/null; then
        extracted="$(find "$tmp" -maxdepth 1 -type d -name 'drama-workshop-skills-*' | head -1)"
        if [ -d "$extracted" ]; then
          [ -d "$dest" ] && mv "$dest" "$dest.backup-$(timestamp)" 2>/dev/null || true
          mv "$extracted" "$dest"
          echo "仓库 zip 下载完成。"
          return 0
        fi
      fi
    fi
    echo "下载失败，尝试下一个源..."
  done

  return 1
}

# 尝试 clone，GitHub 失败则自动切镜像
try_clone() {
  local dest="$1"
  if ! command -v git &>/dev/null; then
    return 1
  fi
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
  echo "git 下载失败，继续使用 zip 下载结果或最终错误提示。" >&2
  return 1
}

# 尝试 pull，GitHub 失败则通过镜像 fetch
try_pull() {
  local dir="$1"
  if ! command -v git &>/dev/null; then
    return 1
  fi
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
  try_zip_download "$dir" || {
    rm -rf "$dir"
    try_clone "$dir"
  }
}

# 下载或更新仓库到缓存目录。zip 优先，避免用户机器没有 git 或 git 被网络拦截。
mkdir -p "$(dirname "$CACHE")"
download_ok=0
if try_zip_download "$CACHE"; then
  download_ok=1
elif [ -d "$CACHE/.git" ] && try_pull "$CACHE"; then
  download_ok=1
else
  [ -d "$CACHE" ] && mv "$CACHE" "$CACHE.backup-$(timestamp)" 2>/dev/null || true
  if try_clone "$CACHE"; then
    download_ok=1
  fi
fi

if [ "$download_ok" -ne 1 ] || [ ! -d "$CACHE" ]; then
  echo ""
  echo "错误：下载失败。可把以下链接复制给 WorkBuddy，让它直接下载 zip 后解压安装：" >&2
  echo "  $REPO_ZIP_CODELOAD_MIRROR" >&2
  echo "  $REPO_ZIP_MIRROR" >&2
  echo "  $REPO_ZIP_CODELOAD" >&2
  echo "  $REPO_ZIP" >&2
  echo "也可以先安装 Git：https://git-scm.com/downloads，然后重新运行安装命令。" >&2
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
        mv "$target" "$safe_root/reinstall-$skill_name-$(timestamp)" 2>/dev/null || rm -rf "$target"
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
