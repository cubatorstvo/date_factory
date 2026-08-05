# Compact city visual capture archive — 2026-08-06

Windowed Godot captures for Block 6 compact layout verification.

## Folders

- `topdown/` — annotated technical SVG + rendered top-down PNG
- `final_route/` — eye-height route shots from the **current** `city.tscn` after marker/POI clearance fixes
- `diagnostic_earlier/` — earlier temp captures used while debugging markers inside facades / blocked sightlines (not final layout truth)

## Final route shots

| File | Viewpoint |
|---|---|
| `01_home_to_commercial.png` | Home spawn → commercial L |
| `02_commercial_to_cafe.png` | StreetMid → Cafe |
| `03_commercial_to_central.png` | StreetMid → Central fountain |
| `04_central_to_park_gate.png` | Central → ParkGate |
| `05_park_gate_to_picnic.png` | ParkGate → Picnic |
| `06_picnic_to_restaurant.png` | Picnic → Park restaurant |
| `07_leisure_to_agency_gate.png` | Leisure forecourt → AgencyGate |
| `08_agency_gate_to_photo.png` | AgencyGate → Photo doorfront |
| `09_agency_lane_return.png` | Agency lane west → return toward leisure |

## Notes

- Captures are scene-only (not full ComplexWorld mount lighting).
- Manual FPS walkthrough through apartment → city is still required for visual PASS.
- Temporary capture helper used: `tools/_capture_city_archive_shots.gd` (may be removed after packaging).
