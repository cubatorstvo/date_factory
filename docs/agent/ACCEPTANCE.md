# ACCEPTANCE — Visual Playtest Audit

## Question
Can we run a development-only scripted visual playtest from Main Menu to Ending, capture a standardized screenshot gallery, auto-detect layout defects, fix reproducible BLOCKER/MAJOR issues, keep RC green, and publish review screenshots on a temporary branch?

## Modes (must remain separate)

```text
SCRIPTED PLAYTHROUGH
VISUAL STATE GALLERY
HUMAN VERIFICATION REQUIRED
```

Do not claim human playtest passed for a scripted run.

## Definition of Done (spec §36)

- [ ] development-only scripted playthrough exists under `game/visual_review/`
- [ ] production APIs used for progression; no direct Stage/XP/story/conquer/Reach cheating in playthrough
- [ ] visual state gallery exists separately
- [ ] deterministic screenshot capture; settle wait ≥2 frames + 150–300ms
- [ ] full playthrough screenshots at 1920×1080
- [ ] critical UI matrix at 1280/1366/1600/1920/2560/ultrawide
- [ ] world composition shots at 1280+1920
- [ ] Main Menu 1280 horizontal offset fixed (UiScale center pivot)
- [ ] regression test for menu centering (`required_for_rc: true`)
- [ ] automatic Control bounds/layout audit
- [ ] UI scale 100/125/150 at 1280 tested
- [ ] apartment/city/cafe/gym/appearance/rivals/salary/media/overload/lab/Stage6/Final represented
- [ ] Phone / Progression / Save/Load / Settings gallery
- [ ] scripted negative path
- [ ] visual/layout BLOCKER=0 and MAJOR=0 after objective Cursor pass
- [ ] all RC regressions pass
- [ ] `report.md` / `report.json` + contact sheets
- [ ] final screenshots roughly 70–120 PNGs
- [ ] source fixes on main; screenshots only on `visual-review/<stamp>` branch
- [ ] human-only limitations stated honestly
- [ ] STOP. Do not delete review branch.

## Evidence locations

- Harness: `game/visual_review/`, `tools/visual_review/run_visual_playtest.py`
- Docs: `docs/qa/VISUAL_PLAYTEST.md`
- Artifacts: `_review/visual_playtest/<run_id>/`
- RC: `py -3 tools/qa/run_all_tests.py --only-rc`

## Verdict

**READY** (scripted visual playtest + layout RC)

Evidence: harness under `game/visual_review/` + `tools/visual_review/`; Main Menu centering fixed; modal CenterContainer fixes; RC **35/35 PASS** (includes `title_menu_layout`); run `final_vp2` (156 PNGs, layout ERROR=0); review artifacts published on temporary `visual-review/*` branch only.

```text
SCRIPTED PLAYTHROUGH
VISUAL STATE GALLERY
HUMAN VERIFICATION REQUIRED
```
