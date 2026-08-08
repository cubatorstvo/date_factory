# File ownership — MODULE 17 FIX2 GirlDiscovery prerequisite

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M17FIX2_A | gameplay | `game/girls/girl_discovery.gd`, `game/girls/girl_actor.gd` (only if feedback missing), `game/first_clone/test/first_clone_self_test.gd` and/or `game/girls/test/girl_discovery_self_test.gd` | city_hub, FirstClone formulas, Phone, MODULE 18 | done |

## Product decisions
1. Scientist overload prerequisite is explicit MODULE17 rule in GirlDiscovery — not a Story DSL.
2. STORY_PREREQUISITE is not FAILURE: no cooldown/clue/contact.
3. Keep StageActorAnchor / FirstClone / city anchors unchanged.
4. STOP — no MODULE 18.
