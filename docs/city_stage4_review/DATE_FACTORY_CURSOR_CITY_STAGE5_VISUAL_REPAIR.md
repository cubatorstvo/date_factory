# DATE FACTORY — City Stage 5: Visual Repair and Playability Pass

## Verdict on Stage 4

Stage 4 is technically integrated, but it is **not visually accepted**.

Keep the working systems:

- marker-driven interactions;
- district persistence and unlock logic;
- three physical district gates;
- synchronized `agency_row` gates;
- generated-content container;
- Stage 4 prefabs and validation infrastructure;
- existing action IDs and save keys.

Do **not** revert these systems.

The problem is the authored environment:

- the city reads as separate buildings placed on one flat navy plane;
- roads, sidewalks and district boundaries are not visually continuous;
- large empty areas expose the edge/void;
- the park is not readable as a park loop;
- the restaurant is not visible through ParkGate;
- leisure is an alley with two arcade machines rather than a forecourt;
- agency is a mostly empty plane with one distant building;
- facade gaps are too large;
- repeated rectangular planters obstruct the commercial route;
- Cafe Two Hearts is blocked by oversized street furniture;
- district gates cover nearly the whole screen and obscure the destination;
- the second agency-gate review camera is trapped between brick walls, indicating a blocked or invalid route.

This pass must repair the environment without redesigning gameplay systems.

---

# Block 0 — Backup and scope

1. Create:
   `res://scenes/art/city/backups/city_before_stage5_visual_repair.tscn`
2. Do not change:
   - action IDs;
   - public `CityAPI`;
   - district IDs;
   - save serialization keys;
   - unlock conditions;
   - marker-based interaction architecture.
3. You may adjust:
   - POI root transforms;
   - visual child transforms;
   - roads and sidewalks;
   - background buildings;
   - park geometry;
   - barriers' visual dimensions/material;
   - lamps, vegetation and furniture;
   - review-camera positions.
4. Preserve every functional POI from Stage 4.

---

# Block 1 — Replace the flat-plane look with continuous streets

The city must look like connected authored streets, not objects scattered on a single floor.

## Commercial / residential street

Create one continuous L-shaped street:

- road width: `6.5–7.5 m`;
- sidewalk width: `1.8–2.4 m` on each active side;
- curbs clearly separate sidewalk from road;
- shop facade line must be nearly continuous;
- facade gaps should normally be `0–0.6 m`;
- hide unavoidable gaps with:
  - narrow filler walls;
  - drainpipes;
  - service doors;
  - awnings;
  - planters placed against walls.

Do not put large rectangular planters inside the walking line.

The player route must remain at least `2.2 m` clear at all times.

Use road markings sparingly:

- one pedestrian crossing at the residential/commercial turn;
- one crossing or paving transition near the central pocket;
- no large empty asphalt field.

## Central pocket

Make a compact `9–11 m` urban widening, not a giant empty square.

It should contain:

- MainBench near an edge, not in the middle of movement;
- one central landmark:
  - small fountain, sculpture or large romantic planter;
- directional sightlines to:
  - ParkGate;
  - AgencyGate;
  - commercial street.

Maximum open dimension without furniture/building framing: approximately `11 m`.

---

# Block 2 — Repair the spawn and Cafe Two Hearts

Current failure:

- the table/chair group blocks the first-person view and walking line;
- the sign is oversized and visually pasted over the whole facade;
- the spawn is almost touching the cafe instead of establishing a street.

Required result:

1. Spawn the player `7–11 m` from the cafe door.
2. From spawn:
   - Cafe Two Hearts is visible as the immediate landmark;
   - the commercial turn is the secondary curiosity;
   - no furniture covers the cafe door or more than 20% of its facade.
3. Move the exterior table group:
   - to one side of the entrance;
   - at least `1.8 m` clear from the direct approach;
   - reduce scale if its chair back is near camera height.
4. Rebuild the cafe sign:
   - one main readable `TWO HEARTS` sign;
   - remove or cover the giant unrelated black sushi-letter boards;
   - sign width should be approximately 45–65% of storefront width;
   - keep pink/gold warm lighting.
5. Preserve the restaurant/cafe romantic warmth but avoid bloom clipping.

---

# Block 3 — Repair ParkGate and the park reveal

Current failure:

- ParkGate is a huge opaque blue rectangle dominating the entire screen;
- the player cannot clearly see a restaurant through it;
- behind the gate there are trees on a blank slab and exposed darkness.

## Gate visual

Change all DistrictGate visuals to:

- opacity at rest: `0.14–0.22`;
- stronger opacity only when the player touches/interacts;
- thin emissive perimeter or subtle grid;
- no large permanent world-space text in the middle;
- requirement text appears only when focused/interacted;
- gate height: approximately `2.6–3.0 m`;
- gate width: corridor width + `0.1–0.3 m`, not wider than the street canyon.

The destination behind the barrier must remain easy to read.

## Park structure

Create an actual park loop:

- a curved or segmented `3.0–4.0 m` path;
- pond is central but offset enough to permit two readable sides;
- water/pond edge must be visually distinct;
- path cannot appear as the same navy floor as the road;
- use grass, soil, gravel or landscaped paving around the pond;
- trees cluster at the perimeter and frame views;
- no tree should appear to sit in an isolated flowerpot on a blank city floor unless intentionally a planter tree.

## Restaurant reveal

From a normal standing view immediately before ParkGate:

- the warm restaurant facade/sign must be visible;
- it should occupy roughly `8–18%` of screen width;
- the path should visually lead toward it;
- use warm lamps/windows to make it the focal point;
- do not place a dark building wall directly in front of the sightline.

The current screenshot `08_through_park_gate_restaurant.png` is a failure because no restaurant is visible.

---

# Block 4 — Build a real leisure forecourt

Current failure:

- leisure reads as a narrow leftover alley;
- two arcade machines stand outside on an empty plane;
- blank building walls dominate the composition.

Required layout:

- compact shared forecourt approximately `14–18 m × 10–14 m`;
- cinema, arcade, bookstore/gym and bar/karaoke frame at least three sides;
- each entrance faces the forecourt;
- arcade machines move:
  - under an arcade awning;
  - inside a recessed facade opening;
  - or into a purposeful exterior arcade nook.
- add:
  - illuminated cinema marquee;
  - small bench/queue rail;
  - poster/lightbox props;
  - pavement variation;
  - warm/pink/cyan practical lights.

The forecourt must have two readable exits:

1. toward the park;
2. toward `AgencyGateLeisure`.

Do not allow a building wall to create a dead-end camera trap.

---

# Block 5 — Build a readable agency lane

Current failure:

- agency lane is a large empty flat field;
- one tall building and bus stop float in the distance;
- map boundaries are exposed.

Required result:

- service street width: `5.5–6.5 m`;
- sidewalks: approximately `1.5–2.0 m`;
- photo studio, agency office and barber form a dense U/L-shaped street edge;
- building frontage gaps: normally below `0.8 m`;
- bus stop terminates a framed view;
- behind the bus stop use:
  - facade mass;
  - wall;
  - turn;
  - or dark service gate;
  not an open void.
- add restrained business identity:
  - cleaner white/amber light;
  - schedule board;
  - office signs;
  - one cyan system accent;
  - less nightlife clutter than leisure.

The full unlocked route must visibly continue from agency toward leisure.  
The second agency gate cannot be placed between two intersecting building walls.

---

# Block 6 — Close all exposed map edges

From every reachable first-person point:

- no horizon should show an undressed navy plane ending in darkness;
- no standalone facade should be visibly floating;
- no road should run into open void.

Use:

- contiguous background facade rows;
- authored turns;
- construction walls;
- tall hedges/trees in park;
- service fences;
- alley closures;
- darkness only behind actual occluding geometry.

Background buildings must be close enough to form a believable block, while remaining non-interactive.

---

# Block 7 — Improve facade variety without changing POIs

The current city repeats similar brick buildings too evenly.

For each district:

## Main street
- medium brick buildings;
- warm awnings;
- varied storefront colors;
- romantic pink/gold destination accents.

## Park/leisure
- lower facade rhythm near park;
- brighter cinema/arcade signage;
- vegetation breaking brick repetition.

## Agency
- taller, cleaner facades;
- less pink;
- white/amber/cyan accents.

Allowed methods:

- vary the available building models;
- change facade scale only within visually safe limits;
- add cornices, awnings, signs and storefront inserts;
- use background massing to hide repeated geometry.

Do not replace the city with primitives or return to greybox blocks.

---

# Block 8 — Lighting repair

Preserve the intended old-street vibe:

- cool navy/violet ambient night;
- warm spherical street lamps;
- POI-specific pink/gold pools;
- readable dark facades;
- no total black storefronts;
- no giant flat purple wash.

Requirements:

- each destination has one dominant practical-light cluster;
- street lamps create rhythm rather than uniform brightness;
- reduce overexposure of lamp bulbs;
- ensure the park path and agency route are readable at player height;
- restaurant and cafe remain brightest warm landmarks.

Remember: mounted city uses the authoritative environment from `complex_world`; test final lighting through the normal game route, not only by opening `city.tscn` standalone.

---

# Block 9 — Gate usability and review cameras

Validate every gate in first person.

## ParkGate

Capture both:

- locked view showing visible restaurant beyond;
- unlocked view showing a clear path.

## AgencyGate

Capture both sides.

## AgencyGateLeisure

Current review image shows only intersecting brick walls. Fix either:

- the gate placement;
- adjacent building placement;
- or capture position,

but also manually confirm the route is physically traversable after unlock.

Review cameras must not be inside walls, props or collision.

---

# Block 10 — Playability validation

Run the normal game, not only headless validation.

Manually test:

1. spawn → cafe;
2. cafe → commercial shops;
3. commercial → central pocket;
4. locked ParkGate collision;
5. Stage 2 unlock → full park loop;
6. park → leisure forecourt;
7. locked agency gates from both sides;
8. Stage 3 unlock → both agency gates disappear;
9. leisure → agency → central complete loop;
10. all prompts appear at correct facades;
11. save/load preserves both district unlocks;
12. NPCs do not enter locked areas or cross pond/walls.

Document failures honestly.

---

# Block 11 — New acceptance package

Replace the review package with:

- `01_topdown_locked.png`;
- `02_topdown_all_open.png`;
- `03_spawn_view.png`;
- `04_spawn_to_cafe_wide.png`;
- `05_commercial_street_both_directions.png`;
- `06_central_pocket_to_both_gates.png`;
- `07_park_gate_locked_restaurant_visible.png`;
- `08_park_loop_pond.png`;
- `09_leisure_forecourt_wide.png`;
- `10_agency_gate_central_side.png`;
- `11_agency_gate_leisure_side.png`;
- `12_agency_lane_wide.png`;
- `13_full_loop_route_notes.md`;
- `BUILD_REPORT_STAGE5.md`;
- `VALIDATION_REPORT_STAGE5.md`.

Every first-person screenshot:

- real player camera height;
- normal gameplay FOV;
- no camera inside geometry;
- no debug-only hiding of problems.

---

# Hard acceptance criteria

Do not mark Stage 5 complete until all are true:

- cafe entrance is unobstructed;
- commercial area looks like one continuous street;
- no giant planters block the route;
- ParkGate does not obscure the entire destination;
- restaurant is visibly framed beyond ParkGate;
- park has a distinct path, pond edge and landscaped ground;
- leisure is a framed forecourt, not an alley;
- agency is a dense street, not an empty plane;
- `AgencyGateLeisure` is reachable and visually valid;
- no major map edge/void is visible from the route;
- full loop is manually traversed after unlock;
- technical Stage 4 validation still passes.
