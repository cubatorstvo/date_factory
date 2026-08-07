# MODULE 07B — DANCE MINIGAME / ТАНЦЕВАЛЬНОЕ ПРОТИВОСТОЯНИЕ

**Проект:** Date Factory  
**Модуль:** 07B — Rival Minigame: Dance  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** заменить неоднозначный SlapCompetitionHost единым RivalCompetitionRunner и реализовать вторую полноценную мужскую мини-игру — танцевальное противостояние  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущий модуль:** MODULE 07A — Slap Minigame

---

# 0. PRE-FLIGHT — HOST → RIVAL COMPETITION RUNNER

До реализации Dance выполнить архитектурный cleanup MODULE 07A.

## 0.1. Проблема текущего имени

Сейчас существует:

```text
SlapCompetitionHost
```

Термин `Host` двусмыслен:

- может восприниматься как multiplayer host;
- звучит как владелец игрового мира;
- на самом деле объект лишь запускает мини-игру и возвращает result.

В Date Factory этот объект не является сетевым host.

---

# 0.2. Canonical name

Создать единый:

```text
RivalCompetitionRunner
```

Canonical responsibility:

```text
RivalEncounters
→ RivalCompetitionRequest
→ RivalCompetitionRunner
→ concrete minigame
→ RivalCompetitionResult
→ RivalEncounters
```

---

# 0.3. Удалить отдельный SlapCompetitionHost

После migration не должно оставаться production class/file:

```text
SlapCompetitionHost
slap_competition_host.gd
```

Его ответственность переносится в:

```text
RivalCompetitionRunner
```

---

# 0.4. Один runner на все 4 состязания

Runner маршрутизирует явно:

```text
SLAP  → SlapMinigame
DANCE → DanceMinigame
SIGMA → not implemented yet
MONEY → not implemented yet
```

После следующих модулей:

```text
SIGMA → SigmaMinigame
MONEY → MoneyMinigame
```

Не создавать:

```text
SlapHost
DanceHost
SigmaHost
MoneyHost
```

---

# 0.5. Никакой generic plugin registry

Типов всего четыре.

Использовать простой explicit routing:

```text
match competition_type:
    SLAP:
        ...
    DANCE:
        ...
```

Не создавать:

- dynamic minigame registry;
- plugin discovery;
- factory container;
- service locator.

---

# 0.6. Production runner должен реально существовать runtime

`RivalCompetitionRunner` должен быть доступен независимо от текущей world scene.

Предпочтительный canonical technical choice:

```text
autoload RivalCompetitionRunner
```

потому что:

- RivalEncounters уже autoload;
- encounter может стартовать из разных world/date scenes;
- текущий `main` меняет scene;
- runner не должен вручную добавляться в каждую локацию.

Если Cursor видит более простой Godot-native способ с теми же гарантиями, может выбрать его и документировать.

Не оставлять production runner только внутри test scene.

---

# 0.7. Использовать существующий runner seam MODULE 06

`RivalEncounters` уже имеет:

```text
set_competition_runner(Callable)
clear_competition_runner()
```

Предпочтительно использовать именно этот seam:

```text
RivalCompetitionRunner._ready()
→ RivalEncounters.set_competition_runner(run_competition)
```

Signal:

```text
competition_requested
```

остаётся notification/presentation signal, а не вторым параллельным способом запуска production minigame.

Не должно существовать двух одновременно активных execution paths:

```text
signal subscriber
+
competition_runner Callable
```

для одного request.

---

# 0.8. MODULE 06 fake runner

MODULE 06 self-tests должны продолжать использовать fake runner.

Test setup может временно:

```text
set_competition_runner(fake)
```

а teardown обязан восстановить production runner либо очистить seam в изолированной test process.

Не ломать независимость MODULE 06 tests.

---

# 0.9. Runner владеет общими обязанностями

`RivalCompetitionRunner` отвечает за:

- один active concrete minigame;
- перевод Player в `MINIGAME`;
- сохранение return control mode;
- запуск конкретной minigame scene/object;
- exactly-once result submission;
- cleanup;
- восстановление control;
- отказ запуска второго minigame одновременно.

Concrete minigame НЕ должна самостоятельно:

- менять Authority;
- менять defeated_rivals;
- решать куда вернуть Player после encounter.

---

# 0.10. Concrete minigame contract

Slap и Dance должны концептуально иметь одинаковую минимальную границу:

```text
setup(request, ...)
signal match_finished(result: RivalCompetitionResult)
```

Не требуется создавать GDScript interface framework.

Достаточно одинакового простого contract по соглашению.

---

# 0.11. Rename tests/docs

Заменить terminology:

```text
host
SlapCompetitionHost
```

на:

```text
runner
RivalCompetitionRunner
```

в:

- tests;
- comments;
- `PROJECT_STRUCTURE.md`;
- `TECHNICAL_DECISIONS.md`;
- module-specific docs.

---

# 0.12. Slap regression

После cleanup:

```text
MODULE 07A ALL PASS
```

включая end-to-end:

```text
Rival → Runner → Slap → Rival
```

---

# 1. Цель Dance

После MODULE 07B должен работать:

```text
Rival Encounter
→ competition_type = DANCE
→ RivalCompetitionRunner
→ DanceMinigame
→ PLAYER_WIN / PLAYER_LOSS
→ CLOSE / CRUSHING
→ RivalEncounters
```

Танец должен соответствовать GDD:

1. соперник показывает короткую связку;
2. игрок запоминает порядок и ритм;
3. игрок повторяет связку;
4. после успешного повторения получает короткую собственную связку;
5. исполняет её в ритм;
6. результат определяется input skill, а не RNG.

---

# 2. Главный характер мини-игры

Это НЕ полноценная rhythm game.

Цель:

- 4 направления;
- короткие последовательности;
- понятный beat;
- 20–60 секунд;
- мгновенное понимание;
- смешная визуальная постановка.

Не создавать десятки нот и музыкальные чарты.

---

# 3. Что Cursor не имеет права добавлять

Не добавлять:

- osu-style notes;
- Guitar Hero lanes;
- BPM editor;
- song charts;
- MIDI;
- combo songs;
- freestyle scoring AI;
- procedural music;
- DDR pad abstraction;
- analog stick gestures;
- dance battle dialogue;
- crowd simulation;
- character mocap system;
- motion matching;
- IK choreography;
- generic rhythm-game engine.

---

# 4. Inputs

Использовать существующие:

```text
move_forward  = W
move_backward = S
move_left     = A
move_right    = D
```

Во время `MINIGAME` Player locomotion уже отключена.

DanceMinigame читает эти actions как четыре dance directions.

Mapping:

```text
W = UP
S = DOWN
A = LEFT
D = RIGHT
```

Не создавать дублирующие Input Map actions:

```text
dance_up
dance_down
...
```

---

# 5. Canonical DanceMove

Создать enum:

```text
UP
DOWN
LEFT
RIGHT
```

Он существует только внутри Dance/minigame domain.

Не добавлять:

- SPIN;
- JUMP;
- POSE;
- CROUCH;
- SPECIAL;

как отдельные gameplay inputs.

Более эффектная хореография позже может визуально менять presentation тех же четырёх moves.

---

# 6. Структура матча

Матч состоит из повторяющихся dance rounds.

Каждый round:

```text
1. OPPONENT_DEMO
2. PLAYER_REPEAT
3. если repeat успешен:
       OWN_PREVIEW
       PLAYER_OWN
4. round resolution
```

Если `PLAYER_REPEAT` провален:

```text
PLAYER_OWN
```

в этом round не запускается.

---

# 7. Счёт

Как и Slap:

## ordinary rival

```text
target_score = 3
```

## story rival

```text
target_score = 5
```

Матч заканчивается сразу при достижении target.

---

# 8. Очко за repeat

Если `PLAYER_REPEAT` успешно завершён:

```text
player_score += 1
```

Если repeat провален:

```text
rival_score += 1
```

---

# 9. Очко за own sequence

`PLAYER_OWN` доступна только после успешного repeat.

Успешное исполнение:

```text
player_score += 1
```

Провал:

```text
rival_score += 1
```

---

# 10. Возможный быстрый round

Один полный идеальный round может дать игроку:

```text
+2
```

Это нормально.

Ordinary match обычно занимает примерно два полных rounds.

За счёт demo + repeat + own один round сам длится достаточно долго.

---

# 11. Match end mid-round

Если после успешного repeat:

```text
player_score >= target_score
```

матч заканчивается сразу.

`PLAYER_OWN` уже не запускается.

Аналогично после fail repeat, если rival достиг target.

---

# 12. Sequence length

## Ordinary

Opponent repeat sequence:

```text
3 moves
```

Own sequence:

```text
3 moves
```

## Story

Opponent repeat sequence:

```text
4 moves
```

Own sequence:

```text
4 moves
```

Не менять длину скрыто по stat difference.

---

# 13. Complex sequence

Для perk-контракта:

```text
complex sequence = length >= 4
```

Следовательно в MODULE 07B:

```text
story rival sequences = complex
ordinary = not complex
```

---

# 14. Beat interval

Canonical:

```text
beat_interval = 0.80 seconds
```

Это расстояние между центрами соседних beat windows.

Не менять tempo по Appearance.

---

# 15. Pre-roll

Перед началом player input:

```text
0.60 seconds
```

короткая фаза:

```text
ТВОЯ ОЧЕРЕДЬ
```

Затем первый expected beat.

---

# 16. Opponent demo

Соперник показывает sequence по одному move каждые:

```text
0.80 s
```

Для каждого move одновременно:

- Character presentation делает движение;
- UI на короткое время показывает corresponding direction icon.

Игрок не вводит команды во время demo.

---

# 17. Demo visibility

Во время opponent demo:

- показывается только текущий move;
- полная sequence не лежит постоянно перед игроком.

То есть repeat содержит небольшой memory component.

Не превращать его в Simon Says на 10 элементов — всего 3/4.

---

# 18. Own preview

Перед `PLAYER_OWN` новая sequence:

- показывается сразу целиком;
- остаётся на экране во время исполнения.

Own phase проверяет в основном:

```text
ритм
```

а не память.

Это отличает две половины round.

---

# 19. Sequence generation

Каждый move выбирается pseudo-random из четырёх.

Ограничение:

```text
один и тот же direction
не более 2 раз подряд
```

То есть допустимо:

```text
LEFT, LEFT, UP
```

но не:

```text
LEFT, LEFT, LEFT
```

---

# 20. Повтор sequence

Новая sequence по возможности не должна полностью совпадать с предыдущей.

Если совпала:

- reroll до `4` attempts;
- затем принять результат.

Не зависать.

---

# 21. Deterministic tests

Как в Slap:

```text
rng_seed
```

должен быть задаваемым для tests.

Не хранить seed в GameState.

---

# 22. Difficulty stat

Использовать snapshot:

```text
difference = player_appearance - rival_appearance
```

из:

```text
RivalCompetitionRequest
```

Не читать текущую Appearance mid-match.

---

# 23. Base timing half-window

Ввод считается по расстоянию во времени от beat center.

Canonical:

```text
base_window = 0.18 + difference * 0.01
```

Clamp:

```text
0.11 <= base_window <= 0.25
```

Это HALF-window.

То есть при:

```text
base_window = 0.18
```

допустимая полная зона:

```text
±0.18 s
```

---

# 24. Examples

```text
difference = 0
=> ±0.18 s

difference = +4
=> ±0.22 s

difference = -4
=> ±0.14 s
```

---

# 25. Appearance does not cause hidden success

Запрещено:

```text
success_chance
auto_hit
random correction
```

Appearance меняет:

- timing window;
- allowed errors;
- visual tier.

---

# 26. Allowed errors

Количество допустимых failed moves в одной sequence:

```text
difference <= -3
=> 0 errors

-2 <= difference <= +2
=> 1 error

difference >= +3
=> 2 errors
```

Clamp:

```text
0..2
```

---

# 27. Что такое error

Error — один expected beat, который:

- получает неправильное направление;
- получает направление слишком рано/поздно;
- не получает input до окончания window.

Один beat = максимум одна error.

---

# 28. Sequence success

Sequence считается успешной:

```text
errors <= allowed_errors
```

Но есть обязательный minimum correctness:

```text
correct_moves >= ceil(sequence_length / 2)
```

Это предотвращает ситуацию, где большие error allowances превращают sequence в автопроход.

Для length 3:

```text
minimum 2 correct
```

Для length 4:

```text
minimum 2 correct
```

---

# 29. Input consumption

Во время active player sequence directional press относится к текущему expected beat.

Первый direction press для текущего beat:

- consumes beat;
- оценивается;
- второй input уже относится к следующему beat.

Spam поэтому приводит к ранним ошибкам следующих beat.

---

# 30. Too early

Если current time:

```text
< beat_time - effective_window
```

press:

```text
ERROR
```

текущий beat считается consumed.

---

# 31. Too late

Если player не нажал до:

```text
beat_time + effective_window
```

текущий beat автоматически:

```text
ERROR
```

и minigame переходит к следующему beat.

---

# 32. Wrong direction

Даже если timing правильный, но direction неверен:

```text
ERROR
```

---

# 33. HIT

Правильный direction и:

```text
abs(input_time - beat_time) <= effective_window
```

даёт:

```text
HIT
```

---

# 34. PERFECT

Canonical perfect region:

```text
perfect_window = effective_window * 0.35
```

Правильный direction внутри:

```text
±perfect_window
```

даёт:

```text
PERFECT
```

---

# 35. Perfect без perk

PERFECT:

- не даёт отдельное score point;
- усиливает visual feedback;
- увеличивает streak как обычный success.

Не создавать hidden score multiplier.

---

# 36. Streak

Локальный dance streak:

```text
последовательные успешные moves
```

HIT/PERFECT:

```text
streak += 1
```

ERROR:

```text
streak = 0
```

кроме `Поставленная походка`.

---

# 37. Streak mechanical effect

Streak слегка помогает держать flow.

На каждый следующий beat:

```text
streak_bonus =
min(streak, 4) * 0.015 seconds
```

То есть максимум:

```text
+0.06 s
```

к timing half-window.

---

# 38. Effective window

Без `Ритм в теле`:

```text
effective_window =
base_window + streak_bonus
```

Final clamp:

```text
<= 0.30 s
```

---

# 39. Streak resets between phases

На старте каждого:

```text
PLAYER_REPEAT
PLAYER_OWN
```

обычный starting streak:

```text
0
```

Streak не переносится:

- из repeat в own;
- между rounds.

---

# 40. `APPEARANCE_STAGED_WALK` — Поставленная походка

Один раз за весь dance match.

Trigger:

```text
первая ERROR
при streak > 0
```

Вместо:

```text
streak = 0
```

использовать:

```text
streak = max(1, ceil(previous_streak / 2.0))
```

Error всё равно:

- считается error;
- может привести к fail sequence.

Perk сохраняет rhythm-flow bonus, а не отменяет ошибку.

---

# 41. Staged Walk при streak 0

Если первая error произошла при:

```text
streak = 0
```

perk НЕ расходуется.

Он сможет сработать позже, когда реально есть серия для сохранения.

---

# 42. `APPEARANCE_RHYTHM_IN_BODY` — Ритм в теле

Имеет два эффекта.

## Effect 1 — wider window

До streak bonus:

```text
base_window *= 1.20
```

После multiplier снова соблюдать final clamp:

```text
<= 0.30
```

---

# 43. Rhythm in Body — visual clue

Первая complex `PLAYER_REPEAT` sequence текущего match получает дополнительную подсказку.

То есть для первого story sequence length 4:

во время player repeat за:

```text
0.25 s
```

до каждого beat center UI показывает полупрозрачный icon ожидаемого направления.

После beat icon исчезает.

---

# 44. Clue usage

Visual clue применяется:

```text
только к первой complex PLAYER_REPEAT sequence
```

и затем считается использованной.

Не применяется:

- ordinary length 3;
- OWN sequence;
- следующим story rounds.

---

# 45. Почему clue не является autoplay

Игрок всё равно обязан:

- нажать правильное направление;
- попасть в timing window.

Clue лишь снимает часть memory pressure один раз.

---

# 46. Другие Appearance perks

MODULE 07B НЕ реализует:

```text
GOOD_PROFILE
POCKET_MIRROR
CONTROL_PROFILE
SECOND_OUTFIT
ENCORE
PUBLIC_SIGNIFICANCE
```

Их owners другие.

---

# 47. Performance tiers

Для presentation определить простой visual tier по player Appearance:

```text
0..2  = BASIC
3..5  = STYLED
6..8+ = FLOURISH
```

Это НЕ difficulty modifier.

Tier используется только если presentation layer располагает подходящими visual variants.

---

# 48. Не требовать новых animation assets

MODULE 07B не блокируется отсутствием production dance animations.

Fallback должен быть рабочим.

---

# 49. Opponent move presentation

Для каждого `DanceMove` нужен читаемый visual.

Порядок fallback:

1. если CharacterActor имеет соответствующий optional alias:
   ```text
   dance_up
   dance_down
   dance_left
   dance_right
   ```
   использовать его;

2. иначе:
   - использовать `gesture`;
   - добавить маленький local transform/tween visual root/actor для направления;
   - вернуть transform после move.

---

# 50. Optional animation aliases

MODULE 07B может добавить optional semantic aliases:

```text
dance_up
dance_down
dance_left
dance_right
dance_react_win
dance_react_loss
```

к Character presentation.

Они НЕ становятся mandatory MODULE 04 baseline.

`has_animation()` fallback обязателен.

---

# 51. Fallback directional movement

Если специализированной animation нет, допустим simple presentation:

```text
LEFT  → небольшой local step/lean влево
RIGHT → небольшой local step/lean вправо
UP    → небольшой forward/up accent
DOWN  → небольшой back/down accent
```

Не менять gameplay collision transform навсегда.

Предпочтительно двигать только `VisualRoot`/presentation child.

---

# 52. Player presentation

FPS Player body не виден.

Во время `PLAYER_REPEAT` / `PLAYER_OWN`:

- не добавлять руки/ноги;
- не делать head bob;
- не трясти камеру на каждый beat.

Player feedback идёт через:

- input icons;
- timing pulse;
- HIT/PERFECT/MISS;
- реакцию rival;
- optional screen-edge pulse.

---

# 53. Rival reactions

После успешной own sequence:

- rival может проиграть `react`;
- сильная sequence — более заметная reaction позже.

После fail:

- rival сохраняет neutral/gesture presentation.

Не создавать production comedy animations сейчас.

---

# 54. Phases enum

Canonical semantic phases:

```text
OPPONENT_DEMO
PLAYER_REPEAT
OWN_PREVIEW
PLAYER_OWN
ROUND_FEEDBACK
FINISHED
```

Допустим:

```text
PRE_ROLL
```

как техническая subphase.

Не строить generic minigame state machine framework.

---

# 55. Demo input ignored

Во время:

```text
OPPONENT_DEMO
OWN_PREVIEW
ROUND_FEEDBACK
```

WASD для Dance input игнорируются.

Player movement всё равно disabled через MINIGAME mode.

---

# 56. UI

Functional UI показывает:

```text
Ты <score> : <score> Соперник
цель N

СМОТРИ
ПОВТОРИ
ТВОЙ ВЫХОД

sequence / current expected slots
beat pulse

HIT / PERFECT / MISS
series
```

---

# 57. Repeat UI

Во время opponent demo:

- current move icon visible.

Во время normal PLAYER_REPEAT:

- sequence скрыта;
- показываются только пустые slots/progress;
- completed moves могут отображаться как success/error marks.

При Rhythm clue:

- next direction icon кратко появляется до beat.

---

# 58. Own UI

Во время OWN:

- полная sequence остаётся видимой;
- current beat визуально выделяется.

---

# 59. Beat pulse

Нужен простой visual metronome:

- scale/pulse marker;
- вертикальная линия;
- ring;

Cursor выбирает.

Игрок должен понимать центр beat без аудио.

---

# 60. Audio

Можно использовать placeholder metronome:

```text
tick
```

если asset доступен.

Но Dance должен быть играбельным без звука.

Не искать музыку специально в MODULE 07B.

---

# 61. Sequence result feedback

После каждой sequence:

```text
УСПЕХ
ПРОВАЛ
```

коротко:

```text
~0.4 s
```

Не затягивать.

---

# 62. Round transition

После successful repeat:

```text
~0.4 s feedback
→ OWN_PREVIEW
```

После failed repeat:

```text
~0.4 s feedback
→ next round
```

если match не завершён.

---

# 63. Own preview duration

Canonical:

```text
1.20 seconds
```

Все move icons показываются одновременно.

---

# 64. VictoryGrade

Использовать ту же понятную score-difference схему, что Slap.

## target 3

```text
winner_difference == 1
=> CLOSE

winner_difference >= 2
=> CRUSHING
```

## target 5

```text
winner_difference <= 2
=> CLOSE

winner_difference >= 3
=> CRUSHING
```

---

# 65. Result

Dance возвращает:

```text
RivalCompetitionResult
```

только:

```text
PLAYER_WIN / PLAYER_LOSS
CLOSE / CRUSHING
debug_score_summary
```

Не меняет Authority.

---

# 66. debug_score_summary

Пример:

```text
"DANCE 3:1"
"DANCE 5:4"
```

---

# 67. Exactly-once

Concrete Dance minigame:

- emits `match_finished` один раз;
- после FINISHED input disabled.

Runner:

- submit-ит результат в RivalEncounters один раз.

Именно Runner является окончательной защитной границей от duplicate submit.

---

# 68. Runner busy

Если active Slap/Dance уже существует:

```text
RivalCompetitionRunner
```

не запускает второй.

Это programmer/state error.

Не создавать queue.

---

# 69. Unsupported types

До MODULE 07C/07D:

```text
SIGMA
MONEY
```

Runner должен явно:

- сообщить debug error / unsupported;
- НЕ возвращать fake WIN/LOSS;
- НЕ завершать encounter случайным результатом.

---

# 70. Error recovery unsupported

Если unsupported type всё же попал в runtime из-за bad content:

- active encounter не должен получить фальшивый result;
- state остаётся диагностируемым;
- debug сообщает issue.

Не придумывать gameplay fallback.

---

# 71. DanceMatch core

Как Slap, желательно отделить headless mechanics:

```text
DanceMatch
```

от Canvas UI.

Он хранит:

- scores;
- target;
- phase;
- generated sequences;
- expected beat;
- timing;
- errors;
- streak;
- perk usage;
- result.

---

# 72. Pure timing evaluator

Создать testable function semantic уровня:

```text
evaluate_move(
    expected_direction,
    actual_direction,
    input_time,
    beat_time,
    effective_window
)
```

Result:

```text
MISS
HIT
PERFECT
```

---

# 73. Result terminology

`MISS` включает:

- wrong direction;
- early;
- late;
- timeout.

Для debug можно хранить specific reason, но gameplay grade один:

```text
MISS
```

---

# 74. Timeout processing

Core tick должен автоматически закрывать missed beat после:

```text
beat_time + effective_window
```

и перейти к следующему.

Не ждать input бесконечно.

---

# 75. Frame independence

Timing использует elapsed seconds/delta.

Не frame count.

---

# 76. Pause

SceneTree pause останавливает:

- demo;
- beat clock;
- timers.

После resume timing продолжается, а не прыгает вперёд.

---

# 77. Focus loss

Не засчитывать key presses при loss focus.

Не auto-fail всю sequence из-за focus event.

Обычный time flow может быть pause-aware согласно выбранному Godot behavior.

---

# 78. Input echoes

Key echo/repeat не должен считаться как новые dance presses.

Принимать только:

```text
just pressed / non-echo key event
```

---

# 79. Test — runner migration

После pre-flight:

```text
SlapCompetitionHost class absent
RivalCompetitionRunner present
```

Slap integration tests используют Runner.

---

# 80. Test — production runner availability

После обычного startup runner существует и способен получить RivalCompetitionRequest.

Он не требует ручного добавления в конкретную test/world scene.

---

# 81. Test — runner routes Slap

```text
SLAP
→ SlapMinigame
```

07A regression PASS.

---

# 82. Test — runner routes Dance

```text
DANCE
→ DanceMinigame
```

---

# 83. Test — unsupported

```text
SIGMA/MONEY
```

до будущих modules не создают fake result.

---

# 84. Test — equal stats

```text
player appearance = 4
rival = 4
```

Expected:

```text
base_window = 0.18
allowed_errors = 1
```

---

# 85. Test — stronger player

```text
8 vs 4
difference +4
```

Expected:

```text
base_window = 0.22
allowed_errors = 2
```

---

# 86. Test — weaker player

```text
2 vs 6
difference -4
```

Expected:

```text
base_window = 0.14
allowed_errors = 0
```

---

# 87. Test — window clamps

```text
difference +100
=> 0.25

difference -100
=> 0.11
```

---

# 88. Test — sequence lengths

Ordinary:

```text
repeat = 3
own = 3
```

Story:

```text
repeat = 4
own = 4
```

---

# 89. Test — generation no triple

Generate many seeded sequences.

Ни одна не содержит:

```text
X, X, X
```

---

# 90. Test — correct timing

Expected:

```text
LEFT
beat 1.0
window 0.18
```

Input:

```text
LEFT at 1.10
```

=> HIT.

---

# 91. Test — perfect

Same:

```text
perfect_window = 0.063
```

Input near center => PERFECT.

---

# 92. Test — wrong direction

```text
expected LEFT
input RIGHT at exact beat
```

=> MISS.

---

# 93. Test — early

Input before:

```text
beat - window
```

=> MISS.

---

# 94. Test — timeout

No input until after deadline:

```text
MISS
```

current beat advances.

---

# 95. Test — input consumes beat

Первый press wrong.

Второй immediate correct:

- относится уже к следующему beat;
- не чинит предыдущий.

---

# 96. Test — sequence pass equal stats

Length 3, allowed errors 1.

```text
2 correct + 1 error
=> SUCCESS
```

---

# 97. Test — sequence fail

Length 3:

```text
1 correct + 2 errors
=> FAIL
```

из-за minimum correctness и error limit.

---

# 98. Test — repeat score

Successful repeat:

```text
player +1
```

и OWN запускается, если target не достигнут.

---

# 99. Test — failed repeat

```text
rival +1
```

OWN skipped.

---

# 100. Test — own success

Successful own:

```text
player +1
```

---

# 101. Test — own fail

```text
rival +1
```

---

# 102. Test — match end after repeat

Player before:

```text
2 / target 3
```

repeat success:

```text
3
```

match ends.

OWN не запускается.

---

# 103. Test — Staged Walk

Perk owned.

Sequence:

```text
3 correct in a row
streak = 3
then error
```

Expected:

```text
error count +1
streak = 2
perk used
```

Следующая error:

```text
normal streak = 0
```

---

# 104. Test — Staged Walk streak zero

Error at streak 0:

```text
perk not used
```

---

# 105. Test — streak timing bonus

```text
streak 4
=> +0.06 s
```

subject to final clamp.

---

# 106. Test — Rhythm in Body width

Equal stats:

```text
0.18 * 1.20 = 0.216
```

before streak bonus.

---

# 107. Test — Rhythm clue ordinary

Length 3:

```text
no complex clue
```

---

# 108. Test — Rhythm clue story

First story `PLAYER_REPEAT`:

```text
next-direction clue appears 0.25 s before beats
```

Second story repeat:

```text
no special clue
```

---

# 109. Test — grade ordinary

Exact:

```text
3:2 CLOSE
3:1 CRUSHING
2:3 CLOSE
1:3 CRUSHING
```

---

# 110. Test — grade story

Exact:

```text
5:4 CLOSE
5:3 CLOSE
5:2 CRUSHING
4:5 CLOSE
3:5 CLOSE
2:5 CRUSHING
```

---

# 111. Test — typed result

Dance returns proper enums.

---

# 112. Test — no Authority mutation

Dance code must not call:

```text
add_authority
lose_authority
mark_rival_defeated
```

---

# 113. Test — end-to-end win

```text
Rival
→ DANCE
→ Runner
→ deterministic Dance win
→ RivalEncounters
→ Authority reward
```

---

# 114. Test — end-to-end loss

Same with loss:

```text
RivalEncounters
→ Authority -1
```

Dance itself does not perform loss.

---

# 115. Test — Player control

During Dance:

```text
MINIGAME
```

After:

```text
return mode restored
```

---

# 116. Test — Runner cleanup

After match:

```text
active_minigame == null
busy == false
```

No orphan UI/timers.

---

# 117. Regressions

Run:

```text
MODULE 02
MODULE 03
MODULE 04
MODULE 05
MODULE 06
MODULE 07A
MODULE 07B
FPS
```

---

# 118. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
```

В contracts уточнить фактическую Dance implementation для:

```text
APPEARANCE_STAGED_WALK
APPEARANCE_RHYTHM_IN_BODY
```

---

# 119. Что MODULE 07B НЕ реализует

Не реализовывать:

- Sigma;
- Money;
- dating dance event;
- фотосессию;
- модельный проход;
- final character animation polish;
- music system;
- crowd system;
- scoring based on audience;
- outfit logic;
- Appearance perks других owners.

---

# 120. Definition of Done

MODULE 07B завершён только если:

- [ ] SlapCompetitionHost удалён/заменён;
- [ ] существует единый RivalCompetitionRunner;
- [ ] production Runner доступен across scenes;
- [ ] Runner использует один canonical execution seam;
- [ ] SLAP route работает;
- [ ] DANCE route работает;
- [ ] SIGMA/MONEY пока explicit unsupported;
- [ ] MODULE 06 fake runner tests сохранены;
- [ ] Dance использует W/S/A/D без новых duplicate actions;
- [ ] OPPONENT_DEMO работает;
- [ ] PLAYER_REPEAT работает;
- [ ] OWN_PREVIEW работает;
- [ ] PLAYER_OWN работает;
- [ ] ordinary target = 3;
- [ ] story target = 5;
- [ ] sequence lengths 3/4 exact;
- [ ] beat interval = 0.80;
- [ ] base timing formula exact;
- [ ] allowed error thresholds exact;
- [ ] HIT/PERFECT/MISS работают;
- [ ] wrong direction/early/timeout работают;
- [ ] streak window bonus работает;
- [ ] Staged Walk реализован;
- [ ] Rhythm in Body window bonus реализован;
- [ ] Rhythm in Body first complex clue реализован;
- [ ] score flow repeat/own exact;
- [ ] CLOSE/CRUSHING exact;
- [ ] typed result;
- [ ] exactly-once submit;
- [ ] no Authority logic inside Dance;
- [ ] current 3D scene остаётся context;
- [ ] character presentation имеет fallback без новых assets;
- [ ] 07A regression PASS;
- [ ] предыдущие regressions PASS;
- [ ] MODULE 07C не реализован заранее.

---

# 121. Порядок выполнения Cursor

## Step 1 — Runner migration

Сначала:

```text
SlapCompetitionHost
→ RivalCompetitionRunner
```

Не трогать Slap mechanics.

Прогнать 07A.

---

## Step 2 — Runner production lifetime

Убедиться, что runner существует в обычном runtime, а не только tests.

---

## Step 3 — Dance core

Создать headless:

```text
DanceMatch
```

с phases/generation/timing/scores.

---

## Step 4 — Dance UI

Создать minimal readable overlay.

---

## Step 5 — presentation fallback

Подключить rival CharacterActor, если доступен.

Не блокироваться на отсутствии специальных animations.

---

## Step 6 — perks

Реализовать только:

```text
STAGED_WALK
RHYTHM_IN_BODY
```

---

## Step 7 — Runner route

Добавить:

```text
DANCE
```

в explicit route.

---

## Step 8 — integration

End-to-end Rival→Dance→Rival.

---

## Step 9 — tests

Прогнать sections 79–116.

---

## Step 10 — regressions

Все предыдущие modules.

---

## Step 11 — docs

Обновить terminology и perk contracts.

---

# 122. Формат финального отчёта Cursor

## Runner cleanup

Подтвердить:

```text
SlapCompetitionHost removed
RivalCompetitionRunner is canonical
```

Указать runtime lifetime/registration.

## Slap regression

Результат MODULE 07A после migration.

## Dance architecture

Core/UI/presentation separation.

## Dance rules

Подтвердить:

```text
demo
repeat
own
target 3/5
sequence 3/4
beat 0.80
```

## Difficulty

Подтвердить exact window/error rules.

## Perks

Подтвердить:

```text
Staged Walk
Rhythm in Body
```

## Integration

```text
Rival → Runner → Dance → Rival
```

## Validation

07B tests + regressions.

## Files changed

Основные файлы.

## Product questions

Если нет:

```text
None.
```

---

# 123. Запрет продолжения

После успешного MODULE 07B:

**НЕ начинать MODULE 07C — Sigma Pressure.**

Остановиться и дождаться отдельной спецификации.
