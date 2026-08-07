# Third-party assets

Assets copied into this repository for Character Framework (Module 04).  
All listed packs are **CC0 1.0** (Public Domain) by **Quaternius** (`https://quaternius.com`).  
File trees were mirrored from the read-only donor (branch `legacy-v1`; see `docs/README.md`).  
Runtime paths are local `res://` only вЂ” no dependency on any external project folder.

---

## hero_base (Universal Base Characters Kit вЂ” male body)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal вЂ” see `assets/characters/hero_base/LICENSE.txt` |
| Vendor | https://quaternius.com |
| Copied from donor | `assets/characters/hero_base/` (minimal male import closure) |

### Copied paths

| Path | Role |
|---|---|
| `assets/characters/hero_base/LICENSE.txt` | License + attribution |
| `assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf` | Male base mesh (glTF) |
| `assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.bin` | Binary buffer |
| `assets/characters/hero_base/meshes/bodies/T_Superhero_Male_Dark.png` | Base color (referenced by glTF) |
| `assets/characters/hero_base/meshes/bodies/T_Superhero_Male_Normal.png` | Normal |
| `assets/characters/hero_base/meshes/bodies/T_Superhero_Male_Roughness.png` | Roughness |
| `assets/characters/hero_base/meshes/bodies/T_Eye_Brown.png` | Eye albedo |
| `assets/characters/hero_base/meshes/bodies/T_Eye_Normal_png.png` | Eye normal |
| `assets/characters/hero_base/meshes/bodies/T_Hair_1_BaseColor.png` | Hair albedo (embedded hair mesh) |
| `assets/characters/hero_base/meshes/bodies/T_Hair_1_Normal_png.png` | Hair normal |

**Note:** Donor layout uses `meshes/bodies/` (not `models/`). Textures are co-located with the glTF (URI siblings). Hairstyles pack, female body, and Godot `.import` sidecars were not copied.

---

## women_modular (Casual individual)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal вЂ” see `assets/characters/women_modular/LICENSE.txt` |
| Vendor | https://quaternius.com / Patreon linked in LICENSE |
| Copied from donor | `assets/characters/women_modular/` (Casual only) |

### Copied paths

| Path | Role |
|---|---|
| `assets/characters/women_modular/LICENSE.txt` | License + attribution |
| `assets/characters/women_modular/meshes/individuals/Casual.gltf` | Self-contained Casual character (embedded buffers/images) |

**Note:** Donor layout uses `meshes/individuals/` (not `models/individuals/`). Formal/Worker/Suit and prefab scenes (`Girl_*.tscn`, `Manager_Suit.tscn`) were not copied.

---

## universal_library (UAL animation library)

| Field | Value |
|---|---|
| Author | Quaternius (@Quaternius) |
| License | CC0 1.0 Universal вЂ” see `assets/animation/universal_library/LICENSE.txt` |
| Vendor | https://quaternius.com |
| Copied from donor | `assets/animation/universal_library/` (standard pack + DF aliases) |

### Copied paths

| Path | Role |
|---|---|
| `assets/animation/universal_library/LICENSE.txt` | License + attribution |
| `assets/animation/universal_library/source/UAL1_Standard.glb` | Source animation library (not root-motion RM) |
| `assets/animation/universal_library/libraries/UAL_CLIP_MAP.json` | Clip map / path index |
| `assets/animation/universal_library/libraries/DF_UAL_Aliases.res` | DF AnimationLibrary aliases (UAL) |
| `assets/animation/universal_library/libraries/DF_Women_Aliases.res` | DF AnimationLibrary aliases (women) |
| `assets/animation/universal_library/retargeted/DF_Women_Seated.res` | Retargeted seated clips |

**Also copied for MODULE 04 retarget:**
| `assets/animation/universal_library/retargeted/DF_UAL_BoneMap.tres` | Male SkeletonProfileHumanoid BoneMap |
| `assets/animation/universal_library/retargeted/DF_Women_BoneMap.tres` | Female SkeletonProfileHumanoid BoneMap |

**Not copied:** `UAL1_Standard_RM.glb` (root-motion pack), Setup PNGs / vendor docs.

---

## License summary

```text
CC0 1.0 Universal (CC0 1.0)
Public Domain Dedication
https://creativecommons.org/publicdomain/zero/1.0/
```

Models by Quaternius вЂ” consider supporting: https://www.patreon.com/quaternius

