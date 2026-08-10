# MODULE 02 — CORE GAME STATE

**Проект:** Date Factory  
**Модуль:** 02 — Core Game State  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** создать единственное каноническое runtime-состояние текущего прохождения без реализации игровых систем, которые изменяют это состояние  
**Продуктовый источник истины:** `docs/MASTER_GDD.md` и `docs/gdd/*`  
**Технический план:** `docs/TECH_PLAN.md` / соответствующий подробный technical plan  
**Предыдущий модуль:** MODULE 01 — Player FPS Core

---

# 0. PRE-FLIGHT: две правки MODULE 01

Перед реализацией Game State исправить два небольших технических долга FPS Core.

## 0.1. Air control

Сейчас горизонтальное ускорение в воздухе фактически такое же, как на земле.

Исправить так, чтобы:

- на земле сохранялось текущее отзывчивое управление;
- в воздухе направление можно было корректировать;
- нельзя было почти мгновенно развернуть горизонтальную скорость на 180°;
- отсутствие input в воздухе не должно искусственно резко тормозить игрока.

Рекомендуемый default:

```text
air_acceleration ≈ 8.0 м/с²
```

Допустим небольшой диапазон вокруг этого значения после ручной проверки feel.

Не добавлять отдельную механику air movement.

---

## 0.2. Step-up safety

Текущий step-up передвигает `global_position.y` напрямую после ray-проверок.

Сохранить простую систему ступеней, но перед фактическим подъёмом убедиться, что **полный collider игрока может безопасно занять новую позицию**.

Cursor самостоятельно выбирает best-practice способ текущего Godot:

- `test_move`;
- body motion test;
- shape query;
- другой стандартный безопасный вариант.

Не строить сложный traversal controller.

После исправлений повторно проверить MODULE 01 stairs/slope smoke tests.

Эти исправления сделать отдельной маленькой частью того же следующего commit либо отдельным commit перед MODULE 02.

---

# 1. Цель MODULE 02

Создать минимальную систему, которая является **единственным источником истины о текущем прохождении**.

Game State хранит:

- текущую сюжетную стадию;
- Деньги;
- Авторитет;
- Покоренных сердец;
- Баллы прокачки;
- четыре характеристики героя;
- отношения с конкретными девушками;
- список уже покорённых девушек;
- открытые локации;
- простые сюжетные флаги;
- поздние числовые показатели клонов.

Game State:

- хранит значения;
- защищает базовые инварианты;
- сообщает об изменениях;
- предоставляет маленький публичный API.

Game State НЕ решает:

- почему игрок получил ресурс;
- сколько должна дать конкретная победа;
- доступен ли конкретный соперник;
- доступна ли конкретная девушка;
- стоимость конкретного перка;
- правила свидания;
- правила стадийного квеста;
- формулу зарплаты;
- формулу производства клонов;
- баланс.

Эти правила принадлежат будущим модулям.

---

# 2. Главный архитектурный принцип

В проекте должен существовать **один canonical runtime Game State**.

Любая система позже должна читать основные значения из него, а не создавать собственные параллельные копии:

```text
Dating.money
Rivals.authority
Phone.experience
Mine.player_money
```

так делать нельзя.

Canonical state должен быть доступен всем крупным gameplay-модулям без поиска Node по всему SceneTree.

---

# 3. Техническое решение: ответственность Cursor

Cursor должен самостоятельно проанализировать лучший способ реализации canonical state для маленькой single-player Godot 4.x игры.

Основные разумные варианты:

1. один gameplay Autoload `GameState`;
2. небольшой Autoload-владелец + отдельный serializable state object/resource;
3. root-owned state с явной передачей зависимостей.

Требования выбора:

- простой доступ будущих независимых систем;
- минимум boilerplate;
- отсутствие Service Locator;
- отсутствие dependency injection framework;
- удобство будущего Save/Load;
- удобство тестирования/reset;
- одно место истины;
- отсутствие UI/domain coupling.

Для текущего масштаба проекта **один небольшой `GameState` autoload является допустимым и ожидаемо разумным решением**, но Cursor обязан кратко сравнить варианты и выбрать лучший после анализа текущего проекта и best practices.

Выбор зафиксировать в:

```text
docs/TECHNICAL_DECISIONS.md
```

Не использовать donor Game singleton как архитектурный шаблон.

---

# 4. Donor

MODULE 02 не требует переноса старого Game State.

Cursor должен кратко посмотреть legacy state только как anti-pattern/reference:

```text
../date_factory_legacy
```

Нужно понять:

- какие старые системы были сцеплены с `Game`;
- какие ошибки новой версии нельзя повторять.

Из donor НЕ копировать:

- старый `Game`;
- economy state;
- bond;
- trait data;
- clone QA;
- old stage state;
- old save model;
- staff;
- crises;
- old upgrades.

Ожидаемый результат donor analysis для MODULE 02:

```text
reference only, no copied gameplay state
```

если не найден действительно нейтральный технический helper.

---

# 5. Canonical code terminology

Внутренние identifier names для основных продуктовых показателей зафиксировать так:

| Игровой термин | Canonical code identifier |
|---|---|
| Деньги | `money` |
| Авторитет | `authority` |
| Покоренных сердец | `experience` |
| Баллы прокачки | `upgrade_points` |
| Мышца | `muscle` |
| Внешность | `appearance` |
| Капитал | `capital` |
| Аура | `aura` |

Не придумывать альтернативы:

- `cash`;
- `respect`;
- `romance_xp`;
- `skill_tokens`;
- `looks`;
- `wealth`;
- `charisma`.

В пользовательском UI позже используются русские канонические названия из GDD.

---

# 6. Canonical stage model

Использовать следующую последовательность:

```text
PROLOGUE
STAGE_1
STAGE_2
STAGE_3
STAGE_4
STAGE_5
STAGE_6
FINALE
```

Смысл:

```text
PROLOGUE — Соседка
STAGE_1  — Актриса
STAGE_2  — Начальница шахты
STAGE_3  — Редактор журнала
STAGE_4  — Учёная
STAGE_5  — Президент
STAGE_6  — Мировое расширение
FINALE   — финальное внеземное свидание
```

Начальное значение новой игры:

```text
PROLOGUE
```

Предпочтительно использовать enum с явными стабильными numeric values:

```text
PROLOGUE = 0
STAGE_1 = 1
...
STAGE_6 = 6
FINALE = 7
```

Не хранить стадию строкой `"stage_4_scientist"`.

Конкретное место объявления enum — техническое решение Cursor.

---

# 7. Деньги (`money`)

Тип:

```text
int
```

Начальное значение:

```text
0
```

Инвариант:

```text
money >= 0
```

Game State должен предоставлять операции семантически уровня:

```text
get_money()
add_money(amount)
can_afford(amount)
spend_money(amount) -> bool
```

Точные GDScript method names можно оформить идиоматично, но смысл должен совпадать.

## `add_money`

- принимает только положительное количество;
- увеличивает баланс;
- сообщает об изменении.

Нулевое значение может быть no-op.

Отрицательное значение считается programmer error, а не скрытым способом потратить деньги.

## `spend_money`

- amount должен быть `>= 0`;
- если денег хватает — списывает и возвращает `true`;
- если не хватает — ничего не меняет и возвращает `false`;
- баланс никогда не уходит в минус.

Не создавать кредиты, долг или отрицательные деньги.

---

# 8. Авторитет (`authority`)

Тип:

```text
int
```

Начальное значение:

```text
0
```

Инвариант:

```text
authority >= 0
```

В текущем Master GDD Авторитет:

- постоянный;
- нерасходуемый;
- в первую очередь растёт от побед над самцами;
- влияет на доступ к соперникам и зарплатный уровень;
- не запускает стадии напрямую.

В MODULE 02 реализовать только:

```text
get_authority()
add_authority(amount)
```

Не реализовывать:

- формулу gain;
- loss;
- rank;
- salary mapping;
- rival requirements.

`add_authority` принимает положительное значение.

**Не добавлять `spend_authority()`.**

Если будущая подробная Rival-спецификация действительно потребует уменьшение Авторитета, это должно быть отдельным явным продуктовым решением, а не скрытым API MODULE 02.

---

# 9. Покоренных сердец (`experience`)

Тип:

```text
int
```

Начальное значение:

```text
0
```

Инвариант:

```text
experience >= 0
```

Покоренных сердец:

- постоянная;
- нерасходуемая;
- не уменьшается;
- в ручной игре обычно растёт на `+1` за новую успешно покорённую девушку;
- позднее может расти массово от автоматизированного потока.

Game State должен предоставлять:

```text
get_experience()
add_experience(amount)
```

---

# 10. Критический инвариант: Покоренных сердец → Баллы прокачки

Master GDD задаёт:

```text
каждый +1 «Покоренных сердец»
=
+1 Балл прокачки
```

Поэтому `add_experience(amount)` должен атомарно:

1. увеличить `experience` на `amount`;
2. увеличить `upgrade_points` на такой же `amount`;
3. отправить соответствующие notifications/signals.

Нельзя полагаться на внешний модуль, который «не забудет» отдельно вызвать:

```text
add_experience(1)
add_upgrade_points(1)
```

Эта связь является core invariant и должна жить внутри Game State.

Пример:

```text
до:
experience = 7
upgrade_points = 2

add_experience(3)

после:
experience = 10
upgrade_points = 5
```

Потраченные ранее Баллы прокачки не восстанавливаются.

---

# 11. Баллы прокачки (`upgrade_points`)

Тип:

```text
int
```

Начальное значение:

```text
0
```

Инвариант:

```text
upgrade_points >= 0
```

Обычный источник появления:

```text
add_experience()
```

Публичный gameplay API не должен позволять произвольно начислять Баллы прокачки без Опытности.

Допустим внутренний/private restore API для будущего Save/Load, но не gameplay-command.

Нужны операции:

```text
get_upgrade_points()
can_spend_upgrade_points(amount)
spend_upgrade_points(amount) -> bool
```

Логика аналогична Деньгам:

- при достаточном количестве списать;
- иначе не менять;
- никогда не уходить ниже нуля.

---

# 12. Стоимость перков НЕ реализуется здесь

Последовательность:

```text
1 → 3 → 9 → 27 → 81 → ...
```

является частью Progression & Perks.

MODULE 02 НЕ реализует:

- формулу стоимости;
- purchased perk count;
- perk IDs;
- perk tree;
- prerequisites.

Game State только хранит расходуемые `upgrade_points`.

MODULE 05 будет использовать Game State API.

---

# 13. Характеристики героя

Canonical characteristics:

```text
muscle
appearance
capital
aura
```

Тип каждой:

```text
int
```

Начальные значения:

```text
0
```

Ручной дизайн ориентируется на диапазон:

```text
0..10
```

В MODULE 02 хранить именно числовые значения.

Не реализовывать:

- способы повышения;
- перки;
- проверки конкретных активностей;
- bonuses;
- minigame difficulty;
- unlocks.

---

# 14. Characteristic API

Создать минимальный API чтения.

Можно использовать:

```text
get_muscle()
get_appearance()
get_capital()
get_aura()
```

либо идиоматичные read-only properties.

Мутация характеристик будет принадлежать MODULE 05.

Чтобы MODULE 05 мог менять значения без прямой записи в private fields, предусмотреть маленький controlled mutation API.

Предпочтительный смысл:

```text
set_characteristic(characteristic, value)
```

или четыре узких setter-а.

Но нельзя придумывать generic RPG Stat framework.

Если используется enum характеристики, canonical enum names:

```text
MUSCLE
APPEARANCE
CAPITAL
AURA
```

Не добавлять другие характеристики.

---

# 15. Диапазон характеристик

Для обычной ручной игры валидировать:

```text
0 <= characteristic <= 10
```

Пока GDD описывает `0–10` как ориентировочный диапазон.

Чтобы не закрыть будущий баланс намертво:

- default runtime должен соблюдать 0–10;
- если Cursor считает hard clamp потенциально вредным для поздней игры, выбрать best-practice решение и документировать;
- НЕ позволять случайно получать отрицательные уровни.

MODULE 05 сможет уточнить правила диапазона.

---

# 16. Отношения с девушками

Game State должен хранить integer relationship score по `girl_id`.

Canonical conceptual structure:

```text
girl_relationships:
    girl_id -> relationship_score
```

`girl_id`:

```text
StringName
```

или другой стабильный lightweight ID-тип, который MODULE 03 сможет использовать напрямую.

Не использовать:

- Node reference;
- scene path как identity;
- display name девушки как identity.

MODULE 03 окончательно задаст content IDs, поэтому Game State сейчас воспринимает ID как opaque stable key.

---

# 17. Relationship score

Тип:

```text
int
```

Default для неизвестного ID:

```text
0
```

Отношения могут потенциально:

- увеличиваться;
- уменьшаться;
- быть отрицательными.

Поэтому MODULE 02 не clamp-ит их к `0`.

Порог:

```text
+5
```

является правилом MODULE 10.

MODULE 02 не должен автоматически считать девушку покорённой при значении `>= 5`.

Это сделает Relationship/Completion system, потому что там находятся награды, защита от double reward и сюжетные side-effects.

---

# 18. Relationship API

Минимально:

```text
get_girl_relationship(girl_id) -> int
set_girl_relationship(girl_id, value)
add_girl_relationship(girl_id, delta)
```

Точные имена могут быть слегка адаптированы к code style.

Требования:

- пустой/невалидный ID отклоняется;
- изменение конкретной девушки уведомляется отдельно;
- Game State не знает черту девушки;
- Game State не знает dating result;
- Game State не знает, почему delta такой.

---

# 19. Покорённые девушки

Хранить отдельный set-like список стабильных `girl_id`:

```text
conquered_girls
```

Смысл:

> девушка уже однажды завершена как новая уникальная девушка и её одноразовая основная награда не должна выдаваться повторно.

Это не «список собственности», а чистый completion flag.

Техническое представление:

- dictionary-as-set;
- typed array с контролем уникальности;
- другой простой вариант

— выбирает Cursor.

Публичный смысл:

```text
is_girl_conquered(girl_id) -> bool
mark_girl_conquered(girl_id) -> bool
```

`mark_girl_conquered`:

- возвращает `true`, только если ID был добавлен впервые;
- повторный вызов не создаёт дубликат и возвращает `false`.

**Он НЕ должен сам начислять «Покоренных сердец».**

Атомарную цепочку:

```text
relationship completion
→ mark conquered
→ +experience
```

реализует MODULE 10.

Это не переносить в low-level state storage.

---

# 20. Открытые локации

Хранить set-like список:

```text
unlocked_locations
```

ID:

```text
StringName
```

Game State не знает:

- где находится сцена;
- почему локация открылась;
- на какой стадии она нужна;
- требования к входу.

Минимальный API:

```text
is_location_unlocked(location_id)
unlock_location(location_id) -> bool
```

Повторный unlock:

- no-op;
- возвращает `false`.

Первый unlock:

- добавляет ID;
- возвращает `true`;
- отправляет notification.

Начальный набор локаций в MODULE 02:

```text
empty
```

Потому что фактическую стартовую квартиру/зоны назначит Story/World module.

Не придумывать `"home"` автоматически.

---

# 21. Story flags

Нужен простой контейнер булевых сюжетных фактов:

```text
story_flags
```

ID:

```text
StringName
```

Использование в будущем:

```text
story_rival_defeated
media_photo_done
lab_opened
...
```

Но MODULE 02 НЕ создаёт реальные flag names.

Начальное состояние:

```text
empty
```

Минимальный API:

```text
get_story_flag(flag_id) -> bool
set_story_flag(flag_id, value: bool)
```

Не строить:

- QuestState framework;
- hierarchical flags;
- tag queries;
- conditions DSL;
- event scripting language.

---

# 22. Current stage storage

Хранить:

```text
current_stage
```

Default:

```text
PROLOGUE
```

Game State не решает, когда стадия завершена.

Нужен controlled API для изменения стадии.

Требования:

- значение должно быть валидным Stage enum;
- отправлять `stage_changed`;
- не иметь автоматических side-effects;
- не открывать локации;
- не давать деньги;
- не запускать cutscene.

Story Module позже вызывает stage transition и отдельно выполняет нужные последствия.

---

# 23. Stage monotonicity

Основная игра линейно движется вперёд.

Обычный gameplay не должен уменьшать stage.

Рекомендуемый публичный API:

```text
advance_stage(next_stage) -> bool
```

Правила:

- `next_stage` должен быть ровно следующей стадией;
- нельзя прыгнуть назад;
- нельзя случайно перепрыгнуть несколько стадий.

Для будущего Save/Load нужен отдельный restore path, который может напрямую восстановить сохранённую стадию без gameplay transition rules.

MODULE 02 не реализует Save/Load, но архитектура не должна делать его невозможным.

Если Cursor выбирает другой технический API с теми же гарантиями — документировать.

---

# 24. Late-game clone metrics

Game State должен заранее иметь минимальное место для поздних чисел, указанных в technical plan и GDD.

Canonical fields:

```text
total_clones
clones_working
clones_dating
money_per_minute
dates_per_minute
```

Важно:

- `money_per_minute` и `dates_per_minute` — показатели;
- это НЕ отдельные spendable resources;
- свободные клоны являются производным числом.

Не создавать поле:

```text
free_clones
```

как отдельный источник истины.

---

# 25. Clone counts

Тип:

```text
int
```

Начально:

```text
total_clones = 0
clones_working = 0
clones_dating = 0
```

Инварианты:

```text
total_clones >= 0
clones_working >= 0
clones_dating >= 0

clones_working + clones_dating <= total_clones
```

Производное:

```text
free_clones =
total_clones - clones_working - clones_dating
```

Game State может предоставлять getter:

```text
get_free_clones()
```

но не хранить третью mutable копию.

---

# 26. Late rates

Canonical:

```text
money_per_minute
dates_per_minute
```

Тип:

```text
float
```

Default:

```text
0.0
```

Инвариант:

```text
>= 0.0
```

MODULE 02 только хранит текущие рассчитанные значения.

Не реализовывать:

- ticking;
- начисление money per second;
- date production;
- offline progress;
- multipliers;
- clone efficiency.

MODULE 18 будет владельцем расчёта и обновления этих rates.

---

# 27. Late Experience

GDD разрешает позднее массовое начисление Опытности.

Поэтому:

```text
experience
upgrade_points
money
clone counts
```

не должны иметь маленьких искусственных caps.

Использовать обычный 64-bit integer Godot/GDScript.

Не внедрять:

- BigInt;
- scientific number library;
- prestige system.

Если поздний баланс приблизится к пределу int64, это решается позже, а не сейчас.

---

# 28. Signals / notifications

Game State может и должен уведомлять consumers о фактических изменениях.

Canonical event semantics:

```text
money_changed
authority_changed
experience_changed
upgrade_points_changed

characteristic_changed

girl_relationship_changed
girl_conquered

location_unlocked
story_flag_changed
stage_changed

clone_counts_changed
late_rates_changed

state_reset
```

Не обязательно использовать именно десять отдельных signals, если Cursor найдёт более чистый простой вариант.

Но запрещено заменять это универсальным:

```text
state_changed(key, value)
```

для всего проекта.

Причина:

- теряется типизация;
- появляются magic strings;
- UI и gameplay начинают подписываться на неизвестные ключи.

Также запрещён global EventBus.

Signals принадлежат самому Game State.

---

# 29. Signal payloads

Signals должны содержать достаточно информации, чтобы UI позже не был вынужден угадывать изменение.

Пример semantics:

```text
money_changed(new_value, delta)
authority_changed(new_value, delta)
experience_changed(new_value, delta)
upgrade_points_changed(new_value, delta)

girl_relationship_changed(girl_id, new_value, delta)
story_flag_changed(flag_id, value)
stage_changed(new_stage, previous_stage)
```

Точные signatures Cursor выбирает при реализации, сохраняя понятность и типизацию.

---

# 30. Direct field mutation

Крупные gameplay-системы не должны делать:

```text
GameState.money -= price
GameState.experience += 1
GameState.clones_working += 10
```

Изменения должны идти через controlled API, чтобы:

- сохранялись invariants;
- отправлялись signals;
- не появлялись отрицательные значения;
- связь Experience → Upgrade Points была гарантирована.

Технически поля могут быть visible внутри script, но external code должен использовать API.

Зафиксировать этот принцип в `PROJECT_STRUCTURE.md` или module docs.

---

# 31. Reset / New Game

Нужен единый метод:

```text
reset_for_new_game()
```

или эквивалент.

Он возвращает ВСЁ runtime-state в canonical defaults:

```text
stage = PROLOGUE

money = 0
authority = 0
experience = 0
upgrade_points = 0

muscle = 0
appearance = 0
capital = 0
aura = 0

girl_relationships = empty
conquered_girls = empty
unlocked_locations = empty
story_flags = empty

total_clones = 0
clones_working = 0
clones_dating = 0
money_per_minute = 0.0
dates_per_minute = 0.0
```

После reset:

- состояние целостно;
- consumers могут получить notification;
- старые dictionary/set references не должны оставлять невидимые данные.

---

# 32. Starting content НЕ задаётся здесь

MODULE 02 intentionally resets world/content lists to empty.

Не добавлять:

```text
unlock_location("apartment")
story_flag("tutorial_started")
money = 100
```

потому что это продуктовые значения стартовой последовательности.

Их задаст Story/New Game bootstrap после соответствующей спецификации.

---

# 33. Save/Load boundary

MODULE 02 НЕ реализует:

- запись файлов;
- JSON;
- binary save;
- slots;
- autosave;
- version migration.

Но state architecture должна позволять MODULE 24:

- получить полный snapshot;
- восстановить полный snapshot;
- валидировать данные.

Cursor может предусмотреть небольшой internal representation для export/import state, только если это естественно и не превращается в save system.

Не создавать сейчас:

```text
SaveManager
SaveFile
SaveSlot
save_game()
load_game()
```

---

# 34. Data Layer boundary

MODULE 03 будет описывать content data.

Поэтому MODULE 02:

- не загружает girl definitions;
- не загружает rival definitions;
- не проверяет существование location ID в Content DB;
- не знает display names;
- не хранит `Resource` конкретной девушки;
- не знает perk definitions.

IDs пока opaque.

После MODULE 03 валидация content IDs может быть добавлена владельцами соответствующих систем.

---

# 35. Player boundary

`PlayerController` и `GameState` — разные сущности.

Player FPS Core не должен становиться владельцем:

- money;
- stage;
- characteristics;
- relationship.

Game State не должен управлять:

- velocity;
- camera;
- interaction ray;
- control mode.

Не добавлять `GameState` child внутрь `Player`.

---

# 36. UI boundary

MODULE 02 не создаёт gameplay HUD.

Для тестирования разрешён маленький debug/state test panel.

UI не должен быть владельцем данных.

Правильное направление:

```text
UI reads GameState
UI requests public mutation through feature systems
```

а не:

```text
Button owns money
Label text parsed back into state
```

---

# 37. Debug/test API

Для разработки нужен удобный способ проверить состояние.

Допустимо:

- debug-only test scene;
- debug methods;
- simple state dump.

Не создавать полноценную cheat console.

Если создаётся state dump:

- только debug build;
- читаемый;
- не используется gameplay-кодом.

---

# 38. Invalid input behavior

Programmer errors должны быть заметны.

Примеры:

```text
add_money(-5)
add_experience(-1)
spend_upgrade_points(-3)
set empty girl_id
assign 12 working clones when total=10
```

Не нужно silently clamp-ить любую ошибку и делать вид, что всё хорошо.

Cursor должен выбрать разумный Godot подход:

- `assert` для dev invariants;
- `push_error`;
- safe return;
- комбинация.

Главное:

- release не ломает save/state;
- debug ясно показывает проблему;
- state после ошибки остаётся валидным.

---

# 39. Atomic updates

Операции, которые логически являются одним изменением, должны быть атомарными.

Главный обязательный пример:

```text
add_experience(N)
```

не должен создавать промежуточное видимое состояние:

```text
experience increased
upgrade_points still old
```

После завершения call оба значения должны быть согласованы.

Signals могут быть отправлены последовательно, но внешние getters уже должны видеть итоговое целостное state.

---

# 40. No derived duplicate state

Не хранить mutable значения, которые можно однозначно вычислить:

```text
free_clones
total_relationships
total_unlocked_locations
current_salary_rank
can_enter_stage_3
can_afford_x
```

Первые три можно получать getter-ами при необходимости.

Salary rank и eligibility принадлежат будущим системам.

---

# 41. No generic blackboard

`story_flags` — единственный разрешённый маленький generic bool container для постановочных story facts.

Не превращать Game State в:

```text
Dictionary everything = {}
```

Основные показатели обязаны оставаться typed explicit fields.

Не хранить core resources в `story_flags`.

---

# 42. No gameplay formulas

MODULE 02 НЕ должен содержать:

```text
salary = authority * ...
rival_requirement = ...
girl_requirement = ...
perk_cost = ...
date_score = ...
clone_income = ...
```

Даже если формулы кажутся очевидными.

Он только предоставляет данные будущим системам.

---

# 43. No timers

Game State не должен иметь `_process()` или `_physics_process()` для:

- денег;
- клонов;
- свиданий;
- прогрессии.

Состояние изменяется по явным командам feature-систем.

Поздний incremental ticker появится в MODULE 18.

Если GameState может существовать вообще без frame processing — это предпочтительно.

---

# 44. File placement

Canonical destination:

```text
res://game/state/
```

Создать эту feature area, если её ещё нет.

Ожидаемый минимальный набор зависит от выбранной техники.

Например:

```text
game/state/game_state.gd
game/state/game_stage.gd
```

либо один компактный файл, если это чище.

Не плодить:

```text
money_manager.gd
authority_manager.gd
experience_manager.gd
relationship_manager.gd
clone_manager.gd
```

Все они были бы искусственным раздроблением простого state container.

---

# 45. Autoload naming

Если выбран autoload:

```text
GameState
```

Имя фиксировано.

Не использовать:

```text
Global
Game
StateManager
GlobalState
PlayerDataManager
```

`GodotIQRuntime` остаётся отдельным техническим autoload.

---

# 46. Integration with current main

После MODULE 02 текущий FPS test world должен продолжать запускаться.

Не менять его на новую gameplay scene.

Добавить проверку Game State в существующий test flow минимально.

Например debug-only state test можно:

- запускать отдельной test scene;
- запускать headless script;
- проверять через небольшой temporary test node.

Cursor выбирает простой подход.

Не превращать FPS HUD в permanent state HUD.

---

# 47. Required state tests

Нужны автоматизированные или легко воспроизводимые tests основных invariants.

Точный test framework Cursor выбирает сам.

Не подключать тяжёлый third-party testing addon без необходимости.

---

# 48. Test — Defaults

После `reset_for_new_game()`:

```text
stage == PROLOGUE

money == 0
authority == 0
experience == 0
upgrade_points == 0

muscle == 0
appearance == 0
capital == 0
aura == 0

relationships empty
conquered girls empty
locations empty
story flags empty

total clones == 0
working == 0
dating == 0
free == 0

money/min == 0
dates/min == 0
```

---

# 49. Test — Money

```text
add_money(100)
=> 100

can_afford(60)
=> true

spend_money(60)
=> true
money => 40

spend_money(50)
=> false
money remains 40
```

---

# 50. Test — Experience invariant

```text
experience = 0
upgrade_points = 0

add_experience(3)

experience == 3
upgrade_points == 3
```

Затем:

```text
spend_upgrade_points(2)
upgrade_points == 1
experience == 3

add_experience(2)

experience == 5
upgrade_points == 3
```

---

# 51. Test — Authority

```text
add_authority(5)
=> authority == 5
```

Убедиться, что нет public `spend_authority`.

---

# 52. Test — Characteristics

Установить по test API:

```text
muscle = 2
appearance = 3
capital = 1
aura = 4
```

Проверить независимость значений и invalid negative input.

Не проверять gameplay effects.

---

# 53. Test — Relationships

```text
girl_id = &"test_girl"

initial => 0

add relationship +3
=> 3

add relationship -2
=> 1

set -4
=> -4
```

Никакой auto-conquer при `>=5`.

---

# 54. Test — Conquered set

```text
mark test_girl first time
=> true

is conquered
=> true

mark same again
=> false
```

Не начислять Experience автоматически.

---

# 55. Test — Location unlock

```text
unlock test_location
=> true

unlock same again
=> false

is unlocked
=> true
```

---

# 56. Test — Story flags

```text
unknown flag => false

set flag true
=> true

set false
=> false
```

---

# 57. Test — Stages

После reset:

```text
PROLOGUE
```

Проверить последовательное продвижение:

```text
PROLOGUE -> STAGE_1
```

Проверить, что обычный gameplay API не позволяет:

```text
STAGE_1 -> PROLOGUE
STAGE_1 -> STAGE_4
```

если выбран strict advance API.

---

# 58. Test — Clone invariants

Допустимое:

```text
total = 10
working = 4
dating = 3

free == 3
```

Недопустимое:

```text
working = 8
dating = 5
total = 10
```

State должен отклонить изменение и остаться валидным.

---

# 59. Test — Signals

Проверить, что:

- успешное изменение вызывает notification один раз;
- неуспешная spend-операция не делает ложный `money_changed`;
- повторный unlock не делает новый unlock event;
- `add_experience` корректно уведомляет об обоих изменениях;
- reset уведомляет предсказуемо.

---

# 60. Test — FPS regression

После pre-flight исправлений и MODULE 02:

- main scene запускается;
- FPS test открывается;
- movement работает;
- interaction работает;
- pause работает;
- никакой Game State integration не ломает Player.

---

# 61. Definition of Done

MODULE 02 считается завершённым, только если:

- [ ] исправлен air control MODULE 01;
- [ ] step-up получил collider-safe validation;
- [ ] FPS regression smoke tests пройдены;
- [ ] существует один canonical Game State;
- [ ] технический способ ownership задокументирован;
- [ ] `GameState` является autoload, если выбран autoload-подход;
- [ ] stage model содержит PROLOGUE, STAGE_1..6, FINALE;
- [ ] money реализован как расходуемый non-negative int;
- [ ] authority реализован как non-negative non-spendable int;
- [ ] experience реализован как non-negative persistent int;
- [ ] upgrade_points реализован как non-negative spendable int;
- [ ] `add_experience(N)` автоматически даёт `+N upgrade_points`;
- [ ] muscle / appearance / capital / aura существуют;
- [ ] relationship storage по girl_id существует;
- [ ] relationship может быть отрицательным;
- [ ] conquered girl set существует;
- [ ] unlocked location set существует;
- [ ] story flags существуют;
- [ ] current stage существует;
- [ ] clone counts существуют;
- [ ] free clones вычисляются, а не хранятся;
- [ ] money_per_minute и dates_per_minute существуют только как rates;
- [ ] нет passive ticker;
- [ ] нет salary formula;
- [ ] нет perk formula;
- [ ] нет content database;
- [ ] нет save/load;
- [ ] нет old Game singleton;
- [ ] нет EventBus;
- [ ] нет parallel resource copies;
- [ ] core state нельзя случайно сделать отрицательным там, где это запрещено;
- [ ] invalid mutations не повреждают state;
- [ ] reset_for_new_game возвращает все значения в defaults;
- [ ] required tests пройдены;
- [ ] donor не изменён;
- [ ] MODULE 03 не реализован заранее.

---

# 62. Порядок выполнения Cursor

## Step 1 — Read

Изучить:

- текущий Master GDD;
- `03_core_loop.md`;
- `04_male_status_system.md`;
- `07_story_clones_finale.md`;
- MODULE 00/01 specs;
- Technical Decisions;
- Project Structure;
- эту спецификацию.

---

## Step 2 — Fix MODULE 01 debt

Сначала выполнить раздел 0.

Запустить FPS regression.

Только после этого переходить к Game State.

---

## Step 3 — Audit donor state

Посмотреть legacy `Game`/state.

Не переносить его.

Кратко зафиксировать, какие coupling patterns намеренно не повторяются.

---

## Step 4 — Choose ownership architecture

Сравнить разумные варианты canonical Game State.

Выбрать best-practice вариант для текущего маленького Godot-проекта.

Не спрашивать пользователя о чисто техническом выборе, если можно принять качественное решение самостоятельно.

Записать decision.

---

## Step 5 — Implement core fields and APIs

Сначала:

- stage;
- money;
- authority;
- experience;
- upgrade points;
- characteristics.

Проверить tests.

---

## Step 6 — Implement ID-based collections

Добавить:

- relationships;
- conquered girls;
- unlocked locations;
- story flags.

Проверить tests.

---

## Step 7 — Implement late metrics

Добавить:

- clone counts;
- free clone getter;
- rates.

Без ticking.

Проверить invariants.

---

## Step 8 — Reset and notifications

Добавить canonical reset и signals.

Проверить atomicity.

---

## Step 9 — Full validation

Выполнить все tests разделов 48–60.

---

## Step 10 — Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
```

Добавить эту module spec в canonical `docs/modules/`, если пользователь передал файл извне.

Не изменять GDD по собственной инициативе.

---

# 63. Формат финального отчёта Cursor

## Pre-flight MODULE 01 fixes

Что исправлено в air control и step-up.

## Game State implementation

Какие canonical fields/API созданы.

## Technical decision

Какой ownership approach выбран и почему.

## Donor analysis

Что просмотрено и почему legacy state не переносился.

## Invariants

Кратко перечислить реально enforced invariants.

## Validation

Результаты всех state tests + FPS regression.

## Files changed

Основные файлы.

## Product questions

Только реальные нерешённые продуктовые вопросы.

Если нет:

```text
None.
```

---

# 64. Запрет продолжения

После успешного MODULE 02:

**НЕ начинать MODULE 03 — Content Data Layer.**

Остановиться и дождаться отдельной спецификации.
