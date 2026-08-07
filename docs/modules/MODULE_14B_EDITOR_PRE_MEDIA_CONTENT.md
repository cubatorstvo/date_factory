# MODULE 14B — EDITOR & PRE-MEDIA MANUAL CONTENT

**Проект:** Date Factory  
**Родительский модуль:** MODULE 14 — Stage Content: Manual Game  
**Подмодуль:** 14B — Editor & Pre-Media Manual Content  
**Статус:** обязательная спецификация перед реализацией  
**Цель:** завершить ручную сюжетную часть до медийного перелома: наполнить STAGE_3 Редактором журнала, её ухажёром, дополнительными обычными персонажами публичного города и довести production flow до `STAGE_4 / MEDIA_ATTENTION`, не реализуя саму медиа-систему.  
**Предыдущий модуль:** MODULE 14A  
**Следующий модуль:** MODULE 15 — Media / Attention

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 14B заканчивается здесь:

```text
STAGE_3
→ победить rival_magazine_editor
→ познакомиться с girl_magazine_editor
→ завершить её relationship line до +5
→ Story advances to STAGE_4
→ StoryFeature.MEDIA_ATTENTION == true
→ появляется точка/приглашение на фотосессию

STOP
```

MODULE 14B НЕ реализует:

```text
фотосессию
социальную ленту
Attention
публикацию фото
входящие предложения
перегрузку свиданиями
girl_scientist
rival_scientist
```

Эти вещи начинаются в MODULE 15/16/17.

---

# 1. Production content additions

Добавить:

## Story

```text
girl_magazine_editor
rival_magazine_editor
```

## Ordinary girls

```text
girl_public_sculpture
girl_cafe_receipt_notes
girl_appearance_flash
```

## Ordinary rivals

```text
rival_public_coat
rival_public_watch
rival_appearance_tripod
```

Итого после 14A+14B:

```text
11 production girls
10 production rivals
```

---

# 2. STORY GIRL — `girl_magazine_editor`

Exact:

```text
id = &"girl_magazine_editor"
display_name = "Редактор журнала"

is_story = true
has_story_stage = true
story_stage = STAGE_3

primary_trait = STRANGE
secondary_trait = SCANDALOUS

required_experience = 3

discovery_situation_id =
&"discovery_situation_magazine_editor_shoot"

appearance_profile_id =
&"appearance_female_magazine_editor"

dating_pool_ids =
[
    &"date_pool_cafe_common",
    &"date_pool_magazine_editor"
]

default_date_location_id = &"cafe"

dating_greeting_ids =
[
    &"dating_greeting_simple",
    &"dating_greeting_attention",
    &"dating_greeting_immediate_joke",
    &"dating_greeting_check_comfort"
]

dating_farewell_id =
&"dating_farewell_early_common"

speech_style_note =
"Говорит как человек, который постоянно решает, что достойно публикации. Обычную статусность замечает, но быстрее оживает от внутренне последовательной странности, публичного абсурда и материала, который хочется показать другим."
```

---

# 3. Почему STRANGE + SCANDALOUS

Не повторять Актрису как вторую STATUS story girl.

Редактор логически любит:

```text
ABSURDITY
ORIGINALITY
OBSESSION
```

и хуже реагирует на:

```text
PRESTIGE
CONTROL
SIMPLICITY
```

Потому что сюжетный результат её линии:

```text
она видит в герое материал
→ устраивает фотосессию
→ делает его публичным феноменом
```

Secondary `SCANDALOUS` естественно связывает её с публичностью:

```text
public CONFLICT появился → +1
все 4 решения полностью private → -1
иначе → 0
```

---

# 4. Editor clues — exact

```text
0:
"Пока остальные смотрят на человека, она смотрит на то, кто ещё на него смотрит."

1:
"Слишком аккуратные и безопасные истории заканчивает вопросом: «И что здесь показывать?»"

2:
"Когда странная деталь повторяется второй раз, перестаёт считать её случайностью и начинает записывать."
```

---

# 5. Editor placement

Production:

```text
location = appearance_space
story_stage = STAGE_3

girl marker = npc_story_magazine_editor
rival marker = npc_story_magazine_editor_rival
```

Использовать existing `StageActorAnchor`.

В `appearance_space` добавить минимальный studio blockout:

```text
Label3D: "РЕДАКЦИЯ / СЪЁМКА"
backdrop plane
tripod/camera placeholder
2 light stands from primitives
```

Не создавать final art.

Добавить:

```text
StoryEventPoint
story_point_editor_photo_session
```

MODULE 14B marker не запускает. MODULE 15 использует его для фотосессии.

---

# 6. Editor discovery situation

ID:

```text
discovery_situation_magazine_editor_shoot
```

Setup:

```text
"Редактор стоит возле камеры и просит помощника убрать из кадра идеально ровный стул, потому что «слишком похоже на мебель»."
```

До rival defeat — existing story gate.

После rival:

## SUCCESS

```text
id = discovery_approach_magazine_editor_wrong_chair
label = "Поставить стул обратно, но боком"
outcome = SUCCESS

result_text =
"Она посмотрела на стул, потом на тебя и спросила, часто ли ты портишь правильные кадры таким способом."
```

## FAILURE — Capital

```text
id = discovery_approach_magazine_editor_replace_set
label = "Предложить купить нормальную декорацию"
CAPITAL 1
FAILURE

result_text =
"Она сказала, что нормальная декорация и была проблемой."
```

## FAILURE — Muscle

```text
id = discovery_approach_magazine_editor_move_everything
label = "Переставить всю площадку сразу"
MUSCLE 1
FAILURE

result_text =
"Площадка стала другой. Материалом она от этого не стала."
```

---

# 7. STORY RIVAL — `rival_magazine_editor`

Exact:

```text
id = &"rival_magazine_editor"
display_name = "Ухажёр Редактора"

is_story = true
has_story_stage = true
story_stage = STAGE_3

required_authority = 4
authority_reward = 3

muscle = 2
appearance = 4
capital = 4
aura = 2

preferred_competition = MONEY
allowed_competitions = [MONEY, DANCE]

appearance_profile_id =
&"appearance_male_magazine_editor_rival"
```

Canonical no-grind path:

```text
Actress rival +2
Mine Boss rival +2
→ Authority4
```

MONEY тематически подходит после Salary Mine, но main story НЕ требует Payable Intent:

```text
MONEY locked → DANCE available
```

Не делать requirement `must win MONEY`.

---

# 8. Editor date pool

Create:

```text
date_pool_magazine_editor
```

Минимум 4 Editor-specific events:

```text
2 CONVERSATION
1 SPACE_EVENT
1 GIRL_PROPOSAL
```

Union с `date_pool_cafe_common`.

---

# 9. `date_event_editor_publishable_failure`

Category:

```text
CONVERSATION
```

Setup:

```text
"Она спрашивает, какой твой провал стоило бы напечатать целиком, не исправляя ни одной детали."
```

Actions:

```text
"Рассказать самый нелепый как было"
AURA0
[VULNERABILITY, ABSURDITY]
```

```text
"Выбрать историю, где всё закончилось дорого"
CAPITAL1
[PRESTIGE]
```

```text
"Сказать, что провал считается провалом только если кто-то это признал"
MUSCLE1
[DOMINANCE]
```

```text
"Начать с последствия и отказаться объяснять причину до конца"
APPEARANCE1
[ORIGINALITY, OBSESSION]
```

---

# 10. `date_event_editor_headline`

Category:

```text
CONVERSATION
```

Setup:

```text
"Она предлагает придумать заголовок про ваш сегодняшний вечер."
```

Actions:

```text
"«Два человека сходили в кафе»"
MUSCLE0
[SIMPLICITY]
```

```text
"Сначала определить, какую мысль должен вынести читатель"
CAPITAL1
[CONTROL]
```

```text
"«Мужчина пережил стол и требует продолжения»"
AURA0
[ABSURDITY, ORIGINALITY]
```

```text
"Придумать семь вариантов и ранжировать их по угрозе цивилизации"
APPEARANCE1
[OBSESSION]
```

---

# 11. `date_event_editor_public_argument`

Category:

```text
SPACE_EVENT
```

Setup:

```text
"За соседним столом двое спорят, можно ли считать напиток супом, если в нём есть ложка."
```

Canonical liked + SCANDALOUS route:

```text
"Вмешаться и потребовать определить юридический статус ложки"
AURA0
[CONFLICT, ABSURDITY]
is_public = true
```

For STRANGE:

```text
ABSURDITY liked + CONFLICT neutral → Primary +1
public CONFLICT → SCANDALOUS condition satisfied
```

Other actions:

```text
"Не вмешиваться"
MUSCLE0
[SIMPLICITY]
public=false
```

```text
"Предложить критерии классификации"
CAPITAL1
[CONTROL]
is_public=true
```

```text
"Попросить принести второй напиток без ложки как контрольную группу"
APPEARANCE1
[ORIGINALITY, ABSURDITY]
is_public=true
```

---

# 12. `date_event_editor_bad_photo`

Category:

```text
GIRL_PROPOSAL
```

Setup:

```text
"Она предлагает сделать намеренно плохую фотографию и оставить только одну попытку."
```

Actions:

```text
"Просто смотреть в камеру"
MUSCLE0
[SIMPLICITY]
```

```text
"Сначала поправить свет и одежду"
CAPITAL1
[PRESTIGE, CONTROL]
```

```text
"Смотреть не в объектив, а на ближайший огнетушитель"
AURA0
[ABSURDITY]
```

```text
"Встать наполовину вне кадра"
APPEARANCE1
[ORIGINALITY]
```

---

# 13. Editor +5 feasibility — mandatory

Automated content test must prove:

```text
Primary +4
Secondary +1
date_delta = +5
```

At least one route uses:

```text
public CONFLICT + liked STRANGE tag
```

without Primary penalty.

`date_event_editor_public_argument` is canonical.

Also prove at least one feasible combination gives:

```text
date_delta <= -2
```

so trait matters.

---

# 14. New appearance profiles

Create:

Girls:

```text
appearance_female_magazine_editor
appearance_female_public_sculpture
appearance_female_cafe_receipt_notes
appearance_female_appearance_flash
```

Men:

```text
appearance_male_magazine_editor_rival
appearance_male_public_coat
appearance_male_public_watch
appearance_male_appearance_tripod
```

Use existing male/female bases only.

Readable accessories/colour/material differences are enough.

---

# 15. Ordinary girl — `girl_public_sculpture`

```text
display_name = "Девушка у скульптуры"
primary_trait = STRANGE
secondary_trait = CONSISTENT
required_experience = 2

discovery_situation_id = discovery_situation_public_sculpture
appearance_profile_id = appearance_female_public_sculpture

dating_pool_ids = [date_pool_cafe_common]
default_date_location_id = cafe
common greetings/farewell
```

Placement:

```text
city_hub public segment
```

Clues:

```text
0 "У скульптуры без таблички придумывает название раньше, чем ищет настоящее."
1 "Если объяснение слишком разумное, предлагает проверить менее разумное."
2 "Возвращается к одной и той же странной детали, пока она не начинает выглядеть намеренной."
```

Discovery:

```text
"Она рассматривает абстрактную скульптуру, которая с одной стороны выглядит как человек, а с другой — как неоплаченный счёт."
```

```text
"Назвать её «Последний аргумент» и не пояснять"
→ SUCCESS

"Найти правильную табличку"
AURA1
→ FAILURE

"Предложить узнать цену"
CAPITAL1
→ FAILURE
```

---

# 16. Ordinary girl — `girl_cafe_receipt_notes`

```text
display_name = "Девушка с записями на чеке"
primary_trait = KIND
secondary_trait = DEMANDING
required_experience = 2

discovery_situation_id = discovery_situation_cafe_receipt_notes
appearance_profile_id = appearance_female_cafe_receipt_notes

dating_pool_ids = [date_pool_cafe_common]
default_date_location_id = cafe
common greetings/farewell
```

Placement:

```text
cafe
```

Clues:

```text
0 "Записывает на обратной стороне чека не цены, а то, кому обещала перезвонить."
1 "Перед тем как выбрать себе место, спрашивает, не занято ли оно чужими вещами."
2 "Два плохих решения подряд замечает быстрее, чем одно очень хорошее."
```

Discovery:

```text
"Она пытается вспомнить номер телефона курьера, записанный между двумя позициями заказа."
```

```text
"Предложить сфотографировать чек до того, как его потеряют"
→ SUCCESS

"Предложить выбросить чек и заказать снова"
CAPITAL1
→ FAILURE

"Уверенно назвать случайный номер"
AURA1
→ FAILURE
```

---

# 17. Ordinary girl — `girl_appearance_flash`

```text
display_name = "Девушка со вспышкой"
primary_trait = STATUS
secondary_trait = SCANDALOUS
required_experience = 3

discovery_situation_id = discovery_situation_appearance_flash
appearance_profile_id = appearance_female_appearance_flash

dating_pool_ids = [date_pool_cafe_common]
default_date_location_id = cafe
common greetings/farewell
```

Placement:

```text
appearance_space
```

Clues:

```text
0 "Перед фотографией сначала смотрит, кто окажется на заднем плане."
1 "Когда кто-то занимает нужное место, не меняет план — меняет человека."
2 "Тихая удачная сцена интересует её меньше, чем публичная сцена, которую заметили остальные."
```

Discovery:

```text
"Она настраивает вспышку так, чтобы случайные прохожие каждый раз выглядели важнее основного объекта."
```

```text
"Предложить оставить прохожих в кадре"
→ SUCCESS

"Попросить всех разойтись"
MUSCLE1
→ FAILURE

"Оплатить пять минут пустого пространства"
CAPITAL1
→ FAILURE
```

---

# 18. Ordinary rivals

## `rival_public_coat`

```text
display_name = "Самец в длинном пальто"
required_authority = 3
authority_reward = 1

MUSCLE1 APPEARANCE3 CAPITAL2 AURA2
preferred = DANCE
allowed = [DANCE, SLAP]

appearance = appearance_male_public_coat
location = city_hub public segment
```

## `rival_public_watch`

```text
display_name = "Самец, проверяющий часы"
required_authority = 4
authority_reward = 1

MUSCLE1 APPEARANCE2 CAPITAL4 AURA2
preferred = MONEY
allowed = [MONEY, DANCE]

appearance = appearance_male_public_watch
location = city_hub public segment
```

## `rival_appearance_tripod`

```text
display_name = "Самец с моноподом"
required_authority = 4
authority_reward = 1

MUSCLE1 APPEARANCE3 CAPITAL1 AURA3
preferred = SIGMA
allowed = [SIGMA, SLAP]

appearance = appearance_male_appearance_tripod
location = appearance_space
```

MONEY/SIGMA optional; each has story-safe ordinary fallback.

---

# 19. Public city gating

Place:

```text
girl_public_sculpture
rival_public_coat
rival_public_watch
```

behind existing:

```text
WorldFeatureGate(PUBLIC_CITY_ACCESS)
```

Do NOT add stage gates/anchors for these ordinary actors.

Stage1:

```text
physical barrier blocks them
```

Stage2:

```text
barrier opens → content reachable
```

This makes Actress reward physically visible.

---

# 20. Cafe density

After 14B cafe contains:

```text
girl_cafe_laptop
girl_cafe_receipt_notes
rival_cafe_receipt
DateVenueInteractable
```

Keep ~2.5m+ separation and separately targetable prompts.

---

# 21. Appearance-space density

At STAGE3 potentially:

```text
girl_appearance_ritual
girl_appearance_flash
rival_appearance_tripod
rival_magazine_editor
girl_magazine_editor
```

Layout rule:

- Editor pair at studio/backdrop end;
- ritual girl at mirror side;
- flash girl at separate side;
- ordinary rival near entrance/side;
- no overlapping raycast colliders.

If 12x12 blockout is too tight, modestly enlarge `appearance_space`, e.g. 16x14.

Do NOT create new location.

---

# 22. Story progression exact

Before Editor:

```text
Stage = STAGE_3
Experience = 3
Authority = 4
MEDIA_ATTENTION = false
```

Rival win:

```text
Authority +3
rival defeated
Stage remains STAGE_3
Editor gate AVAILABLE
```

Editor +5:

```text
relationship = +5
conquered = true
Experience = 4
Upgrade Points +1
Stage → STAGE_4
MEDIA_ATTENTION = true
```

No photo session automatically starts.

---

# 23. Stage4 handoff — important

`StoryStageDefinition(STAGE_4)` canonically points to:

```text
girl_scientist
rival_scientist
```

but these production definitions intentionally do NOT exist yet.

MODULE 14B must ensure player-facing presentation does not crash/push-error spam when Stage4 starts.

Preferred solution:

Add non-strict lookup APIs if absent:

```text
ContentDB.try_get_girl(id)
ContentDB.try_get_rival(id)
```

Keep strict `get_*` APIs unchanged.

Presentation code that may legally encounter reserved-but-not-authored IDs uses `try_get_*`.

---

# 24. Phone Story handoff

At STAGE4 before MODULE15, Phone should show functional:

```text
СТАДИЯ 4
Медийность

Следующий шаг:
Фотосессия у Редактора
```

Do NOT show broken Scientist objectives yet.

Do NOT create fake Scientist definitions.

No Story source-of-truth changes.

---

# 25. Photo-session handoff contract

MODULE 14B provides only:

```text
StoryFeature.MEDIA_ATTENTION == true
StoryEventPoint = story_point_editor_photo_session
Editor conquered historical state
Stage = STAGE_4
```

MODULE 15 uses these facts to launch its one-time introductory photoshoot.

No extra persistent flags:

```text
editor_completed
photo_session_available
media_unlocked
```

are allowed.

---

# 26. No Attention resource yet

Do NOT add to GameState:

```text
attention
followers
fame
media_score
photos
incoming_dates
```

MODULE15 decides exact media runtime state.

---

# 27. No Scientist content

Do NOT create:

```text
girl_scientist.tres
rival_scientist.tres
appearance_female_scientist
appearance_male_scientist_rival
```

MODULE15/16 create overload, then MODULE17 handles Scientist/Lab entry according to the main plan.

---

# 28. Production catalog expected minimum after 14B

```text
Girls = 11
Rivals = 10

Character-specific appearance profiles = 21
+ male/female base profiles

Discovery situations = 11
Dating events >= 24
Dating pools >= 6
Greetings = 4
Farewells = 1
```

Do not fail if implementation adds a couple extra Editor events.

---

# 29. Repeat-date feasibility

For:

```text
girl_magazine_editor
girl_public_sculpture
girl_cafe_receipt_notes
girl_appearance_flash
```

Automated:

```text
plan date1
record events
plan date2 with Relationships history
```

Date2 succeeds without immediate reuse while alternatives exist.

---

# 30. Experience no-grind test

Clean story-only:

```text
Neighbor +5 → XP1
Actress +5 → XP2
Mine Boss +5 → XP3
Editor requirement3
Editor +5 → XP4
```

No ordinary girl required.

---

# 31. Authority no-grind test

Clean story-only:

```text
Actress rival +2
Mine Boss rival +2
→ Authority4
Editor rival requirement4
```

No ordinary rival required.

If user lost Authority, ordinary rivals provide recovery but remain one-time rewards.

---

# 32. Salary / build interaction

At STAGE3 Salary Mine already works.

This gives player a natural choice:

```text
earn Money
→ buy/use paid date actions
→ potentially purchase Capital perks
→ optionally use MONEY vs Editor rival
```

Do not change salary balance.

---

# 33. Perk milestone

Story completion through Editor yields total:

```text
Experience = 4
Upgrade Points earned total = 4
```

With perk price sequence:

```text
1 → 3 → 9
```

player can naturally own 2 perks after Editor if they spend 1 then 3.

Do NOT grant bonus points or rebalance cost.

---

# 34. Tone

Editor humor:

```text
professional media seriousness
applied to complete nonsense
```

Correct examples:

- legal status of a spoon;
- whether failure is publishable;
- an intentionally bad photo;
- treating repeated weirdness as editorial pattern.

Avoid:

- fourth-wall jokes;
- direct social-network brand spam;
- influencer jargon as every joke;
- humiliating women.

---

# 35. Visual differentiation

Editor:
- editorial accessory;
- sharper silhouette;
- glasses/clipboard/camera strap if existing assets permit.

Public sculpture girl:
- arty/odd cue.

Receipt-notes girl:
- practical/plain cue.

Flash girl:
- studio/photo cue.

Rivals:
- coat;
- watch;
- monopod/tripod cue.

Placeholder materials/accessories are enough.

---

# 36. F5 full-route acceptance

Clean reset, no debug:

```text
Neighbor
→ STAGE1
→ Actress rival + Actress
→ STAGE2
→ Mine Boss rival + Mine Boss
→ STAGE3
→ Salary Mine available
→ Editor rival + Editor
→ Editor +5
→ STAGE4
→ MEDIA_ATTENTION true
→ photo-session marker exists
```

No manual stage/XP/Auth setters.

---

# 37. Specific tests — Editor rival

Expected:

```text
Authority4
```

Without Payable Intent:

```text
DANCE selectable
MONEY locked
```

With Payable Intent:

```text
MONEY selectable
DANCE selectable
```

Win:

```text
Authority7
rival defeated
rival actor leaves
Editor available
Stage3 unchanged
```

---

# 38. Specific tests — Editor completion

Before:

```text
XP3
Stage3
MEDIA_ATTENTION false
```

After Editor +5:

```text
XP4
Upgrade Point +1 exactly once
Stage4
MEDIA_ATTENTION true
Editor StageActor removed
```

No photo session auto-run.

---

# 39. Stage4 missing-content safety test

Immediately after Stage4:

- no missing `girl_scientist` crash;
- no missing `rival_scientist` crash;
- no fake actor;
- Story remains Stage4;
- Phone shows media handoff;
- World remains playable.

---

# 40. Public-area progression test

At Stage1:

```text
public sculpture girl / coat rival / watch rival inaccessible behind gate
```

At Stage2:

```text
gate opens
same actors become physically reachable
```

No respawn logic needed.

---

# 41. ContentDB validation

`ContentDB.validate_all()` PASS.

Validate:

- exact production IDs;
- new discovery references;
- date bindings;
- appearance references;
- Editor pool/event references;
- actions max2 tags;
- no duplicate approach/action IDs;
- every new girl has feasible date content.

---

# 42. Scene smoke tests

Check manually:

```text
appearance_space:
Editor pair + 3 ordinary NPC prompts separately targetable

city public:
3 new NPC prompts separately targetable

cafe:
2 girls + rival + DateVenue separately targetable
```

Reposition/expand blockout if required.

---

# 43. Reset

After reaching Stage4, reset must restore:

```text
Stage PROLOGUE
Editor absent
Editor rival undefeated but absent due wrong stage
public city gate locked
new ordinary public actors physically behind gate
contacts/relationships reset
```

No stale Editor child in appearance_space after refresh/reload.

---

# 44. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/05_girls.md
docs/gdd/06_dating.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Update/create content inventory:

```text
docs/content/MANUAL_CONTENT_14B.md
```

Include:

```text
ID
Role
Location
Stage
Trait/competition
XP/Auth requirement
Pool
Placement
Status
```

---

# 45. What MODULE 14B DOES NOT implement

Do NOT implement:

- actual photo session;
- Media service;
- Attention/fame resource;
- social feed;
- photo publishing;
- incoming date proposals;
- Dating Overload;
- Scientist;
- Scientist rival;
- Laboratory story line;
- clone mechanics;
- President;
- World Expansion;
- final content;
- NPC schedules;
- dialogue engine;
- final art/audio;
- save/load.

---

# 46. Definition of Done

MODULE 14B done only if:

- [ ] `girl_magazine_editor` exists;
- [ ] Editor exact STRANGE + SCANDALOUS;
- [ ] required Experience = 3;
- [ ] Editor 3 clues exist;
- [ ] Editor discovery playable;
- [ ] `rival_magazine_editor` exists;
- [ ] required Authority = 4;
- [ ] authority reward = 3;
- [ ] preferred MONEY;
- [ ] allowed MONEY + DANCE;
- [ ] story never requires MONEY perk;
- [ ] Editor pair StageActorAnchors in appearance_space;
- [ ] photo studio blockout readable;
- [ ] `story_point_editor_photo_session` exists;
- [ ] `date_pool_magazine_editor` exists;
- [ ] 4 Editor-specific events exist;
- [ ] Editor perfect +5 route passes;
- [ ] Editor negative-date route passes;
- [ ] 3 new ordinary girls exist;
- [ ] 3 new ordinary rivals exist;
- [ ] 8 new appearance profiles exist;
- [ ] 4 new discovery situations exist;
- [ ] public city segment contains new reachable content after Stage2;
- [ ] no duplicate story gate on ordinary public actors;
- [ ] clean route reaches Editor with XP3/Auth4;
- [ ] Editor rival defeat does not advance stage;
- [ ] Editor +5 advances Stage3→Stage4;
- [ ] MEDIA_ATTENTION true after completion;
- [ ] XP becomes4;
- [ ] Upgrade Point granted once;
- [ ] no photo session auto-run;
- [ ] no Media state/resource implemented;
- [ ] no Scientist production content;
- [ ] Stage4 presentation safe without Scientist definitions;
- [ ] Phone shows media handoff;
- [ ] full clean F5 route reaches Stage4;
- [ ] ContentDB validation PASS;
- [ ] repeat-date feasibility PASS;
- [ ] previous regressions PASS;
- [ ] MODULE15 not implemented ahead.

---

# 47. Recommended Cursor order

```text
1. Audit Stage4 presentation for strict Scientist lookups.
2. Add safe try_get content APIs if necessary.
3. Create Editor girl/rival/appearances/discovery/pool/events.
4. Add Editor pair + photo marker to appearance_space.
5. Prove Stage3 → Editor → Stage4 flow.
6. Add three ordinary girls/rivals + appearances/discoveries.
7. Place public-area/cafe/appearance content.
8. Density/layout smoke pass.
9. Add Stage4 media handoff to Phone Story presentation.
10. Clean F5 PROLOGUE→Stage4 run.
11. ContentDB + date feasibility + all regressions.
12. Docs/content inventory.
```

---

# 48. Cursor final report

## Production route

```text
F5
→ Neighbor
→ Actress
→ Mine Boss
→ Editor
→ STAGE4
→ MEDIA_ATTENTION
```

without debug.

## Editor

Report:

```text
primary/secondary trait
XP requirement
rival Authority requirement
competition set
dating pool/events
```

## Media handoff

Confirm:

```text
photo marker exists
Stage4 unlocked
Phone handoff exists
no photo/media mechanics
no Scientist actor
```

## Ordinary content

List 3 girls + 3 rivals and locations.

## Counts

Production catalog counts.

## Validation

ContentDB, Editor +5, full F5, repeat dates, regressions.

## Commit

SHA.

Then STOP. Do not begin MODULE15.
