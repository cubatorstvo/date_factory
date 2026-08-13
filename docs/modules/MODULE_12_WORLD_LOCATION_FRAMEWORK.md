# MODULE 12 — WORLD & LOCATION FRAMEWORK

**Проект:** Date Factory  
**Модуль:** 12 — World & Location Framework  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** собрать физический FPS-мир из девяти компактных локаций, реализовать загрузку и переходы между ними, стадийные ограничения доступа, внутренние story-gates, точки размещения Player/NPC/сюжетных событий и минимальные физические интерактивные объекты  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/08_locations_ui_content.md`, `docs/tech/TECH_PLAN_FULL.md`  
**Предыдущие модули:** MODULE 01, MODULE 04, MODULE 11  
**Следующий модуль:** MODULE 13 — Salary Mine & Money Loop

---

# 0. ГЛАВНЫЙ ПРИНЦИП

Date Factory НЕ строит большой бесшовный open world.

Канон:

> Мир компактный. Большая карта не является ценностью сама по себе.

MODULE 12 реализует:

```text
несколько маленьких отдельных 3D-сцен
+
быстрые явные переходы между ними
+
story access gates
```

Не реализовывать:

- open-world streaming;
- seamless city;
- terrain world;
- chunk streaming;
- traffic;
- pedestrian simulation;
- NPC schedules;
- navmesh city population;
- day/night world simulation;
- fast-travel map;
- vehicles;
- procedural city.

---

# 1. Канонические Location IDs

Использовать уже существующие девять ID:

```text
apartment
city_hub
cafe
gym
appearance_space
salary_mine
laboratory
production_area
final_location
```

Не добавлять новые canonical location IDs в MODULE 12.

---

# 2. Смысл девяти локаций

## apartment

Физическая стартовая локация.

Будущие функции:

- старт;
- телефон;
- гардероб;
- интерактивные подписи;
- бытовые гэги;
- визуальные изменения прогресса.

MODULE 12 реализует только:

- blockout квартиры;
- стартовую точку;
- физический телефон → существующий PhoneJournal;
- выход в город;
- marker для будущего гардероба/контента.

---

## city_hub

Центральный связующий узел ручной части игры.

Будущие функции:

- fixed girl situations;
- ordinary rivals;
- магазины;
- доступ к другим locations;
- видимый рост статуса.

MODULE 12 реализует:

- компактный blockout;
- spokes/transitions;
- NPC/story markers;
- отдельный внутренний `PUBLIC_CITY_ACCESS` gate.

---

## cafe

Ранняя основная площадка свиданий и spatial dating events.

MODULE 12:

- blockout кафе;
- несколько story/event markers;
- NPC markers;
- обратный переход в city hub.

Dating content MODULE 14.

---

## gym

Пространство:

- Muscle;
- rivals;
- Slap;
- physical activities.

MODULE 12 только физический blockout + markers.

---

## appearance_space

Комбинированное пространство:

- studio;
- runway;
- salon;
- dance;
- photo.

MODULE 12 только blockout + markers.

---

## salary_mine

Физическая оболочка Salary Mine.

MODULE 13 реализует деньги/зарплату.

MODULE 12:

- entry;
- compact mine blockout;
- salary interaction marker;
- NPC/story markers;
- return transition.

---

## laboratory

Поздняя лаборатория.

Будущие функции:

- first clone;
- cloning minigame;
- terminal;
- local production;
- date rooms;
- conveyor.

MODULE 12:

- physical shell;
- markers/rooms placeholders;
- no clone mechanics.

---

## production_area

Отдельная поздняя производственная локация для масштабирования.

Не использовать её для ранней лабораторной производственной линии.

Она открывается только на `WORLD_EXPANSION`.

---

## final_location

Пустая/placeholder физическая оболочка финальной локации.

MODULE 21 наполнит её финальной последовательностью.

---

# 3. Story-access mapping — EXACT

Canonical access mapping:

```text
apartment
→ ALWAYS AVAILABLE

city_hub
→ StoryFeature.SOCIAL_ACCESS

cafe
→ StoryFeature.SOCIAL_ACCESS

gym
→ StoryFeature.SOCIAL_ACCESS

appearance_space
→ StoryFeature.SOCIAL_ACCESS

salary_mine
→ StoryFeature.SALARY_MINE

laboratory
→ StoryFeature.LABORATORY

production_area
→ StoryFeature.WORLD_EXPANSION

final_location
→ StoryFeature.FINAL_DATE
```

---

# 4. Почему PUBLIC_CITY_ACCESS не отдельная Location

В ContentDB уже существуют ровно девять canonical locations.

`PUBLIC_CITY_ACCESS` означает:

> после линии Актрисы открывается более публичная/статусная часть города.

MODULE 12 НЕ создаёт:

```text
city_hub_2
rich_district
downtown
```

как десятую location.

Вместо этого внутри:

```text
city_hub
```

существует:

```text
WorldFeatureGate
```

для:

```text
StoryFeature.PUBLIC_CITY_ACCESS
```

За этим gate MODULE 14 позже размещает более статусный content.

---

# 5. Prologue physical consequence

На `PROLOGUE` доступны:

```text
apartment
```

Город и основные социальные локации закрыты.

Это поддерживает сценарную структуру:

```text
соседка
→ завершение Пролога
→ STAGE_1 / SOCIAL_ACCESS
→ полноценный городской слой
```

MODULE 14 размещает actual neighbor content.

---

# 6. LocationDefinition

Существующий:

```text
LocationDefinition
```

остаётся static source данных location.

Не превращать его в generic world rule container.

Минимально нужны существующие:

```text
id
display_name
description
scene_path
```

MODULE 12 должен заполнить:

```text
scene_path
```

для всех 9 canonical locations.

---

# 7. Access НЕ хранить в LocationDefinition

Не добавлять:

```text
required_stage
required_story_feature
requirements[]
```

в `LocationDefinition`.

Почему:

- canonical access mapping всего из 9 locations;
- StoryFeature уже semantic source;
- generic requirement data layer здесь лишний.

Canonical mapping принадлежит:

```text
World
```

как explicit small match/map.

---

# 8. scene_path теперь обязателен

После MODULE 12 у всех 9 production LocationDefinition:

```text
scene_path != ""
```

и путь должен существовать.

Пример semantic:

```text
res://world/locations/apartment/apartment.tscn
```

---

# 9. Content validation extension

Для canonical production locations проверить:

- scene_path non-empty;
- resource exists;
- path заканчивается `.tscn`;
- PackedScene loadable;
- instantiated root является `WorldLocation`;
- root.location_id совпадает с LocationDefinition.id.

Не instantiate все location scenes каждый frame.

Validation происходит test/startup debug path.

---

# 10. World service

Создать lightweight service:

```text
World
```

или, если в проекте конфликт имени, однозначный:

```text
WorldRouter
```

Предпочтение:

```text
World
```

Ответственность:

- current location;
- access query;
- travel request;
- load/unload location scene;
- Player transfer/spawn;
- transition busy guard;
- location signals;
- reset to start.

---

# 11. World lifetime

Предпочтительно:

```text
autoload World
```

или persistent bootstrap node, существующий независимо от конкретной location scene.

Cursor должен выбрать Godot-native вариант после audit.

Критические гарантии:

- location scene может полностью unload;
- `World` остаётся жив;
- Player переносится/пересоздаётся корректно;
- service не нужно вручную добавлять в каждую location.

---

# 12. Не создавать WorldManager + LocationManager + TravelManager

Одна маленькая система достаточна.

Не создавать:

```text
WorldManager
LocationManager
TravelManager
SpawnManager
SceneLoader
GateManager
```

как отдельные managers.

Нужны simple nodes/classes вокруг одного World owner.

---

# 13. Current location state

Runtime:

```text
current_location_id: StringName
```

MODULE 12 НЕ обязан сохранять его в GameState.

MODULE 24 позже отвечает за persistence текущей локации.

На обычном new game:

```text
apartment
```

---

# 14. current location signals

World emit:

```text
location_loading(location_id)
location_changed(new_location_id, previous_location_id)
travel_rejected(target_location_id, reason)
```

Имена могут отличаться.

Не создавать global EventBus.

---

# 15. WorldAccessStatus

Создать небольшой enum:

```text
AVAILABLE
LOCKED_STORY
UNKNOWN_LOCATION
SCENE_MISSING
```

`TRANSITION_BUSY` относится к travel result, а не постоянному access.

---

# 16. WorldAccessResult

Typed read result semantic:

```text
location_id
status

required_feature
current_stage

message
```

`required_feature` нужен только при story lock.

Не возвращать arbitrary Dictionary, если typed RefCounted прост.

---

# 17. Access API

Нужны:

```text
get_location_access(location_id) -> WorldAccessResult
is_location_available(location_id) -> bool
get_required_feature(location_id) -> StoryFeature / optional
```

---

# 18. Access source

Для story-gated locations World вызывает:

```text
Story.is_feature_unlocked(required_feature)
```

Не сравнивать integer stage вручную в нескольких местах.

---

# 19. `GameState.unlocked_locations` — canonical meaning

MODULE 02 уже содержит persistent:

```text
unlocked_locations
```

MODULE 12 НЕ использует его как duplicate storage canonical stage access.

То есть НЕ делать на каждом stage transition:

```text
GameState.unlock_location("cafe")
GameState.unlock_location("gym")
...
```

Canonical девять location gates выводятся из `StoryFeature`.

---

# 20. Зачем оставить unlocked_locations

Существующий GameState API не удалять.

Его semantic после MODULE 12:

> explicit/manual persistent unlock для будущих authored locations/shortcuts, которые НЕ выводятся из StoryFeature.

В текущих 9 canonical locations MODULE 12 его не требует.

Это предотвращает два источника истины:

```text
Story says locked
GameState says unlocked
```

---

# 21. Apartment ALWAYS

`apartment` не требует Story.

Даже если Story autoload отсутствует в isolated test:

```text
apartment AVAILABLE
```

---

# 22. Missing Story service

Для story-gated production location:

если `/root/Story` отсутствует:

```text
LOCKED_STORY
```

в production path.

Test override может inject access provider, если необходимо.

Не fail-open.

---

# 23. WorldLocation

Создать scene-root contract:

```text
class_name WorldLocation
extends Node3D
```

Минимально:

```text
@export var location_id: StringName
```

---

# 24. WorldLocation responsibilities

Только:

- идентификация location;
- поиск typed markers в собственном subtree;
- optional registration с World;
- optional refresh gates.

НЕ:

- Story progression;
- NPC AI;
- salary;
- dating;
- spawning production story content.

---

# 25. Location scene contract

Каждая location scene содержит логически:

```text
WorldLocation
├── Geometry
├── Collisions
├── PlayerSpawns
├── NpcSpawns
├── StoryEventPoints
├── FeatureGates
├── Interactables
└── Transitions
```

Не обязательно ровно такие node names.

---

# 26. Blockout geometry

MODULE 12 — gameplay blockout, не art pass.

Разрешено/предпочтительно использовать:

- `MeshInstance3D` с BoxMesh/PlaneMesh;
- `StaticBody3D`;
- `CollisionShape3D`;
- простые материалы;
- примитивные двери/коридоры.

Не тратить время на:

- финальные city assets;
- paid pack;
- donor art integration;
- textures;
- decorative props;
- lighting polish.

---

# 27. CSG

Можно использовать CSG только если Cursor считает его безопасным для быстрого editor blockout.

Но production runtime blockout предпочтительно:

```text
MeshInstance3D + StaticBody3D
```

чтобы не создавать лишнюю CSG runtime cost/complexity.

---

# 28. Масштаб

Все locations должны быть компактны.

Ориентиры, не строгие dimensions:

```text
apartment:      1–3 комнаты
city_hub:       1 небольшая улица/площадь + закрытый второй сегмент
cafe:           1 основной зал
gym:            1 основной зал
appearance:     1 studio/runway hall
salary_mine:    1 короткий шахтный зал/туннель
laboratory:     2–4 функциональные зоны
production:     1 крупный, но компактный hall
final:          1 placeholder set
```

Не делать многоминутное хождение между функциями.

---

# 29. Player ownership

MODULE 12 должен использовать существующий Player FPS.

Не копировать Player в девять independent `.tscn` вручную, если это создаёт девять разных runtime instances/state paths.

Предпочтительно:

```text
persistent Player
```

живёт у World/bootstrap и переносится между location scenes.

Допустима другая architecture Cursor, если Player gameplay state не теряется.

---

# 30. Player state across travel

При travel сохраняются:

- GameState;
- Player control configuration;
- purchased perks;
- session-independent state.

Player transform заменяется на target spawn transform.

Velocity:

```text
reset to Vector3.ZERO
```

чтобы игрок не вылетал из двери после load.

---

# 31. PlayerSpawnPoint

Создать:

```text
class_name PlayerSpawnPoint
extends Marker3D
```

Минимально:

```text
@export var spawn_id: StringName
```

Canonical prefix:

```text
spawn_*
```

---

# 32. Spawn IDs local to location

`spawn_id` уникален только внутри конкретной location.

Не нужен global registry.

Каждая location обязана иметь:

```text
spawn_default
```

---

# 33. Travel target spawn

WorldTransition содержит:

```text
target_location_id
target_spawn_id
```

Если target spawn не найден:

- debug error;
- fallback на `spawn_default`, если он существует;
- если default тоже отсутствует — travel fail без уничтожения current location.

---

# 34. Spawn orientation

Player получает:

```text
global_transform = marker.global_transform
```

или эквивалент position + yaw.

Pitch camera reset:

предпочтительно:

```text
0
```

если текущий FPS controller технически хранит pitch отдельно.

Не наследовать случайный look pitch между дверями, если это выглядит странно.

---

# 35. NpcSpawnPoint

Создать:

```text
class_name NpcSpawnPoint
extends Marker3D
```

Минимально:

```text
@export var spawn_id: StringName
```

Optional enum:

```text
GENERIC
GIRL
RIVAL
```

только если реально помогает validation/editor.

---

# 36. NpcSpawnPoint не спавнит NPC

MODULE 12 НЕ создаёт automatic NPC spawner.

Marker — физическая точка для MODULE 14/19.

Не добавлять:

```text
content_id
spawn_chance
schedule
respawn_time
```

---

# 37. StoryEventPoint

Создать:

```text
class_name StoryEventPoint
extends Marker3D
```

Минимально:

```text
@export var event_point_id: StringName
```

Canonical prefix:

```text
story_point_*
```

MODULE 14/15/17/21 смогут найти authored point.

---

# 38. StoryEventPoint не запускает Story сам

Marker ничего не знает:

- о stage;
- о girl;
- о rival;
- о cutscene.

Это просто named transform.

---

# 39. Marker lookup API

WorldLocation предоставляет:

```text
get_player_spawn(spawn_id)
get_npc_spawn(spawn_id)
get_story_event_point(point_id)
```

или equivalently clean helpers.

No SceneTree global search.

---

# 40. Duplicate marker validation

Внутри одной location:

- Player spawn IDs unique;
- NPC spawn IDs unique;
- Story point IDs unique.

При duplicate:

```text
validation error
```

---

# 41. WorldTransition

Создать physical interactable semantic:

```text
WorldTransition
```

Он использует existing MODULE 01 interaction system.

Минимальные exports:

```text
target_location_id: StringName
target_spawn_id: StringName = &"spawn_default"
display_name: String
```

---

# 42. Interaction prompt

Unlocked:

```text
[E] <destination display name>
```

Например:

```text
[E] Выйти в город
[E] Войти в кафе
```

---

# 43. Locked transition prompt

Locked transition остаётся физически читаемым.

Prompt:

```text
[E] Недоступно — <reason>
```

или interact → short message.

Не делать дверь полностью без prompt.

---

# 44. Lock reason

Functional reason выводится из required StoryFeature.

Не писать spoiler-heavy:

```text
Победи Учёную...
```

Generic:

```text
Пока недоступно по сюжету
```

или stage/feature display.

MODULE 22 позже polish.

---

# 45. WorldTravelResult

Semantic outcomes:

```text
SUCCESS
LOCKED
UNKNOWN_LOCATION
SCENE_MISSING
SPAWN_MISSING
BUSY
NO_PLAYER
LOAD_FAILED
```

---

# 46. Travel API

```text
request_travel(
    target_location_id,
    target_spawn_id = &"spawn_default"
) -> result / async-safe operation
```

Godot load can be synchronous because scenes compact.

Не создавать threaded streaming unless profiling показывает необходимость.

---

# 47. Travel busy guard

Во время transition:

```text
_world_busy = true
```

Second request:

```text
BUSY
```

No queue.

---

# 48. Travel order — safe

Preferred semantic:

1. validate target ID;
2. validate Story access;
3. load/instantiate target scene;
4. validate target `WorldLocation`;
5. resolve target spawn;
6. lock Player control;
7. swap location;
8. place Player;
9. free old location;
10. unlock control;
11. emit `location_changed`.

Cursor может безопасно менять order для SceneTree mechanics.

Критическая гарантия:

> если target validation/load fails, current location/player остаются usable.

---

# 49. Не удалять старую scene слишком рано

Нельзя:

```text
free current
→ load target
→ target missing
→ игрок в пустоте
```

Target должен быть validated/ready до destructive swap.

---

# 50. Transition control mode

Во время actual scene swap:

```text
PlayerControlMode.MODAL_UI
```

или existing equivalent, блокирующий movement/look.

Не использовать `PAUSED`, если это мешает scene initialization.

После success:

```text
GAMEPLAY
```

если travel начат из ordinary world gameplay.

---

# 51. Return control

MODULE 12 physical WorldTransition работает только из world gameplay.

Не вызывать location travel посреди:

- Dating active session;
- Rival minigame;
- Phone modal.

Existing interact system не должен быть active в этих modes.

---

# 52. Mouse mode

После successful travel:

```text
captured
```

через Player gameplay mode.

---

# 53. Placeholder fade

Допустим простой:

```text
0.1–0.3 s black fade
```

если легко.

Не является Definition of Done.

No cinematic transition framework.

---

# 54. Travel graph — EXACT framework blockout

Canonical connection graph:

```text
apartment
↔ city_hub

city_hub
↔ cafe

city_hub
↔ gym

city_hub
↔ appearance_space

city_hub
↔ salary_mine

city_hub
↔ laboratory

city_hub
↔ production_area

city_hub
↔ final_location
```

---

# 55. Почему hub-and-spoke

Преимущества для Date Factory:

- мало беготни;
- понятно игроку;
- легко добавлять authored content;
- не нужен world map;
- легко тестировать access;
- compact world соответствует GDD.

Не добавлять прямые:

```text
cafe ↔ gym
gym ↔ laboratory
```

в MODULE 12.

MODULE 14 может добавить shortcut, если это реально понадобится.

---

# 56. Apartment ↔ City

На PROLOGUE target city locked.

Apartment exit физически существует, но показывает story lock.

После `SOCIAL_ACCESS` становится usable автоматически.

---

# 57. City spokes dynamic

Transitions к locked late locations уже могут визуально существовать в city hub.

Пример:

```text
Шахта — закрыто
Лаборатория — закрыто
```

При Story feature unlock они становятся active без перезагрузки GameState.

---

# 58. Access refresh

WorldTransition query access:

- при prompt/interact;
- и/или refresh на:
  ```text
  Story.feature_unlocked
  GameState.stage_changed
  ```

Не кешировать lock навсегда при `_ready()`.

---

# 59. `WorldFeatureGate`

Создать generic but small physical gate:

```text
class_name WorldFeatureGate
extends Node3D
```

Только для:

```text
StoryFeature
```

Не generic requirement engine.

---

# 60. WorldFeatureGate fields

Минимально:

```text
@export var required_feature: StoryTypes.StoryFeature
@export var collision_root: Node3D / CollisionObject3D path
@export var visual_root: Node3D path
```

Техническая форма Cursor.

---

# 61. Gate state

Locked:

- collision enabled;
- visual barrier visible;
- optional prompt/label visible.

Unlocked:

- collision disabled;
- barrier hidden/removed.

---

# 62. Gate reaction

На:

```text
Story.feature_unlocked
GameState.stage_changed/restore
```

gate refresh-ится.

Также refresh в `_ready()`.

---

# 63. PUBLIC_CITY_ACCESS gate

`city_hub` обязательно содержит один testable gate:

```text
required_feature =
StoryFeature.PUBLIC_CITY_ACCESS
```

За ним placeholder second public area.

At STAGE_1:

```text
closed
```

At STAGE_2:

```text
open
```

---

# 64. Не телепортировать при unlock

Если player стоит у barrier и Story stage меняется:

- barrier может исчезнуть;
- Player остаётся на месте.

Не auto-travel.

---

# 65. Physical phone

В apartment создать physical interactable:

```text
PhoneInteractable
```

или тонкий adapter над existing Interactable.

---

# 66. Phone action

Interaction:

```text
[E] Телефон
```

открывает существующий:

```text
PhoneJournal
```

MODULE 08 API.

Это наконец даёт Phone физическую точку входа без permanent hotkey.

---

# 67. Phone control

PhoneJournal уже владеет:

```text
MODAL_UI
mouse visible
```

World object только вызывает open.

Не дублировать Phone UI.

---

# 68. Phone absence safety

Если PhoneJournal scene/service missing в isolated world test:

- readable error;
- не crash.

Production MODULE 12 dependencies already include previous modules.

---

# 69. Wardrobe marker

Apartment содержит:

```text
StoryEventPoint / InteractionPoint
```

например:

```text
story_point_wardrobe
```

или placeholder interactable:

```text
Гардероб
```

Но НЕ реализовывать:

- clothing UI;
- inventory;
- Second Outfit selection.

MODULE 14/22 later.

---

# 70. Salary mine interaction marker

В salary_mine создать named point:

```text
story_point_salary_station
```

или dedicated marker.

MODULE 13 использует его для salary mechanic.

Не создавать salary button logic в MODULE 12.

---

# 71. Lab markers

Минимальные named points:

```text
story_point_clone_machine
story_point_clone_terminal
story_point_lab_date_room
```

Можно изменить exact IDs, если Cursor документирует canonical list.

No clone mechanics.

---

# 72. Production marker

Минимум:

```text
story_point_production_line
```

для MODULE 18/19/20.

---

# 73. Final marker

Минимум:

```text
story_point_final_sequence
```

для MODULE 21.

---

# 74. City markers

City hub blockout должен иметь несколько generic marker slots, например:

```text
npc_city_01
npc_city_02
npc_city_03

story_point_city_01
story_point_city_public_01
```

Это framework/demo slots, не production content IDs.

---

# 75. Cafe markers

Минимум:

```text
npc_cafe_01
npc_cafe_02

story_point_cafe_table
story_point_cafe_space_event
```

No dating event content.

---

# 76. Gym markers

Минимум:

```text
npc_gym_rival_01
story_point_gym_slap
story_point_gym_activity
```

No automatic RivalActor.

---

# 77. Appearance markers

Минимум:

```text
npc_appearance_01
story_point_runway
story_point_photo
story_point_dance
```

No Dance minigame auto-launch.

---

# 78. Location blockout visual language

Для сейчас достаточно:

- floors;
- walls;
- openings;
- readable signs/text labels;
- simple colored/neutral materials;
- strong silhouettes.

Не использовать дорогую production art работу.

---

# 79. Signs

Functional blockout может иметь 3D/TextMesh labels:

```text
КАФЕ
КАЧАЛКА
ШАХТА
ЛАБОРАТОРИЯ
```

Это помогает тестировать hub navigation.

Final signage MODULE 23/25.

---

# 80. Collision

Каждая location обязана иметь:

- floor collision;
- wall collision;
- no obvious fall-through;
- no spawn inside collision.

No NavMesh needed.

---

# 81. Out-of-bounds recovery

Не строить full recovery system.

Blockout должен просто не иметь доступных holes.

Test scene может иметь large floor under map as safety net, но production лучше нормальные walls.

---

# 82. Lighting

Минимум:

- WorldEnvironment или simple ambient;
- DirectionalLight/OmniLight enough to see.

No final lighting pass.

---

# 83. Player spawn visibility

`spawn_default` не должен:

- смотреть в стену с расстояния 0;
- стоять внутри transition trigger;
- сразу trigger-ить обратный travel.

---

# 84. Transition anti-loop

После travel Player spawn должен быть расположен вне interaction collision/Area входной двери.

Не должно быть:

```text
enter cafe
→ immediately auto-return
```

Transitions запускаются E interaction, не body-enter auto travel.

---

# 85. No automatic travel on Area enter

WorldTransition только interact.

Не делать:

```text
body_entered → change scene
```

Игрок должен сам нажать E.

---

# 86. LocationDefinition scene path updates

Заполнить все 9 existing `.tres`.

Expected semantic paths:

```text
apartment
→ res://world/locations/apartment/apartment.tscn

city_hub
→ res://world/locations/city_hub/city_hub.tscn

cafe
→ res://world/locations/cafe/cafe.tscn

gym
→ res://world/locations/gym/gym.tscn

appearance_space
→ res://world/locations/appearance_space/appearance_space.tscn

salary_mine
→ res://world/locations/salary_mine/salary_mine.tscn

laboratory
→ res://world/locations/laboratory/laboratory.tscn

production_area
→ res://world/locations/production_area/production_area.tscn

final_location
→ res://world/locations/final_location/final_location.tscn
```

Если current project directory convention требует `game/world/...`, Cursor может адаптировать base path, но IDs и mapping неизменны.

---

# 87. Main/bootstrap

После MODULE 12 обычный запуск проекта должен попадать:

```text
apartment
```

с playable Player.

Не в отдельную module self-test сцену.

---

# 88. Existing Foundation main

Cursor сначала audit текущий:

```text
project.godot
main scene
Player scene
Foundation bootstrap
```

и выбирает минимальную migration.

Не уничтожать debug infrastructure.

---

# 89. World root architecture

Разумный вариант:

```text
Main
├── LocationRoot
├── Player
└── PersistentUI
```

`World` меняет child `LocationRoot`.

Но это recommendation, не mandatory node tree.

---

# 90. UI persistence

Phone/Dating/Rival UI работают поверх location.

MODULE 12 не должен accidental free UI вместе с old location.

Persistent UI owner должен находиться вне unloadable location scene либо создаваться autoload systems как сейчас.

---

# 91. Current minigame world background

07A/B/C/D требуют current 3D world как background.

После World migration это должно продолжить работать.

Не менять scene целиком при запуске Rival minigame.

---

# 92. Dating world background

MODULE 09 functional date UI тоже не должно ломаться из-за World swap architecture.

Dating location travel — пока caller responsibility.

MODULE 12 не автоматически стартует Dates.

---

# 93. Character Framework compatibility

NpcSpawnPoint рассчитан на:

```text
CharacterActor
GirlActor
RivalActor
```

но MODULE 12 их не инстанцирует автоматически.

MODULE 14 authoring может:

```text
instance actor
→ set global_transform = marker
```

---

# 94. Story presence compatibility

MODULE 14 сможет query:

```text
Story.should_story_girl_be_present(id)
Story.should_story_rival_be_present(id)
```

и использовать World markers.

MODULE 12 не делает это заранее.

---

# 95. Location access test override

Для isolated self-tests допустим:

```text
World.set_access_provider_for_test(callable)
```

или direct stage restore.

Не добавлять production cheat API без необходимости.

Предпочтительно tests используют:

```text
GameState.restore_stage(...)
Story.is_feature_unlocked(...)
```

---

# 96. Scene load validation

World должен убедиться:

```text
PackedScene != null
instance is WorldLocation
instance.location_id == requested ID
```

Mismatch:

```text
LOAD_FAILED
```

Current location сохраняется.

---

# 97. Transition target validation

В editor/runtime self-test проверить все WorldTransition:

- target LocationDefinition exists;
- target scene path exists;
- target spawn exists в target scene.

Можно сделать dedicated world validation test, не expensive validation every frame.

---

# 98. Circular graph validation

Every non-apartment spoke должен иметь путь обратно:

```text
→ city_hub
```

Apartment:

```text
→ city_hub
```

City hub:

```text
→ apartment
```

No softlock room.

---

# 99. Final location return

MODULE 12 placeholder final location может иметь debug/physical return:

```text
final_location → city_hub
```

пока MODULE 21 не перехватит sequence.

Это позволяет framework test.

MODULE 21 может позже disable return during final attempt.

---

# 100. Locked travel no mutation

Если location locked:

- current scene не unload;
- Player transform unchanged;
- current_location_id unchanged;
- World busy false after rejection.

---

# 101. Unknown location no mutation

Same.

---

# 102. Missing spawn no mutation

Target can be instantiated in temporary validation holder; if no spawn:

- reject;
- free temp target;
- keep current world.

---

# 103. Busy request

If travel already running:

```text
BUSY
```

Second target does not overwrite first.

---

# 104. Reset to apartment

World exposes:

```text
reset_to_start()
```

или listens to GameState reset.

On new game/reset:

```text
apartment
spawn_default
```

If reset occurs during self-test no Player, handle safely.

---

# 105. Stage change while in late location

MODULE 11 stage is monotonic in gameplay, so ordinary downgrade не бывает.

Save/debug `restore_stage` could lower stage while Player physically inside a now-locked late location.

MODULE 12 policy:

```text
НЕ auto-teleport
```

Current location remains until next travel/reset.

New transitions into locked location are blocked.

This avoids destructive debug/load surprises.

MODULE 24 can normalize restore later.

---

# 106. Feature unlock while in city

At STAGE_1 city public gate closed.

When Story advances STAGE_2:

```text
gate opens dynamically
```

No reload needed.

---

# 107. Physical access and GameState story

World does not advance Story.

Entering salary mine does NOT:

- complete stage;
- grant money;
- set Story flags.

Physical location is consequence, not story trigger, unless future MODULE 14 adds explicit event.

---

# 108. Interactive object base

Use existing MODULE 01 Interactable.

MODULE 12 can add thin subclasses/adapters:

```text
WorldTransition
PhoneInteractable
WorldFeatureGatePrompt
```

Do not replace the existing interaction framework.

---

# 109. Interaction distance

Use existing Player interaction distance/raycast.

No location-specific different interaction system.

---

# 110. Physical captions

Apartment/world blockout may add one or two demo interactables proving generic world object support.

Example:

```text
Ламинат
→ "Пахнет ламинатом и надеждами."
```

Но this is optional and content-like.

MODULE 25 owns broad caption content.

Do not spend time on joke catalog now.

---

# 111. World scene ownership of environment

Each location can own its own:

- WorldEnvironment;
- lights;
- fog;
- background.

Travel unloads them with location.

Do not create one giant environment manager.

---

# 112. Audio boundary

No location music system.

Ambient audio optional placeholder only.

MODULE 23 later.

---

# 113. No save/load

Current location persistence is MODULE 24.

Do not write save JSON in MODULE 12.

---

# 114. No loading screen system

A simple fade/label is enough.

No progress bar/threaded asset loader.

Scenes are intentionally small.

---

# 115. No multiplayer

No network location sync.

Single-player project.

---

# 116. No donor dependency requirement

Donor may be audited for useful primitive/location assets, but MODULE 12 should not depend on donor geometry to pass.

Blockout must work even with only Godot primitives.

---

# 117. Test — ContentDB location count

Expected:

```text
9
```

IDs exact.

---

# 118. Test — every location scene path

All 9:

```text
non-empty
exists
loadable
WorldLocation root
matching location_id
```

---

# 119. Test — every location spawn_default

All 9 contain:

```text
spawn_default
```

---

# 120. Test — start world

Normal project start:

```text
current_location_id = apartment
Player present
GAMEPLAY
```

---

# 121. Test — Prologue access

At:

```text
PROLOGUE
```

Expected:

```text
apartment AVAILABLE

city_hub LOCKED
cafe LOCKED
gym LOCKED
appearance_space LOCKED
salary_mine LOCKED
laboratory LOCKED
production_area LOCKED
final_location LOCKED
```

---

# 122. Test — Stage1 access

At:

```text
STAGE_1
```

Expected:

```text
apartment available
city_hub available
cafe available
gym available
appearance_space available

salary_mine locked
laboratory locked
production_area locked
final locked
```

---

# 123. Test — Public City Stage1

At STAGE_1:

```text
city_hub PUBLIC_CITY_ACCESS gate locked
collision enabled
barrier visible
```

---

# 124. Test — Public City Stage2

At STAGE_2:

```text
gate unlocked
collision disabled
barrier hidden
```

---

# 125. Test — Salary Mine

STAGE_2:

```text
salary_mine locked
```

STAGE_3:

```text
available
```

---

# 126. Test — Lab

STAGE_4:

```text
laboratory locked
```

STAGE_5:

```text
available
```

---

# 127. Test — Production

STAGE_5:

```text
production_area locked
```

STAGE_6:

```text
available
```

---

# 128. Test — Final

STAGE_6:

```text
final_location locked
```

FINALE:

```text
available
```

---

# 129. Test — GameState unlocked_locations not required

At STAGE_3:

```text
GameState.unlocked_locations empty
```

yet:

```text
salary_mine available
```

via Story feature.

---

# 130. Test — manual unlock does not bypass story canonical gate

If test calls:

```text
GameState.unlock_location("laboratory")
```

at STAGE_1:

canonical World access remains:

```text
LOCKED_STORY
```

for the built-in nine.

This proves no duplicate source of truth.

---

# 131. Test — apartment travel

From apartment after STAGE1:

```text
request city_hub
```

Success:
- old scene replaced;
- current ID city;
- Player at correct spawn;
- velocity zero.

---

# 132. Test — return travel

City → apartment exact target spawn.

---

# 133. Test — every spoke round trip

From city:
- cafe → city;
- gym → city;
- appearance → city;
- mine → city when unlocked;
- lab → city when unlocked;
- production → city when unlocked;
- final → city when unlocked/test.

No softlocks.

---

# 134. Test — locked travel

At STAGE1 request salary_mine.

Expected:

```text
LOCKED
```

No current-world mutation.

---

# 135. Test — unknown location

```text
&"moon_base"
```

=> `UNKNOWN_LOCATION`.

---

# 136. Test — scene missing

Test override LocationDefinition invalid path.

Expected:
- `SCENE_MISSING/LOAD_FAILED`;
- current world intact.

---

# 137. Test — spawn missing

Target valid scene, invalid spawn ID and no fallback in isolated fixture:

```text
SPAWN_MISSING
```

Current world intact.

---

# 138. Test — spawn fallback

If requested spawn missing but `spawn_default` exists:

fallback allowed and logged.

Result still success.

---

# 139. Test — duplicate travel

During busy:

second request:

```text
BUSY
```

---

# 140. Test — location_changed signal

Successful travel emits once with:

```text
new
previous
```

Failed travel emits none.

---

# 141. Test — marker lookup

For each fixture location:
- valid marker found;
- missing returns null;
- no global accidental marker.

---

# 142. Test — duplicate marker validation

Fixture with duplicate spawn ID fails validation.

---

# 143. Test — no automatic NPC spawning

Load city.

No GirlActor/RivalActor appears merely because NpcSpawnPoints exist.

---

# 144. Test — Character placement compatibility

Instantiate test CharacterActor manually at NpcSpawnPoint.

Transform exact.

No World system mutation needed.

---

# 145. Test — StoryEventPoint lookup

Known point returns transform.

---

# 146. Test — Phone physical integration

Apartment:
```text
interact Phone
→ PhoneJournal opens
→ MODAL_UI
```

Close:
```text
GAMEPLAY
```

No phone hotkey added.

---

# 147. Test — transition while Phone open

World transition interaction not possible while Phone MODAL_UI.

---

# 148. Test — Rival regression

Start Rival encounter in a World location.

Minigame uses current world background and returns without unloading location.

---

# 149. Test — Dating UI regression

Functional Dating UI can open while world remains loaded.

No location loss.

---

# 150. Test — stage gate dynamic refresh

Load city at STAGE1.

Advance/restore STAGE2.

Public gate updates without reloading city.

---

# 151. Test — late location lock after debug downgrade

Load lab at STAGE5.

Debug restore STAGE1.

Expected:
- player remains in lab;
- leaving to city works because city available;
- re-enter lab blocked.

No auto teleport.

---

# 152. Test — reset

From any location:

```text
GameState reset / World.reset_to_start
→ apartment
→ spawn_default
```

---

# 153. Test — no stage mutation

Travel through all locations.

GameState.stage unchanged.

---

# 154. Test — no money mutation

Enter salary mine before MODULE13 test unlock.

Money unchanged.

---

# 155. Test — no story flags

Enter lab/production/final.

No Story flags set by location load itself.

---

# 156. Regression MODULE 01

FPS:
- movement;
- interaction;
- control modes;
- mouse capture

PASS across travel.

---

# 157. Regression MODULE 04

CharacterActor works in location scenes.

---

# 158. Regression MODULE 08

PhoneJournal still works.

GirlActor can be manually placed in world scene/test.

---

# 159. Regression MODULE 11

Story features exact.

World never modifies Story stage.

---

# 160. Regression MODULE 06–10

Rival/Dating/Relationships continue independent of world loading.

Run full existing suite.

---

# 161. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/08_locations_ui_content.md
```

Документировать:

- 9-scene world;
- hub-and-spoke;
- story access mapping;
- `PUBLIC_CITY_ACCESS` as internal city gate;
- canonical meaning of `GameState.unlocked_locations`;
- WorldLocation/marker/transition contracts.

---

# 162. PROJECT_STRUCTURE

Expected semantic:

```text
world/
├── world.gd
├── world_types.gd
├── world_location.gd
├── world_transition.gd
├── world_feature_gate.gd
├── player_spawn_point.gd
├── npc_spawn_point.gd
├── story_event_point.gd
├── phone_interactable.gd
├── locations/
│   ├── apartment/
│   ├── city_hub/
│   ├── cafe/
│   ├── gym/
│   ├── appearance_space/
│   ├── salary_mine/
│   ├── laboratory/
│   ├── production_area/
│   └── final_location/
└── test/
```

Не обязано быть ровно так, если repo conventions другие.

---

# 163. Что MODULE 12 НЕ реализует

Категорически не реализовывать:

- Salary Mine income;
- salary calculation;
- production story NPCs;
- ordinary NPC population;
- dating content;
- story scenes;
- city shops economy;
- wardrobe system;
- clothing inventory;
- photo mechanic;
- clone mechanic;
- production counters;
- media;
- traffic;
- NPC schedules;
- NPC navigation;
- open-world streaming;
- large city;
- save/load;
- final sequence;
- visual art polish.

---

# 164. Definition of Done

MODULE 12 завершён только если:

- [ ] существует один canonical World owner;
- [ ] нет manager proliferation;
- [ ] current location runtime tracked;
- [ ] new game starts in apartment;
- [ ] ровно 9 canonical LocationDefinition;
- [ ] все 9 имеют valid `scene_path`;
- [ ] все 9 имеют playable blockout `.tscn`;
- [ ] root каждой = WorldLocation;
- [ ] root location ID matches ContentDB;
- [ ] все имеют `spawn_default`;
- [ ] Player реально ходит в каждой scene;
- [ ] hub-and-spoke travel graph работает;
- [ ] apartment ↔ city;
- [ ] city ↔ 7 spokes;
- [ ] travel only on interaction E, not body enter;
- [ ] target scene validates before destructive unload;
- [ ] failed travel preserves current location;
- [ ] busy guard works;
- [ ] Player velocity reset on arrival;
- [ ] Story access mapping exact;
- [ ] apartment always available;
- [ ] city/cafe/gym/appearance = SOCIAL_ACCESS;
- [ ] salary_mine = SALARY_MINE;
- [ ] laboratory = LABORATORY;
- [ ] production_area = WORLD_EXPANSION;
- [ ] final_location = FINAL_DATE;
- [ ] PUBLIC_CITY_ACCESS implemented inside city_hub, not tenth location;
- [ ] WorldFeatureGate dynamic refresh works;
- [ ] canonical access derived from Story, not duplicated in GameState unlocks;
- [ ] existing unlocked_locations remains only explicit/future manual seam;
- [ ] PlayerSpawnPoint typed;
- [ ] NpcSpawnPoint typed;
- [ ] StoryEventPoint typed;
- [ ] marker lookups local to location;
- [ ] duplicate marker validation;
- [ ] markers do not auto-spawn NPCs;
- [ ] physical Phone in apartment opens existing PhoneJournal;
- [ ] functional placeholder markers exist for future modules;
- [ ] no Salary Mine mechanic implemented;
- [ ] no production NPC/story content implemented;
- [ ] no open-world system;
- [ ] MODULE 01/04/06–11 regressions pass;
- [ ] normal project main boots into actual world, not test harness;
- [ ] MODULE 13 not implemented ahead.

---

# 165. Порядок выполнения Cursor

## Step 1 — Audit current project

Проверить фактические:

```text
project.godot main_scene
Player scene / control API
Interactable
LocationDefinition resources
ContentDB location catalog
GameState unlocked_locations
Story feature API
PhoneJournal opening API
current persistent UI/minigame ownership
```

---

## Step 2 — choose World lifetime architecture

Выбрать минимальный Godot-native owner:

```text
autoload World
```

или persistent bootstrap.

Гарантировать:
- location unload;
- Player persistence;
- UI persistence.

Документировать решение.

---

## Step 3 — core typed world classes

Реализовать:

```text
WorldLocation
PlayerSpawnPoint
NpcSpawnPoint
StoryEventPoint
WorldTransition
WorldFeatureGate
```

без content mechanics.

---

## Step 4 — access mapping

Exact StoryFeature mapping из этой спецификации.

Не использовать GameState unlocked_locations как duplicate story access.

---

## Step 5 — travel pipeline

Сначала без красивого fade:

```text
validate
load
spawn
swap
cleanup
signals
```

---

## Step 6 — build nine blockout scenes

Godot primitives.

Сначала:
```text
apartment
city_hub
```

проверить round trip.

Потом остальные spokes.

---

## Step 7 — city public gate

Добавить `PUBLIC_CITY_ACCESS` internal gate и второй placeholder city segment.

---

## Step 8 — update LocationDefinitions

Заполнить scene paths.

Усилить validation.

---

## Step 9 — physical phone

Apartment → PhoneJournal.

No phone hotkey.

---

## Step 10 — future-module markers

Добавить minimal named markers в:
- city;
- cafe;
- gym;
- appearance;
- mine;
- lab;
- production;
- final.

---

## Step 11 — main boot

Обычный запуск проекта:

```text
apartment
```

---

## Step 12 — tests

Прогнать sections 117–155.

---

## Step 13 — regressions

Все предыдущие relevant modules.

---

## Step 14 — docs

Update world architecture/docs.

---

# 166. Формат финального отчёта Cursor

## World architecture

Как живут:

```text
World
Player
LocationRoot
Persistent UI
```

и почему scene swap безопасен.

## Canonical locations

Показать 9 IDs + scene paths.

## Access mapping

Подтвердить exact:

```text
Apartment always
City/Cafe/Gym/Appearance → SOCIAL_ACCESS
Salary Mine → SALARY_MINE
Laboratory → LABORATORY
Production → WORLD_EXPANSION
Final → FINAL_DATE
PUBLIC_CITY_ACCESS → internal city gate
```

## Travel

Подтвердить:
- hub-and-spoke;
- safe validation before unload;
- spawn system;
- busy guard.

## GameState unlocked_locations

Подтвердить, что canonical Story access НЕ дублируется туда.

## Markers

Что реализовано для:
- Player;
- NPC;
- Story events.

## Integrations

Подтвердить:
- apartment Phone → PhoneJournal;
- Story gates dynamic;
- Rival/Dating world background remains intact.

## Validation

MODULE 12 tests + previous regressions.

## Files changed

Основные файлы.

## Product questions

Только реально нерешаемые из текущей документации.

Если нет:

```text
None.
```

---

# 167. Запрет продолжения

После успешного MODULE 12:

**НЕ начинать MODULE 13 — Salary Mine & Money Loop.**

Остановиться и дождаться отдельной спецификации.

---

# ADDENDUM — Date venue locations (2026-08-13)

Канон: `docs/gdd/10_date_venues_outfits.md`. Девять сюжетных локаций MODULE 12 **остаются**. Добавляются отдельные travel-локации свиданий (не city POI):

```text
restaurant
park
cinema
arcade
museum
planetarium
```

Они входят в `World.CANONICAL_IDS`, имеют `LocationDefinition`, сцену `WorldLocation`, `PlayerSpawnPoint` `spawn_default`, `DateVenueInteractable`, `WorldTransition` на `city_hub`. Доступ: `SOCIAL_ACCESS`, как у кафе. Кафе-сцена donor не копируется в ресторан.
