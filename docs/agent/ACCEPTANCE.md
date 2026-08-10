# ACCEPTANCE — Visual Art Pass 01

## Question
Can we replace primitive hair with PACK_021 hairstyles, fix temporary clothing/shoes/accessories to read as clothing (not debug cubes), replace city POI proxy shells with ready MegaKit buildings, and limit city/cafe background NPC presentation — without undoing corrective lighting/anchors or redesigning layouts?

## DoD (TZ)

- [x] Primitive hair removed; exact male/female 0–4 mapping; real glTF paths
- [x] Clothing silhouettes resized; both shoes; accessories cleaned; walk chest attach
- [x] Character review fixture (clean bases + variants + side + walk)
- [x] City POI audit + replacements; LotBounds production visible=0
- [x] City spawn exclusion 2.5m; cafe ordinary ≤4; date exclusion 2.2m
- [x] Apartment/mine/lab/late: regression only (no art)
- [x] Automated checks + RC suite
- [x] Source on main; review branch `visual-review/art-pass-01-20260809`
- [x] Final report sections; STOP

## Evidence

- Final: `docs/agent/qa/VISUAL_ART_PASS_01_FINAL_REPORT.md`
- QA: `docs/agent/qa/VISUAL_ART_PASS_01_QA.md` (review branch) — READY
- Main: `7ee5fde` · Review: `04cac77`

## Verdict

**READY**

---

# PLAYER EXPERIENCE PASS 01 — Acceptance

## Player-visible question

Can a source-blind, first-time player start a clean New Game, learn movement/look/interact, understand the current purpose, navigate the apartment's physical space, discover Neighbor, and start the normal first prologue interaction without developer knowledge?

## DoD

- [x] Clean isolated `user://`, default settings, 1920×1080, UI 100%, Main Menu → New Game baseline evidence
- [x] Persona A and Persona B source-blind before-fix journals, screenshots, and raw Godot process output
- [x] Fresh movement/look/interact teaching visible and retained until meaningful player evidence
- [x] Persistent HUD objective uses canonical Story/Phone data without second story state
- [x] Semantic, in-range, forward-facing interaction prompts for required early objects
- [x] Spawn has no capsule/camera overlap and at least 1.5 m of clear forward room context
- [x] Essential apartment furniture, walls, openings, and exit physically match their visible geometry
- [x] Neighbor is visible/reachable/interactable through the normal prologue flow; city exit reports its intentional story lock clearly
- [x] Focused automated regression, project validation/error checks, save/load coverage, donor refs 0, PACK019 refs 0, save schema unchanged
- [x] Persona C and Persona D fresh source-blind after-fix evidence meets timing/route targets
- [x] Independent `df-qa-worker` report and opened gameplay screenshots; source commit on main and review artifacts on `visual-review/player-experience-01-<date>`

## Known pre-existing regression

The PE01 RC run is **34/35**. `world_location` fails unchanged from baseline `86cb0f9` because Art Pass 01 cleared City/Cafe `NpcSpawnPoint.spawn_id` / actor content IDs. PE01 does not modify those scenes; the issue does not affect apartment → Neighbor prologue, but can block ordinary City/Cafe NPC binding after Stage 1. It remains outside PE01 ownership and prevents claiming a fully green RC suite.

## Verdict

**READY** — PE01 critical route. The independent QA report is published with review artifacts; the unrelated City/Cafe RC debt remains explicitly tracked above.

---

# ADAPTIVE SCENE UI — Acceptance

## Player-visible question

Can every production UI surface be adjusted in the Godot scene editor and remain readable, centered, reachable, and unclipped from 1280×720 through 3840×2160 on 16:9, 16:10, and 21:9 displays?

## DoD

- [x] Every production screen/popup/overlay has a `.tscn`; repeated runtime cards/rows use reusable PackedScenes
- [x] Production UI controllers contain no programmatic presentation-tree construction
- [x] Fullscreen roots are never geometrically scaled for the 100/125/150% setting
- [x] Long content wraps or scrolls; safe margins remain inside the viewport
- [x] Resolution matrix and accessibility worst cases pass layout audit
- [x] Normal title, gameplay HUD/Phone, modal, minigame, save/settings routes still work
- [x] Focused suites and RC gate pass; engine logs and screenshots are inspected
- [x] Save schema and gameplay rules remain unchanged
- [ ] User playtest accepts the result

## Evidence

- Scene contract: `UI_SCENE_CONTRACT: ALL PASS (366)`
- Layout matrix: `_review/visual_playtest/adaptive_scene_ui_layout_final/` — 33 shots, 0 errors, 0 warnings
- Full gallery: `_review/visual_playtest/adaptive_scene_ui_gallery_matrix/` — 520 shots, 0 errors, 0 warnings
- Normal route: `_review/visual_playtest/adaptive_scene_ui_playthrough/` — 22/22 checkpoints, 0 unmet, 0 errors, 0 warnings
- Full-game integration: 157 PASS; release integration: 21 PASS

## Verdict

**READY FOR USER PLAYTEST** — implementation, automated gates, runtime logs, and visual matrices pass; final user acceptance remains pending.
