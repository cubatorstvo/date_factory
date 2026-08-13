# Prototype City — Scene Structure

Working visual city: `res://world/locations/city_hub/art/city.tscn`  
Playable location: `res://world/locations/city_hub/city_hub.tscn` (`location_id = city_hub`)  
Prototype kit: `res://world/locations/city_hub/prototype/`

The example path `res://scenes/art/city/prototype/` is not used. This repo keeps city art under `world/locations/city_hub/`.

## `city.tscn` tree

Every building, POI, activity, road kit, boundary kit, and district gate is a PackedScene instance. `city.tscn` does not inline InteractionArea / collision / signage for shops.

```
City  (district_gate_sync.gd)
├── Stage1_MainStreet          metadata: district_id=main_street, progression_stage=1
│   ├── Buildings
│   │   ├── BG_00 … BG_05      PrototypeBackgroundHouse00–05.tscn
│   ├── POIs
│   │   ├── PlayerHome
│   │   ├── CafeTwoHearts
│   │   ├── RetailPairFlowerGift
│   │   ├── FashionPairJewelryClothing
│   │   ├── HomewareShop
│   │   └── InternetCafe
│   └── WorldActivities
│       └── MainBench
├── Stage2_ParkLeisure         metadata: district_id=park_leisure, progression_stage=2
│   ├── Buildings
│   │   └── BG_11 … BG_15
│   ├── POIs
│   │   ├── Bookstore
│   │   ├── Gym
│   │   ├── Cinema
│   │   ├── Arcade
│   │   ├── Bar
│   │   └── ParkRestaurant
│   └── WorldActivities
│       ├── ParkBench
│       ├── DuckFeeding
│       └── KaraokeStand
├── Stage3_AgencyRow           metadata: district_id=agency_row, progression_stage=3
│   ├── Buildings
│   │   └── BG_06 … BG_10
│   ├── POIs
│   │   ├── PhotoStudio
│   │   ├── BarberShop
│   │   └── AgencyOffice
│   └── WorldActivities
│       └── BusStopCandy
├── Roads                      PrototypeRoads.tscn
│   ├── RoadSurfaces
│   ├── Sidewalks
│   ├── Curbs
│   ├── Crossings
│   └── GroundPads             (plaza, grass, pond, park paths)
├── Boundaries                 PrototypeBoundaries.tscn
├── DistrictGates
│   ├── ParkGate               DistrictGate.tscn  district_id=park_leisure
│   ├── AgencyGate             DistrictGate.tscn  district_id=agency_row
│   └── AgencyGateLeisure      DistrictGate.tscn  district_id=agency_row
├── GlobalMarkers              (entrances, spawn, overview camera)
├── WorldEnvironment
└── DayKey
```

`Roads` / `Boundaries` expand to MeshInstance3D children inside their PackedScenes. Those meshes are not duplicated as loose nodes in `city.tscn`.

## Prototype PackedScenes

### Buildings / POI

| Scene | Instance in city | Origin (donor) |
|---|---|---|
| `prototype/buildings/PrototypePlayerHome.tscn` | PlayerHome | (32.6, 0, 16.5) yaw -90 |
| `prototype/buildings/PrototypeCafe.tscn` | CafeTwoHearts | (23.8, 0, 14.2) yaw +90 |
| `prototype/buildings/PrototypeRetailPairFlowerGift.tscn` | RetailPairFlowerGift | (15.45, 0, 6.35) yaw 180 |
| `prototype/buildings/PrototypeFashionPairJewelryClothing.tscn` | FashionPairJewelryClothing | (5.4, 0, 6.35) yaw 180 |
| `prototype/buildings/PrototypeHomewareShop.tscn` | HomewareShop | (12.1, 0, -6.35) |
| `prototype/buildings/PrototypeInternetCafe.tscn` | InternetCafe | (5.4, 0, -6.35) |
| `prototype/buildings/PrototypeBookstore.tscn` | Bookstore | (-14.2, 0, 12) |
| `prototype/buildings/PrototypeGym.tscn` | Gym | (-7.5, 0, 12) |
| `prototype/buildings/PrototypeCinema.tscn` | Cinema | (-27.2, 0, 17.5) yaw +90 |
| `prototype/buildings/PrototypeArcade.tscn` | Arcade | (-27.2, 0, 24.2) yaw +90 |
| `prototype/buildings/PrototypeBar.tscn` | Bar | (-16.5, 0, 29.8) yaw 180 |
| `prototype/buildings/PrototypeParkRestaurant.tscn` | ParkRestaurant | (3.2, 0, 21.2) yaw 180 |
| `prototype/buildings/PrototypePhotoStudio.tscn` | PhotoStudio | (-12.5, 0, -6.35) |
| `prototype/buildings/PrototypeBarberShop.tscn` | BarberShop | (-24.5, 0, 11.8) yaw 180 |
| `prototype/buildings/PrototypeAgencyOffice.tscn` | AgencyOffice | (-19.2, 0, -6.35) |

### Activities

| Scene | Instance | Origin |
|---|---|---|
| `prototype/activities/PrototypeMainBench.tscn` | MainBench | (-3.6, 0, 3.4) |
| `prototype/activities/PrototypeParkBench.tscn` | ParkBench | (-3.8, 0, 22.8) |
| `prototype/activities/PrototypeDuckFeeding.tscn` | DuckFeeding | (6.2, 0, 16.8) |
| `prototype/activities/PrototypeKaraokeStand.tscn` | KaraokeStand | (-10.5, 0, 26.5) |
| `prototype/activities/PrototypeBusStopCandy.tscn` | BusStopCandy | (-30.5, 0, 5) |

### Background houses

`prototype/background/PrototypeBackgroundHouse00.tscn` … `15.tscn`  
Instanced as `BG_00` … `BG_15` under the matching Stage `Buildings` node.

### Infra

| Scene | Role |
|---|---|
| `prototype/PrototypeRoads.tscn` | Road surfaces, sidewalks, curbs, crossings, park pads |
| `prototype/PrototypeBoundaries.tscn` | Visible wall blocks + invisible floor collider |
| `art/poi/core/DistrictGate.tscn` | Reusable district barrier (unchanged look) |
| `prototype/district_gate_sync.gd` | Opens gates from Story features |

## POI internals (inside each PackedScene)

Typical building POI contains:

- VisualRoot (BoxMesh / PrismMesh volumes, portal, windows, awning)
- CollisionRoot / StaticBody3D
- TenantSlots → tenant with `poi_id`
- InteractionArea (`action_id`)
- EntranceAnchor, PromptAnchor, SignAnchor
- Signage (board + Label3D)
- LocalLights

`city.tscn` has **no** shop `InteractionArea` nodes of its own.

## Hub travel (not inside `city.tscn`)

Real location travel stays on `city_hub.tscn` → `Transitions/`:

- ToApartment `(31.55, 1.1, 16.5)`
- ToCafe `(24.85, 1.1, 14.2)`
- ToGym `(-7.5, 1.1, 13.05)`
- ToAppearance `(-12.5, 1.1, -5.3)`
- ToMine `(-19.2, 1.1, -5.3)`
- plus lab / production / final markers
