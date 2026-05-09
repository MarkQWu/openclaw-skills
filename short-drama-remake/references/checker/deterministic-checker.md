# Deterministic Checker Contract

Use this reference when implementing or interpreting `scripts/remake_gate_checker.py`.

## Scope

The deterministic checker owns only machine-checkable invariants:

- schema enum presence and status field boundaries
- registry ownership of `gate_status`
- report ownership of `report_status`
- runtime packets excluded from registry artifacts
- current pointer uniqueness
- user-confirmed artifacts requiring `decision_id` and committed transaction refs
- machine reports not requiring `decision_id`
- preflight blocked means `body_generated=false` and no episode script is created
- blocked preflight includes a complete user-visible blocking summary: reason, affected scope, episode/project level, recommended next node, and available actions
- forbidden read and undeclared read traces
- P10 anti-redundancy: consume `resume_packet`, SIR, RMR, and FGR; do not rerun full P9/P11/P12 nodes
- postflight unlock uses top-level `postflight_report.report_status` only

## LLM Review Boundary

LLM review may judge character voice, world-rule shootability, abstract expression reuse, similarity distance, hook strength, and whether scene tasks are dramatically landed.

LLM review may not:

- override deterministic `blocked`
- generate or modify `gate_status`
- generate `decision_id`
- rerun P9/P11/P12 full nodes during P10
- read source bundles instead of consuming SIR/RMR
- turn `[待确认]` claims into direct script facts

## v0.2.0 Implementation Target

The checker validates fixture contracts and the critical Phase 3-5 invariants that caused the original failure:

1. missing execution card blocks script generation
2. legacy `/仿写` does not load the original short-drama workflow
3. P10 does not rejudge source integrity when SIR exists
4. blocked preflight never creates `episode_script`
5. runtime packet refs remain debug-only
6. P10 consumes cached FGR/SIR/RMR and `resume_packet` instead of rerunning full P9/P11/P12 nodes
7. forbidden direct reads block script generation
8. transaction atomicity prevents half-confirmed state
9. dirty / needs_sync invalidates `fast_confirmed`
