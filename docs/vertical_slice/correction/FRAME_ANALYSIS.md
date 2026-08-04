# Frame analysis — correction screenshots

All frames from real `main.tscn` via `tools/capture_correction_route.gd` (not Character Testbed / Blender / standalone env scenes).

| File | Main gameplay? | What is visible | Visual error? | Fixed this pass? | Verdict |
|---|---|---|---|---|---|
| 01_apartment_spawn.png | YES | Interior spawn, HUD, objective, exit door | Overexposed pink walls, empty mid floor, open ceiling | Lighting clamp partial | WARNING |
| 02_apartment_date_preparation.png | YES | Near computer / date prep interact | Same apartment issues; HUD density | Partial light clamp | WARNING |
| 03_apartment_exit.png | YES | Facing apartment exit door | Door readable; room still sparse/pink | Spawn framing better | WARNING |
| 04_street_route.png | YES | Street after teleport, route markers | Empty end / void, capsule NPCs, pink blocks | Street spawn moved closer | WARNING |
| 05_restaurant_destination.png | YES | Approaching restaurant exterior | Destination readable; lamps still hot | Destination framing | WARNING |
| 06_restaurant_entrance.png | YES | Restaurant entry interact | Sign/entry readable; warm wash | Tone-down partial | WARNING |
| 07_date_table_empty.png | YES | Date table before girl seated | Warm-pink wash; table readable | Pink Omni clamp | WARNING |
| 08_girl_enters.png | YES | Girl near entrance / early approach | Approach starts at door | Skip gate + markers | PASS |
| 09_girl_approaches.png | YES | Girl moving toward chair | Path toward seat | Path + hold seated | PASS |
| 10_girl_sit_enter_side.png | YES | Side view sit enter / settle | Sitting on chair marker | Seating lock | PASS |
| 11_girl_sit_idle.png | YES | Girl seated idle at table | Seated pose holds | sit_idle + physics lock | PASS |
| 12_date_ui_three_answers.png | YES | Three answer buttons + seated girl | Custom UI; face not covered | Route works | PASS |
| 13_positive_reaction.png | YES | After positive choice feedback | UI feedback visible | — | PASS |
| 14_negative_reaction.png | YES | After negative choice feedback | UI feedback visible | — | PASS |
| 15_trait_hypothesis.png | YES | Hypothesis / trait prompt UI | Readable | — | PASS |
| 16_trait_confirmed.png | YES | End of phase 3 / confirm moment | Brief; date may close immediately after | Forced capture at phase end | WARNING |
| 17_date_result.png | YES | Result panel | Result readable | — | PASS |
| 18_girl_leaves.png | YES | Girl exit / leave after date | Leave sequence | — | PASS |
| 19_player_control_restored.png | YES | After date; player lock false | FPS restored | Transition fix | PASS |

## Summary counts

- PASS: 12
- WARNING: 7
- FAIL: 0

FAIL was not auto-promoted to PASS.
