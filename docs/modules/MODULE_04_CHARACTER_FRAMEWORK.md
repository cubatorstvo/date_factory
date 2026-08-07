# MODULE 04 — CHARACTER FRAMEWORK

**Проект:** Date Factory  
**Модуль:** 04 — Character Framework  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** создать единый технический слой 3D-персонажей, их внешнего профиля и базовой анимационной презентации без реализации поведения девушек, самцов, свиданий или AI  
**Продуктовый источник истины:** `docs/MASTER_GDD.md` и `docs/gdd/*`  
**Технический план:** `docs/TECH_PLAN.md`  
**Предыдущий модуль:** MODULE 03 — Content Data Layer

---

# 0. PRE-FLIGHT: исправить MODULE 03

Перед Character Framework закрыть одно несоответствие MODULE 03.

Сейчас существуют:

```text
GameTypes.GameStage
GameTypes.PlayerCharacteristic
```

и одновременно собственные:

```text
GameState.Stage
GameState.Characteristic
```

Это запрещённое дублирование canonical enums.

## Требование

После исправления единственным canonical источником должны быть:

```text
GameTypes.GameStage
GameTypes.PlayerCharacteristic
```

`GameState` должен использовать их напрямую.

Не создавать alias-enum с повторным перечислением значений.

Допустимы короткие type aliases/constants только если Godot действительно поддерживает это без создания второго enum и это улучшает читаемость.

После refactor:

- MODULE 02 self-tests проходят;
- MODULE 03 self-tests проходят;
- stage numeric values остаются `0..7`;
- characteristic numeric values остаются прежними;
- внешний API GameState сохраняет смысл;
- новые модули используют `GameTypes.*`.

Эту правку сделать ДО Character Framework.

---

# 1. Цель MODULE 04

Создать reusable framework, через который будущие системы смогут:

- поставить мужчину или женщину в сцену;
- назначить ему стабильную внешность через `appearance_profile_id`;
- получить базовую collision/body presentation;
- запустить понятную базовую анимацию по semantic alias;
- узнать, существует ли нужная анимация;
- временно скрыть/показать персонажа;
- заменить визуальную модель без изменения gameplay-кода;
- в будущем использовать того же мужского visual foundation для:
  - героя в постановочных сценах;
  - обычных самцов;
  - сюжетных самцов;
  - клонов;
- использовать общий женский visual foundation для девушек.

MODULE 04 НЕ реализует характер, поведение, знакомства, состязания или свидания.

---

# 2. Главный продуктовый принцип персонажей

Игра сознательно не требует уникального production-ready тела для каждого NPC.

Базовая стратегия:

```text
одна мужская визуальная база
+
одна женская визуальная база
+
вариации внешнего профиля
```

Персонажей различают прежде всего:

- одежда/вариант модели;
- аксессуары;
- цветовые варианты;
- причёска, если asset это позволяет;
- масштаб отдельных presentation-узлов, если безопасно;
- анимационная манера;
- постановка;
- context.

MODULE 04 должен поддержать эту стратегию технически.

Но сейчас художественный стиль ещё не финализирован.

Поэтому framework обязан быть **replaceable-art friendly**.

Нельзя жёстко привязывать gameplay-код к конкретному donor mesh.

---

# 3. Текущий визуальный режим разработки

На данном этапе:

> используем уже имеющиеся ассеты, чтобы быстро собирать игру.

MODULE 04 НЕ должен:

- переделывать художественный стиль;
- создавать toon shader;
- делать финальные лица;
- генерировать новые модели;
- строить сложный character creator;
- доводить donor-модели до AAA-качества.

Цель — получить функциональный и визуально понятный character layer.

---

# 4. Обязательный donor audit

Перед реализацией Cursor должен изучить donor:

```text
../date_factory_legacy
```

Особенно:

```text
assets/characters/hero_base/
assets/characters/women_modular/
assets/animation/universal_library/
scenes/art/characters/character_anim_controller.gd
```

Известные кандидаты donor:

```text
assets/characters/hero_base/prefabs/Hero.tscn
assets/characters/hero_base/prefabs/Clone.tscn
assets/characters/hero_base/prefabs/DateGirl_UAL.tscn

assets/characters/women_modular/prefabs/Girl_Casual.tscn
assets/characters/women_modular/prefabs/Girl_Formal.tscn
assets/characters/women_modular/prefabs/Girl_Worker.tscn
assets/characters/women_modular/prefabs/Manager_Suit.tscn
```

Известная мужская donor-модель:

```text
Superhero_Male_FullBody.gltf
```

Также существует donor female full-body / modular women content.

---

# 5. Donor decision procedure

Cursor должен для каждого кандидата определить:

```text
COPY
ADAPT
REFERENCE ONLY
REJECT
```

Проверить:

- визуальное качество;
- skeleton;
- animation compatibility;
- import dependencies;
- material dependencies;
- license file;
- runtime scripts;
- legacy coupling.

## Главное правило

Не копировать старые prefab сцены целиком, если они тянут:

- старый controller;
- старые layer numbers;
- old gameplay scripts;
- legacy metadata;
- ненужный runtime behaviour.

Предпочтительно:

1. скопировать source visual assets и реально необходимые animation resources;
2. собрать новые v2 wrapper scenes;
3. использовать новый Character Framework.

---

# 6. License preservation

Если donor asset имеет:

```text
LICENSE.txt
```

и лицензия требует сохранения attribution/license текста:

- скопировать соответствующий license вместе с asset;
- сохранить понятное происхождение;
- не удалять license metadata.

MODULE 04 должен перечислить использованные character/animation asset licenses в:

```text
docs/THIRD_PARTY_ASSETS.md
```

Если файл уже существует — обновить.

Если donor asset собственный и отдельная лицензия не требуется — зафиксировать это кратко.

---

# 7. Не копировать donor animation architecture автоматически

В donor существует:

```text
character_anim_controller.gd
```

который вручную sample-ит bone tracks каждый `_process()`.

Нельзя автоматически считать этот способ правильным для v2.

Cursor обязан сравнить:

1. стандартный `AnimationPlayer`;
2. `AnimationTree`, если он действительно нужен;
3. donor manual pose sampler;
4. другой Godot-native способ.

Предпочтение:

> использовать стандартные средства Godot, если они корректно воспроизводят текущие imported/retargeted animations.

Manual per-frame bone sampling допустим только если реально необходим из-за структуры donor assets и стандартное воспроизведение не работает корректно.

Такое решение обязательно записать в `TECHNICAL_DECISIONS.md`.

---

# 8. Canonical character directories

Создать/использовать:

```text
res://characters/
├── framework/
├── appearances/
├── male/
├── female/
└── test/
```

Assets:

```text
res://assets/characters/
res://assets/animation/
```

Разделение:

```text
characters/ = scenes/scripts/resources framework
assets/     = imported visual/audio source assets
```

Не хранить gameplay rules внутри imported asset folders.

---

# 9. Character body types

Добавить canonical enum:

```text
CharacterBodyType
```

Ровно:

```text
MALE
FEMALE
```

Это visual/body classification, а не gameplay characteristic.

Не добавлять:

- HERO;
- GIRL;
- RIVAL;
- CLONE;
- SCIENTIST;
- PRESIDENT.

Роль персонажа и тело — разные понятия.

Герой, соперник и клон могут использовать `MALE`.

Все девушки используют `FEMALE`.

---

# 10. AppearanceProfileDefinition

MODULE 03 уже оставил:

```text
appearance_profile_id
```

как opaque reference.

Теперь создать typed static resource:

```text
AppearanceProfileDefinition
```

Минимальные поля:

```text
id: StringName
body_type: CharacterBodyType

visual_scene: PackedScene

visual_scale: float = 1.0
vertical_offset: float = 0.0

animation_profile_id: StringName
```

Допустимы только дополнительные поля, которые реально нужны выбранным donor assets.

Не создавать generic bag типа:

```text
Dictionary appearance_options
```

---

# 11. Appearance profile IDs

Canonical prefix:

```text
appearance_*
```

Начальный минимальный production set:

```text
appearance_male_base
appearance_female_base
```

Если donor технически вынуждает использовать отдельные готовые женские варианты уже сейчас, разрешено добавить временные profiles:

```text
appearance_female_casual
appearance_female_formal
appearance_female_worker
appearance_female_manager
```

Но они считаются **temporary production art profiles**, а не новой продуктовой системой.

Не создавать десятки profiles ради количества.

---

# 12. Base male visual

В текущей версии предпочтительно использовать donor male base, если после audit он исправно импортируется:

```text
Superhero_Male_FullBody.gltf
```

или визуально эквивалентный уже существующий male asset из donor.

Собрать новую v2 visual scene.

Canonical:

```text
res://characters/male/male_base_visual.tscn
```

Точная внутренняя структура — техническое решение Cursor.

Не использовать старый `Hero.tscn` как runtime dependency.

Если из него нужен mesh/library — физически скопировать нужные dependencies.

---

# 13. Base female visual

Выбрать лучший существующий female asset из donor после визуально-технического audit.

Приоритет:

1. asset, который стабильно анимируется;
2. читаемо выглядит в FPS;
3. имеет минимум проблем с материалами;
4. легко заменяется;
5. не требует legacy systems.

Canonical:

```text
res://characters/female/female_base_visual.tscn
```

Если `Girl_Casual` является лучшим временным кандидатом — использовать его visual source как female base.

Если `Superhero_Female_FullBody.gltf` лучше технически — использовать его.

Cursor принимает **техническое** решение после сравнения и фиксирует выбор.

Не нужно спрашивать пользователя, какой из двух временных donor-мешей красивее, если один явно технически лучше для текущего placeholder этапа.

---

# 14. CharacterActor

Создать reusable scene:

```text
res://characters/framework/character_actor.tscn
```

Canonical class/scene semantic:

```text
CharacterActor
```

Это объект присутствия humanoid NPC/actor в мире.

Он отвечает за:

- transform;
- collision;
- visual instance;
- appearance application;
- animation presentation;
- visibility;
- базовые presentation anchors.

Он НЕ отвечает за:

- AI;
- navigation;
- dialogue;
- relationship;
- rival logic;
- dating;
- quests;
- schedule.

---

# 15. CharacterActor root

Предпочтительный root:

```text
CharacterBody3D
```

потому что будущим обычным NPC может понадобиться простое движение.

Но Cursor должен проверить, не создаёт ли это лишнюю физическую сложность для статичных NPC.

Допустим другой Godot-native root, если он лучше поддерживает:

- статичное размещение сейчас;
- простое движение позже;
- collision.

Техническое решение документировать, если отличается от `CharacterBody3D`.

---

# 16. CharacterActor conceptual structure

Ожидаемая семантика:

```text
CharacterActor
├── Collision
├── VisualRoot
│   └── <appearance visual instance>
├── AnimationController
├── InteractionAnchor
├── LookAnchor
└── GroundAnchor
```

Это conceptual contract, не обязательные точные node types.

## Anchors

`InteractionAnchor`:

- точка примерно в области торса;
- будущий interaction ray может целиться в неё/коллизию.

`LookAnchor`:

- точка примерно в области лица/головы;
- будущие постановки могут направлять камеру/взгляд туда.

`GroundAnchor`:

- root/reference уровня ног;
- помогает корректно размещать разные visuals по полу.

Не создавать skeleton-specific gameplay anchors без необходимости.

---

# 17. Character collision

NPC collision должна быть простой.

Ориентиры:

Male:

```text
height ~1.75–1.85 m
radius ~0.30–0.35 m
```

Female:

```text
height ~1.65–1.80 m
radius ~0.28–0.33 m
```

Но collider принадлежит CharacterActor/body profile, а не imported mesh.

Главное:

- игрок не проходит сквозь NPC;
- collider не мешает interaction ray;
- model feet стоят на полу;
- разные donor scale не вынуждают менять world scale.

---

# 18. World scale

Canonical world unit:

```text
1 Godot unit = 1 meter
```

Donor visual может требовать local scale correction.

Коррекция должна происходить внутри appearance/profile/VisualRoot.

Нельзя масштабировать сам world или Player ради imported character asset.

---

# 19. Character identity

CharacterActor должен иметь:

```text
content_id: StringName
```

или эквивалентное ясное поле.

Смысл:

- stable ID конкретного character content;
- может быть `girl_*`, `rival_*`, позднее clone/system-generated identity.

Но CharacterActor не должен по prefix самостоятельно решать поведение.

Запрещено:

```text
if content_id begins_with("girl_"):
    ...
```

в framework.

---

# 20. Appearance ownership

CharacterActor не хранит параметры девушки/самца.

Он получает:

```text
appearance_profile_id
```

и применяет profile.

Источник profile — static content.

Future feature wrapper решает, какой profile использовать:

```text
GirlDefinition.appearance_profile_id
RivalDefinition.appearance_profile_id
```

CharacterActor не загружает GirlDefinition сам без причины.

---

# 21. ContentDB extension

Предпочтительный вариант:

добавить `AppearanceProfileDefinition` в существующий static content layer:

```text
ContentCatalog.appearance_profiles
ContentDB.get_appearance_profile(id)
```

Причина:

- appearance_profile_id уже является static content reference;
- не нужен новый global manager.

Добавить validation:

- ID `appearance_*`;
- unique;
- body_type valid;
- `visual_scene != null`;
- `visual_scale > 0`;
- animation profile существует, если указан.

Не создавать отдельный:

```text
AppearanceManager autoload
```

---

# 22. AnimationProfileDefinition

Создать простой static resource только если реальные male/female assets используют разные animation libraries/config.

Минимально:

```text
id: StringName
library: AnimationLibrary
```

Допустимо также хранить small alias availability metadata, если это действительно нужно.

Canonical IDs могут быть:

```text
animation_male_base
animation_female_base
```

Не создавать animation graph data DSL.

---

# 23. Canonical animation aliases

Character Framework должен работать с semantic aliases, а не с исходными длинными названиями imported animations.

Canonical baseline:

```text
idle
walk
run

approach
turn

sit_enter
sit_idle
seated_gesture
sit_exit

gesture
react
```

Дополнительно допустим alias:

```text
stand
```

только если donor library реально использует его отдельно от `sit_exit`.

---

# 24. Meaning of aliases

## `idle`

Спокойное стояние.

## `walk`

Обычная ходьба.

## `run`

Быстрое движение. Может понадобиться для комедийного ухода/побега позже, хотя Player sprint не существует.

## `approach`

Короткая анимация подхода/намеренного приближения, если asset имеет.

## `turn`

Поворот/перестановка корпуса.

## `sit_enter`

Переход из стояния в сидение.

## `sit_idle`

Сидячее idle.

## `seated_gesture`

Жест во время сидения.

## `sit_exit`

Подъём.

## `gesture`

Нейтральный стоячий жест.

## `react`

Нейтральная реакция.

---

# 25. Не создавать эмоциональную taxonomy сейчас

MODULE 04 НЕ создаёт:

```text
HAPPY
ANGRY
SAD
FLIRTY
CRY
SIGMA
EMBARRASSED
```

как обязательные character animation states.

Почему:

- конкретные реакции будут определяться Dating/Rival/Presentation modules;
- текущие donor assets могут не иметь их.

Future modules могут добавить semantic aliases, когда реально понадобится конкретная сцена.

---

# 26. CharacterAnimationController

Создать маленький presentation controller.

Он должен позволять semantic API:

```text
has_animation(alias) -> bool
play_loop(alias) -> bool
play_once(alias) -> bool
stop_or_return_to_idle()
get_current_animation_alias()
```

Можно выбрать более Godot-идиоматичные names.

Нужен signal semantic уровня:

```text
animation_finished(alias)
```

для one-shot animations.

---

# 27. Animation controller НЕ управляет character logic

Запрещено:

```text
if react finished:
    girl_relationship += 1

if approach finished:
    start_rival_minigame()
```

Controller только показывает animation.

Gameplay module сам подписывается/await-ит presentation completion.

---

# 28. Locomotion animation

Character Framework должен уметь позже переключать:

```text
idle ↔ walk ↔ run
```

по команде/скорости.

Но MODULE 04 НЕ создаёт NPC movement AI.

Для test actor допустимо вручную задавать movement presentation state.

Если Cursor создаёт метод:

```text
set_locomotion_speed(speed)
```

он должен только выбрать animation state.

Он не двигает CharacterActor.

---

# 29. Root motion

Не использовать root motion как обязательную основу character movement.

World movement должен позже контролироваться gameplay/navigation logic.

Animations должны быть:

- in-place;
- либо технически нейтрализованы/адаптированы.

Если конкретный donor animation содержит root translation, Cursor должен решить лучший технический способ убрать конфликт.

Не позволять animation незаметно перемещать gameplay collision body.

---

# 30. Facing API

Framework должен предоставить простой способ развернуть visual/actor в сторону world target.

Semantic future need:

```text
face_point(world_position)
```

или equivalent.

MODULE 04 может реализовать:

- мгновенный horizontal facing;
- простой optional timed turn только если это легко и нужно для test.

Не строить steering system.

Не вращать персонажа по pitch/roll.

---

# 31. Look-at

Не создавать полноценную head/eye look-at IK system.

Если donor rig легко поддерживает native SkeletonModifier/LookAt и это почти бесплатная интеграция — всё равно не добавлять в MODULE 04 без gameplay need.

Для будущих диалогов достаточно `LookAnchor`.

---

# 32. Character visibility

Нужен простой API:

```text
set_character_visible(bool)
```

Он должен:

- скрывать visual;
- при необходимости отключать collision;
- не delete/recreate static resources;
- не менять GameState.

Future story/world system сможет использовать его для staged appearance.

---

# 33. Spawn/despawn

MODULE 04 НЕ создаёт global spawn manager.

Future world code может:

```text
instantiate CharacterActor
configure
add_child
```

или использовать маленькую static factory, если это реально уменьшает boilerplate.

Не создавать object pool.

---

# 34. CharacterFactory

Создавать отдельный `CharacterFactory` только если после implementation видно реальное повторение:

```text
instantiate actor
apply appearance
assign id
validate
```

Если полезно, допустима маленькая utility/factory без Autoload.

Запрещено делать:

```text
CharacterManager
NPCManager
SpawnService
```

глобальными системами.

---

# 35. Girl/rival wrappers

MODULE 04 НЕ создаёт полноценные `GirlActor` / `RivalActor` gameplay classes.

Допустимы тонкие test wrappers только для демонстрации разных appearance profiles.

Production gameplay wrappers появятся:

- Girl Discovery — MODULE 08;
- Rival Encounter — MODULE 06.

CharacterActor должен быть достаточно нейтральным, чтобы оба использовали его композиционно.

---

# 36. Player relation

Текущий FPS Player остаётся invisible first-person controller.

MODULE 04 НЕ добавляет к нему:

- тело;
- руки;
- ноги;
- shadow body.

Male base visual должен быть пригоден позже для:

- hero in mirrors/cutscenes;
- clones;
- third-person staged shots,

но сейчас не инстанцируется внутрь FPS Player.

---

# 37. Clone relation

Не создавать отдельную clone model architecture.

Поздний Clone:

```text
тот же male visual foundation
```

с возможным appearance/profile override.

MODULE 17–19 определят clone behaviour.

MODULE 04 только не должен технически закрывать переиспользование male actor.

---

# 38. Appearance variation scope

Framework должен позволять profile-level variation, но не обязан реализовывать все возможные виды.

Минимум:

```text
different visual_scene
different visual_scale
different vertical_offset
different animation_profile
```

Если donor asset легко позволяет безопасную material tint variation — можно добавить:

```text
material overrides
```

только если это не требует большого framework.

Не добавлять сейчас:

- runtime mesh surgery;
- bone scaling system;
- procedural body generation;
- morph targets UI;
- face generator;
- hair slot system;
- equipment inventory.

---

# 39. Accessories

Если текущие donor characters имеют отдельные accessory nodes/meshes, MODULE 04 может предусмотреть простые named attachment anchors.

Например:

```text
HeadAccessory
FaceAccessory
NeckAccessory
HandAccessory
BackAccessory
```

НО только если это реально соответствует assets.

Не создавать универсальную socket taxonomy «на будущее» без доступных props.

---

# 40. Appearance profile resolution

CharacterActor должен обрабатывать invalid profile предсказуемо.

Если profile ID отсутствует:

- debug error;
- actor остаётся без visual либо использует явно заданный test fallback;
- нельзя случайно взять random appearance.

Production code не должен silently заменять missing girl profile на `appearance_female_base` и скрывать content error.

---

# 41. Definition integration

MODULE 03 types:

```text
GirlDefinition.appearance_profile_id
RivalDefinition.appearance_profile_id
```

остаются unchanged по смыслу.

MODULE 04 validation может добавить cross-reference:

- если production GirlDefinition появится и appearance_profile_id не пуст — profile должен существовать;
- аналогично RivalDefinition.

Поскольку production girls/rivals сейчас пусты, MODULE 04 не создаёт fake content ради validation.

---

# 42. Display names

CharacterActor может иметь runtime display name для debug/tooling.

Но source of truth будущего production display name:

```text
GirlDefinition.display_name
RivalDefinition.display_name
```

Не хранить permanent character names внутри mesh prefab.

Donor `label_text = "Hero"` и подобное не является product data.

---

# 43. Collision layers

Использовать уже принятую collision-layer схему проекта.

CharacterActor должен находиться на понятном character/world collision layer.

Interaction ray должен иметь возможность попадать в NPC.

Не резервировать десятки layers.

Если требуется новый named layer:

```text
characters
```

добавить только после анализа текущих layers и задокументировать.

Не ломать Player interaction с world geometry.

---

# 44. Character interaction boundary

MODULE 04 НЕ реализует:

```text
[E] Поговорить
```

как production behaviour.

CharacterActor может иметь collider/interaction anchor, но actual `Interactable` adapter принадлежит будущей Girl/Rival системе.

Test scene может использовать отдельный test interactable, чтобы доказать, что ray попадает в character.

---

# 45. Materials

Скопированные character materials должны:

- работать после clean import;
- не ссылаться на donor;
- не иметь missing textures;
- не требовать legacy world shader.

Не делать художественный rework.

Если импортированный material явно сломан или слишком дорог, Cursor может сделать простой локальный replacement material.

---

# 46. Texture/import size

Не заниматься глубоким optimization pass.

Но если donor character textures имеют очевидно чрезмерный размер для placeholder asset, Cursor может выбрать разумные Godot import settings без изменения source asset.

Не конвертировать вручную весь art pipeline.

---

# 47. Character test scene

Создать:

```text
res://characters/test/character_framework_test.tscn
```

Сцена должна содержать:

- один male CharacterActor;
- один female CharacterActor;
- floor;
- простой свет;
- camera/test observer;
- debug controls или автоматическую sequence анимаций.

Не строить город/кафе.

---

# 48. Test scene visual goals

При запуске должно быть видно:

- оба персонажа имеют нормальный масштаб;
- ноги стоят на полу;
- материалы/текстуры работают;
- collision соответствует телу;
- animation aliases действительно проигрываются.

---

# 49. Animation smoke sequence

Test runner должен проверить минимум:

Male:

```text
idle
walk
gesture
react
```

Female:

```text
idle
walk
gesture
react
```

Если доступны:

```text
sit_enter
sit_idle
seated_gesture
sit_exit
```

тоже проверить.

Если конкретного optional alias нет в donor female/male library:

- это не обязательно blocker;
- `has_animation()` должен честно вернуть false;
- report должен перечислить missing optional aliases.

---

# 50. Baseline mandatory aliases

Для выбранных текущих male/female assets обязательны:

```text
idle
walk
gesture
react
```

Если donor asset не может обеспечить эти 4 даже после разумной адаптации — выбрать другой donor candidate.

`run`, seated aliases и approach — desirable, но не blocker MODULE 04.

---

# 51. Animation transitions

Не требуется сложное blend tree.

Но смена loop-анимаций не должна очевидно ломать pose.

Cursor может использовать:

- AnimationPlayer blend;
- простой crossfade;
- AnimationTree,

в зависимости от best practice и реальных assets.

Если простой AnimationPlayer достаточен — не добавлять AnimationTree ради архитектуры.

---

# 52. Animation speed

Default animation speed:

```text
1.0
```

Не создавать personality-specific animation speed system.

Future staged scene может локально менять speed.

---

# 53. Animation fallback

При запросе отсутствующего alias:

- вернуть `false`;
- сделать понятный debug warning/error;
- не crash;
- не silently играть случайную другую animation.

Можно оставить текущую animation или перейти в `idle` согласно простому documented choice.

---

# 54. Seated state

Если seated animations используются, controller может хранить presentation flag:

```text
is_seated
```

только чтобы корректно выбрать fallback loop после gesture/react.

Это НЕ gameplay state.

Нельзя использовать его для:

- занятости стула;
- date state;
- navigation.

---

# 55. No facial animation system

MODULE 04 не создаёт:

- lip sync;
- phonemes;
- facial blendshape controller;
- emotion face state machine.

Если donor model имеет facial animations — не нужно выбрасывать, но framework не обязан их абстрагировать сейчас.

---

# 56. No voice/audio

Character Framework не проигрывает реплики или голоса.

Audio/Presentation позже.

---

# 57. No navigation

Не добавлять:

- NavigationAgent3D;
- pathfinding;
- wander;
- patrol;
- follow player.

Фиксированные ситуации девушек прямо по GDD не требуют полноценной ежедневной жизни NPC.

World/Discovery modules позже решат, кому реально нужно перемещение.

---

# 58. No physics ragdoll

Не создавать ragdoll.

Пощёчины позже используют animation/feedback, а не full-body physical simulation как обязательное условие.

---

# 59. No AI state machine

Не создавать states:

```text
IDLE
WALKING
TALKING
DATING
FIGHTING
CRYING
FLEEING
```

как AI architecture.

Animation alias — presentation command, а не AI state.

---

# 60. No gameplay stats on actor

Не хранить внутри CharacterActor:

```text
muscle
appearance
capital
aura
authority
experience
relationship
```

Static rival stats — RivalDefinition.

Player stats — GameState.

CharacterActor — presentation/world body.

---

# 61. No unique girl logic

Нельзя создавать script:

```text
neighbor.gd
actress.gd
scientist.gd
```

MODULE 04 не реализует персонажный контент.

---

# 62. No random appearance generator

Не создавать procedural randomization обычных NPC.

Обычные девушки будут handmade/fixed situations.

Самцы тоже используют definitions.

Повторяемость внешности допустима и является частью production simplification.

---

# 63. ContentDB read-only principle

Расширение ContentDB appearance profiles не должно превращать его в runtime editor.

Нельзя:

```text
ContentDB.set_character_color(...)
ContentDB.change_profile(...)
```

Profiles static.

---

# 64. Appearance profile catalog

Production catalog после MODULE 04 должен содержать минимум:

```text
appearance_male_base
appearance_female_base
```

Если добавлены временные female variants — перечислить.

Не требуется создавать profiles для сюжетных персонажей.

---

# 65. Test profile catalog

Создать test profiles отдельно только если реально нужны для invalid-case tests.

Не включать их в production content catalog.

---

# 66. Validation — profiles

Проверить:

- ID non-empty;
- `appearance_*`;
- unique;
- valid body type;
- non-null visual scene;
- scale > 0;
- animation profile reference valid;
- imported scene can instantiate.

---

# 67. Validation — visual integrity

Для production appearance profiles в test:

- scene инстанцируется;
- нет missing dependency;
- нет donor path;
- нет external filesystem path;
- нет legacy gameplay script.

---

# 68. Validation — licenses

Каждый реально скопированный third-party character/animation pack:

- имеет сохранённый license/attribution;
- указан в `THIRD_PARTY_ASSETS.md`.

---

# 69. Validation — donor independence

Поиск по новым character resources/scripts:

```text
../date_factory_legacy
```

ожидаемо:

```text
0 runtime references
```

Также не должно быть symlink/junction.

---

# 70. Validation — old character scripts

Новые production character scenes не должны ссылаться на:

```text
res://scenes/art/characters/character_anim_controller.gd
```

если этот legacy script не был осознанно скопирован и адаптирован в новый path.

Если адаптирован:

- новый файл находится внутри `characters/framework/`;
- legacy path отсутствует;
- old gameplay dependencies отсутствуют.

---

# 71. Test — male instantiation

Instantiate:

```text
appearance_male_base
```

Проверить:

- visual exists;
- scale sane;
- floor alignment;
- collision sane;
- idle works.

---

# 72. Test — female instantiation

То же для:

```text
appearance_female_base
```

---

# 73. Test — replace appearance

На одном test CharacterActor:

1. применить male base;
2. удалить/заменить presentation;
3. применить female base либо другой compatible test profile.

Главная проверка:

- framework не хранит hardcoded donor child paths;
- old visual корректно освобождён;
- новый visual работает.

В production body_type mismatch может быть отклонён — этот test можно делать на generic test actor.

Не требуется gameplay смена пола во время игры; это технический replaceability test.

---

# 74. Test — missing appearance

Invalid ID:

```text
appearance_missing
```

Ожидается:

- apply fails;
- понятное сообщение;
- actor state остаётся валидным.

---

# 75. Test — animation aliases

Для mandatory aliases:

```text
idle
walk
gesture
react
```

`has_animation == true`.

`play_*` работает.

---

# 76. Test — missing animation

Запрос:

```text
nonexistent_alias
```

Ожидается:

```text
false
```

без crash.

---

# 77. Test — one shot completion

`gesture` или `react`:

- запускается;
- finish signal приходит один раз;
- controller возвращается в ожидаемый loop.

---

# 78. Test — visibility

Hide:

- visual disappears;
- collision behaviour соответствует documented choice.

Show:

- character корректно возвращается.

---

# 79. Test — ContentDB regression

После расширения catalog:

- MODULE 03 validation проходит;
- existing 4/4/32/4/9/8 canonical content remains valid;
- appearance profiles индексируются отдельно;
- existing lookups не ломаются.

---

# 80. Test — GameState regression

После enum pre-flight:

- MODULE 02 self-test ALL PASS;
- GameState использует GameTypes;
- нет `enum Stage` и `enum Characteristic` внутри GameState.

---

# 81. Test — FPS interaction regression

Запустить существующий FPS test.

Проверить:

- movement;
- interaction;
- pause;
- raycast.

Character framework не должен ломать collision masks.

---

# 82. Test — character ray hit

В test world поставить CharacterActor перед Player.

Interaction ray должен физически попадать в character collider/target layer.

Не требуется production prompt.

Можно использовать test adapter.

---

# 83. Performance

Несколько десятков inactive humanoid actors не должны создавать тяжёлую постоянную логику.

CharacterActor:

- не должен делать дорогой `_process()` без необходимости;
- не должен сканировать SceneTree;
- не должен каждый frame искать skeleton;
- должен cache references.

Если loop animation стандартно проигрывается AnimationPlayer — не писать manual frame work.

---

# 84. Replaceability test

Ключевой архитектурный acceptance:

Если через неделю пользователь решит заменить все character models, должно быть достаточно в основном:

- импортировать новые visuals;
- создать/обновить AppearanceProfile;
- адаптировать animation profile.

Не должно требоваться переписывать:

- GirlDefinition;
- RivalDefinition;
- Dating;
- Rival system;
- GameState.

---

# 85. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/THIRD_PARTY_ASSETS.md
```

Если `THIRD_PARTY_ASSETS.md` отсутствует — создать.

Записать:

- выбранный male donor source;
- выбранный female donor source;
- animation source;
- что было copied/adapted/rejected;
- лицензии;
- animation approach;
- appearance profile architecture.

---

# 86. Что MODULE 04 НЕ реализует

Категорически не реализовывать:

- Progression/Perks effects;
- Rival encounters;
- Rival AI;
- minigames;
- Girl Discovery;
- phone;
- dates;
- relationship mechanics;
- Story;
- world schedules;
- character daily life;
- navigation;
- dialogue trees;
- facial animation;
- lip sync;
- inventory/equipment;
- character creator;
- procedural random NPC generation;
- clone logic;
- crowd simulation.

---

# 87. Definition of Done

MODULE 04 завершён только если:

- [ ] GameState enum duplication исправлено;
- [ ] MODULE 02 tests проходят;
- [ ] MODULE 03 tests проходят;
- [ ] donor character assets проанализированы;
- [ ] donor animation system проанализирована;
- [ ] выбран и задокументирован male base;
- [ ] выбран и задокументирован female base;
- [ ] лицензии сохранены;
- [ ] существует CharacterBodyType MALE/FEMALE;
- [ ] существует AppearanceProfileDefinition;
- [ ] ContentDB умеет lookup appearance profile;
- [ ] есть production `appearance_male_base`;
- [ ] есть production `appearance_female_base`;
- [ ] существует reusable CharacterActor;
- [ ] visual отделён от gameplay body;
- [ ] character scale соответствует метрам мира;
- [ ] collision работает;
- [ ] LookAnchor/InteractionAnchor или эквивалент существуют;
- [ ] существует простой CharacterAnimationController;
- [ ] обязательные aliases `idle/walk/gesture/react` работают для обеих баз;
- [ ] отсутствующая animation обрабатывается безопасно;
- [ ] one-shot completion работает;
- [ ] framework не реализует AI;
- [ ] framework не содержит gameplay stats;
- [ ] framework не знает Dating/Rival logic;
- [ ] test scene существует;
- [ ] ContentDB regression проходит;
- [ ] GameState regression проходит;
- [ ] FPS regression проходит;
- [ ] raycast может попадать в character;
- [ ] нет runtime dependency на donor;
- [ ] MODULE 05 не реализован заранее.

---

# 88. Порядок выполнения Cursor

## Step 1 — pre-flight enum fix

Убрать:

```text
GameState.Stage
GameState.Characteristic
```

как отдельные enum.

Перевести GameState на:

```text
GameTypes.GameStage
GameTypes.PlayerCharacteristic
```

Запустить MODULE 02/03 tests.

---

## Step 2 — donor audit

Изучить:

```text
hero_base
women_modular
universal_library
character_anim_controller.gd
```

Составить внутреннюю таблицу:

```text
asset
purpose
COPY / ADAPT / REFERENCE / REJECT
dependencies
license
```

---

## Step 3 — animation technical decision

Проверить стандартный Godot playback на выбранных rigs.

Сравнить с legacy manual sampler.

Выбрать самый простой корректный approach.

Зафиксировать решение.

---

## Step 4 — copy assets

Скопировать только выбранные source assets и dependency closure.

Не копировать весь donor character tree «на всякий случай».

Проверить отсутствие donor runtime paths.

---

## Step 5 — appearance resources

Создать:

```text
CharacterBodyType
AppearanceProfileDefinition
animation profile, только если нужен
```

Расширить ContentDB/catalog.

---

## Step 6 — base visuals

Собрать:

```text
male_base_visual.tscn
female_base_visual.tscn
```

с корректным local scale/materials/animation.

---

## Step 7 — CharacterActor

Создать generic actor/body.

Не добавлять AI или interactions feature logic.

---

## Step 8 — animation controller

Реализовать semantic alias API.

---

## Step 9 — test scene

Создать Character Framework test.

Прогнать aliases, scale, visibility, replacement, collision.

---

## Step 10 — regressions

Запустить:

```text
MODULE 02
MODULE 03
FPS
Character Framework
```

---

## Step 11 — documentation

Обновить project docs и third-party asset list.

---

# 89. Формат финального отчёта Cursor

## Pre-flight

Подтвердить:

```text
GameState enum duplication removed
MODULE 02 PASS
MODULE 03 PASS
```

## Donor audit

Для ключевых assets:

```text
COPY / ADAPT / REFERENCE ONLY / REJECT
```

с короткой причиной.

## Selected visual bases

```text
Male:
<source>

Female:
<source>
```

## Animation approach

Что выбрано и почему.

Особенно указать:

```text
standard Godot animation
```

или

```text
adapted manual sampler
```

и причину.

## Framework

Что создано:

- profiles;
- actor;
- animation API;
- anchors;
- collision.

## Validation

Результаты tests.

## Licenses

Что добавлено/сохранено.

## Files changed

Основные файлы.

## Product questions

Только реальные вопросы, без которых нельзя продолжить.

Если нет:

```text
None.
```

---

# 90. Запрет продолжения

После успешного MODULE 04:

**НЕ начинать MODULE 05 — Progression & Perks.**

Остановиться и дождаться отдельной спецификации.
