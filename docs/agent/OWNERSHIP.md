# File ownership — MODULE 23 Audio / Animation / Feedback

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M23_A_AUDIT | researcher | none | product writes | done |
| M23_B_ASSETS | asset | `assets/audio/**`, draft ASSET_LICENSES | donor mutation | done |
| M23_B_AUDIO_CORE | gameplay | `audio/**`, `default_bus_layout.tres`, project.godot autoload/buses | formulas | done |
| M23_C_SFX_WIRE | gameplay | presentation play_* wires across UI/game/minigames | scoring | done |
| M23_D_CAMERA | gameplay | CameraFeedback + Slap impulses | other minigame camera | done |
| M23_E_ANIM | gameplay | CharacterAnimationController aliases + reaction wires | face rig | done |
| M23_F_VFX_AMBIENCE | gameplay | ambience + presentation/vfx + FOV pulses | cutscenes | done |
| M23_G_DOCS | content | docs listed in ACCEPTANCE | runtime | done |
| M23_H_QA | qa | `tmp/m23_qa/**`, `docs/agent/qa/M23_QA.md` | product | done |

## Product decisions
1. Presentation only — no gameplay mutation.
2. Five buses + AudioDirector autoload; 4 music states; bounded pools.
3. CameraFeedback player-local with caps; scale 0..1 for MODULE24.
4. Animation aliases remap to existing clips; no facial.
5. Local industrial ambience; Godot-only VFX.
6. STOP — no MODULE24 settings/persistence.
