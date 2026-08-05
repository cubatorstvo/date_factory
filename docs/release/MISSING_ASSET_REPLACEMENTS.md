# Missing asset replacements

Living release list after city POI prefab pass (`scenes/art/city/prefabs/`).  
`city.tscn` was **not** rebuilt. Search order: `res://assets/` → `C:\Users\User\Downloads\assets` (owned zips) → authored multi-part temporary.

See also: `docs/release/ASSET_LICENSE_REGISTRY.md`.

## Closed / staged with prefab (composition ready)

| Gap | Prefab | Source used | Temporary authored | Future replacement |
|---|---|---|---|---|
| Flower shop facade/display | `FlowerShop.tscn` | Downtown Small building/door/window/planter; Sushi sakura+plant; House plant | Awning + window glow CSG | Dedicated florist stall module if acquired |
| Jewelry storefront | `JewelryShop.tscn` | Downtown + House Shelf + Food bottle + Sushi sign | Awning + gold identity band | Jewelry counter kit |
| Gift storefront | `GiftShop.tscn` | Downtown + House Shelf + Food cupcake + Sushi sign | Awning + pink band | Gift kiosk kit |
| Clothing storefront | `ClothingShop.tscn` | Downtown + House Bookshelf + Houseplant | Awning + blue band | Clothing rack / mannequin set |
| Homeware storefront | `HomewareShop.tscn` | Downtown + House Shelf + Food apple | Awning + green band | Kitchenware display kit |
| Park restaurant facade | `ParkRestaurant.tscn` | Downtown Medium building + Sushi counter/table/stool/sign/plant | Awning CSG | Matching exterior canopy pack |
| Main / park benches | `MainBench.tscn`, `ParkBench.tscn` | Sushi `Environment_Bench` + Downtown planters/bollard | — | Optional dedicated park bench if style mismatch |
| Internet cafe / coffee | `InternetCafe.tscn` | Downtown + Sci-Fi desk/chair + Kenney screen-panel + Food bottle | Awning CSG | Cafe furniture set |
| Bar | `BarFacade.tscn` | Downtown + Sushi counter/stools + Food bottles | Neon band CSG | Bar back / taps set |
| Cinema facade/cue | `CinemaFacade.tscn` | Downtown Medium + Kenney screen-wide + House chairs | Marquee CSG | Modular marquee + poster cases |
| Barber vignette | `BarberShop.tscn` | Downtown + House chair/mirror/shelf | Barber pole CSG | Barber chair + tools |
| Agency vignette | `AgencyOffice.tscn` | Downtown Medium + Sci-Fi desk/shelf/chair + Kenney screen-wide | Board sign CSG | Agency lobby kit |

## Temporary authored (no pack mesh found)

### Duck models / reaction
- Prefab: `DuckFeeding.tscn`
- Packs checked: imported Downtown/House/Food/Sushi/Factory/Sci-Fi; zip inventory of Downtown Standard, Sci-Fi Essentials Standard, House, Food, Factory, Modular SciFi — **no duck/bird animal mesh**.
- Temporary: multi-part low-poly ducks (body/head/beak/wings) + pond rim/water + feeder; anchors `FoodAnchor`, `DuckReactionArea`.
- Future: compact duck ≈0.35–0.5 m + pond prop; reaction animation.
- Priority: High.
- Status: TEMP COMPOSED — replace before visual ship.

### Karaoke microphone / stand
- Prefab: `KaraokeStand.tscn`
- Packs checked: House/Sci-Fi/Factory meshes + zip names — **no microphone**.
- Temporary: stage deck + mic pole/head + speakers CSG; Kenney `screen-small` + House `Light_Stand1`.
- Future: wired mic + adjustable stand at hand height.
- Priority: High.
- Status: TEMP COMPOSED.

### Arcade cabinets
- Prefab: `ArcadeFacade.tscn`
- Packs checked: Sci-Fi Essentials Standard (no terminals); Modular SciFi deferred; Kenney screens selected.
- Temporary: two cabinet housings (body/control deck/joystick/buttons) around Kenney screens.
- Future: stylized cabinet 1.6–1.9 m.
- Priority: Medium.
- Status: TEMP COMPOSED.

### Bus stop / candy machine
- Prefab: `BusStopCandy.tscn`
- Packs checked: Downtown Standard props limited to planter/bollard/AC/drain/manhole — **no bus shelter / vending**.
- Temporary: shelter roof/poles/glass + candy machine CSG; Sushi bench; House trash; Food chocolate.
- Future: urban bus shelter + vending machine.
- Priority: Medium.
- Status: TEMP COMPOSED.

### Gym equipment
- Prefab: `GymFacade.tscn`
- Packs checked: House/Factory/Sci-Fi — no dedicated gym kit; Kenney `machine.glb` reused as cardio silhouette.
- Temporary: rack uprights + barbell/plates + mat CSG.
- Future: bench/rack/cardio props at human scale.
- Priority: Medium.
- Status: TEMP COMPOSED.

### Photo studio camera/softbox
- Prefab: `PhotoStudio.tscn`
- Packs checked: House lights + Sci-Fi + Kenney screens — no camera/softbox.
- Temporary: backdrop + tripod legs + camera body/lens CSG; House light stand/desk lamp + Kenney panel.
- Future: camera, tripod, softbox, backdrop set.
- Priority: Medium.
- Status: TEMP COMPOSED.

## Still pending (not city facade scope this pass)

### Gift icons
- Use: shop/date gift UI.
- Packs checked: project placeholders; `kenney_game-icons.zip` in Downloads (not imported).
- Temporary: none allowed in RC for UI.
- Future: consistent square icons; import selected Kenney icons with permission to ship UI pack subset.
- Priority: High.
- Status: source available, import pending (needs explicit UI import decision).

## Replacement rules

- Every entry closed by exact imported source **or** retained here with documented authored temporary composition.
- Temporary geometry must be multi-part, styled, scaled, and attached under the prefab interaction root.
- A default stretched Box plus label is never acceptable.
- Final evidence still requires a normal-route screenshot after prefabs are wired into the city scene (future block).
- Do not download new packs without user permission.
