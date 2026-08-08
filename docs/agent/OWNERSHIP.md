# File ownership — MODULE 21 Final Date Sequence

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M21_A_CONTENT | content | `girl_final_target`, 2 exhibition rivals, 3 appearances, `content_catalog.tres`, ContentDB narrow validation if needed, count asserts | DatingCore, scenes, rival runner | done |
| M21_B_EXHIBITION | gameplay | `game/rivals/rival_competition_runner.gd` (+ types if needed), rival self-tests | final_location.tscn, DatingCore rewrite | done |
| M21_C_FINAL | gameplay | `game/final_date/**` (controller, interactables, UI, types, tests), narrow Relationships only if needed, `phone_journal.gd` FINALE branches | final_location.tscn (scene worker), expanding DatingEventDefinition, normal rival Authority | done |
| M21_D_SCENE | scene | `world/locations/final_location/final_location.tscn` only — 3 zones, gates, markers, wire FinalSignalInteractable | city_hub, production_area, catalog | done |
| M21_E_DOCS | content | PROJECT_STRUCTURE, TECHNICAL_DECISIONS, gdd 07/08 | runtime | done |
| M21_F_QA | qa | `tmp/m21_qa/**`, `docs/agent/qa/M21_QA.md` | product sources | done |

## Product decisions
1. Final date is staged sequence owned by FinalDateController — not DatingCore planner.
2. Exhibition competitions: Slap/Dance without Authority / mark_rival_defeated.
3. Success: relationship 5 + conquered + +1 XP once; stage stays FINALE.
4. Fail: comedy modal, full retry, no permanent penalty.
5. Functional ending screen + Continue → playable world; no full credits.
6. STOP — no MODULE 22 polish / alternate endings / alien world systems.
