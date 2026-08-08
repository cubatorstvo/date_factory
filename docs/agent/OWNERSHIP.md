# File ownership — MODULE 19 Physical Clone Visualization

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M19_A_SCENE | scene | `world/locations/laboratory/laboratory.tscn` only — expand ~22×18, 10 date rooms, work/free/mass markers, signs | all new .gd, FirstClone, CloneIncremental, MODULE 20 | done |
| M19_B_GAMEPLAY | gameplay | `game/clone_visualization/**` (new), narrow `game/first_clone/first_clone.gd` suppress when controller present + total>=1, `game/first_clone/test/**`, viz self-test | laboratory.tscn, CloneIncremental formulas, GameState new fields, President/MODULE 20 | done |
| M19_C_DOCS | content | `docs/PROJECT_STRUCTURE.md`, `docs/TECHNICAL_DECISIONS.md`, `docs/gdd/07_story_clones_finale.md`, `docs/gdd/08_locations_ui_content.md` | runtime code/scenes | done |
| M19_D_QA | qa | `tmp/m19_qa/**`, `docs/agent/qa/M19_QA.md` | product sources | done |

## Product decisions
1. Visualization-only over GameState aggregates; no per-clone gameplay entities.
2. Caps: 10 date rooms, 3 work, 2 free, 2 mass-flow; actor ceiling ≤27.
3. Overflow = labels + mass corridor only; totals stay in CloneIncremental numbers.
4. No CloneVisualization autoload — lab-local CloneVisualizationController.
5. FirstClone single representative suppressed in lab when controller owns viz (total>=1); MODULE17 test fallback without controller preserved.
6. Anonymous date-room girls = CharacterActor appearances only, not GirlActor.
7. STOP — no President / Stage6 / MODULE 20 world expansion.
