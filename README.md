# DATE FACTORY v2

Новая версия Date Factory. Старый прототип — отдельный read-only donor, не часть runtime.

## Requirements

- Godot **4.7** (Forward Plus)
- Desktop

## Open / run

1. Открыть эту папку как Godot project.
2. Main scene: `res://main.tscn`
3. Play (F5)

## Docs

| Doc | Path |
|---|---|
| Master GDD (product truth) | [`docs/MASTER_GDD.md`](docs/MASTER_GDD.md) |
| Technical plan (surface only) | [`docs/TECH_PLAN.md`](docs/TECH_PLAN.md) |
| Module specs | [`docs/modules/`](docs/modules/) |
| Project structure | [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md) |
| Technical decisions | [`docs/TECHNICAL_DECISIONS.md`](docs/TECHNICAL_DECISIONS.md) |

Per-module **final implementation specs** are provided separately before each module starts.  
`TECH_PLAN` is only module order / boundaries / dependencies.

## Donor

```text
../date_factory_legacy
branch/tag: legacy-v1
mode: READ-ONLY
```

Copy into this project only when explicitly needed. Never runtime-link to donor.
