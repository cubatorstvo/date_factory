# Venues & Local Objects

**Статус:** канон production DateVenues и Local Objects  
**Текущий продукт:** Date System Lab  
**Связанные документы:** [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md), [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md)

Точные IDs, тексты, цены и UI-контракты этого файла — source of truth. High-level Stage 1–4 — [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md). Runtime Date Engine — [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md).

Accent reassignment price uses **Story Stage** `2 / 3 / 4+` (`$300 / $600 / $1000`), not City Stage (City Stage exists only as `1–3`).

## Цель блока

Реализовать полный playable 2D-блок `Venues & Local Objects` поверх текущего Dating Core.

После блока в production существуют четыре основных DateVenue:

```text
apartment
cafe
leisure_center
restaurant
```

Их progression:

```text
Stage 1:
Apartment

Stage 2:
Apartment
Café
Leisure Center

Stage 3:
Apartment
Café
Leisure Center
Restaurant

Stage 4:
те же четыре Venue с полным развитием Apartment
```

Local Source progression:

```text
Stage 1:
Apartment Local coverage = 0
Local Source фактически отсутствует

Stage 2:
Local Source становится активной частью Date build
Apartment = до 4 Tags
Café = 6 Tags
Leisure Center = 8 Tags

Stage 3:
Apartment = до 8 Tags
Restaurant = 8 Tags
Outfit / Characteristic / Venue начинают полноценно сочетаться

Stage 4:
Apartment = до 12 Tags
late rewards усиливают уже освоенные Venue
```

---

# 1. Canonical Local Object model

## Public Venue

Для Café, Leisure Center и Restaurant:

```text
Local Object
→ 2 authored Local Moves
→ 2 разных Tags
```

Tags внутри одного public Venue уникальны.

Итог:

```text
Café:
3 objects
6 Local Moves
6 unique Tags

Leisure Center:
4 objects
8 Local Moves
8 unique Tags

Restaurant:
4 objects
8 Local Moves
8 unique Tags
```

## Apartment

Для Apartment:

```text
1 purchasable Apartment Object
→ 1 Local Move
→ 1 unique Tag
```

Итоговый catalog:

```text
12 Apartment Objects
12 Local Moves
12 unique Tags
```

Все купленные Apartment Objects одновременно входят в Apartment Local Source.

---

# 2. Local Move runtime contract

Каждый Local Move использует текущую canonical `DateMove` architecture.

Semantic fields:

```text
kind = LOCAL
fixed_tag_id
fixed_option_text
fixed_positive_result_text
fixed_negative_result_text
```

Local Move принадлежит одному Local Object.

Local Object принадлежит одному Venue.

Default Venue Source usage:

```text
1 раз за Date
```

Конкретный Local Move:

```text
max_uses_per_date = 1
```

Reward Сони для Restaurant:

```text
Restaurant Venue Source uses = 2
```

При двух использованиях выбираются два Local Moves; каждый конкретный Move остаётся одноразовым.

---

# 3. Canonical IDs

## Venue IDs

```text
apartment
cafe
leisure_center
restaurant
```

## Object ID convention

```text
<venue_id>__<object_name>
```

Примеры:

```text
cafe__barista
leisure_center__claw_machine
restaurant__waiter
apartment__plaid
```

## Local Move ID convention

```text
<object_id>__<action_id>
```

Пример:

```text
leisure_center__claw_machine__get_toy
```

---

# 4. Local Source player-facing format

В Local Source каждая строка Move отображается в формате:

```text
[ТЕГ] Объект: действие
```

Примеры:

```text
[ЗАБОТА] Плед: Предложить ей плед и устроиться поудобнее
[РИСК] Гоночный автомат: Выбрать максимальную сложность и отключить помощь
[ЛЕСТЬ] Живая музыка: Попросить музыканта посвятить ей композицию
```

Квадратные скобки используются только для Tag.

Tag отображается через существующую canonical систему knowledge-coloring:

```text
known positive
known negative
unknown
```

Characteristic-locked Move использует существующую locked presentation и текст:

```text
требуется <Характеристика> ур. N
```

---

# 5. Café

## Identity

```text
casual
public
social / everyday interaction
Stage 2
```

Café имеет 3 Local Objects и 6 уникальных Tags.

## 5.1 Бариста

Object ID:

```text
cafe__barista
```

### POLITENESS

Move ID:

```text
cafe__barista__lady_first
```

Tag:

```text
politeness
```

Option:

```text
[УЧТИВОСТЬ] Бариста: Попросить сначала принять заказ девушки
```

Positive result:

```text
Ей нравится спокойная вежливость в обычной ситуации.
```

Negative result:

```text
Ей кажется, что ты слишком церемонишься из-за простой покупки кофе.
```

### DIRECTNESS

Move ID:

```text
cafe__barista__best_item
```

Tag:

```text
directness
```

Option:

```text
[ПРЯМОТА] Бариста: Спросить, что здесь реально самое вкусное
```

Positive result:

```text
Ей нравится простой вопрос без изучения меню как документации.
```

Negative result:

```text
Ей кажется, что ты слишком легко отдаёшь выбор незнакомому человеку.
```

---

## 5.2 Полка настольных игр

Object ID:

```text
cafe__board_games
```

### CUNNING

Move ID:

```text
cafe__board_games__set_trap
```

Tag:

```text
cunning
```

Option:

```text
[ХИТРОСТЬ] Настольные игры: Выбрать игру и быстро заманить её в ловушку
```

Positive result:

```text
Её веселит, что спокойная игра сразу превратилась в маленькую дуэль.
```

Negative result:

```text
Она замечает подвох и считает такой старт слишком расчётливым.
```

### HUMOR

Move ID:

```text
cafe__board_games__ridiculous_game
```

Tag:

```text
humor
```

Option:

```text
[ЮМОР] Настольные игры: Взять самую нелепую игру и начать до чтения правил
```

Positive result:

```text
Она включается в хаос и смеётся над происходящим.
```

Negative result:

```text
Ей хотелось хотя бы понять правила до начала катастрофы.
```

---

## 5.3 Окно

Object ID:

```text
cafe__window
```

### CARE

Move ID:

```text
cafe__window__fresh_air
```

Tag:

```text
care
```

Option:

```text
[ЗАБОТА] Окно: Слегка приоткрыть окно, заметив, что ей душно
```

Positive result:

```text
Она замечает, что ты обратил внимание на её комфорт.
```

Negative result:

```text
Ей кажется, что ты слишком внимательно контролируешь каждую мелочь.
```

### AUDACITY

Move ID:

```text
cafe__window__open_to_street
```

Tag:

```text
audacity
```

Option:

```text
[НАГЛОСТЬ] Окно: Распахнуть окно и продолжить разговор будто теперь участвует вся улица
```

Positive result:

```text
Её смешит неожиданно публичный поворот разговора.
```

Negative result:

```text
Она предпочла бы оставить ваше свидание внутри помещения.
```

---

# 6. Leisure Center

## Identity

```text
active
public
physical / competitive interaction
Stage 2
```

Leisure Center имеет 4 Local Objects и 8 уникальных Tags.

Эти Object IDs становятся стабильными integration points для будущих коротких 3D activities.

---

## 6.1 Автомат-хватайка

Object ID:

```text
leisure_center__claw_machine
```

### CARE

Move ID:

```text
leisure_center__claw_machine__get_toy
```

Tag:

```text
care
```

Option:

```text
[ЗАБОТА] Автомат-хватайка: Попытаться достать игрушку, которая ей понравилась
```

Positive result:

```text
Ей приятно, что ты сразу превратил её интерес в маленькую цель.
```

Negative result:

```text
Она считает, что игрушка не стоила такого количества усилий.
```

### CUNNING

Move ID:

```text
leisure_center__claw_machine__study_mechanism
```

Tag:

```text
cunning
```

Option:

```text
[ХИТРОСТЬ] Автомат-хватайка: Изучить механизм и выбрать лучший момент для захвата
```

Positive result:

```text
Ей нравится, как быстро ты превращаешь автомат в решаемую задачу.
```

Negative result:

```text
Она хотела просто поиграть, а не наблюдать инженерный аудит автомата.
```

---

## 6.2 Гоночный автомат

Object ID:

```text
leisure_center__racing_arcade
```

### RISK

Move ID:

```text
leisure_center__racing_arcade__max_difficulty
```

Tag:

```text
risk
```

Option:

```text
[РИСК] Гоночный автомат: Выбрать максимальную сложность и отключить помощь
```

Positive result:

```text
Ей нравится сразу поднять ставки.
```

Negative result:

```text
Она считает, что сначала можно было хотя бы понять управление.
```

### AUDACITY

Move ID:

```text
leisure_center__racing_arcade__winner_wish
```

Tag:

```text
audacity
```

Option:

```text
[НАГЛОСТЬ] Гоночный автомат: Предложить маленькое желание победителю
```

Positive result:

```text
Дерзкое условие делает гонку для неё интереснее.
```

Negative result:

```text
Ей не нравится добавлять обязательства к обычной игре.
```

---

## 6.3 Аэрохоккей

Object ID:

```text
leisure_center__air_hockey
```

### DOMINANCE

Move ID:

```text
leisure_center__air_hockey__play_seriously
```

Tag:

```text
dominance
```

Option:

```text
[ДОМИНИРОВАНИЕ] Аэрохоккей: Играть всерьёз и вообще не поддаваться
```

Positive result:

```text
Ей нравится настоящее соревнование без скидок.
```

Negative result:

```text
Она считает, что ты слишком серьёзно воспринял маленькую игру.
```

### HUMOR

Move ID:

```text
leisure_center__air_hockey__world_final
```

Tag:

```text
humor
```

Option:

```text
[ЮМОР] Аэрохоккей: Комментировать матч будто идёт финал чемпионата мира
```

Positive result:

```text
Она смеётся и начинает подыгрывать комментатору.
```

Negative result:

```text
Ей хотелось слышать хотя бы звук самой игры.
```

---

## 6.4 Стойка призов

Object ID:

```text
leisure_center__prize_counter
```

### GENEROSITY

Move ID:

```text
leisure_center__prize_counter__gift_prize
```

Tag:

```text
generosity
```

Option:

```text
[ЩЕДРОСТЬ] Стойка призов: Потратить выигранные жетоны на приз для неё
```

Positive result:

```text
Маленький подарок ей приятен.
```

Negative result:

```text
Она предпочла бы, чтобы ты выбрал что-нибудь себе.
```

### STATUS

Move ID:

```text
leisure_center__prize_counter__giant_trophy
```

Tag:

```text
status
```

Option:

```text
[СТАТУС] Стойка призов: Забрать самый огромный приз и нести его как трофей
```

Positive result:

```text
Её веселит, насколько серьёзно ты относишься к своему новому символу победы.
```

Negative result:

```text
Она считает гигантский трофей слишком заметным даже для тебя.
```

---

# 7. Restaurant

## Identity

```text
formal
service-oriented
high-preparation Venue
Stage 3
```

Restaurant имеет 4 Local Objects и 8 уникальных Tags.

Все 8 Restaurant Local Moves используют Characteristic requirement.

Restaurant обучает Stage 3 synergy:

```text
Outfit stat bonus
→ Characteristic level
→ Restaurant Local Move availability
```

Распределение requirements:

```text
Мышца:
1 Move требует ур. 1
1 Move требует ур. 3

Внешность:
1 Move требует ур. 1
1 Move требует ур. 3

Капитал:
1 Move требует ур. 1
1 Move требует ур. 3

Аура:
1 Move требует ур. 1
1 Move требует ур. 3
```

---

## 7.1 Официант

Object ID:

```text
restaurant__waiter
```

### POLITENESS — Appearance 1

Move ID:

```text
restaurant__waiter__lady_first
```

Tag:

```text
politeness
```

Requirement:

```text
Внешность ур. 1
```

Option:

```text
[УЧТИВОСТЬ] Официант: Попросить сначала обслужить девушку
```

Positive result:

```text
Ей нравится естественная вежливость без лишнего спектакля.
```

Negative result:

```text
Она считает такую церемонию лишней.
```

### DOMINANCE — Muscle 3

Move ID:

```text
restaurant__waiter__set_service_order
```

Tag:

```text
dominance
```

Requirement:

```text
Мышца ур. 3
```

Option:

```text
[ДОМИНИРОВАНИЕ] Официант: Взять организацию заказа на себя и задать порядок подачи
```

Positive result:

```text
Ей нравится, как уверенно ты организовал ситуацию.
```

Negative result:

```text
Она не хотела, чтобы обычный заказ превращался в командование персоналом.
```

---

## 7.2 Дегустационный сет

Object ID:

```text
restaurant__tasting_set
```

### STATUS — Capital 3

Move ID:

```text
restaurant__tasting_set__signature_set
```

Tag:

```text
status
```

Requirement:

```text
Капитал ур. 3
```

Option:

```text
[СТАТУС] Дегустационный сет: Заказать фирменный сет ресторана как очевидный выбор
```

Positive result:

```text
Ей нравится уверенный выбор премиального варианта.
```

Negative result:

```text
Она считает, что впечатление от цены для тебя важнее самого вечера.
```

### COMPOSURE — Aura 3

Move ID:

```text
restaurant__tasting_set__trust_the_chef
```

Tag:

```text
composure
```

Requirement:

```text
Аура ур. 3
```

Option:

```text
[СПОКОЙСТВИЕ] Дегустационный сет: Довериться выбору шефа и спокойно ждать сюрприз
```

Positive result:

```text
Ей нравится, что ты не пытаешься контролировать каждую деталь.
```

Negative result:

```text
Она предпочла бы заранее понимать, что именно принесут.
```

---

## 7.3 Живая музыка

Object ID:

```text
restaurant__live_music
```

### FLATTERY — Appearance 3

Move ID:

```text
restaurant__live_music__dedication
```

Tag:

```text
flattery
```

Requirement:

```text
Внешность ур. 3
```

Option:

```text
[ЛЕСТЬ] Живая музыка: Попросить музыканта посвятить ей композицию
```

Positive result:

```text
Красивый публичный комплимент ей нравится.
```

Negative result:

```text
Она считает такое внимание слишком демонстративным.
```

### GENEROSITY — Capital 1

Move ID:

```text
restaurant__live_music__tip_performance
```

Tag:

```text
generosity
```

Requirement:

```text
Капитал ур. 1
```

Option:

```text
[ЩЕДРОСТЬ] Живая музыка: Хорошо отблагодарить музыканта за отдельное исполнение
```

Positive result:

```text
Ей нравится щедро оценить чужую работу.
```

Negative result:

```text
Она считает, что ты слишком легко превращаешь впечатления в расходы.
```

---

## 7.4 Открытая кухня

Object ID:

```text
restaurant__open_kitchen
```

### CARE — Aura 1

Move ID:

```text
restaurant__open_kitchen__adjust_for_her
```

Tag:

```text
care
```

Requirement:

```text
Аура ур. 1
```

Option:

```text
[ЗАБОТА] Открытая кухня: Попросить изменить блюдо с учётом её вкусов
```

Positive result:

```text
Она замечает, что ты запомнил её предпочтения и подумал о комфорте.
```

Negative result:

```text
Она считает, что ради неё совсем не обязательно менять работу кухни.
```

### DIRECTNESS — Muscle 1

Move ID:

```text
restaurant__open_kitchen__ask_chef
```

Tag:

```text
directness
```

Requirement:

```text
Мышца ур. 1
```

Option:

```text
[ПРЯМОТА] Открытая кухня: Спросить шефа напрямую, что он сам здесь заказал бы
```

Positive result:

```text
Ей нравится получить простой ответ прямо от человека, который знает меню лучше всех.
```

Negative result:

```text
Она считает, что можно было выбрать самостоятельно.
```

---

# 8. Restaurant requirement summary

Validator проверяет точное распределение:

| Characteristic | Level 1 | Level 3 |
|---|---|---|
| Мышца | DIRECTNESS / Открытая кухня | DOMINANCE / Официант |
| Внешность | POLITENESS / Официант | FLATTERY / Живая музыка |
| Капитал | GENEROSITY / Живая музыка | STATUS / Дегустационный сет |
| Аура | CARE / Открытая кухня | COMPOSURE / Дегустационный сет |

Итог:

```text
8 Restaurant Local Moves
8 Characteristic-gated Moves
4 requirements ур. 1
4 requirements ур. 3
2 Moves per Characteristic
```

---

# 9. Apartment canonical model

Apartment Local Objects являются purchasable interactive interior upgrades.

Базовая мебель квартиры существует отдельно от Local Object progression.

Все Local Objects имеют authored fixed placement в Apartment scene/presentation.

Apartment catalog содержит ровно 12 Local Objects и покрывает все 12 canonical Tags ровно по одному разу.

Apartment Local Moves используют:

```text
Characteristic requirement = none
```

Apartment является надёжным purchased toolkit.

---

# 10. Apartment Stage 2 Objects — 4 / 12

## 10.1 Плед — CARE

Object ID:

```text
apartment__plaid
```

Move ID:

```text
apartment__plaid__get_comfortable
```

Tag:

```text
care
```

Price:

```text
$150
```

Option:

```text
[ЗАБОТА] Плед: Предложить ей плед и устроиться поудобнее
```

Positive result:

```text
Ей приятно, что ты подумал о её комфорте.
```

Negative result:

```text
Она считает, что ей и так было нормально.
```

---

## 10.2 Телевизор — HUMOR

Object ID:

```text
apartment__tv
```

Move ID:

```text
apartment__tv__ridiculous_show
```

Tag:

```text
humor
```

Price:

```text
$200
```

Option:

```text
[ЮМОР] Телевизор: Включить что-нибудь настолько нелепое, что это уже интересно
```

Positive result:

```text
Она быстро включается в совместный просмотр абсурда.
```

Negative result:

```text
Она не понимает, почему из всего доступного ты выбрал именно это.
```

---

## 10.3 Проигрыватель — COMPOSURE

Object ID:

```text
apartment__record_player
```

Move ID:

```text
apartment__record_player__quiet_music
```

Tag:

```text
composure
```

Price:

```text
$250
```

Option:

```text
[СПОКОЙСТВИЕ] Проигрыватель: Поставить спокойную музыку и позволить паузе просто существовать
```

Positive result:

```text
Ей нравится момент без необходимости постоянно заполнять тишину.
```

Negative result:

```text
Пауза кажется ей скорее неловкой, чем уютной.
```

---

## 10.4 Карточки «Без фильтров» — DIRECTNESS

Object ID:

```text
apartment__no_filter_cards
```

Move ID:

```text
apartment__no_filter_cards__honest_question
```

Tag:

```text
directness
```

Price:

```text
$300
```

Option:

```text
[ПРЯМОТА] Карточки «Без фильтров»: Вытянуть вопрос и ответить без ухода от темы
```

Positive result:

```text
Ей нравится, что игра действительно приводит к честному разговору.
```

Negative result:

```text
Она считает вопрос слишком прямым для такого момента.
```

---

# 11. Apartment Stage 3 Objects — 8 / 12

## 11.1 Чайный сервиз — POLITENESS

Object ID:

```text
apartment__tea_set
```

Move ID:

```text
apartment__tea_set__serve_tea
```

Tag:

```text
politeness
```

Price:

```text
$400
```

Option:

```text
[УЧТИВОСТЬ] Чайный сервиз: Нормально сервировать чай вместо случайной кружки
```

Positive result:

```text
Ей нравится аккуратное внимание к простой детали.
```

Negative result:

```text
Она считает, что обычный чай получил слишком много церемоний.
```

---

## 11.2 Мини-холодильник — GENEROSITY

Object ID:

```text
apartment__mini_fridge
```

Move ID:

```text
apartment__mini_fridge__best_stock
```

Tag:

```text
generosity
```

Price:

```text
$475
```

Option:

```text
[ЩЕДРОСТЬ] Мини-холодильник: Достать лучший запас специально для неё
```

Positive result:

```text
Ей нравится, что ты оставил хорошее именно для гостя.
```

Negative result:

```text
Она считает такой жест слишком демонстративным.
```

---

## 11.3 Большое зеркало — FLATTERY

Object ID:

```text
apartment__large_mirror
```

Move ID:

```text
apartment__large_mirror__compliment_reflection
```

Tag:

```text
flattery
```

Price:

```text
$550
```

Option:

```text
[ЛЕСТЬ] Большое зеркало: Подвести её к зеркалу и красиво отметить, как она выглядит
```

Positive result:

```text
Комплимент попадает точно в нужный момент.
```

Negative result:

```text
Она считает сцену слишком специально подготовленной для комплимента.
```

---

## 11.4 Витрина коллекции — STATUS

Object ID:

```text
apartment__collection_display
```

Move ID:

```text
apartment__collection_display__show_centerpiece
```

Tag:

```text
status
```

Price:

```text
$625
```

Option:

```text
[СТАТУС] Витрина коллекции: Показать самый впечатляющий предмет своей коллекции
```

Positive result:

```text
Ей нравится увидеть вещь, которой ты действительно гордишься.
```

Negative result:

```text
Она воспринимает экскурсию как демонстрацию достижений.
```

---

# 12. Apartment Stage 4 Objects — 12 / 12

## 12.1 Караоке-система — AUDACITY

Object ID:

```text
apartment__karaoke
```

Move ID:

```text
apartment__karaoke__sing_first
```

Tag:

```text
audacity
```

Price:

```text
$750
```

Option:

```text
[НАГЛОСТЬ] Караоке: Первым начать петь, не проверяя, насколько это хорошая идея
```

Positive result:

```text
Ей нравится, что ты сразу снимаешь неловкость собственным примером.
```

Negative result:

```text
Она считает, что проверка идеи всё-таки не помешала бы.
```

---

## 12.2 Игровая консоль — DOMINANCE

Object ID:

```text
apartment__game_console
```

Move ID:

```text
apartment__game_console__no_mercy
```

Tag:

```text
dominance
```

Price:

```text
$850
```

Option:

```text
[ДОМИНИРОВАНИЕ] Игровая консоль: Запустить соревнование и предупредить, что поддаваться не будешь
```

Positive result:

```text
Ей нравится честное соревнование без скидок.
```

Negative result:

```text
Она считает, что ты слишком быстро превратил отдых в матч.
```

---

## 12.3 Дартс — RISK

Object ID:

```text
apartment__darts
```

Move ID:

```text
apartment__darts__hard_throw
```

Tag:

```text
risk
```

Price:

```text
$950
```

Option:

```text
[РИСК] Дартс: Предложить усложнённый бросок с небольшой ставкой
```

Positive result:

```text
Ей нравится добавить обычной игре немного риска.
```

Negative result:

```text
Она считает усложнение совершенно ненужным.
```

---

## 12.4 Шахматный столик — CUNNING

Object ID:

```text
apartment__chess_table
```

Move ID:

```text
apartment__chess_table__prepared_trap
```

Tag:

```text
cunning
```

Price:

```text
$1100
```

Option:

```text
[ХИТРОСТЬ] Шахматный столик: Быстро устроить позицию с заранее подготовленной ловушкой
```

Positive result:

```text
Ей нравится обнаружить, что короткая партия уже была маленькой схемой.
```

Negative result:

```text
Она считает подготовленную ловушку слишком нечестным стартом.
```

---

# 13. Apartment catalog invariant

Validator подтверждает:

```text
12 Apartment Objects
12 Local Moves
12 unique Tags
```

Exact Tag mapping:

| Stage | Object | Tag |
|---|---|---|
| 2 | Плед | CARE |
| 2 | Телевизор | HUMOR |
| 2 | Проигрыватель | COMPOSURE |
| 2 | Карточки «Без фильтров» | DIRECTNESS |
| 3 | Чайный сервиз | POLITENESS |
| 3 | Мини-холодильник | GENEROSITY |
| 3 | Большое зеркало | FLATTERY |
| 3 | Витрина коллекции | STATUS |
| 4 | Караоке-система | AUDACITY |
| 4 | Игровая консоль | DOMINANCE |
| 4 | Дартс | RISK |
| 4 | Шахматный столик | CUNNING |

---

# 14. Furniture Store

Furniture Store является canonical purchase point Apartment Local Objects.

Катя работает в Furniture Store.

Store показывает предметы текущего Stage и более ранних Stages.

Для каждого предмета показывай:

```text
название
цена
Tag
Local Move text
ownership state
required City Stage
```

После покупки:

```text
object_id добавляется в owned Apartment Objects
Local Move становится частью Apartment Venue Source
предмет появляется в authored Apartment placement
```

---

# 15. Katya MAX reward — Interior Accent

Canonical reward Кати:

```text
Акцент интерьера
```

После MAX Кати игрок получает возможность назначить один купленный Apartment Object акцентным.

State:

```text
GameState.apartment_accent_object_id
```

## First selection

Первое назначение Accent:

```text
price = $0
```

Если reward получен до покупки первого Apartment Local Object, pending selection становится доступным после появления первого owned object.

## Accent effect

При выборе Local Move акцентного Apartment Object:

```text
known positive Tag:
score = +2

known negative Tag:
score = -1
```

Unknown Tag после reveal применяет обычный positive/negative исход и соответствующий score:

```text
positive = +2
negative = -1
```

Остальные Apartment Local Moves:

```text
positive = +1
negative = -1
```

---

# 16. Accent reassignment

Повторное изменение Accent выполняется через Катю / Furniture Store.

Цена зависит от текущего Story Stage (не City Stage):

```text
Story Stage 2: $300
Story Stage 3: $600
Story Stage 4+: $1000
```

После оплаты:

```text
player selects one owned Apartment Object
apartment_accent_object_id = selected object_id
```

UI Furniture Store показывает текущий Accent:

```text
Акцент интерьера: <Object Name>
```

Для выбранного Object:

```text
Положительный локальный ход: +2
```

---

# 17. Apartment Preparation integration

Apartment preparation и Apartment Local Objects являются двумя отдельными axes одного Venue.

Canonical state сохраняет существующую механику:

```text
prepared = true / false
```

Apartment Date после завершения:

```text
prepared = false
```

Manual preparation:

```text
$0
30 minutes
prepared = true
```

Reward Леры:

```text
Apartment автоматически prepared перед Date
$0
0 minutes
```

Purchased Local Objects и Accent работают независимо от preparation state.

Current unprepared-Date penalty продолжает применяться через существующий canonical Apartment rule.

---

# 18. Venue availability by Stage

Production Venue availability:

```text
Stage 1:
apartment

Stage 2:
apartment
cafe
leisure_center

Stage 3:
apartment
cafe
leisure_center
restaurant

Stage 4+:
apartment
cafe
leisure_center
restaurant
```

Stage 1 Date flow использует Apartment как единственный Venue.

Stage 2 впервые показывает meaningful Venue selection.

Stage 3 добавляет Restaurant как последний основной manual DateVenue.

---

# 19. Venue prices

Current playable economy values:

```text
Apartment: $0
Café: $20
Leisure Center: $40
Restaurant: $60
```

Эти значения являются текущими production values для playable 2D.

Поздний `Economy & Pacing` block выполняет общий rebalance зарплат, Outfit, furniture, Venue и service costs одновременно.

---

# 20. Venue Selection UI

При выборе девушки экран Venue Selection показывает все доступные на текущем Stage Venue.

Каждая Venue card содержит:

```text
Venue name
price
Venue Source uses
available Local Tags
Characteristic locks
girl Venue Trait effect
Apartment owned-object count
Apartment Accent
Sonya Restaurant bonus
```

Tag presentation использует существующую canonical coloring knowledge system.

Пример Café:

```text
Café — $20
Локальный ход ×1

[УЧТИВОСТЬ]
[ПРЯМОТА]
[ХИТРОСТЬ]
[ЮМОР]
[ЗАБОТА]
[НАГЛОСТЬ]
```

Пример Restaurant:

```text
Restaurant — $60
Локальный ход ×1

[УЧТИВОСТЬ] требуется Внешность ур. 1
[ДОМИНИРОВАНИЕ] требуется Мышца ур. 3
[СТАТУС] требуется Капитал ур. 3
[СПОКОЙСТВИЕ] требуется Аура ур. 3
[ЛЕСТЬ] требуется Внешность ур. 3
[ЩЕДРОСТЬ] требуется Капитал ур. 1
[ЗАБОТА] требуется Аура ур. 1
[ПРЯМОТА] требуется Мышца ур. 1
```

Пример Apartment:

```text
Apartment — $0
Локальный ход ×1
Предметы: 5 / 12
Акцент интерьера: Плед

[ЗАБОТА] Плед
[ЮМОР] Телевизор
[СПОКОЙСТВИЕ] Проигрыватель
[ПРЯМОТА] Карточки «Без фильтров»
[УЧТИВОСТЬ] Чайный сервиз
```

Accent Object дополнительно показывает:

```text
Положительный локальный ход: +2
```

---

# 21. Girl Venue Trait presentation

Если выбранная девушка имеет Venue-based Trait и выбранный Venue соответствует Trait:

Venue card показывает:

```text
Особенность девушки: +1 к результату свидания здесь
```

Текущая canonical Venue Trait scoring logic сохраняется.

---

# 22. Local Source UI inside Date

Source label:

```text
ЛОКАЦИЯ
```

Public Venue группирует Moves по Object.

Пример Leisure Center:

```text
АВТОМАТ-ХВАТАЙКА

[ЗАБОТА] Автомат-хватайка: Попытаться достать игрушку, которая ей понравилась
[ХИТРОСТЬ] Автомат-хватайка: Изучить механизм и выбрать лучший момент для захвата

ГОНОЧНЫЙ АВТОМАТ

[РИСК] Гоночный автомат: Выбрать максимальную сложность и отключить помощь
[НАГЛОСТЬ] Гоночный автомат: Предложить маленькое желание победителю
```

Restaurant locked example:

```text
[ЛЕСТЬ] Живая музыка: Попросить музыканта посвятить ей композицию · требуется Внешность ур. 3
```

Apartment uses compact one-line-per-object list because each object owns one Move:

```text
[ЗАБОТА] Плед: Предложить ей плед и устроиться поудобнее
[ЮМОР] Телевизор: Включить что-нибудь настолько нелепое, что это уже интересно
```

Accent object показывает рядом:

```text
+2 при положительном результате
```

---

# 23. Source-state logic

Venue Source state использует текущую canonical Date source logic.

Availability classification учитывает:

```text
Move enabled
Move unused
Characteristic requirement satisfied
known Tag preference
Venue Source uses remaining
```

Для Restaurant наличие locked Moves входит в preview, чтобы игрок видел связь с Characteristics и Outfit stat bonus.

После использования Venue Source:

```text
default Venue:
source used

Restaurant + Sonya:
source remains available while one use remains
```

После второго использования Restaurant + Sonya:

```text
source used
```

---

# 24. Sonya integration

Reward Сони:

```text
Restaurant Venue Source can be used 2 times per Date
```

Venue Selection card:

```text
Локальный ход ×2 — постоянный столик Сони
```

Inside Date:

```text
uses_remaining = 2
```

После первого Restaurant Local Move:

```text
uses_remaining = 1
```

Local Move, сыгранный первым, остаётся consumed.

Остальные доступные Restaurant Local Moves могут использоваться вторым Venue Source use.

---

# 25. Public Situation integration

Обновить `allowed_venue_ids` следующих baseline Situations:

```text
stranger_flirts
small_rule
staff_conflict
mistaken_married
lost_wallet
```

Canonical allowed venues:

```text
cafe
leisure_center
restaurant
```

Apartment остаётся private Venue и отсутствует в этом public subset.

Остальные baseline Situation filters сохраняют текущую authored semantics.

---

# 26. Future 3D activity integration contract

Leisure Center Object IDs являются стабильными gameplay anchors:

```text
leisure_center__claw_machine
leisure_center__racing_arcade
leisure_center__air_hockey
leisure_center__prize_counter
```

Future 3D presentation может запускать short activity для конкретного Local Move.

Activity completion возвращает current Date flow в тот же canonical outcome:

```text
move_id
tag_id
positive / negative
score
```

Dating Core продолжает использовать тот же DateMove.

---

# 27. Developer Room / Date Content Lab

Добавить Venue playground.

Controls:

```text
City Stage
Girl
Venue
owned Apartment Objects
Apartment Accent
Katya reward
Sonya reward
player Characteristics
Outfit stat bonuses
```

Preview:

```text
Venue availability
Venue price
Local Source uses
Local Objects
Local Move IDs
Tags
Characteristic requirements
effective Characteristics
known positive / unknown / known negative presentation
Accent +2
Sonya ×2
```

Quick actions:

```text
unlock all Stage 2 Apartment Objects
unlock all Stage 3 Apartment Objects
unlock all Stage 4 Apartment Objects
own all 12 Apartment Objects
clear Apartment Objects
set Accent
clear Accent
toggle Katya reward
toggle Sonya reward
```

Launch selected Venue through production Date Engine.

---

# 28. Validators

Add canonical validation for Venues & Local Objects.

## Venue catalog

```text
exactly 4 main DateVenues:
apartment
cafe
leisure_center
restaurant
```

## Café

```text
3 Local Objects
6 Local Moves
6 unique Tags
0 Characteristic requirements
```

Exact Tags:

```text
politeness
directness
cunning
humor
care
audacity
```

## Leisure Center

```text
4 Local Objects
8 Local Moves
8 unique Tags
0 Characteristic requirements
```

Exact Tags:

```text
care
cunning
risk
audacity
dominance
humor
generosity
status
```

## Restaurant

```text
4 Local Objects
8 Local Moves
8 unique Tags
8 Characteristic requirements
4 at level 1
4 at level 3
2 Moves per Characteristic
```

Exact Tags:

```text
politeness
dominance
status
composure
flattery
generosity
care
directness
```

## Apartment

```text
12 purchasable Local Objects
12 Local Moves
12 unique Tags
all 12 canonical Tags represented exactly once
0 Characteristic requirements
```

Stage availability:

```text
4 objects at Stage 2
4 additional objects at Stage 3
4 additional objects at Stage 4
```

---

# 29. Regression tests

Add/update compact automated checks.

1. Stage 1 exposes only Apartment.
2. Stage 1 Apartment has 0 available Local Moves before furniture progression.
3. Stage 2 exposes Apartment, Café, Leisure Center.
4. Stage 3 exposes all four canonical Venue.
5. Café has exactly 3 objects / 6 Moves / 6 unique Tags.
6. Leisure Center has exactly 4 objects / 8 Moves / 8 unique Tags.
7. Restaurant has exactly 4 objects / 8 Moves / 8 unique Tags.
8. All Restaurant Moves have Characteristic requirements.
9. Restaurant has exactly one level-1 and one level-3 Move for each of the four Characteristics.
10. Restaurant locked state changes from Outfit effective-stat bonus through the current effective Characteristic calculation.
11. Apartment has exactly 12 objects and all 12 Tags exactly once.
12. Apartment Stage 2 exposes first 4 purchasable objects.
13. Apartment Stage 3 exposes first 8.
14. Apartment Stage 4 exposes all 12.
15. Buying an Apartment Object immediately adds its Local Move to Apartment Venue Source.
16. First Katya Accent selection costs $0.
17. Accent positive Local Move scores +2.
18. Accent negative Local Move scores -1.
19. Accent reassignment costs `$300 / $600 / $1000` at Stage `2 / 3 / 4+`.
20. Default Venue Source allows one Local Move per Date.
21. Sonya Restaurant allows exactly two different Local Move uses.
22. Public baseline Situations include Leisure Center in their eligibility.
23. Venue Selection preview uses current Girl knowledge and effective Characteristic values.
24. Local Source option text follows `[ТЕГ] Объект: действие`.

---

# 30. Documentation synchronization

Update:

```text
docs/PROGRESSION_STAGES.md
docs/DATE_SYSTEM_LAB.md
```

Create or update a canonical Venue content document:

```text
docs/VENUES_AND_LOCAL_OBJECTS.md
```

It contains:

```text
4 Venue
Stage availability
Venue prices
all public Local Objects
all public Local Moves
Restaurant Characteristic requirements
12 Apartment Objects
Apartment prices
Katya Accent
Sonya Restaurant ×2
UI contracts
future 3D activity integration
```

Current canonical progression:

```text
Stage 1:
Apartment / no Local coverage

Stage 2:
Apartment + Café + Leisure
Local Source
4 Apartment Tags

Stage 3:
+ Restaurant
8 Apartment Tags
Restaurant Characteristic synergy

Stage 4:
12 Apartment Tags
mastery
```

---

# 31. Canonical cleanup state

После implementation authored project использует один current Venue model:

```text
apartment
cafe
leisure_center
restaurant
```

Current Local Object catalog соответствует таблицам этого файла.

Katya reward в current reward catalog:

```text
Interior Accent
```

Apartment catalog содержит 12 однотеговых объектов.

Public Venue catalog содержит exact `3 / 4 / 4` object structure.

All Venue UI и Date Source UI читают canonical Local Object / Local Move data.

---

# 32. Критерий готовности (playable)

Блок готов, когда:

- production содержит четыре canonical Venue;
- Stage availability соответствует `1 → 3 → 4 → 4`;
- Stage 1 Apartment имеет 0 Local Moves;
- Café полностью реализовано как `3 objects / 6 Tags`;
- Leisure Center полностью реализован как `4 objects / 8 Tags`;
- Restaurant полностью реализован как `4 objects / 8 Tags`;
- каждый Restaurant Move требует Characteristic;
- у каждой характеристики Restaurant имеет один Move `ур.1` и один Move `ур.3`;
- Outfit stat bonus влияет на Restaurant locked/unlocked state через current effective Characteristic;
- Apartment содержит 12 purchasable objects, по одному на каждый Tag;
- Apartment progression работает как `0 → 4 → 8 → 12`;
- все купленные Apartment Objects одновременно входят в Local Source;
- Katya MAX открывает Interior Accent;
- первое назначение Accent бесплатно;
- повторная смена Accent стоит `$300 / $600 / $1000` по Stage;
- Accent positive score = `+2`;
- Restaurant + Sonya имеет Venue Source ×2;
- Venue Selection показывает Local coverage и requirements до начала Date;
- Local Source внутри Date использует формат `[ТЕГ] Объект: действие`;
- public baseline Situations поддерживают Leisure Center;
- Developer Room позволяет проверить весь block через production services;
- validators проходят;
- regression suite проходит;
- `PROGRESSION_STAGES`, `DATE_SYSTEM_LAB` и `VENUES_AND_LOCAL_OBJECTS` синхронизированы.

После завершения сделай отдельный commit:

```text
Venues and Local Objects: complete manual date venue block
```

и push текущей рабочей ветки.
