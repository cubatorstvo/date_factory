# MANUAL CONTENT COMPLETE — MODULE 25 Inventory

Canonical production inventory after **MODULE 25 — Content Completion**.  
Source of truth for counts: `data/catalog/content_catalog.tres` + `data/content/**`.  
Spec: `docs/modules/MODULE_25_CONTENT_COMPLETION.md` §106.

**Boundary:** content completion locked before MODULE 26 balance.  
**Persistence:** Save schema **v1** unchanged.

---

## Catalog totals after MODULE 25

| Kind | Count | Notes |
|---|---:|---|
| Primary traits | 4 | KIND / STATUS / THRILL_SEEKING / STRANGE |
| Secondary traits | 4 | SCANDALOUS / CONSISTENT / VARIETY_SEEKING / DEMANDING |
| Competitions | 4 | SLAP / DANCE / MONEY / SIGMA |
| Perks | 32 | unchanged |
| Locations | 9 | unchanged |
| Stages | 8 | unchanged |
| Girls | **23** | 16 Ordinary + 6 Story + 1 Final |
| Rivals | **19** | 12 Ordinary + 5 Earth story + 2 Final exhibition |
| Discovery situations | **22** | Final target has no ordinary discovery |
| Discovery approaches | 66 | 3 per situation (file count) |
| Dating pools | 24 | cafe common + 16 signatures + story/apartment pools |
| Dating events (central) | **62** | cafe common 24 + 16 signatures + story/apartment events |
| Greetings | 8 | 4 pre-M25 + 4 M25 |
| Farewells | 5 | 2 pre-M25 common + 3 M25 ordinary + president |
| Appearance profiles | 45 | female + male + bases/clone |

---

## 1. All 23 girls

| ID | Role | Primary × Secondary | XP | Discovery | Signature pool | Farewell |
|---|---|---|---:|---|---|---|
| `girl_neighbor` | Story | KIND × CONSISTENT | 0 | `discovery_situation_neighbor_hallway` | — (story pools) | `dating_farewell_early_common` |
| `girl_actress` | Story | STATUS × DEMANDING | 1 | `discovery_situation_actress_waiting` | — | `dating_farewell_early_common` |
| `girl_mine_boss` | Story | THRILL_SEEKING × CONSISTENT | 2 | `discovery_situation_mine_boss_gate` | — | `dating_farewell_early_common` |
| `girl_magazine_editor` | Story | STRANGE × SCANDALOUS | 3 | `discovery_situation_magazine_editor_shoot` | — | `dating_farewell_early_common` |
| `girl_scientist` | Story | KIND × DEMANDING | 4 | `discovery_situation_scientist_lab_gate` | — | `dating_farewell_early_common` |
| `girl_president` | Story | STATUS × VARIETY_SEEKING | 10 | `discovery_situation_president_expansion_gate` | — | `dating_farewell_president` |
| `girl_final_target` | Final | STRANGE × VARIETY_SEEKING | 0 | *(none — FinalDate)* | — | — |
| `girl_city_bicycle` | Ordinary | KIND × VARIETY_SEEKING | 0 | `discovery_situation_city_bicycle` | `date_pool_signature_city_bicycle` | `dating_farewell_early_common` |
| `girl_city_umbrella` | Ordinary | KIND × SCANDALOUS | 0 | `discovery_situation_city_umbrella` | `date_pool_signature_city_umbrella` | `dating_farewell_walk_common` |
| `girl_cafe_spoon_stack` | Ordinary | KIND × CONSISTENT | 1 | `discovery_situation_cafe_spoon_stack` | `date_pool_signature_cafe_spoon_stack` | `dating_farewell_transport_common` |
| `girl_cafe_receipt_notes` | Ordinary | KIND × DEMANDING | 2 | `discovery_situation_cafe_receipt_notes` | `date_pool_signature_cafe_receipt_notes` | `dating_farewell_walk_common` |
| `girl_cafe_laptop` | Ordinary | STATUS × CONSISTENT | 1 | `discovery_situation_cafe_laptop` | `date_pool_signature_cafe_laptop` | `dating_farewell_early_common` |
| `girl_city_lanyard` | Ordinary | STATUS × VARIETY_SEEKING | 2 | `discovery_situation_city_lanyard` | `date_pool_signature_city_lanyard` | `dating_farewell_transport_common` |
| `girl_appearance_coat_check` | Ordinary | STATUS × DEMANDING | 3 | `discovery_situation_appearance_coat_check` | `date_pool_signature_appearance_coat_check` | `dating_farewell_transport_common` |
| `girl_appearance_flash` | Ordinary | STATUS × SCANDALOUS | 3 | `discovery_situation_appearance_flash` | `date_pool_signature_appearance_flash` | `dating_farewell_walk_common` |
| `girl_gym_chalk` | Ordinary | THRILL_SEEKING × SCANDALOUS | 1 | `discovery_situation_gym_chalk` | `date_pool_signature_gym_chalk` | `dating_farewell_early_common` |
| `girl_gym_timer` | Ordinary | THRILL_SEEKING × CONSISTENT | 1 | `discovery_situation_gym_timer` | `date_pool_signature_gym_timer` | `dating_farewell_transport_common` |
| `girl_city_crosswalk` | Ordinary | THRILL_SEEKING × VARIETY_SEEKING | 2 | `discovery_situation_city_crosswalk` | `date_pool_signature_city_crosswalk` | `dating_farewell_last_word_common` |
| `girl_cafe_hot_sauce` | Ordinary | THRILL_SEEKING × DEMANDING | 3 | `discovery_situation_cafe_hot_sauce` | `date_pool_signature_cafe_hot_sauce` | `dating_farewell_last_word_common` |
| `girl_appearance_ritual` | Ordinary | STRANGE × VARIETY_SEEKING | 2 | `discovery_situation_appearance_ritual` | `date_pool_signature_appearance_ritual` | `dating_farewell_early_common` |
| `girl_public_sculpture` | Ordinary | STRANGE × CONSISTENT | 2 | `discovery_situation_public_sculpture` | `date_pool_signature_public_sculpture` | `dating_farewell_walk_common` |
| `girl_appearance_mannequin` | Ordinary | STRANGE × SCANDALOUS | 3 | `discovery_situation_appearance_mannequin` | `date_pool_signature_appearance_mannequin` | `dating_farewell_last_word_common` |
| `girl_cafe_sugar_geometry` | Ordinary | STRANGE × DEMANDING | 4 | `discovery_situation_cafe_sugar_geometry` | `date_pool_signature_cafe_sugar_geometry` | `dating_farewell_last_word_common` |

### Ordinary 4×4 matrix (16 unique pairs)

|  | SCANDALOUS | CONSISTENT | VARIETY_SEEKING | DEMANDING |
|---|---|---|---|---|
| **KIND** | `girl_city_umbrella` | `girl_cafe_spoon_stack` | `girl_city_bicycle` | `girl_cafe_receipt_notes` |
| **STATUS** | `girl_appearance_flash` | `girl_cafe_laptop` | `girl_city_lanyard` | `girl_appearance_coat_check` |
| **THRILL_SEEKING** | `girl_gym_chalk` | `girl_gym_timer` | `girl_city_crosswalk` | `girl_cafe_hot_sauce` |
| **STRANGE** | `girl_appearance_mannequin` | `girl_public_sculpture` | `girl_appearance_ritual` | `girl_cafe_sugar_geometry` |

Every ordinary girl uses `date_pool_cafe_common` + own signature pool.

---

## 2. All 19 rivals

| ID | Role | Auth req | Preferred | Appearance | Placement (production) |
|---|---|---:|---|---|---|
| `rival_actress` | Earth story | 0 | DANCE | `appearance_male_actress_rival` | appearance_space (story) |
| `rival_mine_boss` | Earth story | 2 | SLAP | `appearance_male_mine_rival` | city mine gate (story) |
| `rival_magazine_editor` | Earth story | 4 | MONEY | `appearance_male_magazine_editor_rival` | appearance_space (story) |
| `rival_scientist` | Earth story | 7 | SIGMA | `appearance_male_scientist_rival` | city lab gate (story) |
| `rival_president` | Earth story | 10 | MONEY | `appearance_male_president_rival` | city → production (story) |
| `rival_final_ceremonial` | Final exhibition | 0 | DANCE | `appearance_male_final_ceremonial` | final_location |
| `rival_final_gravity` | Final exhibition | 0 | SLAP | `appearance_male_final_gravity` | final_location |
| `rival_city_tracksuit` | Ordinary | 0 | SLAP | `appearance_male_city_tracksuit` | city_hub |
| `rival_gym_mirror` | Ordinary | 1 | DANCE | `appearance_male_gym_mirror` | gym |
| `rival_city_thermos` | Ordinary *(M25)* | 2 | SIGMA | `appearance_male_city_thermos` | city_hub public |
| `rival_cafe_receipt` | Ordinary | 2 | MONEY | `appearance_male_cafe_receipt` | cafe |
| `rival_city_silent` | Ordinary | 3 | SIGMA | `appearance_male_city_silent` | city_hub |
| `rival_gym_plate_counter` | Ordinary *(M25)* | 3 | SLAP | `appearance_male_gym_plate_counter` | gym |
| `rival_public_coat` | Ordinary | 3 | DANCE | `appearance_male_public_coat` | city public |
| `rival_appearance_ringlight` | Ordinary *(M25)* | 4 | DANCE | `appearance_male_appearance_ringlight` | appearance_space |
| `rival_cafe_menu_holder` | Ordinary *(M25)* | 4 | MONEY | `appearance_male_cafe_menu_holder` | cafe |
| `rival_public_watch` | Ordinary | 4 | MONEY | `appearance_male_public_watch` | city public |
| `rival_appearance_tripod` | Ordinary | 4 | SIGMA | `appearance_male_appearance_tripod` | appearance_space |
| `rival_city_headphones` | Ordinary *(M25)* | 5 | SIGMA | `appearance_male_city_headphones` | city_hub |

Breakdown: **12 ordinary / 5 Earth story / 2 final exhibition**. No new story rivals in MODULE 25.

---

## 3. All 22 discovery situations

| Situation ID | Girl | Location family |
|---|---|---|
| `discovery_situation_neighbor_hallway` | Story neighbor | apartment |
| `discovery_situation_actress_waiting` | Story actress | appearance_space |
| `discovery_situation_mine_boss_gate` | Story mine boss | city / mine |
| `discovery_situation_magazine_editor_shoot` | Story editor | appearance_space |
| `discovery_situation_scientist_lab_gate` | Story scientist | city lab gate |
| `discovery_situation_president_expansion_gate` | Story president | city → production |
| `discovery_situation_city_bicycle` | Ordinary | city_hub |
| `discovery_situation_city_umbrella` | Ordinary *(M25)* | city_hub |
| `discovery_situation_city_lanyard` | Ordinary *(M25)* | city_hub |
| `discovery_situation_city_crosswalk` | Ordinary *(M25)* | city_hub |
| `discovery_situation_public_sculpture` | Ordinary | city public |
| `discovery_situation_cafe_laptop` | Ordinary | cafe |
| `discovery_situation_cafe_spoon_stack` | Ordinary *(M25)* | cafe |
| `discovery_situation_cafe_receipt_notes` | Ordinary | cafe |
| `discovery_situation_cafe_hot_sauce` | Ordinary *(M25)* | cafe |
| `discovery_situation_cafe_sugar_geometry` | Ordinary *(M25)* | cafe |
| `discovery_situation_gym_chalk` | Ordinary | gym |
| `discovery_situation_gym_timer` | Ordinary *(M25)* | gym |
| `discovery_situation_appearance_ritual` | Ordinary | appearance_space |
| `discovery_situation_appearance_flash` | Ordinary | appearance_space |
| `discovery_situation_appearance_coat_check` | Ordinary *(M25)* | appearance_space |
| `discovery_situation_appearance_mannequin` | Ordinary *(M25)* | appearance_space |

Final target uses authored FinalDate — no discovery situation.

---

## 4. Dating pools / events summary

### Cafe common — exactly 24

`date_pool_cafe_common` event IDs:

| # | Event ID | Batch |
|---:|---|---|
| 1–12 | `date_event_cafe_{failure,expensive_water,rule,attention,table_taken,spill,queue,broken_chair,walk_rain,musician,statue,dessert_first}` | pre-M25 |
| 13–24 | `date_event_cafe_{wrong_order,last_cake,window_draft,phone_charger,reserved_sign,loud_table,wobbly_spoon,free_sample,coat_mixup,waiter_question,table_photo,closing_chairs}` | M25 (+12) |

### Signatures — exactly 16 pools / 16 events

| Signature pool | Event |
|---|---|
| `date_pool_signature_city_bicycle` | `date_event_signature_city_bicycle_lock` |
| `date_pool_signature_cafe_laptop` | `date_event_signature_cafe_laptop_power` |
| `date_pool_signature_gym_chalk` | `date_event_signature_gym_chalk_challenge` |
| `date_pool_signature_appearance_ritual` | `date_event_signature_appearance_ritual_napkin` |
| `date_pool_signature_public_sculpture` | `date_event_signature_public_sculpture_menu_name` |
| `date_pool_signature_cafe_receipt_notes` | `date_event_signature_receipt_waiter` |
| `date_pool_signature_appearance_flash` | `date_event_signature_appearance_flash_background` |
| `date_pool_signature_city_umbrella` | `date_event_signature_city_umbrella_waiter` |
| `date_pool_signature_cafe_spoon_stack` | `date_event_signature_spoon_stack_repeat` |
| `date_pool_signature_city_lanyard` | `date_event_signature_city_lanyard_reservation` |
| `date_pool_signature_appearance_coat_check` | `date_event_signature_coat_check_glass` |
| `date_pool_signature_gym_timer` | `date_event_signature_gym_timer_spicy` |
| `date_pool_signature_city_crosswalk` | `date_event_signature_crosswalk_three_routes` |
| `date_pool_signature_cafe_hot_sauce` | `date_event_signature_hot_sauce_second_round` |
| `date_pool_signature_appearance_mannequin` | `date_event_signature_mannequin_third_chair` |
| `date_pool_signature_cafe_sugar_geometry` | `date_event_signature_sugar_geometry_cup` |

### Greetings — 8

| ID | Batch |
|---|---|
| `dating_greeting_simple` | pre-M25 |
| `dating_greeting_attention` | pre-M25 |
| `dating_greeting_immediate_joke` | pre-M25 |
| `dating_greeting_check_comfort` | pre-M25 |
| `dating_greeting_offer_choice` | M25 |
| `dating_greeting_notice_detail` | M25 |
| `dating_greeting_direct_plan` | M25 |
| `dating_greeting_small_confession` | M25 |

### Farewells — 5

| ID | Role |
|---|---|
| `dating_farewell_early_common` | shared / pre-M25 |
| `dating_farewell_president` | story president |
| `dating_farewell_walk_common` | M25 ordinary |
| `dating_farewell_transport_common` | M25 ordinary |
| `dating_farewell_last_word_common` | M25 ordinary |

### Central event total

```text
story / apartment / editor / scientist / president / mine / cafe pre-M25
+ 12 new cafe common
+ 16 ordinary signatures
= 62 production central dating events
```

Other pools (story/apartment, not ordinary signature):  
`date_pool_apartment_common`, `date_pool_neighbor`, `date_pool_actress`, `date_pool_mine_boss`, `date_pool_magazine_editor`, `date_pool_scientist`, `date_pool_president`.

---

## 5. Flavor interactions (≥24) by location

Exact Spec §69–77 distribution — **24** `FlavorInteractable` nodes:

| Location | Count | Nodes / titles |
|---|---:|---|
| apartment | 5 | ОТРАЖЕНИЕ, ГАРДЕРОБ, ХОЛОДИЛЬНИК, ОКНО, СТУЛ |
| city_hub | 5 | СКАМЕЙКА, ГОРОДСКОЙ ЦЕНТР, УРНА, СЛУЖЕБНЫЙ ВХОД, КАРТА ГОРОДА |
| cafe | 3 | МЕНЮ, САХАР, БРОНЬ |
| gym | 2 | ЗЕРКАЛО, БЛИНЫ |
| appearance_space | 3 | КОЛЬЦЕВАЯ ЛАМПА, МАНЕКЕН, ФОН |
| salary_mine | 2 | КОНВЕЙЕР, ТЕХНИКА БЕЗОПАСНОСТИ |
| laboratory | 2 | КАМЕРА КЛОНИРОВАНИЯ, РОМАНТИЧЕСКИЙ СЕКТОР |
| production_area | 1 | КАРТА ЗЕМЛИ |
| final_location | 1 | СТОЛ |
| **Total** | **24** | presentation-only; no GameState mutation |

Adapter: `world/flavor/flavor_interactable.tscn`.

---

## 6. Scenic gags (≥12)

Exact Spec §78 — **12** staged visual gags:

| # | Location | Gag |
|---:|---|---|
| 1 | apartment | Three planning notes near phone (ПЛАН A/B/C) |
| 2 | city_hub | Bus stop tiny text «Ожидание не ускоряет событие» |
| 3 | city_hub | Opposite arrows both «ЦЕНТР» |
| 4 | cafe | Table leg stabilized by folded menu |
| 5 | cafe | Display cake labelled «ПОСЛЕДНИЙ» |
| 6 | gym | Tiny dumbbell on oversized rack |
| 7 | appearance_space | Two mannequins in formal negotiation |
| 8 | salary_mine | Conveyor ends at tiny calculator |
| 9 | laboratory | Clone output «ЧЕЛОВЕК ГОТОВ» |
| 10 | laboratory | Date-room plates `01`..`10` |
| 11 | production_area | Shipping board «ЧЕЛОВЕК — 1 ШТ.» … |
| 12 | final_location | Café napkin holder on final table |

---

## 7. Appearance profiles for new MODULE 25 content

### New ordinary female (9)

| Profile | Girl |
|---|---|
| `appearance_female_city_umbrella` | `girl_city_umbrella` |
| `appearance_female_cafe_spoon_stack` | `girl_cafe_spoon_stack` |
| `appearance_female_city_lanyard` | `girl_city_lanyard` |
| `appearance_female_appearance_coat_check` | `girl_appearance_coat_check` |
| `appearance_female_gym_timer` | `girl_gym_timer` |
| `appearance_female_city_crosswalk` | `girl_city_crosswalk` |
| `appearance_female_cafe_hot_sauce` | `girl_cafe_hot_sauce` |
| `appearance_female_appearance_mannequin` | `girl_appearance_mannequin` |
| `appearance_female_cafe_sugar_geometry` | `girl_cafe_sugar_geometry` |

### New ordinary male / rivals (5)

| Profile | Rival |
|---|---|
| `appearance_male_city_thermos` | `rival_city_thermos` |
| `appearance_male_gym_plate_counter` | `rival_gym_plate_counter` |
| `appearance_male_appearance_ringlight` | `rival_appearance_ringlight` |
| `appearance_male_cafe_menu_holder` | `rival_cafe_menu_holder` |
| `appearance_male_city_headphones` | `rival_city_headphones` |

Total appearance profiles in catalog: **45** (includes pre-M25 females/males, bases, first clone).

---

## 8. Late visual tiers summary

Presentation-only via `UpgradeLevelVisual` (`game/clone_incremental/upgrade_level_visual.gd`).  
No formula / cost / rate changes.

| Scope | Location | Tracks | Visible levels | Nodes |
|---|---|---|---|---:|
| LOCAL_CLONE | laboratory | ProductionSpeed / WorkEfficiency / DatingEfficiency | 1..5 (+ level0 base labels) | 15 tier nodes |
| GLOBAL | production_area | GlobalProduction / GlobalWork / GlobalDating | 1..3 | 9 tier nodes |

Capstone signs (examples):  
- Lab L5: «ПЕЧАТЬ ЧЕЛОВЕКА: СЕРИЙНАЯ», «РАБОТА РАСПРЕДЕЛЯЕТСЯ АВТОМАТИЧЕСКИ», «РОМАНТИЧЕСКИЙ КОНВЕЙЕР: НОРМА»  
- Global L3: «ЛОКАЛЬНОЕ ПРОИЗВОДСТВО ОТМЕНЕНО», «РАБОТА: ПЛАНЕТАРНЫЙ УРОВЕНЬ», «СВИДАНИЯ: ГЛОБАЛЬНЫЙ ПОТОК»

---

## Prior inventories (superseded for totals)

- `docs/content/MANUAL_CONTENT_14A.md`
- `docs/content/MANUAL_CONTENT_14B.md`
- `docs/content/MANUAL_CONTENT_17.md`

Those remain historical slice notes. **This file is the MODULE 25 canonical complete inventory.**

---

## Status

| Check | Result |
|---|---|
| Girls 23 (16 ordinary / 6 story / 1 final) | PASS |
| Ordinary 4×4 complete | PASS |
| Rivals 19 (12 / 5 / 2) | PASS |
| Discovery 22 | PASS |
| Cafe common 24 | PASS |
| Signatures 16/16 | PASS |
| Greetings 8 / Farewells 5 | PASS |
| Central dating events ≥62 | PASS (62) |
| Flavor ≥24 by location | PASS (24) |
| Scenic gags ≥12 | PASS (12) |
| Schema remains v1 | PASS (docs; no schema change in this module) |
