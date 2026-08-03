# DATE FACTORY — Implementation Plan

Источник требований: мастер-документ (сжат в `docs/01`–`10`) + `docs/ACCEPTANCE_MATRIX.md`.  
Статусы: `NOT_STARTED` | `IN_PROGRESS` | `IMPLEMENTED` | `VERIFIED` | `BLOCKED`.

Обновлять после каждого этапа. Не спрашивать пользователя «какой блок дальше» — идти по порядку.

---

## Этап 0 — Управление работой
**Статус:** `VERIFIED`  
**GDD:** этот файл + STATE + MATRIX  
**Результат:** три постоянных документа; возобновление сессий без выбора A/B/C.

| ID | Подзадача | Статус |
|----|-----------|--------|
| 0.1 | `IMPLEMENTATION_PLAN.md` | VERIFIED |
| 0.2 | `IMPLEMENTATION_STATE.md` | VERIFIED |
| 0.3 | `ACCEPTANCE_MATRIX.md` | VERIFIED |

---

## Этап 1 — Аудит и контрольная точка
**Статус:** `VERIFIED`  
**GDD:** `04_SYSTEMS` (колонка «Сейчас»)  
**Системы:** весь каркас  
**Проверяемый результат:** зафиксированный снимок возможностей; проект компилируется (0 parse errors); сейв API на месте.

| ID | Подзадача | Зависимости | Статус |
|----|-----------|-------------|--------|
| 1.1 | Инвентаризация dating/traits/bond/clones/economy/events/save | — | VERIFIED |
| 1.2 | Зафиксировать gaps в STATE | 1.1 | VERIFIED |
| 1.3 | `check_errors` project = 0 | — | VERIFIED |
| 1.4 | Smoke play boot (если runtime доступен) | 1.3 | VERIFIED |

**Приёмка этапа:** STATE описывает baseline; можно начинать этап 2 без потери прогресса.

---

## Этап 2 — Наблюдения, интерпретации, гипотезы, подтверждённые черты
**Статус:** `VERIFIED`  
**GDD:** `06_TRAITS_AND_BOND`  
**Системы:** `GirlsAPI`, `DatingAPI`, `TraitsContent`, `ContentDB`, save  
**Результат:** знание идёт по цепочке неизвестно → наблюдение → гипотеза → подтверждение; мгновенный reveal по correct/wrong убран.

| ID | Подзадача | Зависимости | Файлы | Статус |
|----|-----------|-------------|-------|--------|
| 2.1 | Модель данных: observations[], hypotheses[], confirmed traits | 1 | `girls_api.gd` | VERIFIED |
| 2.2 | Контент: observation text + 3 interpretations (скрытый trait_id) | 2.1 | `traits_content.gd` | VERIFIED |
| 2.3 | Dating: показ observation; выбор = гипотеза; 2× разные obs → confirm | 2.2 | `dating_api.gd` | VERIFIED |
| 2.4 | Bond отдельно от знания (качество ответа) | 2.3 | `dating_api.gd`, balance | VERIFIED |
| 2.5 | Save/load новых полей | 2.1 | `girls_api` to/from_dict | VERIFIED |
| 2.6 | Миграция старых saves (revealed → confirmed) | 2.5 | `girls_api` | VERIFIED |
| 2.7 | Playtest: одно свидание создаёт observation+hypothesis | 2.3–2.6 | — | VERIFIED |

**Приёмка:** см. MATRIX §2. Недопустимо: мгновенное раскрытие черты после одного wrong/correct; подписи черт на кнопках.  
**Проверено 2026-08-03:** M-2.1…M-2.6 PASS (runtime exec). Убрано free-seed `revealed_traits` через insight.

---

## Этап 3 — Полное ручное свидание и обучение
**Статус:** `VERIFIED`  
**GDD:** `06` §5, §12; `08` приход  
**Системы:** `date_ui`, `date_stage`, tutorial quests  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 3.1 | Структура: приход-сигнал + 3 ситуации + завершение | VERIFIED |
| 3.2 | Мягкое обучение первого свидания (объяснение гипотезы) | VERIFIED |
| 3.3 | Реакция девушки + emotion FX | VERIFIED |
| 3.4 | Playtest соседки end-to-end | VERIFIED |

**Проверено:** 3 фазы → grade; coach UI; feedback/hypothesis taught flag; save/reload obs/hyps; date_stage intro walk.

---

## Этап 4 — Журнал девушки в телефоне
**Статус:** `VERIFIED`  
**GDD:** `06` §7  
**Системы:** `phone_ui`, `GirlsAPI`  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 4.1 | Вкладка/панель: факты, гипотезы, подтверждённые, история | VERIFIED |
| 4.2 | Индикатор уверенности автоматики | VERIFIED |
| 4.3 | Playtest открытие журнала после свидания | VERIFIED |

---

## Этап 5 — Знания → автосвидания
**Статус:** `VERIFIED`  
**GDD:** `06` §8  
**Системы:** `DatingAPI` auto, prep pickers  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 5.1 | Качество авто от confirmed (+ риск от hypotheses) | VERIFIED |
| 5.2 | Режимы: осторожный / стандарт / риск (настройка/телефон) | VERIFIED |
| 5.3 | Видимость авто в мире (минимум индикатор + движение stub→улучшить на 10–11) | VERIFIED |
| 5.4 | Playtest: изученная vs неизвестная девушка | VERIFIED |

**Примечание 5.3:** индикатор в телефоне Schedule; пространственное движение авто — этапы 9–11.

---

## Этап 6 — Целостность легенды
**Статус:** `VERIFIED`  
**GDD:** `07` §11–12; `02`  
**Системы:** `EconomyAPI`, HUD, events, dating clone errors  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 6.1 | Ресурс `legend` 0–100 отдельно от scandal | VERIFIED |
| 6.2 | HUD + save | VERIFIED |
| 6.3 | Хуки изменения (заготовки под дефекты/кризисы) | VERIFIED |
| 6.4 | Уровни high/mid/low/crisis влияют на частоту событий | VERIFIED |

**Проверено:** scandal↑ не трогает legend; damage_legend не трогает scandal; bands + event_pressure_mult; save.

---

## Этап 7 — Создание и приёмка первого дубля
**Статус:** `VERIFIED`  
**GDD:** `07` §2–4; `03` stage_4  
**Системы:** `ClonesAPI`, `clone_accept_ui`, phone, lab interact  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 7.1 | Сцена капсулы / терминал приёмки (не кнопка +1) | VERIFIED |
| 7.2 | Чеклист осмотра первого дубля | VERIFIED |
| 7.3 | Выпуск только после приёмки | VERIFIED |
| 7.4 | Playtest первого дубля | VERIFIED |

**Проверено:** begin_acceptance → 6 шагов → approve; latent_defects; available только approved/conditional. 3D капсула-церемония — stub UI (углубить на 10/15).

---

## Этап 8 — Дефекты дублей и отложенные последствия
**Статус:** `VERIFIED`  
**GDD:** `07` §5–7  
**Системы:** `ClonesAPI.deferred_hits`, `EventsAPI.open_runtime_event`  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 8.1 | Пропущенный дефект → отложенное событие | VERIFIED |
| 8.2 | Категории look/time/motion/schedule/memory/stability | VERIFIED |
| 8.3 | Rework не деплоит; mark снимает из latent | VERIFIED |
| 8.4 | Playtest: latent → runtime event → legend/scandal | VERIFIED |

**Проверено:** `opened=true name='Последствие пропуска: Волосы' legend=100→92 scandal=2.0`; rework clones=0 deferred=0; approve latent→deferred_q.

---

## Этап 9 — Расписание, синхронизация, параллельные свидания
**Статус:** `VERIFIED`  
**GDD:** `07` §10; `03` 4C  
**Системы:** venue `route`, `DatingAPI` parallel collision, facility slots  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 9.1 | Модель маршрутов/слотов залов | VERIFIED |
| 9.2 | Параллель игрок+дубль с риском встречи | VERIFIED |
| 9.3 | Playtest первой параллели | VERIFIED |

**Проверено:** routes cafe/park=`city_east`; careful `cheap_cafe→restaurant` runs=1; risk legend 100→95.

---

## Этап 10 — Физический приход/уход
**Статус:** `VERIFIED`  
**GDD:** `08` §5; `09`  
**Системы:** `ArrivalPipeline`, `date_stage`, harem spawn walk  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 10.1 | Унифицированный arrival pipeline (дверь→путь→посадка) | VERIFIED |
| 10.2 | Departure + возврат пространства | VERIFIED |
| 10.3 | Запрет spawn-уже-сидя | VERIFIED |

**Проверено:** `door_ok seat_bad intro_done end_at_seat outro_done out_at_door`; harem door→slot tween.

---

## Этап 11 — Пространственные FPS-кризисы
**Статус:** `VERIFIED`  
**GDD:** `05`, `08`  
**Системы:** `CrisesAPI`, hotspots, HUD  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 11.1 | Crisis runner (сигнал, таймер, 2–4 решения, физика) | VERIFIED |
| 11.2 | Минимум 6–8 кризисов разных категорий | VERIFIED |
| 11.3 | Гейтинг по легенде/стейту | VERIFIED |

**Проверено:** 8 кризисов / 5 категорий; lights spots=2 + physical fix; fail legend 100→95; clones gated; high-legend softens fixes_needed.

---

## Этап 12 — Присутствие после 100% (орбита)
**Статус:** `VERIFIED`  
**GDD:** `06` §100%; `08` §12  
**Системы:** `visit_harem`, orbit crisis assist, mansion labels  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 12.1 | Spawn/точка в жилой зоне | VERIFIED |
| 12.2 | Бонус + позднее событие hook | VERIFIED |
| 12.3 | Участие в кризисах (хотя бы 1) | VERIFIED |

**Проверено:** visit att+0.35; crisis spots=3 orbit_help clears; label «Орбита:».

---

## Этап 13 — Полная стадийная прогрессия
**Статус:** `VERIFIED`  
**GDD:** `03`  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 13.1 | Переименовать/выровнять stage_3 штаб; stage_4 три акта | VERIFIED |
| 13.2 | Переходы со сценами | VERIFIED |
| 13.3 | Стадийные цели в HUD | VERIFIED |

**Проверено:** stage_3=`Операционный штаб`; stage_4=`Проект «Второй Я»` + 4A/B/C flags; HUD goal+acts; 6 stages in ContentDB.

---

## Этап 14 — Финал и постгейм
**Статус:** `VERIFIED`  
**GDD:** `03` финал  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 14.1 | Условия Алгоритма Любви | VERIFIED |
| 14.2 | Последовательность кризисов + ручное свидание | VERIFIED |
| 14.3 | Титры + постгейм флаги | VERIFIED |

**Проверено:** legend gate; pre-finale `lights_out` crisis → cleared; postgame flags; FinaleUI credits text.

---

## Этап 15 — UI / SFX / polish
**Статус:** `VERIFIED`  
**GDD:** `09`, `ART_DIRECTION`  
**Правило:** не начинать полный polish до интеграции 2–12; точечный polish внутри этапов ок.

| ID | Подзадача | Статус |
|----|-----------|--------|
| 15.1 | 4 типа попапов; презентации черты/девушки/стадии/дубля | VERIFIED |
| 15.2 | Полный SFX набор | VERIFIED |
| 15.3 | Единая тема UI | VERIFIED |

**Проверено:** `present_*` queue + distinct SFX; crisis warn; stage/girl reveals; ThemeFactory fonts+spacing.

---

## Этап 16 — Полный прогон и регрессия
**Статус:** `VERIFIED`  
**GDD:** `09` матрица  

| ID | Подзадача | Статус |
|----|-----------|--------|
| 16.1 | Прохождение 1→титры | VERIFIED |
| 16.2 | Save на 3 стадиях | VERIFIED |
| 16.3 | Закрытие MATRIX | VERIFIED |

**Проверено:** `SMOKE_OK stage=stage_6 post=true finale_ui=true clones=3`; save/load stage_2/4/6.

---

## Порядок выполнения (жёсткий)
`0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16`

Параллелить только research/review/playtest субагентами; один Implementer на shared modules.

---

## Этапы T0–T8 — коллективное влияние черт (после 16)

**Канон:** [11_TRAIT_INFLUENCE.md](11_TRAIT_INFLUENCE.md)  
**План:** [TRAIT_INFLUENCE_PLAN.md](TRAIT_INFLUENCE_PLAN.md)

| ID | Подзадача | Статус |
|----|-----------|--------|
| T0 | Канон в docs + словарь ID черт | DONE |
| T1 | Модель единиц влияния + save + отказ от random mass bonuses | VERIFIED |
| T2 | 2 primary traits + quirk у массовых; пары уникалок | VERIFIED |
| T3 | Пороги 1/3 + экран орбиты в телефоне | VERIFIED |
| T4 | Порог 10 — выбор ветки A/B/C | VERIFIED |
| T5 | Порог 30 + синергии (слоты) | VERIFIED |
| T6 | Целенаправленный поиск кандидаток | VERIFIED |
| T7 | Пороги 100/300, мир, уникалки, финал | VERIFIED |
| T8 | Баланс + MATRIX M-17 + smoke | VERIFIED |
