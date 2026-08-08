# MODULE 19 — PHYSICAL CLONE VISUALIZATION

**Проект:** Date Factory  
**Модуль:** 19 — Physical Clone Visualization  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** физически показать в FPS-мире первые клоны и переход к массовым числам, не превращая агрегатную incremental-систему MODULE 18 в симуляцию отдельных NPC.  
**Предыдущий модуль:** MODULE 18 — Clone Incremental Core  
**Следующий модуль:** MODULE 20 — Late Game Expansion  
**Product truth:** `docs/gdd/07_story_clones_finale.md`, раздел 39  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 19

---

# 0. ГЛАВНЫЙ РЕЗУЛЬТАТ

После MODULE 19 игрок, находясь в лаборатории, должен физически видеть:

```text
линия клонирования
→ свободные клоны возле выхода
→ рабочие клоны уходят в рабочий коридор
→ dating-клоны занимают первые физические комнаты свиданий
→ в комнатах есть девушка + клон + короткая циклическая комедийная сцена
→ при росте dating count открываются новые комнаты одна за другой
→ после локального лимита дальнейшие клоны больше не создаются как отдельные NPC
→ они визуально уходят во внешний коридор
→ большие значения продолжают существовать только числами
```

Игрок должен визуально понять переход:

```text
1 клон
→ несколько конкретных тел
→ маленький локальный конвейер
→ слишком много тел для индивидуального наблюдения
→ абстрактный массовый поток
```

---

# 1. КРИТИЧЕСКОЕ ПРАВИЛО АРХИТЕКТУРЫ

MODULE 19 — **только визуализация aggregate state**.

Source of truth остаётся:

```text
GameState.total_clones
GameState.clones_working
GameState.clones_dating
GameState.free_clones

CloneIncremental.money_per_minute
CloneIncremental.dates_per_minute
```

MODULE 19 НЕ хранит:

```text
Clone #1
Clone #2
Clone #3
girl assigned to Clone #7
individual date progress
individual work progress
```

---

# 2. Физические NPC не являются gameplay entities

Все визуальные клоны MODULE 19:

- не имеют persistent ID;
- не имеют сохранения;
- не имеют характеристик;
- не имеют денег;
- не имеют relationship;
- не вызывают DatingCore;
- не вызывают SalaryMine;
- не влияют на rates;
- не являются источником production state.

Их можно полностью удалить и пересоздать из aggregate counts без потери gameplay state.

---

# 3. Не создавать autoload

MODULE 19 НЕ требует:

```text
CloneVisualization autoload
CloneWorldManager
CloneActorRegistry
```

Создать локальный компонент внутри laboratory:

```text
CloneVisualizationController
```

Он живёт только вместе с `laboratory.tscn`.

---

# 4. Controller responsibilities

`CloneVisualizationController`:

- читает aggregate counts;
- показывает/скрывает локальные visual slots;
- создаёт presentation-only CharacterActor;
- проигрывает короткие циклические сцены;
- показывает external/mass flow;
- слушает aggregate signals;
- восстанавливает visuals на `_ready()`.

Не мутирует GameState.

---

# 5. Signals listened

Controller слушает:

```text
GameState.clone_counts_changed
GameState.state_reset
CloneIncremental.clone_produced
```

Optional:

```text
CloneIncremental.assignment_changed
```

не нужен, если `clone_counts_changed` уже покрывает всё.

---

# 6. No gameplay `_process`

Основной refresh:

```text
event-driven
```

Разрешены:

- один локальный `Timer` для cycling dating-room presentation;
- Tween для visual movement;
- один локальный `Timer` для work/mass departure staging.

Не создавать `_process()` на каждом клоне.

---

# 7. Laboratory expansion

Текущий laboratory blockout 12×12 может быть тесным.

MODULE 19 разрешено увеличить physical room примерно до:

```text
22 m × 18 m
```

или ближайшего удобного размера.

Не создавать новую LocationDefinition.

Location остаётся:

```text
laboratory
```

---

# 8. Layout — canonical concept

Лаборатория делится визуально на:

```text
CENTRAL AREA
- Clone Machine
- Clone Terminal
- free waiting area

LEFT / RIGHT WINGS
- 10 date rooms total
- 5 rooms per side
- central observation corridor

WORK EXIT
- work staging pads
- corridor/sign toward work

EXTERNAL EXIT
- mass-flow corridor
- clones beyond local visualization disappear there
```

---

# 9. Dating slots — EXACT COUNT

```text
MAX_LOCAL_DATE_SLOTS = 10
```

Ровно 10 локальных комнат.

Canonical IDs:

```text
clone_date_slot_01
clone_date_slot_02
clone_date_slot_03
clone_date_slot_04
clone_date_slot_05
clone_date_slot_06
clone_date_slot_07
clone_date_slot_08
clone_date_slot_09
clone_date_slot_10
```

---

# 10. Dating slot activation

Slot `N` открыт iff:

```text
GameState.clones_dating >= N
```

Examples:

```text
dating=0
→ 0 rooms active

dating=1
→ slot01 active

dating=6
→ slots01..06 active

dating=10
→ all10 active

dating=34
→ all10 active
→ remaining24 represented as external flow/count
```

---

# 11. «Открывать слоты по одному»

GDD wording реализовать **без новой экономики**:

Каждая dating-room physically starts with:

```text
closed shutter / dark glass
```

Когда aggregate `clones_dating` достигает номера slot:

```text
shutter opens
room light turns on
clone + girl become visible
```

При уменьшении dating count:

```text
highest occupied rooms close first
```

Не добавлять:

- Money cost за комнату;
- отдельный `unlocked_date_slots`;
- новое persistent состояние.

Количество dating clones уже является причиной открытия слотов.

---

# 12. Dating room geometry

Каждый slot:

```text
~2.4–2.8 m width
~2.5–3.0 m depth
```

Содержит:

- transparent/glass front;
- small table;
- two chairs or standing spots;
- room label;
- clone marker;
- girl marker;
- optional small prop.

Simple Godot primitives acceptable.

---

# 13. Room script

Create:

```text
DatingRoomVisual
```

extends:

```text
Node3D
```

Exports:

```text
slot_index: int   # 1..10
clone_marker: NodePath
girl_marker: NodePath
shutter_node: NodePath
room_light_node: NodePath
status_label_node: NodePath
```

---

# 14. Room active API

```text
set_active(active: bool)
```

Active:

- opens shutter;
- lights room;
- ensures clone visual;
- ensures girl visual;
- enables scene presentation.

Inactive:

- closes shutter;
- darkens;
- removes/hides actors;
- label = `"СВОБОДНО"`.

---

# 15. Clone visual actor

Create/reuse lightweight:

```text
CloneVisualActor
```

or reuse `FirstCloneActor` only if it stays clean.

Preferred:

```text
CloneVisualActor
```

thin presentation wrapper around:

```text
CharacterActor
```

No collision with player.

No Interactable.

No AI/navigation.

---

# 16. Clone appearance

All clone visuals intentionally look like the same protagonist proxy.

Use:

```text
appearance_male_first_clone
```

from MODULE 17.

No random variation.

This is important to comedy:

> room after room contains essentially the same man.

---

# 17. Girl visuals in date rooms

Girls in automatic rooms are **anonymous presentation figures**.

They are NOT production `GirlActor`.

They have:

- no girl ID;
- no relationship;
- no contact;
- no journal;
- no DatingCore.

Use CharacterActor female appearances only.

---

# 18. Girl appearance cycle

Use a deterministic list of existing female appearance profiles:

```text
appearance_female_city_bicycle
appearance_female_cafe_laptop
appearance_female_gym_chalk
appearance_female_appearance_ritual
appearance_female_public_sculpture
appearance_female_cafe_receipt_notes
appearance_female_appearance_flash
appearance_female_neighbor
appearance_female_actress
appearance_female_mine_boss
```

Mapping:

```text
slot1 → list0
slot2 → list1
...
slot10 → list9
```

This is visual reuse only.

Do NOT imply these are literally those persistent story/ordinary girls.

No names are displayed inside rooms.

---

# 19. Dating room scenes

Exactly four presentation states:

```text
CALM
OVER_EXPLAINING
SILENT_SUCCESS
MUTUAL_CONFUSION
```

They have NO gameplay result.

---

# 20. Scene cycle

One controller timer:

```text
DATE_SCENE_INTERVAL = 6.0 seconds
```

Every tick:

```text
global_scene_cycle += 1
```

For active slot N:

```text
scene_index = (global_scene_cycle + N) % 4
```

Deterministic.

No RNG needed.

---

# 21. CALM

Presentation:

```text
clone idle/sit
girl idle/sit
```

Label:

```text
ИДЁТ СВИДАНИЕ
```

No special result.

---

# 22. OVER_EXPLAINING

Presentation:

```text
clone gesture loop
girl idle / react if available
```

Label:

```text
КЛОН ОБЪЯСНЯЕТ СВОЮ СИСТЕМУ
```

---

# 23. SILENT_SUCCESS

Presentation:

```text
both idle
minimal gesture
```

Label:

```text
НЕОЖИДАННО УСПЕШНО
```

This does NOT grant Experience.

Real Experience still comes only from CloneIncremental simulation.

---

# 24. MUTUAL_CONFUSION

Presentation:

```text
clone react
girl react/gesture
```

Label:

```text
ОБА СДЕЛАЛИ ВИД, ЧТО ТАК И БЫЛО
```

This does NOT reduce throughput.

---

# 25. Animation fallback

If requested animation does not exist:

- actor remains idle;
- room label still changes;
- no errors;
- no animation-system work in MODULE 19.

MODULE 23 later polishes animation.

---

# 26. Dating room scenes do not sync to Dates/min

Critical:

```text
6-second visual cycle
```

does NOT mean:

```text
10 dates/min
```

and does not consume:

```text
CloneIncremental._date_fraction
```

Visual scenes are ambient theater only.

---

# 27. Work visualization

Exact local cap:

```text
MAX_LOCAL_WORK_VISUALS = 3
```

At most 3 physical worker-clone visuals in laboratory.

---

# 28. Work staging markers

Add:

```text
clone_work_visual_01
clone_work_visual_02
clone_work_visual_03

clone_work_exit
```

near work corridor.

---

# 29. Visible workers

```text
visible_work_count =
min(clones_working, 3)
```

No relation to actual Money/min beyond aggregate count.

---

# 30. Work departure loop

Every:

```text
WORK_DEPARTURE_INTERVAL = 4.0 seconds
```

if `clones_working > 0`:

- choose one visible work clone round-robin;
- Tween it from staging point toward `clone_work_exit`;
- fade/hide at exit;
- restore it to staging point;
- continue loop.

No NavigationAgent.

No CharacterBody movement simulation.

---

# 31. Work sign

Near corridor:

```text
РАБОЧИЙ МАРШРУТ
→ ЗАРПЛАТНАЯ ШАХТА
```

Optional second line:

```text
ВОЗВРАТ НЕ ТРЕБУЕТСЯ ДЛЯ НАЧИСЛЕНИЯ
```

Presentation joke only.

---

# 32. Work movement does not produce Money

Critical:

Tween reaching `clone_work_exit`:

```text
NO GameState.add_money()
```

Money still exclusively comes from:

```text
CloneIncremental
```

---

# 33. Free clone visualization

Exact local cap:

```text
MAX_LOCAL_FREE_VISUALS = 2
```

Add markers:

```text
clone_free_wait_01
clone_free_wait_02
```

near clone output / terminal.

---

# 34. Free visuals

```text
visible_free =
min(GameState.free_clones, 2)
```

They stand idle waiting for assignment.

Label nearby:

```text
СВОБОДНЫЕ КЛОНЫ
```

---

# 35. Production feedback

When local controller receives:

```text
CloneIncremental.clone_produced(new_total)
```

while laboratory loaded:

briefly pulse/flash output machine:

```text
~0.35 sec
```

and show:

```text
КЛОН ГОТОВ
```

for about:

```text
1.0 sec
```

No additional persistent actor required beyond normal count refresh.

---

# 36. Production event does not own visual state

Immediately after `clone_produced`, controller simply refreshes from:

```text
GameState counts
```

It does not increment a local clone list.

---

# 37. External mass flow

Create:

```text
MassCloneFlowVisual
```

local presentation node.

It represents all clones beyond local visible capacity.

---

# 38. External counts — EXACT

Derived:

```text
external_dating =
max(0, clones_dating - 10)

external_work =
max(0, clones_working - 3)

external_free =
max(0, free_clones - 2)

external_total =
external_dating + external_work + external_free
```

No stored values.

---

# 39. External mass label

When `external_total > 0`:

show:

```text
ВНЕШНИЕ ПЛОЩАДКИ

Работа: X
Свидания: Y
Ожидают: Z
```

When zero:

hide or:

```text
ВНЕШНИЙ ПОТОК: 0
```

Preferred hide.

---

# 40. External corridor

Add visual corridor/door with sign:

```text
ВНЕШНИЕ ПЛОЩАДКИ
```

Do NOT label:

```text
ВЕСЬ МИР
ДРУГИЕ СТРАНЫ
```

yet.

World expansion is MODULE 20.

---

# 41. External flow actors

Exact max:

```text
MAX_MASS_FLOW_VISUALS = 2
```

If `external_total > 0`:

show up to 2 looping clone visuals walking/tweening:

```text
mass_flow_spawn
→ mass_flow_exit
→ disappear
→ repeat
```

No more regardless of count.

---

# 42. Mass-flow frequency

Base visual interval:

```text
3.0 seconds
```

If:

```text
external_total >= 20
```

use:

```text
1.5 seconds
```

If:

```text
external_total >= 100
```

use:

```text
0.75 seconds
```

Still at most 2 active flow actors.

This visually communicates scaling without NPC explosion.

---

# 43. External flow does not affect production

No clone is added/removed when a flow actor disappears.

It is theater.

---

# 44. Maximum physical actor budget

At steady local maximum:

```text
10 dating clone actors
10 anonymous female actors
3 work clone actors
2 free clone actors
2 mass-flow clone actors
-------------------------
27 visual CharacterActors maximum
```

This is an absolute MODULE 19 target ceiling.

Do not instantiate 100 actors for 100 clones.

---

# 45. Collision policy

All MODULE19 presentation actors:

```text
no gameplay collision
no interactable collision
```

Player should not get trapped by date-room characters or flow actors.

Glass/walls remain world collision as appropriate.

---

# 46. Raycast interaction policy

Player cannot E-interact with individual date-room clones/girls.

The only existing relevant interaction remains:

```text
Clone Terminal
```

Optional room glass caption may be passive Label3D only.

---

# 47. FirstClone ownership transition

Current MODULE18/17 `FirstClone` maintains one representative.

With MODULE19 laboratory controller active:

```text
FirstClone persistent representative must NOT create a duplicate 28th clone.
```

---

# 48. Suppression contract

Narrowly modify:

```text
FirstClone.reconstruct_representative()
```

Before creating/reparenting representative:

detect current laboratory has:

```text
CloneVisualizationController
```

and that:

```text
total_clones >= 1
```

Then:

```text
_clear_representative()
return
```

MODULE19 owns lab aggregate visualization.

---

# 49. FirstClone fallback remains

If:

- test scene has no visualization controller;
- future temporary scene has no controller;

then old MODULE17 representative behavior remains intact.

Do not delete its fallback/tests.

---

# 50. First-clone reveal unaffected

During first clone sequence:

```text
total_clones == 0
```

Preview/reveal is still fully owned by FirstClone.

CloneVisualizationController does not interfere.

Only AFTER persistent assignment/count commit does MODULE19 aggregate visualization take over.

---

# 51. First assigned clone visual result

Example:

WORK choice:

```text
1/1/0
```

After FirstClone sequence finishes:

- preview closes;
- MODULE19 refresh:
  - one work visual appears;
  - no date room;
  - no free visual.

DATING choice:

```text
1/0/1
```

- slot01 opens;
- one clone + girl visible in room01.

---

# 52. Reassignment live refresh

Laboratory loaded:

```text
3 total
3 Work
0 Dating
```

Terminal:

```text
-1 Work
+1 Dating
```

Expected immediately:

```text
2 work visuals
slot01 opens
```

No scene reload.

---

# 53. Assignment decrease

Example:

```text
dating=6
```

rooms1..6 open.

Change dating to3.

Expected:

```text
rooms4..6 close
rooms1..3 stay
```

No "remembered individuals".

---

# 54. Slot order deterministic

Always fill:

```text
01 → 02 → ... →10
```

Never random room.

This makes visual growth readable.

---

# 55. No room gameplay capacity

Critical:

```text
10 physical date rooms
```

do NOT mean:

```text
max dating clones = 10
```

`clones_dating` may be any aggregate number.

Rates use full count.

Rooms are only first 10 visible representatives.

---

# 56. No work gameplay capacity

Same:

```text
3 visible workers
```

does not cap:

```text
clones_working
```

---

# 57. No free gameplay capacity

Same:

```text
2 visible free
```

does not cap free clones.

---

# 58. Room success/failure is decorative

`SILENT_SUCCESS` / `MUTUAL_CONFUSION`:

- do not alter Experience;
- do not alter relationship;
- do not alter Dates/min;
- do not fulfill backlog.

---

# 59. Visual girl reuse safety

Although appearances are reused, do NOT attach:

```text
GirlActor
GirlDefinition
girl_id
```

Only use appearance profiles / CharacterActor.

---

# 60. Presentation state resets on lab load

Leaving/re-entering laboratory:

- rooms reconstruct from counts;
- scene cycle can restart from0;
- work loop restarts;
- mass flow restarts.

No gameplay loss.

---

# 61. Controller reset

On GameState reset while lab loaded:

```text
all rooms close
all visuals clear
external label hides
work/free/mass visuals clear
```

---

# 62. Controller scene tree

Suggested:

```text
CloneVisualizationController
├── DatingRooms
│   ├── clone_date_slot_01
│   ...
│   └── clone_date_slot_10
├── WorkVisuals
│   ├── clone_work_visual_01
│   ├── clone_work_visual_02
│   └── clone_work_visual_03
├── FreeVisuals
│   ├── clone_free_wait_01
│   └── clone_free_wait_02
├── MassFlow
└── ProductionFeedback
```

---

# 63. Suggested scripts

```text
game/clone_visualization/
├── clone_visualization_controller.gd
├── dating_room_visual.gd
├── clone_visual_actor.gd
├── work_departure_visual.gd      # optional if controller remains readable
├── mass_clone_flow_visual.gd     # optional if controller remains readable
└── test/
```

Do not over-split small code.

---

# 64. No new GameState fields

MODULE19 should add exactly:

```text
ZERO
```

new persistent gameplay fields unless a blocker proves otherwise.

Visual slot activity is derived from aggregate counts.

---

# 65. No new autoload

Again:

```text
project.godot
```

should not gain `CloneVisualization`.

---

# 66. No ContentDB expansion required

No new:

- GirlDefinition;
- RivalDefinition;
- DatingEventDefinition.

Visual profiles can reuse existing CharacterAppearance resources.

---

# 67. No Story changes

MODULE19 does not:

- advance Stage;
- add StoryFeature;
- add story flags;
- unlock production_area;
- spawn President.

---

# 68. Stage 5 remains

Even after:

```text
1000 clones
```

Story:

```text
STAGE_5
```

MODULE20 owns progression beyond local factory scale.

---

# 69. Phone/Terminal unchanged functionally

MODULE19 does not redesign:

```text
Clone Terminal
Phone Clone section
```

They already show aggregate truth.

Optional visual note in terminal:

```text
Локально показано: min(dating,10) dating / min(work,3) work
```

NOT required.

---

# 70. Visual readability — date rooms

Each room label:

Inactive:

```text
СЛОТ 01 — СВОБОДНО
```

Active:

```text
СЛОТ 01
<current scene caption>
```

Do not show girl names.

---

# 71. Visual readability — external count

External label updates immediately on count changes.

Example:

```text
ВНЕШНИЕ ПЛОЩАДКИ
Работа: 47
Свидания: 90
Ожидают: 8
```

This is the key visual transition to abstraction.

---

# 72. Production progression example

State:

```text
total=1
work=1
dating=0
free=0
```

Visible:

```text
1 worker
```

30 sec later:

```text
total2
free1
```

Visible:

```text
1 worker
1 waiting free clone
```

Assign Dating:

```text
room01 opens
free disappears
```

---

# 73. Mid-scale example

```text
total=15
work=4
dating=9
free=2
```

Visible:

```text
date rooms01..09
3 worker visuals
2 free visuals

external:
work1
dating0
free0
```

---

# 74. Larger example

```text
total=150
work=60
dating=80
free=10
```

Visible:

```text
10 dating rooms only
3 worker visuals only
2 free visuals only
2 mass-flow actors maximum

external label:
work57
dating70
free8
```

No 150 NPCs.

---

# 75. Performance rule

Changing count:

```text
150 → 1000
```

must NOT scale active Node count linearly.

After all local visuals are saturated:

node/actor count stays roughly constant.

Only labels/frequency update.

---

# 76. No LOD system required

Because actor cap is low.

Do not build generic NPC LOD/culling system.

---

# 77. No object pooling required

27 actors is small.

Simple instantiate/free or keep-hidden is fine.

Prefer keep/reuse per fixed slot after first creation.

---

# 78. CharacterFactory use

Use existing:

```text
CharacterFactory
CharacterActor
```

No duplicate character construction system.

If CharacterFactory cannot create collisionless presentation actors directly:

- create normally;
- disable character collision layer/mask on visual subtree;
- do not modify global Character Framework API unless tiny reusable option is clearly warranted.

---

# 79. Scene authoring over runtime geometry

Preferred:

- room walls/glass/markers authored in `laboratory.tscn`;
- scripts own activation/actors.

Do not generate the entire laboratory layout procedurally at runtime.

This lets later art replacement stay practical.

---

# 80. Glass

Use simple transparent StandardMaterial3D.

No expensive special shader.

---

# 81. Lighting

Each room may have one small light or emissive panel.

Inactive room:

dim/off.

Active:

on.

Avoid 10 shadow-casting dynamic lights if expensive.

Preferred:

- emissive visual;
- at most non-shadow omni/spot where needed.

---

# 82. Date-room props

Use simple/reused:

- table;
- chairs;
- cup;
- plant;
- frame.

Do NOT build unique interior for each slot.

Small deterministic prop variation by slot index allowed.

---

# 83. Comedy repetition is intentional

The joke is:

```text
same man
room after room
doing slightly different date behavior
```

Do not over-randomize clone appearance.

---

# 84. Work comedy

Optional worker corridor label:

```text
НА РАБОТУ
БЕЗ СОБЕСЕДОВАНИЯ
```

Keep one/two lines.

---

# 85. Mass comedy

Optional external sign:

```text
ВНЕШНИЕ ПЛОЩАДКИ
ИНДИВИДУАЛЬНЫЙ УЧЁТ ПРЕКРАЩЁН
```

This directly communicates design transition.

---

# 86. No mass clone interactions

Player cannot stop/inspect external flow clone.

They vanish into corridor.

---

# 87. No work clone return trip

Visual workers only depart.

Do not animate round trips from Salary Mine.

Money is asynchronous.

---

# 88. No girl arrivals logistics

Room girls simply appear when slot active.

Do not simulate them walking from city.

No transport.

---

# 89. No dating duration coupling

Do not try to calculate:

```text
1 / dates_per_minute
```

for room scene duration.

At high rates this would become absurdly fast.

Presentation stays readable at fixed6 sec cycle.

---

# 90. No production interval coupling for mass flow

Mass flow frequency uses external-count thresholds, not real clone-production interval.

This is intentionally representational.

---

# 91. Test — zero counts

```text
0/0/0
```

Expected:

- all date rooms closed;
- no work actors;
- no free actors;
- mass flow hidden.

---

# 92. Test — first WORK clone

```text
1/1/0
```

Expected:

- one work visual;
- no FirstClone duplicate representative;
- no dating rooms;
- no free actor.

---

# 93. Test — first DATING clone

```text
1/0/1
```

Expected:

- slot01 active;
- exactly one room clone + one anonymous female;
- no FirstClone duplicate representative.

---

# 94. Test — free clone

```text
2/1/0
```

Expected:

- one worker;
- one free waiting clone.

---

# 95. Test — date count scaling

Check exact:

```text
dating0 →0 active
dating1 →1
dating5 →5
dating10 →10
dating11 →10 + external dating1
dating100 →10 + external dating90
```

---

# 96. Test — work count scaling

```text
work0 →0
work1 →1
work3 →3
work4 →3 + external work1
work100 →3 + external work97
```

---

# 97. Test — free count scaling

```text
free0 →0
free1 →1
free2 →2
free3 →2 + external free1
```

---

# 98. Test — external total

Derived exact sum.

No mutable external count.

---

# 99. Test — room close order

```text
dating7 → rooms1..7
dating3 → rooms1..3
```

rooms4..7 inactive.

---

# 100. Test — live terminal assignment

Lab loaded.

Change through real CloneIncremental assignment API.

Visuals refresh without reload.

---

# 101. Test — date scene cycle

Active room:

after controller ticks:

```text
CALM
OVER_EXPLAINING
SILENT_SUCCESS
MUTUAL_CONFUSION
...
```

offset by slot index.

No gameplay mutation.

---

# 102. Test — scene captions do not grant XP

Run visual room timer for 10 minutes with:

```text
CloneIncremental realtime disabled
```

Expected:

```text
Experience unchanged
Money unchanged
backlog unchanged
```

---

# 103. Test — work tween no Money

Run work departure visuals with incremental simulation disabled.

Money unchanged.

---

# 104. Test — mass flow no clone count mutation

Run mass visual loop.

Clone counts unchanged.

---

# 105. Test — clone-produced feedback

Emit real `CloneIncremental.clone_produced`.

Output feedback appears.

Visual count refresh matches GameState.

No local increment.

---

# 106. Test — lab reload

With aggregate state:

```text
20/5/12
```

leave lab and return.

Immediately reconstruct:

```text
10 date rooms
3 work visuals
2? free based on actual free=3
external work2/date2/free1
```

No dependence on previous scene instances.

---

# 107. Test — reset live

Reset while lab loaded.

All clone visualization disappears/closes.

---

# 108. Test — FirstClone sequence regression

Before first assignment:

- FirstClone preview works;
- VisualizationController shows no aggregate clones because total0;
- assignment modal works.

After commit:

- preview removed;
- MODULE19 visuals take over;
- exactly correct visible representation.

---

# 109. Test — FirstClone fallback

In existing MODULE17 test scene without visualization controller:

old one-representative behavior still passes.

---

# 110. Test — max actor count

At:

```text
10000 total
4000 work
5000 dating
1000 free
```

presentation CharacterActor count <=27.

No linear growth.

---

# 111. Test — no state mutation

Static/runtime check:

MODULE19 code never calls:

```text
GameState.set_clone_counts
GameState.add_money
GameState.add_experience
GameState.set_late_rates
DatingOverload.fulfill...
```

---

# 112. Test — no individual model

No arrays/dictionaries like:

```text
clone_records
clone_states
clone_assignments_by_id
```

Fixed visual slot arrays are fine.

---

# 113. Test — Story unchanged

Any physical visualization count:

```text
Stage remains STAGE5
```

No President.

---

# 114. Full F5 extension

Clean production route through MODULE18:

```text
→ first clone
→ automatic production
→ assign several Work/Dating
→ stay in / return to lab

Expected:
→ rooms open one by one
→ work clones visibly depart
→ free clones wait
→ terminal remains functional
→ counts keep growing
→ after local caps external corridor starts showing mass flow
→ actual Money/min / Dates/min continue unchanged by visualization
```

---

# 115. Visual acceptance walkthrough

For practical manual testing, temporary debug/test fixture may set:

```text
total = 15
work = 3
dating = 10
free = 2
```

Then:

```text
total = 30
work = 8
dating = 17
free = 5
```

Only in test/debug scene.

No production debug controls.

---

# 116. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Document exact visual caps:

```text
dating rooms = 10
work visuals = 3
free visuals = 2
mass-flow actors = 2
max presentation characters = 27
```

---

# 117. Technical decision — visualization only

Document:

```text
MODULE19 visual actors are reconstructed projections of aggregate GameState clone counts.
They never own economy, DatingCore, relationships or clone identity.
```

---

# 118. Technical decision — local-to-mass transition

Document:

```text
First 10 dating / first 3 work / first 2 free clones are represented locally.
Excess counts are represented by a constant-size mass-flow corridor + numeric counters.
Node count does not scale with aggregate clone count.
```

---

# 119. What MODULE19 DOES NOT implement

Do NOT implement:

- persistent clone IDs;
- clone save records;
- per-clone assignment;
- per-clone relationships;
- clone traits;
- clone quality;
- clone defects;
- clone death;
- clone inventory;
- pathfinding;
- crowd navigation;
- real city clone NPCs;
- real Salary Mine clone trips;
- real automatic DatingCore;
- date-room capacity limits;
- room unlock currency;
- room production bonuses;
- additional incremental upgrades;
- President;
- Stage6;
- production_area gameplay;
- global map;
- countries;
- airports;
- final expansion.

---

# 120. Definition of Done

MODULE19 complete only if:

- [ ] local `CloneVisualizationController` exists in laboratory;
- [ ] no new visualization autoload;
- [ ] no new persistent GameState fields;
- [ ] laboratory expanded/readable if necessary;
- [ ] exactly10 authored date rooms;
- [ ] date slot IDs01..10;
- [ ] slot N active iff dating>=N;
- [ ] slots open/close visually one-by-one;
- [ ] active room has clone + anonymous female;
- [ ] no GirlActor/GirlDefinition runtime identity for room females;
- [ ] clone visuals use protagonist clone appearance;
- [ ] four deterministic room presentation states;
- [ ] one6s controller scene timer;
- [ ] room scenes never affect gameplay;
- [ ] max3 local work clone visuals;
- [ ] work clones visibly depart via Tween;
- [ ] work departure never adds Money;
- [ ] max2 local free clone visuals;
- [ ] production feedback on clone-produced;
- [ ] external counts derived exact from overflow;
- [ ] external numeric label exists;
- [ ] max2 mass-flow clone visuals;
- [ ] mass flow frequency scales visually only;
- [ ] max presentation CharacterActors <=27;
- [ ] no gameplay collision/interactions on visual actors;
- [ ] FirstClone representative suppressed when MODULE19 controller owns lab;
- [ ] FirstClone fallback remains for old tests/no-controller scenes;
- [ ] first clone reveal itself unchanged;
- [ ] live assignment refresh works without reload;
- [ ] lab reload reconstructs visuals from aggregate state;
- [ ] reset clears visuals;
- [ ] no clone state/economy mutation from MODULE19;
- [ ] no individual clone records;
- [ ] node count stays constant at huge aggregate totals;
- [ ] Story remains Stage5;
- [ ] President still absent;
- [ ] full F5 shows local→mass physical transition;
- [ ] MODULE02–18 regressions PASS;
- [ ] MODULE20 not implemented ahead.

---

# 121. Recommended Cursor order

```text
1. Audit laboratory geometry, FirstClone representative, CharacterFactory.
2. Expand/re-layout laboratory blockout.
3. Author 10 fixed DatingRoomVisual nodes + markers.
4. Implement CloneVisualActor and anonymous female presentation.
5. Implement event-driven CloneVisualizationController.
6. Add 4-state deterministic dating-room cycle.
7. Add 3 work visuals + Tween exit loop.
8. Add 2 free waiting visuals.
9. Add external count/mass-flow corridor with max2 actors.
10. Suppress FirstClone representative only when controller owns lab.
11. Verify FirstClone fallback tests.
12. Stress test huge aggregate counts.
13. Full F5 visual walkthrough.
14. Regressions/docs.
```

---

# 122. Cursor final report

## Architecture

Explain:

```text
CloneVisualizationController
DatingRoomVisual
CloneVisualActor
FirstClone fallback integration
```

Confirm:

```text
no autoload
no persistent clone records
```

## Local caps

Confirm exact:

```text
10 dating rooms
3 work visuals
2 free visuals
2 mass-flow actors
<=27 CharacterActors
```

## Dating rooms

Show:

```text
dating count → opened room count
4 visual scenes
6s cycle
```

Confirm no DatingCore/economy effects.

## Work/free

Explain work departure and free waiting representation.

## Mass transition

Show overflow formulas and external label/flow.

## FirstClone

Confirm no duplicate representative in real lab and old fallback remains in test scenes.

## Performance

Demonstrate that `10000` aggregate clones do not create linear NPCs.

## Boundary

Confirm:

```text
no President
no Stage advance
no Module20 world expansion
```

## F5 validation

Describe real local→mass visual transition.

## Regressions

All prior suites.

## Commit

SHA.

Then STOP. Do not begin MODULE20.
