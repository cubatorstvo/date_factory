# Focused Visual Polish Report

## Animation choice
Temporary vertical-slice choice: `DateGirl_UAL` (`res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn`) + UAL sit aliases on open dining chair `Furniture/GirlDiningChair`.
Reason: modular Casual/Formal had no usable native sit clips; Women UAL retarget was visually broken (stretched legs/feet).

## Fixed
- Sitting cycle uses UAL girl + sequenced approach/turn/sit_enter/sit_idle/gesture/sit_exit; result beat holds `sit_idle` before exit.
- Apartment: ceiling, warm-neutral walls, zone dividers, pink wash reduced; HUD no longer shows literal `resources`/`goal` placeholders.
- Street: capsule citizen spawn disabled; talk-girl meshes/labels hidden; procedural placeholder meshes hidden; world-ground green plane hidden; end/void blockers added; outdoor toast demystified.
- Restaurant: cream/wood/burgundy materials, ceiling added, loud DateAccent/painting muted, lights softened, service partition, less furniture pile at counter.
- UI: compact status panel, truncated goal line, cleared empty interaction hints; carried pink gift cube disabled for presentation.

## Remaining
- Street still reads as dark greybox corridor; restaurant landmark canopy/pillar still placeholder-looking; some void framing remains depending on camera.
- DateGirl_UAL is a base/underwear model (temporary swap), not production outfit.
- Sit is usable (no catastrophic stretch) but still stiff; hips/feet not production-perfect on all camera angles.
- Restaurant still has strong warm/red accents (rug, leftover armchairs) under dramatic lantern light.
- Table gift prop remains a simple box (now wood-toned).

## Scenes / scripts changed
- `scenes/world/vertical_slice/apartment.tscn`
- `scenes/world/vertical_slice/street.tscn`
- `scenes/world/vertical_slice/restaurant.tscn`
- `scenes/world/complex_world.gd`
- `scenes/dating/date_stage.gd`
- `scenes/ui/hud.gd`
- `scenes/player/player.gd`
- `modules/interaction/interaction_router.gd`
- `assets/characters/hero_base/prefabs/DateGirl_UAL.tscn` (new)
- `tools/capture_focused_polish.gd` (capture only)

## Six final frames
`docs/vertical_slice/focused_final/`:
apartment_final.png, street_final.png, restaurant_final.png, girl_sitting_full_body_side.png, date_ui_final.png, date_result_final.png
