# Current feature inventory

Inventory date: 2026-08-05. This records implemented scope, not release readiness.

## Entry and persistence

- Boot menu: New Game, Continue, Settings, Quit.
- Normal save service: `save_slot_1.json`.
- Separate full-access QA profile exists and must remain test-only.
- Quick save/load and pause save/load paths exist.

## Core loop

- Apartment FPS and stage_1 onboarding.
- Phone: contacts, relations, schedule, upgrades, staff, clones, stats and Twitch-related content.
- Manual and automatic dating.
- Home preparation with food/drink/table state.
- City venue sit/wait flow.
- Dialogue choices, gifts, grades and date results.
- Economy, attention, popularity, scandal and legend.
- Inventory: gifts, outfits and carried item state.

## Progression

- Six stages: apartment → office → agency → mansion → factory → orbital.
- Rooms: apartment, neighbor apartment, lab, office nook, agency, mansion, factory, orbital and three themed apartments.
- Districts: main street, park/leisure and agency row.
- Staff, upgrades, crises, events, clones and megamachine parts.
- Existing ending: Algorithm date → FinaleUI → postgame.

## Existing girls

`neighbor`, `fitness`, `goth`, `streamer`, `business`, `fashionista`, `chef`, `lawyer`, `scientist`, `star`, `alien`, `algorithm`.

### Unique meet routes (production)

Discoverability = stage via `GirlsAPI.try_unlock_by_progress` (no auto-contact, no auto-met).  
Contact = city `CityAPI.talk` when worthy (stage + popularity + min dates).  
Met = real date via `DatingAPI.start_manual` (internal `mark_met`).  
Algorithm = finale-only (`unlock_algorithm_if_ready` after hard gates).

| Girl | Unlock condition | Where the player meets her | Code path |
|---|---|---|---|
| `neighbor` | Always (stage_1) | Phone contact from New Game → home date | `GirlsAPI.reset` + `DatingAPI.start_manual` |
| `fitness` | stage_2 + pop≥8 + ≥1 date | City gym front → talk → phone date | `try_unlock_by_progress` → roster `gym_front` → `CityAPI.talk` → date |
| `goth` | stage_2 + pop≥12 + ≥1 date | City night bar → talk → date | same; home_spot `night_bar` |
| `streamer` | stage_2 + pop≥15 + ≥2 dates | City internet cafe → talk → date | home_spot `internet_cafe` |
| `business` | stage_3 + pop≥22 + ≥3 dates | City bus stop (agency row) → talk → date | home_spot `bus_stop` |
| `fashionista` | stage_3 + pop≥28 + ≥3 dates | City street plaza → talk → date | home_spot `street_plaza` |
| `chef` | stage_3 + pop≥35 + ≥3 dates | City corner shop → talk → date | home_spot `corner_shop` |
| `scientist` | stage_3 + pop≥40 + ≥3 dates | City internet cafe → talk → date (unlocks clones after met) | home_spot `internet_cafe` |
| `lawyer` | stage_4 + pop≥50 + ≥4 dates | City bus stop → talk → date | home_spot `bus_stop` |
| `star` | stage_5 + pop≥100 + ≥5 dates | City night bar → talk → date | home_spot `night_bar` |
| `alien` | stage_5 + pop≥140 + ≥5 dates | City park → talk → date | home_spot `park` |
| `algorithm` | Finale gates only (all other uniques met, dates/pop/legend, megamachine) | Orbital finale date — never city spawn | `GirlsAPI.unlock_algorithm_if_ready` → date |

## Dating places

`home`, `cafe`, `park`, `restaurant`, `cinema`, `arcade`, `apt_cozy`, `apt_modern`, `apt_creative`.

## Shops

- Flower shop
- Jewelry shop
- Gift shop
- Clothing shop
- Homeware shop
- Bookstore

## City POI and activities

- Home entrance
- Cafe Two Hearts
- Picnic/park date
- Park restaurant
- Gym and gym pass
- Cinema
- Arcade and arcade date
- Photo studio
- Barber
- Agency board
- Street/park benches
- Flower/candy purchases
- Internet cafe work/scroll
- Coffee
- Duck feeding
- Night bar
- Street karaoke
- Bus schedule/candy machine
- City girls/talk interactions

Several activities are implemented only as hidden generated interactions and require visible props.

## Separate art-backed scenes

- Apartment
- Live city
- Restaurant/date backdrop
- Clone lab
- Player and girl actors
- Main/date/UI shell scenes

Most shops and leisure POI are intentionally facade + overlay activities rather than walkable interiors.

## UI surfaces

- Main menu, pause and settings
- HUD, clock, goals and notifications
- Phone and scheduling
- Shop overlays
- Date dialogue/result/gift selection
- Events and reveal popup
- District, elevator, gym, arcade, photo, barber, agency and clone overlays
- Finale/credits

## Content counts from smoke

- Gifts: 27
- Upgrades: 91
- Events: 31
- Rooms: 11

## Existing regression assets

- `tools/smoke_test.gd`
- `tools/playtest_m17.gd`
- GodotIQ project parse/validation

The current smoke forces finale prerequisites and therefore does not prove the normal player route.
