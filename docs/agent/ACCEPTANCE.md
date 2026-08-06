# Current milestone acceptance

## Milestone
`APT-INTERACT-COMPONENT-001`

## Required player route
1. Войти в квартиру FPS.
2. Смотреть на холодильник — только его подсказка/обводка; меню еды.
3. Смотреть на кухонные ящики — только их подсказка/обводка; меню напитков.
4. Пройти вдоль кухни без ложных мерцающих подсказок от пересечения.
5. Проверить кровать/стол/выход.

## Functional criteria
- [x] Fridge и KitchenDrawers interact AABB не пересекаются.
- [x] Объёмы ≈ mesh AABB (+ padding).
- [x] Interactable — дочерний компонент мебели (не плавающий 1.2³ на room root).
- [x] Меню еды/напитков корректны.

## Visual criteria
- [x] Outline на правильной мебели.
- [x] Нет FocusProxy-боксов на apartment furniture.

## Edge cases
- [x] Scale FBX ~5.6 не раздувает Area.
- [ ] City interacts smoke (не завершён в QA; out of primary route).

## Save/load
- [x] Не затронуто.

## Evidence
- [x] Git diff reviewed
- [x] Independent QA report

## Blocking failures
- Нет.

## Final decision
`READY`
