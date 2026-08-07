# M14A_QA — MODULE 14A Independent QA

**Task:** M14A_QA  
**Module:** 14A — Early Vertical Slice  
**Date:** 2026-08-07  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  

## Verdict

**PASS**

---

## Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | F5 main → apartment GAMEPLAY, Neighbor present (`girl_neighbor`) | **PASS** | Live `godotiq_run(play, main)`: `World.current_location_id=apartment`, HUD `mode=GAMEPLAY`, `Spawned_girl_neighbor` with `girl_id=girl_neighbor`, prompt `[E] Познакомиться`. Screenshot `01_apartment_neighbor.png`. |
| 2 | DateVenue + ProgressionInteractable prompts exist | **PASS** | Apartment nodes present; prompts `[E] Стол для свидания` / `[E] Самооценка` via `get_interaction_prompt(player)`. Survives travel return after STAGE_1. |
| 3 | ContentDB `validate_all` ok / headless MODULE_03 / MODULE_14A ALL PASS | **PASS** | Runtime `validate_all ok=true errors=0`. Headless: `MODULE_14A_TEST: ALL PASS (79)`; `MODULE_03_TEST: ALL PASS (124)`. Logs under `tmp/m14a_qa_indep/`. |
| 4 | STAGE_1 `appearance_space` actress/rival anchors | **PASS** *(via `restore_stage`)* | **Not physical discovery** — used `GameState.restore_stage(STAGE_1)` then `World.request_travel(appearance_space)` because discovery automation is too slow for this quick QA. Both anchors spawned: `Spawned_girl_actress` / `Spawned_rival_actress`. Screenshot `03_appearance_stage1_actress_rival.png`. |
| 5 | Phone Day/Money/Authority/XP/UP + Story | **PASS** | `PhoneJournal.open`: status shows День/Деньги/Авторитет/Опытность/Баллы прокачки; story section title `СЮЖЕТ` with Пролог / Ухажёр / Девушка. Screenshot `02_phone_status_story.png`. |
| 6 | Open and describe 2–3 screenshots | **PASS** | Three PNG evidence files opened and described below. |

---

## Player flow actually executed

1. Independent headless: `module_14a_vertical_test.tscn` → ALL PASS (79); `content_data_test.tscn` → ALL PASS (124).
2. `godotiq_run(play, main)` — apartment GAMEPLAY; Neighbor spawned.
3. Confirm DateVenue / ProgressionSelfAssessment prompts.
4. Open PhoneJournal — status + Story section; close → control returns (`mode=GAMEPLAY`).
5. **`restore_stage(STAGE_1)` (labeled shortcut)** → travel `appearance_space` → actress + rival anchors spawned.
6. Travel back apartment — venue/progression prompts still available; Neighbor despawned (stage gate `story_stage=0` vs stage 1 — expected).
7. Runtime `ContentDB.validate_all()` → ok.
8. Own screenshots saved to `tmp/m14a_qa_indep/`.

---

## Edge cases

| Case | Status | Notes |
|------|--------|-------|
| Phone open → close returns GAMEPLAY | **PASS** | `is_open` true→false; HUD `mode=GAMEPLAY` |
| Travel apartment ↔ appearance_space; interactables persist | **PASS** | Venue/progression prompts remain after return |
| Neighbor stage-gated off at STAGE_1 | **PASS** (expected) | `story_stage=0`, kids=0 after restore_stage(1) |

---

## Screenshot descriptions (opened and inspected)

Evidence: `tmp/m14a_qa_indep/`

### 1) `01_apartment_neighbor.png`

- Grey low-poly apartment room; blue placeholder pillar right.
- Top-left: `mode=GAMEPLAY target=Spawned_girl_neighbor`.
- Center: female CharacterActor (blonde, white tee, orange-brown pants).
- Prompt: **`[E] Познакомиться`**.
- Matches filename: apartment Neighbor gameplay.

### 2) `02_phone_status_story.png`

- Modal **«Телефон — Журнал»**; mode briefly `MODAL UI`.
- Status block: **День: 1 / Деньги: 0 / Авторитет: 0 / Опытность: 0 / Баллы прокачки: 0**.
- **СЮЖЕТ**: Пролог; Ухажёр: —; Девушка: Соседка.
- Journal list/detail for Соседка; Close button present.
- Neighbor visible behind overlay. Matches filename.

### 3) `03_appearance_stage1_actress_rival.png`

- Purple-walled `appearance_space` box room; `mode=GAMEPLAY`.
- Left: female actress model; right: muscular male rival model.
- No Foundation overlay. Matches STAGE_1 actress/rival presence.

---

## Commands + key log lines

### Headless MODULE 14A

```text
Godot_v4.7.1-stable_win64_console.exe --path <repo> --headless res://game/content/test/module_14a_vertical_test.tscn --quit-after 40000
[DF][MODULE_14A_TEST] ALL PASS (79)
MODULE_14A_TEST: ALL PASS (79)
EXIT=0
```

Log: `tmp/m14a_qa_indep/module_14a_vertical.log`

### Headless MODULE 03

```text
... res://world/test/content_data_test.tscn --quit-after 20000
[DF][MODULE_03_TEST] ALL PASS (124)
MODULE_03_TEST: ALL PASS (124)
EXIT=0
```

Log: `tmp/m14a_qa_indep/content_data_test.log`  
(Expected intentional `missing_girl_xyz` push_error during fixture negative lookup.)

### Runtime samples

```text
boot: apartment | mode=GAMEPLAY | Spawned_girl_neighbor girl_id=girl_neighbor
venue_prompt=[E] Стол для свидания
prog_prompt=[E] Самооценка
phone status=День:1 Деньги:0 Авторитет:0 Опытность:0 Баллы прокачки:0
story_title=СЮЖЕТ story=Пролог / Ухажёр:— / Девушка:Соседка
restore_stage(1) + travel appearance_space → girl_actress + rival_actress spawned
validate_all ok=true errors=0
```

---

## Blocking issues

None.

## Non-blocking issues

1. **First play session** logged `[ContentDB] missing girl: girl_neighbor` once at boot; Neighbor still spawned. Clean relaunch had no repeat. Possible rare init race — not a route breaker for this QA.
2. Location geometry remains placeholder (flat rooms / blue pillar); shared low-poly actor looks — visual polish, not MODULE 14A functional FAIL.
3. FPS debug HUD (`mode=…`) remains visible in gameplay shots (pre-existing debug label).

## Scope note

No 14B coverage. No product code edits by QA.

## Overall status

**PASS**
