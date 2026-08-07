# File ownership — MODULE 14B Editor & Pre-Media

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M14B_A_SAFETY_PHONE | df-gameplay-worker | ContentDB try_get_*, Phone STAGE4 handoff | bulk content, scenes, MODULE 15 | done |
| M14B_B_CONTENT | df-content-worker | data/content + catalog | scenes, Phone APIs, MODULE 15 | done |
| M14B_C_SCENES | df-scene-worker | appearance_space, city_hub, cafe | catalog, Phone, MODULE 15 | done |
| M14B_D_TESTS_DOCS | df-gameplay-worker | tests + docs + MANUAL_CONTENT_14B | MODULE 15 | done |
| M14B_E_QA | df-qa-worker | evidence only | product sources | done |

## Product decisions (Orchestrator)

1. Anchor names: npc_girl_magazine_editor / npc_rival_magazine_editor.
2. Stage4: try_get_* + Phone media handoff (not Scientist).
3. story_point_editor_photo_session exists, does not launch.
4. Public ordinary NPCs behind PUBLIC_CITY_ACCESS gate.
5. STOP after 14B — no MODULE 15.
