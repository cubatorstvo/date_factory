# MODULE 07A — SLAP MINIGAME / ПОЩЁЧИННЫЙ БОЙ

**Проект:** Date Factory  
**Модуль:** 07A — Rival Minigame: Slap  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать первую полноценную мужскую мини-игру — пощёчинный бой — и подключить её к готовому Rival Encounter Framework  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущий модуль:** MODULE 06 — Rival Encounter Framework

---

# 1. Цель MODULE 07A

После завершения MODULE 07A игрок должен реально пройти пощёчинный бой от начала до конца:

```text
Rival Encounter
→ competition_type = SLAP
→ SlapMinigame
→ timing gameplay
→ PLAYER_WIN / PLAYER_LOSS
→ CLOSE / CRUSHING
→ RivalEncounters.submit_competition_result()
→ Authority / defeated rival resolution
```

Мини-игра должна:

- объясняться визуально за несколько секунд;
- занимать примерно `20–60 секунд`;
- быть полностью детерминированной навыком игрока и параметрами Мышцы;
- не использовать скрытый шанс победы;
- корректно работать при большой разнице характеристик;
- реализовать все slap-relevant перки Мышцы;
- использовать текущий FPS/world как визуальный фон, а не переносить игрока в отдельную абстрактную 2D-игру;
- вернуть ровно один typed `RivalCompetitionResult`.

---

# 2. MODULE 06 принимается как готовая граница

Не переписывать Rival Encounter Framework.

Использовать существующие:

```text
RivalEncounters
RivalEncounterSession
RivalCompetitionRequest
RivalCompetitionResult
GameTypes.CompetitionType.SLAP
GameTypes.RivalCompetitionOutcome
GameTypes.VictoryGrade
```

MODULE 07A отвечает только за:

```text
request SLAP
→ playable slap match
→ result
```

Авторитет, defeated rival, Heroic Defeat и Local Significance остаются MODULE 06.

---

# 3. Что Cursor не имеет права придумывать

Не добавлять:

- здоровье;
- HP;
- stamina;
- damage numbers;
- физический ragdoll;
- free-form melee;
- блок мышью;
- направление удара;
- удар по разным частям лица;
- combo-input sequences;
- random critical hit;
- dodge;
- parry кроме описанного timing block;
- charge attack;
- weapon system;
- betting;
- blood/gore;
- knockout health bar;
- сложный AI соперника;
- отдельную арену;
- cinematic QTE framework;
- generic rhythm-game framework.

---

# 4. Базовая механика

На экране находится горизонтальная дорожка:

```text
0.0 ------------------------------- 1.0
```

По ней с постоянной скоростью движется указатель.

Каждый цикл состоит из двух половин:

```text
ATTACK
0.0 → 1.0

DEFENSE
1.0 → 0.0
```

После DEFENSE начинается следующий ATTACK.

---

# 5. ATTACK

В ATTACK:

1. указатель движется слева направо;
2. существует одна target zone;
3. игрок нажимает primary timing action;
4. если указатель внутри target zone:
   - атака успешна;
   - игрок получает `+1` очко;
5. если указатель вне zone:
   - атака промахивается;
   - очко не получает никто;
6. если игрок вообще не нажал до конца дорожки:
   - это считается промахом;
7. после результата начинается DEFENSE, если матч ещё не завершён.

---

# 6. DEFENSE

В DEFENSE:

1. указатель движется справа налево;
2. target zone создаётся заново в другом месте;
3. игрок нажимает primary timing action;
4. если указатель внутри zone:
   - удар соперника заблокирован;
   - счёт не меняется;
5. если игрок нажал вне zone:
   - соперник получает `+1` очко;
6. если игрок не нажал до конца дорожки:
   - соперник получает `+1` очко;
7. после результата начинается новый ATTACK, если матч не завершён.

---

# 7. Раннее нажатие

Primary input принимается только один раз за половину цикла.

Если игрок нажал слишком рано:

```text
pointer outside target
```

это немедленно считается промахом.

Нельзя продолжать ждать и нажать второй раз.

Это исключает спам кнопки.

---

# 8. Позднее нажатие

Если указатель прошёл target zone, но ещё не дошёл до конца, игрок всё ещё может нажать.

Такое нажатие:

```text
miss
```

и немедленно завершает текущую половину.

Если не нажать вообще:

```text
timeout miss
```

при достижении конца.

---

# 9. Primary input

Добавить canonical Input Map action:

```text
minigame_primary
```

Default bindings:

```text
Space
Left Mouse Button
```

Во время Slap:

- FPS jump не выполняется;
- mouse look выключен;
- оба bindings означают один и тот же timing input.

UI показывает в первую очередь:

```text
SPACE
```

как клавиатурную подсказку.

---

# 10. Special inputs

Добавить:

```text
minigame_special_1
minigame_special_2
```

Default:

```text
minigame_special_1 = Q
minigame_special_2 = R
```

В Slap:

```text
Q = Двойная пощёчина
R = Двуручный довод
```

если соответствующий perk доступен.

Если perk отсутствует, его special action:

- не отображается;
- input ничего не делает.

---

# 11. Control mode

На протяжении мини-игры:

```text
PlayerControlMode.MINIGAME
```

Обычные:

- movement;
- jump;
- interact;
- mouse look

не работают.

Камера остаётся неподвижной относительно текущей постановки.

Mouse может оставаться captured, так как игра управляется клавиатурой/primary click.

После завершения control возвращает MODULE 06 своему владельцу.

Не создавать второй control stack.

---

# 12. Визуальная постановка

Мини-игра происходит поверх текущей 3D-сцены.

Не загружать отдельную slap arena.

Предпочтительный visual:

- соперник остаётся перед камерой;
- камера фиксируется;
- track UI появляется в нижней/центрально-нижней части экрана;
- score сверху;
- фаза явно читается;
- world остаётся виден.

Допустим небольшой camera framing на соперника, если он не требует нового cinematic framework.

---

# 13. Placeholder presentation допустима

MODULE 04 пока имеет semantic animations:

```text
gesture
react
idle
```

До отдельного presentation polish разрешено:

- attack success игрока → rival `react`;
- rival attack / player miss defense → rival `gesture` + простой camera/UI feedback;
- block → короткий UI feedback;
- misses → simple text/icon/shake.

Не требуется создавать полноценные slap-анимации сейчас.

MODULE 07A считается gameplay-complete даже с placeholder character animation, если timing понятно и работает.

---

# 14. Match target score

## Ordinary rival

```text
target_score = 3
```

если:

```text
RivalDefinition.is_story == false
```

## Story rival

```text
target_score = 5
```

если:

```text
RivalDefinition.is_story == true
```

Не использовать random target score.

---

# 15. Match end

Матч заканчивается сразу, как только:

```text
player_score >= target_score
```

или:

```text
rival_score >= target_score
```

Если player достигает target во время ATTACK:

- DEFENSE уже не проигрывается;
- result создаётся сразу.

Если rival достигает target во время DEFENSE:

- новый ATTACK не начинается.

---

# 16. Начальная фаза

Каждый slap match начинается:

```text
ATTACK
```

игрока.

Initiator Rival Encounter влияет только на выбор типа состязания.

Initiator НЕ определяет, кто бьёт первым внутри Slap.

---

# 17. Normalized track

Внутренняя координата:

```text
pointer_position ∈ [0.0, 1.0]
```

Target zone:

```text
center
width
start = center - width/2
end   = center + width/2
```

UI scaling/resolution не должны влиять на timing math.

---

# 18. Base difficulty

Использовать:

```text
difference = player_muscle - rival_muscle
```

где значения уже snapshot-нуты в:

```text
RivalCompetitionRequest.player_level
RivalCompetitionRequest.rival_level
```

Не читать текущий GameState Muscle во время RUNNING.

---

# 19. Target width formula

Base:

```text
target_width = 0.20 + difference * 0.0125
```

Clamp:

```text
0.12 <= target_width <= 0.28
```

Примеры:

```text
difference = 0
=> 0.20

difference = +4
=> 0.25

difference = -4
=> 0.15

difference >= +7
=> capped near 0.28

difference <= -7
=> capped near 0.12
```

Одинаковая base formula используется для ATTACK и DEFENSE, кроме explicit perk modifier.

---

# 20. Pointer speed formula

Track units per second:

```text
pointer_speed = 0.70 - difference * 0.025
```

Clamp:

```text
0.55 <= pointer_speed <= 0.95
```

Примеры:

```text
difference = 0
=> 0.70

difference = +4
=> 0.60

difference = -4
=> 0.80
```

Большая Мышца игрока:

- делает zone шире;
- слегка замедляет pointer.

Большая Мышца rival:

- делает zone уже;
- слегка ускоряет pointer.

---

# 21. Никакой скрытой вероятности

После расчёта:

```text
width
speed
```

результат полностью определяется input timing.

Запрещено:

```text
success_chance
randf() < muscle_probability
```

---

# 22. Target placement

Для каждой новой половины:

```text
target_center
```

выбирается pseudo-randomly.

Допустимый диапазон центра должен гарантировать margin не меньше:

```text
0.08
```

от краёв track.

То есть target целиком остаётся внутри:

```text
[0.08, 0.92]
```

с учётом half-width.

---

# 23. Не повторять почти одинаковую позицию

Новая zone по возможности должна отличаться от предыдущей:

```text
abs(new_center - previous_center) >= 0.15
```

Сделать ограниченное число reroll attempts, например `5`.

Если подходящее положение не найдено:

- принять последнее валидное;
- не зависать.

---

# 24. Testable RNG

Production использует обычный локальный RNG.

Для self-tests должна быть возможность задать deterministic seed.

Не сохранять RNG seed в GameState.

Он не влияет на progression outcome кроме положения timing zones.

---

# 25. Perfect zone

Внутри target существует central perfect zone.

Base fraction:

```text
perfect_fraction = 0.30
```

То есть:

```text
perfect_width = target_width * perfect_fraction
```

Perfect zone визуально читается как более яркая внутренняя область.

---

# 26. Streak

Slap match хранит локальный:

```text
streak
```

Streak означает:

> количество последних успешных timing half-phases подряд.

Успех:

```text
successful attack
successful defense
```

увеличивает:

```text
streak += 1
```

Обычный miss:

```text
streak = 0
```

Clamp для механики:

```text
0..4
```

UI может показывать больше, но расчёт perfect zone использует максимум `4`.

---

# 27. Streak effect

Streak делает perfect zone немного легче:

```text
perfect_fraction =
0.30 + min(streak, 4) * 0.05
```

Получаем:

```text
streak 0 => 30%
streak 1 => 35%
streak 2 => 40%
streak 3 => 45%
streak 4+ => 50%
```

Normal target zone НЕ увеличивается.

Это не даёт дополнительных очков само по себе.

Streak существует в первую очередь для:

- читаемого momentum;
- perfect-dependent perks;
- визуального ощущения серии.

---

# 28. Perfect attack without perk

Обычный perfect ATTACK:

```text
+1 point
```

так же, как обычный успешный attack.

Разница:

- более сильная visual reaction;
- может активировать perk effects.

Не давать скрытый bonus score без perk.

---

# 29. Perfect defense without perk

Perfect DEFENSE:

```text
0 score change
```

но:

- считается perfect block;
- может активировать `Counter Argument`;
- усиливает visual feedback.

---

# 30. VictoryGrade

Rival Encounter принимает только:

```text
CLOSE
CRUSHING
```

Использовать итоговую разницу очков победителя и проигравшего.

## target_score = 3

```text
difference == 1
=> CLOSE

difference >= 2
=> CRUSHING
```

## target_score = 5

```text
difference <= 2
=> CLOSE

difference >= 3
=> CRUSHING
```

Примеры:

```text
3:2 => CLOSE
3:1 => CRUSHING
3:0 => CRUSHING

5:4 => CLOSE
5:3 => CLOSE
5:2 => CRUSHING
5:0 => CRUSHING
```

---

# 31. Same grade logic for player loss

Если rival победил:

```text
2:3 => CLOSE loss
1:3 => CRUSHING loss

4:5 => CLOSE loss
2:5 => CRUSHING loss
```

Framework дальше сам решает presentation/result Authority.

---

# 32. Perk ownership

Все slap perk checks идут через:

```text
GameState.has_perk(PerkIds.*)
```

или approved Progression read API.

Не копировать perk ownership внутрь RivalDefinition.

На старте Slap match можно snapshot-нуть relevant booleans, чтобы debug-purchase во время мини-игры не меняла её правила.

---

# 33. `MUSCLE_NO_WARMUP` — Без разминки

Для Slap конкретная реализация:

> первая ATTACK zone текущего slap match шире.

Modifier:

```text
first_attack_width_multiplier = 1.25
```

После multiplier:

```text
width <= 0.34
```

Этот bonus применяется только к первой ATTACK half-phase.

Не применяется к первой DEFENSE.

Это локальная slap-интерпретация общего perk-контракта и не меняет его поведение в других strength activities.

---

# 34. `MUSCLE_TOUGH_CHEEK` — Крепкая щека

Один раз за match.

Trigger:

```text
игрок провалил DEFENSE
```

Rival всё равно получает обычное:

```text
+1 point
```

Но вместо:

```text
streak = 0
```

использовать:

```text
streak = max(1, ceil(previous_streak / 2.0))
```

если previous_streak > 0.

Если previous_streak == 0:

```text
streak остаётся 0
```

Perk считается использованным только если реально сохранил ненулевую streak.

Не предотвращает сам удар и rival point.

---

# 35. Почему Tough Cheek не отменяет очко

Контракт говорит:

> пропущенный удар не сбрасывает текущую серию полностью.

Он НЕ говорит:

> удар не засчитывается.

Поэтому rival point сохраняется.

---

# 36. `MUSCLE_DOUBLE_SLAP` — Двойная пощёчина

Один раз за match.

Доступна только в ATTACK.

Игрок нажимает:

```text
Q / minigame_special_1
```

до primary timing input текущей ATTACK phase.

После нажатия:

```text
double_slap_armed = true
```

и charge сразу считается использованной.

---

# 37. Double Slap success

Если armed ATTACK попадает в:

```text
PERFECT zone
```

то:

```text
player gains +2 points total
```

вместо обычного `+1`.

Не:

```text
+1 +2
```

а именно total `2`.

---

# 38. Double Slap normal hit

Если primary попал в обычную target zone, но НЕ perfect:

```text
player gains normal +1
```

но special считается проваленным.

Следующая DEFENSE получает penalty.

---

# 39. Double Slap miss

Если primary вне target или timeout:

```text
player gains 0
```

и следующая DEFENSE получает тот же penalty.

---

# 40. Double Slap defense penalty

Следующая DEFENSE после неидеального Double Slap:

```text
defense_target_width *= 0.65
```

Clamp minimum:

```text
0.08
```

Penalty применяется ровно к одной следующей DEFENSE и затем исчезает.

Pointer speed не меняется.

---

# 41. Double Slap and match end

Если perfect Double Slap сразу достигает target score:

- match заканчивается;
- penalty отсутствует, потому что success perfect;
- DEFENSE не начинается.

---

# 42. `MUSCLE_COUNTER_ARGUMENT` — Ответный аргумент

Trigger:

```text
PERFECT DEFENSE
```

После perfect block:

```text
counter_armed = true
```

на ближайшую следующую ATTACK phase.

---

# 43. Counter success

Если ближайший ATTACK также:

```text
PERFECT
```

то:

```text
+1 additional player point
```

поверх результата этого attack.

Обычный perfect:

```text
1 + 1 = 2
```

---

# 44. Counter expiry

Если ближайший ATTACK:

- normal success;
- miss;
- timeout;

то:

```text
counter_armed = false
```

без bonus.

Bonus не переносится дальше.

---

# 45. Counter + Double Slap stacking

Разрешено.

Если:

```text
counter_armed
+
Double Slap armed
+
PERFECT attack
```

то:

```text
Double Slap = 2 total
Counter      = +1

final gain = 3
```

Это поздняя осознанная синергия двух перков.

Match score clamp-ить не нужно; для presentation можно хранить фактический score >= target, но winner определяется сразу.

---

# 46. `MUSCLE_MASS_RESERVE` — Запас массы

Для Slap выбрать вариант:

```text
одна дополнительная ошибка
```

Один раз за match.

Trigger:

```text
первый обычный ATTACK miss
```

который не является:

- Double Slap attempt;
- Two-Handed Argument attempt.

---

# 47. Mass Reserve effect

Вместо перехода к DEFENSE:

1. miss visual показывается;
2. score не меняется;
3. создаётся новая ATTACK target zone;
4. игрок получает ещё одну ATTACK попытку.

После этого perk считается использованным.

Streak:

```text
сбрасывается в 0
```

потому что ошибка произошла.

---

# 48. Почему Mass Reserve не работает на special attacks

Иначе можно без риска повторять high-risk decisive perk.

Special attempts остаются special risk.

---

# 49. `MUSCLE_TWO_HANDED_ARGUMENT` — Двуручный довод

Доступен только в:

```text
major slap contest
```

Для MODULE 07A major contest определяется:

```text
RivalDefinition.is_story == true
```

То есть только story rival / target score 5.

Обычный rival не даёт этот special.

---

# 50. Two-Handed activation

Один раз за match.

Только в ATTACK.

Input:

```text
R / minigame_special_2
```

до primary timing input.

После:

```text
two_handed_armed = true
```

charge сразу считается использованной.

---

# 51. Double Slap vs Two-Handed

На одной ATTACK phase можно arm только один special:

```text
Double Slap
OR
Two-Handed Argument
```

Первый успешно принятый special input блокирует другой до конца phase.

UI второй special временно disabled.

---

# 52. Two-Handed timing

Two-Handed требует:

```text
PERFECT
```

Normal target hit недостаточен.

Для этой attempt:

```text
normal target отображается как обычно
perfect zone ясно выделена
```

---

# 53. Two-Handed success

Perfect:

```text
player gains +2 points
```

как крупное преимущество.

Если Counter Argument armed:

```text
+1 additional
```

то есть:

```text
3 total
```

---

# 54. Two-Handed failure

Любой не-perfect результат:

- normal target hit;
- outside hit;
- timeout

считается провалом решающего приёма.

Rival немедленно получает:

```text
+2 points
```

Streak:

```text
0
```

После этого:

- если rival достиг target → match end;
- иначе текущий cycle считается завершённым и начинается новый ATTACK игрока.

НЕ запускать обычную DEFENSE сразу после проваленного Two-Handed, потому что rival уже получил крупное преимущество в форме `+2`.

---

# 55. Two-Handed success phase flow

После успешного Two-Handed:

- если player достиг target → match end;
- иначе начинается обычная DEFENSE.

---

# 56. Two-Handed is not instant win

Не делать:

```text
perfect => automatic match victory
```

Он даёт конкретные:

```text
+2 points
```

что может закончить match, если score близок к target.

---

# 57. Perfect visual feedback

Различать минимум:

```text
MISS
HIT
PERFECT
BLOCK
PERFECT_BLOCK
```

UI feedback длится коротко и не должен растягивать матч.

Ориентир pause после результата:

```text
0.15–0.30 s
```

Cursor выбирает технически комфортное значение.

Не добавлять длинную cutscene после каждого удара.

---

# 58. Point feedback

При изменении score:

- score update сразу читаем;
- краткий pop/flash;
- sound placeholder допустим;
- match logic не ждёт длинной animation.

Presentation polish будет MODULE 23.

---

# 59. Slap UI

Минимальный production-functional UI должен показывать:

```text
Player score
Rival score
Target score

ATTACK / BLOCK phase
Track
Pointer
Target zone
Perfect zone

available special perks
used state
```

Не показывать debug stat formula в production UI.

---

# 60. Phase labels

Canonical Russian:

ATTACK:

```text
ПОЩЁЧИНА
```

DEFENSE:

```text
БЛОК
```

Допустимо короткое:

```text
БЕЙ
БЛОК
```

но выбрать один вариант и использовать последовательно.

Предпочтение:

```text
ПОЩЁЧИНА
БЛОК
```

---

# 61. Special labels

```text
Q — Двойная пощёчина
R — Двуручный довод
```

Когда использовано:

- dim;
- `Использовано`;
- не принимает input.

`Двуручный довод` вообще не показывать в ordinary match.

---

# 62. Tutorial

Первый slap match в прохождении должен кратко объяснить:

```text
SPACE — попасть в область
Вперёд — пощёчина
Назад — блок
```

Не создавать отдельную tutorial campaign.

Можно использовать 2–3 строки overlay перед первым cycle.

---

# 63. Tutorial persistence

MODULE 07A не обязан добавлять permanent GameState tutorial flag, если это усложняет систему.

Разрешено:

- показывать подсказку первые несколько секунд каждого match;
- или иметь простой session-local compact hint.

Предпочтительно не добавлять save-state ради tutorial сейчас.

---

# 64. Pause

Обычный global pause продолжает работать согласно MODULE 01.

Slap internal timing должен остановиться вместе с SceneTree pause.

Не продолжать pointer под pause menu.

---

# 65. Focus loss

При потере window focus:

- не регистрировать случайный primary press;
- minigame state остаётся целостным.

Не делать automatic miss только из-за focus loss.

---

# 66. No FPS delta timing bug

Pointer movement должен использовать корректный frame/physics delta.

Timing не должен зависеть от FPS.

Выбор `_process` vs `_physics_process` — технический best-practice выбор Cursor.

Для UI timing обычно ожидаем `_process(delta)`.

---

# 67. Architecture

Создать reusable scene semantic уровня:

```text
SlapMinigame
```

Canonical area:

```text
res://minigames/slap/
```

или фактический canonical minigames path проекта.

Рекомендуемо:

```text
minigames/slap/
├── slap_minigame.tscn
├── slap_minigame.gd
├── slap_match_state.gd     # только если действительно нужно
└── test/
```

Не дробить mechanics на множество managers.

---

# 68. Runner integration

MODULE 06 сейчас имеет competition runner bridge.

Создать реальный integration host/runner, который:

```text
request.competition_type == SLAP
→ запускает SlapMinigame
```

Для пока не реализованных:

```text
DANCE
MONEY
SIGMA
```

не возвращать fake result.

Они должны явно оставаться:

```text
NOT_IMPLEMENTED
```

или не маршрутизироваться до соответствующих MODULE 07B–D.

---

# 69. Не заменять fake runner

`RivalFakeCompetitionRunner` остаётся test-only для MODULE 06 self-tests.

Real runtime использует настоящий Slap runner/host.

Не менять MODULE 06 tests так, чтобы они зависели от Slap gameplay.

---

# 70. Result submission

SlapMinigame после match end создаёт:

```text
RivalCompetitionResult
```

Поля:

```text
outcome
victory_grade
debug_score_summary
```

`debug_score_summary` допустимо:

```text
"3:2"
"5:1"
```

---

# 71. Exactly-once completion

SlapMinigame должен emit/submit final result ровно один раз.

После match ended:

- input disabled;
- pointer stops;
- повторный click не меняет score;
- second submit невозможен.

---

# 72. Cleanup

После завершения:

- slap UI убирается;
- temporary nodes освобождаются;
- input возвращается MODULE 06;
- no lingering signals;
- no orphaned timers.

---

# 73. RivalDefinition lookup

Для определения:

```text
is_story
target_score
```

разрешено lookup RivalDefinition по:

```text
request.rival_id
```

через ContentDB/RivalEncounters.

Не копировать `is_story` в request только ради одного поля, если lookup чистый и дешёвый.

Если Cursor считает snapshot безопаснее — может расширить typed request технически, но не добавлять domain dictionary.

---

# 74. Test mode

SlapMinigame должен быть тестируемым без полного world encounter.

Нужен способ создать test request:

```text
player_level
rival_level
ordinary/story
perk snapshot
```

и управлять input/ticks детерминированно.

Не требуется тяжёлый testing framework.

---

# 75. Unit-testable timing evaluator

Рекомендуется отделить чистую функцию semantic уровня:

```text
evaluate_timing(pointer, target_start, target_end, perfect_start, perfect_end)
```

→

```text
MISS
HIT
PERFECT
```

Техническая форма Cursor.

Цель — тестировать boundary cases без реального UI frame timing.

---

# 76. Boundary semantics

Target boundaries считаются inclusive:

```text
pointer == target_start
=> HIT

pointer == target_end
=> HIT
```

Perfect boundaries inclusive:

```text
pointer == perfect_start
=> PERFECT
```

Floating epsilon использовать только если технически нужно.

---

# 77. Test — base equal stats

```text
player = 4
rival = 4
difference = 0
```

Ожидается:

```text
width = 0.20
speed = 0.70
```

---

# 78. Test — player stronger

```text
player = 8
rival = 4
difference = +4
```

Ожидается:

```text
width = 0.25
speed = 0.60
```

---

# 79. Test — rival stronger

```text
player = 2
rival = 6
difference = -4
```

Ожидается:

```text
width = 0.15
speed = 0.80
```

---

# 80. Test — clamps

Проверить extreme input:

```text
difference +100
=> width 0.28
=> speed 0.55

difference -100
=> width 0.12
=> speed 0.95
```

---

# 81. Test — attack hit

Score:

```text
0:0
```

Primary in normal zone.

После:

```text
1:0
phase = DEFENSE
```

---

# 82. Test — attack miss

Primary outside.

После:

```text
0:0
phase = DEFENSE
```

без Mass Reserve.

---

# 83. Test — attack timeout

No input.

После track end:

```text
0:0
phase = DEFENSE
```

---

# 84. Test — defense block

Before:

```text
1:0
```

Input inside.

After:

```text
1:0
phase = ATTACK
```

---

# 85. Test — defense miss

Before:

```text
1:0
```

outside/timeout.

After:

```text
1:1
phase = ATTACK
```

---

# 86. Test — one input per phase

Первый early press делает miss.

Второй press той же phase не может исправить результат.

---

# 87. Test — ordinary target

Ordinary rival:

```text
target = 3
```

At:

```text
3:2
```

match ends immediately.

---

# 88. Test — story target

Story rival:

```text
target = 5
```

---

# 89. Test — CLOSE/CRUSHING ordinary

Exact:

```text
3:2 => CLOSE
3:1 => CRUSHING
2:3 => CLOSE
1:3 => CRUSHING
```

---

# 90. Test — CLOSE/CRUSHING story

Exact:

```text
5:4 => CLOSE
5:3 => CLOSE
5:2 => CRUSHING
4:5 => CLOSE
3:5 => CLOSE
2:5 => CRUSHING
```

---

# 91. Test — perfect boundaries

Exact target evaluator tests.

---

# 92. Test — streak

Three successful half-phases:

```text
streak = 3
perfect_fraction = 0.45
```

Normal miss:

```text
streak = 0
```

---

# 93. Test — No Warmup

Perk owned.

First ATTACK width:

```text
base_width * 1.25
```

cap `0.34`.

Second ATTACK:

```text
normal base width
```

---

# 94. Test — Tough Cheek

Before defense:

```text
streak = 4
perk unused
```

Defense miss:

```text
rival +1
streak = 2
perk used
```

Следующий defense miss:

```text
normal streak reset 0
```

---

# 95. Test — Tough Cheek with zero streak

```text
streak = 0
```

Defense miss:

- rival +1;
- perk НЕ считается потраченным;
- streak 0.

Позднее при ненулевой streak perk ещё может сработать.

---

# 96. Test — Double Slap perfect

Arm Q.

Perfect.

```text
player +2
charge used
no defense penalty
```

---

# 97. Test — Double Slap normal hit

Arm Q.

Normal HIT.

```text
player +1
next defense width *0.65
charge used
```

---

# 98. Test — Double Slap miss

Arm Q.

MISS.

```text
player +0
next defense width *0.65
```

---

# 99. Test — Counter Argument

Perfect block.

Next perfect attack:

```text
+2 total
```

instead of normal +1.

---

# 100. Test — Counter expiry

Perfect block.

Next normal HIT:

```text
+1
counter consumed without bonus
```

Following perfect attack:

```text
no old counter bonus
```

---

# 101. Test — Double + Counter

Perfect block → counter armed.

Next attack:

- Double Slap armed;
- perfect.

Expected:

```text
+3
```

---

# 102. Test — Mass Reserve

First ordinary ATTACK miss:

```text
no phase switch
new attack zone
streak 0
perk used
```

Second miss:

```text
normal switch to DEFENSE
```

---

# 103. Test — Mass Reserve excludes Double Slap

Double Slap miss:

- Mass Reserve does not retry;
- goes to defense with penalty.

---

# 104. Test — Two-Handed unavailable ordinary

Ordinary rival, perk owned.

R special:

```text
ignored/unavailable
```

UI special hidden.

---

# 105. Test — Two-Handed story perfect

Story rival.

Arm R.

Perfect:

```text
player +2
```

---

# 106. Test — Two-Handed story normal hit

Arm R.

Input inside normal zone but outside perfect.

Expected:

```text
rival +2
streak 0
new ATTACK if match not ended
```

---

# 107. Test — Two-Handed story miss

Same:

```text
rival +2
```

---

# 108. Test — specials mutually exclusive

Arm Q.

Then R same phase:

```text
R rejected
Double remains armed
```

Reverse same.

---

# 109. Test — match end mid-special

Player:

```text
2 / target 3
```

Perfect Double Slap:

```text
score >=3
match ends immediately
no defense
```

---

# 110. Test — result typed

Win returns:

```text
RivalCompetitionOutcome.PLAYER_WIN
VictoryGrade correct
```

Loss equivalent.

---

# 111. Test — submit once

Finish match, then simulate extra input/extra completion callback.

Expected:

```text
one RivalEncounters submission
```

---

# 112. Test — Rival integration

End-to-end:

```text
start RivalEncounter
choose SLAP
real Slap runner starts
complete deterministic match
RivalEncounters resolves Authority
```

Test win and loss.

---

# 113. Test — Heroic Defeat remains MODULE 06

Slap returns only:

```text
LOSS + grade
```

Slap itself does NOT cancel Authority.

MODULE 06 sees relevant snapshot and Heroic Defeat perk.

---

# 114. Test — defeated rival flow

Real slap victory:

- RivalEncounter marks defeated;
- Slap module itself never calls `mark_rival_defeated`.

---

# 115. Test — FPS regression

После MODULE 07A:

- FPS movement works outside minigame;
- interaction works;
- pause works;
- minigame mode enters/exits correctly.

---

# 116. Test — previous modules

Run:

```text
MODULE 02
MODULE 03
MODULE 04
MODULE 05
MODULE 06
```

self-tests.

MODULE 06 fake-runner tests должны оставаться независимыми.

---

# 117. Audio

MODULE 07A может использовать минимальные placeholder SFX, если уже есть подходящие assets:

- hit;
- block;
- miss;
- perfect.

Но не тратить время на поиск/полный sound pass.

Если sounds отсутствуют — gameplay acceptance не блокируется.

---

# 118. Haptics

Не реализовывать controller vibration сейчас.

---

# 119. Accessibility

Мини-игра не должна полагаться только на цвет.

Различия:

- normal zone;
- perfect zone;
- pointer;
- ATTACK/DEFENSE

должны читаться формой/яркостью/текстом.

Не требовать финальных accessibility settings.

---

# 120. Performance

Мини-игра состоит из:

- UI track;
- pointer;
- simple update;
- local state.

Не создавать physics bodies для pointer/zone.

Не использовать collision detection UI timing.

Timing проверяется численно.

---

# 121. Documentation

После реализации обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
```

В `PERK_EFFECT_CONTRACTS.md` уточнить фактические slap implementations:

```text
No Warmup
Tough Cheek
Double Slap
Counter Argument
Mass Reserve
Two-Handed Argument
```

Не менять эффекты остальных perks.

---

# 122. Что MODULE 07A НЕ реализует

Категорически не реализовывать:

- Dance;
- Sigma;
- Money contest;
- generic rhythm engine;
- extra strength activities;
- Hold Doorway world scenes;
- dating strength actions;
- final animation polish;
- crying/running-away presentation;
- crowd;
- dialogue;
- story consequences;
- relationship changes;
- Authority logic внутри Slap.

---

# 123. Definition of Done

MODULE 07A завершён только если:

- [ ] real SLAP request запускает SlapMinigame;
- [ ] current 3D world остаётся фоном;
- [ ] Player входит в MINIGAME control mode;
- [ ] track normalized 0..1;
- [ ] ATTACK 0→1 работает;
- [ ] DEFENSE 1→0 работает;
- [ ] early/late/timeout miss работают;
- [ ] ordinary match до 3;
- [ ] story match до 5;
- [ ] width formula exact;
- [ ] speed formula exact;
- [ ] stat clamps exact;
- [ ] target random placement работает;
- [ ] deterministic test seed доступен;
- [ ] perfect inner zone существует;
- [ ] streak влияет на perfect fraction;
- [ ] grade CLOSE/CRUSHING exact;
- [ ] No Warmup реализован;
- [ ] Tough Cheek реализован;
- [ ] Double Slap реализован;
- [ ] Counter Argument реализован;
- [ ] Mass Reserve реализован;
- [ ] Two-Handed Argument реализован;
- [ ] Double + Counter stacking exact;
- [ ] special inputs mutually exclusive;
- [ ] typed result возвращается;
- [ ] final result submit ровно один раз;
- [ ] Slap не меняет Authority напрямую;
- [ ] Slap не меняет defeated rivals напрямую;
- [ ] MODULE 06 fake runner сохранён;
- [ ] end-to-end Rival→Slap→Rival result работает;
- [ ] предыдущие regressions проходят;
- [ ] MODULE 07B не реализован заранее.

---

# 124. Порядок выполнения Cursor

## Step 1 — Audit

Изучить:

```text
RivalEncounters
RivalCompetitionRequest
RivalCompetitionResult
Player control modes
current UI structure
CharacterActor animation API
PerkIds
PERK_EFFECT_CONTRACTS
```

---

## Step 2 — Technical architecture

Выбрать лучший простой способ:

- инстанцировать slap UI/scene;
- заблокировать FPS;
- вернуть result;
- cleanup.

Использовать Godot best practices.

Не спрашивать пользователя о чисто технической форме.

---

## Step 3 — Input Map

Добавить:

```text
minigame_primary
minigame_special_1
minigame_special_2
```

с bindings из этой спецификации.

---

## Step 4 — Core timing

Сначала реализовать без perks:

```text
track
attack
defense
score
target score
grade
result
```

---

## Step 5 — Stat scaling

Добавить exact width/speed formulas.

---

## Step 6 — Perfect + streak

Добавить perfect zone и streak.

---

## Step 7 — Perks

В порядке:

1. No Warmup
2. Tough Cheek
3. Double Slap
4. Counter Argument
5. Mass Reserve
6. Two-Handed Argument

---

## Step 8 — Presentation

Минимальный readable UI + CharacterActor placeholder reactions.

---

## Step 9 — Real Rival integration

Подключить SLAP к real runner/host.

Другие competition types оставить unimplemented.

---

## Step 10 — Tests

Прогнать sections 77–116.

---

## Step 11 — Regressions

Все предыдущие modules.

---

## Step 12 — Docs

Обновить technical docs и perk contracts.

---

# 125. Формат финального отчёта Cursor

## Architecture

Как Slap scene подключается к RivalEncounters.

## Core rules

Подтвердить:

```text
ordinary target = 3
story target = 5
attack -> defense cycle
```

## Difficulty

Подтвердить exact:

```text
width = clamp(0.20 + diff*0.0125, 0.12, 0.28)
speed = clamp(0.70 - diff*0.025, 0.55, 0.95)
```

## Perks

Для шести perks кратко указать фактическое поведение.

## Integration

Подтвердить:

```text
Slap returns typed result
RivalEncounters owns Authority/defeat
```

## Validation

MODULE 07A tests + previous regressions.

## Files changed

Основные файлы.

## Product questions

Только реальные вопросы, которые нельзя решить технически.

Если нет:

```text
None.
```

---

# 126. Запрет продолжения

После успешного MODULE 07A:

**НЕ начинать MODULE 07B — Dance.**

Остановиться и дождаться отдельной спецификации.
