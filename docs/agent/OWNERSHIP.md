# File ownership — MODULE 17 FIX Scientist production wiring

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M17FIX_A_GAMEPLAY | gameplay | `world/actors/stage_actor_anchor.gd` (state_reset → refresh), `game/girls/girl_actor.gd` (STORY_PREREQUISITE feedback), `game/first_clone/test/**` (unassisted live spawn tests A–F) | city_hub.tscn, laboratory.tscn, FirstClone formulas, Phone hunt copy, MODULE 18 | done |
| M17FIX_B_SCENES | scene | `world/locations/city_hub/city_hub.tscn` only — place scientist rival then girl before ToLab, 2.5–4 m spacing | stage_actor_anchor.gd, girl_actor, catalog, MODULE 18 | done |
| M17FIX_C_QA | qa | evidence only under `tmp/m17_fix_qa/`, `docs/agent/qa/M17_FIX_QA.md` | product sources | done |

## Product decisions
1. Keep existing FirstClone / Scientist content / Phone STAGE5 — do not rewrite.
2. Overload prerequisite stays explicit on StageActorAnchor + GirlDiscovery (no Story DSL).
3. Live spawn must work from real `DatingOverload.problem_recognized` without scene reload or manual `_refresh_spawn`.
4. STORY_PREREQUISITE feedback: «Сначала нужно понять, зачем тебе вообще второй ты.»
5. STOP — no MODULE 18.
