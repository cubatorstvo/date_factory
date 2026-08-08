# ACCEPTANCE — MODULE 17 FIX2 GirlDiscovery Scientist prerequisite

## Player-visible result
Direct `GirlDiscovery.begin_attempt(girl_scientist)` on STAGE_4 before overload recognition returns STORY_PREREQUISITE (even if rival marked defeated). GirlActor shows the prerequisite line. After recognition, rival gate then normal attempt.

## PASS
- RESULT_STORY_PREREQUISITE exists
- Gate runs before Story rival/wrong-stage gates
- No side effects on block
- GirlActor feedback string
- Tests: before / after recognition+rival / after rival+XP
- No MODULE 18

## Verdict
READY
