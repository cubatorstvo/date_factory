# Current milestone acceptance

## Milestone
`RELEASE-RC-HARDENING-001`

## Current gate state

`NOT READY — IMPLEMENTATION PAUSED`

- Baseline audit: PASS.
- Normal Continue policy: technical PASS, independent/player-flow QA pending.
- Unique progression/finale reachability: partial interrupted diff, NOT ACCEPTED.
- Release smoke: PASS (25 steps).
- Full progression regression: NOT ACCEPTED / not proven.
- City/lighting/UI visual pass: NOT RUN.
- Windows export: MISSING.

## Required normal player route
1. Чистая новая игра без QA/debug state.
2. Квартира, обучение и выход в город.
3. Телефон, расписание и назначение свидания.
4. Магазин, покупка, инвентарь и подарок.
5. Подготовка и прохождение домашнего свидания.
6. Прохождение свидания во внешнем существующем POI.
7. Посещение каждого существующего POI и использование каждой уличной активности.
8. Открытие всех текущих progression-зон обычным способом.
9. Достижение последней текущей стадии и понятного финала.
10. Сохранение, загрузка, повторный вход в основные сцены.
11. Возврат в меню или продолжение свободной игры согласно принятому финалу.

## Functional criteria
- [ ] Нет Blocker/Critical.
- [ ] Все существующие POI доступны обычным маршрутом.
- [ ] Все interactions возвращают управление и допускают повторное использование.
- [ ] Inventory/shop/gift/date/progression работают без консоли.
- [ ] Save/load сохраняет маршрут и состояние.
- [ ] Smoke test проходит headless с ненулевым exit code при FAIL.
- [ ] Full progression regression проходит детерминированно.
- [ ] Windows export запускается вне editor и проходит release smoke.

## City and scene criteria
- [ ] Город состоит из компактных различимых зон и петель, а не одной длинной улицы.
- [ ] Каждый POI имеет фасад, читаемый вход, interaction, outline и return spawn.
- [ ] Street activities имеют физические props и завершённую постановку.
- [ ] Blockout POI заменены; временные композиции перечислены отдельно.
- [ ] Interiors компактны, asset-based, без void/floating geometry.
- [ ] Свет читаем во всех ключевых зонах и в основном времени суток.

## UI criteria
- [ ] Все player-facing окна используют единый визуальный язык.
- [ ] Нет стандартных серых Godot controls/debug placeholders.
- [ ] Modal/input/mouse/control return работают.
- [ ] Проверены 1280×720, 1920×1080 и 2560×1440.
- [ ] Текст не обрезан и язык интерфейса согласован.

## Evidence
- [ ] Git diff reviewed.
- [ ] Реальные команды headless запуска и raw Godot stdout/stderr сохранены.
- [ ] Normal-route screenshots открыты и фактически проверены Orchestrator.
- [ ] Clean-save manual playthrough пройден.
- [ ] Save/load regression пройден.
- [ ] Exported build test пройден.
- [ ] Independent `df-qa-worker` report принят.
- [ ] Credits/licenses и build inclusion проверены.

## Sequential stage gates

### Gate 1 — Critical gameplay
- [ ] Interrupted partial diff reviewed and accepted.
- [ ] Normal Continue independently verified.
- [ ] Every existing unique has a production meet/date route.
- [ ] Arcade reservation identity is correct.
- [ ] Smoke and honest full runner execute with expected exit codes.

### Gate 2 — Assets/licenses
- [ ] Exact asset/prefab/source/license mapping accepted.
- [ ] Missing replacements list finalized.
- [ ] Font/Sushi/drinkware provenance closed.

### Gate 3 — City/interactions
- [ ] Approved compact masterplan implemented in live city.
- [ ] Facades and street activities complete.
- [ ] Interaction/outline/collision belongs to visual roots.
- [ ] Top-down and normal-route QA pass.

### Gate 4 — Lighting/rooms
- [ ] City lighting evidence passes.
- [ ] Existing separate scenes and progression rooms pass route/re-entry/save checks.

### Gate 5 — UI/finale
- [ ] Three-resolution UI matrix passes.
- [ ] Existing Algorithm finale communicates completion and offers free play/menu.
- [ ] Postgame persists through save/load.

### Gate 6 — Release
- [ ] Full headless progression PASS.
- [ ] Clean-save manual playthrough PASS.
- [ ] Windows exported build PASS.
- [ ] Independent release QA PASS.
- [ ] Orchestrator inspected logs and every required screenshot.

## Blocking failures
- Любой сломанный основной маршрут, потеря save, постоянные runtime errors, missing critical resource, критическая деформация, debug-only доступ или отсутствие работающего export означает `NOT READY`.
- Major баг не может быть отложен без явного решения, что он блокирует release.

## Final decision
`PENDING`
