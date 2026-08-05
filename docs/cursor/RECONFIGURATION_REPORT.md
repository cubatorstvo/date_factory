# Cursor workflow reconfiguration report

Date: 2026-08-05  
Source: `DATE_FACTORY_CURSOR_SIMPLIFY_WORKFLOW.md`  
Status: **READY**

## Old active rules

| Rule | alwaysApply |
|---|---|
| `date-factory-orchestrator.mdc` | true |
| `date-factory-delegation.mdc` | true |
| `date-factory-quality-gates.mdc` | true |
| `date-factory-background-testing.mdc` | true |
| `date-factory-godot.mdc` | true |
| `gdscript-no-infer-from-variant.mdc` | true |

**Old alwaysApply count:** 6  
**Old alwaysApply size:** 19 640 bytes  
**Old auto-applied project-owned estimate** (6 rules + `AGENTS.md` + `.cursorrules` + `CLAUDE.md`): ~36 058 bytes

## New active rules

| Rule | alwaysApply | Notes |
|---|---|---|
| `date-factory-core.mdc` | true | 3 473 bytes (≤ 3 500) |
| `gdscript-no-infer-from-variant.mdc` | false | glob `**/*.gd` only; 561 bytes |

**New alwaysApply count:** 1  
**New alwaysApply size:** 3 473 bytes (−82.3%)  
**New auto-applied estimate** (core rule + `AGENTS.md` GodotIQ block): ~8 610 bytes (−76.1%)

## Agents

**Removed from active `.cursor/agents/`:**

- `df-gameplay-worker`
- `df-scene-worker`
- `df-asset-worker`
- `df-content-worker`
- `df-qa-worker`

**Remaining:** `df-researcher`  
**Model:** `cursor-grok-4.5-high-fast`

## Commands

**Removed:**

- `orchestrate-feature`
- `validate-milestone`
- `audit-current-diff`
- `agent-model-smoke-test`

**Added:**

- `implement-task`
- `inspect-task`

## Duplicates (`AGENTS.md` / `.cursorrules` / `CLAUDE.md` / `GODOTIQ_RULES.md`)

| File | Finding | Action |
|---|---|---|
| `AGENTS.md` | GodotIQ core + Orchestrator section | Orchestrator section removed; GodotIQ block kept (plugin-managed) |
| `.cursorrules` | Exact duplicate of GodotIQ core | Archived, deleted from project root |
| `CLAUDE.md` | Exact duplicate of GodotIQ core | Archived, deleted from project root |
| `GODOTIQ_RULES.md` | Full reference | Left as single full reference |
| GodotIQ MCP `serverUseInstructions` | Same core rules at MCP layer | Untouched (addon-owned) |

**Files Cursor actually auto-reads in the new setup (project-owned):**

1. `.cursor/rules/date-factory-core.mdc` (`alwaysApply: true`)
2. `.cursor/rules/gdscript-no-infer-from-variant.mdc` only when editing `*.gd`
3. `AGENTS.md` (GodotIQ short core)
4. Selected command / agent when invoked

`GODOTIQ_RULES.md` is on-demand.  
`docs/agent/**` operational set moved to archive; active stub: `docs/agent/README.md`.  
`docs/release/**` unchanged and not auto-loaded.

## Archive

`docs/archive/cursor-orchestrator-v1/` contains:

- old rules, agents, commands
- old `docs/agent/**`
- root copies of `.cursorrules`, `CLAUDE.md`, `AGENTS.md`, `GODOTIQ_RULES.md`
- Orchestrator section extract
- `BEFORE_RECONFIGURATION.md`

## MCP

`.cursor/mcp.json` not modified.  
Contains intentional `GODOTIQ_LICENSE_KEY` env entry (not removed).

## Gameplay

No game code, scenes, assets, saves, or release milestone implementation changed by this reconfiguration.

## Verification checklist

1. `.cursor/rules/`: core + gdscript only — yes  
2. Single `alwaysApply: true` — yes  
3. Only `df-researcher` agent — yes  
4. Researcher model `cursor-grok-4.5-high-fast` — yes  
5. Commands: `implement-task`, `inspect-task` — yes  
6. No active `df-qa-worker` reference — yes  
7. No mandatory milestone/ownership/acceptance read — yes  
8. No “three workers” requirement — yes  
9. No mandatory separate QA — yes  
10. No automatic GPT invocation — yes  
11. Gameplay unchanged — yes  
12. `mcp.json` intact — yes  
13. `git diff --check` on config paths — pass  
14. Archive available — yes  

## Manual UI note

New Agent chats should manually select **Cursor Grok 4.5 High Fast**.  
Reload Cursor / open a new chat so rules, agents, and commands refresh.

## Final status

`READY`
