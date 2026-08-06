# Current milestone

## ID
`CITY-PROXY-POI-001`

## Product goal
Временная, но архитектурно правильная версия городских POI: каждый POI — отдельная PackedScene (или tenant внутри здания) с финальным функциональным контрактом. Proxy-графика допустима. Визуальная работа над городом после этапа приостанавливается.

## Player-visible result
Городские ориентиры и магазины различимы, входы работают, action_id сохранены, районы/unlock не сломаны. В `city.tscn` только корневые экземпляры зданий/активностей — без разрозненных дверей/вывесок/InteractionArea конкретного POI.

## Status
`IN_PROGRESS`

## In scope
- `CityPOIBuilding` / `CityPOITenant` core
- Proxy PackedScenes + multi-tenant pairs
- Перенос в `city.tscn` корневыми экземплярами
- DistrictGate в `poi/core` с export-параметрами
- Binding interacts из tenant InteractionArea
- Docs: BUILD / VALIDATION / POI_REPLACEMENT_GUIDE

## Out of scope
- Платный Downtown MegaKit audit / новые ассеты
- Перестройка маршрутов и районов
- Walk-in интерьеры, финальный свет, общий декор, модульная архитектура

## Dependencies
- Free Downtown MegaKit buildings/parts
- Existing `Interactable` + `complex_world` city bind
- Existing action_ids and district unlock save

## Active tasks

| Task | Agent | Status | Evidence |
|---|---|---|---|
| CITY-PROXY-POI-001-RESEARCH | df-researcher | COMPLETED | research report in chat |
| CITY-PROXY-POI-001-CORE | df-gameplay-worker | PENDING | |
| CITY-PROXY-POI-001-SCENES | df-scene-worker | PENDING | |
| CITY-PROXY-POI-001-DOCS | Orchestrator / content | PENDING | |
| CITY-PROXY-POI-001-QA | df-qa-worker | PENDING | |

## Blocking issues
- GodotIQ MCP CallMcpTool registration flaky in Orchestrator session; workers must retry / fall back carefully.

## Next acceptance action
- Core + scenes integrate → docs → independent QA → Orchestrator READY/NOT READY.
