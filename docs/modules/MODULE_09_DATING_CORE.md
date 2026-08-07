# MODULE 09 — DATING CORE

**Проект:** Date Factory  
**Модуль:** 09 — Dating Core  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать полный runtime одного свидания — arrival, greeting, выбор трёх центральных событий, четыре оцениваемых решения, primary/secondary trait evaluation, часть dating-perks, известные реакции и typed итог свидания — без применения результата к постоянным отношениям девушки  
**Продуктовый источник истины:** `docs/MASTER_GDD.md`, `docs/gdd/05_girls.md`, `docs/gdd/06_dating.md`, `docs/PERK_EFFECT_CONTRACTS.md`  
**Предыдущий модуль:** MODULE 08 — Girl Discovery & Phone Journal  
**Следующий модуль:** MODULE 10 — Relationships & Girl Completion

---

# 0. ГЛАВНАЯ ГРАНИЦА MODULE 09

MODULE 09 отвечает за:

```text
контакт с девушкой уже получен
→ старт одного свидания
→ greeting
→ 3 central events
→ farewell
→ primary evaluation каждого из 4 решений
→ secondary evaluation всего свидания
→ date_delta ∈ [-5, +5]
→ typed DatingResult
```

MODULE 09 **НЕ применяет** `date_delta` к постоянному `GameState.relationship`.

То есть MODULE 09 НЕ вызывает:

```text
change_girl_relationship(...)
mark_girl_conquered(...)
add_experience(...)
```

и НЕ ставит постоянный cooldown повторного свидания.

Это обязанность MODULE 10.

---

# 1. Почему relationship остаётся MODULE 10

После свидания существует два разных понятия:

```text
date_delta
```

и:

```text
persistent relationship
```

Пример:

```text
до свидания relationship = +3
date_delta = -2
```

MODULE 09 возвращает:

```text
-2
```

MODULE 10 позже делает:

```text
relationship = clamp(+3 - 2, -5, +5)
```

и проверяет первое достижение `+5`.

Не смешивать эти операции в Dating Core.

---

# 2. Каноническая структура свидания

Ровно:

```text
1. ARRIVAL
2. GREETING
3. CENTRAL EVENT #1
4. CENTRAL EVENT #2
5. CENTRAL EVENT #3
6. FAREWELL
7. SECONDARY TRAIT EVALUATION
8. FINISHED
```

Оцениваются Primary Trait только:

```text
CENTRAL #1
CENTRAL #2
CENTRAL #3
FAREWELL
```

Greeting:

```text
relationship/date score = 0
```

---

# 3. Максимум и минимум

За 4 evaluated decisions Primary Trait может дать:

```text
-4 .. +4
```

Secondary Trait:

```text
-1 / 0 / +1
```

Итог одного свидания:

```text
date_delta ∈ [-5, +5]
```

Идеальное первое свидание:

```text
+5
```

---

# 4. Static data: существующие типы

Использовать уже существующие:

```text
DatingEventDefinition
DatingEventPoolDefinition
DatingActionDefinition

DatingEventCategory
ActionTag
PrimaryGirlTrait
SecondaryGirlTrait
PlayerCharacteristic
```

Не дублировать enums.

---

# 5. DatingActionDefinition — минимальное расширение

MODULE 09 разрешает расширить существующий `DatingActionDefinition` только следующими полями:

```text
required_perk_id: StringName = &""
is_public: bool = false
is_major_expense: bool = false
result_text: String = ""
```

Существующие поля остаются:

```text
id
label
characteristic
required_characteristic_level
money_cost
resolver_id
direct_tags
```

---

# 6. `required_perk_id`

Это простой explicit gate для authored actions.

Примеры будущего content:

```text
perk_muscle_hold_doorway
perk_capital_buy_problem
```

Не создавать generic:

```text
RequirementDefinition
requirements[]
logical expressions
```

Один optional perk requirement достаточен.

---

# 7. `is_public`

Нужно для:

```text
SecondaryGirlTrait.SCANDALOUS
```

Action может быть:

```text
public = true
```

если его результат заметен окружающим.

External resolver может вернуть фактическое `was_public`, если исход изменил публичность.

---

# 8. `is_major_expense`

Нужно только чтобы отличить:

```text
обычное платное действие
```

от:

```text
крупного / сюжетного расхода
```

для:

```text
Представительские расходы
```

Не создавать economy classification hierarchy.

---

# 9. `result_text`

Короткое authored описание результата действия.

Не является dialogue tree.

MODULE 14 позже наполнит production content.

---

# 10. Greeting static data

Создать typed:

```text
DatingGreetingDefinition
```

Минимально:

```text
id: StringName
label: String

direct_tags: Array[ActionTag]

has_requirement: bool = false
required_characteristic: PlayerCharacteristic
required_level: int = 0

result_text: String = ""
```

Canonical prefix:

```text
dating_greeting_*
```

---

# 11. Greeting tags

Greeting может иметь:

```text
0..2 tags
```

Эти tags оцениваются Primary Trait только **диагностически**.

Результат:

```text
-1 / 0 / +1
```

может быть показан и записан в Phone known reactions.

Но:

```text
date_delta += 0
```

всегда.

---

# 12. Greeting characteristic

Greeting characteristic:

- может быть требованием доступности;
- НЕ входит в 4-characteristic history для Secondary Trait;
- НЕ влияет на Consistent/Variety.

---

# 13. Farewell static data

Создать:

```text
DatingFarewellDefinition
```

Минимально:

```text
id: StringName
title: String
setup_text: String
actions: Array[DatingActionDefinition]
```

Canonical prefix:

```text
dating_farewell_*
```

Farewell action — обычное evaluated decision.

---

# 14. Не добавлять GirlDefinition поля заранее

MODULE 09 НЕ обязан добавлять:

```text
greeting_pool_id
farewell_id
```

в каждую GirlDefinition.

Вместо этого start date использует typed request, который явно задаёт:

- девушку;
- location;
- greeting IDs;
- farewell ID.

MODULE 14 позже связывает конкретный production date content с девушкой/story situation.

Это не заставляет сейчас дублировать common content во всех GirlDefinition.

---

# 15. DatingStartRequest

Создать typed request semantic уровня:

```text
DatingStartRequest
```

Минимально:

```text
girl_id: StringName
location_id: StringName

greeting_ids: Array[StringName]
farewell_id: StringName

excluded_event_ids: Array[StringName]
rng_seed: int / optional test override
```

`excluded_event_ids` нужен будущему MODULE 10 для repeat dates.

MODULE 09 сам не хранит persistent cross-date history.

---

# 16. Start prerequisites

`start_date(request)` проверяет:

1. GirlDefinition существует;
2. у игрока есть contact:
   ```text
   GameState.has_girl_contact(girl_id)
   ```
3. greeting definitions существуют;
4. farewell существует;
5. GirlDefinition dating pools существуют;
6. из pools можно выбрать valid 3-event sequence;
7. другой date session не активен.

MODULE 09 пока НЕ проверяет repeat cooldown — это MODULE 10.

---

# 17. Один active date

На одного local player:

```text
max 1 active DatingSession
```

Новый start при active session:

```text
DATE_ALREADY_ACTIVE
```

Queue не нужен.

---

# 18. DatingSession

Transient, не persistent.

Минимально хранит:

```text
girl_id
location_id

phase

greeting_ids
selected_greeting_id
greeting_reaction

central_event_ids[3]
current_event_index

farewell_id

decision_records[4]

secondary_reaction
date_delta

money_spent_total

perk usage flags

finished
```

---

# 19. Active date не сохраняется

MODULE 09 не реализует mid-date Save/Load.

MODULE 24 позже решит, разрешено ли сохранение посреди свидания.

---

# 20. Session phases

Canonical semantic enum:

```text
ARRIVAL
GREETING
CENTRAL_EVENT
RESOLVING_ACTION
ENCORE_DECISION
FAREWELL
SECONDARY_EVALUATION
FINISHED
```

`CENTRAL_EVENT` использует:

```text
current_event_index = 0..2
```

Не создавать generic StateMachine framework.

---

# 21. ARRIVAL

Arrival не даёт score.

Functional version:

- current 3D scene остаётся фоном;
- если girl CharacterActor доступен — показать её;
- Phone-known clues могут быть показаны кратко;
- UI:
  ```text
  Она пришла
  ```

Можно emit:

```text
arrival_presentation_requested(girl_id)
```

для будущего camera/presentation polish.

Не строить cinematic camera system.

---

# 22. Arrival clues не создаются заново

MODULE 09 не выдаёт новые clue только за сам факт каждого свидания.

Clues уже принадлежат discovery/history system.

Исключения ниже — Aura greeting perks.

---

# 23. Central category selection

Нужно выбрать sequence из 3 категорий.

Категории:

```text
CONVERSATION
SPACE_EVENT
GIRL_PROPOSAL
```

Правила:

- каждый slot имеет равный базовый шанс;
- нельзя 3 одинаковых;
- допустимо `2+1`;
- допустимо `1+1+1`.

---

# 24. Exact category algorithm

Не использовать reroll loop с потенциальным bias.

Сформировать все ordered triples:

```text
3 * 3 * 3 = 27
```

Исключить:

```text
CCC
SSS
GGG
```

Остаётся:

```text
24 valid category sequences
```

Выбрать один из 24 uniformly через session RNG.

Это сохраняет:

- равные marginal chances каждого slot;
- запрет трёх одинаковых;
- deterministic seed tests.

---

# 25. Category sequence immutable

Все три category выбираются:

```text
до первого central event
```

и сохраняются в DatingSession.

Не reroll-ить category при переходе к следующему event.

---

# 26. Event candidate source

Использовать:

```text
GirlDefinition.dating_pool_ids
```

Для каждого pool:

```text
DatingEventPoolDefinition.event_ids
```

Собрать unique event candidates.

---

# 27. Event filtering

Для каждого slot candidate должен:

1. существовать;
2. иметь нужную `DatingEventCategory`;
3. не быть уже выбран в этой date session;
4. не входить в `request.excluded_event_ids`;
5. быть разрешён для `location_id`.

---

# 28. Location rule

Если:

```text
DatingEventDefinition.allowed_location_ids.is_empty()
```

event допустим в любой location.

Иначе:

```text
location_id
```

должен присутствовать в allowed list.

---

# 29. Exact event ID no repeat

Один:

```text
DatingEventDefinition.id
```

не может появиться дважды в одной date session.

---

# 30. Insufficient content

Если для выбранной category sequence невозможно подобрать 3 valid unique events:

не подменять silently категории.

Алгоритм должен выбрать случайно **из тех valid category sequences, для которых фактически существует полный event assignment**.

То есть:

1. перебрать 24 category sequences;
2. определить, для каких существует хотя бы одно valid 3-event assignment;
3. uniformly выбрать valid sequence;
4. затем uniformly выбрать конкретные events slot-by-slot без duplicate.

Если valid sequence нет:

```text
INSUFFICIENT_DATE_CONTENT
```

Date не стартует.

---

# 31. Почему не reroll после старта

После успешного `start_date`:

```text
central_event_ids
```

полностью snapshot-нуты.

UI reload/phase change не меняет их.

---

# 32. Event randomization testability

DatingCore должен иметь deterministic RNG injection/seed для tests.

Не хранить seed в GameState.

---

# 33. Action availability

Для каждого `DatingActionDefinition` проверить:

```text
characteristic level
required_perk_id
money affordability
Public Significance override
```

---

# 34. Base characteristic gate

Доступно, если:

```text
GameState.get_characteristic(action.characteristic)
>=
action.required_characteristic_level
```

кроме explicit Public Significance rule.

---

# 35. Perk-gated action

Если:

```text
required_perk_id != ""
```

нужно:

```text
GameState.has_perk(required_perk_id)
```

Disabled action должен показывать requirement.

---

# 36. Money availability

Если:

```text
action.money_cost > 0
```

обычно требуется:

```text
GameState.can_afford(action.money_cost)
```

с учётом Representation Expenses.

`No Limit` не реализуется полностью здесь — см. section 158.

---

# 37. Action resolver boundary

`resolver_id` остаётся opaque из MODULE 03.

MODULE 09 поддерживает два execution пути:

```text
resolver_id == &"direct"
→ immediate result

anything else
→ external action execution seam
```

Не создавать registry из десятков resolver classes.

---

# 38. Direct resolver

Для:

```text
resolver_id == &"direct"
```

результат:

```text
execution_outcome = SUCCESS
final_tags = action.direct_tags
was_public = action.is_public
```

---

# 39. External action execution

Если resolver не `direct`:

DatingCore формирует typed:

```text
DatingActionExecutionRequest
```

и переходит в:

```text
RESOLVING_ACTION
```

---

# 40. DatingActionExecutionRequest

Минимально:

```text
girl_id
event_id
action_id
resolver_id

characteristic
base_tags

is_public
```

Допустим opaque:

```text
context_token
```

если технически нужен.

Не передавать arbitrary Dictionary domain state.

---

# 41. Execution result

Создать typed:

```text
DatingActionExecutionResult
```

Минимально:

```text
outcome: SUCCESS / FAILURE

has_tag_override: bool
tags: Array[ActionTag]

was_public: bool

result_text: String
```

Tags после resolution:

```text
max 2
```

---

# 42. External resolver use cases

Этот seam позже позволяет без переделки Dating Core подключать:

- RivalEncounter внутри свидания;
- короткую authored activity;
- world action;
- другой feature-specific resolver.

MODULE 09 НЕ обязан реализовывать все эти systems.

---

# 43. Heroic Defeat compatibility

Future Rival action может вернуть:

```text
outcome = FAILURE
has_tag_override = true
tags = [VULNERABILITY, RISK]
was_public = true/false according to scene
```

Dating Core затем оценивает эти final tags обычной Primary Trait логикой.

Он не знает Heroic Defeat напрямую.

---

# 44. Action execution outcome ≠ girl reaction

Это разные вещи.

Пример:

```text
герой проиграл физическую активность
execution_outcome = FAILURE

tags = [VULNERABILITY, RISK]

Kind girl primary reaction = +1
```

Не связывать:

```text
FAILURE => girl -1
```

---

# 45. Primary Trait evaluator

Создать чистую функцию:

```text
evaluate_primary_trait(primary_trait, tags) -> -1 / 0 / +1
```

Использовать static `PrimaryTraitDefinition` из ContentDB.

---

# 46. Exact primary rule

Для final tags:

```text
has_liked
has_disliked
```

Результат:

```text
has_liked && !has_disliked  => +1
!has_liked && has_disliked  => -1
has_liked && has_disliked   => 0
!has_liked && !has_disliked => 0
```

Никаких weights.

---

# 47. Tags max 2

На всех путях:

```text
0..2 tags
```

Если external resolver возвращает больше:

```text
INVALID_ACTION_RESULT
```

Не truncate silently.

---

# 48. Primary reaction immediate

После каждого evaluated decision UI получает:

```text
+1
0
-1
```

сразу.

Primary trait name при этом может оставаться скрытым.

---

# 49. Known reaction recording

После Greeting diagnostic:

```text
GameState.record_girl_known_reaction(
    girl_id,
    greeting_id,
    reaction
)
```

После каждого evaluated action:

```text
source_id = action.id
reaction = primary result
```

---

# 50. Known reaction is final reaction

Если perk Encore изменил tags и reaction:

Phone записывает итоговую реакцию после Encore.

Не хранить две conflicting записи под одним `action_id`.

---

# 51. Decision record

Для каждого из 4 evaluated decisions создать typed:

```text
DatingDecisionRecord
```

Минимально:

```text
source_id
event_id

characteristic
final_tags

primary_reaction

execution_outcome
was_public

money_cost
money_spent

used_public_significance
used_encore
```

Farewell:

```text
event_id = farewell_id
```

---

# 52. Secondary evaluator input

Secondary Trait смотрит только:

```text
decision_records[4]
```

Не greeting.

Не arrival.

---

# 53. SCANDALOUS exact

Secondary:

```text
SCANDALOUS
```

Positive:

```text
есть хотя бы один record:
was_public == true
AND
CONFLICT ∈ final_tags
```

=> `+1`.

Negative:

```text
все 4 records:
was_public == false
```

=> `-1`.

Иначе:

```text
0
```

---

# 54. Public but no conflict

Если есть публичные события, но ни одно не содержит public `CONFLICT`:

```text
SCANDALOUS = 0
```

не `-1`.

---

# 55. CONSISTENT exact

Посчитать 4 characteristics.

Если какая-либо одна встречается:

```text
>= 3
```

=> `+1`.

Если все четыре разные:

```text
4 unique
```

=> `-1`.

Иначе:

```text
0
```

---

# 56. VARIETY_SEEKING exact

Если:

```text
unique characteristics >= 3
```

=> `+1`.

Иначе если одна characteristic встречается:

```text
>= 3
```

=> `-1`.

Иначе:

```text
0
```

---

# 57. DEMANDING exact

Посчитать Primary reactions четырёх decisions.

Если:

```text
negative_count == 0
AND
positive_count >= 2
```

=> `+1`.

Если:

```text
negative_count >= 2
```

=> `-1`.

Иначе:

```text
0
```

---

# 58. Secondary evaluation exactly once

Только после Farewell record #4.

Не пересчитывать при каждом event.

Не записывать Secondary как known reaction к отдельному action ID.

---

# 59. DatingResult

Создать typed immutable-ish result:

```text
DatingResult
```

Минимально:

```text
girl_id
location_id

greeting_id
greeting_reaction

central_event_ids

decision_records

primary_total
secondary_reaction
date_delta

money_spent_total

used_right_to_say_nothing
used_second_outfit
```

---

# 60. Result score

```text
primary_total =
sum(decision.primary_reaction)
```

```text
date_delta =
primary_total + secondary_reaction
```

Validate:

```text
-5 <= date_delta <= +5
```

---

# 61. DatingResult не мутирует relationship

`finish_date()`:

- создаёт result;
- emit:
  ```text
  date_finished(result)
  ```
- закрывает session.

GameState relationship остаётся прежним.

---

# 62. GREETING normal flow

UI показывает available Greeting definitions.

Игрок выбирает один.

Проверяется optional requirement.

Greeting tags оцениваются Primary Trait.

Полученная реакция:

- показывается;
- записывается в known reactions;
- НЕ входит в `date_delta`.

---

# 63. Greeting diagnostic tags

Greeting может:

```text
tags = []
```

Тогда reaction:

```text
0
```

Это допустимо.

---

# 64. Aura perk — `RIGHT_TO_SAY_NOTHING`

Если player владеет:

```text
PerkIds.AURA_RIGHT_TO_SAY_NOTHING
```

Greeting UI дополнительно показывает:

```text
Ничего не говорить
```

---

# 65. Silent greeting effect

Если игрок выбирает silence:

```text
selected_greeting_id = &"dating_greeting_silence"
greeting_reaction = 0
used_right_to_say_nothing = true
```

Не создавать fake ActionTag для молчания.

---

# 66. Silent greeting clue

После silence раскрыть:

```text
ровно 1 следующий неизвестный clue
```

через existing GirlDiscovery/GameState clue API.

Если clues закончились:

- ничего не происходит;
- perk всё равно использован для greeting.

---

# 67. `SHE_ALREADY_STARTED`

Если player также владеет:

```text
PerkIds.AURA_SHE_ALREADY_STARTED
```

после silent greeting раскрыть:

```text
ещё 1 следующий неизвестный clue
```

То есть максимум:

```text
2 new clues
```

за эту greeting sequence.

---

# 68. She Already Started не раскрывает trait автоматически

Не вызывать:

```text
reveal_primary_trait()
```

только из-за perk.

Он делает clue явнее через дополнительный known clue.

---

# 69. Silence once per date naturally

Greeting происходит один раз.

Persistent usage не нужен.

---

# 70. `SECOND_OUTFIT`

Если player владеет:

```text
PerkIds.APPEARANCE_SECOND_OUTFIT
```

в фазах:

```text
ARRIVAL
GREETING
```

и до первого evaluated decision можно один раз вызвать:

```text
use_second_outfit()
```

---

# 71. Second Outfit gameplay effect

MODULE 09 фиксирует его как:

```text
presentation-only date option
```

на текущем этапе.

При использовании:

```text
used_second_outfit = true
signal second_outfit_requested(girl_id)
```

Он НЕ даёт:

- automatic +1;
- tags;
- stat bonus.

MODULE 14/23 позже может связать это с actual accessory presentation.

Не придумывать скрытый числовой бонус.

---

# 72. Second Outfit lock timing

После старта first central evaluated action:

```text
use_second_outfit() unavailable
```

Farewell слишком поздно.

---

# 73. `PUBLIC_SIGNIFICANCE`

Perk:

```text
PerkIds.APPEARANCE_PUBLIC_SIGNIFICANCE
```

один раз за date.

---

# 74. Public Significance availability

Если action:

```text
characteristic == APPEARANCE
```

и обычный stat gate не выполнен, но:

```text
required_level == current_appearance + 1
```

то при unused perk action становится доступен.

---

# 75. Public Significance consume

Perk usage session flag consume-ится:

```text
в момент выбора такого over-level action
```

даже если external activity потом FAIL.

---

# 76. Public Significance не auto-success

Action resolver выполняется нормально.

Primary Trait оценивает фактические final tags.

---

# 77. Public Significance не используется, если stat уже хватает

Если:

```text
current_appearance >= required_level
```

обычная availability.

Session perk charge сохраняется.

---

# 78. `REPRESENTATION_EXPENSES`

Perk:

```text
PerkIds.CAPITAL_REPRESENTATION_EXPENSES
```

автоматически применяется к первому:

```text
money_cost > 0
AND
is_major_expense == false
```

выбранному action за date.

---

# 79. Representation Expenses effect

Такое action:

```text
was_paid_action = true
money_spent = 0
```

GameState Money не списывается.

Action всё равно считается платным для future content logic.

---

# 80. Representation Expenses consume

Charge consume-ится при выборе первого qualifying normal paid action.

Даже если action execution потом FAILURE.

---

# 81. Major expense

Если:

```text
is_major_expense == true
```

Representation Expenses не применяется.

---

# 82. Affordability with Representation Expenses

Первое qualifying normal paid action доступно даже если:

```text
money < money_cost
```

потому что фактический cost:

```text
0
```

---

# 83. `DIGNITY_REFUND`

Если player владеет:

```text
PerkIds.CAPITAL_DIGNITY_REFUND
```

и:

```text
execution_outcome == FAILURE
money_spent > 0
```

то вернуть:

```text
money_spent
```

через canonical `GameState.add_money()`.

---

# 84. Dignity Refund preserves result

Refund НЕ меняет:

- FAILURE outcome;
- final tags;
- Primary reaction;
- publicness;
- decision history.

---

# 85. Dignity Refund + Representation Expenses

Если:

```text
money_spent == 0
```

refund:

```text
0
```

Никаких бесплатных денег.

---

# 86. `BUY_PROBLEM`

`PerkIds.CAPITAL_BUY_PROBLEM` не требует отдельной hardcoded DatingCore branch.

Authored action имеет:

```text
required_perk_id = PerkIds.CAPITAL_BUY_PROBLEM
```

и обычный `resolver_id`.

---

# 87. `HOLD_DOORWAY`

То же:

```text
required_perk_id = PerkIds.MUSCLE_HOLD_DOORWAY
```

Dating Core просто gate-ит authored action.

---

# 88. `PAYABLE_INTENT` / `PRESENCE_REGISTERED`

Их базовый эффект уже проявляется через:

- уровень характеристики, который вырос при покупке perk;
- authored action requirements;
- Rival competition access где применимо.

MODULE 09 не добавляет hidden percentage bonus.

---

# 89. `ENCORE`

Perk:

```text
PerkIds.APPEARANCE_ENCORE
```

один раз за date.

Trigger:

```text
evaluated action characteristic == APPEARANCE
AND
base primary reaction == 0
AND
perk unused
```

---

# 90. Encore decision

После action execution и initial primary evaluation, но ДО окончательного commit DecisionRecord:

DatingSession входит:

```text
ENCORE_DECISION
```

UI предлагает:

```text
Выйти на бис
Продолжить вечер
```

---

# 91. Encore tag transform

Если игрок использует Encore:

```text
used_encore = true
```

Final tags изменяются так:

1. если `ORIGINALITY` уже присутствует:
   - tags не меняются;
2. если tags size == 0:
   ```text
   [ORIGINALITY]
   ```
3. если tags size == 1:
   ```text
   [existing, ORIGINALITY]
   ```
4. если tags size == 2:
   заменить **второй** tag на:
   ```text
   ORIGINALITY
   ```

Max 2 сохраняется.

---

# 92. Encore re-evaluation

После tag transform заново выполнить Primary Trait evaluation.

Именно этот новый результат:

- попадает в DecisionRecord;
- влияет на date_delta;
- записывается в Phone known reaction.

---

# 93. Encore is optional

Игрок может отказаться.

Тогда:

```text
used_encore remains false
```

и perk можно предложить на более позднем neutral Appearance action в том же date.

---

# 94. Encore only neutral base reaction

Если base reaction:

```text
+1
или
-1
```

Encore не предлагается.

---

# 95. Encore presentation

При use emit:

```text
encore_presentation_requested(girl_id, action_id)
```

Не создавать отдельную dance/model mini-game.

MODULE 09 core трактует authored Encore как успешный короткий visual follow-up.

---

# 96. `NO_LIMIT`

Perk:

```text
PerkIds.CAPITAL_NO_LIMIT
```

имеет usage:

```text
once per major story stage
```

MODULE 09 НЕ может корректно владеть этим usage, потому что Story Framework ещё не реализован.

Поэтому MODULE 09:

- не создаёт session-local fake implementation;
- не хранит `no_limit_used` в date;
- оставляет специальный affordability override seam для MODULE 11/14, если технически нужен.

Не делать perk «один раз за date» — это неверно.

---

# 97. Money spending order

При action selection:

1. определить effective cost;
2. если `0` → не spend;
3. иначе проверить affordability;
4. `GameState.spend_money(cost)`;
5. сохранить `money_spent`;
6. затем выполнить resolver.

---

# 98. Failed resolver and refund

Если external resolver FAIL и Dignity Refund:

```text
add_money(money_spent)
```

DecisionRecord хранит:

```text
money_spent = 0
```

или:

```text
money_paid_then_refunded = true
```

Cursor может выбрать.

Для `money_spent_total` итогово учитывать только **net spend**.

---

# 99. Atomicity

Нельзя:

- списать деньги дважды;
- commit action дважды;
- record reaction дважды;
- добавить два DecisionRecord для одного slot.

---

# 100. Central event flow

Для каждого central event:

1. показать title/setup;
2. построить action availability;
3. player выбирает action;
4. execute direct/external;
5. optionally Encore;
6. evaluate Primary;
7. record known reaction;
8. append DecisionRecord;
9. показать short reaction;
10. перейти к следующему event.

---

# 101. Farewell flow

После central event #3:

1. показать `DatingFarewellDefinition`;
2. выбрать action;
3. execute;
4. optionally Encore, если все условия подходят;
5. evaluate Primary;
6. append DecisionRecord #4;
7. перейти к Secondary evaluation.

---

# 102. Farewell uses same action rules

Все обычные action mechanics применяются:

- characteristic gates;
- required perk;
- money;
- Public Significance;
- Representation Expenses;
- Dignity Refund;
- external resolver;
- Encore.

---

# 103. Secondary after Farewell only

После DecisionRecord count:

```text
== 4
```

вычислить Secondary.

Если count !=4:

```text
content/session error
```

не пытаться оценивать.

---

# 104. Primary trait definitions exact

ContentDB должен по-прежнему содержать exact liked/disliked sets:

## KIND

likes:

```text
CARE
VULNERABILITY
SIMPLICITY
```

dislikes:

```text
DOMINANCE
CONFLICT
OBSESSION
```

## STATUS

likes:

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

## THRILL_SEEKING

likes:

```text
RISK
CONFLICT
SPONTANEITY
```

dislikes:

```text
CONTROL
SIMPLICITY
PRESTIGE
```

## STRANGE

likes:

```text
ABSURDITY
ORIGINALITY
OBSESSION
```

dislikes:

```text
PRESTIGE
CONTROL
SIMPLICITY
```

MODULE 09 не дублирует списки в evaluator — читает definitions.

---

# 105. Primary evaluator tests all 4 cases

Для каждого trait тестировать:

```text
liked only => +1
disliked only => -1
liked + disliked => 0
neither => 0
```

---

# 106. Immediate reaction UI

Functional UI показывает минимум:

```text
Реакция: +1
Реакция: 0
Реакция: -1
```

и `result_text`, если он есть.

Не обязан показывать имя Primary Trait.

---

# 107. Causality without trait spoiler

UI может показать final tags:

```text
Забота · Простота
```

как журнал выполненного действия.

Это помогает игроку понимать причинность.

Но не писать:

```text
Добрая любит Заботу
```

пока trait не revealed.

---

# 108. Trait reveal policy

MODULE 09 **не вводит автоматическое правило раскрытия Primary/Secondary trait**, потому что GDD не фиксирует конкретный порог раскрытия.

Он:

- записывает reactions;
- раскрывает clues через explicit Aura perk;
- использует existing `reveal_primary_trait()` API, если future authored content вызовет его.

Не придумывать:

```text
после первого свидания trait автоматически раскрыт
```

без отдельного product decision.

---

# 109. Secondary trait visibility

DatingResult содержит:

```text
secondary_reaction
```

для механики.

UI может показать:

```text
Итог вечера: +1/0/-1
```

без названия Secondary Trait, если он не раскрыт.

MODULE 09 не создаёт secondary reveal state.

---

# 110. Publicness is final execution fact

Direct:

```text
was_public = action.is_public
```

External resolver может вернуть другое фактическое значение.

Secondary Scandalous использует:

```text
DecisionRecord.was_public
```

---

# 111. External resolver completion

Нужен API:

```text
submit_action_execution_result(result)
```

Только в phase:

```text
RESOLVING_ACTION
```

---

# 112. Invalid external result

Reject:

- wrong request/action;
- >2 tags;
- invalid enum;
- second submit;
- submit outside RESOLVING_ACTION.

State не commit-ится.

---

# 113. External resolver cancel

Не создавать generic cancel path.

Owner обязан вернуть SUCCESS/FAILURE.

Если scene unloaded programmer error — session остаётся диагностируемой.

---

# 114. RivalEncounter future bridge

MODULE 09 не обязан hardcode `RivalEncounters`.

Но contract должен позволять future adapter:

```text
Dating action resolver_id
→ start Rival Encounter context DATE
→ get RivalCompetition/Encounter result
→ convert to DatingActionExecutionResult
→ submit
```

Не менять RivalEncounters сейчас ради fake demo.

---

# 115. Functional Dating UI

Создать:

```text
res://ui/dating/dating_ui.tscn
```

или canonical equivalent.

Это функциональный UI, не final phone/date art.

---

# 116. Control mode

Во время ordinary choice UI:

```text
PlayerControlMode.MODAL_UI
```

Mouse visible.

Если external resolver запускает minigame:

- owner может временно переключить `MINIGAME`;
- после resolver возвращается Dating UI / `MODAL_UI`.

Dating Core не должен принудительно вернуть `GAMEPLAY` посреди date.

---

# 117. UI phases

Минимально:

ARRIVAL:

```text
Продолжить
```

GREETING:

```text
список greeting choices
optional silence
optional second outfit
```

CENTRAL:

```text
event title/setup
action buttons
requirements
money cost
```

ENCORE:

```text
Выйти на бис
Продолжить
```

FAREWELL:

```text
farewell choices
```

FINISH:

```text
Итог свидания: X
```

---

# 118. Requirements visible

Disabled action должен объяснять:

```text
Мышца 3
Внешность 5
Нужен перк: ...
Деньги: ...
```

Не скрывать.

---

# 119. Public Significance UI

Appearance action ровно на +1 level выше:

если perk available:

```text
button enabled
```

и отмечается:

```text
Аура общественного значения / special availability
```

Лучше label по actual perk:

```text
Внешность общественного значения
```

Не показывать technical ID.

---

# 120. Representation Expenses UI

Первое qualifying action можно показать:

```text
Бесплатно — Представительские расходы
```

до выбора.

---

# 121. Phone integration after reactions

`PhoneJournal` existing reaction section должен начать показывать Dating known reactions после date actions.

Если source label resolver не знает `DatingGreetingDefinition`:

MODULE 09 расширяет lookup/resolution.

Не показывать raw IDs в production UI.

---

# 122. Phone relationship пока не обновлять

MODULE 09 ещё не применяет relationship.

Phone current relationship display — MODULE 10.

Не добавлять fake score.

---

# 123. Test content only

Production girls/events остаются ненаполненными.

Создать test-only:

```text
girl_test_dating_kind
girl_test_dating_status
girl_test_dating_thrill
girl_test_dating_strange
```

с pool overrides.

---

# 124. Test greetings

Минимум:

```text
dating_greeting_test_simple
tags = [SIMPLICITY]

dating_greeting_test_status
tags = [PRESTIGE]

dating_greeting_test_weird
tags = [ABSURDITY]
```

Test-only.

---

# 125. Test central events

Создать минимум enough events:

```text
4 CONVERSATION
4 SPACE_EVENT
4 GIRL_PROPOSAL
```

чтобы category/event selection можно было полноценно тестировать.

Не включать production catalog.

---

# 126. Test actions

Нужны actions covering:

- liked tag;
- disliked tag;
- liked+disliked;
- neutral tags;
- each characteristic;
- public conflict;
- paid normal;
- paid major;
- perk gate;
- external resolver.

---

# 127. Test farewell

Одна test `DatingFarewellDefinition` с минимум 4 actions по разным characteristics.

---

# 128. Test scene

Создать:

```text
res://game/dating/test/dating_test.tscn
```

Functional:

- Player/current world background;
- test girl;
- Start Date button;
- Dating UI;
- debug Money/Perk setup;
- deterministic seed controls если удобно.

---

# 129. Test — contact required

No contact:

```text
start_date => NO_CONTACT
```

---

# 130. Test — valid category list

Pure generation:

```text
24 valid ordered triples
```

Ни одного:

```text
AAA
BBB
CCC
```

---

# 131. Test — marginal category equality

В списке 24 valid sequences для каждого slot:

каждая category встречается:

```text
8 раз
```

---

# 132. Test — event IDs unique

Любой generated session:

```text
3 unique event IDs
```

---

# 133. Test — location filter

Event allowed only cafe.

Start at another location:

```text
event excluded
```

---

# 134. Test — excluded previous events

IDs из:

```text
request.excluded_event_ids
```

не выбираются.

---

# 135. Test — insufficient content

Нет полного valid assignment:

```text
INSUFFICIENT_DATE_CONTENT
```

No active session.

---

# 136. Test — sequence immutable

После start несколько phase transitions/read calls:

```text
central_event_ids unchanged
```

---

# 137. Test — greeting reaction no score

Kind girl greeting `[SIMPLICITY]`:

```text
greeting_reaction = +1
date primary_total remains 0 before central
```

---

# 138. Test — greeting known reaction

Phone/GameState contains:

```text
source = greeting ID
reaction = +1
```

---

# 139. Test — silence without perk

No option / rejected.

---

# 140. Test — Right to Say Nothing

Own perk.

Use silence.

Expected:

```text
greeting score 0
one next clue revealed
used flag true
```

---

# 141. Test — She Already Started

Own both.

Silence:

```text
up to 2 next unknown clues revealed
```

No automatic trait reveal.

---

# 142. Test — direct action

Direct resolver:

```text
SUCCESS
final tags = direct_tags
```

---

# 143. Test — external action waits

Select non-direct:

```text
phase = RESOLVING_ACTION
no DecisionRecord yet
```

After valid submit:

```text
record committed once
```

---

# 144. Test — external failure can be liked

Execution FAIL with tags:

```text
[VULNERABILITY]
```

Kind girl:

```text
primary reaction +1
```

---

# 145. Test — liked/disliked collision

Status girl tags:

```text
[PRESTIGE, ABSURDITY]
```

Expected:

```text
0
```

---

# 146. Test — neutral tags

Kind girl:

```text
[PRESTIGE]
```

Expected:

```text
0
```

---

# 147. Test — known reaction per evaluated action

After commit:

```text
GameState reaction[action.id] == primary_reaction
```

---

# 148. Test — requirement gate

Action required Muscle 3.

Player 2:

```text
disabled/rejected
```

Player 3:

```text
available
```

---

# 149. Test — required perk

Missing perk:

```text
disabled
```

Own perk:

```text
available
```

---

# 150. Test — Public Significance

Appearance:

```text
current=4
required=5
```

Own perk unused:

```text
available
```

Select:

```text
perk session usage consumed
```

---

# 151. Test — Public Significance too high

Current 4, required 6:

```text
still disabled
```

---

# 152. Test — Public Significance normal availability

Current 5, required 5:

```text
available
special charge not consumed
```

---

# 153. Test — Second Outfit timing

Before central #1:

```text
available once
```

After first evaluated action starts:

```text
unavailable
```

No score/tag effect.

---

# 154. Test — Representation Expenses

First normal paid action cost 20.

Own perk, Money 0.

Expected:

```text
available
money_spent = 0
perk used
```

---

# 155. Test — Representation second paid action

Cost 20, no enough Money:

```text
disabled
```

unless other valid future override exists.

---

# 156. Test — major expense

First paid action major.

Representation Expenses:

```text
does not apply
```

Need actual affordability.

Charge remains available for later normal paid action.

---

# 157. Test — Dignity Refund

Spend 20.

External resolver FAILURE.

Own perk:

```text
Money restored
net money spent 0
tags/reaction preserved
```

---

# 158. Test — No Limit not misimplemented

Own `CAPITAL_NO_LIMIT`.

Unaffordable action without story-stage override:

MODULE 09 must NOT silently treat perk as:

```text
once per date free purchase
```

No incorrect local implementation exists.

---

# 159. Test — Encore trigger

Appearance action base reaction:

```text
0
```

Own perk.

Expected:

```text
ENCORE_DECISION
```

---

# 160. Test — Encore decline

Decline:

```text
original tags/reaction committed
perk remains unused
```

---

# 161. Test — Encore transform 1 tag

Base:

```text
[PRESTIGE]
```

Use Encore:

```text
[PRESTIGE, ORIGINALITY]
```

re-evaluate.

---

# 162. Test — Encore transform 2 tags

Base:

```text
[PRESTIGE, CONTROL]
```

After:

```text
[PRESTIGE, ORIGINALITY]
```

---

# 163. Test — Encore once

After use:

no later neutral Appearance action offers Encore.

---

# 164. Test — Encore only Appearance

Neutral Muscle action:

```text
no Encore
```

---

# 165. Test — SCANDALOUS +1

Any record:

```text
was_public=true
tags contains CONFLICT
```

=> `+1`.

---

# 166. Test — SCANDALOUS -1

All four:

```text
was_public=false
```

=> `-1`.

---

# 167. Test — SCANDALOUS 0

At least one public action, no public Conflict:

```text
0
```

---

# 168. Test — CONSISTENT +1

Characteristics:

```text
MUSCLE MUSCLE MUSCLE AURA
```

=> `+1`.

---

# 169. Test — CONSISTENT -1

```text
MUSCLE APPEARANCE CAPITAL AURA
```

=> `-1`.

---

# 170. Test — CONSISTENT 0

```text
MUSCLE MUSCLE AURA AURA
```

=> `0`.

---

# 171. Test — VARIETY +1

At least 3 unique.

---

# 172. Test — VARIETY -1

One characteristic >=3.

---

# 173. Test — DEMANDING +1

Primary reactions:

```text
+1 +1 0 0
```

=> `+1`.

---

# 174. Test — DEMANDING -1

At least 2 negatives.

---

# 175. Test — full +5

Four primary:

```text
+1 +1 +1 +1
```

Secondary:

```text
+1
```

DatingResult:

```text
date_delta = +5
```

Persistent relationship unchanged.

---

# 176. Test — full -5

Four primary:

```text
-1 -1 -1 -1
```

Secondary:

```text
-1
```

=> `-5`.

---

# 177. Test — exact four decision records

Finish cannot happen with:

```text
3
или
5
```

records.

---

# 178. Test — relationship untouched

Before:

```text
relationship = +2
```

Finish date:

```text
date_delta = +3
```

After MODULE 09:

```text
relationship still +2
```

---

# 179. Test — Experience untouched

No `add_experience`.

---

# 180. Test — conquered untouched

No `mark_girl_conquered`.

---

# 181. Test — no date cooldown

MODULE 09 does not set persistent repeat cooldown.

---

# 182. Test — Phone reaction integration

After date actions:

Phone Journal can resolve/display known action labels rather than raw IDs.

---

# 183. Test — control mode

Dating choice phases:

```text
MODAL_UI
```

External minigame may temporarily use:

```text
MINIGAME
```

Return to date:

```text
MODAL_UI
```

After date result handed off/closed:

restore caller mode.

---

# 184. Exactly-once finish

`date_finished` emitted once.

Further input ignored/rejected.

---

# 185. Reset/new game

No persistent DatingSession in GameState.

Reset current autoload/service active session if needed when new game resets.

Не добавлять date session serialization.

---

# 186. Content validation extensions

Validate:

## Greeting

- prefix;
- 0..2 tags;
- valid requirement;
- unique ID.

## Farewell

- prefix;
- non-empty actions;
- unique action IDs globally consistent with existing action rules.

## DatingAction additions

- `required_perk_id`, if non-empty, exists in Perk catalog;
- `money_cost >=0`;
- tags max2.

---

# 187. No production dating content

MODULE 09 does not fill all city girls/events.

Test fixtures isolated.

Production content MODULE 14/25.

---

# 188. Documentation updates

Обновить:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/PERK_EFFECT_CONTRACTS.md
```

В Perk contracts уточнить actual Dating implementation:

```text
Right To Say Nothing
She Already Started
Second Outfit
Public Significance
Representation Expenses
Dignity Refund
Encore
Hold Doorway authored gate
Buy Problem authored gate
```

---

# 189. GDD update — trait reveal remains open

Не закрывать OPEN QUESTION раздела 31 искусственным автоматическим reveal.

Добавить technical note:

```text
MODULE 09 records clues/reactions but does not automatically reveal trait names.
```

---

# 190. Что MODULE 09 НЕ реализует

Категорически не реализовывать:

- persistent relationship application;
- clamp relationship;
- first +5 completion;
- Experience reward;
- Upgrade Point reward;
- `mark_girl_conquered`;
- repeat-date cooldown;
- persistent used event history;
- automatic trait reveal threshold;
- secondary trait reveal state;
- Story stage progression;
- production dating events;
- city/cafe scene transitions;
- Date scheduling/calendar;
- full dialogue engine;
- gift inventory;
- generic action resolver engine;
- generic requirement DSL;
- No Limit stage usage;
- final Dating UI art.

---

# 191. Definition of Done

MODULE 09 завершён только если:

- [ ] DatingGreetingDefinition существует;
- [ ] DatingFarewellDefinition существует;
- [ ] DatingStartRequest typed;
- [ ] DatingSession transient;
- [ ] only one active date;
- [ ] contact required;
- [ ] category algorithm uses 24 valid ordered triples;
- [ ] valid-content-aware category selection;
- [ ] 3 event IDs selected upfront;
- [ ] exact event IDs never repeat within date;
- [ ] excluded prior IDs respected;
- [ ] location filters respected;
- [ ] greeting diagnostic reaction works and adds 0 score;
- [ ] 3 central events evaluated;
- [ ] farewell evaluated as #4;
- [ ] primary evaluator exact;
- [ ] final tags max2;
- [ ] action execution outcome separate from girl reaction;
- [ ] direct resolver works;
- [ ] external resolver seam works;
- [ ] known reactions recorded;
- [ ] SCANDALOUS exact;
- [ ] CONSISTENT exact;
- [ ] VARIETY_SEEKING exact;
- [ ] DEMANDING exact;
- [ ] `date_delta` exact `-5..+5`;
- [ ] Right To Say Nothing implemented;
- [ ] She Already Started implemented as second clue;
- [ ] Second Outfit state/presentation hook implemented;
- [ ] Public Significance implemented;
- [ ] Representation Expenses implemented;
- [ ] Dignity Refund implemented;
- [ ] Encore implemented;
- [ ] Hold Doorway works via authored perk gate;
- [ ] Buy Problem works via authored perk gate;
- [ ] No Limit NOT incorrectly implemented as once/date;
- [ ] functional Dating UI exists;
- [ ] MODAL_UI ownership correct;
- [ ] Phone can display Dating known reactions;
- [ ] relationship NOT changed;
- [ ] Experience NOT changed;
- [ ] conquered NOT changed;
- [ ] persistent date cooldown NOT added;
- [ ] MODULE 02–08 regressions pass;
- [ ] FPS/rival/minigame regressions pass;
- [ ] MODULE 10 not implemented ahead.

---

# 192. Порядок выполнения Cursor

## Step 1 — Audit

Изучить фактические:

```text
DatingActionDefinition
DatingEventDefinition
DatingEventPoolDefinition
GirlDefinition
Primary/Secondary Trait Definitions
GameState
GirlDiscovery / PhoneJournal
Player control modes
PERK_EFFECT_CONTRACTS
```

---

## Step 2 — Static data extensions

Добавить:

```text
DatingGreetingDefinition
DatingFarewellDefinition
DatingActionDefinition minimal fields
```

и ContentDB validation/lookup.

---

## Step 3 — Pure evaluators

Сначала реализовать и протестировать:

```text
PrimaryTraitEvaluator
SecondaryTraitEvaluator
category/event planner
```

без UI.

---

## Step 4 — DatingSession

Реализовать lifecycle:

```text
ARRIVAL
GREETING
3 EVENTS
FAREWELL
SECONDARY
FINISH
```

---

## Step 5 — Action execution seam

Direct + external request/result.

---

## Step 6 — Money/perk rules

В порядке:

1. required perk gate
2. Representation Expenses
3. Dignity Refund
4. Public Significance
5. Encore
6. silent greeting perks
7. Second Outfit hook

---

## Step 7 — Known reactions

Подключить GameState/Phone seam.

---

## Step 8 — Functional UI

Не делать final polish.

---

## Step 9 — Test fixtures

Только test content.

---

## Step 10 — Tests

Прогнать sections 129–184.

---

## Step 11 — Regressions

Все предыдущие modules.

---

## Step 12 — Docs

Обновить technical/perk docs.

---

# 193. Формат финального отчёта Cursor

## Architecture

Как разделены:

```text
DatingCore
DatingSession
evaluators
DatingUI
external resolver seam
```

## Content

Какие static types добавлены/расширены.

## Event planner

Подтвердить:

```text
24 valid category sequences
3 events selected upfront
no duplicate event IDs
```

## Evaluation

Подтвердить exact Primary/Secondary rules.

## Perks

Перечислить фактические MODULE 09 Dating effects.

## Result boundary

Подтвердить:

```text
DatingResult.date_delta ∈ [-5,+5]
relationship unchanged
Experience unchanged
conquered unchanged
```

## Validation

MODULE 09 tests + all regressions.

## Files changed

Основные файлы.

## Product questions

Только реальные вопросы, которые нельзя решить технически.

Если нет:

```text
None.
```

---

# 194. Запрет продолжения

После успешного MODULE 09:

**НЕ начинать MODULE 10 — Relationships & Girl Completion.**

Остановиться и дождаться отдельной спецификации.
