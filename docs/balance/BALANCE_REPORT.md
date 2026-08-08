# BALANCE REPORT — MODULE 26

**Wave:** D (AFTER locked)  
**Spec:** [`docs/modules/MODULE_26_BALANCE_ANTI_GRIND.md`](../modules/MODULE_26_BALANCE_ANTI_GRIND.md) (§99, §125–127, §130)  
**Audit date:** 2026-08-08  
**Status:** Balance locked — release-candidate constants  
**Documentation only** — not source of truth (constants live in owning systems)

---

## 1. Scope / boundaries

MODULE 26:

```text
НЕ добавляет новый контент
НЕ добавляет новые gameplay systems
НЕ добавляет currencies / stages / perks
НЕ меняет save schema
```

Разрешено:

```text
изменять существующие числовые constants
исправлять anti-grind edge cases
добавлять test-only balance simulations
добавлять balance documentation
```

### Save schema

| Constant | Value | Source |
|---|---|---|
| `SAVE_SCHEMA_VERSION` | **1** | `persistence/save_types.gd` |

Balance changes use existing fields only. No migration. Existing saves remain valid.

### Ownership (no central BalanceConfig)

| Domain | Owner |
|---|---|
| Story rival Auth | rival `.tres` + `RivalEncounters` |
| Story girl XP gates | girl `.tres` + `Relationships` / discovery |
| Perk cost | `Progression._pow3_int` |
| Salary | `SalaryMine` |
| Media thresholds | `MediaContent` |
| Overload | `DatingOverloadTypes` |
| Local clone | `CloneIncrementalTypes` |
| Global late | `LateGameTypes` |
| Cooldowns 1..3 | `GirlDiscovery` / `Relationships` |

`BALANCE_REPORT.md` records audited numbers and evidence; production APIs remain authoritative.

---

## 2. Anti-grind definition + clean mainline principle

### Anti-grind (Spec §2)

Обязательный grind = ситуация, где для продолжения main story игрок обязан:

```text
повторять уже побеждённого самца
фармить случайных ordinary rivals
завоёвывать случайных ordinary girls
повторять Salary Mine без нового решения
ждать real-time без возможности активно ускорить процесс
спамить End Day только ради обязательного ресурса
повторять одну minigame без сюжетной причины
```

Такого в release balance быть не должно.

Optional content может ускорять/усиливать игрока, но не быть скрытым обязательным налогом.

### Clean mainline principle

```text
MAINLINE / уверенный первый проход: ~3.5–5 часов
NATURAL RUN: ≈ 5–8 часов
100% optional: может быть дольше
```

Clean story:

- zero ordinary rivals required for Authority ladder;
- zero ordinary girls required for XP through Scientist;
- zero perks / zero Money required for story gates;
- story rival loss must never force Authority farm (see §4 / §5);
- President XP10 gap closed by late clone dating XP (+5), not ordinary conquest.

---

## 3. BEFORE — production constants (audited)

Values below are the Wave C production snapshot before / around the story-loss fix.  
AFTER statuses are in §5.

### 3.1 Story Authority ladder (rival `.tres`)

Clean win path: `0 → 2 → 4 → 7 → 10 → 15`.

| Rival | `id` | `is_story` | `required_authority` | `authority_reward` | Auth after clean win |
|---|---|---|---|---|---|
| Actress | `rival_actress` | true | 0 | +2 | 2 |
| Mine Boss | `rival_mine_boss` | true | 2 | +2 | 4 |
| Editor | `rival_magazine_editor` | true | 4 | +3 | 7 |
| Scientist | `rival_scientist` | true | 7 | +3 | 10 |
| President | `rival_president` | true | 10 | +5 | 15 |

**Reward once:** via `GameState.mark_rival_defeated` + `authority_reward` on first win only.

**BEFORE loss rule (buggy for story):**  
`RivalEncounters._resolve_competition_result()` on non-win:

```text
if heroic: authority_delta = 0
else: lose_authority(1)   # applied to story AND ordinary
```

Final exhibition competitions do not mutate Authority (separate exhibition seam; rivals `rival_final_*` are not Earth story ladder).

### 3.2 Story XP gates (girl `.tres`) + Experience economy

First conquest of any girl: `Relationships` → `GameState.add_experience(1)` once (+1 UP atomic).

| Girl | `id` | `is_story` | `required_experience` | Clean XP after conquest |
|---|---|---|---|---|
| Neighbor | `girl_neighbor` | true | 0 | 1 |
| Actress | `girl_actress` | true | 1 | 2 |
| Mine Boss | `girl_mine_boss` | true | 2 | 3 |
| Editor | `girl_magazine_editor` | true | 3 | 4 |
| Scientist | `girl_scientist` | true | 4 | 5 |
| President | `girl_president` | true | **10** | 11 (after +5 late XP) |
| Final Target | `girl_final_target` | true | 0 (no XP gate) | +1 ending |

President gap (intentional): after Scientist XP=5; need +5 late automated Experience before XP10 gate.

### 3.3 Perk cost `3^N`

Source: `Progression.get_next_perk_cost()` → `_pow3_int(purchased_count)`.

| Purchased perks N | Next cost `3^N` |
|---|---|
| 0 | 1 |
| 1 | 3 |
| 2 | 9 |
| 3 | 27 |
| 4 | 81 |
| … | … |

Invariant: Experience → UP atomic (`add_experience` adds equal UP). Story is not perk-gated.

### 3.4 Salary formula

Source: `game/salary/salary_mine.gd`

```text
salary_level = 1 + Authority / 3   (integer division)
gross_per_period = 10 * salary_level
passive (perk Financial Inertia + manual cycle seen) = floor(gross * 0.25)
```

| Authority | Level | Gross |
|---|---|---|
| 0–2 | 1 | 10 |
| 3–5 | 2 | 20 |
| 6–8 | 3 | 30 |
| 9–11 | 4 | 40 |
| 12–14 | 5 | 50 |
| 15–17 | 6 | 60 |

Story ladder checkpoints: Auth 0/2/4/7/10/15 → levels 1/1/2/3/4/6 → gross 10/10/20/30/40/60.

### 3.5 Media thresholds

Source: `game/media/media_content.gd`

| Constant | Value |
|---|---|
| `ATTENTION_MIN` / `ATTENTION_MAX` | 0 / 100 |
| `ARTICLE_ATTENTION` | 15 |
| `ATTENTION_THRESHOLDS` | `[15, 30, 45, 60]` |
| `OVERLOAD_READY_ATTENTION` | 45 |
| `OVERLOAD_READY_OFFERS` | 3 |
| `MAX_THRESHOLD_OFFERS` | 4 |
| Pose attention (per pose) | 10 / 15 / 20 (BASE / STAGED / EDITORIAL) |

### 3.6 Dating Overload

Source: `game/dating_overload/dating_overload_types.gd`

| Constant | Value |
|---|---|
| `PERSONAL_DATE_CAPACITY_PER_DAY` | 1 |
| `BASE_NEW_REQUESTS_PER_DAY` | 2 |
| `FIRST_WAVE_COUNT` | 3 |
| `BOOST_WAVE_COUNT` | 3 |
| `FEED_BOOST_ATTENTION` | 5 |
| `RECOGNITION_MIN_DAYS` | 2 |
| `RECOGNITION_MIN_GENERATED` | 7 |
| `RECOGNITION_MIN_BACKLOG` | 4 |
| `RECOGNITION_MIN_PERSONAL_DATES` | 1 |
| Slots | EARLY 19:00 / LATE 20:00 |

### 3.7 Local clone table (`CloneIncrementalTypes`)

| Constant | Value |
|---|---|
| `MAX_LEVEL` | 5 |
| `BASE_PRODUCTION_INTERVAL` | 30.0 s |
| `PRODUCTION_INTERVAL_STEP` | 5.0 s |
| Interval formula | `30 - 5 * level` → 30…5 |
| `BASE_MONEY_PER_CLONE` | 20.0 /min |
| `MONEY_PER_LEVEL` | +10.0 /min |
| `BASE_DATES_PER_CLONE` | 0.50 /min |
| `DATES_PER_LEVEL` | +0.25 /min |
| `UPGRADE_COST_BASE` | 30 |
| `UPGRADE_COST_FACTOR` | 3 |
| Upgrade cost | `30 * 3^level` (levels 0..4 → 30 / 90 / 270 / 810 / 2430) |

### 3.8 Global late table (`LateGameTypes`)

| Constant | Value |
|---|---|
| `MAX_LEVEL` | 3 |
| `WORLD_REACH_MIN` / `MAX` | 0 / 100 |
| `REACH_PER_LATE_XP` | 2 |
| `OPTIONAL_EVENT_REACH` | 10 |
| `UPGRADE_COST_BASE` | 1000 |
| `UPGRADE_COST_FACTOR` | 5 |
| Upgrade cost | `1000 * 5^level` (0..2 → 1000 / 5000 / 25000) |
| Multiplier | `2^level` |
| `MIN_EFFECTIVE_PRODUCTION_INTERVAL` | 0.5 s |
| Event min Reach | Customs 20 / World Route 50 / Last Continent 80 |

### 3.9 Cooldowns 1..3

| System | Source | Range |
|---|---|---|
| Discovery fail retry | `GirlDiscovery` → `_rng.randi_range(1, 3)` | **1..3** GameDays |
| Date repeat cooldown | `Relationships` → `_rng.randi_range(1, 3)` | **1..3** GameDays |

### 3.10 Ordinary rival Auth (content snapshot)

Ordinary rewards generally 1–2 (release target). Audited production content includes rewards of 1 or 2 only (no ordinary `authority_reward > 2`). Loss: `-1` floor 0 (via `lose_authority(1)`).

---

## 4. Production rule change (MODULE 26)

| Rule | BEFORE | AFTER | WHY |
|---|---|---|---|
| Earth **story** rival loss Authority | `-1` (`lose_authority(1)` for all non-heroic losses) | **0** | Prevents Auth threshold drop that forces ordinary farm to retry story |
| Ordinary rival loss | `-1`, floor 0 | unchanged | Optional risk/reward |
| Heroic Defeat ordinary | 0 | unchanged | Perk identity |
| Final exhibition | 0 (no Auth mutation) | unchanged | Exhibition seam |

Canonical loss document (Spec §126):

```text
Ordinary rival loss: Authority -1, floor 0
Earth story rival loss: Authority 0 — retry must never force optional Authority grind
Final exhibition rival: Authority 0
```

**Only production rule change in MODULE 26:**

```text
Earth story rival loss: Authority -1 → 0
```

**Explicitly: no other production constants were retuned.**  
Clone / Stage6 / President / salary / perk / Media / Overload / cooldown budgets all passed with Wave C audited numbers (see §5–§6).

---

## 5. AFTER — locked constants + evidence

| Domain | BEFORE | AFTER | WHY | TEST EVIDENCE | Status |
|---|---|---|---|---|---|
| Story rival loss Auth | -1 | **0** | Anti-grind: story retry never requires Auth farm | `tmp/m26_a_rival_encounter_test.log` (MODULE_06 ALL PASS 183); `RivalEncounters._resolve_competition_result` story branch | **CHANGED** |
| Story Authority ladder | §3.1 | same `0→2→4→7→10→15` | Exact clean ladder | `tmp/m26_balance_self_test.log` §66 | **LOCKED — passed budget** |
| Story XP gates | §3.2 | unchanged | President XP10 intentional | balance self-test §70 | **LOCKED — passed budget** |
| Perk `3^N` | 1/3/9/27/81… | unchanged | Canon | balance self-test §71–72 | **LOCKED — passed budget** |
| Salary formula | `1+Auth/3`, `10*level` | unchanged | Budgets pass | balance self-test §73 | **LOCKED — passed budget** |
| Media thresholds | §3.5 | unchanged | Min path documented §7 | code audit `MediaContent` | **LOCKED — passed budget** |
| Overload recognition | §3.6 | unchanged | Story-beat requirements | code audit `DatingOverloadTypes` | **LOCKED — passed budget** |
| Local clone | §3.7 | unchanged | President/local budgets pass | balance self-test §78–79 | **LOCKED — passed budget** |
| Global late | §3.8 | unchanged | Stage6 budgets pass | balance self-test §80–81, §83 | **LOCKED — passed budget** |
| Cooldowns 1..3 | §3.9 | unchanged | Instant GameDay advance | balance self-test §75–76 | **LOCKED — passed budget** |
| Save schema | v1 | **v1** | Spec §101 | balance self-test `SAVE_SCHEMA_VERSION == 1` | **LOCKED** |

### Evidence checklist

- [x] Story rival loss Auth = 0 for Earth story rivals  
- [x] Ordinary loss still -1 floor 0  
- [x] Clean ladder 0→2→4→7→10→15  
- [x] Clean XP through Scientist; President XP10 +5 late bridge  
- [x] Perk costs unchanged  
- [x] Clone / Stage6 / President bridge simulations  
- [x] Anti-grind: story loss no farm (rule + harness)  
- [x] Schema v1  
- [ ] Full F5 manual routes A–F — MODULE 27 Wave G: **NOT EXECUTABLE IN ENVIRONMENT** (see §8; no invented F5 PASS)  
- [ ] MODULE02–25 full regression re-run — MODULE 27 ownership (matrix draft in `docs/qa/REGRESSION_MATRIX.md`; full recheck pending)  

### Measured harness results (Wave B)

Source: `tmp/m26_balance_self_test.log` (`MODULE_26_BALANCE: ALL PASS (25)`).

| Budget | Measured | Limit | Result |
|---|---|---|---|
| President A (dating-heavy) | **269 s** | ≤390 | PASS |
| President B (balanced) | **359 s** | ≤390 | PASS |
| President C (3-workers then Dating) | **329 s** | ≤390 | PASS |
| Stage6 no-upgrade Reach100 | **436 s** | ≤480 | PASS |
| Stage6 + optional events | **344 s** | ≤390 | PASS |
| Combined (President + Stage6 no-upgrade) | **795 s** | ≤900 | PASS |
| Local first upgrade (cost 30) | **90 s** | ≤90 | PASS |

Also confirmed in same harness:

- Clean Auth ladder lock `0→2→4→7→10→15`
- Anti-grind story loss: no Authority farm required to retry
- `SAVE_SCHEMA_VERSION == 1`

### Harness + evidence links

| Item | Path |
|---|---|
| Balance harness | [`game/balance/test/`](../../game/balance/test/) (`balance_test.tscn`, `balance_self_test.gd`, `balance_projection.gd`) |
| Rival / story-loss regression log | [`tmp/m26_a_rival_encounter_test.log`](../../tmp/m26_a_rival_encounter_test.log) |
| Balance projection log | [`tmp/m26_balance_self_test.log`](../../tmp/m26_balance_self_test.log) |

---

## 6. Media → Overload minimum action path

Sources: `MediaContent`, `Media.complete_photo_session`, `Media.publish_photo`, thresholds `[15, 30, 45, 60]`.

**Overload ready when:**

```text
Attention >= 45
AND incoming offers >= 3
```

Offers are granted by threshold crossings (1 offer per crossed threshold, max 4). Pose attention on publish: BASE **10** / STAGED **15** / EDITORIAL **20**. Article on session complete: **+15**. One photo publish per GameDay.

### Minimum competent path (current production constants)

| Step | Action | Attention after | Offers after |
|---|---|---|---|
| 1 | Required Photo Session → `complete_photo_session` (Editor article +15; stores 3 poses) | 15 | 1 (threshold 15) |
| 2 | Publish best pose (EDITORIAL +20) | 35 | 2 (threshold 30) |
| 3 | `GameDay.advance_day()` (unlock next publish) | 35 | 2 |
| 4 | Publish any remaining pose (≥ BASE +10) | **≥45** | **3** (threshold 45) → `overload_ready` |

**Counts as minimum story Media actions:**

```text
1× Photo Session (includes Editor article)
+ 2× photo publishes
+ 1× End Day between publishes
```

No Media constant retune: path needs no empty multi-day photo farming beyond the one day-lock between publishes. Feed Boost (+5) is a post-activation Overload tool, not required to reach `overload_ready`. Threshold 60 (4th offer) is optional escalation only.

---

## 7. Minigame duration audit

Catalog expected windows (`data/content/competitions/competition_*.tres`) plus match `is_story` scaling (`target_score` 3 ordinary / 5 story; Dance sequence 3 / 4; Sigma disturbance count 1 / 2).

| Family | Catalog expected (s) | Ordinary typical (clean) | Story typical (clean) | Inputs / rounds (clean win) | Story >90s? | Tuning |
|---|---|---|---|---|---|---|
| SLAP | 25–45 | ~25–45 s (score 3) | ~40–75 s (score 5) | 3 / 5 scoring hits | **No** | none |
| DANCE | 30–50 | ~25–45 s (seq 3, score 3) | ~45–75 s (seq 4, score 5) | 3 / 5 successful sequences | **No** | none |
| SIGMA | 30–60 | ~30–55 s (score 3; hold 3 s) | ~45–80 s (score 5; more disturbances) | 3 / 5 hold completions; no single hold >20 s | **No** | none |
| MONEY | 20–40 | ~20–40 s (score 3) | ~30–70 s (score 5) | ≤5 successful stake rounds story; story always has non-MONEY fallback | **No** | none |

**Flag:** no story typical clean-success path audited above **90 s**. No minigame numeric retune in MODULE 26.

Spec targets remain: ordinary 20–60 s; story / final exhibition 30–90 s (including result presentation, excluding walk-to-actor).

---

## 8. Manual routes A–F status

| Route | Spec | Status |
|---|---|---|
| A Clean (zero ordinary / zero perk / free story) | §113 | **Balance-harness covered** for economy / Auth / XP / Money0 / clone budgets. MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT**. Scripted mainline: Wave C `full_game_integration` **PASS (157)**. |
| B Imperfect (story losses / discovery fails) | §114 | **Harness-covered** for story loss Auth=0. MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT**. Scripted imperfect/recovery: Wave C integration **PASS**. |
| C Optional ordinary | §115 | Content optional; not required by harness. MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT**. |
| D Broke / Capital-less | §116 | **Harness-covered** (story Money0 static + Stage6 Money0 / no global). MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT**. |
| E Specialized build | §117 | MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT** (no invented PASS). |
| F No clone upgrades | §118 | **Harness-covered** (President A/B/C + Stage6 no-upgrade). MODULE 27 F5: **NOT EXECUTABLE IN ENVIRONMENT**. |

**Assessment vs natural run 5–8 h:** economy / clone-era budgets fit mainline pacing (combined required incremental **795 s** sim-only). Full F5 manual timing of routes A–F against the 5–8 h natural-run goal was **not executed** in MODULE 27 Wave G agent environment — status remains honest **NOT EXECUTABLE / PARTIAL (scripted only)**. See `docs/qa/FULL_GAME_QA_REPORT.md` and `docs/qa/KNOWN_ISSUES.md`.

---

## 9. Links

| Doc | Path |
|---|---|
| MODULE 26 Spec | [`docs/modules/MODULE_26_BALANCE_ANTI_GRIND.md`](../modules/MODULE_26_BALANCE_ANTI_GRIND.md) |
| Report ownership (§99 / §100) | Spec §99–101 |
| Canonical male loss (§126) | Spec §126 · GDD [`04_male_status_system.md`](../gdd/04_male_status_system.md) §13.1 |
| Project status after MODULE26 (§127) | Spec §127 · [`PROJECT_STRUCTURE.md`](../PROJECT_STRUCTURE.md) |
| Cursor final report shape (§130) | Spec §130 |
| MODULE 27 Full Game QA | [`docs/qa/FULL_GAME_QA_REPORT.md`](../qa/FULL_GAME_QA_REPORT.md) · matrix / known issues under `docs/qa/` |
| Next module | MODULE 28 — Release Integration (only after MODULE 27 Orchestrator PASS) |

### Audited source files

```text
game/balance/test/
game/clone_incremental/clone_incremental_types.gd
game/late_game/late_game_types.gd
game/media/media_content.gd
game/dating_overload/dating_overload_types.gd
game/salary/salary_mine.gd
game/progression/progression.gd
game/rivals/rival_encounters.gd
game/girls/girl_discovery.gd
game/relationships/relationships.gd
persistence/save_types.gd
data/content/rivals/rival_{actress,mine_boss,magazine_editor,scientist,president}.tres
data/content/girls/girl_{neighbor,actress,mine_boss,magazine_editor,scientist,president,final_target}.tres
data/content/competitions/competition_{slap,dance,sigma,money}.tres
minigames/{slap,dance,sigma,money}/*_match.gd
```
