# Active file ownership

| Task ID | Agent | Writable paths | Read-only dependencies | Forbidden paths | Status |
|---|---|---|---|---|---|
| APT-KITCHEN-SOURCES-001 | df-gameplay-worker | `scenes/world/vertical_slice/apartment.tscn`; `scenes/world/complex_world.gd`; `modules/interaction/interactable.gd`; `modules/interaction/interaction_router.gd`; `scenes/ui/shop_ui.gd` | inventory, dating home prep, EventBus, existing UI theme | save schema, time, city, dating state machine, Proxy POC, imported assets | COMPLETED |
| APT-KITCHEN-SOURCES-001-QA | df-qa-worker | `docs/agent/qa/APT-KITCHEN-SOURCES-001_QA.md` only | implementation diff; normal apartment route; engine logs | all gameplay/code/scenes/assets | COMPLETED |
| EVENT-COOLDOWN-010-RESEARCH | df-researcher | none (read-only) | events, time, save wiring | all writes | COMPLETED |
| EVENT-COOLDOWN-010 | df-gameplay-worker | `modules/events/events_api.gd` | `TimeAPI.absolute_minutes()`; existing events save blob; dating post-date caller | `time_api.gd`, event UI/content, economy probability, dating/crises state machines, project.godot | COMPLETED |
| EVENT-COOLDOWN-010-QA | df-qa-worker | `docs/agent/qa/EVENT-COOLDOWN-010_QA.md` only | event implementation diff; TimeAPI; normal project runtime | all gameplay/code/scenes/assets | COMPLETED |
| EVENT-COOLDOWN-011 | df-gameplay-worker | `modules/events/events_api.gd`; `modules/clones/clones_api.gd`; `scenes/ui/phone_ui.gd` (player_initiated flag) | Event UI; TimeAPI; clone deferred_hits save | dating state machine, ContentDB event content, project.godot | COMPLETED |
| EVENT-COOLDOWN-011-QA | df-qa-worker | `docs/agent/qa/EVENT-COOLDOWN-011_QA.md` only | events/clones/phone diff; TimeAPI | all gameplay/code/scenes/assets | COMPLETED |
| APT-HOMEWARE-SHOP-001 | df-gameplay-worker | `scenes/world/complex_world.gd` | DatePlaces shop catalogs; ShopUI homeware; street `open_homeware_shop` | apartment furniture art; dating state machine; Proxy POC | COMPLETED |
| APT-INTERACT-COMPONENT-001-RESEARCH | df-researcher | none (read-only) | Interactable, player interact, apartment kitchen | all writes | COMPLETED |
| APT-INTERACT-COMPONENT-001 | df-gameplay-worker | `modules/interaction/interactable.gd`; apartment interact path in `scenes/world/complex_world.gd` | player raycast; apartment Furniture nodes; outline shader | interaction_router (unless tiny); city spawn defaults; dating SM; save; Proxy POC | COMPLETED |
| APT-INTERACT-COMPONENT-001-QA | df-qa-worker | `docs/agent/qa/APT-INTERACT-COMPONENT-001_QA.md` only | interactable/complex_world diff; apartment kitchen | all gameplay/code/scenes/assets | COMPLETED |
| QA-FULL-ACCESS-SAVE-001-RESEARCH | df-researcher | none (read-only) | boot, save, unlock matrix, travel | all writes | COMPLETED |
| QA-FULL-ACCESS-SAVE-001 | df-gameplay-worker | `autoload/game.gd`; `modules/save/save_service.gd`; `scenes/boot/boot.gd`; `modules/save/full_access_qa_profile.gd` | facility, city, districts, quests, economy, clones, ComplexWorld contracts | normal progression APIs, `complex_world.gd`, scenes/assets, Proxy POC | COMPLETED |
| QA-FULL-ACCESS-SAVE-001-QA | df-qa-worker | `docs/agent/qa/QA-FULL-ACCESS-SAVE-001_QA.md` only | implementation diff; boot Continue; all travel/POI routes | all gameplay/code/scenes/assets | COMPLETED |
| RC-AUDIT-GAMEPLAY-001 | df-researcher | `docs/release/research/GAMEPLAY_TECHNICAL_AUDIT.md` only | gameplay flow, progression, save/load, tests, export configuration | all gameplay/code/scenes/assets; all other release reports | COMPLETED |
| RC-AUDIT-WORLD-001 | df-researcher | `docs/release/research/WORLD_POI_AUDIT.md` only | city, POI scenes, street activities, lighting, interaction ownership | all gameplay/code/scenes/assets; all other release reports | COMPLETED |
| RC-AUDIT-UI-ASSETS-001 | df-researcher | `docs/release/research/UI_ASSET_AUDIT.md` only | UI scenes, themes, imported/source assets, licenses | all gameplay/code/scenes/assets; all other release reports | COMPLETED |
| RC-BOOT-SAVE-001 | df-gameplay-worker | `scenes/boot/boot.gd` | Game normal save/load APIs; SaveService slot checks; QA profile APIs | `autoload/game.gd`; `modules/save/**`; all scenes/assets/tests/project.godot | COMPLETED_PENDING_QA |
| RC-UNIQUE-PROGRESSION-001 | df-gameplay-worker | `modules/girls/girls_api.gd`; `modules/city/city_api.gd`; `modules/dating/date_places.gd` | stage content; facility unlocks; finale gates; date schedule contracts | Game/autoload; save schema; city scene; dating state machine; UI | ABORTED_PARTIAL_NEEDS_REVIEW |
| RC-REGRESSION-FOUNDATION-001 | df-gameplay-worker | `tests/release/**`; `docs/release/AUTOTEST_RUNBOOK.md`; `docs/release/FULL_PLAYTHROUGH_CHECKLIST.md` | production APIs; existing smoke tools; accepted finale/player flow | all production `.gd`/`.tscn`; project.godot; other release docs | ABORTED_PARTIAL_SMOKE_PASS |
| RC-01-PARTIAL-REVIEW | df-gameplay-worker | boot/girls/city/date_places partial files; `tests/release/**`; two test runbooks | audit reports, decisions, stage/finale/save contracts | city scene, assets, project.godot, save schema, autoload | PLANNED_NOT_ASSIGNED |
| RC-01-QA | df-qa-worker | `docs/release/RELEASE_QA_REPORT.md` and scoped evidence only | RC-01 diff, tests, normal/QA saves | all production files | BLOCKED |
| RC-02-ASSET-MAP | df-asset-worker | explicitly selected asset/prefab/license paths | city masterplan, source packs, live marker contracts | gameplay, city scene, whole-pack imports | PLANNED_NOT_ASSIGNED |
| RC-02-LICENSES | df-content-worker | credits/license documentation only | accepted asset map | gameplay/scenes/content expansion | PLANNED_NOT_ASSIGNED |
| RC-03-CITY | df-scene-worker | `scenes/world/city/city.tscn` plus explicitly assigned dedicated city prefabs | masterplan, accepted assets, marker/action contracts | `complex_world.gd`, save/time/dating, legacy city as result | BLOCKED |
| RC-03-INTEGRATION | df-gameplay-worker | `scenes/world/complex_world.gd`; `modules/interaction/interaction_router.gd` | stabilized city scene, Interactable/outline contracts | city scene, save/time/dating state machine | BLOCKED |
| RC-04-LIGHT | df-scene-worker | `scenes/world/complex.tscn`; assigned city light nodes | stabilized city layout | time redesign, gameplay | BLOCKED |
| RC-04-ROOMS | df-scene-worker | one explicitly assigned room/scene per worker | accepted assets, travel contracts | shared city root, save schema, new POI | BLOCKED |
| RC-05-UI | df-gameplay-worker / df-scene-worker | explicit UI files; one global-theme owner | existing UI framework, selected icons | second framework, new feature scope | BLOCKED |
| RC-05-FINALE | df-gameplay-worker | existing finale UI/controller/quest integration | DEC-006, accepted progression | softened gates, new ending framework | BLOCKED |
| RC-06-TESTS | df-gameplay-worker | `tests/release/**`; test docs | accepted production APIs | production cheats/player debug UI | BLOCKED |
| RC-06-EXPORT | df-gameplay-worker | `export_presets.cfg`; export scripts/docs | accepted tests/assets/licenses | gameplay changes | BLOCKED |
| RC-06-PLAYTEST | df-qa-worker | final QA/playtest reports and evidence only | exported build, full route | production files | BLOCKED |

## Rules

- Один файл — один active writer.
- `.tscn` нельзя объединять вслепую.
- save/time/autoload/global state изменяются последовательно.
- После task ownership освобождается.
- На момент handoff активных writers нет; все незавершённые пакеты PAUSED/PLANNED.
- Перед каждым новым worker batch Orchestrator переводит только назначенную строку в `ACTIVE`.
