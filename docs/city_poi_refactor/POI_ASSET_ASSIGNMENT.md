# POI Asset Assignment (варианты для утверждения)
Повтор ассетов неизбежен: в репо только 3 Building_*. Повтор допустим только с разным scale/yaw/sign/light/prop kit.

## `cafe_two_hearts`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `DedicatedBuilding / FacadeOnlyBuilding`
- дверь/арка: Door_1 перед baked opening
- этажность: visual 2–3 @scale0.45
- multi-tenant: нет
- партнёры: —
- совместимость: якорь main_street
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: розовая вывеска TWO HEARTS + warm omni + outdoor table
- сложность: **низкая**
- повтор ассета: Medium часто; cafe получает уникальный sign/awning/props

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `DedicatedBuilding`
- дверь/арка: Door_1
- этажность: крупный landmark
- multi-tenant: нет
- партнёры: —
- совместимость: максимальная узнаваемость
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: самый крупный силуэт на улице
- сложность: **средняя**
- повтор ассета: Large редкий — лучше сохранить для cinema/agency

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnlyBuilding`
- дверь/арка: Door_1
- этажность: 1–2
- multi-tenant: нет
- партнёры: —
- совместимость: компактнее
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: слабее как landmark
- сложность: **низкая**
- повтор ассета: n/a

## `park_restaurant`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `DedicatedBuilding / FacadeOnly`
- дверь/арка: Door_2
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: venue stage2
- стадии: 2
- lock closed tenant: district gate
- отличие от соседей: PARK BISTRO sign + warm light
- сложность: **низкая**
- повтор ассета: тот же Medium что cafe — другой yaw/district/sign/props

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `DedicatedBuilding`
- дверь/арка: Door_2
- этажность: 3
- multi-tenant: возможно + bar
- партнёры: bar (тот же district)
- совместимость: крупный night/food hub
- стадии: 2
- lock closed tenant: если bar отдельно — отдельный DoorAnchor
- отличие от соседей: крупнее cinema
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: бюджетный
- стадии: 2
- lock closed tenant: n/a
- отличие от соседей: слабый
- сложность: **низкая**
- повтор ассета: n/a

## `cinema`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `DedicatedBuilding / FacadeOnly`
- дверь/арка: Door_3 wide
- этажность: 3 visual
- multi-tenant: нет
- партнёры: —
- совместимость: нужен уникальный силуэт
- стадии: 2
- lock closed tenant: district
- отличие от соседей: wide door + neon posters + marquee CSG
- сложность: **средняя**
- повтор ассета: Large #1 priority for cinema

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_2
- этажность: 2
- multi-tenant: с gift? нет — разные районы
- партнёры: —
- совместимость: если Large занят agency
- стадии: 2
- lock closed tenant: district
- отличие от соседей: постеры/неон
- сложность: **низкая**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `MultiTenantBuilding (фасадные DoorAnchors)`
- дверь/арка: ground Door_3 + side Door_1
- этажность: ground cinema / upper unused locked
- multi-tenant: да: cinema + optional gift kiosk только если gift переносится в park — не рекомендуется
- партнёры: не рекомендовать gift
- совместимость: риск путаницы
- стадии: 2
- lock closed tenant: верхний DoorAnchor закрыт prop door
- отличие от соседей: сложнее без выигрыша
- сложность: **высокая**
- повтор ассета: n/a

## `arcade`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly + awning props`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: screen props уже есть
- стадии: 2
- lock closed tenant: district
- отличие от соседей: kenney screens + neon
- сложность: **низкая**
- повтор ассета: Small часто; screens делают уникальность

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: крупнее
- стадии: 2
- lock closed tenant: district
- отличие от соседей: сильнее
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `WorldActivity awning + machines (без building)`
- режим: `WorldActivityPOI cluster`
- дверь/арка: n/a
- этажность: 0
- multi-tenant: n/a
- партнёры: —
- совместимость: если не хватает зданий
- стадии: 2
- lock closed tenant: district
- отличие от соседей: не здание
- сложность: **средняя**
- повтор ассета: n/a

## `flower_shop`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnlyBuilding`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: storefront
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: plants + pink awning
- сложность: **низкая**
- повтор ассета: Small shared; identity via plants/sign

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenantBuilding с gift_shop`
- дверь/арка: две Door_* side-by-side
- этажность: 1 shared facade
- multi-tenant: да flower+gift
- партнёры: gift_shop
- совместимость: оба stage1 main_street retail
- стадии: 1+1
- lock closed tenant: не нужен
- отличие от соседей: две вывески на одном Small — тесно
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `modular Brick storefront (custom)`
- режим: `HollowWalkInBuilding`
- дверь/арка: arch Brick
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: реальный walk-in
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: уникальный
- сложность: **высокая**
- повтор ассета: n/a

## `gift_shop`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: retail
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: gift props/sign
- сложность: **низкая**
- повтор ассета: Small; другой accent color

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant с flower`
- дверь/арка: shared
- этажность: 1
- multi-tenant: да
- партнёры: flower_shop
- совместимость: совместимо
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: сдвоенная витрина
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: если нужен крупный gift hub
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: крупнее
- сложность: **средняя**
- повтор ассета: n/a

## `jewelry_shop`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_2
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: retail
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: gold accent band + glass props
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant с clothing`
- дверь/арка: две двери
- этажность: 1
- multi-tenant: да
- партнёры: clothing_shop
- совместимость: fashion cluster
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: fashion strip
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_2
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: premium silhouette
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: крупнее
- сложность: **средняя**
- повтор ассета: n/a

## `clothing_shop`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: retail
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: wardrobe prop + color
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant jewelry`
- дверь/арка: dual
- этажность: 1
- multi-tenant: да
- партнёры: jewelry_shop
- совместимость: fashion
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: paired
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: flagship
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: крупнее
- сложность: **средняя**
- повтор ассета: n/a

## `homeware_shop`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: retail
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: shelf props
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant с homeware+internet? нет`
- дверь/арка: —
- этажность: 1
- multi-tenant: не рек.
- партнёры: internet_cafe
- совместимость: разный UX (shop UI vs terminals)
- стадии: 1
- lock closed tenant: —
- отличие от соседей: путаница
- сложность: **высокая**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: крупный
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: силуэт
- сложность: **средняя**
- повтор ассета: n/a

## `bookstore`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: leisure retail
- стадии: 2
- lock closed tenant: district
- отличие от соседей: bookshelf + blue awning
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `MultiTenant bookstore ground + cinema upper? `
- дверь/арка: ground Door_1 / upper locked
- этажность: 2
- multi-tenant: книжный+кино — разные здания лучше
- партнёры: cinema
- совместимость: тематика слабо; cinema теряет uniqueness
- стадии: 2+2
- lock closed tenant: верхний вход prop-door
- отличие от соседей: плохо для cinema landmark
- сложность: **высокая**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant bookstore+gym? нет`
- дверь/арка: —
- этажность: 1
- multi-tenant: не рек.
- партнёры: gym
- совместимость: несовместимо тематически
- стадии: 2
- lock closed tenant: —
- отличие от соседей: —
- сложность: **высокая**
- повтор ассета: n/a

## `gym`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: machine prop identity
- стадии: 2
- lock closed tenant: district
- отличие от соседей: kenney machine + posters
- сложность: **низкая**
- повтор ассета: Medium

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `Dedicated`
- дверь/арка: Door_2
- этажность: 3
- multi-tenant: нет
- партнёры: —
- совместимость: спорт landmark
- стадии: 2
- lock closed tenant: district
- отличие от соседей: крупный
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: компакт
- стадии: 2
- lock closed tenant: district
- отличие от соседей: слабее
- сложность: **низкая**
- повтор ассета: n/a

## `internet_cafe`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly (+ later Hollow custom)`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: multiple terminal interacts
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: PC desks outside/under awning
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `modular hollow`
- режим: `HollowWalkInBuilding`
- дверь/арка: arch
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: лучшие терминалы внутри
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: уникальный walk-in
- сложность: **высокая**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: крупнее
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: силуэт
- сложность: **средняя**
- повтор ассета: n/a

## `bar`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: night leisure
- стадии: 2
- lock closed tenant: district
- отличие от соседей: warm/red light + counter
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `MultiTenant bar ground + karaoke annex`
- дверь/арка: Door_1
- этажность: 1–2
- multi-tenant: bar + karaoke world activity рядом лучше отдельно
- партнёры: karaoke (рядом, не внутри)
- совместимость: karaoke WorldActivity
- стадии: 2
- lock closed tenant: n/a
- отличие от соседей: кластер
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `Dedicated`
- дверь/арка: Door_2
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: club silhouette
- стадии: 2
- lock closed tenant: district
- отличие от соседей: крупный
- сложность: **средняя**
- повтор ассета: n/a

## `photo_studio`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: agency row
- стадии: 3
- lock closed tenant: agency gate
- отличие от соседей: screen-panel + posters
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `MultiTenant photo + barber`
- дверь/арка: две двери на фасаде
- этажность: 1
- multi-tenant: да
- партнёры: barber
- совместимость: оба stage3 agency services
- стадии: 3+3
- lock closed tenant: не нужен
- отличие от соседей: services strip
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: studio landmark
- стадии: 3
- lock closed tenant: gate
- отличие от соседей: крупнее
- сложность: **средняя**
- повтор ассета: n/a

## `barber`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: service
- стадии: 3
- lock closed tenant: gate
- отличие от соседей: chair/desk props + stripe pole CSG
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `MultiTenant с photo`
- дверь/арка: dual
- этажность: 1
- multi-tenant: да
- партнёры: photo_studio
- совместимость: agency services
- стадии: 3
- lock closed tenant: n/a
- отличие от соседей: paired
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: крупный
- стадии: 3
- lock closed tenant: gate
- отличие от соседей: силуэт
- сложность: **средняя**
- повтор ассета: n/a

## `agency_office`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `DedicatedBuilding / FacadeOnly`
- дверь/арка: Door_2
- этажность: 2–3
- multi-tenant: нет
- партнёры: —
- совместимость: quest hub / schedule board — нужен читаемый офис
- стадии: 3
- lock closed tenant: gate
- отличие от соседей: wide screen + office desks
- сложность: **низкая**
- повтор ассета: Medium; agency lighting cooler

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `Dedicated`
- дверь/арка: Door_3
- этажность: 3
- multi-tenant: нет
- партнёры: —
- совместимость: HQ silhouette
- стадии: 3
- lock closed tenant: gate
- отличие от соседей: самый крупный в agency
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf`
- режим: `MultiTenant agency + photo + barber`
- дверь/арка: lobby Door_3 + side doors
- этажность: 3 visual
- multi-tenant: да
- партнёры: photo, barber
- совместимость: один HQ
- стадии: все 3
- lock closed tenant: side doors ok same stage
- отличие от соседей: сильный hub но сложная навигация
- сложность: **высокая**
- повтор ассета: n/a

## `player_home`
### Вариант 1 ★ recommend
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `Dedicated / FacadeOnly`
- дверь/арка: Door_1
- этажность: 2
- multi-tenant: нет
- партнёры: —
- совместимость: spawn landmark
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: HOME sign purple
- сложность: **низкая**
- повтор ассета: Small

### Вариант 2
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf`
- режим: `Dedicated`
- дверь/арка: Door_1
- этажность: 3
- multi-tenant: нет
- партнёры: —
- совместимость: более жилой
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: крупнее cafe?
- сложность: **средняя**
- повтор ассета: n/a

### Вариант 3
- asset: `res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf`
- режим: `FacadeOnly`
- дверь/арка: Door_1
- этажность: 1
- multi-tenant: нет
- партнёры: —
- совместимость: как сейчас
- стадии: 1
- lock closed tenant: n/a
- отличие от соседей: стандарт
- сложность: **низкая**
- повтор ассета: n/a

## `main_bench`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

## `park_bench`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

## `duck_feeding`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

## `karaoke`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

## `bus_stop_candy`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

## `park_picnic`
- Режим: **WorldActivityPOI** — без Building_* обязательно.
- Вариант A ★: текущий prop prefab, перенос interact внутрь корня prefab.
- Вариант B: усиленный prop cluster (ещё props) без здания.
- Вариант C: привязка к навесу/стене ближайшего FacadeOnly только как backdrop, не multi-tenant.
- сложность: низкая.

