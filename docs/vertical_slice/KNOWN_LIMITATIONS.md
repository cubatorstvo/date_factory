# Known Limitations

- The production visual pass targets the Stage 1 apartment → street → restaurant slice. Later stages retain more legacy presentation.
- `Girl_Casual` is currently selected for the restaurant; `Girl_Formal` is retargeted and verified but not content-selected at runtime.
- Seated clips in the standalone Character Testbed have no chair props; the production restaurant aligns them to the chair.
- Reaction VFX use lightweight UI glyph bursts rather than a general particle library.
- Import/retarget stabilization regenerates large prefab and `.import` diffs.
- Godot 4.4.1 GL Compatibility prints renderer resource-leak diagnostics when the standalone screenshot SceneTree exits. All 9 PNGs save successfully, and normal game runtime reports zero errors.
- Existing project-wide convention warnings and unused extensibility signals remain outside this focused pass; there are no parser errors or missing signal definitions.
