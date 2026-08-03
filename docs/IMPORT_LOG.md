# IMPORT_LOG — DATE FACTORY Asset Integration

**Дата:** 2026-08-03  
**Роль:** Technical Artist / Asset Integrator  
**Канон:** [ASSET_IMPORT_MANIFEST.md](ASSET_IMPORT_MANIFEST.md)  
**Источник (не изменялся):** `C:\Users\User\Downloads\assets`  
**Рабочая распаковка аудита:** `C:\Users\User\Downloads\assets_audit\_temp`  
**Проект:** `C:\Users\User\Documents\GodotProjects\date_factory`

---

## 1. Резюме

| Метрика | Значение |
|--------|----------|
| Пакетов импортировано | **9** (001, 002, 015–021) |
| Файлов скопировано | **~1000+** (после дедупа форматов) |
| Объём | **~483 MB** |
| PACK_013 массово | **НЕ импортирован** |
| Исходная папка assets | **не изменялась** |
| Test scenes | **6** (+ kit indexes / kit instance helpers) |
| Character prefabs | **6** |
| Base materials | **27** `.tres` |

---

## 2. Импортированные пакеты

| Pack | Источник | Формат в проекте | Назначение | Куда |
|------|----------|------------------|------------|------|
| PACK_001 | Downtown City MegaKit | **glTF (Godot)** | город / фасады | `assets/environment/city/downtown_megakit/` |
| PACK_002 | Kenney Factory Kit | **GLB** (выборка) | фабрика / конвейеры | `assets/environment/factory/kenney_factory/` |
| PACK_015 | Sci-Fi Essentials | **glTF** (без оружия) | лаборатория | `assets/environment/lab/scifi_essentials/` |
| PACK_016 | Sushi Restaurant Kit | **glTF** | ресторан | `assets/environment/restaurant/sushi_restaurant/` |
| PACK_017 | Ultimate Food Pack | **FBX** (gltf нет) | еда / пропсы | `assets/props/food/` |
| PACK_018 | Ultimate House Interior | **FBX** (gltf нет) | интерьер квартиры | `assets/environment/interior/house_interior/` |
| PACK_019 | Ultimate Modular Women | **glTF** individuals | девушки / менеджер | `assets/characters/women_modular/` |
| PACK_020 | Universal Animation Library | **GLB** Unreal-Godot | анимации | `assets/animation/universal_library/` |
| PACK_021 | Universal Base Characters | **glTF** Godot-UE | герой / дубль | `assets/characters/hero_base/` |

### Приоритет форматов (соблюдён)

1. GLB → 2. glTF → 3. FBX → 4. OBJ  
В проекте **нет** одновременных FBX+GLB+OBJ одного объекта.

---

## 3. Категории импортированы

- City meshes + textures (PACK_001)
- Factory industrial props (PACK_002, filtered stems)
- Lab props / drones / furniture-tech (PACK_015)
- Restaurant environment / decoration / food (PACK_016)
- Food pack models (PACK_017)
- House interior furniture (PACK_018)
- Women modular individuals (PACK_019)
- Universal animation GLB (PACK_020)
- Hero base bodies + hairstyles (PACK_021)
- Base material library (`assets/materials/base/`)

---

## 4. Категории исключены

- **PACK_013** Modular SciFi MegaKit — отложен (массово)
- PACK_003 / 005 / 012 UI
- PACK_004 / 006 / 008 / 009 / 011 / 014 audio/music
- PACK_007 / 010 light masks / skyboxes (не на этом этапе)
- Unity / Unreal export trees (PACK_001 FBX Unity/Unreal, PACK_015 FBX Unity, PACK_020 Unity)
- OBJ / BLEND дубли где есть glTF/GLB
- Previews, README, `.url`, HTML overview, ZIP
- PACK_015: оружие, ammo, grenades, mines, health packs, syringes
- PACK_016: Characters (rabbits/panda), Truck
- Рекламные preview JPG паков

---

## 5. Проблемы при импорте

1. **PACK_017 / PACK_018** — в исходниках нет GLB/glTF, только FBX/OBJ/BLEND. Выбран **FBX**.
2. **PACK_015** — набор ближе к sci-fi combat props, чем к «лабораторным терминалам»; терминалы как отдельный класс mesh почти отсутствуют. В lab-сцену положены desk/locker/crate/drone/barrel + blockout.
3. **PACK_001** — roads/vehicles в аудите отмечены как отсутствующие; улица собрана blockout + фасадные kit instances.
4. **Анимации** — клипы лежат внутри `UAL1_Standard.glb` / `_RM.glb`. Именованный `AnimationLibrary.tres` с алиасами `idle/walk/run/sit/stand/gesture/react` требует открытия в редакторе после импорта (карта: `assets/animation/universal_library/libraries/UAL_CLIP_MAP.json`).
5. **Sidecar-текстуры** у glTF копировались рядом с моделями — возможны дубли PNG в mesh-папках (функционально ок, можно почистить на следующем проходе).
6. **Лицензия PACK_016** — в аудите «не определено»; файл лицензии в пак не найден.
7. **PACK_002 textures** — GLB ждут `meshes/Textures/colormap.png`; исправлено копированием из `Models/GLB format/Textures/` (после первого `--import` ошибок colormap = 0).

---

## 6. Отложено

- Малый тест PACK_013 (1 wall / floor / door / column / platform / panel)
- Финальный retarget / AnimationLibrary binding в редакторе
- Полная замена всех blockout-боксов на kit meshes в apartment/restaurant
- Lookdev / освещение / post FX
- UI/SFX/music packs

---

## 7. Структура (создана)

```
res://assets/
  environment/{city,interior,restaurant,factory,lab}/...
  characters/{women_modular,hero_base}/...
  animation/universal_library/{source,libraries,retargeted}/
  props/food/...
  materials/base/...
res://scenes/art/
  kits/  rooms/  city/  restaurant/  factory/  lab/  testbeds/  characters/
res://docs/IMPORT_LOG.md
```

---

## 8. Базовые материалы

Папка: `res://assets/materials/base/`

Группы:
- **City_Base_*** — Concrete, Asphalt, Brick, Glass, Metal
- **Interior_Base_*** — WoodLight/Dark, Fabric, Plastic, WallPaint, Metal, Glass
- **Restaurant_Base_*** — WoodWarm, Lacquer, FabricWarm, Ceramic, Glass, KitchenMetal
- **Factory_Base_*** — DarkMetal, Plastic, AccentPink, Warning
- **Lab_Base_*** — WhitePlastic, ColdMetal, Glass, DarkPanel, Glow

Это не final lookdev — только унификация albedo/roughness/metallic.

---

## 9. Prefab-персонажи

| Prefab | Mesh source | Anim source |
|--------|-------------|-------------|
| `assets/characters/hero_base/prefabs/Hero.tscn` | PACK_021 Superhero_Male_FullBody | UAL1_Standard.glb |
| `assets/characters/hero_base/prefabs/Clone.tscn` | тот же (дубль) | UAL1_Standard.glb |
| `assets/characters/women_modular/prefabs/Girl_Casual.tscn` | PACK_019 Casual | UAL1_Standard.glb |
| `assets/characters/women_modular/prefabs/Girl_Formal.tscn` | PACK_019 Formal | UAL1_Standard.glb |
| `assets/characters/women_modular/prefabs/Girl_Worker.tscn` | PACK_019 Worker | UAL1_Standard.glb |
| `assets/characters/women_modular/prefabs/Manager_Suit.tscn` | PACK_019 Suit | UAL1_Standard.glb |

У каждого: `Visual` (mesh), `Collision`, `AnimationPlayer`, скрытый `UAL_LibrarySource`, metadata `_df_anim_aliases`.

### Подключённые анимационные алиасы (цель)

`idle`, `walk`, `run`, `sit`, `stand`, `gesture`, `react`  
Карта поиска клипов: `assets/animation/universal_library/libraries/UAL_CLIP_MAP.json`.

---

## 10. Test scenes

| Scene | Path |
|-------|------|
| Apartment_Blockout_Finalized | `res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn` |
| City_Street_Slice | `res://scenes/art/city/City_Street_Slice.tscn` |
| Sushi_Date_Restaurant | `res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn` |
| Clone_Lab_Base | `res://scenes/art/lab/Clone_Lab_Base.tscn` |
| Date_Factory_Base | `res://scenes/art/factory/Date_Factory_Base.tscn` |
| Character_Testbed | `res://scenes/art/testbeds/Character_Testbed.tscn` |

Дополнительно (kit helpers, не финальный арт):
- `scenes/art/kits/*_Kit_Index.tscn`
- `scenes/art/city/City_Street_KitInstances.tscn`
- `scenes/art/factory/Date_Factory_KitInstances.tscn`
- `assets/IMPORT_MESH_INDEX.json` — индекс путей для следующего visual pass

Сцены читаемые: floor + walls + зоны + light + spawn marker. Не финальный арт.

---

## 11. Инструменты импорта

- `tools/asset_import_pipeline.py` — основной копирующий пайплайн
- `tools/write_character_prefabs.py` — prefab + kit instance helpers
- Состояние: `docs/import_pipeline_state.json`

---

## 12. Проверка (чеклист)

| Проверка | Статус |
|----------|--------|
| Структура папок создана | PASS |
| Выбранные пакеты скопированы | PASS |
| Форматные дубли не хранятся | PASS |
| PACK_013 не импортирован массово | PASS |
| Исходники `Downloads\assets` не менялись | PASS |
| Base materials существуют | PASS |
| 6 test scenes существуют | PASS |
| 6 character prefabs существуют | PASS |
| Анимационный source + clip map | PASS |
| Godot editor reimport / pink materials | **нужен проход в редакторе** после открытия проекта |
| Проигрывание клипов idle/walk/... | **после reimport** UAL GLB и bind в AnimationPlayer |

---

## 13. Следующий безопасный шаг

1. Открыть проект в Godot 4.7 → дождаться reimport `.gltf/.glb/.fbx`.
2. Открыть `Character_Testbed` — проверить, что меши не розовые.
3. Из `UAL1_Standard.glb` собрать `AnimationLibrary` по `UAL_CLIP_MAP.json`.
4. (Опционально) малый тест PACK_013.
5. Visual pass: заменить blockout-боксы на kit instances из индексов.
