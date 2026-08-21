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

- `GirlProgress`, `TestPlayerState` и replay snapshot хранятся в `user://date_system/`
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
- `WorldState.city_stage` 1–3; social cooldown 3/2/1 дня для девушек и соперников
- Filler-девушки и filler-rivals открываются пачками City Stage; сюжетные цели — Stage + Rating
- Работа 100/ч, затем 200/ч после Story Stage 3; один shift на календарный игровой день
- Одежда — набор купленных Outfit, экипировка перед свиданием, максимум `+1` к одной характеристике; тематический наряд даёт Outfit Move
- Обычные девушки `0..10`, сюжетные `0..15`
- Combo: три последовательных успешных разных тега, максимум +1 за свидание
- Game Terms: глобальные жирные термины с tooltip во всех player-facing экранах
- Story rival: повтор сразу до первой победы; filler rival: City Stage cooldown и остаётся repeatable
- Save version 16: секция `guidance` (`shown_tutorial_ids`, `shown_milestone_ids`); v15→v16 только добавляет пустую guidance, остальной прогресс не преобразуется
- `ObjectiveService` считает текущую сюжетную цель из Stage / Girls / Rivals / Automation; `GuidanceService` показывает first-use tutorial и milestone, не храня игровой прогресс
