# ACCEPTANCE — Visual Bootstrap Corrective + Single-Base Characters

## Question
Can we restore donor lighting parity, replace interactive/debug placeholders with real assets (no floating Areas), move all NPCs to ONE male + ONE female PACK_021 base with modular placeholders, remove PACK_019, update PACK_016 license docs, pass RC tests, and deliver a new screenshot review — without redesigning layouts or systems?

## Locked decisions
- D-VC-01 … D-VC-05 in `docs/agent/DECISIONS.md`
- Male: `Superhero_Male_FullBody.gltf`
- Female: `Superhero_Female_FullBody.gltf`
- Cafe stays location id `cafe`
- Donor `../date_factory_legacy` READ-ONLY

## Definition of Done (TZ §§1–20)

- [x] City donor light/env restored; red trim/emissive artifacts addressed vs donor
- [x] City interactive placeholders → real assets + Areas attached
- [x] Apartment debug labels gone; Day/Date/SelfAssessment/flavor bound to real objects
- [x] Apartment donor lighting baseline restored
- [x] Cafe donor lighting; interactions not floating; PACK_019 NPC stripped from art
- [x] Mine / lab / late placeholders skinned or replaced; no floating Areas; lab camera obstruction fixed
- [x] Exactly 1 male + 1 female production base
- [x] Modular variants: hair 5 + colors 5, top 4, bottom 3, shoes 2, head 3, neck 2+none, hand 2+none
- [x] CharacterVariantController presentation-only; deterministic appearance profiles
- [x] PACK_019 source removed; runtime refs 0
- [x] PACK_016 license docs updated (not unknown)
- [x] Character presentation test + RC suite
- [x] donor runtime refs 0
- [x] Source on main; screenshots on `visual-review/corrective-20260809`
- [x] Final report sections 1–11; then STOP

## Evidence

- Final report: `docs/agent/qa/VISUAL_BOOTSTRAP_CORRECTIVE_FINAL_REPORT.md`
- Independent QA: `docs/agent/qa/VISUAL_BOOTSTRAP_CORRECTIVE_QA.md` (on review branch; READY after attach fix)
- Screenshots: `_review/visual_corrective/` (31 PNGs) on `visual-review/corrective-20260809` @ `05c2f0a`
- Source main: `d9fa832` + `b59c3c9`

## Verdict

**READY**
