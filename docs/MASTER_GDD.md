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

Полная спецификация ядра: [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md).

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

Единственное сохраняемое состояние прохождения. Autoload `GameState` владеет секциями; autoload `SaveManager` отвечает за `new_game` / `save_game` / `load_game` / `has_save` / `delete_save`. Autoload `TimeService` продвигает `flow.game_time_minutes` и публикует прошедший интервал. Autoload `ActionService` выполняет статические `GameAction` против текущего прохождения: требования, денежную стоимость через `EconomyService`, эффекты, затем время через `TimeService`. Autoload `EconomyService` — единственная точка изменения `player.money`. Autoload `AutomationService` считает производство клонов по `TimeService.time_advanced`, начисляет деньги через `EconomyService` и Rating через `RatingService`, ведёт экспансию фабрики CITY → COUNTRY → WORLD. Autoload `PurchaseService` создаёт покупки как `GameAction` и отмечает постоянные `purchased_ids`. Autoload `CharacteristicService` читает и пишет `player.muscle` / `appearance` / `capital` / `aura`. Autoload `EquipmentService` хранит owned/equipped outfits. Autoload `ApartmentService` хранит уровень квартиры, купленные upgrades и подготовку (`prepared`). Autoload `WorldService` хранит семантическую локацию прохождения и открытые места; 3D-смена сцен — presentation через `SceneTransitionService`, не Game Action. Autoload `GirlsService` хранит знакомство, контакт, отношения и cooldown свиданий прохождения; знакомство и приглашение на свидание — `GameAction` через `ActionService`. Autoload `RivalsService` хранит знакомство и победу над соперниками; встреча и соревнование — `GameAction` через `ActionService`. Autoload `CompetitionService` разрешает соревнование с учётом характеристики игрока и фиксирует победу через `RivalsService.defeat_rival()`. Autoload `RatingService` хранит `player.rating`. Autoload `DatingService` связывает Date System с Game Core: передаёт outfit, resolved Local Objects выбранного места и состояние подготовки квартиры.

`GameState` хранит только изменяемое состояние конкретного прохождения. Статические определения игрового контента — параметры девушек, предметов, локаций, Stage, цены, базовые характеристики и прочие definitions — хранятся отдельно от `GameState`. `GameState` хранит только ссылки/ID и изменяемый прогресс относительно этих definitions.

Сейчас в секциях живут `flow.game_time_minutes`, `story.stage`, `story.finale_reached`, `player.money`, `player.rating`, `player.muscle` / `appearance` / `capital` / `aura`, `progression.purchased_ids`, `progression.owned_outfit_ids`, `progression.equipped_outfit_id`, `progression.apartment`, `world.current_location_id`, `world.unlocked_location_ids`. День, час и минута вычисляются из абсолютного игрового времени. Кампания идёт по Stage 1–6, затем Finale; текущий Stage и факт Finale хранит `StoryState`. Статические `StageDefinition` живут в `StageCatalog`; Stage 1–5 завершаются через MAX отношений сюжетной девушки (`GirlRelationshipRequirement` с `target_relationship = GirlDefinition.relationship_max`), переходы и `on_enter_effects` делает autoload `StageService`. Успешное завершение Stage 6 не создаёт Stage 7: `stage` остаётся 6, `finale_reached = true`. Stage 6 завершается `WorldReachRequirement` (фабрика в другом городе дошла до WORLD 100%). Деньги изменяет autoload `EconomyService`. Характеристики изменяет autoload `CharacteristicService`. Одежду изменяет autoload `EquipmentService`. Квартиру изменяет autoload `ApartmentService`. Rating изменяет autoload `RatingService`. Игровые действия выполняет autoload `ActionService` по статическим definitions `GameAction`. Работа и постоянные покупки — статические definitions (`WorkDefinition`, `PurchaseDefinition`, `CharacteristicUpgradeDefinition`, `ApartmentUpgradeDefinition`); `GameState` хранит только деньги, Rating, характеристики, купленные ID, owned/equipped outfits и `progression.apartment` (уровень, купленные upgrades, `prepared`). Локации мира — статические `LocationDefinition` в `LocationCatalog`; `GameState.world` хранит только текущий ID и набор открытых ID. Девушки мира — статические `GirlDefinition` в `GirlCatalog`: authored-набор родного города из 10 девушек, у всех `counts_toward_home_city_coverage = true`, диапазон отношений `-5..+5`, `GirlDefinition.id` совпадает с `GirlProfile.id`. Filler (только Rating, пустые `date_requirements`): `alina` / Алина / `city_center` / Rating 0; `vika` / Вика / `cafe` / Rating 2; `katya` / Катя / `city_center` / Rating 4; `lera` / Лера / `city_center` / Rating 6; `sonya` / Соня / `city_center` / Rating 8 (после Factory — ручная альтернатива первому Automation Rating для доступа к Президенту). Сюжетные цели Stage 1–5 (MinStage + Rating; `date_requirements` = `RivalDefeatedGirlRequirement`; MAX сюжетной девушки по-прежнему завершает главу): `girl_actress` / Актриса / `city_center` / Stage 1 + Rating 1 / `rival_boris`; `girl_mine_boss` / Начальница шахты / `restaurant` / Stage 2 + Rating 3 / `rival_foreman`; `girl_magazine_editor` / Редактор журнала / `cafe` / Stage 3 + Rating 5 / `rival_columnist`; `girl_scientist` / Учёная / `city_center` / Stage 4 + Rating 7 / `rival_academic`; `girl_president` / Президент / `restaurant` / Stage 5 + Rating 9 / `rival_minister`. New Game: Rating 0; каждый MAX authored-девушки даёт +1 Rating. Ручной путь: Alina → Actress+Stage 2 → Vika → MineBoss+Stage 3 → Katya → Editor+Stage 4 → Lera → Scientist+Stage 5+Factory → Sonya или Factory +1 Rating → President+Stage 6. `GameState.girls` хранит `GirlState` по ID (`discovered`, `has_contact`, `relationship`, `next_date_available_at`, раскрытые теги, `secondary_revealed`, `completed_dates`). `GirlDefinition.location_id` — где девушка находится в мире. Доступ к знакомству и свиданиям задают статические `meet_requirements` / `date_requirements` (`GirlAccessRequirement`: Rating, Stage, победа над Rival и будущие типы). Они не сериализуются в save: после load доступность считается заново из `Rating`, `Stage`, `RivalState` и `GirlState`. Место свидания — отдельный `DateLocation`, выбранный игроком. `GameState.dating` хранит активное свидание (`girl_id`, `location_id`, `outfit_id`, `started_at_game_time`). `GameState.rivals` хранит `RivalState` по ID (`discovered`, `defeated`); definitions живут в `RivalCatalog` / `CompetitionCatalog`; `RivalDefinition.linked_girl_id` связывает соперника с сюжетной девушкой, и `RivalsService.get_rivals_at_current_location` показывает его только после `GirlsService.is_discovered(linked_girl_id)`. `automation` хранит unlock фабрики, клонов, один процент распределения Work, дробное производство Rating, текущий масштаб экспансии и купленные automation upgrade ID; definitions upgrades живут в `AutomationCatalog`. Фабрика открывается `on_enter_effects` Stage 5 после MAX Учёной и сюжетно стоит в другом городе; она не завершает девушек родного города. `restaurant` открывается `UnlockLocationStageEffect` при входе в Stage 2; стартовый набор остаётся `city_center` + `apartment` + `cafe`. Охват родного города считается из `GirlDefinition.counts_toward_home_city_coverage` и реальных `GirlState`, без persistent поля. Игровой пропуск до утра — `GameAction` `skip_to_08_00` («Пропустить до 08:00», 0 денег) в разделе Квартира: `TimeService.minutes_until_next_morning(game_time_minutes)` считает минуты до ближайших будущих 08:00 (если сейчас раньше 08:00 — до 08:00 текущего дня; если уже 08:00 или позже — до 08:00 следующего дня), затем `ActionService` проводит этот интервал через `TimeService.advance_time`. Тот же расчёт предназначен для будущей интеракции с кроватью в 3D. `test_wait` остаётся 120-минутным test/dev-контентом. `DateProgressStore` остаётся прогрессом лаборатории; в прохождении знание тегов и отношения живут в `GirlState`.

`DateSession.stage` — стадия эпизода свидания, не `StoryState.stage`.

## Главная формула эпизода

```text
СИТУАЦИЯ
→ БАЗОВЫЕ + ОТКРЫВАЕМЫЕ + ЛОКАЛЬНЫЕ ХОДЫ
→ ВЫБОР ОДНОГО ХОДА
→ ТЕГ
→ ПРЕДПОЧТЕНИЕ ДЕВУШКИ
→ +1 / -1
```

Opening, Core и Closing дают `+1` / `-1` по предпочтению девушки. Secondary, наряд и подготовка квартиры входят в итоговый счёт после Closing.

Venue — это toolkit. Место свидания не имеет общего quality/preference score и не рекомендуется автоматически. Его игровая ценность определяется Local Objects. Каждый Local Object предоставляет фиксированный набор тегированных ходов и расходуется целиком после одного использования за свидание. На экране выбора места игрок сам сравнивает уже известные предпочтения девушки с тегами Local Moves выбранного toolkit.

Игрок получает три источника решений в каждом эпизоде: случайные BASE под ситуацию, UNLOCKABLE через прокачку героя и постоянные LOCAL ходы объектов выбранного места. LOCAL не зависят от Situation и не резервируют теги BASE. Единственный score от места: подготовленная квартира `0`, неподготовленная `-1`. Одежда остаётся линейным `Outfit.score_bonus` (casual `0`, business `+1`, luxury `+2`) без предпочтений конкретной девушки.
