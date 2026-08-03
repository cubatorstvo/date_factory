# DATE FACTORY — Production polish report

Date: 2026-08-03

## 1. Art direction
**Romance Industry Luxury** — dark plum panels (`#140C18` / `#241828`), gold strokes (`#E8B86D`), hot coral CTAs (`#FF4D8D`), cream text (`#F7F0E8`), cyan automation accents (`#6EE7FF`).  
Typography: **Outfit** (display) + **DM Sans** (UI), SIL OFL 1.1.  
See `docs/ART_DIRECTION.md`.

## 2. Systems reworked
| System | Change |
|--------|--------|
| Theme / fonts | `ThemeFactory`, `UiStyle`, global root theme |
| Settings | `SettingsService` + settings menu (volumes, FOV, bob, shake, fullscreen, sens) |
| Audio buses | Master / Music / SFX / UI / Ambient at runtime |
| SFX | Expanded procedural library in `core/sfx.gd` |
| Boot | Branded menu: New / Continue / Settings / Quit + fade |
| Pause | Esc pause overlay with save/load/settings/main menu |
| Reveals | Stage / girl unlock presentations |
| Finale | Credits-style overlay + postgame continue |
| Player feel | Accel, sprint+FOV, bob, land, carry sway, footsteps, shake |
| Dates | Walk-in intro, sit, gift on table, delayed UI, exit walk |
| World | Wanderers, machine spin, stage lighting mood |
| Interactables | Focus glow, punch, click SFX |
| Phone / Event / HUD | Tweens, empty states, floating money text |

## 3. SFX / VFX added
Procedural: click, hover, confirm, cancel, deny, buy, buy_big, unlock, girl, relation, date_ok/bad, money, step, land, door, elevator, machine, gift, place, event_start/end, finale, menu bed.  
VFX: floating money/OK labels, interact pulse, date pocket lights, stage lighting.

## 4. Staged scenes
- Date intro/outro spatial sequence (`date_stage.gd`)
- Stage reveal popup (stages 2+)
- Girl unlock reveal
- Finale / credits overlay

## 5. Playthrough results
- Headless `tools/smoke_test.gd`: **SMOKE_OK** (gifts 24, upgrades 91, events 31, rooms 6) — path through neighbor date → stages → megamachine → Algorithm start.
- Manual visual MCP screenshot pipeline was flaky (timeouts); boot layout verified via state_inspect (panel 560×422 after fix).

## 6. Known issues
- Procedural beeps ≠ production audio
- Capsule mannequins / box rooms remain
- Late-game balance not retuned for 5–8h target
- Pause + date intro need more human soak-testing
- MCP screenshots often timeout in this environment

## 7. Temporary resources to replace
See `docs/TEMP_ASSETS.md` (fonts OFL keepable; SFX/3D stubs replaceable).

## 8. Asset mapping
| Slot | Current | Replace with |
|------|---------|--------------|
| Display font | Outfit OFL | Keep or brand font |
| Body font | DM Sans OFL | Keep |
| UI/SFX | `Sfx._make_wav` | `assets/audio/sfx/*.ogg` |
| Characters | PropFactory capsules | Authored GLB |
| Rooms | BoxMesh rooms | Kitbash / modular |

## 9. Readiness criteria (plan §)
| # | Criterion | Status |
|---|-----------|--------|
| 1 | New game from main menu | **DONE** |
| 2 | Tutorial understandable | **PARTIAL** (gates + goals; no highlight arrows) |
| 3 | Full path to finale | **DONE** (systems + smoke) |
| 4 | Save/load stages | **DONE** (single slot) |
| 5 | Visual+audio feedback on core actions | **PARTIAL→mostly DONE** |
| 6 | No raw default Godot look on main screens | **PARTIAL** (theme applied; phone tabs still utilitarian) |
| 7 | Button states | **DONE** (theme hover/pressed/disabled/focus) |
| 8 | Major unlock presentations | **DONE** (stage/girl/finale) |
| 9 | Spatial date start/end | **DONE** |
| 10 | Characters enter world (not teleport) | **PARTIAL** (dates yes; staff/clones still spawn) |
| 11 | FPS game feel | **DONE** |
| 12 | Camera settings | **DONE** |
| 13 | SFX cover loop | **PARTIAL** (procedural coverage) |
| 14 | Passive world life | **PARTIAL** (wanderers + machines) |
| 15 | Finale feels like ending | **PARTIAL** (overlay; short) |
| 16 | No critical softlocks | **PARTIAL** (Esc recovery; needs soak) |
| 17 | Review: only agreed 3D stubs left | **PARTIAL** |
| 18 | Exportable demo build | **TODO** (export presets not added) |

## 10. Screenshots
Boot layout validated in-engine (brand panel). Capture locally: Play → boot → New Game → apartment → phone → date → Esc pause.

---

### Optional downloads for Brian (licensed / recommended)
1. **Godot export templates** (for Windows build): open Godot → Editor → Manage Export Templates, or  
   https://godotengine.org/download/windows/
2. **CC0 SFX pack (Kenney Interface Sounds)** to replace procedural beeps:  
   https://kenney.nl/assets/interface-sounds  
   License: CC0.
3. **CC0 ambient** (optional): Kenney Music Jingles / OpenGameArt CC0 loops — verify each pack’s license page before import.
4. Fonts already vendored under `assets/fonts/` (OFL) — no install needed.

Do **not** grab random itch.io “free UI kits” without checking license.
