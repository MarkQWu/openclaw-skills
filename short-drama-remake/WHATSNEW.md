**v0.3.0**（2026-05-10）

Postflight Reliability：增强 managed remake 项目的写后 gate，防止候选剧本未闭环就误解锁下一集。

- 新增 postflight fixture：`postflight_missing_user_review_blocks_next_episode`，覆盖“候选稿已生成、质量初审通过，但用户未确认 / canon 未提交 / state 未更新时不能继续下一集”的失败路径。
- 扩展 deterministic checker：校验 postflight `report_status` 枚举、passed 所需子状态、非 passed 禁止 downstream unlock、postflight report 不得写 registry-owned 字段、postflight 必须消费上游 report 和候选稿 artifact。
- 补充 `postflight_report` schema 字段与禁止字段，明确 `quality_gate_status=passed` 不等于下一集可解锁。
- 新增极薄 agent contract：`agents/contracts/script-postflight-auditor.yaml`，只作为 `script_draft.postflight` 的角色边界，不引入平台级 agent runtime。
- 更新 `short-drama-remake/README.md` 的 postflight 使用说明。

**v0.2.0**（2026-05-09）

Phase 6 Packaging & Release：把 Phase 4/5 的 managed project gate 打包成可发布版本。

- 新增正文前硬闸门使用路径：`/仿写` 进入 `short-drama-remake`，正文生成前必须通过 `script_draft.preflight`，被阻断时只输出一个 user-visible blocking summary，且 `body_generated=false`。
- 新增 schema contract：`references/schema/artifact-registry.yaml`、`node-route-table.yaml`、`reports.yaml`，统一 `artifact_status`、注册表派生 `gate_status`、report `report_status`、current pointer、transaction ref 和 forbidden reads。
- 新增 deterministic checker 与回归矩阵：`scripts/remake_gate_checker.py`、`references/checker/deterministic-checker.md`、`references/fixtures/`，覆盖原始失败案例、P9/P10/P11/P12 交叉 gate、反冗余和 forbidden read。
- 明确 P10 反冗余：正文前 gate 只消费 `resume_packet`、FGR、SIR、RMR，不重跑 P9/P11/P12 完整节点。
- 更新发布验证命令：self-test、全部 fixture dry run、`py_compile`。

**v0.1.0**（2026-05-07）

首版短剧拆解复刻能力：支持长剧本 ingest、完整/部分源文件 gate、可复刻骨架、换皮方向、项目策划、集纲和正式剧本。
