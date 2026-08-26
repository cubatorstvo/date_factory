# Work & Career Progression — Economy Vertical Growth

## Цель

Добавить в production game полноценную вертикальную прогрессию заработка и подключить её к Monte Carlo Progression Lab.

Текущая экономика уже показывает достаточную денежную ёмкость: simulated player способен потратить несколько тысяч долларов за прохождение, но базовая работа остаётся примерно на стартовом уровне дохода на протяжении всей кампании.

Новая модель:

```text
Stage 1–2:
ручная стартовая работа

После MAX Начальницы шахты:
открывается Career Progression

Career Rank:
0 → $100
1 → $200
2 → $400
3 → $800
```

Рост дохода достигается действиями игрока и связан с Characteristic `Capital`.

Текущие цены Outfit, Apartment Objects, Characteristic training, Dates, Rivals и прочих production expenses сохрани без балансировочных изменений в этом pass.

После реализации повторно прогоняется Monte Carlo `seeds 1..100`, чтобы измерить чистый эффект прогрессии дохода.

---

# 1. Canonical Work income

Production Work Service является единственным source of truth для базовой оплаты смены.

Canonical Career Rank payouts:

| Career Rank | Income per normal shift |
|---|---:|
| 0 | $100 |
| 1 | $200 |
| 2 | $400 |
| 3 | $800 |

Formula:

```text
normal_shift_income =
    100 * pow(2, career_rank)
```

для `career_rank = 0..3`.

Current production Work action получает payout через Work Service.

Monte Carlo также получает payout только через production Work action.

---

# 2. Career state

Добавь persistent career state в canonical GameState:

```text
career_progression_unlocked: bool
career_rank: int
```

Defaults:

```text
career_progression_unlocked = false
career_rank = 0
```

Range:

```text
career_rank = 0..3
```

Career state входит в new game state, save/load, isolated simulation GameState и Developer Room inspection.

---

# 3. Mine Boss reward

MAX relationship с Начальницей шахты открывает Career Progression.

Canonical reward:

```text
reward_id = career_progression_unlock
```

Player-facing meaning:

```text
Карьерные связи
```

Effect:

```text
career_progression_unlocked = true
```

Reward применяется через существующий production reward pipeline.

После unlock текущий доход остаётся `$100 / shift`; игрок получает возможность самостоятельно повысить Career Rank.

---

# 4. Career Rank requirements

Career Rank связан с `Capital`.

Canonical requirements:

| Upgrade | Capital requirement | New income |
|---|---:|---:|
| Rank 0 → 1 | Capital 1 | $200 |
| Rank 1 → 2 | Capital 3 | $400 |
| Rank 2 → 3 | Capital 5 | $800 |

Career upgrade availability:

```text
career_progression_unlocked
+
current Capital >= required Capital
+
career_rank == previous rank
```

Ranks повышаются последовательно:

```text
0 → 1 → 2 → 3
```

---

# 5. Career Advancement action

Добавь production action:

```text
CAREER_ADVANCEMENT
```

Player-facing action:

```text
Добиться повышения
```

Effect:

```text
career_rank += 1
```

Career Advancement:

```text
duration = duration of one normal Work shift
money reward = 0
```

Action занимает ту же daily Work opportunity, что и обычная смена.

Это создаёт инвестицию времени: сегодня игрок отказывается от зарплаты, повышает Career Rank и получает более высокий доход со всех следующих смен.

---

# 6. Daily Work gate

Обычная работа и Career Advancement используют один production daily Work gate.

В один calendar day через этот gate выполняется одно из:

```text
normal Work
Career Advancement
existing Work variant sharing this gate
```

Сохрани текущую production semantics дополнительных Work modifiers/rewards.

Career Advancement считается отдельной primary activity:

```text
CAREER
```

для telemetry и Monte Carlo.

---

# 7. Current salary display

Work UI показывает:

```text
Доход за смену: $<current_income>
```

После Career Progression unlock также показывает:

```text
Карьера: <career_rank> / 3
```

и next rank:

```text
Следующий доход: $<next_income>
Требование: Capital <required>
```

Когда requirement выполнен:

```text
[Добиться повышения]
```

Action UI показывает duration, current income и new income.

Пример:

```text
Добиться повышения
8 часов

$200 → $400 за смену
Требование: Capital 3
```

Используй фактическую production duration обычной Work смены вместо отдельного hardcoded UI duration.

---

# 8. Before Career unlock

До получения reward Начальницы шахты Work UI работает как стартовая работа:

```text
career_rank = 0
income = $100
```

Career Progression controls появляются после production reward unlock.

---

# 9. Rank 3 state

При `career_rank = 3` UI показывает:

```text
Доход за смену: $800
Карьера: 3 / 3
```

Current playable Stage 1–4 использует максимум `$800 / normal shift`.

Future country/world automation может позже развивать экономику отдельной системой поверх Career Rank 3.

---

# 10. Overtime / extended Work scaling

Существующие Work variants, которые рассчитывают награду как modifier базовой смены, используют Career-adjusted income.

Если текущая production механика даёт:

```text
+50% money
for ×2 Work time
```

то:

```text
Rank 0:
normal = $100
extended = $150

Rank 1:
normal = $200
extended = $300

Rank 2:
normal = $400
extended = $600

Rank 3:
normal = $800
extended = $1200
```

Formula:

```text
extended_income =
    current_normal_shift_income
    * existing production multiplier
```

Existing duration rules также используют текущую production Work semantics.

---

# 11. Work rewards use current Career Rank

Любой production mechanic, который означает оплату Work shift, получает базовую оплату через:

```text
WorkService.get_current_shift_income(game_state)
```

или эквивалентный canonical production method.

Так Monte Carlo, UI и gameplay всегда видят одну зарплату.

---

# 12. Career helper API

В существующий Work/Career service layer добавь компактный API:

```text
get_career_rank()
get_current_shift_income()
is_career_progression_unlocked()
get_next_career_rank()
get_next_career_income()
get_next_career_capital_requirement()
can_advance_career()
advance_career()
```

Следуй текущей архитектуре service/state проекта.

Career logic живёт рядом с Work production logic.

---

# 13. Capital remains normal Characteristic

Career system использует production permanent value `Capital`.

Career requirements `Capital 1 / 3 / 5` читаются из canonical Characteristic state.

Training `Capital` продолжает работать через существующую Characteristic training систему.

Career system добавляет Capital дополнительную экономическую ценность.

---

# 14. Career progression is optional gameplay

Career Advancement является available opportunity.

Player может продолжать работать на текущем Career Rank.

Example:

```text
Capital = 3
Career Rank = 1

available:
WORK → $200
CAREER_ADVANCEMENT → Rank 2, future WORK = $400
```

Gameplay сохраняет выбор игрока.

---

# 15. Monte Carlo — Career investment action

Monte Carlo Executor получает production-valid `CAREER_ADVANCEMENT` candidate.

Career Advancement является economic investment/support action, а не случайной StagePlan long-term goal.

StagePlan остаётся immutable и содержит существующие gameplay intentions.

Career investment появляется динамически, когда он помогает выполнить выбранный StagePlan эффективнее.

---

# 16. Monte Carlo — concrete economic comparison

Для каждого доступного next Career Rank рассчитай стоимость двух путей.

## Path A — current career

```text
remaining_cash_need =
    cash required for current unmet StagePlan goals
    and mandatory Story progression
```

```text
work_actions_without_upgrade =
    ceil(
        max(remaining_cash_need - current_money, 0)
        /
        current_shift_income
    )
```

## Path B — career upgrade

Включи:

```text
Capital prerequisite training still required
money cost of required Capital training
number of Capital training actions
1 Career Advancement action
future Work at new shift income
```

Calculate:

```text
economic_support_actions_with_upgrade =
    required Capital training actions
    + 1 Career Advancement action
    + expected Work actions at new income
```

Compare against:

```text
economic_support_actions_without_upgrade
```

Career path считается rational investment, когда:

```text
economic_support_actions_with_upgrade
<
economic_support_actions_without_upgrade
```

---

# 17. Career may create Capital support dependency

Если Career upgrade экономически выгоден, но следующий rank требует большего Capital:

```text
Career Rank 1 → 2
Capital current = 1
Capital required = 3
```

Executor создаёт economic investment dependency:

```text
Career Rank 2
→ Capital 3
→ required training / cash support
→ Career Advancement
→ higher Work income
```

Эта economic support chain существует даже когда Capital 3 отсутствует среди random Characteristic targets StagePlan.

---

# 18. Career investment scope

ROI analysis использует текущий immutable StagePlan и mandatory progression текущего Stage.

Simulated player принимает решение на основе уже выбранных намерений текущего Stage.

После перехода на следующий Story Stage новый StagePlan создаёт новый ROI calculation.

Career Rank сохраняется campaign-wide.

---

# 19. Career candidate scoring

Если Career investment уменьшает ожидаемое число economic support actions:

```text
saved_support_actions =
    economic_support_actions_without_upgrade
    - economic_support_actions_with_upgrade
```

Career Advancement / its Capital prerequisite получает base priority:

```text
highest_priority_cash_blocked_goal
+ 10
+ 5 * min(saved_support_actions, 4)
```

Затем применяй normal executor modifiers:

```text
daily gate
unblock bonus
repetition penalty
decision noise
```

---

# 20. Planning skill

`planning_skill` влияет на perceived ROI.

Canonical:

```text
perceived_saved_support_actions =
    saved_support_actions
    + execution_rng.randf_range(
        -2.0 * (1.0 - planning_skill),
        +2.0 * (1.0 - planning_skill)
    )
```

Career path выбирается как rational investment при:

```text
perceived_saved_support_actions > 0
```

Высокий planning skill почти точно оценивает повышение; низкий planning skill создаёт небольшую вариативность момента инвестиции.

---

# 21. Career investment commitment

После того как executor выбрал Career investment path, сохраняй temporary economic commitment:

```text
target_career_rank
```

до одного из:

```text
Career Rank достигнут
Stage завершён
production state делает upgrade недоступным
```

Этот commitment позволяет последовательно пройти:

```text
нужный Capital
→ деньги на Capital training
→ Career Advancement
```

Он является execution-level commitment и не изменяет immutable StagePlan.

---

# 22. Career support attribution

Career investment получает собственный support attribution.

Работа для финансирования Capital training:

```text
supporting_goal = career:rank_<N>
supporting_action = characteristic:capital:<required>
```

Работа на обычные StagePlan purchases продолжает использовать существующую attribution.

В этом pass отдельную глобальную cash-reservation систему для Outfit/Apartment не добавляй.

---

# 23. Monte Carlo metrics

Добавь campaign и per-Stage:

```text
career_rank_start
career_rank_end

career_advancement_actions

career_rank_1_day
career_rank_2_day
career_rank_3_day

work_income_start
work_income_end

money_earned_from_work

work_actions_at_rank_0
work_actions_at_rank_1
work_actions_at_rank_2
work_actions_at_rank_3

career_investment_capital_training_actions
work_actions_supporting_career
```

---

# 24. Career ROI telemetry

Для каждой Career Advancement decision сохраняй:

```text
career_rank_before
career_rank_after

current_income
new_income

remaining_cash_need

work_actions_without_upgrade
economic_support_actions_with_upgrade
saved_support_actions
perceived_saved_support_actions

decision
```

Decision:

```text
INVEST
SKIP_FOR_NOW
```

Detailed seed log показывает эти значения.

---

# 25. Population Career report

Добавь aggregate section:

```text
Career Progression
```

Report:

```text
Career Rank reached:
- Rank 0 only
- Rank 1+
- Rank 2+
- Rank 3

Career advancement day:
- Rank 1 P10/P50/P90
- Rank 2 P10/P50/P90
- Rank 3 P10/P50/P90

Work by rank:
- Rank 0
- Rank 1
- Rank 2
- Rank 3

Career support:
- promotion actions
- Capital training actions for career
- Work actions supporting career
```

---

# 26. Economy comparison metrics

Preserve current baseline metrics and compare after implementation:

```text
Campaign days
WORK actions
money_forced_work_days
economy_support_share
dead_progress_days
money earned
money spent
money end

work attribution:
Characteristics
Outfits
Apartment
Dates
Rivals
Career
```

---

# 27. Career Work attribution

Extend existing Work attribution categories:

```text
CHARACTERISTIC
OUTFIT
APARTMENT
DATE
RIVAL
CAREER
OTHER
```

A Work action used to finance Capital training created specifically by career investment is classified `CAREER`.

A Capital target originally selected by immutable StagePlan remains `CHARACTERISTIC`.

---

# 28. Progress Beat

Career Advancement is a Progress Beat.

Add:

```text
Career Rank increased
```

to Progress Beat definition.

---

# 29. Novelty

First Career Progression unlock and first achievement of each Career Rank count as novelty events:

```text
career system unlocked
Career Rank 1
Career Rank 2
Career Rank 3
```

---

# 30. Production UI / Developer Room

Developer Room state display adds:

```text
Career unlocked
Career Rank
Current Work income
Next Career requirement
Next Career income
```

Monte Carlo detailed replay starting/ending state includes the same fields.

---

# 31. Production tests

Add tests for:

```text
Rank 0 → $100
Rank 1 → $200
Rank 2 → $400
Rank 3 → $800
```

Mine Boss unlock:

```text
before reward:
career_progression_unlocked = false

after canonical Mine Boss MAX reward:
career_progression_unlocked = true
```

Capital requirements:

```text
Rank 0 → 1 requires Capital 1
Rank 1 → 2 requires Capital 3
Rank 2 → 3 requires Capital 5
```

Also test:

```text
sequential 0 → 1 → 2 → 3
Career Advancement consumes Work daily gate
save/load preserves unlock and rank
```

---

# 32. Overtime tests

For every existing Work payout modifier verify that Career-adjusted base income is used.

Canonical +50% examples:

```text
Rank 0 → $150
Rank 1 → $300
Rank 2 → $600
Rank 3 → $1200
```

Use actual existing production multiplier.

---

# 33. Monte Carlo tests

Add deterministic controlled tests.

## Career investment is profitable

State:

```text
career unlocked
Career Rank 0
Capital 1
current income = $100
remaining StagePlan cash need large enough
```

Expected:

```text
Career Rank 1 investment saves support actions
Career Advancement candidate exists
```

## Career investment is not profitable

State:

```text
career unlocked
Career Rank 0
Capital 1
remaining StagePlan cash need small
```

Expected:

```text
Career Advancement investment path absent
normal StagePlan execution continues
```

## Capital dependency

State:

```text
Career Rank 1
Capital 1
Rank 2 profitable
Rank 2 requires Capital 3
```

Expected chain:

```text
career commitment Rank 2
→ Capital training support
→ Career Advancement
→ Rank 2
```

## Persistence across Stage

Career Rank achieved in one Stage remains in next Stage.

---

# 34. Determinism

Career ROI rolls use existing execution RNG.

Same content/config/base_seed produces identical:

```text
Career decisions
Career Rank timeline
Work income timeline
Run metrics
execution signature
```

Detailed replay continues to match summary.

---

# 35. Monte Carlo export

Add Career fields to:

```text
seed_summaries.csv
stage_metrics.csv
aggregate_metrics.csv
share_bundle.md
share_bundle.json
specific seed logs
bad seed logs
representative seed logs
```

`share_bundle.md` adds:

```text
## Career Progression
```

with population summary.

---

# 36. Existing prices

This pass evaluates income progression against the current production economy.

Preserve current production values for:

```text
Outfit prices
Apartment Object prices
Characteristic training prices
Date costs
Rival costs
taxi/convenience costs
other current money sinks
```

The next economy-tuning decision will be based on the resulting Monte Carlo comparison.

---

# 37. Population rerun

After tests run:

```text
N = 100
base_seed_start = 1
end_story_stage = 4
archetype = POPULATION
```

Then:

```text
Replay verification = seeds 1..100
```

Expected technical invariants:

```text
100 / 100 runs completed
Replay 100 / 100 matched
NO_USEFUL = 0
SAFETY_CAP = 0
```

N=1000 remains outside this pass.

---

# 38. Before / after comparison

Compare against the current baseline approximately represented by the previous Monte Carlo result:

```text
Campaign days P50 ≈ 66.5
WORK P50 ≈ 66
money_forced_work_days P50 ≈ 65.5
Dates P50 ≈ 46.5
```

Use exact previous export if available.

Report new:

```text
Campaign days P50/P90/P95
WORK P50/P90/P95
money_forced_work_days P50/P90/P95
economy_support_share P50/P90/P95
dead_progress_days P50/P90/P95

money earned P50/P90
money spent P50/P90

Career Rank reached distribution
Career advancement timing
Work actions by Career Rank
```

---

# 39. Expected analysis outcome

This pass measures whether exponential income progression naturally reduces grind while preserving the existing spending capacity.

Report the measured WORK count rather than forcing a target value in code.

The next tuning pass will decide whether the healthy range is closer to `20–30`, `30–40` or another measured range based on actual Stage pacing and spending behavior.

---

# 40. Documentation

Update relevant production and Monte Carlo documentation.

Document:

```text
Career Progression unlock
Career Rank incomes
Capital requirements
Career Advancement action
daily Work gate
overtime scaling
Monte Carlo ROI policy
Career metrics
developer tuning workflow
```

---

# 41. Acceptance criteria

Task complete when:

- production Work income uses Career Rank;
- Rank incomes are `$100 / $200 / $400 / $800`;
- Mine Boss MAX unlocks Career Progression through production reward flow;
- Rank 1 requires Capital 1;
- Rank 2 requires Capital 3;
- Rank 3 requires Capital 5;
- Career Advancement consumes one normal Work-shift duration and daily Work opportunity;
- Career Advancement pays `$0` and increases Career Rank by one;
- normal Work immediately uses the new income;
- existing Work payout modifiers scale from Career-adjusted base income;
- career state persists through save/load;
- Work UI displays current income and next Career upgrade;
- Monte Carlo uses production Career actions;
- Monte Carlo evaluates Career advancement through concrete economic ROI;
- profitable Career path can create a Capital prerequisite support chain;
- Career commitment persists until target rank is reached or Stage ends;
- Career actions and supporting Work are attributed in metrics;
- Career Advancement creates a Progress Beat;
- Career population report is exported;
- existing production prices remain unchanged;
- deterministic tests pass;
- population run `1..100` completes;
- replay verification gives `100 / 100 matched`;
- NO_USEFUL = 0;
- SAFETY_CAP = 0;
- N=1000 is not run;
- final report compares economy before and after Career Progression.

After completion make a separate commit:

```text
Economy: add Career Progression and scaling Work income
```

and push the current working branch.
