# MODULE 07C — SIGMA PRESSURE / СИГМА-ДАВЛЕНИЕ

**Проект:** Date Factory  
**Модуль:** 07C — Rival Minigame: Sigma Pressure  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать третье мужское состязание — удержание невозмутимого выражения под давлением и помехами — и подключить его через единый `RivalCompetitionRunner`  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущие модули:** MODULE 07A — Slap, MODULE 07B — Dance

---

# 0. PRE-FLIGHT — RUNNER TERMINOLOGY

Перед Sigma проверить архитектурный cleanup из MODULE 07B.

Canonical execution path:

```text
RivalEncounters
→ RivalCompetitionRunner
→ concrete minigame
→ RivalCompetitionResult
→ RivalEncounters
```

Production-классов/документации с термином:

```text
SlapCompetitionHost
DanceCompetitionHost
SigmaCompetitionHost
```

быть не должно.

`Host` в этой архитектуре не используется.

Если MODULE 07B ещё не успел выполнить migration, сделать её сейчас ДО Sigma.

---

# 1. Цель MODULE 07C

После завершения должен работать полный flow:

```text
Rival Encounter
→ competition_type = SIGMA
→ RivalCompetitionRunner
→ SigmaMinigame
→ continuous composure gameplay
→ PLAYER_WIN / PLAYER_LOSS
→ CLOSE / CRUSHING
→ RivalEncounters
```

Sigma должна ощущаться принципиально иначе, чем Slap и Dance.

Игрок:

> не ловит отдельный момент и не повторяет последовательность, а несколько секунд непрерывно удерживает «лицо» в допустимой зоне, компенсируя давление соперника мышью.

---

# 2. Фантазия механики

На экране есть горизонтальная шкала невозмутимости.

```text
-1.0                0                 +1.0
|-------------------|-------------------|
                    ^
                   лицо
```

Индикатор выражения лица постоянно уводит в сторону внешнее давление.

Игрок движением мыши вправо/влево компенсирует его и старается удерживать индикатор внутри центральной допустимой зоны.

Соперник периодически создаёт заранее читаемые сильные помехи.

---

# 3. Что Cursor не имеет права добавлять

Не добавлять:

- facial webcam tracking;
- реальное распознавание лица;
- моргание через камеру;
- microphone input;
- aim/shooter механику;
- health;
- stamina;
- random success chance;
- QTE sequences;
- WASD movement;
- сложный physics pendulum;
- 2D rigid bodies;
- gaze raycast;
- eye IK;
- emotion classifier;
- dialogue choices;
- generic balance-minigame framework.

---

# 4. Input

Основное управление:

```text
Mouse X
```

Движение мыши:

```text
влево  → indicator влево
вправо → indicator вправо
```

Камера во время Sigma НЕ вращается.

---

# 5. Special inputs

Использовать уже существующие:

```text
minigame_special_1 = Q
minigame_special_2 = R
```

Sigma mapping:

```text
Q = Карманное зеркало
R = Молчание длиннее нормы
```

если соответствующие perks куплены.

---

# 6. Control mode

На весь Sigma match:

```text
PlayerControlMode.MINIGAME
```

Отключены:

- FPS movement;
- jump;
- interact;
- camera mouse look.

Mouse остаётся captured.

Raw relative mouse movement передаётся SigmaMinigame.

---

# 7. World presentation

Мини-игра происходит в текущем 3D-мире.

Не загружать отдельную арену.

Предпочтительно:

- rival остаётся напротив игрока;
- камера фиксируется на его лице/`LookAnchor`;
- поверх мира появляется Sigma UI;
- rival может использовать placeholder `idle/gesture/react`.

Не создавать cinematic framework.

---

# 8. Match score

Как у остальных rival minigames.

## Ordinary rival

```text
target_score = 3
```

## Story rival

```text
target_score = 5
```

---

# 9. Match состоит из sections

Каждый score attempt — отдельная:

```text
SIGMA SECTION
```

Section длится максимум:

```text
5.0 seconds
```

Игрок пытается набрать нужное время стабильного удержания раньше timeout.

---

# 10. Required hold

Чтобы выиграть section:

```text
required_hold = 3.0 seconds
```

Пока indicator внутри normal zone:

```text
hold_progress += delta
```

Пока indicator вне normal zone:

```text
hold_progress не растёт
```

---

# 11. Section result

Если:

```text
hold_progress >= 3.0
```

до section timeout:

```text
player_score += 1
```

Если прошло:

```text
5.0 seconds
```

и progress < 3.0:

```text
rival_score += 1
```

---

# 12. Match end mid-section

После начисления очка section сразу завершается.

Если кто-либо достиг target score:

```text
match FINISHED
```

Новая section не запускается.

---

# 13. Indicator coordinate

Внутренняя координата:

```text
composure ∈ [-1.0, +1.0]
```

Начало каждой section:

```text
composure = 0.0
```

---

# 14. Mouse control

Canonical base sensitivity:

```text
mouse_control = 0.0025 normalized units / mouse pixel
```

На relative mouse motion:

```text
composure += mouse_delta_x * 0.0025
```

После update:

```text
clamp(-1.0, +1.0)
```

Не использовать FPS mouse sensitivity.

Sigma имеет собственную mechanical sensitivity.

---

# 15. Difficulty stat

Использовать snapshot:

```text
difference = player_aura - rival_aura
```

из `RivalCompetitionRequest`.

Не читать GameState Aura во время RUNNING.

---

# 16. Normal zone half-width

Formula:

```text
normal_half_width =
clamp(
    0.30 + difference * 0.015,
    0.20,
    0.40
)
```

Значит normal zone:

```text
zone_center ± normal_half_width
```

---

# 17. Examples width

```text
difference = 0
=> ±0.30

difference = +4
=> ±0.36

difference = -4
=> ±0.24
```

---

# 18. Base pressure strength

External drift:

```text
pressure_strength =
clamp(
    0.32 - difference * 0.020,
    0.18,
    0.48
)
```

Units:

```text
normalized units / second
```

---

# 19. Examples pressure

```text
difference = 0
=> 0.32

difference = +4
=> 0.24

difference = -4
=> 0.40
```

Большая Aura:

- расширяет допустимую зону;
- уменьшает внешнее давление.

---

# 20. No hidden probability

После расчёта:

```text
normal_half_width
pressure_strength
```

результат определяется только:

- mouse input;
- заранее сформированными disturbance events;
- perk effects.

Запрещено:

```text
randf() < aura_success_probability
```

---

# 21. Baseline pressure direction

На старте каждой section выбирается:

```text
LEFT
или
RIGHT
```

с равной вероятностью.

Направление baseline pressure показывается визуальной стрелкой.

В течение section baseline direction не меняется.

Это делает механику читаемой.

---

# 22. Baseline drift

Каждый frame:

```text
composure += pressure_direction * pressure_strength * delta
```

плюс mouse compensation.

---

# 23. Zone center wobble

Normal zone не абсолютно неподвижна.

Базовая небольшая «психологическая нестабильность»:

```text
rival_wobble_amplitude = 0.035
```

Zone center:

```text
zone_center =
sin(section_time * TAU * 0.45 + phase) * 0.035
+
observer_wobble
```

Wobble плавный и визуально виден.

---

# 24. Observer pressure

Sigma может запускаться с:

```text
observers_present: bool
```

Это presentation/mechanical launch option, не новое поле `RivalDefinition`.

Current default:

```text
ordinary rival → false
story rival    → true
```

Future authored encounter может явно override это значение.

---

# 25. Observer wobble

Если observers present:

```text
observer_wobble =
sin(section_time * TAU * 0.80 + observer_phase) * 0.050
```

Если observers отсутствуют:

```text
0
```

---

# 26. Почему это отдельный launch option

Не добавлять:

```text
has_crowd
```

в каждый RivalDefinition.

Толпа относится к конкретной постановке encounter, а не к личности самца.

---

# 27. Disturbances

Кроме baseline pressure rival создаёт короткие сильные disturbance events.

Disturbance:

1. заранее telegraph;
2. затем короткое усиленное давление;
3. затем возврат к baseline.

---

# 28. Disturbance count

## Ordinary section

```text
1 disturbance
```

## Story section

```text
2 disturbances
```

---

# 29. Disturbance timing

Disturbances размещаются внутри section так, чтобы:

```text
first disturbance >= 0.80 s
last disturbance start <= 3.80 s
```

При двух events между starts:

```text
>= 1.20 s
```

Использовать deterministic RNG support для tests.

---

# 30. Disturbance direction

Каждый event выбирает:

```text
LEFT
RIGHT
```

Направление telegraph показывается явно.

Может совпасть или не совпасть с baseline direction.

---

# 31. Telegraph

Перед disturbance:

```text
0.35 s
```

UI показывает:

- directional arrow;
- короткий pulse rival;
- impending pressure.

Во время telegraph усиленное давление ещё не применяется.

---

# 32. Disturbance active duration

```text
0.55 s
```

Во время active:

```text
external pressure =
baseline pressure
+
disturbance_direction * pressure_strength * 1.65
```

То есть disturbance — дополнительный push, а не полная замена baseline.

---

# 33. Error event

Sigma `hold error` возникает при переходе:

```text
indicator inside normal zone
→ indicator outside normal zone
```

Одна непрерывная excursion снаружи считается одной error.

Пока игрок остаётся снаружи, новые errors каждую frame не создаются.

---

# 34. Error penalty

При обычной error:

```text
hold_progress -= 0.65 seconds
```

Clamp:

```text
>= 0
```

Затем игрок может вернуть indicator внутрь и снова продолжить накапливать progress.

---

# 35. Почему нет instant fail

Механика должна позволять:

- ошибиться;
- восстановиться;
- продолжить давление.

Section проигрывается только по timeout.

Это лучше соответствует «держать лицо», чем одна QTE-ошибка = поражение.

---

# 36. Time outside

Пока indicator снаружи:

- progress не растёт;
- после initial error нет дополнительного drain.

Не делать двойное наказание:

```text
fixed penalty + continuous drain
```

---

# 37. Perfect zone

Внутри normal zone существует центральная perfect zone.

```text
perfect_half_width =
normal_half_width * 0.40
```

Она имеет тот же:

```text
zone_center
```

---

# 38. Perfect time

Пока indicator внутри perfect zone:

```text
perfect_time += delta
```

---

# 39. Perfect section

Section считается:

```text
PERFECT SECTION
```

если одновременно:

```text
section won
unprotected_error_count == 0
perfect_time >= 1.80 seconds
```

---

# 40. Protected error всё равно не perfect

Если `Не моргать первым` защитил progress от первой ошибки:

- error всё равно произошла;
- `unprotected_error_count` в данном случае можно не увеличивать;
- но отдельный:
  ```text
  total_error_count
  ```
  увеличивается.

Perfect condition требует:

```text
total_error_count == 0
```

То есть protected error не позволяет назвать section идеальной.

---

# 41. Normal section score

Successful normal section:

```text
+1 player point
```

Perfect section без специальных bonus perks:

```text
тоже +1
```

Perfect нужен для perk interactions и stronger feedback.

---

# 42. Section transition

После score:

```text
~0.35 s
```

короткий feedback:

```text
ДАВЛЕНИЕ ВЫДЕРЖАНО
или
СОРВАЛСЯ
```

затем новая section, если match не закончился.

---

# 43. VictoryGrade

Использовать ту же score-difference модель.

## target 3

```text
difference == 1 → CLOSE
difference >= 2 → CRUSHING
```

## target 5

```text
difference <= 2 → CLOSE
difference >= 3 → CRUSHING
```

---

# 44. Perk snapshot

На старте Sigma snapshot-нуть relevant perks:

```text
APPEARANCE_POCKET_MIRROR
APPEARANCE_CONTROL_PROFILE

AURA_DONT_BLINK_FIRST
AURA_SILENCE_LONGER
AURA_REVERSE_PRESSURE
AURA_ATMOSPHERIC_INFLUENCE
```

Mid-match debug purchase не меняет правила текущего match.

---

# 45. `APPEARANCE_POCKET_MIRROR` — Карманное зеркало

Один раз за Sigma match.

Input:

```text
Q / minigame_special_1
```

Можно активировать в любой момент active section.

Duration:

```text
2.50 seconds
```

---

# 46. Mirror effect — stable zone

Пока mirror active:

```text
zone_center = 0.0
```

То есть временно отключаются:

- rival wobble;
- observer wobble.

---

# 47. Mirror effect — wider zone

Пока mirror active:

```text
normal_half_width *= 1.20
```

Final clamp:

```text
<= 0.46
```

Perfect zone пересчитывается от увеличенной normal zone.

---

# 48. Mirror does not remove pressure

Baseline drift и active disturbances продолжаются.

Mirror:

> помогает контролировать выражение, а не останавливает соперника.

---

# 49. Mirror usage

После Q:

```text
mirror_used = true
```

сразу.

Повторно в match нельзя.

Если match закончился раньше 2.5 s:

- оставшееся время пропадает.

---

# 50. `APPEARANCE_CONTROL_PROFILE` — Контрольный профиль

Работает только при наличии Pocket Mirror по perk tree.

Если section:

```text
PERFECT
```

и в момент достижения:

```text
hold_progress >= required_hold
```

Mirror всё ещё активен:

```text
player gains +1 additional point
```

---

# 51. Control Profile total score

Perfect section while mirror active:

```text
normal section point = +1
Control Profile       = +1

total = +2
```

---

# 52. Control Profile once per match naturally

Pocket Mirror используется один раз.

Следовательно bonus может сработать максимум на одной section.

Не хранить отдельный persistent charge.

---

# 53. `AURA_DONT_BLINK_FIRST` — Не моргать первым

Один раз за Sigma match.

Первая hold error:

```text
НЕ уменьшает hold_progress
```

То есть вместо:

```text
hold_progress -= 0.65
```

получаем:

```text
hold_progress unchanged
```

---

# 54. Don't Blink still error

Первая protected error:

- `total_error_count += 1`;
- perfect section больше невозможна;
- indicator всё равно находится снаружи до возврата;
- progress не растёт снаружи.

Perk защищает накопленное, а не превращает ошибку в success.

---

# 55. Don't Blink usage at zero progress

Если первая error произошла при:

```text
hold_progress == 0
```

perk всё равно считается использованным.

Контракт:

> первая ошибка не уменьшает progress.

Она является первой ошибкой независимо от того, было ли что терять.

---

# 56. `AURA_SILENCE_LONGER` — Молчание длиннее нормы

Один раз за Sigma match.

Input:

```text
R / minigame_special_2
```

Duration:

```text
2.00 seconds
```

---

# 57. Silence effect

Пока active:

- новые disturbance telegraphs не начинаются;
- pending disturbance clock заморожен;
- active disturbance, если уже начался до нажатия R, завершается нормально;
- baseline pressure продолжается;
- zone wobble продолжается.

Это именно:

> соперник перестаёт создавать дополнительные помехи, но базовое удержание лица остаётся.

---

# 58. Silence and scheduled disturbance

Если disturbance был запланирован на период Silence:

- он НЕ пропускается навсегда;
- его timer продолжает отсчёт после Silence.

Не сдвигать section timeout.

---

# 59. `AURA_REVERSE_PRESSURE` — Обратное давление

Perk создаёт локальный:

```text
reverse_pressure_armed
```

---

# 60. Successful disturbance survival

Disturbance считается выдержанной, если:

от начала ACTIVE disturbance до:

```text
0.75 s после её окончания
```

игрок:

```text
не создал ни одной hold error
```

---

# 61. Arm Reverse Pressure

После successful disturbance survival:

```text
reverse_pressure_armed = true
```

Если уже true:

- новые successful survivals не stack-ятся;
- остаётся один pending bonus.

---

# 62. Consume Reverse Pressure

Следующая `PERFECT SECTION`:

```text
player gains +1 additional point
reverse_pressure_armed = false
```

---

# 63. Reverse Pressure can trigger same section

Если disturbance была успешно выдержана достаточно рано, а текущая section затем закончилась PERFECT:

```text
bonus применяется к этой section
```

Это допустимо.

---

# 64. Reverse Pressure + Control Profile stacking

Разрешено.

Если:

- section PERFECT;
- Mirror active at completion;
- Control Profile owned;
- Reverse Pressure armed;

то:

```text
normal point            +1
Control Profile         +1
Reverse Pressure        +1

total                   +3
```

Это сильная поздняя синергия.

Match заканчивается сразу, если target достигнут.

---

# 65. `AURA_ATMOSPHERIC_INFLUENCE` — Атмосферное влияние

Если observers present и perk НЕ куплен:

```text
observer_wobble active
```

Если perk куплен:

```text
observer_wobble = 0
```

---

# 66. Atmospheric Influence does not remove rival pressure

Perk НЕ убирает:

- baseline pressure;
- rival wobble;
- disturbances.

Он убирает только дополнительное осложнение от наблюдателей.

---

# 67. Atmospheric Influence without observers

Если:

```text
observers_present == false
```

perk ничего не меняет.

Это нормально.

---

# 68. Access perk

`AURA_PRESENCE_REGISTERED` уже используется MODULE 06 для открытия `SIGMA`.

SigmaMinigame не должен повторно запрещать запуск.

Если request уже пришёл:

```text
competition_type == SIGMA
```

значит access gate пройден.

---

# 69. Other Aura perks

MODULE 07C НЕ реализует:

```text
AURA_RIGHT_TO_SAY_NOTHING
AURA_SHE_ALREADY_STARTED
AURA_LOCAL_SIGNIFICANCE
```

Их owners — Rival/Dating.

---

# 70. UI

Functional UI показывает:

```text
Ты <score> : <score> Соперник
цель N

Шкала -1..+1
Indicator
Normal zone
Perfect zone
Current pressure direction

hold progress 0..3 sec
section time 0..5 sec

disturbance telegraph

Q — Карманное зеркало
R — Молчание длиннее нормы
```

только когда соответствующие perks есть.

---

# 71. Labels

Основной phase label:

```text
ДЕРЖИ ЛИЦО
```

Disturbance:

```text
ДАВЛЕНИЕ
```

Perfect feedback:

```text
НЕ ДРОГНУЛ
```

Обычный success:

```text
ВЫДЕРЖАЛ
```

Fail:

```text
СОРВАЛСЯ
```

Можно слегка изменить формулировки при UI polish, но не делать meme-text прямо в mechanic core.

---

# 72. Visual distinguishability

UI не должен полагаться только на цвет.

Normal zone и perfect zone отличаются:

- шириной;
- border/shape;
- brightness/pattern.

Pressure direction имеет стрелку.

---

# 73. Telegraph clarity

Disturbance direction должна быть понятна ДО усиленного push.

Никаких внезапных невидимых impulses.

Это соответствует общему правилу игры:

> player должен понимать правило до наказания.

---

# 74. Rival presentation

Во время baseline:

```text
idle
```

На telegraph:

```text
gesture
```

На player section fail:

```text
gesture / stronger reaction
```

На player success:

```text
react
```

Fallback через MODULE 04.

Не требовать новых facial animations.

---

# 75. Camera

Camera фиксирована на rival.

Не использовать:

- camera shake на baseline;
- head bob;
- forced roll.

На disturbance допустим очень маленький UI-only pulse.

Не двигать FPS camera так, чтобы это мешало mouse compensation.

---

# 76. SigmaMinigame architecture

Canonical area:

```text
res://minigames/sigma/
```

Ожидаемо:

```text
sigma_minigame.tscn
sigma_minigame.gd
sigma_match.gd
test/
```

Как Slap/Dance, предпочтительно:

```text
SigmaMatch = headless mechanics
SigmaMinigame = UI/input/presentation
```

---

# 77. SigmaMatch state

Минимально хранит:

```text
player_score
rival_score
target_score

section_time
hold_progress
perfect_time

composure

normal_half_width
pressure_strength
pressure_direction

disturbance schedule/state

total_error_count

mirror state
silence state
reverse_pressure_armed
perk usage

finished
```

---

# 78. No physics nodes for mechanics

Composure — float math.

Не использовать:

- RigidBody2D;
- CharacterBody2D;
- collision shapes

для indicator.

---

# 79. Deterministic core

Headless tests должны иметь:

- deterministic RNG seed;
- manual tick;
- manual mouse delta;
- explicit special activation.

---

# 80. Disturbance scheduler pause

Silence должен замораживать только:

```text
time_to_next_disturbance
```

не:

```text
section_time
hold_progress
match time
```

---

# 81. Perfect tracking under moving zone

Perfect check использует актуальный:

```text
zone_center
normal_half_width
```

каждый frame.

Mirror может мгновенно изменить zone geometry.

---

# 82. Mouse delta consumption

При входе в MINIGAME:

- сбросить накопленный mouse delta;
- первый frame не должен прыгнуть из-за movement, совершённого перед capture.

После выхода:

- Sigma больше не читает mouse events.

---

# 83. Pointer clamp edges

Если composure достигает:

```text
-1
или
+1
```

indicator просто clamp-ится.

Нет instant fail.

Игрок может вернуть его обратно.

---

# 84. Section start grace

Первые:

```text
0.35 s
```

section baseline pressure работает на:

```text
50%
```

силы.

После:

```text
100%
```

Это даёт игроку короткое время увидеть направление.

Disturbance в grace period не начинается.

---

# 85. Section reset

На новой section reset:

```text
composure = 0
hold_progress = 0
perfect_time = 0
section_time = 0
error counters = 0
pressure direction new
disturbances new
```

Не reset:

```text
match score
one-per-match perk usage
reverse_pressure_armed
```

---

# 86. Reverse Pressure across sections

Если armed и предыдущая section закончилась НЕ perfect:

```text
armed сохраняется
```

до следующей perfect section или конца match.

---

# 87. Mirror does not carry across sections

Если Mirror active и section заканчивается:

- remaining mirror duration МОЖЕТ продолжиться в следующую section только если время ещё осталось.

Это match-level timed effect, а не section-level.

Runner/UI должны корректно сохранить timer.

---

# 88. Silence carry

То же:

если Silence остаётся активен после завершения section:

- remaining duration продолжается в следующей.

---

# 89. New section while timed perk active

New section:

- mirror current remaining time продолжает stabilizing zone;
- silence current remaining time продолжает suppress new disturbances.

Не reset timers.

---

# 90. Grade calculation

Использовать общий helper, если после 07A/07B уже существует чистый shared helper для score grade.

Если helper отсутствует:

- можно создать маленькую generic utility:
  ```text
  RivalScoreGrade
  ```
  только для одинаковой формулы `3/5`.

Не создавать generic minigame base class ради одного helper.

---

# 91. Runner routing

После MODULE 07C:

```text
SLAP  → implemented
DANCE → implemented
SIGMA → implemented
MONEY → explicit unsupported
```

---

# 92. Exactly-once result

Sigma emits:

```text
match_finished(result)
```

ровно один раз.

`RivalCompetitionRunner` submit-ит один раз.

Concrete minigame после FINISHED не изменяет score.

---

# 93. Unsupported Money

Не использовать fake result для MONEY.

MODULE 07D позже добавит route.

---

# 94. Test — equal stats

```text
player aura = 4
rival aura = 4
```

Expected:

```text
normal_half_width = 0.30
pressure_strength = 0.32
```

---

# 95. Test — stronger player

```text
8 vs 4
difference +4
```

Expected:

```text
half_width = 0.36
pressure = 0.24
```

---

# 96. Test — weaker player

```text
2 vs 6
difference -4
```

Expected:

```text
half_width = 0.24
pressure = 0.40
```

---

# 97. Test — clamps

Extreme:

```text
difference +100
=> half_width 0.40
=> pressure 0.18

difference -100
=> half_width 0.20
=> pressure 0.48
```

---

# 98. Test — mouse control

Starting:

```text
composure = 0
```

Mouse delta:

```text
+100 px
```

before pressure:

```text
+0.25
```

subject to clamp.

---

# 99. Test — hold accumulation

Inside zone for:

```text
1.0 s
```

Expected:

```text
hold_progress = 1.0
```

---

# 100. Test — outside

Outside for:

```text
0.5 s
```

after initial error:

- no extra continuous drain;
- progress does not increase.

---

# 101. Test — error penalty

Before:

```text
hold_progress = 2.0
```

Cross outside.

After:

```text
1.35
```

---

# 102. Test — excursion one error

Remain outside for many frames.

Expected:

```text
only one -0.65 penalty
```

Return inside, then exit again:

```text
new error
```

---

# 103. Test — section success

Accumulate:

```text
3.0 s
```

before 5.0.

Expected:

```text
player +1
```

---

# 104. Test — section timeout

At:

```text
5.0 s
```

progress:

```text
2.9
```

Expected:

```text
rival +1
```

---

# 105. Test — perfect section

Win with:

```text
0 errors
perfect_time >=1.80
```

Expected:

```text
perfect = true
```

---

# 106. Test — perfect fails on any error

Even protected Don't Blink error:

```text
perfect = false
```

---

# 107. Test — ordinary disturbances

Each section:

```text
1
```

---

# 108. Test — story disturbances

Each section:

```text
2
```

spacing constraints respected.

---

# 109. Test — telegraph

No disturbance multiplier before:

```text
0.35 s telegraph
```

---

# 110. Test — disturbance pressure

During active:

```text
baseline
+
1.65 * pressure_strength in disturbance direction
```

---

# 111. Test — observer default

Ordinary:

```text
false
```

Story:

```text
true
```

unless launch override.

---

# 112. Test — Mirror activation

Q owned.

Expected:

```text
2.5 s active
zone_center = 0
normal_half_width *1.20
```

---

# 113. Test — Mirror no pressure cancellation

While active:

```text
baseline drift still moves composure
disturbance still pushes
```

---

# 114. Test — Control Profile

Perfect section finishes while Mirror active.

Expected:

```text
+2 total section score
```

without Reverse Pressure.

---

# 115. Test — Control Profile mirror expired

Perfect section after Mirror ended:

```text
only +1
```

---

# 116. Test — Don't Blink

First error at:

```text
progress = 2.0
```

Expected:

```text
progress stays 2.0
perk used
total error +=1
```

Second error:

```text
-0.65
```

---

# 117. Test — Silence

Activate R.

For 2.0 s:

- no new disturbance telegraph starts;
- baseline continues;
- section clock continues.

---

# 118. Test — active disturbance + Silence

Activate R during already active disturbance.

Expected:

- current disturbance finishes;
- then no new event until Silence ends.

---

# 119. Test — scheduled disturbance resumes

A future disturbance scheduled before Silence:

- not deleted;
- countdown resumes afterward.

---

# 120. Test — Reverse Pressure survive

Disturbance active + 0.75 s post-window.

No error.

Expected:

```text
reverse_pressure_armed = true
```

---

# 121. Test — Reverse Pressure fail survival

Any error in survival window:

```text
not armed
```

---

# 122. Test — Reverse Pressure consume

Armed.

Next perfect section:

```text
+2 total
```

without Control Profile.

Then:

```text
armed = false
```

---

# 123. Test — triple perk stack

Perfect section:

- Mirror active;
- Control Profile;
- Reverse Pressure armed.

Expected:

```text
+3 total
```

---

# 124. Test — Atmospheric Influence

Story/observers true.

Without perk:

```text
observer wobble active
```

With perk:

```text
observer wobble exactly 0
```

rival wobble remains.

---

# 125. Test — Atmospheric no observers

Perk on/off produces no observer mechanic difference.

---

# 126. Test — score target

Ordinary:

```text
3
```

Story:

```text
5
```

---

# 127. Test — CLOSE/CRUSHING

Same exact matrix as 07A/07B.

---

# 128. Test — Runner routes Sigma

```text
SIGMA
→ SigmaMinigame
```

---

# 129. Test — Money unsupported

```text
MONEY
```

still does not return fake result.

---

# 130. Test — end-to-end win

```text
Rival
→ SIGMA
→ Runner
→ deterministic Sigma win
→ RivalEncounters
→ authority reward
```

---

# 131. Test — end-to-end loss

Sigma returns loss only.

RivalEncounters applies:

```text
Authority -1
```

or MODULE 06 Heroic Defeat logic if its conditions apply.

---

# 132. Heroic Defeat relevant stat

MODULE 06 must naturally use:

```text
AURA
```

for Sigma because Competition mapping already says:

```text
SIGMA → AURA
```

Sigma itself does nothing special.

---

# 133. No Authority mutation

Static/code search Sigma module:

```text
add_authority = absent
lose_authority = absent
mark_rival_defeated = absent
```

---

# 134. Player control test

During:

```text
MINIGAME
```

After runner cleanup:

```text
previous mode restored
```

---

# 135. Runner cleanup

After Sigma:

```text
active_minigame == null
busy == false
```

---

# 136. Pause regression

Global pause freezes:

- section clock;
- pressure;
- disturbance clock;
- timed perks.

Resume continues cleanly.

---

# 137. Previous regressions

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
FPS
```

---

# 138. Documentation

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
```

В perk contracts зафиксировать фактические значения:

```text
Pocket Mirror
Control Profile
Don't Blink First
Silence Longer
Reverse Pressure
Atmospheric Influence
```

---

# 139. Что MODULE 07C НЕ реализует

Не реализовывать:

- Money contest;
- Dating Aura events;
- greeting silence;
- clue system;
- Local Significance;
- Right To Say Nothing Rival override;
- crowd NPC AI;
- facial animation;
- actual blinking;
- camera tracking;
- final SFX/VFX polish.

---

# 140. Definition of Done

MODULE 07C завершён только если:

- [ ] canonical `RivalCompetitionRunner` используется;
- [ ] host terminology отсутствует;
- [ ] SIGMA route работает;
- [ ] MONEY остаётся unsupported;
- [ ] Sigma работает поверх текущего 3D-world;
- [ ] mouse X управляет composure;
- [ ] FPS camera не вращается;
- [ ] composure normalized -1..+1;
- [ ] section max = 5.0 s;
- [ ] required hold = 3.0 s;
- [ ] ordinary target = 3;
- [ ] story target = 5;
- [ ] Aura width formula exact;
- [ ] Aura pressure formula exact;
- [ ] baseline pressure direction читаем;
- [ ] zone wobble работает;
- [ ] observer pressure работает;
- [ ] disturbances telegraphed;
- [ ] ordinary disturbance count =1;
- [ ] story count =2;
- [ ] error penalty =0.65 s;
- [ ] no continuous outside drain;
- [ ] perfect zone =40% half-width;
- [ ] perfect threshold =1.80 s and zero errors;
- [ ] Pocket Mirror реализован;
- [ ] Control Profile реализован;
- [ ] Don't Blink First реализован;
- [ ] Silence Longer реализован;
- [ ] Reverse Pressure реализован;
- [ ] Atmospheric Influence реализован;
- [ ] perk stacking exact;
- [ ] typed result;
- [ ] exactly-once submit;
- [ ] no Authority logic inside Sigma;
- [ ] end-to-end Rival→Sigma→Rival работает;
- [ ] 07A regression PASS;
- [ ] 07B regression PASS;
- [ ] previous regressions PASS;
- [ ] MODULE 07D не реализован заранее.

---

# 141. Порядок выполнения Cursor

## Step 1 — Runner verification

Проверить cleanup MODULE 07B:

```text
RivalCompetitionRunner canonical
no *CompetitionHost
```

---

## Step 2 — Headless Sigma core

Сначала:

```text
composure
pressure
zone
hold progress
errors
section result
score
```

без perks.

---

## Step 3 — Disturbances

Добавить deterministic schedule + telegraph.

---

## Step 4 — Perfect logic

Добавить perfect zone/time.

---

## Step 5 — UI/input

Подключить relative mouse input и readable overlay.

---

## Step 6 — Perks

В порядке:

1. Don't Blink First
2. Pocket Mirror
3. Control Profile
4. Silence Longer
5. Reverse Pressure
6. Atmospheric Influence

---

## Step 7 — Presentation fallback

CharacterActor + fixed camera.

---

## Step 8 — Runner route

Добавить:

```text
SIGMA
```

---

## Step 9 — End-to-end

Проверить Rival→Sigma→Rival.

---

## Step 10 — Tests

Прогнать sections 94–136.

---

## Step 11 — Regressions

Все предыдущие modules.

---

## Step 12 — Docs

Обновить perk contracts и architecture docs.

---

# 142. Формат финального отчёта Cursor

## Runner

Подтвердить canonical:

```text
RivalCompetitionRunner
```

и отсутствие production `*CompetitionHost`.

## Sigma architecture

Headless core / UI / presentation.

## Core mechanic

Подтвердить:

```text
Mouse X balance
5.0 s section
3.0 s required hold
score target 3/5
```

## Difficulty

Exact:

```text
half_width = clamp(0.30 + diff*0.015, 0.20, 0.40)
pressure   = clamp(0.32 - diff*0.020, 0.18, 0.48)
```

## Disturbances

Подтвердить telegraph/count/timing.

## Perks

Перечислить фактическое поведение шести Sigma perks.

## Integration

```text
Rival → Runner → Sigma → Rival
```

## Validation

07C tests + regressions.

## Files changed

Основные файлы.

## Product questions

Если нет:

```text
None.
```

---

# 143. Запрет продолжения

После успешного MODULE 07C:

**НЕ начинать MODULE 07D — Money Contest.**

Остановиться и дождаться отдельной спецификации.
