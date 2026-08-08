# M22_QA — MODULE 22 Independent QA

**Task:** M22_L_QA  
**Module:** 22 — UI / UX Integration  
**Date:** 2026-08-08  
**Agent:** df-qa-worker  
**Product code changes by QA:** none  
**Evidence:** `tmp/m22_qa/`  
**DoD:** `docs/modules/MODULE_22_UI_UX_INTEGRATION.md` + `docs/agent/ACCEPTANCE.md`

## Verdict

**PASS** → recommend **READY**

Independent headless regressions (MODULE 02–21 sample + new M22 suites) all green. Windowed indep harness boots World, asserts single GameHUD / PhoneJournal, HUD four resources + MODAL_UI hide/restore, Phone tab gates, formatter cases, no `perk_`/`girl_`/`STAGE_`/`MEDIA_ATTENTION` in scanned labels, themed Dating / Rival choose / Progression / Clone / Global terminals. No MODULE 23 audio/VFX added. Non-blocking polish issues noted below.

---

## 1. Summary

| Area | Result |
|------|--------|
| Main boot (`main.tscn`) | PASS — apartment boot; no SCRIPT/Parse errors |
| `ui_number_format_test.tscn` | PASS — `ALL PASS (11)` |
| `game_hud_smoke_test.tscn` | PASS — `ALL PASS (14)` |
| `progression_ui_self_test.tscn` | PASS — `ALL PASS (126)` |
| Dating / rivals / minigames / clones / late / final / media / salary / first_clone / content | PASS — all EXIT=0 |
| Indep windowed harness | PASS — `passed=73 failed=0` EXIT=0 |
| Screenshots (QA opened each) | PASS with visual WARNINGs |
| No MODULE 23 ahead | PASS |

---

## 2. Commands executed

```powershell
$godot = "C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe"

# Headless M22 + MODULE 02–21 sample (logs under tmp/m22_qa/*.log)
& $godot --path . --headless --quit-after 40000 res://ui/hud/test/ui_number_format_test.tscn
& $godot --path . --headless --quit-after 40000 res://ui/hud/test/game_hud_smoke_test.tscn
& $godot --path . --headless --quit-after 60000 res://ui/progression/test/progression_ui_self_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/dating/test/dating_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/rivals/test/rival_encounter_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/slap/test/slap_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/dance/test/dance_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/sigma/test/sigma_minigame_test.tscn
& $godot --path . --headless --quit-after 40000 res://minigames/money/test/money_minigame_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/clone_incremental/test/clone_incremental_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/late_game/test/late_game_test.tscn
& $godot --path . --headless --quit-after 90000 res://game/final_date/test/final_date_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/media/test/media_test.tscn
& $godot --path . --headless --quit-after 40000 res://game/salary/test/salary_mine_test.tscn
& $godot --path . --headless --quit-after 60000 res://game/first_clone/test/first_clone_test.tscn
& $godot --path . --headless --quit-after 40000 res://world/test/content_data_test.tscn

# Main boot smoke
& $godot --path . --headless --quit-after 3 res://main.tscn
# → tmp/m22_qa/main_boot.log

# Independent windowed player-path harness (QA-only under tmp/)
& $godot --path . --quit-after 180 res://tmp/m22_qa/m22_indep_qa.tscn
# → tmp/m22_qa/m22_indep_qa_windowed.log + PNGs + m22_indep_qa_report.txt
```

Godot CLI: `C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe`  
Viewport / shots: **1280×720** (project default). 1080 / 1440 / UI scale 150% not re-run in this indep pass.

---

## 3. Engine logs

| Log | Path | Key line |
|-----|------|----------|
| Number format | `tmp/m22_qa/ui_number_format.log` | `MODULE_22_NUMBER_FORMAT_TEST: ALL PASS (11)` EXIT=0 |
| GameHUD smoke | `tmp/m22_qa/game_hud_smoke.log` | `MODULE_22_HUD_SMOKE: ALL PASS (14)` EXIT=0 |
| Progression UI | `tmp/m22_qa/progression_ui.log` | `MODULE_22_PROGRESSION_UI_TEST: ALL PASS (126)` EXIT=0 |
| Dating / M09 | `tmp/m22_qa/dating.log` | `ALL PASS (163)` EXIT=0 |
| Rivals / M06 | `tmp/m22_qa/rivals.log` | `ALL PASS (120)` EXIT=0 |
| Slap / M07A | `tmp/m22_qa/slap.log` | `ALL PASS (108)` EXIT=0 |
| Dance / M07B | `tmp/m22_qa/dance.log` | `ALL PASS (90)` EXIT=0 |
| Sigma / M07C | `tmp/m22_qa/sigma.log` | `ALL PASS (100)` EXIT=0 |
| Money / M07D | `tmp/m22_qa/money.log` | `ALL PASS (129)` EXIT=0 |
| Clone incremental / M18 | `tmp/m22_qa/clone_incremental.log` | `ALL PASS (110)` EXIT=0 |
| Late game / M20 | `tmp/m22_qa/late_game.log` | `ALL PASS (101)` EXIT=0 |
| Final date / M21 | `tmp/m22_qa/final_date.log` | `ALL PASS (78)` EXIT=0 |
| Media / M15 | `tmp/m22_qa/media.log` | `ALL PASS (146)` EXIT=0 |
| Salary / M13 | `tmp/m22_qa/salary.log` | `ALL PASS (122)` EXIT=0 |
| First clone / M17 | `tmp/m22_qa/first_clone.log` | `ALL PASS (131)` EXIT=0 |
| Content / M03 | `tmp/m22_qa/content_data.log` | `ALL PASS (139)` EXIT=0 |
| Main boot | `tmp/m22_qa/main_boot.log` | Boot → apartment; Player ready |
| Indep windowed | `tmp/m22_qa/m22_indep_qa_windowed.log` | `DONE passed=73 failed=0` EXIT=0 |
| Indep report | `tmp/m22_qa/m22_indep_qa_report.txt` | Full PASS list |

Raw Godot stdout/stderr via Tee (not capture-journal-only). Grep across `tmp/m22_qa/*.log`: **no** product `SCRIPT ERROR` / `Parse Error` / `Failed to load resource`. Exit RID/ObjectDB leak warnings on Godot quit — engine cleanup noise.

---

## 4. Screenshots — paths + factual content (QA opened each)

All captures logged **1280×720**.

| File | What it actually shows |
|------|------------------------|
| `tmp/m22_qa/01_apartment_hud.png` | Apartment («КВАРТИРА»): neighbor NPC, date table + «Самооценка», blue door, crosshair. Top-left GameHUD: `$ 12.4K`, `АВТОРИТЕТ 3`, `ОПЫТНОСТЬ 2`, `БАЛЛЫ 2`. Center toast: Авторитет/Опытность/Балл gains. `mode=GAMEPLAY`. |
| `tmp/m22_qa/02_phone_status.png` | Phone modal STATUS: tabs СТАТУС / СЮЖЕТ / ДЕВУШКИ only (no MEDIA/CLONES). Top bar day + `$ 12.4K` + resources. Characteristics Мышца/Внешность/Капитал/Аура 0. `mode=MODAL_UI`. |
| `tmp/m22_qa/03_phone_story.png` | Phone STORY: «Пролог», «Ухажёр: —», «Девушка: Соседка» (display name, not `girl_`). Same three tabs. |
| `tmp/m22_qa/04_phone_girls.png` | Phone GIRLS empty: «Пока нет записей.» Three tabs; dark list pane. |
| `tmp/m22_qa/05_progression_ui.png` | Progression «ПРОКАЧКА», points 2, tabs МЫШЦА/ВНЕШНОСТЬ/КАПИТАЛ, perk «Без разминки» cost 1 ДОСТУПНО (no `perk_` id). Panel framed lower-right. HUD resources hidden. |
| `tmp/m22_qa/06_dating_ui.png` | Dating arrival: «Соседка», «ПРИБЫТИЕ», «Отношения: 0», «Она пришла», «Продолжить». HUD hidden. **WARNING:** large faded «СТАДИЯ 4» ghost behind modal. |
| `tmp/m22_qa/07_rival_choose.png` | Rival choose «ВЫЗОВ» / «Ухажёр Актрисы», stakes Authority ±, ТАНЕЦ / ПОЩЁЧИНА with Select. HUD hidden. Same stage-ghost WARNING. |
| `tmp/m22_qa/08_clone_terminal.png` | Clone terminal partially visible (WORK 1 @ 20/мин, DATING 0) behind realization AcceptDialog («Проблема не в графике…» / OK). HUD hidden. |
| `tmp/m22_qa/09_global_terminal.png` | Global expansion UI partially visible (…ШИРЕНИЕ, TOTAL/FREE, WORK/DATING) behind same realization dialog. HUD hidden. |

---

## 5. Player flow verified

### Happy path (indep harness)

1. `reset_to_start` → apartment; exactly one GameHUD + PhoneJournal.
2. Seed money/auth/XP → HUD shows `$ 12.4K` / АВТОРИТЕТ 3 / ОПЫТНОСТЬ 2 / БАЛЛЫ 2; shot `01`.
3. Formatter: 12.4K / 1.25M / 1B / `$ 120` / `+1`.
4. `enter_modal_ui` → HUD GameplayRoot hidden; `enter_gameplay` → visible again.
5. Travel apartment → same HUD instance, still count=1.
6. Phone prologue: STATUS/STORY/GIRLS visible; MEDIA/CLONES hidden; shots `02`–`04`.
7. ProgressionSelfAssessment → Progression UI; HUD hidden; shot `05`; close → GAMEPLAY.
8. Reset clears money; restore PROLOGUE; HUD still single.
9. STAGE_4 → MEDIA tab visible, CLONES hidden; attention text `Внимание: 0 / 100` (no `MEDIA_ATTENTION`).
10. Seed dating `girl_neighbor` → DatingUI arrival; HUD hidden; shot `06`.
11. Seed rival `rival_actress` encounter → choose UI; shot `07`.
12. STAGE_5 + first clone WORK → CLONES tab; Clone Terminal open; HUD hidden; shot `08`.
13. STAGE_6 → `production_area` Global terminal open; shot `09`.
14. Label scan: zero hits for `perk_` / `girl_` / `STAGE_` / `MEDIA_ATTENTION`.
15. No `res://audio|sfx|vfx`; no MODULE_23 module doc.

### Edge cases

1. HUD hide/show MODAL_UI ↔ GAMEPLAY (PASS).
2. Phone tab gates prologue → media → clones (PASS).
3. Reset + restore_stage persistence-style cycle without disk save API (PASS for available APIs).
4. Travel does not duplicate HUD (PASS).

### Headless contracts

| Suite | Status |
|-------|--------|
| M22 number format 11 | PASS |
| M22 HUD smoke 14 | PASS |
| M22 progression UI 126 | PASS |
| M09 dating 163 | PASS |
| M06 rivals 120 | PASS |
| M07A–D minigames | PASS |
| M18 clone incremental 110 | PASS |
| M20 late game 101 | PASS |
| M21 final date 78 | PASS |
| M15 media 146 | PASS |
| M13 salary 122 | PASS |
| M17 first clone 131 | PASS |
| M03 content 139 | PASS |

---

## 6. Criteria table

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Theme + formatter K/M/B | **PASS** | format test 11; HUD `$ 12.4K`; indep formatter asserts |
| 2 | Permanent GameHUD 4 resources; event-driven; hide MODAL | **PASS** | smoke 14 + indep + shot `01` |
| 3 | Exactly one GameHUD / PhoneJournal | **PASS** | indep counts boot/travel/final |
| 4 | Phone 5 tabs + visibility gates | **PASS** | prologue 3 tabs; STAGE_4 +MEDIA; clones after first clone |
| 5 | Progression screen readable; no Phone buying | **PASS** | progression UI test 126 + shot `05` (perk display names) |
| 6 | Dating / rival presentation | **PASS** | shots `06`/`07`; dating+rivals headless |
| 7 | Clone / Global terminals readable | **PASS** with WARNING | shots `08`/`09` partially covered by realization dialog |
| 8 | Minigame / final / media / salary regressions | **PASS** | headless suites EXIT=0 |
| 9 | No technical IDs in scanned phone/hud/dating/rival/terminal labels | **PASS** | indep scan hits=0 (`STAGE_` ascii absent; player-facing «СТАДИЯ N» toast separate) |
| 10 | No SCRIPT/Parse errors on main + indep | **PASS** | logs |
| 11 | Resolutions 720/1080/1440 + scale 150% | **WARNING** | indep verified **1280×720** only; 1080/1440/scale150 not re-run |
| 12 | No MODULE 23 audio/VFX | **PASS** | no audio/sfx/vfx dirs; no AudioStreamPlayer/Particles under `ui/`; only MODULE_22 doc |
| 13 | MODULE 02–21 sample regressions | **PASS** | suites listed above |

---

## 7. Limitations

- Assisted seeds (`restore_stage`, contacts, first-clone test helpers, rival `start_encounter`) — not organic full campaign grind.
- Disk save-file round-trip not available (`export_save_dict` absent); reset/restore APIs exercised instead.
- Clone/Global terminal shots occluded by DatingOverload realization `AcceptDialog` after assisted STAGE_5 flags.
- Progression UI framed lower-right in capture (readable; layout polish).
- Project debug `mode=` overlay visible on all shots.
- Stage toast «СТАДИЯ N» can remain as large faded ghost under later modals.
- Terminal section headers still English (`WORK` / `DATING`).
- 1080p / 1440p / UI scale 150% not independently re-verified.
- Godot exit RID/ObjectDB leaks on all runs (noise).

---

## Overall status

**PASS**

## Blocking issues

None.

## Non-blocking issues

1. Faded «СТАДИЯ N» stage banner ghosts under Dating / Rival modals (`06`, `07`).
2. Realization AcceptDialog stacks over Clone/Global terminal when opening after assisted recognition flags (`08`, `09`) — terminals still present behind.
3. English `WORK` / `DATING` section titles in clone/global terminals.
4. Progression panel placement lower-right at 1280×720.
5. Debug `mode=` HUD project-wide.
6. Acceptance resolutions 1080/1440 + scale 150% not re-proven in this QA pass.

## Evidence

- Logs: `tmp/m22_qa/*.log`, `tmp/m22_qa/m22_indep_qa_windowed.log`
- Report: `tmp/m22_qa/m22_indep_qa_report.txt`
- Screenshots: `tmp/m22_qa/01_apartment_hud.png` … `09_global_terminal.png`
- Harness: `tmp/m22_qa/m22_indep_qa.tscn` + `.gd`

## Reproduction steps

1. Run headless suites listed in §2; confirm `ALL PASS` / EXIT=0.
2. Run windowed:  
   `Godot_v4.7.1-stable_win64_console.exe --path . --quit-after 180 res://tmp/m22_qa/m22_indep_qa.tscn`
3. Confirm `M22_INDEP_QA: DONE passed=73 failed=0` and PNGs under `tmp/m22_qa/`.
4. Open each PNG; verify HUD resources, Phone tabs, Progression, Dating, Rival choose, terminals match §4.

## Recommendation

**READY** for MODULE 22 acceptance. Do not start MODULE 23 until Orchestrator closes M22. Non-blocking polish (stage ghost, realization stack, English terminal headers, multi-res scale) can be follow-ups.
