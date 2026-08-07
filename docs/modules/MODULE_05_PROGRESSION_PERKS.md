# MODULE 05 — PROGRESSION & PERKS

**Проект:** Date Factory  
**Модуль:** 05 — Progression & Perks  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать покупку перков, дерево четырёх характеристик, глобально растущую цену, рост уровней характеристик и стабильный API владения перками; зафиксировать точные контракты эффектов для будущих gameplay-модулей  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/03_core_loop.md`, `docs/gdd/04_male_status_system.md`  
**Предыдущий модуль:** MODULE 04 — Character Framework

---

# 1. Цель MODULE 05

После завершения модуля игра должна иметь законченную систему прокачки героя:

- четыре дерева:
  - Мышца;
  - Внешность;
  - Капитал;
  - Аура;
- 32 уже определённых static `PerkDefinition`;
- постоянное владение купленными перками в рамках прохождения;
- покупку за `Баллы прокачки`;
- глобальную цену следующей покупки:
  - `1 → 3 → 9 → 27 → 81 → 243 → ...`;
- prerequisites дерева;
- рост соответствующей характеристики на `+1` за каждый купленный перк;
- невозможность повторной покупки;
- невозможность покупки без prerequisites или без достаточных Баллов прокачки;
- read API для будущих игровых систем;
- signals/notifications для будущего UI;
- тестовую сцену/runner для проверки всей системы.

MODULE 05 НЕ должен заранее реализовывать мини-игры, свидания, зарплатную шахту или Rival Encounter.

---

# 2. Новое каноническое правило уровня характеристики

Пользователь зафиксировал:

> Каждый купленный перк характеристики даёт `+1` к уровню этой характеристики.

Следовательно:

```text
куплен 1 перк Мышцы
=> muscle = 1

куплено 4 перка Внешности
=> appearance = 4
```

На текущем каноническом дереве существует 8 перков каждой характеристики.

Поэтому текущий естественный максимум:

```text
muscle     = 8
appearance = 8
capital    = 8
aura       = 8
```

Старый ориентир GDD `0–10` остаётся описанием масштаба ручной игры, но MODULE 05 не создаёт искусственные уровни `9` и `10`, потому что источника таких уровней сейчас нет.

Не придумывать:

- XP характеристики;
- тренировки, напрямую повышающие stat;
- skill points конкретной характеристики;
- дополнительные невидимые уровни.

---

# 3. Основной invariant Progression

Для каждой характеристики:

```text
уровень характеристики
=
количество купленных перков этой характеристики
```

Примеры:

```text
куплены:
М1
М2
М3A

muscle == 3
```

```text
куплены:
А1
А2
А3B
А5B
А4

aura == 5
```

Это обязательный invariant.

Нельзя позволить gameplay-коду отдельно:

```text
GameState.muscle += 1
```

без покупки перка.

---

# 4. Refactor GameState characteristic mutation

После MODULE 05 публичная произвольная мутация:

```text
set_characteristic(...)
```

не должна быть обычным gameplay API.

Cursor должен выбрать технически чистый способ:

- сделать mutation internal/private;
- заменить её atomic purchase commit API;
- оставить только controlled restore/debug route;
- иной best-practice вариант.

Требования:

- внешний gameplay не может повысить stat без покупки;
- reset по-прежнему ставит все stats в `0`;
- signals `characteristic_changed` продолжают работать;
- Save/Load позже сможет восстановить состояние без нарушения invariant.

---

# 5. Владение перками — runtime state

Добавить в canonical `GameState` persistent runtime collection:

```text
purchased_perks
```

Содержит stable `perk_id`.

Техническое представление выбирает Cursor:

- Dictionary-as-set;
- другой простой set-like вариант.

Требования:

- без дублей;
- reset очищает;
- stable IDs `StringName`;
- не хранить `PerkDefinition Resource` как runtime ownership;
- не хранить отдельный bool для каждого из 32 перков.

---

# 6. Canonical query

Будущие системы должны иметь простой semantic API:

```text
has_perk(perk_id) -> bool
```

Не заставлять consumers напрямую разбирать внутренний Dictionary.

Допустим owner API находится в:

- `GameState`;
- Progression service;

в зависимости от технического решения Cursor.

Главное — одно canonical поведение.

---

# 7. Не создавать generic perk effect engine

Категорически запрещено создавать:

```text
PerkEffect
EffectType
Modifier
GameplayModifier
EffectStack
StatModifier
EffectResolver
AbilitySystem
```

или универсальную структуру вроде:

```text
effects = [
    { type = "timing_window", multiplier = 1.2 },
    { type = "extra_point", condition = ... }
]
```

Причина:

32 перка намеренно меняют конкретные механики разными способами.

Примеры:

- Карманное зеркало меняет сигма-мини-игру;
- Второй комплект добавляет конкретное действие на свидании;
- Зарплата вперёд взаимодействует с Salary Mine;
- Удержание проёма открывает сценические действия.

Правильная архитектура:

```text
future feature system
→ проверяет конкретный canonical perk ID
→ применяет конкретный понятный эффект
```

MODULE 05 хранит ownership и правила покупки.

---

# 8. Perk IDs в code

Все 32 perk IDs уже зафиксированы Content Data Layer.

Future gameplay code не должен плодить строковые литералы:

```text
&"perk_muscle_double_slap"
```

по всему проекту.

Cursor должен проверить текущий MODULE 03.

Если уже существует canonical constants/type-safe доступ — использовать его.

Если нет, создать маленький canonical namespace:

```text
PerkIds
```

с `StringName` constants для всех 32 IDs.

Пример semantics:

```text
PerkIds.MUSCLE_DOUBLE_SLAP
PerkIds.APPEARANCE_POCKET_MIRROR
PerkIds.CAPITAL_SALARY_ADVANCE
PerkIds.AURA_RIGHT_TO_SAY_NOTHING
```

Validator обязан проверять, что каждый constant существует в production ContentDB и совпадает с canonical asset ID.

Не дублировать display names/description в `PerkIds`.

---

# 9. Глобальная цена покупки

Стоимость зависит от общего числа уже купленных перков героя во ВСЕХ четырёх деревьях.

Если:

```text
N = количество уже купленных перков
```

то следующая цена:

```text
3^N
```

То есть:

```text
N=0 => 1
N=1 => 3
N=2 => 9
N=3 => 27
N=4 => 81
N=5 => 243
...
```

Цена НЕ считается отдельно:

- по характеристике;
- по ветке;
- по stage;
- по rarity.

---

# 10. Integer calculation

Не использовать float `pow()` как источник цены, если это может приводить к rounding.

Для текущих 32 перков максимальный exponent ограничен и безопасен для `int64`.

Предпочтительно вычислять integer power корректным integer способом.

Cursor выбирает best-practice реализацию.

---

# 11. Purchased count

Не хранить отдельный mutable:

```text
purchased_perk_count
```

если он однозначно равен:

```text
purchased_perks.size()
```

Использовать производное значение.

Это исключает drift.

---

# 12. Next purchase cost API

Нужен read API semantic уровня:

```text
get_next_perk_cost() -> int
```

Он не зависит от выбранного perk.

Если игрок купил 4 любых перка:

```text
next cost = 81
```

---

# 13. Стоимость конкретного доступного perk

Поскольку все покупки используют одну глобальную последовательность:

```text
get_perk_purchase_cost(perk_id)
```

если такой helper существует, возвращает ту же текущую цену следующей покупки.

Не вводить индивидуальную price в `PerkDefinition`.

---

# 14. Каноническая структура дерева

Для КАЖДОЙ характеристики:

```text
EARLY_COMMON #1
↓
EARLY_COMMON #2
↓
┌──────────────┬──────────────┐
│ BRANCH_A #1  │ BRANCH_B #1  │
│ ↓            │ ↓            │
│ BRANCH_A #2  │ BRANCH_B #2  │
└──────────────┴──────────────┘
       ↓ OR
LATE_COMMON #1
↓
LATE_COMMON #2
```

---

# 15. Prerequisites — early

Для каждой характеристики:

## EARLY_COMMON order 1

```text
нет prerequisite
```

## EARLY_COMMON order 2

требует:

```text
EARLY_COMMON order 1
```

---

# 16. Prerequisites — branches

Оба первых branch-перка требуют:

```text
EARLY_COMMON order 2
```

То есть после двух ранних общих игрок одновременно получает право пойти:

```text
в Branch A
или
в Branch B
```

---

# 17. Branch progression

```text
BRANCH_A order 2
```

требует:

```text
BRANCH_A order 1
```

```text
BRANCH_B order 2
```

требует:

```text
BRANCH_B order 1
```

---

# 18. Ветки НЕ блокируются навсегда

Покупка Branch A НЕ закрывает Branch B.

Покупка Branch B НЕ закрывает Branch A.

Игрок может позднее купить обе.

Причина раннего выбора создаётся:

- общей экспоненциальной ценой;
- ограниченным ранним количеством Опытности/Баллов прокачки.

Не создавать:

```text
chosen_branch
branch_locked
respec_branch
```

---

# 19. Late common unlock

Первый `LATE_COMMON` становится доступен, когда полностью завершена ХОТЯ БЫ ОДНА ветка:

```text
BRANCH_A #2 purchased
OR
BRANCH_B #2 purchased
```

Не требуется завершить обе ветки.

Это и есть слияние ветвящегося дерева обратно в общую позднюю линию.

---

# 20. Late common progression

```text
LATE_COMMON order 2
```

требует:

```text
LATE_COMMON order 1
```

После выхода в late common незаконченная альтернативная ветка всё ещё может быть докуплена позже.

---

# 21. Tree rules derive from existing PerkDefinition

MODULE 03 уже хранит:

```text
characteristic
section
order_in_section
```

Не добавлять вручную arrays prerequisite IDs ко всем 32 resources, если дерево можно однозначно вывести из этих полей.

Предпочтение:

> одна canonical tree rule implementation + static PerkDefinition metadata.

Это уменьшает дублирование.

Если текущая структура MODULE 03 требует маленького дополнения для чистой реализации — Cursor может его сделать, но не создавать generic prerequisite DSL.

---

# 22. Perk availability states

Нужен понятный результат проверки.

Canonical semantic states:

```text
AVAILABLE
OWNED
LOCKED_PREREQUISITE
NOT_ENOUGH_POINTS
UNKNOWN_PERK
```

Технически Cursor может использовать enum/result object.

Важно различать:

```text
структурно закрыт
```

и

```text
открыт, но дорого
```

для будущего UI.

---

# 23. Purchase result

Операция покупки не должна возвращать просто `false` без причины.

Canonical semantic result:

```text
SUCCESS
ALREADY_OWNED
PREREQUISITE_NOT_MET
NOT_ENOUGH_POINTS
UNKNOWN_PERK
INVALID_CONTENT
```

Можно объединить последние два при технической необходимости, но debug должен показывать content error.

---

# 24. Purchase API

Semantic:

```text
purchase_perk(perk_id) -> PurchaseResult
```

Внутри одной операции:

1. найти `PerkDefinition`;
2. проверить ID/content;
3. проверить, не куплен ли perk;
4. проверить prerequisites;
5. вычислить global cost;
6. проверить `upgrade_points`;
7. списать points;
8. добавить ownership;
9. увеличить соответствующую характеристику на `+1`;
10. отправить notifications.

---

# 25. Atomic purchase

Purchase должна быть атомарной.

Нельзя получить состояние:

```text
Баллы уже списаны
но perk не добавлен
```

или:

```text
perk добавлен
но stat не вырос
```

или:

```text
stat вырос
но perk ownership отсутствует
```

Cursor должен выбрать технически чистую transaction-like реализацию без создания generic transaction framework.

---

# 26. Characteristic mapping

Использовать:

```text
PerkDefinition.characteristic
```

для выбора stat.

Не определять характеристику по ID prefix:

```text
if id begins "perk_muscle"
```

Prefix служит readability, не gameplay branching.

---

# 27. Purchase notifications

После успешной покупки должны быть доступны notifications semantic уровня:

```text
perk_purchased(perk_id, characteristic, cost)
```

и уже существующие:

```text
upgrade_points_changed
characteristic_changed
```

Порядок должен быть документирован и предсказуем.

Предпочтительно сначала привести state в финальное целостное состояние, затем emit.

---

# 28. No duplicate signal bus

Не создавать global EventBus.

Perk purchase signal принадлежит:

- Progression system;
- либо GameState,

в зависимости от выбранной архитектуры.

---

# 29. Respec отсутствует

В текущем дизайне нет:

- возврата Баллов прокачки;
- продажи перка;
- сброса отдельной ветки;
- respec героя.

Не реализовывать.

`reset_for_new_game()` очищает всё прохождение — это не respec.

---

# 30. Refund при ошибке покупки

Если операция не может завершиться:

- points не списываются;
- ownership не меняется;
- stat не меняется.

Не нужна отдельная gameplay refund mechanic.

---

# 31. Debug grant

Для тестов можно использовать существующий:

```text
GameState.add_experience(...)
```

потому что он корректно даёт Баллы прокачки.

Не создавать production cheat:

```text
give_upgrade_points(999999)
```

Debug/test-only helper допустим только если реально нужен automation tests.

---

# 32. Эффекты перков: принцип реализации

MODULE 05 НЕ реализует эффект внутри будущей системы, если этой системы ещё нет.

Вместо этого фиксируется **Effect Contract**.

Будущий owner module обязан:

1. использовать exact canonical `perk_id`;
2. проверить ownership через Progression API;
3. реализовать поведение строго по contract;
4. добавить integration test этого perk;
5. не менять смысл perk без обновления GDD/spec.

---

# 33. Usage scope хранит consumer, не Progression

Перки имеют ограничения:

```text
один раз за бой
один раз за свидание
один раз за игровой период
один раз за стадию
```

MODULE 05 НЕ создаёт глобальный `PerkCooldownManager`.

Владельцем использования является контекст, где существует понятие:

- Slap Match;
- Dating Session;
- Rival Encounter;
- Salary Period;
- Story Stage.

Пример:

```text
DatingSession.used_second_outfit = true
```

или локальный set использованных perks.

После конца контекста usage автоматически исчезает вместе с session.

---

# 34. Нет универсального cooldown resource

Не хранить в GameState:

```text
perk_last_used
perk_cooldowns
perk_charges
```

для всех перков.

Исключение появится только если будущий конкретный perk требует persistent cooldown между сценами и его owner module зафиксирует это отдельно.

---

# 35. EFFECT CONTRACTS — Мышца

## `perk_muscle_no_warmup` — Без разминки

Ownership effect contracts:

- герой получает доступ к специальным вариантам Мышцы, у которых requirement допускает текущий уровень;
- первая силовая активность новой сцены получает немного более широкое стартовое timing window.

Future owners:

```text
Dating/World action availability
Strength minigame controller
```

MODULE 05 не определяет числовой размер расширения timing window.

Его задаст конкретная minigame spec.

---

# 36. `perk_muscle_tough_cheek` — Крепкая щека

Contract:

- один раз за пощёчинный бой пропущенный удар соперника не уничтожает текущую серию полностью;
- perk не отменяет само очко/последствие попадания, если будущая slap spec не скажет обратное.

Owner:

```text
MODULE 07A — Slap
```

Usage scope:

```text
one per slap match
```

---

# 37. `perk_muscle_double_slap` — Двойная пощёчина

Contract:

- один раз за slap match игрок может использовать special attack opportunity;
- идеальное попадание даёт `2` очка вместо обычного `1`;
- провал попытки делает ближайшую следующую защиту сложнее.

Owner:

```text
MODULE 07A
```

Точная activation input и числовой defensive penalty определяются MODULE 07A.

---

# 38. `perk_muscle_counter_argument` — Ответный аргумент

Contract:

- идеальный блок arm-ит bonus;
- если следующий ближайший attack window выполнен идеально — атака получает `+1` дополнительное очко;
- bonus не переносится бесконечно на будущие атаки.

Owner:

```text
MODULE 07A
```

---

# 39. `perk_muscle_hold_doorway` — Удержание проёма

Contract:

- открывает специально авторенные действия, в которых герой физически удерживает проход/позицию/объект;
- perk сам не сканирует двери и не позволяет удерживать любой объект мира.

Owners:

```text
Dating event content
World scripted interactions
```

Availability определяется конкретным authored event.

---

# 40. `perk_muscle_heroic_defeat` — Героическое поражение

Contract:

- при поражении сопернику, который считается заметно сильнее, смягчается возможное наказание Авторитетом;
- если поражение произошло как часть оцениваемого события свидания, результат получает:
  - `VULNERABILITY`;
  - `RISK`;
- поражение остаётся поражением.

Owners:

```text
MODULE 06 Rival Encounter
MODULE 09 Dating Core
```

Понятия:

```text
заметно сильнее
authority loss on defeat
```

должны быть точно определены MODULE 06.

MODULE 05 НЕ придумывает формулу сейчас.

---

# 41. `perk_muscle_mass_reserve` — Запас массы

Contract:

- один раз за конкретную силовую мини-игру доступна одна дополнительная поблажка:
  - дополнительная ошибка;
  - либо дополнительный раунд;
- конкретная форма зависит от типа силовой активности.

Owner:

```text
конкретный strength minigame
```

Не создавать generic charge system.

---

# 42. `perk_muscle_two_handed_argument` — Двуручный довод

Contract:

- один раз за крупное силовое состязание игрок может объявить high-risk decisive move;
- идеальный результат немедленно даёт крупное преимущество;
- ошибка немедленно отдаёт крупное преимущество сопернику.

Owner:

```text
MODULE 07A / future authored major strength activities
```

Exact advantage определяет конкретная minigame spec.

---

# 43. EFFECT CONTRACTS — Внешность

## `perk_appearance_good_profile` — Выгодный профиль

Contract:

- открывает специальные варианты Внешности по требованиям уровня;
- при визуальном вступлении девушки одна clue-detail её образа показывается заметнее/читаемее.

Owners:

```text
MODULE 08 Girl Discovery
MODULE 09 Dating
```

Не добавлять hidden numerical bonus.

---

# 44. `perk_appearance_staged_walk` — Поставленная походка

Contract:

- первая ошибка в танцевальной или модельной активности не уничтожает текущую серию полностью.

Owners:

```text
MODULE 07B Dance
future authored appearance activity
```

Usage:

```text
first qualifying mistake per activity
```

---

# 45. `perk_appearance_pocket_mirror` — Карманное зеркало

Contract:

- один раз за sigma contest игрок активирует зеркало;
- на короткий период допустимая зона удержания лица становится стабильнее и визуально понятнее.

Owner:

```text
MODULE 07C Sigma
```

Exact duration/zone behavior задаёт sigma spec.

---

# 46. `perk_appearance_control_profile` — Контрольный профиль

Contract:

- работает только в период активного Карманного зеркала;
- идеальная sigma section в этот период даёт дополнительное очко.

Owner:

```text
MODULE 07C
```

---

# 47. `perk_appearance_second_outfit` — Второй комплект

Contract:

- один раз за date session;
- доступно после прихода девушки;
- только до первого оцениваемого события;
- меняет заранее подготовленный аксессуарный комплект героя.

Owner:

```text
MODULE 09 Dating
Character presentation
```

MODULE 05 не создаёт wardrobe/equipment system.

MODULE 09/Character Presentation выберут минимальную реализацию с уже доступными visual variants.

---

# 48. `perk_appearance_encore` — Выход на бис

Contract:

- один раз за date session;
- trigger: нейтральная реакция (`0`) на действие Внешности;
- открывается короткое дополнительное visual action;
- при успешном authored результате один итоговый tag действия заменяется на:
  - `ORIGINALITY`;
- perk не даёт автоматический `+1` отношения сам по себе.

Owner:

```text
MODULE 09
```

---

# 49. `perk_appearance_rhythm_in_body` — Ритм в теле

Contract:

- правильные rhythm windows в dance немного шире;
- первая сложная связка содержит дополнительную visual clue.

Owner:

```text
MODULE 07B
```

Exact numbers определяет Dance spec.

---

# 50. `perk_appearance_public_significance` — Внешность общественного значения

Contract:

- один раз за date session;
- позволяет выбрать специальный вариант Внешности, requirement которого на `1` выше текущего `appearance`;
- если вариант запускает activity/minigame, её всё равно необходимо выполнить;
- perk не означает автоматический успех.

Owner:

```text
MODULE 09
```

---

# 51. EFFECT CONTRACTS — Капитал

## `perk_capital_payable_intent` — Платёжеспособное намерение

Contract:

- открывает специальные варианты Капитала по уровню;
- открывает доступ к денежным противостояниям.

Owners:

```text
MODULE 06 Rival Encounter
MODULE 07D Money
MODULE 09 Dating
```

---

# 52. `perk_capital_representation_expenses` — Представительские расходы

Contract:

- первое обычное платное действие date session не списывает Деньги;
- действие всё равно считается платным для логики результата;
- perk не применяется к специально обозначенным крупным/сюжетным расходам, если future event spec исключает их из категории «обычное платное действие».

Owner:

```text
MODULE 09
```

Понятие normal paid action должен быть explicit в DatingAction execution, а не определяться по цене на глаз.

---

# 53. `perk_capital_buy_problem` — Купить проблему

Contract:

- один раз за date session;
- позволяет выбрать authored покупку объекта/права, являющегося препятствием;
- только если конкретное событие явно допускает такой вариант;
- не превращает любой world object в purchasable.

Owner:

```text
MODULE 09 + authored world event
```

---

# 54. `perk_capital_hostile_acquisition` — Враждебное приобретение

Contract:

- после специально отмеченной крупной победы деньгами небольшой объект может остаться в собственности героя;
- world presentation может измениться;
- может открыться короткий путь;
- persistent world fact должен храниться story/world system, а не Perk system.

Owners:

```text
MODULE 07D
MODULE 11/12 Story/World
```

---

# 55. `perk_capital_salary_advance` — Зарплата вперёд

Contract:

- один раз за игровой salary period;
- можно получить ближайшую доступную выплату без физического похода к месту выдачи;
- не создаёт дополнительную выплату, а забирает уже доступную/ближайшую.

Owner:

```text
MODULE 13 Salary Mine
```

Понятие salary period определяет MODULE 13.

---

# 56. `perk_capital_dignity_refund` — Возврат достоинства

Contract:

- если платное действие реально завершилось провалом — его денежная стоимость возвращается;
- визуальный/комедийный провал сохраняется;
- созданные итоговые tags сохраняются;
- refund не превращает провал в success.

Owner:

```text
MODULE 09 / paid action resolver
```

---

# 57. `perk_capital_financial_inertia` — Финансовая инерция

Contract:

- после того как соответствующая зарплатная шутка/ручной цикл уже был показан игроку, повышение salary level может давать небольшой автоматический поток Денег;
- perk не запускает passive income до ручного знакомства с механикой.

Owner:

```text
MODULE 13
```

Точная формула определяется MODULE 13/balance.

---

# 58. `perk_capital_no_limit` — Лимит отсутствует

Contract:

- один раз за крупную story stage;
- разрешает допустимый Capital action независимо от фактической цены;
- action всё равно должен быть authored как допустимый Capital solution;
- результат должен физически/сценически остаться в мире;
- не означает бесконечные Деньги.

Owners:

```text
MODULE 09
MODULE 11/12
```

Usage scope хранит story/date context.

---

# 59. EFFECT CONTRACTS — Аура

## `perk_aura_presence_registered` — Присутствие зарегистрировано

Contract:

- открывает специальные Aura actions по требованиям уровня;
- открывает sigma contests.

Owners:

```text
MODULE 06
MODULE 07C
MODULE 09
```

---

# 60. `perk_aura_dont_blink_first` — Не моргать первым

Contract:

- первая ошибка удержания за sigma contest не уменьшает уже набранный progress;
- ошибка может иметь визуальную реакцию, но накопленный progress сохраняется.

Owner:

```text
MODULE 07C
```

---

# 61. `perk_aura_silence_longer` — Молчание длиннее нормы

Contract:

- один раз за sigma contest;
- соперник на короткое время прекращает создавать disturbances;
- базовая hold mechanic продолжается.

Owner:

```text
MODULE 07C
```

---

# 62. `perk_aura_reverse_pressure` — Обратное давление

Contract:

- после успешного пережидания/обработки disturbance следующий perfect sigma section даёт дополнительное очко;
- bonus относится к ближайшей подходящей section.

Owner:

```text
MODULE 07C
```

---

# 63. `perk_aura_right_to_say_nothing` — Право первым ничего не говорить

Имеет два canonical применения.

## Dating

- один раз за date;
- герой пропускает выбор приветствия и молчит;
- девушка начинает первой;
- её инициатива даёт дополнительную диагностическую информацию;
- relationship points за это не начисляются.

Owner:

```text
MODULE 09
```

## Rival encounter

- один раз за encounter;
- только если соперник был initiator;
- позволяет заменить выбранный соперником competition type на другой допустимый.

Owner:

```text
MODULE 06
```

---

# 64. `perk_aura_she_already_started` — Она уже начала

Усиливает предыдущий perk.

## Dating

После применения `RIGHT_TO_SAY_NOTHING` первая реакция девушки содержит более явную clue о primary trait.

## Rival

При замене opponent-selected competition не применяется дополнительное наказание Авторитетом, если такое наказание определено MODULE 06.

Owners:

```text
MODULE 06
MODULE 09
```

Не реализовывать отдельный эффект без базового perk.

---

# 65. `perk_aura_atmospheric_influence` — Атмосферное влияние

Contract:

- crowd/observers больше не усложняют Aura hold mechanics;
- присутствие толпы может усиливать только visual presentation/reaction;
- perk не создаёт числовой relationship bonus.

Owners:

```text
MODULE 07C
Presentation
```

---

# 66. `perk_aura_local_significance` — Аура местного значения

Contract:

- один раз за обычный rival encounter;
- заметно более слабый rival может признать поражение до полноценной мини-игры;
- сюжетных соперников пропускать нельзя;
- player должен явно выбрать/подтвердить использование, если future UX допускает ручной запуск;
- это victory path, а не удаление rival из content.

Owner:

```text
MODULE 06
```

Definition of «заметно слабее» задаёт MODULE 06.

---

# 67. Effect ownership matrix

Будущие modules обязаны реализовать следующие perk groups.

## MODULE 06 — Rival Encounter

```text
MUSCLE_HEROIC_DEFEAT
AURA_RIGHT_TO_SAY_NOTHING
AURA_SHE_ALREADY_STARTED
AURA_LOCAL_SIGNIFICANCE

CAPITAL_PAYABLE_INTENT / AURA_PRESENCE_REGISTERED
как access contracts соответствующих competition types
```

---

# 68. MODULE 07A — Slap

```text
MUSCLE_NO_WARMUP
MUSCLE_TOUGH_CHEEK
MUSCLE_DOUBLE_SLAP
MUSCLE_COUNTER_ARGUMENT
MUSCLE_MASS_RESERVE
MUSCLE_TWO_HANDED_ARGUMENT
```

Только те из общих strength perks, которые реально применимы slap contest.

---

# 69. MODULE 07B — Dance

```text
APPEARANCE_STAGED_WALK
APPEARANCE_RHYTHM_IN_BODY
```

---

# 70. MODULE 07C — Sigma

```text
APPEARANCE_POCKET_MIRROR
APPEARANCE_CONTROL_PROFILE

AURA_DONT_BLINK_FIRST
AURA_SILENCE_LONGER
AURA_REVERSE_PRESSURE
AURA_ATMOSPHERIC_INFLUENCE
```

---

# 71. MODULE 07D — Money

Основные Capital access/specific interaction contracts.

```text
CAPITAL_PAYABLE_INTENT
CAPITAL_HOSTILE_ACQUISITION
```

Конкретные денежные special actions MODULE 07D может добавить по своей спецификации, но не менять effect ownership этих perks.

---

# 72. MODULE 08 — Girl Discovery

```text
APPEARANCE_GOOD_PROFILE
```

в части более читаемой visual clue.

---

# 73. MODULE 09 — Dating

```text
MUSCLE_HOLD_DOORWAY
MUSCLE_HEROIC_DEFEAT

APPEARANCE_GOOD_PROFILE
APPEARANCE_SECOND_OUTFIT
APPEARANCE_ENCORE
APPEARANCE_PUBLIC_SIGNIFICANCE

CAPITAL_PAYABLE_INTENT
CAPITAL_REPRESENTATION_EXPENSES
CAPITAL_BUY_PROBLEM
CAPITAL_DIGNITY_REFUND
CAPITAL_NO_LIMIT

AURA_PRESENCE_REGISTERED
AURA_RIGHT_TO_SAY_NOTHING
AURA_SHE_ALREADY_STARTED
```

---

# 74. MODULE 11/12 — Story / World

```text
CAPITAL_HOSTILE_ACQUISITION
CAPITAL_NO_LIMIT
MUSCLE_HOLD_DOORWAY
```

только для authored persistent/world consequences.

---

# 75. MODULE 13 — Salary Mine

```text
CAPITAL_SALARY_ADVANCE
CAPITAL_FINANCIAL_INERTIA
```

---

# 76. Не реализованные effect contracts не считаются багом MODULE 05

После MODULE 05 допустимо:

```text
has_perk(DOUBLE_SLAP) == true
```

но slap minigame ещё отсутствует.

Это нормально.

MODULE 05 считается завершённым, если:

- perk можно корректно купить;
- ownership сохраняется runtime;
- stat вырос;
- contract зафиксирован;
- future owner однозначно известен.

Не создавать fake slap/dating systems для демонстрации эффекта.

---

# 77. Perk tree read model

Future UI нужен простой способ получить дерево без копирования правил.

Semantic API должен позволять:

```text
get_perks_for_characteristic(characteristic)
get_perk_availability(perk_id)
get_next_perk_cost()
has_perk(perk_id)
```

Порядок perks должен быть deterministic:

```text
EARLY_COMMON order1
EARLY_COMMON order2
BRANCH_A order1
BRANCH_A order2
BRANCH_B order1
BRANCH_B order2
LATE_COMMON order1
LATE_COMMON order2
```

UI позже сам раскладывает в ветвящуюся схему.

---

# 78. No UI domain logic

MODULE 05 может создать test progression panel.

Но production purchase rules не должны жить в Button scripts.

Правильно:

```text
button
→ Progression.purchase_perk(id)
→ result
→ refresh UI
```

---

# 79. Minimal test panel

Создать:

```text
res://game/progression/test/progression_test.tscn
```

или соответствующий текущей структуре путь.

Показывать минимум:

- experience;
- upgrade points;
- next cost;
- four characteristic levels;
- 32 perks;
- owned/available/locked state.

Для теста можно иметь кнопку:

```text
+Experience
```

которая вызывает реальный:

```text
GameState.add_experience(...)
```

Это debug scene, не production UI.

---

# 80. Test panel — никаких визуальных инвестиций

Не делать:

- финальный perk tree art;
- fancy animations;
- production icons;
- gamepad navigation;
- tooltips polished UI.

Главная цель — проверка logic.

---

# 81. GameState reset

`reset_for_new_game()` теперь дополнительно:

```text
purchased_perks = empty
```

и сохраняет:

```text
muscle = 0
appearance = 0
capital = 0
aura = 0
```

---

# 82. State validation helper

Добавить debug/self-test validation semantic уровня:

Для каждого characteristic:

```text
stored level == number of purchased perks of this characteristic
```

Для этого Progression layer может использовать ContentDB.

GameState сам не обязан зависеть от ContentDB.

---

# 83. GameState / ContentDB dependency boundary

Сохраняется:

```text
GameState
```

не должен загружать ContentDB для обычного startup/reset.

Progression system использует:

```text
GameState + ContentDB
```

и связывает runtime ownership со static PerkDefinition.

---

# 84. Техническая архитектура Progression

Cursor самостоятельно сравнивает:

1. stateless `ProgressionService` / `RefCounted`;
2. небольшой `Progression` autoload;
3. иной простой native Godot вариант.

Учитывать:

- system имеет мало собственного transient state;
- persistent state уже в GameState;
- static definitions уже в ContentDB;
- purchase/read operations могут быть почти stateless.

Предпочесть более простой вариант.

Не создавать global manager только потому, что слово «система».

Решение зафиксировать в `TECHNICAL_DECISIONS.md`.

---

# 85. No _process

Progression system не требует:

```text
_process
_physics_process
```

Никакого пассивного polling.

---

# 86. No cache drift

Не кешировать:

```text
current_next_cost
available_perks
characteristic_level
```

как mutable state без необходимости.

Эти значения дешёво выводятся из:

- GameState;
- purchased perks;
- ContentDB.

---

# 87. Purchase concurrency

Single-player игра не требует lock/mutex/network transaction.

Но UI double-click / repeated input не должен купить один perk дважды.

Atomic synchronous purchase достаточно.

---

# 88. Invalid content

Если `PerkDefinition` имеет:

- invalid characteristic;
- invalid section;
- unexpected order;
- duplicate structural slot,

MODULE 03/05 validation должна это обнаружить до нормального gameplay.

Purchase не должна пытаться «догадаться».

---

# 89. Дополнительная validation tree structure

Для каждой характеристики проверить ровно:

```text
EARLY_COMMON:
order 1
order 2

BRANCH_A:
order 1
order 2

BRANCH_B:
order 1
order 2

LATE_COMMON:
order 1
order 2
```

Ни одного дополнительного/пропущенного slot.

---

# 90. Canonical 32-perk count

После MODULE 05 production ContentDB всё ещё содержит:

```text
8 MUSCLE
8 APPEARANCE
8 CAPITAL
8 AURA
32 total
```

Не создавать новые perks для уровней 9/10.

---

# 91. Test — starting progression

После reset:

```text
experience = 0
upgrade_points = 0
purchased_perks empty

muscle = 0
appearance = 0
capital = 0
aura = 0

next cost = 1
```

---

# 92. Test — first purchase

Выдать через реальный GameState:

```text
add_experience(1)
```

Получаем:

```text
experience = 1
upgrade_points = 1
```

Купить любой `EARLY_COMMON order1`, например М1.

После:

```text
owned M1 = true
muscle = 1
upgrade_points = 0
next cost = 3
```

---

# 93. Test — global price

Сделать покупки в разных trees:

```text
М1 cost 1
В1 cost 3
К1 cost 9
А1 cost 27
```

После четырёх покупок:

```text
next cost = 81
```

Это подтверждает глобальный, а не per-tree счётчик.

---

# 94. Test — prerequisite

Попытаться купить:

```text
М2
```

без М1.

Ожидается:

```text
PREREQUISITE_NOT_MET
```

Points/stat/state не изменились.

---

# 95. Test — branch opening

После:

```text
М1
М2
```

доступны одновременно:

```text
М3A
М3B
```

---

# 96. Test — branch chain

После:

```text
М1
М2
М3A
```

доступен:

```text
М5A
```

но:

```text
М5B
```

ещё закрыт без М3B.

---

# 97. Test — late unlock via Branch A

После:

```text
М1
М2
М3A
М5A
```

доступен первый late common:

```text
М4
```

при этом Branch B всё ещё можно начать позднее.

---

# 98. Test — late unlock via Branch B

Новая reset-сессия.

После:

```text
М1
М2
М3B
М5B
```

тоже доступен:

```text
М4
```

---

# 99. Test — branch remains purchasable

После выхода в late через Branch A:

```text
М3B
```

всё ещё можно купить при наличии points.

Нет permanent branch lock.

---

# 100. Test — late order

Нельзя купить:

```text
М6
```

без М4.

То же для всех характеристик.

---

# 101. Test — characteristic invariant

После покупки произвольного набора:

```text
muscle
==
owned muscle perk count
```

То же:

```text
appearance
capital
aura
```

---

# 102. Test — points insufficient

Perk structural available, но:

```text
upgrade_points < next cost
```

Availability:

```text
NOT_ENOUGH_POINTS
```

Purchase:

```text
NOT_ENOUGH_POINTS
```

Ничего не меняется.

---

# 103. Test — duplicate purchase

Повторная покупка owned perk:

```text
ALREADY_OWNED
```

- points не списаны;
- stat не увеличен;
- cost sequence не продвинулась.

---

# 104. Test — unknown ID

```text
purchase_perk(&"perk_missing")
```

Ожидается:

```text
UNKNOWN_PERK
```

и понятный debug message.

---

# 105. Test — exact purchase cost sequence

Автоматически проверить первые 10 покупок:

```text
1
3
9
27
81
243
729
2187
6561
19683
```

Не использовать approximate floats.

---

# 106. Test — reset after purchases

После нескольких покупок:

```text
reset_for_new_game()
```

Ожидается полный ноль/empty.

Следующая цена снова:

```text
1
```

---

# 107. Test — signals

Successful purchase:

- `upgrade_points_changed`;
- `characteristic_changed`;
- `perk_purchased`;

каждый в ожидаемом количестве.

Failed purchase:

- не emit-ит ложный `perk_purchased`;
- не emit-ит characteristic change.

---

# 108. Test — all four trees

Automated test проходит canonical progression каждого tree до 8 perks.

Чтобы не требовать реального количества experience, test может выдавать большое количество через `add_experience()`.

После полного дерева:

```text
characteristic == 8
```

---

# 109. Test — all 32

В technical test можно купить все 32.

После:

```text
purchased_perks.size() == 32

muscle == 8
appearance == 8
capital == 8
aura == 8
```

Цена следующей гипотетической покупки может вычисляться, но в production нет 33-го perk.

---

# 110. Test — ContentDB regression

MODULE 03 self-tests:

```text
ALL PASS
```

32 IDs/names/sections не изменены случайно.

---

# 111. Test — GameState regression

MODULE 02 self-tests проходят с новой purchased state.

Обновить expected reset assertions.

---

# 112. Test — Character regression

MODULE 04 Character Framework smoke продолжает работать.

Progression не должен:

- менять appearance автоматически;
- менять animation;
- спавнить персонажей.

---

# 113. Test — FPS regression

Основной FPS test продолжает запускаться.

---

# 114. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
```

Создать при необходимости:

```text
docs/PERK_EFFECT_CONTRACTS.md
```

только если Cursor считает полезным вынести разделы 35–75 из module spec в короткий canonical reference для будущих modules.

Если создаётся этот файл:

- не менять смыслы;
- future module specs должны ссылаться на него;
- не дублировать туда purchase architecture.

---

# 115. Что MODULE 05 НЕ реализует

Категорически не реализовывать:

- финальный perk UI;
- Slap;
- Dance;
- Sigma;
- Money minigame;
- Rival Encounter;
- Girl Discovery;
- Dating;
- salary period;
- passive income;
- wardrobe;
- buying world objects;
- story world ownership;
- authority defeat formula;
- crowd system;
- clue UI;
- respec;
- perk randomization;
- perk rarity;
- perk loot;
- generic effects engine.

---

# 116. Definition of Done

MODULE 05 завершён только если:

- [ ] GameState хранит purchased perk IDs;
- [ ] reset очищает purchased perks;
- [ ] нельзя покупать один perk дважды;
- [ ] уровень характеристики растёт на `+1` за perk той характеристики;
- [ ] произвольная gameplay мутация characteristic закрыта;
- [ ] invariant stat == owned perk count соблюдается;
- [ ] next cost использует global purchased count;
- [ ] последовательность `1,3,9,27...` точна;
- [ ] все четыре дерева используют одну canonical prerequisite rule;
- [ ] early order работает;
- [ ] обе branches открываются после early #2;
- [ ] branches не permanent-exclusive;
- [ ] branch order работает;
- [ ] late #1 открывается после полного A ИЛИ полного B;
- [ ] late #2 требует late #1;
- [ ] недостаток points корректно блокирует purchase;
- [ ] purchase atomic;
- [ ] purchase result сообщает причину;
- [ ] будущие systems имеют простой `has_perk`;
- [ ] нет generic perk effect engine;
- [ ] нет global cooldown manager;
- [ ] effect usage не хранится глобально заранее;
- [ ] exact effect contracts 32 perks сохранены;
- [ ] future owner каждого effect определён;
- [ ] test progression scene/runner существует;
- [ ] all progression tests проходят;
- [ ] MODULE 02 regression проходит;
- [ ] MODULE 03 regression проходит;
- [ ] MODULE 04 regression проходит;
- [ ] FPS regression проходит;
- [ ] donor не изменён;
- [ ] MODULE 06 не реализован заранее.

---

# 117. Порядок выполнения Cursor

## Step 1 — Read

Прочитать:

```text
docs/gdd/03_core_loop.md
docs/gdd/04_male_status_system.md
```

а также:

- MODULE 02;
- MODULE 03;
- MODULE 04;
- PROJECT_STRUCTURE;
- TECHNICAL_DECISIONS.

---

## Step 2 — Audit current PerkDefinition

Проверить фактические:

- section;
- order;
- IDs;
- description;
- ContentDB API.

Не менять canonical 32 assets без необходимости.

---

## Step 3 — Choose Progression technical architecture

Сравнить stateless service vs autoload.

Выбрать best practice для текущего проекта.

Не спрашивать пользователя о чисто техническом выборе.

---

## Step 4 — Extend runtime state

Добавить purchased perks и atomic characteristic ownership invariant.

---

## Step 5 — Implement cost

Добавить exact integer global cost.

---

## Step 6 — Implement tree rules

На основании:

```text
characteristic
section
order
```

без generic prerequisite DSL.

---

## Step 7 — Implement purchase/query API

Добавить:

- availability;
- purchase result;
- purchase;
- has_perk;
- list/query helpers для будущего UI.

---

## Step 8 — Lock characteristic mutation

Убедиться, что никакой обычный gameplay API не может расходиться с purchased perk count.

---

## Step 9 — Effect contracts

Перенести canonical effect reference в docs, если это помогает будущим modules.

НЕ реализовывать consumers.

---

## Step 10 — Test runner/panel

Прогнать весь tree и purchase matrix.

---

## Step 11 — Regressions

Обязательно:

```text
MODULE 02
MODULE 03
MODULE 04
FPS
```

---

## Step 12 — Documentation

Обновить фактическую структуру и technical decision.

---

# 118. Формат финального отчёта Cursor

## Architecture

Как реализован Progression и почему.

## Runtime state changes

Что добавлено в GameState.

## Tree behavior

Подтвердить:

```text
early 1 -> early 2
-> A1 -> A2
OR
-> B1 -> B2
-> late 1 -> late 2

branches remain purchasable later
```

## Cost

Подтвердить первые значения:

```text
1 / 3 / 9 / 27 / 81 / 243
```

и что счётчик общий на все деревья.

## Characteristic invariant

Подтвердить:

```text
1 purchased perk = +1 level
```

## Effect architecture

Подтвердить:

- ownership реализован;
- effects не эмулируются fake systems;
- contracts закреплены для future owners.

## Validation

Результаты progression tests + regressions.

## Files changed

Основные файлы.

## Product questions

Только реальные неразрешимые продуктовые вопросы.

Если нет:

```text
None.
```

---

# 119. Запрет продолжения

После успешного MODULE 05:

**НЕ начинать MODULE 06 — Rival Encounter Framework.**

Остановиться и дождаться отдельной спецификации.
