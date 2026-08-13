# MODULE 22 — UI / UX INTEGRATION

**Проект:** Date Factory  
**Модуль:** 22 — UI / UX Integration  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** единый финальный UI/UX-проход по уже полностью работающей игре. Создать постоянный HUD, привести PhoneJournal к понятной вкладочной структуре, сделать полноценный экран прокачки, унифицировать dating/minigame/terminal UI, stage notifications, tutorial prompts и readability/accessibility.  
**Предыдущий модуль:** MODULE 21 — Final Date Sequence  
**Следующий модуль:** MODULE 23 — Audio / Animation / Feedback  
**Product truth:** `docs/gdd/08_locations_ui_content.md`, раздел 47  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 22

---

# 0. КРИТИЧЕСКАЯ ГРАНИЦА

MODULE 22:

```text
НЕ добавляет gameplay mechanics
НЕ меняет balance
НЕ меняет progression rules
НЕ меняет Story conditions
НЕ меняет economy formulas
НЕ добавляет content girls/rivals/events
```

Он только:

```text
показывает уже существующее состояние
делает уже существующие действия понятнее
унифицирует presentation
убирает функциональный prototype UI
```

Если UI требует gameplay mutation, которой раньше не было:

```text
STOP
```

и использовать существующий API.

---

# 1. Главный UI principle

GDD:

Игроку постоянно достаточно видеть:

```text
Деньги
Авторитет
Покоренных сердец
Баллы прокачки
```

Поздние производственные числа показываются:

```text
в Phone
в Clone Terminal
в Global Terminal
```

НЕ превращать весь экран в incremental dashboard.

---

# 2. Visual language

Prototype target:

```text
чистый
плоский
комедийно-бюрократический
немного "официальный интерфейс системы"
```

Не делать:

```text
cyberpunk neon
fantasy parchment
dating-app pink overload
AAA hologram soup
```

Recommended:

- тёмные полупрозрачные панели;
- светлый текст;
- один muted accent;
- второй warning/accent для недоступного;
- крупная типографика;
- заметные цифры;
- минимум декоративных рамок.

MODULE23 потом добавит animation/audio feedback.

---

# 3. Единый Theme

Создать:

```text
ui/theme/date_factory_theme.tres
```

и helper/resources при необходимости.

Применить к:

```text
HUD
Phone
Progression
DatingUI
FinalDateUI
Clone Terminal
Global Terminal
story/stage notifications
```

Мини-игры могут сохранить специализированную геометрию, но должны наследовать:

```text
font sizes
panel background
button states
text colors
```

---

# 4. Не переписывать runtime UI в framework

Не создавать:

```text
UIManager
ScreenManager
WidgetFramework
MVVM layer
generic modal engine
global reactive store
```

Допустим один presentation root:

```text
GameHUD
```

Остальные уже существующие UI остаются владельцами своих экранов.

---

# 5. Permanent `GameHUD`

Создать:

```text
ui/hud/game_hud.tscn
ui/hud/game_hud.gd
```

`CanvasLayer`.

HUD должен жить persistent вместе с WorldHost / Player.

Preferred:

```text
World создаёт HUD рядом с persistent PhoneJournal
```

Не внутри location scene.

---

# 6. HUD — exact four resources

В левом верхнем углу:

```text
$ 120
АВТОРИТЕТ 7
ПОКОРЕННЫХ СЕРДЕЦ 5
БАЛЛЫ 2
```

Не показывать:

- relationship;
- Attention;
- GameDay;
- clone totals;
- stage;
- XP progress bars.

---

# 7. Money formatting

Early:

```text
$ 0
$ 120
$ 9 340
```

Late compact:

```text
$ 12.4K
$ 2.35M
$ 1.08B
```

Use compact formatting only at:

```text
>= 10,000
```

Exact helper:

```text
9,999 → 9 999
10,000 → 10K
12,400 → 12.4K
1,250,000 → 1.25M
```

Max2 meaningful decimal digits.

This formatter should be reusable by:

```text
HUD
Phone
Clone Terminal
Global Terminal
ending summary
```

---

# 8. Other integer formatting

Clone count may use compact formatting:

```text
12.4K
2.3M
```

But:

```text
Authority
Experience
Upgrade Points
relationship
```

remain exact integers.

---

# 9. HUD updates

Event-driven:

```text
money_changed
authority_changed
experience_changed
upgrade_points_changed
state_reset
```

No `_process()`.

---

# 10. HUD visibility

Visible during:

```text
GAMEPLAY
```

Hidden during:

```text
MODAL_UI
MINIGAME
PAUSED
```

Reason:

modal/minigame UI already owns screen attention.

When returning GAMEPLAY:

```text
HUD visible
```

Do not infer visibility from mouse mode.

Use actual Player control mode signal if available.

If Player has no semantic signal, add a narrow:

```text
control_mode_changed(mode)
```

signal to PlayerController.

Do NOT make HUD poll.

---

# 11. Interaction prompt pass

Existing world E-interactions must display one consistent prompt position:

```text
bottom-center
```

Format:

```text
[E] Открыть телефон
[E] Вызвать
[E] Перейти: Кафе
```

Unavailable reason:

do NOT show permanently.

When player aims/interacts and action unavailable, existing interactable feedback may show:

```text
Требуется Авторитет 4
Локация пока недоступна
Сегодня больше физически не успеть
```

No giant tutorial toast every frame.

---

# 12. Crosshair

Add simple persistent FPS crosshair:

```text
small center dot/cross
```

Visible only GAMEPLAY.

Do not animate in MODULE22.

MODULE23 may add hit/reaction feedback.

---

# 13. HUD notification rail

Create one small transient text rail:

```text
top-center
```

For semantic state notifications only.

Examples:

```text
Авторитет +2
Покоренных сердец +1
Балл прокачки +1
Новая стадия: Медийность
Лаборатория открыта
Охват Земли: 50%
```

Not every Money tick.

---

# 14. Notification queue

Small local queue:

```text
max 3 pending
display 2.2 seconds each
```

No `_process()` needed; use Timer.

If multiple atomic rewards:

prefer group:

```text
Покоренных сердец +1
Балл прокачки +1
```

as one card if emitted same action.

---

# 15. No passive Money spam

Do NOT notify:

```text
+$1
+$1
+$1
```

from CloneIncremental.

HUD Money number is enough.

Salary claim / major purchase can still show notification.

---

# 16. Stage notification

On `GameState.stage_changed`:

show large one-shot card:

```text
СТАДИЯ 4
МЕДИЙНОСТЬ
```

or stage display name from Story definition.

Duration:

```text
3.0 sec
```

Do not pause game.

For FINALE:

```text
ФИНАЛ
```

---

# 17. Feature unlock notification

When Story feature unlocks:

examples:

```text
ОТКРЫТО: ЗАРПЛАТНАЯ ШАХТА
ОТКРЫТО: ЛАБОРАТОРИЯ
ОТКРЫТО: МИРОВОЕ РАСШИРЕНИЕ
```

Do not notify internal-only:

```text
PUBLIC_CITY_ACCESS
```

unless useful copy says:

```text
Открыт новый район города
```

---

# 18. Phone shell redesign

Current `PhoneJournal` already owns all functionality.

Do NOT replace its data logic.

Refactor presentation into tabs:

```text
СТАТУС
СЮЖЕТ
ДЕВУШКИ
МЕДИА
КЛОНЫ
```

Salary content belongs under:

```text
СТАТУС
```

Overload belongs under:

```text
МЕДИА
```

This keeps five stable tabs.

---

# 19. Phone tab visibility

Always visible:

```text
СТАТУС
СЮЖЕТ
ДЕВУШКИ
```

MEDIA tab appears only after:

```text
StoryFeature.MEDIA_ATTENTION
```

CLONES appears only after:

```text
total_clones >=1
```

Do not show locked empty tabs.

---

# 20. Phone top bar

Always show compact:

```text
День N
$ Money
Авторитет X
Покоренных сердец X
Баллы X
```

Day may exist here even though it is not permanent HUD.

Close:

```text
[ESC] / [X]
```

Use existing modal behavior.

---

# 21. Phone STATUS tab

Contains:

```text
Мышца X
Внешность X
Капитал X
Аура X
```

and current economic state:

Before Salary Mine:

nothing extra.

After Salary Mine:

```text
Зарплата
Уровень: X
Доступно: $X
```

Late:

```text
Денег/мин: X
Свиданий/мин: X
```

No duplicate full clone dashboard here.

---

# 22. Phone STORY tab

Only current objective/status.

No historical quest log.

Layout:

```text
CURRENT STAGE HEADER
1–4 lines current situation
Следующий шаг
```

Use existing `_stage*story_text()` data/copy.

Do NOT expose internal enum/feature names.

---

# 23. Phone GIRLS tab

Two-column desktop layout:

Left:

```text
scroll list
```

Right:

```text
girl detail
```

List row:

```text
Имя
relationship or contact status
```

Examples:

```text
Соседка          +5
Девушка с ноутбуком  Номер получен
Последняя        Сигнал
```

---

# 24. Girl list sorting

Exact order:

1. current story girl if present;
2. contacted girls;
3. seen/discovered but no contact;
4. conquered girls may remain in their story/contact order, but do not hide them.

Within group:

```text
production catalog order
```

No alphabetical reordering required.

Final target special UI preserved.

---

# 25. Girl detail

Show:

```text
Name
Relationship: +N / 5
Contact / cooldown state

Наблюдения
Primary trait info if revealed
Secondary trait info if revealed
Known reactions
```

Known reaction format:

```text
[+1] действие
[0] действие
[-1] действие
```

Use clear signs.

Do not use unexplained colors alone.

---

# 26. Phone MEDIA tab

Subsections in one scroll:

```text
ВНИМАНИЕ
ФОТОГРАФИИ
ВХОДЯЩИЕ
ПЕРЕГРУЗКА
ЛЕНТА
```

Hide subsections not yet active.

---

# 27. Attention visualization

Show:

```text
Внимание
35 / 100
```

with simple horizontal bar.

No hidden percentage.

Threshold markers are optional but recommended:

```text
15
30
45
60
```

Do NOT label internal mechanic names.

---

# 28. Photos

Each photo card:

```text
Профиль
+10 внимания
[Опубликовать]
```

or:

```text
Опубликовано
```

Daily limit feedback:

```text
Сегодня публикация уже была.
```

Do not show enum/error IDs.

---

# 29. Incoming media offers

Rows:

```text
NEW  Девушка со вспышкой
READ Девушка у скульптуры
```

Button:

```text
[Открыть]
```

No accept/decline controls.

---

# 30. Overload UI

Show:

```text
Личная пропускная способность:
0 / 1 сегодня

Невыполненный спрос:
5
```

Backlog row:

```text
ПРОСРОЧЕНО
Вчера · 19:00
Девушка со вспышкой
```

Today:

```text
СЕГОДНЯ
20:00
...
```

No calendar grid.

---

# 31. Feed Boost

Button:

```text
[Поднять волну]
```

Supporting copy:

```text
+5 внимания
Следующий день: +1 входящий запрос
```

Disabled reason displayed directly.

---

# 32. Phone CLONES tab

Read-only:

```text
Всего
Свободно
Работают
На свиданиях

Денег/мин
Свиданий/мин
```

At STAGE6:

also:

```text
Охват Земли XX / 100
```

No assignment buttons.

Explicit footer:

```text
Управление клонами — через терминал лаборатории.
```

At Stage6:

```text
Глобальные улучшения — в производственной зоне.
```

---

# 33. Progression UI

Currently progression logic exists, but MODULE22 must provide one coherent perk tree screen.

Create:

```text
ui/progression/progression_ui.tscn
ui/progression/progression_ui.gd
```

---

# 34. How progression UI opens

Use existing characteristic/progression physical interactables if present.

Do NOT add remote Phone buying.

Each physical progression station may open same UI with:

```text
selected characteristic
```

Examples:

```text
Gym → MUSCLE tab
Appearance Space → APPEARANCE
Capital station/context → CAPITAL
Aura station/context → AURA
```

If current project uses another existing entry seam:

preserve it.

---

# 35. Progression screen structure

Top:

```text
БАЛЛЫ ПРОКАЧКИ: N
```

Tabs:

```text
МЫШЦА
ВНЕШНОСТЬ
КАПИТАЛ
АУРА
```

Each tab:

```text
current stat
8 perk nodes vertically or simple 2-column chain
```

No enormous RPG constellation.

---

# 36. Perk node exact info

Each node displays:

```text
Название
Стоимость: 1 / 3 / 9 / ...
status
```

Statuses:

```text
КУПЛЕНО
ДОСТУПНО
НУЖЕН ПРЕДЫДУЩИЙ ПЕРК
НЕ ХВАТАЕТ БАЛЛОВ
```

Description shown in detail panel / hover/focus.

---

# 37. Perk effect copy

Descriptions must explain real effect in product language.

No raw IDs:

```text
perk_aura_presence_registered
```

No technical contract names.

If current PerkDefinition description is insufficient, MODULE22 may add:

```text
ui_description
```

ONLY if needed as static content metadata.

Do not change perk mechanics.

---

# 38. Characteristic stat readability

Header:

```text
АУРА 3 / 8
```

and:

```text
Каждый купленный перк этой ветки = +1 Аура
```

This is enough.

No hidden XP bars.

---

# 39. Purchase confirmation

Single click:

```text
[Купить за 9]
```

No secondary confirmation modal.

Purchase result immediately:

- node changes state;
- stat header increments;
- points update;
- small HUD notification.

---

# 40. Dating UI redesign

Keep existing `DatingCore` behavior.

Layout:

Top:

```text
Girl name
phase label
Relationship current if already known
```

Center:

```text
event title
setup text
```

Bottom:

```text
choice cards/buttons
```

Reaction appears as dedicated clear line.

---

# 41. Dating action card

Each action shows before click:

```text
Action text

[Мышца 2]         if requirement
$20               if cost
```

If unavailable:

```text
disabled
Требуется Мышца 2
```

If perk makes free:

```text
Бесплатно — Представительские расходы
```

Requirement must never be hidden in tooltip only.

---

# 42. Dating reaction

After selection:

large:

```text
+1
```

or:

```text
0
```

or:

```text
-1
```

plus authored `result_text`.

Do not show only sentence without score.

Hold until player explicitly continues OR existing phase automatically waits enough for reading.

Preferred:

```text
[Далее]
```

for accessibility/readability.

Do not change scoring.

---

# 43. Dating result screen

Exact hierarchy:

```text
ИТОГ СВИДАНИЯ

Свидание: +4
Вечер: +1
Итого: +5

Отношения:
0 → +5

Покоренных сердец +1
Балл прокачки +1
```

Only show reward rows when actually gained.

---

# 44. Greeting diagnostic

Clearly label:

```text
ПРИВЕТСТВИЕ
Не влияет на отношения
```

This prevents player interpreting greeting as hidden score.

---

# 45. Minigame shared shell

Do NOT rewrite headless minigames.

Presentation pass for all four:

```text
SLAP
DANCE
SIGMA
MONEY
```

Shared principles:

- title top-center;
- player vs rival score consistently placed;
- controls always visible;
- perk active/special actions visible;
- result WIN/LOSS obvious;
- technical English feedback translated where feasible.

---

# 46. SLAP UI

Translate prototype:

```text
MISS → МИМО
HIT → ПОПАЛ
PERFECT → ИДЕАЛЬНО
BLOCK → БЛОК
PERFECT BLOCK → ИДЕАЛЬНЫЙ БЛОК
```

Control:

```text
SPACE — удар / блок
```

Perk controls:

```text
Q — ...
R — ...
```

Keep track mechanics unchanged.

---

# 47. DANCE UI

Must always show:

```text
current phase:
СМОТРИ
ПОВТОРИ
ТВОЙ ХОД
```

Input legend:

```text
W A S D
```

Streak/status readable.

Do not expose timing milliseconds.

---

# 48. SIGMA UI

Show:

```text
СОХРАНЯЙ ПАРАМЕТР В ЗОНЕ
```

Current gauge + valid zone.

Mouse hint:

```text
Мышь — удерживать давление
```

Perk controls Q/R/etc as existing.

No hidden success meter.

---

# 49. MONEY UI

Show clearly:

```text
Твои деньги: $X
Текущая ставка: $Y
```

Before action player must understand that real Money is spent.

Buttons/controls:

```text
ПОДНЯТЬ
ОТСТУПИТЬ / equivalent existing action
```

Do not disguise spend.

---

# 50. Minigame result overlay

Before runner closes:

```text
ПОБЕДА
```

or:

```text
ПОРАЖЕНИЕ
```

with one concise reason/score.

Hold:

```text
0.8–1.2 sec
```

Then emit `match_finished` so `RivalCompetitionRunner` closes the overlay and restores `GAMEPLAY`. Do not leave the fight window open after the match has ended. ESC during the result overlay (match already ended) skips remaining hold and closes. Live fight: ESC does not abort.

MODULE23 may add sound/VFX.

Final exhibition rivals use same result visual but no Authority line.

---

# 51. Rival pre-competition UI

When player chooses among allowed competitions:

show each:

```text
ПОЩЁЧИНА
Мышца: Ты 3 / Самец 4
```

```text
ТАНЕЦ
Внешность: Ты 2 / Самец 4
```

Locked competition:

```text
ДЕНЬГИ
Нужен перк «Платёжное намерение»
```

No hidden availability.

---

# 52. Authority consequences

Before normal rival competition:

show:

```text
Победа: Авторитет +N
Поражение: Авторитет -1
```

If Heroic Defeat active/possible:

do NOT promise `-1`.

Show:

```text
Поражение: обычно -1
```

or exact currently derived result if API exposes it.

Final exhibition:

```text
Авторитет не меняется
```

---

# 53. Clone Terminal UI pass

Preserve MODULE18 functionality.

Improve hierarchy:

```text
КЛОН-ФАБРИКА
TOTAL / FREE

WORK
count
Money/min
[-] [+] [Все свободные]

DATING
count
Dates/min
[-] [+] [Все свободные]

NEXT CLONE
X.X sec

UPGRADES
...
```

---

# 54. Clone upgrade cards

Each:

```text
Линия копирования
Уровень 2 / 5
20 сек → 15 сек
[Улучшить — $270]
```

Work:

```text
40 → 50 $/мин за клона
```

Dating:

```text
1.00 → 1.25 свиданий/мин за клона
```

At MAX:

```text
MAX
```

---

# 55. Global Terminal UI pass

Same visual language, larger numbers.

Show:

```text
ОХВАТ ЗЕМЛИ
XX / 100
```

bar.

Global upgrade card:

```text
Международная сеть свиданий
×4 → ×8
[Улучшить — $25K]
```

No raw level formula.

---

# 56. Late-number formatting

Terminal counts/rates:

```text
12 400 clones → 12.4K
28 000 $/min → 28K / мин
80 dates/min → 80 / мин
```

Hover/detail is not required to show exact large integer.

Gameplay math remains exact.

---

# 57. FinalDateUI pass

Keep all MODULE21 behavior.

Apply Theme.

Requirements visible:

```text
[Аура 2] Земля закончилась раньше намерения.
```

Locked:

```text
[Аура 2] ...     Требуется Аура 2
```

Neutral visually separate:

```text
[Нейтрально]
```

---

# 58. Final fail UI

Rival loss:

```text
СВИДАНИЕ ПРЕРВАНО
...
[Повторить свидание целиком]
[Вернуться]
```

Connection fail analogous.

Emphasize:

```text
Попытка не засчитана
```

No "Game Over".

---

# 59. Ending UI pass

Functional ending from MODULE21 remains.

Apply release-candidate layout:

```text
DATE FACTORY

ЦЕЛЬ ДОСТИГНУТА

Покоренных сердец
Авторитет
Клоны
Охват Земли

[Продолжить]
```

No full credits yet unless TECH_PLAN later requests.

---

# 60. Tutorial prompt system

Create lightweight:

```text
ui/tutorial/tutorial_prompt.gd
```

or local HUD component.

No tutorial manager autoload.

Tutorial prompts are presentation flags, not gameplay progression.

---

# 61. Tutorial persistence in MODULE22

Because full Save/Load is MODULE24:

tutorial seen flags can live runtime-only now.

Do NOT add GameState fields solely to persist tutorials yet.

MODULE24 may decide persistence.

---

# 62. Exact tutorial prompts

Show once per runtime when first relevant.

## First movement

```text
WASD — движение
Мышь — обзор
E — взаимодействие
```

## First phone

```text
Телефон хранит сюжет, девушек и текущие системы.
```

## First rival

```text
Самец выбирает или предлагает состязание.
Сравни характеристики до начала.
```

## First date

```text
Требования действий видны заранее.
После выбора реакция всегда показывает +1 / 0 / -1.
```

## First Upgrade Point

```text
Каждый прирост «Покоренных сердец» даёт 1 Балл прокачки.
```

## First clone

```text
Терминал лаборатории распределяет клонов между Работой и Свиданиями.
```

## First Stage6

```text
Охват Земли растёт от новых автоматических свиданий.
```

No more tutorial stack.

---

# 63. Tutorial timing

Never interrupt:

```text
MINIGAME
modal choice
FinalDate dialogue
```

Queue until GAMEPLAY.

Display:

```text
4–6 seconds
```

player may dismiss.

---

# 64. Accessibility — font scale

Add UI setting-ready runtime option:

```text
ui_scale
```

For MODULE22 implement local UI scale presets:

```text
100%
125%
150%
```

Do NOT persist yet; MODULE24 Settings will persist it.

May live in:

```text
UISettingsRuntime
```

only if tiny and justified.

Preferred simpler:

theme/root scale helper.

---

# 65. Minimum font sizes at 1080p

Body:

```text
18 px minimum
```

Buttons:

```text
18
```

Headers:

```text
24–32
```

HUD resource numbers:

```text
20+
```

No 12px prototype labels.

---

# 66. UI safe area

All main UI must fit:

```text
1280×720
1920×1080
2560×1440
```

Test at these three.

No content outside viewport.

Use Containers, not absolute pixel layout for major screens.

---

# 67. Mouse/keyboard

Every modal screen:

- clickable with mouse;
- keyboard navigation via default Godot focus;
- ESC closes only if the gameplay system allows abort/close.

Do not require controller/gamepad pass in MODULE22.

---

# 68. Focus behavior

When modal opens:

```text
first meaningful enabled button grabs focus
```

When rows rebuild:

avoid losing focus to null where practical.

No custom navigation graph needed unless Godot default fails.

---

# 69. Color accessibility

Do NOT rely only on:

```text
green
gray
red
```

Always combine color with symbols/text:

```text
+1
0
-1
КУПЛЕНО
НЕДОСТУПНО
NEW
READ
```

---

# 70. Disabled readability

Disabled button text must remain readable.

No opacity below roughly:

```text
55%
```

Reason printed beneath/in label.

---

# 71. No hidden percentage mechanics

Do not introduce:

```text
72% chance
success probability
relationship %
```

where gameplay does not actually use them.

Display actual deterministic stats.

---

# 72. No fake clocks

Overload retains authored:

```text
19:00
20:00
```

Do not create a current time-of-day HUD.

GameDay is integer only.

---

# 73. Central number formatter

Create:

```text
ui/ui_number_format.gd
```

static helper.

Responsibilities only:

```text
integer grouping
compact K/M/B
rate formatting
signed relationship/reaction formatting
```

No localization framework.

---

# 74. Shared UI text helpers

Can create small:

```text
ui/ui_labels.gd
```

ONLY if repeated formatting benefits.

Do not move domain rules there.

---

# 75. Current functional copy preservation

Do not rewrite all authored jokes in MODULE22.

Only:

- normalize capitalization;
- fix technical/English leftovers;
- improve labels;
- expose requirements/results.

MODULE25 does broad content completion/copy pass.

---

# 76. Technical IDs forbidden in player UI

Search production UI for:

```text
perk_
girl_
rival_
STAGE_
MEDIA_ATTENTION
BODY_CAPACITY_USED
LOCKED_STORY
```

None should be visible to player.

Debug logs may keep them.

---

# 77. English prototype leftovers

Translate obvious gameplay feedback:

```text
MISS
HIT
PERFECT
BLOCK
MAX LEVEL
LOCKED
```

unless intentionally branded.

Identifiers/code remain English.

---

# 78. HUD lifecycle

World reset/travel must NOT duplicate HUD.

At any time:

```text
exactly one GameHUD
exactly one PhoneJournal persistent instance
```

No per-location HUD creation.

---

# 79. Modal stacking invariant

At most one of:

```text
Phone
Progression UI
DatingUI
CloneTerminalUI
GlobalTerminalUI
FinalDateUI
Minigame
```

owns player modal/minigame focus.

Do not create generic stack.

Each existing system must refuse/open safely according to Player control state.

---

# 80. Phone opening safety

Physical phone interaction allowed only GAMEPLAY.

Cannot open:

```text
during date
during rival minigame
during final date modal
```

Existing control mode already supports this; preserve.

---

# 81. Escape behavior

Exact UX:

Phone / Progression / Terminals / other dismissable overlays (fridge, wardrobe, rival choose, confirmation):

```text
ESC → same as close/back → GAMEPLAY
```

Player in `MODAL_UI` / `DIALOGUE` must not consume ESC before those overlays.

Dating active choice:

```text
ESC does NOT abort date
```

Date result screen (`Закрыть` visible):

```text
ESC → close finished date → GAMEPLAY
```

FinalDate active:

```text
ESC does NOT silently abort;
use explicit Вернуться only on failure/allowed state
```

Minigame live:

```text
ESC no gameplay abort
```

Minigame already ended (result overlay):

```text
ESC → skip hold → match_finished → close
```

Pause menu is not part of MODULE22 unless existing project already has one.

---

# 82. HUD + stage debug test

Production should no longer require watching console/logs to know:

- money changed;
- authority changed;
- XP gained;
- UP gained;
- stage changed;
- location opened.

All major player-facing outcomes visible.

---

# 83. Feedback audit matrix

Cursor must audit each system and record UI coverage:

```text
GirlDiscovery
RivalEncounter
Slap
Dance
Sigma
Money
Dating
Relationships
Story
Salary
Media
DatingOverload
FirstClone
CloneIncremental
LateGameExpansion
FinalDate
```

For each answer:

```text
What can player do?
What requirement can block it?
What did action change?
Where does UI show that?
```

No gameplay modification.

---

# 84. GirlDiscovery UI pass

Existing approach selection should clearly show:

```text
approach text
requirement
availability
```

Success:

```text
НОМЕР ПОЛУЧЕН
```

Failure:

```text
НЕ СРАБОТАЛО
Повтор: через N дн.
```

Story prerequisite:

show blocker, not failure.

No automatic relationship score.

---

# 85. First Clone calibration UI

Apply Theme/readability.

Each pass:

```text
СОВПАДЕНИЕ ТЕЛА
СОВПАДЕНИЕ ЛИЦА
СОВПАДЕНИЕ УВЕРЕННОСТИ
```

Keep scanner mechanism.

Miss:

```text
КАЛИБРОВКА НЕ ПРИНЯТА
```

Do not show quality score.

---

# 86. Media Photo Session UI

Apply Theme.

Each pose option clearly shows:

```text
[Внешность 0/1/2]
```

and only available ones enabled.

Do NOT show future Attention reward before selection unless current design already does.

Prepared-photo publish UI later shows actual +Attention.

---

# 87. Salary UI

Phone STATUS:

show:

```text
Уровень зарплаты
Текущая сумма
```

Salary station world prompt:

```text
[E] Получить зарплату — $X
```

if API can provide amount without mutation.

If claim requires 1.5s hold/process, UI shows progress plainly.

No hidden pending amount.

---

# 88. World transition prompt

Use location display names from ContentDB.

Example:

```text
[E] Перейти: Кафе
```

Locked interaction feedback:

```text
Пока недоступно
```

with known story reason only if existing Story exposes meaningful reason.

Do not leak:

```text
requires stage >= 3
```

---

# 89. Clone production feedback

Do NOT show every clone as HUD notification late-game.

When total low:

optional:

```text
Клон готов
```

only first few / while player in lab.

MODULE19 already has physical feedback.

HUD should stay quiet.

---

# 90. Late Game Reach notification

Milestones only:

```text
Охват Земли: 25%
50%
75%
100%
```

Not every +2.

---

# 91. Testing — HUD resources

Modify each resource.

Expected HUD immediate exact refresh.

No frame polling.

---

# 92. Testing — HUD hidden in modal/minigame

Open:

```text
Phone
Dating
Slap
Clone Terminal
```

HUD hides.

Close:

returns.

---

# 93. Testing — Phone tabs visibility

PROLOGUE:

```text
STATUS/STORY/GIRLS
```

Stage4 Media:

```text
+MEDIA
```

First clone:

```text
+CLONES
```

No empty tabs earlier.

---

# 94. Testing — phone functionality regression

All existing MODULE15–21 buttons/actions still work:

- publish photo;
- open incoming;
- Feed Boost;
- salary claim actions if currently phone-driven;
- girl detail;
- final state.

Only layout changed.

---

# 95. Testing — perk tree

All 32 perks visible in correct branch/order.

Purchase costs exactly existing:

```text
1/3/9/27/81...
```

Prerequisites unchanged.

Stats increment exactly once.

---

# 96. Testing — dating requirements

Locked action displays actual requirement before click.

No action that core says unavailable is shown enabled.

---

# 97. Testing — dating result

Reaction each action visible:

```text
+1/0/-1
```

Final:
date + secondary = shown correctly.

Relationship before/after correct.

XP/UP only if gained.

---

# 98. Testing — minigame normal flow

All 4 minigames:

- readable at 720p;
- controls visible;
- result visible;
- runner completion unchanged.

---

# 99. Testing — final exhibition

Uses same polished Slap/Dance presentation.

No normal Authority result UI appears.

---

# 100. Testing — terminal formulas

UI values are read-model values, not duplicated calculations where service already exposes snapshot.

Clone Terminal:

compare screen vs `CloneIncrementalStatus`.

Global Terminal:

compare vs `LateGameStatus`.

---

# 101. Testing — number formatter

Exact regression examples:

```text
0 → "0"
9999 → "9 999"
10000 → "10K"
12400 → "12.4K"
1250000 → "1.25M"
1000000000 → "1B"
```

Signed:

```text
1 → "+1"
0 → "0"
-1 → "-1"
```

---

# 102. Testing — resolutions

Manual screenshot/visual checks at:

```text
1280×720
1920×1080
2560×1440
```

For:

- HUD;
- Phone every tab;
- Progression;
- Dating;
- each minigame;
- Clone Terminal;
- Global Terminal;
- FinalDate;
- Ending.

No clipping/overlap.

---

# 103. Testing — 150% scale

At UI scale150:

- Phone remains usable with scrolling;
- buttons remain visible;
- no essential content inaccessible;
- minigame track still fits 1280×720.

If minigame track too large:

responsive width:

```text
min(available_width - margins, designed_width)
```

Do not scale offscreen.

---

# 104. Testing — no gameplay changes

Run all MODULE02–21 headless tests unchanged.

Any failed gameplay regression due UI refactor is blocker.

---

# 105. Full F5 UX acceptance

Play clean route without console/debug.

At every major step the player must be able to answer from UI alone:

```text
What do I have?
What am I trying to do?
Why is this action unavailable?
What did my last action do?
Where should I go next?
```

From:

```text
PROLOGUE
→ ...
→ FINALE
→ ending
```

---

# 106. No new systems after Milestone F

TECH_PLAN explicitly says after MODULE21:

```text
no major new mechanics
```

MODULE22 must not add:

- quests;
- minimap;
- inventory;
- achievements;
- codex;
- dialogue system;
- map screen;
- notification economy;
- new progression;
- new currencies.

---

# 107. Documentation

Update:

```text
docs/PROJECT_STRUCTURE.md
docs/TECHNICAL_DECISIONS.md
docs/gdd/08_locations_ui_content.md
```

Add:

```text
docs/ui/UI_ARCHITECTURE.md
```

This file should document:

- persistent HUD ownership;
- modal ownership rules;
- five Phone tabs;
- Theme;
- number formatting;
- progression screen;
- notification rules;
- accessibility scale;
- gameplay remains source of truth.

---

# 108. Suggested project additions

```text
ui/
├── theme/
│   └── date_factory_theme.tres
├── hud/
│   ├── game_hud.tscn
│   └── game_hud.gd
├── progression/
│   ├── progression_ui.tscn
│   └── progression_ui.gd
├── tutorial/
│   └── tutorial_prompt.gd
├── ui_number_format.gd
├── phone/
└── dating/
```

Do not move gameplay-owned FinalDate/terminal scripts solely for folder purity.

---

# 109. Definition of Done

MODULE22 complete only if:

- [ ] one shared Date Factory Theme exists;
- [ ] permanent GameHUD exists;
- [ ] HUD shows exactly Money/Auth/XP/UP;
- [ ] HUD uses event-driven updates;
- [ ] HUD hides during modal/minigame/pause;
- [ ] crosshair/prompt presentation consistent;
- [ ] semantic notification rail exists;
- [ ] stage notifications exist;
- [ ] no passive Money notification spam;
- [ ] Phone has stable STATUS/STORY/GIRLS/MEDIA/CLONES tabs;
- [ ] MEDIA hidden before feature;
- [ ] CLONES hidden before first clone;
- [ ] Phone top status compact/readable;
- [ ] STATUS includes stats/salary/late rates;
- [ ] STORY remains current-objective only;
- [ ] GIRLS uses list/detail layout;
- [ ] girl reactions show explicit +1/0/-1;
- [ ] MEDIA has Attention/photos/incoming/overload/feed;
- [ ] CLONES is read-only and points to physical terminals;
- [ ] full Progression UI exists;
- [ ] all 32 perks readable;
- [ ] costs/prereqs shown before purchase;
- [ ] characteristic stat shown per branch;
- [ ] no Phone perk purchasing;
- [ ] DatingUI is polished but gameplay-identical;
- [ ] requirements visible before action;
- [ ] greeting explicitly non-scoring;
- [ ] reaction +1/0/-1 obvious;
- [ ] final dating result breakdown clear;
- [ ] Slap/Dance/Sigma/Money have unified visual shell;
- [ ] controls visible in all minigames;
- [ ] obvious English prototype feedback translated;
- [ ] result WIN/LOSS readable;
- [ ] normal rival reward/consequence readable;
- [ ] final exhibition shows no Authority consequence;
- [ ] Clone Terminal readable + next-value previews;
- [ ] Global Terminal readable + Reach bar;
- [ ] FinalDateUI themed/readable;
- [ ] ending UI themed/readable;
- [ ] tutorial prompts exist only for seven defined first-use concepts;
- [ ] tutorials do not interrupt modal/minigame;
- [ ] runtime UI scale 100/125/150 works;
- [ ] no essential color-only communication;
- [ ] central number formatter exists;
- [ ] K/M/B formatting tested;
- [ ] technical IDs absent from player-facing production UI;
- [ ] exactly one HUD/Phone persistent instance;
- [ ] modal stacking remains safe;
- [ ] 720p/1080p/1440p pass;
- [ ] 150% UI scale pass;
- [ ] all MODULE02–21 regressions PASS;
- [ ] full F5 can be played without console/debug to ending;
- [ ] no MODULE23 audio/animation/VFX implemented ahead.

---

# 110. Recommended Cursor order

```text
1. Audit every current player-facing UI and write a short coverage matrix.
2. Create Theme + number formatter.
3. Add persistent GameHUD + control-mode visibility.
4. Refactor Phone presentation into five tabs without changing action logic.
5. Build Progression UI using existing Progression APIs/content.
6. Polish DatingUI.
7. Apply shared shell/readability to Slap/Dance/Sigma/Money.
8. Polish rival pre-start/result presentation.
9. Polish Clone/Global terminals.
10. Apply Theme to FinalDate/ending.
11. Add stage notifications + seven tutorial prompts.
12. Add UI scale 100/125/150.
13. Search for technical IDs/English leftovers.
14. Resolution/accessibility pass.
15. Full clean F5 without debug.
16. All regressions/docs.
```

---

# 111. Cursor final report

## UI architecture

Explain:

```text
GameHUD ownership
Theme
Phone tabs
Progression UI
modal ownership
number formatter
```

## HUD

Show exact four permanent indicators and visibility rules.

## Phone

Confirm five tabs and all MODULE15–21 actions remain functional.

## Progression

Confirm all 32 perks, costs/prereqs and purchases.

## Dating / Rivals / Minigames

Confirm requirements/results are visible and no gameplay formulas changed.

## Late game

Show Clone/Global Terminal numbers against actual status snapshots.

## Accessibility

Confirm:

```text
720p
1080p
1440p
UI 100/125/150%
color+text states
```

## Full game

Describe clean F5 playthrough using UI only, no console/debug guidance.

## Regression

All MODULE02–21 suites.

## Commit

SHA.

Then STOP. Do not begin MODULE23.
