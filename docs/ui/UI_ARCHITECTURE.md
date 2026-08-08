# UI Architecture — MODULE 22

**Статус:** реализованная presentation architecture после MODULE 22.  
**Граница:** UI показывает уже существующее состояние и действия. Gameplay / balance / Story / economy остаются source of truth.  
**STOP:** без MODULE 23 audio / animation / VFX; без UIManager / ScreenManager / reactive store.

Product truth: `docs/gdd/08_locations_ui_content.md` §47.  
Spec: `docs/modules/MODULE_22_UI_UX_INTEGRATION.md`.

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
| Progression modal | apartment Interactable → spawn | `ui/progression/progression_ui.gd` (+ `.tscn`); shim `progression_modal_ui.gd` |
| Dating modal | DatingCore presentation | `ui/dating/dating_ui.tscn` + `.gd` |
| Rival choose/result | presentation over RivalEncounters | `ui/rivals/rival_encounter_ui.tscn` + `.gd` |
| Minigame overlays | RivalCompetitionRunner | `minigames/*/`, shell `minigames/common/minigame_shell.gd` |
| Clone Terminal | lab Interactable | `game/clone_incremental/clone_terminal_ui.gd` |
| Global Terminal | Production Area Interactable | `game/late_game/global_expansion_terminal_ui.gd` |
| Final date UI | scene-local FinalDateController | `game/final_date/final_date_ui.gd` |

Не создаются: `UIManager`, `ScreenManager`, widget framework, global modal engine.

---

## 2. Persistent shell

`World` keeps under `/root` → `WorldHost`:

```text
LocationRoot          # swapped location scene
Player                # persistent FPS
PersistentUI          # CanvasLayer
├── PhoneJournal
└── GameHUD
```

- Exactly one `GameHUD` and one `PhoneJournal` across travel (`World.get_game_hud()`).
- Location unload does not free PersistentUI children.
- HUD layer is presentation-only; gameplay APIs stay on autoloads.

---

## 3. GameHUD

`class_name GameHUD` · `CanvasLayer` · `ui/hud/game_hud.gd`

### Permanent resources (top-left, GAMEPLAY only)

```text
$ <money>
АВТОРИТЕТ N
ОПЫТНОСТЬ N
БАЛЛЫ N
```

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

Top-center transient queue:

- max 3 pending;
- ~2.2 s each;
- same-frame reward lines may group;
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
| `STATUS` | СТАТУС | always |
| `STORY` | СЮЖЕТ | always |
| `GIRLS` | ДЕВУШКИ | always (discovered-only list) |
| `MEDIA` | МЕДИА | `StoryFeature.MEDIA_ATTENTION` |
| `CLONES` | КЛОНЫ | `GameState.get_total_clones() >= 1` |

Hidden tabs redirect to STATUS. No sixth tab: salary lives under STATUS; ПЕРЕГРУЗКА / feed boost live under MEDIA when overload is active.

Action logic unchanged from MODULE 15–21 APIs (`Media`, `DatingOverload`, `SalaryMine`, `CloneIncremental` read-only rates, Story progress). Phone does **not** purchase perks or assign clones.

Opens via apartment phone Interactable → `PhoneJournal.open` → `MODAL_UI`. No permanent phone hotkey.

---

## 7. Progression UI

```text
ui/progression/progression_ui.tscn
ui/progression/progression_ui.gd
ui/progression/progression_modal_ui.gd   # thin extends shim
```

Entry: `game/progression/progression_interactable.gd` loads `progression_ui.gd`, optional characteristic preselect.

- All **32** ContentDB perks, four characteristic branches;
- cost `3^N`, tree prereqs, availability via existing `Progression` API;
- purchase only through Progression — no Phone perk buy;
- uses Theme + `UiNumberFormat`; may surface purchase feedback through HUD when present.

---

## 8. Dating / rivals / minigames / terminals / finale

| Surface | Path | Notes |
|---|---|---|
| DatingUI | `ui/dating/` | MODAL_UI; requirements before choice; greeting non-scoring; reaction `+1/0/-1`; result breakdown; Theme |
| RivalEncounterUI | `ui/rivals/` | choose / result / exhibition stakes; Authority stakes for normal path; exhibition shows no Authority consequence |
| Minigames | `minigames/slap|dance|sigma|money/` | `ControlMode.MINIGAME`; shared `MinigameShell` Theme + score/result presentation; formulas untouched |
| Clone Terminal | `game/clone_incremental/clone_terminal_ui.gd` | assign Work/Dating + local upgrades; Theme |
| Global Terminal | `game/late_game/global_expansion_terminal_ui.gd` | Reach, rates, global upgrades; Theme |
| FinalDateUI | `game/final_date/final_date_ui.gd` | staged choices, fail→retry, success ending + Continue; Theme + compact numbers |

Gameplay controllers remain owners of outcomes; UI is presentation.

---

## 9. Tutorials (runtime-only)

`TutorialPrompt` inside GameHUD — **not** an autoload, **not** GameState fields (MODULE 24 may persist).

Seven `PromptId`s, once per runtime:

1. `FIRST_MOVEMENT`
2. `FIRST_PHONE`
3. `FIRST_RIVAL`
4. `FIRST_DATE`
5. `FIRST_UPGRADE_POINT`
6. `FIRST_CLONE`
7. `FIRST_STAGE6`

Queued until `GAMEPLAY`; does not interrupt MODAL_UI / MINIGAME / FinalDate dialogue; ~4–6 s, dismissible.

---

## 10. UI scale (runtime-only)

`UiScaleHelper` presets: **100% / 125% / 150%**.

- Applied to HUD scale root and other themed roots via `apply_to_control` / `apply_to_canvas_item`;
- `GameHUD.set_ui_scale_percent` / `get_ui_scale_percent`;
- not persisted (MODULE 24 Settings).

---

## 11. Modal ownership

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

## 12. Non-goals / STOP

- No MODULE 23 audio, animation polish, or VFX ahead of schedule;
- No new gameplay mechanics, balance, Story rules, or content packs from UI work;
- No save fields solely for tutorials / UI scale until MODULE 24;
- Terminals and FinalDateUI stay under `game/**` (not moved into `ui/` for folder purity).

---

## 13. Tests (presentation)

| Runner | Path |
|---|---|
| GameHUD smoke | `ui/hud/test/game_hud_smoke_test.tscn` |
| Number format | `ui/hud/test/ui_number_format_test.tscn` |
| Progression UI | `ui/progression/test/progression_ui_self_test.tscn` |
