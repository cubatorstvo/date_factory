# REGRESSION MATRIX — MODULE 27 Full Game QA

**Spec:** §114  
**Manifest:** `qa/test_manifest.json`  
**Runner:** `tools/qa/run_all_tests.py --only-rc`  
**Evidence root:** `tmp/qa/`  
**Date:** 2026-08-08 (independent QA recheck — **33/33 PASS**)

Status legend:

- **PASS** — log shows `ALL PASS`
- **PASS*** — `ALL PASS` then known post-suite crash (KI-M27-01)
- **FAIL** — assertion failures
- **CRASH** — engine crash before suite completion
- **n/a** — not applicable / interactive-only

Manual A–F: **NOT EXECUTABLE IN ENVIRONMENT** for all rows unless noted.

---

## Manifest suites + full_game_integration

| System | Suite id | Module | required_for_rc | Automated | Manual A–F | Save/load | Perf | Result | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| FPS/Interaction | `player_fps` | M01 | no | interactive | n/a | n/a | n/a | n/a (excluded RC) | — |
| GameState/Data | `game_state` | M02 | yes | PASS | NOT EXEC | via M24 | n/a | **PASS** | `tmp/qa/game_state.log` |
| Content | `content_data` | M03 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/content_data.log` |
| Characters | `character_framework` | M04 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/character_framework.log` |
| Characters (visual) | `character_framework_visual` | M04 | no | interactive | n/a | n/a | n/a | n/a | — |
| Progression | `progression` | M05 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/progression.log` |
| Rivals | `rival_encounter` | M06 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/rival_encounter.log` |
| Slap | `slap_minigame` | M07A | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/slap_minigame.log` |
| Dance | `dance_minigame` | M07B | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/dance_minigame.log` |
| Sigma | `sigma_minigame` | M07C | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/sigma_minigame.log` |
| Money | `money_minigame` | M07D | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/money_minigame.log` |
| Discovery | `girl_discovery` | M08 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/girl_discovery.log` |
| Dating | `dating` | M09 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/dating.log` |
| Relationships | `relationships` | M10 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/relationships.log` |
| Story | `story` | M11 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/story.log` |
| World | `world_location` | M12 | yes | PASS | NOT EXEC | partial via M24/M27 | n/a | **PASS** (127) | `tmp/qa/world_location.log` |
| Salary | `salary_mine` | M13 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/salary_mine.log` |
| Content (14A) | `module_14a_vertical` | M14A | yes | PASS | NOT EXEC | n/a | n/a | **PASS** (121) | `tmp/qa/module_14a_vertical.log` |
| Content (14B) | `module_14b_vertical` | M14B | yes | PASS | NOT EXEC | n/a | n/a | **PASS** (85) | `tmp/qa/module_14b_vertical.log` |
| Media | `media` | M15 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/media.log` |
| Overload | `dating_overload` | M16 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/dating_overload.log` |
| FirstClone | `first_clone` | M17 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/first_clone.log` |
| CloneIncremental | `clone_incremental` | M18 | yes | PASS | NOT EXEC | yes (suite) | n/a | **PASS** | `tmp/qa/clone_incremental.log` |
| CloneVisualization | `clone_visualization` | M19 | yes | PASS | NOT EXEC | n/a | caps in suite | **PASS** | `tmp/qa/clone_visualization.log` |
| LateGame | `late_game` | M20 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/late_game.log` |
| FinalDate | `final_date` | M21 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/final_date.log` |
| UI | `game_hud_smoke` | M22 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/game_hud_smoke.log` |
| UI | `ui_number_format` | M22 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/ui_number_format.log` |
| UI | `progression_ui` | M22 | yes | PASS | NOT EXEC | n/a | n/a | **PASS** | `tmp/qa/progression_ui.log` |
| Audio/Presentation | `audio_director` | M23 | yes | PASS | NOT EXEC | settings via M24 | n/a | **PASS** | `tmp/qa/audio_director.log` |
| Persistence | `save_system` | M24 | yes | PASS* | NOT EXEC | yes | n/a | **PASS*** | `tmp/qa/save_system.log` |
| Persistence | `game_state_save` | M24 | yes | PASS | NOT EXEC | yes | n/a | **PASS** | `tmp/qa/game_state_save.log` |
| Persistence | `world_save_pose` | M24 | yes | PASS* | NOT EXEC | yes | n/a | **PASS*** | `tmp/qa/world_save_pose.log` |
| Balance | `balance` | M26 | yes | PASS | NOT EXEC | n/a | budgets | **PASS** | `tmp/qa/balance.log` |
| Full game | `full_game_integration` | M27 | yes | PASS* | NOT EXEC (scripted A/B/save) | yes (scripted) | n/a | **PASS*** (157) | `tmp/qa/full_game_integration.log` · `tmp/qa/summary.txt` |

---

## Counts (final recheck)

| Bucket | Count |
|---|---|
| Manifest entries | 34 |
| `required_for_rc: true` | 33 (incl. `full_game_integration`) |
| PASS / PASS* | **33** |
| FAIL | **0** |
| CRASH incomplete | **0** |
| Interactive excluded | 2 (`player_fps`, `character_framework_visual`) |

Runner transcript: `tmp/qa/runner_rc_smoke.out` · summary: `tmp/qa/summary.txt`
