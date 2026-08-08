# File ownership — MODULE 24 Save / Load / Settings

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M24_A_AUDIT | researcher | none | product | done |
| M24_B_DOMAIN | gameplay | GameState/GameDay/CloneIncremental + sync_after_load | SaveSystem UI | done |
| M24_C_WORLD | gameplay | world.gd + player pose | GameState bulk | done |
| M24_D_SETTINGS_SEAMS | gameplay | tutorial + FOV/sensitivity seams | SaveSystem ConfigFile | done |
| M24_E_SAVE_IO | gameplay | persistence/**, project.godot autoload | frontend scenes | done |
| M24_F_FRONTEND | scene | ui/frontend/**, main_bootstrap, pause wire | GameState formulas | done |
| M24_G_DOCS | content | SAVE_ARCHITECTURE + structure/decisions/UI notes | runtime | done |
| M24_H_QA | qa | tmp/m24_qa/**, docs/agent/qa/M24_QA.md | product | done |

## Product decisions
1. One SaveSystem before AudioDirector; schema v1 JSON; 3+autosave.
2. Silent GameState bulk restore; DatingDemandEntry uses appointment_day.
3. CloneIncremental fractions persisted; no offline catch-up.
4. can_save_now allows GAMEPLAY and PAUSED; blocks modal/minigame/sessions/FinalDate.
5. Settings in user://settings.cfg; tutorials in settings.
6. Title before World boot; New Game does not delete slots.
7. STOP — no MODULE25; no legacy migration.
