# PROXY POC REPORT

**Status: NOT READY**

T-rest geometry bake landed (arms follow T-rest bones), but residual sleeve/armpit crease and Godot sit framing still block READY.

## Selection

| Slot | Proxy object |
|---|---|
| Body | `Base Model` |
| Hair | `Pixie Cut` |
| Top | `Scallop Trim T-Shirt` |
| Bottom | `Baggy Cargo Pants` |
| Shoes | `Running Shoes` |

## Artifacts

| Artifact | Path |
|---|---|
| Working blend (T-rest) | `C:\Users\User\Downloads\date_factory_proxy_work\ProxyGirl_POC_TRest_Working.blend` |
| Export GLB (separate) | `C:\Users\User\Downloads\date_factory_proxy_work\GirlProxyPOC_TRest.glb` |
| Godot GLB | `res://assets/characters/girls/proxy_poc/GirlProxyPOC_TRest.glb` |
| Godot prefab | `res://assets/characters/girls/proxy_poc/GirlProxyPOC_TRest.tscn` |
| Godot testbed | `res://scenes/art/testbeds/ProxyGirlPOC_TRest_Testbed.tscn` |
| Old A-rest POC (unchanged) | `GirlProxyPOC.glb` / `GirlProxyPOC.tscn` |
| Proofs | `C:\Users\User\Downloads\date_factory_proxy_work\trest_fix\` |

Live `DATE_GIRL_SCENE` / `DateGirl_UAL` was **not** replaced.

## Root cause (confirmed)

- Proxy body/clothes authored in **A-pose**
- `UAL_MasterArmature` rest is **T-pose**
- Old pipeline transferred weights in temporary A-pose but **never baked** meshes to T
- Result: rest bones horizontal, mesh arms down → shoulder/armpit/sleeve pinch

## Diagnosis

| Metric | Before (`ProxyGirl_POC_Working`) | After (`ProxyGirl_POC_TRest_Working`) |
|---|---|---|
| Bone upperarm dir | ≈ ±X (T) | ≈ ±X (T, unchanged master) |
| Mesh arm dir | angled down (~35° mismatch) | near horizontal (~13° residual) |
| Verdict | `FAIL_A_MESH_ON_T_REST` | improved; residual crease remains |

Proofs: `trest_fix/before_rest_pose_front.png`, `after_rest_pose_{front,side,wire}.png`

## Fix pipeline used

`tools/characters/proxy_pipeline/fix_proxy_poc_trest.py`

1. Copy master → temporary `UAL_TransferArmature` (never mutate master rest)
2. Aim transfer arms to Proxy A-pose (shoulder→elbow→wrist)
3. Overlay: `transfer_a_pose_overlay.png`
4. **Apply Pose as Rest on TRANSFER only** → A becomes bind/rest
5. Auto-weight ProxyBody against transfer A-rest; Data Transfer to Top/Bottom
6. **LBS bake** A-rest bone spaces → master T-rest bone spaces (geometry rewrite)
7. Bind baked meshes to clean `UAL_MasterArmature`
8. Hair: rigid `Head` weights (no A→T)
9. Export `GirlProxyPOC_TRest.glb` (separate from old POC)

Canonical stage (also in `PROXY_PIPELINE.md`):

**A-pose garment → skin in matching A-pose → deform to T-pose → bake geometry → bind to clean T-rest armature**

## Animation status (Blender proofs)

| Alias | Clip | T-rest proof |
|---|---|---|
| idle | Idle_Loop | `fixed_01_idle_front.png` |
| walk | Walk_Loop | `fixed_02_walk_front.png`, `fixed_03_walk_side.png` |
| sit_enter | Sitting_Enter | `fixed_04_sit_enter_side.png` |
| sit_idle | Sitting_Idle_Loop | `fixed_05_sit_idle_side.png` |
| seated_gesture | Sitting_Talking_Loop | `fixed_06_seated_gesture_front.png` |
| sit_exit | Sitting_Exit | `fixed_07_sit_exit_side.png` |
| run | Sprint_Loop | present on armature; not re-shot in this fix pack |

## Godot (separate TRest version)

- Prefab instances `GirlProxyPOC_TRest.glb` + shared `DF_UAL_Aliases.res`
- Capture: `res://tools/capture_proxy_girl_poc_trest.gd`
- Aliases `idle` / `walk` / `sit_idle` / `seated_gesture` returned `play_alias → true`
- Shots: `godot_fixed_01..04` under `trest_fix/`
- Idle/rest front shows horizontal T arms (main mismatch fixed in-engine)

## Remaining blockers (why still NOT READY)

1. Residual ~13° arm/mesh mismatch and short-sleeve armpit crease (strong A-on-T pinch is gone, mild crease remains)
2. Godot sit-side capture framing/chair intersection still needs a cleaner pass
3. Shoes/ankles still low-poly faceted
4. Hair/materials remain simple albedo POC
5. Do not mass-process wardrobe until READY

## What works

- Master UAL T-rest / hierarchy / bone names untouched
- Canonical T-pose body + clothes geometry bake path implemented
- Separate TRest GLB/prefab; old POC left in place
- Seven UAL aliases available on export; Blender sit/walk proofs regenerated
