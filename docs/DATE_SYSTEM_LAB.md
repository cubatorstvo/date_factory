# DATE SYSTEM LAB

Каноническая спецификация текущей `main`. Код должен совпадать с этим документом.

## Назначение

Date System Lab — канон ядра свиданий и комната разработчика.

Текущая `main` разделяет два независимых entry point:

- `GameSimulator` — обычная 2D-версия прохождения поверх Game Core;
- `DateSystemLab` — комната разработчика, редактор контента и тестовая среда Date System.

`GameSimulator` не расширяет `DateSystemLab`. Он только отображает `GameState` и запускает `GameAction` через `ActionService`.

Design-content хранится в `res://`. Runtime-прогресс — в `user://`.

## Ход — DateMove

Одна сущность `DateMove` (Ход). Виды: `BASE` (Базовый ход) и `UNLOCKABLE` (Открываемый ход).

### BASE

- Есть у героя с начала игры.
- Применимость задаётся mapping к Ситуации.
- Базовые ходы дают случайный набор тегов. При одинаковом теге два Хода механически эквивалентны: результат идёт через `Tag → preference девушки → +1/-1`.
- Один BASE может снова появиться в следующих эпизодах того же свидания.
- `max_uses_per_date = 0` означает unlimited.
- Несколько BASE одного Tag для одной Situation допустимы: это текстовые варианты одного механического направления.

### UNLOCKABLE

- Есть требование к характеристике и mappings к Ситуациям.
- Все подходящие текущей Ситуации UNLOCKABLE показываются игроку.
- Открываемые ходы расширяют доступный игроку набор тегов.
- Состояния каждого применимого UNLOCKABLE:
  - `AVAILABLE` — `unlock_requirement` выполнен и `uses < max_uses_per_date`; Tag резервируется для BASE selection.
  - `LOCKED` — требование ещё не выполнено; затемнён, рядом `Requirement: ...`; Tag свободен для BASE.
  - `USED` — `uses >= max_uses_per_date`; затемнён, статус `Уже использован`; Tag свободен для BASE.
- Без слова «ДОСТУПЕН»: доступный Ход выглядит как обычная кнопка.
- Seed: `max_uses_per_date = 1`.

### Формирование вариантов эпизода

Для текущей `DateSituation` Date Engine выполняет строго этот порядок:

```text
1. Получить применимые UNLOCKABLE Moves
2. Определить состояние каждого UNLOCKABLE
3. Зарезервировать Tags доступных UNLOCKABLE
4. Сформировать BASE candidate pool
5. Выбрать BASE Moves с максимальным количеством уникальных Tags
6. Собрать итоговый список вариантов
```

`reserved_unlockable_tags` содержит уникальные `tag_id` всех применимых UNLOCKABLE со статусом `AVAILABLE`.

BASE candidate pool делится так:

```text
preferred_base_candidates  — Tag отсутствует в reserved_unlockable_tags
fallback_base_candidates   — Tag присутствует в reserved_unlockable_tags
```

Число выбранных BASE: `DateRules.base_moves_per_episode` (seed = 3). Выбор через RNG текущей `DateSession`. Порядок:

```text
A. preferred, каждый раз новый Tag относительно уже выбранных BASE
B. оставшиеся preferred
C. fallback, сначала новые Tags относительно уже выбранных BASE
D. оставшиеся fallback
```

Пока `selected_base_moves.size() != base_moves_per_episode`. Сначала покрывается максимум разных Tags, затем повторы как fallback.

Итоговый доступный набор:

```text
уникальные Tags AVAILABLE UNLOCKABLE
+ уникальные Tags BASE
+ повторяющиеся Tags как fallback
```

Пример: AVAILABLE UNLOCKABLE → Tag A, BASE selection берёт B, C, D. Игрок видит BASE B/C/D и UNLOCKABLE A.

LOCKED или USED UNLOCKABLE с Tag A оставляют этот Tag в обычном BASE pool: корректно получить `BASE → Tag A` рядом с затемнённым UNLOCKABLE → Tag A, потому что фактически доступен только BASE.

Несколько AVAILABLE UNLOCKABLE одного Tag резервируют его один раз. Content Validator даёт WARNING `DUPLICATE_UNLOCKABLE_TAG_IN_SITUATION`.

## Формула эпизода

```text
СИТУАЦИЯ → ДОСТУПНЫЕ ХОДЫ → ВЫБОР ХОДА
→ СИТУАЦИЯ + ХОД → КОНТЕКСТНЫЙ ТЕГ
→ ПРЕДПОЧТЕНИЕ ДЕВУШКИ → +1 / -1
```

Тег варианта показывается до выбора. Один DateMove может давать разные Tags в разных Situations. Mapping — источник контекстного смысла.

Opening: score `0`, но Tag раскрывается. Core/Closing: `+1` / `-1`.

## Слои

1. Content Layer — typed Resources.
2. Runtime Progress Layer — канонический `GameState` прохождения (`SaveManager`, JSON `user://saves/game.json`) плюс лабораторный `DateProgressStore` (отношения, известные предпочтения, Secondary, число свиданий, тестовая прокачка, квартира, replay snapshot).
3. Date Engine — DateSession, RNG, эпизоды, BASE/UNLOCKABLE, mappings, Tags, Secondary, location/outfit/apartment scores, итог отношений.
4. Text Date Runner — текстовый 2D DateSession.
5. Game Simulator — 2D presentation прохождения поверх Game Core.
6. Developer Room — редактор Content Layer и запуск runner.

## GameState

Autoload `GameState` — текущее прохождение. Секции: `flow`, `story`, `player`, `progression`, `world`, `girls`, `dating`, `rivals`, `automation`. Каждая секция — отдельный typed-класс с `to_dict()` / `from_dict()`.

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
progression.purchased_ids = []
progression.owned_outfit_ids = [casual]
progression.equipped_outfit_id = casual
progression.apartment.level = 1
progression.apartment.purchased_upgrade_ids = []
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

`game_time_minutes = 0` — Day 1, 00:00. День, час и минута не хранятся: их даёт `TimeService`. Кампания: `stage` — текущая/последняя достигнутая игровая стадия 1–6, `finale_reached` — завершение основной последовательности после Stage 6. Мир: `current_location_id` — семантическое место игрока, `unlocked_location_ids` — открытые `LocationDefinition`. Definitions локаций живут в `LocationCatalog`; `GameState` хранит только ID. Девушки: `GirlState` создаётся при первом обращении (`discovered = false`, `has_contact = false`, `relationship = 0`, `next_date_available_at = 0`, пустые revealed tags, `secondary_revealed = false`, `completed_dates = 0`); definitions живут в `GirlCatalog`. `player.rating` — глобальный Rating прохождения: ручное завершение authored-девушки даёт +1, dating production фабрики начисляет те же целые единицы через `RatingService`. `player.muscle` / `appearance` / `capital` / `aura` — постоянные характеристики прохождения; definitions и цены upgrades живут отдельно. `progression.owned_outfit_ids` / `equipped_outfit_id` — владение и текущий наряд; канонический outfit-контент — Date System `Outfit`. `progression.apartment` — постоянный уровень квартиры прохождения. `dating.active_date` — текущее свидание прохождения (`girl_id`, выбранный `location_id` свидания, выбранный `outfit_id`, `started_at_game_time`) или `{}`. `GirlDefinition.location_id` не является местом свидания. Соперники: `RivalState` создаётся при первом обращении (`discovered = false`, `defeated = false`); definitions живут в `RivalCatalog`.

`automation` — runtime-прогресс фабрики клонов. `rivals` сериализует `rivals_by_id`. Поля читаются через `data.get(key, default)`. Отсутствующие поля `world` восстанавливаются стартовым состоянием нового прохождения. Отсутствующие `girls.girls_by_id` — `{}`. Отсутствующий `player.rating` — `0`. Отсутствующие характеристики игрока — `0`. Отсутствующий `dating.active_date` — `{}`. Отсутствующий `outfit_id` у активного свидания — стартовый `casual`. Отсутствующий `rivals.rivals_by_id` — `{}`. Отсутствующие `owned_outfit_ids` / `equipped_outfit_id` — стартовый `casual`. Отсутствующий `apartment` — уровень 1 и пустой список upgrades. Отсутствующий или пустой `automation` — New Game defaults.

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
  "save_version": 12,
  "game_state": { "flow": { "game_time_minutes": 0 }, "story": { "stage": 1, "finale_reached": false }, "player": { "money": 0, "rating": 0, "muscle": 0, "appearance": 0, "capital": 0, "aura": 0 }, "progression": { "purchased_ids": [], "owned_outfit_ids": ["casual"], "equipped_outfit_id": "casual", "apartment": { "level": 1, "purchased_upgrade_ids": [] } }, "world": { "current_location_id": "city_center", "unlocked_location_ids": ["city_center", "apartment", "cafe"] }, "girls": { "girls_by_id": {} }, "dating": { "active_date": {} }, "rivals": { "rivals_by_id": {} }, "automation": { "unlocked": false, "initial_clones_granted": false, "total_clones": 0, "work_allocation_percent": 50, "work_income_fraction": 0, "dating_progress_fraction": 0, "current_expansion_scope": "city", "expansion_progress": 0, "purchased_upgrade_ids": [] } }
}
```

`new_game()` создаёт новые экземпляры всех секций: `game_time_minutes = 0`, stage 1, `finale_reached = false`, money 0, rating 0, характеристики 0, `purchased_ids = []`, стартовый outfit `casual` owned и equipped, квартира уровня 1, `current_location_id = city_center`, стартовые unlock'и, пустой `girls_by_id`, пустой `dating.active_date`, пустой `rivals_by_id`, Automation закрыта (`unlocked = false`, `total_clones = 0`, `work_allocation_percent = 50`). После `apply_new_game()` вызываются `TimeService.on_playthrough_reset()` и `StageService.reconcile_stage_entry_state()` — Stage 1 становится активным через те же `on_enter_effects`. `load_game()` собирает чистый `GameState` через `from_dict()`, затем снова `TimeService.on_playthrough_reset()` и `StageService.reconcile_stage_entry_state()` для unlock'ов уже достигнутых Stage. Save на Stage 5 или 6 без Automation-прогресса получает unlock и стартовые 10 клонов через существующий reconcile `on_enter_effects` Stage 5. Сохранения `save_version = 1` с `flow.day = N` мигрируют в `game_time_minutes = (N - 1) * 1440`. Сохранения без `story.finale_reached` получают `false`. Сохранения без `progression.purchased_ids` получают `[]`. Сохранения без world-полей получают стартовую локацию и стартовый набор unlock'ов. Сохранения без `girls.girls_by_id` получают `{}`; `GirlState` создаётся defaults при первом обращении. Сохранения без `player.rating` получают `0`. Сохранения без характеристик получают `0`. Сохранения без `dating.active_date` получают `{}`. Сохранения без `outfit_id` у активного свидания получают стартовый `casual`. Сохранения без revealed tags / `secondary_revealed` / `completed_dates` у `GirlState` получают пустые списки, `false` и `0`. Сохранения без `rivals.rivals_by_id` получают `{}`; `RivalState` создаётся defaults при первом обращении. Сохранения без equipment получают стартовый `casual`. Сохранения без `apartment` получают уровень 1 и пустой список upgrades. Сохранения `save_version` 10 без полей Automation получают New Game defaults фабрики. Сохранения `save_version` 11 с `completed_auto_dates` мигрируют в общий Rating и экспансию первого города фабрики: `player.rating += completed_auto_dates`, `dating_progress_fraction` остаётся дробным накоплением следующей единицы Rating, `current_expansion_scope = city`, `expansion_progress = min(completed_auto_dates + dating_progress_fraction, 100)`, после чего `completed_auto_dates` удаляется. Текущий формат — `save_version = 12`. Системы и UI читают время через `TimeService`, кампанию через `StageService`, деньги через `EconomyService`, фабрику через `AutomationService`, характеристики через `CharacteristicService`, одежду через `EquipmentService`, квартиру через `ApartmentService`, Rating через `RatingService`, место через `WorldService`, девушек через `GirlsService`, соперников через `RivalsService`, соревнования через `CompetitionService`, свидания через `DatingService`. Игровые действия изменяют money только через `EconomyService` и время только через `TimeService`; последовательность выполнения остаётся у `ActionService`. Переход между локациями не является `GameAction` и не двигает время. Знакомство с девушкой — `GameAction` и занимает 30 минут. Встреча соперника — `GameAction` с нулевым временем. Соревнование — `GameAction`; длительность берётся из `CompetitionDefinition.time_cost_minutes` и проводится через `TimeService`. Начало свидания — `GameAction` с нулевой стоимостью и нулевым временем; длительность свидания проводится после его завершения. Presentation-слой прохождения — `GameSimulator`.

`DateSession.stage` не является `StoryState.stage`. `DateProgressStore` остаётся прогрессом лаборатории свиданий. `GameState.girls` хранит discovery/contact/relationship/cooldown и знание тегов прохождения. Date Engine в лаборатории читает лабораторный `GirlProgress`; в прохождении канонические `relationship` и revealed tags читаются и пишутся через `GirlsService`, а Date System получает `girl_id` от `DatingService`. Физический мир (`LocationDefinition`) не подменяет `DateLocation`. `GirlDefinition` не подменяет `GirlProfile`.

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
```

Пример: `next_date_available_at = current + days_to_minutes(3)`, проверка `current >= next_date_available_at`.

Real-time progression — управляемый режим того же часов:

```text
real_time_progression_enabled
game_minutes_per_real_second
```

Накопитель дробной части переводит реальное время в целые игровые минуты и вызывает тот же `advance_time()`. Для текущей 2D-игры `real_time_progression_enabled = false`: время двигают действия. Будущий 3D free roam включает режим (`1` реальная секунда = `1` игровая минута при стартовом коэффициенте `1.0`); фиксированные действия по-прежнему идут через `advance_time(action.time_cost_minutes)`.

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

`ActionRequirement`: `is_met() -> bool`, `get_failure_reason() -> String`. Проверяет текущее прохождение. `MoneyRequirement(required_money)`: `EconomyService.can_afford(required_money)`, отказ `"Недостаточно денег"`. `NotPurchasedRequirement(purchase_id)`: `purchase_id` отсутствует в `GameState.progression.purchased_ids`, отказ `"Уже куплено"`. `OutfitNotOwnedRequirement(outfit_id)`: `EquipmentService.owns_outfit(outfit_id) == false`, отказ `"Эта одежда уже куплена"`. `OutfitOwnedRequirement(outfit_id)`: игрок владеет нарядом, отказ `"Эта одежда ещё не куплена"`. `LocationRequirement(required_location_id)`: `WorldService.get_current_location_id() == required_location_id`, отказ `"Действие недоступно в этой локации"`. `GirlMeetAvailableRequirement(girl_id)`: `GirlsService.can_meet_girl(girl_id)`, отказ — `GirlsService.get_meet_failure_reason`. `GirlNotMetRequirement(girl_id)`: девушка ещё не `discovered`, отказ `"Вы уже знакомы"`. `GirlLocationRequirement(girl_id)`: `GirlDefinition.location_id` совпадает с текущей локацией, отказ `"Девушка находится в другой локации"`. `GirlDiscoveredRequirement(girl_id)`: `discovered`, отказ `"Вы ещё не знакомы"`. `GirlContactRequirement(girl_id)`: `has_contact`, отказ `"У вас нет контакта этой девушки"`. `RelationshipRequirement(girl_id, minimum_relationship)`: `relationship >= minimum`, отказ `"Недостаточный уровень отношений"`. `DateAvailableRequirement(girl_id)`: `DatingService.can_start_date(girl_id)`, отказ — первая причина `get_start_date_failure_reason`. `DateLocationAvailableRequirement(girl_id, date_location_id)`: `DatingService.is_date_location_available(girl_id, date_location_id)`, отказ `"Это место сейчас недоступно"`. `RivalLocationRequirement(rival_id)`: `RivalDefinition.location_id` совпадает с текущей локацией, отказ `"Соперник находится в другой локации"`. `RivalNotDiscoveredRequirement(rival_id)`: соперник ещё не `discovered`, отказ `"Вы уже встретили этого соперника"`. `RivalDiscoveredRequirement(rival_id)`: `discovered`, отказ `"Вы ещё не встретили этого соперника"`. `RivalNotDefeatedRequirement(rival_id)`: `defeated == false`, отказ `"Этот соперник уже побеждён"`. `CompetitionAvailableRequirement(competition_id)`: `CompetitionService.can_start_competition(competition_id)`, отказ — `CompetitionService.get_failure_reason`. `AutomationUpgradeNotPurchasedRequirement(upgrade_id)`: upgrade ещё не куплен, отказ `"Уже куплено"`. `FactoryExpansionRequirement(from_scope)`: текущий масштаб фабрики совпадает и coverage 100%, отказ `"Охват текущего масштаба ещё не 100%"` / `"Неверный масштаб фабрики"`.

`ActionEffect`: `apply() -> void`, `get_description() -> String`. `MoneyEffect(amount)`: при `amount > 0` вызывает `EconomyService.add_money(amount)`, при `amount < 0` — `EconomyService.spend_money(-amount)`. `PurchaseEffect(purchase_id)` добавляет ID в `ProgressionState.purchased_ids` не более одного раза. `CharacteristicEffect(characteristic_id, amount)` вызывает `CharacteristicService.add_value`. `OwnOutfitEffect(outfit_id)` добавляет ID в `owned_outfit_ids` один раз. `ApartmentUpgradeEffect(upgrade_id, target_level)` ставит `ApartmentState.level = max(current, target_level)` и фиксирует `upgrade_id` в `purchased_upgrade_ids`. `UnlockLocationEffect(location_id)` вызывает `WorldService.unlock_location(location_id)`. `MeetGirlEffect(girl_id)` вызывает `GirlsService.discover_girl` и `give_contact`. `StartDateEffect(girl_id, date_location_id, outfit_id)` вызывает `DatingService.start_date(girl_id, date_location_id, outfit_id)`. `DiscoverRivalEffect(rival_id)` вызывает `RivalsService.discover_rival(rival_id)`. `CompetitionEffect(competition_id)` вызывает `CompetitionService.resolve_competition` и `complete_competition`. `AutomationUpgradeEffect(upgrade_id)` вызывает `AutomationService.apply_upgrade`. `FactoryExpansionEffect(target_scope)` вызывает `AutomationService.apply_expansion`.

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
| `wait_one_day` | 1440 | 0 | — | — |

`wait_one_day` — обычное действие прохождения «Подождать 1 день» в разделе Квартира Simulator. Не test/dev.

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

Seed: `work_basic` — «Работать», доход 100, 60 минут.

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

Родной город — отдельная вычисляемая статистика, не persistent поле `GameState`. Authored-набор: 10 девушек, все с `GirlDefinition.counts_toward_home_city_coverage = true`. `GirlsService` считает их и завершённые линии (`relationship >= relationship_max`). New Game: 0/10 = 0%. Фабрика не завершает этих девушек. Полный охват родного города не требуется для Finale.

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
```

Seed одноразовых upgrades, цена 300, `amount = 1`:

| id | имя | characteristic_id |
|---|---|---|
| `upgrade_muscle_1` | Тренировка | muscle |
| `upgrade_appearance_1` | Уход за внешностью | appearance |
| `upgrade_capital_1` | Развитие капитала | capital |
| `upgrade_aura_1` | Развитие ауры | aura |

Pipeline: `CharacteristicUpgradeDefinition` → `PurchaseService.create_purchase_action` → `ActionService` → `EconomyService` + `CharacteristicEffect` + `PurchaseEffect`.

## Equipment

Канонический источник нарядов — Date System `Outfit` (`id`, `display_name`, `price`, `score_bonus` и прочие gameplay-поля). Один `outfit_id` для Game Core, GameSimulator, Date System и будущей 3D-презентации. Стартовый наряд — `casual`.

`OutfitCatalog`:

```text
START_OUTFIT_ID = casual
get_outfit(outfit_id)
get_all_outfits()
get_purchasable_outfits()
```

`get_purchasable_outfits` — enabled outfits с `price > 0`. Seed: `casual` цена 0 (старт), `business` 500, `luxury` 800.

`ProgressionState` хранит:

```text
owned_outfit_ids
equipped_outfit_id
```

New Game: owned и equipped — `casual`.

Autoload `EquipmentService`:

```text
owns_outfit(outfit_id) -> bool
get_owned_outfits() -> Array
get_equipped_outfit_id() -> StringName
equip_outfit(outfit_id) -> bool
create_buy_outfit_action(outfit_id) -> GameAction
signal outfit_equipped(previous_outfit_id, current_outfit_id)
```

Покупка: `GameAction` с `money_cost = price`, `OutfitNotOwnedRequirement`, `OwnOutfitEffect`. После успеха ID попадает в `owned_outfit_ids` один раз.

`equip_outfit` проверяет владение, ставит `equipped_outfit_id`, испускает `outfit_equipped`. Экипировка: `time_cost = 0`, `money_cost = 0`, не `GameAction`.

## Apartment

Вложенный `ApartmentState` внутри `ProgressionState`:

```text
level: int = 1
purchased_upgrade_ids
```

`ApartmentUpgradeDefinition`:

```text
id, display_name, description, price, level_granted
```

Seed: `apartment_upgrade_1` — «Улучшить квартиру», цена 500, `level_granted = 2`.

Autoload `ApartmentService`:

```text
get_level() -> int
get_quality() -> int
is_upgrade_purchased(upgrade_id) -> bool
create_upgrade_action(upgrade_id) -> GameAction
```

`get_quality()` — adapter к Date Engine `TestPlayerState.apartment_quality`:

```text
apartment_quality = clamp(level - 1, apartment_quality_min, apartment_quality_max)
```

Уровень 1 → качество 0, уровень 2 → качество 1. Другие `DateLocation` свои параметры не берут из квартиры.

Pipeline: `ApartmentUpgradeDefinition` → `ApartmentService.create_upgrade_action` → `ActionService` → `EconomyService` → `ApartmentUpgradeEffect` → `ApartmentState`. Повтор блокируется проверкой `is_upgrade_purchased`.

## Story / Stages

Кампания — последовательность сюжетных глав. Stage фиксирует итог главы; путь к итогу строят Rating, Rival, Economy, характеристики, одежда и квартира.

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

Идентификаторы восстановлены из канона Legacy V2. Это цели глав внутри authored-набора из 10 девушек родного города; filler (`alina`, `vika`, `katya`, `lera`, `sonya`) главы не завершают.

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

Базовый typed-класс: `apply() -> void`. Реализации: `UnlockLocationStageEffect(location_id)` вызывает `WorldService.unlock_location(location_id)`; `UnlockAutomationStageEffect` открывает фабрику; `GrantInitialClonesStageEffect` один раз выдаёт 10 стартовых клонов.

Будущие типы (`UnlockGirlStageEffect`, `UnlockRivalStageEffect`, `UnlockPurchaseStageEffect`, `UnlockDateLocationStageEffect`, `UnlockSystemStageEffect`) добавляются вместе с persistent unlock соответствующей системы.

Канонические `on_enter_effects` заполняются только уже определёнными в текущем проекте persistent unlock'ами этой главы. Stage 1, 3, 4 и Stage 6: `on_enter_effects = []`. Stage 2: `UnlockLocationStageEffect(restaurant)`. Stage 5: `UnlockAutomationStageEffect`, затем `GrantInitialClonesStageEffect`. `reconcile_stage_entry_state()` восстанавливает `restaurant` для сохранений Stage 2+. Новых мировых локаций нет.

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

После `SaveManager.new_game()` (`stage = 1`) и после `load_game()` `StageService.reconcile_stage_entry_state()` последовательно применяет `on_enter_effects` Stage 1 .. current Stage. Идемпотентность даёт одинаковый мир для старых save без StageDefinition. `TimeService.on_playthrough_reset()` вызывается как раньше.

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

`DateLocation` остаётся местом свидания (скоринг). `LocationDefinition` — физическая локация мира. Одинаковые строковые ID (`apartment`, `cafe`) означают одно и то же место в fiction, но это разные typed Resources.

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
| `cafe` | Кафе | INTERIOR | `city_center` | открыта |
| `restaurant` | Ресторан | INTERIOR | `city_center` | закрыта до Stage 2 |

`START_LOCATION_ID = city_center`. `START_UNLOCKED_LOCATION_IDS = [city_center, apartment, cafe]`. `restaurant` закрыт на Stage 1 и открывается `UnlockLocationStageEffect` при входе в Stage 2 (после MAX Актрисы); там стоят Начальница шахты и Президент. Новых мировых локаций нет.

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

`location_id` ссылается на существующий `LocationDefinition`. Диапазон отношений у всего authored-набора родного города — тот же, что у Date System `GirlProfile`: `-5..+5`. Старт `relationship = 0`. `GirlDefinition.id` совпадает с `GirlProfile.id`.

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
| `MinStageGirlRequirement` | `minimum_stage` | `StageService.get_current_stage() >= minimum_stage` | `"Этап игры"` | `"Stage <current> / <required>"` |

Новые типы (`AuthorityGirlRequirement`, `PurchaseGirlRequirement`, `CharacteristicGirlRequirement`, `StoryFlagGirlRequirement`) добавляют тот же контракт. `GirlsService` и `DatingService` работают только с базовым интерфейсом.

`meet_requirements` — можно ли впервые познакомиться. Девушка в текущей открытой локации видна даже при невыполненном Rating: UI показывает имя и прогресс. `date_requirements` — можно ли назначить следующее свидание после знакомства.

Presentation-элемент `RequirementStatus`: `description`, `progress_text`, `is_met`. Его отдают `GirlsService.get_meet_requirements_status` и `DatingService.get_date_requirements_status`. GameSimulator не знает конкретный класс requirement.

Authored-набор родного города (10 девушек, все `counts_toward_home_city_coverage = true`, все `-5..+5`):

| id | имя | локация | meet_requirements | date_requirements |
|---|---|---|---|---|
| `alina` | Алина | `city_center` | `RatingGirlRequirement(0)` | `[]` |
| `girl_actress` | Актриса | `city_center` | `MinStageGirlRequirement(1)`, `RatingGirlRequirement(1)` | `RivalDefeatedGirlRequirement(rival_boris)` |
| `vika` | Вика | `cafe` | `RatingGirlRequirement(2)` | `[]` |
| `girl_mine_boss` | Начальница шахты | `restaurant` | `MinStageGirlRequirement(2)`, `RatingGirlRequirement(3)` | `RivalDefeatedGirlRequirement(rival_foreman)` |
| `katya` | Катя | `city_center` | `RatingGirlRequirement(4)` | `[]` |
| `girl_magazine_editor` | Редактор журнала | `cafe` | `MinStageGirlRequirement(3)`, `RatingGirlRequirement(5)` | `RivalDefeatedGirlRequirement(rival_columnist)` |
| `lera` | Лера | `city_center` | `RatingGirlRequirement(6)` | `[]` |
| `girl_scientist` | Учёная | `city_center` | `MinStageGirlRequirement(4)`, `RatingGirlRequirement(7)` | `RivalDefeatedGirlRequirement(rival_academic)` |
| `sonya` | Соня | `city_center` | `RatingGirlRequirement(8)` | `[]` |
| `girl_president` | Президент | `restaurant` | `MinStageGirlRequirement(5)`, `RatingGirlRequirement(9)` | `RivalDefeatedGirlRequirement(rival_minister)` |

Filler доступны по Rating без соперника. Сюжетные: знакомство → связанный Rival в той же локации → победа → свидание → MAX → следующий Stage. Каноническая связь `RivalDefinition.linked_girl_id`; сервисы не хардкодят пары. `RivalsService.get_rivals_at_current_location` показывает соперника только если `GirlsService.is_discovered(linked_girl_id)`. Sonya — опциональный ручной Rating 8→9 вместо первого Automation Rating для знакомства с Президентом. Шестого сюжетного Rating-гейта 11 нет. Filler не завершают Stage.

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
next_date_available_at: int = 0
revealed_positive_tag_ids: Array[StringName] = []
revealed_negative_tag_ids: Array[StringName] = []
secondary_revealed: bool = false
completed_dates: int = 0
```

`next_date_available_at` — абсолютные игровые минуты, когда снова можно пригласить эту девушку. `0` означает, что cooldown уже закончен. Раскрытые теги, `secondary_revealed` и `completed_dates` — то же знание, что у Date System `GirlProgress`; definitions тегов живут в Date Catalog. Канонические границы отношений — `GirlDefinition.relationship_min` / `relationship_max` (те же, что у Date System `GirlProfile`: весь authored-набор `-5..+5`). Завершённая линия: `relationship == relationship_max`. Отдельный persistent-флаг завершения не нужен.

`GirlsState.girls_by_id`: `girl_id → GirlState`. При первом `GirlsService.get_state` для существующей девушки создаётся стандартный `GirlState` и кладётся в `GameState.girls.girls_by_id`. New Game: `girls_by_id = {}`.

Autoload `GirlsService` — единственная точка discovery, контакта, relationship, cooldown свиданий и знания тегов прохождения. Читает definitions из каталога и пишет `GameState.girls`.

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
get_next_date_available_at(girl_id) -> int
is_date_cooldown_finished(girl_id) -> bool
set_date_cooldown(girl_id, duration_minutes) -> void
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

`discover_girl`: при первом открытии `discovered = true`, сигнал `girl_discovered`, `true`; повтор — состояние прежнее, `false`. `give_contact`: `discovered = true` и `has_contact = true`; при первом контакте сигнал `girl_contact_received` и `true`. `change_relationship`: если линия уже завершена, `relationship` остаётся `relationship_max` и Rating не начисляется повторно. Иначе `relationship += delta`, clamp в `relationship_min..relationship_max` девушки. Если переход впервые достигает максимума, испускается `girl_relationship_completed` и `RatingService.add_rating(1)`. Затем `girl_relationship_changed`, возврат нового значения. `is_relationship_completed` — каноническая проверка завершённой линии: `get_relationship(girl_id) >= get_relationship_max(girl_id)`. Охват родного города считается из `GirlCatalog` + существующих `GirlState` без persistent `city_coverage` и без создания `GirlState` для нетронутых девушек. `is_date_cooldown_finished`: `TimeService.get_game_time_minutes() >= next_date_available_at`. `fill_date_progress` копирует в snapshot `GirlProgress` канонические `relationship`, revealed tags, `secondary_revealed` и `completed_dates`. `apply_date_knowledge` пишет обратно revealed tags, `secondary_revealed` и `completed_dates`; `relationship` по-прежнему меняет только `change_relationship`.

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

## Dating

Autoload `DatingService` связывает Game Core и существующую Date System. Место знакомства и место свидания независимы:

```text
GirlDefinition.location_id  — где девушка находится в мире
DateLocation                — где проходит выбранное игроком свидание
```

`DatingState.active_date` хранит активное свидание прохождения:

```text
girl_id
location_id
outfit_id
started_at_game_time
```

`location_id` — выбранный игроком `DateLocation`. `outfit_id` — выбранный среди owned outfits. Когда свидания нет, `active_date = {}`. DateSession эпизода — runtime Date Engine; если сессия не сериализуется в JSON, после load восстанавливаются `girl_id`, `location_id`, `outfit_id` и `started_at_game_time`, и Date System запускается заново с тем же venue и нарядом. Выбранное место не пересчитывается после загрузки и не берётся из `GirlDefinition.location_id`.

```text
can_start_date(girl_id) -> bool
get_start_date_failure_reason(girl_id) -> String
get_date_requirements_status(girl_id) -> Array[RequirementStatus]
get_available_date_locations(girl_id) -> Array
is_date_location_available(girl_id, date_location_id) -> bool
is_preferred_date_location(girl_id, date_location_id) -> bool
is_date_location_preference_known(girl_id, date_location_id) -> bool
is_preferred_outfit(girl_id, outfit_id) -> bool
is_outfit_preference_known(girl_id, outfit_id) -> bool
create_start_date_action(girl_id, date_location_id, outfit_id) -> GameAction
start_date(girl_id, date_location_id, outfit_id) -> bool
complete_date(result) -> bool
has_active_date() -> bool
get_active_girl_id() -> StringName
get_active_location_id() -> StringName
get_active_outfit_id() -> StringName
get_date_cooldown_remaining_minutes(girl_id) -> int
signal date_started(girl_id)
signal date_completed(girl_id, relationship_delta, current_relationship)
```

Свидание доступно, когда одновременно: `discovered`, `has_contact`, cooldown закончен, линия не завершена, активного свидания нет, и каждый `GirlDefinition.date_requirements.is_met(girl_id)`. Первая причина отказа:

```text
"Вы ещё не знакомы"
"У вас нет контакта этой девушки"
"До следующего свидания нужно подождать"
"Отношения с этой девушкой уже достигли максимума"
"Свидание уже идёт"
"<description>: <progress_text>"   # первый невыполненный date_requirement
```

`get_date_requirements_status` — `RequirementStatus` по `date_requirements`. `DateAvailableRequirement` по-прежнему делегирует в `can_start_date` / `get_start_date_failure_reason`.

`get_available_date_locations` — единая точка списка мест для Presentation. Сейчас возвращает все enabled `DateLocation` текущей Date System, доступные для обычного использования. Позже сюда подключается фильтрация Story / Stage / World / Progression / первых свиданий / сюжетных событий. `is_date_location_available` истинно только для мест из этого списка.

`is_preferred_date_location` использует ту же каноническую модель, что Date Engine при оценке места: `DateLocation.preference_mode == THEMATIC` и `location_format_id` входит в `GirlProfile.favorite_location_format_ids`. UI не считает предпочтение самостоятельно.

`is_date_location_preference_known` — известна ли игроку эта информация. Сейчас `true` для существующих предпочтений, доступных игроку. Точка будущего discovery (первое свидание, диалог, clue, story, relationship). Зелёная подсветка — Presentation уже известного факта; она не меняет вероятность свидания.

`is_preferred_outfit` читает `GirlProfile.favorite_outfit_ids`. `is_outfit_preference_known` сейчас совпадает с `is_preferred_outfit`. Известный предпочитаемый наряд подсвечивается той же мягкой зелёной логикой, что предпочитаемое место.

`create_start_date_action`: `id = start_date_<girl_id>`, `money_cost = 0`, `time_cost_minutes = 0`, `DateAvailableRequirement(girl_id)`, `DateLocationAvailableRequirement(girl_id, date_location_id)`, `OutfitOwnedRequirement(outfit_id)`, `StartDateEffect(girl_id, date_location_id, outfit_id)`. Если `outfit_id` пустой, берётся `EquipmentService.get_equipped_outfit_id()`. Время свидания не входит в action: оно проводится после завершения.

`start_date(girl_id, date_location_id, outfit_id)` записывает `active_date` (`girl_id`, выбранный `location_id`, выбранный `outfit_id`, текущее игровое время), передаёт их в `DateSessionConfig`, собирает `TestPlayerState` из `CharacteristicService` и `ApartmentService.get_quality()` для свидания в квартире, запускает Date Engine и испускает `date_started`. Date System получает snapshot `GirlProgress` через `GirlsService.fill_date_progress`: `relationship` и уже раскрытые теги предыдущих свиданий. Существующие расчёты location quality / preference / outfit / apartment / tags продолжают работать через Date Engine от выбранного места и наряда. При `DateLocation.uses_apartment_quality` качество берётся из `ApartmentService.get_quality()`, а не из лабораторного слайдера.

`DateResult`: `girl_id`, `relationship_delta`, `duration_minutes`, `result_text`. Базовая длительность — `120` игровых минут. Date System передаёт результат, Game Core применяет его.

`complete_date(result)`:

```text
1. Проверить активное свидание и girl_id
2. GirlsService.change_relationship(relationship_delta)
3. GirlsService.apply_date_knowledge из GirlProgress сессии (revealed tags, secondary, completed_dates)
4. TimeService.advance_time(duration_minutes)
5. set_date_cooldown(days_to_minutes(3))
6. Очистить active_date
7. Испустить date_completed
```

Cooldown 3 игровых дня считается от времени после завершения свидания. Date Engine не пишет `GirlState` и не начисляет Rating: знание тегов проходит через `GirlsService.apply_date_knowledge`.

## Rivals / Competitions

Соперники — статический контент плюс runtime-факт знакомства и победы. Награды за победу подключаются отдельными эффектами позже; этот слой только открывает соперника и фиксирует `defeated`.

`RivalDefinition` — статическое game data:

```text
id: StringName
display_name: String
location_id: StringName
linked_girl_id: StringName
competition_ids: Array[StringName]
```

`location_id` ссылается на существующую `LocationDefinition`. `linked_girl_id` — сюжетная девушка, после знакомства с которой соперник появляется в мире. `competition_ids` — соревнования с этим соперником.

| id | имя | локация | linked_girl_id | соревнование |
|---|---|---|---|---|
| `rival_boris` | Борис — каскадёр | `city_center` | `girl_actress` | `competition_casting` (appearance) |
| `rival_foreman` | Аркадий — главный прораб | `restaurant` | `girl_mine_boss` | `competition_armwrestling` (muscle) |
| `rival_columnist` | Герман — звёздный колумнист | `cafe` | `girl_magazine_editor` | `competition_taste_debate` (aura) |
| `rival_academic` | Академик Павел | `city_center` | `girl_scientist` | `competition_grant` (capital) |
| `rival_minister` | Министр Виктор | `restaurant` | `girl_president` | `competition_protocol_duel` (aura) |

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

`discover_rival`: при первом открытии `discovered = true`, сигнал `rival_discovered`, `true`; повтор — состояние прежнее, `false`. `defeat_rival`: `discovered = true` и `defeated = true`; при первой победе сигнал `rival_defeated` и `true`; повтор — `false`, сигнал не повторяется. `get_rivals_at_current_location` читает `WorldService.get_current_location_id()` и возвращает `RivalDefinition` с тем же `location_id`, у которых `linked_girl_id` пустой или `GirlsService.is_discovered(linked_girl_id)`. До знакомства со связанной девушкой соперник не попадает в список, даже если игрок стоит в его локации. Этот контракт общий для 2D GameSimulator и будущего 3D NPC (`rival_id` → те же `GameAction`).

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

`can_start_competition` проверяет по порядку: definition соревнования, definition соперника, текущая локация совпадает с `RivalDefinition.location_id`, соперник `discovered`, соперник ещё не `defeated`. Причины:

```text
"Соревнование не найдено"
"Соперник находится в другой локации"
"Вы ещё не встретили этого соперника"
"Этот соперник уже побеждён"
```

`create_competition_action`:

```text
id = competition_<competition_id>
time_cost_minutes = CompetitionDefinition.time_cost_minutes
money_cost = 0
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

Autoload `StageService`, `ActionService`, `EconomyService`, `AutomationService`, `PurchaseService`, `CharacteristicService`, `WorldService`, `GirlsService`, `RatingService`, `DatingService`, `EquipmentService`, `ApartmentService`, `RivalsService`, `CompetitionService` и `SceneTransitionService` регистрируются в `project.godot` как `/root/StageService`, `/root/ActionService`, `/root/EconomyService`, `/root/AutomationService`, `/root/PurchaseService`, `/root/CharacteristicService`, `/root/WorldService`, `/root/GirlsService`, `/root/RatingService`, `/root/DatingService`, `/root/EquipmentService`, `/root/ApartmentService`, `/root/RivalsService`, `/root/CompetitionService` и `/root/SceneTransitionService`.

Интерфейс — 2D Control, контейнеры и anchors, читаемый в 1280×720 и 1920×1080:

```text
HUD: Day / Time | Money | Rating | Stage | Finale | compact characteristics
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

Пример: `День 3`, `14:30`, `Деньги: 650`, `Rating: 0`, `Stage: 2`, `Мышца: 1`. После Finale: `Stage: 6` и `Finale`, плюс presentation-факт `FINALE REACHED`. Навигация и системы остаются доступны.

Разделы навигации: Главная, Работа, Фабрика, Город, Девушки, Соперники, Свидания, Квартира, Одежда, Прокачка. Раздел Фабрика виден только при `AutomationState.unlocked == true`; до Stage 5 его нет в основной навигации. Смена раздела — только presentation: не меняет `GameState`, не двигает время, не является `GameAction`. Распределение клонов на экране Фабрики сразу пишет `work_allocation_percent` через `AutomationService`.

Главная показывает краткое состояние прохождения (`День`, время, `Stage`, деньги, глобальный Rating, охват родного города `completed / total — percent`; после unlock Automation — текущий масштаб фабрики и его процент), блок текущей сюжетной цели, кнопку «СОХРАНИТЬ» и последний результат действия.

Блок цели читает `StageService.get_current_definition()` и `get_current_requirement()`:

```text
STAGE N

ЦЕЛЬ

<описание цели из requirement.get_description()>

current / target
```

Для Stage 6: «STAGE 6», «Мировой охват», текущий мировой progress / 10 000. После `stage_completed` Action Result / Event Log: «Stage завершён.» После `stage_changed`: «Начат Stage N.» и новая цель. `refresh()` после `stage_changed` обновляет World / Girls / Rivals / Dating / Progression / Factory — новый unlock из `on_enter_effects` уже виден. После входа в Stage 5 появляется раздел Фабрика: фабрика в другом городе, клоны, один slider Work ↔ Dating, hourly Money и Rating из `AutomationService`, текущий Expansion progress и % / час, кнопка расширения при 100% текущего масштаба, три upgrades и dev «+1 ИГРОВОЙ ЧАС» через `TimeService.advance_time(60)`.

Работа показывает `work_basic`: название «Работать», доход 100, время 60 минут, кнопка «РАБОТАТЬ». Пока игрок работает, клоны продолжают производство за те же игровые минуты. Город отображает `WorldState`: текущая локация (`LocationDefinition.display_name`); если это `CITY_ZONE` — связанные `INTERIOR` через `parent_location_id` с кнопкой «ВОЙТИ»; если `INTERIOR` — кнопка «ВЫЙТИ» в родительскую зону. Вход и выход вызывают `WorldService.enter_location` и `refresh()`, без загрузки 3D-сцены и без сдвига времени. Закрытая локация: «Название 🔒», кнопка входа `disabled`. В текущей локации блок «ЛЮДИ» показывает `GirlsService.get_girls_at_current_location()` и `RivalsService.get_rivals_at_current_location()`. Незнакомая девушка видна всегда, даже при невыполненном Rating: имя; если `meet_requirements` непустые — блок «Требования для знакомства:» со статусами `✓` / `✗`, description и progress_text; кнопка «ПОЗНАКОМИТЬСЯ» → `create_meet_girl_action` → `ActionService.execute`, `disabled` при `can_meet_girl() == false`. Связанный соперник в «ЛЮДИ» появляется только после знакомства с его `linked_girl_id`. Неоткрытый соперник: имя, кнопка «ВСТРЕТИТЬ» → `create_meet_rival_action` → `ActionService.execute`. После знакомства девушка отображается как знакомая. После встречи соперник отображается как открытый. Успешное знакомство в Action Result: «Вы познакомились с <Имя>.», «Получен контакт.», «Прошло времени: 30 минут.» Dev-блок `WORLD DEV` / «UNLOCK LOCATION» открывает существующую закрытую локацию через `WorldService.unlock_location`. Работа идёт только через `ActionService.execute(action)`. UI деньги, время и локацию не меняет напрямую.

Прокачка показывает четыре характеристики и одноразовые upgrades: «Тренировка», «Уход за внешностью», «Развитие капитала», «Развитие ауры», цена 300. После покупки: текущее значение и «Куплено». Покупка идёт через `CharacteristicService.create_upgrade_action` → `ActionService.execute`.

Раздел Одежда показывает каталог `OutfitCatalog`. Owned: название, «Куплено», кнопка «НАДЕТЬ». Equipped: «Надето». Purchasable: цена и «КУПИТЬ» через `EquipmentService.create_buy_outfit_action`.

Раздел Квартира показывает «Уровень квартиры: N» и доступные upgrades. Seed: «Улучшить квартиру», цена 500, кнопка «КУПИТЬ» через `ApartmentService.create_upgrade_action`. После покупки уровень становится 2. Там же игровое действие `wait_one_day`: кнопка «Подождать 1 день» → `GameActionCatalog.make_wait_one_day()` → `ActionService.execute` (1440 минут, 0 денег).

Раздел Девушки показывает `GirlsService.get_discovered_girls()`: имя, «Отношения: N / MAX», «Контакт: Да / Нет». Если есть `date_requirements` — блок «Требования для свидания:» со статусами. При максимуме: «Отношения: MAX / MAX» и «Линия завершена». Незнакомые девушки в этот список не входят — они появляются в мире через локацию.

Раздел Соперники показывает `RivalsService.get_discovered_rivals()`: имя, локация, «Статус: Не побеждён» / «Статус: Побеждён». Неоткрытые соперники в этот список не входят. Для открытого и ещё не побеждённого соперника блок «СОРЕВНОВАНИЯ» показывает каждую `CompetitionDefinition`: название, «Время: N минут», «Шанс победы: N%» из `CompetitionService.get_win_chance()`, кнопка «БРОСИТЬ ВЫЗОВ» → `CompetitionService.create_competition_action` → `ActionService.execute`. После победы соревнования этого соперника отображаются как завершённые. Победа в Action Result: «Победа.», «Соперник <Имя> побеждён.», «Прошло времени: N минут.» Поражение: «Поражение.», «<Имя> остаётся непобеждённым.», «Прошло времени: N минут.» Поражение — успешное игровое действие с отрицательным gameplay-result: `ActionResult.success = true`, `defeated` остаётся `false`.

Раздел Свидания показывает `GirlsService.get_contacted_girls()`. Доступная девушка: имя, отношения, статусы `date_requirements` (`✓` если все выполнены; иначе заголовок «Требования:» и `✗` с progress), кнопка «ПРИГЛАСИТЬ» (`disabled`, пока `can_start_date() == false`). Приглашение не запускает свидание: оно открывает выбор места через `DatingService.get_available_date_locations(girl_id)`, затем выбор owned outfit через `EquipmentService.get_owned_outfits()`. Карточка места показывает `DateLocation.display_name` и уже существующие параметры (качество и подобные поля). Известное предпочитаемое открытое место получает мягкую зелёную подсветку и подпись «Предпочитаемое место». Известный предпочитаемый наряд — ту же подсветку и подпись «Предпочитаемый». Обычное открытое место — стандартное оформление. Архитектура UI поддерживает закрытое место: «Название 🔒», кнопка disabled; сейчас список строится только из открытых мест сервиса. Выбор сохраняет presentation-состояние `selected_date_location_id` и `selected_outfit_id`. После выбора: «Девушка: <имя>», «Место: <название>», «Одежда: <название>», кнопка «НАЧАТЬ СВИДАНИЕ» → `DatingService.create_start_date_action(girl_id, selected_date_location_id, selected_outfit_id)` → `ActionService.execute`. «НАЗАД» возвращает к списку девушек. После успеха открывается существующий текстовый DatePlayPanel для активной девушки; Dev UI показывает `Active girl`, `Location` и `Outfit`. После итога Date System вызывает `DatingService.complete_date` и возвращает игрока в раздел Свидания. Cooldown: кнопка disabled, «Следующее свидание через N д. N ч.». Завершённая линия: «Линия завершена», без приглашения. При первом достижении максимума Action Result: «Отношения с <Имя> достигли максимума.» и «Rating +1». Выбор venue и outfit не создаёт отдельный cooldown.

Reusable `GameActionButton` получает `GameAction` и показывает label, `money_cost`, `time_cost_minutes`. Кнопка вызывает `ActionService.execute(action)` и возвращает `ActionResult` в `GameSimulator`. Человекочитаемые label живут в presentation-каталоге Simulator: `wait_one_day` → Подождать 1 день, `test_wait` → Подождать, `test_earn_money` → Работать, `test_spend_money` → Потратить 50. `wait_one_day` отображается как обычное игровое действие, не TEST_WAIT.

Успешный `ActionResult`: «Успешно.», полученные эффекты, «Прошло времени: N мин.». Отказ: «Действие недоступно.» и `ActionResult.failure_reason`. Кнопка `disabled`, если `ActionService.can_execute(action)` ложно; причина — `ActionService.get_failure_reason(action)` в `tooltip_text`.

Единый `refresh()` обновляет HUD, текущую секцию, доступность actions и последние отображаемые значения. Вызывается после New Game, Load, `ActionService.action_executed`, `TimeService.time_advanced`, `EconomyService.money_changed`, `RatingService.rating_changed`, `PurchaseService.purchase_completed`, `CharacteristicService.characteristic_changed`, `EquipmentService.outfit_equipped`, `StageService.stage_progress_changed`, `StageService.stage_completed`, `StageService.stage_changed`, `StageService.finale_reached`, `WorldService.location_changed`, `WorldService.location_unlocked`, `GirlsService.girl_discovered`, `GirlsService.girl_contact_received`, `GirlsService.girl_relationship_changed`, `GirlsService.girl_relationship_completed`, `GirlsService.girl_access_changed`, `DatingService.date_started`, `DatingService.date_completed`, `RivalsService.rival_discovered`, `RivalsService.rival_defeated`, `CompetitionService.competition_completed`, `AutomationService.automation_unlocked`, `AutomationService.clones_changed`, `AutomationService.allocation_changed`, `AutomationService.production_changed`, `AutomationService.upgrade_purchased`, `AutomationService.expansion_changed`. Simulator не хранит копии игровых значений: всегда читает сервисы и `GameState`. Factory slider меняет только `work_allocation_percent` и пересчитывает displayed rates без полного rebuild.

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

`DateMove`: `custom_action_scene`, `custom_action_script` для будущих анимаций, mini-game и scripted sequence. Mapping по-прежнему задаёт Tag.

## Resources

Поля сущностей:

- `DateTag`: id, display_name, description, enabled
- `DateMove`: id, display_name, description, kind, enabled, unlock_requirement, max_uses_per_date, situation_mappings, custom_action_scene, custom_action_script
- `DateMoveSituationMapping`: situation_id, tag_id, option_text, positive_result_text, negative_result_text
- `DateSituation`: id, display_name, description, situation_text, enabled, allowed_phases, weight, custom_episode_scene, custom_logic_script
- `SecondaryRule`: id, display_name, description, enabled, condition_type, condition_parameters, success_score, failure_score
- `GirlDifficultyPreset`: id, display_name, description, enabled, positive_tag_count, sort_order. Seed: starter 6, early 5, mid 4, late 3, elite 2.
- `GirlProfile`: id, display_name, description, enabled, relationship_min/start/max, difficulty_preset_id, positive_tag_ids, negative_tag_ids, secondary_rule_id, favorite_location_format_ids, favorite_outfit_ids, portrait, future_character_scene. Редактор выбирает Difficulty и положительные Tags. Требуемое число positive = `GirlDifficultyPreset.positive_tag_count`. При сохранении `negative_tag_ids = enabled_tag_ids − positive_tag_ids`. Seed: 10 профилей с id как у `GirlCatalog`, все `-5..+5`; Алина `business`.
- `LocationFormat`: id, display_name, description, enabled
- `DateLocation`: id, display_name, description, enabled, base_quality_bonus, preference_mode, location_format_id, uses_apartment_quality, uses_apartment_preparation, future_location_scene
- `Outfit`: id, display_name, description, enabled, score_bonus, price, future_visual_resource
- `ProgressionStat`: id, display_name, description, min_level, max_level
- `UnlockRequirement`: stat_id, required_level
- `DateRules`: см. seed-параметры ниже
- `DateContentCatalog`: tags, moves, situations, girls, girl_difficulty_presets, secondary_rules, location_formats, locations, outfits, progression_stats, date_rules

Enums:

- `DateMoveKind`: BASE, UNLOCKABLE
- `DatePhase`: OPENING, CORE, CLOSING
- `SecondaryConditionType`: DISTINCT_SUCCESS_TAGS, NO_FAILURES
- `LocationPreferenceMode`: NEUTRAL, THEMATIC

NEUTRAL location использует quality bonus. THEMATIC — quality bonus и preference check.

## DateRules seed

```text
opening_episode_count = 1
core_episode_count = 3
closing_episode_count = 1
base_moves_per_episode = 3
allow_situation_repeats = false
show_locked_unlockable_moves = true
opening_choice_score = 0
core_positive_score = 1
core_negative_score = -1
closing_positive_score = 1
closing_negative_score = -1
reveal_tag_after_use = true
reveal_secondary_after_first_completed_date = true
secondary_counted_phases = [CORE]  # fallback, если у SecondaryRule нет counted_phases
location_preference_success = 1
location_preference_failure = -1
apartment_unprepared_penalty = -1
apartment_quality_min = 0
apartment_quality_max = 3
min_distinct_base_tags_per_situation = 6
```

Количество положительных тегов — свойство конкретной девушки через `GirlDifficultyPreset`, не глобальное DateRules.

Все параметры свидания редактируются в «ПРАВИЛА СВИДАНИЯ». Difficulty presets — в «СЛОЖНОСТЬ ДЕВУШЕК».

## Runtime

`GirlProgress`: girl_id, relationship, revealed_positive_tag_ids, revealed_negative_tag_ids, secondary_revealed, completed_dates.

После reload Content Catalog runtime progress нормализуется: известные `tag_id` из обоих revealed-списков оставляются только если Tag активен, затем заново раскладываются по актуальному GirlProfile. Новые Tags (`care`, `humor`, `composure`, `cunning` при расширении набора) начинаются как `UNKNOWN`.

`TestPlayerState`: muscle, appearance, capital, aura, apartment_quality, apartment_prepared.

`DateSession`: session_id, seed, girl_id, location_id, outfit_id, relationship_before, selected_situation_ids, current_phase, current_episode_index, current_candidate_base_move_ids, current_selected_base_move_ids, current_selected_base_tag_ids, current_applicable_unlockable_move_ids, current_available_unlockable_move_ids, current_locked_unlockable_move_ids, current_used_unlockable_move_ids, current_reserved_unlockable_tag_ids, current_preferred_base_move_ids, current_fallback_base_move_ids, used_unlockable_move_counts, episode_history, revealed_tags_during_session, secondary_runtime_state, score_breakdown, relationship_after, completed.

Каждая DateSession создаёт deterministic RNG из seed. При одинаковых seed, GirlProgress snapshot, TestPlayerState и DateContent snapshot воспроизводятся Situations, BASE Moves и порядок BASE Moves.

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

Сигналы: `date_started`, `episode_started`, `move_selected`, `tag_revealed`, `relationship_changed`, `secondary_revealed`, `date_completed`, `relationship_max_reached`.

## Flow свидания

OPENING 1 → CORE 3 → CLOSING 1 → RESULT.

Situations выбираются по `allowed_phases`, `weight`, DateRules и seed. После Closing:

```text
Secondary + Location + Location Preference + Outfit + Apartment + Episode Scores
= Final Date Score → изменение отношений
```

Квартира в Result двумя строками: качество `+N`, подготовка `0` / `-1`. Quality 0..3. Unprepared = `-1`. THEMATIC favorite format `+1`, other `-1`.

## Раскрытие Tags

UNKNOWN / POSITIVE / NEGATIVE. UI: текст `[ТЕГ]` без изменений / зелёный / красный. Первое использование +1 → POSITIVE, -1 → NEGATIVE. Знание хранится в GirlProgress.

Secondary на первом свидании `???`. После первого completed date раскрывается в Result и дальше известна заранее; во время свидания — live progress.

## Seed Secondary

### variety — ЛЮБИТ РАЗНООБРАЗИЕ

`DISTINCT_SUCCESS_TAGS`, `required_count = 3`, counted OPENING+CORE+CLOSING. +1 тремя различными успешными Tags за свидание. Первый успешный тег уже даёт `1/3`. success +2, failure 0. Live: `Разные успешные теги: N/3`.

### demanding — ТРЕБОВАТЕЛЬНАЯ

`NO_FAILURES`, counted CORE. 0 ошибок CORE. success +2, failure 0. Live: `Ошибки CORE: N`.

## Seed Formats

calm Спокойное; entertainment Развлекательное; game Игровое; culture Культурное; unusual Необычное.

## Seed Locations

| id | имя | mode | quality | format | квартира |
|---|---|---|---|---|---|
| apartment | Квартира | NEUTRAL | 0 | — | quality+preparation |
| cafe | Кафе | NEUTRAL | +1 | — | нет |
| restaurant | Ресторан | NEUTRAL | +2 | — | нет |
| park | Парк | THEMATIC | +1 | calm | нет |
| cinema | Кинотеатр | THEMATIC | +1 | entertainment | нет |
| arcade | Аркада | THEMATIC | +1 | game | нет |
| museum | Музей | THEMATIC | +1 | culture | нет |
| planetarium | Планетарий | THEMATIC | +1 | unusual | нет |

## Seed Outfits

casual Повседневный +0, цена 0 (старт); business Деловой +1, цена 500; luxury Роскошный +2, цена 800.

## Seed Stats

muscle Мышца 0..8; appearance Внешность 0..8; capital Капитал 0..8; aura Аура 0..8.

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
| starter | Стартовая | 6 | 6 | 90.9% |
| early | Ранняя | 5 | 7 | 84.1% |
| mid | Средняя | 4 | 8 | 74.5% |
| late | Поздняя | 3 | 9 | 61.8% |
| elite | Элитная | 2 | 10 | 45.5% |

Формула UI: `1 − C(enabled − positive, base_moves) / C(enabled, base_moves)`. Обновляется при изменении числа активных Tags, `positive_tag_count` и `base_moves_per_episode`.

Балансировочный принцип:

```text
STARTER  6  герой почти без прокачки
EARLY    5  первые Открываемые ходы
MID      4  заметная роль билда, места и одежды
LATE     3  развитый набор Открываемых ходов
ELITE    2  поздняя прокачка + сильная подготовка
```

Разрешённые сочетания системы включают STARTER + -5..+5, MID + -5..+5, MID + -10..+10, LATE + -10..+10, ELITE + -10..+10. Authored-набор родного города использует только `-5..+5`.

AVAILABLE UNLOCKABLE по-прежнему резервируют Tag и расширяют покрытие: для STARTER BASE почти всегда даёт хороший вариант; для LATE/ELITE арсенал становится основным способом стабильно находить +1.

## Seed Girls

Authored-набор Date Lab совпадает с `GirlCatalog`: 10 профилей, `GirlProfile.id == GirlDefinition.id`, все `-5..+5` start 0. У каждого профиля есть difficulty preset, positive tags, secondary, favorite formats и favorite outfits; enabled tags без leftover (не positive и не negative).

Алина `alina`: filler, `city_center`, Rating 0. Difficulty starter. Positive: politeness, directness, care, generosity, composure, humor. Secondary variety. Favorites: calm, culture. Первая полноценная девушка: 6/6.

Вика `vika`: filler, `cafe`, Rating 2. Диапазон `-5..+5` (не LATE-гейт и не `-10..+10`).

Катя `katya`: filler, `city_center`, Rating 4.

Лера `lera`: filler, `city_center`, Rating 6.

Соня `sonya`: filler, `city_center`, Rating 8. Опциональный ручной шаг после Factory: альтернатива первому Automation Rating для знакомства с Президентом.

Актриса `girl_actress`: `city_center`, Stage 1 + Rating 1, соперник `rival_boris`.

Начальница шахты `girl_mine_boss`: `restaurant`, Stage 2 + Rating 3, соперник `rival_foreman`.

Редактор журнала `girl_magazine_editor`: `cafe`, Stage 3 + Rating 5, соперник `rival_columnist`.

Учёная `girl_scientist`: `city_center`, Stage 4 + Rating 7, соперник `rival_academic`. Factory открывается на Stage 5 после её MAX.

Президент `girl_president`: `restaurant`, Stage 5 + Rating 9, соперник `rival_minister`. Шестого сюжетного Rating-гейта 11 нет.

Ручная прогрессия без DEV: New Game Rating 0 → Alina MAX (+1) → Actress MAX (+1, Stage 2, restaurant) → Vika MAX (+1) → MineBoss MAX (+1, Stage 3) → Katya MAX (+1) → Editor MAX (+1, Stage 4) → Lera MAX (+1) → Scientist MAX (+1, Stage 5, Factory) → Sonya MAX (+1) или `RatingService.add_rating(1)` от Factory → President MAX (Stage 6). Filler не завершают Stage. Factory не закрывает охват родного города.

## Seed Situations

1. `appearance_question` OPENING — Оценка внешности. «Ну что, как я выгляжу?»
2. `money_request` CORE — Просьба о деньгах. Незнакомец просит денег.
3. `rival_provocation` CORE — Провокация самца.
4. `spontaneous_bet` CORE — Пари.
5. `date_verdict` CLOSING — Оценка свидания. «Ну и как тебе сегодняшний вечер?»

## Seed BASE Moves

`say_directly`, `compliment`, `support`, `smooth`, `tease`, `take_initiative`, `refuse`, `accept_challenge`, `pay`, `show_off`.

Изменённые mappings:

| Move | Situation | Tag | option_text |
|---|---|---|---|
| support | appearance_question | care | Спросить, нравится ли образ ей самой, и поддержать её выбор. |
| support | date_verdict | care | Сказать, что главное — понравился ли вечер ей самой. |
| tease | appearance_question | humor | Сказать, что ожидал увидеть что-то хуже. |
| tease | money_request | cunning | Попросить сначала доказать историю, а потом вернуться к вопросу денег. |
| tease | rival_provocation | humor | Высмеять его претензию. |
| tease | date_verdict | humor | Сказать, что бывало и хуже. |
| smooth | rival_provocation | composure | Спокойно предложить завершить конфликт и разойтись. |
| refuse | money_request | composure | Спокойно отказать и закончить разговор. |
| refuse | rival_provocation | cunning | Отказаться участвовать в провокации и предложить проверить рейтинг через официальный сервис. |
| refuse | spontaneous_bet | composure | Спокойно отказаться от пари. |

Разные BASE Tags по Situation (минимум `min_distinct_base_tags_per_situation` = 6):

| Situation | distinct BASE Tags | число |
|---|---|---|
| appearance_question | directness, politeness, care, flattery, humor, status | 6 |
| money_request | directness, generosity, politeness, cunning, dominance, composure, status | 7 |
| rival_provocation | directness, composure, humor, dominance, cunning, risk, status | ≥7 |
| spontaneous_bet | directness, flattery, politeness, audacity, dominance, composure, risk, status | 8 |
| date_verdict | directness, flattery, care, humor, dominance, status | 6 |

## Seed UNLOCKABLE Moves

| id | имя | req | mappings |
|---|---|---|---|
| punch | Дать в жбан | muscle >= 4 | rival_provocation → dominance |
| solve_with_money | Решить деньгами | capital >= 3 | money_request generosity; rival_provocation status; spontaneous_bet status |
| play_with_looks | Сыграть внешностью | appearance >= 3 | appearance_question audacity; rival_provocation status; date_verdict flattery |
| silent_pressure | Молча продавить | aura >= 3 | money_request dominance; rival_provocation dominance; date_verdict composure |
| raise_stakes | Поднять ставки | capital >= 6 | money_request risk; spontaneous_bet risk |

## Developer Room

Сцена `res://date_system/dev_room/DateSystemLab.tscn` (Control). Это dev-инструмент Date System, не игровая оболочка прохождения. Игровой 2D-проход Game Core — `GameSimulator`.

Разделы: СВИДАНИЕ, ДЕВУШКИ, СЛОЖНОСТЬ ДЕВУШЕК, ТЕГИ, БАЗОВЫЕ ХОДЫ, ОТКРЫВАЕМЫЕ ХОДЫ, СИТУАЦИИ, SECONDARY, МЕСТА, ФОРМАТЫ МЕСТ, НАРЯДЫ, ХАРАКТЕРИСТИКИ, ПРАВИЛА СВИДАНИЯ, БАЛАНС, ТЕСТОВОЕ СОСТОЯНИЕ, ВАЛИДАЦИЯ.

Шапка: GAME TIME (`Day`, `Time`, `Absolute`) из `TimeService`, CAMPAIGN (`Stage`, `Finale`) из `StageService`, `money` из `GameState`, кнопки «Новая игра», «Сохранить», «Загрузить», тестовые действия `+30 MIN` / `+120 MIN` / `+1 DAY` через `GameAction.time_cost_minutes` и `COMPLETE CURRENT STAGE` через `StageService.force_complete_current_stage_for_dev()`. Блок GAME ACTIONS запускает definitions каталога через `ActionService.execute`: `WAIT +120 MIN`, `EARN 100`, `SPEND 50`, `REQUIRE 100`; после попытки обновляет money, game time и показывает `ActionResult` (`SUCCESS` / `FAILED`). Экран СВИДАНИЕ показывает день, часы, `stage` и `money`. ТЕСТОВОЕ СОСТОЯНИЕ показывает вычисляемое время и кампанию, редактирует `money`. Кампанию в лаборатории двигает только `force_complete_current_stage_for_dev()`, без свободного SpinBox Stage.

Редактор: список, поиск, создать, дублировать, редактировать, удалить, сохранить, отменить. Draft-копия Resource. Save: validate → `.tres` → catalog reload → статус. Удаление показывает зависимости.

«СЛОЖНОСТЬ ДЕВУШЕК»: поля ID, Название, Описание, Enabled, Количество положительных тегов (SpinBox 1 .. enabled_tags−1), Порядок. В списке: `Название | Positive | Negative`.

«ДЕВУШКИ»: selector Сложность (enabled presets), рядом `Положительных тегов требуется: N` / `Отрицательных тегов: enabled−N` и теоретическая доступность. Таблица `TAG | НРАВИТСЯ | НЕ НРАВИТСЯ`. Счётчик `Положительные теги: current / required`. Save пересобирает negative как дополнение positive. N ≠ required → ERROR валидации.

«БАЛАНС»: по каждой девушке Girl, Difficulty, Positive Tags, Negative Tags, Relationship Range, Theoretical positive availability. Кнопка «СИМУЛИРОВАТЬ BASE» (10000 seeds, stats на минимуме, UNLOCKABLE unavailable): по Situation и aggregate — доля эпизодов с хотя бы одним positive BASE, доля all-negative, средний positive BASE count. Фактические проценты считаются по реальным mappings Situations.

После save новый DateSession берёт новые данные. Запущенная сессия работает на snapshot.

## Validator

1. уникальные IDs  
2. references существуют  
3. у GirlProfile редактируются только positive tags; все остальные активные Tags считаются negative. Tag не может быть одновременно в positive и negative  
4. mapping → существующая Situation  
5. mapping → существующий Tag  
6. UNLOCKABLE имеет UnlockRequirement  
7. BASE unlimited usage  
8. Situation имеет минимум 3 применимых BASE при seed DateRules  
9. THEMATIC Location имеет LocationFormat  
10. Secondary parameters валидны  
11. достаточно Situations на каждую DatePhase  
12. GirlProfile.secondary существует  
13. favorite LocationFormat существует  
14. UnlockRequirement → существующий ProgressionStat  
15. один Move — максимум один mapping на одну Situation  
16. несколько UNLOCKABLE одной Situation с одинаковым Tag → WARNING `DUPLICATE_UNLOCKABLE_TAG_IN_SITUATION` (не блокирует запуск)
17. `GirlProfile.difficulty_preset_id` не резолвится в enabled preset → ERROR `INVALID_GIRL_DIFFICULTY_REFERENCE`
18. `girl.positive_tag_ids.size() != difficulty.positive_tag_count` → ERROR `INVALID_POSITIVE_TAG_COUNT`
19. `positive ∪ negative == enabled Tags`, пересечение пусто; иначе ERROR `INCOMPLETE_GIRL_TAG_COVERAGE` (missing_tag_ids, duplicate_state_tag_ids, unknown_tag_ids)
20. enabled preset: `1 <= positive_tag_count < enabled_tags.size()` иначе ERROR `INVALID_DIFFICULTY_POSITIVE_COUNT`
21. активный DateTag без DateMoveSituationMapping → WARNING `TAG_WITHOUT_MOVE_MAPPING` (в seed = 0)
22. distinct BASE Tags ситуации < `min_distinct_base_tags_per_situation` → WARNING `LOW_BASE_TAG_DIVERSITY`

Экран: severity, code, resource_type, resource_id, field, message. Кнопка «ПРОВЕРИТЬ ВЕСЬ КОНТЕНТ». ERROR блокирует сохранение; WARNING только показывает проблему.

## UI свидания

Запуск: девушка, место, наряд, квартира (если location uses apartment), тестовые статы, seed. Кнопки: НАЧАТЬ НОВОЕ СВИДАНИЕ, ПОВТОРИТЬ ПОСЛЕДНИЙ SEED, СБРОСИТЬ ПРОГРЕСС ДЕВУШКИ, СБРОСИТЬ ВЕСЬ ТЕСТОВЫЙ ПРОГРЕСС.

Эпизод: фаза, номер, Situation, BASE×3, все applicable UNLOCKABLE. Tag цветом знания конкретной девушки (UNKNOWN — цвет текста по умолчанию, POSITIVE — зелёный, NEGATIVE — красный), option, у locked — затемнение и `Requirement: ...`, у used — затемнение и отдельная строка `Уже использован`. После выбора: ход, tag, реакция, score, новое знание, ПРОДОЛЖИТЬ.

Debug-панель эпизода дополнительно показывает: applicable/available/locked/used unlockable moves, reserved_unlockable_tags, preferred/fallback BASE candidates, selected_base_moves и selected_base_tags. У каждого Move: `move_id`, `tag_id`, `state`.

Result: построчный итог, строки появляются быстро одна за другой. Сначала `[ТЕГ] +1` / `[ТЕГ] -1` по эпизодам с ненулевым score. Opening `0` не показывают. Затем Secondary всегда, даже при `0`; место (quality + preference одним числом); наряд; квартира входит в строку места, если это место её использует. В конце `Итого` и отношения. Без эпизодной статистики и без debug-панели.

Replay восстанавливает snapshot девушки до сессии и тот же seed: те же Situations, BASE selection и порядок.

Сброс девушки: relationship_start, пустые revealed tags, secondary_revealed=false, completed_dates=0.

Карточка девушки: имя; Сложность; Положительных тегов N/12; Теоретическая базовая доступность; Отношения current/max; известные нравится/не нравится; Неизвестно N; Secondary ??? / раскрытое правило.

Debug-панель свёрнута по умолчанию.

UI: контейнеры, anchors, scroll, split, навигация, 1280×720 и 1920×1080.

## Автотесты

Кейсы 1–36 постановки задачи плюс резервирование UNLOCKABLE Tags, 12 Tags, Girl Difficulty presets (STARTER..ELITE), Алина STARTER 6/6, Вика `-5..+5` без LATE-гейта, 10 authored-профилей с preset/positives/secondary/favorites и без leftover tags, теоретическая вероятность без Monte Carlo, persist/reload GirlProfile, смена difficulty, runtime-нормализация знания, 10000-seed баланс равномерного пула для 6/5/4/3/2 positive, round-trip `GameState` save/load (`game_time_minutes` / `stage` / `finale_reached` / `money` / `purchased_ids` / `current_location_id` / `unlocked_location_ids` / `girls_by_id` и наличие всех секций), миграция `save_version` 1 `flow.day` → `game_time_minutes`, миграция `save_version` 2 без `finale_reached` → `false`, миграция без `progression.purchased_ids` → `[]`, миграция без world-полей → стартовый `WorldState`, миграция без `girls.girls_by_id` → `{}`, старт/внутри дня/переход суток/`advance_time` больших интервалов, save/load абсолютного времени и событие `time_advanced`, New Game Stage 1, `GirlRelationshipRequirement` (relationship 3/5 → `is_met == false`; 5/5 → `true`), автоматический переход Stage при MAX сюжетной девушки и отсутствие перехода при MAX другой девушки, `UnlockLocationStageEffect` при входе в следующий Stage, порядок `stage_completed` → on_enter_effects → `stage_changed`, `reconcile_stage_entry_state()` для уже достигнутых Stage и повторная идемпотентность, save/load прогресса текущего `StageRequirement` из `GirlState.relationship`, Stage 6 с `WorldReachRequirement` (без WORLD 100% — `can_complete` / `try_complete` = false; WORLD 100% на Stage 6 → Finale; WORLD 100% до MAX Президента остаётся Stage 5, затем переход 5→6 сразу даёт Finale), успешное `try_complete` на LAST_STAGE с выполненным test requirement → `stage == 6` / `finale_reached` / сигналы `stage_completed(6)` и `finale_reached()` без Stage 7, `StageCatalog` берёт `GirlRelationshipRequirement.target_relationship` из `GirlDefinition.relationship_max`, Finale через `force_complete_current_stage_for_dev()`, полный проход Stage 1–5 → 6 через MAX сюжетных девушек, высокий Rating не завершает Stage пока relationship сюжетной девушки < MAX, `GirlAccessRequirement` (`RatingGirlRequirement` 3/5 → unmet, 5/5 → met; `RivalDefeatedGirlRequirement` до/после `defeat_rival`; `MinStageGirlRequirement` stage 2/3/4), несколько `meet_requirements` (Stage выполнен / Rating нет → `can_meet_girl` false, затем true), атомарность Meet Girl при невыполненном requirement, `DatingService.can_start_date` с `RivalDefeatedGirlRequirement`, save_version не растёт — requirements не сериализуются и после load считаются из GameState, pipeline `ActionService` (`test_wait` / `test_earn_money` / `test_spend_money` / `MoneyRequirement` / полный cost+effect+time / атомарность отказа / `action_executed` только при успехе), `EconomyService` (`add_money` / `spend_money` success/fail / `money_changed`), `work_basic` (100 денег / 60 минут, повтор), покупка `basic_upgrade` (нехватка денег / успех / повтор «Уже куплено»), save/load денег и `purchased_ids`, presentation `GameSimulator` (New Game: money 0 / stage 1 / day 1; работа через Simulator → money 100 / 60 мин; навигация не меняет `GameState`; save/load состояния, изменённого через Simulator; Stage через `StageService`; dev Stage через `force_complete_current_stage_for_dev`; Город: текущая локация, вход/выход интерьера без сдвига времени, закрытая локация, dev unlock, люди текущей локации, знакомство), `WorldService` (New Game start location и unlock'и, первый/повторный unlock, `enter_location`, отказ в закрытую, `location_changed` / `location_unlocked`, время не двигается), `LocationRequirement`, save/load локации и unlock'ов, `GirlsService` (default `GirlState`, однократный `discover_girl` / `give_contact` / `change_relationship`, девушки текущей локации), `MEET_GIRL` (успех 30 минут, повтор «Вы уже знакомы», другая локация), `GirlContactRequirement`, `RelationshipRequirement`, `RatingService` (старт 0, +1 при первом максимуме, большой delta даёт +1, повтор не начисляет), `DatingService` (start date success/fail без контакта/cooldown/максимума, выбранный `date_location_id` пишется в `active_date` и `DateSessionConfig` независимо от `GirlDefinition.location_id`, preferred/known venue API совпадает с Date Engine, недоступное место проваливает `DateLocationAvailableRequirement` без активного свидания, complete_date применяет relationship/time/cooldown, раскрытые теги переходят на следующее свидание, полный цикл до Rating), GameSimulator двухшаговый выбор места и зелёная подсветка известных предпочтений, save/load Rating / cooldown / знание тегов / завершённой девушки / active_date включая `location_id`, миграция без `player.rating` → `0`, `RivalsService` (default `RivalState`, однократный `discover_rival` / `defeat_rival`, соперники текущей локации), `MEET_RIVAL`, `CompetitionService` (детерминированный win/loss через action, отказ в другой локации / до discovery / после победы), save/load `rivals_by_id`, миграция без `rivals.rivals_by_id` → `{}`, GameSimulator: встреча соперника, раздел Соперники, бросить вызов, шанс победы из `get_win_chance()`, характеристики / одежда / квартира, выбор outfit перед свиданием, `CharacteristicService` / `EquipmentService` / `ApartmentService` save/load и миграция `save_version` 9 → 10, Automation: Stage 4 MAX Учёной → Stage 5 unlock + 10 клонов, повторный reconcile не добавляет клонов, load v10 Stage 5/6 restore через reconcile, work 10 клонов 40% / 60 мин → 400, dating 100% / 60 мин → +1 Rating, дробный dating progress 1 клон / 1 час → 0.1 Rating fraction, 10 часов → +1 Rating, upgrades +10 клонов / ×1.5 work / ×1.5 dating, CITY 100% → Country за 10 000 с клонами ×10, Country 100% → World за 1 000 000 с клонами ×10, capped expansion при продолжающемся Rating, `advance_time(60)` vs `60 × advance_time(1)`, save_version 11 → 12, миграция `completed_auto_dates` в Rating и CITY progress, GameSimulator раздел Фабрика после unlock показывает Rating/hour и экспансию, Home показывает охват родного города 0/10 … 10/10, каталог 10 девушек (`GirlDefinition` ↔ `GirlProfile`, Rating-гейты 0/1/2/3/4/5/6/7/8/9), соперники только после discover связанной девушки, restaurant unlock на Stage 2 и restore save Stage 2+, свидания всех 10, ручная прогрессия Alina→President без DEV (ветка Sonya и ветка Factory `add_rating(1)`), filler не завершают Stage, `wait_one_day` +1440 / `test_wait` +120, label «Подождать 1 день».
