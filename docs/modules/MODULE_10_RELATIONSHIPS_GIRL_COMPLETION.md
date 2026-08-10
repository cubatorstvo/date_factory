# MODULE 10 — RELATIONSHIPS & GIRL COMPLETION

**Проект:** Date Factory  
**Модуль:** 10 — Relationships & Girl Completion  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** применить `DatingResult` к постоянным отношениям девушки, ограничить шкалу `[-5,+5]`, реализовать повторные свидания, историю сыгранных событий, первое достижение `+5`, одноразовые «Покоренных сердец»/Баллы прокачки и интеграцию с Phone Journal  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/06_dating.md`  
**Предыдущий модуль:** MODULE 09 — Dating Core  
**Следующий модуль:** MODULE 11 — Story / Stage Framework

---

# 1. Главная граница

MODULE 09 уже возвращает:

```text
DatingResult.date_delta ∈ [-5,+5]
```

но НЕ меняет постоянное состояние девушки.

MODULE 10 отвечает за:

```text
DatingResult
→ relationship before
→ relationship after clamp [-5,+5]
→ cooldown повторного свидания
→ history event IDs
→ первое достижение +5
→ conquered
→ Experience +1
→ Upgrade Points +1
→ Phone update
```

---

# 2. Канонический relationship

У каждой девушки:

```text
relationship ∈ [-5, +5]
```

Default:

```text
0
```

После свидания:

```text
new_relationship =
clamp(
    old_relationship + DatingResult.date_delta,
    -5,
    +5
)
```

---

# 3. Negative relationship

Отрицательное значение разрешено.

Пример:

```text
old = -3
date_delta = -4
raw = -7
final = -5
```

---

# 4. Positive clamp

Пример:

```text
old = +4
date_delta = +3
raw = +7
final = +5
```

---

# 5. GameState relationship API cleanup

Текущий low-level `GameState` позволяет arbitrary values.

После MODULE 10 обычный relationship gameplay API должен гарантировать:

```text
[-5,+5]
```

Cursor должен выбрать чистый вариант:

- clamp внутри `set_girl_relationship`;
- clamp внутри `add_girl_relationship`;
- либо закрыть low-level mutation и дать controlled relationship API.

Главное:

> gameplay после MODULE 10 не может создать relationship = 8 или -12.

Save/Load restore path позже может быть отдельным, но тоже должен валидировать canonical range.

---

# 6. Completion threshold

Девушка считается успешно завершённой ручной линией при:

```text
relationship == +5
```

Техническое состояние уже существует:

```text
GameState.is_girl_conquered(girl_id)
GameState.mark_girl_conquered(girl_id)
```

---

# 7. Первое достижение +5

Только transition:

```text
not conquered
AND
new_relationship == +5
```

создаёт completion reward.

---

# 8. Completion reward

При первом достижении:

```text
mark_girl_conquered(girl_id)
add_experience(1)
```

`add_experience(1)` уже атомарно делает:

```text
Experience +1
Upgrade Points +1
```

Не начислять Upgrade Point отдельно второй раз.

---

# 9. Покоренных сердец

Canonical meaning:

> число уникальных девушек, которые хотя бы один раз достигли `+5`.

Следовательно invariant:

```text
Experience == conquered_girls.size()
```

в нормальном gameplay progression, если нет специальных future non-girl grants.

На текущем этапе никаких других sources Experience нет.

---

# 10. «Покоренных сердец» не уменьшается

Если уже conquered девушка позже каким-либо будущим контентом упадёт:

```text
+5 → +3
```

то:

```text
conquered remains true
Experience remains unchanged
Upgrade Point not removed
```

Completion — исторический факт.

---

# 11. Повторное достижение +5

Если girl уже conquered:

```text
relationship 3
→ date +2
→ relationship 5
```

не выдавать:

```text
Experience
Upgrade Points
second conquered event reward
```

---

# 12. Relationship result object

Создать typed semantic:

```text
RelationshipDateResult
```

или аналог.

Минимально:

```text
girl_id

date_delta
relationship_before
relationship_after
applied_delta

newly_conquered: bool
experience_gained: int
upgrade_points_gained: int

repeat_cooldown_days: int
played_event_ids: Array[StringName]
```

---

# 13. applied_delta

Из-за clamp:

```text
applied_delta
```

может отличаться от `date_delta`.

Пример:

```text
before = 4
date_delta = +5
after = 5
applied_delta = +1
```

---

# 14. Relationships system

Создать system semantic:

```text
Relationships
```

Он отвечает за:

- применение DatingResult;
- completion;
- cooldown;
- event history;
- подготовку exclusion list следующему DatingStartRequest;
- read availability для Phone/UI.

---

# 15. Architecture

Разумный вариант:

```text
autoload Relationships
```

потому что:

- слушает `DatingCore.date_finished`;
- persistent state живёт в GameState;
- используется Phone/Story;
- не зависит от конкретной world scene.

Cursor может выбрать иной простой вариант, если lifetime гарантирован.

Canonical name при autoload:

```text
Relationships
```

Не:

```text
GirlManager
LoveManager
DatingProgressManager
```

---

# 16. Automatic DatingResult application

Production flow должен быть:

```text
DatingCore.date_finished(result)
→ Relationships.apply_date_result(result)
```

Не заставлять UI вручную помнить вызвать commit.

---

# 17. Exactly-once result application

Один `DatingResult` нельзя применить дважды.

Нужен transient/runtime protection.

Предпочтительно `DatingResult` получает:

```text
session_id / date_id
```

stable unique within current run.

Если MODULE 09 ещё не имеет ID, добавить минимальный:

```text
date_id: int
```

или `StringName`.

---

# 18. Date ID ownership

`DatingCore` создаёт новый ID при `start_date`.

Простой monotonic runtime counter достаточен:

```text
1,2,3...
```

Не UUID.

Persistent save of active session не нужен.

---

# 19. Applied date IDs

Relationships может хранить transient:

```text
applied_date_ids
```

для exactly-once.

Но после successful apply persistent state уже изменён.

MODULE 24 позже решит save semantics.

Не создавать distributed transaction log.

---

# 20. Atomic apply

Операция conceptual:

1. validate result;
2. проверить duplicate date_id;
3. получить old relationship;
4. compute clamped new relationship;
5. записать relationship;
6. записать event history;
7. поставить repeat cooldown;
8. если first +5:
   - mark conquered;
   - add_experience(1);
9. mark date_id applied;
10. emit final semantic signals.

Не должно быть состояния:

```text
relationship изменён
но completion reward потерян
```

из-за раннего return.

---

# 21. Invalid DatingResult

Reject если:

- null;
- empty girl_id;
- unknown girl;
- `date_delta` вне `[-5,+5]`;
- central_event_ids size != 3;
- duplicate central event IDs;
- already applied date_id.

Никаких partial mutations.

---

# 22. Repeat date cooldown

После КАЖДОГО завершённого свидания:

```text
repeat_cooldown_days = rng.randi_range(1, 3)
```

Canonical:

```text
1..3 игровых дня
```

---

# 23. Cooldown applies after success too

Даже если:

```text
relationship reaches +5
```

cooldown может быть записан технически.

Но conquered girl больше не требует новых обязательных ручных свиданий.

Future optional interactions могут его учитывать или игнорировать по отдельной спецификации.

---

# 24. Separate discovery cooldown

Не переиспользовать смысл:

```text
girl_retry_days_remaining
```

из MODULE 08.

Это cooldown **повторного знакомства после отказа**.

Dating repeat cooldown — отдельное состояние:

```text
girl_date_cooldown_days_remaining
```

---

# 25. GameState — date cooldown

Добавить persistent:

```text
_girl_date_cooldown_days_remaining
```

API:

```text
get_girl_date_cooldown_days_remaining(girl_id)
set_girl_date_cooldown_days_remaining(girl_id, days)
is_girl_available_for_date(girl_id)
```

---

# 26. Date availability

Минимально:

```text
has contact
AND
date cooldown == 0
```

Conquered girl:

- технически может быть available;
- MODULE 10 не запрещает optional future repeat.

Story/content позже решит, нужна ли кнопка.

---

# 27. Day advance integration

Не создавать второй clock.

MODULE 08 уже имеет day-advance seam для discovery cooldown.

Нужно объединить на уровне вызова так, чтобы один игровой день уменьшал:

```text
discovery retry cooldown
date repeat cooldown
```

---

# 28. Preferred day architecture

Если сейчас:

```text
GirlDiscovery.notify_game_day_advanced()
```

владеет loop только discovery cooldown, MODULE 10 может:

- добавить `Relationships.notify_game_day_advanced()`;
- а future Time owner вызывать оба;

либо создать маленький shared day notification seam только если это реально проще.

Не создавать полноценный TimeManager в MODULE 10.

---

# 29. No duplicate day decrement

Один logical day advance должен уменьшить каждый cooldown ровно на `1`.

Tests обязаны ловить двойное decrement из-за двух signal subscriptions.

---

# 30. Date available again signal

При transition:

```text
1 → 0
```

emit semantic:

```text
girl_date_available_again(girl_id)
```

ровно один раз.

---

# 31. Cooldown seeded RNG

Relationships должен поддерживать deterministic RNG injection для tests.

Production:

```text
randomize
```

Tests:

```text
known seed
```

---

# 32. Event history — цель

GDD требует:

> повторное свидание использует новые три центральных события из доступного пула.

Следовательно MODULE 10 хранит per-girl history central event IDs.

Greeting/Farewell не входят в anti-repeat history.

---

# 33. GameState event history

Добавить persistent:

```text
_girl_played_dating_event_ids
```

Semantic:

```text
girl_id → ordered unique Array[StringName]
```

API:

```text
get_girl_played_dating_event_ids(girl_id)
record_girl_played_dating_events(girl_id, event_ids)
clear_girl_played_dating_event_history(girl_id)
```

---

# 34. Event history only central

Записывать:

```text
DatingResult.central_event_ids
```

ровно 3.

Не записывать:

- greeting;
- farewell;
- discovery approach;
- rival minigame.

---

# 35. Ordered unique

History не должна содержать duplicates.

Порядок нужен для debug и fallback policy.

---

# 36. Last date IDs

Также нужно уметь получить:

```text
last_date_event_ids[girl_id]
```

Можно хранить отдельным Array либо вывести из ordered history, если cycle reset semantics позволяют.

Предпочтительно отдельное:

```text
_girl_last_date_event_ids
```

из ровно трёх IDs.

---

# 37. Next date exclusions — normal path

Перед новым date:

```text
excluded_event_ids =
all played event IDs in current cycle
```

MODULE 09 planner уже умеет это принимать.

---

# 38. Content exhaustion

Если planner с полной history возвращает:

```text
INSUFFICIENT_DATE_CONTENT
```

Relationships/Dating start coordinator должен начать новый event-history cycle.

---

# 39. Cycle reset fallback

При exhaustion:

1. сохранить:
   ```text
   last_date_event_ids
   ```
2. очистить full played-event history;
3. повторить planning с:
   ```text
   excluded_event_ids = last_date_event_ids
   ```

То есть:

> старые события могут вернуться после исчерпания пула, но события прошлого свидания не повторяются сразу.

---

# 40. Если даже после fallback content insufficient

Вернуть:

```text
INSUFFICIENT_DATE_CONTENT
```

Не разрешать immediate same-event repeats только чтобы стартовать.

Content module должен добавить достаточный пул.

---

# 41. Кто строит DatingStartRequest

MODULE 09 требует explicit `DatingStartRequest`.

MODULE 10 должен предоставить helper semantic:

```text
prepare_repeat_date_request(...)
```

или:

```text
get_date_event_exclusions(girl_id)
```

Не обязательно полностью владеть location/greeting/farewell content.

---

# 42. Minimal integration API

Предпочтительный clean split:

```text
Relationships.get_event_exclusions_for_next_date(girl_id)
```

Возвращает current full-cycle history.

Caller строит `DatingStartRequest`.

Если start fail с insufficient content, caller/system может вызвать:

```text
Relationships.begin_new_event_cycle(girl_id)
```

и получить last-date-only exclusions.

---

# 43. Better automatic helper allowed

Cursor может добавить:

```text
DatingCore.start_repeat_date(request_without_exclusions)
```

или adapter, который сам делает fallback.

Но НЕ размывать MODULE 09 planner.

Предпочтение — маленький orchestration method в Relationships.

---

# 44. Relationship completion and event history

Даже perfect first date:

```text
+5
```

должна записать сыгранные 3 event IDs.

History остаётся полезна для optional future repeats/debug.

---

# 45. Phone Journal integration

MODULE 08 Phone должен теперь показывать:

```text
Отношения: X / 5
```

где X:

```text
-5..+5
```

---

# 46. Negative phone display

Показывать signed:

```text
Отношения: -3 / +5
```

или визуально эквивалентно.

Не скрывать отрицательные значения.

---

# 47. Completion status

Если conquered:

```text
Освоена / Замутил
```

Конкретный final label лучше:

```text
Отношения завершены
```

для functional UI.

Final comedy wording MODULE 22.

---

# 48. Phone cooldown

Если contact есть и date cooldown >0:

```text
Следующее свидание: через N дн.
```

Если 0:

```text
Следующее свидание: доступно
```

---

# 49. Discovery cooldown precedence

До получения номера Phone может показывать discovery retry cooldown.

После contact:

```text
date cooldown
```

является relevant retry state.

Не смешивать оба в одной цифре.

---

# 50. Experience display

Phone Journal per-girl НЕ обязан показывать:

```text
+1 Experience rewarded
```

Global HUD/progression позже.

Но completion result UI должен показать reward.

---

# 51. Completion result presentation

При first +5 emit:

```text
girl_completed(girl_id)
```

и functional result overlay/event может показать:

```text
Отношения: +5
Покоренных сердец +1
Балл прокачки +1
```

---

# 52. Completion signal

Не использовать только low-level:

```text
GameState.girl_conquered
```

если higher-level event нужен Story.

Relationships должен дать semantic signal с result:

```text
girl_completed(girl_id, relationship_result)
```

или эквивалент.

MODULE 11 будет его слушать.

---

# 53. Date applied signal

После каждого date:

```text
date_result_applied(result)
```

с before/after relationship.

---

# 54. Relationship changed signal

GameState уже emit-ит:

```text
girl_relationship_changed
```

Использовать его.

Не дублировать бессмысленно тот же low-level сигнал.

---

# 55. Relationship state ownership

Persistent fields живут в:

```text
GameState
```

Rules живут в:

```text
Relationships
```

DatingCore остаётся pure session scorer.

---

# 56. GameState `mark_girl_conquered`

Остаётся set-like low-level operation.

Не добавлять автоматический Experience grant внутрь GameState method.

Почему:

- GameState — storage;
- Relationships — rule owner.

---

# 57. Completion atomicity

Relationships должен:

```text
if mark_girl_conquered() returns true:
    GameState.add_experience(1)
```

Если false:

```text
no XP
```

Это естественная idempotency protection.

---

# 58. Existing conquered inconsistent state

Если data somehow:

```text
relationship == +5
conquered == false
```

а новый date result delta = 0:

MODULE 10 должен всё равно нормализовать completion:

```text
new_relationship == +5
AND not conquered
→ complete
```

Не требовать strict crossing from `<5`.

---

# 59. Already conquered below +5

Если:

```text
conquered == true
relationship < +5
```

никакой repeat reward.

---

# 60. First date perfect

Before:

```text
relationship=0
Experience=0
UpgradePoints=0
```

Date:

```text
+5
```

After:

```text
relationship=5
conquered=true
Experience=1
UpgradePoints=1
```

---

# 61. Multi-date completion

Example:

```text
date1 +2 => relationship 2
date2 +1 => 3
date3 +2 => 5
```

Reward только date3.

---

# 62. Negative recovery

Example:

```text
date1 -4 => -4
date2 +3 => -1
date3 +5 => +4
date4 +2 => +5
```

Reward только final.

---

# 63. Date at upper clamp after conquered

```text
relationship=5
conquered=true
date_delta=+5
```

After:

```text
5
no reward
```

---

# 64. Date at lower clamp

```text
relationship=-5
date_delta=-5
```

After:

```text
-5
applied_delta=0
```

Still records:

- date history;
- cooldown.

---

# 65. Zero date result

```text
date_delta=0
```

Still counts as completed date:

- history recorded;
- cooldown applied;
- relationship unchanged.

---

# 66. Date count

Добавить optional persistent:

```text
_girl_completed_date_count
```

только если реально полезно для future story/Phone/debug.

TECH PLAN MODULE 10 не требует его.

**Default: не добавлять.**

Event history уже подтверждает history.

---

# 67. Secondary trait reveal

GDD Phone хочет известную дополнительную черту, но конкретное правило раскрытия пока не определено.

MODULE 10 может добавить low-level state/API:

```text
revealed_secondary_traits
is_secondary_trait_revealed
reveal_secondary_trait
```

но НЕ автоматически раскрывать её по количеству свиданий.

---

# 68. Почему API нужен сейчас

Phone Journal уже должен уметь показывать known secondary trait, если будущий authored content её раскрыл.

Это симметрично primary trait API MODULE 08.

---

# 69. GameState secondary reveal

Добавить:

```text
_revealed_secondary_traits
```

API:

```text
is_secondary_trait_revealed(girl_id)
reveal_secondary_trait(girl_id)
```

Signal:

```text
secondary_trait_revealed(girl_id)
```

---

# 70. Phone secondary hidden

До reveal:

```text
Доп. черта: ?
```

или не показывать название.

---

# 71. Phone secondary revealed

После reveal:

```text
Доп. черта: Требовательная
```

Description из `SecondaryTraitDefinition`.

Не показывать generic formula DSL — его нет.

---

# 72. No auto primary reveal

MODULE 10 также НЕ автоматически раскрывает Primary Trait при +5.

Открытый вопрос GDD остаётся открытым.

Completion и knowledge — разные оси.

---

# 73. Dating start availability helper

Создать:

```text
can_start_date(girl_id) -> bool
```

и richer result:

```text
get_date_availability(girl_id)
```

Reasons semantic:

```text
AVAILABLE
NO_CONTACT
COOLDOWN
UNKNOWN_GIRL
```

---

# 74. Conquered availability

Не возвращать:

```text
COMPLETED_LOCKED
```

по умолчанию.

Conquered girl может быть optional repeat content later.

Story/UI решит, предлагать ли.

---

# 75. Repeat button in Phone

MODULE 10 может добавить functional:

```text
Свидание доступно
```

status.

Но не добавлять working:

```text
ПОЗВАТЬ НА СВИДАНИЕ
```

если location/greeting/farewell orchestration ещё не production-defined.

MODULE 14/22 интегрирует actual entry.

---

# 76. Date cooldown does not hide GirlActor

В отличие от discovery failed cooldown:

- contact уже получен;
- girl world actor не обязан исчезать.

Date cooldown только блокирует новый Date start.

---

# 77. Cooldown random each date

Каждый successful application DatingResult заново:

```text
1..3
```

Не зависит от date score.

---

# 78. Negative date does not increase cooldown

Нет:

```text
bad date = 3 days
good date = 1 day
```

RNG independent.

---

# 79. Perfect +5 still no immediate second date

Cooldown всё равно 1–3.

Это не важно для required line, но сохраняет единое правило.

---

# 80. Event history transaction

History записывается из result независимо от relationship delta.

Exactly once via date_id.

---

# 81. History and failed external date execution

MODULE 09 выдаёт DatingResult только полностью завершённого date.

Если session оборвалась раньше:

- MODULE 10 ничего не записывает;
- cooldown не начинается;
- event history не commit-ится.

---

# 82. No partial-date consequences

Не вводить penalty за закрытие игры/scene во время active Date.

Save/load later.

---

# 83. Relationship display result screen

Dating UI finish сейчас показывает только:

```text
Итог свидания: date_delta
```

MODULE 10 должен позволить дополнить result panel:

```text
Свидание: +3
Отношения: 1 → 4
```

При first completion:

```text
Покоренных сердец +1
Балл прокачки +1
```

---

# 84. UI ownership

Не переносить relationship logic в `dating_ui.gd`.

UI слушает Relationships result.

---

# 85. DatingCore close order

П production flow:

1. DatingCore emits `date_finished`;
2. Relationships synchronously applies result;
3. UI получает applied result;
4. DatingCore finished session можно закрыть.

Не зависеть от того, нажал ли игрок «Продолжить», чтобы reward commit-нулся.

---

# 86. Relationships startup

При `_ready()`:

- connect DatingCore `date_finished`;
- connect GameState reset при необходимости;
- initialize RNG.

Не `_process`.

---

# 87. Double connection guard

Проверить:

```text
is_connected
```

или equivalent.

Scene reload не должен удваивать callbacks.

---

# 88. Reset

GameState reset очищает:

```text
relationships
conquered
date cooldowns
played dating events
last date event IDs
secondary reveals
```

Relationships transient:

```text
applied date ids
```

тоже очищается.

---

# 89. GameState debug dump

Можно расширить summary relationship counts.

Не обязательно.

---

# 90. Experience invariant validation

Self-test/debug validation:

```text
for every conquered girl:
    relationship may be <=5
```

Но stronger invariant:

```text
Experience == number of conquered girls
```

на текущем game design.

Поскольку `add_experience()` остаётся public gameplay API для tests/future, validator может warning, а не hard crash.

---

# 91. Do not derive Experience live

Не делать:

```text
get_experience() = conquered_girls.size()
```

Experience уже persistent field и используется progression.

Relationships поддерживает invariant через controlled rewards.

---

# 92. Completion and purchased perks

Upgrade Point grant происходит через `add_experience`.

Игрок может сразу потратить новый балл через existing Progression.

MODULE 10 не покупает perk автоматически.

---

# 93. Experience unlocks girls

После reward:

```text
GirlDefinition.required_experience
```

может стать satisfied.

MODULE 10 не обязан scan всех girls.

Discovery при следующем interaction читает новое Experience.

---

# 94. Story boundary

MODULE 10 не:

- advance stage;
- unlock location;
- spawn next story rival;
- set story completion flags.

Он только emit:

```text
girl_completed
```

MODULE 11 решит последствия сюжетной девушки.

---

# 95. Ordinary girl completion

Та же mechanic.

No difference:

```text
story vs ordinary
```

в reward:

```text
+1 Experience
+1 Upgrade Point
```

---

# 96. Final target exception

Не реализовывать сейчас.

MODULE 21 может иметь bespoke final sequence.

---

# 97. Test fixture reuse

Использовать MODULE 09 test girls/results.

Можно создавать `DatingResult` напрямую для relationship unit tests.

Не нужно каждый test проигрывать полный Dating UI.

---

# 98. Test — clamp positive

```text
before 4
delta +4
after 5
applied +1
```

---

# 99. Test — clamp negative

```text
before -4
delta -4
after -5
applied -1
```

---

# 100. Test — first +5 reward

Expected exact:

```text
conquered first time
XP +1
Upgrade Points +1
```

---

# 101. Test — repeat +5 no reward

Already conquered:

```text
XP unchanged
UP unchanged
```

---

# 102. Test — conquered persistence after drop

Conquer girl.

Then force/apply future negative date:

```text
relationship below5
```

Expected:

```text
is_girl_conquered == true
XP unchanged
```

---

# 103. Test — normalized inconsistent +5

Before:

```text
relationship=5
conquered=false
```

Apply delta 0.

Expected:

```text
newly_conquered=true
XP+1
```

---

# 104. Test — date cooldown range

Repeated seeded applies produce only:

```text
1,2,3
```

---

# 105. Test — date cooldown separate from discovery

Discovery retry:

```text
2
```

Date cooldown:

```text
3
```

Both can technically coexist in corrupted/test state and APIs remain independent.

---

# 106. Test — day decrement

Date cooldown:

```text
3→2→1→0
```

One per day call.

---

# 107. Test — availability signal

Only transition:

```text
1→0
```

emits once.

---

# 108. Test — no double day decrement

If both discovery and relationships day seams invoked as one test orchestration:

each own cooldown decreases exactly once.

---

# 109. Test — history record

DatingResult:

```text
[e1,e2,e3]
```

After apply:

```text
played history has e1,e2,e3
last date = same
```

---

# 110. Test — history unique

Later result:

```text
[e3,e4,e5]
```

should not duplicate e3 in ordered full history.

Last date becomes:

```text
[e3,e4,e5]
```

---

# 111. Test — normal exclusion

Next-date exclusions:

```text
all played current-cycle events
```

---

# 112. Test — cycle exhaustion reset

Full history makes planner insufficient.

After reset:

```text
full history cleared
exclusions = last date 3 IDs
```

---

# 113. Test — no immediate repeat after cycle reset

Next plan cannot contain any of previous date's 3 IDs.

---

# 114. Test — second insufficient

If content still cannot generate 3 unique events:

```text
INSUFFICIENT_DATE_CONTENT
```

No history corruption.

---

# 115. Test — perfect first date records history

Even completion in one date stores events and cooldown.

---

# 116. Test — date ID duplicate

Apply same DatingResult twice:

First:

```text
ok
```

Second:

```text
ALREADY_APPLIED
```

No second:

- relationship delta;
- history;
- cooldown reroll;
- reward.

---

# 117. Test — invalid result

`date_delta=6`:

rejected.

No mutation.

---

# 118. Test — invalid central IDs

2 IDs or duplicate IDs:

rejected.

---

# 119. Test — zero delta

Relationship same.

History + cooldown still committed.

---

# 120. Test — Phone relationship

Phone shows exact current relationship.

---

# 121. Test — Phone cooldown

`3`:

```text
через 3 дн.
```

0:

```text
доступно
```

---

# 122. Test — Phone completion

Conquered state visibly distinguished.

---

# 123. Test — secondary trait hidden

Actual trait known in definition but reveal flag false:

Phone does not expose name.

---

# 124. Test — secondary trait reveal

Call:

```text
reveal_secondary_trait
```

Phone shows actual display name/description.

---

# 125. Test — no auto trait reveal at +5

Complete girl.

Primary/secondary reveal flags remain unchanged unless already set.

---

# 126. Test — DatingCore still pure

Static search DatingCore:

- no relationship mutation;
- no add_experience;
- no mark_girl_conquered.

MODULE 10 integrates through signal.

---

# 127. Test — real end-to-end perfect

Run actual MODULE 09 test date to:

```text
date_delta=+5
```

Relationships automatically:

```text
relationship 5
conquered
XP+1
UP+1
cooldown
history
```

---

# 128. Test — end-to-end negative

Actual DatingCore result negative.

Relationship decreases/clamps.

No XP.

---

# 129. Test — event exclusions used on repeat

Complete date A.

After cooldown, start orchestration for date B.

None of A's 3 events appear while unused pool supports alternatives.

---

# 130. Test — no contact

`can_start_date`:

```text
NO_CONTACT
```

---

# 131. Test — cooldown

Contact, cooldown 2:

```text
COOLDOWN
```

---

# 132. Test — available

Contact + cooldown 0:

```text
AVAILABLE
```

---

# 133. Test — conquered still available

By default:

```text
AVAILABLE
```

if no cooldown.

---

# 134. Test — reset

All MODULE 10 persistent fields cleared.

---

# 135. Regression MODULE 02

Update GameState tests for:

- clamp range;
- date cooldown;
- history;
- secondary reveal.

---

# 136. Regression MODULE 05

Experience/Upgrade Points atomic rule unchanged.

---

# 137. Regression MODULE 08

Discovery cooldown remains independent.

Phone previous features remain.

---

# 138. Regression MODULE 09

All DatingCore tests remain PASS.

No scoring changes.

---

# 139. Regression Rival/minigames/FPS

No effect.

Run prior suite.

---

# 140. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/06_dating.md
```

Уточнить implementation:

- relationship hard clamp `[-5,+5]`;
- repeat cooldown actual `1–3`;
- event history cycle;
- no immediate repeat after cycle exhaustion;
- completion reward uses `GameState.add_experience(1)`.

---

# 141. Phone GDD consistency

Phone now functionally supports:

- current relationship;
- next date availability;
- primary trait if known;
- secondary trait if known;
- known reactions.

---

# 142. Что MODULE 10 НЕ реализует

Категорически не реализовывать:

- Story stage advance;
- story girl consequences;
- world unlocks;
- real production date entry buttons;
- restaurant booking;
- calendar/time system;
- incoming messages;
- media attention;
- clone dating;
- passive Dates/minute;
- automatic primary trait reveal;
- automatic secondary trait reveal;
- gifts;
- breakup;
- relationship decay over time;
- jealousy;
- exclusivity;
- girlfriend management;
- post-completion romance simulation.

---

# 143. Definition of Done

MODULE 10 завершён только если:

- [ ] relationship canonical range `[-5,+5]`;
- [ ] gameplay cannot push relationship outside range;
- [ ] DatingResult automatically applies once;
- [ ] date_id / exactly-once protection exists;
- [ ] applied delta accounts for clamp;
- [ ] first +5 marks conquered;
- [ ] first +5 grants `add_experience(1)` exactly once;
- [ ] Upgrade Point comes from same atomic grant;
- [ ] repeat +5 gives no second reward;
- [ ] conquered is historical and never revoked;
- [ ] date cooldown separate from discovery cooldown;
- [ ] date cooldown is seeded random `1..3`;
- [ ] day-advance decrements date cooldown exactly once/day;
- [ ] event history stored per girl;
- [ ] last date event IDs stored/available;
- [ ] next date excludes played current-cycle events;
- [ ] exhausted history resets cycle;
- [ ] previous date's 3 events remain excluded after reset;
- [ ] insufficient content still fails cleanly;
- [ ] Phone shows relationship;
- [ ] Phone shows date availability;
- [ ] Phone shows completion;
- [ ] secondary trait reveal state/API exists;
- [ ] no automatic trait reveal invented;
- [ ] `girl_completed` semantic signal exists for MODULE 11;
- [ ] DatingCore remains scorer only;
- [ ] MODULE 02–09 regressions pass;
- [ ] FPS/Rival/minigame regressions pass;
- [ ] MODULE 11 not implemented ahead.

---

# 144. Порядок выполнения Cursor

## Step 1 — Audit

Изучить:

```text
GameState relationship/conquered APIs
DatingCore.date_finished
DatingResult
GirlDiscovery day cooldown
PhoneJournal
```

---

## Step 2 — relationship clamp

Сначала закрыть low-level canonical range и tests.

---

## Step 3 — persistent MODULE 10 state

Добавить:

```text
date cooldowns
played event history
last date event IDs
secondary trait reveals
```

---

## Step 4 — Relationships service

Реализовать atomic:

```text
DatingResult
→ relationship
→ history
→ cooldown
→ completion reward
```

---

## Step 5 — date ID

Добавить minimal exactly-once identifier в MODULE 09 result/session без изменения scoring.

---

## Step 6 — repeat event orchestration

Подключить existing `excluded_event_ids` planner seam.

---

## Step 7 — day advance

Интегрировать cooldown без создания clock manager.

---

## Step 8 — Phone

Добавить relationship/cooldown/completion/secondary-known display.

---

## Step 9 — end-to-end tests

MODULE 09 → Relationships.

---

## Step 10 — regressions

Все предыдущие modules.

---

## Step 11 — docs

Обновить GDD/technical docs.

---

# 145. Формат финального отчёта Cursor

## Architecture

Как устроен `Relationships` и почему.

## Relationship

Подтвердить exact:

```text
new = clamp(old + date_delta, -5, +5)
```

## Completion

Подтвердить:

```text
first +5
→ mark conquered
→ add_experience(1)
→ Experience +1 + Upgrade Point +1
```

и отсутствие повторной награды.

## Repeat dates

Подтвердить:

```text
cooldown 1–3 days
event history
cycle reset
no immediate repeat of last 3
```

## Phone

Что добавлено.

## Trait knowledge

Подтвердить:

```text
secondary reveal API exists
no automatic reveal
```

## Validation

MODULE 10 tests + regressions.

## Files changed

Основные файлы.

## Product questions

Только реальные вопросы.

Если нет:

```text
None.
```

---

# 146. Запрет продолжения

После успешного MODULE 10:

**НЕ начинать MODULE 11 — Story / Stage Framework.**

Остановиться и дождаться отдельной спецификации.
