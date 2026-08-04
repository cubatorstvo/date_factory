# Known Limitations

**Обновлено:** 2026-08-04

## Stage 1 / visual slice

- Production visual pass targets Stage 1 apartment → street → restaurant. Later facility rooms retain more legacy/greybox presentation.
- City and home load **mutually exclusively** via `ComplexWorld.travel_to` — see [DATING_AND_WORLD.md](../DATING_AND_WORLD.md). Art lives in `scenes/world/city/city.tscn` (and street mirror).
- `PlayerHomeFacade` + `HomeEntrance` are the live home door on the east end; west-end `ApartmentReturn` / street `PlayerSpawn` are legacy unused.
- Gift shelf mesh may still exist in apartment art but is hidden / out of gameplay flow (shops + inventory instead).
- `Girl_Casual` is used for restaurant presentation; `Girl_Formal` may be retargeted but not always content-selected at runtime.
- Free-roam player is camera/capsule; seated Hero appears in date vignette only.
- Reaction VFX use lightweight UI glyph bursts rather than a general particle library.
- Target engine for this project: **Godot 4.7.1**. Older notes mentioning 4.4.1 are obsolete.

## Import / tooling

- Import/retarget stabilization regenerates large prefab and `.import` diffs.
- Proxy girl POC under `assets/characters/girls/proxy_poc/` and `docs/characters/` is experimental — not the live DateGirl path (`DateGirl_UAL`).
- Existing project-wide convention warnings and unused extensibility signals may remain; parser/compile cleanliness is the bar for play.

## Audio / capture

- Zone music: apartment / street / restaurant via `Sfx.set_zone`.
- Standalone screenshot / headless capture tools can print renderer diagnostics on exit; normal game runtime is the acceptance surface.
