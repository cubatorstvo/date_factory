# Локации, UI, контент, антагонисты

> Часть Master GDD 2.0 · разделы 46, 47, 48, 49, 50
> Канон: [`docs/MASTER_GDD.md`](../MASTER_GDD.md)

---

# 46. Локации

Минимальный набор мира:

## 46.1. Квартира

- старт;
- телефон;
- гардероб;
- интерактивные подписи;
- ранние бытовые гэги;
- визуальные изменения прогресса.

## 46.2. Улица и городской хаб

- фиксированные ситуации девушек;
- обычные соперники;
- магазины;
- доступ к другим местам;
- видимый рост статуса героя.

## 46.3. Ресторан или кафе

Основная ранняя площадка свиданий с физическими событиями пространства.

## 46.4. Качалка

- Мышца;
- ранние самцовые ритуалы;
- пощёчины;
- физические активности.

## 46.5. Пространство Внешности

Может быть студией, подиумом, салоном или комбинированной локацией.

- одежда;
- танцы;
- позирование;
- фотосессии.

## 46.6. Зарплатная шахта

- получение денег;
- визуальная материализация зарплаты;
- развитие денежной части.

## 46.7. Лаборатория

- первый клон;
- мини-игра клонирования;
- терминал распределения;
- производственная линия;
- локальные комнаты свиданий;
- поздний мировой конвейер.

## 46.8. Производственная зона

- Global Expansion Terminal;
- Охват Земли / карта;
- глобальные улучшения ×2^n;
- короткие optional FPS-события;
- визуальная эскалация до планетарного масштаба;
- сигнал внеземной цели после Reach 100.

## 46.9. Финальная локация

- ответ на внеземной сигнал;
- поставленное свидание с «Последней»;
- зоны / checkpoints / walk между частями сцены;
- exhibition DANCE затем SLAP;
- функциональный ending screen.

Мир должен быть компактным. Большая карта не является ценностью сама по себе.

### Реализация (MODULE 12 / 19 / 20 / 21)

- Девять отдельных сцен, hub-and-spoke через `city_hub`.
- Доступ локаций — `StoryFeature` (не `GameState.unlock_location` для канонических девяти).
- `PUBLIC_CITY_ACCESS` — внутренний gate внутри `city_hub`, не отдельная location.
- Физический телефон в квартире открывает PhoneJournal; экономика шахты — MODULE 13.
- PhoneJournal (MODULE 14A–21): top status + Story + girls + MEDIA + ПЕРЕГРУЗКА + КЛОНЫ (after total≥1, read-only counts + rates) + salary; final completion via conquered `girl_final_target`.
- STAGE_4 Story: photo session → publish → overload → recognition → Scientist hunt at closed laboratory gate.
- STAGE_5 Story: before clone «Создай первого клона»; after clone → automation → President (requires first clone); clone management via lab terminal.
- STAGE_6 Story: «Мировое расширение», Reach XX/100; Production Area open via `WORLD_EXPANSION`.
- MODULE 14B ordinary public NPCs sit behind existing `PUBLIC_CITY_ACCESS`; Editor pair + photo cue live in `appearance_space`; MODULE 15 photo session uses that cue.
- MODULE 17: Scientist/rival anchors at city_hub laboratory gate (`requires_overload_recognized`); laboratory hosts one-off clone machine + FirstClone representative (suppressed when MODULE 19 controller owns lab).
- MODULE 19: lab-local `CloneVisualizationController` — 10 date rooms / 3 work / 2 free / 2 mass-flow; overflow labels + `ВНЕШНИЕ ПЛОЩАДКИ` (Работа / Свидания / Ожидают).
- MODULE 20: President/rival near city `ToProduction` after first clone; `production_area` Global Terminal + Reach visuals + 3 optional events; Reach100 → FINALE signal.
- MODULE 21: `final_location` + scene-local `FinalDateController`; catalog **14/14**; exhibition rivals; success ending + Continue; fail full retry. STOP before MODULE 22 polish.


---

# 47. UI

## 47.1. Основные постоянные показатели

Игроку достаточно видеть:

- Деньги;
- Авторитет;
- Опытность;
- доступные Баллы прокачки.

В поздней лаборатории дополнительно показываются производственные числа.

## 47.2. Требования

- минимум скрытых процентов;
- требования характеристик видны до выбора;
- результат мини-игры понятен;
- реакция девушки показывает `+1`, `0` или `-1`;
- причины реакций можно восстановить логически;
- большие поздние числа читаются мгновенно.

## 47.3. Телефон после медийной стадии

После редактора журнала появляется простая социальная лента.

Игрок может:

- видеть рост внимания;
- получать входящие предложения;
- публиковать ограниченное число фотографий;
- сознательно увеличивать поток свиданий.

Это не полноценный симулятор социальной сети.

### Реализация (MODULE 15 / 16 / 17 / 18 / 20 / 21)

- `Attention` = persistent media meter `0..100`, non-spendable.
- Photo session creates 3 fixed photo records; one photo publish per GameDay.
- Phone MEDIA section shows Attention, publish buttons, NEW/READ incoming (Open → journal, no schedule), feed newest-first.
- MODULE15 incoming offers are unscheduled initiatives; MODULE16 owns capacity/overlap.
- Four authored thresholds (15/30/45/60); overload-ready at Attention ≥ 45 and ≥ 3 offers.
- Phone ПЕРЕГРУЗКА (after MEDIA): daily personal capacity, backlog rows (OVERDUE then WAITING with 19:00/20:00 labels), Feed Boost «Поднять волну» until recognition.
- Realization modal uses exact «Проблема не в графике / Проблема в количестве меня» on next Phone open or safe GAMEPLAY; mechanical recognition does not wait for the modal.
- Overlap is authored slot labels, not a real clock; intentionally not a calendar manager.
- MODULE17 Phone: after recognition → «Найти Учёную у закрытой лаборатории»; STAGE_5 before clone → «Лаборатория открыта. / Создай первого клона.»
- MODULE18 Phone: STAGE_5 after clone → automation / clone growth; КЛОНЫ shows Всего / Свободно / Работают / Денег/мин / На свиданиях / Свиданий/мин (read-only; local assign/upgrades stay on lab terminal).
- MODULE19: physical caps only in laboratory visualization (10/3/2/2 + mass corridor).
- MODULE20 Phone: STAGE_5 President copy (XP / rival / meet at Production); STAGE_6 Reach XX/100 + rates; FINALE handoff → extraterrestrial goal. Global upgrades at Production Area terminal.
- MODULE21 UI: functional `FinalDateUI` (event choices, fail→retry, success dialogue, ending + `[Продолжить]`). Phone marks final girl completed when conquered. STOP before MODULE 22 phone/art polish.

---

# 48. Контент и повторяемость

## 48.1. Что можно повторять много раз

- базовую механику свидания;
- пощёчины;
- танцевальное противостояние;
- сигма-давление;
- денежные состязания;
- распределение поздних клонов.

Повторение допустимо, если меняются:

- персонаж;
- ставка;
- контекст;
- визуальная постановка;
- модификатор;
- романтический смысл результата.

## 48.2. Что не должно повторяться без изменения

- точная реплика;
- точная постановка;
- один и тот же идентификатор события за вечер;
- тот же сюжетный гэг;
- одна и та же крупная награда;
- длинный ручной маршрут ради уже понятной шутки.

## 48.3. Обычные девушки

Обычные девушки могут использовать общий пул событий.

Их различают:

- основная черта;
- дополнительная черта;
- фиксированная ситуация знакомства;
- внешний набор;
- часть персональных реплик.

Это позволяет создавать много комбинаций без полного отдельного сценария на каждую девушку.

### Реализация (MODULE 21 catalog)

- Production catalog closed for main path: **14 girls / 14 rivals** (includes `girl_final_target` + two exhibition final rivals).
- Final date is a unique authored scene, not a shared ordinary dating pool.

---

# 49. Антигринд

Нельзя требовать:

- десятки одинаковых боёв ради одного порога;
- постоянный ручной сбор шахтной зарплаты;
- долгий поиск случайно появившейся девушки;
- сложную ручную логистику клонов;
- назначение индивидуальных протоколов;
- отслеживание сотен NPC;
- длительное ожидание таймеров поздней инкременталки.

Повторение должно существовать для:

- другого решения;
- добора отношений до `+5`;
- добровольного заработка;
- проверки другого билда;
- комедийного реванша.

---

# 50. Нецели

Игра сознательно не пытается быть:

- реалистичным dating sim;
- глубокой психологической симуляцией;
- полноценной RPG;
- сложной экономической стратегией;
- менеджером расписаний;
- фабричным симулятором логистики;
- игрой про индивидуальное качество каждого клона;
- большим открытым миром;
- сложным боевиком;
- моральной лекцией;
- бесконечным постгеймом.

Поздняя автоматизация является простой цифровой кульминацией уже освоенной игры.

---
