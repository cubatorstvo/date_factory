# MODULE 01 — PLAYER FPS CORE

**Проект:** Date Factory  
**Модуль:** 01 — Player FPS Core  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать простое, предсказуемое и переиспользуемое управление игроком от первого лица и базовый контракт взаимодействия с миром  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`  
**Технический план:** `docs/TECHNICAL_IMPLEMENTATION_PLAN_RU.md`  
**Предыдущий модуль:** `MODULE_00_PROJECT_FOUNDATION_RU.md`

---

# 1. Цель модуля

MODULE 01 должен дать проекту полностью рабочее базовое FPS-управление, которое дальше используется всей игрой без необходимости переписывать locomotion.

После завершения модуля игрок должен уметь:

- ходить по 3D-миру;
- смотреть мышью;
- сталкиваться с окружением;
- подниматься по обычным небольшим ступеням/склонам;
- прыгать;
- видеть доступный интерактивный объект перед собой;
- взаимодействовать с ним по `E`;
- корректно терять управление при открытии modal UI / будущей мини-игры;
- корректно получать управление обратно;
- ставить игру на паузу;
- не иметь никаких gameplay-механик, относящихся к свиданиям, самцам, девушкам, характеристикам или прогрессии.

Это не shooter controller и не parkour controller.

Главная задача:

> Игрок должен забывать о системе движения и без раздражения перемещаться между игровыми ситуациями.

---

# 2. Правило технических решений Cursor

Все продуктовые требования и game-feel решения ниже являются фиксированными.

Cursor НЕ должен самостоятельно добавлять:

- спринт;
- приседание;
- dash;
- stamina;
- lean;
- sliding;
- mantle;
- vault;
- лестницы как отдельную механику;
- физическое хватание предметов;
- оружие;
- melee;
- procedural head bob;
- camera shake при обычной ходьбе;
- FOV kick;
- foot IK;
- сложную систему surface types;
- физические руки игрока;
- full-body FPS body;
- interaction wheel;
- radial menu;
- outline/highlight framework;
- generic ability system.

Чисто техническую реализацию Cursor выбирает самостоятельно.

Для нетривиальных решений он обязан:

1. изучить текущий новый проект;
2. изучить соответствующую реализацию FPS и interaction в donor;
3. определить, какие части donor действительно полезны;
4. сравнить разумные варианты;
5. выбрать решение согласно актуальным Godot best practices;
6. учитывать, что проект маленький, single-player и должен быстро производиться;
7. не строить архитектуру сложнее, чем требуется этой спецификацией;
8. существенные решения зафиксировать в `docs/TECHNICAL_DECISIONS.md`.

Donor — reference и источник отдельных готовых деталей, а не обязательная архитектура.

---

# 3. Обязательный анализ donor перед реализацией

Перед написанием FPS Core Cursor должен найти в:

```text
../date_factory_legacy
```

старые реализации:

- player controller;
- camera / mouse look;
- interaction raycast;
- interactable contract;
- pause / input locking;
- любые generic FPS helpers.

Нужно определить:

- что там уже работает хорошо;
- что связано со старой архитектурой;
- что можно безопасно скопировать;
- что проще написать заново.

Разрешено переносить только независимые части.

Запрещено переносить вместе с FPS Core:

- старый `Game`;
- старый HUD;
- inventory;
- старые gameplay state;
- старую логику dating;
- старые quests;
- старый UI flow;
- любые domain-зависимости.

Если старый player controller чистый и соответствует этой спецификации, его можно использовать как основу после копирования в новый проект.

Если он перегружен legacy-зависимостями, написать новый проще и предпочтительнее.

Donor остаётся read-only.

---

# 4. Canonical player scene

Создать отдельную переиспользуемую сцену:

```text
res://characters/player/player.tscn
```

или эквивалентный путь внутри canonical `characters/`, если фактическая структура MODULE 00 уже детализирована иначе.

Canonical scene name:

```text
Player
```

Игрок должен быть самостоятельной сценой, которую можно инстанцировать в любой будущей world scene.

Не размещать FPS-controller напрямую внутри `main.tscn`.

---

# 5. Базовая структура Player

Точная node-структура является техническим решением Cursor, но она должна концептуально разделять:

- физическое тело игрока;
- collision;
- вертикальный camera pivot;
- Camera3D;
- interaction query/raycast;
- минимальную gameplay input logic.

Предпочтительная семантика:

```text
Player
├── Collision
├── CameraPivot
│   └── Camera
└── InteractionQuery
```

Это НЕ требование использовать именно такие типы узлов или точные имена дочерних Node.

Cursor выбирает корректную Godot-структуру.

---

# 6. Физическое тело игрока

Игрок представляет обычного человека.

Требования:

- физический capsule-like collider;
- персонаж не должен застревать на обычных дверных проёмах;
- высота камеры ощущается как рост взрослого человека;
- collider и камера должны иметь нормальное человеческое соотношение;
- игрок должен нормально проходить по городской среде и квартире;
- collider не должен наклоняться вместе с поверхностью;
- игрок остаётся вертикальным.

Начальные ориентиры:

```text
общая высота collider: ~1.8 м
высота камеры: ~1.65 м
радиус collider: ~0.3–0.35 м
```

Это базовые значения, а не художественная характеристика героя.

Cursor может слегка скорректировать их, если это необходимо для стабильной физики Godot, но не должен превращать героя в высокий/низкий игровой архетип.

---

# 7. Скорость движения

Canonical base movement speed:

```text
4.5 м/с
```

Это обычная постоянная скорость ходьбы игрока.

Нет отдельных:

- walk/run;
- sprint;
- slow walk.

При движении по диагонали итоговая скорость НЕ должна становиться выше.

Движение должно ощущаться отзывчиво.

---

# 8. Ускорение и торможение

Игрок не должен:

- моментально телепортироваться между векторами скорости;
- долго скользить;
- иметь тяжёлую инерцию.

Нужна короткая мягкая интерполяция скорости.

Цель:

> движение начинается и заканчивается почти сразу, но визуально/физически не дёргается.

Рекомендуемый game-feel:

- выход на полную скорость примерно за `0.10–0.20 с`;
- остановка примерно за `0.10–0.15 с`.

Точные acceleration/deceleration constants Cursor рассчитывает сам исходя из physics tick и выбранного подхода.

---

# 9. Air movement

Игра не является платформером.

В воздухе:

- сохраняется разумный контроль;
- игрок может немного корректировать направление;
- нельзя резко менять траекторию как в arena shooter;
- air control не является отдельной системой.

Использовать простую реализацию.

---

# 10. Прыжок

Прыжок нужен для обычного исследования мира, а не для traversal gameplay.

Canonical jump height:

```text
примерно 1.0 м
```

Прыжок:

- обычный одиночный;
- без double jump;
- без bunny-hop механики;
- без jump buffering как обязательной feature;
- без coyote-time как отдельной заметной системы.

Если небольшой coyote time / buffering существенно улучшает техническую надёжность и не меняет ощущение игры, Cursor может реализовать минимальный best-practice вариант и зафиксировать решение.

Игрок не может прыгать, пока не находится на допустимой поверхности.

---

# 11. Gravity

Использовать корректную gravity текущего Godot project / Physics settings.

Не создавать отдельную фантазийную gravity system.

Если стандартное значение проекта не соответствует нормальному человеческому прыжку, настроить его вместе с jump velocity так, чтобы достигался результат раздела 10.

---

# 12. Пол и склоны

Игрок должен:

- устойчиво стоять на ровном полу;
- нормально ходить по небольшим уклонам;
- не дрожать на поверхности;
- не считать стены полом;
- не подниматься по почти вертикальным поверхностям.

Максимальный walkable slope должен соответствовать обычной городской среде.

Ориентир:

```text
~45°
```

Если Godot best practice требует немного другое значение для стабильности, Cursor выбирает технически корректное значение вблизи этого диапазона.

---

# 13. Ступени

Игра содержит:

- квартиры;
- кафе;
- улицы;
- бордюры;
- лестницы.

Игрок не должен регулярно застревать в небольших ступенях.

Нужно выбрать best-practice подход для Godot к step handling.

Цель:

- обычные ступени и небольшие бордюры проходятся естественно;
- камера не совершает резких скачков;
- система не превращается в отдельный сложный traversal-controller.

Ориентир максимальной высоты автоматически преодолеваемой ступени:

```text
~0.30–0.35 м
```

Если donor уже имеет стабильную реализацию ступеней, её нужно рассмотреть как потенциального кандидата для переноса.

---

# 14. Mouse look

Во время обычного gameplay:

- мышь захвачена;
- горизонтальное движение вращает игрока;
- вертикальное движение вращает camera pivot;
- вертикальный угол ограничен;
- движение мыши не зависит от FPS;
- нет camera acceleration;
- нет smoothing, создающего ощутимый input lag.

Vertical look limit:

```text
примерно -89° … +89°
```

Не позволять камере переворачиваться.

---

# 15. Mouse sensitivity

Sensitivity должна быть отдельным параметром controller и позже может быть подключена к Settings.

На MODULE 01 использовать разумное default значение.

Ориентир:

```text
~0.10–0.15° на pixel
```

Cursor должен выбрать корректное представление для Godot input API и не смешивать градусы/радианы.

Не создавать полноценное Settings menu.

---

# 16. Camera FOV

Canonical default vertical FOV:

```text
75°
```

FOV не меняется во время:

- ходьбы;
- прыжка;
- взаимодействия;
- ускорения.

Никакого sprint FOV нет.

Позже Settings могут позволить пользователю менять FOV, но MODULE 01 только хранит параметр controller/camera.

---

# 17. Camera motion

В обычном FPS movement НЕ использовать:

- head bob;
- breathing sway;
- camera roll;
- landing tilt;
- walking shake;
- procedural weapon-style inertia;
- dynamic FOV.

Камера должна быть стабильной.

Допускается только минимальное физически необходимое движение, возникающее из перемещения самого Player body.

Комедийные camera effects будут запускаться конкретными будущими событиями отдельно.

---

# 18. Player visual body

MODULE 01 не должен создавать полноценное видимое тело игрока.

В FPS не требуется:

- ноги;
- руки;
- shadow-only body;
- first-person arms.

Если donor содержит модель игрока, не переносить её в рамках этого модуля без необходимости.

Character visuals будут решаться в Character Framework.

---

# 19. Input actions

Использовать созданные в MODULE 00:

```text
move_forward
move_backward
move_left
move_right
jump
interact
pause
```

Не хардкодить клавиши в gameplay script.

Не создавать новые actions без необходимости этой спецификации.

---

# 20. Interaction philosophy

Взаимодействие должно быть максимально простым:

> Навёл центр экрана на доступный объект → увидел prompt → нажал `E`.

Не нужен:

- cursor selection;
- mouse click interaction;
- inventory hand;
- drag/drop world interaction;
- context wheel;
- interaction mode;
- generic verbs menu.

---

# 21. Interaction distance

Canonical interaction distance:

```text
2.5 м
```

Этого должно хватать для:

- двери;
- телефона;
- компьютера;
- NPC;
- стола;
- кровати;
- кнопки;
- предмета интерьера.

Игрок не должен взаимодействовать через комнату.

---

# 22. Interaction query

Interaction определяется от центра FPS-камеры.

Требования:

- выбирается первый допустимый объект по направлению взгляда;
- стены и обычная геометрия должны блокировать взаимодействие;
- нельзя взаимодействовать сквозь стену;
- query работает стабильно при движении;
- не выполнять ненужный дорогой world scan.

Конкретный Godot-подход:

- RayCast3D;
- direct space query;
- иной стандартный простой вариант

— выбирает Cursor после анализа.

---

# 23. Interactable contract

MODULE 01 должен создать минимальный общий контракт интерактивного world object.

Контракт должен позволять получить:

1. доступно ли взаимодействие сейчас;
2. текст действия;
3. выполнить взаимодействие.

Семантически необходимы операции уровня:

```text
can_interact(player)
get_interaction_prompt(player)
interact(player)
```

Это не обязательные точные GDScript method names.

Cursor может выбрать более идиоматичный технический интерфейс.

Но контракт НЕ должен заранее включать:

- price;
- item_id;
- quest_id;
- girl_id;
- rival_id;
- relationship;
- action tags;
- dialogue;
- inventory transfer;
- animation name;
- sound name;
- cooldown;
- save state.

Конкретные feature-компоненты позже сами оборачивают этот базовый контракт.

---

# 24. Interaction owner

Один interactable объект должен иметь одну понятную точку входа.

Не строить систему, где Player пытается определить тип объекта:

```text
if Door
elif Girl
elif Rival
elif Computer
...
```

Player знает только общий interactable contract.

---

# 25. Interaction prompt

Создать минимальный технический prompt.

Default presentation:

```text
[E] <действие>
```

Примеры допустимого содержания в будущем:

```text
[E] Открыть
[E] Поговорить
[E] Использовать
```

MODULE 01 не создаёт реальные игровые варианты.

Prompt:

- появляется только при наличии валидной цели;
- исчезает сразу при потере цели;
- находится в читаемой зоне около центра/нижней части экрана;
- не должен перекрывать центр прицела;
- не требует отдельного сложного UI framework.

Точное оформление временное.

Финальный UI будет позже.

---

# 26. Crosshair

Использовать минимальный нейтральный center marker.

Он может быть:

- маленькой точкой;
- маленьким простым crosshair.

Не делать shooter-style crosshair.

Если при взаимодействии полезно слегка менять его состояние, допустима минимальная индикация, но сложная система highlight не нужна.

---

# 27. Interaction priority

Если под лучом есть вложенные collision objects, система должна выбирать логически правильный interactable owner.

Cursor должен технически решить это без требования каждому будущему объекту вручную дублировать большой boilerplate.

При этом не строить глобальный registry интерактивных объектов.

---

# 28. Interaction while moving

Взаимодействие не требует остановки игрока.

По нажатию `E` конкретный объект позже сам решает, нужно ли:

- открыть UI;
- запустить сцену;
- заблокировать управление;
- ничего не блокировать.

FPS Core лишь предоставляет механизм перехода control mode.

---

# 29. Player control modes

Нужен минимальный механизм владения управлением.

Обязательные логические состояния:

```text
GAMEPLAY
MODAL_UI
MINIGAME
PAUSED
```

Это semantic contract.

Технически Cursor может реализовать его:

- enum внутри player/controller;
- отдельным маленьким controller;
- иной простой схемой.

Не создавать универсальную state machine framework.

---

# 30. GAMEPLAY mode

В `GAMEPLAY`:

- WASD работает;
- прыжок работает;
- mouse look работает;
- interact работает;
- mouse captured;
- gameplay crosshair/prompt активны.

---

# 31. MODAL_UI mode

Используется будущими:

- телефоном;
- журналом;
- деревом прокачки;
- компьютером;
- диалоговыми modal screens.

В `MODAL_UI`:

- движение выключено;
- прыжок выключен;
- mouse look выключен;
- world interaction выключен;
- mouse освобождена;
- UI получает input.

MODULE 01 не реализует сами UI.

---

# 32. MINIGAME mode

В `MINIGAME`:

- обычное движение игрока выключено;
- обычный world interact выключен;
- обычный FPS mouse look выключен;
- minigame получает нужный input;
- mouse mode определяется конкретной мини-игрой позже.

FPS Core должен позволять будущей мини-игре явно запросить нужный mouse mode, а после окончания вернуть обычный gameplay.

Не придумывать общий minigame framework в этом модуле.

---

# 33. PAUSED mode

По `pause` в обычном gameplay:

- игра ставится на паузу;
- mouse освобождается;
- появляется минимальный временный pause overlay;
- можно продолжить игру;
- `Escape` повторно возвращает gameplay.

MODULE 01 не реализует:

- Settings;
- Save;
- Main Menu;
- Quit confirmation;
- graphics settings.

Если технически удобно добавить временную кнопку `Resume`, это допустимо.

---

# 34. Pause priority

Если уже открыт `MODAL_UI` или `MINIGAME`, `Escape` в первую очередь должен быть доступен владельцу текущего режима согласно будущей feature-spec.

MODULE 01 должен предоставить корректную основу, но не придумывать правила закрытия всех будущих UI.

Для smoke test достаточно проверить:

```text
GAMEPLAY <-> PAUSED
```

и программный переход:

```text
GAMEPLAY -> MODAL_UI -> GAMEPLAY
GAMEPLAY -> MINIGAME -> GAMEPLAY
```

---

# 35. Cursor capture safety

При:

- старте игры;
- возврате из pause;
- возврате из modal UI;
- возврате из minigame

mouse state должен быть предсказуемым.

Не должно возникать ситуации:

- gameplay активен, но mouse свободна;
- UI активно, но mouse остаётся захваченной;
- первый click случайно стреляет/взаимодействует после закрытия UI.

---

# 36. Focus loss

Если окно игры теряет focus:

- не должно происходить неконтролируемое вращение камеры;
- при возврате input должен восстановиться корректно.

Точный best-practice behavior Cursor выбирает самостоятельно.

---

# 37. Test world

Для проверки MODULE 01 создать маленькую техническую сцену:

```text
res://world/test/player_fps_test.tscn
```

или эквивалентный clearly-test путь.

Сцена должна содержать только то, что необходимо проверить:

- пол;
- стены;
- дверной проём;
- несколько ступеней;
- небольшой склон;
- платформу/препятствие для прыжка;
- 2–3 простых interactable test objects.

Не тратить время на визуал.

Можно использовать primitives.

Эта сцена не является частью финального игрового мира.

---

# 38. Test interactables

Создать минимальные тестовые interactables.

Например:

1. объект с prompt `Использовать`;
2. объект, который временно запрещает interaction;
3. объект, который открывает тестовый `MODAL_UI`.

Они нужны только для проверки framework.

Не переносить эти тестовые сущности в actual content.

---

# 39. Main integration

После реализации:

- `main.tscn` должен иметь минимальный путь запуска FPS test или инстанцировать тестовую world scene;
- не создавать реальную квартиру;
- не переносить городской хаб;
- не начинать MODULE 12.

Цель — убедиться, что Player работает в реальном project startup flow.

Cursor выбирает самый простой временный способ.

---

# 40. Collision layers / masks

Cursor должен создать минимальную и понятную layer/mask схему, необходимую сейчас.

Нужно различать как минимум концептуально:

- world solid geometry;
- player;
- interaction targets.

Не создавать десятки заранее зарезервированных layers для будущих систем.

Фактические layer names и номера зафиксировать в:

```text
docs/PROJECT_STRUCTURE.md
```

или `TECHNICAL_DECISIONS.md`, если это существенное решение.

---

# 41. Performance requirements

FPS Core должен использовать стандартные дешёвые операции.

Запрещено:

- каждый frame обходить все interactables сцены;
- искать nodes по всему tree для каждого взаимодействия;
- создавать/удалять большие объекты каждый physics tick;
- логировать обычное движение каждый frame.

Interaction query на каждом physics/frame допустим, если используется обычный одиночный ray/query.

---

# 42. Signals and coupling

Допустимо использовать Godot signals там, где они дают локальную понятную связь.

Не создавать глобальный SignalBus.

Player может иметь небольшие сигналы технического характера, если они реально нужны, например:

- current interaction target changed;
- control mode changed.

Но не создавать future gameplay signals:

- money_changed;
- girl_conquered;
- rival_defeated;
- date_started.

---

# 43. Public API Player FPS Core

После MODULE 01 другие модули должны иметь минимальный стабильный способ:

- получить Player instance;
- временно отключить FPS gameplay input;
- перейти в `MODAL_UI`;
- перейти в `MINIGAME`;
- вернуть `GAMEPLAY`;
- при необходимости получить Camera3D;
- при необходимости инициировать/проверить interact.

Не предоставлять наружу десятки внутренних physics variables.

Конкретные method names Cursor выбирает технически.

---

# 44. Настройки controller

Основные game-feel параметры не должны быть разбросаны magic numbers по script.

Как минимум удобно настраиваемыми должны быть:

```text
move_speed = 4.5
jump_height ~= 1.0
mouse_sensitivity ~= chosen default
fov = 75
interaction_distance = 2.5
max_step_height ~= 0.30–0.35
max_slope ~= 45°
```

Точный способ хранения:

- exported properties;
- constants;
- small configuration resource

Cursor выбирает после анализа.

Не создавать глобальную configuration database.

---

# 45. Что НЕ брать из donor

Даже если donor player зависит от этих вещей, их нужно отрезать:

- Time system;
- Energy;
- Stamina;
- Inventory;
- Game singleton;
- old Interaction HUD;
- old Quest markers;
- dating context;
- NPC domain logic;
- teleport logic, привязанную к старому world structure;
- save data;
- achievements.

Если полезная функция смешана с ними, извлечь только чистую часть.

---

# 46. Кодовые ограничения

Не создавать один гигантский `player.gd`, который одновременно отвечает за:

- locomotion;
- interaction;
- pause UI;
- minigames;
- future stats;
- world transitions.

Но и не дробить controller на десяток микроскриптов.

Ожидается небольшой набор компонентов с ясной ответственностью.

Точную границу Cursor выбирает согласно фактическому объёму.

---

# 47. Debug support

В debug build должно быть удобно понять:

- текущий control mode;
- есть ли interaction target;
- почему interaction target недоступен;
- критические physics/configuration ошибки.

Но не создавать постоянный debug HUD.

Допустим optional debug print/helper при необходимости.

---

# 48. Accessibility / comfort baseline

Даже до финальных Settings FPS Core должен быть нейтральным и комфортным:

- нет обязательного camera shake;
- нет head bob;
- нет motion blur, создаваемого этим модулем;
- стабильный FOV;
- отсутствие резких roll-эффектов;
- отсутствие принудительной camera animation при interact.

Будущие постановочные сцены могут отдельно временно управлять камерой по своей спецификации.

---

# 49. Future compatibility boundaries

FPS Core должен позволять позже без переписывания locomotion:

- открывать телефон;
- разговаривать с NPC;
- запускать dating scene;
- запускать rival minigame;
- пользоваться компьютером;
- взаимодействовать с шахтой;
- входить в лабораторию.

Но MODULE 01 не должен знать, что означают эти сущности.

Все они для Player — просто внешние consumers interaction/control API.

---

# 50. Что MODULE 01 категорически НЕ реализует

Не реализовывать:

- реальных NPC;
- character customization;
- phone;
- journal;
- dialogue;
- girls;
- rivals;
- tags;
- dating;
- relationships;
- story;
- stage system;
- money;
- stats;
- perks;
- inventory;
- items;
- real doors as gameplay feature;
- world streaming;
- level transitions;
- save/load;
- settings menu;
- audio framework;
- animation framework;
- clone gameplay.

---

# 51. Smoke tests

## Test 1 — Basic movement

Проверить:

- W/S/A/D;
- диагональное движение не быстрее;
- старт/остановка отзывчивы;
- collider стабилен.

---

## Test 2 — Mouse look

Проверить:

- horizontal rotation;
- vertical rotation;
- vertical clamp;
- нет roll;
- нет frame-rate-dependent sensitivity.

---

## Test 3 — Jump

Проверить:

- прыжок только с пола;
- высота около целевой;
- нет double jump;
- приземление стабильно.

---

## Test 4 — Slope

Проверить:

- обычный slope проходится;
- слишком крутой slope не считается полом;
- player не дрожит.

---

## Test 5 — Steps

Проверить:

- небольшая ступень проходится;
- лестница из обычных ступеней проходится;
- высокая стена не преодолевается как ступень.

---

## Test 6 — Interaction detection

Проверить:

- объект обнаруживается до 2.5 м;
- дальше 2.5 м не обнаруживается;
- стена блокирует;
- prompt появляется/исчезает;
- E вызывает ровно одну interaction.

---

## Test 7 — Disabled interaction

Test object с `can_interact = false`.

Ожидается:

- interaction не выполняется;
- prompt ведёт себя согласно выбранному простому UX;
- нет error.

---

## Test 8 — Modal UI

Test interactable открывает modal test panel.

Ожидается:

- player movement stop;
- look stop;
- mouse release;
- world interact stop;
- закрытие возвращает gameplay и capture.

---

## Test 9 — Minigame mode

Программно активировать test minigame mode.

Ожидается:

- FPS controls отключены;
- возврат восстанавливает gameplay.

Не нужна реальная мини-игра.

---

## Test 10 — Pause

Проверить:

- Escape из gameplay ставит pause;
- mouse освобождается;
- повторное Resume возвращает игру;
- после возврата камера не прыгает.

---

## Test 11 — Donor independence

Новый Player и interaction не имеют runtime dependency на:

```text
../date_factory_legacy
```

---

## Test 12 — Clean startup

Запустить игру с main scene.

Ожидается:

- no parse errors;
- no missing dependencies;
- no legacy autoload requirements;
- FPS test доступен сразу.

---

# 52. Definition of Done

MODULE 01 завершён, только если:

- [ ] создан отдельный reusable Player scene;
- [ ] WASD movement работает;
- [ ] скорость соответствует базовому game-feel;
- [ ] диагональ нормализована;
- [ ] mouse look работает;
- [ ] vertical clamp работает;
- [ ] FOV = 75° по умолчанию;
- [ ] нет head bob / camera sway / FOV kick;
- [ ] jump работает;
- [ ] обычные slopes работают;
- [ ] обычные steps работают;
- [ ] interaction distance = 2.5 м;
- [ ] базовый interactable contract существует;
- [ ] interaction не зависит от типа gameplay-object;
- [ ] interaction prompt работает;
- [ ] GAMEPLAY mode работает;
- [ ] MODAL_UI переход протестирован;
- [ ] MINIGAME переход протестирован;
- [ ] PAUSED работает;
- [ ] mouse capture/release корректен;
- [ ] test world существует;
- [ ] test interactables существуют;
- [ ] donor проанализирован;
- [ ] donor не изменён;
- [ ] нет runtime dependency на donor;
- [ ] нет legacy gameplay contamination;
- [ ] существенные technical decisions документированы;
- [ ] smoke tests пройдены;
- [ ] MODULE 02 не реализован заранее.

---

# 53. Порядок выполнения Cursor

## Step 1 — Read specs

Изучить:

- `MASTER_GDD.md`;
- technical implementation plan;
- MODULE 00 spec;
- фактический `PROJECT_STRUCTURE.md`;
- `TECHNICAL_DECISIONS.md`;
- эту спецификацию.

---

## Step 2 — Audit donor FPS

Найти FPS/interaction код donor.

Кратко определить:

- reusable;
- legacy-coupled;
- discard.

Не редактировать donor.

---

## Step 3 — Choose technical approach

Выбрать:

- CharacterBody architecture;
- step handling;
- interaction query;
- control mode implementation;
- pause implementation.

Для каждого нетривиального решения учитывать:

- актуальный Godot;
- best practice;
- простоту;
- отсутствие overengineering;
- будущие утверждённые потребности Date Factory.

---

## Step 4 — Implement FPS

Сначала:

- Player scene;
- locomotion;
- camera;
- jump;
- floor/slope/steps.

Проверить отдельно.

---

## Step 5 — Implement interaction

Добавить:

- query;
- interactable contract;
- prompt;
- test interactables.

Проверить отдельно.

---

## Step 6 — Implement control modes

Добавить:

- GAMEPLAY;
- MODAL_UI;
- MINIGAME;
- PAUSED;
- mouse ownership.

Проверить переходы.

---

## Step 7 — Test world

Создать минимальную test scene и выполнить все smoke tests.

---

## Step 8 — Documentation

Обновить только фактические:

- `PROJECT_STRUCTURE.md`;
- `TECHNICAL_DECISIONS.md`.

Не менять продуктовый GDD.

---

# 54. Формат финального отчёта Cursor

После завершения вернуть:

## Implemented

Что реализовано.

## Donor analysis

Какие FPS/interaction части donor были найдены.

Для каждой:

```text
reused / adapted / rejected
```

и краткая причина.

## Technical decisions

Только существенные решения:

- locomotion approach;
- step handling;
- interaction query;
- control mode;
- pause.

## Validation

Результаты smoke tests.

## Files changed

Основные файлы.

## Product questions

Только если неожиданно возник реальный вопрос по механике, которого нет в спецификации.

Если нет:

```text
None.
```

---

# 55. Запрет продолжения

После MODULE 01:

**НЕ начинать MODULE 02 — Core Game State.**

Остановиться и дождаться отдельной спецификации.

