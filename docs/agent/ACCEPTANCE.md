# Acceptance — MODULE 08 Girl Discovery & Phone Journal

## Player-visible result
See girl → discover + clue0 → interact → experience gate → authored approach → number in phone OR fail + clue + 1–3 day cooldown → same girl returns. Phone journal lists discovered only; no Dating buttons.

## PASS
- DiscoverySituation/Approach defs + ContentDB index/validate
- GameState: discovered (ordered), contacts, clues, primary reveal, reactions seam, retry days
- Autoload GirlDiscovery (event-driven, day-advance seam, no clock)
- Good Profile: second initial clue on first discovery only
- GirlActor + test scene; PhoneJournal MODAL_UI; no permanent phone hotkey
- MODULE_08_TEST ALL PASS + regressions 02–07D + FPS
- No MODULE 09

## Product questions
None — follow MODULE_08 spec; use PlayerController.ControlMode.MODAL_UI (not invent PlayerControlMode).
