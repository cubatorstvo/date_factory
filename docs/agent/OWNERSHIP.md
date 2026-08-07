# File ownership — MODULE 13 Salary Mine & Money Loop

| Task | Agent | Writable | Read-only deps | Forbidden | Status |
|------|-------|----------|----------------|-----------|--------|
| M13_A_GAMEDAY_SALARY_CORE | df-gameplay-worker | `game/day/**`, `game/salary/**` (service/types/status/result only, no station scene yet), `game/state/game_state.gd` (salary fields/API/reset only), `game/girls/girl_discovery.gd` (GameDay subscribe only), `game/relationships/relationships.gd` (GameDay subscribe only), `project.godot` (autoload order only), `game/salary/test/**` (core tests) | Story, World, PerkIds, ContentDB, Progression | `world/**/*.tscn`, Phone UI, MODULE 14 content, clone economy | done |
| M13_B_SCENES | df-scene-worker | `world/locations/apartment/apartment.tscn` (DayAdvanceInteractable only), `world/locations/salary_mine/salary_mine.tscn` (SalaryStation only), `game/day/day_advance_interactable.gd`, `game/salary/salary_station.gd` (+ optional small local UI for 1.5s cycle) | Interactable, Player ControlMode, GameDay, SalaryMine APIs, markers | `project.godot`, GameState, PhoneJournal, Story unlock thresholds | done |
| M13_C_PHONE_DOCS | df-gameplay-worker | `ui/phone/phone_journal.gd`, `ui/phone/phone_journal.tscn`, `docs/PROJECT_STRUCTURE.md`, `docs/TECHNICAL_DECISIONS.md`, `docs/PERK_EFFECT_CONTRACTS.md`, `docs/gdd/03_core_loop.md`, `docs/gdd/04_male_status_system.md`, extend `game/salary/test/**` for phone/advance UI fixtures if needed | SalaryMine, GameDay, GameState, Story | World location logic, Story stage thresholds, clone fields | done |
| M13_D_QA | df-qa-worker | evidence only under `tmp/` or test logs (no product code) | all | all product sources | done |

## Product decisions (Orchestrator)

1. `notify_game_day_advanced()` stays as the single cooldown decrement implementation; GameDay handlers call it once. Production never calls notify_* except via that subscription.
2. DayAdvanceInteractable lives in apartment only; prompt `[E] Завершить день`; brief MODAL_UI + "День N" overlay 0.5–1.0s.
3. SalaryStation near existing `story_point_salary_station`; no duplicate marker.
4. Phone salary section appended to PhoneJournal when SALARY_MINE unlocked; no new Phone framework.
5. Autoload order exactly per MODULE 13 §8.
