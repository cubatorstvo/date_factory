# MODULE 27 — FULL GAME QA

**Проект:** Date Factory  
**Модуль:** 27 — Full Game QA  
**Статус:** обязательный Release Candidate QA gate  
**Назначение:** пройти Date Factory как законченную игру, системно прогнать все автоматические regression suites, проверить полный production-flow от Main Menu до ending, softlocks, saves/restarts, NPC states, UI, minigames, manual→incremental transition, finale и производительность. Исправлять только подтверждённые дефекты.  
**Предыдущий модуль:** MODULE 26 — Balance / Anti-Grind  
**Следующий модуль:** MODULE 28 — Release Integration  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 27  
**Balance truth:** `docs/balance/BALANCE_REPORT.md`

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 27 — QA/FIX ONLY.

Запрещено добавлять:

```text
новые gameplay systems
новые girls/rivals/events
новые stages
новые currencies
новые perks
новые locations
новые upgrade tracks
новые balance goals
новую UI architecture
новую save schema без blocker-причины
```

Разрешено:

```text
исправлять подтверждённые баги
исправлять softlocks
исправлять crashes/errors
исправлять неверное состояние
исправлять UI clipping/readability blockers
исправлять save/load corruption
исправлять performance regressions
исправлять broken presentation hooks
добавлять regression tests на найденные баги
```

Каждый production fix в MODULE27 должен быть связан с конкретным reproducible defect.

---

# 1. RELEASE-CANDIDATE PRINCIPLE

После MODULE26:

```text
mechanics locked
content locked
balance locked
```

MODULE27 отвечает на один вопрос:

> Можно ли дать текущий build человеку, который ничего не знает о внутренней архитектуре, и он сможет пройти игру от New Game до ending, сохранить/загрузить её, ошибаться, повторять попытки и не сломать состояние?

Если нет — исправить именно дефект.

---

# 2. BUG SEVERITY

Использовать четыре уровня.

## BLOCKER

Примеры:

```text
crash
не запускается New Game
невозможно продолжить main story
save разрушает прогресс
load не восстанавливает критическое состояние
невозможно завершить Finale
player permanently trapped
game becomes unplayable without debug/restart
```

MODULE27 нельзя принять при любом открытом BLOCKER.

## MAJOR

Примеры:

```text
optional system softlock
NPC wrong state blocks substantial content
minigame result incorrect
major UI action inaccessible
save slot unreliable but workaround exists
major performance collapse
audio/UI modal state leaves controls broken
```

MODULE27 нельзя принять при открытом reproducible MAJOR.

## MINOR

Примеры:

```text
small clipping
wrong non-critical copy
cosmetic animation fallback
minor ambience issue
non-blocking visual overlap
```

May remain only if documented for MODULE28/polish and not player-confusing.

## TRIVIAL

Pure polish.

Does not block QA gate.

---

# 3. QA ARTIFACTS

Create:

```text
docs/qa/FULL_GAME_QA_REPORT.md
docs/qa/REGRESSION_MATRIX.md
docs/qa/KNOWN_ISSUES.md
```

Optional machine-readable:

```text
qa/test_manifest.json
```

Recommended tooling:

```text
tools/qa/run_all_tests.py
```

or equivalent small script.

No runtime QA autoload.

---

# 4. AUTOMATED TEST MANIFEST

Cursor must audit repository and enumerate **every current headless/self-test scene**.

Manifest fields:

```text
id
module
scene_path
category
timeout_seconds
required_for_rc
```

No manually maintained duplicate pass criteria beyond paths/categories.

If repository contains an obsolete test scene:

classify and either:

```text
remove because dead
or
mark non-RC with documented reason
```

Do not silently skip failing tests.

---

# 5. TEST RUNNER

Preferred:

```text
python tools/qa/run_all_tests.py
```

Responsibilities only:

1. discover/read manifest;
2. launch Godot headless per test;
3. capture stdout/stderr;
4. enforce timeout;
5. record exit status;
6. scan for explicit test PASS marker where runner has one;
7. produce summary.

No gameplay simulation logic inside Python.

---

# 6. RUNNER OUTPUT

Write:

```text
tmp/qa/
```

Per test:

```text
<id>.log
```

Summary:

```text
tmp/qa/summary.txt
```

Example:

```text
PASS  game_state
PASS  content_data
PASS  character_framework
...
FAIL  final_date
TIME  world_location

TOTAL 41
PASS  40
FAIL   1
```

Exact count determined from actual repo audit.

---

# 7. EXIT CODE

QA runner:

```text
0 = all required tests PASS
1 = at least one required FAIL/TIMEOUT
```

This enables MODULE28 release gate.

---

# 8. NO FALSE PASS

A Godot process that exits0 but logs:

```text
ERROR
SCRIPT ERROR
Parse Error
ASSERT
TEST FAILED
```

must not be counted PASS.

Runner should recognize current test conventions and/or explicit:

```text
ALL PASS
```

markers.

Avoid treating ordinary `WARNING` as failure globally.

---

# 9. ERROR LOG POLICY

For each required automated test:

fail on:

```text
SCRIPT ERROR
Parse Error
push_error from test failure
unhandled invalid access
resource parse/load failure
```

Known intentionally-triggered error tests must use existing controlled fixtures/log semantics rather than polluting runner as false failure.

Cursor audits these exceptions explicitly.

---

# 10. TIMEOUT POLICY

Default per headless suite:

```text
120 sec
```

Heavy:

```text
balance / save / full integration
up to 300 sec
```

No test may hang indefinitely.

Timeout is FAIL.

---

# 11. BASELINE AUTOMATED CATEGORIES

At minimum manifest must include actual repository suites for:

```text
MODULE02 GameState
MODULE03 ContentData
MODULE04 Character Framework
MODULE05 Progression
MODULE06 Rival Encounter
MODULE07A Slap
MODULE07B Dance
MODULE07C Sigma
MODULE07D Money
MODULE08 GirlDiscovery
MODULE09 Dating
MODULE10 Relationships
MODULE11 Story
MODULE12 World
MODULE13 Salary
MODULE14 early/manual content tests if present
MODULE15 Media
MODULE16 DatingOverload
MODULE17 FirstClone
MODULE18 CloneIncremental
MODULE19 CloneVisualization
MODULE20 LateGame
MODULE21 FinalDate
MODULE22 HUD/UI/Progression presentation tests
MODULE23 Audio/Presentation
MODULE24 SaveSystem/GameState save/world pose
MODULE25 content completion
MODULE26 balance
```

Use real paths, not guessed names.

---

# 12. CONTENT VALIDATION FIRST

Before manual F5:

run ContentDB validation.

Must pass:

```text
23 girls
19 rivals
22 discovery situations
62 central events
45 appearance profiles or current exact catalog count
16 ordinary 4×4 trait combinations
all resource references valid
```

Any production resource load error = BLOCKER.

---

# 13. CLEAN INSTALL TEST

Simulate user with:

```text
no user:// saves
no settings.cfg
```

Expected:

```text
game boots
Main Menu visible
Continue disabled
New Game enabled
Load empty/disabled appropriately
Settings defaults load
no parse errors
```

Do not permanently delete developer real user:// data.

Use isolated test user directory / Godot test invocation when possible.

---

# 14. NEW GAME TEST

From clean title:

```text
New Game
```

Expected:

```text
PROLOGUE
Day1
apartment
Money0
Authority0
Experience0
UP0
no clones
no stale NPC/session state
GAMEPLAY controls active
HUD correct
```

No console required.

---

# 15. TITLE → GAME → TITLE LOOP

Test:

```text
New Game
→ gameplay
→ Pause
→ Main Menu
→ New Game
```

at least3 times.

Expected:

```text
no duplicated HUD
no duplicated Phone
no duplicated Player
no duplicated ambience/music
no stale World location
no stale active sessions
```

---

# 16. AUTLOAD SINGLETON SANITY

After repeated New/Load/Main Menu transitions:

assert one instance/valid service state for all autoloads.

No manually-created duplicates of:

```text
GameState
ContentDB
Progression
RivalEncounters
GirlDiscovery
DatingCore
Relationships
Story
GameDay
World
SalaryMine
Media
DatingOverload
FirstClone
CloneIncremental
LateGameExpansion
SaveSystem
AudioDirector
```

Autoload itself guarantees node uniqueness; QA checks stale subscriptions/state instead.

---

# 17. FULL MANUAL ROUTE A — CLEAN MAINLINE

This is mandatory production F5 run.

Rules:

```text
zero ordinary girls
zero ordinary rivals
zero purchased perks
zero paid story actions
story rivals won first try
correct story discoveries/dates
zero local clone upgrades
zero global upgrades
```

Route:

```text
Main Menu
→ New Game
→ Neighbor
→ Actress rival/date
→ Mine Boss rival/date
→ Salary Mine
→ Editor rival/date
→ Media
→ Dating Overload recognition
→ Scientist rival/date
→ First Clone
→ clone automation to XP10
→ President rival/date
→ Stage6
→ Reach100 with no global upgrade
→ FINALE
→ FinalDate success
→ ending
```

Expected:

```text
no optional content required
no debug
no console
no softlock
```

---

# 18. ROUTE A CHECKPOINT TABLE

Record in QA report at each:

```text
stage
day
Money
Authority
Experience
UP
current location
story objective
```

Key expected Authority:

```text
after Actress rival =2
after Mine =4
after Editor =7
after Scientist =10
after President =15
```

Key XP:

```text
after Scientist =5
President available at10
President completion =11
Final completion +1
```

---

# 19. ROUTE A BALANCE OBSERVATION

Record actual human wall-clock duration for:

```text
PROLOGUE
Stage1
Stage2
Stage3
Stage4
Stage5
Stage6
Finale
```

This is observation only.

Do NOT retune solely because one developer playthrough misses target.

Compare against MODULE26 expected windows and note.

---

# 20. FULL MANUAL ROUTE B — IMPERFECT PLAYER

Mandatory.

Rules:

```text
lose Actress story rival once
lose Mine story rival once
lose Editor story rival once

fail at least2 story discovery approaches
complete at least1 story date at less than +5
recover naturally
```

Expected:

```text
story rival loss never lowers Authority
retry remains available
discovery failure gives retry/clue only
bad date can be recovered with later dates
no ordinary rival/girl required to fix story
eventually reaches ending
```

This is the core anti-grind proof deferred from MODULE26.

---

# 21. ROUTE B STORY-RIVAL RETRY

For each forced story loss:

verify immediately:

```text
Authority unchanged
rival still present/retryable
story girl still gated correctly
Phone objective still correct
no duplicate reward
```

After eventual win:

```text
reward exactly once
```

---

# 22. ROUTE B DISCOVERY RETRY

Force two failures.

For each:

```text
clue gained if authored
retry 1..3 days
no contact
no relationship
no XP
```

Advance days.

Retry.

Success.

No stale failed-attempt UI/session.

---

# 23. ROUTE B DATE RECOVERY

At one story girl:

first date:

```text
delta < +5
```

Then after cooldown:

second/third date as needed.

Expected:

```text
relationship arithmetic correct
event history/cycle correct
girl +5 once
XP once
Story advances once
```

No duplicate conquest reward.

---

# 24. FULL MANUAL ROUTE C — OPTIONAL CONTENT

Mandatory sampled route, not 100% completion.

Before ending:

```text
conquer >=4 ordinary girls
defeat >=3 ordinary rivals
use >=6 flavor interactions
encounter >=4 signature events
```

Cover at least:

```text
city
cafe
gym
appearance_space
```

Expected:

```text
optional XP/Auth accelerates but does not reorder Story illegally
ordinary defeated rivals remain gone
ordinary girls obey cooldown/history
Media candidate expansion works
save/load preserves new Module25 IDs
```

---

# 25. ROUTE C SAVE CHECKPOINT

After at least two new MODULE25 ordinary girls/rivals:

save manual slot.

Restart app.

Load.

Verify:

```text
new girl relationship/contact/clues intact
new rival defeated state intact
signature history intact
schema remains v1
```

---

# 26. FULL MANUAL ROUTE D — BROKE / CAPITAL-LESS

Mandatory.

Rules:

```text
Money kept near0 whenever possible
buy no CAPITAL perks
avoid paid actions
buy zero clone/global upgrades
```

Expected entire story remains completable.

At every mandatory story interaction verify:

```text
free valid discovery/date route
base competition fallback
```

MONEY minigame may be unavailable; no story softlock.

---

# 27. FULL MANUAL ROUTE E — SPECIALIZED BUILD

Mandatory.

Acquire optional/late UP as naturally needed.

Spend almost all feasible purchased perks in one characteristic branch.

Pick one exact branch before test, preferred:

```text
AURA
```

or whichever can exercise most systems.

Expected:

```text
no story softlock
story rival base fallbacks exist
story date perfect/adequate routes exist
FinalDate works by reusing one characteristic level>=2 four times
```

No forced balanced build.

---

# 28. ROUTE E FINALDATE

Final target:

use same level2+ characteristic in all four evaluated events.

Expected:

```text
base score4
distinct1
variety bonus0
score4 >=3
```

Win DANCE/SLAP.

Ending succeeds.

This production run verifies MODULE21 build-safe promise.

---

# 29. FULL MANUAL ROUTE F — NO CLONE UPGRADES

Mandatory.

From FirstClone onward:

```text
local upgrades 0/0/0
global upgrades 0/0/0
```

Allocate clones actively.

Expected:

```text
President XP10 reached
Stage6 Reach100 reached
no Money requirement
ending reached
```

Record actual elapsed clone-simulation wall time.

Compare to MODULE26 harness:

```text
President <=390 sec
Stage6 <=480 sec
combined <=900 sec
```

Manual time may be higher due walking/UI; pure waiting should not exceed harness meaningfully.

---

# 30. ROUTES MAY USE SAVE FIXTURES ONLY FOR QA SPEED

For repeated subsystem validation:

allowed to load audited QA saves.

But acceptance of A/B/E/F must include at least one true clean-flow chain proving state transitions.

Do NOT claim full F5 based only on manually-mutated GameState or test fixtures.

---

# 31. STORY ORDER INVARIANT

During all routes, Stage can move only:

```text
PROLOGUE
→ STAGE1
→ STAGE2
→ STAGE3
→ STAGE4
→ STAGE5
→ STAGE6
→ FINALE
```

Never:

```text
skip backwards
double advance
President before Scientist
Scientist before overload recognition
Production Area before Stage6
Final Location before FINALE
```

Log stage transitions in QA report.

---

# 32. STORY ACTOR MATRIX

For each story stage manually verify actor visibility.

## PROLOGUE

```text
Neighbor present
Actress pair absent
```

## STAGE1

```text
Actress + rival correct
```

## STAGE2

```text
Mine Boss + rival correct
```

## STAGE3

```text
Editor + rival correct
```

## STAGE4 pre-recognition

```text
Scientist pair absent
```

## STAGE4 post-recognition

```text
Scientist + rival present
```

## STAGE5 total clones0

```text
President pair absent
```

## STAGE5 total clones>=1

```text
President pair present
```

## STAGE6

Earth story pairs from previous stages gone.

No stale pair.

---

# 33. STORY ACTOR LIVE-SPAWN

Without scene reload where relevant verify:

```text
overload recognized → Scientist pair appears live
first clone committed → President pair appears live
stage advance → obsolete actors disappear live
```

No duplicate NPCs.

---

# 34. ORDINARY NPC MATRIX

Sample all16 ordinary girls through scene inspection or automated anchors.

For each:

```text
exactly one physical staged actor
correct location
visible under expected public access
Interact prompt reachable
failed discovery cooldown behavior
contact state behavior
```

All12 ordinary rivals:

```text
one physical actor
correct location
defeat removes actor
no respawn after travel/reload/load-save
```

---

# 35. NPC SAVE/LOAD MATRIX

At least four cases:

1. undiscovered girl;
2. discovered/no contact girl;
3. contact + relationship partial girl;
4. conquered girl;
5. undefeated rival;
6. defeated rival.

Save/load/travel.

Expected exact physical/interaction state.

---

# 36. NO DUPLICATE CHARACTERS AFTER TRAVEL

Stress travel:

```text
city ↔ cafe
city ↔ gym
city ↔ appearance
city ↔ mine
city ↔ lab
city ↔ production
```

10 cycles each where accessible.

Return to same location.

No duplicate NPCs/anchors/ambience/HUD.

---

# 37. WORLD ACCESS MATRIX

Test all9 locations at relevant stage.

```text
apartment        always
city_hub         social access
cafe             social access
gym              social access
appearance_space social access
salary_mine      Stage3
laboratory       Stage5
production_area  Stage6
final_location   FINALE
```

Verify:

```text
locked before
available after
```

using production interaction.

---

# 38. WORLD FALLBACK TEST

Use existing automated SaveSystem/world pose tests.

Also manual smoke:

load a save whose target location was intentionally invalid in QA fixture.

Expected:

```text
apartment fallback
gameplay functional
```

No need to corrupt normal player saves.

---

# 39. SAVE/LOAD CHECKPOINT PLAN

Mandatory real restart checkpoints:

```text
CHECKPOINT A — early story
CHECKPOINT B — Media/Overload
CHECKPOINT C — clone era
CHECKPOINT D — Stage6
CHECKPOINT E — post-ending
```

Each must involve:

```text
save
quit application/process
launch
load/Continue
continue gameplay
```

Not just save/load in same process.

---

# 40. CHECKPOINT A — EARLY

Suggested:

```text
STAGE2 or STAGE3
```

Verify:

```text
stage
day
Money/Auth/XP/UP
perks
girl state/history
rival defeated
location/player pose
```

---

# 41. CHECKPOINT B — MEDIA/OVERLOAD

Save with mixed:

```text
Attention
published photos
incoming/read
requests WAITING/OVERDUE/FULFILLED
candidate cursor
personal date capacity state
```

Restart.

Expected exact.

No duplicate wave/offer.

---

# 42. CHECKPOINT C — CLONES

Save with:

```text
total/work/dating/free
local upgrades
production elapsed nonzero
money fraction nonzero
date fraction nonzero
```

Restart.

Verify:

```text
derived rates exact
fractions resume
no offline progress
MODULE19 visuals reconstruct
```

---

# 43. CHECKPOINT D — STAGE6

Save:

```text
Reach between25 and90
global upgrades nonzero
optional event flags mixed
production_area
```

Restart.

Verify:

```text
Reach
multipliers
world visuals
event availability
no repeated +10
```

---

# 44. CHECKPOINT E — POST ENDING

After `girl_final_target +5`:

save.

Restart.

Expected:

```text
FINALE
target conquered
no +1 XP duplicate
Phone final complete
FinalDate does not auto-restart
world remains playable
```

---

# 45. AUTOSAVE QA

Trigger individually:

```text
location_changed
day_advanced
stage_changed
girl_conquered
first clone 0→1
```

Expected:

```text
one debounced autosave
valid metadata
no write spam
```

Trigger multiple in <0.75s:

```text
one write
```

---

# 46. AUTOSAVE RECOVERY

Corrupt QA autosave primary.

Valid backup exists.

Continue/Load:

```text
backup recovery works
UI indicates recovery
```

Corrupt both:

```text
Continue chooses another newest valid save if one exists
or disabled/failure safely
```

No silent New Game.

---

# 47. STABLE SAVE GUARD MANUAL

Attempt Save during each:

```text
GirlDiscovery attempt
Dating active
Rival encounter/minigame
Photo Session
FirstClone calibration
FinalDate walking phase
FinalDate modal
```

Expected:

```text
Save unavailable/rejected
clear player-facing reason
```

After completion/abort to stable GAMEPLAY:

save allowed.

---

# 48. SETTINGS RESTART MATRIX

Change and restart:

```text
Master
Music
SFX
UI
Ambience
mouse sensitivity
FOV
camera feedback
UI scale
fullscreen
VSync
tutorial seen
```

Verify persistence.

Do at least one:

```text
New Game after settings
Load old save after settings
```

Settings remain independent.

---

# 49. SAVE SCHEMA V1 LOCK

MODULE27 should NOT change:

```text
SAVE_SCHEMA_VERSION = 1
```

unless a genuine BLOCKER requires new persisted state that cannot be derived.

If schema change becomes unavoidable:

STOP and explicitly document migration impact before implementation.

Default expectation:

```text
no schema change
```

---

# 50. MINIGAME QA — SLAP

Manual production tests:

```text
ordinary player win
ordinary player loss
story player win
story player loss
perfect hit
miss
block
perfect block
```

Verify:

```text
input responsive
score correct
camera returns baseline
audio/VFX not duplicated
story loss Auth0
ordinary loss -1
heroic loss0
```

---

# 51. MINIGAME QA — DANCE

Test:

```text
correct sequence
wrong input
ordinary win/loss
story win/loss
FinalDate exhibition
```

Verify:

```text
Observe/Repeat phase text
sequence resets correctly
no stuck input
Music duck restored
final exhibition no Authority
```

---

# 52. MINIGAME QA — SIGMA

Test with perk unlocked:

```text
zone enter
disturbance
success
loss
story/ordinary if content allows
```

Verify:

```text
gauge stable
no continuous audio spam
no stuck MINIGAME mode
override interactions unaffected
```

---

# 53. MINIGAME QA — MONEY

Test with sufficient Money:

```text
stake
raise
win
loss
insufficient Money edge
```

Verify:

```text
real Money spent exactly once
no negative Money
UI displays real stake
result closes
```

Story fallback prevents softlock without perk/Money.

---

# 54. MINIGAME ABORT / FOCUS

For all four:

```text
alt-tab / window focus loss if practical
pause attempt
rapid input around result
```

Expected:

```text
no double submit
no duplicate Authority
no stuck mouse mode
no duplicate result callback
```

Do not add complex focus architecture unless reproducible bug exists.

---

# 55. GIRL DISCOVERY QA

Test:

```text
success
failure
locked XP
wrong story stage
story rival required
Scientist overload prerequisite
President first-clone prerequisite
```

Verify distinctions:

```text
locked/prerequisite is NOT failure
no cooldown/clue mutation on prerequisite
failure does mutate expected retry/clue
```

---

# 56. DATING QA

At least one girl from each primary:

```text
KIND
STATUS
THRILL_SEEKING
STRANGE
```

and one from each secondary:

```text
SCANDALOUS
CONSISTENT
VARIETY_SEEKING
DEMANDING
```

May overlap girls.

Verify:

```text
greeting0 score
3 central events
farewell
primary evaluation
secondary evaluation
reaction +1/0/-1
relationship clamp
cooldown
event history
```

---

# 57. DATING PLANNER STRESS

Run automated or scripted:

```text
1000 planned evenings
```

across representative girls.

Assert always:

```text
3 central events
no duplicate event ID in evening
not all3 same category
pool references valid
```

No runtime error.

This is QA-only stress; existing planner unchanged unless defect found.

---

# 58. RELATIONSHIP EDGE QA

Test:

```text
relationship -5
+5
crossing through0
reaching+5 exactly
attempting completion again
```

Expected:

```text
clamp -5..5
conquest once
XP once
UP once
```

---

# 59. STORY DOUBLE-CALL QA

For each story completion signal:

simulate/trigger duplicate callback where test seam exists.

Expected:

```text
stage advances once
feature unlock once
XP/reward once
```

No event-order race.

---

# 60. MEDIA QA

Production route:

```text
Photo Session
article
publish
day advance
publish
Attention45
3 offers
overload ready
```

Verify exact.

Additional:

```text
publish daily limit
threshold60
incoming NEW→READ
candidate list includes Module25 girls after old7
```

No duplicate offers.

---

# 61. DATING OVERLOAD QA

Verify:

```text
first wave3
+2/day
boost+3
capacity1/day
WAITING→OVERDUE
completed personal date fulfills oldest same-girl
clone fulfillment overdue-first
recognition exact conditions
generation stops after recognition
```

No negative relationship/Authority penalty from overdue.

---

# 62. OVERLOAD DUPLICATE SIGNAL QA

Recognition threshold can be crossed by several changes close together.

Expected:

```text
problem_recognized once
clone_solution_needed once
```

Scientist pair spawned once.

---

# 63. FIRST CLONE QA

Test:

```text
BODY miss/retry
FACE miss/retry
CONFIDENCE miss/retry
all success
WORK assignment
DATING assignment
```

Expected:

```text
no quality score
total remains0 before assignment
after assignment exact count1
first clone created once
no duplicate representative under MODULE19
```

---

# 64. CLONE INCREMENTAL QA

At runtime:

```text
production multiple due clones on large delta
fractional Money
fractional dates
assignment +/-
all free
local upgrades
rate refresh
```

Invariant always:

```text
0 <= working
0 <= dating
working+dating <= total
free = total-working-dating
```

---

# 65. CLONE SAVE/LOAD CONTINUITY

This is BLOCKER-level.

For known accumulator state:

save/restart/load.

Then advance exact deterministic delta.

Compare with uninterrupted control run.

Expected:

```text
same clone count
same whole Money
same whole automated dates/XP effects
fractional error only normal floating tolerance
```

No timestamp contribution.

---

# 66. CLONE VISUALIZATION QA

At counts:

```text
0
1 work
1 dating
15 mixed
150 mixed
10000 mixed
```

Verify:

```text
rooms min(dating,10)
workers min(work,3)
free min(free,2)
mass actors <=2
external Work/Dating/Free labels correct
CharacterActors <=27
```

No gameplay mutation from visual cycles.

---

# 67. LATE GAME QA

Verify:

```text
President appears after first clone
XP10 gate
President +5 → Stage6
Production Area unlock
global terminal assignments
three global upgrades
manual Reach events
Reach100
Story.complete_world_expansion
Final Location unlock
```

No `girl_final_target` ordinary DateVenue path.

---

# 68. GLOBAL UPGRADE EDGE QA

At each max:

```text
purchase MAX rejected cleanly
Money unchanged
UI MAX
```

Insufficient Money:

```text
no level mutation
```

Production speed upgrade:

elapsed retained/resolved.

---

# 69. REACH EVENT EXACT-ONCE

For all3:

```text
trigger once → +10
trigger again →0
save/load → trigger again →0
```

Story flags persist.

---

# 70. FINALDATE QA — SUCCESS

Production:

```text
start signal
Event1
Dance win
Event2
walk
Slap win
Event3
Event4
score>=3
```

Expected:

```text
target +5
conquered
XP+1/UP+1 once
Stage FINALE
ending
Continue playable
```

---

# 71. FINALDATE QA — RIVAL FAILURE

Lose DANCE.

Retry entire date.

Then lose SLAP.

Retry entire date.

Expected each:

```text
zero permanent gameplay mutation
rivals return
score resets
zone gates reset
target reset
```

---

# 72. FINALDATE QA — CONNECTION FAILURE

Win both rivals.

Choose neutral enough for:

```text
score<3
```

Expected:

```text
connection failure
full retry
no target relationship mutation
```

Then successful retry.

---

# 73. FINALDATE LEAVE QA

During gameplay walking phase:

attempt leave location if UI/world allows.

Expected:

```text
attempt discarded
return later starts from INTRO
```

No partial phase save.

If normal world transition is intentionally unavailable mid-attempt:

that behavior must be clear and non-stuck.

---

# 74. FINALDATE DOUBLE-SUCCESS QA

After target conquered:

attempt to activate success path again via:

```text
beacon
reload
duplicate callback test
```

Expected:

```text
no second XP/UP
no second ending reward mutation
```

---

# 75. UI QA — RESOLUTIONS

Mandatory manual:

```text
1280×720
1920×1080
2560×1440
```

Screens:

```text
Title
Pause
Settings
Save/Load
HUD
Phone each tab
Progression
GirlDiscovery
Dating
Rival UI
4 minigames
Clone Terminal
Global Terminal
FinalDate
Ending
```

No essential clipping/overlap.

---

# 76. UI QA — SCALE

At:

```text
100%
125%
150%
```

at minimum:

```text
1280×720
1920×1080
```

Verify:

```text
scrollable content remains reachable
buttons not offscreen
focus works
minigame field usable
```

---

# 77. UI INPUT QA

Mouse + keyboard:

```text
button click
focus navigation
ESC behavior
E interactions
Space minigames
WASD
```

No controller requirement in MODULE27.

---

# 78. MODAL OWNERSHIP QA

Attempt to open conflicting UI:

```text
Phone during Dating
Phone during minigame
Progression during another modal
Pause around terminal
FinalDate + Phone
```

Expected:

```text
one owner
no stacked mouse/input deadlock
```

After close:

```text
GAMEPLAY restored
HUD/crosshair correct
```

---

# 79. PAUSE QA

Pause during stable gameplay:

```text
tree paused
clone simulation paused
Music/UI behavior acceptable
Save/Load/Settings work
```

Resume:

```text
simulation continues
no giant delta catch-up
```

No offline-style progress from pause duration.

---

# 80. ALT-TAB / FOCUS SMOKE

Desktop smoke:

```text
alt-tab from GAMEPLAY
alt-tab from Phone
alt-tab from minigame
```

Expected:

no crash, no runaway mouse/input.

If OS-specific behavior cannot be automated, document manual result.

---

# 81. AUDIO QA

At default:

```text
music state transitions
ambience no duplicates
UI sounds restrained
dating reaction SFX
minigame duck restore
clone no spam
final signal/ending
```

At volume0:

exact bus category silent.

No audible SFX runaway.

---

# 82. PRESENTATION FALLBACK QA

Deliberately use test fixture/missing optional alias if current test supports.

Expected:

```text
no crash
idle/fallback
```

Do not remove production assets solely for manual test.

---

# 83. PERFORMANCE TARGET — GENERAL

Release QA target at:

```text
1920×1080
```

normal gameplay:

```text
>=60 FPS target
frame time median <=16.7ms
```

QA should focus on **regressions/spikes**, not absolute GPU benchmarking across unknown hardware.

Record test machine specs in report.

---

# 84. PERFORMANCE TARGET — CPU / IDLE

In static apartment/city scene:

```text
no obvious continuous script spikes
no runaway object count
no per-frame allocations from systems that should be event-driven
```

Profiler spot-check.

Do NOT optimize harmless micro-costs without evidence.

---

# 85. PERFORMANCE — CLONE STRESS

QA state:

```text
10000 total
4000 work
5000 dating
1000 free
max local/global upgrades
```

Observe laboratory for:

```text
60 sec
```

Expected:

```text
presentation actors <=27
no node count linear in10000
no SFX per aggregate clone
no particle count linear in10000
stable memory
no obvious frame collapse
```

---

# 86. PERFORMANCE — PRODUCTION AREA

At:

```text
Reach100
max global visual tiers
large clone counts
```

observe60 sec.

No ever-growing nodes/timers/signals.

---

# 87. PERFORMANCE — TRAVEL LEAK

Repeat:

```text
city→lab→city→production→city
```

20 cycles.

Track:

```text
Node count
Object count
memory
AudioStreamPlayer count if practical
```

Expected:

returns roughly to baseline after scenes free.

No monotonically growing leak.

---

# 88. PERFORMANCE — UI OPEN/CLOSE LEAK

Open/close100 times where practical:

```text
Phone
Progression
Clone Terminal
```

Expected:

```text
no duplicate signal callbacks
no increasing UI nodes
no repeated SFX multiply
```

---

# 89. SIGNAL DUPLICATION QA

Common symptom after save/load/travel:

one action causes:

```text
two notifications
two sounds
two XP events
two actor spawns
```

Specifically test after repeated:

```text
return title
load
travel
```

No duplicated connections.

---

# 90. LONG SESSION SOAK

Mandatory:

```text
>=45 minutes
```

continuous game process.

Include:

```text
10+ location travels
Phone/open close
several dates/rivals
clone production
save/autosave
```

Expected:

```text
no crash
no severe memory growth
no stale modal state
no audio duplication
```

May use a late-game save to cover clone phase efficiently.

---

# 91. SAVE SOAK

Repeat:

```text
manual save same slot 25 times
load 10 times across process restarts where practical
```

Expected:

```text
valid primary
valid backup
no malformed temp files used as saves
metadata correct
```

Do not count backup file as an extra UI slot.

---

# 92. CORRUPTION SAFETY

Automated existing tests + manual QA fixture.

Validate:

```text
corrupt primary → backup
bad schema → reject
bad runtime → reject before mutation
bad location → fallback
bad player pose → spawn fallback
```

Current live game unchanged after failed validation.

---

# 93. SETTINGS SOAK

Change settings repeatedly:

```text
FOV 60↔100
UI scale
audio sliders
fullscreen/windowed
camera feedback0↔1
```

No permanent drift.

FOV camera pulses always return configured baseline.

---

# 94. LOG CLEANLINESS

During a successful clean F5:

capture engine log.

Release QA target:

```text
0 SCRIPT ERROR
0 Parse Error
0 unexpected push_error
0 missing production resource
```

Warnings:

each classify.

Known harmless warnings must be listed in `KNOWN_ISSUES.md` or fixed.

Do not normalize a noisy error log.

---

# 95. BROKEN RESOURCE SCAN

Search production files for:

```text
missing ExtResource/SubResource
invalid uid
missing audio stream
missing appearance profile
missing scene path
```

ContentDB pass plus Godot import/boot.

No broken production refs.

---

# 96. PLAYER-FACING PLACEHOLDER SCAN

Search:

```text
TODO
PLACEHOLDER
DEBUG
TEST
Lorem
LOCKED_STORY
STAGE_
girl_
rival_
perk_
```

in player-facing assets/scripts.

Classify legitimate code identifiers vs rendered strings.

Zero accidental technical copy visible to player.

---

# 97. DONOR DEPENDENCY SCAN

Search production runtime for:

```text
../date_factory_legacy
legacy-v1
```

Expected:

```text
0 runtime references
```

Documentation/license notes allowed.

No external relative donor dependency.

---

# 98. ABSOLUTE PATH SCAN

Search production for developer-machine paths:

```text
C:\
/home/
/Users/
PycharmProjects
```

Expected0 runtime refs.

Test logs/docs may contain controlled evidence paths only if not shipped/player-facing.

Preferred remove machine-specific docs too.

---

# 99. DEBUG INPUT SCAN

Find any production debug cheats:

```text
set stage
grant money
grant XP
spawn clone
teleport
```

If debug-only:

must be:

```text
test scene
editor-only
debug build guard
```

No release gameplay key accidentally grants state.

---

# 100. PROCESS LOOP AUDIT

Audit `_process` / `_physics_process` in production.

Classify each:

```text
FPS controller
CloneIncremental realtime simulation
visual animation/tween support
required minigame
other
```

Anything polling state that should be signal-driven is candidate MINOR/MAJOR only if performance impact/reliability defect exists.

Do not architecture-refactor just because QA dislikes polling.

---

# 101. TIMER AUDIT

After 45m soak:

no repeating Timer unintentionally created per interaction/travel.

Particularly:

```text
clone visualization
tutorial
notifications
audio
terminals
world reach visuals
```

---

# 102. INPUT MAP QA

Verify production project input actions all exist:

```text
move_forward/back/left/right
interact
dash if still intended by project
pause
minigame-required actions
```

No code references missing action names.

Do not add unused actions.

---

# 103. PLAYER MOVEMENT QA

Test:

```text
flat movement
stairs/step-up
30° slopes/world geometry
jump/fall if applicable
interaction while moving
```

No change to MODULE01 design.

No sprint/crouch/headbob if still intentionally absent.

---

# 104. COLLISION QA

All nine locations:

walk boundaries and interaction areas.

Blockers:

```text
fall permanently out of map
walk through required wall/gate
transition unreachable
NPC collision traps player
stair/door prevents required route
```

Cosmetic collision mismatch may be Minor.

---

# 105. SOFTLOCK CHECKLIST

Explicitly attempt:

```text
story rival loss at exact threshold
story discovery fail
bad story date
Money0
zero perks
wrong perk branch
first clone DATING
all clones assigned one side
Reach events skipped
save/load during every stable stage
FinalDate failures
return to title/load
```

Every route must have recoverable next action visible in UI.

---

# 106. PHONE OBJECTIVE QA

At every story step:

open Phone Story.

It must tell enough to continue without debug knowledge.

Check:

```text
stage header
current blocker
next location/person/action
```

Do not require perfect quest-arrow navigation.

But no stale previous objective.

---

# 107. TUTORIAL QA — FRESH USER

Reset tutorial settings.

New Game.

Verify seven tutorial prompts appear at appropriate first use and:

```text
not during minigame/modal
no duplicate same prompt
seen persists across restart
Reset Tutorials works
```

No prompt sequence blocks controls.

---

# 108. UI READABILITY WITHOUT TUTORIAL

With tutorials already seen:

New Game still understandable through:

```text
HUD
Phone
world prompts
requirements
results
```

Tutorial cannot be the only source of critical rule.

---

# 109. QA BUG FIX RULE

When defect found:

1. reproduce minimum case;
2. identify owning system;
3. add regression test where practical;
4. implement smallest fix;
5. run affected module suite;
6. run Full QA automated runner;
7. rerun relevant manual step.

Do NOT combine unrelated cleanup.

---

# 110. NO DRIVE-BY REFACTOR

Forbidden during QA unless required to fix blocker:

```text
rename entire architecture
move folders for aesthetics
rewrite working system
replace data layer
new dependency injection
generic state machine refactor
```

Small readable local fix preferred.

---

# 111. REGRESSION TEST REQUIREMENT

Every fixed:

```text
BLOCKER
MAJOR
```

must get an automated regression if technically feasible.

If impossible because purely visual/OS-specific:

document exact manual reproduction + verification.

Minor regression test optional.

---

# 112. KNOWN ISSUES FORMAT

`docs/qa/KNOWN_ISSUES.md`:

```text
ID
severity
area
reproduction
impact
workaround
release decision
```

At MODULE27 completion:

```text
BLOCKER open = 0
MAJOR open = 0
```

Minor/Trivial may remain with explicit release decision.

---

# 113. QA REPORT SUMMARY

`FULL_GAME_QA_REPORT.md` top:

```text
RC QA STATUS: PASS / FAIL
commit SHA
Godot version
OS/test machine
date
automated suites pass/total
manual routes A–F
open blocker/major/minor/trivial
```

---

# 114. REGRESSION MATRIX

Rows:

```text
system
automated suite
manual coverage
save/load coverage
performance coverage
result
evidence/log
```

Systems:

```text
FPS/Interaction
GameState/Data
Characters
Progression
Rivals
Slap
Dance
Sigma
Money
Discovery
Dating
Relationships
Story
World
Salary
Media
Overload
FirstClone
CloneIncremental
CloneVisualization
LateGame
FinalDate
UI
Audio/Presentation
Persistence/Settings
Content
Balance
```

---

# 115. EVIDENCE PATHS

Keep QA evidence under:

```text
tmp/qa/
```

Examples:

```text
summary.txt
automated/*.log
manual_route_a.md
manual_route_b.md
performance_clone_stress.md
performance_soak.md
save_restart_checkpoints.md
```

`tmp/` need not ship in release.

Docs reference the evidence.

---

# 116. MANUAL ROUTE LOGGING

For A–F, Cursor may record concise checkpoints, not every click.

Example:

```text
21:10 New Game
21:27 Stage1
21:51 Stage2
...
```

No invented human playtime if Cursor cannot literally perform full interactive human controls.

Important:

If Cursor cannot physically perform a manual interaction due environment/tool limitations:

mark:

```text
MANUAL VERIFICATION REQUIRED
```

rather than claiming it was played.

Then maximize automated/integration coverage.

---

# 117. CRITICAL HONESTY RULE

Do NOT write:

```text
"full manual F5 passed"
```

unless Cursor actually launched/controlled the game through that route.

Headless simulation is not manual F5.

QA report must distinguish:

```text
AUTOMATED
SCRIPTED INTEGRATION
MANUAL
NOT EXECUTABLE IN CURRENT ENVIRONMENT
```

This is mandatory.

---

# 118. SCRIPTED FULL-GAME INTEGRATION HARNESS

Because fully human input may not be automatable, allowed to add a **test-only** integration harness:

```text
game/qa/test/full_game_integration_test.tscn
```

It may call production APIs to verify state chain:

```text
PROLOGUE→FINALE
```

But:

- no production autoload;
- no debug UI;
- no shipping gameplay dependency;
- cannot substitute for manual minigame/UI validation.

---

# 119. FULL-GAME INTEGRATION HARNESS SCOPE

Verify production state transitions:

```text
story gates
rival rewards/losses
girl completion
Media thresholds
Overload recognition
Scientist gate
FirstClone commit
President XP bridge
Stage6
Reach100
Final target completion invariant
```

Use actual production APIs/content.

Minigame human performance can use controlled test result seams.

---

# 120. FULL-GAME HARNESS MUST NOT CHEAT GATES

It may force:

```text
competition WIN/LOSS result
```

through official test seam.

It may choose known correct dating actions.

It must NOT:

```text
set Stage directly
set XP arbitrarily except initial/reset fixture
mark story flags manually
teleport progression state past owner APIs
```

The point is verifying orchestration.

---

# 121. ROUTE B SCRIPTED INTEGRATION

Add second integration scenario:

```text
story rival LOSS
→ retry
→ WIN
discovery FAILURE
→ day advance
→ SUCCESS
partial date
→ cooldown
→ recovery +5
```

Proves anti-grind state chain automatically.

---

# 122. SAVE INTEGRATION SCENARIO

Test-only chain:

```text
build real state through APIs
save
mutate
load
continue story
```

At least:

```text
Media→Overload
Clone→Stage6
```

This catches state restored but services not synchronized.

---

# 123. PERFORMANCE AUTOMATION — LIGHTWEIGHT

Allowed test-only stress scene:

```text
game/qa/test/late_scale_stress_test.tscn
```

Set aggregate counts via controlled GameState test restore/API.

Observe:

```text
visual node caps
finite rates
no runaway callbacks
```

Do not make FPS benchmark pass/fail from headless renderer.

Frame-rate remains manual/profile evidence.

---

# 124. MEMORY BASELINE

For manual soak record rough:

```text
start memory
after30m
after45m
```

Godot monitor/process OS memory acceptable.

Target:

no obvious unbounded growth.

Do NOT set unrealistic exact MB cap because imported assets/platform differ.

---

# 125. CRASH TEST

Repeatedly perform high-risk transitions:

```text
load while in title
load from pause
New Game after completed game
return title from late game
quit/restart after autosave
```

No crash.

---

# 126. POST-ENDING QA

After Continue from ending:

verify:

```text
player controls
Phone
travel
clone economy
save
load
settings
```

still work.

Game is not accidentally left in modal/paused state.

---

# 127. NEW GAME AFTER ENDING

From title after completed save:

```text
New Game
```

Expected clean state:

```text
PROLOGUE
Day1
target not conquered
Reach0
clones0
story flags reset
manual save slots preserved
settings preserved
```

Autosave later belongs to new run.

---

# 128. CONTINUE SELECTION QA

Create multiple saves with distinct timestamps.

Expected:

```text
Continue picks newest valid
```

Corrupt newest primary with valid backup:

backup metadata/validity handled.

Corrupt newest entirely:

next newest valid selected.

---

# 129. SAVE DELETE QA

Delete:

```text
manual slot
autosave
```

where UI permits.

Expected:

```text
primary + backup removed
metadata updates
Continue recalculates
```

No accidental delete other slot.

---

# 130. FILESYSTEM FAILURE SMOKE

If feasible using isolated test directory/permissions:

simulate write failure.

Expected:

```text
visible save failure
old valid file retained
game continues
```

Do not require OS-specific permission hacks if unsafe/unreliable; existing automated I/O failure tests may suffice.

---

# 131. HEADLESS BOOT

Run:

```text
Godot --headless project
```

or minimal main boot smoke where supported.

No display-dependent crash in non-UI tests.

MODULE28 may use headless checks during build pipeline.

---

# 132. RELEASE DEBUG OUTPUT

Normal production F5 should not flood console every frame.

`DfLog.info` startup/module logs acceptable.

Blockers:

```text
per-frame prints
clone-per-tick spam
UI refresh spam
repeated missing optional asset warnings
```

Fix/remove noisy loops.

---

# 133. RANDOMNESS REPRODUCIBILITY

Cooldown RNG remains random1..3.

For automated tests:

seed/inject existing RNG seam where available.

Do NOT make production RNG deterministic globally just for tests.

---

# 134. DATE CONTENT STRESS

All23 girls:

Content validation.

All16 ordinary:

planner feasibility.

Story/final:

their dedicated validation.

No need manually play every possible event in MODULE27 if automated content tests prove resource validity, but sample broad manual content.

---

# 135. APPEARANCE RESOURCE SMOKE

Instantiate all45 current appearance profiles in a test scene or controlled factory loop.

Expected:

```text
no missing mesh/material/animation crash
CharacterActor created
```

No need render beauty comparison automatically.

---

# 136. AUDIO RESOURCE SMOKE

Load every production AudioDirector mapped stream.

Expected:

```text
exists/loadable/license inventory
```

No null required mapping.

Optional semantic ID may fallback silently only if intentionally optional.

---

# 137. SAVE + CONTENT ID ROUNDTRIP

For every production girl/rival/perk ID category:

representative sample includes newest Module25 resources.

Unknown-content sanitization remains.

Do not exhaustively save one slot per ID.

---

# 138. THREAD / ASYNC

Project should not have hidden background gameplay tasks.

QA checks no work continues after:

```text
return title
pause
scene unload
```

except intended autoload music/menu state.

---

# 139. CLONE PAUSE TEST

Set production near threshold:

```text
29/30 sec
```

Pause for real10 sec.

Resume.

Expected:

```text
not immediately +10s progressed
```

Only resumed delta.

---

# 140. LOAD NO-OFFLINE TEST

Already automated, repeat smoke with real process restart delay if practical.

Expected no real-world elapsed reward.

---

# 141. CHARACTER COLLISION / PRESENTATION

Verify MODULE19 characters:

```text
do not block player
do not receive E interaction
```

Story/ordinary real NPCs:

interaction works.

Final target/rivals stage-specific behavior correct.

---

# 142. INTERACTION PRIORITY

At crowded areas:

```text
President/rival near ToProduction
new cafe NPCs
laboratory terminal/date rooms
```

Raycast prompt should resolve intended target reasonably.

No required interaction permanently occluded by flavor prop/NPC.

---

# 143. AUDIO/PRESENTATION DUPLICATE AFTER LOAD

Load same save repeatedly.

One:

```text
music track state
ambience source
HUD notification
```

No doubled audio.

Loading should not replay stage-advance/reward sting.

---

# 144. STATE_RESTORED UI

After load:

```text
HUD exact
Phone exact
terminals exact
NPC states exact
WorldReach visuals exact
upgrade visual tiers exact
```

without needing an extra gameplay action to refresh.

---

# 145. TITLE SETTINGS BEFORE GAME

Fresh boot:

change:

```text
audio/UI scale/fullscreen
```

before New Game.

Then start.

Player/HUD/Audio respect settings.

---

# 146. FINAL RC BLOCKER GATE

MODULE27 PASS only when:

```text
all required automated suites PASS
all scripted integration suites PASS
BLOCKER open =0
MAJOR open =0
save corruption/recovery PASS
main story orchestration PROLOGUE→ending PASS
final retry PASS
late scale stress PASS
log cleanliness acceptable
```

Manual environment limitations must be explicit.

---

# 147. IF MANUAL F5 CANNOT BE AUTOMATED BY CURSOR

Do not block useful work indefinitely.

Cursor must:

1. maximize automated full-game integration;
2. run every headless suite;
3. generate exact human checklist:
   ```text
   docs/qa/MANUAL_RC_CHECKLIST.md
   ```
4. mark only genuinely human-only items unchecked;
5. STOP.

Then user can run checklist before MODULE28 if desired.

Do not fabricate completion.

---

# 148. MANUAL RC CHECKLIST

If created, must be short enough to execute.

Sections:

```text
10-minute smoke
Route A clean
Route B imperfect
Route E specialized final
Save/restart checkpoints
Resolution/UI
Audio
45m soak
```

Checkboxes with expected result.

No duplicate 150-section spec.

---

# 149. NO RELEASE INTEGRATION AHEAD

Do NOT implement MODULE28:

```text
Steam achievements
new Steam API work
export preset redesign
release depot packaging
crash upload service
store metadata
build signing
```

QA may inspect current existing Steam integration only for crashes if already used.

---

# 150. CURRENT STEAM INTEGRATION

If project already contains Steam integration from legacy/current foundation:

QA smoke only:

```text
game boots with Steam unavailable
game boots with Steam available if local environment permits
no core gameplay depends on Steam
```

No new Steam features.

---

# 151. DOCUMENT UPDATES

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/balance/BALANCE_REPORT.md
```

Balance report:

mark deferred routes with actual QA result or:

```text
manual verification required
```

Create:

```text
docs/qa/FULL_GAME_QA_REPORT.md
docs/qa/REGRESSION_MATRIX.md
docs/qa/KNOWN_ISSUES.md
```

Optional:

```text
docs/qa/MANUAL_RC_CHECKLIST.md
```

---

# 152. PROJECT STATUS AFTER MODULE27

If PASS:

```text
After MODULE27 — Full Game QA
RC QA gate passed
Remaining: MODULE28 Release Integration
```

If human-only checks remain:

```text
Automated RC gate passed
Manual RC checks remaining: N
```

Be exact.

---

# 153. DEFINITION OF DONE

MODULE27 complete only if:

- [ ] repository-wide automated test manifest created;
- [ ] every current required headless/self-test runner included;
- [ ] one-command QA runner exists;
- [ ] runner has timeout and nonzero failure exit;
- [ ] logs captured under tmp/qa;
- [ ] ContentDB production validation passes;
- [ ] clean install/title smoke passes;
- [ ] repeated New Game/title loop has no duplicate persistent UI/state;
- [ ] scripted full-game integration PROLOGUE→FINALE passes;
- [ ] scripted imperfect/retry integration passes;
- [ ] all required module regressions PASS;
- [ ] story stages never skip/reverse/double;
- [ ] story actor visibility matrix passes;
- [ ] Scientist live overload spawn passes;
- [ ] President live first-clone spawn passes;
- [ ] ordinary NPC state matrix sampled/automated;
- [ ] all9 world location access gates pass;
- [ ] save checkpoints early/media/clone/Stage6/post-ending pass;
- [ ] at least critical checkpoints verified across process restart where environment permits;
- [ ] autosave debounce/recovery passes;
- [ ] stable-save guard passes including FinalDate walking phase;
- [ ] settings persistence matrix passes;
- [ ] SAVE_SCHEMA_VERSION remains1;
- [ ] Slap/Dance/Sigma/Money normal regression passes;
- [ ] story loss Authority0 passes in production integration;
- [ ] ordinary loss-1 passes;
- [ ] final exhibition Authority0 passes;
- [ ] GirlDiscovery prerequisites/failures correctly distinguished;
- [ ] Dating primary+secondary coverage tested;
- [ ] planner stress has no invalid evening;
- [ ] conquest XP/UP exact-once passes;
- [ ] Media route→overload passes;
- [ ] Overload recognition exact-once passes;
- [ ] FirstClone WORK/DATING paths pass;
- [ ] CloneIncremental invariants pass;
- [ ] clone accumulator save/restart continuity passes;
- [ ] MODULE19 visual caps pass at10000 clones;
- [ ] President→Stage6→Reach100 passes;
- [ ] global events exact-once through save/load;
- [ ] FinalDate success passes;
- [ ] FinalDate Dance/Slap failure full-retry passes;
- [ ] FinalDate low-score retry passes;
- [ ] final success rewards exact-once;
- [ ] post-ending playable state passes;
- [ ] UI 720p/1080p/1440p inspected where environment permits;
- [ ] UI100/125/150 inspected;
- [ ] modal ownership/input recovery passes;
- [ ] pause does not advance clone simulation;
- [ ] audio duplicate/duck/volume smoke passes;
- [ ] performance clone10000 stress passes;
- [ ] travel/UI leak stress passes;
- [ ] >=45m soak completed where environment permits;
- [ ] clean production log has0 unexpected script/resource errors;
- [ ] donor runtime dependency scan =0;
- [ ] absolute developer path scan =0 production refs;
- [ ] player-facing technical placeholder scan clean;
- [ ] no release debug cheats accessible;
- [ ] BLOCKER open0;
- [ ] MAJOR open0;
- [ ] every fixed Blocker/Major has regression when feasible;
- [ ] FULL_GAME_QA_REPORT complete and honest about manual vs automated;
- [ ] REGRESSION_MATRIX complete;
- [ ] KNOWN_ISSUES complete;
- [ ] Balance Report deferred A–F status updated;
- [ ] no gameplay/content/balance redesign introduced;
- [ ] no MODULE28 features implemented ahead.

---

# 154. RECOMMENDED CURSOR ORDER

```text
1. Audit every existing test runner and build qa/test_manifest.
2. Implement one-command run_all_tests + logging/timeout/fail semantics.
3. Run full baseline immediately; fix any existing Blocker/Major regressions.
4. Add test-only full-game integration route A.
5. Add imperfect/retry integration route B.
6. Add save/service continuation integration.
7. Run ContentDB/resource/placeholder/donor/path scans.
8. Execute NPC/world/story state matrices.
9. Execute minigame/discovery/dating/media/overload/final edge matrix.
10. Run persistence checkpoints + corruption/autosave/settings.
11. Run clone10000/travel/UI stress + soak/performance checks.
12. Execute manual routes A–F where environment actually permits.
13. Never claim manual execution that was not performed.
14. Fix only reproducible defects; add regressions.
15. Rerun entire automated QA after every Blocker/Major fix.
16. Produce FULL_GAME_QA_REPORT / REGRESSION_MATRIX / KNOWN_ISSUES.
17. Update BALANCE_REPORT deferred routes honestly.
18. Update PROJECT_STRUCTURE.
19. STOP. Do not begin MODULE28.
```

---

# 155. CURSOR FINAL REPORT

## RC status

State exactly:

```text
PASS
or
FAIL
```

and why.

## Automated QA

Report:

```text
required suites total
passed
failed
timed out
summary path
```

List any excluded/non-RC suite and reason.

## Full-game integration

Show production state sequence:

```text
PROLOGUE→1→2→3→4→5→6→FINALE→ending
```

Confirm no direct Stage mutation in harness.

## Manual routes

Table:

```text
A Clean
B Imperfect
C Optional
D Broke
E Specialized
F No Clone Upgrades
```

Status must be one of:

```text
MANUAL PASS
SCRIPTED PASS
PARTIAL
NOT EXECUTABLE IN ENVIRONMENT
FAIL
```

Never conflate them.

## Persistence

Show five restart checkpoints and corruption/autosave/settings results.

## NPC / World / UI

Summarize actor matrices, location access, UI resolutions/scales and modal ownership.

## Minigames / Final

Summarize four minigames + exhibition invariants + FinalDate failure/retry/success.

## Performance

Report:

```text
test machine
1080p observation
10000 clone stress
travel leak
45m soak
```

If human/GPU profiling unavailable, say so rather than invent FPS.

## Bugs fixed

For each Blocker/Major:

```text
ID
reproduction
root cause
fix
regression test
```

## Known issues

Count:

```text
Blocker0
Major0
MinorN
TrivialN
```

and link `docs/qa/KNOWN_ISSUES.md`.

## Logs / docs

Paths:

```text
tmp/qa/summary.txt
docs/qa/FULL_GAME_QA_REPORT.md
docs/qa/REGRESSION_MATRIX.md
docs/qa/KNOWN_ISSUES.md
```

## Release gate

Exact:

```text
MODULE27 RC QA gate passed.
Ready for MODULE28 Release Integration.
```

Only if Blocker/Major0 and required automated/scripted gates pass.

If human-only checks remain, state them explicitly.

## Commit

SHA.

Then STOP.
