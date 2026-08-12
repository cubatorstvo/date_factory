# Asset Licenses

Production external / generated assets with redistribution notes.  
All paths are physical copies inside this repo (`res://` only). **No runtime dependency** on `../date_factory_legacy`.

Character / animation packs: also see `docs/THIRD_PARTY_ASSETS.md` (Quaternius CC0).

---

## Characters — clothing overlays (project primitives)

Kenney and the imported Quaternius Superhero packs ship **body + hair only** (swimsuit/full-body mesh). DATE FACTORY does not model unique clothing GLBs for v1.0.

| Project path | Role |
|---|---|
| `characters/female/female_base_visual.tscn` slots `TopRoot` / `BottomRoot` / `ShoesRoot` / glasses | Neighbor + story girls |
| `characters/male/male_base_visual.tscn` same slot roots | Opening hero / male NPCs |

- Source: authored BoxMesh / CapsuleMesh overlays bound to PACK_021 bones via `character_variant_controller.gd`
- License: **CC0** project primitives (no third-party clothing pack)
- Body mesh remains Quaternius Superhero CC0; overlays cover the swimsuit read so Top/Bottom/Shoes read as clothes
- Profiles: `data/content/appearances/appearance_female_neighbor.tres`, `appearance_male_base.tres`

---

## Audio — Music (Abstraction Music Loop Bundle)

| Project path | Role | Donor filename (copy source) |
|---|---|---|
| `assets/audio/music/manual_apartment_chill.ogg` | MANUAL bed | `apartment_chill.ogg` |
| `assets/audio/music/media_street_night.ogg` | MEDIA bed | `street_night.ogg` |
| `assets/audio/music/clone_restaurant_warm.ogg` | CLONE bed (interim warm loop) | `restaurant_warm.ogg` |

- Pack: [Abstraction — Music Loop Bundle](https://tallbeard.itch.io/music-loop-bundle)
- License: **CC0 / Public Domain** — `assets/audio/licenses/MUSIC_LOOP_BUNDLE_LICENSE.txt`
- Optional credit: Abstraction — https://abstractionmusic.com/
- README copy: `assets/audio/licenses/MUSIC_LOOP_BUNDLE_README.txt`

---

## Audio — FINAL sparse bed (project-generated)

| Project path | Role |
|---|---|
| `assets/audio/music/final_sparse.wav` | FINAL music state — quiet sparse mono bed (~12 s) |

- Source: generated for MODULE 23 (Python stdlib `wave`); **not** from Kenney or Abstraction
- License: **CC0** project stub — `assets/audio/licenses/FINAL_SPARSE_GENERATED_LICENSE.txt`
- Format: WAV (imported by Godot); replace with authored space loop when available

---

## Audio — UI SFX (Kenney Interface Sounds)

Under `assets/audio/sfx/ui/`:

`back.ogg`, `click.ogg`, `close.ogg`, `confirm.ogg`, `error.ogg`, `hover.ogg`, `open.ogg`, `tick.ogg`, `toggle.ogg`

- Pack: [Kenney Interface Sounds](https://kenney.nl)
- License: **CC0** — `assets/audio/licenses/KENNEY_INTERFACE_SOUNDS_LICENSE.txt`

Semantic wiring (examples): `ui_click`→click, `ui_back`→back, `ui_denied`→error, `ui_purchase`→confirm (`audio/audio_ids.gd`).

---

## Audio — Impact / result SFX (Kenney)

| Project path | Role |
|---|---|
| `assets/audio/sfx/impact/soft_impact.ogg` | Soft hit / slap body |
| `assets/audio/sfx/impact/result_success.ogg` | Win / positive / perfect accent |
| `assets/audio/sfx/impact/result_fail.ogg` | Loss / negative |

- License texts (CC0): `KENNEY_IMPACT_SOUNDS_LICENSE.txt`, `KENNEY_MUSIC_JINGLES_LICENSE.txt` under `assets/audio/licenses/`
- Copied via donor world SFX set; local paths only

---

## Audio — World SFX (Kenney)

| Project path | Role |
|---|---|
| `assets/audio/sfx/world/event_chime.ogg` | Stage / milestone / publish / major cue |
| `assets/audio/sfx/world/door_open.ogg` | Final zone gate (and related) |
| `assets/audio/sfx/world/door_close.ogg` | Available world close cue |

- License: Kenney CC0 texts under `assets/audio/licenses/`

---

## Audio — Ambience (Kenney Sci-Fi)

| Project path | Role |
|---|---|
| `assets/audio/ambience/factory_hum.ogg` | Local loop for salary_mine / laboratory / production_area / final_location |

- Pack: Kenney Sci-Fi Sounds
- License: **CC0** — `assets/audio/licenses/KENNEY_SCI_FI_SOUNDS_LICENSE.txt`
- Ownership: scene-local `LocalAmbiencePlayer` on Ambience bus (not AudioDirector music)

---

## Audio — Footsteps (Kenney / donor steps)

| Project path | Role |
|---|---|
| `assets/audio/sfx/steps/step_1.ogg` | Dance correct (and generic step) |
| `assets/audio/sfx/steps/step_2.ogg` | Reserved step variant |
| `assets/audio/sfx/steps/step_3.ogg` | Reserved step variant |

- Copied/renamed from donor street steps; CC0 Kenney lineage via pack licenses above

---

## License file index

All under `assets/audio/licenses/`:

| File | Covers |
|---|---|
| `MUSIC_LOOP_BUNDLE_LICENSE.txt` | Abstraction music loops |
| `MUSIC_LOOP_BUNDLE_README.txt` | Bundle readme |
| `FINAL_SPARSE_GENERATED_LICENSE.txt` | `final_sparse.wav` CC0 stub |
| `KENNEY_INTERFACE_SOUNDS_LICENSE.txt` | UI SFX |
| `KENNEY_IMPACT_SOUNDS_LICENSE.txt` | Impact SFX |
| `KENNEY_MUSIC_JINGLES_LICENSE.txt` | Result jingles |
| `KENNEY_SCI_FI_SOUNDS_LICENSE.txt` | Factory hum ambience |

---

## Environment — Downtown City MegaKit (Quaternius)

| Project path | Role |
|---|---|
| `assets/environment/city/downtown_megakit/` | City buildings, street props (glTF) |

- Author: Quaternius
- License: **CC0 1.0** — `assets/environment/city/downtown_megakit/LICENSE.txt`
- Vendor: https://quaternius.com
- Copied from read-only donor (identical `res://assets/...` layout)

---

## Environment — House Interior + Drinkware (Quaternius)

| Project path | Role |
|---|---|
| `assets/environment/interior/house_interior/` | Apartment furniture / interior meshes (FBX) |
| `assets/environment/interior/drinkware/` | Glass/cup prop scenes + meshes |

- Author: Quaternius (house_interior pack text)
- License: **CC0 1.0** — `assets/environment/interior/house_interior/LICENSE.txt`
- **Note:** `drinkware/` has no separate LICENSE file in the donor pack; treat as Quaternius interior companion props. Do not invent a second license text.

---

## Environment — Sushi Restaurant Kit (PACK_016)

| Project path | Role |
|---|---|
| `assets/environment/restaurant/sushi_restaurant/` | Cafe donor dependency meshes (glTF) |

- Author: Quaternius
- License: **CC0**
- Official source: https://quaternius.com/packs/sushirestaurantkit.html
- Usage: cafe donor dependency only (location id `cafe`). Do not expand into a separate restaurant location.

---

## Environment — Kenney Factory Kit

| Project path | Role |
|---|---|
| `assets/environment/factory/kenney_factory/` | Factory / industrial kit (GLB) |

- Author: Kenney (www.kenney.nl)
- License: **CC0** — `assets/environment/factory/kenney_factory/LICENSE.txt`

---

## Environment — Sci-Fi Essentials (Quaternius)

| Project path | Role |
|---|---|
| `assets/environment/lab/scifi_essentials/` | Lab / sci-fi props (glTF) |

- Author: Quaternius
- License: **CC0 1.0** — `assets/environment/lab/scifi_essentials/LICENSE.txt`
- Vendor: https://quaternius.com

---

## Props — Ultimate Food Pack (Quaternius)

| Project path | Role |
|---|---|
| `assets/props/food/` | Food / bottle props (FBX) |

- Author: Quaternius
- License: **CC0 1.0** — `assets/props/food/LICENSE.txt`

---

## Integrated art scenes sourced from the legacy project

| Project path | Role |
|---|---|
| `world/locations/city_hub/art/` | Donor `city.tscn` + `scenes/art/city/**` (rewritten paths) |
| `world/locations/apartment/` | Apartment art inlined into the gameplay scene + place-setting script |
| `world/locations/cafe/restaurant_art.tscn` | Donor restaurant scene (filename kept; folder = cafe) |
| `characters/framework/character_anim_controller.gd` | Prefab anim binder (from donor `scenes/art/characters/`) |

- Copied into canonical gameplay paths and editable in place
- Path rewrite: `res://scenes/art/city/` → `res://world/locations/city_hub/art/`
- Assets remain `res://assets/...` (no donor filesystem paths)

---

## Engine / platform — GodotSteam (MODULE 28)

| Item | Pin |
|---|---|
| GodotSteam GDExtension | **4.20.1** |
| Steamworks SDK redistributable | **1.64** |
| Runtime path | `addons/godotsteam/` |
| Pin note | `third_party/godotsteam/README.md` |
| GodotSteam license | **MIT** — `addons/godotsteam/license.md` |
| Steamworks redistributable | Valve / Steamworks terms (**not MIT**) |
| Notices | `release/THIRD_PARTY_NOTICES.txt`, `release/DEPENDENCIES.md` |

Do not use custom GodotSteam engine templates; normal Godot **4.7.1** export templates + this GDExtension.

---

## Policy

- Unknown-provenance files must not ship on release-facing production paths.
- Donor remains read-only audit/copy source; never a runtime path.
- Procedural fallbacks inside `AudioDirector` (tiny WAV for critical missing oneshots) are code-generated at runtime, not shipped as assets.
