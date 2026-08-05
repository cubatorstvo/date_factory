# Release bug backlog

Status values: `OPEN`, `ACTIVE`, `FIXED`, `VERIFIED`, `DEFERRED-BLOCKS-RELEASE`.

## Blocker

### RC-B001 — Continue loads QA cheat profile
- Repro: launch → «Продолжить».
- Route: boot/save/load.
- Baseline evidence: `boot.gd` called `load_full_access_qa_profile()`.
- Fix evidence: Continue now checks `Game.save.has_save()` and calls `Game.load_game()`; headless QA-only/no-normal probe leaves button disabled.
- Owner: gameplay.
- Status: FIXED_PENDING_INDEPENDENT_QA.
- Regression: create normal save, restart, Continue restores it; no-save Continue disabled; QA slot unchanged.

### RC-B002 — Normal progression cannot meet all finale-required girls
- Repro: New Game → advance stages → seek business/fashionista/lawyer/scientist/star/alien.
- Route: city/girls/clones/finale.
- Evidence: empty `try_unlock_by_progress()` and roster anchors for only four uniques.
- Owner: gameplay.
- Status: OPEN.
- Regression: deterministic production API test reaches every meet path without `mark_met`.

## Critical

### RC-C001 — Full normal-route regression does not exist
- Repro: legacy `tools/smoke_test.gd` reaches finale by forcing contacts/`mark_met`.
- Route: entire game.
- Owner: gameplay/test infrastructure.
- Status: CLOSED_IN_TESTS; `tests/release` smoke + full runners use production APIs (no runner `mark_met`), write report/log, exit non-zero on FAIL. Visual playthrough still manual.
- Regression: `tests/release/run_release_tests.ps1 -Mode smoke|full`.

### RC-C002 — Windows release build cannot be produced reproducibly
- Repro: run export; `export_presets.cfg` absent.
- Route: packaging.
- Owner: release.
- Status: OPEN.
- Regression: headless Windows export + external smoke + save/load.

## Major

### RC-M001 — City is a linear corridor without compact route loops
- Evidence: live topology main street → ParkGate → leisure → AgencyGate → agency.
- Owner: city scene.
- Status: OPEN.
- Regression: top-down evidence and walkable loop checklist.

### RC-M002 — Street activities have hidden/missing physical staging
- Includes benches, ducks, karaoke, corner shop, internet cafe, bar and bus props.
- Owner: city scene/assets + interaction binding.
- Status: OPEN.
- Regression: visible mesh and prompt within the same parent object; repeated-use capture.

### RC-M003 — Park restaurant facade is missing
- Evidence: `ParkRestaurant` CSG size `(0,0,0)`.
- Owner: city scene.
- Status: OPEN.
- Regression: non-zero facade AABB, entrance screenshot and sit route.

### RC-M004 — Outdoor lighting is too dark and plum-tinted
- Evidence: city environment/key stripped; global sun energy 0.28 and purple ambient.
- Owner: lighting scene.
- Status: OPEN.
- Regression: screenshots for all zones and single-environment audit.

### RC-M005 — POI interaction/outline is detached from facade art
- Evidence: city FocusProxy volumes; apartment-only facade binding.
- Owner: gameplay integration.
- Status: OPEN.
- Regression: move parent facade and verify visual/collision/interaction/outline move together.

### RC-M006 — Expansion rooms and themed apartments are visible greyboxes
- Route: stages 2–6 and themed apartment dates.
- Owner: scenes/assets.
- Status: OPEN.
- Regression: normal-route screenshot per room; no visible default blockout.

### RC-M007 — Arcade date reserves cheap-cafe venue
- Evidence: arcade place uses `venue_id = cheap_cafe`.
- Owner: dating gameplay.
- Status: OPEN.
- Regression: simultaneous reservation test.

### RC-M008 — Finale presentation/postgame choice is incomplete
- Route: Algorithm date completion.
- Owner: gameplay/UI/content.
- Status: OPEN.
- Regression: summary visible; free-play and menu choices; postgame save/load.

### RC-M009 — Gift UI uses placeholder icons
- Owner: assets/UI.
- Status: OPEN.
- Regression: no release-visible path under `assets/ui/gifts/placeholders`.

### RC-M010 — UI consistency/resolution behavior is unverified
- Risks: mixed English seeds, fixed sizes, unset stretch aspect, modal focus.
- Owner: UI/gameplay.
- Status: OPEN.
- Regression: 1280×720, 1920×1080 and 2560×1440 screenshot/input matrix.

### RC-M011 — Credits and license registry are incomplete
- Missing: project-side Sushi source/license record, font licenses, pack credits; drinkware provenance unresolved.
- Owner: assets/release/content.
- Status: OPEN.
- Regression: build manifest references every shipped third-party pack.

### RC-M012 — QA/testbed assets may enter release build
- Evidence: untracked proxy POC and diagnostic tools; no export inclusion policy.
- Owner: release/assets.
- Status: OPEN.
- Regression: exported PCK manifest excludes testbeds, captures, source and diagnostics.

### RC-M013 — Flower purchase has duplicate canonical paths
- Evidence: facade shop UI and hidden discounted corner interaction.
- Owner: city/gameplay.
- Status: OPEN.
- Regression: one player-visible flower purchase flow.

### RC-M014 — No rendered baseline for city/POI/UI
- Owner: QA.
- Status: OPEN.
- Regression: named evidence pack inspected by Orchestrator.

## Minor / triage

- RC-m001: 103 convention warnings; fix only touched/release-risk files.
- RC-m002: orphan signals require use/remove triage, not blind deletion.
- RC-m003: QA profile byte hash varies due to volatile fields.
- RC-m004: legacy `street.tscn` is unused and can confuse maintenance/export.
- RC-m005: city time does not visually drive sun; defer only if current fixed lighting is coherent.
- RC-m006: fixed waypoint NPC navigation; acceptable if final city collision test passes.

## Baseline counts

- Blocker: 2
- Critical: 2
- Major: 14
- Minor/triage: 6

Counts change only after independent verification, not after code existence.
