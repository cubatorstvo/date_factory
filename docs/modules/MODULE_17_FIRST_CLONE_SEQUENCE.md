# MODULE 17 — FIRST CLONE SEQUENCE

**Проект:** Date Factory  
**Модуль:** 17 — First Clone Sequence  
**Цель:** завершить STAGE_4 через Учёную, открыть лабораторию, поставить одноразовую сцену первого клона, короткую мини-игру калибровки, физическое появление дубля и первый выбор `Работа / Свидания`.  
**Предыдущий модуль:** MODULE 16 — Dating Overload  
**Следующий модуль:** MODULE 18 — Clone Incremental Core  
**Product truth:** `docs/gdd/07_story_clones_finale.md`, разделы 33.5, 37, 38  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 17

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 17 реализует:

```text
DatingOverload.problem_recognized
→ появляется Учёная и её сюжетный самец
→ победить rival_scientist
→ познакомиться с girl_scientist
→ довести отношения до +5
→ Story: STAGE_4 → STAGE_5
→ StoryFeature.LABORATORY unlocked
→ войти в лабораторию
→ запустить установку клонирования
→ пройти одноразовую мини-игру
→ увидеть первого физического клона
→ выбрать:
   РАБОТА
   или
   СВИДАНИЯ
→ aggregate clone counts = 1
→ STOP
```

MODULE 17 НЕ реализует:

- второго и следующих клонов;
- производство клонов;
- деньги/минуту;
- свидания/минуту;
- пассивный ticking;
- clone upgrades;
- массовый терминал;
- President;
- individual clone defects / QA / memories / stats.

Это MODULE 18–20.

---

# 1. Сюжетная причинность

Учёная НЕ должна стоять у лаборатории сразу после Editor.

Она появляется только после:

```text
GameState.stage == STAGE_4
AND
DatingOverload.is_problem_recognized() == true
```

Причинность:

```text
медиа
→ перегрузка
→ игрок реально не успевает
→ «Проблема в количестве меня»
→ поиск Учёной
```

---

# 2. Story Framework не менять

Существующий canonical mapping остаётся:

```text
STAGE_4:
girl_scientist
rival_scientist
requires rival
completion = GIRL_COMPLETED
next = STAGE_5
```

MODULE17 создаёт реальные production definitions/actors.

Story сам делает:

```text
rival defeated + scientist conquered
→ STAGE_5
```

Не вызывать `advance_stage()` вручную из FirstClone/Scientist code.

---

# 3. StageActorAnchor — узкое расширение

В существующий `StageActorAnchor` добавить:

```text
@export var requires_overload_recognized: bool = false
```

Если `false` — поведение полностью прежнее.

Если `true`, actor появляется только когда:

```text
stage matches
AND
DatingOverload.is_problem_recognized()
```

Anchor с этим flag слушает:

```text
DatingOverload.problem_recognized
```

No `_process()`.

Не создавать generic `requirements[]` / condition DSL.

---

# 4. Scientist placement

Учёная и её ухажёр находятся:

```text
location = city_hub
```

у закрытого перехода:

```text
laboratory
```

Добавить markers:

```text
npc_story_scientist
npc_story_scientist_rival
```

Оба StageActorAnchor:

```text
story_stage = STAGE_4
requires_overload_recognized = true
```

Laboratory остаётся закрыта до завершения линии Учёной.

---

# 5. Phone Story — до/после recognition

До recognition:

```text
СТАДИЯ 4
Медийность

Входящих встреч: N
Лично успеваешь: 1 / день

Спрос растёт быстрее тебя.
```

После recognition:

```text
СТАДИЯ 4
Учёная

Проблема не в графике.
Проблема в количестве меня.

Следующий шаг:
Найти Учёную у закрытой лаборатории.
```

---

# 6. STORY GIRL — `girl_scientist`

Exact:

```text
id = &"girl_scientist"
display_name = "Учёная"

is_story = true
has_story_stage = true
story_stage = STAGE_4

primary_trait = KIND
secondary_trait = DEMANDING

required_experience = 4

discovery_situation_id =
&"discovery_situation_scientist_lab_gate"

appearance_profile_id =
&"appearance_female_scientist"

dating_pool_ids =
[
    &"date_pool_cafe_common",
    &"date_pool_scientist"
]

default_date_location_id = &"cafe"

dating_greeting_ids =
[
    &"dating_greeting_simple",
    &"dating_greeting_attention",
    &"dating_greeting_immediate_joke",
    &"dating_greeting_check_comfort"
]

dating_farewell_id =
&"dating_farewell_early_common"

speech_style_note =
"Спокойная и методичная; прежде всего следит за тем, что эксперимент делает с живыми людьми. Хуже всего реагирует, когда уверенность героя превращается в давление."
```

---

# 7. Почему `KIND + DEMANDING`

Учёная не должна быть второй STATUS-Актрисой.

Её правило:

> человек важнее красивого эксперимента.

`KIND`:

```text
likes CARE / VULNERABILITY / SIMPLICITY
dislikes DOMINANCE / CONFLICT / OBSESSION
```

`DEMANDING`:

```text
+1 если нет negatives и >=2 positives
-1 если negatives >=2
```

Комедия: персонаж, который собирается копировать людей, оказывается самым осторожным человеком истории.

---

# 8. Scientist clues

Exact:

```text
0:
"Когда помощник говорит «наверное безопасно», она прекращает эксперимент раньше, чем он заканчивает фразу."

1:
"Если человек честно говорит, что не понимает инструкцию, объясняет заново без раздражения."

2:
"Фразу «потом разберёмся, кому стало хуже» записывает только в список запрещённых формулировок."
```

---

# 9. Scientist discovery

ID:

```text
discovery_situation_scientist_lab_gate
```

Setup:

```text
"Учёная стоит у закрытой лаборатории и перечитывает табличку «ДОПУСК ОДНОГО ЧЕЛОВЕКА». Рядом её ухажёр объясняет, что одного человека обычно достаточно."
```

До rival defeat работает existing Story gate.

После rival:

### SUCCESS

```text
id = discovery_approach_scientist_body_count
label = "Спросить, можно ли увеличить количество тела, не меняя количество личности"
outcome = SUCCESS

result_text =
"Она впервые посмотрела не на табличку, а на тебя. Потом ещё раз на табличку."
```

### FAILURE — Capital

```text
id = discovery_approach_scientist_buy_body
label = "Предложить сразу купить второй организм"
CAPITAL 1
FAILURE

"Она уточнила, в каком разделе бухгалтерии ты обычно покупаешь организмы."
```

### FAILURE — Aura

```text
id = discovery_approach_scientist_ethics_later
label = "Сказать, что моральную сторону можно решить после запуска"
AURA 1
FAILURE

"Она записала формулировку в блокнот. Судя по заголовку страницы, это не плюс."
```

---

# 10. Scientist direct prerequisite

Не полагаться только на actor visibility.

Если кто-то вызывает GirlDiscovery API напрямую:

```text
girl_id == girl_scientist
AND
stage == STAGE_4
AND
!DatingOverload.is_problem_recognized()
```

→ blocked semantic result:

```text
STORY_PREREQUISITE
```

Без:

- clue;
- failure;
- retry cooldown.

Никакого generic prerequisite framework.

---

# 11. Scientist appearance

Create:

```text
appearance_female_scientist
```

Existing female base.

Readable:

- lab coat/light outer layer if available;
- glasses/clipboard/simple lab accessory;
- restrained palette.

No new body mesh.

---

# 12. STORY RIVAL — `rival_scientist`

Exact:

```text
id = &"rival_scientist"
display_name = "Ухажёр Учёной"

is_story = true
has_story_stage = true
story_stage = STAGE_4

required_authority = 7
authority_reward = 3

muscle = 4
appearance = 2
capital = 3
aura = 4

preferred_competition = SIGMA

allowed_competitions =
[
    SIGMA,
    SLAP
]

appearance_profile_id =
&"appearance_male_scientist_rival"

competition_modifier_id = &""
```

---

# 13. Authority progression

Clean story:

```text
Actress rival   +2
Mine Boss rival +2
Editor rival    +3
-------------------
Authority        7
```

Scientist rival requires exactly:

```text
7
```

No optional rival grind required.

Reward:

```text
+3
```

Clean result after win:

```text
Authority 10
```

Это future President milestone, но President здесь не создаётся.

---

# 14. Competition accessibility

Preferred:

```text
SIGMA
```

Allowed:

```text
SIGMA + SLAP
```

Без Aura unlock:

```text
SLAP
```

остаётся available.

Main story не может требовать конкретный perk/build.

---

# 15. Rival appearance

Create:

```text
appearance_male_scientist_rival
```

Male base; clean coat/jacket, badge/glasses/clipboard if available.

No unique body.

---

# 16. Scientist date pool

Create:

```text
date_pool_scientist
```

Minimum 4 specific events:

```text
2 CONVERSATION
1 SPACE_EVENT
1 GIRL_PROPOSAL
```

Union:

```text
date_pool_cafe_common + date_pool_scientist
```

---

# 17. Event — `date_event_scientist_failed_test`

Category:

```text
CONVERSATION
```

Setup:

```text
"Она спрашивает, что ты делаешь, когда уверен в решении, а потом выясняется, что решение было неправильным."
```

Actions:

```text
"Сначала признать ошибку человеку, которого она задела"
AURA 0
[VULNERABILITY, CARE]
```

```text
"Пересчитать условия и попробовать снова"
CAPITAL 1
[CONTROL]
```

```text
"Найти того, кто выполнил решение недостаточно уверенно"
MUSCLE 1
[DOMINANCE]
```

```text
"Записать ошибку как отдельный метод"
APPEARANCE 1
[ORIGINALITY]
```

---

# 18. Event — `date_event_scientist_clone_question`

Category:

```text
CONVERSATION
```

Setup:

```text
"Она спрашивает: если появится твоя точная копия и скажет, что не хочет быть тобой, кто из вас неправ?"
```

Actions:

```text
"Сказать, что тогда это уже отдельный человек"
AURA 0
[CARE, VULNERABILITY]
```

```text
"Объяснить, что копия обязана продолжать основную цель"
CAPITAL 1
[OBSESSION]
```

```text
"Сказать, что оригинал решает первым"
MUSCLE 1
[DOMINANCE]
```

```text
"Определить оригинал по тому, кто первым задаст этот вопрос"
APPEARANCE 1
[ABSURDITY, ORIGINALITY]
```

---

# 19. Event — `date_event_scientist_hot_cup`

Category:

```text
SPACE_EVENT
```

Setup:

```text
"Официант ставит слишком горячую чашку прямо перед ней и сразу уходит."
```

Actions:

```text
"Передвинуть чашку на пустое блюдце"
MUSCLE 0
[CARE, SIMPLICITY]
```

```text
"Попросить второе блюдце и проверить температуру"
CAPITAL 1
[CONTROL]
```

```text
"Громко вернуть официанта к эксперименту"
AURA 1
[CONFLICT, CONTROL]
is_public = true
```

```text
"Сделать из салфеток тепловой барьер"
APPEARANCE 1
[ORIGINALITY]
```

---

# 20. Event — `date_event_scientist_napkin_hypothesis`

Category:

```text
GIRL_PROPOSAL
```

Setup:

```text
"Она предлагает записать на салфетке одно утверждение, которое вы готовы проверить прямо сейчас."
```

Actions:

```text
"«Эта салфетка впитывает кофе»"
MUSCLE 0
[SIMPLICITY]
```

```text
"Сначала определить критерий успеха"
CAPITAL 1
[CONTROL]
```

```text
"Составить полную программу эксперимента на вечер"
AURA 1
[OBSESSION]
```

```text
"«Если сложить салфетку семь раз, официант заметит»"
APPEARANCE 1
[ORIGINALITY, ABSURDITY]
```

---

# 21. Scientist feasibility

Mandatory automated content test:

Ideal:

```text
4 primary positives
+ DEMANDING +1
= date_delta +5
```

Poor route:

```text
>=2 primary negatives
→ DEMANDING -1
```

Scientist must not be structurally impossible or always-positive.

---

# 22. Experience progression

Clean story:

```text
Neighbor → XP1
Actress → XP2
Mine Boss → XP3
Editor → XP4
```

Scientist:

```text
required_experience = 4
```

Completion:

```text
XP4 → XP5
Upgrade Point +1 exactly once
```

---

# 23. Scientist completion

After:

```text
rival_scientist defeated
girl_scientist +5
```

existing Story:

```text
STAGE_4 → STAGE_5
```

and:

```text
StoryFeature.LABORATORY == true
```

Do NOT manually unlock the location.

---

# 24. Stage5 presentation boundary

Canonical Stage5 Story maps to President, but President content is intentionally absent.

Until first clone exists:

```text
STAGE_5
Лаборатория

Лаборатория открыта.
Создай первого клона.
```

Do not show missing President objective.

Use safe `try_get_*` presentation lookup as in 14B.

Do not modify StoryStageDefinition.

---

# 25. Laboratory scene

Use existing:

```text
laboratory
```

Existing marker:

```text
story_point_clone_machine
```

Add if needed:

```text
story_point_clone_output
story_point_clone_work_station
story_point_clone_date_station
```

Reuse `story_point_lab_date_room` as date station if physically appropriate.

---

# 26. Lab blockout

Add simple primitives only:

```text
clone chamber
control pedestal

sign:
КАЛИБРОВКА

arrows:
РАБОТА
СВИДАНИЯ
```

No final art.

---

# 27. `FirstCloneMachineInteractable`

Create:

```text
class_name FirstCloneMachineInteractable
extends Interactable
```

At clone-machine marker.

Availability iff:

```text
DatingOverload.is_problem_recognized()
Story.is_feature_unlocked(LABORATORY)
GameState.is_girl_conquered(&"girl_scientist")
GameState.get_total_clones() == 0
FirstClone sequence not active
World.current_location_id == &"laboratory"
```

---

# 28. Machine after creation

If:

```text
total_clones >= 1
```

prompt/feedback:

```text
Первый клон уже создан.
```

No second sequence.

MODULE18 later expands production.

---

# 29. `FirstClone` service

Create autoload:

```text
FirstClone
```

Responsibilities:

- eligibility;
- one active sequence;
- calibration lifecycle;
- physical preview spawn;
- assignment;
- exactly-once commit;
- representative clone reconstruction in lab;
- handoff to MODULE18.

No `_process()`.

Autoload order:

```text
...
Media
DatingOverload
FirstClone
```

---

# 30. Persistent source of truth

Do NOT add:

```text
first_clone_created bool
```

Canonical:

```text
GameState.get_total_clones() >= 1
```

Assignment derived from existing aggregate counts:

WORK:

```text
total1 working1 dating0
```

DATING:

```text
total1 working0 dating1
```

No separate persistent clone job.

---

# 31. No late rates

MODULE17 must leave:

```text
money_per_minute = 0
dates_per_minute = 0
```

No call to `set_late_rates`.

---

# 32. Clone calibration minigame

Create bespoke:

```text
CloneCalibrationMinigame
```

One-time staging.

No generic clone minigame framework.

Length target:

```text
20–40 sec
```

No permanent failure.

No defects.

A miss repeats current pass.

---

# 33. Calibration mechanic

Horizontal normalized track:

```text
0.0 ... 1.0
```

Pointer ping-pongs.

Player presses:

```text
SPACE
```

inside target zone.

Inside:

```text
pass
```

Outside:

```text
0.45 sec miss feedback
retry same pass
```

No score.

---

# 34. Exact passes

## BODY

```text
label = "СОВПАДЕНИЕ ТЕЛА"
target_center = 0.35
target_width = 0.28
pointer_speed = 0.55
```

## FACE

```text
label = "СОВПАДЕНИЕ ЛИЦА"
target_center = 0.62
target_width = 0.22
pointer_speed = 0.70
```

## CONFIDENCE

```text
label = "СОВПАДЕНИЕ УВЕРЕННОСТИ"
target_center = 0.48
target_width = 0.16
pointer_speed = 0.85
```

`target_width` = full normalized zone width.

`pointer_speed` = normalized units/sec before reflection.

No RNG.

---

# 35. Minigame phases

```text
INTRO
CALIBRATION
PASS_FEEDBACK
COMPLETE
FINISHED
```

`current_pass_index 0..2`.

Player control:

```text
MINIGAME
```

Current laboratory remains background.

---

# 36. Intro

```text
КАЛИБРОВКА ОРИГИНАЛА

Система создаст копию настолько точную,
насколько это позволяет текущая юридическая ситуация.

Нажимай SPACE, когда сканер находится в зоне.
```

---

# 37. Feedback

BODY:

```text
ТЕЛО: СОВПАЛО
```

FACE:

```text
ЛИЦО: СОВПАЛО
```

CONFIDENCE:

```text
УВЕРЕННОСТЬ: ВНЕ РЕКОМЕНДУЕМОГО ДИАПАЗОНА
КОПИРОВАНИЕ РАЗРЕШЕНО РУЧНЫМ РЕШЕНИЕМ
```

Это success, не defect.

Miss:

```text
КАЛИБРОВКА НЕ ПРИНЯТА
ПОВТОРИТЬ СКАН
```

---

# 38. Abort

Если sequence закрыта до трех success:

```text
total clones = 0
counts = 0/0/0
partial calibration discarded
```

Можно restart from BODY.

---

# 39. After calibration

Three successes:

```text
КАЛИБРОВКА ЗАВЕРШЕНА
ПЕЧАТЬ ЧЕЛОВЕКА
```

Then:

1. calibration UI hides;
2. 2–3 sec chamber presentation;
3. physical clone preview appears;
4. assignment modal opens.

Still:

```text
GameState.total_clones == 0
```

until assignment.

---

# 40. `FirstCloneActor`

Thin presentation node.

Uses:

```text
CharacterActor
```

through existing CharacterFactory.

No:

- AI;
- navigation;
- individual stats;
- inventory;
- personality;
- dating logic.

---

# 41. Clone appearance

Create:

```text
appearance_male_first_clone
```

Intentionally match protagonist visible proxy as closely as current project allows:

- same base male body;
- same proportions;
- same clothes/colors proxy;
- same face preset;
- same scale.

No random differences/defects.

---

# 42. Physical reveal

Simple:

```text
chamber light/fade
→ clone visible
→ idle/gesture
```

No cinematic-camera framework.

Functional line:

```text
Клон:
«Я тоже считаю, что проблема была в количестве тебя.»
```

---

# 43. Assignment

Modal:

```text
КУДА ОТПРАВИТЬ ПЕРВОГО КЛОНА?

[РАБОТАТЬ]
[НА СВИДАНИЯ]
```

Exactly two options.

No free/unassigned first clone.

---

# 44. WORK commit

Atomic:

```text
GameState.set_clone_counts(
    total = 1,
    working = 1,
    dating = 0
)
```

---

# 45. DATING commit

Atomic:

```text
GameState.set_clone_counts(
    total = 1,
    working = 0,
    dating = 1
)
```

---

# 46. Commit timing

Physical preview exists before assignment, but persistent clone does not.

Assignment is transaction boundary.

This prevents:

```text
clone exists
but role never chosen
```

Double callback cannot create total2.

---

# 47. Assignment presentation

WORK:

```text
Tween clone → story_point_clone_work_station
```

DATING:

```text
Tween clone → story_point_clone_date_station
```

~1.5 sec.

No NavMesh/pathfinding.

Clone remains visible in loaded laboratory.

---

# 48. Representative persistence

When laboratory loads and:

```text
total_clones >= 1
```

FirstClone reconstructs exactly ONE representative actor.

If:

```text
working >=1
```

→ work station.

Else if:

```text
dating >=1
```

→ date station.

This is not a general physical clone system.

MODULE19 later replaces/extends it.

---

# 49. No reassignment in MODULE17

After first choice:

```text
WORK ↔ DATING
```

cannot be changed yet.

MODULE18 terminal owns redistribution.

---

# 50. No immediate output

WORK does NOT:

- add Money;
- work SalaryMine;
- set money/min.

DATING does NOT:

- fulfill backlog;
- run DatingCore;
- change relationship;
- set dates/min.

MODULE17 verifies creation + persistent assignment only.

---

# 51. DatingOverload remains unresolved mechanically

After first clone:

- existing backlog remains;
- hero personal capacity stays1/day;
- no new demand generation already stopped after recognition.

MODULE18 makes clone assignment productive.

---

# 52. Phone clone section

Before total_clones1:

hidden.

After:

```text
КЛОНЫ

Всего: 1
На работе: 1
На свиданиях: 0
Свободных: 0
```

or reverse.

Do NOT show money/min or dates/min yet.

---

# 53. FirstClone status

Typed:

```text
FirstCloneStatus
```

Minimum:

```text
eligible
sequence_active
clone_created
assignment
```

`clone_created` derived from total count.

Availability statuses:

```text
AVAILABLE
OVERLOAD_NOT_RECOGNIZED
SCIENTIST_NOT_COMPLETED
LAB_LOCKED
ALREADY_CREATED
SEQUENCE_ACTIVE
NOT_IN_LAB
```

---

# 54. Signals

Recommended:

```text
sequence_started()
calibration_completed()
clone_preview_spawned()
first_clone_assigned(assignment)
first_clone_completed()
```

No global EventBus.

---

# 55. Optional Scientist presence in lab

For scene presentation, allowed to spawn temporary:

```text
CharacterActor
appearance_female_scientist
```

near machine.

Presentation only.

No GirlActor / relationship interaction.

Remove/hide after assignment.

Optional line:

```text
Учёная:
«Я решила не спрашивать, зачем тебе второй ты. Я уже видела первый.»
```

---

# 56. Clone machine labels

Before:

```text
КОЛИЧЕСТВО ОРИГИНАЛОВ: 1
КОЛИЧЕСТВО КОПИЙ: 0

ПРЕДУПРЕЖДЕНИЕ:
ПОСЛЕ ЗАПУСКА ЭТИ ЧИСЛА ПЕРЕСТАНУТ БЫТЬ УДОБНЫМИ.
```

After:

```text
ОРИГИНАЛОВ: 1
КОПИЙ: 1
```

---

# 57. Explicitly forbidden clone systems

Do NOT create:

```text
clone quality
clone defects
mutation
QA
memory
consent meter
legal status
rebellion
clone happiness
per-clone characteristic
clone perk tree
CloneEntity[]
CloneActorPool
CloneSimulation
```

Calibration misses only retry.

---

# 58. No clone Dating simulation

Dating-assigned clone is aggregate role state.

No cloned DatingCore.

No per-girl clone strategy.

---

# 59. No clone work simulation

Working clone is aggregate role state.

No SalaryMine visit.

No individual shift.

---

# 60. Production content additions

MODULE17 adds:

```text
girl_scientist
rival_scientist

appearance_female_scientist
appearance_male_scientist_rival
appearance_male_first_clone

discovery_situation_scientist_lab_gate
date_pool_scientist
4 scientist date events
```

Still absent:

```text
girl_president
rival_president
girl_final_target
```

---

# 61. Content validation

`ContentDB.validate_all()` must PASS.

Check exact:

```text
Scientist:
stage4
KIND
DEMANDING
XP4

Scientist rival:
stage4
Authority7
reward3
preferred SIGMA
allowed SIGMA+SLAP
```

Pool:
- all events cafe-compatible;
- no duplicate IDs;
- +5 path feasible;
- bad path feasible.

---

# 62. Core tests — Scientist activation

### Before recognition

Stage4:

```text
scientist anchor empty
rival anchor empty
direct discovery blocked
```

### After recognition

Without scene reload:

```text
girl_scientist visible
rival_scientist visible
```

---

# 63. Core tests — story progression

Clean:

```text
Experience4
Authority7
```

Rival:
- challenge available;
- SLAP available with no Aura perk;
- win → Authority10;
- stage remains4.

Scientist:
- XP4 exact;
- contact success;
- ideal date → +5;
- Experience5;
- Upgrade Point +1;
- Story → Stage5;
- Laboratory unlocked.

---

# 64. Core tests — Laboratory

Before Scientist +5:

```text
laboratory locked
```

After Stage5:

```text
available
```

No manual location unlock call.

At Stage5:
- no President actors;
- Phone says create first clone.

---

# 65. Core tests — calibration

Pure constants:

```text
BODY .35 / .28 / .55
FACE .62 / .22 / .70
CONFIDENCE .48 / .16 / .85
```

Pointer:
- deterministic ping-pong;
- stays0..1.

Miss:
- same pass.

Success:
- exactly next pass.

Abort:
- clone counts remain0.

---

# 66. Core tests — first clone

After 3 successes:

```text
preview visible
total clones0
assignment shown
```

WORK:

```text
1/1/0
free0
rates0/0
```

DATING:

```text
1/0/1
free0
rates0/0
```

Double assignment:

```text
still total1
```

Machine afterward:
- sequence unavailable.

---

# 67. Core tests — physical representative

WORK:
- one actor at work station.

DATING:
- one actor at date station.

Leave lab / return:
- exactly one representative reconstructed;
- no duplicate.

No `CloneActorPool`.

---

# 68. Core tests — boundaries

After first clone:

```text
DatingOverload backlog unchanged
manual body cap still1/day
money_per_minute0
dates_per_minute0
President absent
```

No passive output over frames/days.

---

# 69. Full F5 acceptance

Clean no-debug:

```text
PROLOGUE
→ Actress
→ Mine Boss
→ Editor
→ Media
→ DatingOverload
→ problem recognized
→ Scientist pair appears
→ Scientist rival win
→ Scientist contact/date
→ Scientist +5
→ STAGE5
→ Laboratory unlock
→ travel laboratory
→ calibration
→ physical clone
→ choose Work or Dating
→ total_clones1
```

Required.

---

# 70. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
docs/content/MANUAL_CONTENT.md
```

Document:

```text
Scientist appears only after overload recognition.
XP4 / rival Authority7.
Scientist completion unlocks Stage5/Laboratory.
First clone is one-off calibrated scene.
GameState aggregate clone counts are source of truth.
No individual persistent clone object.
No rates until MODULE18.
```

---

# 71. Suggested project area

```text
game/first_clone/
├── first_clone.gd
├── first_clone_types.gd
├── first_clone_status.gd
├── first_clone_machine_interactable.gd
├── clone_calibration_minigame.gd
├── first_clone_actor.gd
└── test/
```

No extra managers.

---

# 72. Definition of Done

MODULE17 done only if:

- [ ] Scientist production definition exists;
- [ ] Scientist = KIND + DEMANDING;
- [ ] XP4 exact;
- [ ] clues/discovery exist;
- [ ] Scientist hidden before overload recognition;
- [ ] direct discovery cannot bypass recognition;
- [ ] Scientist rival production definition exists;
- [ ] Authority7/reward3 exact;
- [ ] preferred SIGMA;
- [ ] allowed SIGMA+SLAP;
- [ ] story works without Aura perk;
- [ ] Scientist pair appears after recognition without polling;
- [ ] Scientist pool has4 specific events;
- [ ] +5 and bad routes verified;
- [ ] Scientist completion yields XP5/UP once;
- [ ] Story Stage4→Stage5 automatically;
- [ ] Laboratory unlocks from existing StoryFeature;
- [ ] President content not created;
- [ ] Stage5 Phone shows First Clone handoff;
- [ ] FirstClone autoload exists;
- [ ] machine works only in laboratory / total0;
- [ ] bespoke 3-pass calibration exists;
- [ ] exact constants implemented;
- [ ] miss only retries;
- [ ] no quality/defects;
- [ ] abort creates no clone;
- [ ] physical preview after 3 passes;
- [ ] first clone appearance matches player proxy;
- [ ] exactly WORK or DATING assignment;
- [ ] WORK =1/1/0;
- [ ] DATING =1/0/1;
- [ ] assignment exactly once;
- [ ] rates remain0;
- [ ] no passive output;
- [ ] one physical representative reconstructs in lab;
- [ ] no generic clone entity simulation;
- [ ] Phone clone counts visible;
- [ ] DatingOverload not silently solved;
- [ ] clean F5 route reaches assigned first clone;
- [ ] ContentDB validation PASS;
- [ ] MODULE02–16 regressions PASS;
- [ ] MODULE18 not implemented ahead.

---

# 73. Recommended Cursor order

```text
1. Audit StageActorAnchor / Story / overload APIs / lab markers / clone count APIs.
2. Add narrow overload prerequisite to StageActorAnchor.
3. Add Scientist + rival + appearances + discovery + 4 date events.
4. Prove recognition → Scientist → +5 → Stage5 → Lab.
5. Implement FirstClone eligibility/core.
6. Implement deterministic calibration state + UI.
7. Spawn physical preview.
8. Commit Work/Dating aggregate counts.
9. Reconstruct one representative on lab load.
10. Phone Stage5 + clone counts.
11. Full F5 route.
12. ContentDB + MODULE02–16 regressions + docs.
```

---

# 74. Cursor final report

## Scientist

Confirm:

```text
KIND + DEMANDING
XP4
rival Auth7 / reward3
SIGMA + SLAP
```

Explain recognition gate.

## Story

Confirm:

```text
problem recognized
→ Scientist
→ Scientist +5
→ Stage5
→ Laboratory
```

No custom stage advance.

## Calibration

Confirm exact 3 passes/constants and no defect/quality system.

## First clone

Confirm:

```text
physical representative
WORK → 1/1/0
DATING → 1/0/1
```

## Boundary

Confirm:

```text
rates0
no passive money/dates
no second clone
no President
```

## F5 validation

Clean route through first assigned clone.

## Regressions

All previous suites.

## Commit

SHA.

Then STOP. Do not begin MODULE18.
