# PROXY PIPELINE — add the next outfit piece

Reproducible path for one additional clothing item after the GirlProxyPOC baseline.

## Prerequisites

- Blender: `C:\Program Files (x86)\Steam\steamapps\common\Blender\blender.exe`
- Proxy source (read-only): `C:\Users\User\Downloads\assets\proxy_1.5.blend`
- Work dir: `C:\Users\User\Downloads\date_factory_proxy_work`
- Donor / UAL already audited (`UAL_DONOR_AUDIT.md`)
- Do **not** batch the wardrobe until one character is READY

## Scripts

`tools/characters/proxy_pipeline/`

1. `audit_proxy.py` — inventory + contact sheets
2. `build_proxy_poc.py` — legacy fit/weights (A-pose weight transfer only; incomplete)
3. `fix_proxy_poc_trest.py` — **canonical T-rest bake** for the POC
4. `diagnose_proxy_rest.py` — bone vs mesh arm angle at Rest Position
5. `validate_proxy_poc.py` — structural GLB checks
6. `render_proxy_poc.py` — animation proof frames

## Canonical rest-pose stage (required)

Proxy garments are authored in **A-pose**. UAL master rest is **T-pose**. Weights alone are not enough.

**A-pose garment → skin in matching A-pose → deform to T-pose → bake geometry → bind to clean T-rest armature.**

Concrete steps:

1. Duplicate master to temporary `UAL_TransferArmature` (do not edit master rest/hierarchy).
2. Pose transfer to match Proxy A-pose (clavicle/upperarm primarily; aim to elbow/wrist).
3. **Apply Pose as Rest on the transfer armature only** so bind/rest matches A-mesh.
4. Skin ProxyBody (auto-weights or donor transfer) while A-rest matches A-mesh; transfer to clothes.
5. Deform to T (pose transfer toward master T **or** LBS rewrite using master T bone matrices).
6. **Bake** the posed/LBS result into mesh datablocks (new T-pose geometry).
7. Delete transfer armature; bind baked meshes to unmodified `UAL_MasterArmature`.
8. Hair (Pixie): rigid/near-rigid `Head` weights — no A→T bake required.
9. Verify Rest Position: bones T **and** mesh arms T; fail if bones T / mesh still A.

## Add one clothing item

1. Pick object name from `proxy_inventory.json` / `POC_SELECTION.md` style criteria.
2. Append only that object into the working blend (same scale as body set).
3. Apply Mirror; remove Solidify for clean shells.
4. Shrinkwrap to `ProxyBody` with small offset + max distance.
5. Run the **canonical rest-pose stage** above for body+item (or propagate body A→T deltas to the item, then weight on T).
6. Normalize All → Clean → Limit Total 4; drop unknown groups.
7. Armature modifier → `UAL_MasterArmature` only (Object parent, never Armature parent).
8. Assign `MAT_Outfit_*` / `MAT_Shoes` / `MAT_Accessory`.
9. Re-render rest + sit + walk proofs; fail closed on A-mesh / T-bones mismatch.
10. Re-export GLB with dedupe pass (one armature, Proxy* meshes only).
11. Reimport in Godot as a **new** prefab version; keep AnimationLibrary as shared `DF_UAL_Aliases.res`.

## Hard rules

- Never rename bones / change hierarchy / alter UAL master rest pose
- Never Apply Pose as Rest on `UAL_MasterArmature`
- Never scale individual bones to match Proxy
- Never create per-clothing Skeleton3D
- Never retarget UAL onto PACK_019
- Prefer fitting Proxy mesh to donor, not donor to Proxy
- Never leave export collections with transfer armature, donor body, or old A-pose copies

## Godot packaging tip

When packing a prefab that instances the GLB, set `owner` only on the instance root. Recursive owner assignment duplicates Skeleton/meshes inside the `.tscn`.
