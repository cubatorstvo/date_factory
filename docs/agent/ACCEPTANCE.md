# Acceptance — MODULE 11 Story / Stage Framework

## Player-visible result
Linear stages PROLOGUE→FINALE with rival→girl→+5 advance (earth stages), story gates on reserved girls, stage-derived feature unlocks.

## Locked decisions
- Autoload `Story` after Relationships (listens girl_completed + encounter_won)
- Extend existing StoryStageDefinition + 8 stage .tres (no production Girl/Rival defs required)
- Features derived from stage (≥ thresholds); only new flag FLAG_WORLD_EXPANSION_COMPLETE
- GirlDiscovery consults Story before Experience; STORY_* ≠ FAILURE
- RivalEncounters core stays Story-agnostic
- No MODULE 12

## PASS
MODULE_11_TEST ALL PASS + regressions 02–10 + FPS
