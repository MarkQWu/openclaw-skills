#!/bin/bash
# release.sh: 一键发布 — VERSION + README + CHANGELOG检查 + commit + tag + push + 同步
set -euo pipefail

VERSION="$1"
SUMMARY="${2:-}"  # 可选：一句话摘要（用于 README 第192行）

if [ -z "$VERSION" ] || ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "用法: bin/release.sh <版本号> [一句话摘要]"
  echo "  例: bin/release.sh 1.10.0 '红果过稿标准编码 + 自检评分校准'"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)

# 平台检测（sed -i 兼容）
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_I="sed -i ''"
else
  SED_I="sed -i"
fi

echo "📦 发布 v${VERSION} ..."

# 1. 写 VERSION
echo "$VERSION" > short-drama/VERSION
echo "  ✅ VERSION → ${VERSION}"

# 2. 更新 README 第3行（版本号+日期）
sed -i '' "s/\*\*当前版本：v[0-9]*\.[0-9]*\.[0-9]*\*\*（[0-9-]*）/**当前版本：v${VERSION}**（${TODAY}）/" README.md
echo "  ✅ README 第3行 → v${VERSION}（${TODAY}）"

# 3. 更新 README 第192行（最新版本行）
if [ -n "$SUMMARY" ]; then
  sed -i '' "s/最新版本：\*\*v[0-9]*\.[0-9]*\.[0-9]*\*\*（[^）]*）—.*/最新版本：**v${VERSION}**（${TODAY}）— ${SUMMARY}/" README.md
  echo "  ✅ README 第192行 → v${VERSION} — ${SUMMARY}"
else
  sed -i '' "s/最新版本：\*\*v[0-9]*\.[0-9]*\.[0-9]*\*\*（[^）]*）—.*/最新版本：**v${VERSION}**（${TODAY}）— 见 CHANGELOG.md/" README.md
  echo "  ⚠️  README 第192行 → v${VERSION}（未提供摘要，默认指向 CHANGELOG）"
fi

# 4. CHANGELOG 检查
if ! grep -q "## ${TODAY} · v${VERSION%%.*}.${VERSION#*.}" CHANGELOG.md 2>/dev/null; then
  echo ""
  echo "  ⚠️  CHANGELOG.md 中未找到 v${VERSION} 条目"
  echo "  请确认 CHANGELOG.md 已手动更新后继续"
  read -p "  按回车继续，或 Ctrl+C 取消: "
fi

# 5. Stage + commit + tag
git add short-drama/VERSION README.md CHANGELOG.md
git commit -m "release: v${VERSION} — ${SUMMARY:-见 CHANGELOG.md}"
git tag "v${VERSION}"
echo "  ✅ commit + tag v${VERSION}"

# 6. Push
git push origin main --tags
echo "  ✅ 已推送到 GitHub"

# 7. 同步安装位置
TARGETS=(
  "$HOME/.claude/skills/short-drama"
  "$HOME/.workbuddy/skills/short-drama"
  "$HOME/.openclaw/skills/short-drama"
)

echo ""
echo "📂 同步安装位置..."

for target in "${TARGETS[@]}"; do
  if [ -d "$target" ]; then
    rsync -a --delete short-drama/ "$target/"
    echo "  ✅ $target"
  else
    echo "  ⏭️  跳过 $target（目录不存在）"
  fi
done

# .tools/ 克隆（git pull）
TOOLS_DIR="$HOME/碳基生命数据库/.tools/openclaw-skills"
if [ -d "$TOOLS_DIR/.git" ]; then
  (cd "$TOOLS_DIR" && git pull origin main --quiet)
  echo "  ✅ $TOOLS_DIR (git pull)"
else
  echo "  ⏭️  跳过 $TOOLS_DIR（非 git 仓库）"
fi

# 8. 验证
echo ""
echo "🔍 验证版本一致性..."
FAIL=0
for target in "${TARGETS[@]}"; do
  if [ -d "$target" ]; then
    TARGET_VER=$(cat "$target/VERSION" 2>/dev/null || echo "missing")
    if [ "$TARGET_VER" != "$VERSION" ]; then
      echo "  ❌ $target → $TARGET_VER (期望 $VERSION)"
      FAIL=1
    fi
  fi
done

if [ -d "$TOOLS_DIR" ]; then
  TOOLS_VER=$(cat "$TOOLS_DIR/short-drama/VERSION" 2>/dev/null || echo "missing")
  if [ "$TOOLS_VER" != "$VERSION" ]; then
    echo "  ❌ $TOOLS_DIR → $TOOLS_VER (期望 $VERSION)"
    FAIL=1
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "  ✅ 所有位置版本一致：v${VERSION}"
else
  echo "  ⚠️  存在版本不一致，请手动检查"
fi

echo ""
echo "🎉 v${VERSION} 发布完成！"
