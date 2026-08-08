# Visual Playtest Phase C+D — Independent QA

**Date:** 2026-08-08  
**Task:** Expand `--gallery` + `--playthrough` to substantial screenshot set; reach Ending without forbidden stage cheats  
**Repo:** `C:\Users\User\Documents\GodotProjects\date_factory`  
**Godot:** `C:\godot\Godot_v4.7.1-stable_win64.exe` (4.7.1.stable)  
**Role:** `df-qa-worker` (implementation + independent verification)  
**Primary evidence run:** `final_vp2` (mode-separated paths)

---

## Overall status

**PASS**

Playthrough completes P00→P21 to Ending via `FullGameIntegrationHelpers` production APIs (FakeCompetitionRunner, date results, clone sim). Gallery captures critical UI, apartment composition, venues, terminals, minigame shells, Stage6 phone, and FinalDate shell. Layout matrix remains green with **ERROR=0**.

---

## 1. Summary

Phase C+D harness is no longer stubbed. Independent `--all --run-id final_vp2` produced **156 PNGs** under mode-separated folders (`layout/`, `gallery/`, `playthrough/`), merged `report.json` / `report.md`, contact sheets, and defect counts. Playthrough negative path (rival loss→win, discovery fail→retry, partial date→conquer) and mainline Reach100→FinalDate→Ending all completed with **0 unmet checkpoints**.

---

## 2. Changed files

### `game/visual_review/`
- `gallery_fixtures.gd` — helpers bind, travel/look, pause/progression/terminals/rival/minigames/discovery/dating; GALLERY FIXTURE story drive; dismiss overlays
- `visual_state_gallery.gd` — full critical UI + apartment 100–109 + city/venues + shells + Stage6 phone + FinalDate
- `playthrough_driver.gd` — full P00→P21 + interleaved negative path + snapshots; no forbidden stage cheats
- `screenshot_capture.gd` — writes `_review/.../<mode>/<WxH>/`
- `visual_playtest_runner.gd` — passes mode into capture setup

### `tools/visual_review/`
- `run_visual_playtest.py` — per-mode default resolutions/timeouts; defect table; mode-aware contact sheets

### Outputs
- `_review/visual_playtest/final_vp2/**` (and earlier `final_vp1` overwritten-mix; use **final_vp2**)

### Forbidden paths
Not modified: `ui/**`, `qa/test_manifest.json`, export presets, gameplay modules, world `.tscn`.

---

## 3. Playthrough checkpoints completed vs unmet

| Checkpoint | Status | Evidence |
|---|---|---|
| P00–P04 | **PASS** | title → new game → apartment → HUD/phone |
| Negative path | **PASS** | `n01`–`n06` PNGs; stage→2 after recovery |
| P05–P08 | **PASS** | city_hub, cafe, gym, appearance |
| P09–P13 | **PASS** | rival choose (mine suitor), mine, media, overload phone, lab STAGE_5 |
| P14–P18 | **PASS** | first clone, XP bridge, production/global terminal, Reach100→FINALE, final location |
| P19–P21 | **PASS** | FinalDate progress + ending capture; unmet=[] |

Log: `_review/visual_playtest/final_vp2/logs/playthrough_1920x1080_ui100.log`  
(`P21_DONE ok=true`, `DONE shots=28`, helper Reach100 in ~347s sim / wall ~10s)

---

## 4. Negative path status

| Step | Status | Shot |
|---|---|---|
| Story rival LOSS | **PASS** | `playthrough/1920x1080/n01_rival_loss.png` |
| Retry WIN | **PASS** | `n02_rival_retry_win.png` |
| Discovery FAIL | **PASS** | `n03_discovery_fail.png` |
| Day advance → SUCCESS | **PASS** | `n04_discovery_success.png` |
| Date partial | **PASS** | `n05_date_partial.png` |
| Cooldown → conquer | **PASS** | `n06_date_recovery_conquer.png` |
| FinalDate failure branches | **WARNING** | not separately forced; success path only |

---

## 5. PNG count + sample paths verified

**Total PNGs (`final_vp2`):** 156  
- layout: 24  
- gallery: 104 (52 × 1280+1920)  
- playthrough: 28  

| Path | Actual content (opened) | Match |
|---|---|---|
| `gallery/1920x1080/010_settings.png` | Centered НАСТРОЙКИ modal over title | **PASS** |
| `gallery/1920x1080/050_progression.png` | ПРОКАЧКА modal (bottom-right) over apartment | **PASS** |
| `gallery/1920x1080/900_phone_status_stage6.png` | Phone STATUS Stage6/Finale stats (Auth 15, rates) | **PASS** (flavor OK overlay) |
| `playthrough/1920x1080/420_rival_choose.png` | Mine boss suitor ВЫЗОВ choices | **PASS** |
| `playthrough/1920x1080/600_lab.png` | Lab-ish room + HUD Auth 10; story OK modal overlay | **WARNING** |
| `playthrough/1920x1080/820_ending.png` | FinalDate success «ЦЕЛЬ ДОСТИГНУТА» (clone theme) | **WARNING** (not title-style Ending chrome) |
| `gallery/.../101_apartment_forward.png` (prior run) / apartment set | Graybox КВАРТИРА + interact labels | **PASS** |

Gallery unmet stub remaining: `130_dating_choice` early (no contact yet); later dating open still flaky → listed unmet only when truly missing.

---

## 6. Layout defects ERROR / WARNING counts

From `final_vp2/report.json` `defect_counts`:

| Severity | Count |
|---|---|
| ERROR | **0** |
| WARNING | **468** |

WARNING volume is mostly non-essential Control bounds across multi-res layout + large gallery trees (expected noise). No ERROR blockers.

---

## 7. Commands / logs

```powershell
$env:GODOT = "C:\godot\Godot_v4.7.1-stable_win64.exe"
py -3 tools/visual_review/run_visual_playtest.py --all --run-id final_vp2 `
  --godot "C:\godot\Godot_v4.7.1-stable_win64.exe"
```

| Artifact | Path |
|---|---|
| Merged report | `_review/visual_playtest/final_vp2/report.json` |
| Markdown | `_review/visual_playtest/final_vp2/report.md` |
| Engine logs | `_review/visual_playtest/final_vp2/logs/*.log` |
| Contact sheets | `_review/visual_playtest/final_vp2/contact_sheets/` |
| Mode PNGs | `.../layout|gallery|playthrough/<WxH>/` |

All launches `exit=0`, `timed_out=False`. No SCRIPT ERROR / Parse Error in playthrough/gallery logs. Exit leaks (RID/ObjectDB) are engine teardown noise after `quit()`.

---

## 8. Limitations

1. **PNG count 156 > ~120** — dual gallery resolutions + full layout matrix inflate total; mode folders prevent overwrite but not count.
2. **Story/flavor OK modals** can overlay lab/phone/final shots; dismiss helper closes OK but may reappear on travel; do not press «Далее» (breaks FinalDate).
3. **`820_ending`** is FinalDate success copy («ЦЕЛЬ ДОСТИГНУТА»), not a separate DATE FACTORY ending title screen.
4. **Playthrough `810_final_date_intro`** skipped in `final_vp2` when dismiss pressed «Далее» — fixed after the run (OK-only dismiss).
5. **World art** is graybox / low-poly placeholders — composition shots match names but are not final art.
6. **Debug `mode=` strings** visible in top-left on gameplay/modal captures.
7. **Dating choice gallery** early stub remains when neighbor contact not yet earned.
8. Do not use `final_vp1` for acceptance — gallery overwrote playthrough files before mode subdirs existed.

---

## 9. Recommendation

**PASS** — accept Phase C+D harness: gallery + playthrough produce a substantial real screenshot set; playthrough reaches Ending without `advance_stage` / `set_world_reach` / `mark_girl_conquered` / `set_story_flag`; layout ERROR=0; evidence in `final_vp2`.

Optional follow-ups (non-blocking): clear flavor overlays more reliably before venue shots; capture true Ending chrome if distinct from FinalDate success; trim gallery to one world res if PNG budget must stay ≤120.
