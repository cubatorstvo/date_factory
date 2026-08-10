# MODULE 14A — EARLY VERTICAL SLICE CONTENT

**Проект:** Date Factory  
**Родительский модуль:** MODULE 14 — Stage Content: Manual Game  
**Подмодуль:** 14A — Early Vertical Slice Content  
**Цель:** превратить MODULE 00–13 в связно проходимую production-игру от нового прохождения до открытия зарплатной шахты.  
**Playable диапазон:** `PROLOGUE → STAGE_1 → STAGE_2 → STAGE_3`  
**Следующий подмодуль:** MODULE 14B — Editor / Remaining Pre-Media Manual Content.

---

# 0. Почему MODULE 14 разбит

MODULE 14 одновременно включает production girls/rivals, discovery situations, dating events, staged scenes, world placement и entry points в Dating/Progression. Это слишком большой безопасный шаг.

```text
14A:
PROLOGUE
→ Actress
→ Mine Boss
→ STAGE_3
→ Salary Mine

14B:
Editor / remaining manual content
→ точный вход в MODULE 15 Media
```

Cursor после 14A НЕ начинает 14B.

---

# 1. Definition of Product Result

После обычного F5 без debug-кнопок игрок должен суметь:

```text
стартовать в квартире
→ познакомиться с Соседкой
→ получить номер
→ пройти свидание
→ довести отношения до +5
→ получить Experience/Upgrade Point
→ перейти в STAGE_1
→ выйти в город
→ найти Актрису и её ухажёра
→ победить rival_actress
→ познакомиться с Актрисой
→ завершить её линию
→ перейти в STAGE_2
→ найти Начальницу шахты и её ухажёра
→ победить rival_mine_boss
→ завершить её линию
→ перейти в STAGE_3
→ увидеть открытую Salary Mine
→ физически забрать первую зарплату
```

Это первая версия игры, которую можно пройти как продукт, а не набор test scenes.

---

# 2. Не новая архитектура

14A — content/integration module.

Не создавать:

- quest engine;
- narrative graph;
- dialogue engine;
- NPC schedules;
- generic spawn DSL;
- generic condition/reward framework;
- generic cutscene system.

Допустимы только маленькие glue-компоненты:

```text
StageActorAnchor
DateVenueInteractable
ProgressionInteractable
```

---

# 3. Production story scope

В 14A playable:

```text
girl_neighbor
girl_actress
girl_mine_boss

rival_actress
rival_mine_boss
```

Пока НЕ создавать playable production actors/content:

```text
girl_magazine_editor
rival_magazine_editor
girl_scientist
rival_scientist
girl_president
rival_president
girl_final_target
```

После Mine Boss stage становится `STAGE_3`; Editor content появится в 14B.

---

# 4. Production girls — exact catalog

Добавить 7 production girls:

```text
girl_neighbor
girl_actress
girl_mine_boss

girl_city_bicycle
girl_cafe_laptop
girl_gym_chalk
girl_appearance_ritual
```

---

# 5. `girl_neighbor`

```text
display_name = "Соседка"
is_story = true
has_story_stage = true
story_stage = PROLOGUE

primary_trait = KIND
secondary_trait = CONSISTENT
required_experience = 0

discovery_situation_id = discovery_situation_neighbor_hallway
appearance_profile_id = appearance_female_neighbor

dating_pool_ids =
[
    dating_pool_apartment_common,
    dating_pool_neighbor
]

speech_style_note =
"Спокойная, бытовая, говорит прямо; абсурд героя воспринимает как странную, но реальную особенность."
```

Clues:

```text
0 "Сначала спрашивает, не мешает ли она."
1 "Не выглядит впечатлённой демонстративными расходами."
2 "На честную бытовую неловкость реагирует мягче, чем на попытку выглядеть главным."
```

Placement:

```text
location = apartment
marker = npc_neighbor_hallway
```

---

# 6. Neighbor discovery

Situation:

```text
discovery_situation_neighbor_hallway
```

Setup:

```text
"Соседка стоит у двери с твоей кружкой. Она говорит, что кружка каким-то образом три дня жила у неё."
```

Approaches:

```text
discovery_approach_neighbor_admit
"Забрать кружку и признать, что это похоже на тебя"
SUCCESS
no requirement
```

```text
discovery_approach_neighbor_style
"Сделать вид, что кружка была частью образа"
APPEARANCE 1
FAILURE
```

```text
discovery_approach_neighbor_rent
"Предложить компенсировать аренду кружки"
CAPITAL 1
FAILURE
```

---

# 7. `girl_actress`

```text
display_name = "Актриса"
is_story = true
has_story_stage = true
story_stage = STAGE_1

primary_trait = STATUS
secondary_trait = DEMANDING
required_experience = 1

discovery_situation_id = discovery_situation_actress_waiting
appearance_profile_id = appearance_female_actress

dating_pool_ids =
[
    dating_pool_cafe_common,
    dating_pool_actress
]

speech_style_note =
"Привыкла к вниманию, быстро замечает качество подачи и отсутствие контроля; говорит так, будто вокруг всегда есть аудитория."
```

Clues:

```text
0 "Перед разговором автоматически проверяет, кто на неё смотрит."
1 "Качественно организованную мелочь замечает быстрее, чем эмоциональный жест."
2 "Когда план разваливается на ходу, становится заметно холоднее."
```

Placement:

```text
location = appearance_space
girl marker = npc_story_actress
rival marker = npc_story_actress_rival
```

---

# 8. Actress discovery

Setup:

```text
"Актриса ждёт у временной таблички «красная дорожка». Рядом стоит её ухажёр и выглядит так, будто табличка принадлежит ему."
```

До defeat rival GirlDiscovery должен вернуть visible:

```text
Сначала разберись с её текущим ухажёром.
```

После rival:

```text
"Спросить, где должна заканчиваться дорожка"
→ SUCCESS

"Передвинуть ограждение, чтобы дорожка стала длиннее"
MUSCLE 1
→ FAILURE

"Предложить купить настоящую дорожку"
CAPITAL 1
→ FAILURE
```

---

# 9. `girl_mine_boss`

```text
display_name = "Начальница шахты"
is_story = true
has_story_stage = true
story_stage = STAGE_2

primary_trait = THRILL_SEEKING
secondary_trait = CONSISTENT
required_experience = 2

discovery_situation_id = discovery_situation_mine_boss_gate
appearance_profile_id = appearance_female_mine_boss

dating_pool_ids =
[
    dating_pool_cafe_common,
    dating_pool_mine_boss
]

speech_style_note =
"Говорит как человек, который привык принимать решения на шумном производстве; скучает от чрезмерно безопасных планов."
```

Clues:

```text
0 "На табличку «Опасно» смотрит скорее как на описание маршрута."
1 "Медленные и полностью безопасные решения её заметно утомляют."
2 "Уважает, когда человек выбрал риск и не меняет решение через десять секунд."
```

Placement:

```text
location = city_hub
girl marker = npc_story_mine_boss
rival marker = npc_story_mine_boss_rival
```

Она находится у закрытого входа в Salary Mine, не внутри неё.

---

# 10. Mine Boss discovery

Setup:

```text
"Начальница шахты проверяет закрытый вход. Её ухажёр объясняет табличке технику безопасности."
```

После rival:

```text
"Спросить, что находится глубже таблички"
→ SUCCESS

"Предложить сделать вход визуально безопаснее"
APPEARANCE 1
→ FAILURE

"Постоять перед закрытым входом увереннее него"
AURA 1
→ FAILURE
```

---

# 11. Ordinary girl — `girl_city_bicycle`

```text
display_name = "Девушка с велосипедом"
primary_trait = KIND
secondary_trait = VARIETY_SEEKING
required_experience = 0

discovery_situation_id = discovery_situation_city_bicycle
appearance_profile_id = appearance_female_city_bicycle
dating_pool_ids = [dating_pool_cafe_common]

location = city_hub
marker = npc_girl_city_bicycle
```

Clues:

```text
0 "Сначала проверяет, не ушибся ли человек, и только потом велосипед."
1 "Сама предлагает менять план, если кому-то стало неудобно."
2 "Три одинаковых вечера подряд считает подозрительным жизненным решением."
```

Discovery:

```text
"У велосипеда слетела цепь. Девушка держит руль и одновременно пытается не уронить пакет."
```

```text
"Молча придержать велосипед"
→ SUCCESS

"Поднять велосипед целиком"
MUSCLE 1
→ FAILURE

"Предложить купить новый"
CAPITAL 1
→ FAILURE
```

---

# 12. Ordinary girl — `girl_cafe_laptop`

```text
display_name = "Девушка с ноутбуком"
primary_trait = STATUS
secondary_trait = CONSISTENT
required_experience = 1

discovery_situation_id = discovery_situation_cafe_laptop
appearance_profile_id = appearance_female_cafe_laptop
dating_pool_ids = [dating_pool_cafe_common]

location = cafe
marker = npc_girl_cafe_laptop
```

Clues:

```text
0 "Перед тем как открыть ноутбук, выравнивает на столе даже сахар."
1 "Замечает марку чашки быстрее, чем вкус кофе."
2 "Если план уже выбран, предпочитает довести его до конца."
```

Situation:

```text
"Свободная розетка находится за соседним столом, а кабель не дотягивается примерно на двадцать сантиметров."
```

Choices:

```text
"Передвинуть свой стул и освободить проход"
→ SUCCESS

"Убедительно посмотреть на розетку"
APPEARANCE 1
→ FAILURE

"Предложить купить удлинитель вместе с кафе"
CAPITAL 1
→ FAILURE
```

---

# 13. Ordinary girl — `girl_gym_chalk`

```text
display_name = "Девушка с магнезией"
primary_trait = THRILL_SEEKING
secondary_trait = SCANDALOUS
required_experience = 1

discovery_situation_id = discovery_situation_gym_chalk
appearance_profile_id = appearance_female_gym_chalk
dating_pool_ids = [dating_pool_cafe_common]

location = gym
marker = npc_girl_gym_chalk
```

Clues:

```text
0 "Первой проверяет тот снаряд, рядом с которым написано «для опытных»."
1 "На спор реагирует живее, чем на комплимент."
2 "Если вокруг никто не заметил происходящее, быстро теряет интерес."
```

Choices:

```text
"Отдать магнезию ей"
→ SUCCESS

"Предложить определить владельца по хвату"
MUSCLE 1
→ FAILURE

"Купить всю банку у администратора"
CAPITAL 1
→ FAILURE
```

---

# 14. Ordinary girl — `girl_appearance_ritual`

```text
display_name = "Девушка у зеркала"
primary_trait = STRANGE
secondary_trait = VARIETY_SEEKING
required_experience = 2

discovery_situation_id = discovery_situation_appearance_ritual
appearance_profile_id = appearance_female_appearance_ritual
dating_pool_ids = [dating_pool_cafe_common]

location = appearance_space
marker = npc_girl_appearance_ritual
```

Clues:

```text
0 "Перед зеркалом трижды меняет местами два одинаковых стакана."
1 "На вопрос «зачем?» отвечает так, будто вопрос относится к физике мира."
2 "Слишком правильные и дорогие решения вызывают у неё подозрение."
```

Choices:

```text
"Переставить третий предмет и ничего не объяснять"
→ SUCCESS

"Спросить, сколько стоит этот ритуал"
CAPITAL 1
→ FAILURE

"Исправить стаканы по линейке"
AURA 1
→ FAILURE
```

---

# 15. Story rival — `rival_actress`

```text
display_name = "Ухажёр Актрисы"
is_story = true
story_stage = STAGE_1

required_authority = 0
authority_reward = 2

muscle = 1
appearance = 2
capital = 1
aura = 1

preferred_competition = DANCE
allowed_competitions = [DANCE, SLAP]

appearance_profile_id = appearance_male_actress_rival
competition_modifier_id = ""
```

Story rival intentionally does NOT require MONEY/SIGMA perk access.

---

# 16. Story rival — `rival_mine_boss`

```text
display_name = "Ухажёр Начальницы шахты"
is_story = true
story_stage = STAGE_2

required_authority = 2
authority_reward = 2

muscle = 3
appearance = 1
capital = 2
aura = 1

preferred_competition = SLAP
allowed_competitions = [SLAP, DANCE]

appearance_profile_id = appearance_male_mine_rival
```

Expected story path:

```text
rival_actress win
→ Authority +2
→ rival_mine_boss threshold satisfied
```

Ordinary rivals provide recovery if player loses Authority.

---

# 17. Ordinary rivals — exact

Add:

```text
rival_city_tracksuit
rival_gym_mirror
rival_cafe_receipt
rival_city_silent
```

### `rival_city_tracksuit`

```text
display = "Самец в спортивном костюме"
required_authority = 0
reward = 1
MUSCLE1 APPEARANCE0 CAPITAL0 AURA0
preferred = SLAP
allowed = [SLAP, DANCE]
location = city_hub
```

### `rival_gym_mirror`

```text
display = "Самец у зеркала"
required_authority = 1
reward = 1
MUSCLE1 APPEARANCE2 CAPITAL0 AURA1
preferred = DANCE
allowed = [DANCE, SLAP]
location = gym
```

### `rival_cafe_receipt`

```text
display = "Самец с чеком"
required_authority = 2
reward = 1
MUSCLE0 APPEARANCE1 CAPITAL2 AURA1
preferred = MONEY
allowed = [MONEY, DANCE]
location = cafe
```

### `rival_city_silent`

```text
display = "Молчащий самец"
required_authority = 3
reward = 1
MUSCLE1 APPEARANCE0 CAPITAL0 AURA2
preferred = SIGMA
allowed = [SIGMA, SLAP]
location = city_hub public segment
```

Player initiates all 14A ordinary encounters; no ambush AI.

---

# 18. Production appearance profiles

Create:

Girls:

```text
appearance_female_neighbor
appearance_female_actress
appearance_female_mine_boss
appearance_female_city_bicycle
appearance_female_cafe_laptop
appearance_female_gym_chalk
appearance_female_appearance_ritual
```

Men:

```text
appearance_male_actress_rival
appearance_male_mine_rival
appearance_male_city_tracksuit
appearance_male_gym_mirror
appearance_male_cafe_receipt
appearance_male_city_silent
```

Use one existing male base and one existing female base. Variation only through current Character Framework: clothes/hair/accessories/materials/proportions/poses.

Do not block on final assets.

---

# 19. RivalActor production presentation — required

Current `RivalActor` is only an Interactable. Extend it minimally:

```text
RivalDefinition.appearance_profile_id
→ CharacterFactory.create(...)
→ child CharacterActor
```

No AI/navigation.

On matching `encounter_won`:

```text
interaction disabled immediately
optional react
~0.6–1.0s
hide / queue_free
```

On scene reload, defeated rival starts absent.

No defeated rival becomes follower/helper.

---

# 20. StageActorAnchor

Create:

```text
class_name StageActorAnchor
extends Marker3D
```

Exports:

```text
actor_kind: GIRL / RIVAL
content_id: StringName
story_stage: GameStage
```

Responsibility only:

```text
if current stage matches:
    instantiate GirlActor/RivalActor

else:
    remove current actor
```

For rival also skip if `GameState.is_rival_defeated(content_id)`.

Listen to stage/encounter signals. No `_process()`.

Do NOT create generic SpawnCondition/SpawnTable DSL.

Use for:

```text
girl_neighbor
girl_actress
rival_actress
girl_mine_boss
rival_mine_boss
```

---

# 21. Story-lock feedback

Extend `GirlActor` functional feedback:

```text
STORY_RIVAL_REQUIRED
→ "Сначала разберись с её текущим ухажёром."

STORY_WRONG_STAGE
→ "Эта линия пока недоступна."
```

These are NOT failures:

- no clue;
- no retry cooldown;
- no relationship effect.

Extend `RivalActor` similarly for low Authority / locked competition so production interaction never fails silently.

---

# 22. Production date binding

MODULE 09 intentionally left this to content.

Extend `GirlDefinition` minimally:

```text
@export var default_date_location_id: StringName = &""
@export var dating_greeting_ids: Array[StringName] = []
@export var dating_farewell_id: StringName = &""
```

Validation for production girls with dating pools:

- date location exists;
- greetings non-empty and all exist;
- farewell exists.

14A venue mapping:

```text
girl_neighbor → apartment
all other 14A girls → cafe
```

---

# 23. Common greetings

Create:

```text
dating_greeting_simple
dating_greeting_attention
dating_greeting_immediate_joke
dating_greeting_check_comfort
```

### Simple

```text
"Просто поздороваться"
tags = [SIMPLICITY]
no requirement
```

### Attention

```text
"Отметить её образ"
tags = [PRESTIGE]
APPEARANCE 1
```

### Weird opening

```text
"Начать с странного наблюдения"
tags = [ABSURDITY]
AURA 1
```

### Comfort

```text
"Спросить, удобно ли место"
tags = [CARE]
no requirement
```

Greeting remains diagnostic only; no relationship points.

Every 14A girl uses these four.

---

# 24. Common farewell

Create:

```text
dating_farewell_early_common
```

Actions:

```text
date_action_farewell_walk
"Проводить до выхода"
MUSCLE 0
[CARE, SIMPLICITY]
```

```text
date_action_farewell_car
"Заказать машину к самой двери"
CAPITAL 1
money_cost = 10
[PRESTIGE, CONTROL]
```

```text
date_action_farewell_extra_block
"Предложить пройти ещё один квартал без причины"
AURA 1
[SPONTANEITY]
```

```text
date_action_farewell_photo_shadow
"Сфотографировать только ваши тени"
APPEARANCE 1
[ORIGINALITY]
```

---

# 25. Apartment dating content

Create union of minimum 6 apartment events:

```text
2 CONVERSATION
2 SPACE_EVENT
2 GIRL_PROPOSAL
```

Pools:

```text
dating_pool_apartment_common
dating_pool_neighbor
```

Exact events:

### `date_event_apartment_laminate` — CONVERSATION

Setup:

```text
"Она спрашивает, почему возле стены лежит один кусок ламината, который явно никуда не устанавливают."
```

Actions:

```text
"Сказать: «Пахнет ламинатом и надеждами.»"
AURA0
[ABSURDITY, ORIGINALITY]

"Признать, что кусок просто остался"
MUSCLE0
[VULNERABILITY, SIMPLICITY]

"Объяснить, что это контрольный образец пола"
CAPITAL1
[CONTROL]

"Поставить его вертикально как декор"
APPEARANCE1
[PRESTIGE, ABSURDITY]
```

### `date_event_apartment_failed_recipe` — CONVERSATION

```text
"На кухне находится блюдо, которое визуально прекратило быть блюдом несколько решений назад."
```

```text
"Сказать, что не получилось"
AURA0 [VULNERABILITY]

"Заказать нормальную еду"
CAPITAL1 money8 [CONTROL, PRESTIGE]

"Съесть первым для проверки"
MUSCLE1 [RISK]

"Переименовать блюдо"
APPEARANCE1 [ORIGINALITY, ABSURDITY]
```

### `date_event_apartment_chair` — SPACE_EVENT

```text
"Один из двух стульев начинает подозрительно покачиваться."
```

```text
"Отдать нормальный стул ей"
MUSCLE0 [CARE, SIMPLICITY]

"Починить ножку салфеткой"
AURA0 [CONTROL, SIMPLICITY]

"Заказать новый стул прямо сейчас"
CAPITAL1 money10 [PRESTIGE, CONTROL]

"Объявить шатание частью дизайна"
APPEARANCE1 [ABSURDITY]
```

### `date_event_apartment_neighbor_noise` — SPACE_EVENT

```text
"За стеной кто-то три раза сверлит ровно по одной секунде."
```

```text
"Ничего не делать"
AURA0 [SIMPLICITY]

"Пойти узнать, нужна ли помощь"
MUSCLE0 [CARE]

"Предложить купить соседу нормальную дрель"
CAPITAL1 [CONTROL, PRESTIGE]

"Ответить тремя ударами ложкой по трубе"
APPEARANCE1 [CONFLICT, ABSURDITY]
public=true
```

### `date_event_apartment_balcony` — GIRL_PROPOSAL

```text
"Она предлагает выйти на балкон, хотя там заметно холоднее."
```

```text
"Выйти сразу"
MUSCLE0 [RISK, SPONTANEITY]

"Принести ей плед"
AURA0 [CARE]

"Сначала закрыть все окна"
CAPITAL1 [CONTROL]

"Выйти ради света для фотографии"
APPEARANCE1 [PRESTIGE, ORIGINALITY]
```

### `date_event_apartment_mug_rule` — GIRL_PROPOSAL

```text
"Она предлагает пить из случайно выбранных кружек и не спрашивать, кому какая принадлежит."
```

```text
"Согласиться без проверки"
AURA0 [SPONTANEITY]

"Выбрать самую простую"
MUSCLE0 [SIMPLICITY]

"Распределить кружки по состоянию"
CAPITAL1 [CONTROL]

"Выбрать кружку по отражению в окне"
APPEARANCE1 [ABSURDITY, ORIGINALITY]
```

---

# 26. Cafe dating pool

Create:

```text
dating_pool_cafe_common
```

Exactly minimum:

```text
12 events
4 CONVERSATION
4 SPACE_EVENT
4 GIRL_PROPOSAL
```

All allowed location:

```text
[cafe]
```

---

# 27. Cafe conversations

### `date_event_cafe_failure`

```text
"Она спрашивает о последней вещи, которая у тебя действительно не получилась."
```

```text
"Рассказать как было"
AURA0 [VULNERABILITY]

"Объяснить, что это был стресс-тест"
CAPITAL1 [CONTROL, ABSURDITY]

"Сказать, что теперь сделал бы силой"
MUSCLE1 [DOMINANCE]

"Превратить историю в красивую версию"
APPEARANCE1 [PRESTIGE]
```

### `date_event_cafe_expensive_water`

```text
"В меню есть вода, которая стоит подозрительно много."
```

```text
"Заказать обычную"
MUSCLE0 [SIMPLICITY]

"Заказать дорогую и не обсуждать"
CAPITAL1 money10 [PRESTIGE]

"Спросить, что именно контролирует цену"
AURA1 [CONTROL]

"Выбрать её по форме бутылки"
APPEARANCE1 [ORIGINALITY]
```

### `date_event_cafe_rule`

```text
"Она спрашивает, какое бытовое правило кажется тебе самым бессмысленным."
```

```text
"Назвать правило и признать, что всё равно соблюдаешь"
AURA0 [SIMPLICITY]

"Сказать, что правила нужны для контроля"
CAPITAL1 [CONTROL]

"Предложить немедленно нарушить одно"
MUSCLE1 [RISK, SPONTANEITY]

"Придумать новое правило вместо старого"
APPEARANCE1 [ABSURDITY, ORIGINALITY]
```

### `date_event_cafe_attention`

```text
"Она спрашивает, что ты первым замечаешь в незнакомом месте."
```

```text
"Кому неудобно"
AURA0 [CARE]

"Где выход"
MUSCLE0 [CONTROL]

"Что здесь самое дорогое"
CAPITAL1 [PRESTIGE]

"Что выглядит не на своём месте"
APPEARANCE1 [ORIGINALITY]
```

---

# 28. Cafe space events

### `date_event_cafe_table_taken`

```text
"Стол у окна занят одним человеком и четырьмя пакетами."
```

```text
"Выбрать другой стол"
AURA0 [SIMPLICITY]

"Вежливо попросить убрать один пакет"
MUSCLE0 [CARE]

"Оплатить человеку десерт за переезд"
CAPITAL1 money12 [PRESTIGE, CONTROL]

"Стоять рядом так, будто это уже ваш стол"
APPEARANCE1 [DOMINANCE, ABSURDITY]
public=true
```

Optional perk action:

```text
"Удерживать проход, пока ситуация сама не станет понятной"
required_perk = perk_muscle_hold_doorway
MUSCLE
[DOMINANCE, CONFLICT]
public=true
```

### `date_event_cafe_spill`

```text
"Официант задевает стакан, и вода идёт прямо к её телефону."
```

```text
"Закрыть телефон рукой"
MUSCLE0 [CARE, RISK]

"Поднять всё со стола по порядку"
CAPITAL1 [CONTROL]

"Отодвинуть телефон и успокоить официанта"
AURA0 [CARE]

"Сделать из салфеток дамбу"
APPEARANCE1 [ORIGINALITY, ABSURDITY]
```

### `date_event_cafe_queue`

```text
"У кассы появляется очередь, хотя никто не понимает, кто её начал."
```

```text
"Встать последним"
MUSCLE0 [SIMPLICITY]

"Организовать очередь по времени прихода"
CAPITAL1 [CONTROL]

"Спросить вслух, существует ли очередь"
AURA0 [CONFLICT, ORIGINALITY]
public=true

"Выглядеть так, будто вы уже обслужены"
APPEARANCE1 [PRESTIGE, ABSURDITY]
```

### `date_event_cafe_broken_chair`

```text
"У соседнего стола ломается стул. Человек остаётся примерно на той же высоте и делает вид, что ничего не произошло."
```

```text
"Помочь встать"
MUSCLE0 [CARE]

"Позвать сотрудника"
AURA0 [CONTROL]

"Оплатить ему новый заказ"
CAPITAL1 money8 [PRESTIGE, CARE]

"Поддержать его решение продолжать сидеть"
APPEARANCE1 [ABSURDITY, OBSESSION]
```

---

# 29. Cafe girl proposals

### `date_event_cafe_walk_rain`

```text
"Она предлагает выйти прогуляться, хотя начинается дождь."
```

```text
"Пойти сразу"
MUSCLE0 [RISK, SPONTANEITY]

"Найти ей зонт"
AURA0 [CARE]

"Заказать машину на один квартал"
CAPITAL1 money10 [PRESTIGE, CONTROL]

"Подождать отражения вывесок в лужах"
APPEARANCE1 [ORIGINALITY]
```

### `date_event_cafe_musician`

```text
"Она предлагает решить, что делать с уличным музыкантом за окном."
```

```text
"Выйти послушать"
AURA0 [SIMPLICITY, SPONTANEITY]

"Оставить деньги"
CAPITAL1 money6 [CARE, PRESTIGE]

"Предложить перенести колонку"
MUSCLE1 [CONTROL]

"Сделать вид, что музыка — саундтрек вашей сцены"
APPEARANCE1 [ABSURDITY, ORIGINALITY]
```

### `date_event_cafe_statue`

```text
"Она предлагает сфотографироваться с крайне неудачной декоративной статуей."
```

```text
"Согласиться как есть"
MUSCLE0 [SIMPLICITY]

"Поставить статую в центр кадра"
APPEARANCE1 [ABSURDITY, ORIGINALITY]

"Оплатить пять минут перестановки света"
CAPITAL1 money8 [PRESTIGE, CONTROL]

"Убедить прохожего тоже встать в кадр"
AURA1 [SPONTANEITY, CONFLICT]
public=true
```

### `date_event_cafe_dessert_first`

```text
"Она предлагает заказать десерт первым и уже потом решить, нужен ли остальной ужин."
```

```text
"Согласиться"
AURA0 [SPONTANEITY]

"Взять самый простой десерт"
MUSCLE0 [SIMPLICITY]

"Заказать весь раздел сразу"
CAPITAL1 money15 [PRESTIGE, OBSESSION]

"Попросить принести его как главное блюдо"
APPEARANCE1 [ABSURDITY, ORIGINALITY]
```

---

# 30. Story-specific pools

Create:

```text
dating_pool_actress
dating_pool_mine_boss
```

Они могут в 14A содержать 1–2 additional themed events, но это НЕ blocker: `dating_pool_cafe_common` уже должен обеспечивать полноценный date.

Не тратить 14A на десятки уникальных story-only events.

---

# 31. Content balance rules

Для всех direct dating actions:

- max 2 tags;
- requirement mostly 0–1;
- rare 2 only if optional;
- каждый event имеет минимум один free action;
- ни одна story line не требует Money;
- no hidden correct-choice marker.

Characteristic describes HOW hero solves it, not which trait likes it.

Не делать fixed mapping:

```text
Muscle = Risk always
Capital = Prestige always
```

---

# 32. DateVenueInteractable

Create:

```text
class_name DateVenueInteractable
extends Interactable
```

Production instances:

```text
apartment:
[E] Стол для свидания

cafe:
[E] Столик для свиданий
```

Flow:

1. determine current location;
2. list girls with contact;
3. filter `GirlDefinition.default_date_location_id == current`;
4. query `Relationships.get_date_availability`;
5. show available + cooldown rows;
6. select girl;
7. build `DatingStartRequest` from GirlDefinition;
8. call `Relationships.start_date_with_history(request)`;
9. open existing `DatingUI`.

No scheduling/time slots/messages.

---

# 33. DateVenue result

Date finishes in same loaded world location.

MODULE10 automatically applies:

```text
relationship
cooldown
completion
XP
```

DateVenue does not duplicate this.

---

# 34. Production Progression entry

Add apartment physical:

```text
ProgressionInteractable
prompt = "[E] Самооценка"
```

Visual can be mirror/wardrobe/clipboard placeholder.

Functional modal only, final UI stays MODULE22.

Show:

```text
Upgrade Points
next perk cost
four characteristics
all perks with:
owned / prerequisite / cost / buy
```

Use ONLY `Progression` public API for tree/purchase rules.

Open = MODAL_UI; close = GAMEPLAY.

---

# 35. Phone functional additions

Without redesign, add small top status:

```text
День
Деньги
Авторитет
Покоренных сердец
Баллы прокачки
```

Add Story section:

```text
СЮЖЕТ
<stage>

Ухажёр: ...
Девушка: ...
```

Read from `Story.get_current_stage_progress()`.

After STAGE3 existing Salary section appears automatically.

No final HUD.

---

# 36. Production placement exact

```text
PROLOGUE
apartment:
StageActorAnchor → girl_neighbor

STAGE_1
appearance_space:
StageActorAnchor → rival_actress
StageActorAnchor → girl_actress

STAGE_2
city_hub mine entrance:
StageActorAnchor → rival_mine_boss
StageActorAnchor → girl_mine_boss
```

Ordinary:

```text
city_hub:
girl_city_bicycle
rival_city_tracksuit

public city segment:
rival_city_silent

cafe:
girl_cafe_laptop
rival_cafe_receipt
DateVenueInteractable

gym:
girl_gym_chalk
rival_gym_mirror

appearance_space:
girl_appearance_ritual
```

Keep prompts targetable; roughly 2.5–4m separation.

---

# 37. Stage consequences

### After Neighbor +5

```text
Experience1
UP1
STAGE_1
SOCIAL_ACCESS
```

### After Actress +5

```text
Experience2
STAGE_2
PUBLIC_CITY_ACCESS
```

Public city barrier dynamically opens.

### After Mine Boss +5

```text
Experience3
STAGE_3
SALARY_MINE
```

Mine transition opens and SalaryMine initializes period1.

No extra flags.

---

# 38. No-grind feasibility

Canonical story path requires no ordinary girl grind:

```text
Neighbor requires XP0
→ XP1

Actress requires XP1
→ XP2

Mine Boss requires XP2
→ XP3
```

Authority:

```text
rival_actress required0, reward2
→ Authority2

rival_mine_boss required2
```

Ordinary NPCs are optional recovery/variety.

---

# 39. Story contest accessibility

Required 14A story rivals use:

```text
DANCE
SLAP
```

only.

Do NOT require `CAPITAL_PAYABLE_INTENT` or `AURA_PRESENCE_REGISTERED` to progress main story in 14A.

---

# 40. Tone

Authored text rule:

> Мир относится к абсурдной логике серьёзно.

No fourth-wall jokes.  
No meme-keyword spam.  
Women are not the humiliation target.  
Hero remains pathologically confident, but mostly benign.

Canonical apartment caption may be added:

```text
"Пахнет ламинатом и надеждами."
```

Do not write full MODULE25 caption catalog.

---

# 41. Production validation — mandatory

`ContentDB.validate_all()` PASS.

Check:

- all 7 girls;
- all 6 rivals;
- all appearance profiles;
- all 7 discovery situations;
- all approaches globally unique;
- greetings/farewell exist;
- GirlDefinition date bindings valid;
- apartment event union feasible;
- cafe 12-event pool exactly 4/category minimum;
- all event action IDs valid;
- tags max2;
- all locations valid.

---

# 42. Repeat-date feasibility

For every 14A girl automated test:

```text
plan first date
record 3 events
plan second date through Relationships history
```

Must succeed without immediate same-event reuse while pool supports alternatives.

Neighbor: minimum 2 dates feasible.  
Cafe girls: minimum 2 dates feasible.

---

# 43. +5 feasibility

For:

```text
girl_neighbor
girl_actress
girl_mine_boss
```

content test must prove an ideal full date can reach:

```text
date_delta = +5
```

when player chooses liked actions and satisfies the girl's secondary trait.

Do not accidentally build a pool where story girl can never reach +5.

---

# 44. Money softlock test

For every production central event:

with:

```text
Money = 0
baseline stat progression
```

at least one action remains available.

Paid actions are optional expression, never required route.

---

# 45. F5 end-to-end acceptance

Clean reset only.

Expected real route:

```text
F5
→ Neighbor discovery/contact
→ apartment date
→ Neighbor +5
→ STAGE1

→ city/appearance
→ rival_actress win
→ Actress contact
→ cafe date
→ Actress +5
→ STAGE2

→ city mine entrance
→ rival_mine_boss win
→ Mine Boss contact
→ cafe date
→ Mine Boss +5
→ STAGE3

→ Salary Mine unlocked
→ travel to mine
→ SalaryStation
→ 1.50s manual claim
→ Money increases
```

No debug stage, XP, Authority or relationship setters.

---

# 46. Specific integration tests

### Neighbor

- physically present only PROLOGUE;
- first sight reveals clue0;
- contact success;
- Apartment DateVenue lists her;
- +5 advances Stage1.

### Actress

- actors appear only Stage1;
- girl interaction before rival shows lock;
- rival win gives Authority2 and leaves;
- stage does NOT advance on rival alone;
- contact/date;
- +5 advances Stage2.

### Mine Boss

- actors appear Stage2;
- mine transition remains locked until +5;
- required Authority2 achievable;
- +5 advances Stage3;
- actors disappear from required stage;
- mine unlocks.

### Ordinary girls

Each:
- discovery works;
- date works;
- completion grants XP normally;
- Story stage unchanged.

### Ordinary rivals

Each:
- visible CharacterActor;
- challenge works;
- reward once;
- defeated remains gone.

---

# 47. Reset test

After progressed state, reset must restore:

```text
Stage PROLOGUE
GameDay1
all story rivals undefeated
contacts empty
relationships0
salary reset/locked
Neighbor actor present
Actress/MineBoss actors absent
```

No stale Stage2 children after scene refresh.

---

# 48. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/05_girls.md
docs/gdd/06_dating.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Create:

```text
docs/content/MANUAL_CONTENT_14A.md
```

Inventory columns:

```text
ID
Role
Location
Stage
Trait / Competition
XP / Authority requirement
Dating Pool
Marker
Status
```

---

# 49. What 14A does NOT implement

Do NOT implement:

- Editor;
- Scientist;
- President;
- Media feed;
- photos;
- incoming dates;
- Dating Overload;
- clones;
- NPC AI/schedules;
- dialogue engine;
- voice;
- final art;
- final HUD;
- final perk tree UI;
- save/load;
- full ordinary roster;
- full event catalog;
- MODULE15 mechanics.

---

# 50. Definition of Done

14A done only if:

- [ ] 7 production girls exist;
- [ ] 2 production story rivals + 4 ordinary rivals exist;
- [ ] all appearance profiles exist;
- [ ] RivalActor has real CharacterActor presentation;
- [ ] defeated rivals leave and stay gone;
- [ ] StageActorAnchor works without polling;
- [ ] Story girl lock feedback visible;
- [ ] low Authority rival feedback visible;
- [ ] 7 discovery situations playable;
- [ ] GirlDefinition date binding added/validated;
- [ ] 4 production greetings;
- [ ] common farewell;
- [ ] apartment minimum 6 dating events;
- [ ] cafe minimum 12 dating events, 4/category;
- [ ] all story +5 routes feasible;
- [ ] no required paid route;
- [ ] DateVenueInteractable works in apartment and cafe;
- [ ] ProgressionInteractable works in apartment;
- [ ] Phone global/story status works;
- [ ] full F5 route reaches STAGE3 without debug;
- [ ] Salary Mine opens through real Mine Boss completion;
- [ ] first salary physically claimable;
- [ ] ContentDB validation PASS;
- [ ] all MODULE 02–13 regressions PASS;
- [ ] no 14B/15 content implemented ahead.

---

# 51. Recommended Cursor order

```text
1. Audit actual APIs.
2. Add GirlDefinition date binding + validation.
3. Implement DateVenueInteractable on fixtures.
4. Make RivalActor visible + defeated leave.
5. Implement StageActorAnchor.
6. Add Neighbor → Actress → Mine Boss skeleton content.
7. Prove F5 story progression.
8. Add 4 ordinary girls + 4 ordinary rivals.
9. Add greetings/farewell.
10. Add apartment6 + cafe12 dating content.
11. Add ProgressionInteractable.
12. Add Phone global/story status.
13. Full clean-run test.
14. ContentDB + all regressions.
15. Docs/content inventory.
```

---

# 52. Cursor final report

## Production route

Show real:

```text
F5 → Neighbor → Actress → Mine Boss → STAGE3 → Salary Mine
```

without debug.

## Content inventory

Counts:

```text
girls
rivals
appearances
discovery situations
dating events
greetings
farewells
```

## Dating entry

Explain physical DateVenue → `DatingStartRequest`.

## Story placement

Explain StageActorAnchor.

## Rival presentation

Explain CharacterActor + leave-after-defeat.

## Progression entry

Explain actual player perk purchase entry.

## Validation

ContentDB, F5 full route and all regressions.

## Commit

SHA.

After that STOP. Do not start 14B.
