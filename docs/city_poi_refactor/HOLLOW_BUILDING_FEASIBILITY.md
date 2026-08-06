# Hollow Building Feasibility
Вердикт по факту осмотра `Building_Small_1`, `Building_Medium_2_001`, `Building_Large_2`.

## Building_Small_1
- exterior: `hollow_shots/Building_Small_1_exterior.png`
- interior attempt: `hollow_shots/Building_Small_1_interior.png`
- topdown: `hollow_shots/Building_Small_1_topdown.png`
- вход: baked facade opening + recommended Door_* prop; named door nodes: []
- AABB: [12.46, 17.026, 14.536]
- доступный внутренний объём (gameplay): **≈0** (collision отсутствует, probes interior=0)
- прилавок: только снаружи / под навесом, не внутри mesh
- NPC внутри: нет
- лестница: нет геометрии
- нужны occluders/стены: да, полный кастомный interior, если настаивать на walk-in
- сложность collision: **высокая** (сейчас has_collision=False)
- лучший POI для этой модели: **FacadeOnly / Dedicated facade**, не HollowWalkIn
- **практический вердикт: НЕ использовать как HollowWalkInBuilding без нового ассета или модульной сборки**

## Building_Medium_2_001
- exterior: `hollow_shots/Building_Medium_2_001_exterior.png`
- interior attempt: `hollow_shots/Building_Medium_2_001_interior.png`
- topdown: `hollow_shots/Building_Medium_2_001_topdown.png`
- вход: baked facade opening + recommended Door_* prop; named door nodes: []
- AABB: [15.056, 25.009, 13.056]
- доступный внутренний объём (gameplay): **≈0** (collision отсутствует, probes interior=0)
- прилавок: только снаружи / под навесом, не внутри mesh
- NPC внутри: нет
- лестница: нет геометрии
- нужны occluders/стены: да, полный кастомный interior, если настаивать на walk-in
- сложность collision: **высокая** (сейчас has_collision=False)
- лучший POI для этой модели: **FacadeOnly / Dedicated facade**, не HollowWalkIn
- **практический вердикт: НЕ использовать как HollowWalkInBuilding без нового ассета или модульной сборки**

## Building_Large_2
- exterior: `hollow_shots/Building_Large_2_exterior.png`
- interior attempt: `hollow_shots/Building_Large_2_interior.png`
- topdown: `hollow_shots/Building_Large_2_topdown.png`
- вход: baked facade opening + recommended Door_* prop; named door nodes: []
- AABB: [20.644, 28.0, 16.645]
- доступный внутренний объём (gameplay): **≈0** (collision отсутствует, probes interior=0)
- прилавок: только снаружи / под навесом, не внутри mesh
- NPC внутри: нет
- лестница: нет геометрии
- нужны occluders/стены: да, полный кастомный interior, если настаивать на walk-in
- сложность collision: **высокая** (сейчас has_collision=False)
- лучший POI для этой модели: **FacadeOnly / Dedicated facade**, не HollowWalkIn
- **практический вердикт: НЕ использовать как HollowWalkInBuilding без нового ассета или модульной сборки**

## Альтернатива hollow
1. Собрать storefront из `Brick_*` + пол/потолок CSG/модули — отдельный pipeline.
2. Купить/добавить полые shop kits — вне текущего scope.
3. Оставить FacadeOnly + props у двери (текущий практичный путь).
