# MODULE 03 — CONTENT DATA LAYER

**Проект:** Date Factory  
**Модуль:** 03 — Content Data Layer  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** создать типизированный, валидируемый и простой слой статического игрового контента без реализации механик, которые этот контент исполняют  
**Продуктовый источник истины:** `docs/MASTER_GDD.md` и `docs/gdd/*`  
**Технический план:** `docs/TECH_PLAN.md`  
**Предыдущий модуль:** MODULE 02 — Core Game State

---

# 1. Цель модуля

Создать единый data-driven фундамент, через который следующие модули будут получать описания:

- девушек;
- самцов-соперников;
- основных и дополнительных черт девушек;
- канонических тегов действий;
- событий свиданий;
- вариантов действий внутри событий;
- пулов событий;
- перков;
- типов мужских состязаний;
- сюжетных стадий;
- локаций.

MODULE 03 отвечает только за:

- типы данных;
- стабильные ID;
- хранение статического контента;
- загрузку статического контента;
- lookup по ID;
- валидацию;
- небольшой canonical seed-контент, который уже полностью определён GDD.

MODULE 03 НЕ исполняет игровые механики.

---

# 2. Ключевой принцип

Разделить:

```text
STATIC CONTENT
```

и

```text
RUNTIME STATE
```

## Static Content

То, что одинаково для всех новых прохождений:

- девушка имеет черту `Добрая`;
- соперник предпочитает пощёчины;
- перк называется `Карманное зеркало`;
- событие относится к категории `Событие пространства`;
- действие имеет теги `Риск` и `Конфликт`;
- локация имеет ID `salary_mine`.

Это MODULE 03.

## Runtime State

То, что меняется во время конкретного прохождения:

- отношения с конкретной девушкой = `3`;
- девушка уже покорена;
- у игрока 17 Авторитета;
- перк уже куплен;
- локация уже открыта;
- текущая стадия;
- количество денег.

Это `GameState` и будущие gameplay modules.

Static Content никогда не должен хранить runtime progress.

---

# 3. Что Cursor не имеет права придумывать

Cursor НЕ должен самостоятельно добавлять новые:

- характеристики героя;
- теги действий;
- основные черты девушек;
- дополнительные черты девушек;
- типы мужских состязаний;
- категории центральных событий свидания;
- сюжетные стадии;
- игровые ресурсы;
- виды наград;
- универсальные condition types;
- универсальные effect types;
- generic scripting DSL.

Cursor НЕ должен придумывать:

- имена сюжетных девушек;
- имена сюжетных соперников;
- финальное имя внеземной девушки;
- новые перки;
- новые локации сверх уже канонически описанных;
- конкретные обычные девушки;
- конкретные dating events для финального контента.

Если будущий content asset требует продуктового текста, которого ещё нет, его пока не создавать.

---

# 4. Что Cursor решает технически самостоятельно

Cursor должен самостоятельно выбрать технически лучший способ хранения данных после анализа:

- Godot custom `Resource` + `.tres`;
- другой нативный Godot data approach;
- способ регистрации и lookup;
- структуру файлов;
- typed arrays;
- validation hooks;
- editor-time vs startup validation.

Для текущего проекта ожидаемый и предпочтительный вариант:

> typed custom Godot Resources + явный каталог контента.

Причины:

- данные редактируются в Godot;
- хорошая типизация;
- ссылки на другие resources;
- нет необходимости писать parser;
- простой Git diff для небольшого количества content assets;
- удобно Cursor;
- нет внешней БД.

Если Cursor считает другой подход объективно лучше, он должен сравнить варианты и записать решение в `TECHNICAL_DECISIONS.md`.

Не использовать JSON/CSV только потому, что «data-driven обычно делают через JSON».

---

# 5. Donor

Legacy Content Data Layer не переносить.

Donor можно посмотреть только чтобы понять:

- какие старые content schemas были чрезмерно сложными;
- какие legacy IDs нельзя случайно вернуть;
- какие generic loaders могут быть технически полезны.

Ожидаемый результат:

```text
reference only
```

Не переносить:

- old girl definitions;
- old traits;
- bond;
- observations/hypotheses;
- trait influence;
- clone definitions;
- old upgrades;
- old quests;
- old content packs;
- old stage definitions.

---

# 6. Canonical content directory

Canonical root:

```text
res://data/
```

Рекомендуемая смысловая структура:

```text
res://data/
├── types/
├── definitions/
├── catalog/
├── content/
│   ├── traits/
│   ├── perks/
│   ├── competitions/
│   ├── locations/
│   ├── girls/
│   ├── rivals/
│   ├── dating_events/
│   ├── dating_pools/
│   └── stages/
└── test/
```

Точные подпапки Cursor может слегка адаптировать к выбранному Resource-подходу.

Не создавать отдельный runtime manager на каждую папку.

---

# 7. Stable IDs

Все static content entities используют:

```text
StringName
```

как canonical runtime ID.

ID:

- ASCII;
- lowercase;
- `snake_case`;
- не зависит от display name;
- после появления в committed content считается стабильным;
- не переименовывается без явной migration-причины.

Пример допустимого ID:

```text
girl_neighbor
rival_stage_1
date_event_window_table
perk_aura_silence_longer
salary_mine
```

Недопустимо:

```text
"Добрая девушка"
"Girl 1"
"newGirl"
"финальная версия 2"
```

---

# 8. ID prefixes

Для content types, где коллизия/читаемость реально полезна, использовать canonical prefixes:

```text
girl_*
rival_*
date_event_*
date_pool_*
perk_*
```

Location IDs остаются короткими:

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

Trait/tag/competition identity задаётся enum и не требует StringName ID для gameplay branching.

---

# 9. Shared enum ownership

MODULE 03 должен обеспечить **единственное canonical объявление** shared enums.

Нельзя иметь:

```text
GameState.Characteristic.MUSCLE
PerkDefinition.Characteristic.MUSCLE
DatingAction.Characteristic.MUSCLE
```

как три независимых enum.

Cursor должен технически решить, как вынести/переиспользовать shared types.

Допустимый best-practice вариант:

```text
GameTypes
ContentTypes
```

с небольшим количеством enum.

Если для этого нужно аккуратно вынести `Stage` и `Characteristic` из `GameState`, это разрешено.

Требования:

- публичное поведение MODULE 02 не ломается;
- значения Stage остаются `0..7`;
- тесты MODULE 02 продолжают проходить;
- не появляется огромный `Enums.gd` на всё будущее.

---

# 10. Canonical PlayerCharacteristic

Единственный enum:

```text
MUSCLE
APPEARANCE
CAPITAL
AURA
```

Соответствие UI:

```text
MUSCLE     = Мышца
APPEARANCE = Внешность
CAPITAL    = Капитал
AURA       = Аура
```

Не добавлять другие значения.

---

# 11. Canonical GameStage

Сохранить:

```text
PROLOGUE = 0
STAGE_1  = 1
STAGE_2  = 2
STAGE_3  = 3
STAGE_4  = 4
STAGE_5  = 5
STAGE_6  = 6
FINALE   = 7
```

---

# 12. Canonical ActionTag

Создать enum с ровно двенадцатью значениями:

```text
CARE
VULNERABILITY
SIMPLICITY
PRESTIGE
CONTROL
DOMINANCE
RISK
CONFLICT
SPONTANEITY
ABSURDITY
ORIGINALITY
OBSESSION
```

Соответствие:

```text
CARE         = Забота
VULNERABILITY= Уязвимость
SIMPLICITY   = Простота
PRESTIGE     = Престиж
CONTROL      = Контроль
DOMINANCE    = Доминирование
RISK         = Риск
CONFLICT     = Конфликт
SPONTANEITY  = Спонтанность
ABSURDITY    = Абсурд
ORIGINALITY  = Оригинальность
OBSESSION    = Одержимость
```

Не использовать String tags вида:

```text
"care"
"risk"
```

в gameplay logic, если enum уже доступен.

---

# 13. Canonical PrimaryGirlTrait

Ровно четыре:

```text
KIND
STATUS
THRILL_SEEKING
STRANGE
```

Соответствие:

```text
KIND           = Добрая
STATUS         = Статусная
THRILL_SEEKING = Азартная
STRANGE        = Странная
```

Не использовать `GAMBLER`: Азартная не является обязательно игроком в азартные игры.

---

# 14. Canonical SecondaryGirlTrait

Ровно четыре:

```text
SCANDALOUS
CONSISTENT
VARIETY_SEEKING
DEMANDING
```

Соответствие:

```text
SCANDALOUS     = Скандальная
CONSISTENT     = Последовательная
VARIETY_SEEKING= Переменчивая
DEMANDING      = Требовательная
```

---

# 15. Canonical DatingEventCategory

Ровно три:

```text
CONVERSATION
SPACE_EVENT
GIRL_PROPOSAL
```

Соответствие:

```text
CONVERSATION  = Разговор
SPACE_EVENT   = Событие пространства
GIRL_PROPOSAL = Предложение девушки
```

Приветствие и прощание НЕ являются четвёртой/пятой категорией центрального события.

---

# 16. Canonical CompetitionType

Ровно четыре:

```text
SLAP
DANCE
MONEY
SIGMA
```

Соответствие:

```text
SLAP  -> MUSCLE
DANCE -> APPEARANCE
MONEY -> CAPITAL
SIGMA -> AURA
```

Эта связь является static content rule и должна быть доступна данным.

---

# 17. Canonical PerkSection

Для описания положения перка в дереве:

```text
EARLY_COMMON
BRANCH_A
BRANCH_B
LATE_COMMON
```

MODULE 03 НЕ решает:

- можно ли купить обе ветки;
- exact prerequisite graph;
- global perk price;
- эффект перка.

Это MODULE 05.

---

# 18. PrimaryTraitDefinition

Создать typed static definition.

Минимальные поля:

```text
trait: PrimaryGirlTrait
display_name: String
liked_tags: Array[ActionTag]
disliked_tags: Array[ActionTag]
description: String
```

`description` — краткое каноническое объяснение для tooling/debug/docs, не обязательный финальный UI-текст.

Инварианты:

- liked уникальны;
- disliked уникальны;
- один tag не может одновременно быть liked и disliked у одной черты;
- arrays не должны изменяться runtime gameplay.

---

# 19. Canonical primary trait data

Создать четыре реальные definition.

## KIND — Добрая

Likes:

```text
CARE
VULNERABILITY
SIMPLICITY
```

Dislikes:

```text
DOMINANCE
CONFLICT
OBSESSION
```

---

## STATUS — Статусная

Likes:

```text
PRESTIGE
CONTROL
DOMINANCE
```

Dislikes:

```text
VULNERABILITY
SPONTANEITY
ABSURDITY
```

---

## THRILL_SEEKING — Азартная

Likes:

```text
RISK
CONFLICT
SPONTANEITY
```

Dislikes:

```text
CONTROL
SIMPLICITY
PRESTIGE
```

---

## STRANGE — Странная

Likes:

```text
ABSURDITY
ORIGINALITY
OBSESSION
```

Dislikes:

```text
PRESTIGE
CONTROL
SIMPLICITY
```

---

# 20. Global primary trait validation

Canonical liked-tags четырёх основных черт должны образовывать точное непересекающееся покрытие всех 12 ActionTag:

```text
3 + 3 + 3 + 3 = 12
```

То есть:

- ни один понравившийся tag не принадлежит двум основным чертам;
- ни один ActionTag не остаётся без основной черты, которой он нравится.

Это важный design invariant и должен проверяться validator/self-test.

Disliked tags МОГУТ пересекаться между чертами.

---

# 21. SecondaryTraitDefinition

Минимальные поля:

```text
trait: SecondaryGirlTrait
display_name: String
description: String
```

Не хранить generic formula, expression, script string или weight table.

Конкретная оценка secondary trait реализуется MODULE 09 Dating Core.

---

# 22. Canonical secondary trait semantics

Definition descriptions должны соответствовать GDD.

## SCANDALOUS

```text
+1: минимум одно оцениваемое событие содержало публичный CONFLICT
-1: свидание прошло полностью тихо и незаметно
0: иначе
```

## CONSISTENT

```text
+1: минимум 3 из 4 оцениваемых решений используют одну характеристику
-1: все 4 решения используют разные характеристики
0: иначе
```

## VARIETY_SEEKING

```text
+1: использованы минимум 3 разные характеристики
-1: одна характеристика использована минимум 3 раза
0: иначе
```

## DEMANDING

```text
+1: нет отрицательных реакций основной черты и есть минимум 2 положительные
-1: минимум 2 отрицательные реакции
0: иначе
```

Эти правила пока только фиксируются как semantic data/docs.

Не писать evaluator в MODULE 03.

---

# 23. GirlDefinition

Создать typed static definition девушки.

Минимальные поля:

```text
id: StringName
display_name: String

is_story: bool
story_stage: GameStage? / optional equivalent

primary_trait: PrimaryGirlTrait
secondary_trait: SecondaryGirlTrait

required_experience: int

discovery_situation_id: StringName
appearance_profile_id: StringName

dating_pool_ids: Array[StringName]

speech_style_note: String
clue_notes: Array[String]
```

Последние два поля предназначены для content authoring/reference.

Они не являются runtime character AI.

---

# 24. GirlDefinition — ограничения

`required_experience`:

```text
>= 0
```

`id`:

```text
girl_*
```

`dating_pool_ids`:

- могут быть пустыми у ещё не наполненного тестового/сюжетного asset;
- перед включением девушки в production content должны иметь хотя бы один валидный pool.

`appearance_profile_id`:

- opaque reference для MODULE 04;
- MODULE 03 не создаёт appearance system.

`discovery_situation_id`:

- opaque reference для MODULE 08;
- MODULE 03 не создаёт world situation logic.

---

# 25. Story girl names

MODULE 03 НЕ придумывает личные имена сюжетным девушкам.

Разрешены stable technical IDs:

```text
girl_neighbor
girl_actress
girl_mine_boss
girl_magazine_editor
girl_scientist
girl_president
girl_final_target
```

Но не создавать production GirlDefinition для них, пока соответствующий content/story module не задаст:

- display name;
- traits;
- requirements;
- appearance;
- pools.

Эти IDs можно документировать как reserved canonical IDs.

---

# 26. RivalDefinition

Создать typed static definition самца.

Минимальные поля:

```text
id: StringName
display_name: String

is_story: bool
story_stage: optional GameStage

required_authority: int
authority_reward: int

muscle: int
appearance: int
capital: int
aura: int

preferred_competition: CompetitionType
allowed_competitions: Array[CompetitionType]

appearance_profile_id: StringName
competition_modifier_id: StringName
```

---

# 27. RivalDefinition — правила

Характеристики:

```text
0..10
```

`required_authority`:

```text
>= 0
```

`authority_reward`:

```text
>= 0
```

`preferred_competition` должен входить в `allowed_competitions`.

`allowed_competitions`:

- минимум 1;
- без дублей.

`competition_modifier_id`:

- optional opaque ID;
- используется позднее для специально поставленных вариаций;
- MODULE 03 не реализует modifiers.

---

# 28. Rival story IDs

Reserved technical IDs:

```text
rival_actress
rival_mine_boss
rival_magazine_editor
rival_scientist
rival_president
```

Соседка не имеет сюжетного соперника.

STAGE_6 не требует отдельного обязательного земного сюжетного ухажёра по текущему GDD.

FINALE может содержать нескольких внеземных самцов; их IDs будут созданы только при спецификации финала.

Не придумывать production names сейчас.

---

# 29. CompetitionDefinition

Typed static definition типа состязания.

Поля:

```text
type: CompetitionType
display_name: String
characteristic: PlayerCharacteristic
expected_duration_min_seconds: int
expected_duration_max_seconds: int
```

Canonical definitions:

```text
SLAP:
display = Пощёчинный бой
characteristic = MUSCLE

DANCE:
display = Танцевальное противостояние
characteristic = APPEARANCE

MONEY:
display = Денежное противостояние
characteristic = CAPITAL

SIGMA:
display = Сигма-давление
characteristic = AURA
```

Expected duration:

```text
20..60 seconds
```

Это guideline, не minigame timer logic.

---

# 30. CompetitionDefinition НЕ содержит механику

Не хранить:

- pointer speed;
- slap target width;
- rhythm windows;
- money bidding formula;
- sigma disturbance frequency;
- score to win.

Это параметры конкретных MODULE 07A–07D.

CompetitionDefinition отвечает только за идентичность типа и связь с характеристикой.

---

# 31. DatingActionDefinition

Создать typed subresource/definition варианта действия внутри dating event.

Минимальные поля:

```text
id: StringName
label: String

characteristic: PlayerCharacteristic
required_characteristic_level: int

money_cost: int

resolver_id: StringName

direct_tags: Array[ActionTag]
```

---

# 32. Meaning of `resolver_id`

`resolver_id` — opaque identifier способа исполнения действия будущим Dating Core/feature module.

Примеры будущих значений МОГУТ быть:

```text
direct
start_rival_conflict
buy_object
short_activity_x
```

Но MODULE 03 не создаёт универсальный resolver engine и не регистрирует список будущих resolver types.

Для test content допустим только:

```text
direct
```

Будущая module spec добавляет resolver IDs вместе с реальным consumer.

---

# 33. DatingActionDefinition — characteristic

Каждое оцениваемое решение должно быть связано с одной основной характеристикой героя.

Поэтому поле обязательно:

```text
MUSCLE / APPEARANCE / CAPITAL / AURA
```

Именно эта характеристика используется дополнительными чертами `CONSISTENT` и `VARIETY_SEEKING`.

Не создавать действие с:

```text
characteristic = NONE
```

для оцениваемых центральных событий/прощания.

Приветствие будет отдельной структурой позже и не обязано следовать этому правилу.

---

# 34. DatingActionDefinition — requirement

```text
required_characteristic_level >= 0
```

Ориентировочный ручной диапазон:

```text
0..10
```

MODULE 03 только хранит requirement.

Не проверяет текущий GameState.

---

# 35. DatingActionDefinition — money

```text
money_cost >= 0
```

`money_cost`:

- расходуемые Деньги;
- НЕ Капитал.

Высокий Капитал может быть requirement характеристики, а фактическая покупка может дополнительно требовать Деньги.

MODULE 03 не делает списание.

---

# 36. DatingActionDefinition — tags

`direct_tags`:

- максимум 2;
- без дублей;
- может содержать 0 тегов только для test/non-evaluated технического action;
- production оцениваемый direct action должен в норме давать 1–2 тега.

Если результат действия зависит от мини-игры/соперника, финальные теги определяет будущий resolver/result, а `direct_tags` могут быть пустыми.

Не создавать универсальный Outcome DSL сейчас.

---

# 37. DatingEventDefinition

Typed definition одного центрального события.

Минимальные поля:

```text
id: StringName
category: DatingEventCategory

title: String
setup_text: String

actions: Array[DatingActionDefinition]

allowed_location_ids: Array[StringName]
```

`title` может быть внутренним authoring title.

`setup_text` — текст/описание ситуации, не обязательно финальная локализованная реплика.

---

# 38. DatingEventDefinition — ограничения

`id`:

```text
date_event_*
```

`actions`:

- минимум 1;
- action IDs уникальны внутри event.

`allowed_location_ids`:

- может быть пустым = event не ограничен локацией;
- если заполнен, содержит stable location IDs.

MODULE 03 НЕ задаёт:

- random weight;
- cooldown;
- stage probability;
- per-girl probability;
- procedural event chain.

---

# 39. Event repetition identity

Именно:

```text
DatingEventDefinition.id
```

является identity для правила:

> один и тот же конкретный event не повторяется в рамках одного свидания.

Не использовать title/text для сравнения событий.

---

# 40. DatingEventPoolDefinition

Чтобы ordinary girls могли делить общий контент, а story girls иметь подобранный пул, создать definition:

```text
id: StringName
event_ids: Array[StringName]
```

ID:

```text
date_pool_*
```

Пул:

- хранит только ссылки на event IDs;
- не копирует события;
- без дублей.

Dating Core позже:

- фильтрует по category;
- выбирает 3 события;
- применяет `2+1` / `1+1+1`;
- запрещает 3 одной категории.

MODULE 03 не выполняет выбор.

---

# 41. Greeting data

MODULE 03 НЕ создаёт полноценную Greeting system.

Причина:

- приветствие не оценивается;
- его диагностические реакции ещё будут подробно проектироваться в Dating Core.

Если GirlDefinition нужно сослаться на будущий набор приветствий, использовать только opaque:

```text
greeting_profile_id: StringName
```

Добавлять поле только если оно реально нужно уже выбранной структуре данных.

Не придумывать список приветствий сейчас.

---

# 42. Farewell data

Прощание является четвёртым оцениваемым решением, но его точная content structure будет в MODULE 09.

MODULE 03 не создаёт отдельный Farewell DSL.

Допустимо позже использовать ту же `DatingActionDefinition`.

Не создавать production farewell content сейчас.

---

# 43. PerkDefinition

Создать typed static definition перка.

Минимальные поля:

```text
id: StringName
display_name: String
description: String

characteristic: PlayerCharacteristic
section: PerkSection
order_in_section: int
```

Опционально:

```text
branch_label: String
```

если это реально улучшает editor/tool readability.

---

# 44. PerkDefinition НЕ содержит

Не хранить:

- цену;
- количество уже купленных перков;
- runtime purchased;
- arbitrary effect formula;
- GDScript code string;
- stat modifier dictionary;
- generic effect list.

Почему:

- цена зависит от глобального порядка покупок;
- effect implementation будет MODULE 05;
- часть перков меняет конкретные мини-игры, а не числовой stat.

MODULE 05 сопоставляет stable `perk_id` с эффектом.

---

# 45. Canonical perk IDs — Мышца

Создать definitions для всех восьми:

```text
perk_muscle_no_warmup
Без разминки
EARLY_COMMON
order 1

perk_muscle_tough_cheek
Крепкая щека
EARLY_COMMON
order 2

perk_muscle_double_slap
Двойная пощёчина
BRANCH_A
order 1

perk_muscle_counter_argument
Ответный аргумент
BRANCH_A
order 2

perk_muscle_hold_doorway
Удержание проёма
BRANCH_B
order 1

perk_muscle_heroic_defeat
Героическое поражение
BRANCH_B
order 2

perk_muscle_mass_reserve
Запас массы
LATE_COMMON
order 1

perk_muscle_two_handed_argument
Двуручный довод
LATE_COMMON
order 2
```

Descriptions взять из GDD без изменения смысла.

---

# 46. Canonical perk IDs — Внешность

```text
perk_appearance_good_profile
Выгодный профиль
EARLY_COMMON
order 1

perk_appearance_staged_walk
Поставленная походка
EARLY_COMMON
order 2

perk_appearance_pocket_mirror
Карманное зеркало
BRANCH_A
order 1

perk_appearance_control_profile
Контрольный профиль
BRANCH_A
order 2

perk_appearance_second_outfit
Второй комплект
BRANCH_B
order 1

perk_appearance_encore
Выход на бис
BRANCH_B
order 2

perk_appearance_rhythm_in_body
Ритм в теле
LATE_COMMON
order 1

perk_appearance_public_significance
Внешность общественного значения
LATE_COMMON
order 2
```

---

# 47. Canonical perk IDs — Капитал

```text
perk_capital_payable_intent
Платёжеспособное намерение
EARLY_COMMON
order 1

perk_capital_representation_expenses
Представительские расходы
EARLY_COMMON
order 2

perk_capital_buy_problem
Купить проблему
BRANCH_A
order 1

perk_capital_hostile_acquisition
Враждебное приобретение
BRANCH_A
order 2

perk_capital_salary_advance
Зарплата вперёд
BRANCH_B
order 1

perk_capital_dignity_refund
Возврат достоинства
BRANCH_B
order 2

perk_capital_financial_inertia
Финансовая инерция
LATE_COMMON
order 1

perk_capital_no_limit
Лимит отсутствует
LATE_COMMON
order 2
```

---

# 48. Canonical perk IDs — Аура

```text
perk_aura_presence_registered
Присутствие зарегистрировано
EARLY_COMMON
order 1

perk_aura_dont_blink_first
Не моргать первым
EARLY_COMMON
order 2

perk_aura_silence_longer
Молчание длиннее нормы
BRANCH_A
order 1

perk_aura_reverse_pressure
Обратное давление
BRANCH_A
order 2

perk_aura_right_to_say_nothing
Право первым ничего не говорить
BRANCH_B
order 1

perk_aura_she_already_started
Она уже начала
BRANCH_B
order 2

perk_aura_atmospheric_influence
Атмосферное влияние
LATE_COMMON
order 1

perk_aura_local_significance
Аура местного значения
LATE_COMMON
order 2
```

---

# 49. Perk tree prerequisites

MODULE 03 НЕ фиксирует окончательную prerequisite graph.

Он фиксирует только:

- characteristic;
- section;
- order.

Причина:

текущий GDD фиксирует структуру «2 ранних → две ветки по 2 → 2 поздних», но ещё не зафиксировал:

- выбор ветки навсегда или возможность открыть обе;
- exact merge rule перед поздней линией.

Это будет продуктовым решением MODULE 05.

Cursor НЕ должен решить это сам сейчас.

---

# 50. LocationDefinition

Typed definition:

```text
id: StringName
display_name: String
description: String
scene_path: String
```

`scene_path`:

- может быть пустым, пока физическая сцена не создана;
- не является unlock state.

Не хранить:

```text
is_unlocked
```

в LocationDefinition.

---

# 51. Canonical location IDs

Создать minimal definitions:

```text
apartment
Квартира

city_hub
Улица и городской хаб

cafe
Ресторан / кафе

gym
Качалка

appearance_space
Пространство Внешности

salary_mine
Зарплатная шахта

laboratory
Лаборатория

production_area
Поздняя производственная зона

final_location
Финальная локация
```

`appearance_space` намеренно остаётся нейтральным, потому что конкретно это может быть студия/подиум/салон.

`final_location` также остаётся нейтральной до MODULE 21.

---

# 52. StoryStageDefinition

Создать typed schema:

```text
stage: GameStage
display_name: String

story_girl_id: StringName
story_rival_id: StringName

notes: String
```

`story_rival_id` может быть empty.

Не хранить здесь:

- completed;
- current;
- runtime quest state;
- actual unlock flags.

---

# 53. Canonical stage records

Допустимо создать static stage definitions с reserved IDs.

## PROLOGUE

```text
display: Пролог — Соседка
story_girl_id: girl_neighbor
story_rival_id: empty
```

## STAGE_1

```text
display: Стадия 1 — Актриса
story_girl_id: girl_actress
story_rival_id: rival_actress
```

## STAGE_2

```text
display: Стадия 2 — Начальница шахты
story_girl_id: girl_mine_boss
story_rival_id: rival_mine_boss
```

## STAGE_3

```text
display: Стадия 3 — Редактор журнала
story_girl_id: girl_magazine_editor
story_rival_id: rival_magazine_editor
```

## STAGE_4

```text
display: Стадия 4 — Учёная
story_girl_id: girl_scientist
story_rival_id: rival_scientist
```

## STAGE_5

```text
display: Стадия 5 — Президент
story_girl_id: girl_president
story_rival_id: rival_president
```

## STAGE_6

```text
display: Стадия 6 — Мировое расширение
story_girl_id: empty
story_rival_id: empty
```

## FINALE

```text
display: Финал
story_girl_id: girl_final_target
story_rival_id: empty
```

FINALE rival sequence будет отдельной поставленной системой, не одним `story_rival_id`.

---

# 54. Stage definition cross-reference rule

Stage definitions могут ссылаться на reserved girl/rival IDs, для которых production definitions ещё не созданы.

Поэтому validator различает:

```text
reserved story reference
```

и

```text
ordinary dangling reference
```

Не нужно создавать пустые fake GirlDefinition только ради прохождения validator.

Лучший технический способ Cursor выбирает сам.

Простой допустимый вариант:

- stage schema валидирует формат reserved ID;
- full cross-reference validation включается только когда соответствующий content set заявлен как production-ready.

Не строить сложную validation profile system.

---

# 55. Generic RequirementDefinition запрещён

Не создавать универсальную систему вида:

```text
Requirement {
    type
    operator
    key
    value
}
```

Сейчас требования простые и понятные.

Использовать явные поля:

```text
GirlDefinition.required_experience
RivalDefinition.required_authority
DatingActionDefinition.required_characteristic_level
DatingActionDefinition.money_cost
```

Будущие сложные условия принадлежат владельцу конкретной системы.

---

# 56. Generic RewardDefinition запрещён

Не создавать:

```text
Reward {
    resource_type
    amount
    multiplier
    flags...
}
```

Примеры:

- Rival `authority_reward` — явное поле.
- Girl completion всегда даёт Опытность по правилам MODULE 10.
- Stage unlocks реализует Story Module.
- Деньги выдаёт Salary Mine.

Данные не должны превращаться в generic RPG engine.

---

# 57. Content Catalog

Нужна одна canonical read-only точка, которая содержит/индексирует static definitions.

Semantic API:

```text
get_primary_trait(trait)
get_secondary_trait(trait)

get_girl(id)
get_rival(id)

get_dating_event(id)
get_dating_pool(id)

get_perk(id)
get_competition(type)
get_location(id)
get_stage(stage)
```

Допустим также read-only методы получить списки.

---

# 58. Content Catalog ownership

Cursor должен сравнить:

1. static Resource catalog, который явно передаётся consumers;
2. один read-only autoload `ContentDB`;
3. другой маленький Godot-native вариант.

Для текущей игры допустим и ожидаемо удобен:

```text
ContentDB
```

как второй gameplay-independent autoload после `GameState`.

Если выбран autoload, canonical name:

```text
ContentDB
```

Не использовать:

```text
ContentManager
DatabaseManager
DataService
GlobalContent
```

---

# 59. ContentDB responsibilities

Разрешено:

- загрузить canonical catalog один раз;
- построить dictionaries по ID;
- валидировать;
- вернуть read-only definition;
- сообщить явную ошибку на duplicate/invalid content.

Запрещено:

- менять GameState;
- открывать локации;
- начислять ресурсы;
- запускать events;
- выбирать dating event;
- покупать perk;
- спавнить NPC;
- создавать сцены;
- иметь `_process()`.

---

# 60. Explicit catalog vs filesystem scan

Предпочтение:

> explicit catalog лучше неявного recursive filesystem scan.

Например canonical root resource может явно содержать arrays definition assets.

Плюсы:

- видно, что входит в production content;
- нет скрытой зависимости от имени папки;
- deterministic startup;
- test assets можно не подключать.

Cursor может выбрать эквивалентный простой вариант.

Не делать filesystem discovery каждый запуск без веской причины.

---

# 61. Missing lookup behavior

Для:

```text
get_girl(&"missing")
```

ожидается:

- `null`;
- debug/error message, если lookup означает programmer/content error.

Не создавать автоматически пустую definition.

Не возвращать случайный fallback content.

Для optional lookup можно иметь отдельный `try_get_*`, если Cursor считает это полезным, но не раздувать API.

---

# 62. Runtime immutability

Static definitions не должны мутироваться gameplay-системами.

Нельзя:

```text
girl_definition.required_experience -= 1
perk_definition.display_name = ...
```

Если будущая система временно меняет effective requirement, она считает override отдельно.

Content assets являются read-only source of truth.

Cursor должен выбрать разумную защиту/discipline для Godot Resources.

Не требуется глубокое копирование каждого Resource каждый frame.

---

# 63. Test fixtures

Создать отдельный test content, НЕ входящий в production catalog.

Минимально:

```text
girl_test_kind
rival_test
date_event_test_conversation
date_event_test_space
date_event_test_proposal
date_pool_test
```

Использовать только для self-tests.

Не придумывать полноценный игровой контент.

---

# 64. Test GirlDefinition

Пример fixture:

```text
id = girl_test_kind
display_name = Test Girl
primary_trait = KIND
secondary_trait = CONSISTENT
required_experience = 0
```

Это технический тест, не часть игры.

---

# 65. Test RivalDefinition

Пример fixture:

```text
id = rival_test
required_authority = 0
authority_reward = 1

muscle = 3
appearance = 3
capital = 3
aura = 3

preferred = SLAP
allowed = [SLAP, DANCE]
```

Не добавлять в production catalog.

---

# 66. Test Dating Events

Создать по одному test event каждой категории.

Каждый содержит несколько простых direct actions.

Использовать канонические теги и характеристики.

Не писать комедийный production text.

Примерные labels допустимы:

```text
Action A
Action B
```

потому что это тест структуры.

---

# 67. Validation system

Нужен единый явный способ прогнать validation всего production catalog.

Требования:

- запускается в editor/debug;
- может запускаться headless;
- возвращает pass/fail;
- сообщения указывают asset/type/ID/problem.

Не подключать тяжёлый validation framework.

---

# 68. Base validation

Для любой ID entity:

- ID non-empty;
- ID соответствует naming convention;
- duplicate ID внутри type registry запрещён.

Для display content:

- production `display_name` non-empty, если тип его требует.

---

# 69. Trait validation

Проверить:

- ровно 4 primary definitions;
- ровно 4 secondary definitions;
- все enum values покрыты;
- нет duplicate definitions одного enum;
- primary liked/disliked arrays уникальны;
- liked/disliked не пересекаются внутри одной primary trait;
- четыре liked sets вместе дают ровно 12 canonical tags;
- liked sets взаимно не пересекаются.

---

# 70. Perk validation

Проверить:

- ровно 32 canonical perk definitions;
- 8 на каждую характеристику;
- на характеристику:
  - 2 EARLY_COMMON;
  - 2 BRANCH_A;
  - 2 BRANCH_B;
  - 2 LATE_COMMON;
- `order_in_section` уникален внутри characteristic+section;
- IDs совпадают с этой спецификацией;
- names совпадают с GDD.

Не валидировать prerequisites, которых ещё нет.

---

# 71. Competition validation

Проверить:

- ровно 4 competition definitions;
- ровно один на каждую CompetitionType;
- characteristic mapping строго:
  - SLAP → MUSCLE
  - DANCE → APPEARANCE
  - MONEY → CAPITAL
  - SIGMA → AURA

---

# 72. Dating action validation

Проверить:

- action ID non-empty;
- required level `>=0`;
- money cost `>=0`;
- `direct_tags.size <= 2`;
- tags уникальны.

Если `resolver_id == direct`:

- production evaluated action должен иметь 1–2 tags.

Для test fixture можно разрешить 0 только если явно marked technical/non-evaluated выбранным техническим способом.

Не добавлять отдельное production boolean поле, если можно проще.

---

# 73. Dating event validation

Проверить:

- valid ID;
- valid category;
- минимум 1 action;
- unique action IDs;
- allowed locations без дублей.

Не проверять category-distribution свидания — это MODULE 09.

---

# 74. Dating pool validation

Проверить:

- valid ID;
- event IDs без дублей;
- каждое production event ID существует.

Test pool проверяется против test registry отдельно.

---

# 75. Girl validation

Проверить:

- ID format;
- valid traits;
- required_experience >=0;
- pool IDs без дублей.

Полный reference validation dating pools применяется только для GirlDefinition, который включён в production catalog.

---

# 76. Rival validation

Проверить:

- ID;
- required_authority >=0;
- authority_reward >=0;
- 4 stats в 0..10;
- allowed competitions non-empty;
- no duplicates;
- preferred contained in allowed.

---

# 77. Location validation

Проверить canonical location set:

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

На MODULE 03 production catalog должен содержать все 9 definitions.

Scene paths могут быть empty.

---

# 78. Stage validation

Проверить:

- ровно 8 stage definitions;
- каждый GameStage представлен ровно один раз;
- reserved IDs соответствуют разделу 53;
- PROLOGUE rival empty;
- STAGE_1..5 rival non-empty;
- STAGE_6 girl/rival empty;
- FINALE girl = `girl_final_target`.

Не требовать существования production story GirlDefinition сейчас.

---

# 79. No localization framework

MODULE 03 не создаёт localization system.

Пока static definitions хранят обычные strings.

Но:

- ID не зависит от текста;
- поэтому позже display text можно заменить localization key без смены ID.

Не создавать сейчас `.po`, translation server wrappers и text tables без отдельной спецификации.

---

# 80. No asset appearance system

`appearance_profile_id` остаётся opaque StringName.

MODULE 03 не хранит:

- meshes;
- hair scenes;
- clothing arrays;
- materials.

Это MODULE 04 Character Framework.

Если Cursor считает `PackedScene` reference в GirlDefinition удобным — НЕ добавлять сейчас: character presentation ещё не спроектирован.

---

# 81. No dialogue engine

Не создавать:

- DialogueLine;
- DialogueTree;
- branching dialogue graph;
- speaker database.

`setup_text`, `label`, `description` — обычные content strings.

Полноценный dialogue flow не является целью игры.

---

# 82. No quest engine

StoryStageDefinition не является QuestDefinition.

Не создавать:

- objectives;
- conditions;
- quest state;
- quest chains.

MODULE 11 будет простой сценарной системой.

---

# 83. No randomization engine

Data Layer не выбирает случайный контент.

Не создавать:

- weighted picker;
- RNG seed;
- shuffle bag;
- event history.

Dating Core позже реализует правила выбора трёх событий.

---

# 84. Integration with GameState

ContentDB может ссылаться на shared enum types.

ContentDB НЕ должен изменять GameState.

GameState не должен загружать ContentDB внутри своего `_ready()`.

Обе системы остаются независимыми:

```text
GameState = runtime mutable state
ContentDB = static read-only definitions
```

Feature modules позже используют обе.

---

# 85. Autoload order

Если используется `ContentDB` autoload, порядок startup не должен создавать скрытую зависимость на `GameState`.

ContentDB должен быть способен загрузиться без runtime state.

GameState должен быть способен reset-нуться без ContentDB.

---

# 86. Documentation

После MODULE 03 обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
```

В `PROJECT_STRUCTURE.md` зафиксировать:

- data directory;
- definition classes;
- production catalog location;
- test content;
- ContentDB, если выбран.

В `TECHNICAL_DECISIONS.md`:

- storage format;
- catalog ownership;
- shared enum ownership;
- validation approach.

---

# 87. Self-test scene/script

Создать reproducible MODULE 03 test runner.

Он должен:

1. загрузить production catalog;
2. прогнать validation;
3. проверить canonical traits;
4. проверить perks;
5. проверить competitions;
6. проверить locations;
7. проверить stages;
8. загрузить test fixtures;
9. проверить lookup;
10. проверить rejection invalid fixtures, если это удобно без загрязнения error output.

Headless запуск должен быть возможен.

---

# 88. Test — ActionTag coverage

Ожидается:

```text
12 enum values
```

Каждый входит ровно в один primary liked set.

---

# 89. Test — KIND

Проверить exact:

```text
likes:
CARE
VULNERABILITY
SIMPLICITY

dislikes:
DOMINANCE
CONFLICT
OBSESSION
```

---

# 90. Test — STATUS

Exact:

```text
likes:
PRESTIGE
CONTROL
DOMINANCE

dislikes:
VULNERABILITY
SPONTANEITY
ABSURDITY
```

---

# 91. Test — THRILL_SEEKING

Exact:

```text
likes:
RISK
CONFLICT
SPONTANEITY

dislikes:
CONTROL
SIMPLICITY
PRESTIGE
```

---

# 92. Test — STRANGE

Exact:

```text
likes:
ABSURDITY
ORIGINALITY
OBSESSION

dislikes:
PRESTIGE
CONTROL
SIMPLICITY
```

---

# 93. Test — Perks

Проверить:

```text
32 total
8 MUSCLE
8 APPEARANCE
8 CAPITAL
8 AURA
```

И exact IDs/names из разделов 45–48.

---

# 94. Test — Competition mapping

Exact:

```text
SLAP -> MUSCLE
DANCE -> APPEARANCE
MONEY -> CAPITAL
SIGMA -> AURA
```

---

# 95. Test — Dating action max tags

Fixture с 1 и 2 tags проходит.

Fixture с 3 tags:

```text
validation fail
```

---

# 96. Test — Duplicate ID

Два definitions одного типа с одинаковым ID:

```text
validation fail
```

Ни один не должен silently overwrite другой в registry.

---

# 97. Test — Lookup

Для test catalog:

```text
get_girl(girl_test_kind)
=> exact resource

get_rival(rival_test)
=> exact resource

get missing
=> null
```

---

# 98. Test — Runtime immutability discipline

Убедиться, что lookup не создаёт новую изменяемую runtime state-копию.

Feature systems должны воспринимать definitions как static.

Не требуется complicated immutable wrapper.

---

# 99. Test — GameState regression

После возможного refactor shared enums:

- MODULE 02 self-tests проходят;
- reset работает;
- stage values не изменились;
- characteristic values не изменились;
- GameState autoload работает.

---

# 100. Test — FPS regression

Main FPS test продолжает запускаться.

ContentDB startup не должен:

- менять сцену;
- ставить игру на pause;
- менять mouse;
- создавать NPC.

---

# 101. Definition of Done

MODULE 03 завершён только если:

- [ ] существует canonical shared ActionTag enum из 12 значений;
- [ ] существует PrimaryGirlTrait enum из 4 значений;
- [ ] существует SecondaryGirlTrait enum из 4 значений;
- [ ] существует DatingEventCategory enum из 3 значений;
- [ ] существует CompetitionType enum из 4 значений;
- [ ] shared Characteristic/Stage не продублированы;
- [ ] есть PrimaryTraitDefinition;
- [ ] есть SecondaryTraitDefinition;
- [ ] есть GirlDefinition;
- [ ] есть RivalDefinition;
- [ ] есть CompetitionDefinition;
- [ ] есть DatingActionDefinition;
- [ ] есть DatingEventDefinition;
- [ ] есть DatingEventPoolDefinition;
- [ ] есть PerkDefinition;
- [ ] есть LocationDefinition;
- [ ] есть StoryStageDefinition;
- [ ] canonical 4 primary trait data exact;
- [ ] canonical 4 secondary trait definitions exact;
- [ ] canonical 32 perks зарегистрированы;
- [ ] canonical 4 competitions зарегистрированы;
- [ ] canonical 9 locations зарегистрированы;
- [ ] canonical 8 stage records зарегистрированы;
- [ ] отсутствуют fake production story girls/rivals;
- [ ] test fixtures отделены от production;
- [ ] есть единый read-only catalog/registry;
- [ ] duplicate IDs не overwrite silently;
- [ ] есть validation;
- [ ] max 2 tags enforced;
- [ ] no generic RequirementDefinition;
- [ ] no generic RewardDefinition;
- [ ] no dialogue engine;
- [ ] no quest engine;
- [ ] no random picker;
- [ ] no gameplay effects;
- [ ] no runtime progress inside definitions;
- [ ] ContentDB не меняет GameState;
- [ ] MODULE 02 tests проходят;
- [ ] MODULE 01 FPS regression проходит;
- [ ] donor не изменён;
- [ ] MODULE 04 не реализован заранее.

---

# 102. Порядок выполнения Cursor

## Step 1 — Read canonical docs

Обязательно прочитать:

```text
docs/gdd/04_male_status_system.md
docs/gdd/05_girls.md
docs/gdd/06_dating.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Также:

- MODULE 00;
- MODULE 01;
- MODULE 02;
- PROJECT_STRUCTURE;
- TECHNICAL_DECISIONS.

---

## Step 2 — Audit current enums

Понять:

- где сейчас Stage;
- где Characteristic;
- как избежать дублирования.

Если нужен маленький shared-types refactor — сделать его с regression tests.

---

## Step 3 — Choose Godot data approach

Сравнить reasonable варианты.

Ожидаемый выбор:

```text
custom Resources + explicit catalog
```

Но решение должно быть технически обосновано.

---

## Step 4 — Implement shared content types

Сначала enums/types.

Без gameplay.

---

## Step 5 — Implement definition classes

Добавить только schemas из этой спецификации.

Не добавлять поля «на будущее».

---

## Step 6 — Implement canonical fixed content

Создать:

- 4 primary traits;
- 4 secondary traits;
- 32 perks;
- 4 competitions;
- 9 locations;
- 8 stages.

Не создавать ordinary girls/rivals/events production content.

---

## Step 7 — Implement catalog

Создать read-only loading + lookup + duplicate protection.

---

## Step 8 — Create isolated test fixtures

Только technical sample content.

---

## Step 9 — Validation

Реализовать и прогнать sections 67–78.

---

## Step 10 — Regression

Запустить:

- MODULE 02 self-tests;
- MODULE 03 self-tests;
- FPS startup/smoke.

---

## Step 11 — Docs

Обновить Project Structure и Technical Decisions.

---

# 103. Формат финального отчёта Cursor

## Implemented

Какие schemas/catalogs/types добавлены.

## Technical decisions

- data storage approach;
- catalog ownership;
- enum ownership;
- validation approach.

## Canonical content

Подтвердить количество:

```text
12 tags
4 primary traits
4 secondary traits
32 perks
4 competitions
9 locations
8 stages
```

## Test fixtures

Что создано и подтверждение, что не входит в production catalog.

## Validation

Результат MODULE 03 self-test.

## Regressions

Результат MODULE 02 tests и FPS smoke.

## Donor

Что просмотрено; подтверждение read-only.

## Files changed

Основные файлы.

## Product questions

Если нет:

```text
None.
```

---

# 104. Запрет продолжения

После успешного MODULE 03:

**НЕ начинать MODULE 04 — Character Framework.**

Остановиться и дождаться отдельной спецификации.
