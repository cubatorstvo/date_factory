# PROJECT STRUCTURE

Фактическая структура после **MODULE 00 — Project Foundation**.  
Godot 4.7 · Forward Plus · main scene: `res://main.tscn`

## Top-level (существует сейчас)

| Path | Назначение | Можно | Нельзя |
|---|---|---|---|
| `addons/` | Editor/tool plugins | GodotIQ и будущие tooling plugins | Gameplay systems |
| `assets/` | Импортируемые визуальные ресурсы | модели, текстуры, материалы, fonts, props | Gameplay scripts / domain logic |
| `core/` | Техническая инфраструктура | debug helpers, bootstrap, generic utilities | Game managers, gameplay systems |
| `docs/` | Документация репозитория (вне gameplay runtime) | GDD, tech plan, module specs, decisions | Runtime code |
| `main.tscn` | Canonical entry scene | минимальный foundation smoke UI | Бог-объект / game loop |
| `project.godot` | Godot project settings | app/input/display/rendering/plugins | Legacy autoloads |
| `icon.svg` | Иконка приложения | — | — |

### `core/` сейчас

- `core/df_log.gd` — `DfLog` debug helper
- `core/main_bootstrap.gd` — временный bootstrap MODULE 00

### `docs/` сейчас

- `MASTER_GDD.md` + `gdd/` — продуктовый канон
- `TECH_PLAN.md` + `tech/` — поверхностный порядок модулей
- `modules/` — подробные спецификации модулей
- `TECHNICAL_DECISIONS.md` — decision log
- `PROJECT_STRUCTURE.md` — этот файл
- `README.md` — индекс docs

## Canonical future destinations (ещё не созданы)

Создавать только когда появится реальный файл соответствующего модуля:

```text
audio/
characters/
data/
game/
minigames/
ui/
world/
```

| Future path | Для чего |
|---|---|
| `audio/` | музыка и аудиоресурсы |
| `characters/` | player/NPC presentation |
| `data/` | content definitions (MODULE 03+) |
| `game/` | feature-level gameplay systems |
| `minigames/` | изолированные мини-игры |
| `ui/` | общие UI scenes/widgets |
| `world/` | локации и world composition |

## Autoload

| Name | Почему |
|---|---|
| `GodotIQRuntime` | Часть editor/runtime bridge addon; не gameplay |

Gameplay autoload отсутствуют намеренно.

## Donor

Read-only donor: `../date_factory_legacy` (`legacy-v1`).  
Runtime проекта не зависит от donor.
