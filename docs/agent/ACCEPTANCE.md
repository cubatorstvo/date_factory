# Acceptance — MODULE 12 World & Location Framework

## Player-visible result
Play from apartment blockout; E-travel hub-and-spoke; StoryFeature gates; phone opens PhoneJournal; PROLOGUE = apartment only.

## Locked decisions
- Autoload `World` owns travel/access/current location
- Scenes: `res://world/locations/<id>/<id>.tscn` for all 9 IDs
- Access from Story features (not GameState.unlock_location for the 9)
- PUBLIC_CITY_ACCESS = internal city_hub gate, not 10th location
- main bootstrap → apartment (FPS test harness remains)
- Blockout OK (Mesh+StaticBody, TextMesh signs)
- No MODULE 13

## PASS
MODULE_12_TEST ALL PASS (127) + regressions 02/03/04/05/06/08/09/10/11 + FPS boot + main→apartment

## Evidence
- `world/test/world_location_test.tscn` → `MODULE_12_TEST: ALL PASS (127)`
- Regressions: MODULE_02/03/04/05/06/08/09/10/11 ALL PASS; `player_fps_test` boots
- `main.tscn` headless: `Boot -> apartment via World`
