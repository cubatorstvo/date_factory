# Compact city layout — technical capture

Status: **annotated technical SVG ready** + **rendered top-down PNG ready**; **FPS / manual walkthrough still required**.

## Files
- Live scene: `scenes/world/city/city.tscn`
- Legacy corridor backup: `scenes/art/city/City_Street_Legacy_Corridor.tscn`
- Technical top-down SVG: `docs/release/research/city_compact_layout_topdown.svg`
- Rendered top-down PNG: `docs/release/research/city_compact_layout_topdown.png`
- Builder: `tools/build_compact_city.gd`

## Capture route (when windowed allowed)
1. Open `res://scenes/world/city/city.tscn` in editor (or mount via complex city).
2. Place temporary Orthogonal Camera3D at `Markers/OverviewCamera` (~(-2, 28, 2)), look down (−Y), size ~28.
3. Screenshot showing ZoneLabels, ParkGate, AgencyGate, POIs, spawn.
4. Optional FPS walk: HomeEntrance → cafe → central fountain → ParkGate → picnic/pond/restaurant → leisure → AgencyGate → photo/bus.

## Coordinate notes
- Art local; `CityVisual` mount offset (−30, 0, 0); city scale ×1.5 in `complex_world`.
- Hardcoded shop/cafe interacts still at fixed city_root positions; facades placed to match.
- Marker-driven park/leisure/agency interacts follow Markers/*.
- Amenity interacts from `city_builder` remain at legacy corridor offsets until binding block.
