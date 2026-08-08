# File ownership — MODULE 22 UI / UX Integration

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M22_A_AUDIT | researcher | none | all product | done |
| M22_B_FOUNDATION | gameplay | Theme, GameHUD, formatter, tutorials, world HUD attach | Phone, dating, minigames | done |
| M22_C_PROGRESSION | gameplay | `ui/progression/**`, progression_interactable open seam | Phone, formulas | done |
| M22_D_DATING | gameplay | `ui/dating/**` | DatingCore formulas | done |
| M22_E_PHONE | gameplay | `ui/phone/**` | other UI | done |
| M22_F_MINIGAMES | gameplay | `minigames/**` | Rival formulas | done |
| M22_G_RIVAL_UI | gameplay | `ui/rivals/**`, rival_actor glue | minigame scripts | done |
| M22_H_TERMINALS | gameplay | clone/global terminal UI | economy formulas | done |
| M22_I_FINAL | gameplay | `final_date_ui.gd` | controller logic | done |
| M22_J_WORLD_MODALS | gameplay | girl_actor / media / salary / calibration presentation | Phone | done |
| M22_K_DOCS | content | PROJECT_STRUCTURE, TECHNICAL_DECISIONS, gdd 08, UI_ARCHITECTURE | runtime | done |
| M22_L_QA | qa | `tmp/m22_qa/**`, `docs/agent/qa/M22_QA.md` | product | done |

## Product decisions
1. Presentation only — no gameplay/balance/story/economy/content mutation.
2. One Theme; one persistent GameHUD under PersistentUI.
3. HUD: Money/Auth/XP/UP only; hide on MODAL/MINIGAME/PAUSED including stage/notify rails.
4. Phone five tabs with MEDIA/CLONES gates.
5. RivalEncounterUI fills production choose/result gap via existing APIs.
6. Tutorials + UI scale runtime-only (MODULE24 may persist).
7. STOP — no MODULE23 audio/animation/VFX.
