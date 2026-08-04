# DATE FACTORY — Acceptance Matrix

Поведение в **запущенной игре**. Статусы: `UNTESTED` | `PASS` | `FAIL` | `BLOCKED`.

Связь с этапами плана: id проверки `M-<этап>.<n>`.

---

## M-1 Baseline

### M-1.1 Проект стартует
- **Старт:** открыть проект, Play boot
- **Действия:** дождаться main/world
- **Визуал:** HUD/мир без красных ошибок парсера
- **Данные:** `Game.run_started` или эквивалент активного рана
- **Save:** не требуется
- **Запрещено:** игнор SCRIPT_ERRORS
- **Статус:** UNTESTED

### M-1.2 Save API жив
- **Старт:** новый ран
- **Действия:** сохранить и загрузить через существующий UI/flow
- **Данные:** stage/economy восстанавливаются
- **Статус:** UNTESTED

---

## M-2 Наблюдения и гипотезы

### M-2.1 Observation до реплики
- **Старт:** ручное свидание с уникалкой, черта не подтверждена
- **Действия:** открыть фазу
- **Визуал:** текст наблюдения-факта (не название черты); 3 реплики без имён черт
- **Данные:** observation добавлена в журнал девушки
- **Запрещено:** мгновенный label «Пунктуальность» на кнопке; reveal до выбора
- **Статус:** PASS (2026-08-03 runtime)

### M-2.2 Выбор = гипотеза
- **Старт:** после M-2.1
- **Действия:** выбрать реплику с верной интерпретацией
- **Визуал:** реакция девушки; запись гипотезы в UI/toast
- **Данные:** hypothesis active/confirmed-pending; trait ещё не в confirmed (после первого раза)
- **Запрещено:** полное раскрытие черты с первого верного ответа
- **Статус:** PASS (2026-08-03 runtime)

### M-2.3 Второе подтверждение
- **Старт:** одна верная гипотеза по черте уже есть
- **Действия:** другое наблюдение той же оси, снова верная интерпретация
- **Визуал:** презентация подтверждённой черты
- **Данные:** trait в confirmed/revealed_traits; гипотеза → confirmed
- **Статус:** PASS (2026-08-03 runtime)

### M-2.4 Ошибочная гипотеза
- **Старт:** observation
- **Действия:** выбрать неверную интерпретацию
- **Данные:** hypothesis rejected; правильная черта НЕ добавлена в confirmed
- **Визуал:** негативная/сомнительная реакция; факт остаётся
- **Статус:** PASS (2026-08-03 runtime)

### M-2.5 Bond ≠ знание
- **Старт:** верная интерпретация с грубым качеством (если разделено) или wrong vs correct bond deltas
- **Данные:** bond меняется по качеству; confirmed только по правилам гипотез
- **Статус:** PASS (2026-08-03 runtime)

### M-2.6 Save знаний
- **Старт:** после гипотезы/confirm
- **Действия:** save → reload
- **Данные:** observations/hypotheses/confirmed сохранены
- **Статус:** PASS (2026-08-03 to_dict; fields persist in entry)

---

## M-3 Ручное свидание / обучение

### M-3.1 Три ситуации + завершение
- **Статус:** PASS (2026-08-03) — 3 фазы, finish, grade; intro walk в date_stage

### M-3.2 Обучение первого свидания
- **Статус:** PASS — coach text + `date_hypothesis_taught` flag + feedback после выбора

### M-3.3 Физический приход (минимум date_stage)
- **Статус:** PASS (partial) — intro walk / outro leave в `date_stage`; doorbell path для home

### M-3.4 Бронь места и времени в телефоне
- **Действия:** Phone → место → слот времени → confirm
- **Данные:** `DateSchedule` booking; HUD countdown
- **Запрещено:** silent auto-book первого слота при открытом телефоне
- **Статус:** PASS (2026-08-04 GodotIQ)

### M-3.5 Home prep + optional gift + Finish + 5 факторов
- **Действия:** еда/напиток на стол → doorbell/start → mid-date gift (опц.) → Finish → панель факторов
- **Запрещено:** обязательный подарок; авто-закрытие UI после последней фазы
- **Статус:** PASS (2026-08-04 must-fix)

### M-3.6 Выход к фасаду дома / раздельные локации
- **Действия:** `go_outside` → спавн у `HomeEntrance`; `go_home` → у двери квартиры; city и home не сосуществуют в tree
- **Статус:** PASS (2026-08-04 GodotIQ) — `travel_to` exclusive loads; см. [DATING_AND_WORLD.md](DATING_AND_WORLD.md)

---

## M-4 Журнал телефона

### M-4.1 Разделы журнала
- **Статус:** PASS — вкладка Journal

### M-4.2 Уверенность авто
- **Статус:** PASS — % авто в журнале

---

## M-5 Авто и знания

### M-5.1 Изученная стабильнее
- **Статус:** PASS — confidence → score/bond

### M-5.2 Режимы риска
- **Статус:** PASS — careful/standard/risk + save

---

## M-6 Легенда

### M-6.1 Отдельно от scandal
- **Статус:** PASS — два ресурса; scandal↑ не бьёт legend

### M-6.2 Падение легенды
- **Статус:** PASS — damage_legend; clone slip; event `legend` delta; pressure по band

---

## M-7 Приёмка дубля

### M-7.1 Не кнопка +1
- UNTESTED — сцена капсулы + осмотр

### M-7.2 Решения
- UNTESTED — approve / rework / scrap / conditional

### M-7.3 Часы/память проверяемы
- UNTESTED — видимый дефект на stub

---

## M-8 Дефекты

### M-8.1 Пропуск → событие
- PASS — deferred_hits → runtime event (look: legend 100→92, scandal 2.0); не −% quality alone

### M-8.2 Исправление
- PASS — rework: clones=0 deferred=0; mark_defect снимает из latent на approve

---

## M-9 Параллель

### M-9.1 Два свидания + риск встречи
- PASS — careful reroute cafe→restaurant; risk legend 100→95; routes shared city_east

---

## M-10 Приход/уход

### M-10.1 Pipeline двери
- PASS — ArrivalPipeline door→seat→door; assert anti spawn-sitting; harem door→slot tween

---

## M-11 Кризисы

### M-11.1 Пространственное решение
- PASS — hotspot Interactable `crisis_fix` (не текст «решить»); timer; legend fail/ok; 8 каталог

---

## M-12 Орбита 100%

### M-12.1 Присутствие в мире
- PASS — mansion «Орбита:»; visit bonus; late personal event every 3rd visit; orbit_help hotspot in crises

---

## M-13 Стадии

### M-13.1 Шесть стадий достижимы
- PASS — ContentDB 6 stages loaded

### M-13.2 Stage 3 = штаб (нейминг)
- PASS — «Операционный штаб»; quests/doors/room without «агентство»

---

## M-14 Финал

### M-14.1 Алгоритм + титры + постгейм
- PASS — legend gate; pre-finale spatial crisis; start_postgame flags; FinaleUI credits copy

---

## M-15 Presentation

### M-15.1 Нестандартный UI / SFX / 4 типа попапов
- PASS — notify/warn/reveal/decision + present_trait/girl/stage/clone; SFX profiles; ThemeFactory

---

## M-16 Полный прогон

### M-16.1 Start→credits
- PASS — neighbor→stages→clones→megamachine→algorithm date→postgame→FinaleUI

### M-16.2 Save на 3 стадиях
- PASS — save/load roundtrip на stage_2, stage_4, stage_6 + postgame reload

---

## M-17 Коллективное влияние черт

> Канон: [11_TRAIT_INFLUENCE.md](11_TRAIT_INFLUENCE.md). План: [TRAIT_INFLUENCE_PLAN.md](TRAIT_INFLUENCE_PLAN.md).

### M-17.1 Единицы влияния только при confirmed + 100%
- PASS — headless `tools/playtest_m17.gd` (claim+reveal → recount ≥10); GodotIQ editor attach flaky (debugger)

### M-17.2 Нет случайных пассивок массовых
- PASS — city/mass исключены из `active_effects()`; уникалки через author mods / ContentDB, не random mass

### M-17.3 Порог 10 — выбор ветки
- PASS — playtest_m17: choose_branch A + deepen + save/load

### M-17.4 Ограниченные синергии
- PASS — playtest_m17: reinvest active + load_synergy

### M-17.5 Поиск повышает вероятность, не гарантирует тег
- PASS (bias ~2× vs baseline; soft_signal без метки черты; T6 smoke)

### M-17.6 Caps и авто (§26 / §27)
- PASS — playtest_m17: money/gift caps, unique auto blocked, simple auto allowed, thrift divert/reserve

---

## Недопустимые упрощения (глобально)
- Класс без игрового сценария  
- UI без логики  
- Debug-only доступ  
- Текстовый кризис вместо FPS  
- Телепорт персонажа  
- Мгновенный reveal черты  
- Числовой штраф вместо события дефекта  
- Механика только на одной тестовой девушке без общего API  
- TODO вместо реализации  
- Только happy path  
