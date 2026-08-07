# MODULE 07D — MONEY CONTEST / ДЕНЕЖНОЕ ПРОТИВОСТОЯНИЕ

**Проект:** Date Factory  
**Модуль:** 07D — Rival Minigame: Money Contest  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать четвёртое и последнее базовое мужское состязание — демонстративный денежный аукцион — и завершить routing всех четырёх типов через `RivalCompetitionRunner`  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/04_male_status_system.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущие модули:** MODULE 07A Slap, 07B Dance, 07C Sigma

---

# 1. Цель MODULE 07D

После завершения полный базовый rival loop должен поддерживать все четыре типа:

```text
SLAP
DANCE
SIGMA
MONEY
```

Money Contest flow:

```text
Rival Encounter
→ MONEY
→ RivalCompetitionRunner
→ MoneyMinigame
→ демонстративное повышение ставки
→ PLAYER_WIN / PLAYER_LOSS
→ CLOSE / CRUSHING
→ RivalEncounters
```

Денежное противостояние должно быть **проще остальных**.

Игрок не управляет сложной экономикой.

Основной вопрос:

> насколько далеко ты готов зайти ради совершенно ненужного предмета, прежде чем другой самец сдастся?

---

# 2. Каноническая фантазия

В каждом раунде два самца спорят за нелепый объект.

Например визуально это может быть:

- стул;
- тостер;
- парковочный конус;
- стакан;
- право первым заказать кофе;
- другой простой placeholder prop.

Конкретный художественный контент позже.

Core-механика не зависит от типа объекта.

Соперник начинает с демонстративной ставки.

Игрок выбирает:

```text
ОСТАНОВИТЬСЯ
ПОВЫСИТЬ
ПЕРЕБИТЬ
ВЫКУПИТЬ
```

Последние два варианта открываются уровнем Капитала.

---

# 3. Главное различие Деньги / Капитал

Не смешивать:

```text
GameState.money
```

и:

```text
PlayerCharacteristic.CAPITAL
```

## Деньги

Реальный расходуемый баланс.

Определяет:

```text
может ли игрок физически оплатить ставку
```

## Капитал

Характеристика.

Определяет:

```text
какие формы финансового давления доступны
```

Высокий Капитал НЕ создаёт деньги из воздуха.

---

# 4. Access perk

`CAPITAL_PAYABLE_INTENT` уже открывает MONEY в MODULE 06.

Если Money request уже пришёл:

```text
competition_type == MONEY
```

MoneyMinigame не повторяет access gate.

---

# 5. Не создавать отдельную экономическую игру

Запрещено:

- market simulation;
- portfolio;
- interest;
- loans;
- stock trading;
- debt;
- credit score;
- bank UI;
- negotiation tree;
- bluff probability;
- hidden random success roll;
- dynamic pricing service;
- economy AI;
- rival bank account;
- inventory valuation;
- auction house system;
- persistent purchased junk inventory в MODULE 07D.

---

# 6. Match score

Как остальные rival minigames.

## Ordinary rival

```text
target_score = 3
```

## Story rival

```text
target_score = 5
```

Каждый auction round даёт ровно одно очко одной стороне.

---

# 7. Раунд

Каждый round:

```text
1. появляется новый абсурдный лот
2. rival делает opening bid
3. player turn
4. player повышает или останавливается
5. если rival не сдаётся — он автоматически повышает
6. снова player turn
7. пока одна сторона не уступит
```

---

# 8. Opening bid

Каждый round начинается:

```text
current_bid_level = 1
```

Это ставка rival.

Игрок должен либо:

```text
повысить выше 1
```

либо:

```text
остановиться
```

---

# 9. Bid levels

Внутренняя ставка хранится не как готовая сумма, а как:

```text
bid_level: int
```

Сумма:

```text
bid_amount = bid_level * stake_unit
```

---

# 10. Stake unit

В начале всего match snapshot-нуть:

```text
starting_money
```

и вычислить:

```text
stake_unit =
max(
    1,
    floor(starting_money / float(target_score * 15))
)
```

Использовать integer результат.

---

# 11. Зачем stake unit зависит от стартового баланса

Экономика Salary Mine ещё не забалансирована.

Поэтому Money Contest не должен сейчас жёстко предполагать, что нормальная сумма:

```text
10
100
1000
```

Игра масштабирует абсурдную ставку относительно текущего кошелька.

При этом:

- Деньги реально расходуются;
- богатый игрок ставит больше абсолютных денег;
- процентное давление остаётся примерно управляемым.

---

# 12. starting_money == 0

Если на старте:

```text
starting_money <= 0
```

не растягивать матч на пять бессмысленных раундов.

Сразу завершить:

```text
PLAYER_LOSS
CRUSHING
```

Debug summary:

```text
"MONEY 0 funds"
```

Никаких денег не списывается.

RivalEncounters дальше применяет обычное поражение по Авторитету.

Это не access gate: игрок формально умеет участвовать, но пришёл без денег.

---

# 13. Money snapshot и реальный баланс

`stake_unit` snapshot-ится в начале match.

Но доступность конкретной ставки проверяет **текущий**:

```text
GameState.money
```

потому что winning rounds реально списывают Деньги.

То есть после каждой покупки следующий round может стать опаснее.

---

# 14. Rival financial ceiling

У rival нет отдельного баланса денег.

Использовать его snapshot:

```text
rival_capital
```

для определения того, насколько далеко он готов зайти в конкретном round.

---

# 15. Rival max level

На каждый новый round:

```text
rival_max_level =
clamp(
    2 + floor(rival_capital / 2) + variation,
    2,
    7
)
```

где:

```text
variation ∈ {-1, 0, +1}
```

из deterministic RNG.

---

# 16. RNG не является шансом победы

RNG выбирает только:

```text
характер конкретного auction round
```

После этого `rival_max_level` фиксирован.

Результат НЕ определяется:

```text
randf() < success
```

Игрок получает визуальные tells и сам решает, продолжать ли.

Для tests можно задать seed.

---

# 17. Значение rival_max_level

Это максимальный bid level, до которого rival готов автоматически повышать.

Игрок выигрывает round, когда делает:

```text
player_bid_level > rival_max_level
```

---

# 18. Rival counter

Если player bid:

```text
<= rival_max_level
```

rival не сдаётся.

Он автоматически делает:

```text
rival_bid_level =
min(
    player_bid_level + 1,
    rival_max_level
)
```

и:

```text
current_bid_level = rival_bid_level
```

После короткой реакции снова player turn.

---

# 19. Если rival дошёл до max

Когда:

```text
current_bid_level == rival_max_level
```

следующая успешная ставка игрока должна быть:

```text
> rival_max_level
```

и тогда rival сдаётся.

---

# 20. Player actions

Canonical enum semantic:

```text
STOP
RAISE
OUTBID
BUYOUT
```

---

# 21. STOP — Остановиться

Всегда доступно.

Игрок добровольно уступает current auction round.

Result:

```text
rival_score += 1
money spent = 0
```

Следующий round начинается, если match не закончен.

---

# 22. RAISE — Повысить

Всегда доступно при наличии денег.

```text
new_level = current_bid_level + 1
```

UI:

```text
ПОВЫСИТЬ
```

---

# 23. OUTBID — Перебить

Открывается если:

```text
player_capital >= 3
```

```text
new_level = current_bid_level + 2
```

UI:

```text
ПЕРЕБИТЬ
```

Это более агрессивная форма ставки.

---

# 24. BUYOUT — Выкупить

Открывается если:

```text
player_capital >= 6
```

```text
new_level = current_bid_level + 3
```

UI:

```text
ВЫКУПИТЬ
```

Это не perk.

Это естественная форма действия высокого Капитала.

---

# 25. Capital forms не гарантируют экономию

Большой jump:

- быстрее давит rival;
- уменьшает количество exchanges;
- но может заметно overshoot его ceiling;
- значит игрок может заплатить больше, чем при аккуратных +1.

Это и есть небольшой decision tradeoff.

---

# 26. Affordability

Для каждого action вычислить:

```text
new_amount = new_level * stake_unit
```

Action доступен только если:

```text
GameState.can_afford(new_amount)
```

или эквивалентная canonical Money API.

---

# 27. Нельзя нажать недоступную ставку

Недоступный action:

- visually disabled;
- показывает сумму;
- input не меняет state;
- не считается STOP.

---

# 28. Нет накопительного расхода ставок

Money Contest работает как аукцион.

Пока rival ещё не сдался:

```text
игрок НЕ платит промежуточные bids
```

Деньги списываются только если player выиграл round.

То есть оплачивается:

```text
final winning purchase
```

---

# 29. Player wins auction round

Если:

```text
new_level > rival_max_level
```

rival folds.

До начисления score проверить ещё раз:

```text
can_afford(final_amount)
```

Затем атомарно:

```text
spend_money(final_amount)
player_score += 1
```

---

# 30. Если spend внезапно не удался

Нормально это невозможно в synchronous single-player flow.

Но если external/debug state изменил Money между availability check и commit:

- round НЕ засчитывается player;
- state не должен стать частично применённым;
- debug error;
- безопаснее трактовать как невозможность продолжить / forced STOP.

Не создавать transaction framework.

---

# 31. Rival round win

При:

- STOP;
- decision timeout;
- отсутствии любого доступного raise action;

```text
rival_score += 1
```

Player Money не меняется.

---

# 32. Decision timeout

Чтобы дуэль не зависала:

```text
decision_timeout = 4.0 seconds
```

На каждый player turn timer начинается заново.

Если input не выбран:

```text
STOP
```

автоматически.

UI показывает короткий countdown/progress.

---

# 33. Если денег не хватает ни на одну ставку

Если:

```text
RAISE unavailable
OUTBID unavailable
BUYOUT unavailable
```

не ждать 4 секунды.

После короткого:

```text
0.50 s
```

feedback:

```text
НЕЧЕМ ПОВЫШАТЬ
```

автоматически проиграть round.

---

# 34. Rival tell

Игрок должен понимать приближение к ceiling.

После каждого rival bid показать реакцию.

Вычислить:

```text
gap = rival_max_level - current_bid_level
```

---

# 35. Tell states

## gap >= 3

```text
СПОКОЕН
```

## gap == 2

```text
СМОТРИТ НА СУММУ
```

## gap == 1

```text
НАПРЯГСЯ
```

## gap == 0

```text
ПОСЛЕДНЯЯ ПОЗИЦИЯ
```

Это не буквальные обязательные production реплики NPC.

Это semantic UI state / placeholder label.

---

# 36. Tell честный

Никакого ложного tell.

Игрок не должен угадывать скрытую probability.

Tell точно соответствует расстоянию до fixed ceiling.

---

# 37. Player Capital не раскрывает точный ceiling

Не создавать отдельную detective submechanic.

Капитал уже даёт дополнительные actions.

Tell одинаково честный для всех.

---

# 38. Раундовый лот

Для visual variety создать маленький локальный catalog display names, например:

```text
"Стул"
"Тостер"
"Конус"
"Пепельница"
"Чужая кружка"
"Право занять этот столик"
```

Это presentation-only.

Не создавать ContentDB domain для auction lots в MODULE 07D.

---

# 39. Lot selection

Выбирать pseudo-randomly.

Не повторять тот же lot два rounds подряд, если возможно.

Gameplay mechanics от lot не меняются.

---

# 40. Player actually buys useless object

На победе round UI фиксирует:

```text
КУПЛЕНО ЗА <amount>
```

Но MODULE 07D НЕ добавляет объект в persistent inventory.

По умолчанию это одноразовая комедийная покупка внутри состязания.

---

# 41. Score target

Ordinary:

```text
3
```

Story:

```text
5
```

После каждого round проверять match end сразу.

---

# 42. VictoryGrade

Использовать ту же общую score difference formula.

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

# 43. Match money summary

MoneyMinigame хранит:

```text
money_spent_total
```

Это сумма реально оплаченных winning rounds.

Debug summary, например:

```text
"MONEY 3:1 spent=24"
```

---

# 44. Money loss does not refund purchases

Если player выиграл два auction rounds, заплатил деньги, но потом проиграл весь match:

```text
потраченные Деньги остаются потраченными
```

Это реальный риск финансового состязания.

`CAPITAL_DIGNITY_REFUND` здесь НЕ работает.

Его contract относится к paid Dating actions.

---

# 45. `CAPITAL_PAYABLE_INTENT`

В MODULE 07D этот perk не даёт дополнительный modifier.

Он уже выполнил свою роль:

```text
открыл MONEY contest
```

Не давать ему второй hidden bonus.

---

# 46. `CAPITAL_HOSTILE_ACQUISITION`

Contract:

> после специально отмеченной денежной победы небольшой объект мира может остаться в собственности героя.

MODULE 07D должен реализовать integration hook, но НЕ persistent world ownership.

---

# 47. Использовать existing `competition_modifier_id`

`RivalDefinition` уже имеет opaque:

```text
competition_modifier_id
```

Теперь для Money определить canonical modifier:

```text
money_acquisition
```

Technical ID:

```text
&"money_acquisition"
```

Это означает:

> победа в MONEY у этого rival является authored acquisition-capable victory.

---

# 48. Default rivals

Если:

```text
competition_modifier_id != &"money_acquisition"
```

Hostile Acquisition ничего не делает.

Не превращать каждую победу деньгами в покупку мира.

---

# 49. Hostile Acquisition trigger

После полного MATCH victory:

```text
outcome == PLAYER_WIN
```

если одновременно:

```text
player owns CAPITAL_HOSTILE_ACQUISITION
AND
rival.competition_modifier_id == &"money_acquisition"
```

`RivalCompetitionRunner` emits dedicated signal semantic уровня:

```text
hostile_acquisition_requested(rival_id: StringName)
```

или эквивалентный однозначный signal.

---

# 50. No world mutation in 07D

MODULE 07D НЕ:

- ставит story flag;
- меняет owner объекта;
- открывает shortcut;
- сохраняет property.

MODULE 11/12 позже решит:

```text
что именно было приобретено
что изменилось в мире
```

---

# 51. Signal occurs once

Acquisition signal:

- максимум один раз за завершённый Money match;
- только после победы;
- до/во время runner cleanup в предсказуемом порядке.

Repeated result submit не повторяет signal.

---

# 52. Hostile Acquisition does not cost extra

Нет дополнительной цены сверх уже потраченных auction Money.

Perk меняет последствия победы, не цену.

---

# 53. No Hostile Acquisition on round win

Не trigger-ить после каждого выигранного auction round.

Только после:

```text
всего Money match PLAYER_WIN
```

---

# 54. No grade requirement

`CLOSE` и `CRUSHING` обе считаются money victory.

Если authored modifier стоит и perk куплен:

```text
Hostile Acquisition trigger
```

для любой победы.

---

# 55. Runner route after MODULE 07D

Должно быть:

```text
SLAP  → implemented
DANCE → implemented
SIGMA → implemented
MONEY → implemented
```

Не должно остаться:

```text
unsupported competition_type=MONEY
```

в production route.

---

# 56. All four minigames use one Runner

Не создавать:

```text
MoneyCompetitionHost
MoneyRunner
AuctionManager
```

Production execution owner остаётся:

```text
RivalCompetitionRunner
```

---

# 57. Control mode

Во время Money:

```text
MINIGAME
```

Mouse должен быть visible/free для UI buttons.

Предпочтительно:

```text
Input.MOUSE_MODE_VISIBLE
```

если Player API позволяет `enter_minigame(mouse_mode)`.

---

# 58. Input

Money можно полностью пройти мышью.

Keyboard shortcuts допустимы:

```text
1 = STOP
2 = RAISE
3 = OUTBID
4 = BUYOUT
```

но не обязательны для acceptance.

Если добавляются:

- не создавать новые Input Map actions;
- использовать `_unhandled_key_input`/key mapping локально только если это соответствует текущему style.

Предпочтение — обычные UI Buttons.

---

# 59. UI

Functional overlay показывает:

```text
Ты <score> : <score> Соперник
цель N

Лот: <name>

Текущая ставка:
<amount>

Твои Деньги:
<money>

Соперник:
<tell>

[ОСТАНОВИТЬСЯ]
[ПОВЫСИТЬ — amount]
[ПЕРЕБИТЬ — amount]
[ВЫКУПИТЬ — amount]
```

Locked Capital actions могут показываться:

```text
Капитал 3
Капитал 6
```

или быть скрыты.

Предпочтительно показывать disabled с requirement, чтобы stat progression читалась.

---

# 60. Rival counter feedback

После player bid, если rival не fold:

```text
СОПЕРНИК ПОВЫСИЛ ДО <amount>
```

коротко:

```text
~0.40 s
```

затем новый player turn.

---

# 61. Rival fold feedback

```text
СОПЕРНИК ОТКАЗАЛСЯ ПЛАТИТЬ
КУПЛЕНО ЗА <amount>
```

коротко:

```text
~0.60 s
```

затем score update / next round.

---

# 62. Player stop feedback

```text
ТЫ РЕШИЛ СОХРАНИТЬ ДЕНЬГИ
```

Rival +1.

Не писать длинные joke lines в mechanic core.

---

# 63. Presentation

World остаётся видимым.

Rival CharacterActor:

- counter bid → `gesture`;
- fold → `react`;
- player stop → `gesture`.

Fallback MODULE 04.

Не требовать новых animations.

---

# 64. Money spending source

Использовать canonical GameState API:

```text
can_afford_money / spend_money
```

или фактические существующие names.

Не мутировать поле Money напрямую.

---

# 65. MoneyMinigame boundary

В отличие от Slap/Dance/Sigma, MoneyMinigame **имеет право менять GameState.money**, потому что GDD прямо требует реального расхода валюты.

Но MoneyMinigame НЕ меняет:

```text
Authority
defeated_rivals
Experience
Upgrade Points
relationships
```

---

# 66. Headless core

Предпочтительно:

```text
MoneyMatch
```

отделить от UI.

Но pure headless core не должен напрямую зависеть от Autoload GameState, если это мешает тестам.

Разумный contract:

- core вычисляет required amount / round result;
- MoneyMinigame/runner вызывает GameState affordability/spend;
- затем сообщает core successful payment.

Cursor может выбрать иной простой вариант.

Главное — money commit testable и атомарный.

---

# 67. Suggested architecture

```text
MoneyMatch
```

хранит:

- scores;
- target;
- player_capital;
- rival_capital;
- stake_unit;
- current bid level;
- rival max;
- round state;
- decision timer;
- RNG;
- total committed spending;
- finished result.

UI:

```text
MoneyMinigame
```

владеет:

- Buttons;
- GameState Money read/spend;
- presentation;
- `match_finished`.

---

# 68. Round phases

Canonical semantic:

```text
ROUND_INTRO
PLAYER_DECISION
RIVAL_RESPONSE
ROUND_FEEDBACK
FINISHED
```

Не строить generic FSM framework.

---

# 69. Decision input guard

На каждый PLAYER_DECISION принимается один action.

После click:

- buttons disabled;
- repeated click не вызывает второй raise.

---

# 70. No double spending

Winning auction payment должен commit-иться ровно один раз.

Даже если UI callback/result callback повторился.

---

# 71. Deterministic RNG

Test seed контролирует:

- rival max variation;
- lot sequence.

Не Money values.

---

# 72. Test fixtures

Использовать existing test rivals либо добавить Money-specific test rival.

Минимум:

```text
rival_test_money
rival_test_money_acquisition
```

Test-only.

---

# 73. Acquisition test definition

`rival_test_money_acquisition`:

```text
allowed includes MONEY
preferred MONEY
competition_modifier_id = &"money_acquisition"
```

Не включать production catalog.

---

# 74. Test — Runner route

MONEY:

```text
→ MoneyMinigame
```

No unsupported error.

---

# 75. Test — all four routes

Smoke:

```text
SLAP
DANCE
SIGMA
MONEY
```

каждый route создаёт правильный minigame.

---

# 76. Test — zero money

```text
money = 0
```

Money starts:

```text
PLAYER_LOSS
CRUSHING
money remains 0
```

exactly once.

---

# 77. Test — stake unit

Example ordinary:

```text
starting_money = 900
target=3

floor(900/(3*15))
=20
```

```text
stake_unit=20
```

---

# 78. Test — minimum stake

```text
starting_money=10
target=5

floor(10/75)=0
=> stake_unit=1
```

---

# 79. Test — rival max

```text
rival_capital=4
variation=0

2 + floor(4/2)
=4
```

---

# 80. Test — rival max clamp low

Extreme low + variation:

```text
>=2
```

---

# 81. Test — rival max clamp high

Extreme:

```text
<=7
```

---

# 82. Test — RAISE unlock

Any player Capital:

```text
+1 available
```

if affordable.

---

# 83. Test — OUTBID unlock

```text
capital=2 → locked
capital=3 → unlocked
```

---

# 84. Test — BUYOUT unlock

```text
capital=5 → locked
capital=6 → unlocked
```

---

# 85. Test — affordability

Current bid:

```text
3
stake_unit=10
money=45
```

RAISE to 4:

```text
40 available
```

OUTBID to 5:

```text
50 unavailable
```

---

# 86. Test — no intermediate spending

Player raises multiple times, rival counters.

Until rival folds:

```text
money unchanged
```

---

# 87. Test — player round win

```text
rival_max=4
current=4
RAISE→5
stake_unit=10
money=100
```

Expected:

```text
spend 50
player_score +1
money=50
```

---

# 88. Test — overshoot

```text
rival_max=4
current=3
BUYOUT +3 →6
```

Player wins and pays:

```text
6*stake_unit
```

not minimal theoretical 5.

---

# 89. Test — STOP

Money unchanged.

Rival +1.

---

# 90. Test — timeout

4.0 seconds without decision:

```text
STOP behavior
```

---

# 91. Test — broke forced stop

No affordable raise:

```text
0.50 feedback
rival +1
```

---

# 92. Test — match target ordinary

```text
3
```

---

# 93. Test — match target story

```text
5
```

---

# 94. Test — previous purchases persist on full loss

Player spends:

```text
40
30
```

on two won rounds, then rival wins whole match.

Expected:

```text
70 remains spent
```

No refund.

---

# 95. Test — grade ordinary

Exact:

```text
3:2 CLOSE
3:1 CRUSHING
2:3 CLOSE
1:3 CRUSHING
```

---

# 96. Test — grade story

Exact matrix same 07A–C.

---

# 97. Test — no Dignity Refund

Own:

```text
CAPITAL_DIGNITY_REFUND
```

Lose Money Contest.

Previously spent auction money:

```text
not refunded
```

---

# 98. Test — Payable Intent no extra modifier

Once request exists, owning Payable Intent does not:

- discount;
- refund;
- widen action levels.

---

# 99. Test — Hostile Acquisition default

Perk owned.

Normal Money rival without modifier.

Win.

Expected:

```text
no acquisition signal
```

---

# 100. Test — Hostile Acquisition marked

Perk owned.

Rival:

```text
competition_modifier_id=&"money_acquisition"
```

Win.

Expected:

```text
hostile_acquisition_requested(rival_id)
```

exactly once.

---

# 101. Test — marked without perk

No perk.

Marked rival.

Win:

```text
no signal
```

---

# 102. Test — marked loss

Perk owned.

Marked rival.

Loss:

```text
no signal
```

---

# 103. Test — CLOSE marked win

Signal occurs.

No CRUSHING requirement.

---

# 104. Test — acquisition does not mutate world

No:

```text
story flag
location unlock
object ownership
```

inside MODULE 07D.

Only hook.

---

# 105. Test — exactly-once spending

Simulate repeated UI callback around winning bid.

Expected:

```text
one spend
one player point
```

---

# 106. Test — exactly-once match submit

Runner submits once.

---

# 107. Test — Money summary

Result debug includes:

```text
score
total spent
```

---

# 108. Test — no Authority mutation in Money

Static/code:

```text
add_authority absent
lose_authority absent
mark_rival_defeated absent
```

RivalEncounters owns these.

---

# 109. Test — end-to-end Money win

```text
Rival
→ MONEY
→ Runner
→ Money
→ spend actual Money
→ PLAYER_WIN
→ RivalEncounters
→ Authority reward
```

---

# 110. Test — end-to-end Money loss

RivalEncounters handles:

```text
Authority -1
```

Money keeps previously committed purchases.

---

# 111. Player control

During Money:

```text
MINIGAME
mouse visible
```

After:

```text
previous mode restored
```

---

# 112. Runner cleanup

After match:

```text
active == null
busy == false
```

---

# 113. Regression all minigames

Run:

```text
07A Slap
07B Dance
07C Sigma
07D Money
```

---

# 114. Previous modules

Run all existing self-tests:

```text
MODULE 02–06
FPS
```

---

# 115. Docs

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
docs/gdd/04_male_status_system.md
```

В GDD можно уточнить конкретную текущую реализацию Money Contest, не меняя базовый дизайн.

---

# 116. Что MODULE 07D НЕ реализует

Не реализовывать:

- Salary Mine;
- passive income;
- date paid actions;
- Representation Expenses;
- Buy Problem;
- Salary Advance;
- Dignity Refund в rival contest;
- Financial Inertia;
- No Limit;
- actual persistent property acquisition;
- world shortcuts;
- inventory of auction junk;
- story consequences;
- final art/audio polish.

---

# 117. Definition of Done

MODULE 07D завершён только если:

- [ ] MONEY route implemented;
- [ ] all 4 competition types routed;
- [ ] one canonical RivalCompetitionRunner;
- [ ] no CompetitionHost terminology;
- [ ] current Money really spends on won auction rounds;
- [ ] Capital is not Money;
- [ ] target 3/5;
- [ ] bid_level system works;
- [ ] stake_unit formula exact;
- [ ] zero-money immediate loss works;
- [ ] rival max formula exact;
- [ ] seeded variation exact;
- [ ] RAISE +1 always;
- [ ] OUTBID +2 at Capital >=3;
- [ ] BUYOUT +3 at Capital >=6;
- [ ] affordability checks exact;
- [ ] intermediate bids cost 0;
- [ ] final winning bid spends actual Money once;
- [ ] STOP loses round with no spend;
- [ ] 4s timeout behaves as STOP;
- [ ] broke forced stop works;
- [ ] honest rival tells work;
- [ ] bought-lot feedback works;
- [ ] money spent persists even if whole match later lost;
- [ ] Payable Intent has no duplicate bonus;
- [ ] Hostile Acquisition marked hook implemented;
- [ ] acquisition hook requires perk + marked rival + full match win;
- [ ] no world mutation from acquisition;
- [ ] CLOSE/CRUSHING exact;
- [ ] typed result;
- [ ] exactly-once spending;
- [ ] exactly-once result submission;
- [ ] no Authority logic inside Money;
- [ ] end-to-end Rival→Money→Rival works;
- [ ] 07A/B/C regressions pass;
- [ ] previous regressions pass;
- [ ] MODULE 08 not implemented ahead.

---

# 118. Порядок выполнения Cursor

## Step 1 — audit Runner / Money API

Проверить:

```text
RivalCompetitionRunner
GameState money API
RivalDefinition.competition_modifier_id
PerkIds
```

---

## Step 2 — MoneyMatch core

Реализовать:

```text
scores
stake unit
rival ceiling
bid levels
actions
round resolution
grade
```

---

## Step 3 — GameState spending seam

Подключить real affordability/payment.

Проверить atomicity.

---

## Step 4 — Money UI

Минимальный readable auction overlay.

---

## Step 5 — Runner route

Заменить:

```text
MONEY unsupported
```

на actual MoneyMinigame.

---

## Step 6 — Hostile Acquisition hook

Только signal/hook.

Никакого World logic.

---

## Step 7 — end-to-end

Проверить win/loss/spending/Authority ownership.

---

## Step 8 — tests

Прогнать sections 74–112.

---

## Step 9 — all 07 regressions

Проверить 4 minigames.

---

## Step 10 — previous regressions

Все прошлые modules.

---

## Step 11 — docs

Обновить architecture/perk contracts.

---

# 119. Формат финального отчёта Cursor

## Money architecture

Core/UI/Runner boundary.

## Core rules

Подтвердить:

```text
target 3/5
current bid levels
real final purchase spending
```

## Capital actions

```text
RAISE +1
OUTBID +2 at Capital 3
BUYOUT +3 at Capital 6
```

## Money formula

Подтвердить:

```text
stake_unit = max(1, floor(starting_money/(target_score*15)))
```

и rival ceiling formula.

## Hostile Acquisition

Подтвердить:

- marked via `competition_modifier_id = money_acquisition`;
- signal only;
- no world mutation.

## Runner

Подтвердить все 4 routes implemented.

## Validation

07D tests + 07A/B/C + previous regressions.

## Files changed

Основные файлы.

## Product questions

Если нет:

```text
None.
```

---

# 120. Запрет продолжения

После успешного MODULE 07D:

**НЕ начинать MODULE 08 — Girl Discovery & Phone Journal.**

Остановиться и дождаться отдельной спецификации.
