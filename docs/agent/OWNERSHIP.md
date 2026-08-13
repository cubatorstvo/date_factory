# File ownership — Visual Art Pass 01

**Status:** complete (READY)  
**Spec:** `VISUAL_ART_PASS_01_CHARACTERS_CITY_RU.md`  
**Main:** `7ee5fde` · **Review:** `visual-review/art-pass-01-20260809` @ `04cac77`

| Task id | Agent | Status |
|---|---|---|
| AP1-CHARS (+ FIX2/FIX3) | df-gameplay-worker | complete |
| AP1-CITY-POI | df-scene-worker | complete |
| AP1-NPC | df-gameplay-worker | complete |
| AP1-QA / REVIEW | df-qa-worker | complete |
| AP1-DOCS | Orchestrator | complete |

Donor READ-ONLY. No Lab/Late art in this pass.

---

# File ownership — Player Experience Pass 01

**Status:** implementation complete; user playtest pending
**Spec:** `PLAYER_EXPERIENCE_PASS_01_BLACK_BOX_ONBOARDING_COLLISION_RU.md`
**Baseline:** `86cb0f9` after preserving prior WIP in `stash@{0}` / `stash@{1}`

| Task id | Agent | Status | Writable paths | Read-only dependencies | Forbidden paths |
|---|---|---|---|---|---|
| PE01-ORCH | Orchestrator | in progress | `docs/agent/{DECISIONS,OWNERSHIP,ACCEPTANCE}.md` | QA reports and evidence | gameplay, scenes |
| PE01-BLIND-A-B | df-qa-worker | in progress | `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`, `tmp/px_pass_01/**` | real title → New Game window only | production code/scenes, normal user data, runtime APIs |
| PE01-ONBOARD | df-gameplay-worker | complete — HUD test 33 PASS; first-frame capture 7 PASS | `ui/hud/{game_hud.gd,game_hud.tscn}`, `ui/tutorial/tutorial_prompt.gd`, `characters/player/{player.gd,player.tscn}`, focused `ui/hud/test/**` | Story, Phone, player interaction API | save schema, Story rules, apartment scenes |
| PE01-APT | df-scene-worker | complete — 66/66 physics, 18/18 visual, 9/9 collision debug | `world/locations/apartment/apartment.tscn`, `world/locations/apartment/apartment.tscn`, focused `world/test/**` | player, interactables, donor source | donor project, city/cafe, layout redesign |
| PE01-REGRESSION | Orchestrator | complete — focused 33 + 7 + 15 + 66 + 18 PASS; RC 34/35 known baseline debt | focused test execution under `tmp/qa/**` | production behavior | scene files, save schema |
| PE01-BLIND-C-D | df-qa-worker | complete — C/D PASS and final D PASS | `docs/qa/PLAYER_EXPERIENCE_PASS_01.md`, `tmp/px_pass_01/**` | fixed real game window | production code/scenes, normal user data |
| PE01-FINAL-QA | df-qa-worker | complete — READY | `docs/agent/qa/PLAYER_EXPERIENCE_PASS_01_QA.md`, `tmp/px_pass_01/**` | player journal, screenshots, logs | gameplay, scenes, save schema |

One writer owns both apartment scenes sequentially. Donor remains read-only. No character, Lab, Late, city, or cafe art work belongs to this pass.

---

# File ownership — Adaptive Scene UI

**Status:** in progress

| Task id | Agent | Status | Writable paths | Forbidden paths |
|---|---|---|---|---|
| UI-SCENES | Current GPT Sol agent | complete | `ui/**`, production UI controllers and entry points, `minigames/**`, focused UI tests/tools/docs, display stretch keys in `project.godot` | gameplay formulas, Story/balance/content, save schema, donor |

User instruction for this chat: no subagents. All implementation and verification are performed by the current agent; final acceptance includes the user's independent playtest.

---

# File ownership — Opening Evening Scene

**Status:** implementation complete; user playtest pending
**Spec:** `C:\Users\User\Downloads\DATE_FACTORY_OPENING_SCENE_RU.md`

| Task id | Agent | Status | Writable paths | Read-only dependencies | Forbidden paths |
|---|---|---|---|---|---|
| OPENING-01 | Current GPT Sol agent | complete — focused 20 PASS; live New Game → bed → old prologue verified | `game/opening/**`, `ui/frontend/title_menu.gd`, focused tests, this milestone's `docs/agent/**` sections | apartment scene, Player, CharacterActor, ContentDB Neighbor appearance, SaveSystem/World APIs | Story stages, GameState/save schema, Neighbor discovery/content, donor |

User instruction for this chat: no subagents. The existing old prologue remains unchanged and starts only after the opening bed interaction.

---

# File ownership — Phone date invite + HUD clock

**Status:** in progress
**Decisions:** D-INVITE-01..04 in `docs/agent/DECISIONS.md`

| Task id | Agent | Status | Writable paths | Read-only dependencies | Forbidden paths |
|---|---|---|---|---|---|
| INVITE-CORE | df-gameplay-worker | complete | `game/day/**`, `game/relationships/relationships.gd`, `game/dating/dating_types.gd`, `persistence/save_system.gd`, focused tests under `game/day/test/**`, `game/relationships/test/**`, `persistence/test/**` | PhoneJournal, GameHUD, DatingUI, DateVenueInteractable, World.request_travel, GameState money, ContentDB girls | `ui/**`, scenes `.tscn`, donor, GDD rewrite, new autoload, dating event catalogs |
| INVITE-UI | df-gameplay-worker | complete | `ui/phone/**`, `ui/hud/game_hud.gd`, `ui/hud/game_hud.tscn`, focused `ui/hud/test/**` `ui/phone/test/**` if present | Relationships invite API, GameDay hour API, DatingUI `open_for_active_date`, DateVenueInteractable dating-UI host pattern | `game/**` except read, `persistence/**`, donor, 3D locations, new HUD framework |

---

# File ownership — Date bonuses (venues, outfits, difficulty)

**Status:** implementation complete; user playtest pending  
**Spec:** `docs/gdd/10_date_venues_outfits.md`  
**Decisions:** D-DATE-BONUS-01..05 in `docs/agent/DECISIONS.md`

| Task id | Agent | Status | Writable paths | Read-only dependencies | Forbidden paths |
|---|---|---|---|---|---|
| BONUS-CORE | df-gameplay-worker | complete | `game/dating/**`, `game/relationships/**`, `game/state/game_state.gd`, `world/world.gd`, `world/locations/apartment/apartment_wardrobe_catalog.gd`, `data/definitions/girl_definition.gd`, `data/catalog/content_db.gd` (location count 9→15 + girl field validation only), `ui/phone/date_invite_panel.gd`, `ui/phone/date_invite_panel.tscn`, `ui/dating/**` (result breakdown only), focused tests under those trees plus `data/test/**` and `world/test/**` only where they assert location count or relationship ±5 | ContentDB locations/girls after BONUS-DATA, WorldLocation contract, PhoneJournal open-invite, SaveSystem schema 1 | donor, GDD rewrite (orchestrator-owned), city_hub art, cafe.tscn, apartment.tscn layout, new autoload |
| BONUS-SCENES | df-scene-worker | complete | `world/locations/restaurant/**`, `world/locations/park/**`, `world/locations/cinema/**`, `world/locations/arcade/**`, `world/locations/museum/**`, `world/locations/planetarium/**` | `world/world_location.gd`, `world/player_spawn_point.gd`, `world/world_transition.gd`, `game/dating/date_venue_interactable.gd`, cafe.tscn **as pattern only** (do not copy meshes) | `world/locations/cafe/**`, city_hub, apartment, donor writes, gameplay autoloads, girl tres |
| BONUS-DATA | df-content-worker | complete | `data/content/locations/{restaurant,park,cinema,arcade,museum,planetarium,cafe}.tres`, `data/catalog/content_catalog.tres` (append six location ExtResources only), `data/content/girls/*.tres` (only `leisure_format_ids` + `relationship_span`) | GirlDefinition new fields, scene paths below | gameplay scripts, scenes, donor, trait/event catalogs |

Scene paths (create if missing):

- `res://world/locations/restaurant/restaurant.tscn`
- `res://world/locations/park/park.tscn`
- `res://world/locations/cinema/cinema.tscn`
- `res://world/locations/arcade/arcade.tscn`
- `res://world/locations/museum/museum.tscn`
- `res://world/locations/planetarium/planetarium.tscn`

Donor remains read-only. No nested agents. Do not play the game or take screenshots.


