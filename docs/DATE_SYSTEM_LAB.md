# DATE SYSTEM LAB

Каноническая спецификация текущей `main`. Код должен совпадать с этим документом.

## Назначение

Date System Lab одновременно:

- самостоятельная 2D-текстовая версия механики свиданий;
- комната разработчика;
- редактор игрового контента;
- тестовая среда;
- фундамент будущей основной игры.

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
5. Developer Room — редактор Content Layer и запуск runner.

## GameState

Autoload `GameState` — текущее прохождение. Секции: `flow`, `story`, `player`, `progression`, `world`, `girls`, `dating`, `rivals`, `automation`. Каждая секция — отдельный typed-класс с `to_dict()` / `from_dict()`.

`GameState` хранит только изменяемое состояние конкретного прохождения. Статические определения игрового контента — параметры девушек, предметов, локаций, Stage, цены, базовые характеристики и прочие definitions — хранятся отдельно от `GameState`. `GameState` хранит только ссылки/ID и изменяемый прогресс относительно этих definitions.

Сейчас используются только:

```text
flow.game_time_minutes = 0
story.stage = 1
player.money = 0
```

`game_time_minutes = 0` — Day 1, 00:00. День, час и минута не хранятся: их даёт `TimeService`.

Пустые секции сериализуются как `{}`. Поля читаются через `data.get(key, default)`.

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
  "save_version": 2,
  "game_state": { "flow": { "game_time_minutes": 0 }, "story": { "stage": 1 }, "player": { "money": 0 }, "progression": {}, "world": {}, "girls": {}, "dating": {}, "rivals": {}, "automation": {} }
}
```

`new_game()` создаёт новые экземпляры всех секций: `game_time_minutes = 0`, stage 1, money 0. `load_game()` собирает чистый `GameState` через `from_dict()`. Сохранения `save_version = 1` с `flow.day = N` мигрируют в `game_time_minutes = (N - 1) * 1440`. Системы и UI читают время через `TimeService`, `GameState.story.stage`, `GameState.player.money`.

`DateSession.stage` не является `StoryState.stage`. `DateProgressStore` остаётся прогрессом лаборатории свиданий, пока `girls` / `dating` пусты.

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

Любой положительный промежуток обрабатывается одним вызовом. После успешного продвижения публикуется `time_advanced(delta_minutes, previous_game_time, current_game_time)`. Будущие Economy / Automation / Dating / Story / World считают результат сразу за весь `delta_minutes`.

Игровые действия несут `GameAction.time_cost_minutes`. После успеха действие вызывает `TimeService.advance_time(time_cost_minutes)`. Покупка может стоить `0` и не двигает часы.

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
- `GirlProfile`: id, display_name, description, enabled, relationship_min/start/max, difficulty_preset_id, positive_tag_ids, negative_tag_ids, secondary_rule_id, favorite_location_format_ids, portrait, future_character_scene. Редактор выбирает Difficulty и положительные Tags. Требуемое число positive = `GirlDifficultyPreset.positive_tag_count`. При сохранении `negative_tag_ids = enabled_tag_ids − positive_tag_ids`.
- `LocationFormat`: id, display_name, description, enabled
- `DateLocation`: id, display_name, description, enabled, base_quality_bonus, preference_mode, location_format_id, uses_apartment_quality, uses_apartment_preparation, future_location_scene
- `Outfit`: id, display_name, description, enabled, score_bonus, future_visual_resource
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

casual Повседневный +0; business Деловой +1; luxury Роскошный +2.

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

Разрешённые сочетания включают STARTER + -5..+5, MID + -5..+5, MID + -10..+10, LATE + -10..+10, ELITE + -10..+10.

AVAILABLE UNLOCKABLE по-прежнему резервируют Tag и расширяют покрытие: для STARTER BASE почти всегда даёт хороший вариант; для LATE/ELITE арсенал становится основным способом стабильно находить +1.

## Seed Girls

Алина `alina`: difficulty starter. rel -5..+5 start 0. Positive: politeness, directness, care, generosity, composure, humor. Negative: flattery, audacity, dominance, risk, status, cunning. Secondary variety. Favorites: calm, culture. Первая полноценная девушка: 6/6, базовый герой может довести до +5 после изучения предпочтений.

Вика `vika`: difficulty late. rel -10..+10 start 0. Positive: audacity, dominance, risk. Negative: politeness, directness, flattery, generosity, status, care, humor, composure, cunning. Secondary demanding. Favorites: game, unusual. Девушка на развитый арсенал: 3/9.

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

Сцена `res://date_system/dev_room/DateSystemLab.tscn` (Control).

Разделы: СВИДАНИЕ, ДЕВУШКИ, СЛОЖНОСТЬ ДЕВУШЕК, ТЕГИ, БАЗОВЫЕ ХОДЫ, ОТКРЫВАЕМЫЕ ХОДЫ, СИТУАЦИИ, SECONDARY, МЕСТА, ФОРМАТЫ МЕСТ, НАРЯДЫ, ХАРАКТЕРИСТИКИ, ПРАВИЛА СВИДАНИЯ, БАЛАНС, ТЕСТОВОЕ СОСТОЯНИЕ, ВАЛИДАЦИЯ.

Шапка: GAME TIME (`Day`, `Time`, `Absolute`) из `TimeService`, `stage` / `money` из `GameState`, кнопки «Новая игра», «Сохранить», «Загрузить» и тестовые действия `+30 MIN` / `+120 MIN` / `+1 DAY` через `GameAction.time_cost_minutes`. Экран СВИДАНИЕ показывает день, часы и `stage` / `money`. ТЕСТОВОЕ СОСТОЯНИЕ показывает вычисляемое время и редактирует `stage` / `money`.

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

Кейсы 1–36 постановки задачи плюс резервирование UNLOCKABLE Tags, 12 Tags, Girl Difficulty presets (STARTER..ELITE), Алина STARTER 6/6, Вика LATE 3/9, теоретическая вероятность без Monte Carlo, persist/reload GirlProfile, смена difficulty, runtime-нормализация знания, 10000-seed баланс равномерного пула для 6/5/4/3/2 positive, round-trip `GameState` save/load (`game_time_minutes` / `stage` / `money` и наличие всех секций), миграция `save_version` 1 `flow.day` → `game_time_minutes`, старт/внутри дня/переход суток/`advance_time` больших интервалов, save/load абсолютного времени и событие `time_advanced`.
