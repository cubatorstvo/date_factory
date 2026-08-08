# ACCEPTANCE — Visual Bootstrap (Donor / Asset Packs)

## Question
Can we replace cube prototypes for city / player room / cafe (donor scenes) and mine / lab / late / characters (audited packs) with local production assets, keep gameplay routes working, and deliver legacy + current screenshot sets without redesigning the game?

## Locked sources (Orchestrator)

| Location | Donor / pack source | Current target |
|---|---|---|
| City | `scenes/world/city/city.tscn` (+ POI) | `world/locations/city_hub/city_hub.tscn` |
| Room | `vertical_slice/apartment.tscn` | `world/locations/apartment/apartment.tscn` |
| Cafe | `vertical_slice/restaurant.tscn` **as cafe** (D-VB-03) | `world/locations/cafe/cafe.tscn` |
| Mine | PACK_002 kenney_factory | `salary_mine` |
| Lab | PACK_015 scifi_essentials (no PACK_013) | `laboratory` |
| Late | PACK_002 + PACK_015 | `production_area` |
| Characters | PACK_021/019/020 + variant wrappers | CharacterActor appearances |

## Definition of Done (TZ §7)

- [x] Donor city transferred, local resources only
- [x] Donor room transferred, local resources only
- [x] Donor cafe transferred **as cafe**
- [x] No runtime dependency on `../date_factory_legacy`
- [x] city / room / cafe load and early routes work
- [x] mine / lab / late are non-cube production bases
- [x] minimal male + female character visual base usable for NPCs
- [x] no critical missing materials/meshes
- [x] critical interaction points still work after transfer
- [x] legacy screenshot set (A1–A3) exists
- [x] current screenshot set (B–F lists) exists
- [x] source on main; review PNGs on temporary `visual-review/*` branch
- [x] final report sections 1–6 delivered
- [x] STOP — no unsolicited art polish pass

## Evidence

- Final report: `docs/agent/qa/VISUAL_BOOTSTRAP_FINAL_REPORT.md`
- Stage G QA: `docs/agent/qa/VISUAL_BOOTSTRAP_STAGE_G_QA.md` — PASS / READY
- Legacy/current PNGs: `tmp/visual_bootstrap_review/` → review branch `_review/visual_bootstrap/`
- Source: `assets/environment/**`, `world/locations/**`, `world/art/donor_import/**`, `characters/female/*_visual.tscn`

## Verdict

**READY**
