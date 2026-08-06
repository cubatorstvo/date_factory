# Building Asset Catalog
Фактический осмотр downtown megakit `Building_*` (Godot AABB + interior cameras + ray probes).
В проекте сейчас только **3 целых здания**. Остальной megakit — модульный кирпич/двери/пропы.

## `Building_Small_1`
- **path:** `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- **AABB size (unit scale):** 12.460 × 17.026 × 14.536 m
- **visual floors estimate (÷3.2m):** 5
- **отдельные входы (named door nodes):** нет — дверь в baked facade
- **положение двери/арки:** front_face_center_guess=[-1.0, 0.988, 2.306]; использовать `Door_*` prop или DoorAnchor перед визуальным проёмом
- **фронт:** условно +Z AABB (уточнять при посадке по силуэту окон)
- **полое?** ray interior_probe_hits=0 / open_sky=5 — **не полое как walk-in объём**
- **внутреннее пространство пригодно?** нет (камера “interior” упирается в фасад/пустоту без пола/потолков как gameplay volume)
- **пол/стены/потолок внутри:** mesh shell без collision; probes ceiling/floor = false
- **открыта задняя сторона:** визуально фасадный объём; не использовать как комнату без доработки
- **войти игроком?** только после добавления кастомных collision + interior occluders / или отказаться
- **прилавок внутри?** не рекомендуется на текущей модели
- **лестница/переход?** нет готового; MultiTenant потребует внешние StairTransitionPOI или отдельные DoorAnchors на фасаде
- **DedicatedBuilding:** да
- **MultiTenantBuilding:** True по габариту, но только как несколько фасадных DoorAnchors, не этажи-интерьеры
- **HollowWalkInBuilding:** **нет** на текущих данных
- **проблемы импорта:** has_collision_shapes=False; mesh_instance_count=1
- **shots:** res://docs/city_poi_refactor/hollow_shots/Building_Small_1_exterior.png, res://docs/city_poi_refactor/hollow_shots/Building_Small_1_interior.png, res://docs/city_poi_refactor/hollow_shots/Building_Small_1_topdown.png

## `Building_Medium_2_001`
- **path:** `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- **AABB size (unit scale):** 15.056 × 25.009 × 13.056 m
- **visual floors estimate (÷3.2m):** 8
- **отдельные входы (named door nodes):** нет — дверь в baked facade
- **положение двери/арки:** front_face_center_guess=[0.0, 0.99, 0.568]; использовать `Door_*` prop или DoorAnchor перед визуальным проёмом
- **фронт:** условно +Z AABB (уточнять при посадке по силуэту окон)
- **полое?** ray interior_probe_hits=0 / open_sky=5 — **не полое как walk-in объём**
- **внутреннее пространство пригодно?** нет (камера “interior” упирается в фасад/пустоту без пола/потолков как gameplay volume)
- **пол/стены/потолок внутри:** mesh shell без collision; probes ceiling/floor = false
- **открыта задняя сторона:** визуально фасадный объём; не использовать как комнату без доработки
- **войти игроком?** только после добавления кастомных collision + interior occluders / или отказаться
- **прилавок внутри?** не рекомендуется на текущей модели
- **лестница/переход?** нет готового; MultiTenant потребует внешние StairTransitionPOI или отдельные DoorAnchors на фасаде
- **DedicatedBuilding:** да
- **MultiTenantBuilding:** True по габариту, но только как несколько фасадных DoorAnchors, не этажи-интерьеры
- **HollowWalkInBuilding:** **нет** на текущих данных
- **проблемы импорта:** has_collision_shapes=False; mesh_instance_count=1
- **shots:** res://docs/city_poi_refactor/hollow_shots/Building_Medium_2_001_exterior.png, res://docs/city_poi_refactor/hollow_shots/Building_Medium_2_001_interior.png, res://docs/city_poi_refactor/hollow_shots/Building_Medium_2_001_topdown.png

## `Building_Large_2`
- **path:** `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- **AABB size (unit scale):** 20.644 × 28.000 × 16.645 m
- **visual floors estimate (÷3.2m):** 9
- **отдельные входы (named door nodes):** нет — дверь в baked facade
- **положение двери/арки:** front_face_center_guess=[1.0, 1.0, 0.322]; использовать `Door_*` prop или DoorAnchor перед визуальным проёмом
- **фронт:** условно +Z AABB (уточнять при посадке по силуэту окон)
- **полое?** ray interior_probe_hits=0 / open_sky=5 — **не полое как walk-in объём**
- **внутреннее пространство пригодно?** нет (камера “interior” упирается в фасад/пустоту без пола/потолков как gameplay volume)
- **пол/стены/потолок внутри:** mesh shell без collision; probes ceiling/floor = false
- **открыта задняя сторона:** визуально фасадный объём; не использовать как комнату без доработки
- **войти игроком?** только после добавления кастомных collision + interior occluders / или отказаться
- **прилавок внутри?** не рекомендуется на текущей модели
- **лестница/переход?** нет готового; MultiTenant потребует внешние StairTransitionPOI или отдельные DoorAnchors на фасаде
- **DedicatedBuilding:** да
- **MultiTenantBuilding:** True по габариту, но только как несколько фасадных DoorAnchors, не этажи-интерьеры
- **HollowWalkInBuilding:** **нет** на текущих данных
- **проблемы импорта:** has_collision_shapes=False; mesh_instance_count=1
- **shots:** res://docs/city_poi_refactor/hollow_shots/Building_Large_2_exterior.png, res://docs/city_poi_refactor/hollow_shots/Building_Large_2_interior.png, res://docs/city_poi_refactor/hollow_shots/Building_Large_2_topdown.png

## Двери / рамы
- `res://assets/environment/city/downtown_megakit/meshes/Door_1.gltf` AABB≈[1.0, 2.2, 0.26]
- `res://assets/environment/city/downtown_megakit/meshes/Door_2.gltf` AABB≈[1.0, 2.2, 0.21]
- `res://assets/environment/city/downtown_megakit/meshes/Door_3.gltf` AABB≈[1.0, 2.2, 0.188]
- `res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Wooden.gltf` AABB≈[2.304, 3.0, 0.478]
- `res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Metal_Single.gltf` AABB≈[2.0, 3.0, 0.2]
- `res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Trim.gltf` AABB≈[2.0, 3.0, 0.226]

## Модульный megakit (не целые здания)
- `Brick_*`, `Sidewalk_*`, `Prop_*` — можно собрать кастомный hollow storefront (высокая сложность).
- Не считать готовым HollowWalkInBuilding без отдельного build pipeline.

## Прочие наборы
- `sushi_restaurant` Environment_* — прилавки/столы/стулья для storefront props.
- `kenney_factory` screens/machine — аркада/агентство/караоке (не здания).
- `scifi_essentials` desk/shelves/chair — барбер/офис props.
