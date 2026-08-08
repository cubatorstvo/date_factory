# Third-party assets

Assets copied into this repository for Character Framework (Module 04) and VISUAL BOOTSTRAP expansion.  
All listed packs are **CC0 1.0** (Public Domain) by **Quaternius** (`https://quaternius.com`) unless noted.  
File trees were mirrored from the read-only donor (branch `legacy-v1`; see `docs/README.md`).  
Runtime paths are local `res://` only — no dependency on any external project folder.

---

## hero_base (Universal Base Characters Kit)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal — see `assets/characters/hero_base/LICENSE.txt` |
| Vendor | https://quaternius.com |
| Copied from donor | `assets/characters/hero_base/` (full pack closure) |

### Copied paths (summary)

| Path | Role |
|---|---|
| `assets/characters/hero_base/LICENSE.txt` | License + attribution |
| `assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf` (+ bin/textures) | Male base mesh |
| `assets/characters/hero_base/meshes/bodies/Superhero_Female_FullBody.gltf` (+ textures) | Female base mesh |
| `assets/characters/hero_base/meshes/hairstyles/` | Hairstyle / eyebrow glTF set |
| `assets/characters/hero_base/prefabs/Hero.tscn` | Hero prefab |
| `assets/characters/hero_base/prefabs/Clone.tscn` | Clone prefab |
| `assets/characters/hero_base/prefabs/DateGirl_UAL.tscn` | Date-girl UAL prefab |

Prefab scripts point at `res://world/art/donor_import/characters/character_anim_controller.gd`.

---

## women_modular (Ultimate Modular Women)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal — see `assets/characters/women_modular/LICENSE.txt` |
| Vendor | https://quaternius.com / Patreon linked in LICENSE |
| Copied from donor | `assets/characters/women_modular/` (full pack closure) |

### Copied paths (summary)

| Path | Role |
|---|---|
| `assets/characters/women_modular/LICENSE.txt` | License + attribution |
| `assets/characters/women_modular/meshes/individuals/*.gltf` | Casual + other individual variants |
| `assets/characters/women_modular/meshes/humanoid_rigs/*.fbx` | Modular humanoid rigs |
| `assets/characters/women_modular/prefabs/Girl_Casual.tscn` | Primary Casual prefab |
| `assets/characters/women_modular/prefabs/Girl_Formal.tscn` | Formal prefab |
| `assets/characters/women_modular/prefabs/Girl_Worker.tscn` | Worker prefab |
| `assets/characters/women_modular/prefabs/Manager_Suit.tscn` | Suit prefab |

---

## universal_library (UAL animation library)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal — see `assets/animation/universal_library/LICENSE.txt` |
| Vendor | https://quaternius.com |
| Copied from donor | `assets/animation/universal_library/` (standard + RM + DF aliases) |

### Copied paths

| Path | Role |
|---|---|
| `assets/animation/universal_library/LICENSE.txt` | License + attribution |
| `assets/animation/universal_library/source/UAL1_Standard.glb` | Source animation library |
| `assets/animation/universal_library/source/UAL1_Standard_RM.glb` | Root-motion variant |
| `assets/animation/universal_library/libraries/UAL_CLIP_MAP.json` | Clip map / path index |
| `assets/animation/universal_library/libraries/DF_UAL_Aliases.res` | DF AnimationLibrary aliases (UAL) |
| `assets/animation/universal_library/libraries/DF_Women_Aliases.res` | DF AnimationLibrary aliases (women) |
| `assets/animation/universal_library/retargeted/DF_Women_Seated.res` | Retargeted seated clips |
| `assets/animation/universal_library/retargeted/DF_UAL_BoneMap.tres` | Male SkeletonProfileHumanoid BoneMap |
| `assets/animation/universal_library/retargeted/DF_Women_BoneMap.tres` | Female SkeletonProfileHumanoid BoneMap |
| `assets/animation/universal_library/source/*_Setup.png` | Vendor setup reference images |

---

## License summary

```text
CC0 1.0 Universal (CC0 1.0)
Public Domain Dedication
https://creativecommons.org/publicdomain/zero/1.0/
```

Models by Quaternius — consider supporting: https://www.patreon.com/quaternius

Environment / prop packs and sushi LICENSE gap: see `docs/ASSET_LICENSES.md`.
