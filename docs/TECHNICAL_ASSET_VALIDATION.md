# Technical Asset Validation

**Project:** DATE FACTORY  
**Date:** 2026-08-03  
**Role:** Godot Asset Integration Engineer  
**Baseline commit:** `d03d8bb` — `chore: before asset stabilization pass`

## Резюме

| Метрика | Значение |
|--------|----------|
| Пакетов проверено | **9** (PACK_001, 002, 015–021) |
| Ресурсов проверено (выборка deep-load) | **83** моделей + 6 prefab + 6 scenes + libraries |
| Ошибок найдено | **~32** (в основном FBX scale 100×) + structural limitations |
| Ошибок исправлено | **237** FBX `.import` scale + AnimationLibrary + prefab/testbed wiring + TechCamera/Light |
| Ошибок осталось | **3** limitations (women sit/stand fallback, lab terminals gap, city roads gap) |
| Prefab проверено | **6 / 6** |
| Сцен проверено | **6 / 6** |
| Анимационных алиасов создано | **7** (`idle/walk/run/sit/stand/gesture/react`) × 2 libraries |

**Итоговый статус: READY WITH LIMITATIONS**

Автовалидатор: [`ASSET_TECHNICAL_VALIDATION.txt`](ASSET_TECHNICAL_VALIDATION.txt) → `PASS=48 WARNING=0 ERROR=0`  
Ошибки импорта: [`ASSET_IMPORT_ERRORS.md`](ASSET_IMPORT_ERRORS.md)  
Скриншоты: [`asset_validation/screenshots/`](asset_validation/screenshots/)

## Импорт по пакетам

### PACK_001 — Downtown City MegaKit
* **Статус:** OK  
* **Проблемы:** roads/vehicles gaps (content)  
* **Исправления:** none required for load/materials  
* **Ограничения:** street slice still partially blockout  

### PACK_002 — Kenney Factory
* **Статус:** OK  
* **Проблемы:** earlier colormap path (fixed in prior import stage)  
* **Исправления:** none this pass  
* **Ограничения:** none technical  

### PACK_015 — Sci-Fi Essentials
* **Статус:** OK with content gap  
* **Проблемы:** few dedicated lab terminals  
* **Исправления:** none  
* **Ограничения:** Clone Lab uses available props + blockout  

### PACK_016 — Sushi Restaurant
* **Статус:** OK  
* **Проблемы:** none in samples  
* **Исправления:** none  
* **Ограничения:** artistic layout deferred  

### PACK_017 — Ultimate Food Pack
* **Статус:** OK after scale fix  
* **Проблемы:** FBX ~100× scale  
* **Исправления:** `nodes/root_scale=0.1` + reimport  
* **Ограничения:** none remaining for scale  

### PACK_018 — House Interior
* **Статус:** OK after scale fix  
* **Проблемы:** FBX ~100× scale  
* **Исправления:** `nodes/root_scale=0.1` + reimport  
* **Ограничения:** apartment still mostly blockout + kit indexes  

### PACK_019 — Modular Women
* **Статус:** OK with animation limitations  
* **Проблемы:** UAL skeleton mismatch; no Sitting clips; humanoid_rigs FBX scale  
* **Исправления:** `DF_Women_Aliases.res`; FBX root_scale; prefabs bind local aliases  
* **Ограничения:** sit/stand are technical fallbacks  

### PACK_020 — Universal Animation Library
* **Статус:** OK  
* **Проблемы:** aliases were JSON-only  
* **Исправления:** real `DF_UAL_Aliases.res` from non-RM `UAL1_Standard.glb`  
* **Ограничения:** RM GLB unused by design  

### PACK_021 — Universal Base Characters
* **Статус:** OK  
* **Проблемы:** none  
* **Исправления:** Hero/Clone prefabs use UAL alias library  
* **Ограничения:** none  

## Анимации

Libraries:
* `res://assets/animation/universal_library/libraries/DF_UAL_Aliases.res`
* `res://assets/animation/universal_library/libraries/DF_Women_Aliases.res`
* Map: [`UAL_CLIP_MAP.json`](../assets/animation/universal_library/libraries/UAL_CLIP_MAP.json)

| Alias | Original (UAL / Hero·Clone) | Original (Women) | Loop | Root motion | Prefabs tested |
|------|-----------------------------|------------------|------|-------------|----------------|
| idle | `Idle` | `Idle` | yes | no | all 6 |
| walk | `Walk` | `Walk` | yes | no | all 6 |
| run | `Sprint` | `Run` | yes | no | all 6 |
| sit | `Sitting_Enter` | `Idle_Neutral` (fallback) | no / yes(fallback) | no | all 6 |
| stand | `Sitting_Exit` | `Idle` (fallback) | no | no | all 6 |
| gesture | `Interact` | `Wave` | no | no | all 6 |
| react | `Hit_Chest` | `HitRecieve` | no | no | all 6 |

Source animations inside GLB/glTF were **not** renamed. Aliases live in project AnimationLibraries (`df_aliases/*`).

## Prefab-персонажи

Controller: `res://scenes/art/characters/character_anim_controller.gd`

| Prefab | Mesh | Skeleton | Materials | Animations | Collision | Status |
|--------|------|----------|-----------|------------|-----------|--------|
| Hero | Superhero_Male_FullBody | 65 / UAL-compatible | OK | UAL aliases 7/7 | Capsule | **PASS** |
| Clone | Superhero_Male_FullBody | 65 / UAL-compatible | OK | UAL aliases 7/7 | Capsule | **PASS** |
| Girl_Casual | Casual.gltf | 62 / women | OK | Women aliases 7/7 | Capsule | **PASS*** |
| Girl_Formal | Formal.gltf | 62 / women | OK | Women aliases 7/7 | Capsule | **PASS*** |
| Girl_Worker | Worker.gltf | 62 / women | OK | Women aliases 7/7 | Capsule | **PASS*** |
| Manager_Suit | Suit.gltf | 62 / women | OK | Women aliases 7/7 | Capsule | **PASS*** |

\* Women sit/stand are fallback clips (see limitations).

## Test scenes

| Scene | Load | Materials | Resources | Scale | Screenshot | Status |
|-------|------|-----------|-----------|-------|------------|--------|
| Apartment_Blockout_Finalized | OK | OK (blockout mats) | OK | OK | [01_apartment.png](asset_validation/screenshots/01_apartment.png) | **PASS** |
| City_Street_Slice | OK | OK | OK | OK | [02_city_street.png](asset_validation/screenshots/02_city_street.png) | **PASS** |
| Sushi_Date_Restaurant | OK | OK | OK | OK | [03_sushi_restaurant.png](asset_validation/screenshots/03_sushi_restaurant.png) | **PASS** |
| Clone_Lab_Base | OK | OK | OK | OK | [04_clone_lab.png](asset_validation/screenshots/04_clone_lab.png) | **PASS** |
| Date_Factory_Base | OK | OK | OK | OK | [05_date_factory.png](asset_validation/screenshots/05_date_factory.png) | **PASS** |
| Character_Testbed | OK | OK | OK | OK | [06–09](asset_validation/screenshots/) idle/walk/sit/gesture | **PASS** |

Each environment scene now has technical `TechCamera` + `TechSun` (+ `TechEnv` when missing) for validation viewing. Character Testbed includes keys `1–7`, `A` auto-demo, `D` manual; auto cycle: idle → walk → gesture → sit → stand → react.

## Оставшиеся технические проблемы

1. Women `sit`/`stand` are not true sit/stand-up clips (PACK_019 content gap).  
2. UAL cannot drive women meshes without a future retarget pass.  
3. PACK_015 lab terminal scarcity / PACK_001 roads-vehicles content gaps.  
4. Environment test scenes remain largely blockout (by design for this stage).  
5. Artistic lighting/composition/VFX/UI intentionally untouched.

## Готовность к visual pass

**READY WITH LIMITATIONS**

Не `READY`, потому что остаются принятые content/animation limitations (women sit/stand, lab/city content gaps).  
Не `NOT READY`: нет розовых materials в проверенных ресурсах, анимационные алиасы работают на всех 6 prefab, все 6 test scenes загружаются, missing-resource ошибок нет.
