# TECHNICAL DECISIONS

Краткий decision log Date Factory v2.  
Записывать только существенные infrastructure/решения.

---

## GodotIQ addon retained

Context:
Нужен AI/editor bridge для разработки в Cursor.

Options:
- Не ставить addon и работать только filesystem tools
- Сохранить GodotIQ как editor/runtime bridge addon

Decision:
Оставить `addons/godotiq` (v0.5.16) и autoload `GodotIQRuntime`.

Reason:
Прямо ускоряет разработку; не содержит gameplay. Autoload — часть addon lifecycle, не gameplay manager.

Scope:
`addons/godotiq/`, `project.godot` `[autoload]` / `[editor_plugins]`

---

## No gameplay autoloads in MODULE 00

Context:
Нужно решить, создавать ли заранее Game/EventBus/SceneManager.

Options:
- Заранее создать несколько «стандартных» managers
- Начать без gameplay autoload

Decision:
Ни одного gameplay autoload. Только GodotIQRuntime.

Reason:
MODULE 00 — foundation. Game State и сервисы появятся по отдельным спецификациям (MODULE 02+).

Scope:
`project.godot`

---

## Debug via `DfLog` class, not autoload

Context:
Нужен минимальный debug baseline с меткой модуля.

Options:
- Autoload logger
- `class_name DfLog` static helpers
- Только стандартный `print`/`push_error`

Decision:
`core/df_log.gd` с `class_name DfLog` и static `info`/`warn`/`error`.

Reason:
Достаточно для MODULE 00, без глобального mutable state и без premature service.

Scope:
`core/df_log.gd`

---

## Temporary bootstrap on `main.tscn`

Context:
Нужен smoke-test запуска без gameplay.

Options:
- Пустая сцена без script
- Минимальный bootstrap + label

Decision:
`main.tscn` (Control) + `core/main_bootstrap.gd` + StatusLabel.

Reason:
Подтверждает запуск и debug path; легко удалить/заменить в MODULE 01.

Scope:
`main.tscn`, `core/main_bootstrap.gd`

---

## Canonical folders without empty placeholders

Context:
Спека задаёт canonical destinations (`audio/`, `characters/`, …).

Options:
- Создать все пустые папки сразу
- Создавать по мере появления реальных файлов

Decision:
Созданы только реально нужные сейчас: `addons/`, `assets/`, `core/`, `docs/`. Остальные — documented future destinations.

Reason:
Спека явно запрещает пустые каталоги «ради дерева».

Scope:
`docs/PROJECT_STRUCTURE.md`, filesystem

---

## Input Map baseline for MODULE 01

Context:
Нужен минимальный input set до Player FPS.

Options:
- Не трогать Input Map до MODULE 01
- Зафиксировать canonical actions сейчас

Decision:
Добавлены `move_forward/backward/left/right`, `jump`, `interact`, `pause` с desktop defaults WASD/Space/E/Esc.

Reason:
Требование MODULE 00; дальше не добавлять gameplay-specific actions заранее.

Scope:
`project.godot` `[input]`
