# POI Replacement Guide

Temporary proxy POIs with a **final functional contract**. When final assets arrive, replace visuals/collision/local entrance pose only.

## Global replacement rule

### MAY replace later
- `VisualRoot` contents (meshes / GLB)
- `CollisionRoot` contents
- Local pose of `EntranceAnchor` (and InteractionArea offset) **inside** the prefab
- Signage / LocalLights / IdentityProps cosmetics

### MUST NOT change
- Building root transform in `city.tscn`
- `building_id`, `district_id`
- Tenant `poi_id`, `action_id` (and multi-action sibling action_ids)
- Save schema / district unlock system
- Interaction routing (`Interactable` → `InteractionRouter` / quest gates)
- Street / district / GeneratedCity layout

Documented in `CityPOIBuilding.gd` and `CityPOITenant.gd`.

`LotBounds` is editor-visible (or meta `debug_show_lot_bounds`); hidden in normal play.

---

## How to swap a building

1. Open the PackedScene under `scenes/art/city/poi/buildings/` (or `activities/`).
2. Replace children of `VisualRoot` / `CollisionRoot`.
3. Nudge `TenantSlots/*/EntranceAnchor` so it sits at the new door/arch (0.3–1.0 m into opening if arch).
4. Keep `InteractionArea` as `Interactable` with the same `action_id`.
5. Do **not** move the instance transform in `city.tscn`.
6. Playtest approach + prompt + action once.

---

## Per-building card

### PlayerHome — `buildings/PlayerHome.tscn`
| Field | Value |
|---|---|
| Replace | `VisualRoot` (`Building_Small_1`), `CollisionRoot`, Home `EntranceAnchor` local pose |
| LotBounds | 9 × 8 m |
| EntranceAnchor | TenantSlots/Home ≈ local (0, 0, 1.05) in front of baked opening |
| Do not change | Root in city @ (32.6,0,16.5); `poi_id=player_home`; `action_id=go_home`; `district_id=main_street` |

### CafeTwoHearts — `buildings/CafeTwoHearts.tscn`
| Field | Value |
|---|---|
| Replace | `VisualRoot` (`Building_Medium_2_001` + outdoor props), collision, Cafe EntranceAnchor |
| LotBounds | 10 × 9 m |
| EntranceAnchor | TenantSlots/Cafe ≈ (0, 0, 1.05); no Door mesh over baked door |
| Do not change | Root @ (23.8,0,14.2); `action_id=sit_cafe`; dating sit flow |

### Cinema — `buildings/Cinema.tscn`
| Field | Value |
|---|---|
| Replace | `VisualRoot` (`Building_Large_2` + marquee), collision, Cinema EntranceAnchor |
| LotBounds | 14 × 11 m |
| EntranceAnchor | TenantSlots/Cinema ≈ (0, 0, 1.05) at baked opening |
| Do not change | Root @ (−27.2,0,17.5); `action_id=sit_cinema`; park_leisure |

### RetailPairFlowerGift — `buildings/RetailPairFlowerGift.tscn`
| Field | Value |
|---|---|
| Replace | Shared façade under `VisualRoot`; per-tenant Signage/IdentityProps; both EntranceAnchors |
| LotBounds | 12 × 7.5 m |
| EntranceAnchor | Flower ≈ (−1.8, 0, 1.05); Gift ≈ (1.8, 0, 1.05) |
| Do not change | Root @ (15.45,0,6.35); `open_flower_shop` / `open_gift_shop` |

### FashionPairJewelryClothing — `buildings/FashionPairJewelryClothing.tscn`
| Field | Value |
|---|---|
| Replace | Shared façade; Jewelry + Clothing tenant visuals/anchors |
| LotBounds | 12 × 7.5 m |
| EntranceAnchor | Jewelry ≈ (−1.8, 0, 1.05); Clothing ≈ (1.8, 0, 1.05) |
| Do not change | Root @ (5.4,0,6.35); `open_jewelry_shop` / `open_clothing_shop` |

### HomewareShop — `buildings/HomewareShop.tscn`
| Field | Value |
|---|---|
| Replace | Proxy `VisualRoot`/`CollisionRoot`, EntranceAnchor |
| LotBounds | 6 × 7 m |
| EntranceAnchor | TenantSlots/Homeware ≈ (0, 0, 1.05) at recessed portal |
| Do not change | Root @ (12.1,0,−6.35); `open_homeware_shop` |

### InternetCafe — `buildings/InternetCafe.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision; keep **three** Interactables (job/scroll/coffee) local offsets |
| LotBounds | 7 × 7 m |
| EntranceAnchor | Primary at portal; siblings offset for PCs/coffee |
| Do not change | Root @ (5.4,0,−6.35); `city_cafe_job`, `city_cafe_scroll`, `city_coffee` |

### Bookstore — `buildings/Bookstore.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor |
| LotBounds | 6 × 7 m |
| EntranceAnchor | TenantSlots/Books ≈ (0, 0, 1.05) |
| Do not change | Root @ (−14.2,0,12); `open_bookstore`; park_leisure |

### Gym — `buildings/Gym.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision; keep workout + gym_pass Interactables |
| LotBounds | 9 × 8 m |
| EntranceAnchor | Primary portal; pass Interactable nearby |
| Do not change | Root @ (−7.5,0,12); `city_workout`, `city_gym_pass` |

### PhotoStudio — `buildings/PhotoStudio.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor |
| LotBounds | 6 × 7 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (−12.5,0,−6.35); `open_photo_studio` + payload `venue_id=photo_studio` |

### BarberShop — `buildings/BarberShop.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor (pole prop optional) |
| LotBounds | 6 × 7 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (−24.5,0,11.8); `open_barber`; agency_row |

### AgencyOffice — `buildings/AgencyOffice.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor |
| LotBounds | 10 × 9 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (−19.2,0,−6.35); `open_agency_board` |

### Arcade — `buildings/Arcade.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision; keep open_arcade + sit_arcade Interactables |
| LotBounds | 8 × 8 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (−27.2,0,24.2); `open_arcade`, `sit_arcade` |

### Bar — `buildings/Bar.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor |
| LotBounds | 7 × 7 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (−16.5,0,29.8); `city_bar_drink` |

### ParkRestaurant — `buildings/ParkRestaurant.tscn`
| Field | Value |
|---|---|
| Replace | Visual/collision/EntranceAnchor (keep distinct from Cafe) |
| LotBounds | 10 × 9 m |
| EntranceAnchor | ≈ (0, 0, 1.05) |
| Do not change | Root @ (3.2,0,21.2); `sit_restaurant` |

---

## WorldActivity (no building shell)

| Scene | Lot / footprint | Replace | Keep |
|---|---|---|---|
| `activities/MainBench.tscn` | activity-sized | Mesh/props under IdentityProps | `city_rest`; root transform |
| `activities/ParkBench.tscn` | activity-sized | Visuals | `city_rest` + payload `bonus=1.5` |
| `activities/DuckFeeding.tscn` | activity-sized | Visuals | `city_park_fun` |
| `activities/KaraokeStand.tscn` | activity-sized | Visuals | `city_karaoke` |
| `activities/BusStopCandy.tscn` | activity-sized | Shelter/machine visuals | `city_bus_info` + `city_buy_gift` |

---

## DistrictGate

Canonical: `scenes/art/city/poi/core/DistrictGate.tscn`  
Instances: `Decor/ParkGate`, `AgencyGate`, `AgencyGateLeisure` — **do not move** without re-validating district flow.  
Exports: `district_id`, `locked_text`, `gate_width`, `gate_height`, `rest_alpha`, `focused_alpha`, `fade_duration`.

---

## Markers still owned by city.tscn

Keep for spawn/return/picnic/camera even after visual replacement:
`PlayerSpawn`, `ApartmentReturn`, `HomeEntrance` (spawn sync), `ParkPicnicSpot` (`sit_park`), `PhotoMark`, overview/bounds markers.
