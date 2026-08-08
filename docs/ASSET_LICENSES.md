# Asset Licenses

Production external / generated assets with redistribution notes.  
All paths are physical copies inside this repo (`res://` only). **No runtime dependency** on `../date_factory_legacy`.

Character / animation packs: also see `docs/THIRD_PARTY_ASSETS.md` (Quaternius CC0).

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
