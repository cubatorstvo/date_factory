# Структура проекта

Godot **4.7.1 stable**, renderer **Forward Plus**.

```text
res://
    date_system/
        content/
            tags/
            moves/
            situations/
            girls/
            secondary/
            location_formats/
            locations/
            outfits/
            progression/
            rules/
            catalog/
        engine/
        runtime/
        episodes/
        ui/
        dev_room/
        tests/
    main/
    addons/godotiq/
```

## Точки входа

| Назначение | Путь |
|---|---|
| Главная сцена | `res://date_system/dev_room/DateSystemLab.tscn` |
| Обёртка запуска | `res://main/main.tscn` |
| Каталог контента | `res://date_system/content/catalog/date_content_catalog.tres` |
| Автотесты | `res://date_system/tests/date_system_test_runner.gd` |

## Хранение данных

| Слой | Где |
|---|---|
| Design-content | `res://date_system/content/**/*.tres` |
| Runtime-прогресс | `user://date_system/` |

## Инфраструктура репозитория

Сохраняются Git-история, `.gitignore`, `.gitattributes`, Cursor rules, GodotIQ addon и `GODOTIQ_RULES.md`.
