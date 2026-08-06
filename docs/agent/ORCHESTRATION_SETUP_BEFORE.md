# Orchestration setup — before

## Branch
`cursor/alpha-lore-events-docs`

## Git status (brief)
- Modified gameplay (dating/apartment/interact) and import noise present — **bootstrap will not touch these**.
- Untracked Proxy POC / drinkware / gift placeholders remain outside this setup.
- Existing Cursor config: `.cursor/mcp.json`, `.cursor/rules/gdscript-no-infer-from-variant.mdc`.

## Found Cursor / agent files
| Path | Notes |
|---|---|
| `AGENTS.md` | GodotIQ core rules (keep) |
| `.cursorrules` | legacy GodotIQ (keep; bootstrap does not create new) |
| `CLAUDE.md` | GodotIQ duplicate (keep) |
| `.cursor/rules/gdscript-no-infer-from-variant.mdc` | AlwaysApply GDScript Variant rule (keep) |
| `.cursor/mcp.json` | GodotIQ MCP (keep) |
| `.cursor/agents/` | **missing** |
| `.cursor/commands/` | **missing** |
| `docs/agent/` | **missing** |

## Planned changes (config/docs only)
- Add 4 AlwaysApply rules: orchestrator, delegation, quality-gates, godot
- Add 6 custom agents `df-*` with model `Cursor Grok 4.5`
- Add 4 slash commands
- Add operational docs under `docs/agent/`
- Append Orchestrator section to `AGENTS.md` without removing GodotIQ

## Possible conflicts
- Main chat model may not be GPT 5.6 Sol (must be selected manually in UI).
- Custom agent `model: Cursor Grok 4.5` may need UI confirmation if Cursor stores a different slug.
- Multitask Mode may still prefer built-in Task types until `df-*` agents are picked in the UI.
- Existing AlwaysApply GodotIQ + new DF rules must coexist (merge, not overwrite).
