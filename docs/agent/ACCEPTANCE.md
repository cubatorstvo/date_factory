# ACCEPTANCE — MODULE 17 FIX Scientist production wiring

## Player-visible result

After DatingOverload recognition on already-loaded city_hub, Scientist + rival appear at lab gate without reload. Direct discovery before recognition shows prerequisite feedback (not FAILURE). Rival → Scientist +5 → STAGE_5 → Lab → first clone still works.

## PASS
- `requires_overload_recognized` + event refresh + `state_reset` refresh
- city_hub Scientist anchors Stage4, appear live after recognition, absent before
- GirlDiscovery STORY_PREREQUISITE + GirlActor feedback string
- FirstClone unchanged (1/1/0 or 1/0/1, rates 0)
- MODULE 02–17 regressions PASS; no MODULE 18

## Verdict
READY
