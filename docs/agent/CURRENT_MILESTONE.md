# Current milestone

## ID
`CITY-PROXY-POI-001`

## Product goal
Временная, но архитектурно правильная версия городских POI. После этапа визуальная работа над городом приостанавливается.

## Player-visible result
Различимые proxy-POI как PackedScene; action_id работают; районы/unlock сохранены; в city.tscn только корневые экземпляры.

## Status
`READY`

## In scope
- CityPOIBuilding / CityPOITenant
- Proxy PackedScenes + multi-tenant
- city.tscn root instances
- DistrictGate in poi/core
- Docs BUILD / VALIDATION / POI_REPLACEMENT_GUIDE

## Out of scope (paused)
Paid MegaKit, route rebuild, walk-in interiors, final lighting, city décor, new assets

## Active tasks

| Task | Agent | Status | Evidence |
|---|---|---|---|
| RESEARCH | df-researcher | COMPLETED | chat report |
| CORE | df-gameplay-worker | COMPLETED | poi/core + bind |
| SCENES | df-scene-worker | COMPLETED | 20 scenes + city |
| DOCS | Orchestrator | COMPLETED | docs/city_proxy_poi/* |
| QA | df-qa-worker + Orchestrator capture | COMPLETED | QA md + qa/*.png |

## Blocking issues
- Нет.

## Next acceptance action
- Milestone принят. Визуал города на паузе до финальных ассетов (см. POI_REPLACEMENT_GUIDE).
