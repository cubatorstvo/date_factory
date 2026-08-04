# DATE FACTORY — Vertical Slice Visual Pass

## Result

The Stage 1 route now presents a complete authored slice:

1. Begin in the apartment and prepare a date.
2. Leave through a fade transition.
3. Cross the compact evening street toward the pink Two Hearts landmark.
4. Enter the restaurant through a second transition.
5. Watch the girl walk in, turn, sit, and enter `sit_idle`.
6. Play the existing observation/answer loop with animated UI, reactions, and camera changes.
7. Receive the result sting, watch `sit_exit`, and return to player control.

The work preserves the existing economy, quest, dating, inventory, and progression APIs. The presentation layer was extended around them instead of replacing them.

## Art Direction

Theme: **stylized low-poly romantic corporate absurdism**.

- Warm domestic coral and dusty rose in the apartment.
- Navy, violet, brick, and neon pink on the street.
- Plum, burgundy, gold, sakura pink, and warm local pools in Two Hearts.
- Gold is reserved for goals, confirmations, destination cues, and premium accents.
- Pink communicates romance and reaction; cyan remains a secondary systemic accent.

See `VISUAL_BIBLE.md` for the reusable rules and exact palettes.

## World Changes

### Apartment

`res://scenes/world/vertical_slice/apartment.tscn`

- Replaced the visible blockout with an authored PACK_018/PACK_017 interior.
- Added bedroom, kitchen, date-preparation table, wardrobe, plants, table dressing, window treatment, and practical lighting. Gift shelf art may remain but is out of gameplay (shops/inventory); see [DATING_AND_WORLD.md](DATING_AND_WORLD.md).
- Removed floating world labels and duplicate procedural interaction props while retaining collision and HUD interaction prompts.

### Street

`res://scenes/world/vertical_slice/street.tscn`

- Built a compact walkable night route with Downtown MegaKit facades.
- Added sidewalks, road, crossing, benches, greenery, lamp rhythm, hidden boundaries, and the Two Hearts destination glow.
- Authored a readable player-spawn-to-restaurant sightline.

### Restaurant

`res://scenes/world/vertical_slice/restaurant.tscn`

- Built entrance, counter, supporting tables, service props, decor, sakura landmark, and a hero date table.
- Added local key/rim pools and presentation markers for arrival, two-shot, close-up, and result framing.
- Added an authored arrival path from the door to the chair.

## Presentation Components

- `DatePresentationController`: smooth arrival, wide, two-shot, close-up, and result camera presets.
- `TransitionOverlay` integration: input-locked fades around apartment/street/restaurant changes.
- Custom `Theme`: Outfit/DM Sans typography, plum/pink/gold controls, rounded panels, authored focus/hover/pressed/disabled states, and compact checkbox icons.
- `DateUI`: bounded 720p composition, staggered answer reveals, button press response, reaction pulse, heart/spark feedback, and compact tutorial copy.
- `HUD`: hierarchy panels, concise resource strip, readable objective block, animated prompt/toast surfaces.
- Player presentation: acceleration, restrained head bob, landing response, sprint FOV response, shake scaling, and a global Motion Effects switch.

## Character Animation

- Added humanoid BoneMap resources for UAL and PACK_019 women.
- Built and bound a dedicated seated animation library.
- Verified aliases: `approach`, `sit_enter`, `sit_idle`, `seated_gesture`, and `sit_exit`.
- `Girl_Casual` is used in the Stage 1 restaurant; `Girl_Formal` was also retargeted and verified.
- The animation controller now samples deterministic poses and returns non-looping aliases to the correct standing/seated state.

## Audio

Authored audio replaces the procedural-only presentation where a selected asset exists.

- UI hover/click/confirm/back/error/open/close/toggle/tick.
- Apartment, street, and restaurant footstep variants.
- Door, soft impact, event chime, success sting, and failure sting.
- Smooth music crossfades:
  - apartment: `apartment_chill.ogg`
  - street: `street_night.ogg`
  - restaurant: `restaurant_warm.ogg`

Licenses are included under `res://assets/audio/licenses/`.

- Kenney Interface/Impact/Sci-Fi/Music Jingles: CC0.
- Abstraction Music Loop Bundle: CC0.

Only selected files were copied into the project. The original `C:\Users\User\Downloads\assets` archives were not modified.

## Validation

- Project compile: **68 scripts, 0 parser/compile errors**.
- Main scene startup: **PASS**.
- Runtime console after gameplay/UI/audio regression: **0 runtime errors, 0 script errors**.
- Missing signal definitions: **0**.
- Player movement regression: moved **3.42 m** under real input.
- Audio state checks:
  - apartment music + apartment steps: correct.
  - street music + randomized street steps: correct.
  - restaurant music + randomized restaurant steps: correct.
- Screenshot tool: **9/9 PNG files saved successfully**.
- Runtime screenshots checked at apartment, street, restaurant/date, HUD, main menu, and settings.

## Known Limitations

- This is a focused Stage 1 vertical slice; later factory/lab/orbit stages retain more of their prior presentation.
- The standalone Character Testbed has no chairs, so seated clips float at seat height there; the restaurant aligns them to the authored chair.
- The restaurant currently uses `Girl_Casual`; content-driven outfit selection can be added later.
- Reaction VFX are deliberately lightweight UI glyph effects rather than a full particle library.
- The command-line capture process under Godot 4.4.1 GL Compatibility reports GPU resource-leak diagnostics while shutting down after all PNGs are saved. It exits successfully; normal game runtime and editor validation remain clean.
- Existing project-wide convention warnings and unused extensibility signals were not rewritten because they predate and are outside this visual-pass scope.
