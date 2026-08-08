# MODULE 21 — FINAL DATE SEQUENCE

**Проект:** Date Factory  
**Модуль:** 21 — Final Date Sequence  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать единственный основной финал Date Factory: конкретную внеземную девушку `girl_final_target`, отдельное длинное поставленное свидание в `final_location`, использование характеристик, две знакомые мини-игры против внеземных самцов, физическое перемещение между частями сцены, полный retry при поражении и единственную успешную концовку.  
**Предыдущий модуль:** MODULE 20 — Late Game Expansion  
**Product truth:** `docs/gdd/07_story_clones_finale.md`, разделы 43–44  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 21

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 21 начинается после:

```text
GameState.stage == FINALE
StoryFeature.FINAL_DATE == true
World.final_location unlocked
world_reach == 100
```

MODULE 21 реализует:

```text
final_location
→ ответить на внеземной сигнал
→ появляется конкретная «Последняя»
→ начинается одно длинное свидание
→ разговор / движение / событие
→ внеземной самец #1 → DANCE
→ продолжение свидания
→ внеземной самец #2 → SLAP
→ финальные разговорные проверки
→ итог свидания

SUCCESS:
girl_final_target relationship = +5
girl_final_target conquered = true
+1 Experience / +1 Upgrade Point exactly once
→ единственная основная концовка
→ функциональный финальный экран
→ игра остаётся доступна после финала

FAIL:
комедийная развязка
→ никакой bad ending
→ никакой permanent penalty
→ бесконечные попытки
→ повторяется ВСЁ финальное свидание целиком
```

После MODULE 21 основной игровой путь должен быть полностью проходим от `F5` до финальной концовки.

---

# 1. GDD — обязательные свойства финала

Финальное свидание:

- отдельная поставленная сцена;
- заметно длиннее обычного свидания;
- полноценные диалоги;
- несколько событий;
- использование освоенных характеристик;
- мини-игры;
- вмешательство внеземных самцов;
- физическое перемещение между частями постановки;
- одна развивающаяся сцена, а не набор случайных обычных dating events.

Проигрыш:

- возможен;
- не создаёт плохую концовку;
- не блокирует игру;
- retry бесконечный;
- повторяется финальное свидание целиком.

---

# 2. Final target identity

Reserved exact ID:

```text
girl_final_target
```

Working display name:

```text
Последняя
```

Это остаётся рабочим именем из GDD.

Не придумывать в MODULE21 сложный lore-name.

Позже art/copy polish может переименовать display name без изменения ID.

---

# 3. Final target is concrete

`girl_final_target` должна существовать как реальный production `GirlDefinition`.

Она НЕ является:

- UI algorithm;
- abstract signal;
- progress bar;
- anonymous reward.

Игрок физически видит и проходит свидание с конкретным персонажем.

---

# 4. `girl_final_target` — exact definition

```text
id = &"girl_final_target"
display_name = "Последняя"

is_story = true
has_story_stage = true
story_stage = FINALE

primary_trait = STRANGE
secondary_trait = VARIETY_SEEKING

required_experience = 0

discovery_situation_id = &""

appearance_profile_id =
&"appearance_female_final_target"

dating_pool_ids = []

speech_style_note =
"Говорит спокойно и буквально. Земной масштаб героя воспринимает не как величие, а как странно длинное введение к одному личному разговору. Её интересует не количество покорённых целей, а то, способен ли герой остаться конкретным человеком, когда больше нечего масштабировать."

clue_notes = []
```

---

# 5. No normal dating binding

For `girl_final_target`:

```text
default_date_location_id = &""
dating_greeting_ids = []
dating_farewell_id = &""
dating_pool_ids = []
```

Она НЕ должна появляться:

- в обычном DateVenue;
- в cafe picker;
- в ordinary DatingCore planner;
- в incoming Media offers;
- в GirlDiscovery world flow.

MODULE21 owns her sequence.

---

# 6. ContentDB validation exception

Do NOT weaken validation globally.

Existing production binding validation already distinguishes girls with dating pools.

Ensure:

```text
girl_final_target with empty normal dating pool
```

is valid specifically because she is final-sequence-only.

If current validator needs a narrow condition:

```text
girl.id == StoryIds.GIRL_FINAL_TARGET
AND story_stage == FINALE
```

may skip normal date-binding requirements.

Do not add generic arbitrary `skip_validation`.

---

# 7. Final target appearance

Create:

```text
appearance_female_final_target
```

Reuse female base body.

Prototype visual intent:

- visibly non-Earth silhouette without requiring a new body mesh;
- unusual skin/material tint;
- simple crown / antenna / halo / head accessory from primitives if needed;
- subtle emissive accent;
- recognizably female-base humanoid;
- not horror/gore.

No procedural alien generator.

---

# 8. Final target tone

She should NOT be:

- impressed just because clones number in thousands;
- a goddess that speaks only in prophecy;
- another STATUS bureaucrat;
- a meme machine.

Comedy:

> герой автоматизировал планету, чтобы в конце снова оказаться одним мужчиной на одном свидании.

---

# 9. Final rivals

Create exactly two final rival definitions:

```text
rival_final_ceremonial
rival_final_gravity
```

They exist in ContentDB for:

- stats;
- display;
- appearances;
- minigame configuration.

They are NOT normal world RivalActors.

---

# 10. Rival #1 — ceremonial

```text
id = &"rival_final_ceremonial"
display_name = "Церемониальный внеземной самец"

is_story = false
has_story_stage = false

required_authority = 0
authority_reward = 0

muscle = 3
appearance = 5
capital = 3
aura = 4

preferred_competition = DANCE
allowed_competitions = [DANCE]

appearance_profile_id =
&"appearance_male_final_ceremonial"

competition_modifier_id = &""
```

---

# 11. Rival #2 — gravity

```text
id = &"rival_final_gravity"
display_name = "Самец гравитационного ранга"

is_story = false
has_story_stage = false

required_authority = 0
authority_reward = 0

muscle = 5
appearance = 3
capital = 4
aura = 4

preferred_competition = SLAP
allowed_competitions = [SLAP]

appearance_profile_id =
&"appearance_male_final_gravity"

competition_modifier_id = &""
```

---

# 12. Rival appearances

Create:

```text
appearance_male_final_ceremonial
appearance_male_final_gravity
```

Reuse male base.

Ceremonial:

- tall/formal;
- bright strange head/shoulder ornament;
- reads as ritual/status rival.

Gravity:

- heavier silhouette/proportions;
- dark simple armor-like blocks/accessories;
- reads as physical rival.

No new alien body system.

---

# 13. CRITICAL — final rivals are exhibition-only

Final rivals must NOT mutate normal Rival persistence.

Their minigames:

- do NOT call `GameState.mark_rival_defeated`;
- do NOT grant Authority;
- do NOT lose Authority on player loss;
- do NOT trigger Heroic Defeat;
- do NOT trigger normal ordinary-rival perks that mutate world outcome;
- do NOT disappear permanently across attempts.

Every retry recreates them.

---

# 14. Reuse minigames, not RivalEncounter consequences

Reuse existing:

```text
DanceMinigame
SlapMinigame
RivalCompetitionRequest
RivalCompetitionResult
perk snapshot behavior where useful
```

But results return to:

```text
FinalDateController
```

not normal:

```text
RivalEncounters._resolve_competition_result()
```

---

# 15. Technical seam — exhibition competition

Cursor must audit actual `RivalCompetitionRunner`.

Preferred narrow solution:

```text
run_exhibition_competition(
    request,
    rival_definition,
    result_callback
)
```

or equivalent.

Requirements:

- existing production normal runner behavior unchanged;
- same Slap/Dance minigames;
- same player input/control modes;
- result callback receives PLAYER_WIN/PLAYER_LOSS;
- no normal RivalEncounters submit;
- no Authority/persistence.

Do NOT copy entire minigame implementations.

---

# 16. No MONEY/SIGMA final requirement

Mandatory final rival minigames are:

```text
DANCE
SLAP
```

Both are base-unlocked systems.

Final cannot be softlocked by:

```text
PAYABLE_INTENT
PRESENCE_REGISTERED
```

Optional copy/perk effects inside minigames may still function.

---

# 17. FinalLocationController

Create scene-local:

```text
FinalDateController
```

inside:

```text
final_location.tscn
```

Do NOT create an autoload unless actual scene architecture makes it strictly necessary.

Preferred:

```text
attempt state is transient and local to final_location
```

Leaving the location aborts the attempt.

---

# 18. Persistent final-completion source

Do NOT add:

```text
final_date_completed bool
```

Canonical persistent completion fact:

```text
GameState.is_girl_conquered(&"girl_final_target")
```

This is enough to know the game was completed.

---

# 19. Final attempt transient state

Controller owns only current attempt:

```text
attempt_active: bool
phase
connection_score: int
used_characteristics: Dictionary/Set
completed_characteristic_events: int
rival_1_won: bool
rival_2_won: bool
```

No save mid-date.

---

# 20. Leaving final_location

If attempt active and player travels out / scene unloads:

```text
attempt is discarded
```

Persistent game state unchanged.

Returning:

```text
start from beginning
```

This satisfies “repeat whole date”.

---

# 21. Start interactable

Use existing marker:

```text
story_point_final_sequence
```

Add physical:

```text
FinalSignalInteractable
```

Prompt before successful ending:

```text
[E] Ответить на внеземной сигнал
```

Availability:

```text
GameState.stage == FINALE
AND
StoryFeature.FINAL_DATE unlocked
AND
not final attempt active
AND
not girl_final_target conquered
```

---

# 22. After successful final

Prompt becomes:

```text
Финал завершён
```

Do not automatically replay.

Optional interaction may only show final summary.

No second Experience reward.

---

# 23. Starting transaction

On E:

1. validate FINALE;
2. validate final target definition;
3. ensure no active normal DatingCore date;
4. ensure no RivalCompetitionRunner busy;
5. clear final transient state;
6. mark target discovered/contact if APIs allow;
7. spawn target presentation actor;
8. begin INTRO.

No Money/Authority/XP mutation.

---

# 24. Final target presentation actor

Use:

```text
CharacterActor
```

from:

```text
appearance_female_final_target
```

Do NOT use `GirlActor` because:

- no proximity discovery;
- no ordinary retry cooldown;
- no normal contact attempt UI.

FinalDateController owns interaction.

---

# 25. final_location physical structure

Expand current 12×12 placeholder into one connected location with three readable areas.

No new LocationDefinition.

Recommended approximate footprint:

```text
30m × 14m
```

---

# 26. Three final zones

Exact logical zones:

```text
ZONE_A_SIGNAL_CHAMBER
ZONE_B_ORBIT_WALK
ZONE_C_FINAL_TABLE
```

All remain in:

```text
final_location
```

---

# 27. Zone A — Signal Chamber

Contains:

- existing beacon;
- target spawn;
- intro interaction;
- first conversation event;
- gate/path toward Zone B.

Visual theme:

```text
signal / arrival / translation
```

---

# 28. Zone B — Orbit Walk

Contains:

- long corridor/platform/bridge;
- visible distant planet/star placeholder;
- ceremonial rival marker;
- second conversation checkpoint;
- path toward final table.

Visual theme:

```text
walking date interrupted by ritual challenger
```

---

# 29. Zone C — Final Table

Contains:

- simple table / two positions;
- gravity rival entrance marker;
- two final conversation events;
- ending position.

Visual theme:

```text
absurdly ordinary date table at impossible scale
```

---

# 30. Phase gates

Use simple scene-local visual/collision gates.

They unlock only by current attempt phase.

They do NOT persist.

Retry closes/restores them.

No StoryFeature gates required.

---

# 31. Player movement

Between dialogue/minigame pieces:

player returns to:

```text
GAMEPLAY
```

and physically walks to next checkpoint.

At dialogue choice:

```text
MODAL_UI
```

At minigame:

```text
MINIGAME
```

This is required so final date feels like one staged FPS scene.

---

# 32. Final phase order — EXACT

```text
INTRO
EVENT_1_SIGNAL_REASON
RIVAL_1_DANCE
EVENT_2_ORIGINAL
MOVE_TO_FINAL_TABLE
RIVAL_2_SLAP
EVENT_3_EARTH_GIFT
EVENT_4_NO_NEXT_TARGET
FINAL_ASSESSMENT
SUCCESS
or
FAILURE
```

Do not randomize order.

---

# 33. Characteristic event rule

There are exactly:

```text
4 evaluated final conversation events
```

Each offers:

```text
MUSCLE option
APPEARANCE option
CAPITAL option
AURA option
NEUTRAL option
```

Characteristic options require:

```text
characteristic level >= 2
```

Neutral requires:

```text
0
```

---

# 34. Scoring

Selecting an available characteristic option:

```text
connection_score += 1
record characteristic as used
```

Neutral option:

```text
+0
```

No negative score.

No hidden RNG.

---

# 35. Variety bonus

At final assessment:

```text
if distinct successfully used characteristics >= 3:
    connection_score += 1
```

One-time.

---

# 36. Final dialogue pass threshold

Required:

```text
connection_score >= 3
```

and:

```text
rival_1_won == true
rival_2_won == true
```

Then SUCCESS.

---

# 37. Why this is build-safe

A specialized player with only one characteristic at level2 can use that characteristic in all four events:

```text
score = 4
```

and pass.

A diversified player gets an extra variety point and more distinct responses.

Therefore:

- characteristics matter;
- build changes route/copy;
- no mandatory balanced build;
- no four endings.

---

# 38. Disabled actions

If characteristic <2:

button shown disabled:

```text
Мышца 2
Внешность 2
Капитал 2
Аура 2
```

Player can always choose Neutral.

If player reaches assessment with <3 score:

attempt fails and can be replayed after returning to normal game/progression.

Late Experience provides Upgrade Points, so no permanent softlock.

---

# 39. Event 1 — `final_event_signal_reason`

Prompt:

```text
Последняя:
«Зачем было покрывать целую планету, если ты хотел поговорить со мной?»
```

Options:

### MUSCLE 2

```text
"Одного тела оказалось физически недостаточно."
```

Result:

```text
«Понятно. Ты решил проблему буквально.»
```

### APPEARANCE 2

```text
"Цель должна была выглядеть завершённой."
```

Result:

```text
«У вас завершённость действительно очень заметная.»
```

### CAPITAL 2

```text
"Локальная модель перестала масштабироваться."
```

Result:

```text
«Это самый деловой ответ на романтический вопрос, который я слышала.»
```

### AURA 2

```text
"Земля закончилась раньше намерения."
```

Result:

```text
«Это уже звучит как причина.»
```

### NEUTRAL

```text
"Долго объяснять."
```

Result:

```text
«Я вижу по инфраструктуре.»
```

---

# 40. Rival #1 staging

After Event1:

Zone B opens.

Player walks onto Orbit Walk.

At checkpoint:

```text
Церемониальный внеземной самец:
«По местному протоколу право продолжить прогулку подтверждается синхронным движением.»
```

Then:

```text
DANCE
```

---

# 41. Rival #1 request

FinalDateController builds request:

```text
rival_id = rival_final_ceremonial
competition_type = DANCE
player_level = current APPEARANCE
rival_level = 5
initiator = RIVAL
context = final/exhibition semantic
```

No Authority gate.

---

# 42. Rival #1 result

Win:

```text
rival_1_won = true
```

Rival presentation leaves/fades.

Continue Event2.

Loss:

```text
entire final attempt fails immediately
```

No Authority loss.

---

# 43. Event 2 — `final_event_original`

Prompt:

```text
Последняя:
«Как вы теперь определяете, кто из вас оригинал?»
```

Options:

### MUSCLE 2

```text
"Оригинал первым доказал, что одного тела мало."
```

### APPEARANCE 2

```text
"По тому, кто выглядит так, будто остальные — его копии."
```

### CAPITAL 2

```text
"По самой ранней записи в производственном учёте."
```

### AURA 2

```text
"Оригинал — тот, кому не нужно спрашивать."
```

### NEUTRAL

```text
"Сейчас уже в основном по привычке."
```

Each characteristic option gives +1.

Neutral +0.

---

# 44. Move to final table

After Event2:

open path:

```text
ZONE_B → ZONE_C
```

Player physically walks to final table.

Target moves/presentation teleports subtly to target table marker.

No pathfinding required.

Use:

```text
Tween
or
hide/show at next marker
```

---

# 45. Rival #2 staging

Before player reaches seated final checkpoint:

```text
Самец гравитационного ранга:
«Я оспариваю локальное право занимать эту сторону стола.»
```

Then:

```text
SLAP
```

No new mechanic.

---

# 46. Rival #2 request

```text
rival_id = rival_final_gravity
competition_type = SLAP
player_level = current MUSCLE
rival_level = 5
initiator = RIVAL
final/exhibition context
```

---

# 47. Rival #2 result

Win:

```text
rival_2_won = true
```

Rival presentation exits.

Continue final table.

Loss:

```text
entire attempt fails
```

No Authority penalty.

---

# 48. Event 3 — `final_event_earth_gift`

Prompt:

```text
Последняя:
«Что Земля отправила с тобой как подтверждение серьёзности намерений?»
```

Options:

### MUSCLE 2

```text
"Официальное подтверждение, что тел теперь достаточно."
```

### APPEARANCE 2

```text
"Обложку, где я наполовину не поместился в кадр."
```

### CAPITAL 2

```text
"Смету международного расширения."
```

### AURA 2

```text
"Право первым ничего не говорить."
```

### NEUTRAL

```text
"Таможенную печать."
```

Characteristic +1.

Neutral0.

---

# 49. Event 4 — `final_event_no_next_target`

Prompt:

```text
Последняя:
«И что ты будешь делать, если после меня действительно никого не останется?»
```

Options:

### MUSCLE 2

```text
"Наконец перестану увеличивать количество тела."
```

### APPEARANCE 2

```text
"Сделаю одну фотографию без следующего этапа."
```

### CAPITAL 2

```text
"Закрою проект без бюджета на расширение."
```

### AURA 2

```text
"Тогда впервые ничего не нужно будет доказывать."
```

### NEUTRAL

```text
"Проверю ещё раз список."
```

Characteristic +1.

Neutral0.

---

# 50. Final assessment

After Event4:

```text
score = 0..4
+ optional variety bonus 1
```

If:

```text
score >=3
AND rival1 won
AND rival2 won
```

SUCCESS.

Otherwise FAILURE.

No random roll.

---

# 51. Failure — rival loss copy

Exact functional modal:

```text
СВИДАНИЕ ПРЕРВАНО

Последняя:
«У нас принято завершать встречу после первого локального свержения.»

Попытка не засчитана.
```

Buttons:

```text
[Повторить свидание целиком]
[Вернуться]
```

---

# 52. Failure — connection copy

If rivals won but score <3:

```text
СВИДАНИЕ НЕ СЛОЖИЛОСЬ

Последняя:
«Ты очень хорошо масштабируешься.
Я пока не поняла, с кем именно разговариваю.»

Попытка не засчитана.
```

Same buttons.

---

# 53. Retry rules

`Повторить свидание целиком`:

- clear score;
- clear used characteristics;
- clear both rival wins;
- restore rival visuals;
- restore target to start;
- close Zone B/C gates;
- return player to `final_attempt_start`;
- begin INTRO again.

No phase may remain completed.

---

# 54. Return rules

`Вернуться`:

- abort transient attempt;
- return Player GAMEPLAY;
- final signal interactable becomes usable again;
- player may leave to city.

No cooldown.

No GameDay change.

---

# 55. Infinite attempts

No attempt counter needed.

Do NOT store:

```text
final_attempts
```

unless only for debug logging.

No increasing difficulty/cost.

---

# 56. Failure permanent mutations — ZERO

On failed attempt do NOT change:

```text
Money
Authority
Experience
Upgrade Points
relationship girl_final_target
conquered set
rival defeated set
Earth Reach
clone counts
```

---

# 57. No final date body-cap issue

MODULE16 hero daily cap must NOT prevent final sequence.

This is a unique story scene after planetary completion.

Do not route start through:

```text
Relationships.can_start_date()
```

or normal DateVenue capacity.

---

# 58. Success persistent effects

On first successful final:

```text
girl_final_target relationship → +5
girl_final_target conquered → true
Experience +1
Upgrade Points +1
```

Exactly once.

---

# 59. Use existing relationship invariant

Do NOT independently invent a second XP rule.

Implementation may use either:

1. a narrow scripted-completion seam in `Relationships`, or
2. equivalent atomic GameState operations following existing completion invariant.

Required invariant:

```text
if target was not conquered:
    relationship = 5
    mark conquered once
    GameState.add_experience(1) once
```

No normal cooldown is required after the ending.

---

# 60. Final completion source

After success:

```text
GameState.is_girl_conquered(&"girl_final_target") == true
```

This is canonical.

No:

```text
FLAG_FINAL_COMPLETE
```

needed.

---

# 61. Success exact copy

Functional scene:

```text
Последняя:
«Значит, вся эта система была нужна, чтобы в конце дойти сюда лично?»

Герой:
«Да. Делегировать финал было бы странно.»

Последняя:
«Это первый разумный предел, который ты назвал сегодня.»
```

Then:

```text
ЦЕЛЬ ДОСТИГНУТА
```

---

# 62. Ending system copy

After dialogue:

```text
ПЛАНЕТАРНЫЙ ПРОЕКТ:
ЗАВЕРШЁН

ПРИЧИНА:
ЦЕЛЬ ДОСТИГНУТА

DATE FACTORY
```

Functional, not final credits art.

---

# 63. Ending summary

Optional but recommended functional summary:

```text
Опытность: X
Авторитет: X
Клонов: X
Охват Земли: 100
```

Do not require special formatting/polish yet.

---

# 64. Ending button

Exact:

```text
[Продолжить]
```

On click:

- close ending overlay;
- player returns GAMEPLAY in final_location;
- final target remains visible in a simple post-ending idle setup;
- clone economy may continue.

No forced application quit.

---

# 65. Post-ending world

Game remains playable.

Final signal interactable now:

```text
Финал завершён
```

Phone Story:

```text
ФИНАЛ ЗАВЕРШЁН

Последняя: +5
Охват Земли: 100

Цель достигнута.
```

---

# 66. No alternate endings

Do NOT branch ending based on:

- chosen characteristic;
- number of clones;
- Money;
- Authority;
- score 3 vs5;
- which rival was closer.

All successful routes reach same ending.

Different choices only change moment-to-moment responses.

---

# 67. No bad ending

Failure is:

```text
retry state
```

not ending.

Do not show credits or “game over”.

---

# 68. Final target in Phone

Before final sequence:

may show:

```text
Последняя
Статус: сигнал обнаружен
```

After start/contact:

```text
Контакт установлен
```

After success:

```text
Отношения: +5
```

No normal date cooldown.

---

# 69. Content catalog additions

Add:

Girls:

```text
girl_final_target
```

Rivals:

```text
rival_final_ceremonial
rival_final_gravity
```

Appearances:

```text
appearance_female_final_target
appearance_male_final_ceremonial
appearance_male_final_gravity
```

No normal dating pool/events required for target.

Final event content lives inside final-sequence typed content/constants.

---

# 70. Production content totals

After MODULE20:

```text
girls = 13
rivals = 12
```

After MODULE21:

```text
girls = 14
rivals = 14
```

The reserved final target ID is now fulfilled.

---

# 71. Final event typed content

Prefer a small:

```text
FinalDateEvent
FinalDateAction
```

or static typed definitions local to `game/final_date/`.

Fields sufficient:

```text
id
prompt
actions

action:
id
label
characteristic
required_level
result_text
```

Do NOT expand general DatingEventDefinition to support final sequence.

---

# 72. Suggested project area

```text
game/final_date/
├── final_date_controller.gd
├── final_date_types.gd
├── final_date_event.gd
├── final_date_action.gd
├── final_signal_interactable.gd
├── final_checkpoint_interactable.gd
├── final_date_ui.gd
└── test/
```

Keep compact.

---

# 73. Scene nodes — exact markers

Add to `final_location`:

```text
final_attempt_start

final_target_signal_marker
final_target_orbit_marker
final_target_table_marker

final_rival_ceremonial_marker
final_rival_gravity_marker

final_checkpoint_event_1
final_checkpoint_rival_1
final_checkpoint_event_2
final_checkpoint_rival_2
final_checkpoint_event_3
final_checkpoint_event_4

final_gate_zone_b
final_gate_zone_c
```

Names can be Node names or marker semantic IDs; content meaning must match.

---

# 74. No NPC navigation

Target/rivals move using:

```text
Tween
or
hide/show between markers
```

No NavigationAgent/AI.

---

# 75. No final open-world combat

No weapons.

No health.

No enemy AI.

Rivals exist only as staged competition interruptions.

---

# 76. Control safety

At any phase:

- exactly one final modal or minigame active;
- player control mode restored correctly;
- cannot open Phone over active modal if current modal conventions prevent it;
- no normal Rival encounter remains active.

Abort/retry clears temporary UI.

---

# 77. Existing economy during final

CloneIncremental / LateGameExpansion may continue running during:

```text
GAMEPLAY walking portions
```

During modal/minigame, existing SceneTree behavior remains as project currently defines.

Final result does not depend on changing counts.

No need to freeze economy.

---

# 78. Rival stats snapshot

Each exhibition competition snapshots player characteristic at start, like normal rivals.

Changes after rival starts do not affect active minigame.

---

# 79. Perks in final minigames

Existing Slap/Dance perks may function normally if runner reuse makes this natural.

Do NOT disable earned perks merely to normalize final difficulty.

---

# 80. No Authority reward

Even successful final rival minigames:

```text
Authority delta = 0
```

They are part of one date, not world hierarchy progression.

---

# 81. No permanent rival defeat

After successful full ending:

it is fine if final rivals are absent in post-ending presentation.

But GameState:

```text
is_rival_defeated(rival_final_*)
```

should remain false / unused.

---

# 82. Final target does not advance Story stage

There is no stage after:

```text
FINALE
```

Success:

```text
GameStage remains FINALE
```

Completion is target conquest/end screen.

---

# 83. Reset

Full `GameState.reset`:

- final target conquered false;
- relationship reset0;
- final controller transient state cleared via scene lifecycle;
- final location locked again through Story stage;
- content remains valid.

---

# 84. FINALE world access

Before:

```text
StoryFeature.FINAL_DATE
```

final_location remains locked.

After Reach100:

available.

No MODULE21 custom unlock flag.

---

# 85. Test — target catalog

ContentDB:

```text
girl_final_target exists
display "Последняя"
story_stage FINALE
STRANGE + VARIETY_SEEKING
appearance valid
no normal dating pool
```

---

# 86. Test — target not ordinary dateable

At cafe/any DateVenue:

```text
girl_final_target never appears
```

Even if contact is manually added.

---

# 87. Test — final rivals catalog

Both definitions exist with:

```text
reward0
required Authority0
DANCE-only / SLAP-only
```

---

# 88. Test — final locked before FINALE

Try direct interact/start before FINALE:

rejected.

No target contact/state mutation.

---

# 89. Test — final starts in FINALE

Expected:

```text
attempt active
phase INTRO
target spawned
score0
rival wins false
```

---

# 90. Test — no normal body cap

Set hero daily date capacity already used.

Final sequence still starts.

---

# 91. Test — characteristic buttons

For each event:

Level1:

characteristic option disabled.

Level2:

enabled.

Neutral always enabled.

---

# 92. Test — scoring specialized build

Player:

```text
AURA2
other stats <2
```

Choose Aura all4 events.

Expected:

```text
base score4
distinct1
no variety bonus
final score4
```

Dialogue portion passes.

---

# 93. Test — scoring diverse build

Use:

```text
MUSCLE
APPEARANCE
CAPITAL
AURA
```

once each.

Expected:

```text
base4
distinct4
variety bonus1
score5
```

Same ending.

---

# 94. Test — neutral fail

Neutral all4:

```text
score0
```

Even after both rivals won:

connection failure.

---

# 95. Test — threshold

Examples:

```text
2 characteristic +2 neutral
distinct2
score2
→ FAIL
```

```text
3 characteristic +1 neutral
score3
→ PASS
```

---

# 96. Test — DANCE loss

Lose rival1.

Expected:

- no normal Authority -1;
- no rival defeated mark;
- final failure modal;
- retry resets from INTRO.

---

# 97. Test — DANCE win

Expected:

```text
rival1_won true
Authority unchanged
```

---

# 98. Test — SLAP loss/win

Same invariant.

No Authority mutation.

---

# 99. Test — final rivals retry

After losing, restart entire date.

Both rival encounters are available again.

No persistence blocks them.

---

# 100. Test — leaving mid-attempt

Start, pass event1/rival1, leave final location.

Return.

Expected:

```text
new attempt begins from INTRO
```

No partial completion.

---

# 101. Test — failure state mutation

Snapshot before attempt.

Fail.

Expected gameplay persistence identical for:

```text
Money
Authority
XP
UP
relationship final target
conquered target
clone counts
Reach
```

Contact/discovered may remain if chosen at start; this is allowed.

---

# 102. Test — success

Before:

```text
final target relationship0
not conquered
Experience X
UP Y
```

Success:

```text
relationship5
conquered true
Experience X+1
UP Y+1
```

---

# 103. Test — success idempotent

Post-ending code/button callback twice:

```text
Experience only +1 once
UP only +1 once
```

Target remains5.

---

# 104. Test — no Stage change

Success:

```text
stage == FINALE
```

---

# 105. Test — post-ending interactable

No full final sequence starts again through normal beacon.

Displays final completed state/summary.

---

# 106. Test — one ending

Specialized vs diversified successful runs:

same canonical ending state and end copy.

No alternate ending flag.

---

# 107. Test — final location movement

Acceptance manual run must physically traverse:

```text
Zone A
→ Zone B
→ Zone C
```

not just click Next through one full-screen panel.

---

# 108. Test — target continuity

Same target presentation appears across zones.

Can move via tween/reposition but visually remains same character.

---

# 109. Test — no final RNG

Event order, options, rivals and success threshold deterministic.

Only player performance/choices affect result.

---

# 110. Test — minigame reuse

Final code does NOT contain copied Slap/Dance gameplay implementations.

Uses existing minigame classes/runner seam.

---

# 111. Test — normal Rival regressions

After adding exhibition seam:

normal world RivalEncounter wins/losses still:

- mark defeat;
- reward/lose Authority;
- use existing behavior exactly.

---

# 112. Test — no normal DatingCore regression

All existing DateVenue dates unchanged.

Final does not register as active DatingCore date.

---

# 113. Phone final state

Before success:

```text
ФИНАЛ
Внеземной сигнал обнаружен.
```

After contact/start:

```text
Последняя
Финальное свидание
```

After success:

```text
ФИНАЛ ЗАВЕРШЁН
Последняя: +5
```

---

# 114. Full game F5 acceptance

Required no-debug production route:

```text
PROLOGUE
→ Neighbor
→ Actress
→ Mine Boss
→ Editor
→ Media
→ Dating Overload
→ Scientist
→ First Clone
→ Clone Incremental
→ President
→ World Expansion
→ Reach100
→ FINALE
→ final_location

→ Final Signal
→ Event1
→ DANCE rival
→ Event2
→ walk to final table
→ SLAP rival
→ Event3
→ Event4
→ score >=3
→ SUCCESS
→ girl_final_target +5
→ ending screen
```

This is first full end-to-end game completion.

---

# 115. Failure F5 acceptance

Also manually prove:

```text
reach FINALE
→ lose one final rival
→ failure
→ retry
→ starts from Event1/INTRO
→ win full sequence
→ ending
```

No reload/debug recovery.

---

# 116. Approximate final duration

Target first successful run:

```text
8–15 minutes
```

depending on reading/minigame speed.

It must be clearly longer than ordinary date.

Do NOT pad with timers/waits.

---

# 117. No final grind

Once FINALE unlocked:

- no extra Money threshold;
- no clone-count threshold;
- no Authority gate;
- no Experience gate;
- no GameDay wait.

Only player choices/minigame skill inside final sequence.

---

# 118. Art scope

MODULE21 needs only readable prototype presentation:

- expanded final location;
- star/planet backdrop placeholder;
- alien-like character color/accessories;
- 3 zones;
- two rival visuals;
- table;
- gates;
- functional UI.

No final art pass.

---

# 119. Audio scope

No bespoke voice acting.

Optional reuse:

- minigame SFX;
- generic transition sting.

MODULE23/polish can improve later.

---

# 120. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
docs/content/MANUAL_CONTENT.md
```

Document exact MODULE21 implementation:

```text
girl_final_target = "Последняя"
STRANGE + VARIETY_SEEKING
custom final sequence, not normal DatingCore
4 characteristic events
level2 options
score threshold3
variety bonus at3 distinct
DANCE + SLAP exhibition rivals
failure full retry
success target +5 / one ending
```

---

# 121. Technical decision — final completion source

Document:

```text
GameState.is_girl_conquered(girl_final_target)
```

is final-completion source.

No extra final story flag.

---

# 122. Technical decision — exhibition rivals

Document:

```text
Final rival minigames reuse existing competition gameplay,
but bypass RivalEncounters persistent win/loss consequences.
```

---

# 123. Technical decision — custom final date

Document:

```text
The final date does not use DatingCore planning/scoring.
It is a deterministic authored scene with its own transient score,
while final successful relationship completion reuses the canonical
girl-conquest / Experience invariant.
```

---

# 124. What MODULE21 DOES NOT implement

Do NOT implement:

- alternate endings;
- bad ending;
- branching campaigns;
- procedural alien girls;
- procedural alien rivals;
- alien faction system;
- alien world map;
- new combat;
- health;
- weapons;
- final economy reset;
- prestige/rebirth;
- New Game+;
- offline progress;
- final art-quality models;
- voice acting;
- full credits production.

---

# 125. Definition of Done

MODULE21 complete only if:

- [ ] `girl_final_target` production definition exists;
- [ ] display name `"Последняя"`;
- [ ] STRANGE + VARIETY_SEEKING;
- [ ] FINALE story stage;
- [ ] no normal date pool/binding;
- [ ] not listed by DateVenue;
- [ ] alien female appearance exists;
- [ ] exactly2 final rival definitions exist;
- [ ] ceremonial rival DANCE-only / reward0;
- [ ] gravity rival SLAP-only / reward0;
- [ ] two alien male appearances exist;
- [ ] final rivals use exhibition/non-persistent result path;
- [ ] final rival loss causes zero Authority penalty;
- [ ] final rival win grants zero Authority;
- [ ] final rivals never persist in defeated set;
- [ ] existing Slap/Dance mechanics reused;
- [ ] normal RivalEncounter behavior unchanged;
- [ ] `FinalDateController` production scene logic exists;
- [ ] existing `story_point_final_sequence` used;
- [ ] Final Signal interactable exists;
- [ ] only available in FINALE;
- [ ] daily personal-date cap does not block final;
- [ ] final_location has3 physical zones;
- [ ] player physically moves ZoneA→B→C;
- [ ] exactly4 evaluated characteristic events;
- [ ] each has Muscle/Appearance/Capital/Aura/Neutral;
- [ ] characteristic options require level2;
- [ ] each enabled characteristic choice gives +1;
- [ ] neutral gives0;
- [ ] >=3 distinct gives one variety bonus;
- [ ] dialogue success threshold exact3;
- [ ] sequence order deterministic;
- [ ] rival1 DANCE occurs between Event1/Event2;
- [ ] rival2 SLAP occurs before final table events;
- [ ] failure can occur from either rival or low final score;
- [ ] failure has no permanent gameplay penalty;
- [ ] retry resets ENTIRE final sequence;
- [ ] attempts unlimited;
- [ ] leaving mid-attempt discards transient progress;
- [ ] success sets final target relationship+5;
- [ ] success marks final target conquered exactly once;
- [ ] success gives +1 XP/+1 UP exactly once;
- [ ] Stage remains FINALE;
- [ ] one canonical ending only;
- [ ] functional final end screen exists;
- [ ] `[Продолжить]` returns to playable world;
- [ ] post-ending Phone shows completion;
- [ ] clone/global economy is not reset;
- [ ] full clean F5 route reaches ending;
- [ ] failure→retry→success route works;
- [ ] MODULE02–20 regressions PASS.

---

# 126. Recommended Cursor order

```text
1. Audit final_location, CharacterFactory, Relationships completion APIs,
   RivalCompetitionRunner/Slap/Dance seams, Player control modes.
2. Add final target + two rival resources/appearances to ContentDB.
3. Ensure final target is excluded from normal Dating/Discovery flows.
4. Add narrow exhibition competition seam without changing normal Rival consequences.
5. Expand final_location into Zone A/B/C + all markers/gates.
6. Implement FinalDateController pure phase/score state.
7. Implement one reusable final dialogue-choice UI.
8. Wire Event1 → DANCE → Event2 → movement → SLAP → Event3 → Event4.
9. Implement full failure/retry reset.
10. Implement atomic target +5 success + functional ending.
11. Phone final state.
12. Full clean F5 completion + failure/retry regression.
13. All previous regressions/docs.
```

---

# 127. Cursor final report

## Final target

Confirm:

```text
girl_final_target
"Последняя"
STRANGE + VARIETY_SEEKING
no normal DatingCore pool
```

## Sequence

Show exact:

```text
Intro
Event1
Dance rival
Event2
physical move
Slap rival
Event3
Event4
assessment
```

## Characteristic scoring

Confirm:

```text
level2 requirement
+1 per characteristic action
neutral0
+1 variety at3 distinct
threshold3
```

## Exhibition rivals

Prove:

```text
no Authority delta
no defeated persistence
normal RivalEncounters unchanged
```

## Retry

Prove both:

```text
rival loss
low score
```

reset whole date with no permanent penalty.

## Success

Confirm:

```text
girl_final_target relationship5
conquered
+1 XP/+1 UP once
Stage remains FINALE
```

## Ending

Show one canonical ending and playable post-ending state.

## F5

Describe full game path from clean start to ending.

## Regressions

All MODULE02–20 suites.

## Commit

SHA.

Then STOP.
