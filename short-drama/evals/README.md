# short-drama skill 评测框架（evals）

> 让 skill 每次大改有数据可证明是否真提升，不靠"感觉"。

## 触发时机

| 改动级别 | 是否跑 eval |
|---|---|
| **Major release**（v1.X.0 → v2.0.0）| ✅ 强制跑 |
| **Minor release**（v1.18.x → v1.19.0）| ✅ 强制跑 |
| **Patch release**（v1.19.0 → v1.19.1）| ⚪ 不强制（除非 patch 改动了 SKILL.md 引用 / references/ 内容）|
| 单文件 reference 文档微调 | ⚪ 不需要 |

## 跑法

### 第一次跑（建立 v1.19.x baseline）

```bash
# 1. 用 sample 内容启动 skill 跑完一集流程
#    准备项目目录：~/short-drama-projects/<项目名>/
#    按 samples/domestic-test.md 或 samples/overseas-test.md 内容输入：
#    /开始 → /创作方案 → /角色开发 → /目录 → /分集 1 → /自检 1
#    （overseas 题材先 /出海 切换 mode）

# 2. 跑评测脚本
bash ~/.claude/skills/short-drama/evals/run.sh \
  ~/short-drama-projects/重回十八岁那年的盛夏 \
  domestic-test

# 3. 把输出写入 baseline 文件
mkdir -p ~/.claude/skills/short-drama/evals/baselines
cat > ~/.claude/skills/short-drama/evals/baselines/baseline-v1.19.0-domestic.md <<EOF
# Baseline v1.19.0 domestic-test
日期：YYYY-MM-DD

## run.sh 输出
[贴 run.sh 完整输出]

## 主观人工评分（1-10）
- voice 一致性：?
- 段落颗粒：?
- 90s 节奏适配：?

## 失败/异常 case
- ...
EOF
```

### 后续 release（与 baseline 对比）

```bash
# 1. 用同一 sample 在新版本下重跑（同样 sample 内容 + 新 SKILL.md）
# 2. 跑 run.sh 拿新结果
# 3. diff baseline vs 新结果，看是否回归
diff \
  ~/.claude/skills/short-drama/evals/baselines/baseline-v1.19.0-domestic.md \
  ~/.claude/skills/short-drama/evals/baselines/baseline-v1.20.0-domestic.md
```

## 6 条断言（assertions.md 完整定义）

| ID | 类型 | 简述 |
|---|---|---|
| A1 | mech | anchor 字段触发（全 13 题材时 creative-plan 含 anchor） |
| A2 | mech | 开场前 1/3 字数有冲突词 |
| A3 | mech (overseas) | 海外模式好莱坞格式 + 反中式 humiliation→power 弧 |
| A4 | mech | 自检 7 维度齐全 |
| A5 | mixed | dramatic-truth 4 症状校验被触发（v1.19.0 新增） |
| A6 | mixed (overseas) | 海外模式中式直译扣分扫描 |

## 限制（明确边界）

- **不替代人工评**：voice 一致性 / 情感真实度 / 90s 节奏适配 这种主观维度仍需人工评分，eval 仅扫机器可检查项
- **不预跑 baseline**：v1.19.0 ship 时本框架建立但未跑——下次有人写一集本子时第一次跑 = v1.19.0 baseline
- **不覆盖跨集场景**：当前只测 ep1，跨集 used-lines 复用扫描 / 50 集长剧上下文窗口管理 等暂不在 assertion 内
- **题材覆盖窄**：仅 1 国内重生穿越 + 1 海外 Billionaire Romance，其他题材（古装/悬疑/末日/萌宝）后续按需扩

## 扩展原则

新增 assertion 时遵循：

1. **优先机器可检查**（grep / 正则 / 字数统计）
2. **半机器**（grep 触发 + 人工裁定）只用于 dramatic-truth 这种 LLM 主观维度
3. **不预设答案**——assertion 描述"应当出现/不应当出现"，不规定具体分数
4. **失败可定位根因**——每条 assertion 不通过都要写"diagnose 提示"指向 SKILL.md/references/ 具体位置

## 关键文件清单

```
evals/
├── README.md          ← 本文件
├── assertions.md      ← 6 条断言完整定义
├── run.sh             ← 半手动 runner（chmod +x）
├── samples/
│   ├── domestic-test.md   ← 国内固定 input（重生穿越）
│   └── overseas-test.md   ← 海外固定 input（Billionaire Romance）
└── baselines/         ← 每个 minor/major release 一份基线（首次运行时建立）
    └── （首次跑后填充）
```

## 起源

v1.19.0 ship 后发现没有 eval 数据无法回答"实际效果如何"。本框架解决"后续 release 是真提升还是噪声"的可验证性问题。
