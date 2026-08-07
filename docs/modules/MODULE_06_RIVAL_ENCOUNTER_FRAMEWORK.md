# MODULE 06 — RIVAL ENCOUNTER FRAMEWORK

**Проект:** Date Factory  
**Модуль:** 06 — Rival Encounter Framework  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать полный жизненный цикл встречи с самцом-соперником — доступность вызова, инициатора, выбор состязания, запуск будущей мини-игры, обработку победы/поражения, Авторитет, defeat-state и perk-интеграцию — без реализации самих мини-игр  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущий модуль:** MODULE 05 — Progression & Perks

---

# 0. PRE-FLIGHT — зафиксировать новые продуктовые решения

До реализации MODULE 06 обновить соответствующую GDD-документацию следующими утверждёнными правилами.

## 0.1. Поражение в мужском состязании

Любое обычное поражение игрока в состязании с самцом:

```text
Авторитет -1
```

Независимо от того:

- произошло состязание отдельно;
- произошло состязание внутри свидания;
- кто был инициатором;
- какой тип состязания использовался.

Авторитет никогда не становится отрицательным.

То есть при:

```text
authority = 0
```

поражение оставляет:

```text
authority = 0
```

---

## 0.2. Смена состязания через Ауру

Если соперник инициировал encounter и выбрал состязание, а игрок использует:

```text
perk_aura_right_to_say_nothing
```

игрок может заменить выбранное состязание на другое допустимое.

**Никакого дополнительного штрафа Авторитета за такую смену нет.**

Удалить из `PERK_EFFECT_CONTRACTS.md` старую формулировку о возможном penalty за override.

---

## 0.3. `Она уже начала`

Поскольку штрафа за смену состязания нет, мужская часть старого контракта:

```text
perk_aura_she_already_started
```

про отмену penalty больше не существует.

В Rival Encounter этот perk НЕ имеет отдельного эффекта.

Его актуальный эффект остаётся в Dating:

> после применения `Право первым ничего не говорить` первая инициатива девушки даёт более явную clue её основной черты.

Не придумывать новый мужской эффект только чтобы perk «работал в двух местах».

---

## 0.4. Отношения девушки

Зафиксировать для будущих Dating/Relationships modules:

```text
relationship ∈ [-5, +5]
```

Это отдельная система и никак не заменяет Авторитет.

MODULE 06 отношения девушки НЕ изменяет.

---

## 0.5. Опытность

Зафиксировать:

> Опытность соответствует количеству уникальных девушек, которые хотя бы один раз достигли `+5`.

Опытность:

- не расходуется;
- не уменьшается;
- поражение в мужском состязании её не меняет;
- ухудшение отношений уже покорённой девушки в будущем не отнимает ранее полученную Опытность.

MODULE 06 Опытность НЕ изменяет.

---

# 1. Цель MODULE 06

После MODULE 06 должен существовать законченный framework:

```text
RivalDefinition
+
runtime Rival Encounter
+
GameState Authority
+
defeated rival state
+
competition selection
+
future minigame integration contract
```

Framework должен уметь:

1. определить, может ли игрок сейчас вызвать конкретного соперника;
2. начать encounter с инициатором `PLAYER` или `RIVAL`;
3. определить, кто выбирает состязание;
4. определить допустимые типы состязаний;
5. применить relevant perk rules;
6. сформировать typed request будущей мини-игре;
7. принять typed результат;
8. при победе выдать Авторитет один раз;
9. навсегда отметить соперника побеждённым;
10. при поражении снять `1` Авторитета;
11. закончить encounter в целостном состоянии;
12. уведомить future presentation/story systems.

MODULE 06 НЕ реализует Slap/Dance/Sigma/Money gameplay.

---

# 2. Основная модель

Система строится вокруг короткоживущего:

```text
RivalEncounterSession
```

Session существует только от начала вызова до завершения результата.

Persistent данные находятся в:

```text
GameState
```

Static данные:

```text
RivalDefinition
ContentDB
```

---

# 3. Что Cursor не имеет права придумывать

Не добавлять:

- дружбу с побеждённым самцом;
- recruitment;
- follower system;
- rivalry meter;
- revenge system;
- morale;
- stamina;
- health;
- injury;
- betting;
- random encounter generation;
- hidden hostility;
- faction reputation;
- ELO;
- rank points;
- matchmaking;
- arbitrary refusal penalties;
- cost to challenge;
- cooldown между вызовами;
- forced branch dialogue;
- combat AI.

---

# 4. Самцы после поражения

Канон:

> Побеждённый самец уступает и покидает ситуацию.

Он НЕ становится:

- другом;
- знакомым;
- помощником;
- сотрудником;
- клоном;
- членом команды.

После первой победы игрока конкретный `rival_id` считается permanently defeated в текущем прохождении.

---

# 5. Повторная победа запрещена

Нельзя фармить одного и того же соперника.

Если:

```text
is_rival_defeated(rival_id) == true
```

обычный encounter с ним больше не запускается.

Future story/world system может оставить его visual в сцене, но Rival Encounter Framework должен отвечать:

```text
ALREADY_DEFEATED
```

Авторитет повторно не выдаётся.

---

# 6. GameState — defeated rivals

Добавить persistent set-like state:

```text
defeated_rivals
```

ID:

```text
StringName
```

Минимальный API:

```text
is_rival_defeated(rival_id) -> bool
mark_rival_defeated(rival_id) -> bool
```

`mark_rival_defeated`:

- `true` только первый раз;
- повторно `false`;
- не начисляет reward самостоятельно.

---

# 7. Reset

`reset_for_new_game()` дополнительно:

```text
defeated_rivals = empty
```

---

# 8. Авторитет — controlled loss

MODULE 02 изначально разрешал только рост Авторитета.

Теперь создать controlled API semantic уровня:

```text
lose_authority(amount) -> int
```

или эквивалент.

Правила:

```text
amount >= 0
authority never below 0
```

Return желательно:

```text
actual amount lost
```

Пример:

```text
authority = 5
lose 1
=> authority = 4
=> actual_loss = 1
```

```text
authority = 0
lose 1
=> authority = 0
=> actual_loss = 0
```

Не использовать отрицательное значение:

```text
add_authority(-1)
```

---

# 9. Encounter initiator

Canonical enum:

```text
PLAYER
RIVAL
```

Не добавлять третьего универсального:

```text
SCRIPT
```

Сюжетная система может явно начать encounter как:

```text
RIVAL
```

или:

```text
PLAYER
```

в зависимости от постановки.

---

# 10. Что означает «кто подошёл первым»

Каноническое правило:

> Тот, кто инициировал encounter, получает право первого выбора состязания.

Технически MODULE 06 НЕ реализует navigation/AI «подойти».

Инициатор передаётся явно при запуске:

```text
start_encounter(rival_id, initiator)
```

или эквивалентно.

---

# 11. PLAYER initiator

Типичный случай:

```text
игрок подошёл
→ [E] Вызвать
→ PLAYER initiator
```

Перед запуском encounter Framework проверяет:

1. rival существует;
2. rival ещё не defeated;
3. player authority достаточен;
4. существует хотя бы одно доступное player competition.

Если проверки проходят:

```text
PLAYER выбирает competition
```

из допустимого списка.

---

# 12. RIVAL initiator

Типичный случай:

```text
соперник сам инициировал сцену
```

MODULE 06 не заставляет NPC ходить к игроку.

World/Story system вызывает:

```text
start_encounter(rival_id, RIVAL)
```

Соперник выбирает:

```text
preferred_competition
```

если это состязание доступно игроку.

Если preferred competition сейчас технически недоступен игроку из-за progression gate:

```text
encounter не должен стартовать
```

и возвращается явная причина:

```text
COMPETITION_LOCKED
```

World/Story system позже обязан не инициировать такую ситуацию до выполнения prerequisite.

Не выбирать сопернику случайно другой тип вместо preferred.

---

# 13. required_authority

`RivalDefinition.required_authority` используется для player-initiated challenge.

Если:

```text
GameState.authority < required_authority
```

и PLAYER является initiator:

```text
RIVAL_REFUSED_LOW_AUTHORITY
```

Encounter не стартует.

Нет:

- штрафа Авторитета;
- потери денег;
- cooldown.

---

# 14. Rival initiated challenge и required_authority

Если Rival сам является initiator:

```text
required_authority
```

НЕ блокирует encounter.

Логика проста:

> если самец сам выбрал игрока, он уже согласился соревноваться.

Story/World system отвечает за то, когда такой вызов уместен.

---

# 15. High-status refusal

Framework должен предоставлять результат отказа, чтобы future presentation могла показать:

- короткую реплику;
- dismissive animation;
- уход.

MODULE 06 не пишет production реплики.

---

# 16. Competition access

Базовая доступность игроку:

```text
SLAP  = доступно
DANCE = доступно
```

Денежное противостояние:

```text
MONEY
```

доступно только если куплен:

```text
perk_capital_payable_intent
```

Сигма-давление:

```text
SIGMA
```

доступно только если куплен:

```text
perk_aura_presence_registered
```

---

# 17. Почему access проверяется в MODULE 06

Это не minigame mechanic, а правило:

> может ли этот тип состязания вообще быть выбран в Rival Encounter.

Конкретные mechanics состязания принадлежат MODULE 07.

---

# 18. Allowed competitions

Для конкретного Rival:

```text
RivalDefinition.allowed_competitions
```

задаёт типы, которые этот соперник вообще поддерживает.

Фактически доступный player list:

```text
allowed_competitions
INTERSECT
player_unlocked_competitions
```

---

# 19. PLAYER choice

Если игрок инициировал encounter:

- показать только доступное пересечение;
- player выбирает ровно один type;
- никаких random weights;
- `preferred_competition` rival не влияет.

---

# 20. Empty competition list

Если после фильтрации:

```text
0 доступных competitions
```

Encounter не стартует.

Result:

```text
NO_AVAILABLE_COMPETITION
```

Это content/progression situation, а не crash.

---

# 21. Rival choice

При `RIVAL` initiator:

```text
chosen = preferred_competition
```

Проверить:

- preferred входит в `allowed_competitions`;
- preferred доступен player progression.

Если нет — явная ошибка/недоступность.

Не fallback-ить случайно на другое соревнование.

---

# 22. `Право первым ничего не говорить`

Perk:

```text
perk_aura_right_to_say_nothing
```

работает в Rival Encounter только если:

```text
initiator == RIVAL
```

и rival уже выбрал preferred competition.

Игроку разрешается:

```text
оставить выбранное rival состязание
```

или:

```text
заменить его на любое другое доступное состязание
```

из intersection:

```text
rival.allowed_competitions
∩
player_unlocked_competitions
```

---

# 23. Override не штрафуется

При замене competition:

```text
authority penalty = 0
```

Нет:

- скрытого штрафа;
- дополнительного риска;
- расхода perk;
- потери Баллов прокачки.

Perk просто даёт право переопределить выбор.

---

# 24. Usage `Право первым ничего не говорить`

Scope:

```text
один раз за encounter
```

Поскольку в encounter выбирается competition только один раз, отдельный persistent charge почти не нужен.

Не хранить usage в GameState.

Session может иметь:

```text
competition_override_used
```

если это полезно для presentation/debug.

---

# 25. `Она уже начала`

`perk_aura_she_already_started`:

```text
NO RIVAL EFFECT
```

в текущей версии.

Не проверять его в MODULE 06.

---

# 26. Chosen competition becomes immutable

После подтверждения выбора и запуска мини-игры:

```text
competition_type
```

не меняется.

Не разрешать switch mid-minigame.

---

# 27. Encounter phases

Нужна небольшая явная session state model.

Canonical semantics:

```text
CHOOSING
READY
RUNNING
RESOLVING
FINISHED
```

Можно добавить:

```text
CREATED
```

если технически полезно.

Не строить generic StateMachine framework.

---

# 28. Session data

Минимально session содержит:

```text
rival_id
initiator
chosen_competition

player_characteristic_level
rival_characteristic_level

phase

override_used
```

После результата:

```text
outcome
victory_grade
authority_delta
```

Не хранить:

- relationship;
- money;
- dating tags;
- quest state.

---

# 29. Relevant characteristic

Mapping из MODULE 03:

```text
SLAP  -> MUSCLE
DANCE -> APPEARANCE
MONEY -> CAPITAL
SIGMA -> AURA
```

Перед запуском competition session snapshot-ит:

```text
player characteristic level
rival characteristic level
```

---

# 30. Почему snapshot

Чтобы result одной мини-игры не менялся посередине из-за случайной внешней покупки перка/debug mutation.

После `RUNNING` конкретный encounter использует характеристики, с которыми начался.

---

# 31. Rival stat source

Использовать:

```text
RivalDefinition.muscle
appearance
capital
aura
```

Не вычислять «общий level rival» для обычного minigame.

---

# 32. Minigame integration boundary

MODULE 06 должен определить typed contract будущим MODULE 07A–07D.

Он не должен знать их сценовую реализацию.

Semantic request:

```text
RivalCompetitionRequest
```

содержит минимум:

```text
rival_id
competition_type
player_level
rival_level
initiator
```

Допустимо передать read-only session ID/reference.

---

# 33. Minigame result

Canonical result:

```text
PLAYER_WIN
PLAYER_LOSS
```

Encounter Framework не принимает `DRAW` как финальный результат.

Если конкретная мини-игра может закончиться равенством, MODULE 07 обязана разрешить его:

- дополнительным раундом;
- tie-break;
- продолжением,

и только после этого вернуть WIN/LOSS.

---

# 34. Victory grade

Minigame дополнительно возвращает presentation grade:

```text
CLOSE
CRUSHING
```

Grade:

- не меняет размер authority reward;
- не меняет обычный loss penalty;
- используется для реакции персонажей/постановки.

Каждый MODULE 07 сам определяет, что для его scoring считается CLOSE/CRUSHING.

Framework не делает generic score normalization.

---

# 35. Typed result

Semantic:

```text
RivalCompetitionResult
```

Минимально:

```text
outcome
victory_grade
```

Опционально:

```text
debug_score_summary
```

только для debug/report.

Не передавать arbitrary result dictionary.

---

# 36. Competition host contract

Cursor должен выбрать самый простой технический bridge.

Допустимые варианты:

1. Rival Encounter signal:
   ```text
   competition_requested(request)
   ```
   и последующий:
   ```text
   submit_competition_result(result)
   ```

2. injectable runner interface/object;

3. scene-local host.

Требования:

- MODULE 06 тестируется без реальных MODULE 07;
- future minigame scene легко подключается;
- нет global EventBus;
- нет generic minigame framework.

---

# 37. Test competition runner

Создать технический fake/stub runner, который умеет вернуть:

```text
WIN CLOSE
WIN CRUSHING
LOSS CLOSE
LOSS CRUSHING
```

по test command.

Он НЕ является gameplay minigame.

---

# 38. Victory

При:

```text
PLAYER_WIN
```

последовательность:

1. убедиться, что rival ещё не defeated;
2. `mark_rival_defeated(rival_id)`;
3. если впервые:
   ```text
   add_authority(rival.authority_reward)
   ```
4. сформировать final encounter result;
5. отправить notifications;
6. закончить session.

---

# 39. authority_reward

Размер победной награды берётся ТОЛЬКО из:

```text
RivalDefinition.authority_reward
```

MODULE 06 не создаёт формулу:

```text
reward = stats difference
```

или multiplier за crushing win.

---

# 40. Zero reward

`authority_reward = 0` технически допустим.

Победа всё равно:

- отмечает rival defeated;
- завершает encounter.

---

# 41. Victory and repeat protection

Если из-за programming error result пытаются submit повторно:

- второй commit не начисляет reward;
- session уже FINISHED;
- понятный debug error/return.

---

# 42. Loss — обычное правило

При:

```text
PLAYER_LOSS
```

обычный loss:

```text
authority_loss = 1
```

Использовать controlled `GameState.lose_authority(1)`.

Rival НЕ отмечается defeated.

Игрок может позже попробовать снова.

---

# 43. Loss at zero Authority

```text
authority = 0
```

Loss:

```text
actual authority delta = 0
```

Encounter всё равно считается поражением.

---

# 44. Crushing loss

`CRUSHING` не создаёт дополнительный штраф Авторитета.

Потеря всё равно:

```text
-1
```

Presentation позже может быть сильнее:

- игрок эмоционально/комедийно проигрывает;
- может проиграться более заметная реакция.

Но экономический штраф одинаков.

---

# 45. Close loss

То же:

```text
-1
```

Presentation мягче.

---

# 46. `Героическое поражение`

Perk:

```text
perk_muscle_heroic_defeat
```

может отменить обычный `-1`, если игрок проиграл **заметно более сильному** сопернику.

Каноническое правило MODULE 06:

```text
rival relevant characteristic
>=
player relevant characteristic + 2
```

где relevant characteristic определяется выбранным CompetitionType.

Пример:

```text
SLAP:
player muscle = 3
rival muscle = 5
=> noticeably stronger
```

---

# 47. Heroic defeat Authority effect

Если условие раздела 46 выполнено и perk куплен:

```text
authority_loss = 0
```

Поражение остаётся поражением.

Rival остаётся undefeated.

---

# 48. Heroic defeat inside date

Если encounter был запущен как часть будущего Dating context:

- Rival Framework возвращает информацию:
  ```text
  heroic_defeat_triggered = true
  ```
- Dating Module позже добавляет к результату:
  ```text
  VULNERABILITY
  RISK
  ```

MODULE 06 сам relationship/tags не меняет.

---

# 49. Context

Чтобы future Dating мог знать, что encounter принадлежит свиданию, start API может принимать небольшой typed context marker.

Canonical semantics:

```text
WORLD
DATE
STORY
```

Но не создавать generic context dictionary.

Если Cursor считает enum из трёх значений лишним сейчас, допустим minimal boolean/source enum.

Требование:

- Future Dating может отличить date encounter;
- Framework не знает `girl_id`, если это не требуется.

Если для callback нужен `context_token`, использовать opaque token, не domain data bag.

---

# 50. `Аура местного значения`

Perk:

```text
perk_aura_local_significance
```

может позволить обычному явно более низкоранговому rival уступить до мини-игры.

Не работает на:

```text
RivalDefinition.is_story == true
```

---

# 51. Local Significance — rank rule

Каноническая простая проверка:

```text
player authority
>=
rival.required_authority + 3
```

То есть игрок уже заметно выше уровня Авторитета, необходимого для вызова этого rival.

Это rank comparison, а не сравнение конкретной характеристики.

---

# 52. Почему используется required_authority

`required_authority` уже является canonical rank gate RivalDefinition.

Не добавлять новое поле:

```text
rival_authority
rival_rank
rival_power
```

только ради этого perk.

---

# 53. Local Significance flow

Работает только после того, как выбран/определён конкретный rival.

Если:

```text
has perk
AND not story
AND authority >= required_authority + 3
```

Framework предоставляет player option semantic уровня:

```text
DEMAND_CONCESSION
```

Использование НЕ обязательно.

Игрок может всё равно выбрать обычное состязание.

---

# 54. Local Significance result

Если игрок выбирает concession:

```text
PLAYER_WIN
```

без запуска мини-игры.

Victory grade:

```text
CRUSHING
```

для presentation purposes.

Дальше обычная victory flow:

- mark defeated;
- authority_reward;
- rival leaves later via presentation.

---

# 55. Local Significance usage

Один раз за конкретный encounter естественным образом.

Не хранить cooldown.

Если rival уже defeated — encounter не стартует.

---

# 56. Story rivals

Story rival:

```text
is_story = true
```

никогда не может быть skipped через Local Significance.

Даже при огромном Авторитете.

---

# 57. Story system boundary

MODULE 06 не знает:

- какая девушка связана с rival;
- завершает ли победа quest;
- открывает ли stage;
- кто показал соперника;
- когда story rival появляется.

MODULE 11 позже слушает:

```text
rival_defeated(rival_id)
```

или проверяет GameState.

---

# 58. Dating boundary

MODULE 06 не знает:

- relationship score;
- girl traits;
- date score;
- greeting/farewell;
- date success.

Если encounter запущен во время свидания:

- он временно занимает control;
- возвращает result Dating system;
- Dating решает последствия для девушки.

---

# 59. Player control mode

На время actual competition:

```text
Player control mode = MINIGAME
```

Использовать API MODULE 01.

До запуска мини-игры selection UI может использовать:

```text
MODAL_UI
```

После завершения:

- control возвращается владельцу context;
- world encounter обычно возвращает `GAMEPLAY`;
- Dating context позже может вернуть `MODAL_UI`/свой state.

Не hardcode всегда `GAMEPLAY`, если encounter вызван внешним owner.

---

# 60. Control ownership

Rival Encounter должен корректно вернуть control тому system, который его передал.

Cursor должен выбрать простой explicit approach.

Не строить global input stack framework, если можно передать:

```text
return_control_mode
```

или callback owner.

---

# 61. Encounter cancellation

После фактического старта encounter нет отдельной gameplay-кнопки:

```text
Cancel
Run Away
Decline
```

если она не предусмотрена будущей постановкой.

До запуска player-initiated challenge игрок просто может не нажимать `[E]`.

Rival-initiated story scenes должны запускаться только когда Story system действительно хочет состязание.

---

# 62. Player refusal не вводится

Не придумывать:

- отказ = -Authority;
- cowardice;
- cooldown.

Системы отказа пока нет.

---

# 63. Rival actor integration

MODULE 04 оставил нейтральный CharacterActor.

MODULE 06 может создать тонкий production adapter:

```text
RivalActor
```

или:

```text
RivalInteractable
```

Минимальная ответственность:

- `rival_id`;
- получить RivalDefinition;
- при player interact запросить Rival Encounter;
- обновить доступность после defeat.

Не копировать:

- stats;
- authority reward;
- display name

в scene вручную.

Они берутся из RivalDefinition.

---

# 64. RivalActor не AI

Adapter НЕ реализует:

- navigation;
- wander;
- approach detection;
- daily routine;
- combat.

Rival-initiated encounter вызывается explicit World/Story trigger.

---

# 65. Player interaction prompt

Для обычного доступного rival допустим semantic prompt:

```text
[E] Вызвать
```

Если authority недостаточен, два допустимых UX:

1. prompt остаётся:
   ```text
   [E] Вызвать
   ```
   и rival отказывает после взаимодействия;

2. prompt показывает requirement.

Выбрать **вариант 1**.

Причина:

- отказ самца является частью мира/комедии;
- игрок физически узнаёт, что его не считают достойным.

MODULE 06 test UI может показывать result code.

Production реплика позже.

---

# 66. Already defeated prompt

После defeat RivalActor больше не предлагает:

```text
[E] Вызвать
```

Если visual остаётся, future content может дать другой interaction.

MODULE 06 не придумывает его.

---

# 67. RivalDefinition validation extension

Дополнительно проверить:

```text
preferred_competition
∈
allowed_competitions
```

уже существующее правило.

Также warning для production rival, если:

```text
allowed only MONEY
```

или:

```text
allowed only SIGMA
```

и progression/content stage не гарантирует доступ.

Но не делать cross-stage logic в validator.

---

# 68. Story rival reward

Story rivals используют тот же:

```text
authority_reward
```

Никакого автоматического special multiplier.

Story unlock — отдельно.

---

# 69. Characteristic access versus rival stats

Даже если player characteristic сильно ниже rival:

- challenge разрешён;
- minigame difficulty/result logic решает MODULE 07;
- Framework не запрещает «слишком сложный» contest.

Authority gate — отдельная ось.

---

# 70. No auto-win from stat comparison

Кроме explicit:

```text
AURA_LOCAL_SIGNIFICANCE
```

Framework НЕ делает:

```text
if player stat > rival stat:
    win
```

Stats передаются minigame.

---

# 71. No RNG result

Rival Encounter никогда не делает:

```text
randf() based on stats
```

Победа приходит из мини-игры.

---

# 72. Presentation events

Framework должен выдавать semantic notifications, достаточные для future presentation.

Например:

```text
encounter_started
rival_refused
competition_selected
competition_requested
encounter_won
encounter_lost
encounter_finished
```

Не обязательно ровно эти signals.

Не создавать EventBus.

---

# 73. Final Encounter Result

Создать typed result semantic уровня:

```text
rival_id
outcome
victory_grade
competition_type
authority_delta

heroic_defeat_triggered
concession_used
competition_override_used
```

Не добавлять:

- girl relationship delta;
- money;
- tags;
- quest completion.

---

# 74. Authority delta

Victory:

```text
+rival.authority_reward
```

Loss:

```text
-1
```

Heroic defeat qualifying:

```text
0
```

Loss at zero:

```text
0 actual
```

Concession victory:

```text
+rival.authority_reward
```

---

# 75. Result idempotency

Final result commit должен происходить один раз.

После `FINISHED`:

```text
submit_result()
```

отклоняется.

---

# 76. No persistence of active encounter

MODULE 06 не обязан сохранять mid-encounter session.

Save/Load MODULE 24 позже определит:

- можно ли сохраняться во время minigame;
- как восстанавливать active scene.

Persistent только:

```text
defeated_rivals
authority
```

---

# 77. Test Rival content

Поскольку production rivals ещё не наполнены, создать isolated test definitions.

Минимум:

```text
rival_test_low
rival_test_high
rival_test_story
rival_test_money
rival_test_sigma
```

Не включать их в production catalog.

---

# 78. `rival_test_low`

Пример:

```text
required_authority = 0
authority_reward = 1

stats = 2 / 2 / 2 / 2

preferred = SLAP
allowed = [SLAP, DANCE]
is_story = false
```

---

# 79. `rival_test_high`

Пример:

```text
required_authority = 5
authority_reward = 3

stats = 6 / 6 / 6 / 6

preferred = DANCE
allowed = [SLAP, DANCE, MONEY, SIGMA]
is_story = false
```

---

# 80. `rival_test_story`

```text
is_story = true
required_authority = 0
authority_reward = 2
preferred = SLAP
allowed includes SLAP
```

Используется для проверки Local Significance запрета.

---

# 81. Test scene

Создать:

```text
res://game/rivals/test/rival_encounter_test.tscn
```

Содержит:

- Player;
- 2–3 test RivalActors;
- minimal selection UI;
- fake competition runner;
- debug output current authority/session/result.

Не делать production arena.

---

# 82. Test — player initiates

Authority достаточен.

Player взаимодействует.

Ожидается:

```text
initiator = PLAYER
competition selection = player
```

---

# 83. Test — low authority refusal

```text
authority = 2
required = 5
```

Player initiates.

Ожидается:

```text
RIVAL_REFUSED_LOW_AUTHORITY
```

No session/minigame.

No authority change.

---

# 84. Test — rival initiates bypass gate

```text
authority = 2
required = 5
```

Start:

```text
RIVAL initiator
```

Ожидается:

- required_authority не блокирует;
- rival chooses preferred.

---

# 85. Test — default competition access

Without Capital/Aura access perks:

```text
SLAP available
DANCE available
MONEY locked
SIGMA locked
```

---

# 86. Test — Capital access

Купить:

```text
perk_capital_payable_intent
```

Ожидается:

```text
MONEY available
```

---

# 87. Test — Aura access

Купить:

```text
perk_aura_presence_registered
```

Ожидается:

```text
SIGMA available
```

---

# 88. Test — player list intersection

Rival:

```text
allowed = [DANCE, MONEY]
```

Player no Capital perk.

Available selection:

```text
[DANCE]
```

---

# 89. Test — rival preferred locked

Rival initiates:

```text
preferred = MONEY
```

Player without Capital access.

Ожидается:

```text
COMPETITION_LOCKED
```

No silent fallback.

---

# 90. Test — Right to Say Nothing

Rival initiates with:

```text
preferred = SLAP
allowed = [SLAP, DANCE]
```

Player owns:

```text
AURA_RIGHT_TO_SAY_NOTHING
```

Ожидается:

- player can keep SLAP;
- player can choose DANCE;
- no authority penalty.

---

# 91. Test — no override without perk

То же без perk.

Chosen competition remains:

```text
SLAP
```

---

# 92. Test — She Already Started no rival effect

Иметь:

```text
AURA_SHE_ALREADY_STARTED
```

без `RIGHT_TO_SAY_NOTHING` невозможно по perk tree, но framework всё равно НЕ содержит отдельной ветки эффекта этого perk.

Static search/test подтверждает отсутствие dependency.

---

# 93. Test — win

Rival reward:

```text
3
```

Authority before:

```text
4
```

Fake result:

```text
WIN CLOSE
```

After:

```text
authority = 7
rival defeated = true
```

---

# 94. Test — crushing win same reward

Same rival clone/reset.

Fake:

```text
WIN CRUSHING
```

Reward всё равно:

```text
+3
```

---

# 95. Test — repeated reward protection

После defeat повторный encounter:

```text
ALREADY_DEFEATED
```

Authority unchanged.

---

# 96. Test — loss

Authority:

```text
4
```

Fake:

```text
LOSS CLOSE
```

After:

```text
authority = 3
rival not defeated
```

---

# 97. Test — crushing loss

Authority:

```text
4
```

Fake:

```text
LOSS CRUSHING
```

After:

```text
authority = 3
```

Не `2`.

---

# 98. Test — loss at zero

Before:

```text
0
```

After loss:

```text
0
```

Result actual authority delta:

```text
0
```

---

# 99. Test — Heroic Defeat qualifies

Chosen:

```text
SLAP
```

Player:

```text
muscle = 3
```

Rival:

```text
muscle = 5
```

Player owns:

```text
MUSCLE_HEROIC_DEFEAT
```

Loss.

Authority:

```text
unchanged
```

Result:

```text
heroic_defeat_triggered = true
```

---

# 100. Test — Heroic Defeat does not qualify

Player:

```text
muscle = 4
```

Rival:

```text
muscle = 5
```

Difference only `1`.

Loss:

```text
authority -1
heroic_defeat_triggered = false
```

---

# 101. Test — Heroic Defeat relevant characteristic

Rival может быть значительно сильнее по Muscle, но contest:

```text
DANCE
```

Сравнивать:

```text
appearance
```

а не muscle.

---

# 102. Test — Local Significance

Player owns:

```text
AURA_LOCAL_SIGNIFICANCE
```

Rival:

```text
required_authority = 2
is_story = false
```

Player authority:

```text
5
```

Порог:

```text
5 >= 2 + 3
```

Concession option available.

---

# 103. Test — Local Significance below margin

Player:

```text
authority = 4
```

Rival required:

```text
2
```

```text
4 < 5
```

No concession.

---

# 104. Test — Local Significance story immunity

Даже если:

```text
authority = 100
```

и story rival required = 0:

```text
concession unavailable
```

---

# 105. Test — Local Significance victory

Player uses concession.

Expected:

```text
WIN
CRUSHING
no minigame request
rival defeated
authority += reward
concession_used = true
```

---

# 106. Test — session snapshot

Start contest:

```text
player muscle = 3
```

После start debug повышает stat до 4.

Competition request/session продолжает использовать:

```text
3
```

---

# 107. Test — duplicate result

После FINISHED второй submit:

- rejected;
- no second reward/loss;
- no second finish signal.

---

# 108. Test — GameState regression

MODULE 02 tests проходят после:

- `lose_authority`;
- `defeated_rivals`;
- reset extension.

---

# 109. Test — Progression regression

MODULE 05:

```text
212+ / ALL PASS
```

Перки ownership продолжают работать.

---

# 110. Test — Content regression

MODULE 03 validation проходит.

Не изменять canonical RivalDefinition без необходимости.

---

# 111. Test — Character regression

MODULE 04 проходит.

RivalActor может использовать CharacterActor без изменения framework.

---

# 112. Test — FPS regression

Player:

- movement;
- interaction;
- modal;
- minigame mode;
- pause

продолжает работать.

---

# 113. Test — no relationship contamination

Static/code search Rival module не должен менять:

```text
girl_relationships
experience
upgrade_points
```

кроме Progression access read.

---

# 114. Architecture choice

Cursor самостоятельно выбирает наиболее простой owner architecture.

Разумные варианты:

1. scene-local `RivalEncounterController`;
2. autoload `RivalEncounters`;
3. small controller instantiated владельцем world/date scene.

При выборе учитывать:

- encounter может стартовать из world и date;
- session transient;
- persistent state уже в GameState;
- minigame может временно менять player control;
- не нужен глобальный manager ради нескольких методов.

Если autoload выбран, canonical name:

```text
RivalEncounters
```

Не:

```text
MaleManager
CompetitionManager
RivalSystemManager
```

Decision записать.

---

# 115. No multiple simultaneous encounters

Один local player не участвует в двух rival encounters одновременно.

Framework должен отклонять новый start, пока текущий session:

```text
not FINISHED
```

Result:

```text
ENCOUNTER_ALREADY_ACTIVE
```

Не создавать queue.

---

# 116. Error safety

Если minigame возвращает malformed result:

- state не меняется;
- session не commit-ит Authority;
- debug error.

Если RivalDefinition исчез/invalid во время session:

- использовать captured valid reference/ID data согласно выбранному approach;
- не выдавать random fallback.

---

# 117. Module file placement

Canonical area:

```text
res://game/rivals/
```

Возможная структура:

```text
game/rivals/
├── rival_encounter.gd
├── rival_encounter_session.gd
├── rival_competition_request.gd
├── rival_competition_result.gd
├── rival_actor.gd
└── test/
```

Не обязаны быть ровно эти файлы.

Не дробить на десяток микроклассов, если typed lightweight objects можно объединить.

---

# 118. Documentation

Обновить:

```text
docs/gdd/04_male_status_system.md
docs/gdd/...dating/relationship relevant file
docs/PERK_EFFECT_CONTRACTS.md
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
```

Зафиксировать новые пользовательские решения из section 0.

---

# 119. Что MODULE 06 НЕ реализует

Категорически не реализовывать:

- slap mechanics;
- dance mechanics;
- sigma mechanics;
- money mechanics;
- dating scoring;
- girl relationship;
- Experience rewards;
- story progression;
- salary calculation;
- rival navigation;
- random rival spawn;
- defeat animations;
- crying;
- running away;
- production dialogue;
- final UI;
- save/load;
- audio/VFX.

---

# 120. Definition of Done

MODULE 06 завершён только если:

- [ ] GDD обновлён: обычный loss = Authority -1;
- [ ] GDD обновлён: relationship -5..+5;
- [ ] GDD обновлён: Experience never decreases;
- [ ] perk contract обновлён: override has no penalty;
- [ ] `SHE_ALREADY_STARTED` rival effect удалён;
- [ ] defeated_rivals хранится в GameState;
- [ ] reset очищает defeated rivals;
- [ ] есть controlled Authority loss;
- [ ] Authority не падает ниже 0;
- [ ] есть PLAYER/RIVAL initiator;
- [ ] player-initiated low-authority refusal работает;
- [ ] rival-initiated bypasses required_authority;
- [ ] player выбирает competition, если initiator PLAYER;
- [ ] rival выбирает preferred, если initiator RIVAL;
- [ ] SLAP/DANCE доступны по умолчанию;
- [ ] MONEY gated Capital perk;
- [ ] SIGMA gated Aura perk;
- [ ] allowed competition intersection работает;
- [ ] Right To Say Nothing override работает без penalty;
- [ ] chosen competition immutable после start;
- [ ] typed competition request существует;
- [ ] typed WIN/LOSS result существует;
- [ ] CLOSE/CRUSHING grade существует;
- [ ] fake runner существует;
- [ ] victory даёт exact authority_reward;
- [ ] rival defeated only on win;
- [ ] repeat reward невозможен;
- [ ] ordinary loss = -1;
- [ ] crushing loss тоже = -1;
- [ ] Heroic Defeat threshold = relevant stat difference >=2;
- [ ] Heroic Defeat qualifying loss = 0 Authority loss;
- [ ] Local Significance threshold = required_authority +3;
- [ ] Local Significance не работает на story rivals;
- [ ] Local Significance optional;
- [ ] concession victory не запускает minigame;
- [ ] one active encounter maximum;
- [ ] result commit idempotent;
- [ ] GameState regression проходит;
- [ ] MODULE 03 regression проходит;
- [ ] MODULE 04 regression проходит;
- [ ] MODULE 05 regression проходит;
- [ ] FPS regression проходит;
- [ ] Rival module не меняет relationships/Experience;
- [ ] MODULE 07 не реализован заранее.

---

# 121. Порядок выполнения Cursor

## Step 1 — documentation pre-flight

Сначала внести утверждённые product clarifications.

---

## Step 2 — audit current state

Проверить:

- GameState authority API;
- purchased perks API;
- RivalDefinition;
- CompetitionType;
- CharacterActor;
- Interactable;
- Player control modes.

---

## Step 3 — choose architecture

Выбрать session/controller ownership.

Сравнить best-practice варианты.

---

## Step 4 — extend GameState

Добавить:

```text
defeated_rivals
lose_authority
```

и tests.

---

## Step 5 — competition access

Реализовать progression gates и intersection.

---

## Step 6 — session flow

Реализовать:

```text
start
choose
override
request competition
submit result
resolve
finish
```

---

## Step 7 — perk integrations

Только MODULE 06 contracts:

```text
RIGHT_TO_SAY_NOTHING
HEROIC_DEFEAT
LOCAL_SIGNIFICANCE
```

и access perks:

```text
CAPITAL_PAYABLE_INTENT
AURA_PRESENCE_REGISTERED
```

---

## Step 8 — RivalActor adapter

Добавить минимальное world interaction.

---

## Step 9 — fake runner/test scene

Не реализовывать настоящую мини-игру.

---

## Step 10 — full validation

Прогнать sections 82–113.

---

## Step 11 — regressions

Все предыдущие modules.

---

## Step 12 — documentation

Обновить Technical Decisions/Project Structure.

---

# 122. Формат финального отчёта Cursor

## Product clarifications applied

Подтвердить:

```text
loss = -1 Authority
override penalty = 0
relationship canonical range = -5..+5
Experience never decreases
SHE_ALREADY_STARTED has no Rival effect
```

## Architecture

Как устроены session/controller/minigame bridge.

## GameState changes

```text
defeated_rivals
authority loss
```

## Challenge rules

Подтвердить PLAYER/RIVAL flows.

## Perk integrations

Перечислить только реально реализованные MODULE 06 perks.

## Minigame boundary

Подтвердить:

```text
fake runner only
real MODULE 07 not implemented
```

## Validation

Результаты MODULE 06 tests и всех regressions.

## Files changed

Основные файлы.

## Product questions

Если нет:

```text
None.
```

---

# 123. Запрет продолжения

После успешного MODULE 06:

**НЕ начинать MODULE 07 — Rival Minigames.**

Остановиться и дождаться отдельной спецификации.
