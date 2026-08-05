# QA-FULL-ACCESS-SAVE-001 — Independent QA

**Task ID:** QA-FULL-ACCESS-SAVE-001-QA  
**Date:** 2026-08-05  
**QA agent:** df-qa-worker (independent; did not trust implementation report)  
**Scope written:** this file only  
**Overall status:** **PASS**  
**Recommendation to Orchestrator:** **READY**

---

## Summary

Boot «Продолжить» works with no normal `user://save_slot_1.json`: it regenerates dedicated `user://save_slot_qa_full_access.json` (`qa_profile=full_access`, `qa_schema_version=1`), loads stage_6 full unlocks into normal `res://scenes/boot/main.tscn` apartment FPS, and leaves the normal save hash untouched. City ParkGate/AgencyGate are open (hidden barriers), representative shops/leisure/agency UIs open, lab + `apt_*` destinations load, clone creation entry is usable (`can_create=true`, POIs present). «Новая игра» remains stage_1 with starting resources/locks. Runtime test renames were restored.

---

## Normal route / runtime session

| Step | Result |
|---|---|
| `godotiq_project_summary(brief)` | DATE FACTORY, Godot 4, autoloads: GodotIQRuntime, EventBus, SettingsService, Game |
| `godotiq_check_errors(project)` | **0 errors / 96 scripts** (before and after runs) |
| Baseline normal save | `DATE FACTORY/save_slot_1.json` **sha256=`8065E3112FA7BDCDB539EF1EC773763C1B819740474257799A496E29DD040D36`** size=19007 (stage_6 player save; money≈16547) |
| Simulate no normal save | Renamed to `save_slot_1.json.qa_hidden` (+ backup copy); also hid existing QA save to force regenerate |
| `godotiq_run(play, scene=main)` | Boot `boot.tscn`, Continue **enabled** (`disabled=false`) despite no normal save |
| Actual UI click | `godotiq_input` tap **«Продолжить»** → `current_scene=res://scenes/boot/main.tscn`, `stage_6`, `tutorial_done=true` |
| Repeat Continue | Second/third Continue after restart: regenerates QA save; same profile markers/resources |
| Travel/POI smoke | City + open gates; homeware/bookstore/photo/barber/agency UIs; lab + clone POIs; apt_cozy/modern/creative |
| New Game | Boot tap **«Новая игра»** → `stage_1`, $40 / ★0 / attention 3, park/agency locked |
| Debug console | Only QA profile warning log (expected marker); **0 script errors** |
| Restore | `save_slot_1.json` restored; hash match baseline; test artifacts removed; game stopped |

Userdata dir: `C:\Users\User\AppData\Roaming\Godot\app_userdata\DATE FACTORY\`

---

## Exact unlock lists (Continue / QA profile)

### Meta
- `stage_id`: `stage_6`
- `tutorial_done`: `true`
- `qa_profile`: `full_access` (on disk JSON; not in `Game.to_dict()` runtime keys)
- `qa_schema_version`: `1`

### Economy
- `money`: **100000**
- `popularity`: **500**
- `attention`: **10** (max 10)
- `legend`: 80, `scandal`: 0
- HUD (Continue): `$100000 · ★ 500 · ВНИМАНИЕ 10/10 · СВИДАНИЯ 25`

### Facility rooms
`apartment`, `neighbor_apt`, `lab`, `office_nook`, `agency`, `mansion`, `factory`, `orbital`, `apt_cozy`, `apt_modern`, `apt_creative`

### Facility venues
`kitchen_table`, `cheap_cafe`, `park`, `photo_studio`, `cinema_room`, `restaurant`, `luxury_hall`, `lab_capsule`, `conveyor`, `orbital_hall`

### City districts
`main_street`, `park_leisure`, `agency_row`  
Facility flags: `district_park_leisure=true`, `district_agency_row=true`

### City apartments (also in facility rooms)
`apt_cozy`, `apt_modern`, `apt_creative`

### Clones / scientist
- `max_slots`: **3**
- `can_create()`: **true**
- `Game.girls.is_met(scientist)`: **true**
- `Game.girls.has_contact(scientist)`: **true**
- Lab POIs: `Machine_Капсула клона`, terminal Area3D with `create_clone`
- Acceptance smoke: `begin_acceptance()` created pending; cleared via `from_dict` (no lasting clone)

### Events / dating cleanliness (at load)
- Events: `history=[]`, no active event dict at inspect; cooldown stamp present
- Clones: `pending={}`, `deferred_hits=[]`, `clones=[]`
- Dating: no active date overlay; PhoneUI/EventUI not visible at apartment start
- **WARNING:** during later lab play a crisis banner appeared (`КРИЗИС: Журналист…`) — not present at initial Continue load; not a Continue blocker

---

## Criterion-by-criterion

### 1. Continue enabled without normal save
| Status | **PASS** |
|---|---|
| Evidence | After hiding `save_slot_1.json`, boot UI map: Continue `disabled=false`, text «Продолжить». Actual tap succeeded. |
| Reproduction | Rename/remove `user://save_slot_1.json` → play main/boot → observe Continue enabled → tap. |

### 2. Continue regenerates dedicated QA save and loads normal main FPS
| Status | **PASS** |
|---|---|
| Evidence | QA save was absent → after Continue created `save_slot_qa_full_access.json` with markers. Scene `res://scenes/boot/main.tscn`, location `home` / zone `apartment`, FPS HUD + crosshair. Log: `[QA] full_access profile ready → user://save_slot_qa_full_access.json`. Toast message configured as `QA: все локации и POI открыты` (host cleared by capture time). |
| Reproduction | Delete QA save + normal save → Continue → check file + scene. |

### 3. QA JSON markers
| Status | **PASS** |
|---|---|
| Evidence | Disk JSON: `qa_profile=full_access`, `qa_schema_version=1`, `stage_id=stage_6`. Path: `user://save_slot_qa_full_access.json`. |
| Reproduction | Open QA JSON after Continue. |

### 4. State matrix (stage_6 unlocks / resources / scientist / clones)
| Status | **PASS** |
|---|---|
| Evidence | Runtime `Game.to_dict()` + girls/clones probes match lists above. |
| Reproduction | Continue → `godotiq_exec` dump of economy/facility/city/clones/girls. |

### 5. Normal travel / POI smoke after Continue
| Status | **PASS** |
|---|---|
| Evidence | See routes table below. All listed `quests.can_do` actions **true**. Gates: `ParkGate.visible=false`, `AgencyGate.visible=false` with district unlocks true (open = barrier hidden). |
| Reproduction | Continue → `ComplexWorld.travel_to` + `InteractionRouter.route` for UIs. |

### 6. New Game remains stage_1 / Continue did not alter New Game
| Status | **PASS** |
|---|---|
| Evidence | Boot tap «Новая игра» → `stage_1`, `tutorial_done=false`, money **40**, pop **0**, attention **3**, districts only `main_street`, park/agency **false**, apts `[]`, scientist unmet, `can_create=false`, max_slots **0**. HUD: `$40 · ★ 0 · ВНИМАНИЕ 3/3 · СВИДАНИЯ 0`, goal tutorial about neighbor phone. |
| Reproduction | From boot click New Game (with or without QA save present). |

### 7. Normal save untouched
| Status | **PASS** |
|---|---|
| Evidence | Baseline sha256 `8065E311…040D36`. During Continue runs normal path absent. After restore: same hash/size/mtime content. Continue never recreated `save_slot_1.json` while hidden. |
| Reproduction | Hash before Continue (with file moved aside) → Continue → confirm still absent → restore → hash match. |

### 8. Repeat Continue deterministic/idempotent
| Status | **PASS** (content) / **WARNING** (byte hash) |
|---|---|
| Evidence | Multiple Continues always yield `qa_profile=full_access`, schema 1, stage_6, money 100000, same unlock lists. File sha256 changes between regenerations (volatile fields e.g. event cooldown timestamp). |
| Reproduction | Continue twice → compare JSON markers/resources vs sha256. |

### 9. Project errors / console
| Status | **PASS** |
|---|---|
| Evidence | `check_errors` project: 0. Console: expected QA `push_warning` marker; no script compile errors. |
| Reproduction | check_errors + read_debug_console after Continue. |

### 10. No testbed-only route; control return
| Status | **PASS** |
|---|---|
| Evidence | Entry via boot Continue into `main.tscn` ComplexWorld FPS. Transition Dim modulate α=0 after load (not stuck black). Phone/Event overlays not blocking at start. |
| Reproduction | Boot → Continue → screenshot apartment. |

---

## Routes actually tested

| Route | Method | Result |
|---|---|---|
| Boot Continue (no normal save) | UI tap | PASS → apartment FPS stage_6 |
| Apartment / home cluster | Default spawn after Continue | PASS |
| City | `travel_to(city)` | PASS |
| ParkGate / AgencyGate open | Node visible=false + districts unlocked + leisure labels visible | PASS |
| Shops / café / homeware | Interactables present; `open_homeware_shop` UI «Дом и посуда» $100000; flower/gift/clothing `can_do`; café actions present | PASS |
| Park picnic / restaurant / gym / bookstore / cinema / arcade | POIs present; bookstore UI open; sit_*/gym/arcade `can_do=true` (sit_* not started to avoid date side-effects; arcade UI not forced after prior exec timeout) | PASS |
| Photo / barber / agency board | UIs opened: «Фотостудия — образ», «Барбер Agency Row», «Расписание агентства» (slots 0/3) | PASS |
| Lab | `travel_to(lab)` zone=lab; screenshot Clone_Lab_Base | PASS |
| apt_cozy / apt_modern / apt_creative | `travel_to` each → zone matches | PASS |
| Clone creation entry | Lab `create_clone` POIs + `can_create` + begin_acceptance then cleared | PASS (non-destructive) |
| New Game | Boot UI tap | PASS stage_1 |
| Repeat Continue | Multiple sessions | PASS content idempotent |

---

## Screenshots (opened and described)

1. **Boot menu** — DATE FACTORY panel; buttons Новая игра / Продолжить / Настройки / Выход; Continue interactable without normal save.  
2. **Apartment FPS after Continue** — first-person kitchen/bed apartment; HUD `$100000 · ★ 500 · ВНИМАНИЕ 10/10 · СВИДАНИЯ 25`; stage_6 quest line «Собери 3 части мегамашины»; crosshair; no phone/event overlay.  
3. **City / open park leisure** — night street FPS; world label «Парк Leisure» / barista visible beyond former gate line; full-access HUD resources.  
4. **Lab exclusive** — FPS lab (`Clone_Lab_Base` / clone lab geometry); HUD still `$100000 · ★ 500 · … · СВИДАНИЯ 25`; clone-lab interact label visible.  
5. **New Game apartment** — same apartment FPS shell; HUD `$40 · ★ 0 · ВНИМАНИЕ 3/3 · СВИДАНИЯ 0`; tutorial goal about neighbor phone (not QA unlock toast).

---

## Save hash / path evidence

| File | Role | sha256 / notes |
|---|---|---|
| `user://save_slot_1.json` | Normal save | Baseline & final: `8065E3112FA7BDCDB539EF1EC773763C1B819740474257799A496E29DD040D36` (unchanged by Continue) |
| `user://save_slot_qa_full_access.json` | Dedicated QA | Regenerated on Continue; markers `qa_profile=full_access`, `qa_schema_version=1`; last live hash after tests `4FD51CC79CA01B6D1793C2EE447E6D5C47A94C6CFB20ED2A8558E139CC982103` |
| Test renames | `.qa_hidden` / `.qa_backup` / `.pre_qa_run` | Restored/removed after session |

---

## Logs

- Expected marker (warning severity): `[QA] full_access profile ready → user://save_slot_qa_full_access.json`
- Script errors: **0**
- Project parse errors: **0**
- No missing-resource errors observed on Continue / travel / POI UI opens

---

## Blocking issues

None.

---

## Non-blocking issues

1. **Toast not captured on screen** after Continue (ToastHost cleared quickly); identification relies on console warning + profile `TOAST_MSG`.  
2. **Byte-level QA save hash not stable** across regenerations (content/markers stable).  
3. **Crisis can appear during later play** after Continue (journalist crisis seen in lab) — initial load pending/deferred were clean.  
4. **GodotIQ long `await`/batched UI execs** can timeout during `TransitionOverlay` tweens; travel still completes when polled after wall-clock wait (tooling flake, not player-blocker).

---

## Overall status

**READY**

Critical Continue / unlock / New Game / normal-save isolation routes verified independently on the normal boot → main FPS path.
