# Asset gap list

Search order: imported `res://assets/` first, then `C:\Users\User\Downloads\assets`. No new external pack without an Orchestrator decision.

## Existing packs suitable for hardening

- Downtown City MegaKit: facades, modular street buildings, vegetation and urban props.
- Ultimate House Interior: apartment/themed-room furniture, shelves, desks, salon/office substitutes.
- Sushi Restaurant Kit: restaurant interior and food service modules.
- Ultimate Food Pack: food, table and shop display props.
- Sci-Fi Essentials: arcade/photo/lab screens and technical props.
- Kenney Factory: factory/industrial rooms.
- Modular Women, Universal Base Characters and Universal Animation Library: actors/animation.
- Kenney UI/game-icons/input-prompts in Downloads: selected UI replacements only.

## Required visual replacements

City POI prefabs staged under `scenes/art/city/prefabs/` (not wired into `city.tscn` yet). Registry: `docs/release/ASSET_LICENSE_REGISTRY.md`.

| Gap | Preferred source | Current fallback rule |
|---|---|---|
| Flower shop facade/display | Downtown + Food/House props | Prefab `FlowerShop.tscn` staged |
| Jewelry/gift/clothing/homeware storefront identity | Downtown + House props + selected icons | Prefabs `JewelryShop` / `GiftShop` / `ClothingShop` / `HomewareShop` |
| Park restaurant facade | Downtown exterior + Sushi interior cues | Prefab `ParkRestaurant.tscn` |
| Bench activity staging | Existing city benches + UAL sit/stand | Prefabs `MainBench` / `ParkBench` |
| Duck feeding | Downtown park/water + available animal search | Prefab `DuckFeeding` — authored ducks (no pack mesh) |
| Karaoke stand | House/Sci-Fi/Factory audio-screen props | Prefab `KaraokeStand` — authored mic + Kenney screen |
| Gym | House/Sci-Fi/Factory candidates | Prefab `GymFacade` — Kenney machine + authored rack |
| Cinema | Downtown facade + house seating/screens | Prefab `CinemaFacade` + Kenney screen-wide |
| Arcade | Sci-Fi terminals + Factory props | Prefab `ArcadeFacade` — authored cabinets + Kenney screens |
| Photo studio | House electronics + Sci-Fi lights/screens | Prefab `PhotoStudio` — authored camera/tripod |
| Barber | House chair/desk/mirror candidates | Prefab `BarberShop.tscn` |
| Agency | House office + Sci-Fi screens | Prefab `AgencyOffice.tscn` |
| Bus stop / candy | Downtown urban props (missing in Standard) | Prefab `BusStopCandy` — authored shelter/machine |
| Internet cafe / coffee | Downtown + Sci-Fi desk + screens | Prefab `InternetCafe.tscn` |
| Bar | Downtown + Sushi counter cues | Prefab `BarFacade.tscn` |
| Themed apartments | House Interior variants | Three coherent set-dressing families |
| Factory/orbital expansion rooms | Kenney Factory / selected Modular Sci-Fi sample | No mass import; representative POC first |
| Gift icons | Kenney game-icons + project-authored variants | Placeholders cannot ship |

## License/provenance gaps

- Add official source/license record for Quaternius Sushi Restaurant Kit.
- Add SIL OFL files for Outfit and DM Sans.
- Verify or remove drinkware assets from shipped scenes.
- Update in-game credits and repository asset registry.

## Import constraints

- One chosen format per asset; do not re-import Sushi FBX/OBJ beside existing glTF.
- Import only used objects, not entire archives.
- Normalize scale, pivot, materials and collision in a reusable prefab.
- Validate in the real target scene.
- Keep source archives, Blender working files, captures and testbeds out of export.

## Evidence required before closing a gap

- Exact source path and pack.
- License/source record.
- Chosen format and duplicate rejection.
- Godot prefab/scene path.
- Scale/material/collision check.
- Screenshot in the normal-route environment.
