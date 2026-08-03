# Temporary / replaceable assets

## Fonts (keep or replace)
| File | License | Source |
|------|---------|--------|
| `assets/fonts/Outfit-*.ttf` | SIL OFL 1.1 | [Outfit / Fontsource](https://fontsource.org/fonts/outfit) |
| `assets/fonts/DMSans-*.ttf` | SIL OFL 1.1 | [DM Sans / Fontsource](https://fontsource.org/fonts/dm-sans) |

OFL text: https://openfontlicense.org/

## Audio
All current SFX/music beds are **procedural WAV stubs** generated in `core/sfx.gd`.
Replace by dropping authored files into `assets/audio/sfx/` and wiring names in `Sfx._profile` / a future AudioLibrary.

Suggested replacement keys: click, hover, confirm, cancel, deny, buy, buy_big, unlock, girl, relation, date_ok, date_bad, money, step, land, door, elevator, machine, gift, place, event_start, event_end, finale, menu_bed.

## 3D
Capsule / box mannequins via `core/prop_factory.gd` — intentional stubs until character art.

## UI chrome
Theme built at runtime by `ThemeFactory` + `UiStyle` (no external icon pack yet).
