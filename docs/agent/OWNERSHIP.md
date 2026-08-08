# File ownership — MODULE 18 Clone Incremental Core

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M18_A_CORE | gameplay | `game/clone_incremental/**` (new), `game/state/game_state.gd`, `game/state/test/**` or `game_state_self_test.gd`, `game/dating_overload/dating_overload.gd`, `game/dating_overload/test/**`, `game/first_clone/first_clone.gd`, `game/first_clone/test/**`, `project.godot` (CloneIncremental after FirstClone) | `laboratory.tscn`, `phone_journal.gd`, MODULE 19 viz/President | done |
| M18_B_SCENE | scene | `world/locations/laboratory/laboratory.tscn` only — wire CloneTerminalInteractable at `story_point_clone_terminal` | all .gd except using existing script path, MODULE 19 | done |
| M18_C_PHONE_DOCS | content | `ui/phone/phone_journal.gd`, docs §82 (PROJECT_STRUCTURE, TECHNICAL_DECISIONS, gdd 07/08) | CloneIncremental math, laboratory.tscn, MODULE 19 | done |
| M18_D_QA | qa | evidence `tmp/m18_qa/**`, `docs/agent/qa/M18_QA.md` | product sources | done |

## Product decisions
1. Activation = `total_clones >= 1` only; no Story flag.
2. Real-time `_process` simulation; GameDay never grants clone output.
3. Rates owned by CloneIncremental → `GameState.set_late_rates`.
4. Production: free clone every `30 - 5*level` seconds; work `20+10*L` $/min/clone; dating `0.50+0.25*L` dates/min/clone.
5. Upgrades: 3 Money tracks, cost `30 * 3^L`, levels 0..5.
6. Auto-dates: backlog first via `fulfill_oldest_demand_by_clone` (no hero capacity), then `add_experience(1)`.
7. One physical FirstClone representative; management via lab terminal only.
8. STOP — no MODULE 19 multi-clone viz / President / offline.
