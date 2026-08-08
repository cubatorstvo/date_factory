# Presentation Architecture — MODULE 23 (+ MODULE 24 settings seams)

**Статус:** реализованная presentation architecture после MODULE 23; volumes / camera scale / FOV wired from SaveSystem in MODULE 24.  
**Граница:** audio / animation / camera / VFX усиливают уже работающий F5→ending gameplay. Не владеют scoring, Story, economy, balance, save schema.  
**STOP:** без MODULE 25 content completion; SaveSystem owns persistence (this layer only exposes apply seams).

Spec: `docs/modules/MODULE_23_AUDIO_ANIMATION_FEEDBACK.md`.  
UI shell: `docs/ui/UI_ARCHITECTURE.md`.  
Persistence: `docs/persistence/SAVE_ARCHITECTURE.md`.  
Licenses: `docs/ASSET_LICENSES.md`.

---

## 1. Ownership

| Concern | Owner | Path |
|---|---|---|
| Buses | `default_bus_layout.tres` | Master / Music / SFX / UI / Ambience |
| Music + global 2D SFX/UI | autoload `AudioDirector` | `audio/audio_director.gd` |
| Semantic IDs + stage→music map | `AudioIds` | `audio/audio_ids.gd` |
| Local ambience | scene-local `LocalAmbiencePlayer` | `world/local_ambience_player.gd` (from `WorldLocation._ready`) |
| Camera impulses | player-local `CameraFeedback` | `characters/player/camera_feedback.gd` |
| Camera FOV helpers | `PresentationCamera` | `presentation/vfx/presentation_camera.gd` |
| NPC animation | existing `CharacterAnimationController` | `characters/framework/character_animation_controller.gd` |
| Soft VFX helpers | static `RefCounted` helpers | `presentation/vfx/*.gd` |

Не создаются: VFX framework, ambience autoload state machine, voice/TTS, combat music track. Settings UI lives under `ui/frontend/` (SaveSystem-owned persistence).

---

## 2. Audio buses

Exact layout (`res://default_bus_layout.tres` → all send Master):

| Bus | Default dB |
|---|---|
| Master | 0 |
| Music | −8 |
| SFX | −3 |
| UI | −5 |
| Ambience | −10 |

`AudioDirector` re-applies the same base dB when linear volume (0..1) changes. `0` → mute (−80 dB).

---

## 3. AudioDirector

Autoload (after `SaveSystem`): music A/B crossfade, bounded one-shot pools, volume seams, minigame duck. Boot volumes come from `SaveSystem` → `set_*_volume` (deferred after both ready).

### API (presentation)

```text
play_ui(sound_id)
play_sfx(sound_id)
set_music_state(state) / get_music_state()
notify_stage(stage)          # Story stage → music state
duck_for_minigame(active)    # Music −4 dB; restore 0.4 s
set_*_volume(0..1) / get_*_volume()
  master | music | sfx | ui | ambience
```

### Pools

| Pool | Size | Bus |
|---|---|---|
| SFX | 8 | SFX |
| UI | 4 | UI |

Round-robin; no unlimited spawn. Max 12 global simultaneous 2D one-shots. World 3D emitters stay on location scenes when needed.

### Missing-asset safety

Unknown/missing stream → skip; warn once in debug; critical UI/slap IDs may use a tiny procedural WAV. No crash.

---

## 4. Four music states

Exact states: `MANUAL` · `MEDIA` · `CLONE` · `FINAL`.

| Game stage | State | Loop |
|---|---|---|
| PROLOGUE, STAGE_1..3 | MANUAL | `assets/audio/music/manual_apartment_chill.ogg` |
| STAGE_4 | MEDIA | `assets/audio/music/media_street_night.ogg` |
| STAGE_5, STAGE_6 | CLONE | `assets/audio/music/clone_restaurant_warm.ogg` |
| FINALE | FINAL | `assets/audio/music/final_sparse.wav` |

- Mapping: `AudioIds.music_state_for_stage` → `AudioDirector.notify_stage` (also on boot from `GameState` stage).
- Same-state travel / re-notify does **not** restart the bed.
- Crossfade: **1.0 s** (MusicA / MusicB).
- Minigame duck via `RivalCompetitionRunner` → `duck_for_minigame` (no dedicated combat track).

---

## 5. Ambience ownership

**Not** owned by `AudioDirector` state machine.

`WorldLocation` calls `LocalAmbiencePlayer.ensure_on_location(self)`:

| Location id | Stream | Local volume |
|---|---|---|
| `salary_mine` | `factory_hum.ogg` | −8 dB |
| `laboratory` | same | −8 dB |
| `production_area` | same | −7 dB |
| `final_location` | same | −12 dB |

Apartment / cafe / city_hub / others: **no** ambience node (asset gap). Player lives under location → freed on travel; `ensure` is idempotent (no duplicates). Bus: `Ambience`.

---

## 6. Semantic SFX

Gameplay/UI call `AudioIds` constants → `AudioDirector.play_ui` / `play_sfx`. No raw `res://` paths in callers.

Families (see `AudioIds.sfx_paths()` for file map):

- UI: `ui_click` / `ui_back` / `ui_denied` / `ui_purchase`
- Rewards / story: `reward_small` / `reward_major` / `stage_advance` / `final_signal` / `reach_milestone`
- Dating / discovery / rivals: relationship ± / rival win·loss
- Minigames: slap / dance / sigma / money minimum sets
- Salary / media / clone / late / final key cues

**Silent by design:** HUD number refresh, passive Money tick, countdown refresh, disabled hover. Grouped notification cards play one SFX each.

No voice acting / TTS / lip sync.

---

## 7. CameraFeedback

Player-local child of FPS camera (not autoload). Caps:

| Effect | Cap |
|---|---|
| Rotation kick | ≤ 2.0° |
| Positional shake | ≤ 0.025 m |
| FOV pulse | ≤ 3.0° |
| Duration | ≤ 0.20 s |

`set_feedback_scale(0..1)` — default 1; scale `0` zeroes all motion feedback (gameplay unchanged). Effects restore exact baseline position/rotation/FOV.

Primary usage: Slap hit/perfect/incoming; First Clone reveal FOV +2°/0.18s; Final signal FOV +1.5°/0.18s (`PresentationCamera`). Dance / Sigma / Money / stage cards: no camera motion.

Persisted as `controls/camera_feedback` in `user://settings.cfg` via `SaveSystem` (applied on boot / settings apply / after load).

---

## 8. Animation aliases / fallback

`CharacterAnimationController` preserved (MODULE 04). Loops: `idle` / `walk` / `run` / `approach` / `sit_idle` / `seated_gesture`.

Semantic presentation aliases (`play_semantic` / oneshot) with ordered fallbacks:

| Alias | Fallback chain |
|---|---|
| `react_positive` | gesture → idle |
| `react_negative` | react → idle |
| `react_confused` | seated_gesture → gesture → idle |
| `victory` | gesture → idle |
| `defeat` | react → idle |
| `gesture_short` | gesture → idle |

Missing clip → soft idle / no-op; optional semantics do not spam warnings; **never** gates UI `[Далее]` or gameplay commits.

---

## 9. VFX ownership

Lightweight static helpers under `presentation/vfx/` — no particle framework:

| Helper | Role |
|---|---|
| `ScreenFlash` | Media shutter, slap impact, clone reveal canvas flash |
| `UiAccentPulse` | Dating ± reaction + badge pulse |
| `MeshEmissivePulse` | Short mesh emissive charge |
| `BeaconPulse` | Final signal beacon / Label3D pulse |
| `PresentationCamera` | Resolve player `CameraFeedback` + FOV presets |

Call sites remain in existing UI/minigame/world controllers. Missing VFX → gameplay unchanged. No blood/gore; no per-clone particle storm (MODULE 19 actor caps unchanged).

---

## 10. Gameplay authority

Presentation **follows** commits. Do not delay XP / Authority / Story / clone counts / Money for SFX, crossfade, animation, or particles. Controllers keep current mutation timing; audio/VFX are fire-and-forget.

---

## 11. MODULE 24 settings seams (owned by SaveSystem)

Presentation does **not** read/write `settings.cfg`. `SaveSystem` applies:

| Setting | Target |
|---|---|
| `master` / `music` / `sfx` / `ui` / `ambience` | `AudioDirector.set_*_volume(0..1)` |
| `camera_feedback` | `CameraFeedback.set_feedback_scale(0..1)` |
| `fov` | player `set_camera_fov` |
| `mouse_sensitivity` | player look sensitivity |

Game JSON saves do **not** embed audio/camera settings — only `user://settings.cfg`.

---

## 12. Tests

| Area | Runner |
|---|---|
| AudioDirector / buses / music / duck | `audio/test/audio_director_self_test.gd` |
| CameraFeedback caps / scale0 | `CameraFeedback.run_self_test()` (+ tmp harnesses as needed) |

UI/gameplay regressions remain under existing `ui/**/test/` and `game/**/test/` suites.
