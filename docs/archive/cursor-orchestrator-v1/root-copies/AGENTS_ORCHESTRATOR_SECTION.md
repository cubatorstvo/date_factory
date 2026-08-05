<!-- DATE FACTORY ORCHESTRATOR START -->
# DATE FACTORY OrchestratorвЂ“Worker

Project orchestration rules:

- `.cursor/rules/date-factory-orchestrator.mdc`
- `.cursor/rules/date-factory-delegation.mdc`
- `.cursor/rules/date-factory-quality-gates.mdc`
- `.cursor/rules/date-factory-godot.mdc`
- `.cursor/rules/date-factory-background-testing.mdc`

Also keep: `.cursor/rules/gdscript-no-infer-from-variant.mdc`

Operational docs: `docs/agent/` вЂ” start with `docs/agent/RUNBOOK.md` before a substantial milestone.

Main Cursor Agent chat acts as **Orchestrator** and should use **GPT 5.6 Sol** (selected manually in the model picker).

All technical custom subagents (`df-*`) must use **Cursor Grok 4.5**.

Allowlist: `df-researcher`, `df-gameplay-worker`, `df-scene-worker`, `df-asset-worker`, `df-content-worker`, `df-qa-worker`.

Commands: `/orchestrate-feature`, `/validate-milestone`, `/audit-current-diff`, `/agent-model-smoke-test`.
<!-- DATE FACTORY ORCHESTRATOR END -->
