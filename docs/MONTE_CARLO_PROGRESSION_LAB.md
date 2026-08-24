# Monte Carlo Progression Lab — Implementation Specification

## Цель

Реализовать developer-инструмент для количественного анализа progression, экономики и pacing Stage 1–4.

Инструмент моделирует популяцию игроков через:

```text
Seed
→ Player Profile
→ immutable StagePlan
→ deterministic Stage Executor
→ production gameplay rules
→ Run Metrics
→ population statistics
→ bad-seed detection
→ export
```

Главный принцип симуляции:

> RNG в начале каждого Stage определяет полный набор долгосрочных намерений игрока на этот Stage. Executor затем выполняет именно этот фиксированный набор целей, выбирая конкретный следующий action рационально по текущему production state.

Такой подход моделирует игрока, который заранее решил:

```text
закрыть 3 filler girls
прокачать Внешность до 3
купить 2 предмета квартиры
победить обоих ordinary rivals
получить 1 новый Outfit
```

и затем последовательно пытается выполнить этот план.

---

# 1. Progression semantic finalization

Перед Monte Carlo implementation доведи current Stage semantics до одного source of truth.

## StageDefinition

`StageDefinition` является canonical source для:

```text
filler_girl_ids
story_girl_id
ordinary_rival_ids
story_rival_id
required_filler_max_count
story_girl_required_rating
```

Girl access requirements и Rival access requirements получают Stage data из `StageDefinition`.

## Story Stage requirement

Используй canonical naming:

```text
MinStoryStageGirlRequirement
minimum_story_stage
```

Girl availability пересчитывается по Story Stage progression events.

City Stage продолжает обслуживать physical world expansion.

---

# 2. Scope симуляции

Monte Carlo Lab моделирует:

```text
Story Stage 1
Story Stage 2
Story Stage 3
Story Stage 4
```

Каждый Run начинается из canonical new-game state Stage 1 и выполняется до выбранного `end_story_stage`.

Config:

```text
end_story_stage = 1..4
```

Default:

```text
end_story_stage = 4
```

Metrics сохраняются отдельно для каждого Stage и для всего Run.

---

# 3. Production-rule execution

Каждый simulation Run создаёт изолированный `GameState` с canonical new-game setup.

Executor использует production services и production actions для:

```text
work
characteristic training
girl discovery / dating
Date Engine
Rivals
Outfit purchase
Apartment Object purchase
Venue selection
Apartment preparation
Story progression
Daily Activity
Rating
Relationship
reward acquisition
time / day progression
```

Вся симуляция выполняется на отдельном state instance.

После Run state уничтожается.

Production save пользователя и активная Developer Room state остаются отдельными от simulation state.

---

# 4. Deterministic seed architecture

Каждый Run имеет:

```text
base_seed: int64
```

Из него детерминированно получаются независимые RNG streams.

Streams:

```text
PROFILE
CAMPAIGN_INTEREST
STAGE_PLAN_1
STAGE_PLAN_2
STAGE_PLAN_3
STAGE_PLAN_4
EXECUTION_1
EXECUTION_2
EXECUTION_3
EXECUTION_4
DATE
GIRL_KNOWLEDGE
```

Реализуй stable seed derivation через SHA-256:

```text
input = "<base_seed>:<stream_name>"
sha256(input UTF-8)
derived_seed = first 8 bytes interpreted as unsigned 64-bit
```

Используй derived seed как seed Godot `RandomNumberGenerator`.

Одинаковые:

```text
game content
simulation config
base seed
```

создают одинаковый Player Profile, StagePlans и execution path.

---

# 5. Simulation archetypes

Canonical archetypes:

```text
EFFICIENT
TYPICAL
EXPLORER
CHAOTIC
```

Population default weights:

```text
EFFICIENT = 0.15
TYPICAL   = 0.50
EXPLORER  = 0.25
CHAOTIC   = 0.10
```

UI позволяет:

```text
single archetype
or POPULATION
```

`POPULATION` выбирает archetype один раз на Run по этим weights.

---

# 6. Player Profile traits

Каждый archetype задаёт center values для семи traits:

```text
completionism
exploration
build_ambition
spending_impulsiveness
planning_skill
dating_skill
whimsy
```

Canonical centers:

| Trait | Efficient | Typical | Explorer | Chaotic |
|---|---:|---:|---:|---:|
| completionism | 0.20 | 0.45 | 0.85 | 0.60 |
| exploration | 0.20 | 0.50 | 0.95 | 0.75 |
| build_ambition | 0.55 | 0.55 | 0.70 | 0.80 |
| spending_impulsiveness | 0.15 | 0.45 | 0.60 | 0.90 |
| planning_skill | 0.95 | 0.65 | 0.55 | 0.30 |
| dating_skill | 0.90 | 0.70 | 0.60 | 0.40 |
| whimsy | 0.10 | 0.25 | 0.35 | 0.70 |

Для каждого trait один раз на Run:

```text
u1 = rng.randf()
u2 = rng.randf()

value = clamp(center + (u1 + u2 - 1.0) * 0.15, 0.0, 1.0)
```

Эти значения сохраняются на весь Campaign Run.

---

# 7. Campaign-wide personal interests

В начале Run с stream `CAMPAIGN_INTEREST` сгенерируй:

```text
girl_interest[girl_id] = randf()
rival_interest[rival_id] = randf()
tag_interest[tag_id] = randf()
venue_interest[venue_id] = randf()
characteristic_interest[characteristic_id] = randf()
```

Эти interests стабильны во всех Stage одного Run.

Они моделируют личные предпочтения конкретного simulated player.

---

# 8. Immutable StagePlan

При входе в каждый Story Stage сгенерируй ровно один `StagePlan`.

После генерации StagePlan сохраняется immutable до конца Stage.

StagePlan содержит:

```text
stage
target_filler_girl_ids
target_ordinary_rival_ids

characteristic_targets
target_outfit_count
target_apartment_object_count

venue_visit_goals

story_girl_id
story_rival_id

plan_decisions
```

`plan_decisions` содержит human-readable причины всех сгенерированных намерений для export log.

Executor выбирает действия только для достижения целей из StagePlan и обязательной Story progression.

---

# 9. Filler target generation

Каждый Stage 1–4 имеет три filler girls.

Сначала:

```text
target_count = 2
```

Затем:

```text
if rng.randf() < completionism:
    target_count = 3
```

Для каждой filler girl вычисли:

```text
selection_score =
    0.75 * girl_interest[girl_id]
    + 0.25 * rng.randf()
```

Отсортируй по score descending.

Возьми первые `target_count`.

В StagePlan сохрани:

```text
"Решил довести до MAX: Marina, Katya"
```

или:

```text
"Решил довести до MAX всех трёх filler girls"
```

---

# 10. Ordinary Rival target generation

Для каждого ordinary rival текущего Stage:

```text
engage_probability =
    clamp(
        0.10
        + 0.70 * completionism
        + 0.20 * exploration,
        0.0,
        1.0
    )
```

Вычисли:

```text
interest_adjustment =
    lerp(0.75, 1.25, rival_interest[rival_id])
```

Final probability:

```text
clamp(engage_probability * interest_adjustment, 0.0, 1.0)
```

Один roll определяет участие в этом rival content на весь Stage.

Story Rival всегда входит в mandatory Story progression.

---

# 11. Characteristic target generation

Characteristic targets генерируются один раз при входе в Stage.

Для каждой из четырёх Characteristics:

```text
target_probability =
    clamp(
        0.10
        + 0.50 * build_ambition
        + 0.10 * exploration,
        0.0,
        1.0
    )
```

Умножь probability на:

```text
lerp(0.80, 1.20, characteristic_interest[id])
```

Roll определяет наличие Characteristic goal.

## Target milestone

Canonical milestones:

```text
1
3
5
```

Найди первый milestone выше current permanent value.

Он становится базовым target.

Затем:

```text
deep_build_probability =
    0.10 + 0.50 * build_ambition
```

Если существует следующий milestone и roll проходит:

```text
target = next milestone
```

Пример StagePlan:

```text
Мышца: current 0 → target 1
Внешность: current 0 → target 3
Аура: current 1 → target 3
Капитал: no additional target
```

StagePlan сохраняет target values до конца Stage.

---

# 12. Outfit acquisition plan

## Stage 1

```text
target_outfit_count = 0
```

## Stage 2

StagePlan всегда содержит цель:

```text
Acquire at least 1 DRESSED Outfit
```

Это соответствует objective `Приоденься`.

Дополнительные Outfit определяются через три Bernoulli rolls:

```text
p_outfit_extra =
    clamp(
        0.05
        + 0.35 * build_ambition
        + 0.25 * exploration
        + 0.25 * spending_impulsiveness,
        0.0,
        1.0
    )
```

```text
target_outfit_count =
    1
    + Binomial(3, p_outfit_extra)
```

Range:

```text
1..4
```

## Stage 3 / Stage 4

Для четырёх новых Outfit текущего Stage:

```text
target_outfit_count =
    Binomial(4, p_outfit_extra)
```

---

# 13. Outfit selection

Когда StagePlan выбирает конкретные Outfit, оцени каждый available current-stage Outfit:

```text
characteristic_relevance =
    1.0 if outfit bonus characteristic has unmet target
    else 0.0
```

```text
tag_relevance =
    tag_interest[outfit_move_tag]
```

Для stat-only Outfit:

```text
tag_relevance = 0.0
```

Score:

```text
0.55 * characteristic_relevance
+ 0.25 * tag_relevance
+ 0.20 * rng.randf()
```

Выбери `target_outfit_count` highest-scoring distinct Outfit.

Marina free reward удовлетворяет ту же acquisition goal, если выбранный бесплатный Outfit входит в target list.

Если reward становится доступен раньше ordinary purchase, executor выбирает highest-scoring unowned target Outfit через canonical Marina ordinary-store flow.

---

# 14. Apartment purchase plan

Stage 1:

```text
target_apartment_object_count = 0
```

Stage 2–4 имеют по четыре новых Apartment Objects.

Для каждого из четырёх:

```text
p_object =
    clamp(
        0.05
        + 0.45 * build_ambition
        + 0.25 * exploration
        + 0.20 * spending_impulsiveness,
        0.0,
        1.0
    )
```

Каждый объект получает Bernoulli roll.

Количество успешных rolls:

```text
target_apartment_object_count
```

---

# 15. Apartment object selection

Для каждого нового available Apartment Object вычисли:

```text
tag_score = tag_interest[object_tag]
```

```text
known_positive_coverage =
    fraction of currently known targeted girls
    whose known positive tags include object_tag
```

StagePlan generation использует только информацию, реально доступную simulated player на момент входа в Stage.

Score:

```text
0.55 * tag_score
+ 0.30 * known_positive_coverage
+ 0.15 * rng.randf()
```

Выбери highest-scoring objects в количестве `target_apartment_object_count`.

---

# 16. Venue exploration plan

Для каждого DateVenue, который впервые становится gameplay-available на текущем Stage:

```text
visit_probability = exploration
```

Roll создаёт goal:

```text
visit venue at least once during this Stage
```

Stage 2 candidates:

```text
Café
Leisure Center
```

Stage 3 candidate:

```text
Restaurant
```

Apartment существует до Stage 2 и не получает new-venue exploration goal.

---

# 17. Complete Stage goal pool

После StagePlan generation собери полный pool:

```text
mandatory Story progression
selected filler MAX goals
selected ordinary Rival goals
Characteristic target goals
Outfit acquisition goals
Apartment purchase goals
Venue exploration goals
```

Сохрани этот pool в StagePlan до первого execution action Stage.

Human-readable example:

```text
STAGE 2 PLAN

Filler:
- Marina → MAX
- Katya → MAX
- Lera → skip

Rivals:
- Denis → engage
- Roman → skip

Characteristics:
- Appearance 1 → 3
- Aura 0 → 1

Outfit:
- acquire 2 Stage 2 Outfit
- priorities: Stylish, Minimal Black

Apartment:
- buy 2 objects
- priorities: TV, Plaid

Venue exploration:
- visit Leisure Center at least once
- Café visit goal absent

Story:
- Mine Boss mandatory
- Foreman mandatory
```

---

# 18. StagePlan commitment

Stage Executor reads the generated StagePlan as immutable.

Long-term goals stay identical throughout the Stage.

Dynamic gameplay information controls:

```text
which goal can progress now
which specific production action is available
which Date Move is selected
which Venue best serves a planned Date
which support action is required
```

The executor does not generate additional long-term Stage goals after StagePlan creation.

---

# 19. Goal priority values

Assign exact base priorities:

```text
mandatory Stage-2 dress-up acquisition = 100

current-stage targeted filler Date progress = 90
Story Rival = 90

Characteristic target = 75
planned Outfit acquisition = 70
planned Apartment Object acquisition = 65
planned ordinary Rival = 60
Venue exploration = 35

Story Girl relationship before plan barrier complete = 55
Story Girl relationship after plan barrier complete = 100
```

`plan barrier complete` means every optional goal generated in StagePlan is complete.

This allows the simulated player to finish the plan it chose before triggering Story Girl MAX and leaving the Stage.

---

# 20. Candidate-action scoring

At each decision point collect production-valid candidate actions that advance at least one unmet StagePlan goal or its support dependency.

Score:

```text
score =
    goal_base_priority
    + daily_gate_bonus
    + unblock_bonus
    + novelty_bonus
    - repetition_penalty
    + decision_noise
```

Exact values:

```text
daily_gate_bonus = +20
```

Apply to a direct goal action with an unused today-only opportunity:

```text
Date
Rival
Characteristic training
Work
```

```text
unblock_bonus = +25
```

Apply when action directly removes a blocker from a higher-priority goal.

Examples:

```text
buy mandatory DRESSED Outfit
prepare Apartment for planned Date
earn missing cash for target purchase
```

```text
novelty_bonus = +10
```

Apply when the action uses content the Run has never used before:

```text
new girl
new Rival
new Venue
new Outfit
new Apartment Object
```

Repetition applies only to a candidate that continues the current primary activity:

```text
if candidate_primary_activity == previous_primary_activity:
    repetition_penalty =
        8 * current_consecutive_same_primary_action_count
else:
    repetition_penalty = 0
```

Example after three consecutive WORK actions: WORK penalty = 24, DATE penalty = 0, TRAINING penalty = 0.

Decision noise uses the per-stage `EXECUTION_n` stream (`_execution_rng`):

```text
noise_amplitude =
    15.0 * (1.0 - planning_skill)

decision_noise =
    _execution_rng.randf_range(-noise_amplitude, +noise_amplitude)
```

Score every candidate with noise first, then choose highest final score.

Tie break:

```text
lowest stable content ID lexical order
```

after deterministic noise has been applied.

---

# 21. Cash dependency model

For every unmet goal with a money requirement calculate current cash gap through production prices of the **concrete planned action**. See 23.5. Story Girl Date is included when the barrier allows it.

Examples:

```text
training
Outfit
Apartment Object
Venue fee
Rita taxi
Accent reassignment
```

Work becomes a support candidate when at least one planned goal is currently blocked by cash.

Attach each Work action to the highest-priority cash-blocked goal:

```text
supporting_goal_id
```

Work candidate base score:

```text
blocked_goal_priority - 5
```

Then apply normal:

```text
daily_gate_bonus
repetition_penalty
decision_noise
```

Every Work action therefore has a concrete reason in logs.

Example:

```text
WORK
supporting_goal = characteristic:appearance:3
cash_before = 40
cash_needed = 150
```

---

# 22. Goal support attribution

Every support action stores:

```text
supporting_goal_id
```

Support categories:

```text
WORK
APARTMENT_PREPARATION
REQUIRED_PURCHASE
```

Direct progress actions store:

```text
direct_goal_id
```

This attribution is used for `Goal Friction` metrics.

---

# 23. Stage end

Stage completion occurs when:

```text
StagePlan barrier complete
+
Story Girl reaches MAX
```

The executor then enters the next Story Stage.

The next Stage generates a fresh immutable StagePlan using that Stage's dedicated RNG stream and the carried production state.

Campaign-level profile/interests remain unchanged.

Story Girl relationship is gated by the immutable StagePlan barrier. While the barrier is incomplete, Story Girl Date candidates stop at `production_MAX - 1`. After the barrier is complete, the next Story Girl Date may reach MAX and production Stage transition runs.

Isolated runs set `StageService.auto_complete_enabled = false` and disconnect production Stage auto-complete (`girl_relationship_changed` and `expansion_changed`). `get_catalog()` can resubscribe those signals, so the flag is the isolation that actually holds. A Stage then advances only when the executor calls `try_complete_current_stage()` after the StagePlan barrier is complete and Story Girl is at MAX. The transition assertion uses barrier/MAX status captured immediately after the successful action, before that production complete call.

If Story Stage advances, the barrier was complete immediately before the transition and Story Girl is at MAX as a result of the production action.

---

# 23.1 Date loadout and eligibility

Date candidate construction selects the planned Outfit and Venue before the final production eligibility check.

```text
owned Outfit candidates
→ Outfit score
→ planned Outfit
→ Venue candidates
→ planned Venue
→ temporary loadout context
→ production Date eligibility
→ Date candidate
```

OutfitAboveCasual is evaluated against the selected Outfit, not the currently equipped casual Outfit. Execution equips the same planned Outfit/Venue before starting the production Date.

---

# 23.2 Failed candidates and stall detection

Candidate existence does not count as progress. A decision cycle succeeds only when the selected action actually executes.

`_execute_candidate()` returns:

```text
success
failure_code
failure_reason
```

Failed candidates are retried from a rebuilt snapshot with the failed identity excluded. Repeated failed or empty cycles skip the calendar day.

```text
max_consecutive_stalled_days = 8
```

reaches `NO_USEFUL_ACTIONS_STAGE_<n>` with a diagnostic snapshot instead of looping until `max_calendar_days`. Safety cap remains the last-resort limit.

Detailed replay records `FAILED CANDIDATE` blocks and stall-day unmet goals. Seeds `7, 22, 24, 31, 47, 84, 90` are the deterministic regression set from the N=100 deadlock run.

---

# 23.3 Per-stage economy consistency

Successful WORK and spending actions update both campaign and current-stage:

```text
money_earned
money_spent
minimum_money
```

from actual production money deltas. Goal Friction completion is written to both campaign and stage metrics. After a full campaign:

```text
sum(stage.money_earned) == campaign.money_earned
sum(stage.money_spent) == campaign.money_spent
sum(stage.total_actions) == campaign.total_actions
```

`money_blocked_days` and `max_consecutive_money_blocked_days` are extra diagnostics. The hard warning still uses `money_blocked_decision_points`.

---

# 23.4 Summary vs detailed replay

`detailed` is telemetry-only. For the same production content, config, `base_seed`, archetype mode and `end_story_stage`:

```text
run_seed(seed, detailed = false)
run_seed(seed, detailed = true)
```

produce one simulation outcome. Logging mode does not consume RNG, change candidates, Date/Venue/Outfit choice, production state, metrics, warnings or stop reason.

Each Run stores `execution_signature`: SHA-256 of a canonical payload with stable key order:

```text
base_seed, archetype, profile, interests, StagePlans
ordered executed actions
ordered failed-candidate identities that affected retry
Date decisions
Story Stage transitions
final progression snapshot (stage, money, relationships)
campaign metrics, stage metrics
stop reason, hard warnings
RNG draw counts per stream
```

Excluded: timestamps, wall-clock, file paths, UI progress, Markdown formatting.

Pass 2 detailed replay of a Pass 1 seed must match `execution_signature`. Mismatch is `REPLAY_DETERMINISM_MISMATCH` with a first-difference diagnostic. Detailed Markdown/JSON logs are written only after that check. After N=100, verification replays seeds `1..100` without Markdown export.

RNG consumption is outside `if detailed` branches. Per-stream draw counts (`PROFILE`, `CAMPAIGN_INTEREST`, `STAGE_PLAN_1..4`, `EXECUTION_1..4`, `DATE`, `GIRL_KNOWLEDGE`) must match between summary and detailed replay. Each `_run_seed` uses a fresh isolated PlaythroughSession and a new StageExecutor. `GIRL_KNOWLEDGE` seeds production initial-tag reveals on contact so girl knowledge does not use `randomize()` during a lab run.

---

# 23.5 Cash dependency snapshot

One `cash_dependencies[]` snapshot is the source of truth at each decision point. Each row:

```text
goal_id
action_id
action_type
required_money
current_money
cash_gap
priority
```

`required_money` is the production cost of the concrete planned action (Date uses the selected Outfit/Venue/taxi/express styling, not a cheapest-venue estimate). Story Girl Date is included when the StagePlan barrier allows it and the planned Date is production-eligible except for money.

From this snapshot the executor derives cash-blocked goals, `money_blocked_decision_points`, Goal Friction money blocks, WORK support (`supporting_goal_id`, `supporting_action_id`, `cash_gap`) and diagnostic fields. WORK binds to the highest-priority cash-blocked row.

---

# 23.6 Rival StagePlan goals

Ordinary Rival goals are one-shot StagePlan intents. `is_rival_goal_complete(goal_id, rival_id)` is true after a production victory. A completed ordinary Rival no longer generates a direct Rival candidate, even if production still allows a repeatable rematch.

`story_rival_id` is a mandatory Stage goal `story_rival:<rival_id>:defeat` until defeated. It appears in unmet goals, barrier, Goal Friction, diagnostics and exports.

Story Rival candidates follow production state:

```text
LOCKED → no candidate
AVAILABLE_TO_MEET → MEET
DISCOVERED + AVAILABLE_TO_CHALLENGE → CHALLENGE
DAILY_GATED → no direct candidate
DEFEATED → goal complete
```

Meet/challenge exist only when production availability confirms them (including linked Story Girl and Story Stage). If Story Girl Date is blocked by an undefeated Story Rival, the executor follows Story Rival meet/challenge rather than leaving an invisible prerequisite.

Diagnostic rival rows include ordinary targets and the Story Rival: `rival_id`, `goal_type`, `discovered`, `defeated`, meet/challenge availability, daily gate, `linked_girl_id`, `blocking_reason`.

---

# 23.7 Bad seeds vs Top K

`all_bad_seeds` is every Run with `badness_score >= threshold` or `hard_warnings.size() > 0`.

`top_bad_seeds` is the first `bad_seed_count_display` (default 25) after sorting by hard-warning count desc, badness desc, `base_seed` asc.

```text
bad_seed_count = all_bad_seeds.size()
bad_seed_percentage = bad_seed_count / N
```

`bad_seeds.csv` exports **all** bad seeds. Detailed bad-seed logs replay only `top_bad_seeds`. Overview and `share_bundle` show the full count/percentage and then the Top K list. Warning prevalence (`warning_id`, `run_count`, `run_share`) is exported after each population run. MONEY_BLOCKED / GOAL_FRICTION / DEAD_PROGRESS_STREAK thresholds stay unchanged in this pass.

---

# 24. Date simulation

Every Date uses the production Date Engine:

```text
5 episodes
production Situation eligibility
production BASE 3/3 split
Characteristic Source
Outfit Source
Venue Source
Vika
Dasha
Katya
Sonya
Nika
current girl knowledge
current Traits
current scoring
```

Date decisions use the simulated player's `dating_skill`, `planning_skill` and `whimsy`.

---

# 25. Date Move utility

For every currently selectable Move calculate player-visible utility.

## Known positive Tag

```text
base_utility = +100
```

## Unknown Tag

Calculate public probability using the same information exposed by the girl's preference counters:

```text
p_positive =
    remaining_unknown_positive_count
    /
    total_unknown_count
```

Expected score:

```text
expected =
    p_positive * 1
    + (1 - p_positive) * -1
```

Map to utility:

```text
base_utility = 35 * expected
```

## Known negative Tag

```text
base_utility = -80
```

---

# 26. Date bonus awareness

Add actual visible scoring modifiers to utility.

Examples:

```text
Characteristic Trait
Venue Trait
Katya Accent
Sonya extra Venue use
Dasha first-negative protection
```

For each expected additional Relationship point:

```text
utility += 25
```

---

# 27. Extra-source conservation

For CHARACTERISTIC / OUTFIT / VENUE source Moves with one remaining use:

```text
remaining_episode_ratio =
    remaining_episodes_after_current / 4.0
```

Conservation penalty:

```text
25
* remaining_episode_ratio
* planning_skill
```

BASE Moves use:

```text
conservation penalty = 0
```

Restaurant + Sonya calculates remaining Venue uses through production state.

---

# 28. Date decision noise

For each Move:

```text
noise_amplitude =
    80
    * (1.0 - dating_skill)
    + 40
    * whimsy
```

```text
move_noise =
    rng.randf_range(-noise_amplitude, +noise_amplitude)
```

Final:

```text
move_utility =
    base utility
    + bonus awareness
    - conservation penalty
    + move_noise
```

Choose highest utility valid Move.

---

# 29. Venue selection for a Date

For every production-available Venue calculate:

```text
known_positive_coverage =
    count available Local Moves with known positive Tags
```

```text
unknown_coverage =
    count available Local Moves with unknown Tags
```

```text
known_negative_coverage =
    count available Local Moves with known negative Tags
```

```text
trait_bonus =
    1 if girl's Venue Trait matches
    else 0
```

```text
exploration_goal_bonus =
    1 if StagePlan has unmet visit goal for this Venue
    else 0
```

Score:

```text
venue_score =
    35 * known_positive_coverage
    + 8 * unknown_coverage
    - 20 * known_negative_coverage
    + 30 * trait_bonus
    + 25 * exploration_goal_bonus
    + 15 * venue_interest[venue_id]
    - normalized_price_pressure
```

Price pressure:

```text
normalized_price_pressure =
    40
    * venue_price
    / max(current_money + expected_one_work_income, 1)
    * planning_skill
```

Add:

```text
rng.randf_range(-20, 20) * whimsy
```

Choose highest score.

Apartment preparation uses production rules after Apartment is selected.

---

# 30. Outfit selection for a Date

From owned Outfit calculate:

```text
effective Characteristic unlock value
Outfit Move known-tag value
planned Characteristic relevance
```

Score:

```text
40 * number_of_newly_satisfied_characteristic_requirements
+ 30 * known_positive_outfit_move
+ 10 * unknown_outfit_move
+ 20 * planned_characteristic_relevance
+ rng.randf_range(-15, 15) * whimsy
```

Choose highest score.

If the girl requires OutfitAboveCasual, casual-tier Outfit are excluded from this ranking.

Nika Backup Outfit uses the two highest-scoring distinct owned Outfit when reward is active.

This planned Outfit is stored on the Date candidate and used for both eligibility evaluation and execution.

---

# 31. Primary activity categories

Every simulation action is mapped to:

```text
WORK
TRAINING
DATE
RIVAL
PURCHASE
APARTMENT_PREPARATION
STORY
OTHER
```

---

# 32. Progress beat definition

A `Progress Beat` occurs when an action causes at least one:

```text
Relationship increase
new Tag reveal
Characteristic increase
Outfit acquired
Apartment Object acquired
Rival defeated
filler reward acquired
Rating increase
new Venue available
new Outfit tier/content available
new Apartment content available
Story Girl discovered
Story Rival unlocked
Story Stage advanced
```

A calendar day with zero Progress Beats is:

```text
dead_progress_day
```

Track both:

```text
dead_progress_days
max_consecutive_dead_progress_days
```

---

# 33. Core Run metrics

For each Stage and total Campaign collect:

```text
calendar_days
total_actions

work_actions
training_actions
dates
rival_attempts
rival_wins
purchases
apartment_preparations

dates_by_girl
dates_to_max_by_girl

money_earned
money_spent
money_end
minimum_money

outfits_acquired
apartment_objects_acquired
characteristic_upgrades

rating_start
rating_end

money_blocked_decision_points
daily_gate_blocked_decision_points

These campaign/stage metrics count **decision points**, not blocked goals.

At one decision point:

```text
0 blocked goals → +0
1 blocked goal  → +1
5 blocked goals → +1
```

If at least one unmet planned goal is money-blocked, `money_blocked_decision_points += 1`. If at least one is daily-gate-blocked, `daily_gate_blocked_decision_points += 1`. Each type is counted at most once per decision point.

Detailed seed logs include the blocked goal lists for that decision point:

```text
Money-blocked goals:
- <goal_id>

Daily-gate-blocked goals:
- <goal_id>
```

progress_beats
dead_progress_days
max_consecutive_dead_progress_days

unique_situations_seen
unique_moves_used
unique_venues_used

max_consecutive_same_primary_action
max_consecutive_work_actions
max_consecutive_work_only_days
```

---

# 34. Work-only day

A calendar day is `work_only_day` when:

```text
work_actions > 0
```

and that day contains zero:

```text
DATE
RIVAL
TRAINING
PURCHASE
STORY
```

Track:

```text
work_only_days
max_consecutive_work_only_days
```

---

# 35. Goal Friction

For each StagePlan goal collect:

```text
direct_actions
support_actions
calendar_days_from_first_attempt_to_completion
blocked_by_money_count
blocked_by_daily_gate_count
```

Per-goal blocking counts increment for **each blocked goal** at the decision point, independently of the campaign decision-point counters.

Example: three money-blocked goals at one decision point give `money_blocked_decision_points += 1` and `blocked_by_money_count += 1` on each of those three goals.
```

Friction ratio:

```text
goal_friction_ratio =
    support_actions
    / max(direct_actions, 1)
```

Store:

```text
max_goal_friction_ratio
mean_goal_friction_ratio
highest_friction_goal_id
```

---

# 36. Economy support share

Calculate:

```text
economy_support_share =
    work_actions
    / max(total_actions, 1)
```

Maintenance share:

```text
maintenance_share =
    (work_actions + apartment_preparations)
    / max(total_actions, 1)
```

---

# 37. Novelty density

Count first-time content beats:

```text
first girl interaction
first Rival interaction
first Venue use
first Outfit acquisition
first Apartment Object acquisition
first Situation
first Move ID
first reward
Story unlock
```

Metric:

```text
novelty_density =
    novelty_events
    / max(total_actions, 1)
```

---

# 38. Purchase utility

For every acquired Outfit and Apartment Object track after purchase:

```text
times_considered
times_selected
times_produced_positive_score
times_unlocked_requirement
```

Aggregate by item ID:

```text
purchase_rate
consideration_rate
use_rate
positive_impact_rate
```

---

# 39. Population statistics

For every numeric metric calculate:

```text
count
mean
standard deviation
min
P10
P25
P50
P75
P90
P95
max
```

Produce statistics:

```text
overall
per archetype
per Stage
per archetype per Stage
```

---

# 40. Badness Score

After all N summary runs complete, calculate percentile rank `0..1` for these metrics:

```text
max_consecutive_work_only_days
economy_support_share
money_blocked_decision_points
daily_gate_blocked_decision_points
dead_progress_days
calendar_days
max_goal_friction_ratio
1 - novelty_density
```

Per Run:

```text
badness =
    0.20 * percentile(max_consecutive_work_only_days)
    + 0.15 * percentile(economy_support_share)
    + 0.15 * percentile(money_blocked_decision_points)
    + 0.10 * percentile(daily_gate_blocked_decision_points)
    + 0.10 * percentile(dead_progress_days)
    + 0.10 * percentile(calendar_days)
    + 0.10 * percentile(max_goal_friction_ratio)
    + 0.10 * percentile(1 - novelty_density)
```

Convert:

```text
badness_score = round(badness * 100)
```

---

# 41. Hard bad-seed flags

A Run receives a hard warning when any condition is true:

```text
max_consecutive_work_only_days >= 4

max_consecutive_dead_progress_days >= 2

money_blocked_decision_points >= 5

max_goal_friction_ratio >= 3.0
and highest friction goal has support_actions >= 4

economy_support_share >= 0.45
and total_actions >= 12
```

Bad seed set:

```text
badness_score >= 90
OR
at least one hard warning
```

Default UI displays:

```text
Top 25 bad seeds
```

sorted:

```text
hard warning count descending
badness_score descending
base_seed ascending
```

---

# 42. Representative seeds

In addition to bad seeds select:

```text
median seed
P10 duration seed
P90 duration seed
median economy-support seed
highest novelty seed
lowest novelty seed
```

---

# 43. Two-pass logging architecture

## Pass 1 — summary simulation

Run all N simulations with compact summary recording.

Store:

```text
seed
archetype
profile traits
StagePlan summaries
Run metrics
Stage metrics
badness inputs
```

## Pass 2 — deterministic replay

After analysis, rerun requested seeds using the same base seed and config.

Enable full event logging.

Use Pass 2 for:

```text
bad seeds
representative seeds
user-entered specific seed
```

---

# 44. Detailed seed log

A detailed log contains:

```text
Simulation config
Base seed
Archetype
Player Profile traits
Campaign interests summary

For each Stage:
StagePlan
plan decisions
starting state
daily timeline
action details
goal attribution
Date summaries
ending state
Stage metrics

Campaign summary
badness score
hard warning list
```

---

# 45. Daily timeline format

Human-readable Markdown example:

```text
## Day 6

### WORK
Goal support: characteristic:appearance:3
Money: $40 → $140
Time: 10:00 → 18:00

### DATE — Marina
Venue: Café
Outfit: Stylish
Relationship: 4 → 7
New Tags:
- CARE = positive
- STATUS = negative

Date score: +3

### End of day
Progress Beats: 3
Money: $120
```

---

# 46. StagePlan export format

Every Stage log begins with a compact plan:

```text
## Stage 2 Plan

Archetype: Typical

Filler:
- Marina: MAX
- Katya: MAX
- Lera: skip

Ordinary Rivals:
- Denis: engage
- Roman: skip

Characteristics:
- Appearance: 0 → 3
- Aura: 0 → 1

Outfits:
- target count: 2
- Stylish
- Minimal Black

Apartment:
- target count: 2
- TV
- Plaid

Venue exploration:
- Leisure Center: visit
- Café: no explicit goal
```

---

# 47. Developer Room — Monte Carlo Progression Lab

Add a dedicated panel:

```text
Monte Carlo Progression Lab
```

Controls:

```text
Scope:
End Story Stage [1..4]

Archetype:
Efficient
Typical
Explorer
Chaotic
Population

N simulations:
integer
default = 1000

Base seed start:
integer
default = 1

Bad seed count:
integer
default = 25
```

Run seeds:

```text
base_seed_start
base_seed_start + 1
...
base_seed_start + N - 1
```

---

# 48. Run controls

Buttons:

```text
Run N simulations
Cancel
Replay selected seed
```

Progress:

```text
completed / N
runs per second
elapsed time
estimated remaining time
```

Simulation executes in batches:

```text
100 runs per UI batch
```

Yield to the main loop between batches.

---

# 49. Results UI

Tabs:

```text
Overview
Stages
Archetypes
Bad Seeds
Representative Seeds
Items
Specific Seed
Export
```

Overview displays numeric tables for:

```text
campaign-day distribution
work distribution
Date distribution
economy support
dead days
Goal Friction
novelty
bad-seed percentage
```

---

# 50. Bad Seeds UI

Table columns:

```text
seed
archetype
badness score
hard warnings
campaign days
work actions
max work-only streak
money blocked
max goal friction
novelty density
```

Selecting row enables:

```text
Replay seed
View log
Export seed
```

---

# 51. Specific Seed UI

Input:

```text
seed
```

Buttons:

```text
Replay
View full plan + path
Export log
```

Display:

```text
Profile
StagePlans
Timeline
Metrics
Warnings
```

---

# 52. Export destination

Default export root:

```text
user://progression_lab_exports/
```

Every export operation also supports `Export to...` through a directory chooser.

Folder name:

```text
YYYY-MM-DD_HH-mm-ss__N_<count>__seed_<start>
```

Display final absolute path in Developer Room and provide:

```text
Open Export Folder
```

---

# 53. Export — Full Statistics Bundle

Button:

```text
Export Full Statistics
```

Create:

```text
config.json
aggregate_summary.md
aggregate_metrics.csv
stage_metrics.csv
archetype_metrics.csv
seed_summaries.csv
bad_seeds.csv
item_metrics.csv
representative_seeds.csv
share_bundle.md
share_bundle.json
```

`seed_summaries.csv` contains one row per simulation Run.

Detailed logs are included for:

```text
Top K bad seeds
representative seeds
```

Folders:

```text
bad_seed_logs/
representative_seed_logs/
```

Each detailed seed receives:

```text
<seed>.md
<seed>.json
```

---

# 54. Export — Bad Seeds Only

Button:

```text
Export Bad Seed Logs
```

Create:

```text
config.json
bad_seeds.csv
bad_seeds_summary.md
bad_seeds.jsonl
logs/
```

For every selected bad seed:

```text
logs/<seed>.md
logs/<seed>.json
```

Этот bundle предназначен для прямой загрузки в ChatGPT.

---

# 55. Export — Specific Seed

Button:

```text
Export Specific Seed
```

Для selected seed create:

```text
seed_<seed>.md
seed_<seed>.json
```

Markdown contains:

```text
Profile
StagePlans
daily timeline
Date summaries
goal friction
metrics
warnings
```

JSON contains the same data structurally.

---

# 56. share_bundle.md

`share_bundle.md` является compact one-file report для загрузки в ChatGPT.

Include:

```text
simulation config
archetype weights
N
aggregate P10/P50/P90/P95 tables
Stage tables
bad-seed count and percentage (all_bad_seeds / N)
Top K bad seeds
warning prevalence
highest-friction goals
item utility summary
representative seed summaries
```

Для каждого Top bad seed:

```text
seed
archetype
StagePlan one-line summary
primary warning
key metrics
```

---

# 57. JSON schema stability

Add:

```text
schema_version = 1
simulation_version = current git commit short hash when available
```

to:

```text
config.json
share_bundle.json
specific seed json
bad seed json
```

Also export:

```text
timestamp
project version
Godot version
```

---

# 58. Comparison-ready config

Every aggregate export contains all tuning inputs required to reproduce the run:

```text
N
seed start
end Story Stage
archetype mode
population weights
trait centers
trait jitter
StagePlan formulas
badness weights
hard-warning thresholds
```

---

# 59. Simulation Config resource

Create one editable developer config containing all Monte Carlo tuning constants.

Include:

```text
population weights
trait centers
trait jitter = 0.15

StagePlan probabilities / formula coefficients

candidate scoring:
daily_gate_bonus = 20
unblock_bonus = 25
novelty_bonus = 10
repetition_penalty_per_step = 8
decision_noise_max = 15

Date utility constants

badness weights
hard-warning thresholds

default N = 1000
default bad seed count = 25
```

Developer Room reads and displays the active config identity.

Export serializes the full config.

---

# 60. Performance metrics

After every run batch collect:

```text
runs_per_second
mean_ms_per_run
total_elapsed
```

Show them in UI and export.

Support:

```text
N = 100
N = 1,000
N = 10,000
N = 100,000
```

according to measured runtime.

---

# 61. Automated analysis warnings

Aggregate report emits named warnings.

## Work concentration

```text
P90 max_consecutive_work_only_days >= 4
```

```text
WORK_STREAK_P90
```

## Economy support

```text
P50 economy_support_share >= 0.30
```

```text
ECONOMY_SUPPORT_HIGH_MEDIAN
```

## Tail economy support

```text
P90 economy_support_share >= 0.45
```

```text
ECONOMY_SUPPORT_HIGH_TAIL
```

## Money blocking

```text
P90 money_blocked_decision_points >= 5
```

```text
MONEY_BLOCKING_HIGH_TAIL
```

## Dead progression

```text
P90 dead_progress_days >= 2
```

```text
DEAD_PROGRESS_HIGH_TAIL
```

## Goal friction

```text
P90 max_goal_friction_ratio >= 3.0
```

```text
GOAL_FRICTION_HIGH_TAIL
```

## Low novelty

```text
P10 novelty_density <= 0.15
```

```text
NOVELTY_LOW_TAIL
```

Report exact measured values next to every warning.

---

# 62. Goal Isolation diagnostics

Add predefined diagnostic mode:

```text
Goal Isolation
```

It uses `TYPICAL` profile centers with trait jitter disabled.

Available characteristic target:

```text
Muscle 1 / 3 / 5
Appearance 1 / 3 / 5
Capital 1 / 3 / 5
Aura 1 / 3 / 5
```

Two variants:

```text
MINIMAL_CONTENT
FULL_STAGE_CONTENT
```

## MINIMAL_CONTENT

Plan:

```text
exactly 2 required filler
0 optional ordinary rivals
0 optional Outfit beyond mandatory Stage 2 dress-up gate
0 optional Apartment Objects
selected Characteristic target
mandatory Story progression
0 Venue exploration goals
```

## FULL_STAGE_CONTENT

Plan:

```text
3 filler
all ordinary rivals
2 current-stage Outfit
2 current-stage Apartment Objects
selected Characteristic target
mandatory Story progression
0 Venue exploration goals
```

Goal Isolation uses these fixed diagnostic plans. Venue exploration goals are created only in the ordinary Monte Carlo StagePlan flow. A production Date may still visit a Venue while executing another diagnostic goal; that visit is an execution action, not a long-term Venue exploration goal.

Run:

```text
N = 1000
```

using varying execution/date seeds while keeping the same high-level diagnostic plan.

Compare:

```text
work actions
work-only streak
days
Goal Friction
dead days
```

---

# 63. Item utility report

For every Outfit and Apartment Object report:

```text
eligible_runs
acquired_runs
acquisition_rate

considered_after_purchase
used_after_purchase
positive_effect_count
requirement_unlock_count
```

Derived:

```text
use_per_acquisition
positive_effect_per_acquisition
unlock_per_acquisition
```

Sort one report section by lowest `use_per_acquisition`.

---

# 64. Validation

Add deterministic tests.

## Seed determinism

Same:

```text
content
config
seed
```

produces equal:

```text
PlayerProfile
StagePlans
RunSummary
detailed replay action sequence
```

## StagePlan immutability

Hash StagePlan immediately after generation.

Verify identical hash at Stage end.

## Population weights

Large deterministic sample:

```text
N = 10000
```

matches configured archetype weights within ±0.02 absolute share per archetype.

## Fixed goal generation

For selected canonical test seeds assert exact:

```text
archetype
traits
filler targets
rival targets
characteristic targets
Outfit count
Apartment Object count
Venue exploration goals
```

---

# 65. Production integration tests

Create short simulation seeds that exercise:

```text
Stage 2 dress-up gate
Marina free Outfit
Apartment purchase
Restaurant Characteristic unlock
Sonya Venue ×2
Katya Accent
Rita taxi
Nika Backup Outfit
Eva initial knowledge
```

Each case ends with exactly one explicit result: PASS or FAIL.

```text
expected production content exists + flag/result observed → PASS
expected production content exists + flag/result absent → FAIL
required canonical production content cannot be resolved → FAIL with "content missing"
```

Canonical seed fixtures freeze exact archetype, trait values (tolerance 1e-6) and StagePlan fields. Same content/config/base_seed must reproduce identical PlayerProfile, interests, StagePlans, summary metrics and detailed action sequence. Different EXECUTION seeds with `planning_skill < 1` can select different valid actions.

Verify simulation uses production results and records them in metrics/logs.

---

# 66. Export tests

Verify:

```text
Full Statistics export
Bad Seeds Only export
Specific Seed export
```

Create expected files.

Parse generated JSON.

Verify:

```text
schema_version
seed
config
StagePlans
metrics
warnings
```

Specific seed Markdown contains:

```text
Stage Plan
Daily timeline
Summary
```

---

# 67. Developer workflow

Canonical tuning loop:

```text
1. Change production economy / progression values.
2. Run N simulations.
3. Inspect P10 / P50 / P90 / P95.
4. Inspect aggregate warnings.
5. Inspect Top bad seeds.
6. Replay suspicious seeds.
7. Export Full Statistics or Bad Seeds Only.
8. Compare the next tuning iteration with the previous export.
```

The Monte Carlo Lab serves as the quantitative filter before later human 3D playtesting.

---

# 68. Documentation

Create:

```text
docs/MONTE_CARLO_PROGRESSION_LAB.md
```

Document:

```text
simulation model
archetypes
traits
StagePlan generation
executor policy
metrics
bad-seed rules
Goal Isolation
export formats
reproducibility
developer workflow
```

Update relevant Developer Room documentation.

---

# 69. Критерий готовности

Блок готов, когда:

- Run seed детерминированно создаёт Player Profile;
- каждый Stage заранее получает immutable StagePlan;
- StagePlan содержит filler, rival, Characteristic, Outfit, Apartment и Venue intentions;
- executor выполняет production actions для достижения фиксированного plan;
- Work всегда атрибутируется конкретной blocked planned goal;
- Dates проходят через production Date Engine;
- Date decisions используют knowledge, skill и deterministic noise;
- campaign Run работает Stage 1→4;
- metrics считаются per Stage и total;
- Goal Friction работает per goal;
- work-only streak и dead progression metrics работают;
- item utility metrics работают;
- N simulations дают P10/P25/P50/P75/P90/P95;
- Badness Score рассчитывается после population run;
- hard bad-seed flags работают;
- bad seeds deterministic replay создаёт подробный timeline;
- Goal Isolation сравнивает minimal-content и full-content routes;
- Developer Room имеет Population / single archetype / specific seed workflows;
- Full Statistics export создаёт shareable aggregate bundle;
- Bad Seeds Only export создаёт compact bundle с логами плохих seeds;
- Specific Seed export создаёт `.md + .json`;
- `share_bundle.md` подходит для прямой загрузки в ChatGPT;
- exports содержат config и schema version;
- deterministic tests проходят;
- production integration tests проходят;
- export tests проходят;
- documentation синхронизирована.
- execution RNG участвует в candidate scoring;
- repetition penalty применяется только к continuing primary activity;
- blocking campaign metrics считаются per decision point;
- Goal Friction blocking counts считаются per goal;
- Goal Isolation FULL_STAGE_CONTENT имеет fixed diagnostic plan без Venue exploration goals;
- integration tests имеют explicit PASS/FAIL semantics;
- canonical seed fixtures проверяют exact StagePlans.

После завершения сделай отдельный commit:

```text
Tools: add Monte Carlo Progression Lab
```

и push текущей рабочей ветки.
