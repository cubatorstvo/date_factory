# DATE FACTORY — Master GDD

**Статус:** канон новой `main`  
**Текущий продукт:** Date System Lab — ядро механики свиданий плюс 2D Game Simulator  
**Источник:** пользовательский документ полного перезапуска проекта

## Приоритет

```text
этот документ + docs/DATE_SYSTEM_LAB.md
>
явная последняя инструкция пользователя
>
код новой main
>
архивы legacy-v2 / legacy-v1
```

## Концепция

Date Factory строится вокруг свиданий как главной игровой системы. Игрок выбирает девушку, готовится к встрече, выбирает место и одежду, проходит последовательность эпизодов, реагирует на ситуации через доступные Ходы, постепенно раскрывает предпочтения девушки и развивает собственный арсенал действий.

Экономика, мир, девушки и Rating уже строятся вокруг этого ядра как Game Core-системы. Полноценный 3D free roam подключается к ним позже.

Текущая `main` реализует ядро как:

- `GameSimulator` — самостоятельную 2D-игру над Game Core (`GameState`, `SaveManager`, `TimeService`, `StageService`, `ActionService`);
- комнату разработчика `DateSystemLab` для настройки и тестирования контента свиданий.

Полная спецификация ядра: [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md). High-level Stage 1–4 progression: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).

## Архивы

| Архив | Git | Папка |
|---|---|---|
| Legacy V1 | ветка `legacy-v1` | `../date_factory_legacy` |
| Legacy V2 | ветка `legacy-v2` | `../date_factory_legacy_v2` |

Оба архива read-only. Источник архитектуры новой `main` — этот GDD и Date System Lab, не архивный код.

## Слои

1. **Content Layer** — typed Resources в `res://date_system/content/`
2. **Runtime Progress Layer** — канонический `GameState` прохождения в `user://`; Date System Lab дополнительно хранит тестовый прогресс свиданий в `DateProgressStore`
3. **Date Engine** — детерминированная логика свидания
4. **Text Date Runner** — текстовый 2D-проход DateSession
5. **Game Simulator** — 2D presentation-оболочка прохождения: HUD, навигация, запуск `GameAction` через `ActionService`, без собственной игровой логики
6. **Developer Room** — редактор контента и тестовый запуск Date System

## GameState

Единственное сохраняемое состояние прохождения. Autoload `GameState` владеет секциями; autoload `SaveManager` отвечает за `new_game` / `save_game` / `load_game` / `has_save` / `delete_save`. Autoload `TimeService` продвигает `flow.game_time_minutes` и публикует прошедший интервал. Autoload `ActionService` выполняет статические `GameAction` против текущего прохождения: требования, денежную стоимость через `EconomyService`, эффекты, затем время через `TimeService`. Autoload `EconomyService` — единственная точка изменения `player.money`. Autoload `AutomationService` считает производство клонов по `TimeService.time_advanced`, начисляет деньги через `EconomyService` и Rating через `RatingService`, ведёт экспансию фабрики CITY → COUNTRY → WORLD. Autoload `PurchaseService` создаёт покупки как `GameAction` и отмечает постоянные `purchased_ids`. Autoload `CharacteristicService` читает и пишет `player.muscle` / `appearance` / `capital` / `aura` в диапазоне 0–5; Мышца прокачивается тренажёрами $50 / $35 за 60 минут, остальные характеристики — $300 мгновенно; источник истины — текущее значение, а не `purchased_ids`. Autoload `EquipmentService` хранит купленные Outfit и экипированный `current_outfit_id`. Autoload `ApartmentService` хранит `prepared`, `owned_local_object_ids` и `accent_object_id`. Autoload `WorldService` хранит семантическую локацию прохождения и открытые места; 3D-смена сцен — presentation через `SceneTransitionService`, не Game Action. Autoload `GirlsService` хранит знакомство, контакт, отношения и знание тегов прохождения; знакомство и приглашение на свидание — `GameAction` через `ActionService`; доступность свидания — `DailyActivityService` key `date:<girl_id>`. Autoload `RivalsService` хранит знакомство и победу над соперниками; встреча и соревнование — `GameAction` через `ActionService`. Autoload `CompetitionService` разрешает соревнование с учётом характеристики игрока и фиксирует победу через `RivalsService.defeat_rival()`. Autoload `RatingService` хранит `player.rating`. Autoload `DatingService` связывает Date System с Game Core: передаёт outfit, resolved Local Objects выбранного места и состояние подготовки квартиры. Autoload `ObjectiveService` собирает player-facing цель текущего Story Stage из `StageDefinition`, `GirlsService`, `RivalsService` и `AutomationService`; это runtime-view, а не отдельный прогресс. Autoload `GuidanceService` показывает одноразовые tutorial и milestone текущего прохождения; факт показа хранит секция `GameState.guidance`.

`GameState` хранит только изменяемое состояние конкретного прохождения. Статические определения игрового контента — параметры девушек, предметов, локаций, Stage, цены, базовые характеристики и прочие definitions — хранятся отдельно от `GameState`. `GameState` хранит только ссылки/ID и изменяемый прогресс относительно этих definitions.

Сейчас в секциях живут `flow.game_time_minutes`, `story.stage`, `story.finale_reached`, `player.money`, `player.rating`, `player.muscle` / `appearance` / `capital` / `aura`, `player.last_work_day_index`, `player.career_connections_unlocked`, `player.career_rank`, `progression.purchased_ids`, `progression.current_outfit_id`, `progression.apartment`, `world.current_location_id`, `world.unlocked_location_ids`, `world.city_stage`, `guidance.shown_tutorial_ids`, `guidance.shown_milestone_ids`. День, час и минута вычисляются из абсолютного игрового времени. Кампания идёт по Stage 1–6, затем Finale; текущий Stage и факт Finale хранит `StoryState`. Статические `StageDefinition` живут в `StageCatalog` и несут player-facing `objective_title` / `objective_description`. У каждого Story Stage одна главная Objective: Stage 1–5 строят подцели из реальных meet/date requirements сюжетной девушки, Stage 6 — из текущей экспансии Date Factory. `ObjectiveService` — канонический источник текущей цели и marker `← ЦЕЛЬ`; описания понятий остаются в Game Terms. Stage 1–5 завершаются через MAX отношений сюжетной девушки (`GirlRelationshipRequirement` с `target_relationship = GirlDefinition.relationship_max`), переходы и `on_enter_effects` делает autoload `StageService`. Успешное завершение Stage 6 не создаёт Stage 7: `stage` остаётся 6, `finale_reached = true`. Stage 6 завершается `WorldReachRequirement` (фабрика в другом городе дошла до WORLD 100%). Деньги изменяет autoload `EconomyService`. Характеристики изменяет autoload `CharacteristicService`. Одежду изменяет autoload `EquipmentService`. Квартиру изменяет autoload `ApartmentService`. Rating изменяет autoload `RatingService`. Игровые действия выполняет autoload `ActionService` по статическим definitions `GameAction`. Работа и постоянные покупки — статические definitions (`WorkDefinition`, `PurchaseDefinition`, `CharacteristicUpgradeDefinition`, `ApartmentObjectDefinition`); работа доступна один раз за календарный игровой день (`DailyActivityService` key `work`). `GameState` хранит только деньги, Rating, характеристики, купленные ID, текущий outfit и `progression.apartment` (`prepared`, `owned_local_object_ids`, `accent_object_id`). Локации мира — статические `LocationDefinition` в `LocationCatalog`; `GameState.world` хранит только текущий ID и набор открытых ID. Девушки мира — статические `GirlDefinition` в `GirlCatalog`: authored-набор родного города из 17 девушек, у всех `counts_toward_home_city_coverage = true`, `GirlDefinition.id` совпадает с `GirlProfile.id`. Обычные девушки, Actress, Mine Boss и Magazine Editor имеют диапазон отношений `0..10`, Scientist и President — `0..15`. Filler открываются пачками по Story Stage (`MinStoryStageGirlRequirement`, пустые `date_requirements` у Stage 1 girls): Stage 1 — `alina` / Алина / `city_center`, `vika` / Вика / `cafe`, `dasha` / Даша / `cafe`; Stage 2 — `marina` / Марина / `clothing_store` (Casual exception; MAX даёт один доступный Outfit за `$0`), `katya` / Катя / `furniture_store` (MAX — `Акцент интерьера`), `lera` / Лера / `cafe`; Stage 3 — `kira` / Кира / `cafe`, `olya` / Оля / `restaurant`, `sonya` / Соня / `city_center`; Stage 4 — `nika` / Ника / `cafe`, `rita` / Рита / `restaurant`, `eva` / Ева / `restaurant`. Девушки, доступные начиная со Stage 2, кроме Марины, требуют для свидания Outfit выше Casual. Сюжетные цели Stage 1–5 (MinStage + current-stage filler MAX + Rating; `date_requirements` = `RivalDefeatedGirlRequirement`; MAX сюжетной девушки по-прежнему завершает главу): `girl_actress` / Актриса / `city_center` / Stage 1 + 2 of 3 filler + Rating 2 / `rival_boris`; `girl_mine_boss` / Начальница шахты / `restaurant` / Stage 2 + 2 of 3 filler + Rating 5 / `rival_foreman`; `girl_magazine_editor` / Редактор журнала / `cafe` / Stage 3 + 2 of 3 filler + Rating 8 / `rival_columnist`; `girl_scientist` / Учёная / `city_center` / Stage 4 + 2 of 3 filler + Rating 11 / `rival_academic`; `girl_president` / Президент / `restaurant` / Stage 5 + Rating 12 / `rival_minister`. New Game: Rating 0, `city_stage = 1`; каждый MAX authored-девушки даёт +1 Rating. Ритм: две filler-линии Stage 1 → Actress+Stage 2+City Stage 2+Café/Leisure DateVenues+Clothing Store+«Приоденься» → две filler-линии Stage 2 / Марина в Casual → MineBoss+Stage 3 (City Stage 2, Restaurant DateVenue, Outfit Moves, Career Connections для Rank 2–3; Rank 1 доступен раньше при Capital 1) → две filler-линии Stage 3 → Editor+Stage 4+City Stage 3+12-Tag Apartment cap → две filler-линии Stage 4 → Scientist+Stage 5+Factory+Rating 12 → President+Stage 6. `GameState.girls` хранит `GirlState` по ID (`discovered`, `has_contact`, `relationship`, раскрытые теги, `completed_dates`, `last_date_situation_ids`). Доступность следующего свидания: `DailyActivityService` key `date:<girl_id>` (1 бесплатный слот в календарный день, следующий слот завтра; Рита — `$75` за extra same-day). `GirlDefinition.location_id` — где девушка находится в мире. Доступ к знакомству и свиданиям задают статические `meet_requirements` / `date_requirements` (`GirlAccessRequirement`: Rating, Stage, победа над Rival и будущие типы). Они не сериализуются в save: после load доступность считается заново из `Rating`, `Stage`, `RivalState` и `GirlState`. Место свидания — отдельный `DateVenue`, выбранный игроком. `GameState.dating` хранит активное свидание (`girl_id`, `venue_id`, `outfit_id`, `started_at_game_time`). `GameState.rivals` хранит `RivalState` по ID (`discovered`, `defeated`, `last_challenge_completed_at`); definitions живут в `RivalCatalog` / `CompetitionCatalog`. Сюжетный `RivalDefinition.linked_girl_id` показывает соперника только после `GirlsService.is_discovered(linked_girl_id)`. Сюжетный соперник (`linked_girl_id != ""`) до первой победы допускает повтор сразу; после победы линия вызова завершена (`defeated = true`). Filler-rivals имеют пустой `linked_girl_id` и `minimum_story_stage`; вызов списывает `entry_fee` 100 и при победе выплачивает 200; после любой попытки действует дневной слот `rival:<rival_id>`, и соперник остаётся repeatable. `automation` хранит unlock фабрики, клонов, один процент распределения Work, дробное производство Rating, текущий масштаб экспансии и купленные automation upgrade ID; definitions upgrades живут в `AutomationCatalog`. Фабрика открывается `on_enter_effects` Stage 5 после MAX Учёной и сюжетно стоит в другом городе; она не завершает девушек родного города. DateVenue availability: Stage 1 — Apartment; Stage 2 — Apartment + Café + Leisure Center; Stage 3 — плюс Restaurant. `restaurant` как мировая локация знакомства (Начальница шахты, Оля, позже Президент) открывается при входе в Stage 2; как DateVenue — на Stage 3. Стартовый набор мировых локаций: `city_center` + `apartment` + `cafe`. Café как DateVenue и Leisure Center открываются на Stage 2 вместе с Clothing Store (Марина). High-level contract: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md). Охват родного города считается из `GirlDefinition.counts_toward_home_city_coverage` и реальных `GirlState`, без persistent поля. Игровой пропуск до утра — `GameAction` `skip_to_08_00` («Пропустить до 08:00», 0 денег) в разделе Квартира: `TimeService.minutes_until_next_morning(game_time_minutes)` считает минуты до ближайших будущих 08:00 (если сейчас раньше 08:00 — до 08:00 текущего дня; если уже 08:00 или позже — до 08:00 следующего дня), затем `ActionService` проводит этот интервал через `TimeService.advance_time`. Тот же расчёт предназначен для будущей интеракции с кроватью в 3D. `test_wait` остаётся 120-минутным test/dev-контентом. `DateProgressStore` остаётся прогрессом лаборатории; в прохождении знание тегов и отношения живут в `GirlState`.

`DateSession.stage` — стадия эпизода свидания, не `StoryState.stage`.

## Главная формула эпизода

```text
СИТУАЦИЯ
→ БАЗОВЫЕ + ХОДЫ ХАРАКТЕРИСТИКИ + ЛОКАЛЬНЫЕ ХОДЫ
→ ВЫБОР ОДНОГО ХОДА
→ ТЕГ
→ ПРЕДПОЧТЕНИЕ ДЕВУШКИ
→ +1 / -1
```

Opening, Core и Closing дают `+1` / `-1` по предпочтению девушки. Итог свидания:

```text
Raw Date Score = сумма пяти эпизодов + Combo + Girl Trait + Apartment Preparation
Relationship Gain = max(Raw Date Score, 0)
Relationship After = min(Relationship Before + Relationship Gain, Relationship Max)
```

Combo: три последовательных успешных хода с тремя разными тегами дают `+1`, максимум один раз за свидание. Каждая девушка имеет ровно один Trait (характеристика героя или место свидания). При первом знакомстве обычная девушка раскрывает 2 случайных Tag, сюжетная — 0; награда Евы даёт глобальный `+1`. Filler MAX улучшает уже доступные системы, Story MAX расширяет игру.

Игрок получает три источника решений в каждом эпизоде: три из шести situation-owned BASE (baseline 30 Situations / 180 BASE), ходы характеристики через `EffectiveStat` и Outfit/Local как отдельные источники по одному использованию за свидание. Characteristic и Outfit Moves не зависят от Situation. Reward Вики один раз за свидание меняет shown-тройку на оставшиеся три BASE той же Situation. Единственный score от места: подготовленная квартира `0`, неподготовленная `-1`. Наряд даёт максимум `+1` к одной характеристике; Outfit Move появляется на Stage 3. Универсального `Outfit.score_bonus` нет. Player-facing текст использует глобальные Game Terms: жирный термин и tooltip.

Venue — это toolkit. Место свидания не имеет общего quality/preference score и не рекомендуется автоматически. Его игровая ценность определяется Local Objects и, отдельно, Trait места конкретной девушки. Stage 1 использует только Apartment с 0 Local Moves; Local Source и Venue choice появляются на Stage 2 (Café, Leisure Center); Restaurant — на Stage 3. Apartment — единственный player-developed DateVenue: 12 объектов × 1 unique Tag × 1 Local Move, покрытие `0 → 4 → 8 → 12`. Каждый Local Object предоставляет фиксированный набор тегированных ходов и расходуется целиком после одного использования за свидание. На экране выбора места игрок сам сравнивает уже известные предпочтения девушки с тегами Local Moves выбранного toolkit. High-level Stage 1–4: [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md).
