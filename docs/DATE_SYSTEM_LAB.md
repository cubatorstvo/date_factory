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
- Перед эпизодом Date Engine собирает все применимые BASE.
- RNG выбирает из них 3 и определяет порядок отображения.
- Один BASE может снова появиться в следующих эпизодах того же свидания.
- `max_uses_per_date = 0` означает unlimited.

### UNLOCKABLE

- Есть требование к характеристике и mappings к Ситуациям.
- Все подходящие текущей Ситуации UNLOCKABLE показываются игроку.
- Выполненное требование делает Ход доступным.
- Будущее требование: затемнён, рядом характеристика и уровень.
- Seed: `max_uses_per_date = 1`.
- После использования строка остаётся со статусом `Уже использован`.

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
2. Runtime Progress Layer — отношения, известные предпочтения, Secondary, число свиданий, тестовая прокачка, квартира, replay snapshot.
3. Date Engine — DateSession, RNG, эпизоды, BASE/UNLOCKABLE, mappings, Tags, Secondary, location/outfit/apartment scores, итог отношений.
4. Text Date Runner — текстовый 2D DateSession.
5. Developer Room — редактор Content Layer и запуск runner.

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
- `GirlProfile`: id, display_name, description, enabled, relationship_min/start/max, positive_tag_ids, negative_tag_ids, secondary_rule_id, favorite_location_format_ids, portrait, future_character_scene
- `LocationFormat`: id, display_name, description, enabled
- `DateLocation`: id, display_name, description, enabled, base_quality_bonus, preference_mode, location_format_id, uses_apartment_quality, uses_apartment_preparation, future_location_scene
- `Outfit`: id, display_name, description, enabled, score_bonus, future_visual_resource
- `ProgressionStat`: id, display_name, description, min_level, max_level
- `UnlockRequirement`: stat_id, required_level
- `DateRules`: см. seed-параметры ниже
- `DateContentCatalog`: tags, moves, situations, girls, secondary_rules, location_formats, locations, outfits, progression_stats, date_rules

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
secondary_counted_phases = [CORE]
location_preference_success = 1
location_preference_failure = -1
apartment_unprepared_penalty = -1
apartment_quality_min = 0
apartment_quality_max = 3
```

Все параметры редактируются в Developer Room.

## Runtime

`GirlProgress`: girl_id, relationship, revealed_positive_tag_ids, revealed_negative_tag_ids, secondary_revealed, completed_dates.

`TestPlayerState`: muscle, appearance, capital, aura, apartment_quality, apartment_prepared.

`DateSession`: session_id, seed, girl_id, location_id, outfit_id, relationship_before, selected_situation_ids, current_phase, current_episode_index, current_candidate_base_move_ids, current_selected_base_move_ids, current_applicable_unlockable_move_ids, used_unlockable_move_counts, episode_history, revealed_tags_during_session, secondary_runtime_state, score_breakdown, relationship_after, completed.

Каждая DateSession создаёт deterministic RNG из seed.

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

UNKNOWN / POSITIVE / NEGATIVE. UI: ⚪ 🟢 🔴. Первое использование +1 → POSITIVE, -1 → NEGATIVE. Знание хранится в GirlProgress.

Secondary на первом свидании `???`. После первого completed date раскрывается в Result и дальше известна заранее; во время свидания — live progress.

## Seed Secondary

### variety — ЛЮБИТ РАЗНООБРАЗИЕ

`DISTINCT_SUCCESS_TAGS`, `required_count = 3`, counted CORE. +1 тремя различными Tags в CORE. success +2, failure 0. Live: `Разные успешные теги: N/3`.

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

politeness УЧТИВОСТЬ; directness ПРЯМОЛИНЕЙНОСТЬ; flattery ПОДХАЛИМАЖ; audacity НАГЛОСТЬ; dominance ДОМИНИРОВАНИЕ; risk АЗАРТ; generosity ЩЕДРОСТЬ; status СТАТУС.

## Seed Girls

Алина `alina`: rel -5..+5 start 0. Positive: politeness, directness, risk, generosity. Negative: flattery, audacity, dominance, status. Secondary variety. Favorites: calm, culture.

Вика `vika`: rel -10..+10 start 0. Positive: flattery, audacity, dominance, status. Negative: politeness, directness, risk, generosity. Secondary demanding. Favorites: game, unusual.

## Seed Situations

1. `appearance_question` OPENING — Оценка внешности. «Ну что, как я выгляжу?»
2. `money_request` CORE — Просьба о деньгах. Незнакомец просит денег.
3. `rival_provocation` CORE — Провокация самца.
4. `spontaneous_bet` CORE — Пари.
5. `date_verdict` CLOSING — Оценка свидания. «Ну и как тебе сегодняшний вечер?»

## Seed BASE Moves

`say_directly`, `compliment`, `support`, `smooth`, `tease`, `take_initiative`, `refuse`, `accept_challenge`, `pay`, `show_off` — mappings и option_text как в постановке задачи.

## Seed UNLOCKABLE Moves

| id | имя | req | mappings |
|---|---|---|---|
| punch | Дать в жбан | muscle >= 4 | rival_provocation → dominance |
| solve_with_money | Решить деньгами | capital >= 3 | money_request generosity; rival_provocation status; spontaneous_bet status |
| play_with_looks | Сыграть внешностью | appearance >= 3 | appearance_question audacity; rival_provocation status; date_verdict flattery |
| silent_pressure | Молча продавить | aura >= 3 | money_request dominance; rival_provocation dominance; date_verdict audacity |
| raise_stakes | Поднять ставки | capital >= 6 | money_request risk; spontaneous_bet risk |

## Developer Room

Сцена `res://date_system/dev_room/DateSystemLab.tscn` (Control).

Разделы: СВИДАНИЕ, ДЕВУШКИ, ТЕГИ, БАЗОВЫЕ ХОДЫ, ОТКРЫВАЕМЫЕ ХОДЫ, СИТУАЦИИ, SECONDARY, МЕСТА, ФОРМАТЫ МЕСТ, НАРЯДЫ, ХАРАКТЕРИСТИКИ, ПРАВИЛА СВИДАНИЯ, ТЕСТОВОЕ СОСТОЯНИЕ, ВАЛИДАЦИЯ.

Редактор: список, поиск, создать, дублировать, редактировать, удалить, сохранить, отменить. Draft-копия Resource. Save: validate → `.tres` → catalog reload → статус. Удаление показывает зависимости.

После save новый DateSession берёт новые данные. Запущенная сессия работает на snapshot.

## Validator

1. уникальные IDs  
2. references существуют  
3. каждый активный Girl Tag ровно в positive или negative  
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

Экран: severity, resource_type, resource_id, field, message. Кнопка «ПРОВЕРИТЬ ВЕСЬ КОНТЕНТ».

## UI свидания

Запуск: девушка, место, наряд, квартира (если location uses apartment), тестовые статы, seed. Кнопки: НАЧАТЬ НОВОЕ СВИДАНИЕ, ПОВТОРИТЬ ПОСЛЕДНИЙ SEED, СБРОСИТЬ ПРОГРЕСС ДЕВУШКИ, СБРОСИТЬ ВЕСЬ ТЕСТОВЫЙ ПРОГРЕСС.

Эпизод: фаза, номер, Situation, BASE×3, все applicable UNLOCKABLE, состояние/цвет Tag/option/requirement/uses. После выбора: ход, tag, реакция, score, новое знание, ПРОДОЛЖИТЬ.

Result: все эпизоды, Secondary, location quality/preference, outfit, apartment quality/preparation, total, relationship before→after.

Replay восстанавливает snapshot девушки до сессии и тот же seed: те же Situations, BASE selection и порядок.

Сброс девушки: relationship_start, пустые revealed tags, secondary_revealed=false, completed_dates=0.

Карточка девушки: имя, отношения min/max, нравится/не нравится/неизвестно, Secondary, любимые форматы.

Debug-панель свёрнута по умолчанию.

UI: контейнеры, anchors, scroll, split, навигация, 1280×720 и 1920×1080.

## Автотесты

Кейсы 1–36 постановки задачи (раскрытие tags, scores фаз, BASE pool/RNG/replay, UNLOCKABLE, Secondary, локации, квартира, outfit, clamp Алины/Вики, reset, resource reload, validator).
