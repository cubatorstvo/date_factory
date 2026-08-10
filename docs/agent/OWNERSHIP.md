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
