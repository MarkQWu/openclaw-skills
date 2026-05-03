#!/bin/bash
# release.sh: 一键发布 — 更新 master VERSION → sync 5 副本 → 更新 README → commit + tag + push → GH Actions 自动建 Release
set -euo pipefail

VERSION="${1:-}"
SUMMARY="${2:-}"
USER_MSG="${3:-}"   # 用户可见的更新通知文案（写进 WHATSNEW.md）；不传则用 SUMMARY

if [ -z "$VERSION" ] || ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "用法: release.sh <版本号> [commit摘要] [用户通知文案]"
  echo "  例: release.sh 1.28.0 '新增更新提醒功能' \\"
  echo "       '⚠️ 两个命令改名了：/创作方案→/策划，/目录→/分集目录'"
  echo "  注：第3个参数写给用户看（展示在 skill 里），第2个参数写进 git commit message"
  exit 1
fi

TODAY=$(date +%Y-%m-%d)
MASTER_DIR="$HOME/.claude/skills/short-drama"
REPO_DIR="$HOME/.claude/.skill-repos/openclaw-skills"

if [ ! -d "$MASTER_DIR" ]; then
  echo "❌ 权威 master 目录不存在：$MASTER_DIR"
  exit 1
fi

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "❌ openclaw-skills 仓库不存在：$REPO_DIR"
  exit 1
fi

echo "📦 发布 v${VERSION} ..."

# 1.5 · NLPM lint gate（起源：2026-04-22 xiaolai NLPM 交互学习落地）
echo ""
echo "🔍 结构检查（skill-lint）..."
LINT_SCRIPT="$HOME/.claude/scripts/skill-lint.sh"
if [ ! -x "$LINT_SCRIPT" ]; then
  echo "  ⚠️  skill-lint.sh 不存在或不可执行，跳过 lint（$LINT_SCRIPT）"
else
  if ! bash "$LINT_SCRIPT" "$MASTER_DIR"; then
    echo ""
    echo "  ❌ lint 未通过，release 已中止。修复结构问题后重跑。"
    exit 1
  fi
  echo "  ✅ lint 通过"
fi

# 1. 更新权威 master 的 VERSION
echo "$VERSION" > "$MASTER_DIR/VERSION"
echo "  ✅ master VERSION → ${VERSION}"

# 1.6 · 写 WHATSNEW.md（sync 前写入 master，会被 sync 带到所有副本）
# USER_MSG 优先；无 USER_MSG 则 fallback 到 SUMMARY；两者都无则只写版本号
NOTICE_BODY="${USER_MSG:-${SUMMARY:-}}"
if [ -n "$NOTICE_BODY" ]; then
  printf "**v%s**（%s）\n\n%s\n\n输入 \`/帮助\` 查看全部命令\n" \
    "$VERSION" "$TODAY" "$NOTICE_BODY" > "$MASTER_DIR/WHATSNEW.md"
else
  printf "**v%s**（%s）\n\n输入 \`/帮助\` 查看全部命令\n" \
    "$VERSION" "$TODAY" > "$MASTER_DIR/WHATSNEW.md"
fi
echo "  ✅ WHATSNEW.md → v${VERSION}"

# 2. Sync master → 5 副本（含 openclaw-skills 仓库）
echo ""
echo "📂 Sync master → 5 副本..."
bash "$MASTER_DIR/scripts/sync-all-locations.sh"

# 3. 切到 openclaw-skills 仓库，更新 README 并提交
cd "$REPO_DIR"

# README 第 3 行（版本号 + 日期）
sed -i '' "s/\*\*当前版本：v[0-9]*\.[0-9]*\.[0-9]*\*\*（[0-9-]*）/**当前版本：v${VERSION}**（${TODAY}）/" README.md
echo "  ✅ README 第 3 行 → v${VERSION}（${TODAY}）"

# README 最新版本行（用 Python 替换，避免 macOS sed 多字节字符替换 bug）
if [ -n "$SUMMARY" ]; then
  python3 -c "
import re, sys
version, today, summary = sys.argv[1], sys.argv[2], sys.argv[3]
content = open('README.md').read()
pattern = r'最新版本：\*\*v[0-9]+\.[0-9]+\.[0-9]+\*\*（[^）]*）—.*'
replacement = f'最新版本：**v{version}**（{today}）— {summary}'
content = re.sub(pattern, replacement, content)
open('README.md', 'w').write(content)
" "$VERSION" "$TODAY" "$SUMMARY"
  echo "  ✅ README 最新版本行 → v${VERSION} — ${SUMMARY}"
else
  python3 -c "
import re, sys
version, today = sys.argv[1], sys.argv[2]
content = open('README.md').read()
pattern = r'最新版本：\*\*v[0-9]+\.[0-9]+\.[0-9]+\*\*（[^）]*）—.*'
replacement = f'最新版本：**v{version}**（{today}）— 见 commit 与 GitHub Release'
content = re.sub(pattern, replacement, content)
open('README.md', 'w').write(content)
" "$VERSION" "$TODAY"
  echo "  ⚠️  README 最新版本行 → v${VERSION}（未提供摘要）"
fi

# 4. Stage + commit + tag（包含 sync 带来的 short-drama/ 变化）
git add short-drama README.md
git commit -m "release: v${VERSION} — ${SUMMARY:-see commit and GitHub Release}"
git tag "v${VERSION}"
echo "  ✅ commit + tag v${VERSION}"

# 5. Push main + tag（tag push 触发 GH Actions workflow 建 Release）
git push origin main --tags
echo "  ✅ 已推送到 GitHub"

# 6. 等 GH Actions workflow 并验证 Release 建立
echo ""
echo "⏳ 等待 GH Actions workflow 建 Release（15s）..."
sleep 15

if ! gh release view "v${VERSION}" --repo MarkQWu/openclaw-skills > /dev/null 2>&1; then
  echo "  ⚠️  Release v${VERSION} 未建 — GH Actions workflow 可能失败或延迟"
  echo "      查看运行日志：gh run list --repo MarkQWu/openclaw-skills --limit 3"
  echo "      手动补建：gh release create v${VERSION} --repo MarkQWu/openclaw-skills --generate-notes"
else
  echo "  ✅ Release v${VERSION} 已建立"
fi

# 7. 完工提醒
echo ""
echo "🎉 v${VERSION} 发布完成！"
echo ""
echo "🔔 人工环节提醒："
echo "   1. 使用说明.md / 使用说明.html 是否需要同步新功能？"
echo "   2. 飞书知识库是否同步？"
echo "   3. 其他引用 skill 版本号的外部文档（README 镜像、个人 notes、知识库节点）是否需要同步？"
echo "      若文档里写了具体版本号，考虑改为指针叙事（引用 VERSION 文件）避免下次陈旧"
echo ""
echo "📣 是否需要对外宣传？"
echo "   判断：用户可感知的功能变化？→ 宣传。纯重构/内部优化？→ 跳过。"
echo ""
echo "   宣传动作（按需选）："
echo "   1. 群内通知：一句话 + 亮点截图"
echo "   2. 公众号 post：功能展示 + 使用前后对比"
echo "   3. 用户 DM：针对会用到这个功能的活跃用户单独通知"
