# Asset / license registry (release)

Living provenance table for packs used by city POI prefabs and shipped environment art.  
Update when importing new objects. Do not ship packs without a row here.

## Packs in use (city POI pass)

| Pack ID | Source archive (Downloads) | Project path | Format used | License | Credit line |
|---|---|---|---|---|---|
| Downtown City MegaKit (Standard) | `Downtown City MegaKit[Standard].zip` | `assets/environment/city/downtown_megakit/` | glTF only | CC0 1.0 (Quaternius) — `LICENSE.txt` in folder | Quaternius — Downtown City MegaKit (CC0) |
| Ultimate House Interior | `Ultimate House Interior Pack - June 2020-…zip` | `assets/environment/interior/house_interior/` | FBX only | See pack `LICENSE.txt` | Quaternius — Ultimate House Interior |
| Ultimate Food Pack | `Ultimate Food Pack - Oct 2019-…zip` | `assets/props/food/` | FBX only | See pack `LICENSE.txt` | Quaternius — Ultimate Food Pack |
| Sushi Restaurant Kit | `Sushi Restaurant Kit - May 2023-…zip` | `assets/environment/restaurant/sushi_restaurant/` | glTF only | **UNRESOLVED in tree** — vendor personal/commercial claim noted in baseline audit; **no LICENSE file in zip/project** | Quaternius? / vendor TBD — **blocker for export credits** |
| Sci-Fi Essentials (Standard) | `Sci-Fi Essentials Kit[Standard].zip` | `assets/environment/lab/scifi_essentials/` | glTF only | CC0 Standard subset — `LICENSE.txt` | Quaternius — Sci-Fi Essentials (CC0 subset) |
| Kenney Factory Kit 3.0 | `kenney_factory-kit_3.0.zip` | `assets/environment/factory/kenney_factory/` | GLB only | CC0 — `LICENSE.txt` | Kenney — Factory Kit (CC0) |

## Selective imports this pass (not whole packs)

| Object | From pack | Dest | Notes |
|---|---|---|---|
| `screen-small.glb` | Kenney Factory | `…/kenney_factory/meshes/` | Arcade / karaoke / photo |
| `screen-wide.glb` | Kenney Factory | same | Cinema / agency |
| `screen-panel-small.glb` | Kenney Factory | same | Internet cafe / photo |
| `screen-hanging-small.glb` | Kenney Factory | same | Reserve / secondary displays |
| `machine.glb` | already present | same | Gym cardio silhouette |

## Prefab catalog

Reusable roots (collision + Interact/Prompt/Outline anchors). **`city.tscn` not modified.**

Path: `scenes/art/city/prefabs/`

| Prefab | Primary sources | Temporary authored parts |
|---|---|---|
| FlowerShop | Downtown building/door/window/planter + Sushi sakura/plant | Awning / window glow CSG |
| JewelryShop / GiftShop / ClothingShop / HomewareShop | Downtown + House shelf/bookshelf + Food display props + Sushi sign | Awning / identity band CSG |
| ParkRestaurant | Downtown medium building + Sushi counter/table/stool/sign | Awning CSG |
| MainBench / ParkBench | Sushi `Environment_Bench` + Downtown planters/bollard | — |
| DuckFeeding | Downtown planter | Pond rim/water/feeder + stylized ducks CSG |
| KaraokeStand | Kenney screen + House light stand | Stage/mic/speakers CSG |
| InternetCafe | Downtown + Sci-Fi desk/chair + Kenney panel + Food bottle | Awning CSG |
| BarFacade | Downtown + Sushi counter/stools + Food bottles | Neon band CSG |
| BusStopCandy | Sushi bench + House trash + Food chocolate | Shelter + candy machine CSG |
| GymFacade | Downtown + Kenney machine | Rack/barbell/mat CSG |
| CinemaFacade | Downtown + Kenney wide screen + House chairs | Marquee CSG |
| ArcadeFacade | Downtown + Kenney screens | Cabinet housings CSG |
| PhotoStudio | Downtown + House lights + Kenney panel | Backdrop/tripod/camera CSG |
| BarberShop | Downtown + House chair/mirror/shelf | Barber pole CSG |
| AgencyOffice | Downtown + Sci-Fi desk/shelf/chair + Kenney wide screen | Board sign CSG |
| City_POI_Prefab_Index | Instances above for visual review | — |

## Open provenance problems

| ID | Issue | Action needed |
|---|---|---|
| LIC-SUSHI-01 | No LICENSE in Sushi kit zip/project | Add vendor license text + credits line before export |
| LIC-FONT-01 | Outfit / DM Sans OFL files missing under `assets/fonts/` | Add SIL OFL texts (out of city POI scope) |
| LIC-DRINK-01 | `assets/environment/interior/drinkware/` provenance unclear | Prefer Food pack bottles in POI prefabs; resolve or remove drinkware |
| LIC-CRED-01 | In-game finale credits omit pack list | Content/release pass |
| PACK-MODSCIFI | Modular SciFi still deferred (material risk) | Not imported this pass; arcade uses Kenney screens + authored cabinets |

## Rebuild

```powershell
& C:\godot\Godot_v4.7.1-stable_win64.exe --headless --path C:\Users\User\Documents\GodotProjects\date_factory --script res://tools/build_city_poi_prefabs.gd --quit-after 90
```
