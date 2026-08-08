# DECISIONS — Visual Playtest Audit

## D-VP-01 — UI scale centering

**Decision:** Keep `Control.scale` in `UiScaleHelper.apply_to_control`, but set `pivot_offset = size * 0.5` and refresh on `resized`.

**Why:** Title/pause/settings/HUD apply scale to FULL_RECT roots. CenterContainer centers unscaled geometry; top-left pivot then biases the panel right/down at 125%/150%. Center pivot preserves centering without per-resolution magic offsets.

## D-VP-02 — Two test modes

**Decision:** Strict separation of `SCRIPTED_PLAYTHROUGH` (production progression APIs) vs `VISUAL_STATE_GALLERY` (fixtures / save restore allowed).

**Forbidden in playthrough:** `GameState.advance_stage`, `restore_stage`, direct XP inject, `mark_girl_conquered`, `mark_rival_defeated`, `set_story_flag`, `set_world_reach`.

**Allowed acceleration:** FakeCompetitionRunner, minigame `debug_*`, `complete_calibration_for_test`, `advance_simulation_for_test`, `set_test_auto_win_exhibition`.

## D-VP-03 — RC vs visual runs

**Decision:** Headless title-menu layout centering suite is `required_for_rc: true`. Full PNG visual playtest stays windowed via `tools/visual_review/run_visual_playtest.py` and is **not** in `--only-rc`.

## D-VP-04 — Phone tab seam

**Decision:** Add public `PhoneJournal.set_tab(tab)` wrapping `_set_active_tab` for gallery/matrix screenshots. No new phone architecture.

## D-VP-05 — Release / git hygiene

**Decision:**

- Exclude `game/visual_review/*` and `_review/*` from Windows export.
- Gitignore `_review/` on main; review branch force-adds final run artifacts only.
- Source fixes land on main first; then create `visual-review/<YYYYMMDD-HHMM>`.

## D-VP-06 — World art scope

**Decision:** Fix only reproducible BLOCKER/MAJOR emptiness/placement/lighting. Leave subjective art quality to external human review.
