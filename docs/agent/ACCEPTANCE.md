# Acceptance — MODULE 07B Dance Minigame

## Player-visible result
Rival DANCE competition runs through unified RivalCompetitionRunner → DanceMinigame → typed result → RivalEncounters Authority reward/penalty (not inside Dance).

## PASS criteria (must all hold)
- SlapCompetitionHost removed; RivalCompetitionRunner is sole production runner (autoload preferred)
- One execution seam: `set_competition_runner` — no dual signal+callable submit paths
- SLAP + DANCE routes work; SIGMA/MONEY unsupported (no fake result)
- MODULE 06 fake runner tests still PASS
- Dance: W/A/S/D, demo/repeat/own, target 3/5, seq 3/4, beat 0.80, exact window/error/perk rules
- Headless MODULE_07B_TEST ALL PASS + regressions 02–07A + FPS

## Product questions
None — follow MODULE_07B_DANCE_MINIGAME.md exactly.
