# DATE FACTORY — технический план реализации

**Статус:** верхнеуровневый / поверхностный план реализации  
**Назначение:** модули, границы, зависимости и рекомендуемый порядок разработки  
**Источник продуктовых требований:** [`docs/MASTER_GDD.md`](MASTER_GDD.md)  
**Полный текст одним файлом:** [`tech/TECH_PLAN_FULL.md`](tech/TECH_PLAN_FULL.md)

## Критически важно

Этот документ **НЕ** является описанием итоговой реализации.

- Не детальная техническая спецификация систем.
- Не финальная архитектура кода.
- Не разрешение самостоятельно «додумывать» механики.

Для **каждого модуля / блока** перед началом реализации будет предоставлена
**отдельная итоговая спецификация реализации**.

Пока такой спецификации нет:

- модуль нельзя считать готовым к полной реализации;
- допускается только минимальный интерфейс/заглушка, если это нужно уже
  утверждённому текущему модулю;
- Cursor не должен заранее строить универсальные системы «на будущее».

## Приоритет документов

```text
docs/MASTER_GDD.md (+ docs/gdd/*)
>
explicit latest user instruction
>
per-module implementation spec (когда выдана)
>
docs/TECH_PLAN.md (+ docs/tech/*)   ← только порядок/границы/зависимости
>
new project code
>
legacy donor documentation/code
```

## Оглавление по блокам

| Разделы | Файл |
|---|---|
| 1, 2 | [Правила работы с планом и общий принцип архитектуры](tech/01_rules_and_architecture.md) |
| 3 | [Порядок реализации: MODULE 00–28](tech/02_modules.md) |
| 4 | [Крупные интеграционные срезы (milestones)](tech/03_milestones.md) |
| 5, 6, 7, 8, 9 | [Поставка модулей, ограничения, риски, критерии готовности](tech/04_delivery_and_constraints.md) |

## Карта модулей

- MODULE 00 — Project Foundation
- MODULE 01 — Player FPS Core
- MODULE 02 — Core Game State
- MODULE 03 — Content Data Layer
- MODULE 04 — Character Framework
- MODULE 05 — Progression & Perks
- MODULE 06 — Rival Encounter Framework
- MODULE 07 — Rival Minigames
- MODULE 08 — Girl Discovery & Phone Journal
- MODULE 09 — Dating Core
- MODULE 10 — Relationships & Girl Completion
- MODULE 11 — Story / Stage Framework
- MODULE 12 — World & Location Framework
- MODULE 13 — Salary Mine & Money Loop
- MODULE 14 — Stage Content: Manual Game
- MODULE 15 — Media / Attention Escalation
- MODULE 16 — Dating Overload
- MODULE 17 — First Clone Sequence
- MODULE 18 — Clone Incremental Core
- MODULE 19 — Physical Clone Visualization
- MODULE 20 — Late Game Expansion
- MODULE 21 — Final Date Sequence
- MODULE 22 — UI / UX Integration
- MODULE 23 — Audio / Animation / Feedback
- MODULE 24 — Save / Load / Settings
- MODULE 25 — Content Completion
- MODULE 26 — Balance / Anti-Grind
- MODULE 27 — Full Game QA
- MODULE 28 — Release Integration

## Мета из исходника

# DATE FACTORY — технический план реализации

**Статус:** верхнеуровневый план реализации  
**Назначение:** определить модули проекта, их границы, зависимости и рекомендуемый порядок разработки  
**Источник продуктовых требований:** `docs/MASTER_GDD.md`  
**Важно:** этот документ НЕ является подробной технической спецификацией отдельных систем.

---
