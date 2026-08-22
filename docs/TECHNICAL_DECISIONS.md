# Технические решения — Date System Lab

## Движок и рендер

- Godot 4.7.1 stable
- Forward Plus
- Главная сцена — 2D Control UI (`GameSimulator`)
- 3D-локации — presentation тех же `location_id`; вход в дверь грузит `LocationDefinition.scene_path` через `SceneTransitionService`, не через `ActionService`

## Контент

- Typed `Resource` + `class_name` для каждой сущности
- Seed-контент — реальные `.tres` в `res://`
- Сохранение из Developer Room через `ResourceSaver`
- Date Engine получает snapshot каталога на старте DateSession: новый `DateContentCatalog` с копиями массивов и теми же Resources. `Resource.duplicate()` в Godot 4.7 снимает методы с custom Resource, поэтому глубокое дублирование каталога нельзя использовать. Уже запущенное свидание не подменяет Resources на лету

## Runtime

- `GirlProgress`, `DatePlayerSnapshot` и replay snapshot хранятся в `user://date_system/`
- JSON, не `res://`: прогресс игрока не является design-content

## RNG

- Каждая DateSession создаёт `RandomNumberGenerator` из `seed`
- Выбор Situations и BASE-ходов идёт только через этот RNG, в фиксированном порядке вызовов, чтобы replay совпадал

## Combo

- Универсальное правило Date Engine: три последовательных успешных хода с тремя разными тегами дают `Combo +1`
- Параметры живут в `DateRules` (`combo_required_distinct_success_tags`, `combo_bonus_score`, `combo_max_rewards_per_date`)
- Relationship Gain = `max(Raw Date Score, 0)`; свидание не снижает отношения

## Эпизоды будущего

- `DateSituation` уже содержит `custom_episode_scene` и `custom_logic_script`
- Текущая версия использует `text_presentation` через `DateEpisodeController`
- Расчёт Tag и score всегда делает Date Engine после `move_id`

## Тесты

- Headless GDScript runner без внешних фреймворков
- Кейсы из спецификации Date System Lab, раздел 75

## City density

- Характеристики героя 0–5, repeatable upgrade за 300 от текущего `PlayerState`
- `WorldState.city_stage` 1–3 открывает пачки filler-девушек и filler-rivals; сюжетные цели — Stage + Rating. Stage 1 filler: Алина / Вика / Даша. Марина — Stage 2. High-level Stage 1–4: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md)
- Apartment Local coverage: Stage 1 `0/12`, Stage 2 `4/12`, Stage 3 `8/12`, Stage 4 `12/12`; 1 object = 1 Tag = 1 Local Move
- Повторяемые progression-активности идут через autoload `DailyActivityService` и календарный `day_index = floor(game_time_minutes / 1440)`
- Канонические keys: `work`, `characteristic_training`, `date:<girl_id>`, `rival:<rival_id>`, `story_event:<event_id>`; базовый daily limit = 1
- Работа 100/ч, затем 200/ч после Story Stage 3; после MAX Оли limit `work` = 2 (обычная смена + подработка / checkbox)
- Все постоянные прокачки Мышца / Внешность / Капитал / Аура делят один `characteristic_training` в день; экспресс-стайлинг Киры — подготовка к Date, не daily training
- Обычная встреча с конкретной девушкой — один бесплатный `date:<girl_id>` в календарный день; разные девушки независимы
- Reward Риты `rita_urgent_taxi` — платная same-day встреча `$75`, не обход паузы; бесплатный слот остаётся использованным
- Повторная попытка Rival — `rival:<rival_id>` раз в календарный день, включая story rival до первой победы
- Одежда — набор купленных Outfit, экипировка перед свиданием, максимум `+1` к одной характеристике; Outfit как build-layer — Stage 2, Outfit Move — Stage 3
- Подарок Марины `marina_free_outfit_pending` делает следующую обычную покупку доступного Outfit в магазине `$0`; отдельного gift-списка нет; Марина — Stage 2 Casual exception
- Катя даёт `Акцент интерьера`: выбранный Apartment Local Move positive `+2`

## Venues & Local Objects

- Production DateVenues: только `apartment`, `cafe`, `leisure_center`, `restaurant`. Seed leftovers (`park`, `cinema`, `arcade`, `museum`, `planetarium`) не входят в `DateContentCatalog.date_venues`
- Local Object IDs уникальны per-venue (`cafe__window`, не общий `window`)
- Apartment `local_object_ids` пустой: Local Source квартиры = только купленные Apartment Objects
- `DateVenue.price`: Apartment `$0`, Café `$20`, Leisure Center `$40`, Restaurant `$60`. `DatingService.create_start_date_action` включает эту цену в `money_cost`
- DateVenue unlock — persistent `WorldState.unlocked_date_venue_ids`, старт `[apartment]`. `UnlockDateVenueStageEffect` рядом с `UnlockLocationStageEffect`. Stage 2: `cafe` + `leisure_center`; Stage 3: `restaurant`. `DatingService.get_available_date_venues` фильтрует по этому списку
- World `leisure_center` и `furniture_store` — `LocationDefinition` (не DateVenue). Stage 2 unlocks both world locations. Katya `location_id = furniture_store`
- Furniture Store UI читает `ApartmentService`, не `PurchaseService`
- Accent: `ApartmentState.accent_object_id`; награда только `katya_interior_accent`. Без Emperor Chair constants и без миграции `katya_emperor_chair`. Первое назначение `$0`; смена по Story Stage `$300 / $600 / $1000`

## Progression integration

- Spec `min_city_stage` 1–4 для Outfit и Apartment Objects = **Story Stage**. `WorldState.city_stage` остаётся 1–3 для filler packs. Поля в коде: `Outfit.min_story_stage`, `ApartmentObjectDefinition.min_story_stage`, плюс `Outfit.tier` (`0` Casual / `1` Dressed)
- Stage 2+ Date gate: `OutfitAboveCasualGirlRequirement` проверяет `equipped Outfit.tier >= 1`, не price и не id-имя. Марина: `date_requirements = []`. Stage 1 girls без этого requirement
- Марина: `MinCityStageGirlRequirement(2)`, `location_id = clothing_store`. Clothing Store — `LocationDefinition` по образцу `furniture_store`, unlock на Stage 2. Симуляторная секция одежды остаётся player-facing магазином
- Apartment domain: `ApartmentObjectDefinition`, `owned_local_object_ids`, `accent_object_id`, `create_buy_apartment_object_action`. Player-facing `Предметы: N / 12`. `ApartmentState.level` не является progression UI. Automation `purchased_upgrade_ids` не трогать
- Dating runtime читает только `venue_id`. Save-compatibility не требуется: старые ключи `location_id` / `purchased_upgrade_ids` / `katya_emperor_chair` не мигрируем
- Objective «Приоденься»: secondary Stage 2, completion = владение любым Outfit `tier >= 1`, не экипировка
- Accent +2 идёт через текущий Date Engine score path (`DateSessionConfig.accent_object_id`), не отдельный scorer
- Sonya `venue_source_limit = 2` остаётся в `DatingService._create_engine`. Два разных Local Move; sibling move того же объекта разрешён
- Source label: `ЛОКАЦИЯ`. Option format: `[ТЕГ] Объект: действие` через `GameTermFormatter`
- Developer Room venue playground вызывает production `DatingService` / `DateEngine`, не второй lab engine
- Обычные девушки `0..10`; Actress / Mine Boss / Magazine Editor `0..10`; Scientist / President `0..15`
- Stage 1 filler positives: Alina 8, Vika 7, Dasha 6; для 8 и 7 добавлены difficulty presets `wide` и `easy`
- `GirlProfile.initial_known_tag_count` — базовый source of truth (filler 2, story 0); Ева добавляет `+1`
- После полного revealed positive/negative set оставшиеся unknown Tags автоматически раскрываются
- Combo: три последовательных успешных разных тега, максимум +1 за свидание
- Game Terms: глобальные жирные термины с tooltip во всех player-facing экранах
- Save version 18: секция `daily_activity`; миграция 17→18 переносит `last_work_day_index` / `last_overtime_day_index` в `work`
- `ObjectiveService` считает текущую сюжетную цель из Stage / Girls / Rivals / Automation; `GuidanceService` показывает first-use tutorial и milestone, не храня игровой прогресс
