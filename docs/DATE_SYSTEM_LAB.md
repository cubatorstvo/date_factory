# DATE SYSTEM LAB

Каноническая спецификация текущей `main`. Код должен совпадать с этим документом.

High-level Stage 1–4 systems — [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md). Roster, Rating gates и Story vs City Stage — [`STORY_STAGE_PROGRESSION.md`](STORY_STAGE_PROGRESSION.md):

```text
Stage 1 = Apartment / fundamentals
Stage 2 = Apartment + Café + Leisure / Local + basic Outfit
Stage 3 = + Restaurant / Outfit Moves / synergy
Stage 4 = mastery / 12-Tag Apartment
```

## Назначение

Date System Lab — канон ядра свиданий и комната разработчика.

Текущая `main` разделяет два независимых entry point:

- `GameSimulator` — обычная 2D-версия прохождения поверх Game Core;
- `DateSystemLab` — комната разработчика, редактор контента и тестовая среда Date System.

`GameSimulator` не расширяет `DateSystemLab`. Он только отображает `GameState` и запускает `GameAction` через `ActionService`.

Design-content хранится в `res://`. Runtime-прогресс — в `user://`.

## Ход — DateMove

Одна сущность `DateMove` (Ход). Виды: `BASE` (Базовый ход), `CHARACTERISTIC` (ход характеристики), `OUTFIT` (ход одежды), `LOCAL` (локальный ход).

### BASE

- Есть у героя с начала игры.
- Каждая `DateSituation` владеет ровно шестью собственными BASE Moves через `base_move_ids`.
- BASE использует ту же fixed-presentation модель, что Characteristic / Outfit / Local: `fixed_tag_id`, `fixed_option_text`, `fixed_positive_result_text`, `fixed_negative_result_text`.
- Шесть BASE одной Situation имеют шесть различных Tags.
- Канонический ID: `<situation_id>__<action_id>`. Новый Situation — локальный authored-content unit: Situation + 6 BASE, без правки существующих ходов.
- Первый baseline pool: 30 Situations / 180 BASE, шесть различных Tags на Situation, 15 BASE на каждый из 12 Tags.
- Применимость BASE определяется ownership: ход принадлежит ровно одной Situation.
- Одна Situation используется максимум один раз за текущее свидание, поэтому конкретный BASE встречается максимум в одном эпизоде Date.

### Characteristic Move (`CHARACTERISTIC`)

- 12 ходов, по одному на каждый Tag. Постоянный Tag и постоянный player-facing текст через `fixed_*`.
- Открываются по `EffectiveStat` на уровнях `1 / 3 / 5`.
- Доступны в любом эпизоде (OPENING / CORE / CLOSING). Situation не бросает их вероятность.
- Источник «Характеристика» расходуется один раз за свидание после выбора хода.

### Outfit Move (`OUTFIT`)

- Постоянный Tag и текст. Есть только у тематической одежды.
- Outfit Moves / Outfit Source появляются на Stage 3. До этого Outfit даёт только `+1` к одной характеристике.
- Источник «Одежда» показывается, если экипированный Outfit имеет Outfit Move.
- Расходуется один раз за свидание.

### Local Move (`LOCAL`)

- Ходы объектов выбранного Date Venue. Недоступные ходы видны с требованием.
- Venue / Local Source появляется на Stage 2. Apartment на Stage 1 имеет 0 Local Moves.
- После одного выбранного Local Move весь источник «Место свидания» израсходован до конца свидания. Обычный positive result = `+1`; после MAX Кати акцентный Apartment Local Move даёт positive `+2`. Negative result всегда `-1`.

### Формирование вариантов эпизода

Каждый эпизод предлагает три Base Moves и три дополнительных источника:

```text
DateSituation
    ↓
6 собственных контекстных BASE Moves
    ↓
RNG показывает 3 из 6
    +
[ХАРАКТЕРИСТИКА] [ОДЕЖДА] [МЕСТО СВИДАНИЯ]
    ↓
игрок выбирает один Move
```

RNG выбирает Situation, перемешивает её six-move set и показывает первые три. Оставшиеся три хранятся как `current_reroll_base_move_ids`. RNG не определяет доступность уже открытого Characteristic Move или Outfit Move.

Число выбранных BASE: `DateRules.base_moves_per_episode` (seed = 3). Reward Вики `vika_base_reroll` за `$25` один раз за свидание заменяет shown-тройку на точные оставшиеся три той же Situation. Characteristic / Outfit / Venue Source и Combo не меняются.

Источник расходуется только после фактического выбора хода. Открытие списка и «Назад» источник не тратят. Использованная кнопка остаётся видимой, disabled, tooltip `Уже использовано на этом свидании.`

## Формула эпизода

```text
СИТУАЦИЯ → 3 из 6 BASE + источники Характеристика / Одежда / Место свидания → ВЫБОР ОДНОГО ХОДА
→ ТЕГ
→ ПРЕДПОЧТЕНИЕ ДЕВУШКИ → +1 / -1
```

Тег варианта показывается до выбора. BASE, Characteristic, Outfit и LOCAL читают Tag из `DateMove.fixed_tag_id`.

Opening, Core и Closing используют одну source-модель. `+1` / `-1` по предпочтению.

## Dating Core

Одно свидание — пять решений: `OPENING 1 → CORE 3 → CLOSING 1 → RESULT`. Каждый ход несёт один из 12 активных Tags. Для конкретной девушки Tag либо положительный (`+1`), либо отрицательный (`-1`). Authored-набор предпочтений — только `positive_tag_ids`; остальные активные Tags автоматически отрицательные.

Знание Tags принадлежит девушке и живёт между свиданиями: UNKNOWN, POSITIVE, NEGATIVE. Цветовая подсветка — единственный быстрый player-facing индикатор. `GirlProfile.initial_known_tag_count` задаёт, сколько случайных активных Tags раскрываются при первом знакомстве и сразу пишутся в `GirlState.revealed_*`: обычные / filler — `2`, сюжетные — `0`. Конкретный набор Tags в каждом прохождении свой; знак берётся из `positive_tag_ids`. Награда Евы добавляет глобальный `+1` к этому числу и ретроактивно раскрывает один неизвестный Tag уже знакомым незавершённым девушкам.

Сложность девушки — число положительных Tags из 12: STARTER 6, EARLY 5, MID 4, LATE 3, ELITE 2.

Отношения всегда стартуют с `0` и только растут. Максимум берётся из Game Core `GirlDefinition`: ordinary / filler `10`; Actress / Mine Boss / Magazine Editor `10`; Scientist / President `15`. `GirlProfile` не хранит отдельную копию диапазона. `StageCatalog` и Story requirements используют тот же максимум. Первое достижение MAX завершает линию и даёт `Rating +1` один раз. У filler-девушки на том же переходе активируется её персональная постоянная награда.

Формула итога:

```text
Raw Date Score = сумма пяти эпизодов + Combo + Girl Trait + Apartment Preparation
Relationship Gain = max(Raw Date Score, 0)
Relationship After = min(Relationship Before + Relationship Gain, Relationship Max)
```

Combo: три последовательных положительных хода с разными Tags дают `+1`, максимум один раз за свидание. Отрицательный ход сбрасывает цепочку; повтор Tag перестраивает уникальный успешный хвост.

Каждая из 17 девушек имеет ровно один Trait, известный до первого свидания.

Trait характеристики (`loves_strong` / Мышца, `values_appearance` / Внешность, `loves_wealthy` / Капитал, `senses_aura` / Аура): первый за свидание положительный ход с формальным `unlock_requirement` этой характеристики даёт `+1`. Строка эпизода: `Особенность «…»: +1`. В breakdown это единый `Girl Trait +1`.

Trait места (`homebody` / квартира, `loves_cafe` / кафе, `loves_restaurants` / ресторан): `+1` в совпадающем месте, иначе `+0`. Строка Trait в результате показывается всегда.

Распределение Trait: Алина и Соня — Домоседка; Марина, Ника, Редактор журнала — Чувствует ауру; Вика и Актриса — Ценит внешность; Даша и Кира — Любит сильных; Катя и Учёная — Любит кафе; Лера, Ева и Начальница шахты — Любит рестораны; Оля, Рита и Президент — Любит обеспеченных.

Активные DateVenues по Stage: квартира (Stage 1); квартира + кафе + Leisure Center (Stage 2); плюс ресторан (Stage 3). Подготовленная квартира `0`, неподготовленная `-1`. Наряд хранится в сессии как часть подготовки; универсального `Outfit.score_bonus` нет. High-level unlock и обучающая роль — [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).

Характеристики героя `0..5`. `raise_stakes` требует `Капитал >= 5`. Trait характеристики читает формальное requirement хода.

Итоговый экран: пять строк эпизодов, Combo, особенность девушки, штраф квартиры если применён, `Итог свидания: N` (сырой итог), `Прогресс отношений: +N` (Gain), `Отношения: X / MAX`.

## Слои

1. Content Layer — typed Resources.
2. Runtime Progress Layer — канонический `GameState` прохождения (`SaveManager`, JSON `user://saves/game.json`) плюс лабораторный `DateProgressStore` (отношения, известные предпочтения, Combo, число свиданий, тестовая прокачка, квартира, replay snapshot).
3. Date Engine — DateSession, RNG, эпизоды, BASE/CHARACTERISTIC, mappings, Tags, Trait, Combo, apartment preparation, итог отношений.
4. Text Date Runner — текстовый 2D DateSession.
5. Game Simulator — 2D presentation прохождения поверх Game Core.
6. Developer Room — редактор Content Layer и запуск runner.

## GameState

Autoload `GameState` — текущее прохождение. Секции: `flow`, `story`, `player`, `progression`, `world`, `girls`, `dating`, `rivals`, `automation`, `daily_activity`. Каждая секция — отдельный typed-класс с `to_dict()` / `from_dict()`.

`GameState` хранит только изменяемое состояние конкретного прохождения. Статические определения игрового контента — параметры девушек, предметов, локаций, Stage, цены, базовые характеристики и прочие definitions — хранятся отдельно от `GameState`. `GameState` хранит только ссылки/ID и изменяемый прогресс относительно этих definitions.

Сейчас используются:

```text
flow.game_time_minutes = 0
story.stage = 1
story.finale_reached = false
player.money = 0
player.rating = 0
player.muscle = 0
player.appearance = 0
player.capital = 0
player.aura = 0
daily_activity.usages = {}
progression.purchased_ids = []
progression.unlocked_filler_reward_ids = []
progression.marina_free_outfit_pending = false
progression.current_outfit_id = casual
progression.apartment.prepared = true
progression.apartment.owned_local_object_ids = []
progression.apartment.accent_object_id = ""
world.current_location_id = city_center
world.unlocked_location_ids = [city_center, apartment, cafe]
girls.girls_by_id = {}
dating.active_date = {}
rivals.rivals_by_id = {}
automation.unlocked = false
automation.initial_clones_granted = false
automation.total_clones = 0
automation.work_allocation_percent = 50
automation.work_income_fraction = 0
automation.dating_progress_fraction = 0
automation.current_expansion_scope = city
automation.expansion_progress = 0
automation.purchased_upgrade_ids = []
```

`game_time_minutes = 0` — Day 1, 00:00. День, час и минута не хранятся: их даёт `TimeService`. Кампания: `stage` — текущая/последняя достигнутая игровая стадия 1–6, `finale_reached` — завершение основной последовательности после Stage 6. Мир: `current_location_id` — семантическое место игрока, `unlocked_location_ids` — открытые `LocationDefinition`. Definitions локаций живут в `LocationCatalog`; `GameState` хранит только ID. Девушки: `GirlState` создаётся при первом обращении (`discovered = false`, `has_contact = false`, `relationship = 0`, пустые revealed tags, `completed_dates = 0`, пустой `last_date_situation_ids`); definitions живут в `GirlCatalog`. `player.rating` — глобальный Rating прохождения: ручное завершение authored-девушки даёт +1, dating production фабрики начисляет те же целые единицы через `RatingService`. `player.muscle` / `appearance` / `capital` / `aura` — постоянные характеристики прохождения; definitions и цены upgrades живут отдельно. `player.last_work_day_index` — календарный день последней работы (`game_time_minutes / 1440`, `-1` если ещё не работал). `progression.current_outfit_id` — экипированный Outfit; канонический outfit-контент — Date System `Outfit`. `progression.apartment` — `prepared`, `owned_local_object_ids`, `accent_object_id` (квартира не хранит level). `dating.active_date` — текущее свидание прохождения (`girl_id`, выбранный `venue_id` свидания, выбранный `outfit_id`, `started_at_game_time`) или `{}`. `GirlDefinition.location_id` не является местом свидания. Соперники: `RivalState` создаётся при первом обращении (`discovered = false`, `defeated = false`); definitions живут в `RivalCatalog`.

`automation` — runtime-прогресс фабрики клонов. `rivals` сериализует `rivals_by_id`. Поля читаются через `data.get(key, default)`. Отсутствующие поля `world` восстанавливаются стартовым состоянием нового прохождения. Отсутствующие `girls.girls_by_id` — `{}`. Отсутствующий `player.rating` — `0`. Отсутствующие характеристики игрока — `0`. Отсутствующий `dating.active_date` — `{}`. Отсутствующий `outfit_id` у активного свидания — стартовый `casual`. Отсутствующий `rivals.rivals_by_id` — `{}`. Отсутствующий `current_outfit_id` восстанавливается стартовым `casual`. Отсутствующий `last_work_day_index` — `-1`. Отсутствующий `apartment` — `prepared = true`, пустой `owned_local_object_ids`, пустой `accent_object_id`. Отсутствующий или пустой `automation` — New Game defaults.

Autoload `SaveManager` — жизненный цикл:

```text
new_game()
save_game()
load_game()
has_save() -> bool
delete_save()
```

Формат файла `user://saves/game.json`:

```text
{
  "save_version": 15,
  "game_state": { "flow": { "game_time_minutes": 0 }, "story": { "stage": 1, "finale_reached": false }, "player": { "money": 0, "rating": 0, "muscle": 0, "appearance": 0, "capital": 0, "aura": 0, "last_work_day_index": -1 }, "progression": { "purchased_ids": [], "current_outfit_id": "casual", "apartment": { "owned_local_object_ids": [], "prepared": true, "accent_object_id": "" } }, "world": { "current_location_id": "city_center", "unlocked_location_ids": ["city_center", "apartment", "cafe"], "city_stage": 1 }, "girls": { "girls_by_id": {} }, "dating": { "active_date": {} }, "rivals": { "rivals_by_id": {} }, "automation": { "unlocked": false, "initial_clones_granted": false, "total_clones": 0, "work_allocation_percent": 50, "work_income_fraction": 0, "dating_progress_fraction": 0, "current_expansion_scope": "city", "expansion_progress": 0, "purchased_upgrade_ids": [] } } }
}
```

`new_game()` создаёт новые экземпляры всех секций: `game_time_minutes = 0`, stage 1, `finale_reached = false`, money 0, rating 0, характеристики 0, `purchased_ids = []`, стартовый outfit `casual` как `current_outfit_id`, квартира `prepared = true` без owned objects, `current_location_id = city_center`, `city_stage = 1`, стартовые unlock'и, пустой `girls_by_id`, пустой `dating.active_date`, пустой `rivals_by_id`, Automation закрыта (`unlocked = false`, `total_clones = 0`, `work_allocation_percent = 50`). После `apply_new_game()` вызываются `TimeService.on_playthrough_reset()` и `StageService.reconcile_stage_entry_state()` — Stage 1 становится активным через те же `on_enter_effects`. `load_game()` собирает чистый `GameState` через `from_dict()`, затем снова `TimeService.on_playthrough_reset()` и `StageService.reconcile_stage_entry_state()` для unlock'ов уже достигнутых Stage. Save на Stage 5 или 6 без Automation-прогресса получает unlock и стартовые 10 клонов через существующий reconcile `on_enter_effects` Stage 5. Сохранения `save_version = 1` с `flow.day = N` мигрируют в `game_time_minutes = (N - 1) * 1440`. Сохранения без `story.finale_reached` получают `false`. Сохранения без `progression.purchased_ids` получают `[]`. Сохранения без world-полей получают стартовую локацию и стартовый набор unlock'ов. Сохранения без `girls.girls_by_id` получают `{}`; `GirlState` создаётся defaults при первом обращении. Сохранения без `player.rating` получают `0`. Сохранения без характеристик получают `0`. Сохранения без `dating.active_date` получают `{}`. Сохранения без `outfit_id` у активного свидания получают стартовый `casual`. Сохранения без revealed tags / `completed_dates` у `GirlState` получают пустые списки и `0`. Сохранения `save_version` 14 мигрируют в 15: `last_work_day_index = -1`, `relationship = max(0, relationship)`, outfit chain из ранее купленных, `secondary_revealed` удаляется. Текущий формат — `save_version = 15`. Сохранения без `rivals.rivals_by_id` получают `{}`; `RivalState` создаётся defaults при первом обращении. Сохранения без equipment получают стартовый `casual`. Сохранения без `apartment` получают `prepared = true`, пустой `owned_local_object_ids` и пустой `accent_object_id`. Сохранения `save_version` 12 без `apartment.prepared` получают `true`. Сохранения `save_version` 10 без полей Automation получают New Game defaults фабрики. Сохранения `save_version` 11 с `completed_auto_dates` мигрируют в общий Rating и экспансию первого города фабрики: `player.rating += completed_auto_dates`, `dating_progress_fraction` остаётся дробным накоплением следующей единицы Rating, `current_expansion_scope = city`, `expansion_progress = min(completed_auto_dates + dating_progress_fraction, 100)`, после чего `completed_auto_dates` удаляется. Текущий формат — `save_version = 14`. Сохранения `save_version` 13 без `world.city_stage` получают City Stage из Story Stage (1 → 1, 2–3 → 2, 4–6 → 3); `RivalState.last_challenge_completed_at` без значения считается 0 (вызов доступен). Системы и UI читают время через `TimeService`, кампанию через `StageService`, деньги через `EconomyService`, фабрику через `AutomationService`, характеристики через `CharacteristicService`, одежду через `EquipmentService`, квартиру через `ApartmentService`, Rating через `RatingService`, место через `WorldService`, девушек через `GirlsService`, соперников через `RivalsService`, соревнования через `CompetitionService`, свидания через `DatingService`. Игровые действия изменяют money только через `EconomyService` и время только через `TimeService`; последовательность выполнения остаётся у `ActionService`. Переход между локациями не является `GameAction` и не двигает время. Знакомство с девушкой — `GameAction` и занимает 30 минут. Встреча соперника — `GameAction` с нулевым временем. Соревнование — `GameAction`; длительность берётся из `CompetitionDefinition.time_cost_minutes` и проводится через `TimeService`. Начало свидания — `GameAction` с нулевой стоимостью и нулевым временем; длительность свидания проводится после его завершения. Presentation-слой прохождения — `GameSimulator`.

`DateSession.stage` не является `StoryState.stage`. `DateProgressStore` остаётся прогрессом лаборатории свиданий. `GameState.girls` хранит discovery/contact/relationship и знание тегов прохождения. Доступность свидания считает `DailyActivityService` key `date:<girl_id>`. Date Engine в лаборатории читает лабораторный `GirlProgress`; в прохождении канонические `relationship` и revealed tags читаются и пишутся через `GirlsService`, а Date System получает `girl_id` от `DatingService`. Физический мир (`LocationDefinition`) не подменяет `DateVenue`. `GirlDefinition` не подменяет `GirlProfile`.

## Time / Game Flow

Единые игровые часы для текущей 2D-текстовой оболочки, будущих Game Actions, 3D free roam, incremental и cooldown'ов. Источник истины — абсолютное игровое время в минутах.

```text
1 игровой день = 1440 игровых минут
24 часа, 60 минут в часе

day = floor(game_time_minutes / 1440) + 1
minute_of_day = game_time_minutes % 1440
hour = floor(minute_of_day / 60)
minute = minute_of_day % 60
```

`FlowState` хранит только `game_time_minutes`. `to_dict()` / `from_dict()` сериализуют это поле.

Autoload `TimeService` — единственная точка продвижения времени:

```text
advance_time(delta_minutes: int)
```

Любой положительный промежуток обрабатывается одним вызовом. После успешного продвижения публикуется `time_advanced(delta_minutes, previous_game_time, current_game_time)`. `AutomationService` считает производство фабрики сразу за весь `delta_minutes`. Тот же интервал учитывается при ручной работе, обычном свидании, dev advance time и будущих real-time / offline progression.

Игровые действия несут `GameAction.time_cost_minutes`. После успеха `ActionService` вызывает `TimeService.advance_time(time_cost_minutes)`. Покупка может стоить `0` и не двигает часы.

`TimeService` API для cooldown'ов на абсолютном времени:

```text
get_game_time_minutes() -> int
get_day() -> int
get_hour() -> int
get_minute() -> int
days_to_minutes(days: int) -> int
hours_to_minutes(hours: int) -> int
minutes_until_next_morning(game_time_minutes: int) -> int
```

`minutes_until_next_morning` считает минуты до ближайших будущих 08:00 от переданного `game_time_minutes`. Если текущая минута дня меньше 08:00 — до 08:00 этого дня; если сейчас 08:00 или позже — до 08:00 следующего дня. Примеры: 03:20 → 280; 07:59 → 1; 08:00 → 1440; 23:30 → 510. Игровое действие и будущая кровать в 3D берут этот интервал и проводят его через `ActionService` → `TimeService.advance_time`.

Календарный `day_index` для Daily Activity Gate: `floor(game_time_minutes / 1440)`. Он совпадает с `TimeService.get_calendar_day_index()` и не равен player-facing `get_day()` (`floor / 1440 + 1`).

Real-time progression — управляемый режим того же часов:

```text
real_time_progression_enabled
game_minutes_per_real_second
```

Накопитель дробной части переводит реальное время в целые игровые минуты и вызывает тот же `advance_time()`. Для текущей 2D-игры `real_time_progression_enabled = false`: время двигают действия. Будущий 3D free roam включает режим (`1` реальная секунда = `1` игровая минута при стартовом коэффициенте `1.0`); фиксированные действия по-прежнему идут через `advance_time(action.time_cost_minutes)`.

## Daily Activity Gate

Autoload `DailyActivityService` — единственная production-точка проверки и регистрации дневных использований значимых повторяемых progression-активностей. Календарный день: `TimeService.get_calendar_day_index()` = `floor(game_time_minutes / 1440)`.

`GameState.daily_activity` хранит по каждому activity key:

```text
last_used_day_index
usage_count_on_that_day
```

Если `last_used_day_index != current_day_index`, `usage_count_today = 0`. Новый календарный день возвращает дневные возможности без отдельного reset.

Канонические keys и базовые limits:

```text
work                    = 1
characteristic_training = 1
date:<girl_id>          = 1
rival:<rival_id>        = 1
story_event:<event_id>  = 1
```

Limit применяется к успешному запуску activity. Просмотр UI и подготовка слот не тратят. Player-facing состояние показывается рядом с действием.

Повторяемых story events в текущем Game Core ещё нет: сервис принимает `story_event:<event_id>` как зарезервированный namespace. Новую event-систему не создавать.

## Game Actions

Единый механизм игровых действий для текущей 2D-оболочки, будущего 3D-мира, UI, сюжета, работы, покупок, знакомств, свиданий, соперников и incremental. Presentation не меняет `GameState` напрямую: любое игровое действие описывается как `GameAction` и выполняется через autoload `ActionService`. Денежный pipeline действия идёт через `EconomyService`.

```text
Presentation / UI / 3D
        ↓
    GameAction
        ↓
   ActionService
        ↓
 Requirements
        ↓
 EconomyService
        ↓
     Effects
        ↓
   TimeService
        ↓
    GameState
```

`GameAction` — статическое описание действия, не часть `GameState`. Definitions живут в `res://game/actions/` (`GameActionCatalog` и typed Resources). `GameState` хранит только изменяемое состояние прохождения.

```text
id: StringName
time_cost_minutes: int = 0
money_cost: int = 0
requirements: Array[ActionRequirement] = []
effects: Array[ActionEffect] = []
```

`id` однозначно идентифицирует действие (`work_mine`, `meet_girl`, `invite_to_date`, `buy_upgrade`, `challenge_rival`, `start_date`, `travel`, `prepare_apartment`).

`ActionRequirement`: `is_met() -> bool`, `get_failure_reason() -> String`. Проверяет текущее прохождение. `MoneyRequirement(required_money)`: `EconomyService.can_afford(required_money)`, отказ `"Недостаточно денег"`. `NotPurchasedRequirement(purchase_id)`: `purchase_id` отсутствует в `GameState.progression.purchased_ids`, отказ `"Уже куплено"`. `OutfitNotOwnedRequirement(outfit_id)`: `EquipmentService.owns_outfit(outfit_id) == false`, отказ `"Эта одежда уже куплена"`. `OutfitOwnedRequirement(outfit_id)`: игрок владеет нарядом, отказ `"Эта одежда ещё не куплена"`. `LocationRequirement(required_location_id)`: `WorldService.get_current_location_id() == required_location_id`, отказ `"Действие недоступно в этой локации"`. `GirlMeetAvailableRequirement(girl_id)`: `GirlsService.can_meet_girl(girl_id)`, отказ — `GirlsService.get_meet_failure_reason`. `GirlNotMetRequirement(girl_id)`: девушка ещё не `discovered`, отказ `"Вы уже знакомы"`. `GirlLocationRequirement(girl_id)`: `GirlDefinition.location_id` совпадает с текущей локацией, отказ `"Девушка находится в другой локации"`. `GirlDiscoveredRequirement(girl_id)`: `discovered`, отказ `"Вы ещё не знакомы"`. `GirlContactRequirement(girl_id)`: `has_contact`, отказ `"У вас нет контакта этой девушки"`. `RelationshipRequirement(girl_id, minimum_relationship)`: `relationship >= minimum`, отказ `"Недостаточный уровень отношений"`. `DateAvailableRequirement(girl_id)`: `DatingService.can_start_date(girl_id)`, отказ — первая причина `get_start_date_failure_reason`. `DateVenueAvailableRequirement(girl_id, date_venue_id)`: `DatingService.is_date_venue_available(girl_id, date_venue_id)`, отказ `"Это место сейчас недоступно"`. `RivalLocationRequirement(rival_id)`: `RivalDefinition.location_id` совпадает с текущей локацией, отказ `"Соперник находится в другой локации"`. `RivalNotDiscoveredRequirement(rival_id)`: соперник ещё не `discovered`, отказ `"Вы уже встретили этого соперника"`. `RivalDiscoveredRequirement(rival_id)`: `discovered`, отказ `"Вы ещё не встретили этого соперника"`. `RivalNotDefeatedRequirement(rival_id)`: `defeated == false`, отказ `"Этот соперник уже побеждён"`. `CharacteristicBelowMaxRequirement(characteristic_id)`: текущее значение < 5, отказ `"Характеристика уже максимальная"`. `CompetitionAvailableRequirement(competition_id)`: `CompetitionService.can_start_competition(competition_id)`, отказ — `CompetitionService.get_failure_reason`. `AutomationUpgradeNotPurchasedRequirement(upgrade_id)`: upgrade ещё не куплен, отказ `"Уже куплено"`. `FactoryExpansionRequirement(from_scope)`: текущий масштаб фабрики совпадает и coverage 100%, отказ `"Охват текущего масштаба ещё не 100%"` / `"Неверный масштаб фабрики"`.

`ActionEffect`: `apply() -> void`, `get_description() -> String`. `MoneyEffect(amount)`: при `amount > 0` вызывает `EconomyService.add_money(amount)`, при `amount < 0` — `EconomyService.spend_money(-amount)`. `PurchaseEffect(purchase_id)` добавляет ID в `ProgressionState.purchased_ids` не более одного раза. `CharacteristicEffect(characteristic_id, amount)` вызывает `CharacteristicService.add_value`. `OwnOutfitEffect(outfit_id)` вызывает `EquipmentService.add_owned_outfit` и экипирует купленный наряд. `ApartmentOwnObjectEffect(object_id)` добавляет object_id в `ApartmentState.owned_local_object_ids`. `UnlockLocationEffect(location_id)` вызывает `WorldService.unlock_location(location_id)`. `MeetGirlEffect(girl_id)` вызывает `GirlsService.discover_girl` и `give_contact`. `StartDateEffect(girl_id, date_venue_id, outfit_id)` вызывает `DatingService.start_date(girl_id, date_venue_id, outfit_id)`. `DiscoverRivalEffect(rival_id)` вызывает `RivalsService.discover_rival(rival_id)`. `CompetitionEffect(competition_id)` вызывает `CompetitionService.resolve_competition` и `complete_competition`. `AutomationUpgradeEffect(upgrade_id)` вызывает `AutomationService.apply_upgrade`. `FactoryExpansionEffect(target_scope)` вызывает `AutomationService.apply_expansion`.

`ActionResult` — ответ Presentation после попытки:

```text
success: bool
failure_reason: String
action_id: StringName
time_spent_minutes: int
money_spent: int
applied_effects: Array[String]
```

Успех: `success = true`, `failure_reason = ""`. Отказ: `success = false`, `failure_reason` первой непройденной проверки, `time_spent_minutes = 0`, `money_spent = 0`, `applied_effects = []`. `GameState` при отказе не меняется.

Autoload `ActionService`:

```text
can_execute(action: GameAction) -> bool
get_failure_reason(action: GameAction) -> String
execute(action: GameAction) -> ActionResult
signal action_executed(action_id: StringName, result: ActionResult)
```

Порядок `execute()`:

```text
1. Проверить каждый action.requirements
2. Проверить EconomyService.can_afford(action.money_cost)
3. Если проверка не прошла — вернуть failed ActionResult, GameState без изменений
4. Списать money_cost через EconomyService.spend_money(action.money_cost)
5. Применить все ActionEffect
6. TimeService.advance_time(action.time_cost_minutes)
7. Вернуть успешный ActionResult и испустить action_executed
```

`money_cost` — встроенная стандартная стоимость. Нехватка даёт `"Недостаточно денег"`. `time_cost_minutes = 0` не двигает часы и не публикует `time_advanced`. `action_executed` испускается только после успеха.

Игровые definitions каталога:

| id | time | money_cost | requirements | effects |
|---|---|---|---|---|
| `skip_to_08_00` | `minutes_until_next_morning` | 0 | — | — |

`skip_to_08_00` — обычное действие прохождения «Пропустить до 08:00» в разделе Квартира Simulator. Не test/dev. `time_cost_minutes` берётся из текущего `game_time_minutes` через `TimeService.minutes_until_next_morning`: до 08:00 текущего дня, если сейчас раньше 08:00; иначе до 08:00 следующего дня. Пропуск идёт через `GameAction` → `ActionService.execute` → `TimeService.advance_time`, чтобы Automation и остальные системы получили обычный `time_advanced` на фактически прошедшие минуты.

Тестовые definitions каталога:

| id | time | money_cost | requirements | effects |
|---|---|---|---|---|
| `test_wait` | 120 | 0 | — | — |
| `test_earn_money` | 60 | 0 | — | `MoneyEffect(+100)` |
| `test_spend_money` | 30 | 50 | — | — |
| `test_require_money` | 10 | 0 | `MoneyRequirement(100)` | — |

Лабораторные кнопки `+30 MIN` / `+120 MIN` / `+1 DAY` остаются часами через `TimeService.apply_action`. Именованные игровые действия идут только через `ActionService.execute`.

## Economy

Autoload `EconomyService` — единственная точка изменения `GameState.player.money`. Хранимое значение по-прежнему в `PlayerState`; сервисы и игровые эффекты не пишут money напрямую.

```text
get_money() -> int
can_afford(amount: int) -> bool
add_money(amount: int) -> void
spend_money(amount: int) -> bool
signal money_changed(previous_money: int, current_money: int, delta: int)
```

`get_money()` возвращает `GameState.player.money`. `can_afford(amount)` — `true`, если `amount <= 0` или `get_money() >= amount`. `add_money(amount)` начисляет деньги (`money += amount`) и публикует `money_changed`. `spend_money(amount)` при достаточном балансе списывает сумму, публикует `money_changed` и возвращает `true`; иначе деньги не меняются и результат `false`. `delta` — фактическое изменение (`current_money - previous_money`). Деньги рабочих клонов приходят через тот же `add_money`: фабрика участвует в общей экономике, параллельно ручной работе.

## Work

`WorkDefinition` — статическое описание работы, не часть `GameState`:

```text
id: StringName
display_name: String
income: int
time_cost_minutes: int
```

`WorkService.create_work_action(work)` собирает `GameAction`: `id` и `time_cost_minutes` из definition, `money_cost = 0`, эффект `MoneyEffect(+income)`.

Seed: `work_basic` — «Работать», 60 минут. Ставка из `WorkService.get_current_hourly_pay()`: 100 до Story Stage 3, 200 после MAX Начальницы шахты. Tiers описаны `WorkTierDefinition` (`min_story_stage`, `income`, `time_cost_minutes`). GameSimulator: `Работать — 1 ч — +100` / `+200`.

Работа идёт через `DailyActivityService` с `activity_key = work`. Базовый daily limit = 1. После MAX Оли `olya_overtime` эффективный limit = 2.

Первая смена без checkbox: usage 0→1, выплата 100%, 1 смена; затем доступно «Выйти на подработку». Дополнительная смена: usage 1→2, выплата 50%, 1 смена. Первая смена с checkbox: usage 0→2, выплата 150%, 2 смены. Оба UI-пути дают `usage_count = 2` за календарный день. Player-facing после обычной смены: «Сегодня уже работали.» После Оли и одной смены — кнопка подработки.

## Purchases

`ProgressionState.purchased_ids` — JSON-массив купленных ID. New Game: `[]`. Методы `has(id)` / `add(id)`; один ID максимум один раз.

`PurchaseDefinition` — статическое описание постоянной одноразовой покупки:

```text
id: StringName
display_name: String
description: String
price: int
```

Autoload `PurchaseService`:

```text
is_purchased(purchase_id: StringName) -> bool
can_purchase(definition: PurchaseDefinition) -> bool
create_purchase_action(definition: PurchaseDefinition) -> GameAction
signal purchase_completed(purchase_id: StringName)
```

`is_purchased` читает `GameState.progression.purchased_ids`. `can_purchase` — покупка ещё не куплена и `EconomyService.can_afford(price)`. `create_purchase_action` собирает `GameAction` с `id = buy_<purchase_id>`, `money_cost = price`, `time_cost_minutes = 0`, `NotPurchasedRequirement` и `PurchaseEffect`. После успешного `ActionService.execute` сервис испускает `purchase_completed`.

Seed: `basic_upgrade` — «Базовое улучшение», цена 300. Покупка только добавляет ID в `purchased_ids`.

Полный pipeline покупки:

```text
PurchaseDefinition
        ↓
PurchaseService.create_purchase_action()
        ↓
ActionService.execute()
        ↓
NotPurchasedRequirement
        ↓
EconomyService.can_afford()
        ↓
EconomyService.spend_money()
        ↓
PurchaseEffect
        ↓
ProgressionState.purchased_ids
```

`CharacteristicUpgradeDefinition` расширяет `PurchaseDefinition` полями `characteristic_id` и `amount`. `PurchaseService.create_purchase_action` для такого definition добавляет `CharacteristicEffect` рядом с `PurchaseEffect`. ID upgrade попадает в `purchased_ids`; повтор блокирует `NotPurchasedRequirement`.

## Automation / Incremental Core

Фабрика клонов — первый рабочий incremental-loop. Клоны работают параллельно обычным действиям игрока и используют тот же `TimeService`. Отдельного таймера Automation нет. Отдельных свободных клонов нет: всё количество распределяется одним процентом.

После MAX Учёной герой получает технологию клонирования, запускает Date Factory в **другом городе** и возвращается в родной authored-город. `WorldState` по-прежнему представляет физическое пространство родного города. Клоны не изменяют `GirlState` конкретных девушек родного города.

```text
общее количество клонов
        │
        ▼
work_allocation_percent
        │
        ├── X% → работа → Money
        └── 100-X% → свидания → Rating + Factory Expansion
```

`AutomationState` — единственное persistent runtime-состояние фабрики:

```text
unlocked: bool = false
initial_clones_granted: bool = false
total_clones: int = 0
work_allocation_percent: int = 50
work_income_fraction: float = 0
dating_progress_fraction: float = 0
current_expansion_scope: StringName = city
expansion_progress: float = 0
purchased_upgrade_ids: Array[StringName] = []
```

Dating allocation всегда вычисляется: `100 - work_allocation_percent`. Эффективные клоны дробные: `work_clones = total_clones * work_percent / 100`, `dating_clones = total_clones * dating_percent / 100`. Пример: 3 клона и 50% / 50% → 1.5 рабочего и 1.5 dating-клона.

Autoload `AutomationService` — единственная gameplay-точка количества клонов, распределения, скорости производства, обработки прошедшего времени, покупки automation upgrades, начисления Rating от фабрики и экспансии. Подписывается на `TimeService.time_advanced`. Пока `unlocked == false`, производство равно 0.

Базовые скорости без upgrades:

```text
100 денег на одного эффективного рабочего клона за игровой час
0.1 dating production на одного эффективного dating-клона за игровой час
```

`1.0 dating production = +1 Rating`. Целая часть денежного производства идёт через `EconomyService.add_money`. Дробная часть хранится в `work_income_fraction`. Dating-клоны не запускают `DateSession` / `DateEngine` / `GirlState`. Целые единицы dating production идут в `RatingService.add_rating`. Дробный прогресс следующей единицы Rating — `dating_progress_fraction`. Тот же dating output одновременно добавляется в `expansion_progress` текущего масштаба как непрерывное значение. `advance_time(60)` и `60 × advance_time(1)` при одинаковом исходном состоянии дают одинаковые Money, Rating и эквивалентные дробные остатки.

Три последовательных масштаба фабрики — город, в котором стоит фабрика, затем страна, затем мир:

```text
CITY    100 reach points
COUNTRY 1 000 reach points
WORLD   10 000 reach points
```

После открытия Automation: `scope = CITY`, `progress = 0`. Процент: `current / required`, не выше 100%. При 100% текущего масштаба `expansion_progress` остаётся на потолке; dating production продолжает давать Rating. Следующий охват растёт только после покупки expansion.

Переходы — `GameAction` через `AutomationService.create_expansion_action` → `ActionService` → `EconomyService.spend_money` → `FactoryExpansionEffect`:

| переход | UI | цена | клоны |
|---|---|---|---|
| CITY → COUNTRY | РАСШИРИТЬ ДО МАСШТАБОВ СТРАНЫ | 10 000 | `total_clones *= 10` |
| COUNTRY → WORLD | РАСШИРИТЬ ДО МАСШТАБОВ МИРА | 1 000 000 | `total_clones *= 10` |

Требования: текущий scope совпадает с переходом, coverage текущего масштаба 100%, достаточно денег. Существующие upgrades `+10 клонов` / Work ×1.5 / Dating ×1.5 продолжают работать до и после масштабирования.

Родной город — отдельная вычисляемая статистика, не persistent поле `GameState`. Authored-набор: 17 девушек, все с `GirlDefinition.counts_toward_home_city_coverage = true`. `GirlsService` считает их и завершённые линии (`relationship >= relationship_max`). New Game: 0/17 = 0%. Фабрика не завершает этих девушек. Полный охват родного города не требуется для Finale.

Automation открывается при входе в Stage 5 (после MAX Учёной). `Stage 5.on_enter_effects`:

```text
1. UnlockAutomationStageEffect  → unlocked = true
2. GrantInitialClonesStageEffect → один раз +10 клонов, initial_clones_granted = true
```

Повторный `StageService.reconcile_stage_entry_state()` не выдаёт стартовых клонов снова.

Статические upgrades живут в `AutomationCatalog`, не в `GameState`. Купленные ID — в `AutomationState.purchased_upgrade_ids`. Итоговые work / dating multiplier считаются из definitions купленных ID.

| id | имя | цена | эффект |
|---|---|---|---|
| `automation_extra_clones` | Дополнительные клоны | 1000 | +10 `total_clones` |
| `automation_work_optimization` | Оптимизация труда | 1500 | work efficiency ×1.5 |
| `automation_dating_optimization` | Оптимизация свиданий | 1500 | dating production ×1.5 |

Покупка: `AutomationService.create_upgrade_action` → `GameAction` → `ActionService` → `EconomyService.spend_money` → `AutomationUpgradeEffect`. Это отдельная progression-категория, не `progression.purchased_ids`.

Сигналы сервиса: `automation_unlocked`, `clones_changed`, `allocation_changed`, `production_changed`, `upgrade_purchased`, `expansion_changed`. `expansion_changed` вызывает `StageService.try_complete_current_stage()`. Stage 6 завершается `WorldReachRequirement`: `scope == WORLD` и coverage мира 100%.

## Character Progression

Постоянное развитие прохождения после работы:

```text
работа → деньги → характеристики / одежда / квартира → свидания и соревнования → Rating / победы
```

Канонические ID характеристик:

```text
MUSCLE = "muscle"
APPEARANCE = "appearance"
CAPITAL = "capital"
AURA = "aura"
```

Отображаемые имена: Мышца, Внешность, Капитал, Аура. Значения живут в `PlayerState`. New Game: все `0`.

Autoload `CharacteristicService`:

```text
get_value(characteristic_id) -> int
add_value(characteristic_id, amount) -> int
get_catalog() -> CharacteristicCatalog
create_upgrade_action(upgrade_id) -> GameAction
signal characteristic_changed(characteristic_id, previous_value, current_value, delta)
```

`get_value` читает `GameState.player`. `add_value` делает `current += amount`, возвращает итог и испускает `characteristic_changed`.

`CharacteristicUpgradeDefinition`:

```text
id, display_name, description, price
characteristic_id, amount
time_cost_minutes
required_filler_reward_id
```

Повторяемые upgrades, `amount = 1`, `max_level = 5`. Источник истины — текущее значение `PlayerState`, не `purchased_ids`. Внешность / Капитал / Аура остаются `$300` / `0 мин`. Мышца идёт через спортзал:

| id | имя | characteristic_id | цена | время | награда |
|---|---|---|---:|---:|---|
| `upgrade_muscle_1` | Тренажёр 1 | muscle | 50 | 60 | — |
| `upgrade_muscle_2` | Тренажёр 2 | muscle | 35 | 60 | `alina_improved_gym` |
| `upgrade_appearance_1` | Уход за внешностью | appearance | 300 | 0 | — |
| `upgrade_capital_1` | Развитие капитала | capital | 300 | 0 | — |
| `upgrade_aura_1` | Развитие ауры | aura | 300 | 0 | — |

Тренажёр 2 виден только после MAX Алины; Тренажёр 1 остаётся доступен. Pipeline: `CharacteristicService.create_upgrade_action` → `ActionService` → `EconomyService` + `CharacteristicBelowMaxRequirement` + `DailyActivityAvailableRequirement(characteristic_training)` + `CharacteristicEffect` + регистрация usage. Все четыре постоянные прокачки делят один `activity_key = characteristic_training`, daily limit = 1. Экспресс-стайлинг Киры не расходует этот key. Player-facing: «Сегодня уже тренировались. Следующая тренировка: завтра.» UI: `Мышца: 2/5`, `Прокачать до 3 — 50` / `35`, на 5/5 — «Максимум».

## Equipment

Канонический источник нарядов — Date System `Outfit` (`id`, `display_name`, `price`, `min_story_stage`, `tier`, без универсального score bonus). `tier`: `0` Casual, `1` Dressed. Spec `min_city_stage` 1–4 = Story Stage; поле в коде — `min_story_stage`. Один `outfit_id` для Game Core, GameSimulator, Date System и будущей 3D-презентации. Стартовый наряд — `casual`.

`OutfitCatalog`:

```text
START_OUTFIT_ID = casual
get_outfit(outfit_id)
get_all_outfits()
get_purchasable_outfits()
get_shop_outfits(story_stage)
```

`get_purchasable_outfits` — enabled outfits с `price > 0`. `get_shop_outfits` дополнительно фильтрует по `Outfit.min_story_stage`.

`ProgressionState` хранит набор купленных `owned_outfit_ids` и экипированный `current_outfit_id`. New Game: во владении и на герое `casual`.

Autoload `EquipmentService`:

```text
get_current_outfit_id() -> StringName
owns_outfit(outfit_id) -> bool
get_owned_outfits() -> Array
get_shop_outfits() -> Array[Outfit]
create_buy_outfit_action(outfit_id) -> GameAction
equip_outfit(outfit_id) -> bool
signal outfit_equipped(previous_outfit_id, current_outfit_id)
```

Покупка — разовая, через `create_buy_outfit_action`: обычный `money_cost = price`, `OutfitNotOwnedRequirement`, `MinStoryStageRequirement`, `OwnOutfitEffect`. Если `marina_free_outfit_pending` и Outfit открыт текущим progression, ещё не owned и присутствует в обычном магазине, effective price = `$0`, player-facing `$0 · Подарок Марины`, та же кнопка покупки. Первая успешная покупка выдаёт выбранный Outfit, ставит `marina_free_outfit_pending = false`; остальные сразу снова по обычной цене. Если выбрать нечего, pending сохраняется. Отдельного gift-списка в player-facing магазине нет. Покупка добавляет Outfit во владение и делает его текущим. Перед свиданием можно бесплатно экипировать любой уже купленный Outfit.

Outfit progression: Stage 1 — только `casual` (`tier = 0`); Stage 2 — Clothing Store и stat-only Dressed Outfit (`tier = 1`, `+1` к одной характеристике); Stage 3 — Outfit Move / Outfit Source; Stage 4 — late Outfit Moves. Универсального бонуса к итогу свидания нет. Марина — Stage 2 optional path к первому Outfit за `$0`, Casual exception. Девушки, доступные с Stage 2, кроме Марины, требуют для свидания экипированный Outfit `tier >= 1`; отказ по смыслу: «Для этого свидания нужен образ интереснее повседневного.»

`EffectiveStat = min(BaseStat + OutfitStatBonus, 5)`.

`get_equipped_outfit_id()` — алиас `get_current_outfit_id()`.

## Apartment

Вложенный `ApartmentState` внутри `ProgressionState`:

```text
prepared: bool = true
owned_local_object_ids
accent_object_id: StringName = ""
```

Apartment — единственный DateVenue, Local coverage которого строит сам игрок. Канон покрытия: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).

```text
12 purchasable Apartment Local Objects
12 canonical Tags
1 Object = 1 unique Tag
1 Object = 1 Local Move
Stage 1: 0 / 12
Stage 2: up to 4 / 12
Stage 3: up to 8 / 12
Stage 4: up to 12 / 12
```

`ApartmentObjectDefinition`:

```text
id, display_name, description, price, min_story_stage, local_move_id, placement_id, enabled
```

Точный список 12 объектов, Tags, цены и тексты Local Moves: [`VENUES_AND_LOCAL_OBJECTS.md`](VENUES_AND_LOCAL_OBJECTS.md). `ApartmentObjectDefinition.id` = Local Object id. Stage 2: `apartment__plaid` $150 CARE, `apartment__tv` $200 HUMOR, `apartment__record_player` $250 COMPOSURE, `apartment__no_filter_cards` $300 DIRECTNESS. Stage 3: `apartment__tea_set` $400 POLITENESS, `apartment__mini_fridge` $475 GENEROSITY, `apartment__large_mirror` $550 FLATTERY, `apartment__collection_display` $625 STATUS. Stage 4: `apartment__karaoke` $750 AUDACITY, `apartment__game_console` $850 DOMINANCE, `apartment__darts` $950 RISK, `apartment__chess_table` $1100 CUNNING.

`ApartmentState.prepared` стартует `true`. После свидания в квартире квартира становится грязной (`prepared = false`). Уборка — игровое действие `$0 / 30 мин`. Награда Леры автоматически готовит квартиру перед каждым домашним свиданием.

После MAX Кати открывается `Акцент интерьера`: игрок назначает один уже купленный Apartment Local Object. Accent Local Move: positive `+2`, negative `-1`. Обычный Apartment Local Move: `+1` / `-1`. Первое назначение `$0`; последующая смена через Катю / Furniture Store: Story Stage `2 / 3 / 4+` = `$300 / $600 / $1000`.

Autoload `ApartmentService`:

```text
is_prepared() -> bool
is_object_owned(object_id) -> bool
create_buy_apartment_object_action(object_id) -> GameAction
get_accent_object_id() -> StringName
```

Player-facing прогрессия: `Предметы: N / 12`. Apartment не хранит level. Date System использует `prepared` и owned Local Objects: подготовленная квартира `0`, неподготовленная `-1`. Stage 1 coverage = 0.

Pipeline: `ApartmentObjectDefinition` → `ApartmentService.create_buy_apartment_object_action` → `ActionService` → `EconomyService` → `ApartmentOwnObjectEffect` → `ApartmentState.owned_local_object_ids`. Повтор блокируется `is_object_owned`. Покупка уважает Stage cap покрытия (`0 / 4 / 8 / 12`).

## Story / Stages

Кампания — последовательность сюжетных глав. Stage фиксирует итог главы; путь к итогу строят Rating, Rival, Economy, характеристики, одежда и квартира.

Обучающая роль Stage 1–4 и порядок систем — [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md):

```text
Stage 1 — Foundations: Apartment-only, BASE + Characteristic, Casual, 0 Local Moves
Stage 2 — Choice: Café + Leisure Center, Local Source, stat-only Outfit, «Приоденься», Marina
Stage 3 — Synergy: Restaurant, Outfit Moves, multi-system combinations
Stage 4 — Mastery: полный ручной toolkit, 12-Tag Apartment
Stage 5 — Factory Introduction
```

```text
Пролог (отдельный onboarding)
→ Stage 1 → Stage 2 → Stage 3 → Stage 4 → Stage 5 → Stage 6 → Finale
```

Пролог (Соседка) не входит в `StoryState.stage`. Основная кампания начинается с Stage 1 после пролога. Текущий `GameSimulator` стартует сразу в Stage 1.

```text
Stage 1–5
    ↓
одна ключевая сюжетная девушка
    ↓
relationship достигает MAX
    ↓
Stage завершён
    ↓
активируется следующий Stage
    ↓
применяются on_enter_effects нового Stage
```

`StoryState` хранит только изменяемый прогресс кампании:

```text
stage: int = 1
finale_reached: bool = false
```

`stage` — текущая или последняя достигнутая игровая стадия (1–6). После завершения Stage 6 `stage` остаётся 6, а `finale_reached` становится `true`. Статические `StageDefinition` в save не сериализуются. Прогресс цели главы вычисляется из `GirlState.relationship`.

### StageDefinition

Типизированный `Resource`, статическое game data:

```text
stage: int
display_name: String
completion_requirement: StageRequirement
on_enter_effects: Array[StageEnterEffect]
```

Один `completion_requirement` — главная сюжетная цель главы. `on_enter_effects` — 0..N идемпотентных изменений мира при активации этой главы. Повторный `apply()` даёт то же итоговое состояние.

### StageRequirement

Базовый typed-класс:

```text
is_met() -> bool
get_current_value() -> int
get_target_value() -> int
get_description() -> String
```

Текущая реализация — `GirlRelationshipRequirement(girl_id, target_relationship)`:

```text
is_met: GirlsService.get_relationship(girl_id) >= target_relationship
get_current_value: GirlsService.get_relationship(girl_id)
get_target_value: target_relationship
get_description: человекочитаемая цель с именем из GirlDefinition
```

Для сюжетных Stage 1–5 `StageCatalog` при создании `GirlRelationshipRequirement` читает соответствующую `GirlDefinition` и ставит `target_relationship = girl_definition.relationship_max`. Источник максимума один: изменение `relationship_max` в definition меняет цель главы в заново построенном requirement. Stage 6 использует `WorldReachRequirement` того же базового класса и завершает главу через тот же `try_complete_current_stage()`.

### Сюжетные девушки Stage 1–5

Это цели глав внутри authored-набора из 17 девушек родного города; filler (`alina`, `marina`, `vika`, `dasha`, `katya`, `lera`, `kira`, `olya`, `sonya`, `nika`, `rita`, `eva`) главы не завершают.

| Stage | girl_id | имя | MAX |
|---|---|---|---|
| 1 | `girl_actress` | Актриса | `relationship_max` девушки |
| 2 | `girl_mine_boss` | Начальница шахты | `relationship_max` девушки |
| 3 | `girl_magazine_editor` | Редактор журнала | `relationship_max` девушки |
| 4 | `girl_scientist` | Учёная | `relationship_max` девушки |
| 5 | `girl_president` | Президент | `relationship_max` девушки |

Сюжетная линия главы: знакомство с сюжетной девушкой → связанный Rival появляется в той же мировой локации → соревнование → свидание → MAX → следующий Stage. Соседка (`girl_neighbor`) относится к прологу и не является целью Stage 1–5.

### Stage 6

Production: `stage = 6`, `completion_requirement = WorldReachRequirement`. Requirement выполнен, когда `current_expansion_scope == WORLD` и coverage мира 100%. `on_enter_effects` содержит только уже заданные канонические unlock'и этой главы; сейчас список пуст. После MAX отношений Президента: Stage 5 завершается → `stage = 6` → `on_enter_effects` Stage 6 → глава активна. Фабрика клонов к этому моменту уже открыта с Stage 5 и может уже иметь World 100%. После входа в новый Stage `StageService` сразу повторно вызывает `try_complete_current_stage()`: заранее достигнутый World Reach завершает Stage 6 без дополнительного действия игрока.

Полный охват родного города не является условием Stage 6 / Finale.

Когда `WorldReachRequirement` выполнен, `try_complete_current_stage()` идёт по ветке последнего Stage: `finale_reached = true`, сигналы `stage_completed(6)` и `finale_reached()`, `StoryState.stage` остаётся `6`. Stage 7 не создаётся.

### StageEnterEffect

Базовый typed-класс: `apply() -> void`. Реализации: `UnlockLocationStageEffect(location_id)` вызывает `WorldService.unlock_location(location_id)`; `SetCityStageStageEffect(city_stage)` вызывает `WorldService.set_city_stage` (idempotent max); `UnlockAutomationStageEffect` открывает фабрику; `GrantInitialClonesStageEffect` один раз выдаёт 10 стартовых клонов.

Будущие типы (`UnlockGirlStageEffect`, `UnlockRivalStageEffect`, `UnlockPurchaseStageEffect`, `UnlockDateVenueStageEffect`, `UnlockSystemStageEffect`) добавляются вместе с persistent unlock соответствующей системы. `UnlockDateVenueStageEffect(date_venue_id)` открывает DateVenue для свиданий; это отдельно от `UnlockLocationStageEffect`.

Канонические `on_enter_effects` заполняются persistent unlock'ами главы. Stage 1 и Stage 6: `on_enter_effects = []`. Stage 2: `SetCityStageStageEffect(2)`, `UnlockLocationStageEffect(leisure_center)`, `UnlockLocationStageEffect(furniture_store)`, `UnlockLocationStageEffect(clothing_store)`, `UnlockLocationStageEffect(restaurant)`, `UnlockDateVenueStageEffect(cafe)`, `UnlockDateVenueStageEffect(leisure_center)`. Stage 3: `UnlockDateVenueStageEffect(restaurant)`. Stage 4: `SetCityStageStageEffect(3)`. Stage 5: `UnlockAutomationStageEffect`, затем `GrantInitialClonesStageEffect`. `reconcile_stage_entry_state()` восстанавливает DateVenues, мировые локации и достигнутый City Stage для сохранений Stage 2+.

Stage 2 также включает текущую цель «Приоденься», пока нет Dressed Outfit: купить любой образ выше Повседневного. Hint: Марина работает в магазине одежды. Пока цель не выполнена, `ObjectiveService` показывает её как текущую цель Stage 2, затем сразу переходит к следующей незавершённой сюжетной цели главы.

`on_enter_effects` принадлежат **новому** активному Stage: завершение Stage 1 ставит `stage = 2` и применяет эффекты Stage 2.

### StageCatalog

```text
get_stage(stage: int) -> StageDefinition
get_all_stages() -> Array[StageDefinition]
```

Содержит Stage 1–6. Seed собирается в коде, как `GirlCatalog` / `LocationCatalog`.

### StageService

Autoload — единственная точка продвижения кампании. Читает `StageCatalog`, пишет `GameState.story`.

```text
FIRST_STAGE = 1
LAST_STAGE = 6

get_current_stage() -> int
get_current_definition() -> StageDefinition
get_current_requirement() -> StageRequirement
can_complete_current_stage() -> bool
try_complete_current_stage() -> bool
force_complete_current_stage_for_dev() -> bool
is_finale_reached() -> bool
reconcile_stage_entry_state() -> void
```

`can_complete_current_stage()`: `false`, если Finale уже достигнут, нет definition или `completion_requirement == null`; иначе `requirement.is_met()`.

`try_complete_current_stage()` — production-точка. Если цель не выполнена, вернуть `false`. Если выполнена — канонический переход и `true`.

Порядок перехода при `current_stage < LAST_STAGE`:

```text
1. Проверить can_complete_current_stage()
2. Испустить stage_completed(completed_stage)
3. StoryState.stage += 1
4. Применить on_enter_effects нового Stage
5. Испустить stage_changed(previous_stage, current_stage)
6. Повторно вызвать try_complete_current_stage() для нового Stage
```

К моменту `stage_changed` новое состояние мира уже активно.

Порядок перехода при `current_stage == LAST_STAGE`:

```text
1. Проверить can_complete_current_stage()
2. StoryState.finale_reached = true
3. Испустить stage_completed(6)
4. Испустить finale_reached()
5. StoryState.stage остаётся 6
```

`force_complete_current_stage_for_dev()` — только dev Presentation. Stage 1–5: тот же переход и `on_enter_effects` без проверки цели. Stage 6: та же finale-ветка (`finale_reached`, `stage_completed(6)`, `finale_reached()`, `stage` остаётся 6).

Сигналы:

```text
stage_progress_changed(stage: int)
stage_completed(stage: int)
stage_changed(previous_stage, current_stage)
finale_reached()
```

`stage_progress_changed` испускается после данных, влияющих на текущий `StageRequirement`. Сейчас источник — `GirlsService.girl_relationship_changed`. Затем `StageService.try_complete_current_stage()`. Изменение отношений другой девушки главу не завершает.

Gameplay-ворота остаются в своих системах и не являются `StageRequirement`:

- доступ к знакомству и свиданиям — `GirlDefinition.meet_requirements` / `date_requirements` (`GirlAccessRequirement`);
- деньги, покупки, характеристики, одежда, квартира — `EconomyService` / `PurchaseService` / `CharacteristicService` / `EquipmentService` / `ApartmentService`.

Rating, Stage и Rival независимы: высокий Rating не завершает главу; глава завершается только `GirlRelationshipRequirement` сюжетной девушки. Rating — горизонтальная прогрессия внутри Stage.

### New Game / Load

После `SaveManager.new_game()` (`stage = 1`) и после `load_game()` `StageService.reconcile_stage_entry_state()` последовательно применяет `on_enter_effects` Stage 1 .. current Stage. Идемпотентность даёт одинаковый мир для save без StageDefinition. `TimeService.on_playthrough_reset()` вызывается в том же порядке.

## World / Locations

Физический мир отделён от содержательных действий:

```text
WORLD NAVIGATION          GAME ACTION
ходьба / дверь            работа / покупка
вход / выход интерьера    знакомство / свидание
переход зоны              соревнование / прочее
        ↓                         ↓
WorldService              ActionService
SceneTransitionService    EconomyService / TimeService
```

`DateVenue` остаётся местом свидания (скоринг). `LocationDefinition` — физическая локация мира. Одинаковые строковые ID (`apartment`, `cafe`) означают одно и то же место в fiction, но это разные typed Resources.

`LocationDefinition`:

```text
id: StringName
display_name: String
location_type: CITY_ZONE | INTERIOR
scene_path: String
default_spawn_id: StringName
parent_location_id: StringName
```

`CITY_ZONE` — физическая часть города, `parent_location_id = ""`. `INTERIOR` — отдельная подгружаемая сцена; `parent_location_id` указывает городскую зону входа.

Seed каталога текущего дизайна:

| id | имя | type | parent | start |
|---|---|---|---|---|
| `city_center` | Центральная часть города | CITY_ZONE | — | текущая и открыта |
| `apartment` | Квартира | INTERIOR | `city_center` | открыта |
| `cafe` | Кафе | INTERIOR | `city_center` | открыта как мир; DateVenue с Stage 2 |
| `leisure_center` | Leisure Center | INTERIOR | `city_center` | закрыта до Stage 2 |
| `furniture_store` | Мебельный магазин | INTERIOR | `city_center` | закрыта до Stage 2 |
| `clothing_store` | Магазин одежды | INTERIOR | `city_center` | закрыта до Stage 2 |
| `restaurant` | Ресторан | INTERIOR | `city_center` | закрыта до Stage 2 как мир; DateVenue с Stage 3 |

`START_LOCATION_ID = city_center`. `START_UNLOCKED_LOCATION_IDS = [city_center, apartment, cafe]`. Кафе открыто на Stage 1 как место знакомства (Вика, Даша), но не как DateVenue. `leisure_center`, `furniture_store` и `clothing_store` открываются при входе в Stage 2. `START_UNLOCKED` не включает `clothing_store`. `restaurant` открывается как мировая локация при входе в Stage 2 (Начальница шахты, Оля, позже Президент); как DateVenue — на Stage 3. High-level DateVenue contract: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).

`LocationCatalog`:

```text
get_location(location_id) -> LocationDefinition
get_all_locations() -> Array[LocationDefinition]
get_locations_by_type(location_type) -> Array[LocationDefinition]
get_interiors_for_zone(zone_id) -> Array[LocationDefinition]
```

`WorldState`:

```text
current_location_id: StringName
unlocked_location_ids: Array[StringName]
```

`to_dict()` / `from_dict()` сериализуют оба поля. Один ID в `unlocked_location_ids` хранится один раз. Отсутствующие поля → стартовое состояние New Game.

Autoload `WorldService` — единственная точка смены семантической локации и unlock. Читает и пишет `GameState.world`.

```text
get_current_location_id() -> StringName
get_current_location() -> LocationDefinition
is_location_unlocked(location_id) -> bool
unlock_location(location_id) -> bool
can_enter_location(location_id) -> bool
enter_location(location_id) -> bool
signal location_unlocked(location_id)
signal location_changed(previous_location_id, current_location_id)
```

`unlock_location`: добавляет ID один раз, при первом открытии испускает `location_unlocked` и возвращает `true`; повтор возвращает `false` без сигнала. `can_enter_location`: definition существует и ID открыт. `enter_location`: при `can_enter` запоминает предыдущий ID, пишет `current_location_id`, испускает `location_changed`, возвращает `true`. `time_cost = 0`: время не двигается. Закрытая или неизвестная локация: `false`, состояние не меняется.

3D Presentation:

- `LocationSpawnPoint` — reusable `Marker3D` с `spawn_id` внутри 3D-сцены.
- `LocationDoor` — reusable дверь с `target_location_id` и `target_spawn_id`; при взаимодействии вызывает `SceneTransitionService.transition_to_location`.
- Autoload `SceneTransitionService.transition_to_location(location_id, spawn_id = "")`: каталог → `WorldService.can_enter` / `enter_location` → загрузка `scene_path` → игрок в `spawn_id` или `default_spawn_id`.

Выход из интерьера — тот же `LocationDoor` на родительскую `CITY_ZONE`. После `load_game()` 3D Presentation читает `current_location_id`, грузит `scene_path` и ставит игрока в `default_spawn_id`. 2D `GameSimulator` сцену не грузит: только `WorldService.enter_location` + `refresh()`.

`TimeService.real_time_progression_enabled` уже существует и выключен для 2D. Будущий 3D free roam включает его на время ходьбы; дверь по-прежнему только меняет локацию и сцену.

## Girls / Discovery

Знакомство — игровое действие мира, не навигация и не Date Engine. `GirlProfile` остаётся контентом лаборатории свиданий. `GirlDefinition` — статическая девушка прохождения: тот же `id`, что у seed Date System.

```text
GirlCatalog
     │
     ▼
GirlDefinition                 GameState.girls
id / name / location                │
relationship min/max                ▼
meet_requirements[]            GirlState
date_requirements[]            discovered / contact /
     │                         relationship
     ▼
GirlsService
     │
     ├── WorldService
     ├── RatingService / StageService / RivalsService
     └── GameAction → ActionService
```

`GirlDefinition`:

```text
id: StringName
display_name: String
location_id: StringName
relationship_min: int
relationship_max: int
counts_toward_home_city_coverage: bool = true
meet_requirements: Array[GirlAccessRequirement] = []
date_requirements: Array[GirlAccessRequirement] = []
```

Это статическое game data. Requirements не пишутся в save. `counts_toward_home_city_coverage` включает девушку в ручной охват родного города. Все текущие authored-девушки `GirlCatalog`, включая сюжетных, входят в этот показатель. Будущие массовые сущности Automation не создаются как `GirlDefinition`.

`location_id` ссылается на существующий `LocationDefinition`. Нижняя граница отношений у всех девушек — `0`. Обычные девушки, Actress, Mine Boss и Magazine Editor: `relationship_max = 10`. Scientist и President: `relationship_max = 15`. Старт отношений — `0`. `GirlDefinition.id` совпадает с `GirlProfile.id`.

### GirlAccessRequirement

Базовый typed `Resource` для доступа к девушке. Не `ActionRequirement` и не `StageRequirement`: у доступа есть прогресс для UI.

```text
is_met(girl_id: StringName) -> bool
get_description(girl_id: StringName) -> String
get_progress_text(girl_id: StringName) -> String
```

`is_met` — gameplay-проверка. `get_description` — название для игрока. `get_progress_text` — текущее состояние.

Текущие типы:

| Класс | Параметр | is_met | description | progress |
|---|---|---|---|---|
| `RatingGirlRequirement` | `required_rating` | `RatingService.get_rating() >= required_rating` | `"Рейтинг"` | `"<current> / <required>"` |
| `RivalDefeatedGirlRequirement` | `rival_id` | `RivalsService.is_defeated(rival_id)` | `"Победить <RivalDefinition.display_name>"` | `"Не выполнено"` / `"Выполнено"` |
| `MinStageGirlRequirement` | `minimum_stage` | `StageService.get_current_stage() >= minimum_stage` | `"Этап сюжета"` | `"Stage <current> / <required>"` |
| `CurrentStageFillerMaxGirlRequirement` | `story_stage`, `required_count` | число filler этого Stage с relationship MAX `>= required_count` | `"Девушки этапа"` | `"<current> / <required>"` |
| `OutfitAboveCasualGirlRequirement` | — | экипированный `Outfit.tier >= 1` | `"Одежда"` | `"Повседневный"` / `"Выше повседневного"` |

Новые типы (`AuthorityGirlRequirement`, `PurchaseGirlRequirement`, `CharacteristicGirlRequirement`, `StoryFlagGirlRequirement`) добавляют тот же контракт. `GirlsService` и `DatingService` работают только с базовым интерфейсом.

`meet_requirements` — можно ли впервые познакомиться. Девушка в текущей открытой локации видна даже при невыполненном Rating: UI показывает имя и прогресс. `date_requirements` — можно ли назначить следующее свидание после знакомства.

Presentation-элемент `RequirementStatus`: `description`, `progress_text`, `is_met`. Его отдают `GirlsService.get_meet_requirements_status` и `DatingService.get_date_requirements_status`. GameSimulator не знает конкретный класс requirement.

Authored-набор родного города (17 девушек, все `counts_toward_home_city_coverage = true`; обычные, Actress, Mine Boss и Editor `0..10`; Scientist и President `0..15`):

| id | имя | локация | meet_requirements | date_requirements |
|---|---|---|---|---|
| `alina` | Алина | `city_center` | `MinStageGirlRequirement(1)` | `[]` |
| `vika` | Вика | `cafe` | `MinStageGirlRequirement(1)` | `[]` |
| `dasha` | Даша | `cafe` | `MinStageGirlRequirement(1)` | `[]` |
| `girl_actress` | Актриса | `city_center` | `MinStageGirlRequirement(1)`, `CurrentStageFillerMaxGirlRequirement(1, 2)`, `RatingGirlRequirement(2)` | `RivalDefeatedGirlRequirement(rival_boris)` |
| `marina` | Марина | `clothing_store` | `MinStageGirlRequirement(2)` | `[]` |
| `katya` | Катя | `furniture_store` | `MinStageGirlRequirement(2)` | `OutfitAboveCasualGirlRequirement` |
| `lera` | Лера | `cafe` | `MinStageGirlRequirement(2)` | `OutfitAboveCasualGirlRequirement` |
| `kira` | Кира | `cafe` | `MinStageGirlRequirement(3)` | `OutfitAboveCasualGirlRequirement` |
| `olya` | Оля | `restaurant` | `MinStageGirlRequirement(3)` | `OutfitAboveCasualGirlRequirement` |
| `girl_mine_boss` | Начальница шахты | `restaurant` | `MinStageGirlRequirement(2)`, `CurrentStageFillerMaxGirlRequirement(2, 2)`, `RatingGirlRequirement(5)` | `RivalDefeatedGirlRequirement(rival_foreman)`, `OutfitAboveCasualGirlRequirement` |
| `girl_magazine_editor` | Редактор журнала | `cafe` | `MinStageGirlRequirement(3)`, `CurrentStageFillerMaxGirlRequirement(3, 2)`, `RatingGirlRequirement(8)` | `RivalDefeatedGirlRequirement(rival_columnist)`, `OutfitAboveCasualGirlRequirement` |
| `sonya` | Соня | `city_center` | `MinStageGirlRequirement(3)` | `OutfitAboveCasualGirlRequirement` |
| `nika` | Ника | `cafe` | `MinStageGirlRequirement(4)` | `OutfitAboveCasualGirlRequirement` |
| `rita` | Рита | `restaurant` | `MinStageGirlRequirement(4)` | `OutfitAboveCasualGirlRequirement` |
| `eva` | Ева | `restaurant` | `MinStageGirlRequirement(4)` | `OutfitAboveCasualGirlRequirement` |
| `girl_scientist` | Учёная | `city_center` | `MinStageGirlRequirement(4)`, `CurrentStageFillerMaxGirlRequirement(4, 2)`, `RatingGirlRequirement(11)` | `RivalDefeatedGirlRequirement(rival_academic)`, `OutfitAboveCasualGirlRequirement` |
| `girl_president` | Президент | `restaurant` | `MinStageGirlRequirement(5)`, `RatingGirlRequirement(12)` | `RivalDefeatedGirlRequirement(rival_minister)`, `OutfitAboveCasualGirlRequirement` |

Filler доступны по Story Stage без соперника. Сюжетные: 2 of 3 current-stage filler MAX + Rating → знакомство → связанный Rival → победа → свидание → MAX → следующий Stage. Каноническая связь `RivalDefinition.linked_girl_id`; сервисы не хардкодят пары. `RivalsService.get_rivals_at_current_location` показывает сюжетного соперника только если `GirlsService.is_discovered(linked_girl_id)` и ordinary/story rivals при `minimum_story_stage <= Story Stage`. Stage 1 даёт три параллельных filler-линии (Алина, Вика, Даша); две завершённые открывают Actress (Rating 2). После Actress City Stage 2, Clothing Store, Café/Leisure DateVenues и текущая цель «Приоденься». Марина — Stage 2 Casual exception и optional path к первому Outfit. Остальные Stage 2+ girls требуют Outfit выше Casual; отказ: «Для этого свидания нужен образ интереснее повседневного.» Две из Stage 2 filler открывают Mine Boss (Rating 5); после неё работа 200/ч. Две из Stage 3 filler (Кира, Оля, Соня) открывают Editor (Rating 8). После Editor City Stage 3 и 12 / 12 Apartment cap. Две из Stage 4 filler (Ника, Рита, Ева) открывают Scientist (Rating 11); Scientist MAX даёт Rating 12 и открывает President. Filler не завершают Stage. Roster: [`STORY_STAGE_PROGRESSION.md`](STORY_STAGE_PROGRESSION.md).

`GirlCatalog`:

```text
get_girl(girl_id) -> GirlDefinition
get_all_girls() -> Array[GirlDefinition]
get_girls_for_location(location_id) -> Array[GirlDefinition]
```

`GirlState` — только изменяемое состояние прохождения:

```text
discovered: bool = false
has_contact: bool = false
relationship: int = 0
revealed_positive_tag_ids: Array[StringName] = []
revealed_negative_tag_ids: Array[StringName] = []
completed_dates: int = 0
last_date_situation_ids: Array[StringName] = []
```

Раскрытые теги, `completed_dates` и `last_date_situation_ids` — то же знание, что у Date System `GirlProgress`; definitions тегов живут в Date Catalog. Доступность свидания не хранится на `GirlState`: её даёт `DailyActivityService` key `date:<girl_id>` (1 бесплатный слот в календарный день, следующий слот завтра; Рита — `$75` за extra same-day). Канонические границы отношений — `GirlDefinition.relationship_min` / `relationship_max` (обычные, Actress, Mine Boss и Editor `0..10`; Scientist и President `0..15`). Date System читает этот максимум и не хранит отдельную копию на `GirlProfile`. Завершённая линия: `relationship == relationship_max`, player-facing `Отношения: N / N — МАКСИМУМ`. Отдельный persistent-флаг завершения не нужен.

`GirlsState.girls_by_id`: `girl_id → GirlState`. При первом `GirlsService.get_state` для существующей девушки создаётся стандартный `GirlState` и кладётся в `GameState.girls.girls_by_id`. New Game: `girls_by_id = {}`.

Autoload `GirlsService` — единственная точка discovery, контакта, relationship и знания тегов прохождения. Читает definitions из каталога и пишет `GameState.girls`. Доступность свидания — `DailyActivityService` key `date:<girl_id>`.

```text
get_definition(girl_id) -> GirlDefinition
get_state(girl_id) -> GirlState
is_discovered(girl_id) -> bool
has_contact(girl_id) -> bool
get_relationship(girl_id) -> int
get_relationship_max(girl_id) -> int
is_relationship_completed(girl_id) -> bool
get_home_city_girl_count() -> int
get_home_city_completed_count() -> int
get_home_city_coverage_percent() -> float
discover_girl(girl_id) -> bool
give_contact(girl_id) -> bool
change_relationship(girl_id, delta) -> int
fill_date_progress(girl_id, progress) -> void
apply_date_knowledge(girl_id, progress) -> void
get_girls_at_current_location() -> Array[GirlDefinition]
get_discovered_girls() -> Array[GirlDefinition]
get_contacted_girls() -> Array[GirlDefinition]
can_meet_girl(girl_id) -> bool
get_meet_requirements_status(girl_id) -> Array[RequirementStatus]
get_meet_failure_reason(girl_id) -> String
create_meet_girl_action(girl_id) -> GameAction
signal girl_discovered(girl_id)
signal girl_contact_received(girl_id)
signal girl_relationship_changed(girl_id, previous_value, current_value, delta)
signal girl_relationship_completed(girl_id)
signal girl_access_changed(girl_id)
```

`discover_girl`: при первом открытии `discovered = true`, сигнал `girl_discovered`, `true`; повтор — состояние прежнее, `false`. `give_contact`: `discovered = true` и `has_contact = true`; при первом контакте сигнал `girl_contact_received` и `true`. `change_relationship`: если линия уже завершена, `relationship` остаётся `relationship_max` и Rating не начисляется повторно. Иначе `relationship += delta`, clamp в `relationship_min..relationship_max` девушки. Если переход впервые достигает максимума, испускается `girl_relationship_completed` и `RatingService.add_rating(1)`. Затем `girl_relationship_changed`, возврат нового значения. `is_relationship_completed` — каноническая проверка завершённой линии: `get_relationship(girl_id) >= get_relationship_max(girl_id)`. Охват родного города считается из `GirlCatalog` + существующих `GirlState` без persistent `city_coverage` и без создания `GirlState` для нетронутых девушек. `fill_date_progress` копирует в snapshot `GirlProgress` канонические `relationship`, revealed tags, `completed_dates` и `last_date_situation_ids`. `apply_date_knowledge` пишет обратно revealed tags, `completed_dates` и `last_date_situation_ids`; `relationship` по-прежнему меняет только `change_relationship`.

`get_girls_at_current_location` читает `WorldService.get_current_location_id()` и возвращает `GirlDefinition` с тем же `location_id`, независимо от `meet_requirements`. Этот контракт общий для 2D GameSimulator и будущего 3D NPC (`girl_id` → тот же `GameAction`). Невыполненный Rating не скрывает девушку в открытой локации.

`can_meet_girl(girl_id)`:

```text
1. Есть GirlDefinition
2. Девушка в текущей локации (как GirlLocationRequirement)
3. Ещё не discovered
4. Каждый meet_requirements.is_met(girl_id)
```

`get_meet_requirements_status` возвращает `RequirementStatus` по каждому `meet_requirements`. `get_meet_failure_reason` — первая человекочитаемая причина: нет definition / другая локация / уже знакомы / первый невыполненный access requirement (`"<description>: <progress_text>"`).

`girl_access_changed(girl_id)` испускается, когда меняется Rating, Stage или победа Rival. GameSimulator обновляет экран через уже существующий центральный `refresh()`.

Знакомство — `GameAction` через `GirlsService.create_meet_girl_action`:

```text
id = meet_<girl_id>
time_cost_minutes = 30
money_cost = 0
requirements: GirlMeetAvailableRequirement(girl_id)
effects: MeetGirlEffect
```

`GirlMeetAvailableRequirement.is_met` → `GirlsService.can_meet_girl`. Причина отказа → `get_meet_failure_reason`. `MeetGirlEffect` вызывает `discover_girl` и `give_contact`. Повторное знакомство отказывает `"Вы уже знакомы"`. В другой локации — `"Девушка находится в другой локации"`. `GirlContactRequirement` — приглашение на свидание. Dating-слой берёт девушку по `girl_id` и обновляет отношения через `GirlsService`.

## Rating

`Rating` — глобальный показатель прохождения. Хранится в `PlayerState.rating`. New Game: `0`. Источники:

```text
ручное завершение девушки → RatingService.add_rating(1)
dating production фабрики → RatingService.add_rating(целые накопленные единицы)
```

Оба источника используют один счётчик. `RatingGirlRequirement` читает этот же глобальный Rating: после мощной фабрики городские Rating-требования обычно уже выполнены.

Autoload `RatingService` — единственная точка изменения Rating:

```text
get_rating() -> int
add_rating(amount: int = 1) -> int
signal rating_changed(previous_rating, current_rating, delta)
```

`get_rating()` возвращает `GameState.player.rating`. `add_rating()` увеличивает Rating и возвращает новое значение. Ручное начисление происходит один раз в момент первого достижения `relationship_max` конкретной девушки. Фабрика начисляет целые единицы dating production через тот же метод; дробный остаток живёт в `AutomationState.dating_progress_fraction`.

## Filler Girl Rewards

Story Girl MAX расширяет игру и двигает крупный progression. Filler Girl MAX улучшает уже доступные системы.

Каждая из 12 filler-девушек по-прежнему даёт `Rating +1` при первом MAX и ровно одну персональную постоянную награду. Награда видна на карточке до MAX, активируется на том же переходе `previous < max → current >= max` и не выдаётся повторно. Базовые версии затронутых систем остаются доступны без награды.

`FillerRewardCatalog` — статическое game data. `GameState.progression.unlocked_filler_reward_ids` хранит полученные ID; `marina_free_outfit_pending` — неиспользованное право на подарок Марины. Date Engine не читает autoload: флаги приходят в `DateSessionConfig` из `DatingService`.

| Девушка | Reward ID | Эффект |
|---|---|---|
| Алина | `alina_improved_gym` | В прокачке рядом с «Тренажёр 1» ($50 / 60 мин, Мышца +1) появляется «Тренажёр 2» ($35 / 60 мин). Оба видны. |
| Марина | `marina_free_outfit` | Один бесплатный уже доступный незакупленный Outfit через обычный Outfit Store: `$0 · Подарок Марины`. Право в `marina_free_outfit_pending` сохраняется, пока выбрать нечего. |
| Вика | `vika_base_reroll` | Один раз за свидание за $25 заменить 3 текущих BASE; Situation и источники не меняются. |
| Даша | `dasha_soften_negative` | Первая отрицательная реакция свидания: `-1 → 0`; тег всё равно раскрывается как отрицательный, combo сбрасывается. |
| Катя | `katya_interior_accent` | Назначить один уже купленный Apartment Local Object акцентным. Accent Local Move: `+2` / `-1`. Первое назначение `$0`; смена Accent по Story Stage `$300 / $600 / $1000` (Stage `2 / 3 / 4+`). |
| Лера | `lera_apartment_cleaning` | После квартирного свидания `prepared = false`; уборка $0 / 30 мин; с наградой квартира автоматически готовится перед домашним свиданием. |
| Кира | `kira_express_styling` | Чекбокс подготовки $40: временная Внешность +1 на это свидание, cap 5. Не расходует `characteristic_training`. |
| Оля | `olya_overtime` | Daily limit `work` становится 2. Вторая смена 50% ставки / 60 мин; чекбокс на первой смене даёт суммарно $150 / 120 мин на seed-ставке $100. |
| Соня | `sonya_restaurant_second_venue` | Venue Source в Restaurant: 1 → 2 использования; каждый Local Move по-прежнему один раз. |
| Ника | `nika_backup_outfit` | Запасной owned Outfit; чекбокс смены после эпизода (не CLOSING); состояние Outfit Source сохраняется. |
| Рита | `rita_urgent_taxi` | $75 за каждую дополнительную same-day встречу с девушкой, чей бесплатный `date:<girl_id>` уже использован. |
| Ева | `eva_read_people` | `effective_initial_known_tag_count = GirlProfile.initial_known_tag_count + 1`; ретро +1 неизвестный Tag уже знакомым незавершённым девушкам, затем общая нормализация знания. |

Player-facing роли и описания девушек — в Seed Girls. Game Simulator показывает награду на карточке, результат MAX и DEV-панель: MAX/сброс каждой награды, деньги, четыре характеристики, дневной слот свидания, `Apartment.prepared`.

## Dating

Autoload `DatingService` связывает Game Core и существующую Date System. Место знакомства и место свидания независимы:

```text
GirlDefinition.location_id  — где девушка находится в мире
DateVenue                — где проходит выбранное игроком свидание
```

`DatingState.active_date` хранит активное свидание прохождения:

```text
girl_id
venue_id
outfit_id
started_at_game_time
```

`venue_id` — выбранный игроком `DateVenue`. `outfit_id` — выбранный среди owned outfits. Когда свидания нет, `active_date = {}`. DateSession эпизода — runtime Date Engine; если сессия не сериализуется в JSON, после load восстанавливаются `girl_id`, `venue_id`, `outfit_id` и `started_at_game_time`, и Date System запускается заново с тем же venue и нарядом. Выбранное место не пересчитывается после загрузки и не берётся из `GirlDefinition.location_id`.

```text
can_start_date(girl_id) -> bool
get_start_date_failure_reason(girl_id) -> String
get_date_requirements_status(girl_id) -> Array[RequirementStatus]
get_available_date_venues(girl_id) -> Array
is_date_venue_available(girl_id, date_venue_id) -> bool
create_start_date_action(girl_id, date_venue_id, outfit_id) -> GameAction
start_date(girl_id, date_venue_id, outfit_id) -> bool
complete_date(result) -> bool
has_active_date() -> bool
get_active_girl_id() -> StringName
get_active_venue_id() -> StringName
get_active_outfit_id() -> StringName
get_date_cooldown_remaining_minutes(girl_id) -> int
is_date_available_today(girl_id) -> bool
signal date_started(girl_id)
signal date_completed(girl_id, relationship_delta, current_relationship)
```

`get_date_cooldown_remaining_minutes` возвращает минуты до следующего календарного дня, если дневной слот `date:<girl_id>` уже использован.

Свидание доступно, когда одновременно: `discovered`, `has_contact`, бесплатный daily slot `date:<girl_id>` свободен или доступен платный override Риты, линия не завершена, активного свидания нет, и каждый `GirlDefinition.date_requirements.is_met(girl_id)`. Первая причина отказа:

```text
"Вы ещё не знакомы"
"У вас нет контакта этой девушки"
"Сегодня уже встречались. Следующая встреча: завтра."
"Отношения с этой девушкой уже достигли максимума"
"Свидание уже идёт"
"Для этого свидания нужен образ интереснее повседневного."
"<description>: <progress_text>"   # первый невыполненный date_requirement
```

`get_date_requirements_status` — `RequirementStatus` по `date_requirements`. `DateAvailableRequirement` по-прежнему делегирует в `can_start_date` / `get_start_date_failure_reason`.

`get_available_date_venues` — единая точка списка мест для Presentation. Возвращает DateVenues, открытые текущим Story Stage по [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md): Stage 1 — Apartment; Stage 2 — Apartment, Café, Leisure Center; Stage 3+ — плюс Restaurant. Карточка места показывает toolkit: Local Objects и теги их Local Moves, а не quality, не preference score и не автоматическую рекомендацию. Теги окрашиваются знанием текущей девушки тем же `GameTermFormatter`, что чипы «Любит» / «Не любит»: весь `[ИМЯ]`, не только скобки (UNKNOWN — текущий цвет текста, POSITIVE — зелёный, NEGATIVE — красный). Название Local Object остаётся нейтральным. Замок и требование — одна пара: если характеристика не выполнена, рядом с тегом `🔒` и `Требуется: <имя> <нужно> (сейчас <есть>)`, цвет знания тега сохраняется; если выполнена — ни замка, ни текста требования (текущие значения уже в HUD). `is_date_venue_available` истинно только для мест из этого списка. Закрытое DateVenue: «Название 🔒». Stage 1 Apartment показывает пустой Local toolkit (0 Local Moves).

Venue — это toolkit. Место не даёт общего quality/preference score. Наряд остаётся выбранной частью подготовки без универсального `Outfit.score_bonus`.

`create_start_date_action`: `id = start_date_<girl_id>`, `money_cost` 0 плюс опции Express Styling $40 и urgent taxi $75, `time_cost_minutes = 0`, `DateAvailableRequirement(girl_id)` (`bypass_daily_limit` при taxi), `DateVenueAvailableRequirement`, `OutfitOwnedRequirement`, `StartDateEffect` с backup outfit / styling / taxi. Если `outfit_id` пустой, берётся `EquipmentService.get_current_outfit_id()`. Время свидания не входит в action: оно проводится после завершения. Успешный бесплатный старт регистрирует `date:<girl_id>`. Taxi не возвращает бесплатный слот: каждая дополнительная встреча в тот же день стоит отдельные `$75`.

`start_date(girl_id, date_venue_id, outfit_id)` записывает `active_date` (`girl_id`, выбранный `venue_id`, выбранный `outfit_id`, текущее игровое время), передаёт их в `DateSessionConfig` вместе с resolved Local Object IDs места, собирает `DatePlayerSnapshot` из `CharacteristicService` и `ApartmentState.prepared` для свидания в квартире, запускает Date Engine и испускает `date_started`. Date System получает snapshot `GirlProgress` через `GirlsService.fill_date_progress`: `relationship` и уже раскрытые теги предыдущих свиданий. LOCAL ходы оцениваются той же tag-логикой, что BASE и CHARACTERISTIC. При `DateVenue.uses_apartment_preparation` подготовка берётся из `ApartmentState.prepared`.

`DateResult`: `girl_id`, `relationship_delta`, `duration_minutes`, `result_text`. Базовая длительность — `120` игровых минут. Date System передаёт результат, Game Core применяет его.

`complete_date(result)`:

```text
1. Проверить активное свидание и girl_id
2. GirlsService.change_relationship(relationship_delta)
3. GirlsService.apply_date_knowledge из GirlProgress сессии (revealed tags, completed_dates)
4. TimeService.advance_time(duration_minutes)
5. Если место использует подготовку квартиры — Apartment.prepared = false
6. Очистить active_date
7. Испустить date_completed
```

Пауза между обычными свиданиями с конкретной девушкой — Daily Activity Gate `date:<girl_id>`, limit 1, регистрация на успешном старте. На следующем календарном дне снова доступен один бесплатный слот. Date Engine не пишет `GirlState` и не начисляет Rating: знание тегов проходит через `GirlsService.apply_date_knowledge`.

## Rivals / Competitions

Соперники — статический контент плюс runtime-факт знакомства, победы и дневной попытки. Вызов — денежная ставка: `entry_fee` 100 списывается при старте, победа выплачивает 200, поражение оставляет взнос. Story rival (`linked_girl_id != ""`) после победы `defeated = true`, линия вызова завершена, requirement сюжетной девушки выполнен. Filler rival остаётся repeatable после любой попытки; `defeated = true` фиксирует первую победу, но не закрывает реванши. Любая повторяемая попытка (story до первой победы и filler всегда) использует `rival:<rival_id>` с daily limit 1. Неудачная попытка расходует текущий дневной слот. Player-facing: «Сегодня уже была попытка. Следующая попытка: завтра.» Доступность считает только `RivalsService` через Daily Activity Gate.

`RivalDefinition` — статическое game data:

```text
id: StringName
display_name: String
location_id: StringName
linked_girl_id: StringName
competition_ids: Array[StringName]
minimum_story_stage: int = 1
```

`location_id` ссылается на существующую `LocationDefinition`. `linked_girl_id` — сюжетная девушка, после знакомства с которой соперник появляется в мире; у ordinary rivals пустой. `minimum_story_stage` ограничивает gameplay-доступ по Story Stage. `competition_ids` — соревнования с этим соперником.

| id | имя | локация | linked_girl_id | story | соревнование |
|---|---|---|---|---|---|
| `rival_gleb` | Глеб — Турник | `city_center` | — | 1 | `competition_horizontal_bar` (muscle) |
| `rival_max` | Макс — Фотомодель | `cafe` | — | 1 | `competition_photo` (appearance) |
| `rival_boris` | Борис — каскадёр | `city_center` | `girl_actress` | 1 | `competition_casting` (appearance) |
| `rival_denis` | Денис — Криптоэксперт | `cafe` | — | 2 | `competition_crypto` (capital) |
| `rival_roman` | Роман — Ведущий | `restaurant` | — | 2 | `competition_toast` (aura) |
| `rival_foreman` | Аркадий — главный прораб | `restaurant` | `girl_mine_boss` | 2 | `competition_armwrestling` (muscle) |
| `rival_columnist` | Герман — звёздный колумнист | `cafe` | `girl_magazine_editor` | 3 | `competition_taste_debate` (aura) |
| `rival_lev` | Лев — Уличный атлет | `city_center` | — | 3 | `competition_street_athlete` (muscle) |
| `rival_timur` | Тимур — Магнат | `restaurant` | — | 3 | `competition_magnate` (capital) |
| `rival_academic` | Академик Павел | `city_center` | `girl_scientist` | 4 | `competition_grant` (capital) |
| `rival_minister` | Министр Виктор | `restaurant` | `girl_president` | 5 | `competition_protocol_duel` (aura) |

`RivalCatalog`:

```text
get_rival(rival_id) -> RivalDefinition
get_all_rivals() -> Array[RivalDefinition]
get_rivals_for_location(location_id) -> Array[RivalDefinition]
```

`RivalState` — только изменяемое состояние прохождения:

```text
discovered: bool = false
defeated: bool = false
last_challenge_completed_at: int = 0
```

`RivalsState.rivals_by_id`: `rival_id → RivalState`. При первом `RivalsService.get_state` для существующего соперника создаётся стандартный `RivalState` и кладётся в `GameState.rivals.rivals_by_id`. New Game: `rivals_by_id = {}`.

Autoload `RivalsService` — единственная точка discovery и победы. Читает definitions из каталога и пишет `GameState.rivals`.

```text
get_definition(rival_id) -> RivalDefinition
get_state(rival_id) -> RivalState
is_discovered(rival_id) -> bool
is_defeated(rival_id) -> bool
discover_rival(rival_id) -> bool
defeat_rival(rival_id) -> bool
get_rivals_at_current_location() -> Array[RivalDefinition]
get_discovered_rivals() -> Array[RivalDefinition]
create_meet_rival_action(rival_id) -> GameAction
signal rival_discovered(rival_id)
signal rival_defeated(rival_id)
```

`discover_rival`: при первом открытии `discovered = true`, сигнал `rival_discovered`, `true`; повтор — состояние прежнее, `false`. `defeat_rival`: `discovered = true` и `defeated = true`; при первой победе сигнал `rival_defeated` и `true`; повтор — `false`, сигнал не повторяется. `get_rivals_at_current_location` читает `WorldService.get_current_location_id()` и текущий Story Stage, возвращает `RivalDefinition` с тем же `location_id` и `minimum_story_stage <= Story Stage`, у которых `linked_girl_id` пустой или `GirlsService.is_discovered(linked_girl_id)`. До знакомства со связанной девушкой сюжетный соперник не попадает в список. Этот контракт общий для 2D GameSimulator и будущего 3D NPC (`rival_id` → те же `GameAction`).

Встреча — `GameAction` через `RivalsService.create_meet_rival_action`:

```text
id = meet_rival_<rival_id>
time_cost_minutes = 0
money_cost = 0
requirements: RivalNotDiscoveredRequirement, RivalLocationRequirement
effects: DiscoverRivalEffect
```

`CompetitionDefinition` — статическое game data:

```text
id: StringName
display_name: String
rival_id: StringName
time_cost_minutes: int
base_win_chance: float
primary_characteristic_id: StringName
entry_fee: int = 100
```

`base_win_chance` в диапазоне `0.0 ... 1.0`. Seed соревнований:

| id | смысл | rival_id | primary |
|---|---|---|---|
| `competition_casting` | кастинг внешности | `rival_boris` | appearance |
| `competition_armwrestling` | армрестлинг | `rival_foreman` | muscle |
| `competition_taste_debate` | спор о вкусе | `rival_columnist` | aura |
| `competition_grant` | грант | `rival_academic` | capital |
| `competition_protocol_duel` | протокольная дуэль | `rival_minister` | aura |

`CompetitionCatalog`:

```text
get_competition(competition_id) -> CompetitionDefinition
get_competitions_for_rival(rival_id) -> Array[CompetitionDefinition]
```

Связь: `CompetitionDefinition.rival_id` и `RivalDefinition.competition_ids`.

`CompetitionResult`:

```text
rival_id: StringName
competition_id: StringName
won: bool
result_text: String
```

Autoload `CompetitionService`:

```text
can_start_competition(competition_id) -> bool
get_failure_reason(competition_id) -> String
create_competition_action(competition_id) -> GameAction
get_win_chance(competition_id) -> float
resolve_competition(competition_id) -> CompetitionResult
complete_competition(result) -> bool
signal competition_completed(competition_id, rival_id, won)
```

`can_start_competition` проверяет по порядку: definition соревнования, definition соперника, текущая локация совпадает с `RivalDefinition.location_id`, соперник `discovered`, дневной слот `rival:<rival_id>` свободен. Причины:

```text
"Соревнование не найдено"
"Соперник находится в другой локации"
"Вы ещё не встретили этого соперника"
"Соперник ещё не готов к реваншу"
```

`create_competition_action`:

```text
id = competition_<competition_id>
time_cost_minutes = CompetitionDefinition.time_cost_minutes
money_cost = entry_fee
requirements: CompetitionAvailableRequirement
effects: CompetitionEffect
```

Время проводит стандартный `ActionService` → `TimeService.advance_time()`.

`resolve_competition` бросает `get_win_chance(competition_id)`. Presentation и Core используют один метод.

```text
final_win_chance = clamp(base_win_chance + characteristic_bonus, 0.0, 1.0)
characteristic_bonus = CharacteristicService.get_value(primary_characteristic_id) * 0.1
```

Пример: `base_win_chance = 0.5`, `muscle = 2` → шанс `0.7`. При `base_win_chance = 0.8` и `muscle = 5` итог `1.0`. Для автотестов `CompetitionService` принимает фиксированный `won` или контролируемый RNG.

`CompetitionEffect.apply()`: `resolve_competition`, затем `complete_competition`.

`complete_competition(result)`:

```text
1. Проверить CompetitionResult
2. Получить RivalDefinition
3. Если won: RivalsService.defeat_rival(rival_id)
4. Испустить competition_completed
5. Вернуть true
```

При поражении `defeated` остаётся `false`. Награда за победу на этом этапе — сам `defeated`; будущие системы подписываются на `rival_defeated` или идут через Core pipeline.

Будущий 3D Rival NPC несёт `rival_id` и получает данные через `RivalsService`. Взаимодействие запускает те же Meet Rival / Competition `GameAction`, что 2D GameSimulator.

## Game Simulator

Сцена `res://game/simulator/GameSimulator.tscn` — presentation-слой прохождения. Главная сцена проекта. `DateSystemLab` остаётся отдельным dev-инструментом.

```text
GameSimulator
      │
      │ пользователь нажимает кнопку
      ▼
GameAction
      │
      ▼
ActionService
      │
      ├── requirements
      ├── EconomyService
      ├── effects
      └── TimeService
      │
      ▼
GameState
      │
      ▼
GameSimulator.refresh()
```

Autoload `StageService`, `ActionService`, `EconomyService`, `AutomationService`, `PurchaseService`, `CharacteristicService`, `DailyActivityService`, `WorldService`, `GirlsService`, `RatingService`, `DatingService`, `EquipmentService`, `ApartmentService`, `RivalsService`, `CompetitionService`, `SceneTransitionService`, `ObjectiveService` и `GuidanceService` регистрируются в `project.godot`.

Интерфейс — 2D Control, контейнеры и anchors, читаемый в 1280×720 и 1920×1080:

```text
HUD: Day / Time | Money | Rating | Stage | City Stage | Finale | compact characteristics X/5
HUD Objective Panel: текущая сюжетная цель, подцели, следующий шаг
Navigation | Current Section
Action Result / Event Log
```

HUD читает только канонические данные:

```text
TimeService.get_day() / get_hour() / get_minute()
EconomyService.get_money()
RatingService.get_rating()
StageService.get_current_stage()
StageService.is_finale_reached()
CharacteristicService.get_value(muscle / appearance / capital / aura)
```

Пример: `День 3`, `14:30`, `Деньги: 650`, `Rating: 0`, `Stage: 2`, `Город: этап 2/3`, `Мышца: 1/5`. После Finale: `Stage: 6` и `Finale`, плюс presentation-факт `FINALE REACHED`. Навигация и системы остаются доступны.

Разделы навигации: Главная, Работа, Фабрика, Город, Девушки, Соперники, Свидания, Квартира, Одежда, Прокачка. Раздел Фабрика виден только при `AutomationState.unlocked == true`; до Stage 5 его нет в основной навигации. Смена раздела — только presentation: не меняет `GameState`, не двигает время, не является `GameAction`. Распределение клонов на экране Фабрики сразу пишет `work_allocation_percent` через `AutomationService`.

Главная показывает краткое состояние прохождения (`День`, время, `Stage`, деньги, глобальный Rating, охват родного города `completed / total — percent`; после unlock Automation — текущий масштаб фабрики и его процент), кнопку «СОХРАНИТЬ» и последний результат действия. Постоянный блок цели живёт в HUD и читает `ObjectiveService.get_current()`:

```text
ЦЕЛЬ — <objective_title>

<objective_description>

○ / ✓ подцели текущего Stage
Следующий шаг: <next_step_text>
```

Stage 1–5 строят подцели из meet/date requirements сюжетной девушки (current-stage filler MAX, Rating, знакомство, сюжетный соперник, отношения до `relationship_max`). MinStage не показывается: его закрывает сам текущий Stage. На Stage 1–4, пока не выполнены `2 из 3` filler и Rating, текущая цель — «Повышай Рейтинг» / «Заверши отношения с любыми 2 из 3 девушек этого этапа.» На Stage 2, пока нет Dressed Outfit, «Приоденься» является текущей целью, пока не куплена одежда выше Casual. Stage 6 строит подцели из `AutomationService` (охват текущего масштаба, затем расширение). Marker `← ЦЕЛЬ` помечает локацию, девушку, соперника, свидание или Фабрику текущей подцели и не запрещает остальные активности. Game Terms внутри цели, tutorial и milestone остаются глобальными.

`GuidanceService` показывает одно overlay-сообщение за раз: first-use tutorial (`objectives_intro`, `dating_intro`, `local_objects_intro`, `locked_moves_intro`, `rival_intro`, `factory_intro`) и milestone смены Stage. `GuidancePopup` закрывает весь экран dim-слоем и ставит карточку по центру через full-rect anchors (offsets 0); центр держится при 1280×720, 1920×1080 и смене размера окна. История показа — только `GuidanceState`, не игровой прогресс.

После `stage_completed` Action Result / Event Log: «Stage завершён.» После `stage_changed`: «Начат Stage N.» и новая цель. `refresh()` после `stage_changed` / `objective_changed` / закрытия guidance обновляет World / Girls / Rivals / Dating / Progression / Factory — новый unlock из `on_enter_effects` уже виден. После входа в Stage 5 появляется раздел Фабрика: фабрика в другом городе, клоны, один slider Work ↔ Dating, hourly Money и Rating из `AutomationService`, текущий Expansion progress и % / час, кнопка расширения при 100% текущего масштаба, три upgrades и dev «+1 ИГРОВОЙ ЧАС» через `TimeService.advance_time(60)`.

Работа показывает текущую ставку на кнопке: `Работать — 1 ч — +100`, после Mine Boss `+200`. После MAX Оли доступны чекбокс подработки на первой смене и отдельная вторая смена 50% ставки. После успешной работы в этом календарном дне: `Сегодня уже работали.` Календарный день: `day_index = floor(game_time_minutes / 1440)`. Доступность и регистрация — `DailyActivityService` key `work`. Город отображает `WorldState`: текущая локация (`LocationDefinition.display_name`); если это `CITY_ZONE` — связанные `INTERIOR` через `parent_location_id` как кликабельные строки; клик по открытой строке входит в место. Если `INTERIOR` — кнопка «ВЫЙТИ» в родительскую зону. Вход и выход вызывают `WorldService.enter_location` и `refresh()`, без загрузки 3D-сцены и без сдвига времени. Закрытая локация: «Название 🔒», строка `disabled`. В текущей локации блок «ЛЮДИ» показывает `GirlsService.get_girls_at_current_location()` и `RivalsService.get_rivals_at_current_location()`. Незнакомая девушка видна всегда, даже при невыполненном Rating: имя; если `meet_requirements` непустые — блок «Требования для знакомства:» со статусами `✓` / `✗`, description и progress_text; кнопка «ПОЗНАКОМИТЬСЯ» → `create_meet_girl_action` → `ActionService.execute`, `disabled` при `can_meet_girl() == false`. Связанный соперник в «ЛЮДИ» появляется только после знакомства с его `linked_girl_id`. Неоткрытый соперник: имя, кнопка «ВСТРЕТИТЬ» → `create_meet_rival_action` → `ActionService.execute`. После знакомства девушка отображается как знакомая. После встречи соперник отображается как открытый. Успешное знакомство в Action Result: «Вы познакомились с <Имя>.», «Получен контакт.», «Прошло времени: 30 минут.» Dev-блок `WORLD DEV` / «UNLOCK LOCATION» открывает существующую закрытую локацию через `WorldService.unlock_location`. Работа идёт только через `ActionService.execute(action)`. UI деньги, время и локацию не меняет напрямую.

Прокачка показывает четыре характеристики 0–5. Мышца: «Тренажёр 1 — $50 / 60 мин»; после MAX Алины рядом «Тренажёр 2 — $35 / 60 мин». Внешность / Капитал / Аура по-прежнему `$300` мгновенно. На 5/5 — «Максимум». Повышение идёт через `CharacteristicService.create_upgrade_action` → `ActionService.execute` и не зависит от `purchased_ids`.

Раздел Одежда показывает текущий наряд и магазин по Story Stage: Stage 1 — только Casual; Stage 2 stat-only комплекты за 250; Stage 3 тематические Outfit Move за 700; Stage 4 за 1200. Текущая цель Stage 2 «Приоденься» указывает на этот магазин, пока нет Dressed Outfit. Купленные наряды надеваются бесплатно через `EquipmentService.equip_outfit`. Покупка — `create_buy_outfit_action(outfit_id)`. Date System Lab даёт явный selector любого Outfit как dev-инструмент.

Раздел Квартира показывает купленные Apartment Local Objects, Stage cap покрытия (`0 / 4 / 8 / 12`) и карточки доступных objects. Stage 1: пустой Local toolkit. После MAX Кати — выбор `Акцент интерьера`. Там же игровое действие `skip_to_08_00`: кнопка «Пропустить до 08:00» → `GameActionCatalog.make_skip_to_08_00()` → `ActionService.execute` (`time_cost_minutes` из `TimeService.minutes_until_next_morning`, 0 денег). 12 objects: [`VENUES_AND_LOCAL_OBJECTS.md`](VENUES_AND_LOCAL_OBJECTS.md).

Раздел Девушки показывает `GirlsService.get_discovered_girls()`: имя, «Отношения: N / MAX», «Контакт: Да / Нет». Если есть `date_requirements` — блок «Требования для свидания:» со статусами. При максимуме: «Отношения: 10 / 10 — МАКСИМУМ» для обычных и ранних сюжетных; «Отношения: 15 / 15 — МАКСИМУМ» для Учёной и Президента. Незнакомые девушки в этот список не входят — они появляются в мире через локацию.

Раздел Соперники показывает `RivalsService.get_discovered_rivals()`: имя, локация, «Статус: Не побеждён» / «Статус: Побеждён». Неоткрытые соперники в этот список не входят. Блок «СОРЕВНОВАНИЯ» показывает каждую `CompetitionDefinition`: название, время, характеристику, «Шанс победы: N%», `Взнос 100 -> Победа 200`. Story rival до первой победы: кнопка `Вызвать`, если дневной `rival:<id>` свободен; иначе «Сегодня уже была попытка. Следующая попытка: завтра.» После победы: `Побеждён`, линия завершена. Filler rival: `Вызвать` / `Реванш` с тем же дневным лимитом. UI читает доступность только через `RivalsService.can_challenge_now`. Победа в Action Result: «Победа.», «Соперник <Имя> побеждён.», выплата 200. Поражение: «Поражение.»; у filler — «<Имя> остаётся доступен для реванша.» Поражение — успешное игровое действие: `ActionResult.success = true`.

Раздел Свидания показывает `GirlsService.get_contacted_girls()`. Доступная девушка: имя, отношения `X / MAX`, Trait (название и механическое описание), статусы `date_requirements` (`✓` если все выполнены; иначе заголовок «Требования:» и `✗` с progress), кнопка «ПРИГЛАСИТЬ» (`disabled`, пока `can_start_date() == false`). Приглашение не запускает свидание: оно открывает подготовку. Игрок выбирает Venue и любой купленный Outfit. Экран показывает девушку, отношения, Trait, известные Tags и число неизвестных, Venue, Outfit и четыре итоговые характеристики с уже применённым бонусом одежды (`Внешность: 3 (2 + 1 от одежды)`). Карточка Outfit показывает бонус, открываемый Characteristic Move и Outfit Move. Одежда DatingService больше не берётся молча из текущего слота: `create_start_date_action(girl_id, date_venue_id, outfit_id)` передаёт выбранный наряд, `start_date` экипирует его. Сразу под именем выбранной девушки — Trait и уже открытые предпочтения: «Любит:» известные положительные теги зелёным, «Не любит:» известные отрицательные красным; неизвестные теги не показываются. У каждой строки свой счётчик оставшихся неизвестных этой полярности: «Любит: [теги] (Неизвестно X)», «Не любит: [теги] (Неизвестно Y)». Отдельной строки «Неизвестно N» нет. Для обычной девушки до первого свидания видны два начально известных Tag. Ряд `LabUi.tag_knowledge_row` прижимает теги влево, без растягивания по ширине. Карточка места показывает Trait девушки и toolkit: Local Objects и теги Local Moves через `DatingService.resolve_date_local_object_ids`. Каждый тег окрашивается знанием этой девушки тем же `GameTermFormatter`, что чипы «Любит» / «Не любит» и варианты ходов (весь `[ИМЯ]`); название объекта нейтрально; замок и требование неразлучны: невыполненное даёт `🔒` и `Требуется: <имя> <нужно> (сейчас <есть>)`, выполненное не показывает ни замок, ни текст (значения уже в HUD). Игрок сам сравнивает известные предпочтения с наборами Local Moves: без score, рейтинга, процента совместимости и рекомендации места. Карточка наряда не показывает бонус к свиданию. Обычное открытое место — стандартное оформление. Архитектура UI поддерживает закрытое место: «Название 🔒», кнопка disabled; сейчас список строится только из открытых мест сервиса. Выбор сохраняет presentation-состояние `selected_date_venue_id` и `selected_outfit_id`. После выбора: «Девушка: <имя>», «Место: <название>», «Одежда: <название>», кнопка «НАЧАТЬ СВИДАНИЕ» → `DatingService.create_start_date_action(girl_id, selected_date_venue_id, selected_outfit_id)` → `ActionService.execute`. «НАЗАД» возвращает к списку девушек. После успеха открывается существующий текстовый DatePlayPanel для активной девушки; Dev UI показывает `Active girl`, `Location` и `Outfit`. После итога Date System вызывает `DatingService.complete_date` и возвращает игрока в раздел Свидания. Если дневной слот `date:<girl_id>` уже использован: кнопка disabled, «Сегодня уже встречались. Следующая встреча: завтра.» Награда Риты — срочное такси $75. Завершённая линия: «Линия завершена», без приглашения. При первом достижении максимума Action Result: «ОТНОШЕНИЯ MAX», «Rating +1» и блок персональной filler-награды. До MAX карточка filler-девушки показывает «Награда за MAX»; после получения — «Награда получена». Подготовка свидания может включать Express Styling Киры, urgent taxi Риты и backup Outfit Ники.

Reusable `GameActionButton` получает `GameAction` и показывает label, `money_cost`, `time_cost_minutes`. Кнопка вызывает `ActionService.execute(action)` и возвращает `ActionResult` в `GameSimulator`. Человекочитаемые label живут в presentation-каталоге Simulator: `skip_to_08_00` → Пропустить до 08:00, `test_wait` → Подождать, `test_earn_money` → Работать, `test_spend_money` → Потратить 50. `skip_to_08_00` отображается как обычное игровое действие, не TEST_WAIT.

Успешный `ActionResult`: «Успешно.», полученные эффекты, «Прошло времени: N мин.». Отказ: «Действие недоступно.» и `ActionResult.failure_reason`. Кнопка `disabled`, если `ActionService.can_execute(action)` ложно; причина — `ActionService.get_failure_reason(action)` в `tooltip_text`.

Единый `refresh()` обновляет HUD, текущую секцию, доступность actions и последние отображаемые значения. Вызывается после New Game, Load, `ActionService.action_executed`, `TimeService.time_advanced`, `EconomyService.money_changed`, `RatingService.rating_changed`, `PurchaseService.purchase_completed`, `CharacteristicService.characteristic_changed`, `EquipmentService.outfit_equipped`, `StageService.stage_progress_changed`, `StageService.stage_completed`, `StageService.stage_changed`, `StageService.finale_reached`, `WorldService.location_changed`, `WorldService.location_unlocked`, `WorldService.city_stage_changed`, `GirlsService.girl_discovered`, `GirlsService.girl_contact_received`, `GirlsService.girl_relationship_changed`, `GirlsService.girl_relationship_completed`, `GirlsService.girl_access_changed`, `DatingService.date_started`, `DatingService.date_completed`, `RivalsService.rival_discovered`, `RivalsService.rival_defeated`, `CompetitionService.competition_completed`, `AutomationService.automation_unlocked`, `AutomationService.clones_changed`, `AutomationService.allocation_changed`, `AutomationService.production_changed`, `AutomationService.upgrade_purchased`, `AutomationService.expansion_changed`. Simulator не хранит копии игровых значений: всегда читает сервисы и `GameState`. Factory slider меняет только `work_allocation_percent` и пересчитывает displayed rates без полного rebuild.

Управление сохранением через `SaveManager`: «НОВАЯ ИГРА» → `new_game()`; «СОХРАНИТЬ» → `save_game()` и сообщение «Игра сохранена.»; «ЗАГРУЗИТЬ» доступна при `has_save()` → `load_game()`; «УДАЛИТЬ СОХРАНЕНИЕ» → `delete_save()`. После New Game HUD: Day 1, 00:00, Money 0, Rating 0, Stage 1.

Временный dev-control «ЗАВЕРШИТЬ ТЕКУЩИЙ STAGE» вызывает `StageService.force_complete_current_stage_for_dev()` и визуально отделён от игровых действий. Stage 1–5 переходят без проверки цели; на Stage 6 включает Finale. Обычное прохождение Stage 1–5 идёт через `try_complete_current_stage()` после MAX отношений сюжетной девушки.

## Будущие эпизоды и действия

`DateSituation`: `text_presentation`, `custom_episode_scene`, `custom_logic_script`. Сейчас используется text.

`DateEpisodeController` API:

```text
setup(date_context, situation)
start_episode()
signal move_selected(move_id)
signal episode_presentation_finished
```

`DateMove`: `custom_action_scene`, `custom_action_script` для будущих анимаций, mini-game и scripted sequence. BASE/CHARACTERISTIC/OUTFIT/LOCAL берут Tag из `fixed_tag_id`.

## Resources

Поля сущностей:

- `DateTag`: id, display_name, description, enabled
- `DateMove`: id, display_name, description, kind, enabled, unlock_requirement, max_uses_per_date, fixed_tag_id, fixed_option_text, fixed_positive_result_text, fixed_negative_result_text, custom_action_scene, custom_action_script
- `DateSituation`: id, display_name, description, situation_text, enabled, allowed_phases, allowed_venue_ids, allowed_girl_ids, weight, base_move_ids, custom_episode_scene, custom_logic_script
- `GirlDifficultyPreset`: id, display_name, description, enabled, positive_tag_count, sort_order. Seed: starter 6, early 5, mid 4, late 3, elite 2.
- `GirlProfile`: id, display_name, description, enabled, difficulty_preset_id, trait_id, positive_tag_ids, initial_known_tag_count, portrait, future_character_scene. Редактор выбирает Difficulty, положительные Tags, Trait и число начально известных Tags. Отрицательные предпочтения — вычисляемое дополнение к активным Tags. Требуемое число positive = `GirlDifficultyPreset.positive_tag_count`. Seed: 17 профилей с id как у `GirlCatalog`; обычные MAX 10, сюжетные MAX 15.
- `GirlTrait`: id, display_name, description, enabled, kind (CHARACTERISTIC / VENUE), characteristic_id, date_venue_id
- `DateLocalObject`: id, display_name, description, enabled, move_ids (kind LOCAL), future_visual_scene
- `DateVenue`: id, display_name, description, enabled, min_story_stage, uses_apartment_preparation, local_object_ids, future_location_scene
- `Outfit`: id, display_name, description, enabled, price, stat_id, stat_bonus, min_story_stage, tier (0 Casual / 1 Dressed), outfit_move_id, future_visual_resource
- `CharacteristicDefinition`: id, display_name, description, min_level, max_level
- `UnlockRequirement`: stat_id, required_level
- `DateRules`: см. seed-параметры ниже
- `DateContentCatalog`: tags, moves, situations, girls, girl_difficulty_presets, traits, local_objects, date_venues, outfits, characteristics, date_rules

Enums:

- `DateMoveKind`: BASE, CHARACTERISTIC, OUTFIT, LOCAL
- `DateMoveSource`: CHARACTERISTIC, OUTFIT, VENUE
- `DatePhase`: OPENING, CORE, CLOSING

Characteristic, Outfit, Local и BASE читают `fixed_tag_id`, `fixed_option_text`, `fixed_positive_result_text`, `fixed_negative_result_text`. Место не имеет quality/preference score.

`DateContentCatalog` канонические операции: `find_situation`, `find_move`, `enabled_situations()`, `base_moves_for_situation(situation_id)`, `eligible_situations(phase, venue_id, girl_id)`. `base_moves_for_situation` возвращает шесть `DateMove` в authored order до RNG shuffle. `eligible_situations` применяет `enabled`, `allowed_phases`, `allowed_venue_ids` (`[]` = любое место), `allowed_girl_ids` (`[]` = любая девушка). Snapshot — manual shallow-copy Resource containers.

## DateRules seed

```text
opening_episode_count = 1
core_episode_count = 3
closing_episode_count = 1
base_moves_per_episode = 3
allow_situation_repeats = false
positive_move_score = 1
negative_move_score = -1
reveal_tag_after_use = true
combo_required_distinct_success_tags = 3
combo_bonus_score = 1
combo_max_rewards_per_date = 1
apartment_unprepared_penalty = -1
min_distinct_base_tags_per_situation = 6
```

Количество положительных тегов — свойство конкретной девушки через `GirlDifficultyPreset`, не глобальное DateRules.

Все параметры свидания редактируются в «ПРАВИЛА СВИДАНИЯ». Difficulty presets — в «СЛОЖНОСТЬ ДЕВУШЕК».

## Runtime

`GirlProgress`: girl_id, relationship, revealed_positive_tag_ids, revealed_negative_tag_ids, completed_dates, last_date_situation_ids.

После reload Content Catalog runtime progress нормализуется: известные `tag_id` из обоих revealed-списков оставляются только если Tag активен, затем заново раскладываются по актуальному GirlProfile. Новые Tags (`care`, `humor`, `composure`, `cunning` при расширении набора) начинаются как `UNKNOWN`.

`DatePlayerSnapshot`: muscle, appearance, capital, aura, apartment_prepared.

`DateSession`: session_id, seed, girl_id, venue_id, outfit_id, local_object_ids, used_local_object_ids, used_base_move_ids, characteristic_source_used, outfit_source_used, venue_source_used, relationship_before, selected_situation_ids, current_phase, current_episode_index, current_candidate_base_move_ids, current_selected_base_move_ids, current_reroll_base_move_ids, current_selected_base_tag_ids, episode_history, revealed_tags_during_session, combo_distinct_success_tag_ids, combo_achieved, combo_rewards_earned, score_breakdown, relationship_after, completed.

Каждая DateSession создаёт deterministic RNG из seed. При одинаковых seed, GirlProgress snapshot, DatePlayerSnapshot и DateContent snapshot воспроизводятся Situations, BASE Moves и порядок BASE Moves.

## Date Engine API

```text
create_date_session(config)
get_session_state()
get_current_episode()
get_available_moves()
choose_move(move_id)
advance()
get_result()
abort()
```

Сигналы: `date_started`, `episode_started`, `move_selected`, `tag_revealed`, `relationship_changed`, `combo_achieved`, `date_completed`, `relationship_max_reached`.

## Flow свидания

OPENING 1 → CORE 3 → CLOSING 1 → RESULT.

Situations выбираются по `enabled`, `allowed_phases`, `allowed_venue_ids`, `allowed_girl_ids`, `weight` и seed. Сначала preferred pool — eligible Situations текущей фазы, которых ещё нет в `selected_situation_ids` и нет в `GirlProgress.last_date_situation_ids`. Если preferred пуст, используется reuse pool остальных eligible этой фазы. Внутри текущего Date Situation уникальна. После завершения Date `last_date_situation_ids` записывает пять `selected_situation_ids`.

В каждом эпизоде six-move set делится на `3 shown + 3 reroll`. OPENING, CORE и CLOSING дают `+1` / `-1` по предпочтению девушки. После Closing:

```text
Combo + Unprepared Apartment
= Final Date Score → изменение отношений
```

Место не имеет общей строки бонуса. Неподготовленная квартира: `Неподготовленная квартира  -1`. Подготовленная квартира: `0`, отдельной строки нет. Одежда не даёт очков к итогу, только `EffectiveStat` и при наличии Outfit Move. Combo учитывает OPENING/CORE/CLOSING и любой выбранный ход при `score_delta > 0`; outfit и apartment не входят в chain. Награда максимум один раз за свидание.

## Раскрытие Tags

UNKNOWN / POSITIVE / NEGATIVE. UI: жирный `[ТЕГ]` без символа замка; известный положительный — зелёный, известный отрицательный — красный, неизвестный — нейтральный. Единый helper — `LabUi` плюс глобальный Game Terms renderer. Первое использование +1 → POSITIVE, -1 → NEGATIVE. Знание хранится в GirlProgress.

После каждого изменения revealed knowledge выполняется одна нормализация. Если `revealed_positive_count == positive_tag_ids.size()`, все оставшиеся unknown становятся revealed negative. Если `revealed_negative_count == active_tag_count - positive_count`, все оставшиеся unknown становятся revealed positive. Путь один: знакомство, ход свидания, ретро-награда Евы и любое другое production-раскрытие. Результат пишется в обычные `revealed_positive_tag_ids` / `revealed_negative_tag_ids`.

LOCKED и USED ходы имеют один disabled-стиль; причина текстом внутри блока. Символ `🔒` в player-facing BASE-ходах отсутствует; в Characteristic Source locked-строка использует `🔒` и `требуется ур. N`.

Базовое стартовое количество известных Tags хранится только в `GirlProfile.initial_known_tag_count` (обычные / filler 2, сюжетные 0). Ева добавляет `+1`.

Во время свидания сверху фиксировано: `Отношения на начало свидания: N / MAX`, `До максимума: K`, Trait, затем постоянный preference-блок `LabUi.known_preference_block` (`Любит:` / `Не любит:` и `(Неизвестно X)` / `(Неизвестно Y)`). Блок виден во всех пяти эпизодах и обновляется сразу после раскрытия Tag. Компактный Combo: `КОМБО: 0 / 3`, затем теги chain, затем `КОМБО: ПОЛУЧЕНО +1`.

Player-facing текст проходит через глобальный `GameTerm` renderer: жирное выделение, tooltip из `GameTermRegistry` (DateTag, CharacteristicDefinition, DateLocalObject и системные термины вроде Рейтинг / Отношения / Комбо / Этап города / Одежда). Текстовые aliases — `display_name` и явно заданные `aliases`; внутренний `id` только идентифицирует GameTerm и в тексте не ищется. Совпадение принимается только на границах слова: символы слева и справа отсутствуют либо не буква, не цифра и не `_` (Unicode/кириллица). Тег в квадратных скобках `[ИМЯ]` выделяется целиком. Если aliases пересекаются, побеждает самый длинный. Недоступные ходы не используют символ замка.

## Combo

Универсальное правило для каждой девушки: три последовательных успешных хода с тремя разными тегами дают `Combo +1`.

На успешном эпизоде тег добавляется в `combo_distinct_success_tag_ids`; повтор тега оставляет уникальный успешный хвост после предыдущего появления этого тега. Неудача очищает chain. После первой награды `combo_achieved = true`. `DateScoreBreakdown.combo_score` входит в total вместе с Girl Trait и apartment preparation. Relationship Gain = `max(total, 0)`.

## Seed Local Objects

Local Object IDs уникальны per-venue. Public Venue: 2 Local Moves / 2 unique Tags. Apartment: 1 Object = 1 Move = 1 Tag. Полные тексты: [`VENUES_AND_LOCAL_OBJECTS.md`](VENUES_AND_LOCAL_OBJECTS.md).

| id | имя | venue | ходы | req |
|---|---|---|---|---|
| cafe__barista | Бариста | cafe | `lady_first` УЧТИВОСТЬ; `best_item` ПРЯМОТА | — |
| cafe__board_games | Настольные игры | cafe | `set_trap` ХИТРОСТЬ; `ridiculous_game` ЮМОР | — |
| cafe__window | Окно | cafe | `fresh_air` ЗАБОТА; `open_to_street` НАГЛОСТЬ | — |
| leisure_center__claw_machine | Автомат-хватайка | leisure_center | `get_toy` ЗАБОТА; `study_mechanism` ХИТРОСТЬ | — |
| leisure_center__racing_arcade | Гоночный автомат | leisure_center | `max_difficulty` РИСК; `winner_wish` НАГЛОСТЬ | — |
| leisure_center__air_hockey | Аэрохоккей | leisure_center | `play_seriously` ДОМИНИРОВАНИЕ; `world_final` ЮМОР | — |
| leisure_center__prize_counter | Стойка призов | leisure_center | `gift_prize` ЩЕДРОСТЬ; `giant_trophy` СТАТУС | — |
| restaurant__waiter | Официант | restaurant | `lady_first` УЧТИВОСТЬ; `set_service_order` ДОМИНИРОВАНИЕ | appearance 1 / muscle 3 |
| restaurant__tasting_set | Дегустационный сет | restaurant | `signature_set` СТАТУС; `trust_the_chef` СПОКОЙСТВИЕ | capital 3 / aura 3 |
| restaurant__live_music | Живая музыка | restaurant | `dedication` ЛЕСТЬ; `tip_performance` ЩЕДРОСТЬ | appearance 3 / capital 1 |
| restaurant__open_kitchen | Открытая кухня | restaurant | `adjust_for_her` ЗАБОТА; `ask_chef` ПРЯМОТА | aura 1 / muscle 1 |
| apartment__plaid | Плед | apartment | `get_comfortable` ЗАБОТА | Stage 2, $150 |
| apartment__tv | Телевизор | apartment | `ridiculous_show` ЮМОР | Stage 2, $200 |
| apartment__record_player | Проигрыватель | apartment | `quiet_music` СПОКОЙСТВИЕ | Stage 2, $250 |
| apartment__no_filter_cards | Карточки «Без фильтров» | apartment | `honest_question` ПРЯМОТА | Stage 2, $300 |
| apartment__tea_set | Чайный сервиз | apartment | `serve_tea` УЧТИВОСТЬ | Stage 3, $400 |
| apartment__mini_fridge | Мини-холодильник | apartment | `best_stock` ЩЕДРОСТЬ | Stage 3, $475 |
| apartment__large_mirror | Большое зеркало | apartment | `compliment_reflection` ЛЕСТЬ | Stage 3, $550 |
| apartment__collection_display | Витрина коллекции | apartment | `show_centerpiece` СТАТУС | Stage 3, $625 |
| apartment__karaoke | Караоке | apartment | `sing_first` НАГЛОСТЬ | Stage 4, $750 |
| apartment__game_console | Игровая консоль | apartment | `no_mercy` ДОМИНИРОВАНИЕ | Stage 4, $850 |
| apartment__darts | Дартс | apartment | `hard_throw` РИСК | Stage 4, $950 |
| apartment__chess_table | Шахматный столик | apartment | `prepared_trap` ХИТРОСТЬ | Stage 4, $1100 |

Move ID = `<object_id>__<action_id>`. Apartment Venue `local_object_ids` пустой: покрытие только из купленных Apartment Objects. Reward Кати — `Акцент интерьера`, не предмет каталога.

## Seed Locations

Venue — toolkit. Игровая ценность места = набор Local Objects. DateVenue availability по Stage: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md). Production catalog содержит ровно четыре DateVenue.

| id | имя | enabled | DateVenue Stage | цена | объекты | квартира |
|---|---|---|---|---:|---|---|
| apartment | Квартира | true | 1 | 0 | 0 на старте; 12 purchasable objects | preparation |
| cafe | Кафе | true | 2 | 20 | barista, board_games, window (6 Tags) | нет |
| leisure_center | Центр досуга | true | 2 | 40 | claw_machine, racing_arcade, air_hockey, prize_counter (8 Tags) | нет |
| restaurant | Ресторан | true | 3 | 60 | waiter, tasting_set, live_music, open_kitchen (8 Tags, Characteristic gates) | нет |

## Seed Outfits

13 Outfit. `casual` с начала, `tier = 0`, без бонуса и без Outfit Move. Outfit как build-layer — Stage 2; Outfit Moves — Stage 3.

Stage 2, цена 250, `tier = 1`, только `+1`: `sport` мышца, `stylish` внешность, `business` капитал, `minimal_black` аура.

Stage 3, цена 700, `tier = 1`, `+1` и Outfit Move: `wrestling`, `magician`, `luxury`, `leather_jacket`.

Stage 4, цена 1200, `tier = 1`, `+1` и Outfit Move: `stunt`, `model`, `philanthropist`, `black_turtleneck`.

## Seed Stats

muscle Мышца 0..5; appearance Внешность 0..5; capital Капитал 0..5; aura Аура 0..5.

## Seed Tags

12 активных Tags:

| id | имя | смысл |
|---|---|---|
| politeness | УЧТИВОСТЬ | Вежливость, уважение, мягкая поддержка. |
| directness | ПРЯМОЛИНЕЙНОСТЬ | Прямая речь без украшений. |
| flattery | ПОДХАЛИМАЖ | Угодливая похвала и сглаживание. |
| audacity | НАГЛОСТЬ | Колкость, дерзость, провокация. |
| dominance | ДОМИНИРОВАНИЕ | Контроль ситуации и давления. |
| risk | АЗАРТ | Готовность к риску и пари. |
| generosity | ЩЕДРОСТЬ | Деньги и материальная помощь. |
| status | СТАТУС | Демонстрация положения и ресурсов. |
| care | ЗАБОТА | Внимание к комфорту, состоянию и интересам другого человека. |
| humor | ЮМОР | Реакция через шутку, иронию или превращение ситуации в комедию. |
| composure | САМООБЛАДАНИЕ | Спокойствие, выдержка и отсутствие суеты под давлением ситуации. |
| cunning | ХИТРОСТЬ | Решение ситуации через обходной ход, проверку условий или использование правил в свою пользу. |

## Girl Difficulty

Количество положительных тегов — главный параметр сложности девушки. Диапазон отношений — отдельное независимое измерение.

```text
Tag Difficulty     → насколько трудно получить +1 в эпизоде из BASE
Relationship Range → сколько суммарного прогресса нужно до максимума
```

Seed presets при 12 активных Tags и `base_moves_per_episode = 3`. Теоретическая доступность хотя бы одного positive среди трёх разных BASE Tags в равномерном пуле из 12:

| id | имя | positive | negative | теоретическая доступность |
|---|---|---|---|---|
| wide | Широкая | 8 | 4 | 98.2% |
| easy | Лёгкая | 7 | 5 | 95.5% |
| starter | Стартовая | 6 | 6 | 90.9% |
| early | Ранняя | 5 | 7 | 84.1% |
| mid | Средняя | 4 | 8 | 74.5% |
| late | Поздняя | 3 | 9 | 61.8% |
| elite | Элитная | 2 | 10 | 45.5% |

Формула UI: `1 − C(enabled − positive, base_moves) / C(enabled, base_moves)`. Обновляется при изменении числа активных Tags, `positive_tag_count` и `base_moves_per_episode`.

Балансировочный принцип:

```text
WIDE     8  онбординг Dating Core, почти всегда есть +1 в BASE
EASY     7  ранний City Stage, всё ещё очень дружелюбный набор
STARTER  6  герой почти без прокачки
EARLY    5  первые Открываемые ходы
MID      4  заметная роль билда, места и одежды
LATE     3  развитый набор Открываемых ходов
ELITE    2  поздняя прокачка + сильная подготовка
```

Authored-набор использует канонические максимумы отношений: обычные `0..10`; Actress / Mine Boss / Magazine Editor `0..10`; Scientist / President `0..15`. Сложность задаётся только числом положительных Tags.

AVAILABLE CHARACTERISTIC по-прежнему резервируют Tag и расширяют покрытие: для STARTER BASE почти всегда даёт хороший вариант; для LATE/ELITE арсенал становится основным способом стабильно находить +1.

## Seed Girls

Authored-набор Date Lab совпадает с `GirlCatalog`: 17 профилей, `GirlProfile.id == GirlDefinition.id`, старт отношений `0`. У каждого профиля есть difficulty preset, positive tags, ровно один Trait и `initial_known_tag_count` (2 у обычных, 0 у сюжетных). Negative Tags — вычисляемое дополнение. Предпочтений места и наряда кроме Trait нет.

Алина `alina`: filler City Stage 1, `city_center`. Difficulty `wide`. Trait Домоседка. Positive: politeness, directness, care, generosity, composure, humor, risk, dominance. Тренер городского спортзала. Награда MAX: `alina_improved_gym`. Первая полноценная девушка: 8/12.

Вика `vika`: filler City Stage 1, `cafe`. Difficulty `easy`. Trait Ценит внешность. Positive: audacity, dominance, risk, humor, cunning, directness, care. Бариста Café. Награда MAX: `vika_base_reroll`.

Даша `dasha`: filler City Stage 1, `cafe`. Difficulty `starter`. Trait Любит сильных. Positive: audacity, risk, humor, dominance, politeness, composure. Менеджер клиентского сервиса. Награда MAX: `dasha_soften_negative`.

Марина `marina`: filler City Stage 2 / Story Stage 2, `clothing_store`. Difficulty `easy`. Trait Чувствует ауру. Positive: care, composure, directness, humor, politeness, flattery, status. Продавец магазина одежды. Casual exception: свидания доступны в Повседневном. Награда MAX: `marina_free_outfit`. Optional soft onboarding path Outfit system.

Катя `katya`: filler City Stage 2, `furniture_store`. Trait Любит кафе. Продавец мебельного магазина. Date eligibility: Outfit выше Casual (`tier >= 1`). Награда MAX: `katya_interior_accent`.

Лера `lera`: filler City Stage 2, `cafe`. Trait Любит рестораны. Клининговый сервис. Date eligibility: Outfit выше Casual. Награда MAX: `lera_apartment_cleaning`.

Оля `olya`: filler City Stage 2, `restaurant`. Trait Любит обеспеченных. Positive: generosity, status, care, politeness. Предпринимательница. Date eligibility: Outfit выше Casual. Награда MAX: `olya_overtime`.

Кира `kira`: filler City Stage 2, `cafe`. Trait Любит сильных. Стилист. Date eligibility: Outfit выше Casual. Награда MAX: `kira_express_styling`.

Соня `sonya`: filler City Stage 3, `city_center`. Trait Домоседка. VIP-менеджер Restaurant. Date eligibility: Outfit выше Casual. Награда MAX: `sonya_restaurant_second_venue`.

Ника `nika`: filler City Stage 3, `cafe`. Trait Чувствует ауру. Positive: cunning, directness, audacity, composure. Директор магазина одежды. Date eligibility: Outfit выше Casual. Награда MAX: `nika_backup_outfit`.

Рита `rita`: filler City Stage 3, `restaurant`. Trait Любит обеспеченных. Positive: status, dominance, generosity, risk. Организатор мероприятий. Date eligibility: Outfit выше Casual. Награда MAX: `rita_urgent_taxi`.

Ева `eva`: filler City Stage 3, `restaurant`. Trait Любит рестораны. Рекрутер / интервьюер. Date eligibility: Outfit выше Casual. Награда MAX: `eva_read_people`.

Актриса `girl_actress`: `city_center`, Stage 1 + Rating 2, соперник `rival_boris`. Trait Ценит внешность. `relationship_max = 10`. Начально известных Tags нет. City Stage 2 после MAX.

Начальница шахты `girl_mine_boss`: `restaurant`, Stage 2 + Rating 5, соперник `rival_foreman`. Trait Любит рестораны. `relationship_max = 10`. Начально известных Tags нет. Date eligibility: Outfit выше Casual. Мировая локация ресторана открыта с Stage 2; DateVenue Restaurant — с Stage 3. После MAX работа 200/ч.

Редактор журнала `girl_magazine_editor`: `cafe`, Stage 3 + Rating 8 + 2 of 3 Stage 3 filler, соперник `rival_columnist`. Trait Чувствует ауру. `relationship_max = 10`. Начально известных Tags нет. Date eligibility: Outfit выше Casual. City Stage остаётся 2 до MAX; City Stage 3 после входа в Stage 4.

Учёная `girl_scientist`: `city_center`, Stage 4 + Rating 11 + 2 of 3 Stage 4 filler, соперник `rival_academic`. Trait Любит кафе. `relationship_max = 15`. Начально известных Tags нет. Date eligibility: Outfit выше Casual. Factory открывается на Stage 5 после её MAX.

Президент `girl_president`: `restaurant`, Stage 5 + Rating 12, соперник `rival_minister`. Trait Любит обеспеченных. `relationship_max = 15`. Начально известных Tags нет. Date eligibility: Outfit выше Casual.

Ручная прогрессия без DEV: New Game Rating 0, Story Stage 1 / City Stage 1 → две filler Stage 1 → Actress MAX (Stage 2, City Stage 2, Café/Leisure DateVenues, Clothing Store, objective «Приоденься») → две filler Stage 2 / Марина в Casual → MineBoss MAX (Stage 3, City Stage 2, Restaurant DateVenue, Outfit Moves, работа 200) → две filler Stage 3 → Editor MAX (Stage 4, City Stage 3, 12-Tag Apartment cap) → две filler Stage 4 → Scientist MAX (Stage 5, Factory, Rating 12) → President MAX (Stage 6). Optional третья filler каждого Stage и Factory Rating дают surplus. Filler не завершают Stage. Factory не закрывает охват родного города. Roster: [`STORY_STAGE_PROGRESSION.md`](STORY_STAGE_PROGRESSION.md). High-level contract: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).

## Seed Situations

Первый canonical baseline Date Content:

```text
30 baseline Situations
180 BASE Moves
6 BASE на Situation
6 distinct Tags на Situation
15 BASE occurrences каждого Tag во всём baseline pool
```

Формула пула: `6 OPENING / 18 CORE / 6 CLOSING`. Свидание собирает `1 Opening + 3 Core + 1 Closing`. Все Situations: `enabled = true`, `weight = 1.0`, `allowed_girl_ids = []`. Public-only (`allowed_venue_ids = cafe, leisure_center, restaurant`): `stranger_flirts`, `small_rule`, `staff_conflict`, `mistaken_married`, `lost_wallet`. Остальные — любой DateVenue.

| id | phase | display_name | venue |
|---|---|---|---|
| `appearance_question` | OPENING | Ты не такой, как я представляла | любой |
| `awkward_silence` | OPENING | Пауза затянулась | любой |
| `why_me` | OPENING | Почему именно я? | любой |
| `first_compliment` | OPENING | Она делает первый комплимент | любой |
| `phone_reminder` | OPENING | Телефон сдаёт тебя с потрохами | любой |
| `takes_control` | OPENING | Она берёт всё на себя | любой |
| `money_request` | CORE | Кто платит? | любой |
| `spontaneous_bet` | CORE | Спонтанное пари | любой |
| `rival_provocation` | CORE | Провокация соперника | любой |
| `terrible_joke` | CORE | Ужасная шутка | любой |
| `embarrassing_hobby` | CORE | Стыдное увлечение | любой |
| `stranger_flirts` | CORE | К ней подкатывает другой | cafe, restaurant |
| `small_rule` | CORE | Маленькое нарушение | cafe, restaurant |
| `small_lie` | CORE | Маленькая ложь | любой |
| `friends_dilemma` | CORE | Чужая проблема | любой |
| `staff_conflict` | CORE | Она спорит с персоналом | cafe, restaurant |
| `compatibility_test` | CORE | Тест на совместимость | любой |
| `lost_in_hand` | CORE | Потерянная вещь | любой |
| `mistaken_married` | CORE | Вас приняли за супругов | cafe, restaurant |
| `take_photo` | CORE | Сфоткаемся? | любой |
| `big_money` | CORE | Большие деньги | любой |
| `choose_for_me` | CORE | Выбери за меня | любой |
| `friend_call` | CORE | Звонит её подруга | любой |
| `lights_out` | CORE | Выключается свет | любой |
| `date_verdict` | CLOSING | Ну и как тебе вечер? | любой |
| `see_again` | CLOSING | Увидимся ещё? | любой |
| `honest_question` | CLOSING | Один честный вопрос | любой |
| `lost_wallet` | CLOSING | Чужой кошелёк | cafe, restaurant |
| `simple_goodbye` | CLOSING | Просто «пока» | любой |
| `sudden_rain` | CLOSING | Начинается дождь | любой |

Три authored-слоя через фильтры: general (`[]` / `[]`), venue-specific, girl-specific. Все слои используют один Date Engine. Option texts и Situation texts живут в `DateSituation` / `DateMove` resources.

## Seed BASE Moves

Каждый BASE принадлежит одной Situation. ID: `<situation_id>__<action_id>`. Display name совпадает с `fixed_option_text`. Positive/negative result texts задаются каноническим шаблоном Tag:

| Tag | Positive result | Negative result |
|---|---|---|
| `politeness` | Ей нравится твоя корректность. | Ей кажется, что ты слишком церемонишься. |
| `directness` | Прямота ей нравится. | Прямота кажется ей грубой. |
| `care` | Она ценит заботу. | Забота кажется ей лишней. |
| `generosity` | Щедрый жест ей нравится. | Она воспринимает щедрость как лишнее давление. |
| `composure` | Спокойствие ей нравится. | Спокойствие кажется ей безразличием. |
| `humor` | Она смеётся — шутка попала в её вкус. | Шутка ей не заходит. |
| `audacity` | Наглость её цепляет. | Наглость её раздражает. |
| `dominance` | Уверенный контроль ей нравится. | Ей не нравится, что ты командуешь. |
| `risk` | Ей нравится готовность рискнуть. | Она считает риск лишним. |
| `cunning` | Она оценивает находчивость. | Хитрость ей не нравится. |
| `flattery` | Лесть попадает в цель. | Лесть кажется ей натянутой. |
| `status` | Демонстрация статуса производит впечатление. | Пафос её раздражает. |

Каждый из 12 Tags встречается в BASE-пуле ровно 15 раз. Шесть distinct BASE Tags на каждую Situation — инвариант validator.

## Seed Characteristic Moves

12 ходов, kind `CHARACTERISTIC`, фиксированный Tag, требования `EffectiveStat` 1/3/5.

| id | характеристика | уровень | Tag | имя |
|---|---|---:|---|---|
| char_say_plain | muscle | 1 | directness | Сказать по-простому |
| char_stress_test | muscle | 3 | risk | Проверить на прочность |
| char_force_argument | muscle | 5 | dominance | Силовой аргумент |
| char_gallantry | appearance | 1 | politeness | Включить галантность |
| char_polished_compliment | appearance | 3 | flattery | Красиво подать комплимент |
| char_play_with_looks | appearance | 5 | audacity | Сыграть внешностью |
| char_cover_expenses | capital | 1 | generosity | Взять расходы на себя |
| char_propose_scheme | capital | 3 | cunning | Предложить схему |
| char_status_solve | capital | 5 | status | Решить вопрос статусом |
| char_support_mode | aura | 1 | care | Включить поддержку |
| char_joke_relief | aura | 3 | humor | Разрядить шуткой |
| char_hold_pause | aura | 5 | composure | Выдержать паузу |

Окно Characteristic Source показывает эти 12 ходов четырьмя группами в порядке Мышца / Внешность / Капитал / Аура; внутри группы ур. 1, 3, 5. Заголовок: `МЫШЦА — ур. N` с breakdown modifiers и cap 5. Trait-бонус характеристики — одна строка в соответствующей группе: `Особенность девушки: +1 к результату ходов <Характеристики>`. Доступный ход: `[ЛЕСТЬ] Красиво подать комплимент · ур. 3`. Locked: `🔒 [НАГЛОСТЬ] Сыграть внешностью · требуется ур. 5`. Цвета known-positive / unknown / known-negative сохраняются.

## Seed LOCAL Moves

kind = LOCAL, `max_uses_per_date = 1`. `fixed_option_text` хранит только действие; UI собирает `[ТЕГ] Объект: действие`. Полные positive/negative texts: [`VENUES_AND_LOCAL_OBJECTS.md`](VENUES_AND_LOCAL_OBJECTS.md).

| id | объект | tag | option | req |
|---|---|---|---|---|
| cafe__barista__lady_first | cafe__barista | politeness | Попросить сначала принять заказ девушки | — |
| cafe__barista__best_item | cafe__barista | directness | Спросить, что здесь реально самое вкусное | — |
| cafe__board_games__set_trap | cafe__board_games | cunning | Выбрать игру и быстро заманить её в ловушку | — |
| cafe__board_games__ridiculous_game | cafe__board_games | humor | Взять самую нелепую игру и начать до чтения правил | — |
| cafe__window__fresh_air | cafe__window | care | Слегка приоткрыть окно, заметив, что ей душно | — |
| cafe__window__open_to_street | cafe__window | audacity | Распахнуть окно и продолжить разговор будто теперь участвует вся улица | — |
| leisure_center__claw_machine__get_toy | leisure_center__claw_machine | care | Попытаться достать игрушку, которая ей понравилась | — |
| leisure_center__claw_machine__study_mechanism | leisure_center__claw_machine | cunning | Изучить механизм и выбрать лучший момент для захвата | — |
| leisure_center__racing_arcade__max_difficulty | leisure_center__racing_arcade | risk | Выбрать максимальную сложность и отключить помощь | — |
| leisure_center__racing_arcade__winner_wish | leisure_center__racing_arcade | audacity | Предложить маленькое желание победителю | — |
| leisure_center__air_hockey__play_seriously | leisure_center__air_hockey | dominance | Играть всерьёз и вообще не поддаваться | — |
| leisure_center__air_hockey__world_final | leisure_center__air_hockey | humor | Комментировать матч будто идёт финал чемпионата мира | — |
| leisure_center__prize_counter__gift_prize | leisure_center__prize_counter | generosity | Потратить выигранные жетоны на приз для неё | — |
| leisure_center__prize_counter__giant_trophy | leisure_center__prize_counter | status | Забрать самый огромный приз и нести его как трофей | — |
| restaurant__waiter__lady_first | restaurant__waiter | politeness | Попросить сначала обслужить девушку | appearance 1 |
| restaurant__waiter__set_service_order | restaurant__waiter | dominance | Взять организацию заказа на себя и задать порядок подачи | muscle 3 |
| restaurant__tasting_set__signature_set | restaurant__tasting_set | status | Заказать фирменный сет ресторана как очевидный выбор | capital 3 |
| restaurant__tasting_set__trust_the_chef | restaurant__tasting_set | composure | Довериться выбору шефа и спокойно ждать сюрприз | aura 3 |
| restaurant__live_music__dedication | restaurant__live_music | flattery | Попросить музыканта посвятить ей композицию | appearance 3 |
| restaurant__live_music__tip_performance | restaurant__live_music | generosity | Хорошо отблагодарить музыканта за отдельное исполнение | capital 1 |
| restaurant__open_kitchen__adjust_for_her | restaurant__open_kitchen | care | Попросить изменить блюдо с учётом её вкусов | aura 1 |
| restaurant__open_kitchen__ask_chef | restaurant__open_kitchen | directness | Спросить шефа напрямую, что он сам здесь заказал бы | muscle 1 |
| apartment__plaid__get_comfortable | apartment__plaid | care | Предложить ей плед и устроиться поудобнее | — |
| apartment__tv__ridiculous_show | apartment__tv | humor | Включить что-нибудь настолько нелепое, что это уже интересно | — |
| apartment__record_player__quiet_music | apartment__record_player | composure | Поставить спокойную музыку и позволить паузе просто существовать | — |
| apartment__no_filter_cards__honest_question | apartment__no_filter_cards | directness | Вытянуть вопрос и ответить без ухода от темы | — |
| apartment__tea_set__serve_tea | apartment__tea_set | politeness | Нормально сервировать чай вместо случайной кружки | — |
| apartment__mini_fridge__best_stock | apartment__mini_fridge | generosity | Достать лучший запас специально для неё | — |
| apartment__large_mirror__compliment_reflection | apartment__large_mirror | flattery | Подвести её к зеркалу и красиво отметить, как она выглядит | — |
| apartment__collection_display__show_centerpiece | apartment__collection_display | status | Показать самый впечатляющий предмет своей коллекции | — |
| apartment__karaoke__sing_first | apartment__karaoke | audacity | Первым начать петь, не проверяя, насколько это хорошая идея | — |
| apartment__game_console__no_mercy | apartment__game_console | dominance | Запустить соревнование и предупредить, что поддаваться не будешь | — |
| apartment__darts__hard_throw | apartment__darts | risk | Предложить усложнённый бросок с небольшой ставкой | — |
| apartment__chess_table__prepared_trap | apartment__chess_table | cunning | Быстро устроить позицию с заранее подготовленной ловушкой | — |

## Developer Room

Сцена `res://date_system/dev_room/DateSystemLab.tscn` (Control). Это dev-инструмент Date System, не игровая оболочка прохождения. Игровой 2D-проход Game Core — `GameSimulator`.

Разделы: СВИДАНИЕ, ДЕВУШКИ, СЛОЖНОСТЬ ДЕВУШЕК, ТЕГИ, БАЗОВЫЕ ХОДЫ, ХОДЫ ХАРАКТЕРИСТИК, ХОДЫ ОДЕЖДЫ, СИТУАЦИИ, МЕСТА, ЛОКАЛЬНЫЕ ОБЪЕКТЫ, ЛОКАЛЬНЫЕ ХОДЫ, НАРЯДЫ, ХАРАКТЕРИСТИКИ, ПРАВИЛА СВИДАНИЯ, БАЛАНС, ТЕСТОВОЕ СОСТОЯНИЕ, ВАЛИДАЦИЯ.

Шапка: GAME TIME (`Day`, `Time`, `Absolute`) из `TimeService`, CAMPAIGN (`Stage`, `Finale`) из `StageService`, `money` из `GameState`, кнопки «Новая игра», «Сохранить», «Загрузить», тестовые действия `+30 MIN` / `+120 MIN` / `+1 DAY` через `GameAction.time_cost_minutes` и `COMPLETE CURRENT STAGE` через `StageService.force_complete_current_stage_for_dev()`. Блок GAME ACTIONS запускает definitions каталога через `ActionService.execute`: `WAIT +120 MIN`, `EARN 100`, `SPEND 50`, `REQUIRE 100`; после попытки обновляет money, game time и показывает `ActionResult` (`SUCCESS` / `FAILED`). Экран СВИДАНИЕ показывает день, часы, `stage` и `money`, итоговые характеристики с бонусом одежды, открытые Characteristic Moves и Outfit Move. ТЕСТОВОЕ СОСТОЯНИЕ редактирует BaseStat 0..5, любой Outfit, показывает EffectiveStat, открытые Characteristic Moves, Outfit Move и даёт восстановить/потратить три source-use. Кампанию в лаборатории двигает только `force_complete_current_stage_for_dev()`, без свободного SpinBox Stage.

Редактор: список, поиск, создать, дублировать, редактировать, удалить, сохранить, отменить. Draft-копия Resource. Save: validate → `.tres` → catalog reload → статус. Удаление показывает зависимости.

«СЛОЖНОСТЬ ДЕВУШЕК»: поля ID, Название, Описание, Enabled, Количество положительных тегов (SpinBox 1 .. enabled_tags−1), Порядок. В списке: `Название | Positive | Negative`.

«ДЕВУШКИ»: selector Сложность (enabled presets), Trait, число начально известных Tags, рядом `Положительных тегов требуется: N` / `Отрицательных тегов: enabled−N` и теоретическая доступность. Таблица `TAG | НРАВИТСЯ | НЕ НРАВИТСЯ`: редактируются только positive tags, столбец «не нравится» — вычисляемое дополнение. Счётчик `Положительные теги: current / required`. В списке девушек видно Trait. N ≠ required → ERROR валидации.

«МЕСТА»: `local_object_ids` выбранной DateVenue. Production DateVenues: apartment (Stage 1), cafe и leisure_center (Stage 2), restaurant (Stage 3). Local Objects: [`VENUES_AND_LOCAL_OBJECTS.md`](VENUES_AND_LOCAL_OBJECTS.md).

«СИТУАЦИИ»: ID, Display Name, Situation Text, Enabled, Allowed Phases, Allowed Venue IDs, Allowed Girl IDs, Weight, шесть BASE (Move ID, Tag, Option, Positive/Negative Result).

«БАЛАНС»: по каждой девушке Girl, Difficulty, Positive Tags / 12, Relationship Max, Trait, Initial Known Tags, Theoretical positive availability. Кнопка «СИМУЛИРОВАТЬ BASE» (10000 seeds, stats на минимуме, CHARACTERISTIC unavailable): по Situation и aggregate — доля эпизодов с хотя бы одним positive BASE, доля all-negative, средний positive BASE count. Фактические проценты считаются по situation-owned BASE (`base_move_ids`).

Экран СВИДАНИЕ позволяет выбрать любую из 30 Situations по ID, girl, DateVenue, увидеть eligible pool, `last_date_situation_ids`, six authored BASE (Move ID, Tag, Option, Positive/Negative Result) и seeded split `3 shown + 3 reroll`, нажать Vika reroll. Public-only Situation запускается production Date Engine с подходящим DateVenue.

После save новый DateSession берёт новые данные. Запущенная сессия работает на snapshot.

## Validator

1. уникальные IDs  
2. references существуют  
3. у GirlProfile authored-предпочтения только `positive_tag_ids`; остальные активные Tags автоматически negative  
4. enabled Situation: `base_move_ids.size() == 6`, IDs уникальны, все Moves существуют / enabled / kind BASE  
5. шесть `fixed_tag_id` заполнены, существуют в Tag catalog и различны; option/positive/negative texts заполнены  
6. каждый BASE Move authored catalog referenced ровно одной DateSituation  
7. `allowed_venue_ids` / `allowed_girl_ids` ссылаются на существующие DateVenue / GirlProfile  
8. Characteristic Move имеет UnlockRequirement на 1/3/5 и постоянный Tag через `fixed_*`; ровно 12 ходов покрывают 12 Tags  
16. два Characteristic Move с одним Tag → ERROR `CHARACTERISTIC_TAG_DUPLICATE`
17. `GirlProfile.difficulty_preset_id` не резолвится в enabled preset → ERROR `INVALID_GIRL_DIFFICULTY_REFERENCE`
18. `girl.positive_tag_ids.size() != difficulty.positive_tag_count` → ERROR `INVALID_POSITIVE_TAG_COUNT`
19. повторы или неизвестные id в `positive_tag_ids` → ERROR `INCOMPLETE_GIRL_TAG_COVERAGE`
20. enabled preset: `1 <= positive_tag_count < enabled_tags.size()` иначе ERROR `INVALID_DIFFICULTY_POSITIVE_COUNT`
21. активный DateTag без BASE/CHARACTERISTIC/OUTFIT/LOCAL Move с этим Tag → WARNING `TAG_WITHOUT_MOVE_MAPPING`
22. distinct BASE Tags ситуации ≠ 6 → ERROR six-tag invariant
23. enabled Situations = 30 с фазами `6 OPENING / 18 CORE / 6 CLOSING` → иначе ERROR
24. situation-owned BASE count ≠ 180 → ERROR
25. каждый enabled DateTag встречается в BASE-пуле не ровно 15 раз → ERROR

Экран: severity, code, resource_type, resource_id, field, message. Кнопка «ПРОВЕРИТЬ ВЕСЬ КОНТЕНТ». ERROR блокирует сохранение; WARNING только показывает проблему.

## UI свидания

Запуск: девушка, место, наряд, квартира (если location uses apartment), тестовые статы, seed. Кнопки: НАЧАТЬ НОВОЕ СВИДАНИЕ, ПОВТОРИТЬ ПОСЛЕДНИЙ SEED, СБРОСИТЬ ПРОГРЕСС ДЕВУШКИ, СБРОСИТЬ ВЕСЬ ТЕСТОВЫЙ ПРОГРЕСС.

Эпизод: фаза, номер, Situation, BASE×3 и кнопки источников `[ХАРАКТЕРИСТИКА] [ОДЕЖДА] [ЛОКАЦИЯ]`. В верхней информационной части постоянно видны Relationship, Trait и `LabUi.known_preference_block`; блок обновляется после раскрытия Tags. Цвет источника — зелёный / серый / красный по известным Tags девушки; заблокированный неиспользованный источник нейтральный; использованный погашен, tooltip `Уже использовано на этом свидании.` Characteristic Source сгруппирован по Мышца / Внешность / Капитал / Аура. Внутри списка видны и доступные, и закрытые ходы. После выбора: ход, tag, реакция, score, новое знание, ПРОДОЛЖИТЬ.

Debug-панель эпизода дополнительно показывает source-used флаги, six BASE, selected_base_moves, reroll_base_moves и selected_base_tags.

Result: построчный итог, строки появляются быстро одна за другой. Сначала `[ТЕГ] +1` / `[ТЕГ] -1` по эпизодам, включая OPENING. Затем Combo, особенность девушки, при неподготовленной квартире строка `Неподготовленная квартира  -1`. Далее `Итог свидания: N` (сырой итог), `Прогресс отношений: +N` (`max(raw, 0)`), `Отношения: X / MAX`. Без эпизодной статистики и без debug-панели.

Replay восстанавливает snapshot девушки до сессии и тот же seed: те же Situations, BASE selection и порядок.

Сброс девушки: relationship `0`, пустые revealed tags, completed_dates=0. Начально известные Tags снова читаются из профиля.

Карточка девушки: имя; Сложность; Положительных тегов N/12; Trait; Теоретическая базовая доступность; Отношения current/max; известные «Любит:» / «Не любит:» через `LabUi.known_preference_block` (включая начально известные Tags и счётчики «(Неизвестно X)» / «(Неизвестно Y)» по полярности).

Debug-панель свёрнута по умолчанию.

UI: контейнеры, anchors, scroll, split, навигация, 1280×720 и 1920×1080.

## Автотесты

Кейсы Dating Core: 17 девушек в `GirlCatalog` и Date Content, обычные MAX 10 / Actress-MineBoss-Editor MAX 10 / Scientist-President MAX 15, старт отношений 0, Gain = max(raw, 0), начально известные Tags обычных и полностью UNKNOWN сюжетных, Trait характеристики и места, Combo, квартира 0/−1, `raise_stakes` при Капитал 5, полный цикл пяти эпизодов без `outfit_score`. Плюс резервирование CHARACTERISTIC Tags, 12 Tags, Girl Difficulty presets (WIDE/EASY/STARTER..ELITE), Алина WIDE 8, Марина/Вика EASY 7, Даша STARTER 6, 17 authored-профилей с preset/positives/Trait и без leftover tags, теоретическая вероятность без Monte Carlo, persist/reload GirlProfile, смена difficulty, runtime-нормализация знания и дедукция оставшихся Tags, 10000-seed баланс равномерного пула для 6/5/4/3/2 positive, round-trip `GameState` save/load (`game_time_minutes` / `stage` / `finale_reached` / `money` / `purchased_ids` / `current_location_id` / `unlocked_location_ids` / `girls_by_id` и наличие всех секций), миграция `save_version` 1 `flow.day` → `game_time_minutes`, миграция `save_version` 2 без `finale_reached` → `false`, миграция без `progression.purchased_ids` → `[]`, миграция без world-полей → стартовый `WorldState`, миграция без `girls.girls_by_id` → `{}`, старт/внутри дня/переход суток/`advance_time` больших интервалов, save/load абсолютного времени и событие `time_advanced`, New Game Stage 1, `GirlRelationshipRequirement` (relationship 3/5 → `is_met == false`; 5/5 → `true`), автоматический переход Stage при MAX сюжетной девушки и отсутствие перехода при MAX другой девушки, `UnlockLocationStageEffect` при входе в следующий Stage, порядок `stage_completed` → on_enter_effects → `stage_changed`, `reconcile_stage_entry_state()` для уже достигнутых Stage и повторная идемпотентность, save/load прогресса текущего `StageRequirement` из `GirlState.relationship`, Stage 6 с `WorldReachRequirement` (без WORLD 100% — `can_complete` / `try_complete` = false; WORLD 100% на Stage 6 → Finale; WORLD 100% до MAX Президента остаётся Stage 5, затем переход 5→6 сразу даёт Finale), успешное `try_complete` на LAST_STAGE с выполненным test requirement → `stage == 6` / `finale_reached` / сигналы `stage_completed(6)` и `finale_reached()` без Stage 7, `StageCatalog` берёт `GirlRelationshipRequirement.target_relationship` из `GirlDefinition.relationship_max`, Finale через `force_complete_current_stage_for_dev()`, полный проход Stage 1–5 → 6 через MAX сюжетных девушек, высокий Rating не завершает Stage пока relationship сюжетной девушки < MAX, `GirlAccessRequirement` (`RatingGirlRequirement` 3/5 → unmet, 5/5 → met; `RivalDefeatedGirlRequirement` до/после `defeat_rival`; `MinStageGirlRequirement` stage 2/3/4), несколько `meet_requirements` (Stage выполнен / Rating нет → `can_meet_girl` false, затем true), атомарность Meet Girl при невыполненном requirement, `DatingService.can_start_date` с `RivalDefeatedGirlRequirement`, save_version не растёт — requirements не сериализуются и после load считаются из GameState, pipeline `ActionService` (`test_wait` / `test_earn_money` / `test_spend_money` / `MoneyRequirement` / полный cost+effect+time / атомарность отказа / `action_executed` только при успехе), `EconomyService` (`add_money` / `spend_money` success/fail / `money_changed`), `work_basic` (100 денег / 60 минут, повтор), покупка `basic_upgrade` (нехватка денег / успех / повтор «Уже куплено»), save/load денег и `purchased_ids`, presentation `GameSimulator` (New Game: money 0 / stage 1 / day 1; работа через Simulator → money 100 / 60 мин; навигация не меняет `GameState`; save/load состояния, изменённого через Simulator; Stage через `StageService`; dev Stage через `force_complete_current_stage_for_dev`; Город: текущая локация, вход/выход интерьера без сдвига времени, закрытая локация, dev unlock, люди текущей локации, знакомство), `WorldService` (New Game start location и unlock'и, первый/повторный unlock, `enter_location`, отказ в закрытую, `location_changed` / `location_unlocked`, время не двигается), `LocationRequirement`, save/load локации и unlock'ов, `GirlsService` (default `GirlState`, однократный `discover_girl` / `give_contact` / `change_relationship`, девушки текущей локации), `MEET_GIRL` (успех 30 минут, повтор «Вы уже знакомы», другая локация), `GirlContactRequirement`, `RelationshipRequirement`, `RatingService` (старт 0, +1 при первом максимуме, большой delta даёт +1, повтор не начисляет), `DatingService` (start date success/fail без контакта/daily gate/максимума, выбранный `date_venue_id` пишется в `active_date` и `DateSessionConfig` независимо от `GirlDefinition.location_id`, resolved Local Object IDs preview и сессии совпадают, недоступное место проваливает `DateVenueAvailableRequirement` без активного свидания, complete_date применяет relationship/time, раскрытые теги переходят на следующее свидание, полный цикл до Rating), GameSimulator двухшаговый выбор места по toolkit Local Objects и одежды без score bonus, save/load Rating / daily_activity / знание тегов / завершённой девушки / active_date включая `venue_id`, миграция без `player.rating` → `0`, `RivalsService` (default `RivalState`, однократный `discover_rival` / `defeat_rival`, соперники текущей локации), `MEET_RIVAL`, `CompetitionService` (детерминированный win/loss через action, отказ в другой локации / до discovery / после победы), save/load `rivals_by_id`, миграция без `rivals.rivals_by_id` → `{}`, GameSimulator: встреча соперника, раздел Соперники, бросить вызов, шанс победы из `get_win_chance()`, характеристики / одежда / квартира, выбор outfit перед свиданием, `CharacteristicService` / `EquipmentService` / `ApartmentService` save/load и миграция `save_version` 9 → 10, Automation: Stage 4 MAX Учёной → Stage 5 unlock + 10 клонов, повторный reconcile не добавляет клонов, load v10 Stage 5/6 restore через reconcile, work 10 клонов 40% / 60 мин → 400, dating 100% / 60 мин → +1 Rating, дробный dating progress 1 клон / 1 час → 0.1 Rating fraction, 10 часов → +1 Rating, upgrades +10 клонов / ×1.5 work / ×1.5 dating, CITY 100% → Country за 10 000 с клонами ×10, Country 100% → World за 1 000 000 с клонами ×10, capped expansion при продолжающемся Rating, `advance_time(60)` vs `60 × advance_time(1)`, save_version 11 → 12, миграция 12 → 13 (`apartment.prepared = true`), Local Moves toolkit / OPENING ±1 / USED объекта / upgrade tv / replay, save_version 12 → 13 (`apartment.prepared = true`), Local Moves (toolkit места, OPENING ±1, USED на весь объект, upgrade `tv`, replay snapshot), миграция `completed_auto_dates` в Rating и CITY progress, GameSimulator раздел Фабрика после unlock показывает Rating/hour и экспансию, Home показывает охват родного города 0/17 … 17/17, каталог 17 девушек (`GirlDefinition` ↔ `GirlProfile`, filler по City Stage, сюжетные Rating 2/5/7/10/12), filler-rivals в местах вместе с девушками, реванш на следующий календарный день, restaurant unlock на Stage 2 и City Stage 2/3 через Stage Effects, свидания всех 17, ручная прогрессия Alina/Marina→President без DEV (ветка оставшихся filler и ветка Factory `add_rating(1)`), filler не завершают Stage, `skip_to_08_00` 03:20→08:00 / 07:59→08:00 / 08:00→08:00 следующего дня / 23:30→08:00 следующего дня / `test_wait` +120, label «Пропустить до 08:00», характеристики 0–5, save_version 18, Daily Activity Gate, filler rewards: первое знакомство 2/0 Tags и 3/1 после Евы, retro +1, Dasha 0 затем -1, Vika $25 один раз, Olya $150/120, Sonya два Venue только в Restaurant, Nika swap с сохранением Outfit Source, Rita taxi $75, MAX reward + Rating один раз.
