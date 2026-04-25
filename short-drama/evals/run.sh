#!/usr/bin/env bash
# short-drama skill 评测半手动 runner
#
# 用法：
#   bash evals/run.sh <project-dir> <sample-name>
#
# 例：
#   bash evals/run.sh ~/short-drama-projects/重回十八岁那年的盛夏 domestic-test
#   bash evals/run.sh ~/short-drama-projects/CEO-Hidden-Heir overseas-test
#
# 前置条件：
#   1. 已用 sample 内容跑完 /开始 → /创作方案 → /目录 → /分集 1 → /自检 1
#   2. 项目目录下有 episodes/ep001.md + reviews/ep001-review.md + creative-plan.md

set -uo pipefail

PROJECT_DIR="${1:-}"
SAMPLE="${2:-}"

if [[ -z "$PROJECT_DIR" || -z "$SAMPLE" ]]; then
  echo "用法：bash evals/run.sh <project-dir> <sample-name>"
  echo "  sample-name: domestic-test | overseas-test"
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "❌ 项目目录不存在：$PROJECT_DIR"
  exit 1
fi

EP1="$PROJECT_DIR/episodes/ep001.md"
REVIEW="$PROJECT_DIR/reviews/ep001-review.md"
PLAN="$PROJECT_DIR/creative-plan.md"

for f in "$EP1" "$REVIEW" "$PLAN"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ 缺文件：$f"
    echo "   请先跑完 /创作方案 + /分集 1 + /自检 1"
    exit 1
  fi
done

PASS=0
FAIL=0
NA=0

check() {
  local name="$1"
  local result="$2"
  local detail="${3:-}"
  case "$result" in
    PASS) echo "  ✅ $name PASS  $detail"; PASS=$((PASS+1));;
    FAIL) echo "  ❌ $name FAIL  $detail"; FAIL=$((FAIL+1));;
    NA)   echo "  ⚪ $name N/A   $detail"; NA=$((NA+1));;
    *)    echo "  ⚠️  $name UNKNOWN $detail";;
  esac
}

echo "=== short-drama skill eval: $SAMPLE ==="
echo "Project: $PROJECT_DIR"
echo ""

# 判定是否海外模式
IS_OVERSEAS=0
if grep -qE '"mode"\s*:\s*"overseas"' "$PROJECT_DIR/.drama-state.json" 2>/dev/null; then
  IS_OVERSEAS=1
fi

# A1: anchor 字段（仅 MVP 5 题材）
echo "## A1 anchor 字段触发"
if grep -qE "MVP 5|都市情感|重生穿越|古装宫廷|励志逆袭|悬疑探案" "$PLAN"; then
  if grep -qE "^## anchor|^### anchor|^- anchor:|anchor:" "$PLAN"; then
    check "A1" "PASS" "(creative-plan.md 含 anchor 字段)"
  else
    check "A1" "FAIL" "(MVP 5 题材但 creative-plan 缺 anchor 字段 → anchor-trigger.md 未生效)"
  fi
else
  check "A1" "NA" "(题材未命中 MVP 5)"
fi

# A2: 前 1/3 字数有冲突词
echo ""
echo "## A2 开场冲突字数位置"
TOTAL_CHARS=$(grep -v '^>' "$EP1" | grep -v '^---' | grep -v '^<!--' | wc -m | tr -d ' ')
THIRD=$((TOTAL_CHARS / 3))
HEAD_CONTENT=$(head -c $THIRD "$EP1")
CONFLICT_COUNT=$(echo "$HEAD_CONTENT" | grep -cE "打|撞|推|摔|抓|逃|追|跪|怒吼|咆哮|尖叫|怒斥|质问|背叛|撕破脸|当众|打脸|揭穿|血|刀|枪|急诊|trembling|frozen|shock|scream|grab|push|crash" || true)
if [[ "$CONFLICT_COUNT" -ge 1 ]]; then
  check "A2" "PASS" "(前 1/3 命中 $CONFLICT_COUNT 次冲突词)"
else
  check "A2" "FAIL" "(前 1/3 字数 0 冲突 → opening-rules.md 未生效)"
fi

# A3: 海外模式好莱坞格式（仅 overseas）
echo ""
echo "## A3 海外模式好莱坞格式 + 反中式弧"
if [[ "$IS_OVERSEAS" -eq 1 ]]; then
  INT_EXT=$(grep -cE "^INT\.|^EXT\." "$EP1" || true)
  SHOT=$(grep -cE "WIDE SHOT|CLOSE-UP|MEDIUM SHOT" "$EP1" || true)
  CHINESE_ARC=$(grep -cE "赘婿|逆袭|打脸|废柴|战神|神医归来|凤凰涅槃" "$EP1" || true)
  if [[ "$INT_EXT" -ge 2 && "$SHOT" -ge 1 && "$CHINESE_ARC" -eq 0 ]]; then
    check "A3" "PASS" "(INT/EXT=$INT_EXT, SHOT=$SHOT, 中式弧禁词=0)"
  else
    check "A3" "FAIL" "(INT/EXT=$INT_EXT, SHOT=$SHOT, 中式弧禁词=$CHINESE_ARC)"
  fi
else
  check "A3" "NA" "(mode=domestic)"
fi

# A4: 自检 7 维度齐全
echo ""
echo "## A4 自检 7 维度齐全"
DIM_COUNT=0
for dim in "节奏" "爽点" "台词" "格式与可拍性" "主线与连贯性" "反抽象" "AI Slop"; do
  if grep -q "$dim" "$REVIEW"; then
    DIM_COUNT=$((DIM_COUNT+1))
  else
    echo "    ⚠️ 缺维度：$dim"
  fi
done
if [[ "$DIM_COUNT" -ge 7 ]]; then
  check "A4" "PASS" "($DIM_COUNT/7 维度命中)"
else
  check "A4" "FAIL" "($DIM_COUNT/7 维度，缺 $((7-DIM_COUNT)) 个 → quality-rubric.md 未加载完整)"
fi

# A5: dramatic-truth 4 症状触发
echo ""
echo "## A5 dramatic-truth 4 症状触发（v1.19.0 新增）"
DT_COUNT=$(grep -cE "Trailer-Speak|Metaphor Overdose|As-You-Know-Bob|Urgency Mismatch" "$REVIEW" || true)
if [[ "$DT_COUNT" -ge 1 ]]; then
  check "A5" "PASS" "(4 症状清单中 $DT_COUNT 个被触发记录 → dramatic-truth.md 已加载)"
else
  check "A5" "FAIL" "(0 症状 → SKILL.md L300 引用 silent-fail，dramatic-truth.md 未读)"
fi

# A6: 中式表达扣分（仅 overseas）
echo ""
echo "## A6 海外模式中式表达扣分"
if [[ "$IS_OVERSEAS" -eq 1 ]]; then
  CN_EXPR_IN_EP1=$(grep -cE "心如刀绞|双瞳如墨|星眸|面如冠玉|肤白胜雪|提到嗓子眼|走马灯般|胸口憋着|魂七魄|骨头都酥|五脏六腑" "$EP1" || true)
  CN_EXPR_FLAGGED=$(grep -E "心如刀绞|双瞳如墨|星眸|面如冠玉|肤白胜雪|提到嗓子眼|走马灯般" "$REVIEW" 2>/dev/null | grep -cE "扣分|建议|【严重】|【建议】|改写|flagged|deduct" || true)
  if [[ "$CN_EXPR_IN_EP1" -eq 0 ]]; then
    check "A6" "NA" "(剧本未含中式表达 → 自检无需标记)"
  elif [[ "$CN_EXPR_FLAGGED" -ge 1 ]]; then
    check "A6" "PASS" "(剧本含 $CN_EXPR_IN_EP1 处中式表达，自检标记 $CN_EXPR_FLAGGED 处)"
  else
    check "A6" "FAIL" "(剧本含 $CN_EXPR_IN_EP1 处中式表达但自检 0 标记 → anti-patterns.md 禁词表失效)"
  fi
else
  check "A6" "NA" "(mode=domestic)"
fi

# 汇总
echo ""
echo "=== 汇总 ==="
echo "PASS: $PASS / FAIL: $FAIL / N/A: $NA"

if [[ "$FAIL" -gt 0 ]]; then
  echo "❌ 有 $FAIL 条断言不通过 — 检查上方 FAIL 详情"
  echo ""
  echo "建议下一步："
  echo "  1. 记录失败 case 到 baseline-vX.X.X.md"
  echo "  2. 调查根因（SKILL.md 引用断 / references/ 文件丢失 / 模型未读）"
  echo "  3. 修正后重跑"
  exit 1
fi

echo "✅ 全部断言通过（含 N/A）"
echo ""
echo "建议下一步："
echo "  1. 把本次结果记录为 baseline-vX.X.X.md（首次跑）或与上一 baseline 对比（回归测试）"
echo "  2. 主观维度（voice / 90s 节奏 / 平台适配感）人工评 1-10 也记录到 baseline"
exit 0
