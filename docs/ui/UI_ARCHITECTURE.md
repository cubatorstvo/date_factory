# UI Architecture — adaptive scene-first presentation

**Статус:** production UI хранится в редактируемых `.tscn`; controller-скрипты обновляют состояние и обрабатывают действия.
**Граница:** UI показывает уже существующее состояние и действия. Gameplay / balance / Story / economy / SaveSystem остаются source of truth.  
**STOP:** без MODULE 25 content packs; без UIManager / ScreenManager / reactive store.

Product truth: `docs/gdd/08_locations_ui_content.md` §47.  
Spec: `docs/modules/MODULE_22_UI_UX_INTEGRATION.md` (+ MODULE 24 front-end).  
Audio / camera / VFX: `docs/presentation/PRESENTATION_ARCHITECTURE.md`.  
Persistence: `docs/persistence/SAVE_ARCHITECTURE.md`.

---

## 1. Ownership

| Layer | Owner | Path |
|---|---|---|
| Persistent HUD | `World` → `WorldHost/PersistentUI/GameHUD` | `ui/hud/game_hud.tscn` + `.gd` |
| Phone journal | `World` → `WorldHost/PersistentUI/PhoneJournal` | `ui/phone/phone_journal.tscn` + `.gd` |
| Shared Theme | Theme resource + builder | `ui/theme/date_factory_theme.tres`, `date_factory_theme_builder.gd` |
| Number format | static helper | `ui/ui_number_format.gd` (`UiNumberFormat`) |
| UI scale | runtime helper | `ui/theme/ui_scale_helper.gd` (`UiScaleHelper`) |
| Tutorials | HUD-owned helper | `ui/tutorial/tutorial_prompt.gd` (`TutorialPrompt`) |
| Progression modal | phone ПРОКАЧКА tab embed / PackedScene | `ui/progression/progression_ui.tscn` + `.gd` |
| Dating modal | DatingCore presentation | `ui/dating/dating_ui.tscn` + `.gd` |
| Rival choose/result | presentation over RivalEncounters | `ui/rivals/rival_encounter_ui.tscn` + `.gd` |
| Minigame overlays | RivalCompetitionRunner | `minigames/*/`, shell `minigames/common/minigame_shell.gd` |
| Clone Terminal | lab Interactable → PackedScene | `game/clone_incremental/clone_terminal_ui.tscn` + `.gd` |
| Global Terminal | Production Area Interactable → PackedScene | `game/late_game/global_expansion_terminal_ui.tscn` + `.gd` |
| Final date UI | scene-local FinalDateController → PackedScene | `game/final_date/final_date_ui.tscn` + `.gd` |
| Title menu | bootstrap-spawned CanvasLayer | `ui/frontend/title_menu.tscn` + `.gd` |
| Pause menu | player pause → CanvasLayer | `ui/frontend/pause_menu.tscn` + `.gd` |
| Settings panel | title/pause child panel | `ui/frontend/settings_panel.tscn` + `.gd` |
| Front-end → SaveSystem | static helper | `ui/frontend/frontend_save_api.gd` (`FrontendSaveApi`) |

Не создаются: `UIManager`, `ScreenManager`, widget framework, global modal engine.

---

## 2. Scene-first and adaptive contract

- Каждый production screen, popup и overlay имеет собственную `.tscn`.
- Статические `Control`/`Label`/`Button` не создаются controller-кодом. Динамические карточки и строки создаются только из `PackedScene`.
- Общие presentation-компоненты находятся в `ui/common/`: action/choice cards, save-slot card, confirmation/message dialogs, transient notice, separators и result overlay.
- Layout использует full-rect anchors, `Container`, safe margins, перенос текста и `ScrollContainer` для длинного содержимого.
- Логический canvas — 1920×1080; `canvas_items` + `expand` адаптируют 16:9, 16:10 и 21:9 от 1280×720 до 3840×2160.
- Accessibility scale 100/125/150% меняет типографику Theme и вызывает reflow; полноэкранный root всегда остаётся `scale = Vector2.ONE`.

---

## 3. Persistent shell

`World` keeps under `/root` → `WorldHost`:

```text
LocationRoot          # swapped location scene
Player                # persistent FPS
PersistentUI          # world/persistent_ui.tscn
├── PhoneJournal
└── GameHUD
```

- Exactly one `GameHUD` and one `PhoneJournal` across travel (`World.get_game_hud()`).
- Location unload does not free PersistentUI children.
- HUD layer is presentation-only; gameplay APIs stay on autoloads.

---

## 4. GameHUD

`class_name GameHUD` · `CanvasLayer` · `ui/hud/game_hud.gd`

### Permanent resources (top-left, GAMEPLAY only)

```text
$ <money>
АВТОРИТЕТ N
ПОКОРЕННЫХ СЕРДЕЦ N
БАЛЛЫ N
```

Code mapping: HUD/phone label **Покоренных сердец** displays `GameState` **`experience`** (`get_experience` / `add_experience`). Identifier unchanged.
No relationship / Attention / GameDay / late rates / clone counts on HUD.

### Visibility

Listens to `PlayerController.control_mode_changed`.

| Mode | Resource strip + crosshair |
|---|---|
| `GAMEPLAY` | visible |
| `MODAL_UI` / `MINIGAME` / `PAUSED` | hidden (`GameplayRoot.visible = false`) |

Notification / stage / tutorial panels live outside the gameplay-only strip so they can still present when queued rules allow.

### Updates

Event-driven from `GameState` / `Story` / related signals — not `_process` polling of resources.

### Notification rail

Bottom-center transient card:

- newest replaces current immediately (no pending queue);
- ~2.2 s display; slides in from below on each present;
- same-frame reward lines may group into one card;
- no passive clone Money spam;
- salary / major money via `notify_major_money`;
- authority / XP / UP deltas, feature unlocks, Reach milestones (25/50/75/100).

### Stage toasts

On `stage_changed`: short stage card (~3 s). FINALE → `ФИНАЛ`. Does not pause the game.

### Feature toasts

On Story feature unlock — short copy from HUD `FEATURE_COPY` (social / public city / salary mine / media / lab / world expansion / final date).

---

## 4. Theme

```text
ui/theme/date_factory_theme.tres
```

Builder: `ui/theme/date_factory_theme_builder.gd`.

Applied by HUD, Phone, Progression, DatingUI, RivalEncounterUI, terminals, FinalDateUI, world modals (discovery / photo / salary), and minigame shell (`MinigameShell.apply_theme`). Minigames keep specialized layout; inherit panel / button / text language from Theme.

Visual target: clean flat comedy-bureaucracy — dark translucent panels, light text, one muted accent + warning accent. No neon / parchment / dating-app pink.

---

## 5. `UiNumberFormat`

`ui/ui_number_format.gd` — static helpers:

| API | Role |
|---|---|
| `format_grouped` | spaced thousands |
| `format_compact` | K / M / B above thresholds |
| `format_money` | `$ ` + compact/grouped |
| `format_signed` | `+N` / `0` / `-N` |
| `format_rate` | float rates for Phone/terminals |

Exact compact cases covered by `ui/hud/test/ui_number_format_test.tscn`.

---

## 6. Phone — five tabs

`class_name PhoneJournal` · `ui/phone/phone_journal.gd`

Tabs (`PhoneTab`):

| Tab | Label | Gate |
|---|---|---|
| `GIRLS` | ДЕВУШКИ | always (default open tab; discovered-only list) |
| `STATUS` | ПРОКАЧКА | always (stats + embedded perk tree; badge when upgrade points > 0) |
| `STORY` | СЮЖЕТ | always |
| `MEDIA` | МЕДИА | `StoryFeature.MEDIA_ATTENTION` |
| `CLONES` | КЛОНЫ | `GameState.get_total_clones() >= 1` |

Hidden tabs redirect to STATUS. No sixth tab: salary lives under ПРОКАЧКА; ПЕРЕГРУЗКА / feed boost live under MEDIA when overload is active.

Action logic unchanged from MODULE 15–21 APIs (`Media`, `DatingOverload`, `SalaryMine`, `CloneIncremental` read-only rates, Story progress). Perk purchase runs through the embedded Progression panel on ПРОКАЧКА.

Opens via **Q** (`phone` InputMap) anywhere in GAMEPLAY, or apartment phone Interactable → `PhoneJournal.open` → `MODAL_UI`. Q / Esc closes.

---

## 7. Progression UI

```text
ui/progression/progression_ui.tscn
ui/progression/progression_ui.gd
ui/progression/progression_modal_ui.gd   # thin extends shim
```

Entry:
- Phone **ПРОКАЧКА** tab embeds the perk tree (`embed_into`);
- standalone `ProgressionInteractable` remains available for tests / debug only (apartment wardrobe is clothing).

- All **32** ContentDB perks, four characteristic branches;
- cost `3^N`, tree prereqs, availability via existing `Progression` API;
- purchase only through Progression;
- uses Theme + `UiNumberFormat`; may surface purchase feedback through HUD when present.

---

## 8. Dating / rivals / minigames / terminals / finale

| Surface | Path | Notes |
|---|---|---|
| DatingUI | `ui/dating/` | MODAL_UI; requirements before choice; greeting non-scoring; reaction `+1/0/-1`; result breakdown; Theme |
| RivalEncounterUI | `ui/rivals/` | choose / result / exhibition stakes; Authority stakes for normal path; exhibition shows no Authority consequence |
| Minigames | `minigames/slap|dance|sigma|money/` | `ControlMode.MINIGAME`; shared `MinigameShell` Theme + score/result presentation; after `ended` show result then `match_finished` closes (ESC skips hold); live fight is not aborted by ESC; formulas untouched |
| Clone Terminal | `game/clone_incremental/clone_terminal_ui.tscn` | assign Work/Dating + local upgrades; Theme |
| Global Terminal | `game/late_game/global_expansion_terminal_ui.tscn` | Reach, rates, global upgrades; Theme |
| FinalDateUI | `game/final_date/final_date_ui.tscn` | staged choices, fail→retry, success ending + Continue; Theme + compact numbers |

Gameplay controllers remain owners of outcomes; UI is presentation.

---

## 9. Tutorials

`TutorialPrompt` inside GameHUD — **not** an autoload, **not** GameState fields.

Seven `PromptId`s:

1. `FIRST_MOVEMENT`
2. `FIRST_PHONE`
3. `FIRST_RIVAL`
4. `FIRST_DATE`
5. `FIRST_UPGRADE_POINT`
6. `FIRST_CLONE`
7. `FIRST_STAGE6`

`TutorialPrompt.export_seen_ids` / `restore_seen_ids` + `SaveSystem` `[tutorial] seen` in `user://settings.cfg` (reset from Settings). Queued until `GAMEPLAY`; does not interrupt MODAL_UI / MINIGAME / FinalDate dialogue; ~4–6 s, dismissible.

---

## 10. UI scale

`UiScaleHelper` presets: **100% / 125% / 150%**.

- Duplicates the scene Theme and scales centralized font metrics (`Caption`, `Body`, `Header`, `Title`, `Display`);
- never scales a fullscreen root transform; Containers reflow after metric changes;
- applied to HUD scale root and other themed roots via `apply_to_control` / `apply_to_canvas_item`;
- `GameHUD.set_ui_scale_percent` / `get_ui_scale_percent`;
- persisted as `display/ui_scale` (1.0 / 1.25 / 1.5) through `SaveSystem` Settings.

---

## 11. Title / Pause / Settings (MODULE 24)

Presentation-only; all I/O through `FrontendSaveApi` → `SaveSystem`.

| Surface | Entry | Actions |
|---|---|---|
| `TitleMenu` | `main_bootstrap` after `World.prepare_for_title` | Continue (latest valid), New Game, Load slot, Settings |
| `PauseMenu` | pause → `ControlMode.PAUSED` | Resume, Save slot, Load slot, Settings, Return to title |
| `SettingsPanel` | from title or pause | audio sliders, sensitivity, camera feedback, FOV, UI scale, fullscreen, vsync; Apply writes `settings.cfg` |

- Manual save from pause is allowed (`can_save_now` accepts `PAUSED`).
- Load/New Game from title starts World travel; return-to-title calls `SaveSystem.return_to_title`.
- No second persistence layer inside UI scripts.

---

## 12. Modal ownership

Source of truth for input focus: `PlayerController.ControlMode`:

```text
GAMEPLAY | MODAL_UI | MINIGAME | PAUSED
```

API: `enter_gameplay` / `enter_modal_ui` / `enter_minigame` / `enter_paused`.

Rules:

- At most one modal (or minigame) owner at a time;
- Owner enters mode on open, restores gameplay (or transitions to next owner) on close;
- Rival → minigame uses dismiss-for-transition without stacking Phone/Progression over active modal;
- HUD resource strip hides whenever mode ≠ GAMEPLAY;
- No global modal stack framework.

---

## 13. Audio seams (MODULE 23)

UI does **not** own `AudioDirector`. Call sites resolve `/root/AudioDirector` and use `AudioIds` only (no raw paths).

| Surface | Typical IDs |
|---|---|
| Phone / Progression / Rival choose | `ui_click`, `ui_back`, `ui_denied`, `ui_purchase` |
| GameHUD grouped cards | `reward_small`, `reward_major`, `stage_advance`, `final_signal` |
| DatingUI | `relationship_positive` / `neutral` / `negative` (+ `UiAccentPulse`) |
| RivalEncounterUI result | `rival_win` / `rival_loss` |
| Phone media actions | `media_publish`, `media_incoming`, `media_feed_boost` |

**Silent:** resource number refresh, passive Money tick, countdown refresh, disabled hover.  
Volumes / camera feedback / FOV / UI scale persistence → `SaveSystem` (`settings.cfg`).

---

## 14. Non-goals / STOP

- No UIManager / ScreenManager / reactive store;
- No new gameplay mechanics, balance, Story rules, or MODULE 25 content packs from UI work;
- Terminals and FinalDateUI stay under `game/**` (not moved into `ui/` for folder purity);
- UI never writes save JSON directly — only via `SaveSystem` / `FrontendSaveApi`.

---

## 15. Tests (presentation)

| Runner | Path |
|---|---|
| GameHUD smoke | `ui/hud/test/game_hud_smoke_test.tscn` |
| Number format | `ui/hud/test/ui_number_format_test.tscn` |
| Progression UI | `ui/progression/test/progression_ui_self_test.tscn` |
| Scene-first production contract | `ui/test/ui_scene_contract_self_test.tscn` |
| Multi-resolution gallery | `tools/visual_review/run_visual_playtest.py --layout/--gallery` |
| AudioDirector | `audio/test/audio_director_self_test.gd` |
