# Donor art import mirror (VISUAL BOOTSTRAP)

Source: read-only legacy donor project (branch `legacy-v1`).
Assets remain at `res://assets/...` (identical layout).
Art scenes live under `res://world/art/donor_import/...`.

## Layout

| Path | Source |
|---|---|
| `city/city.tscn` | `scenes/world/city/city.tscn` |
| `city/**` (poi, prefabs, slices) | `scenes/art/city/**` |
| `apartment/apartment.tscn` | `scenes/world/vertical_slice/apartment.tscn` |
| `apartment/apartment_place_setting.gd` | same donor folder |
| `cafe/restaurant.tscn` | `scenes/world/vertical_slice/restaurant.tscn` |

## Cafe filename choice

Kept `restaurant.tscn` (donor filename) under `cafe/` folder.
Do not confuse with gameplay `world/locations/**`.

## Path rewrite

`res://scenes/art/city/` → `res://world/art/donor_import/city/`
`res://scenes/world/vertical_slice/apartment_place_setting.gd` → `res://world/art/donor_import/apartment/apartment_place_setting.gd`

No absolute/relative paths pointing outside this repo for runtime.

## Characters helper

| Path | Source |
|---|---|
| `characters/character_anim_controller.gd` | `scenes/art/characters/character_anim_controller.gd` |

Character prefabs under `assets/characters/**/prefabs` were rewritten to this local script path.
