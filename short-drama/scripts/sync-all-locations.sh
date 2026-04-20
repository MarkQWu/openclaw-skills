#!/usr/bin/env bash
# 将 master short-drama/ 同步到 4 个已知副本位置
#
# 使用场景：每次在 .tools/openclaw-skills/ 仓库 git push 后运行一次，
# 消除 5 副本不同步问题（详见 memory/feedback_openclaw-sync-all-locations.md）
#
# 用法：
#   bash scripts/sync-all-locations.sh          # 实际同步
#   bash scripts/sync-all-locations.sh --dry    # 预览将要做什么

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MASTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$MASTER_DIR/SKILL.md" ]]; then
  echo "❌ 未在 master short-drama 目录下：$MASTER_DIR" >&2
  exit 1
fi

DRY_RUN=""
if [[ "${1:-}" == "--dry" ]]; then
  DRY_RUN="--dry-run"
  echo "[DRY RUN] 不实际同步，仅展示将要做的操作"
fi

DESTINATIONS=(
  "$HOME/.claude/.skill-repos/openclaw-skills/short-drama"
  "$HOME/.claude/skills/short-drama"
  "$HOME/.workbuddy/skills/short-drama"
  "$HOME/.openclaw/skills/short-drama"
)

MASTER_VERSION=$(cat "$MASTER_DIR/VERSION" 2>/dev/null || echo "unknown")
echo "Master 版本: $MASTER_VERSION"
echo "Master 路径: $MASTER_DIR"
echo ""

SYNCED=0
SKIPPED=0
for DEST in "${DESTINATIONS[@]}"; do
  PARENT_DIR="$(dirname "$DEST")"

  if [[ ! -d "$PARENT_DIR" ]]; then
    echo "⚠ 跳过（父目录不存在）: $PARENT_DIR"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ -n "$DRY_RUN" ]]; then
    echo "[预览] rsync → $DEST"
    rsync -a --delete $DRY_RUN \
      --exclude='.git/' \
      --exclude='__pycache__/' \
      --exclude='*.pyc' \
      "$MASTER_DIR/" "$DEST/" | head -5
    continue
  fi

  mkdir -p "$DEST"
  rsync -a --delete \
    --exclude='.git/' \
    --exclude='__pycache__/' \
    --exclude='*.pyc' \
    "$MASTER_DIR/" "$DEST/"

  DEST_VERSION=$(cat "$DEST/VERSION" 2>/dev/null || echo "unknown")
  if [[ "$DEST_VERSION" == "$MASTER_VERSION" ]]; then
    echo "✅ $DEST (VERSION=$DEST_VERSION)"
    SYNCED=$((SYNCED + 1))
  else
    echo "❌ $DEST (同步后 VERSION=$DEST_VERSION ≠ master $MASTER_VERSION)" >&2
    SKIPPED=$((SKIPPED + 1))
  fi
done

echo ""
if [[ -n "$DRY_RUN" ]]; then
  echo "[DRY RUN 完毕] 共 ${#DESTINATIONS[@]} 个目标"
else
  echo "同步完成：$SYNCED 成功，$SKIPPED 跳过/失败（共 ${#DESTINATIONS[@]} 个）"
  echo ""
  echo "验证所有 5 副本（含 master）版本："
  echo "  $MASTER_DIR/VERSION → $MASTER_VERSION"
  for DEST in "${DESTINATIONS[@]}"; do
    if [[ -f "$DEST/VERSION" ]]; then
      printf "  %s/VERSION → %s\n" "$DEST" "$(cat "$DEST/VERSION")"
    fi
  done
fi
