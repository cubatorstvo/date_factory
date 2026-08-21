# TECH PLAN — Date System Lab

Поверхность реализации текущей `main`. Канон правил: [`MASTER_GDD.md`](MASTER_GDD.md), [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md).

## Порядок слоёв

1. Content Resources + seed `.tres` + Catalog
2. Runtime models + `user://` store
3. Date Engine (session, RNG, mappings, Tags, Trait, Combo, scores)
4. DateEpisodeController (text)
5. Text Date Runner + Result + Debug
6. Developer Room (редакторы, валидация, запуск)
7. Автотесты

## Границы

- Нет 3D-мира, экономики, сюжета, рейтинга, clone/staff.
- Нет параллельного dating-движка: один Date Engine.
- Архивы `legacy-v1` и `legacy-v2` не являются runtime-зависимостью.
