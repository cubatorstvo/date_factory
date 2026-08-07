# MODULE 13 — SALARY MINE & MONEY LOOP

**Проект:** Date Factory  
**Модуль:** 13 — Salary Mine & Money Loop  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать раннюю/среднюю денежную линию героя: зарплатный разряд от Авторитета, физическое получение накопленной зарплаты в шахте, единый минимальный игровой день для cooldown/зарплатных периодов и антигринд через `Зарплата вперёд` + `Финансовая инерция`  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/03_core_loop.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`, `docs/tech/TECH_PLAN_FULL.md`  
**Предыдущие модули:** MODULE 02, MODULE 06, MODULE 11, MODULE 12  
**Следующий модуль:** MODULE 14 — Stage Content: Manual Game

---

# 0. ГЛАВНАЯ ИДЕЯ

Деньги в ручной части:

```text
Авторитет
→ зарплатный разряд
→ зарплата за период
→ физически накопилась в зарплатной шахте
→ игрок забрал её
→ Деньги
```

Позже ручная необходимость уменьшается:

```text
Зарплата вперёд
→ можно забрать накопленную выплату удалённо

Финансовая инерция
→ часть каждой новой выплаты автоматически попадает на баланс
```

Это НЕ:

- job simulator;
- mining simulator;
- clicker;
- tycoon;
- бухгалтерская RPG.

---

# 1. Что уже канонично

Из GDD:

```text
Деньги = расходуемая валюта
Авторитет = определяет зарплатный уровень
ранние Деньги физически связаны с зарплатной шахтой
ручной сбор позже должен уменьшаться / заменяться пассивным доходом
```

MODULE 13 НЕ меняет существующие Money APIs других систем.

Dating, Money Contest и будущие systems продолжают использовать:

```text
GameState.get_money()
GameState.add_money()
GameState.can_afford()
GameState.spend_money()
```

или фактические canonical names.

---

# 2. Story gate

Salary Mine доступна через уже реализованный:

```text
StoryFeature.SALARY_MINE
```

который открывается при:

```text
GameStage.STAGE_3
```

MODULE 13 НЕ меняет этот threshold.

До unlock:

- SalaryMine service существует;
- новые salary periods не начисляются;
- remote advance недоступен;
- физическая шахта уже blocked MODULE 12.

---

# 3. Почему нужен минимальный `GameDay`

MODULE 08 и MODULE 10 уже используют:

```text
1–3 игровых дня
```

для:

- повторной попытки знакомства;
- повторного свидания.

MODULE 13 вводит ещё:

```text
salary period = один игровой день
```

Три независимых «уведомления о дне» дальше являются лишним источником double-decrement bugs.

Поэтому MODULE 13 добавляет только очень маленький:

```text
GameDay
```

---

# 4. `GameDay` НЕ является Time System

`GameDay` НЕ реализует:

- часы;
- минуты;
- время суток;
- расписания;
- day/night;
- календарные даты;
- NPC schedules;
- real-time ticking;
- sleep needs;
- hunger;
- automatic time passage.

Это только:

```text
integer day index
+
explicit advance_day()
+
day_advanced signal
```

---

# 5. GameDay API

Canonical autoload:

```text
GameDay
```

Минимально:

```text
signal day_advanced(new_day: int)

var current_day: int = 1

func get_current_day() -> int
func advance_day() -> int
```

---

# 6. Day advance

```text
advance_day()
```

делает:

```text
current_day += 1
day_advanced.emit(current_day)
return current_day
```

Один вызов = ровно один игровой день.

---

# 7. Reset

`GameDay` слушает:

```text
GameState.state_reset
```

и делает:

```text
current_day = 1
```

Не emit fake `day_advanced` при reset.

---

# 8. GameDay autoload order

Обновить production order:

```text
GodotIQRuntime
GameState
ContentDB
Progression
GameDay
RivalEncounters
RivalCompetitionRunner
GirlDiscovery
DatingCore
Relationships
Story
World
SalaryMine
```

`GameDay` должен существовать до `_ready()`:

```text
GirlDiscovery
Relationships
```

чтобы они могли подписаться.

---

# 9. MODULE 08 migration

`GirlDiscovery` на `_ready()` подписывается:

```text
GameDay.day_advanced
```

и вызывает существующую логику:

```text
notify_game_day_advanced()
```

или приватный equivalent.

Старый public method можно сохранить для tests.

Production owner дня:

```text
GameDay
```

---

# 10. MODULE 10 migration

`Relationships` аналогично подписывается:

```text
GameDay.day_advanced
```

и уменьшает date cooldown один раз.

---

# 11. Запрет двойного decrement

Не должно одновременно происходить:

```text
GameDay signal
+
World manually calls GirlDiscovery.notify...
+
UI manually calls Relationships.notify...
```

Production day advancement идёт только:

```text
GameDay.advance_day()
```

---

# 12. Functional day advance in apartment

Чтобы система уже была играбельной без будущего модуля, в apartment добавить простой interactable:

```text
DayAdvanceInteractable
```

Prompt:

```text
[E] Завершить день
```

---

# 13. Что делает `Завершить день`

При interaction:

1. блокирует повторный input;
2. optional короткий black fade / functional overlay;
3. вызывает:
   ```text
   GameDay.advance_day()
   ```
4. показывает:
   ```text
   День N
   ```
   примерно `0.5–1.0 s`;
5. возвращает GAMEPLAY.

---

# 14. Это не сон-механика

Не создавать:

- сон;
- энергию;
- кровать как обязательную RPG system;
- штрафы за поздний день.

Позже MODULE 14/22 может визуально привязать interaction к кровати/дивану.

Сейчас semantic:

```text
Завершить день
```

---

# 15. Day advance restrictions

Разрешать только когда Player:

```text
ControlMode.GAMEPLAY
```

Нельзя во время:

- Phone;
- Dating;
- Rival;
- minigame;
- modal UI.

---

# 16. Day advance location

Production interactable находится только:

```text
apartment
```

GameDay API технически доступен tests/future systems откуда угодно.

---

# 17. SalaryMine service

Создать canonical autoload:

```text
SalaryMine
```

Ответственность:

- salary level;
- gross payout;
- salary periods;
- pending payout;
- passive part;
- manual claim;
- Salary Advance;
- signals/read models.

Не создавать:

```text
SalaryManager
EconomyManager
PayrollManager
MineManager
PassiveIncomeManager
```

---

# 18. Salary state ownership

Rules:

```text
SalaryMine
```

Persistent/runtime passage data:

```text
GameState
```

Money itself:

```text
GameState.money
```

---

# 19. GameState salary fields

Добавить minimal:

```text
_salary_initialized: bool = false
_salary_period_index: int = 0
_pending_salary: int = 0
_salary_manual_cycle_seen: bool = false
_salary_advance_used_period: int = -1
```

---

# 20. Не хранить derived salary level

НЕ хранить persistent:

```text
salary_level
salary_amount
```

Они всегда derived от текущего:

```text
Authority
```

---

# 21. GameState salary API

Минимально:

```text
is_salary_initialized() -> bool
mark_salary_initialized() -> bool

get_salary_period_index() -> int
advance_salary_period_index() -> int

get_pending_salary() -> int
add_pending_salary(amount: int)
take_all_pending_salary() -> int

has_seen_manual_salary_cycle() -> bool
mark_manual_salary_cycle_seen() -> bool

get_salary_advance_used_period() -> int
set_salary_advance_used_period(period_index: int)
```

Можно уменьшить число public methods через controlled SalaryMine commit methods, если code остаётся ясным.

---

# 22. Reset

GameState reset:

```text
salary_initialized = false
salary_period_index = 0
pending_salary = 0
manual_cycle_seen = false
salary_advance_used_period = -1
```

Money reset остаётся существующим правилом.

---

# 23. Salary level formula — EXACT

Canonical implementation:

```text
salary_level =
1 + floor(authority / 3)
```

Integer equivalent:

```text
1 + authority / 3
```

при integer division.

---

# 24. Salary examples

```text
Authority 0..2
→ level 1

Authority 3..5
→ level 2

Authority 6..8
→ level 3

Authority 9..11
→ level 4

Authority 12..14
→ level 5
```

No hard max.

---

# 25. Gross salary formula — EXACT

```text
gross_salary_per_period =
10 * salary_level
```

Examples:

```text
Authority 0
→ level1
→ 10

Authority 3
→ level2
→ 20

Authority 8
→ level3
→ 30

Authority 12
→ level5
→ 50
```

Balance numbers MODULE 26 may adjust later.

Structure stays simple.

---

# 26. Authority loss

Если Authority уменьшился:

```text
salary_level
```

может уменьшиться.

Это нормально.

Новый уровень используется только для **следующей открываемой salary period**.

Уже накопленный:

```text
pending_salary
```

не пересчитывается назад.

---

# 27. Salary level signal

SalaryMine слушает:

```text
GameState.authority_changed
```

или фактический signal.

Если derived level изменился:

```text
salary_level_changed(new_level, old_level)
```

No Money payment immediately.

---

# 28. Salary period

Один salary period открывается:

```text
на каждый GameDay.day_advanced
```

после unlock Salary Mine.

---

# 29. Initial salary period

Чтобы первый визит в шахту не был пустым:

при первом переходе feature:

```text
SALARY_MINE locked → unlocked
```

создать одну initial salary period немедленно.

То есть после Stage2 completion / entering STAGE3:

```text
pending payout > 0
```

без необходимости сначала завершать ещё один день.

---

# 30. Restore/start already unlocked

На `SalaryMine._ready()`:

если:

```text
Story.is_feature_unlocked(SALARY_MINE)
AND
!GameState.is_salary_initialized()
```

создать initial period.

Это покрывает future restore/debug stage.

---

# 31. One period algorithm

`_open_salary_period()`:

1. verify Salary feature unlocked;
2. if first:
   ```text
   mark initialized
   ```
3. increment:
   ```text
   salary_period_index += 1
   ```
4. derive:
   ```text
   level
   gross
   ```
5. calculate passive part;
6. add passive directly to Money;
7. add remainder to pending salary;
8. emit typed/report signal.

---

# 32. Pending salary accumulates

Если игрок не ходил в шахту несколько дней:

```text
pending_salary
```

суммируется.

Не:
- теряется;
- заменяется только последней выплатой;
- имеет artificial cap.

Это уже уменьшает обязательность ежедневного похода.

---

# 33. Example accumulation

Без Financial Inertia:

```text
day salary 20
day salary 20
day salary 20
```

игрок не забирал.

Expected:

```text
pending_salary = 60
Money unchanged
```

Один следующий manual claim:

```text
+60 Money
pending = 0
```

---

# 34. Salary period read model

Создать typed:

```text
SalaryStatus
```

или equivalent.

Минимально:

```text
unlocked: bool

authority
salary_level
gross_per_period

period_index
pending_salary

manual_cycle_seen

passive_enabled
passive_per_period

salary_advance_owned
salary_advance_available
salary_advance_used_this_period
```

Phone/UI читает snapshot.

---

# 35. Physical salary station

В существующей:

```text
salary_mine.tscn
```

на/около marker:

```text
story_point_salary_station
```

создать physical:

```text
SalaryStation
```

extends existing `Interactable`.

---

# 36. Salary Station prompt

Если feature unavailable — сама location недоступна, поэтому normal case unlocked.

Если pending > 0:

```text
[E] Добыть зарплату — <amount>
```

Если pending == 0:

```text
[E] Зарплата ещё не выросла
```

или:

```text
Выплата уже добыта
```

Prompt может быть read-only/interaction feedback.

---

# 37. Manual salary cycle

Manual claim не должен быть просто мгновенным +Money click.

Нужна короткая физическая «шахтная шутка», но без отдельной minigame.

Canonical flow:

```text
E
→ 1.50 s "ДОБЫЧА ЗАРПЛАТЫ"
→ payout
→ "ЗАРПЛАТА ДОБЫТА: +X"
```

---

# 38. Manual cycle control

На `1.50 s`:

```text
PlayerControlMode.MODAL_UI
```

Mouse look/movement blocked.

UI — небольшой progress bar / label.

После complete:

```text
GAMEPLAY
```

---

# 39. No skill check

Manual salary:

- нельзя провалить;
- нет timing;
- нет mash;
- нет hidden RNG.

Комедия — в физическом факте добычи зарплаты, а не в повторяемой сложности.

---

# 40. Manual claim commit

В момент completion:

```text
amount =
GameState.take_all_pending_salary()
```

Если:

```text
amount > 0
```

то:

```text
GameState.add_money(amount)
GameState.mark_manual_salary_cycle_seen()
```

---

# 41. Snapshot amount vs current pending

При старте 1.5s cycle допустимо snapshot-нуть visible amount.

Но commit должен быть safe.

Предпочтительно:

- block DayAdvance while salary modal active;
- pending не меняется во время cycle;
- then `take_all`.

Не создавать locking framework.

---

# 42. Exactly-once manual claim

Double input / repeated callback не может:

- начислить payout дважды;
- mark cycle twice with extra effects.

Station busy guard.

---

# 43. Empty claim

Если pending 0:

- не входить в 1.5s modal;
- показать short feedback;
- Money unchanged;
- manual-cycle-seen НЕ меняется.

---

# 44. First manual joke seen

Persistent:

```text
salary_manual_cycle_seen
```

становится true только после:

```text
успешного manual claim amount > 0
```

Remote Salary Advance НЕ устанавливает этот flag.

---

# 45. Почему manual cycle обязателен перед пассивом

Perk contract:

> автоматический поток включается только после того, как шахтная шутка была показана вручную.

Игрок должен хотя бы раз реально сходить в шахту и добыть зарплату.

---

# 46. CAPITAL_SALARY_ADVANCE

Perk:

```text
PerkIds.CAPITAL_SALARY_ADVANCE
```

Contract:

> один раз за salary period можно забрать ближайшую доступную выплату без личного похода.

---

# 47. Salary Advance не создаёт деньги

Remote claim использует только:

```text
pending_salary
```

Нельзя:

- брать следующий день заранее;
- дублировать будущую выплату;
- создавать кредит.

---

# 48. Advance availability

Available если одновременно:

```text
StoryFeature.SALARY_MINE unlocked
perk owned
pending_salary > 0
salary_advance_used_period != current_salary_period_index
```

---

# 49. Salary Advance claim

```text
claim_salary_advance()
```

атомарно:

1. revalidate;
2. `amount = take_all_pending_salary()`;
3. `GameState.add_money(amount)`;
4. `set_salary_advance_used_period(current_period_index)`;
5. emit result.

---

# 50. Claim ALL accumulated pending

Если накопилось несколько salary periods:

```text
pending = 80
```

Salary Advance забирает:

```text
все 80
```

за одно использование текущего salary period.

Не вводить очередь отдельных payroll envelopes.

---

# 51. Once per salary period

После remote claim:

```text
used_period = current period
```

Повторно до следующего:

```text
GameDay.advance_day()
```

нельзя.

---

# 52. Manual claim после Salary Advance

После remote claim pending=0.

Manual station:
- ничего не выдаёт;
- manual cycle seen не появляется.

Если player хочет открыть Financial Inertia, он должен в другом period хотя бы раз забрать salary физически.

Это намеренно сохраняет ценность шахтной шутки.

---

# 53. Manual claim does not consume Salary Advance

Если player вручную забрал payout:

```text
salary_advance_used_period
```

не меняется.

Но pending=0, так что remote claim просто нечего забирать.

Если в новом period появляется pending, Salary Advance снова available.

---

# 54. Phone integration

Расширить existing:

```text
PhoneJournal
```

маленькой functional salary section.

Показывать её только если:

```text
StoryFeature.SALARY_MINE unlocked
```

---

# 55. Phone salary section

Минимально:

```text
ЗАРПЛАТА

Авторитет: A
Разряд: L
За период: G
Накоплено: P
```

Если passive active:

```text
Автоматически: X / период
```

---

# 56. Salary Advance button

Если perk owned:

```text
[Получить зарплату вперёд]
```

Button enabled только по availability.

Рядом:

```text
Получить <pending>
```

---

# 57. Salary Advance feedback

Success:

```text
Получено удалённо: +X
```

Failed availability:

- `Нет накопленной выплаты`;
- `Уже использовано в этом периоде`;
- `Нужен перк`.

No raw technical IDs.

---

# 58. Phone is not mine substitute by default

Без:

```text
CAPITAL_SALARY_ADVANCE
```

Phone salary section только read-only.

Игрок видит накопление, но забирает деньги физически в шахте.

---

# 59. CAPITAL_FINANCIAL_INERTIA

Perk:

```text
PerkIds.CAPITAL_FINANCIAL_INERTIA
```

---

# 60. Exact activation

Passive salary active только если:

```text
perk owned
AND
salary_manual_cycle_seen == true
AND
SALARY_MINE feature unlocked
```

---

# 61. Passive share — EXACT

При каждом НОВОМ salary period:

```text
passive_amount =
floor(gross_salary * 0.25)
```

Integer.

---

# 62. Pending remainder — EXACT

```text
manual_amount =
gross_salary - passive_amount
```

Then:

```text
GameState.add_money(passive_amount)
GameState.add_pending_salary(manual_amount)
```

---

# 63. No money loss from rounding

Всегда:

```text
passive_amount + manual_amount == gross_salary
```

---

# 64. Example inertia

Gross:

```text
20
```

Expected:

```text
passive = 5
pending += 15
```

Gross:

```text
30
```

Expected:

```text
passive = 7
pending += 23
```

---

# 65. Inertia not retroactive

Если perk куплен при:

```text
pending = 100
```

эти 100 не делятся задним числом.

Passive применяется только к будущим opened periods.

---

# 66. Manual flag not retroactive

Если player владел Financial Inertia до первого mine visit:

до manual cycle:

```text
passive = 0
```

После первого successful manual claim:

следующий period:

```text
passive 25%
```

---

# 67. Anti-grind hierarchy

MODULE 13 даёт три последовательных уровня convenience:

## Base

```text
salary accumulates
→ можно ходить в шахту не каждый день
```

## Salary Advance

```text
можно забрать накопленное удалённо один раз/period
```

## Financial Inertia

```text
25% каждой новой выплаты приходит автоматически
```

Late-game clone economy MODULE 18 позже даёт другой масштаб.

---

# 68. Financial Inertia is not clones

Не использовать:

```text
GameState.money_per_minute
clones_working
```

для salary passive flow.

Clone economy остаётся MODULE 18.

---

# 69. No real-time passive income

Financial Inertia НЕ начисляет:

```text
money per second
```

и не использует `_process()`.

Passive salary начисляется дискретно:

```text
on salary period / GameDay advance
```

Это проще и не требует offline calculation.

---

# 70. SalaryMine event-driven

Никакого `_process()`.

Подписки:

```text
GameDay.day_advanced
Story.feature_unlocked
GameState.authority_changed
GameState.state_reset
```

---

# 71. Signals

Нужны semantic, например:

```text
salary_level_changed(new_level, old_level)

salary_period_opened(status)
salary_pending_changed(amount)

salary_claimed(amount, method)
passive_salary_paid(amount)

manual_salary_cycle_seen()
```

Не создавать EventBus.

---

# 72. SalaryClaimMethod

Если typed enum полезен:

```text
MANUAL_MINE
SALARY_ADVANCE
```

Ровно.

---

# 73. Salary claim result

Typed:

```text
SalaryClaimResult
```

Минимально:

```text
ok
error

method
amount

pending_after
money_after

period_index
manual_cycle_first_time
```

---

# 74. Error codes

Minimal semantic:

```text
OK
LOCKED
NO_PENDING
PERK_REQUIRED
ADVANCE_ALREADY_USED
BUSY
```

Не создавать generic economy error framework.

---

# 75. Initial period + Financial Inertia

Если feature unlock happens и player уже:

```text
owns Financial Inertia
manual_cycle_seen == true
```

initial period также использует passive 25%.

Это может происходить только debug/restore, потому что normal play не видел mine before unlock.

---

# 76. Stage downgrade debug

Если player debug-restores stage ниже STAGE3:

- existing pending salary сохраняется;
- new salary periods не открываются;
- remote Salary Advance locked;
- mine physical travel already blocked after leaving.

Не auto-delete earned pending.

---

# 77. Stage re-unlock

Если debug returns to STAGE3:

если:

```text
salary_initialized == true
```

не создавать второй free initial period.

Следующая зарплата только через GameDay advance.

---

# 78. Salary level display after Authority change

Phone/status immediately показывает новый derived level.

Но current pending не пересчитывается.

---

# 79. Authority gain after current period

Example:

```text
period opened at Authority 5
gross 20
pending +=20

then Authority 6
level becomes3
```

Pending остаётся 20.

Next day:

```text
gross 30
```

---

# 80. Authority loss example

```text
Authority 6 → level3
period gross30
then lose Authority to5 → level2
```

Pending30 stays.

Next period gross20.

---

# 81. Capital stat does NOT determine salary

Не использовать:

```text
CAPITAL characteristic
```

для gross salary.

Salary level определяется:

```text
Authority
```

по GDD.

Capital perks только меняют способ получения/автоматизации.

---

# 82. Experience does NOT determine salary

Не использовать Experience.

---

# 83. Stage does NOT multiply salary

После unlock stage only enables system.

STAGE4/5 themselves do not automatically multiply salary.

Рост идёт через Authority.

---

# 84. No random salary

Нет:

```text
±10%
bonus chance
critical paycheck
```

Формула deterministic.

---

# 85. Salary station visual

MODULE 12 blockout можно слегка дополнить:

- рычаг;
- щель/ящик;
- подпись:
  ```text
  ЗАРПЛАТНАЯ ЖИЛА
  ```
- simple cash/envelope placeholder.

No final art.

---

# 86. Manual cycle presentation

На completion допустимо:

- placeholder object rises from chute;
- simple tween;
- text `+X`.

Но payout НЕ зависит от animation.

MODULE 23 later polish.

---

# 87. No physical cash inventory

Не создавать pickup item с отдельным Money object state.

После cycle payout сразу:

```text
GameState.money += amount
```

Physical envelope — presentation-only.

---

# 88. No mine resource

Не создавать валюты:

```text
Ore
SalaryOre
WorkPoints
ShiftTokens
```

Только Money.

---

# 89. No shift energy

Не создавать:

- stamina;
- work capacity;
- fatigue;
- shift count.

---

# 90. No grind exploit through E

Manual station забирает только accrued:

```text
pending_salary
```

Повторное E после payout даёт 0.

Новые деньги появляются только:

```text
new salary period
```

---

# 91. No grind exploit through day input spam

Player может завершать дни подряд, но это одновременно:

- двигает girl cooldowns;
- двигает date cooldowns;
- создаёт salary periods.

Это нормальная абстракция текущего ручного прототипа.

MODULE 14 позже может встроить meaningful daily pacing/content.

Не добавлять artificial cooldown в реальных секундах.

---

# 92. GameDay display in Phone — optional

Можно добавить:

```text
День N
```

в Phone header/debug.

Не mandatory.

---

# 93. GameDay and World

World НЕ меняет day при travel.

Переход:

```text
apartment → city → mine → apartment
```

можно делать сколько угодно в одном game day.

---

# 94. Dating does not auto-advance day

MODULE 13 НЕ решает, сколько времени занимает date.

Date completion сам по себе НЕ вызывает:

```text
GameDay.advance_day()
```

Это product pacing MODULE 14.

Пока player явно завершает день в apartment.

---

# 95. Rival does not auto-advance day

То же.

---

# 96. Salary period claim timing

В текущем day можно:

- получить salary;
- участвовать в событиях;
- вернуться;
- День не меняется.

Следующая salary period появляется только после explicit `advance_day`.

---

# 97. No salary before Story unlock

Если debug calls:

```text
GameDay.advance_day()
```

на STAGE1:

SalaryMine:
```text
does nothing
period_index remains0
pending0
```

Girl cooldowns всё равно двигаются.

---

# 98. Initial unlock exactly once

At transition:

```text
STAGE2 → STAGE3
```

Expected:

```text
salary_initialized true
period_index 1
one gross payout accrued
```

Story may emit both stage and feature signals.

Guard prevents double initialization.

---

# 99. Autoload duplicate signal protection

Every service uses:

```text
is_connected
```

or equivalent.

F5 boot/scene travel does not double-subscribe.

---

# 100. GameState Money integration

MODULE 13 NEVER writes:

```text
_money
```

directly outside GameState.

Use canonical:

```text
add_money
```

for:
- passive salary;
- manual claim;
- Salary Advance.

---

# 101. Pending salary nonnegative

GameState API guarantees:

```text
pending_salary >= 0
```

`take_all` atomically returns previous amount and sets 0.

---

# 102. Period index monotonic

After initialization:

```text
1,2,3...
```

No decrement during gameplay.

Reset returns0.

---

# 103. Salary Advance usage index

Default:

```text
-1
```

After use period3:

```text
3
```

At period4 availability returns naturally because:

```text
used_period != current_period
```

No explicit reset bool needed.

---

# 104. Perk purchase mid-period — Salary Advance

If player buys `CAPITAL_SALARY_ADVANCE` mid-period and pending >0:

button immediately becomes available if not used this period.

This is allowed.

---

# 105. Perk purchase mid-period — Financial Inertia

No retroactive passive.

Starts next opened period after both:
- perk owned;
- manual cycle seen.

---

# 106. Phone refresh

Phone salary section refreshes on:

```text
money_changed
authority_changed
salary_period_opened
salary_pending_changed
salary_claimed
perk_purchased
```

или simple refresh when journal opens + relevant signals.

No `_process()`.

---

# 107. Salary station prompt refresh

Query current status when interaction prompt is requested / after salary signals.

No stale amount.

---

# 108. Existing Story World access unchanged

MODULE 13 does NOT manually unlock:

```text
salary_mine
```

World continues to derive from:

```text
StoryFeature.SALARY_MINE
```

---

# 109. Existing marker contract

Использовать existing MODULE 12:

```text
story_point_salary_station
```

Если фактический ID уже немного другой, Cursor сначала audit и переиспользует его.

Не создавать duplicate station marker рядом без причины.

---

# 110. Production boot

После MODULE 13 F5:

```text
main
→ World
→ apartment
```

как после MODULE12 fix.

GameDay/SalaryMine autoloads не должны ломать boot.

---

# 111. Functional early loop test

Debug/fixture route:

1. restore/set Story to STAGE3;
2. Salary initial period appears;
3. apartment → city → salary_mine;
4. SalaryStation shows pending;
5. E;
6. 1.5s manual cycle;
7. Money increases;
8. manual cycle seen;
9. return apartment;
10. `Завершить день`;
11. new payout accrues;
12. return mine or use Salary Advance if owned.

Это основной MODULE13 vertical test.

---

# 112. Test — GameDay reset

Initial:

```text
day1
```

advance:

```text
2
```

GameState reset:

```text
1
```

No fake day_advanced.

---

# 113. Test — discovery cooldown integration

Set discovery cooldown3.

One:

```text
GameDay.advance_day()
```

Expected:

```text
2
```

not1.

---

# 114. Test — date cooldown integration

Date cooldown3.

One day:

```text
2
```

Exactly once.

---

# 115. Test — both cooldowns same day

Discovery3 + Date2.

One advance:

```text
2
1
```

---

# 116. Test — level formula

Exact:

```text
Authority0 →1
2→1
3→2
5→2
6→3
11→4
12→5
```

---

# 117. Test — gross formula

```text
level1 →10
level2 →20
level5 →50
```

---

# 118. Test — locked no salary

At STAGE2:

```text
GameDay.advance_day()
```

Expected:

```text
initialized false
period0
pending0
```

---

# 119. Test — initial period

Transition to STAGE3.

Assume Authority6:

```text
level3
gross30
period1
pending30
```

without inertia.

---

# 120. Test — initialization idempotent

Multiple:
- feature signals;
- `_ensure_initialized`;
- World travels.

Still:

```text
period1
```

not2/3.

---

# 121. Test — accumulation

Gross20.

Three periods unclaimed:

```text
pending60
```

---

# 122. Test — Authority change next period only

Current pending20.

Authority crosses tier.

Pending remains20.

Next period adds new tier amount.

---

# 123. Test — Authority loss

Same reverse.

---

# 124. Test — manual empty

Pending0.

Interact:

```text
no modal cycle
money unchanged
manual_seen false
```

---

# 125. Test — manual claim

Pending60.

After cycle:

```text
pending0
money +60
manual_seen true
```

---

# 126. Test — manual exactly once

Duplicate callback:

```text
only +60 total
```

---

# 127. Test — manual flag only positive payout

Pending0 never sets seen.

---

# 128. Test — Financial Inertia before manual

Own perk.

manual_seen=false.

Gross20:

```text
passive0
pending+20
```

---

# 129. Test — Financial Inertia after manual

Own perk + seen.

Gross20:

```text
Money +5
pending +15
```

---

# 130. Test — inertia rounding

Gross30:

```text
floor(7.5)=7
pending23
total30
```

---

# 131. Test — no retroactive inertia

Pending100 before perk.

Buy perk.

Pending remains100.

---

# 132. Test — Salary Advance no perk

Pending20.

Expected:

```text
PERK_REQUIRED
money unchanged
```

---

# 133. Test — Salary Advance success

Period4.
Pending50.
Perk owned.

Expected:

```text
claim50
pending0
used_period4
money+50
```

---

# 134. Test — Salary Advance duplicate same period

After first use, even if test injects pending:

```text
ADVANCE_ALREADY_USED
```

No second claim.

---

# 135. Test — Salary Advance next period

Open period5.

Expected:

```text
available again
```

if pending>0.

---

# 136. Test — Salary Advance claims accumulated pending

Pending80 from several periods.

Current period unused.

Expected:

```text
+80
pending0
```

---

# 137. Test — remote does not set manual seen

After Salary Advance:

```text
manual_seen remains false
```

if it was false.

---

# 138. Test — manual claim does not consume advance

Manual claim period3.

`used_period` remains previous/default.

---

# 139. Test — Phone section locked

Before STAGE3:

salary section hidden.

---

# 140. Test — Phone section unlocked

STAGE3:

shows exact:
- Authority;
- level;
- gross;
- pending.

---

# 141. Test — Phone Salary Advance button

No perk:
- no working button / requirement visible.

Perk owned + available:
- enabled.

After use:
- disabled current period.

---

# 142. Test — Station prompt

Pending30:

```text
amount30
```

After claim:
```text
empty state
```

---

# 143. Test — `Завершить день`

Apartment E:

```text
GameDay advances exactly1
Player returns GAMEPLAY
```

---

# 144. Test — cannot day advance during modal

Phone open/minigame:
- interaction cannot fire.

---

# 145. Test — travel no day change

Apartment→mine→city:

```text
current_day unchanged
salary period unchanged
```

---

# 146. Test — no Salary Money through `_process`

Run idle frames:

Money/pending unchanged.

---

# 147. Test — no clone state mutation

MODULE13 never changes:

```text
total_clones
clones_working
clones_dating
money_per_minute
dates_per_minute
```

---

# 148. Test — existing Money systems

After salary claim:

Money Contest can spend that balance.

Dating paid actions can spend it.

No separate salary currency.

---

# 149. Test — reset salary

After accrued/claimed state, reset:

```text
initialized false
period0
pending0
manual_seen false
advance_used -1
```

---

# 150. Test — production F5 regressions

F5:
- apartment loads;
- Player gameplay;
- Phone works;
- End Day works;
- no legacy bootstrap.

---

# 151. Regression MODULE 08

Girl discovery day cooldown now production-driven via GameDay.

All existing tests pass.

---

# 152. Regression MODULE 10

Relationship date cooldown production-driven via GameDay.

No double decrement.

---

# 153. Regression MODULE 11/12

Story access/world travel unchanged.

SalaryMine does not mutate stage/location unlocks.

---

# 154. Regression MODULE 07D/09

Money spending/refund remains correct.

Salary just adds Money through GameState.

---

# 155. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
docs/gdd/03_core_loop.md
docs/gdd/04_male_status_system.md
```

---

# 156. Perk contracts update — exact

`CAPITAL_SALARY_ADVANCE`:

```text
Salary Mine unlocked only.
Once per salary period.
Remote claim of ALL currently accumulated pending salary.
Does not create future payout.
Does not mark manual cycle seen.
```

`CAPITAL_FINANCIAL_INERTIA`:

```text
After at least one successful manual salary collection,
25% floor of each future gross salary period is deposited automatically;
remaining gross stays pending for manual/advance collection.
```

---

# 157. TECH decision — GameDay

Document:

```text
GameDay is explicit day-index broadcaster only.
No time-of-day.
Production day progression occurs only via GameDay.advance_day().
GirlDiscovery/Relationships/SalaryMine subscribe.
```

---

# 158. PROJECT_STRUCTURE expected area

Semantic:

```text
game/day/
├── game_day.gd
└── day_advance_interactable.gd

game/salary/
├── salary_mine.gd
├── salary_types.gd
├── salary_status.gd
├── salary_claim_result.gd
├── salary_station.gd
└── test/
```

Exact folder naming may follow repo conventions.

---

# 159. What MODULE 13 DOES NOT implement

Не реализовывать:

- clone income;
- money/minute;
- offline earnings;
- stock market;
- bank;
- debt;
- loans;
- salary negotiation;
- job choices;
- multiple employers;
- mining resources;
- ore;
- work stamina;
- shift productivity;
- employee management;
- taxes;
- random salary bonuses;
- salary equipment upgrades;
- stage-specific salary multiplier;
- real-time passive income;
- full TimeManager;
- time-of-day;
- schedules;
- automatic date-day consumption;
- production NPC content;
- final UI polish.

---

# 160. Definition of Done

MODULE 13 завершён только если:

- [ ] `GameDay` exists as minimal autoload;
- [ ] GameDay starts at day1;
- [ ] explicit `advance_day()` is the single production day source;
- [ ] GirlDiscovery subscribes to GameDay;
- [ ] Relationships subscribes to GameDay;
- [ ] no double cooldown decrement;
- [ ] apartment has functional `Завершить день`;
- [ ] no full time/day-night system created;
- [ ] `SalaryMine` canonical service exists;
- [ ] SalaryMine is event-driven/no `_process`;
- [ ] Salary Mine still gated by `StoryFeature.SALARY_MINE`;
- [ ] salary level exact `1 + Authority/3`;
- [ ] gross exact `10 * level`;
- [ ] Authority changes only affect future periods;
- [ ] first salary period created exactly once at unlock;
- [ ] one new period per GameDay after unlock;
- [ ] pending salary accumulates;
- [ ] no lost unclaimed salary;
- [ ] salary physical station exists in salary_mine;
- [ ] manual cycle is 1.50s no-skill interaction;
- [ ] manual payout uses real GameState Money;
- [ ] manual claim clears pending once;
- [ ] first positive manual claim sets `manual_cycle_seen`;
- [ ] Salary Advance implemented exactly once/current salary period;
- [ ] Salary Advance claims accumulated pending only;
- [ ] Salary Advance does not create money/future payout;
- [ ] Salary Advance does not count as manual cycle;
- [ ] Phone salary section exists after unlock;
- [ ] Financial Inertia activates only after manual cycle;
- [ ] passive exact floor 25%;
- [ ] remainder stays pending;
- [ ] passive only on new periods;
- [ ] no real-time money tick;
- [ ] no clone income touched;
- [ ] production F5 still boots apartment;
- [ ] previous modules regressions pass;
- [ ] MODULE 14 content not implemented ahead.

---

# 161. Порядок выполнения Cursor

## Step 1 — Audit

Проверить фактические:

```text
GameState money/authority APIs + signals
GirlDiscovery day API
Relationships day API
Story feature signals
World apartment/salary_mine scenes
story_point_salary_station
PhoneJournal
PerkIds
project.godot autoload order
```

---

## Step 2 — GameDay

Создать minimal broadcaster.

Подключить MODULE08/10.

Сначала regression cooldown tests.

---

## Step 3 — Apartment day interaction

Сделать actual production:
```text
[E] Завершить день
```

Проверить один сигнал = один decrement.

---

## Step 4 — GameState salary state

Добавить minimal fields/APIs/reset.

---

## Step 5 — SalaryMine core

Реализовать:
```text
unlock initialization
level formula
gross formula
period opening
pending accumulation
```

без UI.

---

## Step 6 — Manual salary station

1.50s functional cycle + real Money commit.

---

## Step 7 — Salary Advance

Core + Phone button.

---

## Step 8 — Financial Inertia

25% next-period passive after manual cycle.

---

## Step 9 — Phone status

Read-only salary data + advance action.

---

## Step 10 — End-to-end

Stage3:
```text
initial salary
→ mine
→ manual claim
→ apartment day
→ next salary
→ phone/advance/passive
```

---

## Step 11 — Tests

Прогнать sections 112–150.

---

## Step 12 — Regressions

MODULE 02–12 + FPS.

---

## Step 13 — Docs

Обновить technical/perk/GDD notes.

---

# 162. Формат финального отчёта Cursor

## GameDay

Подтвердить:

```text
minimal day broadcaster only
day1 start
apartment End Day
GirlDiscovery + Relationships migrated
no double decrement
```

## Salary architecture

Как разделены:

```text
SalaryMine
GameState salary state
SalaryStation
PhoneJournal
```

## Formula

Exact:

```text
level = 1 + Authority / 3
gross = 10 * level
```

## Periods

Подтвердить:

```text
initial at unlock
+1 period per GameDay
pending accumulates
```

## Manual mine

Подтвердить:
```text
1.50s
no skill check
take all pending
real Money
manual cycle flag
```

## Salary Advance

Подтвердить:
```text
once per current period
claims all pending
no future money
no manual-seen flag
```

## Financial Inertia

Подтвердить:
```text
requires perk + manual seen
floor 25% auto
75% remainder/pending including rounding remainder
```

## Production integration

F5 + apartment End Day + mine Station + Phone.

## Validation

MODULE 13 tests + regressions.

## Files changed

Основные файлы.

## Product questions

Только реально нерешаемые вопросы.

Если нет:

```text
None.
```

---

# 163. Запрет продолжения

После успешного MODULE 13:

**НЕ начинать MODULE 14 — Stage Content: Manual Game.**

Остановиться и дождаться отдельной спецификации.
