# DATE FACTORY — Implementation State

**Обновлено:** 2026-08-03  
**Сессия:** T8 — баланс / MATRIX / smoke (трек влияния закрыт)

---

## Текущее состояние проекта

Этапы **0–16 VERIFIED**. Блок влияния черт: **T0–T8 VERIFIED**.

### Готово (эта сессия)
- `TraitInfluenceAPI.clamp_effect_bag` — потолки boost / полы cut (§26)  
- Caps в `branch_passive_effects()` и после merge в `GirlsAPI.active_effects()`  
- `GirlsAPI.allows_auto_date` + soft confidence penalty для high/unique (§27)  
- `DatingAPI._auto_schedule` уважает `allows_auto_date`  
- Smoke: `tools/smoke_trait_influence.gd` (editor: `T8_SMOKE_OK`)  
- MATRIX M-17 + PLAN/STATE закрыты  

### Playtest M-17 (2026-08-03)
- Headless: `M17_PLAYTEST_OK` (`tools/playtest_m17.gd`), `TRAIT_INFLUENCE_SMOKE_OK`, `SMOKE_OK`
- Фикс compile: явные типы `revealed_ok: bool`, `quirk: String` (ломали `Game` / attach)
- GodotIQ editor runtime attach: debugger не активен → UI play через MCP недоступен  

### Следующий gap
Контент/полировка или ручной UI-play в редакторе (телефон Орбита), если нужен визуальный QA.

---

## Завершённые этапы
0–16 = VERIFIED  
T0–T8 = VERIFIED  

## Текущий этап
**Трек влияния черт — закрыт**

## Следующий
Runtime playtest / контент по желанию — см. [ACCEPTANCE_MATRIX.md](ACCEPTANCE_MATRIX.md) M-17

---

## Принятые решения
- Одна доктрина за раз; снятие = реорганизация.  
- Резерв расширения нельзя вернуть в карман.  
- Уникалки усиливают знакомые деревья, не дают лишних единиц влияния.  
- `from_dict` → `recount(false)`: live girls — source of truth для counts.  
- Mult caps: money/event_pop ≤1.45; gift/staff ≥0.70; scandal/clone_error ≥0.55.  

## Известные проблемы
- 3D капсула stub  
- GodotIQ runtime attach иногда не поднимается  
- Полный in-game playtest M-17 всё ещё зависит от stable runtime  

## Инструкция новой сессии
1. STATE: трек T0–T8 закрыт  
2. Не открывать новый этап влияния без явного запроса  
3. При регрессии: `tools/smoke_trait_influence.gd` или editor exec T8 smoke  
