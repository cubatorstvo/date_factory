# RC-AUDIT-UI-ASSETS-001 — UI & Asset Baseline Audit

**Date:** 2026-08-05  
**Project:** DATE FACTORY (`C:\Users\User\Documents\GodotProjects\date_factory`)  
**Extra asset source (read-only):** `C:\Users\User\Downloads\assets`  
**Scope:** read-only baseline inventory of UI, imported packs, source packs, licenses, gaps  
**Writable deliverable:** this file only  
**Visual runs:** none (windowed game not opened) — visual polish claims marked **PENDING VISUAL REVIEW**

---

## 0. Executive summary

DATE FACTORY already has a **Russian-primary, code-driven UI stack** (theme + StyleBox chrome, phone/HUD/date/shop overlays, Esc dismiss chain) and a **partial Quaternius/Kenney 3D import** for city / apartment / sushi restaurant / factory / lab. UI chrome assets (Kenney UI pack, icons, input prompts) are present in Downloads but **not imported**. Several gameplay POIs are interact/UI-backed while street art remains greybox or facade-light. Credits do **not** list third-party packs; `export_presets.cfg` is missing; Sushi Restaurant Kit has **no license file** in source zip or project tree.

**Audit deliverable status:** PASS (baseline research complete).  
**Release/UI polish readiness:** NOT READY (gaps below; visual confirmation pending).

---

## 1. Existing flow (player-visible UI)

| Step | Route | UI surface |
|---|---|---|
| Boot | `boot.tscn` → New Game / Continue / Settings / Quit | Main menu (RU) |
| Enter world | `main.tscn` → `ComplexWorld` home apartment | HUD + FPS |
| Phone | Q (typical) | `phone_ui` tabs: candidates, relations, schedule, upgrades, staff, clones, stats, Twitch |
| City | «На улицу» travel | City interacts + district gates |
| Shops | flower / jewelry / gift / clothing / homeware / bookstore | `shop_ui` modal |
| Leisure | gym / cinema sit / arcade | `gym_ui`, sit wait HUD, arcade overlay |
| Agency | photo / barber / board | `photo_studio_ui`, `barber_ui`, `agency_board_ui` |
| Dating | book → sit/wait → date stage | HUD wait + `date_ui` dialogue/result/gift inventory |
| Home vertical | elevator / basement lab | `elevator_ui`, clone accept |
| Pause | Esc (after overlays) | `pause_menu` → settings / save / load / menu |
| Finale | postgame | `finale_ui` + short credits text (no pack list) |

Evidence: `docs/DATING_AND_WORLD.md`, `scenes/world/complex_world.gd` interact wiring, `core/ui_escape.gd`, `core/ui_layers.gd`.

---

## 2. UI inventory / matrix

### 2.1 Surfaces

| Surface | Scene / script | Theme/chrome | Language | Mouse/control return | Notes |
|---|---|---|---|---|---|
| Main menu | `scenes/boot/boot.tscn` + `boot.gd` | `DateFactoryTheme.apply` | RU (+ brand EN) | Visible on boot | Continue currently loads QA full-access profile (uncommitted gameplay work) |
| Pause | `pause_menu.tscn/.gd` | Theme + `ui_fill` dim | RU | Captured on close via Esc chain | Save/Load/Settings/Menu |
| Settings | `settings_menu.tscn/.gd` | Theme | RU | Own open/close | No language option; audio/mouse/FOV/shake |
| HUD / clock / toasts | `hud.tscn/.gd` | Theme variations | RU runtime | N/A | Static tscn still has `resources`/`goal` placeholders; overwritten at runtime |
| Phone / girls / schedule / time-place booking | `phone_ui.tscn/.gd` | Theme | RU + EN leftovers | `set_open` / Esc | Tabs include Twitch names + Stats save/load |
| Inventory (gifts) | Inside `date_ui.gd` popup | Theme | RU | Date overlay | No standalone world inventory UI |
| Shops | `shop_ui.gd` (runtime-built) | Theme | RU | Captured restore | Multiple shop kinds |
| Gift selection | `date_ui` gift grid + placeholders under `assets/ui/gifts/placeholders/` | Icons PNG | RU labels | Date overlay | Explicit **placeholders** path |
| Date dialogue / result / end | `date_ui.tscn/.gd` | Theme | RU | Esc / result close | Gift inventory during/after |
| Events / reveal | `event_ui`, `reveal_popup` | Theme | RU | Overlay dismiss | |
| District gates | `district_gate_ui.gd` | Runtime | RU | Captured restore | |
| Elevator | `elevator_ui.gd` | Runtime | RU | Overlay | Themed apt buy/travel |
| Gym / photo / barber / agency | respective `*_ui.gd` | Runtime | RU | Overlay | |
| Clones accept | `clone_accept_ui.gd` | Runtime | RU | Overlay | |
| Finale / credits | `finale_ui.tscn/.gd` | Theme | RU | Pauses tree | Credits lack asset attributions |
| Transition | `transition_overlay` | Dim fill | — | — | Boot/game fade |
| Debug / QA affordances | Boot Continue QA; phone Stats Save/Load; Twitch tab | — | Mixed | — | No dedicated debug overlay scene found |

### 2.2 Themes / fonts / panels / states

| Element | Location | Status |
|---|---|---|
| Colors / StyleBox helpers | `core/ui_style.gd` | Central palette (deep bg, accent pink, money gold, etc.) |
| Theme builder | `core/theme_factory.gd` → `assets/ui/date_factory_theme.tres` | Outfit + DM Sans |
| Apply helper | `scenes/ui/chrome/date_factory_theme.gd` | Applied from boot/UI roots |
| Fill roles | `scenes/ui/chrome/ui_fill.gd` | bg / dim / accent_glow |
| Button hover/pressed | `UiStyle.button_box(state)` | Code StyleBoxFlat states |
| Modal dim | ColorRect + fill_role | Used by pause/settings/phone |
| Layer bands | `core/ui_layers.gd` | HUD→PHONE→DATE→…→SETTINGS→TRANSITION |

### 2.3 Input / Esc / mouse

- `UiEscape.dismiss_overlays`: closes event → shop → gym → arcade → agency/photo/barber → date → phone before pause.
- Many overlays set `Input.MOUSE_MODE_VISIBLE` on open and restore CAPTURED when no other overlay.
- Twitch `LineEdit` has special handling so WASD is not eaten (`phone_ui.gd`).

### 2.4 Language matrix

| Aspect | Finding |
|---|---|
| Primary UI language | Russian (`Loc` class: tags/traits/statuses) |
| Brand | English «DATE FACTORY» |
| Leftover EN strings | Phone tab placeholders `schedule` / `stats`; Twitch status seed `offline`; HUD tscn placeholder labels |
| Localization system | No Godot Translation / locale switcher in settings |
| i18n readiness | Hardcoded RU strings in scenes + scripts |

### 2.5 Responsive risks (1280×720 / 1920×1080 / 2560×1440)

| Risk | Evidence | Severity |
|---|---|---|
| Base viewport 1280×720 | `project.godot` `window/size/viewport_*` | Info |
| Stretch mode `canvas_items` only; **no `stretch/aspect`** set | `project.godot` display section | Medium — letterbox vs crop undefined across monitors |
| Fixed panel mins (phone offsets, pause 390, settings 620, boot 560) | tscn `custom_minimum_size` / absolute phone title offsets | Medium — dense phone tabs at 720p; large empty margins at 1440p |
| HUD text truncation | `hud.gd` ellipsis >120 chars | Low |
| ItemList heights hardcoded (~260–320) | phone/shop lists | Medium at low height / UI scale |
| Visual verification at 3 resolutions | Not run | **PENDING VISUAL REVIEW** |

### 2.6 UI problem register

| ID | Severity | Repro | Evidence | Owner | Regression |
|---|---|---|---|---|---|
| UI-EN-01 | Low | Open phone → Schedule/Stats tabs before refresh | `phone_ui.tscn` texts `schedule`/`stats` | df-scene-worker / gameplay UI | Screenshot + string grep |
| UI-EN-02 | Low | Open Twitch tab cold | `Статус: offline` EN token | df-gameplay-worker | Loc.online |
| UI-GIFT-01 | Medium | Open gift inventory on date | `assets/ui/gifts/placeholders/*` | df-asset-worker + content | Icon pass ≠ placeholders |
| UI-INV-01 | Medium | Seek world inventory outside date/shop | No dedicated inventory scene | Orchestrator product → gameplay | Player can only see gifts via date/shop |
| UI-CRED-01 | High (release) | Finale → Титры | `finale_ui.gd` narrative-only credits | content + release | Must list packs/licenses for export |
| UI-LANG-01 | Medium | Settings: no language | `settings_menu` | product | Future EN build blocked |
| UI-RES-01 | Medium | Change monitor to 1440p/ultrawide | stretch aspect unset | df-gameplay-worker | Visual matrix 3 resolutions |
| UI-QA-01 | Medium (dev) | Boot Continue | Loads full-access QA profile | gameplay (existing uncommitted) | Must not ship as normal Continue |
| UI-VIS-01 | — | All chrome polish / hover / focus | No rendered capture this audit | df-qa-worker | **PENDING VISUAL REVIEW** |

---

## 3. Current UI language

- **Player-facing copy:** Russian (menus, toasts, districts, shops, date, finale).
- **Code helper:** `core/loc.gd` maps English content tags → Russian display.
- **Not present:** locale files, language toggle, English UI pack.
- **Mixed tokens:** English brand; some debug/seed labels; content IDs remain English (`kitchen_table`, `cheap_cafe`).

---

## 4. Asset registry / packs / licenses

### 4.1 GodotIQ project snapshot

- Engine: Godot 4; type 3D  
- Counts: scenes 47, scripts 96, assets 1098  
- Autoloads: GodotIQRuntime, EventBus, SettingsService, Game  
- By category (brief): textures 338, models 645, audio 28, fonts 6, scenes 47, resources 33, shaders 1  

### 4.2 Imported packs (in `res://assets`)

| Pack ID | Path | Approx models | Format in tree | LICENSE in project | License claim |
|---|---|---|---|---|---|
| PACK_001 Downtown City MegaKit | `assets/environment/city/downtown_megakit/` | ~153 | glTF | Yes | CC0 (Standard/free subset) |
| PACK_018 House Interior | `assets/environment/interior/house_interior/` | ~123 | FBX | Yes | CC0 Quaternius |
| PACK_016 Sushi Restaurant | `assets/environment/restaurant/sushi_restaurant/` | ~100 | glTF | **NO** | **Unknown in-repo** |
| PACK_002 Kenney Factory | `assets/environment/factory/kenney_factory/` | ~105 | (kit meshes) | Yes | CC0 Kenney |
| PACK_015 Sci-Fi Essentials | `assets/environment/lab/scifi_essentials/` | ~23 | mixed | Yes | CC0 Quaternius Standard |
| PACK_017 Ultimate Food | `assets/props/food/` | ~103 | mixed | Yes | CC0 Quaternius |
| PACK_019 Modular Women | `assets/characters/women_modular/` | ~21 | mixed | Yes | CC0 (file header still says “Modular Males” — metadata smell) |
| PACK_021 Universal Base Characters | `assets/characters/hero_base/` | ~10 bodies/parts | mixed | Yes | CC0 Quaternius Standard |
| PACK_020 Universal Animation Library | `assets/animation/universal_library/` | small | mixed | Yes | CC0 Quaternius |
| Drinkware (ad-hoc) | `assets/environment/interior/drinkware/` | 3 | meshes | **NO** | Source zip not found in Downloads |
| UI gift placeholders | `assets/ui/gifts/placeholders/` | 28 PNG | png | N/A | Project-made placeholders — **not final** |
| Fonts Outfit + DM Sans | `assets/fonts/` | 6 ttf | ttf | **NO OFL/LICENSE file** | Typically SIL OFL — **attribution file missing** |
| Audio Kenney + Abstraction | `assets/audio/` + `assets/audio/licenses/` | 28 | wav/ogg | Partial license texts | Kenney CC0; Music Loop Bundle CC0 Abstraction |

### 4.3 Source Downloads (`C:\Users\User\Downloads\assets`) — not all imported

| Source archive | In project? | License in zip | Notes |
|---|---|---|---|
| Downtown City MegaKit[Standard].zip | Yes (subset) | License_Standard.txt CC0 | Free subset warning |
| Ultimate House Interior Pack…zip | Yes | License.txt | |
| Ultimate Food Pack…zip | Yes | License.txt | |
| Ultimate Modular Women…zip | Yes | License.txt | |
| Universal Animation Library…zip | Yes | License.txt | |
| Universal Base Characters…zip | Yes | License_Standard.txt | |
| Sci-Fi Essentials Kit…zip | Yes (limited) | License_Standard.txt | |
| kenney_factory-kit_3.0.zip | Yes | License.txt CC0 | |
| Sushi Restaurant Kit…zip | Yes meshes | **0 license/readme hits** | **Export/credits blocker until proven** |
| Modular SciFi MegaKit[Standard].zip | **No** (manifest: deferred) | License_Standard.txt CC0 | Material/import risk historically |
| kenney_ui-pack.zip | **No** | License.txt CC0 | 1343 entries; UI chrome candidate |
| kenney_game-icons.zip | **No** | license.txt | Icon candidate |
| kenney_input-prompts_1.5.zip | **No** | License.txt | Control hints candidate |
| kenney_ui-audio.zip | **No** | License.txt | |
| kenney_interface-sounds.zip | Partial via audio licenses | License.txt | |
| kenney_impact/sci-fi/music-jingles/skyboxes/light-masks | Partial or unused | License.txt each | |
| music-loop-bundle-2026-q2.zip | Partial | _LICENSE.txt CC0 | |
| proxy_1.5.blend | Outside import policy | — | Blender source; not opened this audit |

Manifest policy (`docs/ASSET_IMPORT_MANIFEST.md`): UI packs explicitly deferred; Modular SciFi deferred; one format only; free Standard kits are subsets.

### 4.4 Format duplicates

- Downtown: glTF only (no basename multi-format groups).  
- Sushi: glTF only in project.  
- House interior: FBX-only (acceptable single-format, but differs from preferred GLB policy).  
- Source sushi zip still contains FBX/OBJ trees — do not re-import as second format.

### 4.5 What cannot be called final

- Gift placeholder PNGs  
- Themed apartments greybox (`docs/CITY_HUB_EXPANSION_REPORT.md`, `DATING_AND_WORLD.md`)  
- Street leisure/agency facades still art-thin / greybox corridor (`docs/FOCUSED_POLISH_REPORT.md`)  
- Kenney factory bright palette (manifest: unify later)  
- Capsule/procedural NPC remnants risk (`REMAINING_ISSUES.md`)  
- Women modular as temporary cast (manifest PACK_019)  
- Sci-Fi Essentials Standard subset / Modular SciFi not evaluated visually  
- UI without Kenney chrome pack — functional StyleBox UI, not final art UI (**PENDING VISUAL REVIEW**)

---

## 5. Exact candidate asset mapping (no new POIs)

Mapping = existing interact/venue → best **already identified** pack candidates. Orchestrator decides adoption.

### 5.1 City POIs (from `complex_world.gd` + `CityDistricts`)

| POI / interact | Need | Primary candidate (imported) | Secondary candidate (Downloads / deferred) | Final? |
|---|---|---|---|---|
| Мой дом facade/door | Facade + door | Downtown MegaKit | — | Partial — street polish pending |
| Кафе Two Hearts | Facade + sit interior cue | Downtown facade; House/Food props | — | Facade-level; interior not dedicated cafe kit |
| Цветочный / Ювелирный / Подарки / Одежда / Дом и посуда | Shop facade + shelf props | Downtown + Food/House/Drinkware | Kenney icons for UI shop rows | Street shops UI-backed; interiors not full shops |
| Парк picnic | Vegetation / bench | Downtown vegetation/urban props | — | Leisure strip markers exist |
| Ресторан у парка | Facade + date interior | Downtown exterior + **Sushi Restaurant** interior | Food pack plates | Strongest interior kit; street canopy still placeholder-looking per polish docs |
| Фитнес Leisure | Gym machines / posters | Limited; House electronics; Factory props as last resort | Modular SciFi panels (deferred) | UI minigame; 3D gym not a dedicated pack |
| Книжный | Shelves/books | House interior shelves/props | — | UI shop |
| Кинотеатр | Facade / seats | Downtown building modules | — | Sit interact; no cinema kit |
| Аркада Перегруз | Cabinets / screens | Sci-Fi Essentials terminals; Factory | Kenney UI/icons for HUD | Minigame + sit |
| Фотостудия | Studio props | House electronics + Sci-Fi screens | — | Overlay UI |
| Барбер | Chair/desk | House interior | — | Overlay UI |
| Офис агентства | Desk/console | House + Sci-Fi | — | Board UI |
| ParkGate / AgencyGate | Barrier visuals | City CSG + downtown | — | Functional gate UX exists |

### 5.2 Home / facility / late venues (`ContentPacks.venues` + rooms)

| Venue / room | Need | Candidate pack | Notes |
|---|---|---|---|
| `kitchen_table` / apartment | Interior furniture | House Interior + Food | Vertical slice apartment art exists |
| `cheap_cafe` | Cafe set | Downtown + House/Food | No dedicated cafe kit |
| `park` | Outdoor date | Downtown vegetation | |
| `restaurant` | Fine dining | Sushi Restaurant + Food | Thematic sushi ≠ all restaurants |
| `cinema_room` | Media room | House electronics | Complex room; not full cinema |
| `photo_studio` | Studio | House + Sci-Fi | |
| `luxury_hall` | Late luxury | House Interior premium props | Art gap |
| `lab_capsule` / lab room | Lab | Sci-Fi Essentials | Standard subset |
| `conveyor` / factory | Industrial | Kenney Factory | Palette not final |
| `orbital_hall` / orbital | Sci-fi modular | **Modular SciFi MegaKit (deferred)** | Not imported |
| `apt_cozy` / `apt_modern` / `apt_creative` | Distinct interiors | House Interior variants | Currently greybox — not final |

### 5.3 UI asset candidates (Downloads → future import)

| UI need | Candidate | License | Import status |
|---|---|---|---|
| Panels/buttons/windows | `kenney_ui-pack.zip` | CC0 | Not imported (manifest deferred) |
| Gift/shop/status icons | `kenney_game-icons.zip` | CC0 | Not imported |
| WASD/Esc prompts | `kenney_input-prompts_1.5.zip` | CC0 | Not imported |
| UI SFX | `kenney_ui-audio.zip` / interface-sounds | CC0 | Partial interface sounds |
| Replace gift placeholders | Icons pack + custom | — | Placeholders remain |

---

## 6. Gaps

1. **No Kenney UI/icon/prompt packs in repo** while Downloads contain them.  
2. **Sushi LICENSE missing** in project and source zip listing.  
3. **Font license files missing** (Outfit, DM Sans).  
4. **Drinkware** without license/source provenance in Downloads.  
5. **Modular SciFi** needed for orbital/late tech look — deferred, unimported.  
6. **Dedicated interiors** missing for cafe, gym, cinema, arcade, barber, photo, agency, themed apts.  
7. **Standalone inventory UI** missing.  
8. **Credits omit third-party attribution**.  
9. **No `export_presets.cfg`** → export inclusion policy undefined.  
10. **EN leftover strings** in phone/HUD seeds.  
11. **Stretch aspect** unset for multi-resolution.  
12. **Visual QA** of UI states / POI facades not evidenced this run.

---

## 7. Likely missing replacements

| Gap | Likely replacement source | Cannot invent |
|---|---|---|
| Gift icons | Kenney game-icons + custom | Keep placeholders until pass |
| UI chrome | Kenney UI pack (CC0) | Or keep StyleBox (product choice) |
| Input legend art | Kenney input-prompts | Boot already text-only hints |
| Gym / cinema / arcade sets | Mix Downtown + Sci-Fi + Factory; or new pack search | Do not add POIs |
| Orbital / late lab expansion | Modular SciFi MegaKit sample then scale | Manifest forbids mass import now |
| Themed apt uniqueness | House Interior recolor/set dressing | Still greybox |
| Cafe identity | Downtown facade kit + Food | No cafe-specific kit in Downloads |
| Sushi provenance | Vendor page / purchase receipt / License from Synty-like storefront | Block “final” until cleared |

---

## 8. Integration boundaries

| Boundary | Reuse | Do not break |
|---|---|---|
| UI chrome | `UiStyle`, `ThemeFactory`, `DateFactoryTheme`, `UiLayers`, `UiEscape` | Parallel UI framework |
| Content IDs | `ContentPacks` / `ContentDB` venue & gift ids | Renaming without migration |
| City interacts | `complex_world.gd` + markers in `city.tscn` | Duplicate POI systems |
| Dating places | `date_places.gd` / `date_schedule.gd` | Second schedule UI |
| Shops | `shop_ui.gd` + inventory API | Separate shop frameworks |
| Asset folders | Manifest layout under `assets/environment|characters|props|ui` | Multi-format reimport |
| Save | Inventory/facility unlocks | Schema churn for icons-only work |
| Uncommitted WIP | QA Continue, proxy girl POC, etc. | Do not delete/revert unrelated changes |

---

## 9. Risks (severity / repro / evidence / owner / regression)

| ID | Severity | Repro | Evidence | Owner | Regression |
|---|---|---|---|---|---|
| LIC-SUSHI-01 | **Critical (release)** | Ship build with sushi meshes | No LICENSE in project; zip license_hits=0 | release + asset | Block export until license file + credits line |
| LIC-FONT-01 | High | Distribute fonts | No OFL/LICENSE beside `assets/fonts` | asset/release | Add SIL OFL texts; credits |
| LIC-DRINK-01 | Medium | Use drinkware in shipped scenes | No license/source in Downloads | asset | Provenance note or remove |
| LIC-CRED-01 | High | Finale credits | Narrative-only `finale_ui.gd` | content/release | Credits checklist of all packs |
| EXP-01 | High | Export project | No `export_presets.cfg` | release | Define include/exclude; strip `.blend`, zips, testbeds |
| ART-GREY-01 | High (visual) | Visit leisure/agency/themed apts | CITY_HUB + FOCUSED polish docs | scene/asset | Rendered POI matrix |
| ART-NPC-01 | Medium | City NPCs | Capsule notes in correction docs | scene | No capsule as final |
| DUP-FMT-01 | Low | Reimport sushi FBX+glTF | Source zip multi-format | asset | One format policy |
| UI-RES-01 | Medium | 1080p/1440p | stretch aspect unset | gameplay | Resolution matrix |
| UI-PLACEHOLDER-01 | Medium | Gift UI | `placeholders/` path | content/asset | Icon set |
| META-WOMEN-01 | Low | Read women LICENSE header | Says “Modular Males” | asset | Fix license text copy |
| QA-CONTINUE-01 | Medium (ship) | Boot Continue | `boot.gd` QA profile load | gameplay | Normal save Continue |

---

## 10. Credits / license / export inclusion

| Topic | Status | Risk |
|---|---|---|
| In-game credits pack list | Missing | High |
| Quaternius CC0 packs | LICENSE present (most) | Credit still recommended |
| Kenney packs | LICENSE present where imported | Credit recommended |
| Sushi Restaurant Kit | **Unresolved** | **Do not treat as cleared for commercial export** |
| Fonts | Likely OFL; files absent | Attribution required for OFL |
| Music Loop Bundle | CC0 text present | Note Abstraction request re NFT/AI (non-binding) |
| Standard vs Source kits | Downtown/Sci-Fi/Base Characters are **Standard free subsets** | Feature incompleteness, not license violation |
| Export filters | None configured | Risk of shipping testbeds, proxy POC, `.import` noise, tools |
| Downloads zips | Outside repo (good) | Do not commit zips |

---

## 11. Recommended ownership

| Track | Agent | Writable focus (future tasks) |
|---|---|---|
| UI string cleanup + stretch aspect + Continue semantics | `df-gameplay-worker` | `boot.gd`, `phone_ui`, `project.godot` display (careful ownership), settings |
| Theme/chrome import of Kenney UI (if approved) | `df-asset-worker` then `df-scene-worker` | `assets/ui/**`, theme resources — **not** parallel on same tscn |
| Gift icon replacement | `df-content-worker` + `df-asset-worker` | placeholders → final icons; gift data paths |
| POI facade/interior art for existing markers only | `df-scene-worker` + `df-asset-worker` | `city.tscn`, apartment/restaurant slices; one writer per tscn |
| License harvest + CREDITS.md + finale credits | `df-content-worker` / release Orchestrator | docs + `finale_ui.gd` copy |
| Independent visual matrix | `df-qa-worker` | 1280/1080/1440 captures; mouse return; Esc stack |
| Modular SciFi sample POC | `df-asset-worker` | tiny sample only per manifest |

**This audit file:** `docs/release/research/UI_ASSET_AUDIT.md` — researcher owned for this task.

---

## 12. Acceptance evidence (for follow-up tasks)

| Check | Required evidence | This audit |
|---|---|---|
| UI inventory complete | Matrix §2 | Done |
| Language baseline | Loc + string samples | Done |
| Pack/license registry | §4 | Done |
| Candidate mapping for existing POIs | §5 | Done (no new POIs) |
| Gaps & replacements | §6–7 | Done |
| Credits/export risks | §10 | Done |
| Rendered UI at 3 resolutions | Screenshots + Godot log | **PENDING VISUAL REVIEW** |
| Rendered POI facade/interior pass | Screenshots per POI | **PENDING VISUAL REVIEW** |
| Sushi license cleared | License file path + credit line | **UNMET** |
| Font licenses in tree | OFL files | **UNMET** |
| Export preset exists | `export_presets.cfg` | **UNMET** |

---

## 13. Commands / tools used (read-only)

- GodotIQ: `godotiq_project_summary(detail=brief)`  
- GodotIQ: `godotiq_asset_registry` filters: all brief; `assets/ui`; `sushi_restaurant`; `downtown_megakit`; `assets/fonts`; `assets/audio`  
- GodotIQ: `godotiq_file_context` on boot, phone, hud, date_ui, settings, pause, theme/ui_style/ui_escape/ui_layers, content_db/content_packs, city.tscn  
- Filesystem read: project `assets/`, `scenes/ui/`, licenses, `docs/ASSET_IMPORT_MANIFEST.md`, `DATING_AND_WORLD.md`, polish reports  
- Downloads: zip entry counts + license hit scan (no extract/import); sample license text from Downtown / Kenney UI / Modular SciFi  
- **Not run:** Blender, windowed game, visual capture, asset import

---

## 14. Uncommitted context note

Workspace contains unrelated uncommitted work (QA full-access Continue, proxy girl POC, save modules, etc.). This audit **did not modify** those files and **must not** be used as an excuse to delete them.

---

## 15. Audit verdict

| Criterion | Result |
|---|---|
| Baseline UI inventory | Met |
| Asset/license registry | Met (with explicit unknowns) |
| Candidate mapping without new POIs | Met |
| Visual proof | Pending |
| License/export clearance for release | Not met |

**RC-AUDIT-UI-ASSETS-001 research audit: PASS**  
**Release visual/license readiness: NOT READY**
