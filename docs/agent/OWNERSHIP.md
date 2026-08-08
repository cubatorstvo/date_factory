# File ownership — Visual Playtest Audit

**Status:** complete / READY (scripted visual; human review pending)  
**Spec:** `VISUAL_PLAYTEST_FULL_SCRIPTED_SCREENSHOT_AUDIT_RU.md` (development-only; not a gameplay module)

| Task id | Agent | Writable paths | Read-only dependencies | Forbidden | Status |
|---|---|---|---|---|---|
| VP-A-docs | Orchestrator | `docs/agent/OWNERSHIP.md`, `docs/agent/ACCEPTANCE.md`, `docs/agent/DECISIONS.md`, `docs/qa/VISUAL_PLAYTEST.md` | — | gameplay / scenes | complete |
| VP-B1-layout | df-gameplay-worker | `ui/theme/ui_scale_helper.gd`, `ui/frontend/title_menu.gd`, `ui/frontend/pause_menu.gd`, `ui/frontend/settings_panel.gd`, `ui/frontend/save_load_panel.gd`, `ui/frontend/test/*`, `ui/phone/phone_journal.gd` (`set_tab` only), `qa/test_manifest.json`, `export_presets.cfg`, `.gitignore` | SaveSystem settings keys, theme | autoloads, world scenes, balance | complete |
| VP-B2-harness | df-qa-worker | `game/visual_review/*`, `tools/visual_review/*` | full_game helpers, production APIs | product gameplay modules, `project.godot`, `qa/test_manifest.json`, `export_presets.cfg` | complete |
| VP-B1b-modals | Orchestrator | `ui/frontend/settings_panel.gd`, `save_load_panel.gd`, `title_menu.gd`, `pause_menu.gd` (CenterContainer modal fix) | — | gameplay | complete |
| VP-C-gallery | df-qa-worker | `game/visual_review/*`, `tools/visual_review/*` | phone/UI APIs, save API, FullGameIntegrationHelpers (RO) | stage/XP cheats labeled as playthrough | active |
| VP-D-playthrough | df-qa-worker | `game/visual_review/*` | World, Story, rivals, dating, clones, FinalDate, FullGameIntegrationHelpers (RO) | `GameState.advance_stage`, `set_world_reach`, `mark_girl_conquered` in playthrough | active |
| VP-E-fix | Orchestrator + targeted workers | defect-specific files only | RC suite, review artifacts | invent MODULE 29 | pending |

One writer per file at a time. Do not parallelize writers on the same `.gd` / `.tscn` / `project.godot` / manifest.
