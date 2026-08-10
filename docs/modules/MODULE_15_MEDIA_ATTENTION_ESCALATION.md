# MODULE 15 — MEDIA / ATTENTION ESCALATION

**Проект:** Date Factory  
**Модуль:** 15 — Media / Attention Escalation  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** реализовать медийный перелом после Редактора: отдельную фотосессию, публикацию в крупном медиа, простую социальную ленту в телефоне, ограниченный набор фотографий для публикации, рост Внимания, первые входящие инициативы девушек, видимый рост известности и clean handoff в MODULE 16 Dating Overload.  
**Предыдущий модуль:** MODULE 14B  
**Следующий модуль:** MODULE 16 — Dating Overload

**Product truth:** `docs/MASTER_GDD.md`, `docs/gdd/07_story_clones_finale.md`, `docs/gdd/08_locations_ui_content.md`  
**Tech boundary:** `docs/tech/TECH_PLAN_FULL.md`

---

# 0. ГЛАВНАЯ ГРАНИЦА

MODULE 15 начинается после:

```text
girl_magazine_editor relationship == +5
→ Story advances STAGE_3 → STAGE_4
→ StoryFeature.MEDIA_ATTENTION unlocked
```

MODULE 15 реализует:

```text
MEDIA_ATTENTION unlocked
→ отдельная фотосессия у Редактора
→ герой появляется в медиа
→ телефон получает MEDIA section
→ Внимание начинает расти
→ игрок публикует ограниченные фотографии
→ девушки сами начинают писать
→ количество доступных романтических инициатив заметно растёт
→ Media сообщает: overload_ready
```

MODULE 15 НЕ реализует саму перегрузку расписания.

STOP перед:

```text
накладывающимися встречами
capacity / one-body limitation
растущим backlog demand
выводом «проблема в количестве меня»
Scientist line
laboratory
cloning
```

Это MODULE 16+.

---

# 1. Что требует GDD

После Редактора:

```text
отдельная фотосессия
→ публикация в журнале/газете/новостях
→ простая социальная лента
→ возможность публиковать фотографии
→ рост внимания
→ девушки начинают сами писать
→ количество доступных свиданий резко растёт
```

Телефон после медийной стадии должен позволять:

```text
видеть рост внимания
видеть входящие инициативы
публиковать ограниченное число фотографий
сознательно увеличивать поток свиданий
```

Это НЕ полноценный social network simulator.

---

# 2. `Внимание` — canonical MODULE 15 meaning

Создать media-state показатель:

```text
Внимание / Attention
```

Это:

- persistent;
- non-spendable;
- integer;
- range `0..100`;
- показатель текущей публичной заметности героя.

Это НЕ:

- Деньги;
- Авторитет;
- Покоренных сердец;
- Балл прокачки;
- отдельная экономика.

Внимание используется только для:

```text
media presentation
incoming initiatives
MODULE16 demand escalation
```

---

# 3. Почему Attention 0..100

Игроку нужна читаемая шкала:

```text
Внимание: 45 / 100
```

Не нужны:

- followers in millions;
- hidden logarithms;
- engagement rate;
- impressions;
- views;
- likes;
- CTR.

MODULE 20 позже может визуально перейти к большим масштабам другими системами.

---

# 4. Attention rules

Canonical:

```text
MIN = 0
MAX = 100
```

MODULE 15:

- Attention только растёт;
- decay отсутствует;
- publishing не расходует Attention;
- no random modifiers.

Future module может добавить temporary demand multiplier, но не должен переопределять уже заработанный Attention без отдельного решения.

---

# 5. GameState media state

Добавить persistent:

```text
_media_photo_session_completed: bool = false
_media_attention: int = 0

_media_photo_pose_by_shot: Dictionary = {}
_media_published_photo_ids: Array[StringName] = []

_media_last_photo_publish_day: int = -1

_media_incoming_offer_girl_ids: Array[StringName] = []
_media_read_offer_girl_ids: Array[StringName] = []

_media_feed_event_ids: Array[StringName] = []
```

---

# 6. Reset

GameState reset:

```text
photo_session_completed = false
attention = 0
pose map empty
published photos empty
last publish day = -1
incoming offers empty
read offers empty
feed empty
```

---

# 7. GameState Attention API

Minimal:

```text
get_media_attention() -> int
set_media_attention(value: int)
add_media_attention(amount: int) -> int
```

Gameplay clamps:

```text
0..100
```

Signal:

```text
media_attention_changed(new_value, delta)
```

---

# 8. Photo session state API

Minimal:

```text
is_media_photo_session_completed()
mark_media_photo_session_completed() -> bool

set_media_photo_pose(shot_id, pose_id)
get_media_photo_pose(shot_id)
get_media_photo_pose_map()
```

Do not allow normal gameplay to overwrite a committed shot after session completion.

---

# 9. Published photo state

API:

```text
is_media_photo_published(photo_id)
mark_media_photo_published(photo_id) -> bool
get_media_published_photo_ids()
```

Ordered unique.

---

# 10. Feed state

Feed stores compact semantic IDs only.

Examples:

```text
feed_article_editor
feed_photo_media_photo_profile
feed_inbound_girl_public_sculpture
```

API:

```text
append_media_feed_event(event_id) -> bool
get_media_feed_event_ids()
```

Ordered; duplicate ID rejected.

No generic social post database.

---

# 11. Incoming offers state

`incoming_offer_girl_ids` = ordered unique girls who proactively wrote after Media exposure.

API:

```text
has_media_incoming_offer(girl_id)
add_media_incoming_offer(girl_id) -> bool
get_media_incoming_offer_girl_ids()

is_media_offer_read(girl_id)
mark_media_offer_read(girl_id)
```

No accept/decline/schedule state in MODULE 15.

---

# 12. Why offers have no accept/decline yet

MODULE 15 only proves:

> спрос появился и начал расти.

MODULE 16 owns:

- simultaneous proposals;
- capacity;
- scheduling conflict;
- backlog pressure.

In MODULE 15 an incoming card can be:

```text
NEW
READ
```

but cannot be permanently declined to avoid the future overload.

---

# 13. Media service

Create canonical autoload:

```text
Media
```

Responsibilities:

- feature availability;
- photo-session completion;
- Attention;
- photo publishing;
- media feed view model;
- incoming initiatives;
- overload-ready condition;
- media signals.

No `_process()`.

---

# 14. Autoload order

Append after current production systems:

```text
...
Story
World
SalaryMine
Media
```

Media needs:

```text
GameState
ContentDB
GameDay
Story
GirlDiscovery
```

It does NOT require DatingCore/Relationships for core operations beyond querying candidate girls.

---

# 15. Media activation

Media feature is story-available when:

```text
Story.is_feature_unlocked(StoryFeature.MEDIA_ATTENTION)
```

But the actual social feed remains inactive until:

```text
photo_session_completed == true
```

This preserves canonical sequence:

```text
Editor +5
→ photo session
→ publication
→ media effects
```

---

# 16. No article before photo session

At STAGE_4 immediately after Editor completion:

```text
Attention = 0
incoming offers = 0
feed inactive
```

Phone says:

```text
Фотосессия у Редактора
```

exactly as 14B.

---

# 17. Photo session location

Use existing:

```text
appearance_space
story_point_editor_photo_session
```

No new location.

---

# 18. `PhotoSessionInteractable`

Create:

```text
class_name PhotoSessionInteractable
extends Interactable
```

Placed at/near:

```text
story_point_editor_photo_session
```

---

# 19. Photo interactable availability

Visible/interactive when:

```text
MEDIA_ATTENTION feature unlocked
AND
photo_session_completed == false
```

Before Stage4:

- hidden or disabled.

After completed:

- no repeat;
- can remain as noninteractive visual studio.

---

# 20. Photo prompt

Before completion:

```text
[E] Фотосессия у Редактора
```

After completion:

```text
Съёмка завершена
```

No second session.

---

# 21. Photo session is not a generic minigame framework

Create one bespoke:

```text
MediaPhotoSession
```

Do NOT add:

```text
PhotoMinigameRegistry
PoseEngine
ShootManager
PhotoQualitySystem
CameraSimulation
```

Exactly three fixed shots.

---

# 22. Control mode

During photo session:

```text
PlayerControlMode.MODAL_UI
mouse visible
```

Current `appearance_space` remains visible behind UI.

No scene transition.

---

# 23. Photo session phases

Exact:

```text
INTRO
SHOT_1
SHOT_2
SHOT_3
RESULT
FINISHED
```

One selection per shot.

No RNG.

---

# 24. Appearance is the photo-session stat

Photo-session pose availability depends only on:

```text
PlayerCharacteristic.APPEARANCE
```

This fulfills GDD:

> Внешность improves photo sessions/public events.

No hidden chance.

---

# 25. Three fixed photo IDs

Canonical:

```text
media_photo_profile
media_photo_chair
media_photo_cover
```

---

# 26. Three pose tiers per shot

Each shot has exactly three pose choices:

```text
BASE
STAGED
EDITORIAL
```

Requirements:

```text
BASE      → Appearance 0
STAGED    → Appearance 1
EDITORIAL → Appearance 2
```

Attention value when later published:

```text
BASE      → +10
STAGED    → +15
EDITORIAL → +20
```

---

# 27. Pose choice is visible requirement

Disabled choices display:

```text
Внешность 1
Внешность 2
```

No random quality roll.

---

# 28. Shot 1 — Profile

ID:

```text
media_photo_profile
```

Setup:

```text
"Редактор просит сделать фотографию профиля, но уточняет, что профиль должен что-то сообщать."
```

Choices:

## BASE

```text
pose_media_profile_normal
"Повернуться боком"
Appearance 0
Attention +10
```

## STAGED

```text
pose_media_profile_registered
"Выставить поставленный профиль"
Appearance 1
Attention +15
```

## EDITORIAL

```text
pose_media_profile_wrong_target
"Смотреть в профиль не камеры, а ближайшего прожектора"
Appearance 2
Attention +20
```

---

# 29. Shot 2 — Chair

ID:

```text
media_photo_chair
```

Setup:

```text
"В кадр возвращают тот самый стул. Редактор говорит, что теперь он официально часть материала."
```

Choices:

## BASE

```text
pose_media_chair_sit
"Сесть как на стул"
Appearance 0
+10
```

## STAGED

```text
pose_media_chair_sideways
"Сесть боком, как будто так и было задумано"
Appearance 1
+15
```

## EDITORIAL

```text
pose_media_chair_argument
"Поставить стул рядом и позировать так, будто он проиграл спор"
Appearance 2
+20
```

---

# 30. Shot 3 — Cover

ID:

```text
media_photo_cover
```

Setup:

```text
"Последний кадр должен стать обложкой. Редактор просит не пытаться выглядеть нормально."
```

Choices:

## BASE

```text
pose_media_cover_stand
"Просто стоять"
Appearance 0
+10
```

## STAGED

```text
pose_media_cover_turn
"Развернуться на полшага позже команды"
Appearance 1
+15
```

## EDITORIAL

```text
pose_media_cover_half_frame
"Оставить половину себя за краем кадра"
Appearance 2
+20
```

---

# 31. Shot commit

Selection stores:

```text
shot_id → pose_id
```

but does NOT add Attention yet.

Attention comes only from:

```text
publication
```

---

# 32. Session abort

If player closes/leaves before RESULT:

- no photo-session completion;
- no article;
- no Attention;
- partial transient selections discarded.

They can restart.

No mid-session save.

---

# 33. Session completion transaction

After third shot and final Continue:

1. validate all 3 shot selections;
2. store all three pose selections;
3. mark photo session completed;
4. publish Editor article;
5. add first Attention;
6. create first inbound offer threshold effects;
7. emit:
   ```text
   photo_session_completed
   ```
8. return Player to GAMEPLAY.

Exactly once.

---

# 34. Initial article

On first photo session completion automatically publish:

```text
feed_article_editor
```

Headline:

```text
"Редакция подтверждает воспроизводимую странность городского самца"
```

Subline:

```text
"Субъект отказался объяснять часть поз и тем самым подтвердил их редакционную ценность."
```

Functional feed text; final copy can be polished MODULE25.

---

# 35. Article Attention

Exact:

```text
ARTICLE_ATTENTION = 15
```

Session completion:

```text
Attention 0 → 15
```

No dependence on photo pose quality.

---

# 36. Why article starts at 15

At first publication:

- media system becomes visible;
- first incoming initiative appears immediately;
- player understands causal link without waiting a day.

---

# 37. Photo publication

After session three unpublished photo cards exist:

```text
media_photo_profile
media_photo_chair
media_photo_cover
```

Each can be published once.

---

# 38. One photo post per GameDay

Exact rule:

```text
max 1 player photo publication per GameDay
```

Use:

```text
GameDay.current_day
```

State:

```text
media_last_photo_publish_day
```

---

# 39. Article does NOT consume daily photo post

On the same day as photo session:

- Editor article auto-publishes;
- player may also publish one photo.

`last_photo_publish_day` is only set by player photo publication.

---

# 40. Why 1/day

Purpose:

- feed grows visibly over several game days;
- incoming initiatives arrive progressively;
- player can consciously accelerate but not dump all photos instantly;
- existing `Завершить день` gets a meaningful midgame use.

This is NOT a real scheduling system.

---

# 41. Publish API

```text
publish_photo(photo_id) -> MediaPublishResult
```

Validation:

1. Media active;
2. known fixed photo ID;
3. photo session completed;
4. pose for photo exists;
5. not previously published;
6. current day != last publish day.

---

# 42. Publish result

Typed result:

```text
ok
error
photo_id
attention_gained
attention_after
new_offer_girl_ids
```

Errors:

```text
LOCKED
PHOTO_SESSION_REQUIRED
UNKNOWN_PHOTO
NOT_PREPARED
ALREADY_PUBLISHED
DAILY_LIMIT
```

---

# 43. Photo Attention value

Derived from selected pose:

```text
BASE 10
STAGED 15
EDITORIAL 20
```

No additional stat multiplier.

No random engagement.

---

# 44. Publishing feed entry

Photo publication appends:

```text
feed_photo_<photo_id>
```

Feed renderer resolves:

- photo title;
- selected pose label;
- Attention gain.

---

# 45. Attention threshold offers

MODULE 15 exact thresholds:

```text
15
30
45
60
```

When Attention reaches/crosses each threshold:

```text
generate exactly 1 new incoming initiative
```

Maximum new threshold initiatives in MODULE 15:

```text
4
```

---

# 46. Why threshold-driven, not RNG

The player must understand:

```text
публикация
→ Attention
→ входящее сообщение
```

No hidden chance.

---

# 47. Incoming candidate priority

Use existing ordinary production girls only.

Canonical priority list:

```text
girl_appearance_flash
girl_public_sculpture
girl_cafe_receipt_notes
girl_gym_chalk
girl_appearance_ritual
girl_cafe_laptop
girl_city_bicycle
```

Exclude story girls.

---

# 48. Candidate eligibility

A candidate is eligible if:

```text
GirlDefinition exists
is_story == false
required_experience <= current Experience
not already used as a Media incoming offer
```

Contact/conquered status does NOT exclude her.

Reason:

> even a girl the hero already knows can proactively ask for another date after seeing the publication.

This guarantees media pressure for completionist players too.

---

# 49. If candidate has no contact

When incoming offer is created:

1. mark girl discovered;
2. reveal clue index 0 if not known;
3. add girl contact;
4. clear discovery retry cooldown.

Do NOT apply `Good Profile` extra clue:
this is not a visual first encounter.

---

# 50. If candidate already has contact

Do not mutate:

- relationship;
- date cooldown;
- conquered state.

Only add media incoming offer/feed event.

---

# 51. If candidate is conquered

Still allowed to send a new initiative.

Completion is historical:

```text
замутил
```

not a permanent ban on optional repeat dates.

No Experience reward from offer.

---

# 52. Incoming feed event

Append:

```text
feed_inbound_<girl_id>
```

Example rendering:

```text
НОВОЕ СООБЩЕНИЕ

Девушка у зеркала:
«Видела материал. Вопросов стало больше. Можно начать с кафе.»
```

Do not require unique bespoke message for all girls in MODULE15.

---

# 53. Incoming message templates

Use simple trait-sensitive template for presentation only.

## KIND

```text
"Видела публикацию. Ты там выглядел как человек, которому иногда нужна помощь с решениями. Кофе?"
```

## STATUS

```text
"Видела материал. Подача спорная, но заметная. Можно встретиться."
```

## THRILL_SEEKING

```text
"После этой публикации стало интересно, что ты сделаешь без редактора рядом. Пойдём куда-нибудь."
```

## STRANGE

```text
"Видела фотографию. Она объяснила меньше, чем должна была. Это хороший повод встретиться."
```

These are feed copy, not dialogue trees.

---

# 54. Mark offer read

Phone can:

```text
Открыть
```

which:

1. marks `read`;
2. selects that girl's journal entry.

Offer remains in incoming list.

No accept/decline.

---

# 55. Date availability from offer

If normal `Relationships` says girl available for date:

- existing DateVenue can immediately list her by contact.

If date cooldown >0:

- offer still exists;
- DateVenue shows normal cooldown.

Media does not bypass date cooldown.

---

# 56. No auto-date

Incoming initiative does NOT:

- start DatingCore;
- teleport player;
- schedule date;
- change GameDay.

Player still physically goes to cafe/venue in MODULE15.

This is important groundwork for MODULE16.

---

# 57. `overload_ready` condition

Media exposes derived:

```text
OVERLOAD_READY_ATTENTION = 45
OVERLOAD_READY_OFFERS = 3
```

Condition:

```text
Attention >= 45
AND
incoming_offer_count >= 3
```

---

# 58. Overload ready signal

First transition false→true:

```text
overload_ready()
```

exactly once per run.

Media also provides:

```text
is_overload_ready() -> bool
```

MODULE16 will use/query it.

---

# 59. No Story stage transition

`overload_ready` does NOT:

- advance STAGE_4;
- spawn Scientist;
- unlock Laboratory;
- set world expansion.

It is only the bridge to MODULE16.

---

# 60. Attention progression examples

### Appearance 0 route

```text
article +15
photo1 +10 →25
photo2 +10 →35
photo3 +10 →45
```

Offers:

```text
15
30
45
```

After third photo:

```text
3 offers
overload_ready == true
```

Guaranteed.

---

# 61. Appearance 2 route

```text
article15
photo1 20 →35
photo2 20 →55
```

Thresholds crossed:

```text
15
30
45
```

So after only two player publications:

```text
3 offers
overload_ready == true
```

Higher Appearance accelerates media escalation without hidden probability.

---

# 62. Fourth offer

If Attention reaches:

```text
60
```

fourth offer appears.

This may happen before or after overload-ready.

MODULE15 still allows it.

---

# 63. Attention max

Any addition beyond100 clamps100.

No further MODULE15 threshold offers after60.

MODULE16 may use Attention continuously for demand rate.

---

# 64. Phone Media section

Extend existing PhoneJournal.

Before MEDIA_ATTENTION:

```text
Media section hidden.
```

After feature unlocked but before photo session:

```text
МЕДИА

Фотосессия доступна у Редактора.
Внимание: 0 / 100
```

No feed/photo buttons yet.

---

# 65. Phone after photo session

Functional layout:

```text
МЕДИА
Внимание: 35 / 100

ФОТОГРАФИИ
[Профиль — Опубликовать]
[Стул — опубликовано]
[Обложка — Опубликовать]

ВХОДЯЩИЕ
• NEW Девушка со вспышкой
• READ Девушка у скульптуры

ЛЕНТА
• Редакция подтверждает...
• Фото: ...
• Новое сообщение: ...
```

Do not redesign entire Phone into real social app.

---

# 66. Photo publish button state

For each photo:

- not prepared → hidden;
- prepared/unpublished/current-day available → enabled;
- already published → `Опубликовано`;
- unpublished but daily limit used → disabled + `Следующая публикация завтра`.

---

# 67. Incoming rows

Each incoming offer row:

```text
NEW/READ
display_name
[Открыть]
```

`Открыть` calls existing journal selection.

No schedule button.

---

# 68. Feed order

Use GameState `media_feed_event_ids` order.

Newest may display top or bottom; choose one and document.

Preferred:

```text
newest first
```

while persistent array remains chronological oldest→newest.

---

# 69. Feed event rendering

Known event types only:

```text
feed_article_editor
feed_photo_*
feed_inbound_*
```

Unknown IDs:

- debug warning;
- skip production display.

No raw technical IDs.

---

# 70. Photo titles

Exact:

```text
media_photo_profile → "Профиль"
media_photo_chair   → "Стул"
media_photo_cover   → "Обложка"
```

---

# 71. Media world visuals

GDD requires visible growth of fame.

Create small:

```text
MediaAttentionVisual
```

Node3D adapter.

Export:

```text
min_attention: int
```

It toggles a visual subtree based on current Media Attention.

No generic requirement DSL.

---

# 72. MediaAttentionVisual behavior

At `_ready()`:

```text
refresh
```

Listen:

```text
Media.attention_changed
```

No `_process()`.

Visible if:

```text
Attention >= min_attention
```

---

# 73. Physical visual stages

Add simple primitive/text groups.

## Attention 15

`city_hub` public segment:

```text
MagazineStand
Label3D:
"НОВЫЙ ВЫПУСК"
```

## Attention 30

Two wall poster placeholders:

```text
"САМЕЦ НЕДЕЛИ — МАТЕРИАЛ ВНУТРИ"
```

## Attention 45

Large public-board placeholder:

```text
"ЛИЦО ПОДТВЕРЖДЕНО РЕДАКЦИЕЙ"
```

## Attention 60

Appearance studio sign:

```text
"ПОВТОРНАЯ СЪЁМКА НЕ ТРЕБУЕТСЯ.
ОБЩЕСТВЕННОСТЬ УЖЕ СМОТРИТ."
```

---

# 74. Visuals are presentation-only

Do not:

- change collision;
- change Story gates;
- spawn crowd AI;
- grant stats.

Only visible escalation.

---

# 75. Optional camera flash presentation

When publishing a photo or receiving offer:

Phone can briefly flash/pulse functional UI.

No audio/polish requirement until MODULE23.

---

# 76. Photo session presentation

At each shot:

- setup text;
- 3 pose choices;
- after selection:
  ```text
  ВСПЫШКА
  ```
  ~0.25s white overlay;
- Editor one short result line.

No scoring bar.

---

# 77. Editor shot feedback

Examples:

BASE:

```text
"Редактор: «Пригодно. Человек присутствует.»"
```

STAGED:

```text
"Редактор: «Уже похоже на решение.»"
```

EDITORIAL:

```text
"Редактор: «Не исправляй. Именно это и оставим.»"
```

Presentation only.

---

# 78. Photo session exact-once

Double final callback cannot:

- publish article twice;
- add +15 twice;
- create duplicate first offer.

Use:

```text
mark_media_photo_session_completed()
```

idempotency boundary.

---

# 79. Publish exact-once

`mark_media_photo_published(photo_id)` must occur inside safe commit.

Double button/callback:

```text
ALREADY_PUBLISHED
```

No duplicate Attention/feed/offers.

---

# 80. Threshold crossing exact-once

For each threshold:

Media checks whether corresponding offer ordinal already exists.

Do not store four separate bools if count/history already proves crossing.

Example:

```text
desired_offer_count =
count(threshold <= attention)
```

Then generate until:

```text
incoming_offer_count == min(desired_offer_count, 4)
```

This naturally catches large +20 jumps crossing multiple thresholds at once.

---

# 81. Crossing multiple thresholds

Example:

```text
Attention15 → publish +20 →35
```

Crosses30.

Exactly one additional offer.

Example:

```text
25 → +20 →45
```

Crosses30 and45 if 30 offer somehow missing:
generate both until count3.

No dropped threshold.

---

# 82. Candidate selection deterministic

No RNG.

For each new offer choose first eligible unused candidate from canonical priority list.

This ensures tests and authored pacing.

---

# 83. If all candidates already offered

Do not invent procedural girls.

If candidate list exhausted:

- no new offer;
- attention still rises;
- warning in debug.

Current list7 > max4, so normal MODULE15 cannot exhaust.

---

# 84. Experience gating still respected

At Stage4 story-only path:

```text
Experience = 4
```

all current ordinary candidate girls have required experience <=3.

Still keep eligibility check for correctness.

---

# 85. Media-discovered girl helper

Add to `GirlDiscovery` minimal:

```text
discover_girl_from_media(girl_id) -> bool
```

Rules:

- marks discovered;
- reveals clue0 if not known;
- does NOT run visual `Good Profile` bonus;
- does NOT create retry cooldown;
- does NOT evaluate discovery approach;
- can be called even if previously discovered;
- idempotent.

Then Media ensures contact.

---

# 86. Why use GirlDiscovery helper

Avoid Media duplicating clue/discovery invariants.

But `discover_girl_from_media` remains a narrow explicit source, not generic discovery-source framework.

---

# 87. Contact addition

After media discovery:

```text
GameState.add_girl_contact(girl_id)
```

No relationship points.

No Experience.

No conquest.

---

# 88. Known reaction

Incoming media message is NOT a dating Primary Trait reaction.

Do not call:

```text
record_girl_known_reaction(+1)
```

just because she wrote.

---

# 89. GameDay integration

Media listens to:

```text
GameDay.day_advanced
```

only for:

- Phone/button refresh;
- daily photo publish availability.

It does NOT automatically add Attention every day.

It does NOT automatically generate offers without threshold change in MODULE15.

---

# 90. No Attention decay

GameDay does NOT decrease Attention.

No daily maintenance.

---

# 91. Story Phone handoff progression

Phone Story section Stage4:

## Before photo session

```text
СТАДИЯ 4
Медийность

Следующий шаг:
Фотосессия у Редактора
```

## After photo session, before overload-ready

```text
СТАДИЯ 4
Медийность

Публикуй фотографии.
Входящие предложения растут.
```

## After overload-ready

```text
СТАДИЯ 4
Медийность

Спрос растёт быстрее обычного.
```

Do NOT show Scientist objective yet.

MODULE16 will replace final handoff.

---

# 92. Media article physical cue

After photo session completed:

existing studio can show:

```text
Label3D:
"МАТЕРИАЛ ОПУБЛИКОВАН"
```

or magazine prop.

Not required to spawn Editor actor again.

---

# 93. Editor presence after Stage4

14B StageActorAnchor removed Editor when stage advanced.

MODULE15 does NOT respawn her as a full GirlActor.

PhotoSessionInteractable itself represents the scheduled editorial shoot.

Optional static Editor CharacterActor for presentation is allowed only if tiny and local to photo session, then removed.

Do not fight StoryActor rules.

---

# 94. If photo session needs Editor visual

Allowed:

```text
MediaPhotoSession
→ temporary CharacterActor
appearance_female_magazine_editor
```

at studio marker.

It is presentation-only.

No GirlActor/contact/discovery behavior.

---

# 95. No photo file generation

Do NOT:

- render viewport PNG;
- save screenshots to disk;
- generate actual image files;
- add gallery filesystem.

A `MediaPhotoRecord` is semantic:

```text
shot ID + selected pose + Attention value
```

MODULE23 can later add visual thumbnails.

---

# 96. No actual social network backend

No:

- usernames;
- comments;
- likes;
- follower graph;
- DMs;
- hashtags;
- moderation;
- post editing;
- infinite scroll;
- procedural feed.

Feed is a small ordered list of authored system events.

---

# 97. No incoming proposal scheduler

MODULE15 offers are just incoming initiatives.

Do not add:

```text
date time
appointment slot
conflict
deadline
expiration
calendar
capacity
```

MODULE16.

---

# 98. No automatic relationship pressure

Unread/ignored offers in MODULE15 do NOT:

- lower relationship;
- expire;
- penalize Authority;
- cost Money.

They simply accumulate visibly.

---

# 99. No Story progression from Attention

Attention:

```text
45
100
```

does not advance Stage.

MODULE16 uses overload-ready to trigger its own staged problem.

---

# 100. Test content: candidates exist

At least first four priority girls must exist in production ContentDB:

```text
girl_appearance_flash
girl_public_sculpture
girl_cafe_receipt_notes
girl_gym_chalk
```

14A/14B already provide them.

---

# 101. Test — initial Stage4 state

After Editor completion:

```text
MEDIA_ATTENTION feature = true
photo_session_completed = false
Attention = 0
feed empty
offers empty
```

Phone:

```text
Фотосессия у Редактора
```

---

# 102. Test — photo interactable Stage3

At STAGE3:

```text
not available
```

---

# 103. Test — photo interactable Stage4

At STAGE4 before session:

```text
[E] Фотосессия у Редактора
```

---

# 104. Test — shot requirements

Appearance0:

```text
BASE enabled
STAGED disabled
EDITORIAL disabled
```

Appearance1:

```text
BASE + STAGED enabled
EDITORIAL disabled
```

Appearance2:

```text
all enabled
```

---

# 105. Test — no hidden stat effect

Appearance8 does NOT add extra Attention beyond fixed pose tier values.

It only guarantees options available.

---

# 106. Test — abort session

Choose 1–2 shots, close.

Expected:

```text
completed false
Attention0
feed empty
pose state not committed
```

---

# 107. Test — complete base session

Choose BASE for all.

Expected prepared semantic values:

```text
profile 10
chair 10
cover 10
```

Completion:

```text
photo_session_completed true
Attention15
feed_article_editor appended
```

---

# 108. Test — first incoming at article

Attention15:

```text
incoming count1
```

Candidate:

```text
girl_appearance_flash
```

unless it is invalid/missing; normal production exact candidate should be it.

---

# 109. Test — media contact

If candidate had no contact:

after offer:

```text
discovered true
contact true
clue0 known
no GoodProfile clue1 auto-reveal
relationship unchanged
```

---

# 110. Test — already-contacted candidate

Pre-contact first candidate.

At Attention15:

- same candidate can still receive proactive offer;
- no duplicate contact;
- offer added once.

---

# 111. Test — conquered candidate

Pre-conquer first candidate.

Offer still added.

No XP/reward change.

---

# 112. Test — article does not use daily photo quota

After session same GameDay:

first photo button enabled.

---

# 113. Test — publish base photo

Attention15 → publish +10:

```text
25
```

Photo marked published.

Feed appended once.

No new threshold30 offer yet.

---

# 114. Test — daily limit

Same day second photo:

```text
DAILY_LIMIT
```

No mutation.

---

# 115. Test — next day

`GameDay.advance_day()`.

Unpublished photo available again.

No automatic Attention change.

---

# 116. Test — base progression thresholds

Expected:

```text
15 → offer1
25
35 → offer2 at30
45 → offer3 at45
```

After third base photo:

```text
overload_ready true
```

---

# 117. Test — editorial progression

Article15.

Publish Editorial +20:

```text
35
offer2 exists
```

Next day +20:

```text
55
offer3 exists
overload_ready true
```

---

# 118. Test — threshold jump recovery

Set/produce Attention25 and only one offer.

Add20→45.

System must fill offer2 and offer3.

---

# 119. Test — fourth offer

Reach60.

Exactly fourth offer.

No fifth offer from MODULE15 thresholds.

---

# 120. Test — max Attention

95 +20:

```text
100
```

delta reported actual:

```text
+5
```

No >100.

---

# 121. Test — publish duplicate

Same photo after future day:

```text
ALREADY_PUBLISHED
```

No Attention.

---

# 122. Test — unknown photo

Rejected.

---

# 123. Test — photo before session

Rejected.

---

# 124. Test — photo value derives stored pose

Choose STAGED for chair.

Publish chair:

```text
+15
```

not based on current Appearance at publish time.

---

# 125. Test — Appearance change after session

Photo pose committed at shoot.

Buy Appearance perk later.

Existing photo Attention value unchanged.

---

# 126. Test — incoming priority

First four MODULE15 offers exact order:

```text
girl_appearance_flash
girl_public_sculpture
girl_cafe_receipt_notes
girl_gym_chalk
```

assuming all definitions valid.

Contact/conquered status does not reorder.

---

# 127. Test — required Experience skip

Fixture candidate with required Experience > player:

skip to next eligible.

No invalid contact.

---

# 128. Test — offer read

`mark_media_offer_read`:

- row NEW→READ;
- offer remains;
- no relationship/cooldown mutation.

---

# 129. Test — open incoming contact

Phone open row:

- marks read;
- selects girl in existing journal;
- current Phone modal remains open.

---

# 130. Test — DateVenue sees media contact

New media-contact girl appears in cafe DateVenue if:

```text
normal date cooldown == 0
default_date_location == cafe
```

No special Media Date path.

---

# 131. Test — ignored offer

Advance several days without opening.

Offer remains.

No penalty.

---

# 132. Test — feed order

Persistent order:

```text
article
inbound1
photo1
inbound2
...
```

depending exact threshold sequence.

Phone renders newest-first correctly.

---

# 133. Test — visual15

Attention14:

magazine stand hidden.

15:

visible.

---

# 134. Test — visual30/45/60

Exact threshold toggles.

No collision changes.

---

# 135. Test — reset visuals

Game reset Attention0.

All MediaAttentionVisual objects return hidden on current/reloaded location.

---

# 136. Test — overload-ready once

Cross 45 with 3 offers:

```text
signal once
```

Further Attention:

no duplicate signal.

`is_overload_ready()` remains true.

---

# 137. Test — no Story advance

After Attention100 / 4 offers:

```text
GameState.stage == STAGE_4
```

unless external test changed it.

---

# 138. Test — no Scientist

MODULE15 production catalog still lacks:

```text
girl_scientist
rival_scientist
```

No lab unlock.

---

# 139. Test — no schedule fields

Static/code search Media module:

no:

```text
appointment_time
calendar_slot
deadline
overlap_time
```

---

# 140. Test — no Attention tick

Run frames/time.

Attention unchanged.

Only:

```text
article/photo publication
```

changes it in MODULE15.

---

# 141. Test — GameDay no Attention tick

Advance day without publishing:

Attention unchanged.

---

# 142. Test — no reward contamination

Media Attention/offers do NOT change:

```text
Money
Authority
Experience
Upgrade Points
relationships
conquered
```

except adding contacts/discovery state for new incoming girls.

---

# 143. Test — F5 full integration

Clean route:

```text
PROLOGUE
→ Actress
→ Mine Boss
→ Editor +5
→ STAGE4

→ appearance_space
→ Photo Session
→ Article Attention15 + offer1
→ publish photos over days
→ Attention45+
→ 3+ incoming initiatives
→ overload_ready
```

No debug.

---

# 144. Phone functional integration

After media active, Phone still preserves:

```text
status
story
girl journal
salary
```

Media section is additive.

No regression in Salary Advance button.

---

# 145. World regression

Photo session occurs inside appearance_space.

No World scene unload.

Rival/Dating systems still use current 3D background.

---

# 146. Story handoff regression

Before photo session:

```text
Фотосессия у Редактора
```

After session:

Phone text updates to media progression.

No strict ContentDB error for missing Scientist.

---

# 147. ContentDB changes

MODULE15 does NOT require new Girl/Rival resources.

No new production dating events required.

Media static shot/pose definitions may live in:

```text
game/media/media_content.gd
```

as explicit constants/typed records.

Do not expand general ContentDB solely for 3 shots unless existing conventions clearly make resources simpler.

---

# 148. Suggested media classes

Semantic minimal area:

```text
game/media/
├── media.gd
├── media_types.gd
├── media_photo_session.gd
├── media_photo_record.gd          # only if useful
├── media_publish_result.gd
├── photo_session_interactable.gd
├── media_attention_visual.gd
└── test/
```

Do not force every file if fewer is cleaner.

---

# 149. Media signals

Recommended:

```text
attention_changed(new_value, delta)
photo_session_completed()
photo_published(photo_id, attention_gained)
incoming_offer_added(girl_id)
incoming_offer_read(girl_id)
feed_changed()
overload_ready()
```

No global EventBus.

---

# 150. No manual media initialization button

Media initializes naturally via:

```text
StoryFeature.MEDIA_ATTENTION
+
PhotoSessionInteractable
```

No debug UI in production.

---

# 151. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/07_story_clones_finale.md
docs/gdd/08_locations_ui_content.md
```

Technical note:

```text
Attention = persistent media meter 0..100, non-spendable.
Photo session creates 3 fixed photo records.
One photo can be published per GameDay.
MODULE15 incoming offers are unscheduled initiatives; MODULE16 owns capacity/overlap.
```

---

# 152. GDD clarification

Add implementation note, not product rewrite:

```text
MODULE15 uses 4 authored Attention thresholds (15/30/45/60) to make first incoming initiatives deterministic.
At 45 Attention + 3 offers Media becomes overload-ready.
```

---

# 153. What MODULE 15 DOES NOT implement

Do NOT implement:

- full social network;
- follower counts;
- likes/comments;
- procedural posts;
- real screenshot/photo files;
- schedule/calendar;
- simultaneous appointment slots;
- offer expiration;
- penalties for ignored offers;
- date capacity;
- backlog pressure;
- Scientist;
- Scientist rival;
- Laboratory story;
- cloning;
- production;
- Stage transition beyond STAGE4;
- automatic Experience;
- Attention decay;
- real-time Attention;
- final Media art/audio.

---

# 154. Definition of Done

MODULE15 complete only if:

- [ ] Media autoload exists;
- [ ] Attention persistent `0..100`;
- [ ] Attention non-spendable/no decay;
- [ ] Stage4 alone starts Attention0;
- [ ] existing photo-session marker used;
- [ ] PhotoSessionInteractable exists;
- [ ] photo session cannot run before MEDIA_ATTENTION;
- [ ] photo session exactly once;
- [ ] exactly 3 fixed shots;
- [ ] each shot has BASE/STAGED/EDITORIAL;
- [ ] requirements 0/1/2 Appearance exact;
- [ ] publication values 10/15/20 exact;
- [ ] session abort commits nothing;
- [ ] session completion auto-publishes Editor article;
- [ ] article grants exactly15 Attention;
- [ ] article creates first threshold incoming initiative;
- [ ] 3 prepared photos stored semantically;
- [ ] no PNG/screenshots generated;
- [ ] each photo publishable once;
- [ ] max1 photo publication per GameDay;
- [ ] article does not consume daily photo quota;
- [ ] Attention threshold offers exact15/30/45/60;
- [ ] threshold generation deterministic/no RNG;
- [ ] threshold jumps cannot lose offers;
- [ ] candidate priority exact;
- [ ] existing contact/conquered girls can still send initiative;
- [ ] media-discovered girls get contact + clue0;
- [ ] Good Profile not applied to media discovery;
- [ ] incoming offers have NEW/READ only;
- [ ] no accept/decline/calendar in MODULE15;
- [ ] DateVenue automatically sees new contacts;
- [ ] Phone MEDIA section exists;
- [ ] Phone shows Attention;
- [ ] Phone shows 3 photo cards;
- [ ] Phone publishes photos;
- [ ] Phone shows incoming offers;
- [ ] Phone shows feed;
- [ ] physical city/studio fame visuals appear at15/30/45/60;
- [ ] overload-ready exact Attention>=45 + offers>=3;
- [ ] overload-ready signal exactly once;
- [ ] Story remains STAGE4;
- [ ] Scientist resources still absent;
- [ ] no Laboratory unlock;
- [ ] no Dating Overload scheduling logic;
- [ ] full clean F5 route reaches overload-ready;
- [ ] MODULE02–14 regressions PASS;
- [ ] MODULE16 not implemented ahead.

---

# 155. Recommended Cursor order

## Step 1 — audit

Check actual:

```text
GameState
GameDay
Story
PhoneJournal
GirlDiscovery
DateVenue
appearance_space
story_point_editor_photo_session
current ContentDB ordinary girls
```

## Step 2 — GameState media state

Implement persistent fields/reset/APIs first.

## Step 3 — Media core

Attention, thresholds, deterministic incoming candidates, feed IDs.

Unit-test without UI.

## Step 4 — media discovery helper

Add narrow `GirlDiscovery.discover_girl_from_media`.

## Step 5 — PhotoSession

Three-shot deterministic modal.

Test abort/commit/Appearance options.

## Step 6 — physical interactable

Attach to existing photo marker.

## Step 7 — Phone Media section

Attention/photos/incoming/feed.

## Step 8 — publication/day limit

Integrate GameDay.

## Step 9 — physical fame visuals

Threshold visuals only.

## Step 10 — Stage4 story handoff text

Before/after session/overload-ready.

## Step 11 — full F5

Editor completion → photo → posts → offers → overload-ready.

## Step 12 — regressions/docs

Everything.

---

# 156. Cursor final report

## Media architecture

Explain:

```text
Media
GameState media state
PhotoSession
Phone
MediaAttentionVisual
```

## Attention

Confirm:

```text
0..100
article +15
photos +10/+15/+20
no RNG
no decay
```

## Photo session

Confirm exact 3 shots and Appearance gates.

## Publication

Confirm:

```text
3 limited photos
one per GameDay
each once
```

## Incoming initiatives

Show thresholds:

```text
15 / 30 / 45 / 60
```

and candidate priority.

Confirm contact/discovery handling.

## Overload handoff

Confirm:

```text
Attention >=45
offers >=3
→ overload_ready
```

but:

```text
Stage stays4
no Scientist
no calendar
```

## Production integration

Clean F5 route.

## Validation

MODULE15 tests + all regressions.

## Files changed

Main paths.

## Commit

SHA.

Then STOP. Do not start MODULE16.
