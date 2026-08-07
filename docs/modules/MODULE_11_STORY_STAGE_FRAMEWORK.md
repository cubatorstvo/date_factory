# MODULE 11 — STORY / STAGE FRAMEWORK

**Проект:** Date Factory  
**Модуль:** 11 — Story / Stage Framework  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать лёгкую сценарную систему стадий, сюжетных целей, gating сюжетных девушек/самцов, автоматический переход между стадиями и семантические feature-unlocks для следующих модулей  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/07_story_clones_finale.md`  
**Предыдущие модули:** MODULE 02–10  
**Следующий модуль:** MODULE 12 — World & Location Framework

---

# 0. ГЛАВНЫЙ ПРИНЦИП

MODULE 11 НЕ является quest engine.

В Date Factory существует заранее известная линейная последовательность:

```text
PROLOGUE
→ STAGE_1
→ STAGE_2
→ STAGE_3
→ STAGE_4
→ STAGE_5
→ STAGE_6
→ FINALE
```

Для земных сюжетных стадий используется почти один и тот же шаблон:

```text
сюжетный самец
→ победить его
→ сюжетная девушка
→ довести отношения до +5
→ перейти дальше
```

Исключения:

```text
PROLOGUE:
    только соседка

STAGE_6:
    внешняя цель мировой автоматизации

FINALE:
    отдельная MODULE 21 sequence
```

Не строить универсальные:
- `QuestDefinition`;
- Requirement DSL;
- Reward DSL;
- Objective Graph;
- branching quest tree;
- dialogue condition engine;
- generic trigger engine.

---

# 1. Канонические стадии

Использовать существующий enum:

```text
GameTypes.GameStage
```

Exact order:

```text
PROLOGUE = 0
STAGE_1 = 1
STAGE_2 = 2
STAGE_3 = 3
STAGE_4 = 4
STAGE_5 = 5
STAGE_6 = 6
FINALE  = 7
```

Не создавать второй enum стадий.

---

# 2. Каноническая сюжетная карта

## PROLOGUE

```text
story girl = girl_neighbor
story rival = none
goal = complete girl_neighbor
next = STAGE_1
```

После успешной линии соседки начинается первая полноценная стадия.

## STAGE_1 — Актриса

```text
story girl = girl_actress
story rival = rival_actress
next = STAGE_2
```

Порядок:

```text
defeat rival_actress
→ acquaintance with girl_actress becomes story-allowed
→ complete girl_actress to +5
→ STAGE_2
```

## STAGE_2 — Начальница шахты

```text
story girl = girl_mine_boss
story rival = rival_mine_boss
next = STAGE_3
```

Completion открывает semantic feature:

```text
SALARY_MINE
```

## STAGE_3 — Редактор журнала

```text
story girl = girl_magazine_editor
story rival = rival_magazine_editor
next = STAGE_4
```

Completion открывает:

```text
MEDIA_ATTENTION
```

## STAGE_4 — Учёная

```text
story girl = girl_scientist
story rival = rival_scientist
next = STAGE_5
```

Completion открывает:

```text
LABORATORY
```

## STAGE_5 — Президент

```text
story girl = girl_president
story rival = rival_president
next = STAGE_6
```

Completion открывает:

```text
WORLD_EXPANSION
```

## STAGE_6 — Мировое расширение

```text
story girl = none
story rival = none
completion = external milestone
next = FINALE
```

MODULE 20 позже сообщает:

```text
world expansion complete
```

## FINALE

Reserved target:

```text
girl_final_target
```

MODULE 11 НЕ реализует её обычную relationship line, финальное свидание, внеземных rivals или ending. Это MODULE 21.

---

# 3. Reserved story IDs

Создать один canonical constants holder:

```text
StoryIds
```

Exact girl IDs:

```text
GIRL_NEIGHBOR         = &"girl_neighbor"
GIRL_ACTRESS          = &"girl_actress"
GIRL_MINE_BOSS        = &"girl_mine_boss"
GIRL_MAGAZINE_EDITOR  = &"girl_magazine_editor"
GIRL_SCIENTIST        = &"girl_scientist"
GIRL_PRESIDENT        = &"girl_president"
GIRL_FINAL_TARGET     = &"girl_final_target"
```

Exact rival IDs:

```text
RIVAL_ACTRESS         = &"rival_actress"
RIVAL_MINE_BOSS       = &"rival_mine_boss"
RIVAL_MAGAZINE_EDITOR = &"rival_magazine_editor"
RIVAL_SCIENTIST       = &"rival_scientist"
RIVAL_PRESIDENT       = &"rival_president"
```

Не придумывать display names персонажей.

---

# 4. StoryStageDefinition

Создать typed static:

```text
StoryStageDefinition
```

Минимальные поля:

```text
stage: GameTypes.GameStage
display_name: String

story_girl_id: StringName = &""
story_rival_id: StringName = &""

requires_story_rival: bool = false

completion_mode: StoryTypes.StageCompletionMode
next_stage: GameTypes.GameStage
```

---

# 5. StageCompletionMode

Ровно:

```text
GIRL_COMPLETED
EXTERNAL_MILESTONE
NONE
```

Mapping:

```text
PROLOGUE  → GIRL_COMPLETED
STAGE_1   → GIRL_COMPLETED
STAGE_2   → GIRL_COMPLETED
STAGE_3   → GIRL_COMPLETED
STAGE_4   → GIRL_COMPLETED
STAGE_5   → GIRL_COMPLETED
STAGE_6   → EXTERNAL_MILESTONE
FINALE    → NONE
```

Не создавать generic completion conditions array.

---

# 6. Story stage catalog

Нужны ровно 8 `StoryStageDefinition`, по одному на каждый `GameStage`.

Допустимые реализации:
1. explicit resources + ContentDB catalog;
2. маленький explicit `StoryStageCatalog`;
3. ContentDB extension.

Предпочтительно использовать существующий Content Data Layer и explicit catalog.

Не filesystem scan.

MODULE 14 ещё не создал production story Girl/Rival definitions. Поэтому MODULE 11 validation проверяет формат и exact reserved mapping, но НЕ требует, чтобы production `GirlDefinition`/`RivalDefinition` уже существовали.

---

# 7. Exact stage definitions

## PROLOGUE

```text
display_name = "Пролог"
story_girl_id = girl_neighbor
story_rival_id = ""
requires_story_rival = false
completion_mode = GIRL_COMPLETED
next_stage = STAGE_1
```

## STAGE_1

```text
display_name = "Стадия 1"
girl_actress
rival_actress
requires_story_rival = true
next = STAGE_2
```

## STAGE_2

```text
girl_mine_boss
rival_mine_boss
requires_story_rival = true
next = STAGE_3
```

## STAGE_3

```text
girl_magazine_editor
rival_magazine_editor
requires_story_rival = true
next = STAGE_4
```

## STAGE_4

```text
girl_scientist
rival_scientist
requires_story_rival = true
next = STAGE_5
```

## STAGE_5

```text
girl_president
rival_president
requires_story_rival = true
next = STAGE_6
```

## STAGE_6

```text
girl = ""
rival = ""
requires_story_rival = false
completion_mode = EXTERNAL_MILESTONE
next = FINALE
```

## FINALE

```text
story_girl_id = girl_final_target
story_rival_id = ""
completion_mode = NONE
next_stage = FINALE
```

---

# 8. Stage transition ownership

Persistent stage уже хранится в:

```text
GameState
```

Gameplay API уже существует:

```text
GameState.advance_stage(next_stage)
```

MODULE 11 НЕ дублирует persistent stage.

Rule owner:

```text
Story
```

Storage owner:

```text
GameState
```

---

# 9. Story service

Создать lightweight system:

```text
Story
```

Предпочтительно autoload, потому что он:
- слушает Relationships;
- слушает RivalEncounters;
- используется GirlDiscovery;
- используется будущими World/Salary/Media/Lab modules;
- не зависит от конкретной scene.

Canonical name:

```text
Story
```

Не `QuestManager`, `StoryManager`, `CampaignManager`.

---

# 10. Story event-driven

Никакого `_process()`.

Story слушает:

```text
Relationships.girl_completed
RivalEncounters.encounter_won
GameState.state_reset
GameState.stage_changed
```

---

# 11. Stage complete check

Для `GIRL_COMPLETED`:

```text
girl_complete =
GameState.is_girl_conquered(story_girl_id)
```

Если:

```text
requires_story_rival == true
```

дополнительно:

```text
rival_complete =
GameState.is_rival_defeated(story_rival_id)
```

Stage complete:

```text
girl_complete && rival_complete
```

Пролог:

```text
girl_complete only
```

---

# 12. Почему слушаем и rival win

Нормальный порядок:

```text
rival first
girl second
```

Но debug/restore может дать:

```text
girl already conquered
rival defeated later
```

Поэтому после любого relevant:

```text
girl_completed
или
encounter_won
```

Story вызывает:

```text
_try_complete_current_stage()
```

---

# 13. Advance exactly one stage

После completion:

```text
GameState.advance_stage(def.next_stage)
```

Story никогда не использует `restore_stage()` для gameplay.

Один semantic event продвигает максимум одну стадию.

Если debug заранее отметил следующие стадии выполненными, один callback НЕ должен пролететь несколько стадий.

Допустим technical:

```text
reconcile_current_stage()
```

Он тоже проверяет максимум одну текущую stage.

---

# 14. Stage signals

Story emit semantic:

```text
stage_completed(completed_stage)
stage_started(new_stage)
stage_objective_changed(progress)
```

Порядок normal transition:

```text
stage_completed(old_stage)
→ GameState.advance_stage(next)
→ GameState.stage_changed
→ Story.stage_started(next)
→ Story.stage_objective_changed(new_progress)
```

---

# 15. StoryStageProgress

Создать typed read model:

```text
StoryStageProgress
```

Минимально:

```text
stage
display_name

story_girl_id
story_rival_id

rival_required
rival_defeated

girl_completed

completion_mode
external_milestone_complete

is_complete
```

---

# 16. Subquests без quest engine

Functional objective view строится из `StoryStageProgress`.

PROLOGUE:

```text
[ ] Довести отношения с сюжетной девушкой до +5
```

STAGE_1..5:

```text
[ ] Победить текущего ухажёра
[ ] Довести отношения с сюжетной девушкой до +5
```

До defeat rival второй пункт может быть `LOCKED`.

STAGE_6:

```text
[ ] Завершить мировое расширение
```

FINALE:

```text
Финальная глава
```

Если нужен `ObjectiveState`, ровно:

```text
LOCKED
ACTIVE
COMPLETE
```

Не создавать `QuestObjectiveDefinition`.

---

# 17. Story girl gate

Story предоставляет:

```text
get_story_girl_gate(girl_id)
```

Statuses:

```text
NOT_STORY_GIRL
AVAILABLE
WRONG_STAGE
RIVAL_REQUIRED
```

Опытность сюда НЕ входит.

Она уже проверяется через:

```text
GirlDefinition.required_experience
```

в GirlDiscovery.

---

# 18. Current stage story girl

Если girl соответствует current stage:
- rival не нужен → `AVAILABLE`;
- rival нужен и defeated → `AVAILABLE`;
- rival нужен и undefeated → `RIVAL_REQUIRED`.

Reserved story girl другой stage:

```text
WRONG_STAGE
```

Это защищает от случайного spawn Президента на ранней стадии.

---

# 19. Final target gate

`girl_final_target`:

```text
AVAILABLE
```

только при:

```text
GameState.stage == FINALE
```

Но normal GirlDiscovery flow НЕ обязан использоваться для final target. MODULE 21 владеет entry sequence.

---

# 20. GirlDiscovery integration

В `GirlDiscovery.begin_attempt()` добавить маленькую optional Story check.

Порядок:
1. validate girl;
2. discovered/contact/cooldown;
3. Story gate;
4. обычный Experience gate;
5. discovery situation.

Если Story возвращает:

```text
WRONG_STAGE
RIVAL_REQUIRED
```

attempt не стартует.

Добавить semantic reasons:

```text
STORY_WRONG_STAGE
STORY_RIVAL_REQUIRED
```

или clean mapping.

Это НЕ `FAILURE`.

Нет:
- clue reveal;
- cooldown;
- relationship change.

---

# 21. Story gate UI

Functional text:

`RIVAL_REQUIRED`:

```text
Сначала разберись с её текущим ухажёром.
```

`WRONG_STAGE`:

```text
Эта линия пока недоступна.
```

Production prose MODULE 14.

---

# 22. Story rival gate

Story предоставляет:

```text
get_story_rival_gate(rival_id)
```

Statuses:

```text
NOT_STORY_RIVAL
AVAILABLE
WRONG_STAGE
ALREADY_DEFEATED
```

Current stage rival доступен, если не defeated.

Authority/minigame access отдельно проверяет `RivalEncounters`.

---

# 23. Не встраивать Story в RivalEncounters core

MODULE 06 tests используют test story rivals.

Поэтому НЕ заставлять generic:

```text
RivalEncounters.start_encounter()
```

глобально консультироваться со Story.

Story gating должен использовать future staged scene / story rival actor / caller MODULE 14.

---

# 24. Rival win не завершает stage

Story слушает:

```text
RivalEncounters.encounter_won(result)
```

Если это current story rival:
- objective обновляется;
- girl gate становится `AVAILABLE`;
- stage остаётся прежней.

Сюжетный самец — подквест, а не конец стадии.

---

# 25. Story girl completion

Story слушает:

```text
Relationships.girl_completed(girl_id, result)
```

Если current story girl:

```text
_try_complete_current_stage()
```

Ordinary girl completion stage не меняет.

---

# 26. StoryFeature

Создать enum:

```text
StoryTypes.StoryFeature
```

Ровно:

```text
SOCIAL_ACCESS
PUBLIC_CITY_ACCESS
SALARY_MINE
MEDIA_ATTENTION
LABORATORY
WORLD_EXPANSION
FINAL_DATE
```

---

# 27. Feature thresholds

Exact:

```text
SOCIAL_ACCESS
→ stage >= STAGE_1

PUBLIC_CITY_ACCESS
→ stage >= STAGE_2

SALARY_MINE
→ stage >= STAGE_3

MEDIA_ATTENTION
→ stage >= STAGE_4

LABORATORY
→ stage >= STAGE_5

WORLD_EXPANSION
→ stage >= STAGE_6

FINAL_DATE
→ stage >= FINALE
```

---

# 28. Почему thresholds такие

- PROLOGUE completion → начинает полноценную social stage.
- STAGE_1 Actress completion → public/status city layer.
- STAGE_2 Mine Boss completion → Salary Mine.
- STAGE_3 Editor completion → Media/Attention.
- STAGE_4 Scientist completion → Laboratory.
- STAGE_5 President completion → World Expansion.
- STAGE_6 completion → Final Date.

---

# 29. Feature API

Нужны:

```text
is_feature_unlocked(feature) -> bool
get_feature_unlock_stage(feature) -> GameStage
```

Не хранить отдельные bool в GameState.

Feature производна от stage.

При normal stage advance можно emit:

```text
feature_unlocked(feature)
```

для newly crossed feature.

Modules при startup обязаны query текущее состояние, а не полагаться только на signal.

---

# 30. Restore stage semantics

Если Save/Load позже делает:

```text
GameState.restore_stage(STAGE_5)
```

Story:
- refresh current snapshot;
- не replay-ит пять fake stage completion;
- не выдаёт rewards.

Feature query сразу возвращает корректное значение из current stage.

---

# 31. Story features не являются rewards

Stage transition НЕ даёт напрямую:
- Money;
- Authority;
- Experience;
- Upgrade Points;
- perk.

Эти значения уже выдаются systems, которые породили событие.

---

# 32. World boundary

MODULE 11 НЕ вызывает конкретные:

```text
GameState.unlock_location(...)
```

Почему:
- MODULE 12 ещё определяет physical world map;
- не надо угадывать конкретные двери/районы.

MODULE 12 будет использовать:

```text
GameState.stage
Story.is_feature_unlocked(...)
```

для access.

Таким образом MODULE 11 отвечает за semantic unlock, MODULE 12 — за physical world.

---

# 33. External Stage 6 milestone

Создать exact flag:

```text
StoryIds.FLAG_WORLD_EXPANSION_COMPLETE
= &"story_world_expansion_complete"
```

Story API:

```text
complete_world_expansion() -> bool
```

Разрешено только если:

```text
current stage == STAGE_6
```

First call:

```text
GameState.set_story_flag(flag, true)
_try_complete_current_stage()
```

=>:

```text
STAGE_6 → FINALE
```

Wrong stage:
- reject;
- flag не ставить.

Duplicate:
- no duplicate transition.

---

# 34. Stage 6 complete check

```text
GameState.get_story_flag(
    StoryIds.FLAG_WORLD_EXPANSION_COMPLETE
)
```

Это единственный новый persistent Story flag MODULE 11.

---

# 35. Не дублировать факты

Не создавать flags:

```text
actress_complete
mine_boss_complete
editor_complete
scientist_complete
president_complete
```

Эти факты уже существуют в:

```text
GameState.conquered_girls
```

Не создавать rival defeat flags — они уже в:

```text
GameState.defeated_rivals
```

---

# 36. FINALE

При entering FINALE:

```text
StoryFeature.FINAL_DATE == true
```

Но Story больше автоматически не advance.

Не добавлять `POST_GAME`/`ENDING`/`COMPLETE` stage.

---

# 37. No branching

Никакие choices MODULE 11:
- не меняют порядок stages;
- не создают alternate stage;
- не создают alternate ending.

---

# 38. Actor visibility helpers

Story предоставляет:

```text
should_story_girl_be_present(girl_id) -> bool
should_story_rival_be_present(rival_id) -> bool
```

Story girl required presence:
- true для girl current stage;
- false для reserved story girls других stages.

Rival required presence:
- current stage match;
- not defeated.

Это helper для MODULE 14, а не despawn law.

---

# 39. Не создавать Story actors

MODULE 11 НЕ создаёт:

```text
StoryGirlActor
StoryRivalActor
QuestNPC
```

MODULE 14 использует обычные:

```text
GirlActor
RivalActor
```

+ Story gates.

---

# 40. Stage progression не зависит от Authority

Нельзя:

```text
Authority >= N
→ next stage
```

Authority только gate RivalEncounter.

---

# 41. Stage progression не зависит от Experience напрямую

Нельзя:

```text
Experience >= N
→ next stage
```

Experience может gate acquaintance через `GirlDefinition.required_experience`, но сама не закрывает stage.

---

# 42. Source-of-truth responsibilities

```text
StoryStageDefinition
→ story girl/rival + next stage

GirlDefinition
→ Experience gate

RivalDefinition
→ Authority gate / competitions / stats

Relationships
→ girl completion

RivalEncounters
→ rival defeat

GameState
→ persistent stage
```

Не дублировать.

---

# 43. Test strategy

Production story Girl/Rival content MODULE 14 ещё отсутствует.

Framework tests могут напрямую создавать state через:

```text
GameState.mark_girl_conquered(StoryIds.GIRL_...)
GameState.mark_rival_defeated(StoryIds.RIVAL_...)
```

Нужен хотя бы один real-signal integration test через:
- `Relationships.girl_completed`;
- `RivalEncounters.encounter_won`.

---

# 44. Test — reset

After reset:

```text
stage == PROLOGUE
SOCIAL_ACCESS == false
current story girl == girl_neighbor
rival required == false
```

---

# 45. Test — neighbor completion

Expected:

```text
PROLOGUE → STAGE_1
SOCIAL_ACCESS = true
```

No other feature.

---

# 46. Test — Stage 1 mapping

Current:

```text
girl_actress
rival_actress
rival required=true
```

---

# 47. Test — actress gated

Before rival defeat:

```text
get_story_girl_gate(girl_actress)
→ RIVAL_REQUIRED
```

GirlDiscovery attempt:
- no failure;
- no clue increment from failure;
- no cooldown.

---

# 48. Test — rival win alone

Defeat `rival_actress`.

Expected:

```text
stage remains STAGE_1
girl gate AVAILABLE
```

---

# 49. Test — actress completion

After rival:

```text
girl_actress +5
→ STAGE_2
PUBLIC_CITY_ACCESS = true
```

---

# 50. Test — girl already complete before rival

Debug:
```text
girl_actress conquered
rival not defeated
```

No advance.

Then rival defeat event:

```text
STAGE_1 → STAGE_2
```

---

# 51. Test — ordinary content ignored

Ordinary rival win:
- stage unchanged.

Ordinary girl +5:
- Experience may rise;
- stage unchanged.

---

# 52. Test — wrong story girl/rival

At STAGE_1:

```text
girl_president → WRONG_STAGE
rival_president → WRONG_STAGE
```

---

# 53. Test — one event one stage maximum

Pre-mark:
```text
neighbor conquered
actress conquered
rival_actress defeated
```

Reconcile PROLOGUE once:

```text
→ STAGE_1 only
```

Second explicit reconcile may:

```text
→ STAGE_2
```

---

# 54. Test — feature unlock sequence

Mine Boss completion:

```text
STAGE_2 → STAGE_3
SALARY_MINE true
```

Editor completion:

```text
STAGE_3 → STAGE_4
MEDIA_ATTENTION true
```

Scientist completion:

```text
STAGE_4 → STAGE_5
LABORATORY true
```

President completion:

```text
STAGE_5 → STAGE_6
WORLD_EXPANSION true
```

---

# 55. Test — cumulative features

At STAGE_6:

```text
SOCIAL_ACCESS true
PUBLIC_CITY_ACCESS true
SALARY_MINE true
MEDIA_ATTENTION true
LABORATORY true
WORLD_EXPANSION true
FINAL_DATE false
```

---

# 56. Test — Stage 6 milestone

Entering STAGE_6 alone does not advance.

Wrong-stage `complete_world_expansion()` rejected.

At STAGE_6 first valid call:

```text
flag true
stage → FINALE
FINAL_DATE true
```

Second call no duplicate.

---

# 57. Test — Finale no auto advance

At FINALE:
- even if `girl_final_target` is debug-marked conquered;
- stage remains FINALE.

---

# 58. Test — restore stage feature derivation

```text
restore_stage(STAGE_5)
```

Expected:

```text
LABORATORY true
WORLD_EXPANSION false
```

No replay rewards.

---

# 59. Test — Authority/Experience not direct stage conditions

At PROLOGUE:
```text
Authority = 999
Experience = 999
```

Stage remains PROLOGUE until neighbor completion.

---

# 60. Test — normal gates preserved

Story girl gate AVAILABLE after rival does NOT bypass:
```text
GirlDefinition.required_experience
```

Story rival gate AVAILABLE does NOT bypass:
```text
RivalDefinition.required_authority
```

---

# 61. Test — no mutation leakage

Story module never directly calls:
```text
set_girl_relationship
add_girl_relationship
mark_rival_defeated
add_experience
add_authority
```

---

# 62. Test — catalog exactness

Exactly 8 stage definitions.

Every enum exactly once.

Exact canonical ID mapping.

STAGE1–5 `requires_story_rival=true`.

STAGE6 external/no girl/no rival.

FINALE final target/NONE.

---

# 63. Regressions

Run:
```text
MODULE 02
MODULE 03
MODULE 04
MODULE 05
MODULE 06
MODULE 07A
MODULE 07B
MODULE 07C
MODULE 07D
MODULE 08
MODULE 09
MODULE 10
FPS
```

Особенно:
- MODULE 06 test story rivals должны продолжать работать;
- ordinary MODULE 08 girls не должны получить Story gating.

---

# 64. Functional debug view

Допустим маленький test/debug panel:

```text
Current Stage
Story Girl
Story Rival
Rival status
Girl status
Unlocked features
```

Debug-only buttons:
```text
Mark Rival Defeated
Mark Girl Conquered
Complete World Expansion
Reset
```

Не production quest journal.

---

# 65. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
```

Документировать:
- exact stage mapping;
- feature thresholds;
- no quest engine;
- semantic/physical unlock boundary.

---

# 66. Expected area

Пример:

```text
game/story/
├── story.gd
├── story_ids.gd
├── story_types.gd
├── story_stage_definition.gd
├── story_stage_progress.gd
├── story_stage_catalog.gd
└── test/
```

Не обязано быть ровно столько файлов.

---

# 67. Что MODULE 11 НЕ реализует

Категорически не реализовывать:
- physical world;
- scene transitions;
- doors;
- district barriers;
- NPC placement;
- production story girls;
- production story rivals;
- production dialogue;
- Salary Mine mechanics;
- income;
- media feed;
- photo session;
- dating overload;
- cloning;
- final date;
- quest editor;
- branching quests;
- alternate endings;
- Save/Load;
- final story UI.

---

# 68. Definition of Done

MODULE 11 завершён только если:

- [ ] `StoryStageDefinition` существует;
- [ ] ровно 8 canonical stages;
- [ ] reserved IDs canonical;
- [ ] mappings exact;
- [ ] `Story` lightweight service существует;
- [ ] source of truth stage = GameState;
- [ ] event-driven, no `_process`;
- [ ] PROLOGUE completes from neighbor;
- [ ] STAGE1–5 require correct rival + correct girl;
- [ ] rival win alone does not advance;
- [ ] ordinary rival/girl do not advance;
- [ ] one event advances max one stage;
- [ ] Story girl gate exists;
- [ ] wrong-stage story girl blocked;
- [ ] undefeated rival blocks acquaintance;
- [ ] story gate does not trigger discovery failure/cooldown;
- [ ] GirlDiscovery consults Story for reserved story girls;
- [ ] Experience gate remains GirlDiscovery responsibility;
- [ ] Story rival gate exists;
- [ ] RivalEncounters core not polluted with Story gating;
- [ ] Stage6 external milestone exists;
- [ ] only world-expansion extra Story flag added;
- [ ] Stage6 → Finale only by milestone;
- [ ] Finale no auto advance;
- [ ] `StoryFeature` exists;
- [ ] exact thresholds implemented;
- [ ] feature state derived from stage;
- [ ] Salary Mine = STAGE3;
- [ ] Media = STAGE4;
- [ ] Laboratory = STAGE5;
- [ ] World Expansion = STAGE6;
- [ ] Final Date = FINALE;
- [ ] no physical location unlocks guessed;
- [ ] typed current stage progress exists;
- [ ] no universal quest engine;
- [ ] no fake production story actors/content;
- [ ] MODULE 02–10 regressions pass;
- [ ] FPS/Rival/minigame regressions pass;
- [ ] MODULE 12 not implemented ahead.

---

# 69. Порядок выполнения Cursor

## Step 1 — Audit

Проверить:
```text
GameTypes.GameStage
GameState stage/story flags
Relationships.girl_completed
RivalEncounters.encounter_won
GirlDiscovery.begin_attempt
ContentDB
```

## Step 2 — static story definitions

Добавить:
```text
StoryIds
StoryTypes
StoryStageDefinition
8-stage catalog
validation
```

Без production Girl/Rival resources.

## Step 3 — Story service

Реализовать:
```text
current definition
current progress
event subscriptions
try completion
advance
```

## Step 4 — story gates

```text
story girl gate
story rival gate
```

## Step 5 — GirlDiscovery integration

Минимально подключить story girl gate.

## Step 6 — Feature gates

Exact stage-derived thresholds.

## Step 7 — Stage6 seam

```text
complete_world_expansion()
```

## Step 8 — tests

Прогнать tests из спецификации.

## Step 9 — regressions

Все previous modules.

## Step 10 — docs

Обновить architecture/GDD notes.

---

# 70. Формат финального отчёта Cursor

## Story architecture

Как устроены:
```text
Story
StoryStageDefinition
StoryStageProgress
GameState
```

## Canonical mapping

8 stages + story girl/rival IDs.

## Stage progression

Подтвердить:
```text
PROLOGUE = neighbor
STAGE1–5 = rival + girl
STAGE6 = external milestone
FINALE = no auto advance
```

## Story gates

GirlDiscovery integration и отсутствие Story logic в generic RivalEncounters.

## Features

Exact:
```text
STAGE1 Social
STAGE2 Public City
STAGE3 Salary Mine
STAGE4 Media
STAGE5 Laboratory
STAGE6 World Expansion
FINALE Final Date
```

## State

Подтвердить:
- no duplicated completion flags;
- only world-expansion external flag;
- stage remains GameState source of truth.

## Validation

MODULE 11 tests + regressions.

## Files changed

Основные файлы.

## Product questions

Если нет:
```text
None.
```

---

# 71. Запрет продолжения

После успешного MODULE 11:

**НЕ начинать MODULE 12 — World & Location Framework.**

Остановиться и дождаться отдельной спецификации.
