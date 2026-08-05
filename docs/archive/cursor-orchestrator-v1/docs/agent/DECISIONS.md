# Product and architecture decisions

### DEC-001 — Минимальный интервал случайных событий

- Date: 2026-08-05
- Context: `EventsAPI` использовал wall-clock `delta`, а post-date путь мог обходить cooldown.
- Decision: все случайные catalog-events имеют единый минимум 10 игровых минут по `TimeAPI.absolute_minutes()`; отметка последнего показа хранится в существующем events save blob.
- Rejected alternatives: 10 реальных минут; frame-based cooldown; отдельная проверка только passive-roll.
- Consequences: пауза не расходует интервал, игровые time-skip/travel учитываются, save/load не сбрасывает защиту.
- Related files: `modules/events/events_api.gd`.
- Acceptance implications: passive и post-date trigger заблокированы до 10 минут; после 10 минут снова разрешены без изменения вероятностей.

### DEC-002 — Тот же интервал для runtime/deferred popup-событий

- Date: 2026-08-05
- Context: «Последствие пропуска» и другие `open_runtime_event` обходили 10-минутный catalog gate; clone `deferred_hits` спамили каждые ~5–19 wall-clock секунд.
- Decision: любой успешный popup event UI (catalog + runtime) ставит общий stamp; clone deferred firing ждёт тот же 10-минутный game-time gap и не тикает wall-clock due во время блокировки.
- Rejected alternatives: оставить runtime без лимита; отдельный короткий wall-clock cooldown для клонов.
- Consequences: latent clone consequences и прочие runtime popups не чаще раза в 10 игровых минут; очередь `deferred_hits` сохраняется, но не спамит.
- Related files: `modules/events/events_api.gd`, `modules/clones/clones_api.gd`.
- Acceptance implications: после любого event UI следующий catalog/runtime/deferred не раньше +10 game minutes.

### DEC-003 — Interactable как дочерний компонент мебели с AABB

- Date: 2026-08-05
- Context: Fridge и KitchenDrawers на расстоянии 0.7 м имели общие Area3D 1.2×1.2 → пересечение ~0.5 м; интеракты висели на room root, не на мебели.
- Decision: расширить существующий `Interactable` (не второй framework): для apartment furniture reparent под узел мебели, `fit_collision_to_meshes` по AABB мешей + padding; city fixed boxes пока не трогать.
- Rejected alternatives: только уменьшить shelf box; StaticBody interact layer; proximity без raycast.
- Consequences: области не пересекаются и следуют за мебелью; outline root = parent furniture.
- Related files: `modules/interaction/interactable.gd`, apartment path in `complex_world.gd`.
- Acceptance implications: fridge/drawers AABBs disjoint; prompts map to correct units.

### DEC-004 — Continue загружает отдельный full-access QA-профиль

- Date: 2026-08-05
- Context: пользователю нужен быстрый ручной обход всех реализованных локаций и POI.
- Decision: «Продолжить» регенерирует и загружает отдельный `user://save_slot_qa_full_access.json`; обычный `save_slot_1.json` и «Новая игра» не меняются.
- Rejected alternatives: перезаписать реальный save; статичный JSON fixture; debug/testbed scene.
- Consequences: normal FPS route, stage_6, все districts/rooms/venues/apt_* и необходимые ресурсы открыты; профиль маркирован и регенерируется.
- Related files: `autoload/game.gd`, `modules/save/save_service.gd`, `scenes/boot/boot.gd`, optional QA builder.
- Acceptance implications: Continue работает без normal save; real save не меняется; New Game остаётся stage_1.

### DEC-005 — Shipping Continue возвращается к обычному сохранению

- Date: 2026-08-05
- Context: QA milestone временно направил player-facing «Продолжить» в full-access профиль, что в release обходит progression и игнорирует `save_slot_1`.
- Decision: в shipping-маршруте «Продолжить» загружает только обычное сохранение и disabled при его отсутствии; full-access профиль сохраняется как test-only механизм, недоступный обычному игроку.
- Rejected alternatives: удалить QA profile; оставить cheat Continue; перезаписывать normal save.
- Consequences: baseline P01/P08 закрываются без потери QA-инструмента.
- Related files: `scenes/boot/boot.gd`, `autoload/game.gd`, `modules/save/save_service.gd`, release tests.
- Acceptance implications: New Game создаёт stage_1; Continue восстанавливает его; QA full-access запускается только явной test-командой.

### DEC-006 — Финал текущего scope сохраняет существующую Algorithm progression

- Date: 2026-08-05
- Context: stage_6, megamachine, algorithm date, FinaleUI и postgame уже реализованы, но normal-route заблокирован отсутствующими meet-path для части уникальных девушек.
- Decision: не смягчать финальные gates и не создавать новый финальный framework. Завершение текущей версии: stage_6 → сборка megamachine/core → закрытие обязательного crisis state → встречены существующие unique girls → Algorithm date → краткий итог → выбор free play или возврата в меню.
- Rejected alternatives: soft-end сразу после megamachine; QA-profile как финал; новая сюжетная система.
- Consequences: требуется восстановить stage-based discoverability/spawn всех существующих unique girls и проверить маршрут без `mark_met` cheats.
- Related files: `modules/girls/girls_api.gd`, `modules/city/city_api.gd`, existing finale/router/UI/quest files.
- Acceptance implications: deterministic full regression доходит до FinaleUI нормальными production API; postgame сохраняется и загружается.

### DEC-007 — Overlay POI остаются overlay POI

- Date: 2026-08-05
- Context: магазины, gym, cinema, arcade, photo, barber и agency уже спроектированы как городские фасады с overlay/activity UI; отдельных walkable interiors у них нет.
- Decision: hardening завершает их фасады, props, interaction ownership, outline и UI, но не добавляет новые интерьеры ради масштаба. Существующие отдельные сцены apartment, restaurant и lab доводятся как отдельные локации.
- Rejected alternatives: создать по интерьеру для каждого overlay POI; выдавать пустые box-комнаты за интерьеры.
- Consequences: scope остаётся feature-complete без новой travel architecture.
- Related files: city scene, ComplexWorld, existing POI UI, apartment/restaurant/lab scenes.
- Acceptance implications: назначение каждого POI читается с улицы; activity полностью работает; отдельная сцена обязательна только там, где уже является частью маршрута.

### DEC-008 — UI hardening переиспользует текущую тему

- Date: 2026-08-05
- Context: проект уже имеет `UiStyle`, `ThemeFactory`, `DateFactoryTheme`, `UiLayers` и `UiEscape`; Kenney UI/icons/prompts доступны в source packs.
- Decision: не создавать вторую UI-систему. Сохранить текущую русскоязычную StyleBox-тему, выровнять все состояния/размеры и точечно импортировать CC0 icons/prompts там, где они заменяют placeholders.
- Rejected alternatives: массово заменить интерфейс готовым skin pack; добавить новую localization system в RC.
- Consequences: английские seed/debug строки устраняются, но полноценная смена языка остаётся вне scope.
- Related files: `core/ui_style.gd`, theme resource, existing UI scenes/scripts, selected `assets/ui`.
- Acceptance implications: единый визуальный язык и три целевых разрешения без новой UI architecture.

### DEC-009 — Техническая реализация передаётся по последовательным stage gates

- Date: 2026-08-05
- Context: baseline и план завершены; два implementation-пакета были прерваны с partial diff, а основной Orchestrator-чат должен остановить техническую реализацию.
- Decision: дальнейший код/scene/asset/export выполняют только назначенные `df-*` workers по `RELEASE_HARDENING_PLAN.md` и `HANDOFF_TO_GROK.md`. Сначала отдельный review partial diff, затем независимый QA; city, global theme, save/autoload и export интегрируются последовательно.
- Rejected alternatives: продолжать код в основном чате; считать partial smoke/full runner готовым; запускать city/art до закрытия Blocker progression.
- Consequences: partial файлы не удаляются и не принимаются автоматически; ownership получает статусы PAUSED/PLANNED до нового worker batch.
- Related files: `docs/release/RELEASE_HARDENING_PLAN.md`, `docs/release/HANDOFF_TO_GROK.md`, `docs/agent/OWNERSHIP.md`.
- Acceptance implications: каждый stage имеет scoped task, evidence contract, independent QA и явный gate.

### DEC-010 — Текущее состояние остаётся NOT READY до полного release evidence

- Date: 2026-08-05
- Context: normal Continue исправлен технически, но progression partial не принят; full regression, visual pass и Windows export отсутствуют.
- Decision: milestone не получает промежуточный READY. Текущий статус — `NOT READY / IMPLEMENTATION PAUSED`.
- Rejected alternatives: READY по audit/smoke; READY WITH LIMITATIONS.
- Consequences: финальный статус меняется только после clean-save playthrough, full test, exported build и независимого QA.
- Related files: release reports, acceptance and QA evidence.
- Acceptance implications: все обязательные checkbox в `ACCEPTANCE.md` должны быть доказаны.

## Template

### DEC-000 — Название

- Date:
- Context:
- Decision:
- Rejected alternatives:
- Consequences:
- Related files:
- Acceptance implications:
