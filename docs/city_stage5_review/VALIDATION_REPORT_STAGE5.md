# VALIDATION_REPORT — City Stage 5

## Technical

Command:

`Godot_v4.7.1-stable_win64.exe --headless --path . --script res://tools/validate_city_stage4.gd`

Result: `VALIDATE_CITY_STAGE4_PASS`

Notes from validator:

- agency gates share `district_id` and hide together
- no Interactable nodes inside `city.tscn`
- POI/marker/gate transforms match synced Stage 5 layout in Stage 4 manifest
- pond collision present at `GeneratedCity/Roads/Pond/PondCollision`

## Capture package

Command:

`Godot_v4.7.1-stable_win64.exe --path . -s res://tools/capture_city_stage5_review.gd`

Result: `CAPTURE_CITY_STAGE5_PASS count=12`

Camera rules used:

- eye height `1.65`
- FOV `75`
- minimized real GPU window (dummy `--headless` cannot capture)

## Not covered by automation

- Stage 2 / Stage 3 district unlock progression inside running game
- save/load persistence of both district unlocks
- NPC pathing after unlock changes
- prompt reachability with player collision capsule
- bloom/overexposure under final `complex_world` lighting stack

These require the manual checklist in `13_full_loop_route_notes.md`.
