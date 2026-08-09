# Player Experience Pass 01 — Evidence Index

This review-only index points to the curated artifacts committed with the pass.

## Before

- `tmp/px_pass_01/evidence/A/stuck_00_00_blank_no_main_menu.png` — initial clean-profile boot failure.
- `tmp/px_pass_01/evidence/B_recovery/stuck_00_25_no_taught_controls_or_goal.png` — Persona B has no taught controls or objective before the pass fixes.
- `tmp/px_pass_01/logs/godot_A_20260809_213016.log`
- `tmp/px_pass_01/logs/godot_B_20260809_213349.log`

## After

- `tmp/px_pass_01/evidence/C/01_new_game_first_frame.png` — first-frame controls and objective.
- `tmp/px_pass_01/evidence/C/04_first_interaction_prompt.png` — semantic interaction affordance.
- `tmp/px_pass_01/evidence/C/09_neighbor_interaction.png` — Neighbor discovery and contact.
- `tmp/px_pass_01/evidence/C/10_first_story_next_step.png` — post-contact story continuation.
- `tmp/px_pass_01/evidence/D_final/01_new_game_first_frame.png`
- `tmp/px_pass_01/evidence/D_final/09_neighbor_prompt_canonical.png`
- `tmp/px_pass_01/evidence/D_final/11_number_modal.png`
- `tmp/px_pass_01/evidence/D_final/12_resumed_post_number.png`
- `tmp/px_pass_01/logs/godot_C_20260809_220623.log`
- `tmp/px_pass_01/logs/godot_D_final_20260809_223827.log`

## Collision debug

`tmp/pe01_collision_debug/` contains the capture helper, raw engine log, AABB measurements, report, and the six reviewed overlays. The final images for the corrected storage and exit collision volumes are:

- `tmp/pe01_collision_debug/evidence/apartment_collision_storage.png`
- `tmp/pe01_collision_debug/evidence/apartment_collision_exit.png`

## Test and review results

- `docs/qa/PLAYER_EXPERIENCE_PASS_01.md` — player journal.
- `docs/agent/qa/PE01_BLIND_A_B_QA.md` — initial blind-run QA.
- `docs/agent/qa/PE01_BLIND_C_D_QA.md` — repaired-flow blind-run QA.
- `docs/agent/qa/PLAYER_EXPERIENCE_PASS_01_QA.md` — independent final QA verdict.
- `tmp/pe01_final_qa/` and `tmp/pe01_apt_phys/` — focused self-test logs and reviewed screenshots.
- `tmp/qa/summary.txt` and `tmp/qa/world_location.log` — reference-regression result; the remaining `world_location` failure is inherited City/Cafe debt.

No video recording was captured for this pass. The reproducible input driver is in `tmp/px_pass_01/driver/`, while the curated screenshot sequences and raw engine logs above provide the review record.
