# Full playthrough checklist (release)

Manual / acceptance companion to headless `tests/release` runners.  
Headless PASS does **not** prove visuals, input feel, or export packaging.

Use with: New Game clean save (not QA full-access slot).

Headless launch (logical contracts):

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\release\run_release_tests.ps1 -Mode smoke
powershell -ExecutionPolicy Bypass -File .\tests\release\run_release_tests.ps1 -Mode full
```

See `docs/release/AUTOTEST_RUNBOOK.md` for artifacts and contracts.

## Boot / New Game

- [ ] Boot menu loads without script errors
- [ ] New Game starts `stage_1` in apartment
- [ ] Continue disabled or correct when no normal save
- [ ] Continue restores `user://save_slot_1.json` only (QA slot untouched)

## Apartment → city

- [ ] Exit apartment to city (`go_outside`)
- [ ] Return home (`go_home`)
- [ ] Controls/UI return after travel

## Economy / shops / inventory

- [ ] Job / cafe tip earns money
- [ ] Flower / gift / clothing / homeware purchase updates inventory
- [ ] Gift count visible for date prep
- [ ] «Подарить подарок» visible/usable on date when inventory has a gift

## Schedule + home date

- [ ] Phone books home date with neighbor (not before tutorial wardrobe gate)
- [ ] Table food/drink prep required
- [ ] Date starts in window; choices resolve; result screen
- [ ] Neighbor becomes met via date (not debug)
- [ ] Post-date: phone Journal/Связи shows profile + last date summary

## External POI date

- [ ] Book cafe / restaurant / park / cinema / arcade when unlocked
- [ ] Cafe and arcade do not block each other's capacity
- [ ] Sit/start works; gift optional; result recorded
- [ ] Re-entry to city/home after date

## City amenities (existing)

- [ ] Bench rest
- [ ] Ducks / park fun (when park unlocked)
- [ ] Karaoke / bar
- [ ] Gym pass or gym session
- [ ] Bookstore / arcade / photo / barber / agency board (as unlocked)
- [ ] Flower shop purchase path is singular and clear

## Unique discovery (production only)

For each ContentDB unique except algorithm:

- [ ] Reachable without QA profile / `mark_met` cheat
- [ ] Contact via city talk or documented meet route
- [ ] At least one successful date → met
- [ ] Stage/popularity gates match content defs

Uniques: neighbor, fitness, goth, streamer, business, fashionista, chef, scientist, lawyer, star, alien.

## Stage expansion

- [ ] stage_1 → stage_2 (park district)
- [ ] stage_2 → stage_3 (agency row)
- [ ] stage_3 → stage_4 → stage_5 → stage_6 via expansion costs + popularity
- [ ] Facility rooms/venues unlock with stage (including `arcade` venue)

## Lab / clones / staff (existing systems)

- [ ] Scientist met unlocks clone usability (or documented equivalent)
- [ ] Hire staff when staged
- [ ] Clone create / acceptance when available

## Finale / postgame

- [ ] Megamachine parts purchasable
- [ ] Algorithm unlock when finale gates satisfied
- [ ] Algorithm date at orbital hall
- [ ] Postgame flag set; free-play / menu choice clear
- [ ] Save / load preserves postgame + stage_6

## Save / load contracts

- [ ] Mid-run save → load restores stage, economy, contacts, met flags
- [ ] Re-entry after load into apartment/city works
- [ ] QA full-access slot never overwritten by normal save

## Headless regression cross-check

- [ ] `run_release_tests.ps1 -Mode smoke` exit 0
- [ ] `run_release_tests.ps1 -Mode full` exit 0
- [ ] Inspect `*_godot.log` + `*_report.txt` under `tests/release/artifacts/` (`duration_sec`, `failed_step` if any)

## Explicitly out of this checklist

- Visual polish screenshots (separate capture pass)
- Windows export install verification (packaging phase)
- New POI / new mechanics beyond frozen scope
- Trusting `tools/smoke_test.gd` (uses `mark_met`; not normal-route proof)
