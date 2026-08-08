# MODULE 26 — BALANCE / ANTI-GRIND

**Проект:** Date Factory  
**Модуль:** 26 — Balance / Anti-Grind  
**Статус:** обязательная спецификация перед Full Game QA  
**Назначение:** отдельный количественный проход по темпу всей игры после полного content lock. Убрать обязательный фарм, проверить Authority / XP / Money / cooldown / minigame / clone pacing, исправить только реальные bottleneck-и и зафиксировать release-candidate balance constants.  
**Предыдущий модуль:** MODULE 25 — Content Completion  
**Следующий модуль:** MODULE 27 — Full Game QA  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 26

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 26:

```text
НЕ добавляет новый контент
НЕ добавляет новые gameplay systems
НЕ добавляет currencies
НЕ добавляет stages
НЕ добавляет perks
НЕ меняет save schema
```

Разрешено:

```text
изменять существующие числовые constants
исправлять anti-grind edge cases
добавлять test-only balance simulations
добавлять balance documentation
```

После MODULE26:

```text
content locked
mechanics locked
balance locked
```

MODULE27 только QA/fixes, а не новый redesign.

---

# 1. PRODUCT PACING TARGET

Целевой объём:

```text
MAINLINE / уверенный первый проход:
~3.5–5 часов

NATURAL RUN:
основной сюжет
+ часть ordinary girls/rivals
+ чтение flavor
+ несколько неидеальных попыток
≈ 5–8 часов

100% optional/systemic content:
может быть дольше
```

Не растягивать mainline искусственными таймерами.

---

# 2. ANTI-GRIND DEFINITION

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

---

# 3. FIRST REAL BALANCE FIX — STORY RIVAL LOSS

Текущий `RivalEncounters` на обычном loss делает:

```text
lose_authority(1)
```

для любого non-exhibition rival.

Это неправильно для clean story pacing.

## New exact rule

```text
STORY RIVAL LOSS:
Authority delta = 0

ORDINARY RIVAL LOSS:
Authority delta = -1, floor 0

FINAL EXHIBITION:
Authority delta = 0
```

---

# 4. WHY STORY LOSS MUST BE ZERO

Canonical story Authority progression:

```text
Actress rival:
requires 0
reward +2
→ Authority 2

Mine Boss rival:
requires 2
reward +2
→ Authority 4

Editor rival:
requires 4
reward +3
→ Authority 7

Scientist rival:
requires 7
reward +3
→ Authority 10

President rival:
requires 10
reward +5
→ Authority 15
```

Each story rival begins exactly at current clean Authority.

Old behavior:

```text
Authority 4
→ lose Editor rival
→ Authority 3
→ player-initiated threshold requires4
```

Potential result:

```text
must farm ordinary rival to retry story
```

That is forbidden anti-grind.

---

# 5. RIVAL LOSS IMPLEMENTATION

In:

```text
RivalEncounters._resolve_competition_result()
```

Loss:

```text
if def != null and def.is_story:
    authority_delta = 0
else:
    heroic = _qualifies_heroic_defeat()
    if heroic:
        authority_delta = 0
    else:
        authority_delta = -GameState.lose_authority(1)
```

Do NOT mark story rival defeated on loss.

Retry remains available.

---

# 6. HEROIC DEFEAT

`MUSCLE_HEROIC_DEFEAT` remains meaningful for:

```text
ordinary rival losses
```

Story already has zero penalty.

No extra reward for story heroic loss.

UI consequence line:

Story rival:

```text
Поражение: Авторитет не меняется
```

Ordinary:

```text
Поражение: Авторитет -1
```

unless Heroic Defeat derived no-loss condition is shown.

Final exhibition unchanged.

---

# 7. NO STORY AUTHORITY FARM

Story rival reward remains exactly-once through:

```text
mark_rival_defeated
```

Retry after loss:

```text
0 reward until actual first win
```

Repeated interaction after victory cannot farm.

---

# 8. STORY AUTHORITY VALUES — LOCK

Do NOT retune these unless tests prove content mismatch:

```text
Actress:   req0  reward2
Mine:      req2  reward2
Editor:    req4  reward3
Scientist: req7  reward3
President: req10 reward5
```

These already form an exact clean ladder.

---

# 9. ORDINARY RIVAL REWARDS

Current ordinary rivals remain optional.

Target:

```text
reward generally1–2
```

No ordinary rival reward >2 in release unless current content already has a justified exception and simulation proves safe.

Do NOT make ordinary Authority more profitable than story progression.

---

# 10. ORDINARY LOSS LOOP

Ordinary rival:

```text
win once → reward once
loss → -1
```

No rematch reward after defeat.

This remains risk/reward optional content.

---

# 11. XP / EXPERIENCE STORY LADDER — LOCK

Clean story completions:

```text
Neighbor       → XP1
Actress        → XP2
Mine Boss      → XP3
Editor         → XP4
Scientist      → XP5
President      → XP11 after required late XP
Final Target   → +1 ending reward
```

Required story girl gates:

```text
Neighbor   XP0
Actress    XP1
Mine Boss  XP2
Editor     XP3
Scientist  XP4
President  XP10
Final      no XP gate
```

This means all manual Earth story through Scientist is reachable using story XP only.

---

# 12. PRESIDENT GAP — INTENTIONAL

After Scientist:

```text
Experience = 5
```

President requires:

```text
10
```

Exact required bridge:

```text
+5 late automated Experience
```

This is intentional because President must prove clone dating automation actually works.

Do NOT let ordinary girls become mandatory for President.

Do NOT lower President XP10.

---

# 13. ORDINARY XP REMAINS OPTIONAL

16 ordinary girls each can grant:

```text
+1 Experience once
```

They may:

- accelerate perk acquisition;
- unlock ordinary girls earlier;
- reduce reliance on late automation if conquered before it.

But clean mainline must not require them.

---

# 14. UPGRADE POINT ECONOMY — LOCK

Each new Experience:

```text
+1 Upgrade Point
```

No other mandatory UP source.

Do not change atomic invariant.

---

# 15. PERK COST — LOCK CANON

Global purchase sequence remains:

```text
1
3
9
27
81
243
...
```

Implementation:

```text
3 ^ total_purchased_perks
```

Do NOT change to per-tree pricing.

Do NOT flatten exponent in MODULE26.

---

# 16. PERK PACING EXPECTATION

By Scientist completion clean story:

```text
5 XP / 5 total UP earned
```

This guarantees player can buy:

```text
first perk =1
second perk =3
```

with:

```text
1 UP spare
```

Therefore early game naturally supports about:

```text
2 chosen perks
```

without optional XP.

This is intended.

---

# 17. NO PERK-GATED STORY

Automated test must prove every mandatory story rival has:

```text
at least one currently base-unlocked competition
```

with zero purchased perks.

Known intended fallbacks include:

```text
SLAP
DANCE
```

President explicitly DANCE fallback.

No story date perfect route may require perk-owned action.

---

# 18. MONEY — MAINLINE PRINCIPLE

Main story must be completable with:

```text
Money = 0 at the start of each manual story encounter
```

except systems where Money itself is optional choice.

Meaning:

- no mandatory paid discovery route;
- no mandatory paid date action;
- no mandatory MONEY competition;
- no mandatory clone upgrade purchase;
- no mandatory global upgrade purchase.

Money improves flexibility, not story permission.

---

# 19. SALARY FORMULA — CURRENT VALUE LOCK

Current:

```text
salary_level = 1 + Authority / 3
gross = 10 * salary_level
```

Keep initially.

Clean story examples:

```text
Authority 4 → level2 →20 / period
Authority 7 → level3 →30
Authority10 → level4 →40
Authority15 → level6 →60
```

This is sufficient for small manual choices without dominating clone economy.

---

# 20. FINANCIAL INERTIA — LOCK

Passive salary:

```text
25% gross
```

after:

```text
perk owned
+ manual cycle seen
```

Keep.

Salary Mine is transitional early economy.

Do NOT buff it until it competes with clones.

---

# 21. SALARY ANTI-GRIND TEST

No mandatory story step may require:

```text
>1 salary period
```

of savings.

Prefer:

```text
0
```

required periods.

If a current mandatory authored action costs more than one clean salary claim and has no free story route:

that action/content is a balance bug.

Fix the action requirement/cost, not salary inflation.

---

# 22. MONEY MINIGAME PRINCIPLE

Money contest spends real Money.

Keep:

```text
starting_money-dependent stake_unit
```

unless statistical test proves pathological.

Story must always have non-MONEY fallback.

Therefore a broke player may lose/refuse MONEY without story softlock.

---

# 23. MONEY MATCH TIME TARGET

Normal MONEY competition:

```text
typical successful duration:
20–60 sec
```

Story:

```text
30–90 sec
```

No deterministic success path should require:

```text
>7 successful player scoring rounds
```

Current target-score values must be audited.

Do not change blindly.

---

# 24. DISCOVERY RETRY — KEEP 1–3 DAYS

Current failure retry:

```text
random 1..3 GameDays
```

Keep.

Why it is acceptable:

```text
GameDay advance is explicit/instant
failure also reveals clue
story has authored success route
```

No real-time waiting.

---

# 25. DISCOVERY ANTI-GRIND

A failed story discovery:

```text
must never remove Authority
must never remove XP
must never permanently consume unique resource
```

Only:

```text
clue + 1..3 day retry
```

Current behavior expected.

---

# 26. DATE REPEAT COOLDOWN — KEEP 1–3 DAYS

Current completed date cooldown:

```text
random 1..3 GameDays
```

Keep.

It is a failure/retry pacing device, not real-time grind.

---

# 27. PERFECT STORY DATE RULE

Every story girl must have a deterministic:

```text
+5 in one date
```

route.

Therefore a player who correctly understands clues can complete:

```text
one story date
→ relationship+5
→ no cooldown wait needed for progression
```

Test all Earth story girls.

---

# 28. ORDINARY PERFECT DATE RULE

MODULE25 already requires every ordinary girl to have feasible +5.

Keep.

No ordinary girl should require 2+ dates by construction.

Repeated dates are consequence/replay, not mandatory baseline.

---

# 29. RECOVERY FROM BAD DATE

A bad date may create:

```text
relationship <0
```

That is allowed.

But there must be no hard lower-state lock.

From:

```text
-5
```

repeated good dates can still eventually reach +5.

Cooldown only requires GameDay progression.

No permanent failure.

---

# 30. DATE DURATION TARGET

One ordinary/systemic date:

```text
4 choices total:
greeting +3 central + farewell
```

Target first-read:

```text
3–7 minutes
```

Repeat date when text is known:

```text
1.5–4 minutes
```

No timer padding.

---

# 31. STORY DATE TARGET

Authored story date:

```text
4–8 minutes
```

President:

```text
5–9 minutes
```

FinalDate separately:

```text
8–15 minutes
```

Do not shorten final sequence into ordinary date range.

---

# 32. RIVAL MINIGAME DURATION TARGETS

Per single encounter:

```text
ordinary:
20–60 sec

story:
30–90 sec

final exhibition:
30–90 sec
```

Including result presentation, excluding walking to actor.

---

# 33. MINIGAME REPEATABILITY

No competition should require repetitive button actions for:

```text
>90 seconds typical success
```

Audit:

```text
SLAP
DANCE
SIGMA
MONEY
```

with representative levels:

```text
player = rival-2
player = rival
player = rival+2
```

No hidden stat should make input duration explode.

---

# 34. DIFFICULTY PRINCIPLE

Characteristic level changes:

```text
margin / tools / forgiveness
```

not:

```text
hard lock on manual skill
```

Story can still be won at low relevant characteristic because story fallbacks exist.

Do NOT introduce stat-based auto-loss.

---

# 35. MEDIA PACING — LOCK CORE THRESHOLDS

Keep:

```text
Attention thresholds:
15 / 30 / 45 / 60
```

Overload ready:

```text
Attention >=45
incoming offers >=3
```

No decay.

Media is escalation, not grind meter.

---

# 36. PHOTO / ARTICLE ATTENTION — LOCK

Keep current authored:

```text
BASE photo +10
STAGED +15
EDITORIAL +20
Editor article +15
Feed Boost +5
```

No repeated daily publication should be mandatory to reach overload.

---

# 37. MEDIA ANTI-GRIND TEST

Clean Stage4 route must be able to activate DatingOverload with:

```text
one required Photo Session
+ Editor article
+ at most one normal publication/Feed action according to current intended flow
```

Do NOT require multiple empty GameDays of photo farming.

Cursor must simulate actual current Media flow and document exact minimum action path.

If current state already crosses45 naturally:

no balance change.

---

# 38. OVERLOAD CORE — LOCK

Keep:

```text
personal date capacity =1/day
first wave =3
base daily wave =2
boost wave =3
Feed Boost Attention +5
```

Recognition:

```text
min days =2
generated >=7
backlog >=4
personal dates >=1
```

These are story-beat requirements.

Do not shorten unless test proves impossible.

---

# 39. OVERLOAD ACTIVE-TIME TARGET

Once overload starts, knowledgeable player should reach:

```text
problem_recognized
```

after:

```text
2 GameDay advances
+1 actual personal date
```

with no additional arbitrary grind.

No need to fulfill backlog before recognition.

---

# 40. FIRST CLONE CALIBRATION TARGET

Keep existing calibration values.

Target:

```text
20–40 sec
```

No permanent failure.

Miss retry same pass.

No tuning unless manual timing is outside range.

---

# 41. CLONE LOCAL BALANCE — INITIAL LOCK

Current local constants:

```text
production:
30 /25 /20 /15 /10 /5 sec

work:
20 /30 /40 /50 /60 /70 Money/min/clone

dating:
0.50 /0.75 /1.00 /1.25 /1.50 /1.75 dates/min/clone

upgrade costs:
30 /90 /270 /810 /2430
```

These are good baseline and remain unless simulation budgets below fail.

---

# 42. FIRST LOCAL UPGRADE ACCESS

WORK-first path:

```text
1 working clone
20 Money/min
```

With auto second clone at30 sec.

Acceptance:

```text
first 30-Money local upgrade
must be affordable within <=90 sec
```

without Salary Mine farming.

Current formula should pass.

---

# 43. DATING-FIRST SOFTLOCK TEST

First clone assigned:

```text
DATING
Money=0
```

Must still progress:

```text
new free clone in30 sec
→ assign Work
→ Money begins
```

No paid production requirement.

Keep.

---

# 44. PRESIDENT AUTOMATION BUDGET

Starting immediately after first persistent clone:

Assumptions:

```text
Experience =5
DatingOverload backlog =4
local upgrade levels =0
no ordinary girls after Scientist
no debug
```

Allowed player behavior:

```text
every produced free clone is assigned immediately
```

Use three deterministic strategies:

### A — dating-heavy

```text
first clone Work
all later clones Dating
```

### B — balanced

```text
alternate Work / Dating
```

### C — 3 workers then Dating

```text
maintain max3 Work until3
all later free → Dating
```

Acceptance:

```text
all three strategies reach:
Experience10
within <=6.5 minutes real clone simulation
```

No upgrades required.

If one fails only marginally:

tune local dating/production, not President XP gate.

---

# 45. PRESIDENT BUDGET EXCLUDES READING

The <=6.5m is pure clone simulation time.

Player can:

- inspect terminal;
- move through lab/city;
- read UI;
- spend Money.

Simulation runs during gameplay/modal as currently designed.

No forced AFK.

---

# 46. CLONE WORK ECONOMY TARGET

At:

```text
5 working clones
local work level0
```

expected current:

```text
100 Money/min
```

This should make:

```text
30/90 local upgrades
```

cheap,
```text
270
```
meaningful,
and:
```text
810/2430
```
late optional investments.

Keep.

---

# 47. LOCAL MAX UPGRADE IS OPTIONAL

Main story must NEVER require:

```text
local level5
```

or even:

```text
any local upgrade purchase
```

Local upgrades are acceleration toys.

---

# 48. GLOBAL BALANCE — INITIAL LOCK

Current:

```text
global levels0..3
multipliers:
x1/x2/x4/x8

costs:
1000/5000/25000

Reach:
+2 per late XP

optional events:
+10 each

production interval floor:
0.5 sec
```

Keep unless Stage6 pacing test fails.

---

# 49. STAGE6 NO-UPGRADE BUDGET

Start from a conservative clean President-completion snapshot generated by the President automation test.

At Stage6:

```text
Reach0
no global upgrades
ignore all three optional events
all new free clones → Dating
```

Acceptance:

```text
Reach100 within <=8 minutes
```

No global purchase required.

This proves world expansion cannot softlock on Money.

---

# 50. STAGE6 OPTIONAL EVENT BUDGET

Same start.

Use all three physical +10 Reach events as soon as available.

No global upgrades.

Acceptance:

```text
Reach100 within <=6.5 minutes
```

Optional FPS activity meaningfully accelerates stage.

---

# 51. GLOBAL UPGRADE VALUE

Global upgrades must feel obviously useful.

At each upgrade:

```text
effective production/work/dating value exactly doubles
```

No diminishing hidden modifier.

UI already shows before→after.

Keep.

---

# 52. GLOBAL UPGRADE IS NOT REQUIRED

A player with:

```text
Money0
```

at Stage6 can still complete Earth Reach through dating clones.

Production itself is free.

This is mandatory anti-grind invariant.

---

# 53. COMPLETE CLONE-ERA BUDGET

From first clone persistent commit:

```text
→ President eligibility
→ President story completion excluding reading/minigame
→ Reach100
```

Reasonable active allocation strategy:

```text
<=15 minutes of required real-time incremental simulation
```

This excludes:

- President discovery/date;
- walking;
- reading;
- rival minigame;
- optional terminal tinkering.

No 30-minute idle wall.

---

# 54. LATE XP INFLATION

After backlog reaches0:

auto dates can generate unbounded XP/UP.

This is intentional late-game power curve.

Do NOT cap Experience.

Do NOT scale auto-date XP downward.

Perk exponential costs absorb late XP.

---

# 55. EARLY VS LATE ECONOMY ROLES

Expected:

```text
Early:
Salary Mine = small Money utility

Transition:
local Work clones = primary Money source

Late:
global multipliers = explosive scale
```

No system should compete equally forever.

Therefore do not overbuff Salary Mine to late-game scale.

---

# 56. GAME DAY SPAM

`GameDay.advance_day()` remains instant.

It drives:

```text
cooldowns
salary period
overload waves
```

Anti-grind check:

No required mainline step should ask player to spam:

```text
>3 consecutive End Day clicks
```

without another gameplay action in between.

Exception:

player recovering from self-created multiple failed cooldown states is allowed.

---

# 57. REQUIRED STORY DAY ADVANCES

Intentional forced day progression only:

```text
Overload recognition:
at least2 day advances
```

Other story progression should not require fixed day counts when successful first try.

---

# 58. ORDINARY CONTENT DOES NOT BLOCK STORY

Automated clean-route test must ignore:

```text
all16 ordinary girls
all12 ordinary rivals
all flavor
all optional Reach events
```

and still reach ending.

Only late aggregate auto XP is mandatory after Scientist.

---

# 59. OPTIONAL CONTENT VALUE

Optional ordinary content should provide:

```text
XP
Authority
knowledge/practice
content variety
```

but not unlock exclusive story stages.

No balancing change adds such gates.

---

# 60. FIRST-TIME PLAYER ERROR BUDGET

Manual QA target:

A player may:

```text
lose2 story rival attempts
fail2 discovery approaches
have2 mediocre dates
```

and still recover without:

```text
ordinary farming
save reload
debug
```

Story rival zero-loss is the main fix enabling this.

Discovery/date retries may require GameDay advancement.

---

# 61. NO PUNISHMENT CASCADE

One failure must not create:

```text
resource loss
→ gate loss
→ unrelated grind
→ second gate loss
```

Specifically:

story rival failure:

```text
no Authority loss
```

ordinary rival failure:

```text
-1 Authority only
```

date failure:

```text
relationship/cooldown only
```

discovery failure:

```text
clue/cooldown only
```

---

# 62. BALANCE HARNESS — TEST ONLY

Create:

```text
game/balance/test/
```

No autoload.

Recommended:

```text
balance_self_test.gd
balance_projection.gd
balance_test.tscn
```

`BalanceProjection` is:

```text
RefCounted
test-only
```

It may compute current formulas without scene rendering.

Do NOT create runtime BalanceManager.

---

# 63. BALANCE PROJECTION INPUT

Model only deterministic economy timing:

```text
Authority story ladder
XP story ladder
perk costs
salary formula
clone production
clone Work/Dating rates
backlog
President XP gap
Reach
global multipliers
```

Do not simulate:

```text
player walking
reading speed
human minigame skill
random discovery choices
```

Those belong manual QA.

---

# 64. USE PRODUCTION CONSTANTS

Balance tests import/call actual:

```text
CloneIncrementalTypes
LateGameTypes
Progression
SalaryMine static/pure formulas where possible
```

Do NOT duplicate current numbers into test model silently.

If a production constant changes, test projection should use it.

Target budgets may be constants in test only.

---

# 65. DETERMINISTIC CLONE SIMULATION

Use:

```text
CloneIncremental.advance_simulation_for_test()
```

where practical.

Prefer real service test over a mathematical copy.

For strategy allocation:

after each `clone_produced`:

assign via actual:

```text
assign_one_to_work
assign_one_to_dating
```

or deterministic direct test seam if current self-tests already have one.

---

# 66. TEST — STORY AUTHORITY CLEAN

Forced wins:

```text
Actress →2
Mine→4
Editor→7
Scientist→10
President→15
```

No ordinary rival.

---

# 67. TEST — STORY LOSS NO AUTHORITY

For all5 Earth story rivals:

```text
set Authority = exact required
force loss
```

Expected:

```text
Authority unchanged
rival not defeated
retry initiation remains legal
```

This exact test prevents future anti-grind regression.

---

# 68. TEST — ORDINARY LOSS STILL -1

Representative ordinary rival:

```text
Authority5
loss
→4
```

At0:

```text
loss
→0
```

Heroic Defeat test unchanged.

---

# 69. TEST — STORY NO PERKS

Set:

```text
purchased perks =[]
```

For every story rival:

```text
effective competition set not empty
```

At least one:

```text
SLAP or DANCE
```

available.

---

# 70. TEST — STORY GIRL XP GATES

Clean completion sequence without ordinary:

```text
before each story girl:
XP >= required_experience
```

through Scientist.

President:

```text
XP5 <10
```

as intentional clone bridge.

---

# 71. TEST — PERK COSTS

Still exact:

```text
1
3
9
27
81
```

first five purchases.

No tree-dependent price.

---

# 72. TEST — EARLY PERK BUDGET

After Scientist clean:

```text
XP5
UP5
```

Possible:

```text
buy cost1
buy cost3
remaining1
```

Third cost9 unavailable.

Pass.

---

# 73. TEST — SALARY CLEAN VALUES

Exact:

```text
Auth0 → level1 gross10
Auth2 → level1 gross10
Auth3 → level2 gross20
Auth4 → level2 gross20
Auth7 → level3 gross30
Auth10→ level4 gross40
Auth15→ level6 gross60
```

If integer division behavior differs in actual Godot code, test exact production result.

---

# 74. TEST — STORY REQUIRES ZERO MONEY

Static/content audit:

For every mandatory story:

- discovery has zero-cost success;
- perfect date route has zero-cost option at each evaluated point;
- rival has base non-MONEY fallback.

President farewell has free positive options.

Fail if a story path mathematically requires Money.

---

# 75. TEST — DISCOVERY RETRY RANGE

Repeated seeded failures:

```text
1 <= cooldown <=3
```

No 0, no >3.

---

# 76. TEST — DATE COOLDOWN RANGE

Seeded completed dates:

```text
1..3
```

No >3.

---

# 77. TEST — STORY PERFECT +5

For:

```text
Neighbor
Actress
Mine Boss
Editor
Scientist
President
```

construct known authored positive path.

Expected:

```text
date_delta = +5
```

No characteristic requirement >0 on chosen actions.

---

# 78. TEST — PRESIDENT BRIDGE THREE STRATEGIES

Use exact §44 strategies.

Starting:

```text
XP5
backlog4
local levels0
one first clone
```

Expected:

```text
XP10 <=390 sec
```

for each strategy.

Record actual seconds.

---

# 79. TEST — LOCAL UPGRADE AFFORDABILITY

WORK-first no salary:

Expected:

```text
Money >=30
within <=90 sec
```

Production remains free.

---

# 80. TEST — STAGE6 NO-UPGRADE

From clean projected snapshot:

```text
Reach0
global levels0
new clones → dating
```

Expected:

```text
Reach100 <=480 sec
```

No manual events.

---

# 81. TEST — STAGE6 EVENTS

Same but trigger all three events at thresholds.

Expected:

```text
Reach100 <=390 sec
```

---

# 82. TEST — NO GLOBAL MONEY SOFTLOCK

Set:

```text
Money0
Stage6
```

Never purchase global upgrade.

Reach still reaches100.

---

# 83. TEST — COMPLETE INCREMENTAL REQUIRED TIME

Record:

```text
President bridge seconds
+
Stage6 no-upgrade seconds
```

Target:

```text
<=900 sec
```

Use conservative strategy, not optimized speedrun.

---

# 84. TEST — LATE RATE MONOTONICITY

For each local/global upgrade:

new effective value must be strictly better:

Production:

```text
interval decreases
```

Work:

```text
Money/min increases
```

Dating:

```text
Dates/min increases
```

No dead upgrade level.

---

# 85. TEST — PURCHASE VALUE

Local costs positive and increasing.

Global costs positive and increasing.

No overflow/negative integer through max defined level.

---

# 86. TEST — 10000 CLONES

Balance formulas remain finite.

At max upgrades:

```text
rates finite
production interval >=0.5
```

No integer/float overflow in normal expected counts.

---

# 87. MINIGAME BALANCE AUDIT

Use existing headless match classes.

For each:

```text
SLAP
DANCE
SIGMA
MONEY
```

record:

- normal target/round count;
- story target/round count;
- minimum input count for clean win;
- expected time under deterministic correct input.

Do NOT fake visual wait time.

---

# 88. MINIGAME TUNING RULE

Only change a minigame numeric if:

```text
ordinary deterministic clean win >60 sec
or
story >90 sec
or
required repeated input count feels mechanically redundant
```

When adjusting:

prefer:

```text
target score/round count
```

over changing core feel/timing windows.

Do not redesign minigame in MODULE26.

---

# 89. SLAP FAIRNESS

At player/rival stat gaps:

```text
-2
0
+2
```

perfect human timing must retain a plausible win route.

Stats may shift difficulty/forgiveness, not make timing irrelevant.

No exact win-rate Monte Carlo required if deterministic mechanics.

---

# 90. DANCE FAIRNESS

Sequence lengths must not become memory-test grind.

Target:

```text
single required observation/repeat sequence:
readable in one normal attention cycle
```

No late story requiring >8-symbol memorization unless current design already intentionally does and manual QA proves comfortable.

If >8:

reduce sequence length, not input timing.

---

# 91. SIGMA FAIRNESS

Continuous hold segment:

```text
no single uninterrupted required hold >20 sec
```

A whole match may contain multiple rounds.

No hidden unavoidable disturbance chain.

---

# 92. MONEY FAIRNESS

At story rival and typical clean-story Money:

MONEY may be difficult/unavailable.

That is allowed because story fallback exists.

For ordinary Money rivals:

starting Money >0 should produce playable stake unit >=1.

No forced spend >current Money.

---

# 93. STORY TRANSITION BUDGET

No stage transition should require all of:

```text
Authority grind
XP grind
Money grind
GameDay grind
```

simultaneously.

Each stage has one primary challenge.

Expected:

```text
Stage1: manual core introduction
Stage2: story rival/date
Stage3: salary/editor
Stage4: media→overload
Stage5: clone automation→President
Stage6: accelerated Reach
Finale: skill/authored final
```

---

# 94. TARGET PER-STAGE FIRST-RUN WINDOWS

Manual QA, including walking/reading but not optional completionism:

```text
PROLOGUE   15–30 min
STAGE1     25–45 min
STAGE2     25–45 min
STAGE3     30–50 min
STAGE4     35–60 min
STAGE5     25–50 min
STAGE6     10–25 min
FINALE      8–15 min
```

These are ranges, not timers.

A knowledgeable replay may be much faster.

---

# 95. MAINLINE TOTAL

Expected first informed/competent run:

roughly:

```text
3.5–5 hours
```

A first blind-ish natural run with optional exploration:

```text
5–8 hours
```

Do NOT inject artificial waits to hit exact total.

---

# 96. SPEEDRUN SAFETY

A player who already knows all correct choices can finish much faster.

That is fine.

Do not add:

```text
minimum playtime
minimum days except overload
forced real-time timers
```

for duration padding.

---

# 97. OPTIONAL COMPLETIONISM

Conquering all16 ordinary girls and defeating all12 ordinary rivals is not part of mainline pacing.

No target to fit 100% completion inside5h.

---

# 98. BALANCE TELEMETRY — TEST/DEBUG ONLY

Allowed simple debug report:

```text
BalanceReport
```

generated by tests:

```text
story Authority ladder
story XP ladder
perk purchase cumulative costs
salary values
President bridge times
Stage6 times
incremental total
minigame timing audit
```

No runtime telemetry upload.

No analytics service.

---

# 99. REPORT FILE

Create:

```text
docs/balance/BALANCE_REPORT.md
```

Include:

```text
BEFORE
AFTER
WHY
TEST EVIDENCE
```

for every changed production number.

If a number is unchanged:

mark:

```text
LOCKED — passed budget
```

This prevents random future retuning.

---

# 100. BALANCE CONSTANT OWNERSHIP

Do not create central BalanceConfig containing every number.

Keep constants where systems own them:

```text
Rival definitions → rival stats/rewards
CloneIncrementalTypes → clone
LateGameTypes → global
DatingOverloadTypes → overload
SalaryMine → salary
Progression → perk formula
minigame classes → timing/targets
```

`BALANCE_REPORT.md` is documentation, not source of truth.

---

# 101. SAVE SCHEMA

Balance changes use existing fields only.

Keep:

```text
SAVE_SCHEMA_VERSION = 1
```

No migration.

Existing saves remain valid.

---

# 102. SAVE COMPATIBILITY WITH CHANGED FORMULAS

Derived values:

```text
Money/min
Dates/min
production interval
salary next period
```

may reflect new release constants after load.

Persisted values:

```text
Money
counts
upgrades
pending salary
```

remain exact.

No save rewrite needed.

---

# 103. NO RETROACTIVE COMPENSATION

If a balance cost changes:

do NOT refund/spend old save currency automatically.

MODULE26 should avoid unnecessary cost changes anyway.

---

# 104. UI SYNC

Any changed balance number must already display from source APIs.

Audit:

```text
Rival consequence
Salary
Clone Terminal
Global Terminal
Phone
Progression
```

No stale hard-coded old values.

---

# 105. CONTENT LOCK

Do NOT edit MODULE25 jokes/events simply because balance tester dislikes a line.

Only action:

```text
required_level
money_cost
rival stat/reward
```

may be adjusted if mathematically necessary.

Copy/content improvements are closed unless blocking clarity.

---

# 106. EXPECTED FINAL PRODUCTION CHANGES

At minimum MODULE26 changes:

```text
story rival loss Authority:
-1 → 0
```

Everything else is **measure first**.

Current audited clone/salary/perk/overload values are initial release candidates and should remain if budgets pass.

This module is not permission to retune everything.

---

# 107. IF PRESIDENT BRIDGE FAILS

Priority order:

1. slightly increase base Dating rate:
   ```text
   0.50 → 0.60 or0.75
   ```
2. or reduce base production interval:
   ```text
   30 →25
   ```
3. do NOT reduce President XP10;
4. do NOT remove backlog-first semantics.

Choose smallest single change that makes all strategies <=390 sec.

Document exact before/after.

---

# 108. IF STAGE6 FAILS

Priority:

1. increase:
   ```text
   REACH_PER_LATE_XP 2→3
   ```
   ONLY if no-upgrade route exceeds480 sec materially;
2. or slightly lower world Reach max only if product meaning unchanged — NOT preferred;
3. do NOT make global upgrade mandatory;
4. do NOT add passive Reach per second.

Preferred first knob:

```text
REACH_PER_LATE_XP
```

---

# 109. IF EARLY MONEY FAILS

Do NOT globally buff salary first.

Priority:

1. ensure mandatory action has free route;
2. reduce that optional/mandatory action cost;
3. only then consider salary gross:
   ```text
   10*level →15*level
   ```

Avoid clone-era inflation.

---

# 110. IF PERK PACING FEELS TOO SLOW

Do NOT change canonical `3^N`.

Optional ordinary girls + late XP are intended sources.

Perks are meaningful sparse progression, not one purchase every stage.

---

# 111. IF STORY DATE RETRY FEELS TOO PUNITIVE

Do NOT remove relationship consequences.

First allowed tweak:

story date cooldown only:

```text
force1 day
```

while ordinary stays1..3.

But ONLY if manual QA demonstrates repeated 3-day clicks are a real annoyance.

This is not default change.

---

# 112. IF DISCOVERY RETRY FEELS TOO PUNITIVE

Same:

story discovery failure may be reduced to:

```text
1 day
```

only after manual QA evidence.

Default remains1..3.

---

# 113. MANUAL QA ROUTE A — CLEAN

Player intentionally:

- uses zero ordinary girls;
- uses zero ordinary rivals;
- buys zero perks;
- chooses free positive story actions;
- wins story rivals first try;
- uses clones as needed.

Must reach ending.

This is the canonical anti-grind proof.

---

# 114. MANUAL QA ROUTE B — IMPERFECT

Player:

```text
loses each of first3 story rivals once
fails2 story discovery attempts
gets one +2/+3 story date rather than +5
buys one bad optional purchase
```

Must recover through normal game without ordinary farming.

Story rival losses0 Authority is critical.

---

# 115. MANUAL QA ROUTE C — OPTIONAL

Player defeats/contacts several ordinary NPCs.

Expected:

```text
faster/more flexible
not required
```

No optional content accidentally advances story out of order.

---

# 116. MANUAL QA ROUTE D — BROKE CAPITAL-LESS

Player:

```text
Money near0
no Capital perks
```

Must still:

- pass every story rival through base fallback;
- complete every story date;
- reach clones;
- reach President;
- finish Stage6 without global purchase;
- complete FinalDate.

---

# 117. MANUAL QA ROUTE E — SPECIALIZED BUILD

Spend available perks almost entirely in one characteristic.

Must not hit mandatory story softlock.

FinalDate still works with one characteristic level2 repeated four times, per MODULE21.

---

# 118. MANUAL QA ROUTE F — NO UPGRADES CLONES

After first clone:

buy:

```text
zero local clone upgrades
zero global upgrades
```

Allocate clones actively.

Must reach FINALE inside stated late-game budgets.

---

# 119. NO DEBUG REQUIREMENTS

All six balance QA routes run through production UI/world.

Automated projection may use test seams.

No player-facing debug commands.

---

# 120. REGRESSION — STORY RIVAL UI

After new zero-loss rule:

Rival UI must not falsely say:

```text
Поражение: Авторитет -1
```

for story rival.

Read from actual context.

---

# 121. REGRESSION — SALARY AUTHORITY

Since story losses no longer reduce Authority:

salary level no longer drops from story retry.

Ordinary loss still may lower salary level.

That is expected.

---

# 122. REGRESSION — SAVE

Load old schema-v1 save where player had lower Authority due prior story loss.

Do NOT auto-repair/refund Authority.

New rule applies to future losses.

Save remains valid.

---

# 123. REGRESSION — FINAL RIVALS

Exhibition still:

```text
Authority delta0
```

Do not accidentally route through new story check in a way that changes FinalDate.

---

# 124. PERFORMANCE

Balance projections/test loops must not ship active `_process`.

No runtime balance telemetry.

No new performance cost.

---

# 125. DOCUMENTATION UPDATE

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/04_male_status_system.md
docs/gdd/06_dating.md
docs/gdd/07_story_clones_finale.md
```

Create:

```text
docs/balance/BALANCE_REPORT.md
```

---

# 126. CANONICAL MALE LOSS RULE DOCUMENT

Update GDD realization note:

```text
Ordinary rival loss:
Authority -1, floor0.

Earth story rival loss:
Authority0 — retry must never force optional Authority grind.

Final exhibition rival:
Authority0.
```

No ambiguity.

---

# 127. PROJECT STATUS AFTER MODULE26

`PROJECT_STRUCTURE.md`:

```text
after MODULE26 — Balance / Anti-Grind
```

Record final locked balance values.

Remaining:

```text
MODULE27 Full Game QA
MODULE28 Release Integration
```

---

# 128. DEFINITION OF DONE

MODULE26 complete only if:

- [ ] story rival loss Authority changed to0;
- [ ] all5 Earth story rival loss tests prove no Authority change;
- [ ] story rival loss leaves rival retryable;
- [ ] ordinary rival loss remains -1 floor0;
- [ ] Heroic Defeat ordinary behavior unchanged;
- [ ] final exhibition remains0;
- [ ] clean story Authority ladder exact0→2→4→7→10→15;
- [ ] no ordinary rival required for clean story;
- [ ] clean story XP reaches Scientist using story girls only;
- [ ] President remains XP10;
- [ ] exactly +5 late XP bridge required from clean XP5;
- [ ] no ordinary girl required for clean story;
- [ ] Experience→UP atomic rule unchanged;
- [ ] perk global costs remain1/3/9/27/81…;
- [ ] no story is perk-gated;
- [ ] no story is Money-gated;
- [ ] salary formula audited and locked or minimal documented change;
- [ ] discovery retry1..3 audited;
- [ ] date cooldown1..3 audited;
- [ ] every Earth story girl has deterministic +5 first-date route;
- [ ] minigame typical duration audit complete;
- [ ] no typical story minigame >90s;
- [ ] Media overload minimum action route documented;
- [ ] DatingOverload core recognition constants unchanged unless documented blocker;
- [ ] first clone calibration20–40s;
- [ ] local clone constants audited;
- [ ] first local30-Money upgrade affordable <=90s;
- [ ] dating-first clone path has no Money softlock;
- [ ] President bridge strategy A <=390s;
- [ ] President bridge strategy B <=390s;
- [ ] President bridge strategy C <=390s;
- [ ] Stage6 no-upgrade Reach100 <=480s;
- [ ] Stage6 with optional events <=390s;
- [ ] Stage6 completes with Money0/no global upgrades;
- [ ] complete required incremental simulation <=900s;
- [ ] all upgrade effects monotonic;
- [ ] no mandatory >3 consecutive End Day spam in clean success path;
- [ ] `game/balance/test` projection/self-test exists;
- [ ] test uses production constants/APIs, not stale copied numbers;
- [ ] `docs/balance/BALANCE_REPORT.md` records all final constants and evidence;
- [ ] natural full-game manual timing target assessed against5–8h content goal;
- [ ] clean zero-ordinary/zero-perk/zero-upgrade routes pass;
- [ ] imperfect-player recovery route passes;
- [ ] broke Capital-less route passes;
- [ ] specialized build route passes;
- [ ] schema remains v1;
- [ ] old saves still load;
- [ ] all MODULE02–25 regressions PASS;
- [ ] no MODULE27 QA fixes performed ahead beyond blockers found by balance tests.

---

# 129. RECOMMENDED CURSOR ORDER

```text
1. Audit all current balance constants and write BEFORE table.
2. Fix story rival loss Authority0 + UI consequence text.
3. Add story/ordinary loss regression tests.
4. Build test-only balance projection using production formulas/APIs.
5. Verify Authority/XP/perk/salary invariants.
6. Verify all story no-perk / no-Money routes.
7. Run President bridge A/B/C simulations.
8. Run Stage6 no-upgrade + optional-event simulations.
9. Audit all four minigame target durations/input counts.
10. Run Media/Overload minimum-path analysis.
11. Only if a budget fails, apply smallest allowed tuning knob.
12. Rerun every projection after each tuning.
13. Manual QA routes A–F.
14. Create BALANCE_REPORT with BEFORE/AFTER/evidence.
15. All MODULE02–25 regressions.
16. Update GDD/PROJECT_STRUCTURE.
```

---

# 130. CURSOR FINAL REPORT

## Changes

List EVERY production number/rule changed.

Expected minimum:

```text
Earth story rival loss:
Authority -1 → 0
```

If nothing else changed:

say so explicitly.

## Authority

Show:

```text
clean story ladder
loss/retry proof
ordinary loss proof
```

## XP / perks

Show:

```text
story XP ladder
President XP bridge
1/3/9… unchanged
no perk-gated story
```

## Money

Show salary values and prove story works with Money0.

## Dates / discovery

Show cooldown ranges and +5 story feasibility.

## Minigames

Table:

```text
normal typical duration
story typical duration
input/round count
any tuning
```

## Clone transition

Report actual measured seconds for:

```text
President strategy A
B
C
Stage6 no upgrade
Stage6 + events
combined late simulation
```

## Anti-grind manual routes

Confirm A–F.

## Balance report

Link/path:

```text
docs/balance/BALANCE_REPORT.md
```

## Save compatibility

Schema v1 remains; old saves load.

## Regressions

All MODULE02–25 suites.

## Commit

SHA.

Then STOP. Do not begin MODULE27.
