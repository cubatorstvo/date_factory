# ACCEPTANCE — MODULE 27 Full Game QA

## Question
Can a normal player finish the game with save/load without broken state?

## Evidence
- RC runner: **33/33 PASS** (`py -3 tools/qa/run_all_tests.py --only-rc`)
- Scripted Route A/B/save: **ALL PASS (157)**
- Title / New Game smoke: PASS (GodotIQ)
- Manual A–F: NOT EXECUTABLE IN ENVIRONMENT (honest; scripted covers mainline/recovery)
- BLOCKER=0, MAJOR=0
- Schema v1
- Docs: `docs/qa/FULL_GAME_QA_REPORT.md`, REGRESSION_MATRIX, KNOWN_ISSUES
- Independent QA: `docs/agent/qa/M27_QA.md`

## Production fixes (defect-linked)
1. Stale catalog count asserts (M25) in girl_discovery / 14a / 14b
2. Dance E2E story loss Auth expect 0 (M26)
3. Empty pre-M25 NpcSpawnPoint spawn_ids
4. world_location headless free-crash settle frames

## Verdict
**READY**

STOP — do not begin MODULE 28.
