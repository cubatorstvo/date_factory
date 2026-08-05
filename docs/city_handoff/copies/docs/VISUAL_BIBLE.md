# DATE FACTORY — Visual Bible

## North Star

**Stylized low-poly romantic corporate absurdism.**

Every composition should combine:

- a readable everyday place;
- one romantic focal cue;
- one slightly over-organized or corporate detail;
- a clear gameplay route;
- warm character-scale lighting against a darker environment.

## Palette

### Global

- Ink: `#11121B`
- Deep plum: `#241823`
- Panel plum: `#2B1B2B`
- Romance plum: `#5B2B4A`
- Active pink: `#D16A8C`
- Heart pink: `#FF83AC`
- Warm text: `#F6E7DC`
- Goal gold: `#E7B562`
- Focus gold: `#F0C06D`
- System cyan: `#69C4D2`

### Apartment

- Floor brown: `#5F403B`
- Wall linen: `#D9C7BA`
- Kitchen berry: `#7A3D55`
- Romance accent: `#4A2039`
- Wood/coral: `#B7745B`
- Night background: `#201424`

### Street

- Ground navy: `#111821`
- Road violet-black: `#242733`
- Sidewalk gray-plum: `#58515F`
- Curb mauve: `#B59AA5`
- Crossing cream: `#EFC8BA`
- Ambient blue: `#394A6D`
- Destination pink: `#FF4F9A`

### Restaurant

- Floor cocoa: `#382628`
- Wall plum: `#3B2035`
- Date accent: `#8B2F5E`
- Counter coral: `#B87062`
- Brass gold: `#D5A34D`
- Ambient wine: `#664057`
- Deep background: `#170F1A`

## Materials

- Prefer broad color blocks and readable roughness over noisy realism.
- Floors: roughness `0.65–0.9`; keep highlights broad.
- Painted walls: roughness `0.7–0.85`.
- Brass/sign accents: metallic `0.35–0.7`, roughness `0.25–0.5`.
- Emission is a navigation and mood tool, not general decoration.
- One dominant accent material per gameplay destination.
- Avoid pure white, pure black, and uniform gray blockout materials.

## Lighting

### General

- Use a soft low-energy directional key plus local practical pools.
- Local lights should explain the route, face, table, or interaction.
- Preserve shadow shape; do not flatten rooms with high global energy.
- Use glow lightly on signs, bulbs, and goal accents.

### Apartment

- Warm ceiling fill, bedside pool, kitchen pool, and exit cue.
- Keep the window/background darker than the date-preparation area.
- The table and wardrobe should be readable from the player spawn.

### Street

- Cool ambient base with warm lamp rhythm.
- The restaurant is the brightest pink/gold landmark.
- Crossings and route edges must remain readable without floating labels.

### Restaurant

- Warm date-table key, gold rim, counter pool, and entrance pool.
- The girl’s face and the answer panel must remain the primary contrast pair.
- Background tables are visible but at least one value step below the hero table.

## Composition

- Spawn view must reveal one immediate objective and one secondary curiosity.
- Routes use light, repetition, color contrast, and architecture—not arrows in empty space.
- Keep hero props in triangular clusters rather than even grids.
- Do not center every shot; use thirds and foreground framing.
- Hide boundaries with facades, darkness, turns, planters, or authored walls.
- Remove duplicate procedural props when an authored art prop already communicates the interaction.

## Camera

- FPS FOV default: `80°`, adjustable `60–110°`.
- Head bob amplitude: restrained (`~0.045 m` maximum).
- Sprint FOV change: smooth and optional through Motion Effects.
- Camera shake: event-driven, scaled by setting, never continuous.

### Date Shot Language

- Arrival: door/path context.
- Wide: establish restaurant and table.
- Two-shot: relationship and body language.
- Girl close-up: reactions and observed traits.
- Hero close-up: optional answer consequence.
- Result: wider release before control returns.

Use sine/back easing and `0.45–0.9 s` transitions. Never hard-cut repeatedly during an answer.

## UI

- Fonts:
  - Display/buttons: Outfit SemiBold.
  - Body: DM Sans Regular/Medium.
- Body text: warm ivory, never default gray.
- Panels: translucent plum, 1 px warm border, `12–18 px` corner radius.
- Buttons:
  - normal: dark romance plum;
  - hover/focus: brighter plum + gold frame;
  - pressed: pink with dark text;
  - disabled: low-contrast muted plum.
- Keep touch/click targets near `44–49 px` where layout allows.
- HUD should communicate hierarchy in surfaces, not free-floating debug strings.
- DateUI must fit 1280×720 with all answers inside the viewport.
- Use entrance/exit motion of `0.16–0.34 s`; never animate anchored container positions in a way that changes offsets.

## VFX

- Positive romance: pink hearts, soft scale pulse, warm glint.
- Discovery/confirmation: gold spark, short chime.
- Negative reaction: restrained gold/amber spark; avoid red screen spam.
- Factory/system events: cyan/gold, sharper timing.
- Keep bursts under one second and clear the face and answer text.

## Audio

- UI hover is quieter than click; click is quieter than confirm.
- Moderate pitch variation only (`0.97–1.03`).
- Footsteps follow the current zone material.
- Door cue starts under the fade.
- Music crossfades rather than restarts abruptly.
- Result sting plays once before the girl’s exit.
- Licensed source files and licenses remain together under `assets/audio/`.

## Asset Pack Combinations

- Apartment: PACK_018 structure/furniture + PACK_017 small props.
- Street: PACK_001 Downtown MegaKit + project-authored road, lights, crossing, and sign accents.
- Restaurant: PACK_016 Sushi Restaurant + PACK_017 food/decor + selected PACK_018 utility props.
- Characters: PACK_019 women + UAL humanoid animation retargeting.
- UI/audio: custom Godot Theme using project fonts; selected Kenney/Abstraction audio.

## Prohibitions

- Default Godot theme as final presentation.
- Floating Label3D names as environmental signage.
- Empty cube rooms or unexplained prop grids.
- One global DirectionalLight as the complete lighting solution.
- Instant NPC appearance at the chair.
- Teleport without fade, sound, and input lock.
- Full-screen UI slabs without information hierarchy.
- Tiny text over busy 3D backgrounds without a surface.
- Uniform emission on every prop.
- Random asset placement without route, function, or story.
- Camera position tweens that corrupt Control anchors/offsets.
- New assets copied without their license file.
