# DATE FACTORY release baseline audit

Date: 2026-08-05  
Branch: `release/rc-hardening`  
Engine: Godot 4.7.1  
Status: `NOT READY`

## Scope freeze

Текущий набор POI, dating places, progression stages, shops, activities и facility rooms является окончательным scope RC. Разрешены завершение, исправление, asset replacement, layout/lighting/UI pass, тесты и упаковка. Новые POI, районы, крупные механики, cloud/multiplayer/achievements и параллельные frameworks запрещены.

## Baseline evidence

- GodotIQ: 47 scenes, 96 scripts, 1098 assets.
- Parse check: 0 GDScript errors / 96 scripts.
- Convention scan: 0 errors, 103 warnings, 33 info.
- Headless Godot 4.7.1 smoke: `SMOKE_OK gifts=27 upgrades=91 events=31 rooms=11`.
- Normal-route visual tour: not yet performed; all visual conclusions remain `PENDING VISUAL REVIEW`.
- Windows export preset/build: absent.

## Player route found

`New Game → apartment → phone/schedule → shops/inventory → home or city date → district expansion → facility stages → lab/clones → stage_6 orbital → megamachine → Algorithm date → FinaleUI/postgame`.

The route exists architecturally but is not currently completable through normal player actions.

## Release blockers

1. Player-facing Continue always loads the QA full-access profile instead of the normal save.
2. Several unique girls required by finale gates have no discoverability/spawn path; `try_unlock_by_progress()` is empty.

## Critical/major baseline

- No reproducible full-progression regression without forced `mark_met`.
- No Windows export preset or tested build.
- Existing finale is present but normal-route completion is unproven.
- City is a linear east-west corridor with no route loops.
- Several street activities have gameplay interactions but hidden/missing physical art.
- `ParkRestaurant` visual CSG has zero size.
- City-authored environment/key light is stripped; remaining global sun/ambient produces a dim plum street.
- POI outlines/colliders are generally proxy volumes, not owned by facade objects.
- Expansion rooms and themed apartments remain procedural greyboxes.
- Gift icons remain placeholders; UI has mixed English seed strings and unverified resolution behavior.
- Credits/asset registry/export inclusion policy are incomplete.

## License baseline

- Most Quaternius/Kenney packs include CC0 files.
- Sushi Restaurant Kit source page confirms personal/commercial use; a project-side license/source record still must be added.
- Outfit and DM Sans license files are missing from the repository.
- Drinkware provenance is unresolved; remove from release usage or document a verified source.

## Product decisions

- Restore shipping Continue to the normal save; retain QA full-access as test-only.
- Preserve the existing stage_6/Algorithm finale and repair production meet paths instead of softening gates.
- Keep overlay POIs as overlay activities; finish facades/props/UI rather than inventing walkable interiors.
- Reuse the existing UI theme and selectively replace placeholders.

## Source reports

- `docs/release/research/GAMEPLAY_TECHNICAL_AUDIT.md`
- `docs/release/research/WORLD_POI_AUDIT.md`
- `docs/release/research/UI_ASSET_AUDIT.md`
- `docs/release/research/_smoke_audit.log`

## Baseline verdict

The audit itself is complete. The game is `NOT READY`: two Blockers and multiple release-critical Major items remain, and no visual/export/full-route acceptance evidence exists.
