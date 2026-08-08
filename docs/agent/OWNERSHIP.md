# File ownership — MODULE 17 First Clone Sequence

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M17_A_CORE | gameplay | `world/actors/stage_actor_anchor.gd`, `game/girls/girl_discovery.gd` (STORY_PREREQUISITE for scientist), `game/first_clone/**`, `project.godot` (FirstClone after DatingOverload), `game/first_clone/test/**` | Phone UI, city_hub/lab .tscn, bulk content, MODULE 18 | done |
| M17_B_CONTENT | content | `data/content/girls/girl_scientist*`, rivals, appearances, discovery, dating scientist pool/events, `content_catalog.tres` | FirstClone formulas, scenes, MODULE 18/President | done |
| M17_C_SCENES | scene | `city_hub.tscn` (scientist anchors), `laboratory.tscn` (machine + markers + blockout) | catalog, Phone, MODULE 18 | done |
| M17_D_PHONE_DOCS | gameplay | `phone_journal.gd`, docs §70 | FirstClone math, MODULE 18 | done |
| M17_E_QA | qa | evidence only | product sources | done |

## Product decisions
1. Scientist anchors: `requires_overload_recognized=true`, STAGE_4, city_hub at laboratory gate.
2. No manual `advance_stage` — Story owns STAGE_4→5.
3. Clone truth = `GameState.set_clone_counts`; no first_clone_created bool; rates stay 0.
4. Calibration: 3 deterministic SPACE passes; miss retries; abort → 0 clones.
5. Assignment WORK 1/1/0 or DATING 1/0/1 exactly once.
6. STOP — no MODULE 18 production/rates.
