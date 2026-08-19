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

Единственное сохраняемое состояние прохождения. Autoload `GameState` владеет секциями; autoload `SaveManager` отвечает за `new_game` / `save_game` / `load_game` / `has_save` / `delete_save`. Autoload `TimeService` продвигает `flow.game_time_minutes` и публикует прошедший интервал. Autoload `ActionService` выполняет статические `GameAction` против текущего прохождения: требования, денежную стоимость через `EconomyService`, эффекты, затем время через `TimeService`. Autoload `EconomyService` — единственная точка изменения `player.money`. Autoload `PurchaseService` создаёт покупки как `GameAction` и отмечает постоянные `purchased_ids`. Autoload `WorldService` хранит семантическую локацию прохождения и открытые места; 3D-смена сцен — presentation через `SceneTransitionService`, не Game Action. Autoload `GirlsService` хранит знакомство, контакт, отношения и cooldown свиданий прохождения; знакомство и приглашение на свидание — `GameAction` через `ActionService`. Autoload `RivalsService` хранит знакомство и победу над соперниками; встреча и соревнование — `GameAction` через `ActionService`. Autoload `CompetitionService` разрешает соревнование и фиксирует победу через `RivalsService.defeat_rival()`. Autoload `RatingService` хранит `player.rating`. Autoload `DatingService` связывает Date System с Game Core.

`GameState` хранит только изменяемое состояние конкретного прохождения. Статические определения игрового контента — параметры девушек, предметов, локаций, Stage, цены, базовые характеристики и прочие definitions — хранятся отдельно от `GameState`. `GameState` хранит только ссылки/ID и изменяемый прогресс относительно этих definitions.

Сейчас в секциях живут `flow.game_time_minutes`, `story.stage`, `story.finale_reached`, `player.money`, `player.rating`, `progression.purchased_ids`, `world.current_location_id`, `world.unlocked_location_ids`. День, час и минута вычисляются из абсолютного игрового времени. Кампания идёт по Stage 1–6, затем Finale; текущий Stage и факт Finale хранит `StoryState`, переходы делает autoload `StageService`. Деньги изменяет autoload `EconomyService`. Rating изменяет autoload `RatingService`. Игровые действия выполняет autoload `ActionService` по статическим definitions `GameAction`. Работа и постоянные покупки — статические definitions (`WorkDefinition`, `PurchaseDefinition`); `GameState` хранит только деньги, Rating и купленные ID. Локации мира — статические `LocationDefinition` в `LocationCatalog`; `GameState.world` хранит только текущий ID и набор открытых ID. Девушки мира — статические `GirlDefinition` в `GirlCatalog` с теми же ID, что Date System (`alina`, `vika`); `GameState.girls` хранит `GirlState` по ID (`discovered`, `has_contact`, `relationship`, `next_date_available_at`, раскрытые теги, `secondary_revealed`, `completed_dates`). `GameState.dating` хранит активное свидание (`girl_id`, `started_at_game_time`). `GameState.rivals` хранит `RivalState` по ID (`discovered`, `defeated`); definitions живут в `RivalCatalog` / `CompetitionCatalog`. `automation` — пустой каркас. `DateProgressStore` остаётся прогрессом лаборатории; в прохождении знание тегов и отношения живут в `GirlState`.

`DateSession.stage` — стадия эпизода свидания, не `StoryState.stage`.

## Главная формула эпизода

```text
СИТУАЦИЯ
→ ДОСТУПНЫЕ ХОДЫ
→ ВЫБОР ХОДА
→ СИТУАЦИЯ + ХОД
→ КОНТЕКСТНЫЙ ТЕГ
→ ПРЕДПОЧТЕНИЕ ДЕВУШКИ
→ +1 / -1
```

Opening даёт разведку и `0` очков. Core и Closing дают `+1` / `-1`. Secondary, место, наряд и квартира входят в итоговый счёт после Closing.
