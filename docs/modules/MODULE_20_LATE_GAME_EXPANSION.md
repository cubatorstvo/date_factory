# MODULE 20 — LATE GAME EXPANSION

**Проект:** Date Factory  
**Модуль:** 20 — Late Game Expansion  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** завершить земную сюжетную линию Президентом, открыть STAGE_6 и превратить локальную clone factory в быстрый мировой incremental-рывок: глобальные множители, производственная зона, мировой охват, короткие ручные события, визуальная эскалация и автоматический переход к FINALE после исчерпания земной цели.  
**Предыдущий модуль:** MODULE 19 — Physical Clone Visualization  
**Следующий модуль:** MODULE 21 — Final Date Sequence  
**Product truth:** `docs/gdd/07_story_clones_finale.md`  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 20

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 20 состоит из двух последовательных частей.

## PART A — PRESIDENT / завершение STAGE_5

```text
STAGE_5
→ первый клон уже создан
→ Clone Incremental работает
→ автоматические свидания поднимают Experience
→ появляется Президент + её сюжетный самец
→ rival_president
→ girl_president +5
→ existing Story:
   STAGE_5 → STAGE_6
→ WORLD_EXPANSION unlocked
→ production_area physically opens
```

## PART B — WORLD EXPANSION / STAGE_6

```text
STAGE_6
→ Global Expansion Terminal
→ быстрые глобальные множители
→ Охват Земли 0..100
→ новые автоматические late dates увеличивают охват
→ 3 коротких optional FPS-события
→ мир визуально переходит:
   локальная фабрика
   → государственная программа
   → международный поток
   → планетарный масштаб
→ Охват Земли 100
→ Story.complete_world_expansion()
→ STAGE_6 → FINALE
→ FINAL_DATE unlocked
→ обнаружен внеземной романтический сигнал
→ STOP
```

MODULE 20 НЕ реализует:

- `girl_final_target`;
- финальное свидание;
- внеземных самцов;
- финальные состязания;
- финальную концовку.

Это MODULE 21.

---

# 1. PRODUCT LOGIC

GDD определяет:

```text
Президент
→ последнее земное сюжетное свидание
→ государственное признание
→ страна помогает цели героя
→ мировой масштаб
→ Земля фактически исчерпана
→ внеземная финальная цель
```

MODULE 20 должен использовать существующий Story framework.

Не вводить параллельную stage-машину.

Canonical:

```text
STAGE_5:
story girl = girl_president
story rival = rival_president
completion = GIRL_COMPLETED
next = STAGE_6

STAGE_6:
completion = EXTERNAL_MILESTONE
next = FINALE
```

---

# 2. PRESIDENT НЕ ПОЯВЛЯЕТСЯ ДО ПЕРВОГО КЛОНА

STAGE_5 начинается после Scientist +5.

Но President line должна стать физически доступна только когда:

```text
GameState.get_total_clones() >= 1
```

Причина:

```text
Scientist
→ first clone
→ incremental transition
→ President
```

Игрок не должен иметь возможность обойти клонирование и сразу пройти President.

---

# 3. StageActorAnchor — narrow prerequisite

Расширить существующий `StageActorAnchor`:

```gdscript
@export var requires_first_clone_created: bool = false
```

Default:

```text
false
```

Existing:

```text
requires_overload_recognized
```

оставить без изменений.

---

# 4. President anchor condition

Если:

```text
requires_first_clone_created == true
```

spawn only when:

```text
current_stage == story_stage
AND
GameState.get_total_clones() >= 1
```

Fail closed, если GameState недоступен.

---

# 5. Live refresh

Such anchors дополнительно слушают:

```text
GameState.clone_counts_changed
```

и вызывают:

```text
_refresh_spawn()
```

No `_process()`.

Existing story anchors с default false не меняют поведения.

---

# 6. PRESIDENT LOCATION

Президент и её rival физически размещаются:

```text
city_hub
```

около существующего:

```text
Transitions/ToProduction
```

Причинность:

```text
Президент
→ государственное разрешение
→ Production Area
```

---

# 7. Exact markers

```text
npc_story_president
npc_story_president_rival
```

Both:

```text
story_stage = STAGE_5
requires_first_clone_created = true
```

Recommended physical order:

```text
public path
→ President rival
→ President
→ locked ToProduction
```

Spacing:

```text
2.5–4 m
```

---

# 8. STORY GIRL — `girl_president`

Exact:

```text
id = &"girl_president"
display_name = "Президент"

is_story = true
has_story_stage = true
story_stage = STAGE_5

primary_trait = STATUS
secondary_trait = VARIETY_SEEKING

required_experience = 10

discovery_situation_id =
&"discovery_situation_president_expansion_gate"

appearance_profile_id =
&"appearance_female_president"

dating_pool_ids =
[
    &"date_pool_president"
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
&"dating_farewell_president"
```

Speech style:

```text
Говорит так, будто даже бытовое решение должно иметь
ответственного, публичную формулировку и официальный статус.
Ценит контроль, престиж и способность занять позицию,
но замечает, когда герой решает абсолютно всё одним инструментом.
```

---

# 9. Почему STATUS + VARIETY_SEEKING

President = последняя институциональная вершина Земли.

STATUS likes:

```text
PRESTIGE
CONTROL
DOMINANCE
```

dislikes:

```text
VULNERABILITY
SPONTANEITY
ABSURDITY
```

VARIETY_SEEKING:

```text
+1 if >=3 different characteristics among 4 evaluated actions
-1 if one characteristic used >=3 times
```

Это превращает President date в проверку:

```text
статус
+
широта освоенных инструментов
```

а не просто повтор Actress.

---

# 10. President clues — exact

```text
0:
"Перед решением сначала выясняет, кто готов отвечать за него публично."

1:
"Третий одинаковый аргумент подряд записывает как отсутствие второго инструмента."

2:
"Демонстративную скромность считает не добродетелью, а плохо оформленной позицией."
```

---

# 11. Discovery situation

ID:

```text
discovery_situation_president_expansion_gate
```

Setup:

```text
"Президент инспектирует закрытый вход в производственную зону.
На табличке написано:
«МЕЖДУНАРОДНОЕ РАСШИРЕНИЕ — НЕ УТВЕРЖДЕНО».
Её ухажёр держит папку с документами так,
будто лично изобрёл государство."
```

Before rival defeated:

```text
Сначала разберись с её текущим ухажёром.
```

---

# 12. President discovery approaches

## SUCCESS

```text
id = discovery_approach_president_outgrown_country

label =
"Спросить, кто подписывает разрешение, если задача уже перестала помещаться в стране"

no requirement
outcome = SUCCESS

result_text =
"Она посмотрела на производственную зону, потом на тебя
и попросила сформулировать вопрос ещё раз — уже для протокола."
```

## FAILURE — Capital

```text
id = discovery_approach_president_pay_international

label =
"Предложить оплатить международный масштаб сразу"

require CAPITAL 1
outcome = FAILURE

result_text =
"Президент уточнила, в какой валюте обычно покупают международный масштаб."
```

## FAILURE — Aura

```text
id = discovery_approach_president_self_declare

label =
"Объявить себя международным проектом"

require AURA 1
outcome = FAILURE

result_text =
"Она сказала, что международные проекты обычно требуют хотя бы вторую страну."
```

---

# 13. Direct GirlDiscovery prerequisite

Re-use existing:

```text
RESULT_STORY_PREREQUISITE
```

Before ordinary Story gate:

```text
girl_id == GIRL_PRESIDENT
AND stage == STAGE_5
AND total_clones < 1
→ STORY_PREREQUISITE
```

No:

- failure;
- clue mutation;
- cooldown;
- contact;
- relationship.

Feedback exact:

```text
Сначала лаборатория должна доказать, что умеет производить больше одного тебя.
```

Не создавать generic prerequisite DSL.

---

# 14. STORY RIVAL — `rival_president`

Exact:

```text
id = &"rival_president"
display_name = "Официальный самец государственного уровня"

is_story = true
has_story_stage = true
story_stage = STAGE_5

required_authority = 10
authority_reward = 5

muscle = 5
appearance = 5
capital = 7
aura = 6

preferred_competition = MONEY

allowed_competitions =
[
    MONEY,
    SIGMA,
    DANCE
]

appearance_profile_id =
&"appearance_male_president_rival"

competition_modifier_id = &""
```

---

# 15. Authority progression

Clean story:

```text
Actress   +2
Mine Boss +2
Editor    +3
Scientist +3
----------------
Authority 10
```

Therefore President rival:

```text
required_authority = 10
```

After win:

```text
Authority 10 → 15
```

No ordinary-rival grind.

---

# 16. Build-safe rival

Preferred:

```text
MONEY
```

Second thematic:

```text
SIGMA
```

Both can depend on perks.

Therefore:

```text
DANCE
```

is mandatory un-gated fallback.

Main story must never require one characteristic tree.

---

# 17. President appearances

Create:

```text
appearance_female_president
appearance_male_president_rival
```

Reuse existing female/male base.

No unique body mesh dependency.

President:

- formal silhouette;
- recognizable state-level accessory.

Rival:

- formal coat/suit;
- badge/watch/folder;
- visually “officially unnecessary”.

---

# 18. President date pool

Create:

```text
date_pool_president
```

Contains exactly:

```text
6 President-specific central events
```

Categories:

```text
2 CONVERSATION
2 SPACE_EVENT
2 GIRL_PROPOSAL
```

Do NOT include common cafe pool.

This is last Earth story date.

---

# 19. Event 1 — `date_event_president_responsibility`

Category:

```text
CONVERSATION
```

Setup:

```text
"Президент спрашивает, кто отвечает, если десять тысяч твоих копий
одновременно делают правильную вещь неправильным способом."
```

Actions:

```text
AURA 0
"Назвать себя ответственным до выяснения деталей"
[CONTROL]
```

```text
MUSCLE 0
"Сказать, что у решения должен быть один окончательный хозяин"
[DOMINANCE]
```

```text
APPEARANCE 0
"Сначала определить публичную позицию"
[PRESTIGE]
```

```text
CAPITAL 0
"Признаться, что надеялся, что никто не спросит"
[VULNERABILITY]
```

---

# 20. Event 2 — `date_event_president_budget`

Category:

```text
CONVERSATION
```

Setup:

```text
"Она просит объяснить бюджет проекта одной фразой,
пока помощник уже открыл таблицу на сорока семи страницах."
```

Actions:

```text
CAPITAL 0
"«У каждой цифры будет ответственный»"
[CONTROL, PRESTIGE]
```

```text
MUSCLE 0
"«Сначала принимаем решение, потом считаем его вес»"
[DOMINANCE]
```

```text
APPEARANCE 0
"Оформить первую страницу так, чтобы она уже выглядела утверждённой"
[PRESTIGE]
```

```text
AURA 0
"«Бюджет сам поймёт масштаб задачи»"
[ABSURDITY]
```

---

# 21. Event 3 — `date_event_president_security_table`

Category:

```text
SPACE_EVENT
```

Setup:

```text
"Служба охраны внезапно объявляет ваш стол слишком близким к вашему же столу."
```

Actions:

```text
MUSCLE 0
"Передвинуть ограничитель и назвать это новой границей"
[DOMINANCE]
```

```text
AURA 0
"Попросить охрану адаптировать протокол к фактическому столу"
[CONTROL]
```

```text
APPEARANCE 0
"Превратить ограничитель в линию для официальной фотографии"
[PRESTIGE, ORIGINALITY]
is_public = true
```

```text
CAPITAL 0
"Предложить уйти через кухню, чтобы никому не мешать"
[SIMPLICITY]
```

---

# 22. Event 4 — `date_event_president_press_camera`

Category:

```text
SPACE_EVENT
```

Setup:

```text
"Фотограф просит вас одновременно выглядеть естественно и исторически."
```

Actions:

```text
APPEARANCE 0
"Встать так, будто кадр уже войдёт в учебник"
[PRESTIGE]
```

```text
AURA 0
"Заранее определить одну официальную эмоцию"
[CONTROL]
```

```text
CAPITAL 0
"Попросить оставить только камеры с утверждённого списка"
[CONTROL, PRESTIGE]
```

```text
MUSCLE 0
"Сказать, что не любишь внимание, и спрятаться за охранником"
[VULNERABILITY]
```

---

# 23. Event 5 — `date_event_president_three_orders`

Category:

```text
GIRL_PROPOSAL
```

Setup:

```text
"Президент кладёт на стол три папки и предлагает подписать одну
просто для проверки твоего инстинкта."
```

Actions:

```text
CAPITAL 0
"Подписать бюджетную"
[CONTROL, PRESTIGE]
```

```text
MUSCLE 0
"Подписать распоряжение безопасности"
[DOMINANCE]
```

```text
APPEARANCE 0
"Подписать ту, которая лежит в центре кадра"
[PRESTIGE]
```

```text
AURA 0
"Подписать пустой лист и придумать документ позже"
[ABSURDITY]
```

---

# 24. Event 6 — `date_event_president_private_or_state`

Category:

```text
GIRL_PROPOSAL
```

Setup:

```text
"Она спрашивает, это свидание всё ещё частное дело
или уже государственный проект."
```

Actions:

```text
AURA 0
"«Частное решение с публичными последствиями»"
[CONTROL]
```

```text
APPEARANCE 0
"«Достаточно публичное для официальной фотографии»"
[PRESTIGE]
```

```text
MUSCLE 0
"«Государственное, потому что я уже решил»"
[DOMINANCE]
```

```text
CAPITAL 0
"«Лучше нигде это не фиксировать»"
[SIMPLICITY, VULNERABILITY]
```

---

# 25. President farewell

Create:

```text
dating_farewell_president
```

Actions:

```text
MUSCLE 0
"Проводить её через коридор охраны"
[DOMINANCE]
```

```text
APPEARANCE 0
"Остановиться для официальной фотографии"
[PRESTIGE]
```

```text
AURA 0
"Самому сказать протоколу, где заканчивается вечер"
[CONTROL]
```

```text
CAPITAL 0
"Заказать машину с формулировкой «по государственным причинам»"
money_cost = 20
[PRESTIGE, CONTROL]
```

At least 3 free positive farewell routes.

---

# 26. President +5 feasibility

Mandatory deterministic test.

One valid date route must produce:

```text
STATUS +4
VARIETY_SEEKING +1
date_delta = +5
```

and use:

```text
>=3 different characteristics
```

across the four evaluated actions.

No ideal-route action requires characteristic >0.

---

# 27. President bad-date feasibility

At least one deterministic combination:

```text
date_delta <= -2
```

using disliked:

```text
VULNERABILITY
SIMPLICITY
ABSURDITY
```

---

# 28. President Experience threshold

Clean story after Scientist:

```text
Experience = 5
```

President requires:

```text
Experience = 10
```

Therefore MODULE18 automatic dates must generate:

```text
+5 late Experience
```

before President line can finish.

This is intentional integration proof.

Do NOT lower President requirement to5.

---

# 29. President completion

After:

```text
rival_president defeated
girl_president relationship reaches +5
```

existing Story automatically:

```text
STAGE_5 → STAGE_6
```

Expected:

```text
Experience +1
Upgrade Points +1
WORLD_EXPANSION unlocked
production_area accessible
```

No custom stage call.

---

# 30. PART B — LateGameExpansion

Create canonical autoload:

```text
LateGameExpansion
```

Responsibilities:

- `world_reach`;
- three global upgrades;
- external multipliers for CloneIncremental;
- optional manual Stage6 events;
- world-expansion completion;
- final signal handoff;
- status/signal APIs.

No per-country or per-clone simulation.

---

# 31. Autoload order

After:

```text
CloneIncremental
```

add:

```text
LateGameExpansion
```

Tail:

```text
FirstClone
CloneIncremental
LateGameExpansion
```

MODULE19 stays local scene component.

---

# 32. Earth Reach

User-facing:

```text
Охват Земли
```

Technical:

```text
world_reach
```

Persistent integer:

```text
0..100
```

Non-spendable.

---

# 33. Why Reach is separate from Experience

Experience may be arbitrarily high before STAGE6.

Using:

```text
Experience >= X
```

would allow early waiting to skip the world expansion.

Therefore:

```text
STAGE6 starts Reach at0
```

Past Experience is not converted retroactively.

---

# 34. GameState fields

Add/reset:

```text
_world_reach: int = 0

_global_production_upgrade_level: int = 0
_global_work_upgrade_level: int = 0
_global_dating_upgrade_level: int = 0
```

Global levels:

```text
0..3
```

---

# 35. GameState APIs

```text
get_world_reach()
set_world_reach(value)
add_world_reach(amount)

get_global_production_upgrade_level()
get_global_work_upgrade_level()
get_global_dating_upgrade_level()

set_global_upgrade_level(type, level)
```

Reach clamp:

```text
0..100
```

Level clamp:

```text
0..3
```

Signals:

```text
world_reach_changed(new_value, delta)
global_upgrade_changed(upgrade_type, new_level, previous_level)
```

---

# 36. Active state

Reach acquisition / purchases active only at:

```text
STAGE_6
```

Effective global multipliers may remain active in:

```text
FINALE
```

after they were earned.

---

# 37. Reach source — EXACT

LateGameExpansion listens:

```text
CloneIncremental.late_experience_granted(amount)
```

Only while Stage6.

Exact:

```text
world_reach += amount * 2
```

Meaning:

```text
one new aggregate late girl
→ +1 Experience
→ +1 UP
→ +2 Earth Reach
```

---

# 38. Backlog dates give NO Reach

Do NOT listen to generic:

```text
automated_date_completed
```

because dates that only clear MODULE16 backlog are not new global coverage.

Only:

```text
late_experience_granted
```

advances Reach.

---

# 39. No retroactive Reach

Example:

```text
Experience = 500
```

before President completion.

Enter Stage6:

```text
Reach = 0
```

No replay.

---

# 40. Global upgrades — EXACT

Exactly three:

```text
GLOBAL_PRODUCTION
GLOBAL_WORK
GLOBAL_DATING
```

Each:

```text
level 0..3
```

Multiplier:

```text
2^level
```

Table:

```text
0 → ×1
1 → ×2
2 → ×4
3 → ×8
```

---

# 41. Global upgrade costs — EXACT

Next-level cost:

```text
1000 * 5^current_level
```

Table:

```text
0→1 = 1,000
1→2 = 5,000
2→3 = 25,000
```

At3:

```text
MAX
```

Currency:

```text
Money
```

Tracks independent.

---

# 42. Global production multiplier

MODULE18 local interval remains canonical local formula.

Effective:

```text
effective_interval =
max(
    0.5,
    local_interval / global_production_multiplier
)
```

Examples:

```text
local30 × global2 → 15s
local10 × global4 → 2.5s
local5 × global8 → 0.625s
```

Hard minimum:

```text
0.5 sec
```

---

# 43. Global work multiplier

Effective:

```text
money_per_minute =
clones_working
*
(20 + 10 * local_work_level)
*
global_work_multiplier
```

---

# 44. Global dating multiplier

Effective:

```text
dates_per_minute =
clones_dating
*
(0.50 + 0.25 * local_dating_level)
*
global_dating_multiplier
```

Reach itself is NOT multiplied separately.

---

# 45. CloneIncremental remains economy owner

Do NOT move:

- production elapsed;
- Money accumulation;
- date accumulation;
- aggregate assignment

into LateGameExpansion.

Narrowly modify CloneIncremental calculation seams to query optional:

```text
/root/LateGameExpansion
```

for:

```text
get_production_multiplier()
get_work_multiplier()
get_dating_multiplier()
```

If absent/inactive:

```text
×1
```

All MODULE18 tests outside STAGE6 preserve old formulas.

---

# 46. External modifier refresh

LateGameExpansion purchase emits:

```text
global_modifiers_changed
```

CloneIncremental gets one public seam:

```text
refresh_external_modifiers()
```

It must:

1. recalculate late rates;
2. preserve production elapsed seconds;
3. resolve immediately due clone production under new faster interval.

Do NOT reset progress.

---

# 47. Production progress example

Before:

```text
effective interval = 5s
elapsed = 4s
```

Buy global ×2:

```text
effective interval = 2.5s
```

Expected:

```text
1 clone produced
remaining elapsed = 1.5s
```

---

# 48. Global purchase result

Typed result:

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

Purchases available only:

```text
stage >= STAGE_6
```

---

# 49. Production Area

Expand existing:

```text
production_area.tscn
```

from placeholder into late-game blockout.

Approximate floor:

```text
24×18 m
```

Location ID unchanged:

```text
production_area
```

---

# 50. Production Area minimum layout

```text
CENTRAL
- Global Expansion Terminal
- Earth/world map board
- Reach display

LEFT
- clone export/logistics corridor
- transport signage

RIGHT
- state/international news wall
- upgrade presentation

FAR END
- final signal array / antenna placeholder
```

Primitives/placeholders are correct.

No actual airport/logistics simulator.

---

# 51. GlobalExpansionTerminalInteractable

Physical:

```text
GlobalExpansionTerminalInteractable
```

Prompt:

```text
[E] Глобальный терминал
```

Functional at:

```text
STAGE_6+
```

---

# 52. Global terminal display

```text
ГЛОБАЛЬНОЕ РАСШИРЕНИЕ

Охват Земли: XX / 100

Всего клонов: N
Свободно: F
Работа: W
Свидания: D

Денег/мин: M
Свиданий/мин: R
Новый клон: X.XX с
```

---

# 53. Global terminal assignment

May reuse existing:

```text
CloneIncremental.assign_one_to_work()
CloneIncremental.assign_one_to_dating()
CloneIncremental.unassign_one_from_work()
CloneIncremental.unassign_one_from_dating()
CloneIncremental.assign_all_free_to_work()
CloneIncremental.assign_all_free_to_dating()
```

No new assignment model.

---

# 54. Global terminal upgrades

Exactly:

```text
ГЛОБАЛЬНАЯ ЛИНИЯ КЛОНИРОВАНИЯ
Уровень L/3
Множитель ×X
[Улучшить — COST]

ГОСУДАРСТВЕННЫЕ КОНТРАКТЫ
Уровень L/3
Деньги ×X
[Улучшить — COST]

МЕЖДУНАРОДНАЯ СЕТЬ СВИДАНИЙ
Уровень L/3
Свидания ×X
[Улучшить — COST]
```

Technical IDs stay enum IDs.

---

# 55. Local upgrades remain valid

MODULE18 local upgrades:

```text
PRODUCTION_SPEED
WORK_EFFICIENCY
DATING_EFFICIENCY
```

stay intact.

Effective output is:

```text
local upgrade
×
global multiplier
```

Do not reset or replace local upgrades.

---

# 56. Phone Stage5 — before first clone

Keep:

```text
СТАДИЯ 5
Лаборатория

Лаборатория открыта.
Создай первого клона.
```

---

# 57. Phone Stage5 — clone exists, XP < 10

```text
СТАДИЯ 5
Президент

Покоренных сердец: X / 10

Автоматические свидания расширяют твой земной статус.
```

---

# 58. Phone Stage5 — XP10, rival alive

```text
СТАДИЯ 5
Президент

Президент инспектирует вход в производственную зону.
Сначала разберись с её официальным ухажёром.
```

---

# 59. Phone Stage5 — rival defeated

```text
СТАДИЯ 5
Президент

Следующий шаг:
Познакомиться с Президентом у производственной зоны.
```

---

# 60. Phone Stage6

```text
СТАДИЯ 6
Мировое расширение

Охват Земли: XX / 100
Клоны: N
Денег/мин: M
Свиданий/мин: R

Следующий шаг:
Расширять мировой охват.
```

---

# 61. Phone FINALE handoff

After completion:

```text
ФИНАЛ

Земная цель исчерпана.
Обнаружена романтическая цель вне Земли.

Финальная локация открыта.
```

Do not start final sequence from Phone.

---

# 62. Rare manual FPS events

Exactly three optional one-time physical interactions in `production_area`.

Each:

```text
+10 World Reach
```

They exist only to interrupt number-watching.

No quest framework.

---

# 63. Event persistence

Use existing GameState story-flag dictionary with IDs:

```text
late_event_customs_stamp
late_event_world_route
late_event_last_continent
```

No new quest object model.

---

# 64. Event 1 — Customs

Available:

```text
STAGE_6
world_reach >= 20
flag false
```

Prompt:

```text
[E] Поставить экспортную печать
```

Presentation:

```text
ДОКУМЕНТ:
ЧЕЛОВЕК — 1 ШТ.

ТЕКУЩАЯ ПАРТИЯ:
427 ОДИНАКОВЫХ ЛЮДЕЙ
```

Result:

```text
Теперь партия оформлена корректно.
```

Reward:

```text
+10 Reach
flag true
```

---

# 65. Event 2 — World Route

Available:

```text
world_reach >= 50
flag false
```

Prompt:

```text
[E] Перевести маршрут в режим «МИР»
```

Before:

```text
МАРШРУТ:
ГОРОД
```

After:

```text
МАРШРУТ:
МИР
```

Result:

```text
Локальная логистика официально закончилась.
```

Reward:

```text
+10 Reach
```

---

# 66. Event 3 — Last Continent

Available:

```text
world_reach >= 80
flag false
```

Prompt:

```text
[E] Отметить последний свободный континент
```

Result:

```text
Земля закончилась раньше списка задач.
```

Reward:

```text
+10 Reach
```

---

# 67. Manual events are optional

Player may reach:

```text
100
```

using automated late dates only.

Skipping all three cannot softlock progression.

---

# 68. WorldReachVisual

Create local:

```text
WorldReachVisual
```

Export:

```text
min_reach: int
```

Visible when:

```text
stage >= STAGE_6
AND
world_reach >= min_reach
```

Listen:

```text
world_reach_changed
stage_changed
state_reset
```

No `_process()`.

---

# 69. Production-area visual thresholds

## Reach 0

```text
Government seal
Earth map outline
Global Terminal
"НАЦИОНАЛЬНЫЙ ПРОЕКТ"
```

## Reach 25

```text
transport/export props
"ДРУГИЕ ГОРОДА"
```

## Reach 50

```text
half-lit world map
airport/train placeholder
"МЕЖДУНАРОДНЫЙ ПОТОК"
```

## Reach 75

```text
world-news board
multiple route arrows
"ПЛАНЕТАРНАЯ ОЧЕРЕДЬ"
```

## Reach 100

```text
"ЗЕМЛЯ: ОХВАТ ЗАВЕРШЁН"
final signal array active
```

---

# 70. Minimal world changes outside Production Area

## city_hub, Stage6

Near `ToProduction`:

```text
ГОСУДАРСТВЕННАЯ ПРОГРАММА КЛОНИРОВАНИЯ
```

## laboratory, Stage6

Mass corridor wording evolves toward:

```text
ДРУГИЕ ГОРОДА
```

and later:

```text
ДРУГИЕ СТРАНЫ
```

No actual destination nodes.

---

# 71. MODULE19 cosmetic carryover — REQUIRED

Current MODULE19 controller already derives:

```text
external_work
external_dating
external_free
```

but production label shows only:

```text
ВНЕШНИЙ ПОТОК: N
```

Update it to:

```text
ВНЕШНИЕ ПЛОЩАДКИ

Работа: X
Свидания: Y
Ожидают: Z
```

Example:

```text
Работа: 57
Свидания: 70
Ожидают: 8
```

This is presentation-only.

No gameplay/state change.

---

# 72. No country database

Do NOT create:

```text
CountryDefinition
CityDefinition
AirportDefinition
RegionalDemand
WorldRouteGraph
```

World scale is represented by:

```text
Reach
global multipliers
visual infrastructure
```

---

# 73. No logistics simulator

No:

- clone shipping inventory;
- route travel times;
- plane entities;
- country capacity;
- regional assignment.

---

# 74. World completion

When:

```text
world_reach >= 100
```

LateGameExpansion calls exactly:

```gdscript
Story.complete_world_expansion()
```

No direct stage mutation.

Existing Story then:

```text
sets world expansion flag
STAGE_6 → FINALE
FINAL_DATE unlocked
```

---

# 75. Completion idempotency

If Story world-expansion flag already complete:

do nothing.

LateGameExpansion emits once:

```text
world_expansion_completed()
final_target_detected()
```

---

# 76. Final signal presentation

On successful completion:

```text
СИСТЕМА:

ЗЕМНЫЕ ЦЕЛИ — ИСЧЕРПАНЫ

ОБНАРУЖЕН НОВЫЙ РОМАНТИЧЕСКИЙ СИГНАЛ
ИСТОЧНИК: ВНЕ ЗЕМЛИ
```

---

# 77. Final Location preparation

`final_location` becomes available through existing:

```text
StoryFeature.FINAL_DATE
```

MODULE20 may add only:

```text
FinalSignalBeacon
antenna/portal placeholder
Label3D
```

Text:

```text
ИСТОЧНИК СИГНАЛА:
ЗА ПРЕДЕЛАМИ ЗЕМЛИ

РОМАНТИЧЕСКИЙ СТАТУС:
НЕ УСТАНОВЛЕН
```

---

# 78. DO NOT create final target

Still absent after MODULE20:

```text
girl_final_target
```

Also absent:

```text
alien rivals
final dating pool
final competitions
ending
```

MODULE21 owns all of that.

---

# 79. Global multipliers remain in FINALE

After:

```text
STAGE_6 → FINALE
```

do not reset:

- clone counts;
- local upgrades;
- global upgrades;
- rates;
- Reach.

Clone economy may continue running.

---

# 80. Reach stops at100

Further late Experience in FINALE:

```text
Reach stays100
```

No repeated Story completion.

---

# 81. No GameDay / offline changes

MODULE20 does not add:

- Reach per GameDay;
- clone production on End Day;
- offline catch-up.

MODULE18 real-time semantics remain.

---

# 82. No minimum Stage6 duration

Do NOT require:

- minimum GameDays;
- minimum real minutes;
- arbitrary clone count threshold.

If player intentionally built an overpowered factory before President:

```text
Stage6 may finish very quickly
```

That is desired reward.

---

# 83. Content additions

MODULE20 production:

Girls:

```text
girl_president
```

Rivals:

```text
rival_president
```

Appearances:

```text
appearance_female_president
appearance_male_president_rival
```

Discovery:

```text
discovery_situation_president_expansion_gate
```

Pools:

```text
date_pool_president
```

Events:

```text
6
```

Farewell:

```text
dating_farewell_president
```

No `girl_final_target`.

---

# 84. Expected content totals

Before:

```text
girls = 12
rivals = 11
discovery situations = 12
dating events >= 28
```

After:

```text
girls = 13
rivals = 12
discovery situations = 13
dating events >= 34
```

---

# 85. Content validation

President exact:

```text
stage5
STATUS
VARIETY_SEEKING
XP10
venue cafe
6-event dedicated pool
dedicated farewell
```

Rival exact:

```text
stage5
Authority10
reward5
preferred MONEY
allowed MONEY/SIGMA/DANCE
```

---

# 86. Tests — President hidden

```text
STAGE5
total_clones = 0
```

Expected:

```text
President absent
President rival absent
```

---

# 87. Tests — live first-clone spawn

`city_hub` loaded.

Commit first clone:

```text
0 →1
```

Expected without reload:

```text
President + rival appear
```

---

# 88. Tests — direct discovery prerequisite

```text
STAGE5
total0
President rival manually defeated
XP10
```

Direct:

```text
GirlDiscovery.begin_attempt(girl_president)
```

Expected:

```text
STORY_PREREQUISITE
```

No cooldown/contact/failure clue.

---

# 89. Tests — President XP

```text
total>=1
rival defeated
Experience9
```

Normal Experience lock.

At10:

available.

---

# 90. Tests — President Authority

Clean:

```text
Authority10
```

Rival challenge works.

At9:

player initiation refused.

---

# 91. Tests — President build safety

Without MONEY/SIGMA unlock perks:

```text
DANCE selectable
```

No story softlock.

---

# 92. Tests — rival win

Clean:

```text
Authority10 →15
```

Rival defeated.

Stage remains5.

---

# 93. Tests — President +5

Expected:

```text
President conquered
Experience +1
UP +1
STAGE5 → STAGE6
WORLD_EXPANSION true
production_area accessible
```

Exactly once.

---

# 94. Tests — perfect / bad President dates

Perfect:

```text
+5
>=3 distinct characteristics
no required stat >0
```

Bad:

```text
<= -2
```

---

# 95. Tests — LateGame inactive Stage5

Global multiplier getters:

```text
×1
```

Purchases:

```text
LOCKED
```

Reach does not advance.

---

# 96. Tests — Stage6 initial

Immediately after President:

```text
Reach0
global levels0/0/0
multipliers1/1/1
```

Past Experience ignored.

---

# 97. Tests — Reach

At Stage6:

```text
late_experience_granted(1)
→ +2 Reach
```

```text
late_experience_granted(5)
→ +10
```

Clamp100.

---

# 98. Tests — no Reach from backlog

Auto date that only fulfills old DatingOverload demand:

```text
Reach unchanged
```

---

# 99. Tests — no Reach from manual hero date

Manual DatingCore:

```text
no direct Reach gain
```

---

# 100. Tests — global multiplier table

Each:

```text
level0 ×1
level1 ×2
level2 ×4
level3 ×8
```

---

# 101. Tests — global costs

```text
1000
5000
25000
MAX
```

independent per track.

---

# 102. Tests — effective production

```text
local10 + global×1 →10
local10 + global×2 →5
local10 + global×4 →2.5
local10 + global×8 →1.25
```

```text
local5 + global×8 →0.625
```

Never <0.5.

---

# 103. Tests — effective work

Example:

```text
10 workers
local work level5
local =700/min
global work level2 =×4
effective =2800/min
```

---

# 104. Tests — effective dating

Example:

```text
10 dating
local dating level2
local =10/min
global dating level3 =×8
effective =80/min
```

---

# 105. Tests — immediate multiplier refresh

Buy global Work:

```text
GameState.money_per_minute changes immediately
```

Dating analogous.

---

# 106. Tests — elapsed production preserved

Speed upgrade reducing interval below elapsed:

- due clones resolved;
- correct remainder kept.

No reset to0.

---

# 107. Tests — Global Terminal

At Stage6 shows:

- Reach;
- aggregate counts;
- effective rates;
- effective interval;
- three global upgrade tracks;
- assignment controls.

---

# 108. Tests — Production Area access

Stage5:

```text
LOCKED_STORY
```

Stage6:

```text
available
```

No custom location flag.

---

# 109. Tests — manual event thresholds

```text
Customs: 19 no /20 yes
World Route: 49 no /50 yes
Last Continent: 79 no /80 yes
```

---

# 110. Tests — event exact-once

First use:

```text
+10 Reach
flag true
```

Second:

```text
+0
```

---

# 111. Tests — optional events

Disable/ignore all3.

Automated dating alone still reaches100.

---

# 112. Tests — visuals

Exact threshold groups:

```text
0
25
50
75
100
```

No gameplay mutation.

---

# 113. Tests — MODULE19 external label

State:

```text
work60
dating80
free10
```

Local caps:

```text
work3
dating10
free2
```

External label exact values:

```text
Работа: 57
Свидания: 70
Ожидают: 8
```

---

# 114. Tests — completion

```text
Stage6
Reach98
late XP +1
```

Expected:

```text
Reach100
Story world-expansion flag true
STAGE6 → FINALE
FINAL_DATE true
final_target_detected once
```

---

# 115. Tests — completion idempotent

Further late XP:

- no second Story completion;
- no second final signal;
- Reach remains100.

---

# 116. Tests — final target absent

ContentDB still has no production:

```text
girl_final_target
```

No validation failure.

---

# 117. Tests — final location

Before FINALE:

```text
locked
```

After:

```text
available
```

Only signal/beacon presentation.

---

# 118. Tests — economy persists Finale

Global clone multipliers/rates continue after Stage transition.

---

# 119. Tests — no domain explosion

No:

```text
countries
regional demand
airports as gameplay
clone shipping inventory
individual clone state
```

---

# 120. Full F5 route extension

Required:

```text
PROLOGUE
→ Actress
→ Mine Boss
→ Editor
→ Media
→ Overload
→ Scientist
→ First Clone
→ Clone Incremental
→ late Experience reaches10

→ President appears near ToProduction
→ rival President
→ President +5
→ STAGE6
→ Production Area

→ Global Terminal
→ allocate clones
→ buy global upgrades
→ automated late dates increase Reach
→ optional manual world events
→ visual world expansion
→ Reach100

→ Story.complete_world_expansion()
→ FINALE
→ final location opens
→ extraterrestrial signal visible

STOP
```

No debug required for acceptance path.

---

# 121. Pacing

This stage must be fast.

World Reach without optional events:

```text
50 new aggregate late girls
```

because:

```text
2 Reach / late Experience
```

But by now:

- dating clones already exist;
- global dating multiplier can reach ×8;
- optional events can provide +30 Reach.

No long idle requirement.

---

# 122. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
docs/content/MANUAL_CONTENT.md
```

Document exact current balance:

President:

```text
STATUS + VARIETY_SEEKING
XP10
rival Authority10
reward5
MONEY/SIGMA/DANCE
```

World:

```text
Reach0..100
+2 per late XP

global levels0..3
×1/×2/×4/×8
costs1000/5000/25000
```

---

# 123. Technical decisions

Document:

```text
World Reach begins at zero on STAGE6 and is not derived from total historical Experience.
```

```text
LateGameExpansion supplies global multipliers only.
CloneIncremental remains owner of production and passive Money/date simulation.
```

```text
Stage6 world scale is represented by one Reach meter, multiplier upgrades and presentation.
There is no country/logistics simulation.
```

---

# 124. Suggested project area

```text
game/late_game/
├── late_game_expansion.gd
├── late_game_types.gd
├── late_game_status.gd
├── global_upgrade_purchase_result.gd
├── global_expansion_terminal_interactable.gd
├── global_expansion_terminal_ui.gd
├── global_expansion_event_interactable.gd
├── world_reach_visual.gd
└── test/
```

Keep compact.

---

# 125. What MODULE20 DOES NOT implement

Do NOT implement:

- `girl_final_target`;
- alien character definition;
- alien rival definitions;
- final dating pool;
- final date;
- final competitions;
- ending;
- credits;
- country database;
- city database;
- routing graph;
- transport simulation;
- regional demand;
- prestige/rebirth;
- additional currencies;
- individual clone tracking;
- offline progress;
- save/load.

---

# 126. Definition of Done

MODULE20 complete only if:

- [ ] `girl_president` exists;
- [ ] President STATUS + VARIETY_SEEKING exact;
- [ ] President XP10;
- [ ] President discovery/clues exact;
- [ ] 6-event dedicated President pool;
- [ ] dedicated President farewell;
- [ ] +5 route uses >=3 characteristics;
- [ ] bad route exists;
- [ ] `rival_president` exists;
- [ ] Authority10;
- [ ] reward5;
- [ ] preferred MONEY;
- [ ] allowed MONEY/SIGMA/DANCE;
- [ ] DANCE makes story perk-safe;
- [ ] President pair at ToProduction;
- [ ] hidden until first clone;
- [ ] live spawn on first clone;
- [ ] direct GirlDiscovery cannot bypass first-clone prerequisite;
- [ ] clean story gets President via +5 automated XP;
- [ ] President +5 advances only via existing Story;
- [ ] WORLD_EXPANSION unlocks Production Area;
- [ ] `LateGameExpansion` autoload exists;
- [ ] Reach persistent0..100;
- [ ] no retroactive Reach;
- [ ] +2 Reach per `late_experience_granted`;
- [ ] backlog dates give no Reach;
- [ ] exactly3 global upgrade tracks;
- [ ] levels0..3;
- [ ] multipliers exact1/2/4/8;
- [ ] costs exact1000/5000/25000;
- [ ] effective production has0.5s floor;
- [ ] global Work/Dating modify actual GameState late rates;
- [ ] CloneIncremental remains economy owner;
- [ ] production elapsed preserved on global speed changes;
- [ ] Production Area expanded/readable;
- [ ] physical Global Terminal exists;
- [ ] Global Terminal assignment works;
- [ ] Global Terminal shows effective numbers;
- [ ] three optional FPS events exist;
- [ ] each +10 exact once;
- [ ] events are not required;
- [ ] visual thresholds0/25/50/75/100;
- [ ] small city/lab Stage6 visual changes exist;
- [ ] MODULE19 external label shows Work/Dating/Free breakdown;
- [ ] Reach100 calls `Story.complete_world_expansion`;
- [ ] Story reaches FINALE;
- [ ] FINAL_DATE unlocks;
- [ ] extraterrestrial signal presentation exists;
- [ ] `girl_final_target` remains absent;
- [ ] no MODULE21 final gameplay;
- [ ] global economy continues in FINALE;
- [ ] clean F5 reaches extraterrestrial signal;
- [ ] MODULE02–19 regressions PASS;
- [ ] MODULE21 not implemented ahead.

---

# 127. Recommended Cursor order

```text
1. Audit StageActorAnchor / GirlDiscovery / Story Stage5-6 / ToProduction / CloneIncremental.
2. Add President content.
3. Add first-clone President anchor prerequisite + direct discovery guard.
4. Verify President story path → Stage6 → Production Area.
5. Add GameState Reach/global levels.
6. Implement LateGameExpansion headless core.
7. Add narrow CloneIncremental global-multiplier seam.
8. Build Global Terminal in Production Area.
9. Add three optional FPS Reach events.
10. Add Reach visual thresholds and minimal city/lab changes.
11. Fix MODULE19 external Work/Dating/Free breakdown.
12. Reach100 → Story.complete_world_expansion → Finale signal.
13. Add only final-location signal beacon.
14. Full F5 + regressions/docs.
```

---

# 128. Cursor final report

## President

Confirm:

```text
STATUS + VARIETY_SEEKING
XP10
rival Auth10 / reward5
MONEY / SIGMA / DANCE
```

Confirm first-clone prerequisite and Stage5→6.

## Earth Reach

Confirm:

```text
0..100
+2 per late XP
no retroactive conversion
no backlog contribution
```

## Global upgrades

Confirm:

```text
3 tracks
0..3
×1/×2/×4/×8
1000/5000/25000
```

## CloneIncremental integration

Show effective production/work/dating and prove MODULE18 remains owner.

## Production Area

Show:

- Global Terminal;
- three optional events;
- 0/25/50/75/100 visuals.

## MODULE19 carryover

Confirm external label now shows:

```text
Работа / Свидания / Ожидают
```

## Completion

Confirm:

```text
Reach100
→ Story.complete_world_expansion()
→ FINALE
→ FINAL_DATE
→ extraterrestrial signal
```

## Boundary

Confirm:

```text
no girl_final_target
no final date
no alien rival
no ending
```

## F5

Clean full route.

## Regressions

All previous suites.

## Commit

SHA.

Then STOP. Do not begin MODULE21.
