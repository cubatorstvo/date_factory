# MODULE 12 FIX — PRODUCTION BOOTSTRAP / AUTOLOAD WIRING

**Проект:** Date Factory  
**Статус:** блокирующая коррекция MODULE 12  
**Причина:** World Framework реализован, но обычный F5 всё ещё запускает старый FPS test bootstrap и пытается создать удалённый `SlapCompetitionHost`. `project.godot` также не регистрирует autoload-сервисы MODULE 07B–12, хотя код и `PROJECT_STRUCTURE.md` считают их production autoloads.

---

# 1. Что уже НЕ нужно переделывать

НЕ переписывать:

```text
world/world.gd
WorldLocation
WorldTransition
WorldFeatureGate
9 location scenes
marker framework
Story access mapping
```

Если текущие tests проходят — сохранить реализацию.

---

# 2. Блокирующая проблема №1 — `core/main_bootstrap.gd`

Сейчас production bootstrap всё ещё делает legacy/test flow:

```text
_ensure_slap_competition_host()
_enter_fps_test()
```

и пытается load:

```text
res://minigames/slap/slap_competition_host.gd
```

Этот файл после MODULE 07B больше не существует и НЕ должен существовать.

Удалить полностью из production bootstrap:

```text
SlapCompetitionHost
_ensure_slap_competition_host()
FPS_TEST_SCENE
_enter_fps_test()
change_scene_to_file(player_fps_test.tscn)
```

---

# 3. Canonical production boot

`main_bootstrap.gd` должен делать только production boot через canonical World:

```text
_ready()
→ deferred _boot()

_boot()
→ /root/World.boot_from_main()
```

Проверить result.

При failure:

```text
DfLog.error(...)
```

Не fallback-ить автоматически в FPS test scene.

FPS test остаётся отдельной technical test scene, которую запускают вручную/tests.

---

# 4. `main.tscn` не должен закрывать 3D-мир

Текущий `main.tscn` содержит fullscreen:

```text
ColorRect Background
Label "Date Factory — Foundation OK"
```

После MODULE 12 это устаревший Foundation экран.

Удалить production fullscreen overlay.

Предпочтительный `main.tscn`:

```text
Node
script = core/main_bootstrap.gd
```

или другой минимальный невизуальный bootstrap root.

Критическая гарантия:

> после F5 apartment 3D видна и принимает FPS input.

Не оставлять fullscreen Control/ColorRect поверх WorldHost.

---

# 5. Блокирующая проблема №2 — autoload wiring

`PROJECT_STRUCTURE.md` уже документирует production autoloads, но `project.godot` сейчас содержит только старый subset.

Добавить реальные autoload entries для существующих production services.

Dependency-safe order:

```text
GodotIQRuntime
GameState
ContentDB
Progression
RivalEncounters
RivalCompetitionRunner
GirlDiscovery
DatingCore
Relationships
Story
World
```

Exact paths:

```text
GameState
→ res://game/state/game_state.gd

ContentDB
→ res://data/catalog/content_db.gd

Progression
→ res://game/progression/progression.gd

RivalEncounters
→ res://game/rivals/rival_encounters.gd

RivalCompetitionRunner
→ res://game/rivals/rival_competition_runner.gd

GirlDiscovery
→ res://game/girls/girl_discovery.gd

DatingCore
→ res://game/dating/dating_core.gd

Relationships
→ res://game/relationships/relationships.gd

Story
→ res://game/story/story.gd

World
→ res://world/world.gd
```

`GodotIQRuntime` оставить как сейчас.

---

# 6. Почему порядок важен

На `_ready()`:

```text
RivalCompetitionRunner
```

регистрируется в уже существующем:

```text
RivalEncounters
```

`Relationships` подключается к уже существующему:

```text
DatingCore
```

`Story` подключается к:

```text
Relationships
RivalEncounters
GameState
```

`World` подключается к:

```text
Story
GameState
```

Поэтому не регистрировать эти autoloads в случайном порядке.

---

# 7. Не создавать runtime services вручную в bootstrap

После исправления bootstrap НЕ должен делать:

```text
load script
new()
add_child()
```

для:

```text
RivalCompetitionRunner
GirlDiscovery
DatingCore
Relationships
Story
World
```

Они canonical autoloads.

Единственный runtime host, который `World` создаёт сам:

```text
WorldHost
```

— это нормально.

`WorldHost` здесь означает persistent SceneTree container, не multiplayer host и не competition runner.

---

# 8. Проверить stale terminology

Production code не должен содержать:

```text
SlapCompetitionHost
_ensure_slap_competition_host
```

Technical docs тоже обновить, если где-то stale.

`WorldHost` НЕ переименовывать: это другой смысл — container для LocationRoot/Player/PersistentUI.

---

# 9. F5 smoke test — ОБЯЗАТЕЛЬНЫЙ

Запустить именно:

```text
F5 / project main scene
```

Не module test scene.

Expected:

```text
/root/GameState exists
/root/ContentDB exists
/root/Progression exists
/root/RivalEncounters exists
/root/RivalCompetitionRunner exists
/root/GirlDiscovery exists
/root/DatingCore exists
/root/Relationships exists
/root/Story exists
/root/World exists
```

И:

```text
World.current_location_id == &"apartment"
World.get_current_location() != null
World.get_current_location().location_id == &"apartment"
World.get_player() != null
Player control mode == GAMEPLAY
```

---

# 10. Visual smoke test

После F5 пользователь должен реально видеть:

```text
apartment blockout
```

а НЕ:

```text
Date Factory — Foundation OK
```

и НЕ:

```text
player_fps_test.tscn
```

---

# 11. Interaction smoke test

В production F5:

1. Player ходит по apartment.
2. E на Phone открывает PhoneJournal.
3. Phone close возвращает GAMEPLAY.
4. На PROLOGUE выход в city показывает story lock.
5. После test/debug stage → STAGE_1 переход apartment → city работает.

---

# 12. Rival runner smoke test

Проверить:

```text
RivalEncounters.get_competition_runner()
```

или фактический seam показывает production:

```text
RivalCompetitionRunner.run_competition
```

Никакого old Slap host.

---

# 13. Relationships/Story signal smoke test

После обычного project boot:

```text
Relationships
```

должен быть подключён к:

```text
DatingCore.date_finished
```

и:

```text
Story
```

к:

```text
Relationships.girl_completed
RivalEncounters.encounter_won
```

Не полагаться только на module self-tests, где services могли manually instantiate.

---

# 14. World signal smoke test

После boot World должен быть реально подключён к:

```text
GameState.stage_changed
Story.feature_unlocked
```

Чтобы `PUBLIC_CITY_ACCESS` gate refresh работал в production.

---

# 15. Regression tests

После исправления прогнать:

```text
MODULE 05
MODULE 06
MODULE 07A
MODULE 07B
MODULE 07C
MODULE 07D
MODULE 08
MODULE 09
MODULE 10
MODULE 11
MODULE 12
FPS test scene
```

Особенно проверить, что добавление autoloads не создаёт double registration в tests.

Test scenes не должны manually instantiate второй production service с тем же semantic owner без cleanup/isolation.

---

# 16. Documentation consistency

После fix фактическое поведение должно совпадать с уже написанным в:

```text
docs/PROJECT_STRUCTURE.md
```

где указано:

```text
main scene → apartment via autoload World
```

Если documentation перечисляет autoload order, привести его к фактическому dependency-safe order.

---

# 17. Definition of Done

Fix принят только если:

- [ ] `SlapCompetitionHost` отсутствует из production bootstrap;
- [ ] FPS test scene больше не является production boot target;
- [ ] `main.tscn` не перекрывает World fullscreen Foundation UI;
- [ ] все production autoloads зарегистрированы;
- [ ] `RivalCompetitionRunner` after `RivalEncounters`;
- [ ] `Relationships` after `DatingCore`;
- [ ] `Story` after `Relationships`;
- [ ] `World` after `Story`;
- [ ] F5 реально загружает apartment;
- [ ] Player видим/управляем;
- [ ] physical Phone работает;
- [ ] PROLOGUE city transition locked;
- [ ] STAGE_1 city transition works;
- [ ] RivalCompetitionRunner production seam зарегистрирован;
- [ ] Story/Relationships production signals подключены;
- [ ] MODULE 12 tests PASS;
- [ ] previous regressions PASS;
- [ ] никакой MODULE 13 logic не реализована.

---

# 18. Формат отчёта Cursor

## Root cause

Почему module tests проходили, хотя production boot оставался старым.

## Autoloads

Показать фактический `[autoload]` order.

## Bootstrap

Показать новый production flow:

```text
main.tscn
→ main_bootstrap
→ World.boot_from_main()
→ apartment
```

## Removed stale path

Подтвердить отсутствие:

```text
SlapCompetitionHost
FPS_TEST_SCENE production routing
```

## F5 validation

Результат реального project-main smoke test.

## Regression

MODULE 05–12 + FPS.

## Commit

SHA.

После этого остановиться. MODULE 13 не начинать.
