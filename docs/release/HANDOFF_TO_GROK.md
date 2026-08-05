# DATE FACTORY — handoff to Grok workers

## Current state

- Branch: `release/rc-hardening`.
- Engine: Godot 4.7.1 at `C:\godot\Godot_v4.7.1-stable_win64.exe`.
- Status: `NOT READY`.
- Scope/audits/decisions/masterplan/final plan are complete.
- Main Orchestrator chat has stopped technical implementation.
- Do not reset/delete inherited uncommitted QA full-access or proxy POC work.

Read first:

1. `docs/release/RELEASE_HARDENING_PLAN.md`
2. `docs/release/RELEASE_BASELINE_AUDIT.md`
3. `docs/release/BUG_BACKLOG.md`
4. `docs/release/CITY_MASTERPLAN.md`
5. `docs/agent/DECISIONS.md`
6. `docs/agent/OWNERSHIP.md`
7. `docs/agent/ACCEPTANCE.md`

## Important partial state

- `boot.gd`: normal Continue implementation is technically passing; independent player-flow QA remains.
- `girls_api.gd`, `city_api.gd`, `date_places.gd`: interrupted partial progression diff; parses, but correctness is not accepted.
- `tests/release/**`: interrupted foundation; 25-step smoke PASS, full mode not accepted.
- Never treat partial code or smoke existence as release completion.

## First assignment — RC-01-PARTIAL-REVIEW

Agent: `df-gameplay-worker`.

Goal:

- review and finish the partial critical gameplay/test work;
- restore normal-save Continue;
- provide production discover/contact/date paths for every existing non-algorithm unique;
- preserve existing stage_6/Algorithm finale gates;
- correct arcade reservation identity;
- finish honest smoke/full runners without direct `mark_met`.

Writable:

- `scenes/boot/boot.gd`
- `modules/girls/girls_api.gd`
- `modules/city/city_api.gd`
- `modules/dating/date_places.gd`
- `tests/release/**`
- `docs/release/AUTOTEST_RUNBOOK.md`
- `docs/release/FULL_PLAYTHROUGH_CHECKLIST.md`

Forbidden:

- save schema, Game/autoload, city scene, UI/assets/project.godot;
- new girls/POI/stages/districts;
- softer finale;
- player-facing debug/QA route;
- direct test `mark_met` used to fake progression.

Required PASS:

- parse/validate each touched script;
- New Game stage_1;
- no-save Continue disabled;
- normal Continue restores slot 1 and does not touch QA slot;
- all 11 existing non-algorithm uniques have documented production routes;
- Algorithm remains finale-only;
- smoke PASS;
- full runner auto-quits and returns honest non-zero FAIL or real PASS;
- raw Godot logs and concise reports saved.

After implementation run `RC-01-QA` with `df-qa-worker`. Do not start city work before independent PASS.

## Remaining stages

### RC-02 — Assets/licenses
- `df-asset-worker`: exact minimal assets/prefabs for all current facades, rooms and street activities; one format, scale/material/collision/source/license evidence.
- `df-content-worker`: credits, Sushi/font/drinkware provenance.
- No whole-pack imports or new POI.

### RC-03 — Live city
- `df-scene-worker`: one writer for `city.tscn`; implement compact zones/two loops/facades/activity props/top-down evidence.
- Then `df-gameplay-worker`: bind existing interactions/outlines/anchors in `complex_world.gd` and router.
- Then independent city QA.

### RC-04 — Lighting/rooms
- `df-scene-worker`: one authoritative environment and readable city lighting.
- Separate non-overlapping scene tasks for apartment regression, restaurant, lab, themed apartments and progression rooms.
- No visible blockout, void or new travel architecture.

### RC-05 — UI/finale
- One theme owner: current UI framework only; replace placeholders/mixed strings; verify 720p/1080p/1440p.
- Gameplay worker: existing Algorithm finale summary + free play/menu; postgame save/load.

### RC-06 — Tests/export/release QA
- Finish full deterministic regression.
- Add reproducible Windows export preset/scripts/docs.
- Test exported build outside editor.
- `df-qa-worker`: clean-save full playthrough and independent release report.

## Worker contract

Every task returns:

1. summary;
2. changed files;
3. actual normal player flow verified;
4. commands;
5. raw engine logs;
6. screenshots opened and described when visual;
7. limitations/unmet criteria;
8. PASS/FAIL.

Headless by default. Windowed runs only after technical checks, as one planned capture route, then close immediately.

## Final gate

Only the Orchestrator may change status to `READY`. Any broken normal route, save loss, missing critical asset, persistent runtime error, failed full regression/export, or absent independent QA means `NOT READY`.
