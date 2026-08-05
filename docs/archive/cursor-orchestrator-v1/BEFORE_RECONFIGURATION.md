# BEFORE reconfiguration — Cursor orchestrator v1

Captured before simplifying DATE FACTORY Cursor workflow.

## Active rules (`.cursor/rules/`)

| File | Size (bytes) | alwaysApply |
|---|---:|---|
| `date-factory-orchestrator.mdc` | 4722 | true |
| `date-factory-background-testing.mdc` | 3780 | true |
| `date-factory-delegation.mdc` | 3399 | true |
| `date-factory-quality-gates.mdc` | 2950 | true |
| `date-factory-godot.mdc` | 2813 | true |
| `gdscript-no-infer-from-variant.mdc` | 1976 | true |

**alwaysApply: true count:** 6 / 6

**Sum of alwaysApply rule bodies:** 19 640 bytes

## Agents (`.cursor/agents/`)

- `df-researcher.md` (1542)
- `df-gameplay-worker.md` (1745)
- `df-scene-worker.md` (1503)
- `df-asset-worker.md` (1457)
- `df-content-worker.md` (1506)
- `df-qa-worker.md` (1552)

## Commands (`.cursor/commands/`)

- `orchestrate-feature.md` (1201)
- `validate-milestone.md` (597)
- `audit-current-diff.md` (586)
- `agent-model-smoke-test.md` (1049)

## Root / legacy instruction files

| File | Size | Notes |
|---|---:|---|
| `AGENTS.md` | 6142 | GodotIQ block + DATE FACTORY Orchestrator–Worker section |
| `.cursorrules` | 5138 | Exact duplicate of GodotIQ core block |
| `CLAUDE.md` | 5138 | Exact duplicate of GodotIQ core block / `.cursorrules` |
| `GODOTIQ_RULES.md` | 49651 | Full GodotIQ reference (on-demand) |
| `.cursor/mcp.json` | 348 | GodotIQ MCP; contains license key env var |

## Auto-applied context estimate (project-owned)

Files Cursor commonly injects automatically in this project:

1. All six `.cursor/rules/*.mdc` with `alwaysApply: true` → **19 640** bytes
2. `AGENTS.md` (workspace agent instructions) → **6 142** bytes
3. `.cursorrules` (legacy project rules) → **5 138** bytes
4. `CLAUDE.md` (often mirrored / duplicate) → **5 138** bytes

**Approximate auto-applied project-owned total:** ~**36 058** bytes  
(plus GodotIQ MCP server instructions at runtime; `GODOTIQ_RULES.md` is reference-only unless opened)

## Duplicates found

1. **GodotIQ Core Rules** repeated in:
   - `AGENTS.md` (between `GODOTIQ RULES START/END`)
   - `.cursorrules` (identical)
   - `CLAUDE.md` (identical)
   - mirrored again inside GodotIQ MCP `serverUseInstructions`
2. **Orchestrator policy** repeated across:
   - five `date-factory-*.mdc` alwaysApply rules
   - `AGENTS.md` Orchestrator–Worker section
   - custom agent frontmatter / commands
3. Full detail also lives in `GODOTIQ_RULES.md` (correct single full reference)

## Operational docs that were always referenced

`docs/agent/**`: CURRENT_MILESTONE, DECISIONS, OWNERSHIP, ACCEPTANCE, RUNBOOK, QA reports, setup reports.
