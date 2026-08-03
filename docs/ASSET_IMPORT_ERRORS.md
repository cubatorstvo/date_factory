# ASSET_IMPORT_ERRORS

Technical import audit for DATE FACTORY stabilization pass (2026-08-03).

| Metric | Value |
|---|---|
| Packs audited | 9 (001, 002, 015–021) |
| Models sampled (deep load) | 83 |
| Issues logged | 5 (+ historical scale batch) |
| Critical pink/missing materials in samples | 0 |
| Missing `.bin` / broken load in samples | 0 |

## Issues

| Pack | Resource | Path | Type | Cause | Fix | Status |
|---|---|---|---|---|---|---|
| PACK_017 / PACK_018 / PACK_019 humanoid_rigs | FBX unit scale | `assets/**/*.fbx.import` | suspicious_scale | Unity/cm FBX imported with effective ~100× node scale | Set `nodes/root_scale=0.1` + reimport (`apply_root_scale`); Apple AABB ≈ 0.08 m | **FIXED** |
| PACK_019 | UAL retarget | `DF_UAL_Aliases.res` | skeleton_mismatch | Women skeletons (62 bones, Root/Hips) ≠ UAL (65 bones, root/pelvis) | Women use `DF_Women_Aliases.res` from embedded PACK_019 clips; UAL for Hero/Clone | **MITIGATED** |
| PACK_019 | sit/stand aliases | `DF_Women_Aliases.res` | missing_clip_fallback | No `Sitting_*` clips in Modular Women individuals | `sit→Idle_Neutral` (loop), `stand→Idle` (oneshot) | **OPEN_LIMITATION** |
| PACK_015 | lab terminals | `assets/environment/lab/scifi_essentials` | content_gap | Pack is sci-fi combat props; dedicated lab terminals scarce | Desk/locker/drone + blockout in `Clone_Lab_Base` | **OPEN_LIMITATION** |
| PACK_001 | roads/vehicles | `assets/environment/city/downtown_megakit` | content_gap | Audit noted roads/vehicles gaps | Street slice uses blockout + facade kit instances | **OPEN_LIMITATION** |

## Pack sample results (no open load/material errors)

| Pack | Status | Notes |
|---|---|---|
| PACK_001 | OK | glTF city meshes load with materials |
| PACK_002 | OK | Kenney GLB + colormap path previously fixed |
| PACK_015 | OK w/ content gap | Meshes/materials OK |
| PACK_016 | OK | Restaurant glTF OK |
| PACK_017 | OK after scale fix | FBX food props |
| PACK_018 | OK after scale fix | FBX interior props |
| PACK_019 | OK w/ anim limitations | Individuals glTF OK; humanoid_rigs FBX scaled |
| PACK_020 | OK | UAL GLB + project AnimationLibraries |
| PACK_021 | OK | Hero base glTF OK; skeleton matches UAL |

Statuses: `OPEN` unresolved · `MITIGATED` workaround · `OPEN_LIMITATION` accepted for visual pass · `FIXED` corrected this pass.
