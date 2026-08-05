# Release scene inventory

## Main-route scenes

| Scene/location | Purpose | Entry/exit | Current readiness |
|---|---|---|---|
| `boot.tscn` | Main menu | OS launch → main | Functional; Continue is release Blocker |
| `main.tscn` | Game/UI shell | Boot; menu return | Functional baseline |
| `complex.tscn` | Exclusive world root | Hosts home or city | Functional; lighting authority needs pass |
| `apartment.tscn` | Starting home | New Game; exit to city | Art-backed benchmark; verify interactions/save |
| `city/city.tscn` | All outdoor city routes | Apartment exit; return home | Compact neighborhood (Block 6); prefab POIs; binding polish pending |
| `restaurant.tscn` | Restaurant date backdrop | Date stage | Asset-backed; route and character placement need visual QA |
| `Clone_Lab_Base.tscn` | Clone lab | Basement/elevator | Asset-backed; environment stripped on mount |
| Procedural `apt_*` | Themed apartment dates | Elevator/booking | Visible greybox; not release-ready |
| Procedural facility rooms | Stage expansion/finale | Apartment facility tree | Office/agency/mansion/factory/orbital greyboxes |

## Existing presentation scenes

- `date_stage` uses restaurant scene and procedural park/cinema/arcade backdrops.
- Shops, gym, cinema, arcade, photo, barber and agency are facade + overlay activities, not separate interiors.
- Player and girl actor scenes are shared across world/date presentation.

## City district inventory

### Main street
- Player home facade/door.
- Cafe Two Hearts.
- Flower, jewelry, gift, clothing and homeware shop interactions.
- City girls and main-street amenities.

### Park/leisure
- Gate, picnic, park rest and duck activity.
- Park restaurant.
- Gym, gym pass, bookstore, cinema and arcade.

### Agency row
- Gate.
- Photo studio, barber and agency office.
- Nearby bar/karaoke and bus-related amenities.

## Scene-level gaps

- Current city topology has no route loop.
- Generated street amenity visuals are hidden while interactions remain.
- Park restaurant shell has zero size.
- Leisure/agency facades are CSG/label-heavy.
- City POI outline targets are proxy boxes instead of facade-owned visual roots.
- No city NavigationRegion; current NPC movement is waypoint-based.
- Environment ownership strips city/lab authored environment and key lights.
- Expansion rooms are built as empty procedural volumes.

## Legacy/test scenes

- `scenes/world/vertical_slice/street.tscn`: legacy mirror; not live city.
- `scenes/art/city/*`: kit slices/indexes, not normal route.
- `scenes/art/kits/*`: asset indexes.
- `scenes/art/testbeds/*`: debug/testbeds including proxy POC.
- Capture/diagnostic tools: development-only and must be excluded from release.

## Required acceptance per live scene

- Reachable through the normal route.
- Clear entry and exit.
- Control returns after interaction.
- Repeat entry/use works.
- Save/load preserves required state.
- No script/runtime/missing-resource errors.
- No void, floating geometry, visible default blockout or debug UI.
- Correct player/girl placement and camera where applicable.
- Rendered screenshot inspected; filename alone is not evidence.
