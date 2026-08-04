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

## Rules

- Один файл — один active writer.
- `.tscn` нельзя объединять вслепую.
- save/time/autoload/global state изменяются последовательно.
- После task ownership освобождается.
