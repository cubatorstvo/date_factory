# MODULE 18 — CLONE INCREMENTAL CORE

**Проект:** Date Factory  
**Модуль:** 18 — Clone Incremental Core  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** превратить первого клона из MODULE 17 в маленькую полноценную incremental-систему: автоматическое производство новых клонов, распределение агрегатных чисел между работой и свиданиями, реальные `Деньги/мин` и `Свидания/мин`, погашение backlog перегрузки, позднюю автоматическую Опытность и три простых денежных улучшения.  
**Предыдущий модуль:** MODULE 17 — First Clone Sequence  
**Следующий модуль:** MODULE 19 — Physical Clone Visualization  
**Product truth:** `docs/gdd/07_story_clones_finale.md`, разделы 38–41  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 18

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 18 начинается после:

```text
GameState.total_clones == 1
```

и первого назначения:

```text
WORK:
total=1
working=1
dating=0

или

DATING:
total=1
working=0
dating=1
```

MODULE 18 реализует:

```text
первый клон
→ лабораторная линия автоматически печатает новых свободных клонов
→ игрок через физический компьютер распределяет агрегатные числа:
   Работа / Свидания / Свободные
→ рабочие клоны дают Деньги/мин
→ dating-клоны дают Свидания/мин
→ автоматические свидания сначала гасят старый overload backlog
→ после backlog новые автоматические свидания дают Experience + Upgrade Points
→ Деньги покупают 3 простых upgrade-линии
→ производство и rates ускоряются
→ STOP
```

MODULE 18 НЕ реализует:

- отдельных persistent Clone entities;
- физические 10 clone slots;
- наблюдаемые комнаты свиданий;
- уход клонов в шахту;
- conveyor crowd;
- Президент;
- rival President;
- Stage 6;
- мировую экспансию;
- глобальную карту;
- транспорт клонов;
- финальную цель.

Это MODULE 19–21.

---

# 1. Канон GDD

Поздний терминал должен показывать минимум:

```text
Всего клонов
Клонов на работе
Денег в минуту
Клонов на свиданиях
Свиданий в минуту
```

Свободные клоны:

```text
total - working - dating
```

Игрок принимает одно главное решение:

```text
куда отправлять клонов:
РАБОТА
или
СВИДАНИЯ
```

Деньги покупают улучшения:

```text
производства клонов
денежной эффективности
скорости свиданий
```

Никаких individual protocols / QA.

---

# 2. Источник clone state

Canonical aggregate source остаётся:

```text
GameState:
_total_clones
_clones_working
_clones_dating

get_total_clones()
get_clones_working()
get_clones_dating()
get_free_clones()
set_clone_counts(...)
```

MODULE 18 НЕ создаёт второй массив/список клонов.

---

# 3. Existing late rates become real

MODULE 02 уже содержит:

```text
get_money_per_minute()
get_dates_per_minute()
set_late_rates(...)
```

MODULE 18 становится canonical owner вычисления этих rates.

До первого клона:

```text
0.0
0.0
```

После первого клона rates derived от assignment/upgrades.

---

# 4. `CloneIncremental` service

Создать canonical autoload:

```text
CloneIncremental
```

Responsibilities:

- automatic clone production;
- aggregate assignment;
- upgrade purchase;
- rate calculation;
- real-time passive accumulation;
- DatingOverload backlog automation;
- late Experience generation;
- terminal read model/signals.

Не создавать:

```text
CloneManager
CloneEconomyManager
CloneProductionManager
CloneDatingManager
```

---

# 5. Autoload order

После:

```text
FirstClone
```

добавить:

```text
CloneIncremental
```

Semantic current tail:

```text
Media
DatingOverload
FirstClone
CloneIncremental
```

---

# 6. Activation

Incremental core active iff:

```text
GameState.get_total_clones() >= 1
```

No additional Story flag.

Normal gameplay guarantees first clone only after Laboratory/Scientist.

Debug stage downgrade after clone creation does NOT destroy or stop existing clone economy.

Canonical fact:

```text
clone exists
→ incremental system exists
```

---

# 7. No production before first clone

At:

```text
total_clones == 0
```

Expected:

```text
production progress = 0
money rate = 0
date rate = 0
no passive output
```

---

# 8. Real-time, not GameDay

`Деньги/мин` and `Свидания/мин` are literal play-time rates.

Use real gameplay delta.

`GameDay.advance_day()`:

- does NOT simulate 24 hours;
- does NOT manufacture clones;
- does NOT grant clone money;
- does NOT grant automatic dates.

---

# 9. No offline progress in MODULE18

Closing game/process produces nothing while closed.

MODULE24 may later decide save timestamp/offline behavior.

---

# 10. Continuous simulation implementation

For this module continuous update is legitimate.

Preferred:

```gdscript
func _process(delta: float) -> void:
    advance_simulation(delta)
```

This is one lightweight autoload.

Do NOT create one `_process()` per clone.

---

# 11. Pause behavior

When SceneTree is paused, incremental simulation pauses normally.

Modal UI/Phone do not pause SceneTree, so production continues while managing UI.

---

# 12. Simulation accumulators

`CloneIncremental` owns runtime:

```text
_production_elapsed_seconds
_money_fraction
_date_fraction
```

Autoload lifetime keeps them across scene changes.

Save persistence waits for MODULE24.

Reset clears all three.

---

# 13. Large delta safety

`advance_simulation(delta)` correctly handles:

- multiple produced clones;
- multiple integer Money payouts;
- multiple automated dates.

Tests must use deterministic:

```text
advance_simulation_for_test(seconds)
```

or equivalent.

---

# 14. Clone production — base

After first clone:

```text
clone line automatically runs
```

No button per clone.

Base interval:

```text
30.0 seconds / clone
```

At each interval:

```text
total += 1
working unchanged
dating unchanged
```

New clone is FREE.

---

# 15. Why automatic/free production

The incremental decision is:

```text
allocation + upgrades
```

not repeatedly pressing `Создать клона`.

No per-clone Money cost in MODULE18.

---

# 16. New clone invariant

Before:

```text
total = 4
working = 2
dating = 1
free = 1
```

After production:

```text
total = 5
working = 2
dating = 1
free = 2
```

Use `GameState.set_clone_counts(...)`.

---

# 17. No clone cap in MODULE18

Aggregate total has no artificial gameplay cap.

Physical visualization is separately capped by MODULE19.

---

# 18. Production upgrade formula — EXACT

Upgrade:

```text
PRODUCTION_SPEED
```

Levels:

```text
0..5
```

Exact interval:

```text
interval_seconds = 30.0 - 5.0 * production_level
```

Table:

```text
0 →30s
1 →25s
2 →20s
3 →15s
4 →10s
5 →5s
```

---

# 19. Upgrade keeps elapsed progress

Example:

```text
interval30
elapsed27
buy level1 → interval25
```

Immediately resolve:

```text
1 clone
remaining elapsed2
```

Do NOT reset production progress.

---

# 20. Work rate formula — EXACT

Upgrade:

```text
WORK_EFFICIENCY
```

Levels:

```text
0..5
```

Per working clone:

```text
money_per_minute_per_clone = 20.0 + 10.0 * work_level
```

Table:

```text
0 →20
1 →30
2 →40
3 →50
4 →60
5 →70
```

Total:

```text
money_per_minute = clones_working * (20 + 10 * work_level)
```

---

# 21. Dating rate formula — EXACT

Upgrade:

```text
DATING_EFFICIENCY
```

Levels:

```text
0..5
```

Per dating clone:

```text
dates_per_minute_per_clone = 0.50 + 0.25 * dating_level
```

Table:

```text
0 →0.50
1 →0.75
2 →1.00
3 →1.25
4 →1.50
5 →1.75
```

Total:

```text
dates_per_minute = clones_dating * (0.50 + 0.25 * dating_level)
```

---

# 22. Rate updates

On:

```text
clone counts change
work upgrade change
dating upgrade change
reset
```

recompute and call:

```text
GameState.set_late_rates(money_rate, dating_rate)
```

No independent stored rate source in CloneIncremental.

---

# 23. Passive Money accumulation

Every simulation delta:

```text
_money_fraction += money_per_minute * delta / 60.0
```

When >=1:

```text
whole = floor(_money_fraction)
_money_fraction -= whole
GameState.add_money(whole)
```

Never round each frame.

---

# 24. Work output vs Salary Mine

Clone work directly adds:

```text
GameState Money
```

It does NOT:

- add SalaryMine pending salary;
- alter salary level;
- simulate salary collection.

---

# 25. Automated date accumulation

```text
_date_fraction += dates_per_minute * delta / 60.0
```

Each whole completion calls:

```text
_process_one_automated_date()
```

No DatingCore.

No trait solving.

No individual girl event.

---

# 26. First priority: overload backlog

For each automated date:

```text
if DatingOverload backlog > 0:
    fulfill exactly one oldest active demand by clone
    grant NO Experience
else:
    GameState.add_experience(1)
```

This directly solves the earlier physical bottleneck.

---

# 27. Why backlog fulfillment gives no Experience

MODULE16 demand is usually repeated meetings from known girls.

Not necessarily new unique conquest.

So:

```text
backlog fulfillment = throughput only
```

---

# 28. After backlog is empty

Each automated date represents one newly covered aggregate girl:

```text
GameState.add_experience(1)
```

Existing invariant automatically grants:

```text
+1 Experience
+1 Upgrade Point
```

No synthetic GirlDefinition/contact/journal entry.

---

# 29. DatingOverload clone API

Add narrow:

```text
fulfill_oldest_demand_by_clone() -> bool
```

Priority:

```text
OVERDUE oldest request_id first
then WAITING oldest request_id
```

Mark exactly one:

```text
FULFILLED
fulfilled_day = GameDay.current_day
```

Return whether one was fulfilled.

---

# 30. Clone dates do not use hero capacity

Do NOT mutate:

```text
last_personal_date_day
personal_dates_completed
```

Hero still has personal one-date/day cap.

---

# 31. No relationship mutation

Clone backlog fulfillment changes only demand state.

Not relationship.

---

# 32. Batch exactness

If:

```text
backlog2
five automated dates complete
```

Expected:

```text
2 demands fulfilled
Experience +3
Upgrade Points +3
```

Batch processing must equal sequential processing.

---

# 33. Upgrade system

Exactly three:

```text
PRODUCTION_SPEED
WORK_EFFICIENCY
DATING_EFFICIENCY
```

All:

```text
MAX_LEVEL = 5
```

No clone-quality/capacity/memory tree.

---

# 34. Upgrade costs — EXACT

Next-level cost from current level L:

```text
30 * 3^L
```

Table:

```text
0→1 = 30
1→2 = 90
2→3 = 270
3→4 = 810
4→5 = 2430
```

At5:

```text
MAX
```

Each track independent.

---

# 35. Upgrade currency

Use:

```text
GameState.can_afford
GameState.spend_money
```

Clone upgrades use Money.

Not Upgrade Points.

---

# 36. GameState upgrade fields

Add/reset:

```text
_clone_production_upgrade_level = 0
_clone_work_upgrade_level = 0
_clone_dating_upgrade_level = 0
```

Getters:

```text
get_clone_production_upgrade_level()
get_clone_work_upgrade_level()
get_clone_dating_upgrade_level()
```

Mutation validates 0..5.

---

# 37. Upgrade signal/result

Signal:

```text
clone_upgrade_changed(upgrade_type, new_level, previous_level)
```

Typed purchase result:

```text
ok
error
upgrade_type
new_level
money_spent
money_after
```

Errors:

```text
LOCKED
MAX_LEVEL
NOT_ENOUGH_MONEY
INVALID_UPGRADE
```

---

# 38. Assignment becomes editable

MODULE17 first assignment was fixed only for first-scene commitment.

MODULE18 now allows aggregate redistribution.

API:

```text
assign_one_to_work()
assign_one_to_dating()
unassign_one_from_work()
unassign_one_from_dating()
assign_all_free_to_work()
assign_all_free_to_dating()
```

---

# 39. Assignment rules

Assign requires:

```text
free >= 1
```

Unassign returns one clone to free.

Never changes total.

Never allows:

```text
working + dating > total
```

Rates recalculate immediately.

---

# 40. FirstClone representative compatibility

Modify MODULE17 `FirstClone` narrowly:

listen:

```text
GameState.clone_counts_changed
```

If lab loaded:

```text
reconstruct_representative()
```

Still only ONE visible representative.

If any work clone exists → work marker.  
Else if any dating clone exists → date marker.  
Else output/free marker.

MODULE19 replaces this with real local multi-clone visualization.

---

# 41. Laboratory terminal

Use existing:

```text
story_point_clone_terminal
```

Add:

```text
CloneTerminalInteractable
```

Prompt:

```text
[E] Терминал клонов
```

Before first clone:

```text
Терминал ожидает первого клона
```

---

# 42. Terminal modal

Open:

```text
MODAL_UI
mouse visible
```

Close:

```text
GAMEPLAY
```

Incremental simulation continues while modal open.

---

# 43. Terminal — exact information

```text
КЛОН-ФАБРИКА

Всего клонов: N
Свободно: F

На работе: W
Денег в минуту: M

На свиданиях: D
Свиданий в минуту: R

Следующий клон: X.X с
```

---

# 44. Terminal allocation controls

WORK:

```text
[-1] [+1] [Все свободные]
```

DATING:

```text
[-1] [+1] [Все свободные]
```

Truthful disabled states.

---

# 45. Terminal upgrade section

```text
ЛИНИЯ КОПИРОВАНИЯ
Уровень L/5
Новый клон каждые X с
[Улучшить — COST]

РАБОЧАЯ МЕТОДИКА
Уровень L/5
Доход одного рабочего: X/мин
[Улучшить — COST]

РОМАНТИЧЕСКИЙ КОНВЕЙЕР
Уровень L/5
Скорость одного клона: X свиданий/мин
[Улучшить — COST]
```

At max:

```text
[MAX]
```

---

# 46. Terminal refresh

React to:

```text
clone_counts_changed
late_rates_changed
clone_upgrade_changed
money_changed
```

Countdown display may use UI-only Timer 0.25s.

That Timer must NOT advance simulation itself.

---

# 47. Phone Clone section expansion

After clone exists show:

```text
КЛОНЫ

Всего: N
Свободно: F
Работают: W
На свиданиях: D

Денег/мин: M
Свиданий/мин: R
```

Phone remains read-only for clone assignment/upgrades.

---

# 48. Why management stays physical

GDD explicitly requires FPS player standing by computer.

No remote management from Phone in MODULE18.

---

# 49. Status snapshot

Create:

```text
CloneIncrementalStatus
```

Fields:

```text
active
total
working
dating
free

production_level
work_level
dating_level

production_interval
production_elapsed
seconds_to_next_clone

money_per_minute
dates_per_minute

backlog_count
```

Read-only snapshot.

---

# 50. Signals

Recommended:

```text
clone_produced(new_total)
assignment_changed(total, working, dating, free)
upgrade_purchased(upgrade_type, new_level)
automated_money_granted(amount)
automated_date_completed()
backlog_fulfilled_by_clone(request_id)
late_experience_granted(amount)
```

No per-clone events.

---

# 51. Reset

On GameState reset:

```text
production_elapsed=0
money_fraction=0
date_fraction=0
```

GameState reset also restores:

```text
clone counts0
rates0
upgrade levels0
```

No duplicate subscriptions.

---

# 52. WORK-first boot

MODULE17 state:

```text
1/1/0
```

Immediately:

```text
20 Money/min
0 Dates/min
30s next clone
```

---

# 53. DATING-first boot

```text
1/0/1
```

Immediately:

```text
0 Money/min
0.50 Dates/min
30s next clone
```

No softlock because next clone is free after30s.

---

# 54. No manual clone grind

Line runs automatically anywhere in world.

No need to remain in laboratory.

No scene-node dependency for production math.

---

# 55. Overload integration

As dating clones work:

```text
old backlog visibly decreases
```

through existing DatingOverload signals.

MODULE16 demand generation stays stopped after recognition.

---

# 56. Manual hero cap remains

Even after backlog reaches0:

```text
original hero = max1 manual date/GameDay
```

Clone auto dates bypass it because they are separate bodies.

---

# 57. No Authority/Attention from clone outputs

Automated clone work/dates do NOT grant:

```text
Authority
Attention
relationship points
```

Only:

- Money from work;
- backlog fulfillment;
- late Experience/UP after backlog.

---

# 58. Existing perk system unchanged

Clone upgrades:

- are not PerkDefinitions;
- do not increase MUSCLE/APPEARANCE/CAPITAL/AURA;
- do not consume normal UP.

---

# 59. FirstClone machine remains one-off

Do NOT repurpose calibration machine.

After first clone:

```text
Первый клон уже создан
```

Management is Clone Terminal.

Production is automatic.

---

# 60. Stage5 presentation

After first clone exists:

```text
СТАДИЯ 5
Лаборатория

Автоматизация запущена.
Наращивай производство клонов.
```

Do NOT show missing President objective yet.

---

# 61. No Story progress from numbers

MODULE18 never calls:

```text
advance_stage
complete_world_expansion
```

Even 10000 clones → Stage5.

President is later.

---

# 62. Numerical formatting

Money/min:
integer-looking when whole.

Dates/min:
max2 decimal places.

No K/M/B formatting yet.

---

# 63. Tests — zero clones

```text
total0
advance300s
```

Expected:

```text
no clones
no Money
no XP
rates0/0
```

---

# 64. Tests — initial rates

```text
1/1/0 lvl0 →20/min, 0
1/0/1 lvl0 →0, .50/min
```

---

# 65. Tests — production

```text
29.9s → no clone
30.0s total → +1 free clone
90s → +3 clones
```

Assignments preserved.

---

# 66. Tests — production levels

Exact:

```text
30/25/20/15/10/5
```

Elapsed27 + buy lvl1 → one clone + remainder2.

---

# 67. Tests — work formula

One worker:

```text
lvl0 20
lvl1 30
lvl2 40
lvl3 50
lvl4 60
lvl5 70
```

3 workers lvl2 →120/min.

30s → +60 Money.

---

# 68. Tests — dating formula

One dating:

```text
.50/.75/1.00/1.25/1.50/1.75
```

2 dating lvl0 →1 date/min.

60s → one auto date.

---

# 69. Tests — backlog first

Backlog2 +2 auto dates:

```text
backlog0
XP unchanged
UP unchanged
```

Backlog2 +5 auto dates:

```text
backlog0
XP+3
UP+3
```

---

# 70. Tests — clone demand fulfillment

Must NOT change:

```text
relationship
personal date capacity
personal_dates_completed
```

---

# 71. Tests — aggregate late XP

Backlog0 +100 automated dates:

```text
XP+100
UP+100
```

No100 new contacts/girl IDs.

---

# 72. Tests — costs

Each tree:

```text
30
90
270
810
2430
MAX
```

Insufficient Money → no mutation.

---

# 73. Tests — assignment

Examples:

```text
3 total /1 work /1 dating /1 free
+work →3/2/1/0free
-work →3/1/1/1free
all free→dating
```

Invariant always valid.

---

# 74. Tests — rate update immediate

Assignment or efficiency upgrade emits/recalculates late rates immediately.

---

# 75. Tests — representative

Lab loaded:

- Work exists → representative work marker;
- no Work + Dating exists → date marker;
- neither → output marker.

Still one actor.

---

# 76. Tests — world independence

Leave lab.

Simulation continues.

No null-node dependency.

---

# 77. Tests — GameDay exploit

Calling:

```text
GameDay.advance_day()
```

with zero simulation seconds produces no clone/Money/date.

---

# 78. Tests — no offline

No wall-clock catch-up path.

---

# 79. Tests — Stage unchanged

Huge clone/XP totals do not advance Story.

No President content.

---

# 80. Full F5 extension

Clean:

```text
PROLOGUE
→ Actress
→ Mine Boss
→ Editor
→ Media
→ Overload
→ Scientist
→ First Clone

→ second clone auto-produced
→ open lab terminal
→ assign Work/Dating
→ observe Money/min and Dates/min
→ dating clones clear backlog
→ late dates add Experience/UP
→ buy upgrades
→ rates/production improve
```

---

# 81. Expected early feel

WORK first:

```text
t0:
1 Work
20/min
clone in30s

t30:
2 total
1 free

assign Dating:
20 Money/min
.5 Dates/min
```

DATING first:

```text
t0:
1 Dating
.5 Dates/min
clone in30s

t30:
second clone free
assign Work
→20 Money/min
```

No long forced idle.

---

# 82. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Document exact current balance:

```text
production 30→5 sec
work 20→70 Money/min/clone
dating .50→1.75 dates/min/clone
cost 30×3^level
```

These can be tuned in MODULE26, but MODULE18 implementation must be exact.

---

# 83. Technical decisions

Document:

```text
CloneIncremental stores no individual clone records.
GameState aggregate counts are canonical.
```

```text
Automated dates do not invoke DatingCore.
Backlog is fulfilled first.
After backlog is empty, each whole auto date calls GameState.add_experience(1).
```

```text
Late rates use real gameplay seconds.
GameDay does not simulate incremental output.
No offline gains in MODULE18.
```

---

# 84. Suggested project area

```text
game/clone_incremental/
├── clone_incremental.gd
├── clone_incremental_types.gd
├── clone_incremental_status.gd
├── clone_upgrade_purchase_result.gd
├── clone_terminal_interactable.gd
└── test/
```

Keep compact.

---

# 85. Definition of Done

MODULE18 complete only if:

- [ ] `CloneIncremental` autoload exists;
- [ ] active only with total clones>=1;
- [ ] no output with zero clones;
- [ ] auto production base30s;
- [ ] produced clone is free;
- [ ] production works outside lab;
- [ ] no per-clone cost/cap;
- [ ] production levels exact0..5 and30/25/20/15/10/5;
- [ ] elapsed progress preserved on upgrade;
- [ ] work output exact20+10*level per clone/min;
- [ ] dating output exact.50+.25*level per clone/min;
- [ ] GameState late rates canonical;
- [ ] fractional Money/date accumulation;
- [ ] backlog fulfilled before late Experience;
- [ ] clone backlog fulfillment does not consume hero capacity;
- [ ] no relationship mutation;
- [ ] after backlog, auto dates grant XP/UP through `add_experience`;
- [ ] no synthetic girls;
- [ ] exactly3 upgrade tracks;
- [ ] costs exact30/90/270/810/2430;
- [ ] upgrades use Money;
- [ ] GameState stores3 upgrade levels;
- [ ] +1/-1/all-free assignment works;
- [ ] invariants preserved;
- [ ] rates update immediately;
- [ ] MODULE17 representative refreshes on count changes;
- [ ] only one physical representative remains;
- [ ] physical Clone Terminal exists;
- [ ] terminal shows counts/rates/countdown/upgrades;
- [ ] Phone clone section shows counts/rates read-only;
- [ ] GameDay does not create incremental output;
- [ ] no offline progress;
- [ ] reset clears incremental runtime/levels/rates;
- [ ] Story stays Stage5;
- [ ] President still absent;
- [ ] no MODULE19 physical multi-clone visualization;
- [ ] clean F5 demonstrates full incremental loop;
- [ ] MODULE02–17 regressions PASS;
- [ ] MODULE19 not implemented ahead.

---

# 86. Recommended Cursor order

```text
1. Audit GameState / FirstClone / DatingOverload / Phone / lab terminal marker.
2. Add GameState three upgrade levels.
3. Implement pure CloneIncremental rates/production/assignment/upgrades.
4. Add narrow DatingOverload clone fulfillment API.
5. Add deterministic simulation + _process delegate.
6. Refresh FirstClone representative on aggregate count changes.
7. Add physical Clone Terminal.
8. Expand Phone read-only clone summary.
9. Run clean production path.
10. Regressions/docs.
```

---

# 87. Cursor final report

## Architecture

Explain:

```text
CloneIncremental
GameState aggregate counts/upgrades/rates
DatingOverload integration
Clone Terminal
Phone
```

## Production

Confirm:

```text
30/25/20/15/10/5 sec
free new clones
```

## Work

Confirm:

```text
20 + 10*level Money/min/clone
```

## Dating

Confirm:

```text
.50 + .25*level dates/min/clone
```

## Upgrades

Confirm:

```text
3 tracks
levels0..5
cost30×3^level
```

## Late Experience

Confirm:

```text
auto date
→ backlog first
→ then +1 Experience/+1 UP
```

## Boundary

Confirm:

```text
no individual clone records
no MODULE19 physical slots
no President
no Stage advance
no offline progress
```

## F5 validation

Clean route through working incremental loop.

## Regressions

All previous suites.

## Commit

SHA.

Then STOP. Do not begin MODULE19.
