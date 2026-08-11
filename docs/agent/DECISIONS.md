# DECISIONS — Visual Bootstrap (Donor / Asset Packs)

## D-VB-01 — Donor city source

**Decision:** Primary transfer source is `date_factory_legacy/scenes/world/city/city.tscn` plus its POI prefab closure under `scenes/art/city/`.

**Why:** Named production city with `PlayerSpawn`, `CafeEntrance`, `HomeEntrance`, and district POIs aligned to gameplay spokes. `vertical_slice/street.tscn` is denser mesh placement but thinner POI coverage; use only as supplement if Stage A shots show city too sparse — do not invent a new layout.

## D-VB-02 — Donor room source

**Decision:** Transfer `scenes/world/vertical_slice/apartment.tscn` (house_interior + food props). Ignore thin `Apartment_Blockout_Finalized.tscn`.

## D-VB-03 — Cafe = donor restaurant scene, location id stays cafe

**Decision:** Transfer `scenes/world/vertical_slice/restaurant.tscn` into current **`cafe`** location. Do **not** create a separate restaurant location. Do **not** invent a new cafe interior from scratch. Rename player-facing labels to cafe where needed; keep internal mesh names if harmless. `CafeTwoHearts` stays city façade/approach only.

**Why (TZ lock, overrides researcher caution):** User TZ states the donor «ресторан / кафе» scene must be used **as cafe**, a separate restaurant must not be built, and a good donor venue must be transferred rather than redesigned. Donor has no other production cafe interior — only this vertical-slice venue + facade POI. Product ID/path/ContentDB keys remain `cafe` (not `restaurant`).

**Supersedes:** researcher recommendation “do not transfer restaurant.tscn as cafe / compose new interior”. That would violate TZ §3D and §4 (no reinventing layout when donor venue exists).

## D-VB-04 — Sushi kit (PACK_016) scope

**Decision:** Copy only the sushi_restaurant dependency closure required by the donor cafe scene. Do not expand sushi usage. Do not build a new restaurant from PACK_016.

**Risk:** Donor tree has **no** `LICENSE.txt` under `sushi_restaurant/`. Track as remaining license hygiene issue; do not block transfer of the existing donor cafe scene per TZ “keep good donor cafe”.

## D-VB-05 — Packs on disk vs TZ pack list

**Decision:** Use packs physically present under donor `assets/`:

| TZ id | On disk |
|---|---|
| PACK_001 Downtown | `assets/environment/city/downtown_megakit` (CC0) |
| PACK_018 House Interior | `assets/environment/interior/house_interior` (CC0) |
| PACK_002 Kenney Factory | `assets/environment/factory/kenney_factory` |
| PACK_015 Sci-Fi Essentials | `assets/environment/lab/scifi_essentials` |
| PACK_017 Food | `assets/props/food` |
| PACK_019/020/021 | donor/current `assets/characters`, `assets/animation` |
| PACK_013 Modular SciFi | **NOT present** — lab/late use PACK_015 (+ factory) only |
| PACK_014 music | **out of scope** |
| PACK_016 sushi | only as cafe scene deps (D-VB-04) |

## D-VB-06 — Integration pattern

**Decision:** Keep current `world_location.gd` / spawn / transition / interactable scripts. Replace BoxMesh visuals by instancing transferred art roots (or merging geometry under a `VisualRoot`) and re-placing logic markers onto donor landmarks. Prefer adapting marker transforms to donor geometry over rebuilding rooms.

## D-VB-07 — Screenshot / git hygiene

**Decision:** Legacy + current PNGs live under `tmp/visual_bootstrap_review/` then publish on temporary `visual-review/bootstrap-<stamp>`. Source asset/scene fixes land on main. Do not commit PNG dumps to main.

## D-VB-08 — No gameplay redesign

**Decision:** No stage/XP/story/dating/balance/content catalog changes except minimal path/marker fixes required for travel and interactions after visual swap.

## D-VB-09 — City transfer accepted with known non-blockers

**Decision:** Accept Stage B city mount (`Geometry/DonorCity`) as bootstrap PASS.

**Known non-blockers (do not redesign city for these now):** WorldTransition debug BoxMeshes still visible; occasional megakit trim/emissive red edge artifacts; stylized CSG POI shells. Fix only if they break travel/collision or cause missing-resource errors.

## D-VB-10 — Lab dating booths stay box shells

**Decision:** Accept Stage E2 lab with PACK_015 prop dressing. Dating booth structural shells may remain tinted BoxMeshes because PACK_013 Modular SciFi is absent. Do not invent modular wall kits.

## D-VB-11 — Characters already on Quaternius path

**Decision:** Stage F does not rebuild GirlActor/RivalActor. Bases already point at PACK_021/019 meshes via CharacterActor. Scope = variant wrappers + appearance `visual_scene` remaps + review screenshots. No FPS player body.

## D-VC-01 — Corrective pass supersedes bootstrap non-blockers

**Decision:** User TZ `VISUAL_BOOTSTRAP_CORRECTIVE_SINGLE_BASE_CHARACTERS_RU.md` supersedes D-VB-09 / D-VB-10 / D-VB-11 for remaining visual debt.

Must fix now (not polish):
- City / apartment / cafe donor lighting parity (wrapper brightening removed or donor values restored literally).
- Visible interactive placeholders → real assets + Area/Interactable reparented (no floating Areas).
- Debug Label3D removed from production render.
- Lab ceiling/shell obstruction and debug labels addressed within existing PACK_015 (still no inventing PACK_013).

## D-VC-02 — Single male + single female PACK_021 bases

**Decision:**
- Male base mesh: `res://assets/characters/hero_base/meshes/bodies/Superhero_Male_FullBody.gltf`
- Female base mesh: `res://assets/characters/hero_base/meshes/bodies/Superhero_Female_FullBody.gltf`

All production NPCs use these two bases only. Diversity = modular placeholder slots via `CharacterVariantController` + optional fields on `AppearanceProfileDefinition`. No PACK_019 whole-mesh variants.

Female animation: switch `animation_female_base` to UAL path proven by `DateGirl_UAL.tscn` (`DF_UAL_Aliases` / same male UAL libraries). Do not keep `DF_Women_*` as required runtime after PACK_019 removal.

## D-VC-03 — PACK_019 removal gate

**Decision:** Delete `assets/characters/women_modular/**` only after:
1. All female wrappers/appearances on PACK_021 female base.
2. Cafe `restaurant.tscn` has zero Girl_Casual / Casual.gltf instances.
3. Project grep runtime refs to `women_modular` = 0 (excluding historical docs if needed).

## D-VC-04 — PACK_016 sushi license documentation

**Decision:** Per user TZ §17, document Sushi Restaurant Kit as Quaternius CC0 with official source `https://quaternius.com/packs/sushirestaurantkit.html`. Usage remains cafe donor dependency only (D-VB-04 scope unchanged).

## D-VC-05 — No layout redesign

**Decision:** Corrective pass does not change floor plans, POI positions, building placement, or gameplay semantics. Asset-first replacement of placeholders only.

## D-AP1-01 — Art Pass 01 scope lock

**Decision:** Art Pass 01 only: real PACK_021 hair; clothing/shoes/accessory silhouette fix (keep slot architecture); city POI proxy→ready Building_* by lot size; LotBounds never visible in production; city spawn NPC exclusion 2.5m; cafe ordinary visual cap 4 + date exclusion 2.2m. No apartment/mine/lab/late art. No PACK_013. No layout redesign. Keep one male + one female PACK_021 base and PACK_019 removed.

## D-AP1-02 — Hair variant indices 0–4

**Decision:** Remap appearance `hair_variant` to exact TZ indices (male 0=bald…4=Buns; female 0=BuzzedFemale…4=bald). Use PACK_021 glTF under `hairstyles/Origin at 0/glTF (Godot)/`. Never Hair_Beard as hairstyle. Per-instance material overrides for hair color.

## D-AP1-03 — City ready-building replacement rule

**Decision:** Replace proxy exteriors only with `Building_Small_1` / `Building_Medium_2_001` / `Building_Large_2` by max(lot) thresholds 8.5 / 11.5. Preserve scenes that already have real Building_*. Uniform scale ≤90% lot. Fit fail → leave unchanged + `READY_BUILDING_FIT_FAILED`.

---

## D-PE01-01 — Player evidence precedes implementation

**Decision:** PLAYER EXPERIENCE PASS 01 starts with two isolated clean-profile, source-blind runs from Main Menu → New Game. No gameplay source, GDD, test fixture, state inspection, teleport, direct Story call, or direct interaction invocation may be used by the black-box player.

**Why:** System/API reachability does not establish first-time-player comprehension. Before/after journals and screenshots must preserve player-visible truth.

## D-PE01-02 — Existing systems only

**Decision:** Present the current Story/Phone objective through the existing HUD, use `TutorialPrompt` and the player interaction pipeline, and retain current World/Interactable semantics. Do not create a quest, waypoint, minimap, dialogue, tutorial-language, or duplicate story-state framework.

## D-PE01-03 — Apartment physics scope

**Decision:** Keep donor apartment visuals and the production wrapper's markers/Areas separate. Fit simple primitive static collision to essential visible apartment furniture only after blind evidence confirms the defect; retain donor CSG as the room shell. One scene writer owns both apartment scenes sequentially.

## D-PE01-04 — Prologue route truth

**Decision:** Neighbor discovery is the intended Stage 0 route. The city exit remains story-locked until normal prologue progress unlocks it, so its player-facing feedback must be clear but it is not a false mandatory route to Neighbor. Restore the Neighbor anchor content reference only if Phase A/B confirms the actor is absent.

## D-PE01-05 — Evidence isolation

**Decision:** Use an isolated empty `user://` profile and never delete developer saves/settings. Source/test/docs fixes land on clean `main`; before/after screenshots, collision diagnostics, recordings, and a copy of the player journal publish only on `visual-review/player-experience-01-<date>`.

---

## D-UI-01 — Production UI is scene-authored

**Decision:** Every production screen, popup, modal, overlay, and persistent HUD surface is authored as a `.tscn`. Controller scripts may update data and instantiate reusable row/card scenes, but may not construct presentation trees with `Control.new()`, `Label.new()`, or `Button.new()`.

One-off controls remain declarative children of their owning screen. Repeated runtime entries use `ui/common/` PackedScenes. No `UIManager`, modal stack, or gameplay-state framework is introduced.

## D-UI-02 — Resolution and accessibility scaling are separate

**Decision:** Godot `canvas_items` stretch with a 1920×1080 logical canvas and `expand` aspect handles 1280×720–3840×2160 across 16:9, 16:10, and 21:9. Scene anchors, Containers, safe margins, wrapping, and scrolling own reflow.

The existing 100/125/150% setting remains an accessibility multiplier for theme typography. It must not geometrically scale a fullscreen root, because that moves anchored controls outside the viewport.

## D-UI-03 — Phone on Q; progression inside phone tab

**Decision:** Permanent `phone` InputMap action on **Q** opens `PhoneJournal` in GAMEPLAY. Esc/Q closes. Progression lives on the phone **ПРОКАЧКА** tab (former СТАТУС content + embedded perk tree). No separate header **ПРОКАЧКА** button. Tab order: **ДЕВУШКИ → ПРОКАЧКА → СЮЖЕТ** (+ МЕДИА/КЛОНЫ when unlocked). Default open tab is **ДЕВУШКИ**. Apartment wardrobe is clothing shop, not progression. Q during minigames stays `minigame_special_1`.

## D-UI-04 — Player label «Покоренных сердец»

**Decision:** Player-facing Russian name for the former «Опытность» stat is **Покоренных сердец**.

**Code mapping (unchanged identifiers):**
- GameState field / save key: `experience`
- getters/setters: `get_experience`, `add_experience`
- related: `required_experience` on girl defs, `experience_gained` on relationship results, `late_experience_granted`

Do not rename code identifiers; only UI strings and product docs use the new label.

## D-WARDROBE-01 — Apartment wardrobe clothing shop

**Decision:** Wardrobe Interaction opens a fridge-like single-column clothing menu. Starting outfits: **Повседневный** and **Дешёвый деловой** (unlocked). Additional outfits are purchased with money and equip via story flags (`wardrobe_item_*_owned`, `wardrobe_equipped_*`). Visual mesh swap for the FPS player is deferred until dedicated male outfit assets are wired.

---

## D-OPENING-01 — Separate pre-prologue evening

**Decision:** New Game opens a standalone first-person evening scene before `SaveSystem.start_new_game`. The bed completion signal then invokes the existing new-game path exactly once. Continue/Load and the old Neighbor prologue are unchanged.

**Why:** This delivers the supplied opening as an isolated production scene while deliberately deferring the known narrative contradiction with the old prologue to the user's next stage.

## D-OPENING-02 — No new cinematic framework or save state

**Decision:** One scene-local controller owns the fixed dialogue timeline, camera/card presentation, Neighbor departure, input handoff, and fade. It reuses the production apartment scene, Player, CharacterActor, Neighbor appearance, and semantic animation aliases. No dialogue engine, quest state, opening-seen flag, GameState field, or save-schema change is introduced.

## D-OPENING-03 — First-person staging and user acceptance

**Decision:** The seated portion uses a fixed first-person camera with scene-authored subtitles/card overlay. After Neighbor leaves, the existing FPS Player takes over and walks to the bed. No subagents are used in this chat; self-verification can reach only `READY FOR USER PLAYTEST`.

## D-OPENING-04 — Verification boundary

**Decision:** OPENING-01 acceptance uses the focused 20-check contract, existing UI/save/world-save suites, and the live production handoff with opened gameplay frames. Existing `world_location` and apartment-onboarding test debt is recorded but not repaired because it predates the opening, tests missing Phone/collider assumptions, and lies outside the isolated pre-prologue scope.
