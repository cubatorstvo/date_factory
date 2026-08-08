# MODULE 23 — AUDIO / ANIMATION / FEEDBACK

**Проект:** Date Factory  
**Модуль:** 23 — Audio / Animation / Feedback  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** общий presentation-pass по полностью работающей игре: звуковой язык, музыка, реактивные SFX, умеренный camera feedback, semantic animation reactions, лёгкие VFX и комедийные тайминги.  
**Предыдущий модуль:** MODULE 22 — UI / UX Integration  
**Следующий модуль:** MODULE 24 — Save / Load / Settings  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 23

---

# 0. ГРАНИЦА

MODULE 23 не меняет:
- gameplay mechanics;
- scoring;
- balance;
- Story;
- economy;
- content girls/rivals/events;
- minigame formulas.

Он усиливает только presentation.

---

# 1. ASSET AUDIT FIRST

До production-кода Cursor обязан проверить:

```text
res://assets/
res://characters/
res://minigames/
../date_factory_legacy  # READ-ONLY, legacy-v1
```

Ищем:
- music loops;
- UI SFX;
- impacts;
- camera/shutter;
- machinery;
- ambience;
- AnimationLibraries;
- gestures/reactions;
- particles/materials/shaders.

Никакой runtime dependency на donor.

В final report перечислить реально выбранные assets.

---

# 2. LICENSES

Создать/обновить:

```text
docs/ASSET_LICENSES.md
```

Для production external assets:
- path;
- source pack;
- known license / redistribution note.

Файл с неизвестным происхождением не использовать в release-facing production path.

---

# 3. AUDIO BUSES

Exact buses:

```text
Master
Music
SFX
UI
Ambience
```

Default target:

```text
Master     0 dB
Music     -8 dB
SFX       -3 dB
UI        -5 dB
Ambience -10 dB
```

Допустима коррекция ±2 dB после loudness audit.

---

# 4. AudioDirector

Один компактный autoload:

```text
AudioDirector
```

Responsibilities:
- music state;
- crossfade;
- global 2D SFX;
- UI SFX;
- bounded one-shot pools;
- volume seams для MODULE24.

Не владеет gameplay.

Minimal API:

```text
play_ui(sound_id)
play_sfx(sound_id)
set_music_state(state)
get_music_state()
set_master_volume(value)
set_music_volume(value)
set_sfx_volume(value)
set_ui_volume(value)
set_ambience_volume(value)
```

User values:

```text
0.0..1.0
```

0 = mute/-80dB.

---

# 5. BOUNDED POOLS

Global SFX:

```text
8 players
```

UI:

```text
4 players
```

At most12 global simultaneous one-shots.

No unlimited dynamic spawn.

3D world emitters stay local scenes.

---

# 6. SEMANTIC SOUND IDS

No raw audio paths scattered through gameplay.

Examples:

```text
ui_click
ui_back
ui_denied
ui_purchase
reward_small
reward_major
stage_advance
relationship_positive
relationship_neutral
relationship_negative
rival_win
rival_loss
camera_shutter
clone_complete
reach_milestone
final_signal
```

---

# 7. EXACT FOUR MUSIC STATES

```text
MANUAL
MEDIA
CLONE
FINAL
```

Mapping:

```text
PROLOGUE / STAGE1 / STAGE2 / STAGE3 → MANUAL
STAGE4                              → MEDIA
STAGE5 / STAGE6                     → CLONE
FINALE                              → FINAL
```

Travel inside same state does NOT restart music.

Crossfade:

```text
1.0 sec
```

Two players MusicA/MusicB sufficient.

---

# 8. MUSIC FEEL

MANUAL:
- light;
- dry;
- quirky;
- low pressure.

MEDIA:
- busier pulse;
- public/media pressure;
- still comedic.

CLONE:
- mechanical;
- forward-moving;
- lightly industrial.

FINAL:
- sparse;
- strange;
- calm;
- space-like.

No sentimental romance soundtrack, no epic boss orchestra.

---

# 9. MINIGAME MUSIC DUCK

While rival minigame active:

```text
Music -4 dB
```

Restore over:

```text
0.4 sec
```

No dedicated combat track.

Ending:
FINAL music -6dB over0.8s, ending sting, restore after Continue.

---

# 10. LOCAL AMBIENCE

Where suitable assets exist:

```text
city_hub       → distant city/wind
cafe           → room/cups
salary_mine    → industrial hum
laboratory     → electrical/mechanical hum
production_area→ larger machinery/airflow
final_location → low signal/space ambience
```

Local scene `AudioStreamPlayer`, bus `Ambience`.

No ambience autoload state machine.

---

# 11. WORLD 3D AUDIO

Use `AudioStreamPlayer3D` for:
- clone chamber;
- media shutter source;
- machinery;
- final signal beacon.

Short sensible attenuation.

No hundreds of clone emitters.

---

# 12. UI SOUND LANGUAGE

```text
successful button → ui_click
close/back        → ui_back
attempt unavailable → ui_denied
purchase          → ui_purchase
tab change        → subtle ui_click
```

No sounds from:
- HUD number refresh;
- passive Money tick;
- countdown refresh;
- focus/hover of disabled button.

---

# 13. HUD / REWARD AUDIO

Grouped reward notification:

```text
reward_small
```

Stage / major feature:

```text
stage_advance
```

Reach25/50/75:

```text
reward_major
```

Reach100:

```text
final_signal
```

One sound per grouped card.

---

# 14. GIRL REACTION AUDIO

Dating:

```text
+1 → relationship_positive
0  → relationship_neutral
-1 → relationship_negative
```

Subtle, no laugh-track.

GirlDiscovery:
- success → positive;
- failure → negative;
- story/lock → ui_denied.

---

# 15. RIVAL RESULT AUDIO

Normal and exhibition:

```text
WIN  → rival_win
LOSS → rival_loss
```

Do not layer another huge Authority sting.

---

# 16. SLAP AUDIO

Minimum:
- hit impact;
- perfect accent;
- block;
- perfect block accent;
- miss whoosh.

No gore/bone-crunch tone.

---

# 17. DANCE AUDIO

Minimum:
- prompt beat;
- correct step;
- wrong step;
- sequence success.

No second full song fighting with global music.

---

# 18. SIGMA AUDIO

Minimum:
- zone enter subtle cue;
- disturbance cue;
- success accent.

No continuous high-pitched beep.

---

# 19. MONEY AUDIO

Minimum:
- stake raise;
- Money spent;
- rival raise;
- shared win/loss.

Gameplay remains source of Money mutation.

---

# 20. SALARY / MEDIA / CLONE / LATE / FINAL SFX

Salary:
- hold start machinery;
- payout/stamp.

Media:
- pose confirm;
- shutter synchronized with flash;
- publish cue;
- incoming cue;
- Feed Boost rising pulse.

First Clone:
- calibration accept/reject;
- machine charge;
- clone reveal;
- assignment confirm.

Incremental:
- local clone-produced sound only while relevant in lab;
- NO global beep per clone late-game.

Late:
- global upgrade accent;
- three manual event cues;
- Reach milestones.

Final:
- answer signal;
- zone gate;
- alien rival entrance;
- existing Dance/Slap;
- failure cue;
- ending sting.

---

# 21. NO VOICE ACTING

Do NOT add:
- TTS;
- AI voices;
- recorded dialogue;
- voice bark system;
- lip sync.

Dialogue remains text.

---

# 22. CAMERA FEEDBACK

Create player-local:

```text
CameraFeedback
```

Not autoload.

Minimal API:

```text
impulse_rotation(...)
shake(...)
fov_pulse(...)
set_feedback_scale(0..1)
get_feedback_scale()
```

Default scale1.

MODULE24 persists/exposes later.

---

# 23. CAMERA CAPS

Absolute defaults:

```text
rotation kick <= 2.0°
positional shake <= 0.025m
FOV pulse <= 3°
single effect <= 0.20s
```

All restore baseline exactly.

No continuous shake/headbob expansion.

---

# 24. CAMERA USAGE

SLAP:
- hit ~1.2° /0.10s;
- perfect ~1.8° +0.015m /0.10s;
- incoming impact <=1.5°;
- miss none.

DANCE/SIGMA/MONEY:
```text
none
```

First Clone reveal:
```text
FOV +2° /0.18s
```

Final signal:
```text
FOV +1.5°
```

Stage/Reach:
```text
none
```

Scale0 removes all motion feedback without affecting gameplay.

---

# 25. CHARACTER ANIMATION

Preserve and reuse:

```text
CharacterAnimationController
```

Do NOT replace it.

Audit actual libraries.

If assets support, semantic aliases:

```text
react_positive
react_negative
react_confused
victory
defeat
gesture_short
```

Existing aliases remain:
`idle/walk/run/approach/sit_idle/seated_gesture`.

---

# 26. ANIMATION FALLBACK

If alias exists → play.

Else fallback:
```text
seated_gesture / gesture_short / idle
```

Never block gameplay.

Optional missing aliases should not spam warnings every use.

---

# 27. GIRL ANIMATIONS

Dating:
```text
+1 → react_positive
0  → gesture_short/seated_gesture
-1 → react_negative
```

GirlDiscovery:
- success positive;
- failure negative;
- prerequisite confused or idle.

Animation does NOT gate `[Далее]`.

---

# 28. RIVAL ANIMATIONS

Player wins:
```text
rival → defeat
```

Player loses:
```text
rival → victory
```

Do not delay lifecycle >~1s because of long clip.

Exhibition aliens use same aliases/fallback.

---

# 29. CLONE VISUAL ANIMATIONS

Dating rooms:

```text
CALM             → sit_idle
OVER_EXPLAINING  → seated_gesture / gesture_short
SILENT_SUCCESS   → sit_idle
MUTUAL_CONFUSION → react_confused / gesture_short
```

Work Tween:
`walk` while moving if available.

Free clones:
idle.

No gameplay coupling.

---

# 30. FACIAL STATES

Audit actual meshes.

Only if real blendshapes/bones already support it:

```text
neutral
positive
negative
confused
```

Otherwise body animation/head pose is enough.

Do NOT build:
- face rig;
- lip sync;
- eye-tracking AI;
- procedural eyebrows.

---

# 31. VFX PRINCIPLE

Simple Godot-only effects:
- GPUParticles3D;
- Canvas flash;
- emissive pulse;
- Tween.

VFX explains:
```text
impact
state change
scale
```

No general VFX framework.

---

# 32. CORE VFX

Dating reaction:
- +1/0/-1 brief UI accent pulse, 0.15–0.25s.

Relationship +5:
- small badge/panel pulse.

Slap:
- tiny screen-space impact flash <0.12s;
- perfect slightly stronger;
- no blood.

Dance:
- correct-step highlight;
- sequence success pulse.

Sigma:
- valid-zone glow;
- disturbance edge pulse.

Money:
- stake number pulse.

Media:
- preserve 0.20–0.30s white flash + shutter.

Clone:
- chamber emissive charge;
- short reveal flash;
- optional steam/particles.

Reach:
- map emissive pulse at milestones.

Final:
- beacon pulse/beam;
- simple target reveal particles.

---

# 33. COMEDIC TIMING

Play absurdity straight.

Do NOT add:
- laugh track;
- rimshot;
- meme soundboard;
- cartoon boings everywhere.

Recommended holds:
```text
girl reaction → player-controlled Далее
rival result overlay → ~0.9s
stage card →3s non-blocking
photo flash →0.25s
clone reveal beat →0.6–1.0s
alien rival entrance →0.7s
ending sting before title →~0.8s
```

No long forced dead air.

---

# 34. GAMEPLAY AUTHORITY RULE

Presentation never owns gameplay.

Do NOT delay:
- XP commit until particle ends;
- Authority until victory animation ends;
- Story until music crossfade;
- clone count until SFX ends.

Gameplay commits when it currently commits.

Presentation follows.

---

# 35. MISSING-ASSET SAFETY

Missing/null audio:
- skip;
- warn once in debug;
- no crash.

Missing animation:
- fallback idle;
- no crash.

Missing VFX:
- gameplay unchanged.

---

# 36. PERFORMANCE

Global 2D one-shots <=12.

Particles per normal location roughly <10.

No sound/particle per aggregate clone.

MODULE19 <=27 visual CharacterActors remains unchanged.

At 10,000 clones:
presentation node/audio/VFX count stays effectively constant.

---

# 37. SETTINGS SEAMS FOR MODULE24

AudioDirector exposes 0..1 controls:
- Master;
- Music;
- SFX;
- UI;
- Ambience.

CameraFeedback exposes:
```text
feedback_scale 0..1
```

MODULE23 does NOT build settings menu or persistence.

---

# 38. TESTS — MUSIC

Exact:
```text
PROLOGUE → MANUAL
STAGE4   → MEDIA
STAGE5   → CLONE
STAGE6   → CLONE
FINALE   → FINAL
```

Travel same state: no restart.

Crossfade works.

Minigame duck restores without drift.

---

# 39. TESTS — AUDIO SPAM

100 passive HUD/Money/countdown updates:
```text
0 unintended sounds
```

Clone economy at huge scale:
no per-clone global sound storm.

---

# 40. TESTS — DATING / DISCOVERY

Each +1/0/-1:
- correct one-shot;
- correct pulse;
- semantic NPC reaction if actor exists;
- scoring unchanged.

Discovery success/failure/lock cues correct.

---

# 41. TESTS — RIVALS

Normal:
existing Authority/defeat semantics unchanged.

Exhibition:
```text
Authority0 delta
no defeated persistence
```

Presentation still works.

---

# 42. TESTS — CAMERA

Perfect Slap respects caps.

Repeated impulses return exact baseline.

Scale0 produces zero camera motion.

Minigame mechanics unchanged.

---

# 43. TESTS — FALLBACKS

Remove one optional reaction animation:
no crash.

Null one SFX:
no crash.

All UI/gameplay completes.

---

# 44. TESTS — AMBIENCE

Repeated travel:
- ambience starts/stops with scene;
- no duplicates.

---

# 45. FULL F5 PRESENTATION PASS

Manual ears-on/visual run start→ending.

Check:

Early:
- restrained UI/world audio;
- reactions readable;
- ambience background-only.

Rivals:
- input/impact/result clear;
- only Slap adds physical camera feel.

Media:
- flash + shutter sync;
- no notification spam.

Clone:
- first reveal has clear charge/beat;
- lab sounds mechanical;
- mass clone stage stays calm enough.

Late:
- CLONE music distinct;
- Reach milestones feel larger;
- Production Area reads industrial/global.

Final:
- FINAL state distinct;
- alien rival entrances clear;
- ending sting/title lands;
- failure never feels like bad ending.

---

# 46. LOUDNESS ACCEPTANCE

At defaults:
- music never masks UI/minigame cues;
- ambience is background;
- Slap noticeable but not startlingly louder than other major SFX;
- no harsh continuous high-frequency cues.

No mastering pipeline required.

---

# 47. OPTIONAL FOOTSTEPS

Player footsteps are optional.

If donor has a simple clean generic implementation, may reuse.

Do NOT build surface-material footstep database.

NPC footsteps not required.

---

# 48. NO CUTSCENE SYSTEM

Do NOT add:
- camera switching framework;
- Timeline;
- cinematic director;
- dialogue cinematic framework.

Game stays first-person.

---

# 49. DOCUMENTATION

Update:
```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/ui/UI_ARCHITECTURE.md
docs/ASSET_LICENSES.md
```

Create:
```text
docs/presentation/PRESENTATION_ARCHITECTURE.md
```

Document:
- buses;
- AudioDirector;
- 4 music states;
- ambience ownership;
- semantic SFX;
- camera caps/scale;
- animation aliases/fallback;
- VFX ownership;
- no gameplay authority;
- licenses.

---

# 50. SUGGESTED PROJECT ADDITIONS

```text
audio/
├── audio_director.gd
├── audio_ids.gd
└── test/

assets/audio/
├── music/
├── sfx/
└── ambience/

characters/player/
└── camera_feedback.gd

presentation/
└── vfx/
```

Only create files actually used.

---

# 51. DEFINITION OF DONE

- [ ] current + donor asset audit performed;
- [ ] no runtime donor dependency;
- [ ] ASSET_LICENSES updated;
- [ ] exact five audio buses exist;
- [ ] one compact AudioDirector autoload;
- [ ] bounded pools;
- [ ] semantic sound IDs;
- [ ] exactly four music states;
- [ ] exact stage mapping;
- [ ] same-state travel no music restart;
- [ ] 1s crossfade;
- [ ] minigame duck/restoration;
- [ ] useful local ambience where assets permit;
- [ ] consistent UI click/back/denied/purchase language;
- [ ] no passive Money/HUD audio spam;
- [ ] girl +1/0/-1 cues;
- [ ] GirlDiscovery cues;
- [ ] rival win/loss cues;
- [ ] four minigames minimum SFX;
- [ ] salary/media/clone/late/final key SFX;
- [ ] no per-clone global beep;
- [ ] no voice/TTS;
- [ ] player-local CameraFeedback;
- [ ] exact feedback caps;
- [ ] scale0 disables motion feedback;
- [ ] existing CharacterAnimationController preserved;
- [ ] semantic reactions wired where assets exist;
- [ ] safe animation fallback;
- [ ] facial states only if real rig supports;
- [ ] restrained core VFX;
- [ ] no blood/gore;
- [ ] media flash/shutter sync;
- [ ] clone reveal audio/VFX beat;
- [ ] Reach100/final signal distinct;
- [ ] presentation never mutates gameplay;
- [ ] late-scale actor/audio/VFX count bounded;
- [ ] audio volume seams exposed for MODULE24;
- [ ] camera scale seam exposed for MODULE24;
- [ ] gameplay/UI regressions PASS;
- [ ] full clean F5 presentation run reaches ending;
- [ ] no MODULE24 persistence/settings screen ahead.

---

# 52. CURSOR ORDER

```text
1. Audit current assets + legacy-v1, licenses.
2. Audio buses + AudioDirector + pools.
3. Select/map four real music loops, crossfade.
4. Local ambience.
5. UI/HUD/dating/discovery/reward SFX.
6. Minigame/result SFX.
7. CameraFeedback + Slap.
8. NPC semantic animations.
9. Media/clone/late/final SFX + minimal VFX.
10. Facial reactions only if actual model supports.
11. Runtime volume/camera seams for Module24.
12. Stress test huge clone count/audio spam.
13. Full F5 ears-on/visual pass.
14. Regressions/docs/licenses.
```

---

# 53. CURSOR FINAL REPORT

## Asset audit
List actual music/SFX/ambience/animations/VFX and licenses.

## Audio
Confirm buses, AudioDirector, bounded pools, 4 music states.

## Music
Confirm exact stage mapping, crossfade and ducking.

## SFX
Summarize coverage:
UI / girls / rivals / 4 minigames / salary / media / clone / late / final.

## Camera
Confirm caps + scale0..1.

## Animation
List actual aliases available and fallback behavior.

## VFX
List presentation-only effects.

## Performance
Prove huge clone count does not scale sounds/particles/actors.

## F5
Describe clean start→ending presentation run.

## Regressions
All previous suites.

## Commit
SHA.

Then STOP. Do not begin MODULE24.
