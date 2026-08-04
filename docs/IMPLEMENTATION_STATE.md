# DATE FACTORY — Implementation State

**Обновлено:** 2026-08-04  
**Сессия:** Dating overhaul + world facade (документация синхронизирована с кодом)

---

## Текущее состояние проекта

Этапы **0–16 VERIFIED**. Трек влияния черт **T0–T8 VERIFIED**.  
Переработка свиданий Stage 1 (расписание / home-restaurant / часы / shops / finish + 5 факторов) — **в коде и прогнана по must-fix**.

Подробности систем: [DATING_AND_WORLD.md](DATING_AND_WORLD.md).

### Готово (dating overhaul)

- `TimeAPI` + HUD часы / countdown брони  
- Phone: место → слоты времени (телефон закрывается перед Events-карточкой; без silent first-slot)  
- Home prep: еда/напиток carry → стол, homeware, doorbell, start у стола  
- Restaurant: sit/wait, charge, early time skip  
- Shops → `ShopUI`; gift shelves сняты из flow  
- Mid-date optional gift once; Finish button; 5-factor result panel  
- Home vignette = apartment art; Hero mesh на `HeroSeat`  
- Quests Stage 1 переписаны под book/prep/finish  
- Коммит ветки: dating rewrite (см. git log `Rewrite dating around schedule…`)

### В мире (city/apartment split)

- `ComplexWorld.travel_to` — взаимоисключающие локации `home` / `city`  
- `scenes/world/city/city.tscn` + фасад `PlayerHomeFacade` / `HomeEntrance`  
- Спавны: выход → HomeEntrance; вход → apartment `PlayerSpawn` у двери  
- Южная стена квартиры закрыта (дверный проём сохранён)  
- Playtest GodotIQ: exclusive loads + round-trip clean  

### Следующий gap

1. Ручной visual QA: фасад «Мой дом», поза Hero за столом, home prep → doorbell → date  
2. Каркас кварталов города (`Districts/*`) наполнять по мере контента  
3. Не начинать новый крупный трек без явного запроса  

---

## Завершённые этапы

0–16 = VERIFIED  
T0–T8 = VERIFIED  
Dating overhaul must-fix = VERIFIED (GodotIQ playtest 2026-08-04)  
City/apartment location split = VERIFIED (GodotIQ playtest 2026-08-04)

## Текущий этап

**Stage 1 world + dating loop — playable; visual QA / content polish**

## Следующий

Visual QA и polish по желанию; обновлять [DATING_AND_WORLD.md](DATING_AND_WORLD.md) при новых районах.

---

## Принятые решения

- Одна доктрина за раз; снятие = реорганизация.  
- Резерв расширения нельзя вернуть в карман.  
- Уникалки усиливают знакомые деревья, не дают лишних единиц влияния.  
- Mult caps: money/event_pop ≤1.45; gift/staff ≥0.70; scandal/clone_error ≥0.55.  
- Свидание: schedule-first; gift optional; гипотезы диалогов сохраняются.  
- Live DateGirl = `DateGirl_UAL` (не Proxy POC).  
- City/apartment: не `change_scene` всего Main — слот локации в `ComplexWorld`.  
- Godot целевой: **4.7.1** (не 4.4.1).  

## Известные проблемы

- 3D capsule player в free-roam (на свидании — Hero mesh)  
- GodotIQ runtime attach иногда нестабилен  
- Proxy POC и diag tools — untracked WIP, не часть live path  
- После `save_scene` всегда проверять root (`City` / `Apartment`)  

## Инструкция новой сессии

1. Прочитать [DATING_AND_WORLD.md](DATING_AND_WORLD.md) и этот STATE  
2. Не откатывать dating schedule-first / `travel_to` без запроса  
3. Регрессия: `tools/smoke_trait_influence.gd`, `tools/verify_dating_overhaul.gd`; door flow home↔city  
  
