# Work & Career Progression — Early Rank 1 and Mine Boss Connections

## Цель

Скорректировать Career Progression так, чтобы ранняя экономика Stage 2 не оставалась на зарплате `$100` почти до конца этапа.

Текущие payouts сохраняются:

```text
Rank 0 = $100
Rank 1 = $200
Rank 2 = $400
Rank 3 = $800
```

Новая progression:

```text
Stage 1:
Rank 0
$100

Stage 2 early:
Rank 1
Capital 1
+ Career Advancement
→ $200

Stage 2 late / Stage 3:
Rank 2
Capital 3
+ Career Connections
+ Career Advancement
→ $400

Stage 3–4:
Rank 3
Capital 5
+ Career Connections
+ Career Advancement
→ $800
```

MAX Начальницы шахты открывает `Career Connections`, то есть высокие карьерные уровни Rank 2–3.

Rank 1 доступен самостоятельно с Story Stage 2. На Stage 1 игрок остаётся на Rank 0 / $100.

Текущие цены production economy в этом pass не меняются. Меняется только Career gating/timing.

---

# 1. Canonical Work income

Production Work Service — единственный source of truth для базовой оплаты смены.

| Career Rank | Income per normal shift |
|---|---:|
| 0 | $100 |
| 1 | $200 |
| 2 | $400 |
| 3 | $800 |

```text
normal_shift_income = 100 * pow(2, career_rank)
```

для `career_rank = 0..3`. Реализация: `100 * (1 << career_rank)`.

Current production Work action и Monte Carlo получают payout только через Work Service.

---

# 2. Career state

Persistent career state в `PlayerState`:

```text
career_connections_unlocked: bool
career_rank: int
```

Defaults:

```text
career_connections_unlocked = false
career_rank = 0
```

Range:

```text
career_rank = 0..3
```

Meaning:

```text
false:
Rank 1 доступен
Rank 2–3 требуют Connections и поэтому недоступны

true:
Rank 2–3 могут открываться при выполнении Capital requirements
```

Поле заменяет прежнее `career_progression_unlocked`. Career state входит в new game, save/load, isolated simulation GameState и Developer Room inspection.

Production helper:

```text
WorkService.has_career_connections(game_state)
```

true, если player flag **или** filler reward `career_connections` (legacy id `career_progression_unlock` тоже считается до миграции).

---

# 3. Rank requirements

| Upgrade | Story Stage | Capital | Career Connections | New income |
|---|---:|---:|---|---:|
| Rank 0 → 1 | >= 2 | 1 | — | $200 |
| Rank 1 → 2 | — | 3 | required | $400 |
| Rank 2 → 3 | — | 5 | required | $800 |

```text
Rank 0 → 1:
career_rank == 0
story_stage >= 2
Capital >= 1

Rank 1 → 2:
career_rank == 1
Capital >= 3
career_connections_unlocked == true

Rank 2 → 3:
career_rank == 2
Capital >= 5
career_connections_unlocked == true
```

Ranks повышаются последовательно: `0 → 1 → 2 → 3`.

`WorkService.can_advance_career()`:

- Rank 0 → 1: Story Stage >= 2 + Capital + daily Work slot
- Rank 1 → 2 и 2 → 3: Capital + Connections + daily Work slot

---

# 4. Rank 1 availability

С начала игры Career system знает о Rank 1, но повышение недоступно до Story Stage 2.

Rank 1 Career Advancement production-valid при:

```text
career_rank == 0
story_stage >= 2
Capital >= 1
daily Work slot free
```

Mine Boss reward для Rank 1 не требуется. Это основной ранний economic progression Stage 2. Stage 1 всегда использует Rank 0 / $100.

---

# 5. Mine Boss reward

MAX Начальницы шахты (`girl_mine_boss`, player-facing «Начальница шахты») открывает Career Connections.

Canonical reward:

```text
reward_id = career_connections
legacy reward_id = career_progression_unlock
display_name = Карьерные связи
```

Effect:

```text
career_connections_unlocked = true
```

Reward открывает возможность Career Rank 2 и Rank 3. Текущий Career Rank при reward сохраняется. Ставка смены сразу не растёт.

Preview:

```text
Откроются карьерные связи. Rank 2 и Rank 3 станут доступны при достаточном Capital.
```

Granted:

```text
Открыты карьерные связи. Rank 2 и Rank 3 можно взять при достаточном Capital.
```

Применяется через существующий `grant_filler_reward_for_girl`. Stage skip через DEV **не** выдаёт Connections.

Constant: `FillerRewardCatalog.ID_CAREER_CONNECTIONS = &"career_connections"`. Legacy `ID_CAREER_PROGRESSION_UNLOCK = &"career_progression_unlock"` остаётся только для миграции/fallback.

---

# 6. Career Advancement action

Production action `career_advancement` — «Добиться повышения».

```text
duration = one normal Work shift (WORK_MINUTES = 60)
money reward = 0
uses Work daily gate (RecordWorkDayEffect, key work)
career_rank += 1
```

Work income после action сразу использует новый rank.

Requirements в порядке:

1. `WorkAvailableTodayRequirement`
2. `MinStoryStageRequirement` (`min_stage = 2`) — **только если** `career_rank == 0`
3. `CareerConnectionsUnlockedRequirement` — **только если** `career_rank >= 1`
4. `CareerRankBelowMaxRequirement`
5. `CareerCapitalRequirement`

Fail copy для Connections: «Нужны карьерные связи.»

Career Advancement — отдельная primary activity `CAREER` для telemetry и Monte Carlo.

---

# 7. Daily Work gate

Обычная работа и Career Advancement используют один production daily Work gate.

В один calendar day через этот gate выполняется одно из: normal Work / Career Advancement / existing Work variant sharing this gate.

---

# 8. Player-facing Career UI

Work UI **всегда** показывает карьеру с New Game. Не прятать Rank 1 до Mine Boss.

## Rank 0

На Stage 1 Rank 1 показывается как future opportunity:

```text
Карьера: 0 / 3
Доход: $100
Следующее повышение: $200
Откроется на следующем этапе
Требование: Capital 1
```

После перехода на Stage 2:

```text
Карьера: 0 / 3
Доход за смену: $100
Следующее повышение: $200
Требование: Capital 1
```

Когда Capital 1 достигнут, Stage >= 2 и слот Work свободен:

```text
[Добиться повышения]
```

## Rank 1 before Connections

```text
Карьера: 1 / 3
Доход за смену: $200

Следующее повышение: $400
Требование: Capital 3
Требование: Карьерные связи
```

Short hint, когда одновременно `career_rank == 1` и `career_connections_unlocked == false`:

```text
Дальше одним старанием уже не пробиться.
Говорят, всем здесь заправляет Начальница шахты.
```

При Capital < 3 UI всё равно показывает оба requirements: Capital 3 и Карьерные связи.

## Rank 2 after Connections

```text
Карьера: 2 / 3
Доход за смену: $400
Следующее повышение: $800
Требование: Capital 5
```

Connections requirement на Rank 2→3 не повторяется, если Connections уже получены.

## Rank 3

```text
Карьера: 3 / 3
Доход за смену: $800
```

Action button copy сохраняет фактическую duration обычной Work смены:

```text
Добиться повышения — 1 ч — $<current> → $<next>
```

---

# 9. Overtime

Существующие Work variants используют Career-adjusted income. Production modifier `+50%`:

```text
Rank 0: $100 / extended $150
Rank 1: $200 / extended $300
Rank 2: $400 / extended $600
Rank 3: $800 / extended $1200
```

---

# 10. Career helper API

```text
get_career_rank()
get_current_shift_income()
has_career_connections()
get_next_career_rank()
get_next_career_income()
get_next_career_capital_requirement()
next_rank_requires_connections()
get_story_stage()
next_rank_requires_min_story_stage()
is_next_career_rank_unlocked()
can_advance_career()
advance_career()
```

`is_career_progression_unlocked()` не сохраняется как public alias с прежним смыслом «любое повышение». Connections — отдельный helper.

---

# 11. Capital remains normal Characteristic

Career system использует production permanent value `Capital`. Training Capital продолжает работать через Characteristic training. Career добавляет Capital экономическую ценность.

---

# 12. Career progression is optional

Игрок может продолжать работать на текущем Career Rank. Rank 1 доступен без Mine Boss; Rank 2–3 — нет.

---

# 13. Monte Carlo — Career investment

Monte Carlo Executor получает production-valid `CAREER_ADVANCEMENT` candidate. Career — economic investment, не StagePlan goal. StagePlan остаётся immutable.

Rank 1 ROI считается даже при `career_connections_unlocked == false`, как только production Story Stage >= 2 и Capital 1 достижим. До Stage 2 Rank 1 ROI не создаёт commitment.

Rank 2–3 ROI paths включаются только после production Career Connections unlock.

Когда Rank 2 или Rank 3 потенциально выгоден, но Connections отсутствуют:

```text
career advancement remains future locked opportunity
```

Detailed diagnostics:

```text
target rank
Capital requirement
Connections requirement
Mine Boss reward source
```

Monte Carlo продолжает обычный StagePlan execution до production unlock Connections.

Если текущий StagePlan содержит Mine Boss и Rank 2 потенциально экономически выгоден, diagnostic/replay добавляет:

```text
Career dependency:
Rank 2
→ Career Connections
→ Mine Boss relationship reward
```

Это diagnostic dependency. StagePlan structure не меняется.

ROI math финансирует prerequisite Capital по текущей зарплате, а остаток Stage cash — по новой. Active Career commitment резервирует prerequisite cash; optional spending использует `free_money`. StagePlan Capital training during commitment spends reserved cash. Mandatory Stage continuation (Stage 2 dress-up) may override reservation. Commitment `target_career_rank`, support attribution `career:rank_<N>` и planning_skill noise сохраняются.

Rank 1 commitment:

```text
target_career_rank = 1
Capital 1 → required Work support at Rank 0 income → Career Advancement → Rank 1
```

---

# 14. Career metrics

Сохрани существующие Career metrics. Добавь:

```text
career_connections_unlock_day
career_connections_unlock_stage
rank_1_before_connections: bool
```

Population aggregate:

```text
Rank 1 before Connections share
Career Connections unlock P10/P50/P90
Rank 2 delay after Connections P10/P50/P90
```

Stage-specific Work:

```text
Stage 1–4 WORK P50/P90/P95
Stage 2 money_forced_work_days P50/P90/P95
Stage 2 economy_support_share P50/P90/P95
```

Rank timing:

```text
Rank 1/2/3 day P10/P50/P90
Rank 1/2/3 Stage distribution
```

Target observation: Rank 1 should usually occur during early/mid Stage 2. Этот pass измеряет результат, а не hardcodes конкретный day.

Work by rank: `work_actions_at_rank_0..3` population P50/P90/P95. Особенно сравнить Rank 0 WORK before Rank 1 с предыдущим прогоном (P50 ≈ 32.5).

Novelty: first Career Connections unlock и first achievement of each Career Rank.

Progress Beat: Career Rank increased — без изменений.

---

# 15. Production UI / Developer Room

Developer Room:

```text
Career Connections: true/false
Career Rank
Current Work income
Next Career requirement
Next Career income
```

Monte Carlo detailed replay starting/ending state включает те же поля, плюс Connections.

---

# 16. Save/load migration

`SAVE_VERSION = 20`.

`_migrate_v19_career_connections` when `from_version < 20`:

- `career_connections_unlocked` ← existing `career_progression_unlocked` if new key absent
- drop or stop writing `career_progression_unlocked`
- `career_rank` без изменения semantics
- в `unlocked_filler_reward_ids` заменить `career_progression_unlock` на `career_connections`

`PlayerState.from_dict` читает `career_connections_unlocked`, с fallback на `career_progression_unlocked`.

---

# 17. Production tests

## Rank 1 Stage gate

```text
Stage 1, Capital 1, Rank 0
→ Rank 1 unavailable

Stage 2, Capital 1, Rank 0
→ Rank 1 available
```

## Rank 1 without Connections

```text
career_rank = 0
story_stage >= 2
Capital = 1
career_connections_unlocked = false
```

Expected: `can_advance_career() = true`, next rank = 1, income after advancement = $200.

## Rank 2 requires Connections

```text
career_rank = 1
Capital = 3
career_connections_unlocked = false
```

Expected: Rank 2 unavailable.

After `career_connections_unlocked = true`: Rank 2 available.

## Rank 3

```text
career_rank = 2
Capital = 5
career_connections_unlocked = true
```

Expected: Rank 3 available.

## Mine Boss reward

Before MAX: `career_connections_unlocked = false`. After production reward: `true`. Career Rank unchanged.

## Save migration

Old `career_progression_unlocked` + current rank → after migration both `career_connections_unlocked` and `career_rank` correct. `save_version == 20`.

Preserve: sequential 0→1→2→3, daily Work gate, overtime $150/$300/$600/$1200, Stage skip does not grant Connections.

---

# 18. Monte Carlo tests

## Rank 1

Controlled: Stage 2, Rank 0, Capital 1, Connections false, large remaining cash need.

Expected: Rank 1 ROI evaluated; Career Advancement candidate can be chosen.

## Rank 2 lock

Controlled: Rank 1, Capital 3, Connections false.

Expected: Rank 2 production action unavailable; diagnostics identify Career Connections requirement.

After Connections: Rank 2 ROI/action becomes available.

Preserve existing profitable / not profitable / Capital dependency / persistence / attribution / determinism tests, retargeted onto Connections semantics. Rank 1 tests must not require Connections.

Same content/config/seed → identical Rank timeline, Connections timing, WORK timeline, execution signature. Replay exact.

---

# 19. Population rerun

После tests:

```text
N = 100
base_seed_start = 1
end_story_stage = 4
archetype = POPULATION
Replay verification seeds 1..100
```

Invariants: 100/100 completed, Replay 100/100 matched, NO_USEFUL = 0, SAFETY_CAP = 0.

Сравни с предыдущим Career Progression run (export `2026-08-26 15-28-40__N_100__seed_1`):

```text
Campaign P50 ≈ 48.5 days
WORK P50 ≈ 46
money_forced_work_days P50 ≈ 45
Dates P50 ≈ 46
Stage 1 WORK P50 ≈ 8
Stage 2 WORK P50 ≈ 20
Stage 3 WORK P50 ≈ 9
Stage 4 WORK P50 ≈ 6
Rank 0 WORK P50 ≈ 32.5
Rank 1 WORK P50 ≈ 3
Rank 2 WORK P50 ≈ 3
Rank 3 WORK P50 ≈ 8
Rank 1 day P50 ≈ 34
```

Главный вопрос:

```text
Does early Rank 1 reduce Stage 2 WORK from ~20 toward ~10–14 without breaking later economy?
```

Report: Stage 2 WORK/days P50/P90/P95, Rank 1 timing, Rank 0 WORK before Rank 1, campaign WORK/days, money earned/spent/end.

---

# 20. Preserve current economy

Current production prices and higher Career salaries remain unchanged. This pass changes only Career gating/timing.

---

# 21. Acceptance criteria

Task complete when:

- Rank 1 is available without Mine Boss reward;
- Rank 1 requires Story Stage >= 2 and Capital 1;
- Rank 1 pays $200 after Career Advancement;
- Mine Boss MAX grants Career Connections;
- Rank 2 requires Capital 3 + Career Connections;
- Rank 3 requires Capital 5 + Career Connections;
- Career Advancement retains current Work-gate/duration semantics;
- production UI clearly shows Rank 1 requirement;
- Rank 1 UI exposes future Rank 2 and Career Connections requirement;
- player-facing hint identifies Mine Boss as the source of Career Connections;
- save/load preserves Career Rank and Connections;
- old Career unlock state migrates correctly;
- Monte Carlo evaluates Rank 1 before Connections;
- Monte Carlo respects Connections for Rank 2–3;
- Career metrics include Connections timing;
- Stage-specific WORK metrics are exported;
- deterministic tests pass;
- population `1..100` completes;
- replay verification = `100 / 100`;
- NO_USEFUL = 0;
- SAFETY_CAP = 0;
- final report compares Stage 2 WORK before/after.
