# DATE FACTORY v2 — docs

This repository `main` branch is the **new** Date Factory project.

The previous prototype lives only as a read-only donor:

- path: `../date_factory_legacy`
- branch / tag: `legacy-v1`

## Product truth

Канонический Master GDD 2.0:

```text
docs/MASTER_GDD.md
```

Разбивка по блокам: `docs/gdd/`  
Полный текст одним файлом: `docs/gdd/MASTER_GDD_FULL.md`

## Technical plan (surface only)

Верхнеуровневый порядок модулей и зависимостей:

```text
docs/TECH_PLAN.md
```

Разбивка: `docs/tech/`  
Полный текст: `docs/tech/TECH_PLAN_FULL.md`

Это **не** описание итоговой реализации.  
Для каждого модуля перед стартом будет отдельная финальная спецификация.

## Module specs

```text
docs/modules/
```

Текущий: [`MODULE_00_PROJECT_FOUNDATION.md`](modules/MODULE_00_PROJECT_FOUNDATION.md)

Также:

- [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)
- [`TECHNICAL_DECISIONS.md`](TECHNICAL_DECISIONS.md)

## Conflict priority

```text
new MASTER_GDD
>
explicit latest user instruction
>
per-module implementation spec (когда выдана)
>
TECH_PLAN (только порядок / границы / зависимости)
>
new project code
>
legacy donor documentation/code
```

Legacy documentation in the donor is reference material about the old implementation only. It does **not** define requirements for v2.
