# Remaining problems after correction pass

Honest list — not production-quality.

## Gameplay / systems
- Trait-confirmed UI is very brief at end of phase 3; hard to hold for a clean still without extending date UI lifetime.
- Capture HUD can show stale/default labels under `-s` SceneTree script runs; live GodotIQ play previously showed real resource strings — treat capture HUD text as lower confidence than seating/quest evidence.

## Sitting / animation
- Legs/feet may still show residual retarget quirks on some chairs; Casual/Formal not re-proven in isolation this pass beyond restaurant GirlSeat path.
- Full sit sequence (approach → turn → sit_enter → sit_idle → seated_gesture → sit_exit) works for date path; sit_exit polish not deeply re-audited frame-by-frame.

## Apartment
- Overexposed / pink walls still present.
- Large empty center floor.
- Furniture still largely perimeter.
- Four zones (sleep / work / kitchen / storage+exit) not fully recomposed.
- Heavy ceiling / open void still visible.

## Street
- Map end / empty termination still visible from some angles.
- Overbright lamps.
- Repeating / blocky facades.
- Capsule NPC placeholders with Label3D names.
- Restaurant destination improved by spawn + framing, not by new landmark art.

## Restaurant
- Warm red-pink wash reduced but not eliminated.
- Floor / zoning composition still limited vs Visual Bible ideal.
- Date table still relies partly on local lights rather than full material recovery.

## UI
- Motion Effects settings not re-captured in the 19-shot set.
- 1280×720 layout OK for date answers; apartment HUD density still busy.
- No Godot default theme on date UI; custom theme retained.

## Runtime / tooling
- GLES Compatibility RID/texture leak spam on Godot CLI process exit (renderer shutdown), not gameplay SCRIPT ERROR.
- Capture tool is evidence automation on real main scene — not a substitute demo level, but not a human mouse run either.

## Explicitly out of scope / not done
- New retargeter / full library re-retarget.
- Factory / lab / late-game expansion.
- New large presentation systems.
- Full apartment/street art rebuild.
