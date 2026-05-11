# short-drama-remake

`short-drama-remake` is the dedicated remake / reference-analysis skill. Use it for `仿写`, reference skeleton extraction, skin-swap concepting, managed remake projects, episode execution cards, and shooting-ready remake scripts.

## Entry

- Main entry: call this skill directly for `/仿写` or remake requests.
- Do not route remake work through `short-drama`.
- In managed projects, script drafting is guarded by `script_draft.preflight`; downstream script generation must not rely on memory or ad hoc file search.

## Quick Start

1. Send `/仿写` with a script file path, attached file, pasted script, or screen-recorded prompt workflow description.
2. The skill first judges source scope and extracts a reusable story-function skeleton. It does not rewrite immediately.
3. Continue through the guided chain: skeleton table -> 10 skin-swap concepts -> selected concept plan -> episode outlines -> shooting-ready script.

After every substantial output, the skill should show what was completed, what files or artifacts now matter, why the next stage follows, and 2-4 copy-paste next commands.

## Managed Project Gate

Before writing an episode script, the project must have readable current artifacts:

- accepted execution card for the target episode
- `fact_gate_report`
- `source_integrity_report`
- `reference_mapping_report`
- `reference-expression-guide.md`
- `factor-scorecard.yaml`
- `remake-risk-audit.md`
- `project-state.md`
- accepted canon

`script_draft.preflight` consumes those artifacts and reports. It must not rerun full `resume.restore`, `fact_gate.validate`, `source.validate`, or `reference_map.validate` inside the script-drafting node.

## Blocking Summary

When preflight blocks script generation, return one user-visible blocking summary:

- blocking reason
- affected scope
- whether it blocks this episode or the whole project
- recommended next step
- available user actions

Blocked preflight must set `body_generated=false` and must not create an episode script.

## Postflight Reliability

After a candidate episode script is drafted, `script_draft.postflight` must close the episode before the next episode can unlock.

`quality_gate_status=passed` is not enough by itself. The next episode remains locked until postflight confirms user acceptance, canon commit, project-state update, clean read trace, passed risk/sync checks, and top-level `postflight_report.report_status=passed`.

The bundled `script-postflight-auditor` contract is a thin role boundary around the existing route table and report schema. It is not a platform runtime and does not replace `SKILL.md` as workflow authority.

## Validation

Run the minimal gate checks from the skill root:

```bash
python3 scripts/remake_gate_checker.py --self-test
```

Run all bundled fixtures:

```bash
find references/fixtures -name fixture.yaml -print0 | xargs -0 -n1 python3 scripts/remake_gate_checker.py --fixture
```

Compile the checker:

```bash
PYTHONPYCACHEPREFIX=/private/tmp/short-drama-remake-pycache python3 -m py_compile scripts/remake_gate_checker.py
```

Fixture files are JSON-compatible YAML. The checker intentionally validates deterministic contracts only; creative quality remains an LLM review boundary.
