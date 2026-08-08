# MODULE 17 FIX — SCIENTIST PRODUCTION GATE / SPAWN WIRING

**Проект:** Date Factory  
**Статус:** блокирующая коррекция MODULE 17  
**Причина:** `FirstClone`, Scientist static content и лаборатория уже реализованы, но production-route от `DatingOverload.problem_recognized` к физической Учёной отсутствует. Поэтому обычный игрок не может пройти STAGE_4 → STAGE_5 и добраться до первого клона.

---

# 1. Что уже правильно и НЕ надо переделывать

Сохранить текущие:

```text
game/first_clone/*
girl_scientist.tres
rival_scientist.tres
date_pool_scientist
4 Scientist dating events
laboratory clone machine/markers
Phone STAGE5 clone handoff
Phone clone count section
FirstClone autoload
```

Уже корректны:

```text
Scientist:
KIND + DEMANDING
XP 4

Scientist rival:
Authority 7
reward 3
preferred SIGMA
allowed SIGMA + SLAP

FirstClone calibration:
BODY       .35 / .28 / .55
FACE       .62 / .22 / .70
CONFIDENCE .48 / .16 / .85

Assignment:
WORK   → 1 / 1 / 0
DATING → 1 / 0 / 1

late rates:
0 / 0
```

---

# 2. Блокер №1 — `StageActorAnchor` не получил MODULE17 prerequisite

Фактический:

```text
res://world/actors/stage_actor_anchor.gd
```

сейчас проверяет только:

```text
current_stage == story_stage
```

и defeated-state rival.

В нём отсутствует:

```text
requires_overload_recognized
```

Добавить:

```gdscript
@export var requires_overload_recognized: bool = false
```

Default `false`, чтобы весь MODULE14 content продолжил работать без изменений.

В `_should_spawn()` после stage match:

```text
if requires_overload_recognized:
    DatingOverload must exist
    DatingOverload.is_problem_recognized() must be true
```

Иначе `return false`.

---

# 3. Event-driven refresh

Если `requires_overload_recognized == true`, подписаться на:

```text
DatingOverload.problem_recognized
```

Callback:

```text
_refresh_spawn()
```

Также добавить:

```text
GameState.state_reset → _refresh_spawn()
```

если этого ещё нет.

Никакого `_process()`.

---

# 4. Блокер №2 — Scientist anchors отсутствуют из `city_hub.tscn`

Добавить возле физического transition `ToLab` два `StageActorAnchor`.

## Girl

```text
node name = npc_story_scientist
actor_kind = GIRL
content_id = &"girl_scientist"
story_stage = STAGE_4
requires_overload_recognized = true
```

## Rival

```text
node name = npc_story_scientist_rival
actor_kind = RIVAL
content_id = &"rival_scientist"
story_stage = STAGE_4
requires_overload_recognized = true
```

Placement:

```text
Player path
→ rival Scientist
→ girl Scientist
→ locked Laboratory door
```

Не ставить colliders друг в друга или прямо в transition collider. Ориентир 2.5–4 m между interactable targets.

---

# 5. Expected physical behavior

## STAGE4 before overload recognition

```text
Scientist absent
Scientist rival absent
Lab locked
```

## Same loaded city_hub after `problem_recognized`

Без scene reload:

```text
Scientist appears
Scientist rival appears
Lab remains locked
```

## After rival defeated

```text
rival leaves
Scientist stays
```

## After Scientist +5

Existing Story:

```text
STAGE4 → STAGE5
```

Then:

```text
both Stage4 anchors clear
Lab becomes available
```

---

# 6. Блокер №3 — direct GirlDiscovery API can bypass overload prerequisite

Фактический `GirlDiscovery._story_gate_block()` сейчас спрашивает только `Story.get_story_girl_gate()`.

А Story для current Stage4 проверяет:

```text
stage
rival defeated
```

но НЕ `DatingOverload.problem_recognized`.

Добавить:

```gdscript
const RESULT_STORY_PREREQUISITE: StringName = &"STORY_PREREQUISITE"
```

И ДО обычного Story rival gate:

```text
if girl_id == StoryIds.GIRL_SCIENTIST
AND current stage == STAGE_4
AND DatingOverload.is_problem_recognized() == false:
    return STORY_PREREQUISITE
```

Если DatingOverload отсутствует — также blocked.

---

# 7. No side effects

`STORY_PREREQUISITE`:

- NOT FAILURE;
- no clue reveal;
- no retry cooldown;
- no relationship;
- no contact.

Functional feedback:

```text
Сначала нужно понять, зачем тебе вообще второй ты.
```

---

# 8. Не загрязнять generic Story/Rival core

Не добавлять generic requirement DSL в:

```text
StoryStageDefinition
Story
RivalEncounters
```

Scientist overload prerequisite — explicit MODULE17 integration rule.

Direct RivalEncounters debug-call before recognition не является production path; physical rival отсутствует до recognition.

---

# 9. Phone уже правильный

Current Phone уже показывает после recognition:

```text
СТАДИЯ 4
Учёная

Проблема не в графике.
Проблема в количестве меня.

Следующий шаг:
Найти Учёную у закрытой лаборатории.
```

Не переписывать.

После fix UI начнёт соответствовать миру.

---

# 10. FirstClone уже правильный

Не переделывать current clone implementation.

Особенно сохранить:

```text
eligibility:
overload recognized
Scientist conquered
LABORATORY unlocked
total clones == 0
current location == laboratory
```

И:

```text
WORK   → 1/1/0
DATING → 1/0/1
```

Rates после assignment:

```text
money_per_minute = 0
dates_per_minute = 0
```

---

# 11. Mandatory tests

## A — old anchors regression

Neighbor / Actress / Mine Boss / Editor anchors с default `requires_overload_recognized=false` работают как раньше.

## B — Scientist hidden

```text
STAGE4
problem_recognized=false
```

Expected: оба Scientist anchors пусты.

## C — live recognition spawn

`city_hub` уже загружен.

Real `DatingOverload.problem_recognized`.

Expected без reload: оба actors появляются.

## D — direct discovery blocked

```text
STAGE4
problem=false
rival_scientist вручную marked defeated
```

Call:

```text
GirlDiscovery.begin_attempt(&"girl_scientist")
```

Expected:

```text
ok=false
reason=STORY_PREREQUISITE
```

No cooldown/clue/contact mutation.

## E — recognition then rival gate

```text
problem=true
rival undefeated
```

Scientist attempt → `STORY_RIVAL_REQUIRED`.

## F — rival then Scientist

```text
problem=true
rival defeated
XP4
```

Scientist attempt succeeds normally.

## G — physical Stage transition

Through actual world actors:

```text
recognition
→ rival Scientist
→ Scientist discovery/contact/date
→ +5
```

Expected:

```text
STAGE5
LABORATORY true
```

## H — lab/clone smoke

Then:

```text
city → laboratory
→ machine
→ calibration
→ assignment
```

Expected:

```text
total1
working1/dating0
OR
working0/dating1
rates0/0
```

---

# 12. Full F5 regression

Clean route:

```text
F5
→ Neighbor
→ Actress
→ Mine Boss
→ Editor
→ Media
→ DatingOverload
→ recognition

WITHOUT scene reload workaround:
→ Scientist pair appears at lab gate

→ rival Scientist
→ Scientist +5
→ Stage5
→ Lab
→ first clone
```

This is the actual MODULE17 acceptance test.

---

# 13. Definition of Done

Fix accepted only if:

- [ ] `StageActorAnchor.requires_overload_recognized` exists;
- [ ] default false;
- [ ] event-driven refresh on problem_recognized;
- [ ] reset refresh works;
- [ ] city_hub contains `npc_story_scientist`;
- [ ] city_hub contains `npc_story_scientist_rival`;
- [ ] both Stage4;
- [ ] both require overload recognized;
- [ ] both appear live after recognition;
- [ ] both absent before recognition;
- [ ] Scientist direct discovery blocked before recognition;
- [ ] dedicated non-failure prerequisite result exists;
- [ ] no cooldown/clue failure side effects;
- [ ] rival remains Story-gated after recognition;
- [ ] clean physical route Stage4→5 works;
- [ ] FirstClone behavior unchanged;
- [ ] assignment remains exactly 1/1/0 or 1/0/1;
- [ ] late rates remain0;
- [ ] MODULE02–16 regressions PASS;
- [ ] MODULE18 not implemented.

---

# 14. Cursor final report

## Root cause

Почему static Scientist content и FirstClone существовали, но production world не давал физически встретить Scientist.

## StageActorAnchor

Показать prerequisite field и event-driven refresh.

## City Hub

Показать два Scientist anchors.

## GirlDiscovery

Показать direct API prerequisite.

## Full route

```text
recognition
→ Scientist appears without reload
→ rival
→ girl
→ Stage5
→ lab
→ first clone
```

## Regression

Previous story actors + MODULE17 tests.

## Commit

SHA.

Then STOP. Do not start MODULE18.
