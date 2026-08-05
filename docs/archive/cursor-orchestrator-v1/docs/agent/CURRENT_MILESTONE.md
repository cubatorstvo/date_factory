# Current milestone

## ID
`RELEASE-RC-HARDENING-001`

## Product goal
Довести текущий замороженный scope DATE FACTORY до feature-complete Windows release candidate без добавления новых POI и крупных механик.

## Player-visible result
Игрок проходит целостный маршрут от новой игры до понятного финала, посещает все существующие POI и активности в компактном законченном городе, сохраняется/загружается и может запустить тот же маршрут в экспортированной Windows-сборке.

## Status
`NOT READY — IMPLEMENTATION PAUSED — HANDOFF READY`

## Scope freeze

### In scope
- Завершение и исправление существующих механик и маршрутов.
- Перекомпоновка существующего города и текущих POI.
- Замена blockout подходящими уже доступными ассетами.
- Lighting/UI consistency pass.
- Минимальный финал на существующей progression.
- Headless smoke/full-progression regression и Windows export.
- Credits/licenses для реально используемых пакетов.

### Out of scope
- Новые POI, районы, магазины и крупные механики.
- Достижения, мастерская, multiplayer, cloud saves.
- Новый framework или переписывание проекта.
- Расширение ассортимента/контента без необходимости текущего маршрута.
- Объявление testbed, debug route или blockout финальным результатом.

## Dependencies
- Существующие Game/SaveService/time/dating/inventory/shop/progression contracts.
- ComplexWorld и текущие отдельные POI scenes.
- Импортированные `res://assets/` и локальные source packs.
- QA full-access profile только как инструмент проверки, не как доказательство normal progression.

## Active tasks

| Task | Agent | Status | Evidence |
|---|---|---|---|
| RC-AUDIT-GAMEPLAY-001 | df-researcher | COMPLETED | `docs/release/research/GAMEPLAY_TECHNICAL_AUDIT.md` |
| RC-AUDIT-WORLD-001 | df-researcher | COMPLETED | `docs/release/research/WORLD_POI_AUDIT.md` |
| RC-AUDIT-UI-ASSETS-001 | df-researcher | COMPLETED | `docs/release/research/UI_ASSET_AUDIT.md` |
| RC-BOOT-SAVE-001 | df-gameplay-worker | COMPLETED_PENDING_QA | normal Continue technical checks pass |
| RC-UNIQUE-PROGRESSION-001 | df-gameplay-worker | ABORTED_PARTIAL_NEEDS_REVIEW | production meet/finale partial diff |
| RC-REGRESSION-FOUNDATION-001 | df-gameplay-worker | ABORTED_PARTIAL_SMOKE_PASS | 25-step smoke PASS; full unaccepted |
| RC-01-PARTIAL-REVIEW | df-gameplay-worker | PLANNED | first handoff stage |
| RC-01-QA | df-qa-worker | BLOCKED_BY_RC-01 | independent critical-flow gate |
| RC-02-ASSET-MAP | df-asset-worker | PLANNED | asset/license/prefab matrix |
| RC-03-CITY | df-scene-worker | BLOCKED_BY_RC-01_RC-02 | compact live city rebuild |
| RC-04-LIGHT-ROOMS | df-scene-worker | BLOCKED_BY_RC-03 | lighting and existing room art |
| RC-05-UI-FINALE | df-gameplay-worker / df-scene-worker | BLOCKED_BY_PRIOR_GATES | UI/finale clarity |
| RC-06-TEST-EXPORT-QA | df-gameplay-worker / df-qa-worker | BLOCKED_BY_PRIOR_GATES | full regression, Windows RC, playtest |

## Blocking issues
- RC-B001: player Continue загружает QA full-access.
- RC-B002: часть unique girls не имеет normal-route meet path, поэтому финал недостижим.
- RC-C001: нет честного full-progression regression.
- RC-C002: нет export preset/Windows build.
- Ветка унаследовала незакоммиченные QA full-access и proxy POC изменения; их нельзя потерять или смешать с автоматическим cleanup.

## Next acceptance action
- Передать `docs/release/HANDOFF_TO_GROK.md`.
- Назначить одного `df-gameplay-worker` на `RC-01-PARTIAL-REVIEW`.
- Не начинать city/art до независимого PASS Stage 1.
