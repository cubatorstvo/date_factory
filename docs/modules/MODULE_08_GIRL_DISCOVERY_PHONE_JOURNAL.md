# MODULE 08 — GIRL DISCOVERY & PHONE JOURNAL

**Проект:** Date Factory  
**Модуль:** 08 — Girl Discovery & Phone Journal  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать обнаружение девушек в фиксированных ситуациях, попытку знакомства, ограничение по Опытности, получение номера, повторную попытку через 1–3 игровых дня и функциональный телефонный журнал известной информации  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/05_girls.md`, `docs/gdd/08_locations_ui_content.md`  
**Предыдущие модули:** MODULE 02–07  
**Следующий модуль:** MODULE 09 — Dating Core

---

# 0. ГРАНИЦА МОДУЛЯ

MODULE 08 заканчивается в момент:

```text
девушка обнаружена
→ игрок попытался познакомиться
→ получил номер
→ контакт появился в телефоне
```

MODULE 08 НЕ запускает свидание.

После получения номера:

```text
relationship НЕ меняется
experience НЕ меняется
upgrade_points НЕ меняются
girl conquered НЕ отмечается
```

Dating начинается только в MODULE 09.

---

# 1. Канонический flow

```text
Игрок видит девушку в её фиксированной ситуации
→ девушка появляется в журнале
→ открывается первая подсказка
→ игрок взаимодействует
→ проверяется required_experience
→ показываются authored варианты знакомства
→ игрок выбирает доступный вариант
→ SUCCESS:
       номер получен
       контакт постоянный
       cooldown отсутствует
→ FAILURE:
       короткая реакция
       раскрывается следующая подсказка
       девушка исчезает/становится недоступна
       cooldown 1–3 игровых дня
→ после cooldown та же девушка возвращается
   в ту же ситуацию
```

---

# 2. Главный production-принцип

Каждая девушка — handmade content.

Не генерировать новых девушек после провала.

Не менять:

```text
girl_id
primary_trait
secondary_trait
appearance_profile_id
discovery_situation_id
```

после failed attempt.

Повторная попытка всегда относится к той же:

```text
GirlDefinition
```

---

# 3. Фиксированная ситуация

GDD прямо разрешает постановочные повторяемые сцены.

Примеры:

- девушка сидит в конкретном кафе;
- помогает одному и тому же упавшему велосипедисту;
- спорит с продавцом;
- ждёт транспорт;
- выполняет странный ритуал.

MODULE 08 НЕ создаёт:

- NPC schedule;
- daily routine;
- simulation of incident;
- AI pedestrian life.

Фиксированная ситуация — content scene/definition.

---

# 4. Static data extension

Добавить typed static resources:

```text
DiscoverySituationDefinition
DiscoveryApproachDefinition
```

в существующий Content Data Layer.

Не создавать новый ContentManager.

Использовать `ContentDB`.

---

# 5. DiscoverySituationDefinition

Минимальные поля:

```text
id: StringName
location_id: StringName

setup_text: String
approaches: Array[DiscoveryApproachDefinition]
```

Canonical ID prefix:

```text
discovery_situation_*
```

`location_id` ссылается на существующий `LocationDefinition`.

---

# 6. GirlDefinition остаётся owner связи

Уже существует:

```text
GirlDefinition.discovery_situation_id
```

Именно GirlDefinition определяет ситуацию конкретной девушки.

Не добавлять duplicate:

```text
girl_id
```

в `DiscoverySituationDefinition`, если технически без этого можно обойтись.

Cross-reference:

```text
GirlDefinition.discovery_situation_id
→ DiscoverySituationDefinition.id
```

---

# 7. DiscoveryApproachDefinition

Минимальные поля:

```text
id: StringName
label: String

has_requirement: bool
required_characteristic: GameTypes.PlayerCharacteristic
required_level: int

outcome: DiscoveryApproachOutcome

result_text: String
```

---

# 8. DiscoveryApproachOutcome

Ровно:

```text
SUCCESS
FAILURE
```

Не добавлять:

- CRITICAL_SUCCESS;
- PARTIAL_SUCCESS;
- RANDOM;
- CONDITIONAL_SCRIPT;
- TRAIT_SCORE;
- DATING_SCORE.

---

# 9. Почему outcome authored

Знакомство — короткий handmade content beat.

MODULE 08 не должен создавать универсальный social resolver.

Конкретный вариант может быть:

```text
"Помочь поднять велосипед"
→ SUCCESS
```

или:

```text
"Объяснить, что падение укрепляет характер"
→ FAILURE
```

Правильность варианта задаётся content authoring.

---

# 10. Характеристики в знакомстве

Некоторые authored approaches могут требовать:

```text
MUSCLE
APPEARANCE
CAPITAL
AURA
```

Пример:

```text
required_characteristic = MUSCLE
required_level = 2
```

Requirement:

- виден игроку заранее;
- недоступный вариант disabled;
- выбор disabled варианта невозможен.

---

# 11. Требование не определяет исход

Requirement лишь определяет доступность.

Например:

```text
Мышца 3
```

может открыть абсурдный вариант, который authored как FAILURE.

Не считать автоматически:

```text
requirement met => success
```

---

# 12. Не использовать Dating tags

Discovery approaches НЕ создают:

```text
CARE
PRESTIGE
ABSURDITY
...
```

и не оцениваются PrimaryGirlTrait.

Это начинается в MODULE 09.

Не реализовывать Dating evaluator раньше времени.

---

# 13. ContentDB catalog

Расширить explicit static catalog:

```text
discovery_situations
```

Нужны lookup:

```text
get_discovery_situation(id)
```

и при необходимости:

```text
find_discovery_approach(approach_id)
```

для Phone/Debug.

Не сканировать filesystem.

---

# 14. Validation — situation

Проверить:

- id non-empty;
- prefix `discovery_situation_*`;
- unique;
- location exists;
- setup_text non-empty для production;
- минимум 1 approach;
- approach IDs unique глобально или как минимум внутри catalog без неоднозначности.

Предпочтительно глобально unique.

---

# 15. Validation — approach

Проверить:

- id non-empty;
- canonical prefix:
  ```text
  discovery_approach_*
  ```
- label non-empty;
- valid outcome;
- if `has_requirement`:
  - required_level `0..8`;
  - characteristic valid;
- result_text non-empty для production.

---

# 16. Validation — GirlDefinition

Если production girl имеет:

```text
discovery_situation_id != ""
```

reference должен существовать.

Если production girl участвует в городском discovery:

```text
discovery_situation_id
```

обязателен.

Story exceptions можно разрешать позже MODULE 11/14 явно.

Не придумывать exceptions сейчас.

---

# 17. Production content scope

MODULE 08 НЕ создаёт реальные:

```text
girl_neighbor
girl_actress
girl_scientist
...
```

discovery situations.

Реальное наполнение — MODULE 14.

Создать только test fixtures.

---

# 18. Runtime state — discovered girls

Добавить в `GameState` set-like:

```text
discovered_girls
```

API semantic:

```text
is_girl_discovered(girl_id) -> bool
mark_girl_discovered(girl_id) -> bool
get_discovered_girl_ids() -> Array[StringName]
```

No duplicates.

---

# 19. Runtime state — contacts

Добавить set-like:

```text
girl_contacts
```

API:

```text
has_girl_contact(girl_id) -> bool
add_girl_contact(girl_id) -> bool
get_girl_contact_ids() -> Array[StringName]
```

Контакт постоянный в прохождении.

---

# 20. Contact invariant

Если:

```text
has_girl_contact(girl_id)
```

то:

```text
is_girl_discovered(girl_id) == true
```

`add_girl_contact()` должен гарантировать этот invariant.

---

# 21. Number is not relationship

Получение номера НЕ делает:

```text
relationship +1
```

и вообще не трогает:

```text
girl_relationships
```

---

# 22. Number is not completion

Не вызывать:

```text
mark_girl_conquered
add_experience
Progression
```

при получении номера.

---

# 23. Runtime state — clues

Для каждой девушки хранить known clue indices.

Semantic:

```text
known_clues[girl_id] = set of integer indices
```

Источник текста:

```text
GirlDefinition.clue_notes[index]
```

Не копировать сами строки clue в GameState.

---

# 24. Clue API

Нужны:

```text
is_girl_clue_known(girl_id, clue_index)
reveal_girl_clue(girl_id, clue_index) -> bool
get_known_girl_clue_indices(girl_id) -> Array[int]
```

Return copy, не internal collection.

---

# 25. Clue order

Phone отображает clues по исходному порядку:

```text
0
1
2
...
```

а не по порядку Dictionary.

---

# 26. First discovery clue

Когда girl впервые обнаружена:

```text
mark_girl_discovered()
```

если:

```text
clue_notes.size() >= 1
```

автоматически раскрывается:

```text
clue index 0
```

---

# 27. Failed attempt clue

При каждом FAILURE:

- найти минимальный ещё неизвестный clue index;
- раскрыть ровно один;
- если все clues уже известны:
  - failure всё равно валиден;
  - новой clue нет.

---

# 28. `APPEARANCE_GOOD_PROFILE` — Выгодный профиль

MODULE 08 реализует discovery-часть perk-контракта.

Если игрок владеет:

```text
PerkIds.APPEARANCE_GOOD_PROFILE
```

при ПЕРВОМ обнаружении девушки:

```text
clue 0
```

раскрывается как обычно,

и дополнительно, если существует:

```text
clue 1
```

тоже сразу раскрывается.

Это конкретная реализация:

> герой замечает дополнительную визуальную деталь образа.

---

# 29. Good Profile only on first discovery

Perk не выдаёт новую clue:

- при каждом открытии журнала;
- при каждом respawn;
- при каждом failed attempt.

Только initial discovery.

---

# 30. Good Profile snapshot

Проверить perk в момент первого discovery.

Если игрок купил perk позже:

- ранее встреченные девушки автоматически вторую clue не получают.

Это не retroactive perk.

---

# 31. Runtime state — primary trait reveal

Добавить set-like:

```text
revealed_primary_traits
```

API:

```text
is_primary_trait_revealed(girl_id)
reveal_primary_trait(girl_id) -> bool
```

MODULE 08 сам trait НЕ раскрывает.

API нужен Phone Journal и будущему MODULE 09/10.

---

# 32. Primary trait hidden by default

До explicit reveal Phone НЕ пишет:

```text
Добрая
Статусная
Азартная
Странная
```

как факт.

Он показывает только известные clues.

---

# 33. После reveal

Phone показывает:

```text
название primary trait
likes
dislikes
```

через existing:

```text
PrimaryTraitDefinition
```

Не копировать списки тегов в journal state.

---

# 34. Secondary trait

MODULE 08 НЕ создаёт reveal-state SecondaryGirlTrait.

Её раскрытие/интерпретация относится к Dating/Relationships.

Если позже понадобится — расширить тогда.

---

# 35. Known reactions seam

Телефон в будущем должен показывать известные реакции девушки.

Добавить минимальный runtime seam:

```text
record_girl_known_reaction(
    girl_id,
    source_id,
    reaction
)
```

где:

```text
reaction ∈ {-1, 0, +1}
```

---

# 36. Reaction storage

Semantic:

```text
known_reactions[girl_id][source_id] = reaction
```

No duplicate source IDs.

Повторная запись того же source может overwrite то же canonical observation.

---

# 37. MODULE 08 reaction population

MODULE 08 НЕ обязан записывать discovery SUCCESS/FAILURE как `+1/-1`.

Это не Primary Trait evaluation.

В обычной реализации после MODULE 08:

```text
known reactions section
```

может быть пустым.

MODULE 09 начнёт его наполнять.

---

# 38. Reaction source resolution

Phone Journal должен пытаться разрешить source label через static content.

Future:

```text
DatingActionDefinition.id
```

может быть source.

Discovery approach тоже может быть source при будущем явном product decision.

Если source не удаётся разрешить:

- в production UI не показывать raw technical ID;
- debug может показать warning.

---

# 39. Retry cooldown runtime state

После failed attempt хранить:

```text
girl_retry_days_remaining[girl_id]: int
```

Canonical range после failure:

```text
1..3
```

---

# 40. Retry API

Нужны:

```text
get_girl_retry_days_remaining(girl_id) -> int
is_girl_available_for_discovery(girl_id) -> bool
```

---

# 41. Cooldown selection

После FAILURE:

```text
cooldown_days = rng.randi_range(1, 3)
```

Seed должен быть injectable для tests.

Не использовать:

- real-world hours;
- OS time;
- Timer seconds.

---

# 42. Почему remaining days, а не full clock

Полная игровая система времени ещё не реализована.

MODULE 08 не должен преждевременно строить:

- часы;
- календарь;
- day/night;
- schedule manager.

Нужен минимальный day-advance seam.

---

# 43. Day advance seam

`GirlDiscovery` предоставляет:

```text
advance_game_day()
```

или более явно:

```text
notify_game_day_advanced()
```

Один вызов означает:

```text
прошёл один игровой день
```

Для всех cooldown:

```text
remaining = max(0, remaining - 1)
```

---

# 44. Future time integration

Когда полноценный time/world owner появится:

```text
он вызывает notify_game_day_advanced()
```

MODULE 08 не владеет временем.

Не создавать отдельный global Clock.

---

# 45. Cooldown persistence

Cooldown days remaining находятся в `GameState`, а не только в transient actor.

Почему:

- смена scene не должна сбрасывать cooldown;
- MODULE 24 позже сможет сохранить это состояние.

---

# 46. Contact clears cooldown

При успешном получении номера:

```text
girl_retry_days_remaining = 0
```

---

# 47. Failed attempt after existing cooldown impossible

Нельзя начать новую попытку, пока:

```text
remaining > 0
```

---

# 48. Experience gate

Перед acquaintance attempt проверить:

```text
GameState.experience >= GirlDefinition.required_experience
```

---

# 49. Gate visible

Если опыта недостаточно:

```text
Опытность: X / N
```

должна быть видна до выбора approach.

Interaction не создаёт failed attempt.

---

# 50. Low Experience does NOT trigger cooldown

Если:

```text
experience < required
```

результат:

```text
LOCKED_EXPERIENCE
```

Нет:

- failure reaction;
- new clue;
- cooldown;
- relationship change.

---

# 51. Опытность read-only here

MODULE 08 только читает Experience.

Не вызывает:

```text
add_experience()
```

---

# 52. Canonical Experience meaning

Документация уже должна отражать latest product rule:

> Опытность = число уникальных девушек, которые когда-либо достигли `+5`.

MODULE 08 лишь использует текущее значение.

MODULE 10 реализует начисление.

---

# 53. GirlDiscovery system

Создать system semantic:

```text
GirlDiscovery
```

Он отвечает за:

- discovery;
- availability;
- experience gate;
- begin attempt;
- resolve authored approach;
- success/contact;
- failure/cooldown/clue;
- day advance;
- notifications.

---

# 54. Architecture choice

Cursor сравнивает:

1. stateless/autoload service;
2. small autoload;
3. scene owner.

Учитывать:

- cooldown state persistent в GameState;
- discovery actor может находиться в разных scenes;
- future world time должен уведомлять систему;
- Phone Journal читает те же данные.

Разумный вариант:

```text
autoload GirlDiscovery
```

Но это техническое решение Cursor.

Если autoload:

```text
GirlDiscovery
```

— canonical name.

Не:

```text
GirlManager
DatingManager
WomenManager
```

---

# 55. Не использовать `_process`

GirlDiscovery не требует polling.

Все изменения event-driven:

- actor seen;
- interact;
- choice selected;
- day advanced.

---

# 56. Attempt result enum

Нужен typed result semantic:

```text
SUCCESS
FAILURE
LOCKED_EXPERIENCE
COOLDOWN
ALREADY_CONTACT
UNKNOWN_GIRL
INVALID_CONTENT
```

Можно разделить begin/resolve result технически.

---

# 57. Begin attempt

Semantic:

```text
begin_attempt(girl_id)
```

Проверки:

1. girl exists;
2. discovered;
3. not already contact;
4. cooldown == 0;
5. experience sufficient;
6. discovery situation exists.

Если OK:

- вернуть situation + available approach state;
- НЕ менять progression.

---

# 58. Attempt session

Можно иметь маленький transient:

```text
GirlDiscoveryAttempt
```

с:

```text
girl_id
situation_id
available approach ids
finished
```

Не сохранять mid-attempt.

---

# 59. No simultaneous duplicate attempt

Для одного local player только один active discovery attempt.

Если UI already open:

```text
ALREADY_ACTIVE
```

или ignore repeated interact.

Не создавать queue.

---

# 60. Approach selection

При выборе:

1. проверить attempt active;
2. найти approach;
3. повторно проверить requirement;
4. прочитать authored outcome;
5. завершить attempt один раз.

---

# 61. SUCCESS

При authored:

```text
SUCCESS
```

атомарно:

```text
add_girl_contact(girl_id)
clear cooldown
finish attempt
```

Return:

```text
SUCCESS
```

---

# 62. FAILURE

При authored:

```text
FAILURE
```

атомарно:

```text
reveal next clue if any
set cooldown random 1..3
finish attempt
```

Return:

```text
FAILURE
cooldown_days
new_clue_index optional
```

---

# 63. Exactly-once attempt

После attempt finished:

- второй click не выдаёт номер повторно;
- второй failure callback не создаёт второй cooldown;
- не раскрывает две clues.

---

# 64. Discovery actor

Создать тонкий production adapter semantic:

```text
GirlDiscoveryActor
```

или:

```text
GirlActor
```

Предпочтение:

```text
GirlActor
```

если класс остаётся нейтральным для future reuse.

---

# 65. GirlActor fields

Минимально:

```text
girl_id: StringName
```

и references на:

```text
CharacterActor
Interactable/collision
discovery trigger
```

Static данные не дублируются.

---

# 66. GirlActor setup

По `girl_id`:

```text
GirlDefinition
→ appearance_profile_id
→ CharacterActor.apply appearance
```

Если framework уже делает это в другом thin adapter — переиспользовать.

---

# 67. GirlActor не хранит gameplay data

Не копировать в scene:

- primary trait;
- secondary trait;
- required experience;
- clue texts;
- discovery outcome;
- relationship.

Все через ContentDB/GameState.

---

# 68. Seen trigger

У GirlActor есть простой:

```text
Area3D
```

или эквивалентный proximity trigger.

Ориентир radius:

```text
4.0 m
```

Когда Player впервые входит:

```text
GirlDiscovery.discover_girl(girl_id)
```

---

# 69. Trigger не AI

Area только фиксирует:

```text
игрок увидел/приблизился
```

Не заставляет девушку:

- идти;
- смотреть;
- разговаривать;
- следовать.

---

# 70. Discovery notification

При первом discovery можно кратко показать:

```text
Новая запись в телефоне
```

и первую clue.

Final polish MODULE 22/23.

---

# 71. Interactable

Если contact ещё не получен и cooldown == 0:

```text
[E] Познакомиться
```

---

# 72. Cooldown actor presence

После FAILURE канон:

> девушка возвращается через 1–3 игровых дня.

Поэтому пока cooldown > 0:

GirlActor должен быть:

- hidden;
- collision disabled;
- interaction disabled.

---

# 73. Actor returns

После day advance, когда remaining становится:

```text
0
```

GirlActor refresh-ится:

- visible;
- collision enabled;
- same position;
- same appearance;
- same girl_id.

---

# 74. Scene reload during cooldown

При `_ready()` GirlActor обязан query current availability.

Если cooldown >0:

```text
сразу hidden
```

а не появиться на frame и исчезнуть.

---

# 75. Contact obtained actor

После получения номера MODULE 08 НЕ требует исчезновения девушки.

Она может остаться в ситуации.

Interact после contact:

```text
номер уже получен
```

и discovery attempt не запускается.

Future content/world может изменить поведение.

---

# 76. Phone Journal purpose

Functional phone UI должен отвечать на вопросы:

- кого я уже видел;
- чей номер у меня есть;
- что я заметил о девушке;
- раскрыта ли её основная черта;
- какие реакции уже известны.

Не быть полноценным smartphone simulator.

---

# 77. Phone Journal scene

Создать:

```text
res://ui/phone/phone_journal.tscn
```

или canonical current UI path.

Semantic class:

```text
PhoneJournal
```

---

# 78. Phone open boundary

MODULE 08 НЕ добавляет постоянную клавишу телефона.

Предоставить API:

```text
open()
close()
```

или instantiate scene.

Future:

- квартира;
- physical phone;
- MODULE 22

решат input/entry point.

Test scene имеет кнопку/open debug action.

---

# 79. Why no phone key now

Не резервировать:

```text
Tab
P
F
```

без утверждённого общего UI design.

---

# 80. Phone control mode

Открытый journal:

```text
PlayerControlMode.MODAL_UI
```

Mouse visible.

При закрытии возвращается previous control mode.

Использовать existing Player API.

---

# 81. Phone list population

Показывать только:

```text
discovered_girls
```

Не весь production ContentDB.

Не спойлерить невстреченных девушек.

---

# 82. List ordering

Deterministic.

Предпочтение:

```text
порядок первого discovery
```

Если set не хранит order, GameState может хранить discovered IDs как ordered unique array.

Если это усложняет state, допустим:

```text
display_name / ID deterministic sort
```

Выбрать и документировать.

Не random order.

---

# 83. Entry contact status

Для каждой discovered girl:

```text
Номер получен
```

или:

```text
Номера нет
```

---

# 84. Girl display name before contact

Не вводить новую систему неизвестных имён.

Показывать:

```text
GirlDefinition.display_name
```

если оно заполнено.

Test fixtures имеют display names.

Real content позже решит, является ли display name именем или ролью.

---

# 85. Phone entry — clues

Показывать:

```text
Наблюдения
```

и только раскрытые:

```text
clue_notes[index]
```

---

# 86. Unknown clues

Не показывать:

```text
??? ??? ???
```

по количеству.

Игрок не должен знать точное число оставшихся clues.

Просто список известных наблюдений.

---

# 87. Phone entry — primary trait hidden

До reveal:

```text
Характер: ?
```

Допустимо:

```text
Тип пока не определён
```

---

# 88. Phone entry — primary trait revealed

После reveal показать:

```text
Основная черта: Добрая
Нравится: ...
Не нравится: ...
```

через static definition.

---

# 89. Phone entry — reactions

Секция:

```text
Известные реакции
```

Если записей нет:

```text
Пока нет наблюдений
```

---

# 90. No dating button

После MODULE 08 Phone НЕ показывает рабочие:

```text
Позвать на свидание
Назначить встречу
Написать
```

кнопки.

Не создавать fake flow MODULE 09.

Контакт просто существует.

---

# 91. Experience gate in world UI

При interaction с locked girl:

вместо choices показать коротко:

```text
Нужна Опытность: N
Сейчас: X
```

и закрыть/оставить modal.

Не скрывать requirement.

---

# 92. Discovery choice UI

Минимальный modal:

```text
<situation setup>

[Подход 1]
[Подход 2]
[Подход 3]
```

У каждого requirement, если есть:

```text
Мышца 2
Аура 3
...
```

---

# 93. Disabled choice

Если requirement unmet:

- button disabled;
- requirement visible.

Не скрывать вариант полностью.

---

# 94. Result UI

SUCCESS:

```text
НОМЕР ПОЛУЧЕН
<result_text>
```

FAILURE:

```text
НЕ ВЫШЛО
<result_text>

Новая заметка:
<clue>
```

если новая clue есть.

---

# 95. Failure cooldown shown

После failure показать:

```text
Она появится снова через N дн.
```

или грамматически нейтрально:

```text
Повторная попытка через N дн.
```

Final localization polish позже.

---

# 96. No relationship score UI

Discovery result UI не показывает:

```text
+1 / -1 отношения
```

потому что relationship не меняется.

---

# 97. No trait score UI

Не показывать:

```text
Primary trait +1/-1
```

для acquaintance choices.

---

# 98. Discovery signals

Нужны semantic notifications, например:

```text
girl_discovered(girl_id)
girl_contact_added(girl_id)
girl_clue_revealed(girl_id, clue_index)
girl_discovery_failed(girl_id, cooldown_days)
girl_available_again(girl_id)
primary_trait_revealed(girl_id)
```

Не обязательно ровно эти names.

Не создавать global EventBus.

---

# 99. GameState signals

Persistent state mutation signals могут жить в GameState.

GirlDiscovery может переизлучать higher-level semantic events.

Избегать двойного дублирования, если не нужно.

---

# 100. No world scanning

GirlDiscovery не ищет все GirlActor в SceneTree каждый frame.

Actor сам:

- подписывается на relevant signal;
- либо refresh вызывается через clean event.

---

# 101. Day advance event

После `notify_game_day_advanced()`:

для каждого cooldown, который стал 0:

```text
emit girl_available_again(girl_id)
```

ровно один раз.

---

# 102. Test fixtures

Создать test-only:

```text
girl_test_discovery
girl_test_experience_locked
```

и corresponding discovery situations.

Не включать production catalog.

---

# 103. `girl_test_discovery`

Пример:

```text
required_experience = 0
primary = KIND
secondary = CONSISTENT
clues:
  0 "Поднимает чужой велосипед."
  1 "Сначала спрашивает, не ушибся ли человек."
  2 "Раздражается, когда помощь превращают в соревнование."
```

Test situation:

```text
discovery_situation_test_bicycle
```

---

# 104. Test approaches

Например:

```text
discovery_approach_test_help
label = "Помочь поднять велосипед"
outcome = SUCCESS
no requirement
```

```text
discovery_approach_test_flex
label = "Поднять велосипед одной рукой и ждать реакции"
outcome = FAILURE
require MUSCLE 2
```

```text
discovery_approach_test_buy
label = "Купить новый велосипед"
outcome = FAILURE
require CAPITAL 3
```

Это только test content.

---

# 105. Experience locked fixture

```text
required_experience = 3
```

Используется только tests.

---

# 106. Test scene

Создать:

```text
res://game/girls/test/girl_discovery_test.tscn
```

или canonical equivalent.

Содержит:

- Player;
- floor;
- две test GirlActors;
- simple fixed situation props;
- phone open button;
- debug day advance button;
- debug Experience grant только test.

---

# 107. Test — initial state

После reset:

```text
discovered girls empty
contacts empty
clues empty
cooldowns empty
primary reveal empty
```

---

# 108. Test — proximity discovery

Player входит в radius.

Expected:

```text
girl discovered
clue 0 known
contact false
```

---

# 109. Test — proximity idempotent

Выйти/зайти снова:

- no duplicate discovery;
- no extra clue.

---

# 110. Test — Good Profile

Own perk before first discovery.

Expected:

```text
clue 0 known
clue 1 known
```

ровно.

---

# 111. Test — Good Profile not retroactive

Discover without perk:

```text
only clue 0
```

Buy perk later.

Expected:

```text
clue 1 still unknown
```

до normal reveal path.

---

# 112. Test — experience gate

Girl requires 3.

Current Experience 2.

Interact:

```text
LOCKED_EXPERIENCE
```

No cooldown/no clue/no contact.

---

# 113. Test — experience gate exact

Experience 3:

attempt allowed.

---

# 114. Test — disabled characteristic choice

Approach requires:

```text
MUSCLE 2
```

Player Muscle 1.

Button disabled.

Server/system-level select attempt also rejected.

---

# 115. Test — success

Choose authored success.

Expected:

```text
contact added
discovered true
cooldown 0
relationship unchanged
experience unchanged
```

---

# 116. Test — duplicate success

Second callback/select:

```text
no second contact event
```

---

# 117. Test — already contact

Interact after success:

```text
ALREADY_CONTACT
```

No attempt.

---

# 118. Test — failure

Choose authored failure.

Expected:

```text
contact false
next clue revealed
cooldown 1..3
```

---

# 119. Test — deterministic cooldown

Seed fixture to produce known:

```text
1
2
3
```

as expected.

---

# 120. Test — failure with all clues known

Failure:

- no invalid index;
- cooldown still applied;
- result says no new clue.

---

# 121. Test — actor disappears

After failure:

```text
GirlActor hidden
collision disabled
interaction disabled
```

---

# 122. Test — cooldown blocks

While remaining >0:

```text
begin attempt => COOLDOWN
```

---

# 123. Test — day decrement

Cooldown 3.

After one:

```text
2
```

after second:

```text
1
```

after third:

```text
0
```

---

# 124. Test — return signal

Transition:

```text
1 → 0
```

emits available-again once.

Actor visible again.

---

# 125. Test — scene reload cooldown

Instantiate actor while cooldown 2.

It starts hidden immediately.

---

# 126. Test — same girl remains same

After cooldown:

- same girl_id;
- same definition;
- same appearance profile;
- known clues preserved.

---

# 127. Test — contact clears cooldown

Simulate/ensure contact acquisition:

```text
remaining = 0
```

---

# 128. Test — phone only discovered

ContentDB may contain two test girls.

Only one discovered.

Phone lists one.

---

# 129. Test — phone contact state

Before number:

```text
Номера нет
```

After success:

```text
Номер получен
```

---

# 130. Test — phone clues

Only known clue indices displayed.

Unknown text not leaked.

---

# 131. Test — trait hidden

Before explicit reveal:

Phone does not show actual primary trait.

---

# 132. Test — trait reveal

Call:

```text
reveal_primary_trait(girl_id)
```

Phone then shows:

- trait display name;
- liked tags;
- disliked tags.

---

# 133. Test — known reaction API

Record:

```text
source_id
reaction = -1/0/+1
```

Query returns exact values.

Invalid:

```text
reaction = 2
```

rejected.

---

# 134. Test — discovery does not record fake trait reaction

SUCCESS/FAILURE alone should not create primary trait reaction records.

---

# 135. Test — no relationship mutation

Static/integration:

MODULE 08 code does not call normal relationship change API during discovery result.

---

# 136. Test — no Experience mutation

MODULE 08 never calls:

```text
add_experience
```

---

# 137. Test — no conquest

MODULE 08 never calls:

```text
mark_girl_conquered
```

---

# 138. Test — Phone control mode

Open:

```text
MODAL_UI
mouse visible
```

Close:

previous mode restored.

---

# 139. Test — no phone hotkey required

No new permanent Input Map action solely for Phone in MODULE 08.

---

# 140. Test — ContentDB validation

Discovery definitions validated and indexed.

Existing MODULE 03 counts/content remain valid.

---

# 141. Test — Character regression

GirlActor uses Character Framework cleanly.

No changes to CharacterActor gameplay responsibilities.

---

# 142. Test — Progression regression

Good Profile ownership read works.

MODULE 05 tests remain PASS.

---

# 143. Test — Rival/minigame regressions

MODULE 06 + 07A/B/C/D remain PASS.

Girl systems do not alter Runner/Rival code.

---

# 144. Test — FPS regression

Movement/interaction/control modes continue PASS.

---

# 145. Runtime location dependency

MODULE 08 may reference:

```text
LocationDefinition.id
```

but does not implement:

- scene transitions;
- location unlocking;
- world loading.

MODULE 12 owns these.

---

# 146. Fixed situation world boundary

MODULE 08 provides:

- definitions;
- GirlActor;
- test scene.

MODULE 14 later creates actual production fixed situation scenes.

Не создавать сейчас полноразмерный city hub.

---

# 147. Story girls

Reserved story girl IDs remain reserved.

Не создавать real neighbor/actress content merely to test system.

Use test IDs.

---

# 148. Phone Journal is functional, not final

MODULE 22 later does:

- final layout;
- consistent phone shell;
- animation;
- icons;
- navigation;
- accessibility;
- unified HUD integration.

MODULE 08 UI only must be:

- readable;
- usable;
- correct.

---

# 149. No messaging

MODULE 08 does not implement:

- SMS;
- incoming messages;
- chat;
- girl initiation;
- media feed.

MODULE 15 later expands phone.

---

# 150. No call scheduling

Number obtained does NOT imply:

```text
call girl
choose date time
book restaurant
```

MODULE 09 decides how date starts.

---

# 151. Documentation updates

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
```

В perk contract уточнить actual MODULE 08 implementation:

```text
APPEARANCE_GOOD_PROFILE
→ second initial clue revealed if available
```

---

# 152. GDD consistency

Не менять product meaning.

Проверить, что docs явно продолжают говорить:

```text
same girl returns after 1–3 days
Experience gate visible
no new girl on failure
```

---

# 153. Что MODULE 08 НЕ реализует

Категорически не реализовывать:

- Dating session;
- greeting;
- 3 central events;
- farewell;
- action tags;
- primary trait scoring;
- secondary trait scoring;
- relationship delta;
- relationship clamp;
- +5 completion;
- Experience earning;
- Upgrade Point earning;
- date cooldown;
- date scheduling;
- restaurant scene;
- story stage progression;
- quest system;
- city generation;
- NPC schedules;
- phone messaging;
- media feed;
- production girl content.

---

# 154. Definition of Done

MODULE 08 завершён только если:

- [ ] DiscoverySituationDefinition существует;
- [ ] DiscoveryApproachDefinition существует;
- [ ] authored SUCCESS/FAILURE работает;
- [ ] approach requirements visible;
- [ ] ContentDB indexes/validates discovery situations;
- [ ] GirlDefinition situation references validate;
- [ ] production girls не наполнены раньше MODULE 14;
- [ ] discovered girls persistent runtime state;
- [ ] contacts persistent runtime state;
- [ ] known clue indices persistent runtime state;
- [ ] primary trait reveal state существует;
- [ ] known reaction seam существует;
- [ ] retry cooldown days persistent;
- [ ] first sight reveals clue 0;
- [ ] Good Profile reveals additional initial clue;
- [ ] Experience gate works and is visible;
- [ ] low Experience does not count as failure;
- [ ] success adds number only;
- [ ] success does not change relationship/Experience;
- [ ] failure reveals next clue;
- [ ] failure cooldown exact 1–3 days;
- [ ] deterministic test RNG;
- [ ] day-advance seam works;
- [ ] no full clock system created;
- [ ] same GirlActor returns;
- [ ] actor hidden during cooldown;
- [ ] GirlActor uses Character Framework;
- [ ] phone lists only discovered girls;
- [ ] phone distinguishes number/no number;
- [ ] phone shows only known clues;
- [ ] primary trait hidden until reveal;
- [ ] revealed primary trait shows liked/disliked rules;
- [ ] phone reactions section supported;
- [ ] no Dating button/flow implemented;
- [ ] Phone uses MODAL_UI;
- [ ] no permanent phone hotkey invented;
- [ ] MODULE 02–07 regressions pass;
- [ ] FPS regression passes;
- [ ] MODULE 09 not implemented ahead.

---

# 155. Порядок выполнения Cursor

## Step 1 — Audit

Изучить фактические:

```text
GirlDefinition
ContentDB
GameState
CharacterActor
Interactable
Progression/PerkIds
Player control mode
```

---

## Step 2 — Static discovery data

Добавить:

```text
DiscoverySituationDefinition
DiscoveryApproachDefinition
DiscoveryApproachOutcome
```

и validation.

---

## Step 3 — Extend GameState

Добавить persistent:

```text
discovered girls
contacts
known clues
primary trait reveal
known reactions
retry days remaining
```

с clean APIs/reset.

---

## Step 4 — GirlDiscovery service

Реализовать:

```text
discover
begin attempt
resolve approach
success
failure
day advance
availability
```

без `_process`.

---

## Step 5 — Good Profile

Реализовать только discovery effect этого perk.

---

## Step 6 — GirlActor

Thin CharacterActor + Interactable + proximity discovery.

---

## Step 7 — Phone Journal

Functional read-only journal/contact UI.

No Dating actions.

---

## Step 8 — Test fixtures

Создать isolated girls/situations вне production catalog.

---

## Step 9 — Tests

Прогнать sections 107–144.

---

## Step 10 — Regressions

Все MODULE 02–07 + FPS.

---

## Step 11 — Docs

Обновить architecture/perk contracts/project structure.

---

# 156. Формат финального отчёта Cursor

## Architecture

Как разделены:

```text
ContentDB
GameState
GirlDiscovery
GirlActor
PhoneJournal
```

## Discovery content

Как устроены Situation/Approach definitions.

## Runtime state

Перечислить новые persistent fields/API.

## Acquaintance flow

Подтвердить:

```text
seen
→ clue
→ Experience gate
→ authored choice
→ number OR cooldown
```

## Cooldown

Подтвердить:

```text
1–3 game-day advances
same girl returns
no full clock created
```

## Perk

Подтвердить actual:

```text
Good Profile → second initial clue
```

## Phone

Подтвердить:

- discovered only;
- contact status;
- clues;
- hidden/revealed primary trait;
- reaction seam;
- no Dating action.

## Validation

MODULE 08 tests + previous regressions.

## Files changed

Основные файлы.

## Product questions

Только реальные вопросы, которые невозможно решить технически.

Если нет:

```text
None.
```

---

# 157. Запрет продолжения

После успешного MODULE 08:

**НЕ начинать MODULE 09 — Dating Core.**

Остановиться и дождаться отдельной спецификации.
