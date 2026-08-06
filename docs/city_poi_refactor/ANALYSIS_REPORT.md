# ANALYSIS_REPORT — City POI Modular Architecture

Статус: **ANALYSIS ONLY** — `city.tscn` не менялся, новые prefab не создавались, здания не переставлялись.

## Резюме

В проекте для целых фасадов доступны только три mesh:

| Asset | AABB (m) | Hollow walk-in | Рекомендуемая роль |
|---|---|---|---|
| Building_Small_1 | [12.46, 17.026, 14.536] | нет | массовые Storefront / Home / Arcade |
| Building_Medium_2_001 | [15.056, 25.009, 13.056] | нет | Cafe / Restaurant / Gym / Agency |
| Building_Large_2 | [20.644, 28.0, 16.645] | нет | Cinema (приоритет) / optional Agency HQ |

Текущие POI prefab почти все — **FacadeOnlyBuilding**: Building_* + отдельный Door_* + awning/sign/props. Interact живёт на city Markers через `complex_world.gd`, то есть **ещё не инкапсулирован** в корень POI-сцены.

## 5 лучших зданий для уникальных POI

1. **Building_Large_2 → Cinema** (нужен самый читаемый leisure landmark)
2. **Building_Medium_2_001 → Cafe Two Hearts** (стартовый якорь)
3. **Building_Medium_2_001 → Agency Office** (stage3 hub; другой light/sign)
4. **Building_Medium_2_001 → Park Restaurant** (venue stage2)
5. **Building_Small_1 → Player Home** (spawn identity via HOME sign)

*(«Лучших зданий» физически три — ранжирование по назначению, не по количеству файлов.)*

## 3 лучших кандидата MultiTenantBuilding

1. **Photo Studio + Barber** в одном Small/Medium на agency_row (одинаковая стадия, две двери) — **рекомендуется**
2. **Flower + Gift** dual-door Small на main_street — **допустимо**
3. **Jewelry + Clothing** dual-door Small — **допустимо**

## 3 лучших полых здания

**Нет пригодных.** Все три Building_* дали interior_probe_hits=0 и has_collision=false.  
HollowWalkIn откладывается до модульной сборки Brick_* или новых ассетов.

## POI, которым обязателен уникальный силуэт

- Cafe Two Hearts
- Cinema
- Player Home
- Agency Office
- Park Restaurant

## POI, которые безопасно объединить

- photo_studio + barber
- flower_shop + gift_shop (если две вывески/двери)
- jewelry_shop + clothing_shop

## Отклонённые идеи (слишком сложно / непрактично)

1. HollowWalkIn на текущих Building_* без кастомного интерьера
2. Cinema+Bookstore multi-floor в одном Large
3. Cafe внутри multi-tenant с магазинами (ломает uniqueness)
4. Смешение stage1 storefront с stage2/3 venue в одном shell
5. Массовая сборка 20 уникальных зданий из Brick_* в этом этапе (отдельный pipeline, не analysis-approve)

## Целевая архитектура (не реализована)

`POIBuilding` с TenantSlots / EntranceAnchors — принять после утверждения таблицы назначений.  
WorldActivityPOI остаются отдельными сценами.

## Артефакты

- `POI_INVENTORY.md`
- `BUILDING_ASSET_CATALOG.md`
- `POI_ASSET_ASSIGNMENT.md`
- `MULTI_TENANT_COMPATIBILITY.md`
- `HOLLOW_BUILDING_FEASIBILITY.md`
- `contact_sheets/*`
- `hollow_shots/*`
- `_analysis_raw.json` (машинные замеры)
