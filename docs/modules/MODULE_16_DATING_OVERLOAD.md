# MODULE 16 — DATING OVERLOAD

**Проект:** Date Factory  
**Модуль:** 16 — Dating Overload  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** системно и физически доказать игроку, что после медийного роста одного героя больше не хватает: входящие встречи начинают перекрываться, личная пропускная способность ограничивается одним свиданием в игровой день, backlog растёт быстрее обслуживания, после чего формируется сюжетный вывод о необходимости клонирования.  
**Предыдущий модуль:** MODULE 15 — Media / Attention Escalation  
**Следующий модуль:** MODULE 17 — First Clone Sequence  
**Product truth:** `docs/gdd/07_story_clones_finale.md`, раздел «Перегрузка свиданиями»  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 16

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 16 начинается, когда:

```text
Story stage == STAGE_4
AND
Media.is_overload_ready() == true
```

То есть к этому моменту уже есть:

```text
Attention >= 45
incoming media offers >= 3
```

MODULE 16 реализует:

```text
overload starts
→ 3 конкретных запроса на встречи
→ часть встреч накладывается
→ одно физическое тело = максимум 1 личное свидание / GameDay
→ каждый новый день приходит больше запросов, чем герой может обслужить
→ backlog растёт
→ игрок хотя бы один раз реально идёт на свидание
→ через несколько дней проблема становится математически очевидной
→ герой формулирует:
   «Проблема не в графике. Проблема в количестве меня.»
→ clone_solution_needed
→ STOP
```

MODULE 16 НЕ реализует:

- Учёную как production NPC;
- её сюжетного самца;
- лабораторию;
- клонирование;
- первый клон;
- распределение клонов;
- calendar-management game;
- сложное расписание.

---

# 1. Product principle

GDD требует:

> это постановочная демонстрация проблемы, а не сложный календарный менеджмент.

Поэтому MODULE 16 намеренно не создаёт:

```text
calendar
appointments grid
hour-by-hour optimization
travel-time routing
priorities
deadlines
rescheduling negotiation
penalties
```

Игрок должен понять проблему примерно за 2–3 игровых дня.

---

# 2. Ограничение тела — canonical rule

После начала overload:

```text
PERSONAL_DATE_CAPACITY_PER_DAY = 1
```

То есть за один `GameDay` герой может завершить максимум:

```text
1 личное свидание
```

Это правило относится ко ВСЕМ ручным свиданиям:

- media requests;
- обычные девушки;
- story/optional repeat dates.

До начала overload:

```text
никакого daily date cap нет
```

---

# 3. Почему cap глобальный

Если Media-demand ограничен, но игрок может пройти ещё пять обычных свиданий в тот же день, тезис:

> «у меня одно тело»

не работает.

После activation физическая пропускная способность героя становится общей.

---

# 4. Daily cap — не календарь

Нет часов.

Rule:

```text
если сегодня уже завершено одно DatingCore свидание,
новое DatingCore свидание нельзя начать до следующего GameDay
```

Functional reason:

```text
Сегодня ты уже физически был на одном свидании.
```

---

# 5. Когда capacity расходуется

Capacity consume происходит только после:

```text
Relationships.date_result_applied
```

то есть после реально завершённого свидания.

Не consume при:

- открытии DateVenue;
- выборе девушки;
- failed start;
- closed UI before session;
- rival encounter.

---

# 6. Если Dating session уже началась

После успешного start:

не позволять второй date start параллельно — это и так запрещено MODULE09.

Capacity commit всё равно на completion.

---

# 7. DatingOverload service

Создать canonical autoload:

```text
DatingOverload
```

Responsibilities:

- activation from Media;
- personal daily capacity;
- demand generation;
- backlog;
- request state;
- feed boost;
- fulfillment from real dates;
- problem-recognition trigger;
- clone handoff signal.

No `_process()`.

---

# 8. Autoload order

Append:

```text
...
SalaryMine
Media
DatingOverload
```

DatingOverload depends on:

```text
GameState
GameDay
Media
Relationships
ContentDB
```

---

# 9. Runtime/persistent state owner

Persistent gameplay facts live in:

```text
GameState
```

Rules live in:

```text
DatingOverload
```

---

# 10. GameState fields

Add:

```text
_dating_overload_started: bool = false
_dating_overload_start_day: int = -1

_dating_overload_next_request_id: int = 1
_dating_overload_requests: Array = []

_dating_overload_last_personal_date_day: int = -1
_dating_overload_personal_dates_completed: int = 0

_dating_overload_last_feed_boost_day: int = -1
_dating_overload_boost_pending: bool = false

_dating_overload_problem_recognized: bool = false
```

---

# 11. Demand records

Create typed:

```text
DatingDemandEntry
```

Prefer `RefCounted`.

Fields:

```text
request_id: int
girl_id: StringName

created_day: int
appointment_day: int
slot: DatingDemandSlot

status: DatingDemandStatus
fulfilled_day: int = -1
```

Optional:

```text
source = MEDIA
```

not required because MODULE16 demand is entirely media-originated.

---

# 12. Demand slot enum

Exactly:

```text
EARLY_EVENING
LATE_EVENING
```

These are presentation labels only.

Display:

```text
EARLY_EVENING → "19:00"
LATE_EVENING  → "20:00"
```

There is NO real game clock.

---

# 13. Demand status enum

Exactly:

```text
WAITING
OVERDUE
FULFILLED
```

No:

```text
ACCEPTED
DECLINED
CANCELLED
FAILED
RESCHEDULED
```

---

# 14. Why OVERDUE remains active

Unserved request does not disappear.

At next day:

```text
WAITING from earlier day
→ OVERDUE
```

It remains in backlog.

This makes unmet demand visible.

---

# 15. No relationship penalty

OVERDUE request:

- does NOT lower relationship;
- does NOT remove contact;
- does NOT create Authority penalty;
- does NOT cost Money.

The point is production pressure, not punishment.

---

# 16. Demand backlog

Derived:

```text
backlog =
count(status == WAITING or OVERDUE)
```

No separate mutable backlog integer.

---

# 17. Activation condition

DatingOverload listens:

```text
Media.overload_ready
```

and also on `_ready()` queries:

```text
Media.is_overload_ready()
```

for restore/debug safety.

Activation only if:

```text
Story stage == STAGE_4
AND
not overload_started
```

---

# 18. Activation transaction

First activation:

```text
started = true
start_day = GameDay.current_day
```

Then immediately generate:

```text
3 requests
```

with exact slot pattern:

```text
request1 → EARLY_EVENING
request2 → EARLY_EVENING
request3 → LATE_EVENING
```

This is the first explicit overlap.

---

# 19. First-wave meaning

Phone should visibly show:

```text
19:00 — Девушка A
19:00 — Девушка B
20:00 — Девушка C
```

and:

```text
Личная пропускная способность сегодня: 1
```

The player does not need a calendar tutorial.

The contradiction is self-evident.

---

# 20. Demand candidates

Use current Media incoming offers only.

Source:

```text
Media.get_incoming_offer_girl_ids()
```

or GameState equivalent.

Do not generate new arbitrary contacts here.

---

# 21. Candidate cycle

Demand generation cycles deterministically through current incoming offer list in its stored order.

Example incoming:

```text
A, B, C
```

Initial demands:

```text
A
B
C
```

Next wave:

```text
A
B
```

Next:

```text
C
A
```

Repeated requests from same girl are allowed.

---

# 22. Why repeated demand is allowed

Media initiative means:

> человек хочет ещё одной встречи.

A previously contacted/conquered girl can request another date.

This is essential so backlog can keep growing without procedural new girls.

---

# 23. If offer list grows

At Attention60 Media may add a fourth incoming girl.

Future demand cycle uses the expanded list naturally.

No demand regeneration/reorder needed.

---

# 24. If zero offers

Activation should not normally happen because overload-ready requires >=3.

If corrupted/test state:

- do not create invalid demand;
- push warning;
- remain started;
- retry generation next GameDay.

---

# 25. Daily new demand

On every:

```text
GameDay.day_advanced
```

while overload active and problem not yet recognized:

1. age existing WAITING requests;
2. generate new demand wave;
3. evaluate recognition trigger.

---

# 26. Aging

For all entries:

```text
if status == WAITING
AND appointment_day < current_day
→ OVERDUE
```

FULFILLED stays FULFILLED.

---

# 27. Base daily wave

Exact:

```text
BASE_NEW_REQUESTS_PER_DAY = 2
```

Slot pattern:

```text
EARLY_EVENING
LATE_EVENING
```

Thus steady state:

```text
incoming capacity = 2/day
personal capacity = 1/day
```

Backlog grows by at least:

```text
+1/day
```

if player services every day.

---

# 28. Feed boost

GDD says social feed can temporarily increase attention further.

MODULE16 adds one deliberately simple action:

```text
Поднять волну
```

in Phone Media/Overload section.

---

# 29. Feed boost availability

Available if:

```text
overload_started
AND
problem not recognized
AND
last_feed_boost_day != current_day
```

No resource cost.

---

# 30. Feed boost effect

On use:

```text
Attention +5
boost_pending = true
last_feed_boost_day = current_day
```

The +5 uses canonical:

```text
GameState.add_media_attention(5)
```

which lets existing Media threshold logic generate a fourth incoming offer if 60 is crossed.

---

# 31. Feed boost next-wave effect

At next `GameDay.day_advanced`:

If:

```text
boost_pending == true
```

generate:

```text
3 requests
```

with:

```text
EARLY
EARLY
LATE
```

instead of2.

Then:

```text
boost_pending = false
```

---

# 32. Feed boost does not stack

Using once/day:

```text
boost_pending
```

is bool.

No:

```text
+6 requests
+9 requests
```

from repeated days before consuming.

Since wave consumes next day, one daily use is enough.

---

# 33. Feed boost does not consume photo limit

It is not a photo publication.

No relation to:

```text
media_last_photo_publish_day
```

Player may:

- publish one remaining photo;
- use one feed boost

same GameDay.

This is acceptable escalation.

---

# 34. Feed boost after all photos

Remains available until problem recognized.

This ensures player can intentionally intensify overload even after 3 photos are used.

---

# 35. No feed boost after recognition

After conclusion:

```text
Поднять волну
```

disabled/hidden.

MODULE18+ may later have other media growth.

---

# 36. Personal capacity API

DatingOverload:

```text
can_start_personal_date() -> bool
```

Returns true if:

```text
not overload_started
OR
last_personal_date_day != GameDay.current_day
```

---

# 37. Availability reason

Add:

```text
DatingOverloadTypes.PersonalDateAvailability
```

or tiny result:

```text
AVAILABLE
BODY_CAPACITY_USED
```

No generic scheduling error system.

---

# 38. Relationships integration

`Relationships.start_date_with_history(...)` or the production DateVenue start boundary must consult optional:

```text
/root/DatingOverload
```

before starting DatingCore.

If:

```text
BODY_CAPACITY_USED
```

return/display:

```text
Сегодня ты уже физически был на одном свидании.
```

No DatingCore session starts.

---

# 39. Do NOT put this rule inside DatingCore

DatingCore remains:

```text
one-session scorer
```

Daily physical capacity is meta-progression.

Keep it in DatingOverload/Relationships orchestration.

---

# 40. Completion integration

DatingOverload listens to:

```text
Relationships.date_result_applied
```

or exact final applied-result signal.

On each completed date while overload active:

```text
last_personal_date_day = current_day
personal_dates_completed += 1
```

Exactly once by `date_id`.

---

# 41. Fulfill demand

After date completion for:

```text
girl_id
```

find oldest backlog request for same girl:

priority:

```text
OVERDUE oldest first
then WAITING oldest
```

Mark exactly one:

```text
FULFILLED
fulfilled_day = current_day
```

---

# 42. If no demand for that girl

Date still consumes personal body capacity.

No demand is fulfilled.

This reinforces:

> spending the body elsewhere makes backlog worse.

---

# 43. Multiple demand entries same girl

One completed date fulfills:

```text
exactly 1 request
```

not all queued requests from that girl.

---

# 44. Date score does not affect fulfillment

Any completed DatingResult:

```text
+5
0
-5
```

counts as physically attended.

Demand status becomes fulfilled regardless of relationship outcome.

---

# 45. Date cooldown remains normal

Demand request does NOT bypass:

```text
Relationships date cooldown
```

If girl is on cooldown:

request can become overdue.

This is acceptable and further demonstrates limited throughput.

---

# 46. Demand does not force DateVenue

Player can service a request using existing:

```text
DateVenueInteractable
```

for that girl.

No separate Overload DatingCore path.

---

# 47. DateVenue presentation integration

Cafe DateVenue rows should annotate:

```text
Девушка со вспышкой — спрос: 2
```

or:

```text
Входящих встреч: 2
```

if backlog requests exist.

No new scheduling UI.

---

# 48. DateVenue capacity state

If daily personal capacity used:

DateVenue prompt/result:

```text
Сегодня больше физически не успеть.
```

List may still open read-only, but no date start buttons.

Simplest valid behavior:

- interaction shows short feedback;
- does not open picker.

---

# 49. Phone Overload section

After overload starts, add:

```text
ПЕРЕГРУЗКА
```

to existing Media section.

Minimum:

```text
Сегодня можно лично посетить: 1
Сегодня уже посещено: 0/1

Невыполненный спрос: N
Завершено запросов: M
```

---

# 50. Demand rows

Show active backlog requests:

```text
OVERDUE
Вчера, 19:00
Девушка у зеркала

TODAY
19:00
Девушка со вспышкой
```

No accept button.

Optional:

```text
[Открыть контакт]
```

only.

---

# 51. Fulfilled requests

Do not clutter main list.

Either:

- hide fulfilled;
- or small counter only.

Preferred:

```text
main list = backlog only
```

---

# 52. Sort order

Phone backlog order:

1. OVERDUE oldest first;
2. today's EARLY;
3. today's LATE.

Within same group:

```text
request_id ascending
```

---

# 53. No request expiration

Requests remain until fulfilled or until MODULE16 conclusion.

No auto-delete.

---

# 54. Post-recognition backlog

After problem recognized:

- no new requests generated;
- current backlog remains visible;
- one-date/day cap remains active until MODULE17 explicitly changes/solves it.

This is important:

> проблема не исчезает потому что герой понял проблему.

---

# 55. Why cap persists into MODULE17

First clone must feel like an actual capacity solution.

If cap disappears at recognition, cloning has no mechanical payoff.

MODULE17 will decide when additional clone capacity affects this.

---

# 56. Problem recognition — exact condition

Trigger if all are true:

```text
overload_started == true

GameDay.current_day >= overload_start_day + 2

total_generated_requests >= 7

backlog_count >= 4

personal_dates_completed >= 1

problem_recognized == false
```

---

# 57. Why these values

Base trajectory if player performs optimally:

Activation day:

```text
3 incoming
1 completed
backlog2
```

Next day:

```text
+2
1 completed
backlog3
```

Second next day:

```text
+2
backlog5 before/after capacity depending timing
```

At this point:

```text
7 total demand
physical throughput <=2–3
backlog >=4
```

The mismatch is visible without long grind.

---

# 58. Recognition evaluation timing

Call `_try_recognize_problem()`:

- after day wave generation;
- after personal date completion.

No `_process()`.

---

# 59. Feed boost can accelerate backlog, not minimum time

Even if boost creates 3/day:

still require:

```text
current_day >= start_day +2
```

The conclusion should be staged, not instant from one button.

---

# 60. Player must physically attend at least one date

Requirement:

```text
personal_dates_completed >= 1
```

Prevents:

```text
spam End Day
→ instant clone revelation
```

Player must experience actual body use.

---

# 61. Recognition transaction

First trigger:

```text
problem_recognized = true
```

Emit:

```text
clone_solution_needed()
```

and:

```text
problem_recognized()
```

exactly once.

---

# 62. Canonical realization text

Functional modal/toast:

```text
Проблема не в графике.

Проблема в количестве меня.
```

Second line:

```text
Нужен способ физически находиться в нескольких местах одновременно.
```

No joke dilution here; this is the clear design conclusion.

---

# 63. Story state after recognition

Still:

```text
GameStage.STAGE_4
```

Do NOT:

- advance to STAGE5;
- mark Scientist conquered;
- unlock Laboratory.

---

# 64. Module17 handoff

DatingOverload exposes:

```text
is_problem_recognized() -> bool
```

MODULE17 must use this as prerequisite for Scientist/clone sequence.

No extra StoryFeature enum needed.

---

# 65. No new Story flag

Do not add:

```text
story_scientist_available
story_clone_needed
```

to Story flags.

The overload state itself is canonical source.

---

# 66. Phone Story section before recognition

During overload:

```text
СТАДИЯ 4
Медийность

Входящих встреч: N
Лично успеваешь: 1 / день

Спрос растёт быстрее тебя.
```

Do not show Scientist yet.

---

# 67. Phone Story after recognition

```text
СТАДИЯ 4

Проблема не в графике.
Проблема в количестве меня.

Следующий шаг:
Найти способ быть в нескольких местах одновременно.
```

Optional final line:

```text
Нужна Учёная.
```

No Scientist actor until MODULE17.

---

# 68. No direct Scientist content

MODULE16 production catalog must still NOT add:

```text
girl_scientist
rival_scientist
appearance_female_scientist
appearance_male_scientist_rival
```

---

# 69. Demand IDs

Use integer:

```text
1,2,3...
```

Display does not show IDs.

No UUID.

---

# 70. Demand generation function

Semantic:

```text
_generate_wave(count, slot_pattern)
```

For each:

1. choose next candidate from incoming-offer cycle;
2. allocate request_id;
3. set:
   ```text
   created_day = current_day
   appointment_day = current_day
   ```
4. assign slot;
5. append to GameState;
6. emit:
   ```text
   demand_added(entry)
   ```

---

# 71. Candidate cycle index

Do NOT need persistent candidate index if it can derive from:

```text
next_request_id
```

Example:

```text
candidate_index =
(request_id - 1) % incoming_offer_count
```

This naturally incorporates current count but could reorder when count grows.

Preferred persistent:

```text
_dating_overload_candidate_cursor: int
```

Add if needed.

---

# 72. Candidate cursor rule

Use current offer list.

For each generated request:

```text
girl = offers[cursor % offers.size()]
cursor += 1
```

Persistent cursor.

When offer list grows, new girl naturally enters future cycle.

---

# 73. GameState additional cursor

If chosen:

```text
_dating_overload_candidate_cursor: int = 0
```

Reset0.

---

# 74. Demand GameState API

Minimal:

```text
is_dating_overload_started()
mark_dating_overload_started(day)

get_dating_overload_start_day()

allocate_dating_demand_request_id() -> int

append_dating_demand(entry)
get_dating_demand_entries() -> Array

mark_dating_demand_fulfilled(request_id, day)

get/set dating overload candidate cursor

get/set last personal date day
increment personal dates completed

get/set last feed boost day
get/set boost pending

is_dating_overload_problem_recognized()
mark_dating_overload_problem_recognized()
```

Cursor may encapsulate mutations in fewer methods.

Do not expose raw arrays for write.

---

# 75. Copy safety

`get_dating_demand_entries()` returns copies/snapshots.

Caller must not mutate GameState internal entries directly.

If using RefCounted entries, return duplicates.

---

# 76. Reset

GameState reset clears all overload state.

DatingOverload transient idempotency also reset.

---

# 77. Day-before activation

GameDay advances while Media not overload-ready:

DatingOverload does nothing.

---

# 78. Activation mid-day

If Media reaches overload-ready after photo publication:

activate immediately on that same current day.

First 3 requests are for:

```text
today
```

Daily body capacity is still unused unless a personal date already completed earlier that day.

---

# 79. Edge: date already completed earlier activation day

If current day already had a normal date BEFORE overload activated:

Should that consume overload capacity?

Canonical:

```text
NO
```

Daily cap begins at activation.

Reason:
avoid retroactively punishing an action performed before system existed.

`last_personal_date_day` starts `-1` at activation.

---

# 80. Edge: active Dating when overload triggers

Possible but unlikely.

If Media attention changes while DatingCore active:

- activation state can occur;
- do NOT interrupt current date;
- when current date completes after activation:
  - it counts as first overload personal date;
  - consumes capacity.

---

# 81. GameDay while Dating active

Existing apartment End Day interaction inaccessible during modal/date.

No special handling.

---

# 82. Feed boost Attention threshold

`+5` may cross:

```text
60
```

Existing Media logic may generate offer4.

DatingOverload listens to no special candidate event; next generation queries current offers.

---

# 83. Feed boost cannot exceed Attention100

Uses GameState clamp.

Reported actual gain may be0 near100.

`boost_pending` still set even if Attention already100.

Because the button's main overload effect is the next +1 demand.

---

# 84. Feed boost UI

Phone:

```text
[Поднять волну]
+5 Внимания
Следующий день: +1 входящий запрос
```

After use:

```text
Волна поднята
```

Disabled until next day.

---

# 85. Avoid compulsive clicker

No repeated click.

Exactly once per GameDay.

No animations/rewards per repeated press.

---

# 86. Demand and Media incoming distinction

Keep concepts separate:

```text
Media incoming offer
= girl has proactively opened romantic channel

Dating demand entry
= concrete request for another physical meeting
```

One girl can have:

```text
1 Media offer
many DatingDemand entries
```

---

# 87. Do not duplicate contacts

Demand generation never touches contact/discovery.

Media already ensured contact.

---

# 88. Demand source girls all default cafe

Current candidate production girls use:

```text
default_date_location_id = cafe
```

MODULE16 does not create multi-venue scheduling.

If future candidate venue differs:

DateVenue existing mapping handles it.

---

# 89. No forced teleport

Demand row never:

```text
teleports to cafe
starts date
```

Player physically travels.

This is necessary to feel manual limitation.

---

# 90. No travel-time calculation

Physical travel is enough.

Do not calculate minutes.

---

# 91. No appointment penalties

Overdue is visual/systemic only.

No:
- relationship loss;
- offer removal;
- story fail.

---

# 92. No impossible fail state

Player can always progress to recognition eventually.

Even if poor dates:
- completed physical date counts.

---

# 93. If all candidate girls on date cooldown

Player can:
- end a GameDay;
- cooldowns reduce;
- demand grows;
- eventually one becomes available.

No bypass required.

---

# 94. If player spends date on unrelated girl

Counts physical use.

Recognition still progresses personal_dates_completed.

Backlog remains larger.

This is valid.

---

# 95. No required score

Recognition does not require:

```text
successful relationship delta
```

Only bodily attendance.

---

# 96. Overload status snapshot

Create typed:

```text
DatingOverloadStatus
```

Fields:

```text
active
problem_recognized

current_day
capacity_per_day
capacity_used_today

total_generated
fulfilled_count
backlog_count
overdue_count

feed_boost_available
boost_pending
```

Phone consumes snapshot.

---

# 97. Signals

Recommended:

```text
overload_started()
demand_added(request_id)
demand_fulfilled(request_id)
backlog_changed(backlog_count)
personal_capacity_changed()
feed_boost_used()
problem_recognized()
clone_solution_needed()
```

No EventBus.

---

# 98. Relationships availability enum extension

If existing date availability enum has reasons, add:

```text
BODY_CAPACITY_USED
```

If not, production DateVenue can query DatingOverload separately.

Prefer one visible source of truth in the orchestration layer.

---

# 99. Normal date cooldown order

When determining date start:

1. contact;
2. date cooldown;
3. active date;
4. overload body capacity;
5. event content.

Exact order not product-critical, but error should be truthful.

---

# 100. Phone existing incoming offers

Do not remove MODULE15 incoming list.

MODULE16 adds concrete meeting backlog below it.

Potential layout:

```text
ВХОДЯЩИЕ КОНТАКТЫ
...

ПЕРЕГРУЗКА
...
```

---

# 101. Offer read state remains independent

Reading a Media message does not fulfill Demand.

---

# 102. Feed remains available

Existing photos/feed stay visible.

Feed boost is one additional action.

---

# 103. No additional photos

MODULE16 adds no new `media_photo_*`.

---

# 104. No Attention passive tick

Demand generation depends on overload active, not continuous Attention growth.

Attention still only changes from:
- existing Media actions;
- +5 Feed Boost.

---

# 105. Physical world presentation

At overload activation, add one small presentation-only visual:

Apartment Phone:

```text
notification badge / Label3D
"3"
```

or Phone UI badge.

No crowd/NPC simulation required.

---

# 106. Optional city notification visual

At backlog >=4:

one `MediaAttentionVisual`-style label may show:

```text
"НЕОТВЕЧЕННЫХ ПРИГЛАШЕНИЙ: ..."
```

Not mandatory.

Core DoD is Phone/UI.

---

# 107. Realization modal timing

When condition reached:

If Player currently:
- Dating modal;
- Rival minigame;
- Phone UI;

do NOT interrupt mid-action.

Set:

```text
problem_recognized = true
```

and queue/show realization next safe world gameplay or next Phone open.

Simpler allowed:

- emit signal immediately;
- presentation handler defers modal until Player GAMEPLAY.

Do not pause a minigame with story toast.

---

# 108. Mechanical recognition does not wait for modal

Even if presentation delayed:

```text
is_problem_recognized() == true
```

immediately after condition.

MODULE17 can rely on state.

---

# 109. No Stage transition

Repeated because critical:

```text
STAGE_4 remains STAGE_4
```

The Scientist is the Stage4 story girl; her line is next.

---

# 110. Test — inactive before Media ready

At Stage4:

```text
Attention 35
offers2
```

Expected:

```text
overload_started false
no demand
no date cap
```

---

# 111. Test — activation

Set Media:

```text
Attention45
offers3
```

Media overload-ready signal.

Expected:

```text
started true
start_day=current
3 requests
slots EARLY, EARLY, LATE
backlog3
```

---

# 112. Test — activation idempotent

Repeated:
- signal;
- `_ensure_started`;
- scene reload.

Still:

```text
3 initial requests only
```

---

# 113. Test — first explicit overlap

Initial requests:

```text
two appointment_day=current
two slot=EARLY_EVENING
```

---

# 114. Test — capacity before overload

Complete two dates same GameDay in isolated pre-overload test.

No overload block.

Existing one-active-session rule still applies sequentially.

---

# 115. Test — capacity after overload

Complete one date.

Second date same day:

```text
BODY_CAPACITY_USED
```

---

# 116. Test — next day capacity reset derived

No mutable bool reset needed.

Because:

```text
last_personal_date_day != new current_day
```

next day available.

---

# 117. Test — date consumes capacity once

Duplicate Relationships result callback same date_id:

no extra:
- fulfilled request;
- personal count.

Rely on Relationships exactly-once plus overload guard if needed.

---

# 118. Test — fulfill matching request

Backlog:

```text
A request1
B request2
```

Complete date with A.

Expected:

```text
request1 FULFILLED
request2 active
```

---

# 119. Test — multiple same girl

Requests A1,A2.

One date A:

```text
one fulfilled only
```

oldest active.

---

# 120. Test — unrelated date

Backlog A/B.

Date with C:

```text
capacity consumed
backlog unchanged
```

---

# 121. Test — bad date fulfills

Date delta -5:

matching demand fulfilled.

---

# 122. Test — day aging

Day10 WAITING request.

Advance to11:

```text
OVERDUE
```

still backlog.

---

# 123. Test — base new wave

On day advance:

```text
+2
EARLY/LATE
```

---

# 124. Test — backlog growth optimal

Initial3.

Fulfill1 →2.

Day+1 adds2, fulfill1 →3.

Day+1 adds2:

```text
>=5 before optional fulfill
```

Mismatch proven.

---

# 125. Test — Feed Boost

Use current day:

```text
Attention +5
boost_pending true
last_boost_day=current
```

Second use same day rejected.

---

# 126. Test — boosted wave

Next day:

```text
+3 requests
EARLY/EARLY/LATE
boost_pending false
```

---

# 127. Test — boost no stacking

Even if test tries duplicate same day:

only one pending boost.

---

# 128. Test — boost can create fourth Media offer

Attention55 + boost5 →60.

Existing Media:

```text
offer4 generated
```

Future demand cycle sees expanded offers.

---

# 129. Test — recognition minimum days

Even huge backlog on activation day:

```text
problem false
```

Day start+1:

still false.

Day start+2:

eligible if other conditions.

---

# 130. Test — recognition requires physical date

Generate 7+, backlog7, day+2, personal_dates_completed0.

Expected:

```text
false
```

Complete one date:

condition reevaluates:

```text
true
```

if backlog>=4.

---

# 131. Test — exact realization

When trigger:

```text
problem_recognized true
clone_solution_needed signal1
```

No second signal later.

---

# 132. Test — demand stops after recognition

Advance days:

no new entries.

Existing backlog remains.

---

# 133. Test — daily date cap persists after recognition

Same one-body cap still enforced.

MODULE17 must solve/extend.

---

# 134. Test — feed boost disabled after recognition

No new boost.

---

# 135. Test — Stage unchanged

Recognition:

```text
GameState.stage == STAGE_4
```

---

# 136. Test — no Scientist catalog

Still absent.

---

# 137. Test — no Laboratory access

```text
StoryFeature.LABORATORY == false
```

---

# 138. Test — Phone overload

After activation:

shows:
- capacity;
- backlog;
- requests;
- boost button.

---

# 139. Test — Phone sorting

Overdue oldest before today.

---

# 140. Test — Media incoming preserved

Existing Media incoming list still shown/works.

---

# 141. Test — DateVenue annotations

Girl with 2 demand requests displays2.

Girl with none no fake demand.

---

# 142. Test — ignored demands no relationship penalty

Advance 5 days.

Relationships unchanged solely from overdue.

---

# 143. Test — reset

Reset:

```text
started false
requests empty
last date day -1
boost state reset
recognized false
```

Media reset separately via GameState reset.

---

# 144. Test — full F5 bridge

Clean production route:

```text
PROLOGUE
→ Actress
→ Mine Boss
→ Editor
→ Photo Session
→ publish until Media overload-ready
→ initial 3 overlapping requests
→ physically complete at least one date
→ advance days
→ backlog grows
→ realization
→ clone_solution_needed
```

No debug.

---

# 145. Milestone D criterion

After MODULE16, game fulfills TECH_PLAN Milestone D:

```text
вся ручная часть
медийный рост
перегрузка свиданиями
готовый переход к клонам
```

No clone exists yet.

---

# 146. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Technical note:

```text
After Media overload-ready, personal hero capacity = 1 completed manual date per GameDay.
Dating demand generates 3 initial overlapping requests, then 2/day.
Backlog is non-punitive and persists.
Problem recognition after >=2 days, >=7 generated, >=4 backlog, >=1 completed personal date.
```

---

# 147. GDD implementation clarification

Document exact staged implementation without changing design intent:

```text
The overlap is represented by authored slot labels 19:00/20:00, not a real clock.
The system is intentionally not a calendar manager.
```

---

# 148. Suggested project area

```text
game/dating_overload/
├── dating_overload.gd
├── dating_overload_types.gd
├── dating_demand_entry.gd
├── dating_overload_status.gd
└── test/
```

No need for more managers.

---

# 149. What MODULE16 DOES NOT implement

Do NOT implement:

- Scientist content;
- Scientist rival;
- Lab;
- First Clone;
- Clone capacity;
- auto dates;
- calendar;
- appointment drag/drop;
- travel-time calculation;
- request expiration;
- request rejection penalties;
- relationship penalties for backlog;
- dynamic pricing;
- additional Media photos;
- social-network simulation;
- Story stage advance;
- save/load.

---

# 150. Definition of Done

MODULE16 complete only if:

- [ ] DatingOverload autoload exists;
- [ ] activation only from Media overload-ready at Stage4;
- [ ] activation idempotent;
- [ ] initial 3 requests exact;
- [ ] first slot pattern EARLY/EARLY/LATE;
- [ ] presentation shows overlapping times;
- [ ] daily personal date capacity exact1 after activation;
- [ ] cap applies to all manual dates;
- [ ] pre-overload dates remain unlimited by MODULE16;
- [ ] capacity consumes only on completed date;
- [ ] next GameDay naturally restores capacity;
- [ ] base demand wave exact2/day;
- [ ] demand slots EARLY/LATE;
- [ ] demand candidate cycle deterministic;
- [ ] repeated same-girl requests allowed;
- [ ] WAITING/OVERDUE/FULFILLED exact statuses;
- [ ] overdue remains backlog;
- [ ] no relationship/Authority penalty for overdue;
- [ ] matching completed date fulfills exactly one oldest demand;
- [ ] unrelated date still consumes body capacity;
- [ ] bad date still counts as physical fulfillment;
- [ ] backlog derived, not duplicate mutable counter;
- [ ] Phone overload section implemented;
- [ ] DateVenue demand counts/physical-cap feedback implemented;
- [ ] Feed Boost once/GameDay;
- [ ] Feed Boost +5 Attention;
- [ ] Feed Boost makes next wave3;
- [ ] boost does not stack;
- [ ] Media thresholds still work from +5;
- [ ] recognition exact >=start+2 days;
- [ ] recognition exact total generated>=7;
- [ ] recognition exact backlog>=4;
- [ ] recognition requires >=1 physical completed date;
- [ ] canonical realization text shown safely;
- [ ] clone_solution_needed emitted once;
- [ ] no new demand after recognition;
- [ ] daily one-body cap persists after recognition;
- [ ] Stage remains STAGE4;
- [ ] Scientist still absent;
- [ ] Laboratory locked;
- [ ] no clone mechanics;
- [ ] clean F5 route reaches recognition;
- [ ] all MODULE02–15 regressions PASS;
- [ ] MODULE17 not implemented ahead.

---

# 151. Recommended Cursor order

## Step 1 — Audit actual integration points

Check:

```text
Media.overload_ready
Media incoming offer API
GameDay
Relationships.start_date_with_history
Relationships.date_result_applied
DateVenueInteractable
PhoneJournal
GameState reset
```

## Step 2 — typed demand model + GameState

Implement state/reset/copies.

## Step 3 — DatingOverload core

Activation, 3-request first wave, 2/day, backlog, aging.

Unit-test without UI.

## Step 4 — daily body capacity

Integrate Relationships/DateVenue.

Regression DatingCore unchanged.

## Step 5 — fulfillment

Completed date → oldest demand same girl.

## Step 6 — Phone overload UI

Requests/backlog/capacity.

## Step 7 — Feed Boost

+5 Attention / next-wave +1.

## Step 8 — recognition

Exact condition + deferred safe presentation.

## Step 9 — production F5

Run full manual+media route to clone handoff.

## Step 10 — regressions/docs

All modules.

---

# 152. Cursor final report

## Overload architecture

Explain:

```text
DatingOverload
GameState demand state
Relationships integration
Phone/DateVenue
```

## Demand math

Confirm exact:

```text
activation: 3
slots: 19:00 / 19:00 / 20:00

each day: +2
body capacity: 1 completed date/day
```

## Fulfillment

Confirm one date fulfills one matching oldest demand.

## Feed boost

Confirm:

```text
once/day
Attention +5
next wave +1 request
```

## Recognition

Confirm exact:

```text
>=2 days
>=7 total generated
>=4 backlog
>=1 personal date completed
```

and exact conclusion.

## Handoff

Confirm:

```text
clone_solution_needed
Stage4 unchanged
no Scientist
no Laboratory
no clone
```

## F5 validation

Clean route from start through realization.

## Regressions

All previous suites.

## Commit

SHA.

Then STOP. Do not start MODULE17.
