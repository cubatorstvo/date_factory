# DATE FACTORY — City Handoff Package

Пакет для внешнего ведущего level designer.  
Город **не перестраивался**. Только исследование и выгрузка фактов.

Архив: `docs/DATE_FACTORY_CITY_HANDOFF.zip`.

---

## Критическое предупреждение о сценах

| Сцена | Путь | Роль |
|-------|------|------|
| Запрошена как «главная для анализа» | `scenes/art/city/City_Street_Slice.tscn` | Art/kit **testbed** (BoxMesh, 17 узлов, без Interactable, без megakit instances) |
| Фактически играемый город | `scenes/world/city/city.tscn` | `ComplexWorld.CITY_SCENE` — compact hub, markers, POI prefabs, gates |

Весь substantive layout / POI / route материал в пакете относится к **live `city.tscn`**, плюс отдельный дамп и 2 скриншота Street Slice.

---

## Содержимое пакета

| Файл / папка | Часть | Описание |
|--------------|-------|----------|
| `01_CITY_CONTEXT.md` | 1 | Игровой цикл, прогрессия, city activities, источники |
| `02_CURRENT_CITY_STATE.md` | 2 | Дерево, размеры, маршрут, POI, проблемы |
| `current_city_nodes.json` | 2 | Live city nodes (transforms, AABB, collision, …) |
| `city_street_slice_nodes.json` | 2 | Street Slice nodes |
| `03_CITY_ASSET_CATALOG.md` | 3 | Каталог megakit + prefabs по категориям |
| `city_asset_catalog.json` | 3 | 173 asset records |
| `screenshots/assets_*.png` | 3 | Contact sheets |
| `04_SCREENSHOT_INDEX.md` | 4 | Индекс всех кадров + camera meta |
| `screenshot_index_data.json` | 4 | Сырые meta |
| `screenshots/current/*.png` | 4 | Top-down, route, POI, junctions, edges… |
| `05_TECHNICAL_HANDOFF.md` | 5 | Writable scope, contracts, travel, outline, GeneratedCity |
| `copies/` | 5 | Копии `.gd` / `.tscn` / `.md` / shader / tools (без тяжёлых meshes) |

---

## Быстрый старт для LD

1. Прочитать `01_CITY_CONTEXT.md` — зачем город в игре.  
2. Открыть `screenshots/current/01_topdown_full.png` + `03_topdown_route.png`.  
3. Пройти `05_route_*.png` и `07_poi_*.png`.  
4. Сверить координаты в `current_city_nodes.json`.  
5. Смотреть доступный kit в `03_CITY_ASSET_CATALOG.md` + contact sheets.  
6. Перед redesign — `05_TECHNICAL_HANDOFF.md` (что нельзя ломать).  
7. Тексты исходников — `copies/`.

---

## Обнаруженные пробелы / ограничения выгрузки

1. **GodotIQ MCP** в сессии экспорта был недоступен (`MCP process client not registered`) — дамп через headless/windowed Godot scripts.  
2. **Headless Dummy renderer** не отдаёт bitmap — скриншоты сняты отдельным non-headless minimized запуском (`tools/export_city_handoff_shots.gd`).  
3. Скриншоты — **SubViewport capture** сцены `city.tscn` / Street Slice, не полный FPS playthrough через `ComplexWorld` (без mount offset ×1.5 и без runtime-spawned Interactable FocusProxy).  
4. Contact sheet `assets_landmarks_01.png` содержит мало крупных Building_* (kit classification: большинство Building_* попали в buildings/residential heuristics).  
5. AABB некоторых Prop/Planter в JSON могут быть завышены — проверять в редакторе.  
6. Collision flag для CSG pads часто `false` в экспорте; walkability опирается на `PerimeterCollision/FloorCollider` и prefab StaticBody.  
7. Тяжёлые `.gltf` / textures **не** включены в ZIP — только пути и contact sheets.  
8. Runtime interacts создаются кодом при mount — в статическом `city.tscn` их NodePath нет.  
9. Документы могут иметь drift vs код; в `01`/`05` приоритет у кода/validate scripts.

---

## Воспроизведение экспорта (для обновления пакета)

```text
godot --headless --path . -s res://tools/export_city_handoff.gd
godot --path . -s res://tools/export_city_handoff_shots.gd
godot --headless --path . -s res://tools/gen_city_handoff_md.gd
```

Затем пересобрать ZIP из `docs/city_handoff/`.

---

## Статус

`HANDOFF PACKAGE READY — NO CITY REBUILD`  
Визуальная приёмка новой планировки — на стороне LD / пользователя после redesign.
