# MODULE 25 — CONTENT COMPLETION

**Проект:** Date Factory  
**Модуль:** 25 — Content Completion  
**Статус:** обязательная спецификация перед реализацией  
**Назначение:** финально заполнить уже готовую игру контентом до release-candidate объёма, не добавляя новых gameplay systems. Закрыть полный набор обычных девушек, обычных самцов, dating events, реплик, интерактивных подписей, сценических гэгов, визуальных вариаций NPC и presentation tiers существующей late-game incremental части.  
**Предыдущий модуль:** MODULE 24 — Save / Load / Settings  
**Следующий модуль:** MODULE 26 — Balance / Anti-Grind  
**Product truth:** `docs/gdd/05_girls.md`, `docs/gdd/06_dating.md`, `docs/gdd/08_locations_ui_content.md`  
**Tech truth:** `docs/tech/TECH_PLAN_FULL.md`, MODULE 25

---

# 0. КРИТИЧЕСКАЯ ГРАНИЦА

MODULE 25 — CONTENT ONLY.

Он НЕ добавляет:

```text
новые gameplay systems
новые currencies
новые Story stages
новые minigames
новые trait types
новые action tags
новые clone assignments
новые upgrade tracks
новую location
новый quest system
новый NPC scheduler
```

Разрешено только:

```text
новые .tres content resources
новые production NPC anchors
новые appearance profiles
новые existing-format dating/discovery content
новые static/interactive flavor props
presentation-only visual tiers существующих upgrades
маленькие content adapters, если без них невозможно показать утверждённый flavor
```

Все gameplay formulas остаются прежними до MODULE 26.

---

# 1. CURRENT PRODUCTION BASELINE

На входе MODULE25 production catalog:

```text
Girls: 14
Rivals: 14
```

Girls:

```text
7 story/final
7 ordinary
```

Ordinary girls already:

```text
girl_city_bicycle
girl_cafe_laptop
girl_gym_chalk
girl_appearance_ritual
girl_public_sculpture
girl_cafe_receipt_notes
girl_appearance_flash
```

Story/final:

```text
girl_neighbor
girl_actress
girl_mine_boss
girl_magazine_editor
girl_scientist
girl_president
girl_final_target
```

Rivals currently include:

```text
5 Earth story rivals
7 ordinary rivals
2 final exhibition rivals
```

---

# 2. CONTENT TARGET — EXACT

After MODULE25:

```text
Girls = 23
```

Breakdown:

```text
16 ordinary
7 story/final
```

Rivals:

```text
19
```

Breakdown:

```text
12 ordinary
5 Earth story
2 final exhibition
```

Discovery situations:

```text
22
```

because:

```text
13 existing discovery situations
+9 new ordinary
```

Final target remains custom FinalDate and has no ordinary discovery situation.

---

# 3. WHY EXACTLY 16 ORDINARY GIRLS

There are:

```text
4 primary traits
×
4 secondary traits
=
16 combinations
```

Release candidate should contain:

```text
exactly one ordinary girl for every primary×secondary pair
```

This gives mechanically meaningful variety without adding traits.

Existing 7 combinations:

```text
KIND + VARIETY_SEEKING       girl_city_bicycle
STATUS + CONSISTENT          girl_cafe_laptop
THRILL_SEEKING + SCANDALOUS  girl_gym_chalk
STRANGE + VARIETY_SEEKING    girl_appearance_ritual
STRANGE + CONSISTENT         girl_public_sculpture
KIND + DEMANDING             girl_cafe_receipt_notes
STATUS + SCANDALOUS          girl_appearance_flash
```

Missing exactly 9 combinations are filled below.

---

# 4. NEW ORDINARY GIRL MATRIX — EXACT

| ID | Display | Primary | Secondary | XP | Discovery location |
|---|---|---|---|---:|---|
| `girl_city_umbrella` | Девушка с чужим зонтом | KIND | SCANDALOUS | 0 | city_hub |
| `girl_cafe_spoon_stack` | Девушка со стопкой ложек | KIND | CONSISTENT | 1 | cafe |
| `girl_city_lanyard` | Девушка с бейджами | STATUS | VARIETY_SEEKING | 2 | city_hub |
| `girl_appearance_coat_check` | Девушка у гардероба | STATUS | DEMANDING | 3 | appearance_space |
| `girl_gym_timer` | Девушка с таймером | THRILL_SEEKING | CONSISTENT | 1 | gym |
| `girl_city_crosswalk` | Девушка у перехода | THRILL_SEEKING | VARIETY_SEEKING | 2 | city_hub |
| `girl_cafe_hot_sauce` | Девушка с острым соусом | THRILL_SEEKING | DEMANDING | 3 | cafe |
| `girl_appearance_mannequin` | Девушка у манекена | STRANGE | SCANDALOUS | 3 | appearance_space |
| `girl_cafe_sugar_geometry` | Девушка с сахарной схемой | STRANGE | DEMANDING | 4 | cafe |

No ordinary girl requires XP >4.

President still requires10 and late automation remains relevant.

---

# 5. GIRL 01 — `girl_city_umbrella`

```text
display_name = "Девушка с чужим зонтом"
primary = KIND
secondary = SCANDALOUS
required_experience = 0
appearance = appearance_female_city_umbrella
discovery = discovery_situation_city_umbrella
default date = cafe
```

Speech:

```text
Мягкая к людям, но совершенно не умеет помогать тихо.
Если видит несправедливость, делает добро так, что о нём узнаёт весь квартал.
```

Clues:

```text
1. "Держит зонт над незнакомым человеком, а сама стоит под дождём."
2. "Когда водитель обрызгал прохожего, объяснила ему проблему через открытую дверь автобуса."
3. "Фразу «не будем устраивать сцену» воспринимает как описание ещё не начавшейся сцены."
```

Discovery setup:

```text
"Она держит над мокрым прохожим чужой зонт и одновременно громко выясняет,
кто именно оставил этот зонт на остановке."
```

Approaches:

SUCCESS:
```text
"Предложить подержать зонт, пока она заканчивает общественное расследование"
→ CARE + public context
```

FAILURE:
```text
"Сказать, что проще купить новый зонт"
CAPITAL 1
→ PRESTIGE
```

FAILURE:
```text
"Посоветовать всем разойтись без лишнего шума"
AURA 1
→ quiet/control
```

---

# 6. GIRL 02 — `girl_cafe_spoon_stack`

```text
display_name = "Девушка со стопкой ложек"
primary = KIND
secondary = CONSISTENT
XP = 1
appearance = appearance_female_cafe_spoon_stack
discovery = discovery_situation_cafe_spoon_stack
```

Speech:

```text
Спокойная, заботливая, повторяет хорошие маленькие действия
до тех пор, пока они не превращаются в личный протокол.
```

Clues:

```text
1. "Каждый раз возвращает лишнюю ложку официанту, чтобы тому не пришлось собирать их потом."
2. "Заказывает одно и то же, если прошлый раз всем было удобно."
3. "Новый эффектный план интересует её меньше, чем старый работающий."
```

Discovery:

```text
"Она собирает с соседних пустых столов забытые ложки
и складывает их в идеально одинаковые стопки для официанта."
```

SUCCESS:
```text
"Молча собрать вторую такую же стопку"
```

FAIL:
```text
"Заказать новые ложки для всего кафе"
CAPITAL 1
```

FAIL:
```text
"Переставить стопку в более эффектное место"
APPEARANCE 1
```

---

# 7. GIRL 03 — `girl_city_lanyard`

```text
display_name = "Девушка с бейджами"
primary = STATUS
secondary = VARIETY_SEEKING
XP = 2
appearance = appearance_female_city_lanyard
discovery = discovery_situation_city_lanyard
```

Speech:

```text
Организованная, замечает статус и качество,
но быстро теряет уважение к человеку с одной-единственной сильной кнопкой.
```

Clues:

```text
1. "Раздаёт бейджи по уровням доступа раньше, чем люди успевают представиться."
2. "Если один аргумент сработал дважды, на третий раз просит другой."
3. "Уважает хороший костюм, но ещё больше — человека, который умеет менять тактику."
```

Discovery:

```text
"Перед городским мероприятием она обнаружила коробку из трёх видов бейджей
и пытается восстановить иерархию по качеству пластика."
```

SUCCESS:
```text
"Предложить разделить доступ по трём разным признакам, а не только по цвету"
```

FAIL:
```text
"Сразу взять самый дорогой на вид бейдж"
CAPITAL 1
```

FAIL:
```text
"Объявить, что тебе бейдж не нужен"
AURA 1
```

---

# 8. GIRL 04 — `girl_appearance_coat_check`

```text
display_name = "Девушка у гардероба"
primary = STATUS
secondary = DEMANDING
XP = 3
appearance = appearance_female_appearance_coat_check
discovery = discovery_situation_appearance_coat_check
```

Speech:

```text
Вежливая и строгая. Не требует роскоши ради роскоши,
но замечает две плохие детали быстрее одной выдающейся.
```

Clues:

```text
1. "Перевешивает дорогой пиджак, потому что плечики не соответствуют ткани."
2. "Одну ошибку исправляет молча. Вторую уже записывает как систему."
3. "Называет порядок вещей формой уважения к самим вещам."
```

Discovery:

```text
"Она спорит с номерком гардероба: пальто дорогое, номерок дешёвый,
и это, по её словам, создаёт неверную управленческую связь."
```

SUCCESS:
```text
"Предложить заменить номерок, не трогая пальто"
```

FAIL:
```text
"Предложить купить новый гардероб"
CAPITAL 1
```

FAIL:
```text
"Сказать, что номерок должен подчиниться уверенности владельца"
AURA 1
```

---

# 9. GIRL 05 — `girl_gym_timer`

```text
display_name = "Девушка с таймером"
primary = THRILL_SEEKING
secondary = CONSISTENT
XP = 1
appearance = appearance_female_gym_timer
discovery = discovery_situation_gym_timer
```

Speech:

```text
Любит риск, но уважает человека, который рискует последовательно,
а не меняет личность после каждого подхода.
```

Clues:

```text
1. "Каждые шестьдесят секунд выбирает следующий снаряд чуть опаснее предыдущего."
2. "Проигрыш её веселит, если попытка была настоящей."
3. "Не любит, когда человек после одной ошибки полностью меняет стиль."
```

Discovery:

```text
"Таймер пищит. Она смотрит на табличку «НЕ ПОВТОРЯТЬ БЕЗ ТРЕНЕРА»
и запускает таймер ещё раз."
```

SUCCESS:
```text
"Предложить повторить тот же рискованный подход, но честно засечь время"
```

FAIL:
```text
"Предложить безопасную разминку вместо попытки"
MUSCLE 1
```

FAIL:
```text
"Предложить каждый раз менять упражнение"
APPEARANCE 1
```

---

# 10. GIRL 06 — `girl_city_crosswalk`

```text
display_name = "Девушка у перехода"
primary = THRILL_SEEKING
secondary = VARIETY_SEEKING
XP = 2
appearance = appearance_female_city_crosswalk
discovery = discovery_situation_city_crosswalk
```

Speech:

```text
Любит движение и смену условий.
Если решение уже стало привычным, для неё оно почти перестало быть решением.
```

Clues:

```text
1. "Выбирает переход не потому, что он ближе, а потому что на нём сегодня сломан другой светофор."
2. "После удачного способа сразу спрашивает, какой есть второй."
3. "Плохо переносит расписание, которое пережило больше одного дня."
```

Discovery:

```text
"Она стоит у перехода и сравнивает три маршрута,
хотя все три ведут на противоположную сторону одной улицы."
```

SUCCESS:
```text
"Предложить перейти туда одним способом, а вернуться другим"
```

FAIL:
```text
"Выбрать самый предсказуемый безопасный маршрут"
CAPITAL 1
```

FAIL:
```text
"Сказать, что правильный переход может быть только один"
AURA 1
```

---

# 11. GIRL 07 — `girl_cafe_hot_sauce`

```text
display_name = "Девушка с острым соусом"
primary = THRILL_SEEKING
secondary = DEMANDING
XP = 3
appearance = appearance_female_cafe_hot_sauce
discovery = discovery_situation_cafe_hot_sauce
```

Speech:

```text
Ей нужен настоящий риск, но две трусливые оговорки подряд
уничтожают впечатление сильнее одного хорошего трюка.
```

Clues:

```text
1. "Заказывает соус, возле которого меню предлагает подписать устное согласие."
2. "Ошибку прощает, если человек не делает вид, что так и планировал."
3. "Два безопасных решения подряд считает официальным отказом от вечера."
```

Discovery:

```text
"Она читает предупреждение на бутылке соуса вслух
и спрашивает официанта, почему текст звучит как приглашение."
```

SUCCESS:
```text
"Предложить попробовать по одной капле без героического вранья"
```

FAIL:
```text
"Попросить принести самый мягкий соус"
CAPITAL 1
```

FAIL:
```text
"Вылить сразу половину бутылки, чтобы впечатлить"
MUSCLE 1
```

---

# 12. GIRL 08 — `girl_appearance_mannequin`

```text
display_name = "Девушка у манекена"
primary = STRANGE
secondary = SCANDALOUS
XP = 3
appearance = appearance_female_appearance_mannequin
discovery = discovery_situation_appearance_mannequin
```

Speech:

```text
Серьёзно относится к нелепым системам и предпочитает,
чтобы их последствия были видны окружающим.
```

Clues:

```text
1. "Попросила манекен отвернуться, прежде чем переодеть второй манекен."
2. "Если странный ритуал никто не заметил, считает эксперимент неполным."
3. "Официальная дорогая версия вещи кажется ей менее интересной, чем неправильная с точным правилом."
```

Discovery:

```text
"Она публично спорит с манекеном о том,
может ли тот носить шарф после того, как уже видел его на другом манекене."
```

SUCCESS:
```text
"Предложить вызвать второго манекена как независимого свидетеля"
```

FAIL:
```text
"Купить шарф и закрыть вопрос"
CAPITAL 1
```

FAIL:
```text
"Тихо переставить манекен, пока никто не видит"
APPEARANCE 1
```

---

# 13. GIRL 09 — `girl_cafe_sugar_geometry`

```text
display_name = "Девушка с сахарной схемой"
primary = STRANGE
secondary = DEMANDING
XP = 4
appearance = appearance_female_cafe_sugar_geometry
discovery = discovery_situation_cafe_sugar_geometry
```

Speech:

```text
Строит точные бессмысленные системы.
Одна ошибка интересна, две ошибки означают, что человек не понял систему.
```

Clues:

```text
1. "Раскладывает сахар по треугольнику, хотя кофе пьёт без сахара."
2. "Первое нарушение схемы исправляет. Второе классифицирует."
3. "Дорогой десерт не впечатляет, если его нельзя встроить в правило."
```

Discovery:

```text
"На столе выложен треугольник из пакетиков сахара.
Она объясняет официанту, что один пакет лежит математически невежливо."
```

SUCCESS:
```text
"Спросить, где должен лежать пакет, чтобы схема снова считалась вежливой"
```

FAIL:
```text
"Предложить заменить весь сахар дорогим"
CAPITAL 1
```

FAIL:
```text
"Сдвинуть один пакет на глаз"
APPEARANCE 1
```

---

# 14. NEW GIRL APPEARANCE PROFILES

Create exact IDs:

```text
appearance_female_city_umbrella
appearance_female_cafe_spoon_stack
appearance_female_city_lanyard
appearance_female_appearance_coat_check
appearance_female_gym_timer
appearance_female_city_crosswalk
appearance_female_cafe_hot_sauce
appearance_female_appearance_mannequin
appearance_female_cafe_sugar_geometry
```

Use existing female base.

Cursor first audits current/donor clothing/hair/accessory assets.

Visual intent:

```text
umbrella       → practical outer layer + umbrella/long prop if available
spoon_stack    → calm café silhouette, neutral hair/accessory
lanyard        → structured outfit + visible badge/lanyard
coat_check     → formal/clean silhouette
gym_timer      → sporty silhouette + wrist/timer prop if possible
crosswalk      → street/casual + bag/head accessory
hot_sauce      → café casual with stronger accent accessory
mannequin      → fashion-forward unusual accessory
sugar_geometry → precise/minimal outfit, small glasses/accessory if available
```

No new base body.

If exact prop missing:

use simple MeshInstance3D primitive attached to staged situation, not character rig.

---

# 15. ALL 16 ORDINARY GIRLS GET SIGNATURE DATING EVENT

Each ordinary girl must have:

```text
1 personal signature central event
```

This event is added through a tiny one-event personal pool:

```text
date_pool_signature_<girl suffix>
```

Girl's pools become:

```text
[
  date_pool_cafe_common,
  date_pool_signature_<girl>
]
```

Existing story pools unchanged.

Signature event may repeat only according to existing planner history/cycle logic.

No special planner rule.

---

# 16. SIGNATURE EVENT — existing `girl_city_bicycle`

ID:

```text
date_event_signature_city_bicycle_lock
```

Category:

```text
SPACE_EVENT
```

Setup:

```text
"У входа чужой велосипед пристёгнут к вашему стулу."
```

Actions:

```text
MUSCLE 0
"Перенести стул вместе с велосипедом"
[CARE, ORIGINALITY]
```

```text
APPEARANCE 0
"Пересесть за соседний стол без объявления проблемы"
[SIMPLICITY]
```

```text
CAPITAL 0
"Предложить оплатить владельцу новый замок"
[PRESTIGE]
```

```text
AURA 0
"Громко потребовать владельца освободить мебель"
[CONFLICT, DOMINANCE]
```

---

# 17. SIGNATURE — `girl_cafe_laptop`

ID:

```text
date_event_signature_cafe_laptop_power
```

Category CONVERSATION/SPACE_EVENT.

Setup:

```text
"Ноутбук сообщает: «Осталось 3%». Розетка одна и занята декоративной лампой."
```

Actions:

```text
CAPITAL 0
"Спросить администратора, какая розетка предусмотрена для гостей"
[CONTROL]
```

```text
APPEARANCE 0
"Аккуратно перестроить стол вокруг провода"
[CONTROL, PRESTIGE]
```

```text
MUSCLE 0
"Выдернуть декоративную лампу"
[DOMINANCE]
```

```text
AURA 0
"Сказать, что три процента должны научиться планировать"
[ABSURDITY]
```

---

# 18. SIGNATURE — `girl_gym_chalk`

ID:

```text
date_event_signature_gym_chalk_challenge
```

Setup:

```text
"За соседним столом кто-то спорит, что острый напиток невозможно допить залпом."
```

Actions:

```text
MUSCLE 0
"Принять спор и честно попробовать"
[RISK, CONFLICT]
```

```text
AURA 0
"Поднять ставку: проигравший объявляет результат всему кафе"
[CONFLICT]
is_public = true
```

```text
CAPITAL 0
"Заказать обычный напиток"
[SIMPLICITY]
```

```text
APPEARANCE 0
"Сделать вид, что спор относится к другому столу"
[CONTROL]
```

---

# 19. SIGNATURE — `girl_appearance_ritual`

ID:

```text
date_event_signature_appearance_ritual_napkin
```

Setup:

```text
"Она кладёт салфетку ровно между двумя чашками и спрашивает,
может ли вечер продолжаться, если угол не кратен семи."
```

Actions:

```text
APPEARANCE 0
"Повернуть салфетку ровно на семь градусов"
[ORIGINALITY, ABSURDITY]
```

```text
AURA 0
"Объявить текущий угол временно допустимым по внутреннему правилу"
[ABSURDITY]
```

```text
CAPITAL 0
"Попросить новую дорогую салфетку"
[PRESTIGE]
```

```text
MUSCLE 0
"Убрать салфетку совсем"
[SIMPLICITY]
```

---

# 20. SIGNATURE — `girl_public_sculpture`

ID:

```text
date_event_signature_public_sculpture_menu_name
```

Setup:

```text
"В меню есть десерт без фотографии. Она предлагает сначала дать ему название."
```

Actions:

```text
AURA 0
"Назвать его «Последствие выбора»"
[ORIGINALITY, ABSURDITY]
```

```text
APPEARANCE 0
"Придумать название по форме пустого места в меню"
[ORIGINALITY]
```

```text
CAPITAL 0
"Выбрать самый дорогой десерт с нормальным названием"
[PRESTIGE]
```

```text
MUSCLE 0
"Попросить просто принести десерт"
[SIMPLICITY]
```

---

# 21. SIGNATURE — `girl_cafe_receipt_notes`

ID:

```text
date_event_signature_receipt_waiter
```

Setup:

```text
"Официант забывает чужой заказ и расстраивается заметно сильнее клиента."
```

Actions:

```text
MUSCLE 0
"Спокойно помочь отнести правильный заказ"
[CARE, SIMPLICITY]
```

```text
AURA 0
"Сказать официанту, что ошибка не делает его плохим официантом"
[CARE, VULNERABILITY]
```

```text
CAPITAL 0
"Потребовать менеджера"
[CONFLICT, CONTROL]
```

```text
APPEARANCE 0
"Пошутить на весь зал про сервис"
[CONFLICT]
is_public = true
```

---

# 22. SIGNATURE — `girl_appearance_flash`

ID:

```text
date_event_signature_appearance_flash_background
```

Setup:

```text
"Она замечает, что на заднем плане вашей фотографии человек ест суп."
```

Actions:

```text
APPEARANCE 0
"Перестроить кадр так, чтобы суп выглядел частью композиции"
[PRESTIGE, ORIGINALITY]
is_public = true
```

```text
MUSCLE 0
"Попросить человека пересесть"
[DOMINANCE]
```

```text
CAPITAL 0
"Оплатить ему другой стол"
[CONTROL, PRESTIGE]
```

```text
AURA 0
"Сказать, что настоящий кадр выдержит суп"
[ABSURDITY]
```

---

# 23. SIGNATURE — `girl_city_umbrella`

ID:

```text
date_event_signature_city_umbrella_waiter
```

Setup:

```text
"Официант роняет поднос. Никто не пострадал, но весь зал замолчал."
```

Actions:

```text
MUSCLE 0
"Помочь собрать посуду"
[CARE, SIMPLICITY]
```

```text
AURA 0
"Первым сказать, что всё нормально, достаточно громко для всего зала"
[CARE]
is_public = true
```

```text
APPEARANCE 0
"Сделать вид, что ничего не произошло"
[CONTROL]
```

```text
CAPITAL 0
"Потребовать компенсацию"
[CONFLICT]
```

---

# 24. SIGNATURE — `girl_cafe_spoon_stack`

ID:

```text
date_event_signature_spoon_stack_repeat
```

Setup:

```text
"Официант снова приносит две лишние ложки — ровно как в прошлый раз."
```

Actions:

```text
MUSCLE 0
"Вернуть их тем же спокойным способом"
[CARE, SIMPLICITY]
```

```text
CAPITAL 0
"Предложить официанту простое постоянное место для лишних приборов"
[CONTROL, CARE]
```

```text
APPEARANCE 0
"Сложить из ложек новую композицию"
[ORIGINALITY]
```

```text
AURA 0
"Объявить лишнюю ложку частью традиции"
[ABSURDITY]
```

---

# 25. SIGNATURE — `girl_city_lanyard`

ID:

```text
date_event_signature_city_lanyard_reservation
```

Setup:

```text
"На вашем столе стоит табличка «VIP», но бронь оформлена просто на имя."
```

Actions:

```text
CAPITAL 0
"Уточнить у администратора фактический уровень брони"
[CONTROL, PRESTIGE]
```

```text
APPEARANCE 0
"Оставить табличку, но выбрать другой способ подачи заказа"
[PRESTIGE, ORIGINALITY]
```

```text
MUSCLE 0
"Сказать, что табличка теперь ваша"
[DOMINANCE]
```

```text
AURA 0
"Игнорировать любые уровни весь вечер"
[ABSURDITY]
```

---

# 26. SIGNATURE — `girl_appearance_coat_check`

ID:

```text
date_event_signature_coat_check_glass
```

Setup:

```text
"В вашем бокале небольшая царапина. Напиток идеален."
```

Actions:

```text
APPEARANCE 0
"Попросить заменить только бокал"
[PRESTIGE, CONTROL]
```

```text
CAPITAL 0
"Спокойно уточнить стандарт посуды заведения"
[CONTROL]
```

```text
MUSCLE 0
"Сказать, что царапина никому не мешает"
[SIMPLICITY]
```

```text
AURA 0
"Объявить царапину знаком качества"
[ABSURDITY]
```

---

# 27. SIGNATURE — `girl_gym_timer`

ID:

```text
date_event_signature_gym_timer_spicy
```

Setup:

```text
"Меню предлагает «испытание недели»: закончить очень острое блюдо за минуту."
```

Actions:

```text
MUSCLE 0
"Запустить таймер и принять испытание"
[RISK]
```

```text
AURA 0
"Принять испытание по тем же правилам, даже если первая попытка плохая"
[RISK, CONTROL]
```

```text
CAPITAL 0
"Купить обычную порцию"
[SIMPLICITY]
```

```text
APPEARANCE 0
"Менять правила после каждого кусочка"
[SPONTANEITY]
```

---

# 28. SIGNATURE — `girl_city_crosswalk`

ID:

```text
date_event_signature_crosswalk_three_routes
```

Setup:

```text
"После кафе можно идти домой тремя маршрутами одинаковой длины."
```

Actions:

```text
MUSCLE 0
"Выбрать путь через шумную ярмарку"
[RISK, SPONTANEITY]
```

```text
APPEARANCE 0
"Сначала пройти через набережную, потом резко сменить маршрут"
[SPONTANEITY, ORIGINALITY]
```

```text
CAPITAL 0
"Вызвать машину прямо ко входу"
[CONTROL]
```

```text
AURA 0
"Настоять на одном заранее выбранном маршруте"
[CONTROL]
```

---

# 29. SIGNATURE — `girl_cafe_hot_sauce`

ID:

```text
date_event_signature_hot_sauce_second_round
```

Setup:

```text
"После первой острой закуски официант предлагает вторую, заметно хуже."
```

Actions:

```text
MUSCLE 0
"Принять второй раунд без обещаний победить"
[RISK, VULNERABILITY]
```

```text
AURA 0
"Принять и публично признать, если станет слишком остро"
[RISK, CONFLICT]
is_public = true
```

```text
CAPITAL 0
"Заказать молоко и отказаться"
[CONTROL, SIMPLICITY]
```

```text
APPEARANCE 0
"Сделать вид, что первый раунд уже был финалом"
[CONTROL]
```

---

# 30. SIGNATURE — `girl_appearance_mannequin`

ID:

```text
date_event_signature_mannequin_third_chair
```

Setup:

```text
"За вашим столом неожиданно стоит третий пустой стул.
Она спрашивает, кого заведение ожидало."
```

Actions:

```text
AURA 0
"Назначить стул официальным свидетелем"
[ABSURDITY, ORIGINALITY]
is_public = true
```

```text
APPEARANCE 0
"Повернуть стул к залу, чтобы свидетель видел всё"
[ABSURDITY]
is_public = true
```

```text
CAPITAL 0
"Попросить убрать лишний стул"
[CONTROL]
```

```text
MUSCLE 0
"Самому отнести его подальше"
[SIMPLICITY]
```

---

# 31. SIGNATURE — `girl_cafe_sugar_geometry`

ID:

```text
date_event_signature_sugar_geometry_cup
```

Setup:

```text
"Чашка стоит на два сантиметра левее центра сахарной схемы."
```

Actions:

```text
APPEARANCE 0
"Встроить чашку в новую симметрию"
[ORIGINALITY]
```

```text
AURA 0
"Объявить чашку новой точкой отсчёта"
[ABSURDITY, ORIGINALITY]
```

```text
CAPITAL 0
"Попросить новый сервировочный набор"
[PRESTIGE, CONTROL]
```

```text
MUSCLE 0
"Сдвинуть всё в центр стола"
[SIMPLICITY]
```

---

# 32. COMMON CAFE POOL EXPANSION

Current:

```text
12 cafe common central events
```

Add exactly:

```text
12 new common cafe events
```

Result:

```text
24 common cafe events
```

This provides repeat-date variety across all ordinary girls.

Exact new IDs:

```text
date_event_cafe_wrong_order
date_event_cafe_last_cake
date_event_cafe_window_draft
date_event_cafe_phone_charger
date_event_cafe_reserved_sign
date_event_cafe_loud_table
date_event_cafe_wobbly_spoon
date_event_cafe_free_sample
date_event_cafe_coat_mixup
date_event_cafe_waiter_question
date_event_cafe_table_photo
date_event_cafe_closing_chairs
```

---

# 33. COMMON EVENT — wrong order

Setup:

```text
"Официант приносит чужой заказ и уже уходит."
```

Actions:

```text
MUSCLE: "Догнать и вернуть тарелку" [CARE]
APPEARANCE: "Попросить заменить заказ без сцены" [CONTROL]
CAPITAL: "Оставить чужой заказ и заказать свой второй раз" [PRESTIGE]
AURA: "Объявить ошибку новым выбором вечера" [SPONTANEITY, ABSURDITY]
```

---

# 34. COMMON — last cake

```text
"В витрине остался последний кусок торта. За ним одновременно тянется другой посетитель."
```

```text
MUSCLE: "Уступить кусок" [CARE, SIMPLICITY]
APPEARANCE: "Предложить разделить его так, чтобы обе тарелки выглядели нормально" [ORIGINALITY]
CAPITAL: "Купить весь оставшийся торт" [PRESTIGE]
AURA: "Предложить решить право на торт публичным спором" [CONFLICT]
```

---

# 35. COMMON — window draft

```text
"Из окна сильно дует прямо на соседний стол."
```

```text
MUSCLE: "Закрыть окно после вопроса соседям" [CARE]
APPEARANCE: "Поменяться местами так, чтобы никого не пересаживать" [CARE, ORIGINALITY]
CAPITAL: "Попросить администратора решить проблему" [CONTROL]
AURA: "Сказать, что сквозняк теперь часть концепции" [ABSURDITY]
```

---

# 36. COMMON — phone charger

```text
"У соседнего гостя садится телефон, а у вас единственная зарядка."
```

```text
MUSCLE: "Одолжить зарядку" [CARE, SIMPLICITY]
APPEARANCE: "Предложить заряжать телефоны по очереди" [CARE, CONTROL]
CAPITAL: "Подарить ему новую зарядку" [PRESTIGE]
AURA: "Сказать, что телефон должен пережить вечер самостоятельно" [DOMINANCE]
```

---

# 37. COMMON — reserved sign

```text
"На пустой половине вашего стола внезапно появляется табличка «ЗАРЕЗЕРВИРОВАНО»."
```

```text
MUSCLE: "Передвинуть свои вещи на свою половину" [SIMPLICITY]
APPEARANCE: "Перестроить сервировку вокруг таблички" [ORIGINALITY]
CAPITAL: "Уточнить бронь у администратора" [CONTROL]
AURA: "Перевернуть табличку к пустому стулу и продолжить" [ABSURDITY]
```

---

# 38. COMMON — loud table

```text
"Соседний стол обсуждает ваш разговор громче вас."
```

```text
MUSCLE: "Попросить их говорить тише" [CONFLICT]
APPEARANCE: "Сменить тему так, чтобы наблюдатели потеряли сюжет" [ORIGINALITY]
CAPITAL: "Попросить другой стол у персонала" [CONTROL]
AURA: "Начать обсуждать соседний стол ещё громче" [CONFLICT, ABSURDITY]
is_public = true
```

---

# 39. COMMON — wobbly spoon

```text
"Одна ложка заметно отличается от остальных и качается на столе."
```

```text
MUSCLE: "Попросить обычную ложку" [SIMPLICITY]
APPEARANCE: "Положить её так, чтобы качание стало симметричным" [ORIGINALITY]
CAPITAL: "Попросить заменить весь комплект" [PRESTIGE, CONTROL]
AURA: "Назначить её главной ложкой" [ABSURDITY]
```

---

# 40. COMMON — free sample

```text
"Официант приносит один бесплатный мини-десерт на двоих."
```

```text
MUSCLE: "Отдать девушке" [CARE, SIMPLICITY]
APPEARANCE: "Разделить ровно пополам" [CONTROL]
CAPITAL: "Заказать два полноценных" [PRESTIGE]
AURA: "Предложить определить владельца спором" [CONFLICT]
```

---

# 41. COMMON — coat mixup

```text
"Посетитель у выхода случайно берёт куртку, похожую на вашу."
```

```text
MUSCLE: "Догнать и спокойно показать ошибку" [CARE]
APPEARANCE: "Сначала проверить свою бирку" [CONTROL]
CAPITAL: "Сказать, что купишь другую" [PRESTIGE]
AURA: "Позволить ему уйти и объявить это обменом" [ABSURDITY, SPONTANEITY]
```

---

# 42. COMMON — waiter question

```text
"Официант спрашивает, всё ли понравилось, и явно ждёт настоящего ответа."
```

```text
MUSCLE: "Честно назвать одну проблему без наезда" [VULNERABILITY, CARE]
APPEARANCE: "Сначала отметить хорошее, потом конкретную проблему" [CONTROL]
CAPITAL: "Сказать, что всё должно соответствовать цене" [PRESTIGE]
AURA: "Ответить: «мы ещё собираем данные»" [ABSURDITY]
```

---

# 43. COMMON — table photo

```text
"За соседним столом просят вас сфотографировать компанию."
```

```text
MUSCLE: "Согласиться и сделать один простой кадр" [CARE, SIMPLICITY]
APPEARANCE: "Поставить их лучше и сделать нормальный кадр" [CARE, PRESTIGE]
CAPITAL: "Предложить вызвать фотографа заведения" [PRESTIGE]
AURA: "Попросить их сначала сформулировать концепцию снимка" [ABSURDITY]
```

---

# 44. COMMON — closing chairs

```text
"Персонал начинает ставить стулья на столы вокруг вас, но вас пока не просит уходить."
```

```text
MUSCLE: "Сразу закончить вечер, чтобы не задерживать людей" [CARE, SIMPLICITY]
APPEARANCE: "Спокойно попросить две минуты и красиво завершить разговор" [CONTROL]
CAPITAL: "Предложить доплатить за ещё полчаса" [PRESTIGE]
AURA: "Считать поднятые стулья официальным финальным ритуалом" [ABSURDITY]
```

---

# 45. COMMON EVENT CATEGORY DISTRIBUTION

Among the 12 new common events ensure:

```text
CONVERSATION      = 4
SPACE_EVENT       = 4
GIRL_PROPOSAL     = 4
```

Cursor may map the above concepts to categories sensibly, but final exact count must be 4/4/4.

Planner rule remains:

```text
no three same category
no duplicate ID in evening
```

---

# 46. GREETINGS EXPANSION

Current:

```text
4 common greetings
```

Add exactly4:

```text
dating_greeting_offer_choice
dating_greeting_notice_detail
dating_greeting_direct_plan
dating_greeting_small_confession
```

Functional purpose:

each provides diagnostic information only.

No score.

Copy:

```text
offer_choice:
"Сразу предложить ей выбрать место за столом"

notice_detail:
"Отметить одну конкретную деталь её ситуации знакомства"

direct_plan:
"Коротко сказать, как ты предлагаешь провести вечер"

small_confession:
"Признаться, что заранее продумал только первые пять минут"
```

Each greeting must produce authored response/clue-compatible result text.

---

# 47. ORDINARY FAREWELL EXPANSION

Keep:

```text
dating_farewell_early_common
```

Add exactly3 common farewell definitions:

```text
dating_farewell_walk_common
dating_farewell_transport_common
dating_farewell_last_word_common
```

Each has four characteristic actions.

No new farewell mechanic.

Distribute 16 ordinary girls roughly 4 per farewell set.

---

# 48. FAREWELL — walk

```text
MUSCLE:
"Проводить до следующего перекрёстка"
[CARE, SIMPLICITY]

APPEARANCE:
"Выбрать красивый короткий маршрут"
[PRESTIGE]

CAPITAL:
"Заказать машину до дома"
[PRESTIGE, CONTROL]
money_cost = 10

AURA:
"Сказать, что правильный момент прощания уже наступил"
[CONTROL]
```

---

# 49. FAREWELL — transport

```text
MUSCLE:
"Подождать вместе до транспорта"
[CARE]

APPEARANCE:
"Проводить до нужной двери и уйти без лишней сцены"
[CONTROL, PRESTIGE]

CAPITAL:
"Оплатить поездку"
[PRESTIGE]
money_cost = 10

AURA:
"Предложить выбрать транспорт по первому приехавшему номеру"
[SPONTANEITY]
```

---

# 50. FAREWELL — last word

```text
MUSCLE:
"Честно сказать, что вечер понравился"
[VULNERABILITY]

APPEARANCE:
"Закончить вечер одной хорошо сформулированной фразой"
[PRESTIGE]

CAPITAL:
"Сразу предложить конкретный следующий план"
[CONTROL]

AURA:
"Оставить последнюю реплику ей"
[CARE, ORIGINALITY]
```

---

# 51. NEW ORDINARY RIVALS — EXACT FIVE

Add:

```text
rival_city_thermos
rival_gym_plate_counter
rival_appearance_ringlight
rival_cafe_menu_holder
rival_city_headphones
```

Production total becomes:

```text
19 rivals
```

No new story rivals.

---

# 52. RIVAL — city thermos

```text
display_name = "Самец с термосом"

required_authority = 2
authority_reward = 1

muscle = 2
appearance = 2
capital = 1
aura = 3

preferred = SIGMA
allowed = [SIGMA, DANCE]

appearance = appearance_male_city_thermos
```

Physical:

```text
city_hub public segment
```

Presentation:

```text
Стоит у лавки и держит термос обеими руками так,
будто это источник легитимности.
```

If SIGMA locked, DANCE remains base fallback.

---

# 53. RIVAL — gym plate counter

```text
display_name = "Самец, считающий блины"

required_authority = 3
reward = 1

muscle = 4
appearance = 1
capital = 2
aura = 2

preferred = SLAP
allowed = [SLAP, MONEY]

appearance = appearance_male_gym_plate_counter
```

Physical:

```text
gym
```

Presentation:

```text
Пересчитывает блины на чужой штанге и сообщает промежуточные итоги владельцу.
```

SLAP base-safe.

---

# 54. RIVAL — appearance ringlight

```text
display_name = "Самец внутри кольцевой лампы"

required_authority = 4
reward = 2

muscle = 1
appearance = 5
capital = 3
aura = 3

preferred = DANCE
allowed = [DANCE, SIGMA]

appearance = appearance_male_appearance_ringlight
```

Physical:

```text
appearance_space
```

Presentation:

```text
Стоит точно в центре кольцевой лампы и не выходит из неё даже для разговора.
```

---

# 55. RIVAL — cafe menu holder

```text
display_name = "Самец с кожаной папкой меню"

required_authority = 4
reward = 2

muscle = 2
appearance = 3
capital = 5
aura = 2

preferred = MONEY
allowed = [MONEY, SLAP]

appearance = appearance_male_cafe_menu_holder
```

Physical:

```text
cafe
```

Presentation:

```text
Держит меню закрытым и периодически проверяет цену блюда, которое уже заказал.
```

SLAP base fallback.

---

# 56. RIVAL — city headphones

```text
display_name = "Самец в наушниках без музыки"

required_authority = 5
reward = 2

muscle = 3
appearance = 4
capital = 2
aura = 5

preferred = SIGMA
allowed = [SIGMA, DANCE, SLAP]

appearance = appearance_male_city_headphones
```

Physical:

```text
city_hub public segment
```

Presentation:

```text
В больших наушниках. Музыка не играет.
Наушники используются исключительно для переговорной позиции.
```

---

# 57. NEW MALE APPEARANCE PROFILES

Create:

```text
appearance_male_city_thermos
appearance_male_gym_plate_counter
appearance_male_appearance_ringlight
appearance_male_cafe_menu_holder
appearance_male_city_headphones
```

Reuse male base.

Audit current/donor accessories.

Simple staged props are acceptable if rig attachment is not worth it.

No new male body.

---

# 58. ORDINARY RIVAL PHYSICAL RULES

Existing defeated persistence remains.

Once ordinary rival defeated:

```text
does not respawn
```

They are optional Authority/replay content.

No farming.

No story requirement depends on any of these five.

---

# 59. MEDIA CANDIDATE LIST EXPANSION

Current Media incoming list uses existing ordinary girls.

Preserve existing 7 first in current deterministic order.

Append new9 in this exact order:

```text
girl_city_umbrella
girl_cafe_spoon_stack
girl_city_lanyard
girl_gym_timer
girl_city_crosswalk
girl_appearance_coat_check
girl_cafe_hot_sauce
girl_appearance_mannequin
girl_cafe_sugar_geometry
```

Do NOT change:

```text
Attention thresholds
first-wave semantics
DatingOverload formulas
```

This only expands candidate variety after existing content.

---

# 60. ORDINARY GIRL WORLD PLACEMENT

All 9 new girls must be physically reachable without random spawn.

Use current production pattern:

```text
GirlActor / staged anchor
```

No daily schedule simulation.

Exact distribution:

```text
city_hub:
  city_umbrella
  city_lanyard
  city_crosswalk

cafe:
  cafe_spoon_stack
  cafe_hot_sauce
  cafe_sugar_geometry

gym:
  gym_timer

appearance_space:
  appearance_coat_check
  appearance_mannequin
```

---

# 61. ACCESS GATING

New ordinary girls in city/gym/cafe/appearance:

use same public/social access semantics as existing ordinary content.

Do not add story stages to ordinary GirlDefinition.

Their individual XP gates are enough after location access.

No new generic StageActor requirement system.

---

# 62. DISCOVERY SITUATION REQUIREMENTS

All 9 new situations:

- fixed;
- visible props;
- exact one success route;
- exactly two authored failure routes;
- at least one failure exposes useful clue;
- no RNG;
- no reusable generic situation ID;
- retry still existing 1–3 days.

Add production validation:

```text
every ordinary girl has a valid discovery situation
```

---

# 63. STORY CONTENT AUDIT — NO NEW STORY CHARACTERS

Do NOT add new story girls/rivals.

Audit existing:

```text
Neighbor
Actress
Mine Boss
Magazine Editor
Scientist
President
Final Target

Actress Rival
Mine Rival
Editor Rival
Scientist Rival
President Rival
2 final exhibition rivals
```

For each verify:

```text
display_name intentional
speech_style_note non-placeholder
3 clues where applicable
discovery copy complete
date-specific copy complete
rival display copy readable
Phone/story references not technical
```

Fix copy only.

Do not change traits/stats/rewards in Module25.

Balance belongs MODULE26.

---

# 64. DATING COPY AUDIT

Every production central DatingEvent must have:

```text
nonempty setup
4 nonempty actions
valid characteristic
<=2 tags/action
result_text if schema supports per-action result
no placeholder/TODO/debug text
```

Every production action must be understandable before click.

No exact joke line reused in two different events.

---

# 65. REACTION COPY

If current Dating UI derives generic reaction copy:

add enough authored action result text so ordinary content does not feel like:

```text
+1
same sentence
```

Rule:

For new signature/common events:

```text
all actions have unique short result text
```

Target:

```text
1 sentence
<= roughly 120 characters where practical
```

No need for branching dialogue trees.

---

# 66. GIRL-SPECIFIC GREETING RESPONSES

For each 16 ordinary girls:

at least2 of her available greeting interactions should yield response text
that references her:

```text
speech style
discovery motif
trait clue
```

This can be data-driven if current greeting schema supports girl-independent copy poorly.

Do NOT create new dialogue system.

Preferred minimal solution:

add optional per-girl greeting response map only if current schema already has a clean seam.

Otherwise use signature event + speech/clues and leave greetings common.

No architecture expansion solely for this requirement.

---

# 67. INTERACTIVE FLAVOR CONTENT

TECH_PLAN requires:

```text
интерактивные подписи
```

Add at least:

```text
24 flavor interactions
```

across world.

Exact minimum distribution:

```text
apartment        5
city_hub         5
cafe             3
gym              2
appearance_space 3
salary_mine      2
laboratory       2
production_area  1
final_location   1
------------------
total           24
```

No rewards.

No state mutation except optional one-shot local presentation.

---

# 68. FLAVOR INTERACTION IMPLEMENTATION

First audit whether reusable flavor Interactable already exists.

If not, allowed one tiny:

```text
FlavorInteractable
```

extends `Interactable`.

Exports:

```text
prompt
text
```

Interaction:

```text
show small HUD/Label message
```

No GameState.

No save state.

No generic dialogue system.

---

# 69. APARTMENT FLAVOR — EXACT FIVE

Objects/copy:

```text
Mirror:
"ОТРАЖЕНИЕ
Статус: пока оригинал."

Wardrobe:
"ГАРДЕРОБ
Некоторые вещи уже выглядят как решение."

Fridge:
"ХОЛОДИЛЬНИК
Внутри находится еда и ни одного социального обязательства."

Window:
"ОКНО
Город пока не подозревает о производственном плане."

Chair:
"СТУЛ
Пахнет ламинатом и надеждами."
```

Do not repeat laminate joke elsewhere.

---

# 70. CITY FLAVOR — EXACT FIVE

```text
Bench:
"СКАМЕЙКА
Не бронируй место на тротуаре своим существованием."

Public sign:
"ГОРОДСКОЙ ЦЕНТР
Люди всё ещё перемещаются индивидуально."

Trash bin:
"УРНА
Принимает решения без предварительной записи."

Closed side door:
"СЛУЖЕБНЫЙ ВХОД
У тебя пока нет должности, которая звучит убедительно."

Map:
"КАРТА ГОРОДА
Масштаб пока позволяет притворяться, что это личная жизнь."
```

---

# 71. CAFE FLAVOR — EXACT THREE

```text
Menu:
"МЕНЮ
Любая проблема может быть дороже на 20% после добавления соуса."

Sugar tray:
"САХАР
Свободная геометрия. Пока."

Reserved table:
"БРОНЬ
Стол уже достиг большего социального статуса, чем некоторые посетители."
```

---

# 72. GYM FLAVOR — EXACT TWO

```text
Mirror:
"ЗЕРКАЛО
Повторения засчитываются даже если ты смотришь на себя."

Plate rack:
"БЛИНЫ
Не еда. Ошибка терминологии уже принята коллективом."
```

---

# 73. APPEARANCE SPACE FLAVOR — EXACT THREE

```text
Ring light:
"КОЛЬЦЕВАЯ ЛАМПА
Создаёт официальный вид даже у плохого решения."

Mannequin:
"МАНЕКЕН
Не дал согласия на текущий образ, но и не возражал."

Backdrop:
"ФОН
Реальность начинается сразу за краем кадра."
```

---

# 74. SALARY MINE FLAVOR — EXACT TWO

```text
Conveyor:
"КОНВЕЙЕР
Деньги физически существуют только ради убедительности."

Warning:
"ТЕХНИКА БЕЗОПАСНОСТИ
Не стой под начислением."
```

---

# 75. LAB FLAVOR — EXACT TWO

```text
Clone chamber:
"КАМЕРА КЛОНИРОВАНИЯ
Гарантия не распространяется на уверенность."

Date-room corridor:
"РОМАНТИЧЕСКИЙ СЕКТОР
Индивидуальный учёт прекращается после десятой комнаты."
```

---

# 76. PRODUCTION FLAVOR — EXACT ONE

```text
World map:
"КАРТА ЗЕМЛИ
Свободное место постепенно перестаёт быть географическим понятием."
```

---

# 77. FINAL FLAVOR — EXACT ONE

```text
Final table:
"СТОЛ
После планетарной автоматизации всё снова свелось к двум стульям."
```

---

# 78. SCENIC GAGS — EXACT TWELVE

Add at least12 no-reward staged visual gags.

No new simulation.

1. Apartment:
```text
three identical planning notes near phone, only headings differ
```

2. City:
```text
bus stop sign with tiny "Ожидание не ускоряет событие"
```

3. City:
```text
two arrows pointing opposite directions both labelled "ЦЕНТР"
```

4. Cafe:
```text
one table leg visibly stabilized by a folded menu
```

5. Cafe:
```text
display cake labelled "ПОСЛЕДНИЙ" even after scene reload
```

6. Gym:
```text
one tiny dumbbell on an excessively large dedicated rack
```

7. Appearance:
```text
mannequin facing another mannequin as if in formal negotiation
```

8. Salary Mine:
```text
salary conveyor ends directly next to a tiny office calculator
```

9. Laboratory:
```text
clone output arrow points to "ЧЕЛОВЕК ГОТОВ"
```

10. Laboratory:
```text
date rooms use bureaucratic numbered plates 01..10
```

11. Production Area:
```text
shipping board begins with "ЧЕЛОВЕК — 1 ШТ." and scales absurdly
```

12. Final:
```text
ordinary café-style napkin holder on the impossible final table
```

No same major gag repeated.

---

# 79. NPC VISUAL VARIATION — ORDINARY WOMEN

Across 16 ordinary girls:

At minimum ensure no more than:

```text
3 girls
```

share the exact same combination of:

```text
hair/accessory
outfit variation/material
silhouette scale/pose
```

Use current/donor assets.

Allowed:
- material variation;
- hair variation;
- glasses/headwear;
- jacket/skirt/pants variation;
- small scale/proportion variation within reasonable range;
- staged prop.

Do NOT make unique base meshes.

---

# 80. NPC VISUAL VARIATION — ORDINARY MEN

Across 12 ordinary rivals:

No more than3 share identical visual combination.

Keep same male face/body canon.

Variation:
- clothes;
- hair;
- accessories;
- proportions;
- pose;
- staged prop.

---

# 81. STORY CHARACTERS REMAIN MORE DISTINCT

Story/final appearances should visually remain more recognizable than ordinary NPCs.

Do not use a new ordinary profile that is effectively identical to:

```text
President
Scientist
Editor
Final Target
```

---

# 82. LATE INCREMENTAL CONTENT — NO NEW UPGRADE TRACKS

TECH_PLAN says:

```text
late incremental improvements
```

Interpretation in MODULE25:

complete authored presentation for existing:

```text
3 local clone upgrades
3 global upgrades
```

Do NOT add seventh track.

No new formulas.

---

# 83. LOCAL UPGRADE VISUAL TIERS

Existing levels:

```text
0..5
```

Add presentation-only tier cues in laboratory.

## PRODUCTION_SPEED

Visible equipment:

```text
level0: one clone chamber
level1: extra cooling pipe
level2: second status panel
level3: overhead cable bundle
level4: additional emitter frame
level5: sign "ПЕЧАТЬ ЧЕЛОВЕКА: СЕРИЙНАЯ"
```

## WORK_EFFICIENCY

```text
level0: basic work-exit sign
level1: clipboard
level2: time-board
level3: contract stack
level4: stamped route board
level5: sign "РАБОТА РАСПРЕДЕЛЯЕТСЯ АВТОМАТИЧЕСКИ"
```

## DATING_EFFICIENCY

```text
level0: basic date corridor
level1: numbered queue board
level2: extra flowers/neutral props
level3: scheduling display
level4: "СЛЕДУЮЩИЙ" light
level5: sign "РОМАНТИЧЕСКИЙ КОНВЕЙЕР: НОРМА"
```

Pure visual.

---

# 84. LOCAL UPGRADE VISUAL COMPONENT

Allowed one local component:

```text
UpgradeLevelVisual
```

Exports:

```text
upgrade_type
minimum_level
```

Reads GameState existing upgrade level.

Event-driven on:

```text
clone_upgrade_changed
state_restored
```

No GameState mutation.

No save state.

If existing visual helper can do this, reuse it.

---

# 85. GLOBAL UPGRADE VISUAL TIERS

Existing levels:

```text
0..3
```

Production Area presentation-only.

## GLOBAL_PRODUCTION

```text
1: second route line lights
2: world-map manufacturing arrows
3: board "ЛОКАЛЬНОЕ ПРОИЗВОДСТВО ОТМЕНЕНО"
```

## GLOBAL_WORK

```text
1: contract rack
2: international contract stack
3: board "РАБОТА: ПЛАНЕТАРНЫЙ УРОВЕНЬ"
```

## GLOBAL_DATING

```text
1: extra route arrows
2: international queue board
3: board "СВИДАНИЯ: ГЛОБАЛЬНЫЙ ПОТОК"
```

No new multiplier.

---

# 86. SAVE SCHEMA V1 COMPATIBILITY

MODULE25 is additive content.

Do NOT add new required persistent fields.

Therefore:

```text
SAVE_SCHEMA_VERSION stays 1
```

Existing Module24 saves must load.

Unknown historical IDs policy already handles removed IDs.

No migration.

---

# 87. CONTENT CATALOG TOTALS AFTER MODULE25

Exact expected:

```text
primary traits        4
secondary traits      4
competitions          4
perks                 32
locations             9
stages                8

girls                 23
  ordinary            16
  story/final          7

rivals                19
  ordinary            12
  Earth story          5
  final exhibition     2

discovery situations  22
```

Dating central events:

```text
existing >=34
+16 ordinary signature
+12 new cafe common
--------------------------------
>=62 production central events
```

---

# 88. ORDINARY TRAIT MATRIX VALIDATION

Automated content test must build:

```text
(primary_trait, secondary_trait)
```

for all ordinary girls.

Expected:

```text
16 unique pairs
```

and exact complete Cartesian product:

```text
4×4
```

No duplicate/missing pair.

Story/final girls excluded.

---

# 89. ORDINARY GIRL COMPLETENESS TEST

Every ordinary girl must have:

```text
valid appearance
valid discovery
required XP0..4
>=2 dating pools:
  cafe common
  own signature pool
valid greetings
valid farewell
3 clue notes
nonempty speech_style_note
```

Existing ordinary girls must be upgraded to the same standard.

---

# 90. SIGNATURE POOL TEST

Exactly:

```text
16 signature pools
16 signature events
```

One per ordinary girl.

Each signature pool contains exactly one signature event.

No signature event shared by two girls.

---

# 91. COMMON POOL TEST

`date_pool_cafe_common`:

```text
exactly24 central events
```

or, if current pool contains a different actual number than12 at implementation start:

Cursor must preserve all existing and add the exact 12 specified here.

Final count should be:

```text
previous +12
```

Do not delete old content merely to hit24 if repository changed.

---

# 92. DATE FEASIBILITY TEST

For every ordinary trait combination:

Use available common+signature+farewell content to prove:

```text
at least one possible +5 first date
```

without requiring characteristic level >0.

Important:

Actions can have characteristics for secondary tracking while:

```text
required_level = 0
```

A new ordinary girl must never be impossible to perfect because her content lacks positive primary tags.

---

# 93. NEGATIVE ROUTE TEST

Every ordinary girl must also have:

```text
at least one feasible date route <=0
```

and for all four primary traits, common content must include disliked tags.

No girl should be positive-only.

---

# 94. SECONDARY TRAIT COVERAGE

Across available content, each secondary must be realistically triggerable both directions:

SCANDALOUS:
```text
public conflict route exists
quiet route exists
```

CONSISTENT:
```text
3/4 same-characteristic feasible
4 different feasible
```

VARIETY:
```text
>=3 different feasible
one characteristic >=3 feasible
```

DEMANDING:
```text
clean >=2 positive feasible
>=2 negative feasible
```

---

# 95. REPEAT-DATE VARIETY

For an ordinary girl:

simulate:

```text
5 consecutive dates
```

with cooldown bypass only in test.

Planner must not violate:

```text
no duplicate event ID same evening
no three same category
last-date exclusion/current-cycle behavior
```

New common/signature content should increase variety, not alter planner rules.

---

# 96. PHYSICAL NPC COLLISION / PLACEMENT TEST

All new 9 girls +5 rivals:

- do not overlap transitions;
- do not overlap other character collision;
- interact ray can reach them;
- no spawn inside wall;
- public gates behave like existing ordinary NPCs;
- defeated ordinary rivals disappear normally;
- failed-discovery girl retry visibility follows existing system.

---

# 97. MEDIA / OVERLOAD CONTENT TEST

At Stage4:

existing first7 incoming priority remains exactly unchanged.

After enough candidate iteration:

new girls appear in appended order.

No duplicate active demand ID.

No Media threshold change.

---

# 98. FLAVOR TEST

Exactly >=24 flavor interactions.

They:

```text
never alter Money/Auth/XP/UP/relationship/Story
```

Repeated use simply repeats text.

No save field.

---

# 99. SCENIC GAG TEST

At least12 physical gags visibly exist.

They are presentation-only.

No scripted reward.

No new autoload.

---

# 100. INCREMENTAL VISUAL TIER TEST

Change existing local upgrade levels:

```text
0→5
```

Expected presentation props appear at defined thresholds.

Rates/formulas unchanged.

Same global0→3.

No node count scales with clone total.

---

# 101. COPY QUALITY RULES

Final content pass searches for:

```text
TODO
PLACEHOLDER
TEST
DEBUG
Lorem
"Girl"
"Rival"
raw enum IDs
technical error IDs
```

in player-facing production content.

Debug/test files excluded.

No player-facing:

```text
girl_city_...
rival_...
STAGE_...
LOCKED_STORY
```

---

# 102. TONE RULES

Maintain GDD humor:

```text
seriousness toward nonsense
world accepts absurd rules
hero remains pathologically confident
```

Avoid:
- joke explanation;
- narrator saying “это абсурдно”;
- meme every line;
- cruelty toward women as joke;
- same joke template repeatedly.

Approx content tone target:

```text
70% timeless absurdity
20% contemporary internet/social texture
10% direct current meme energy
```

Do not force references to 2026 brands/events.

---

# 103. INTERACTIVE TEXT LENGTH

Flavor:

```text
1–2 short lines
```

Discovery result:

```text
1 concise reaction
```

Dating action label:

```text
one readable sentence
```

Do not turn small interactions into dialogue walls.

---

# 104. NO NEW STORY REWARDS

Content additions do NOT:

- grant new feature unlocks;
- change Authority rewards;
- add new Experience types;
- change Reach;
- change stage completion.

Story remains exactly Modules11–21.

---

# 105. NO NEW ECONOMY VALUES

Do NOT tune:
- salary;
- clone rates;
- costs;
- perk costs;
- rival reward values already existing;
- late multiplier formulas.

New ordinary rivals need their specified stats/rewards because they are new content.

All existing balance waits for MODULE26.

---

# 106. MANUAL CONTENT INVENTORY

Create canonical:

```text
docs/content/MANUAL_CONTENT_COMPLETE.md
```

Table inventory:

```text
all23 girls
all19 rivals
all22 discovery situations
all dating pools/events
all greetings/farewells
24+ flavor interactions
12+ scenic gags
appearance profiles
late visual tiers
```

Mark:

```text
Story
Ordinary
Final
```

---

# 107. UPDATE GDD REALIZATION NOTES

Update:

```text
docs/gdd/05_girls.md
docs/gdd/06_dating.md
docs/gdd/08_locations_ui_content.md
```

Implementation note after Module25:

```text
16 ordinary girls cover complete 4×4 trait matrix
23 total production girls
19 total rivals
>=62 central dating events
content completion locked before balance pass
```

---

# 108. PROJECT STRUCTURE

Update:

```text
docs/PROJECT_STRUCTURE.md
```

to:

```text
after MODULE25 — Content Completion
```

Catalog counts exact.

Persistence remains:

```text
schema v1
```

---

# 109. SAVE COMPATIBILITY TEST

Take a valid Module24 schema-v1 fixture/save containing only old14 girls.

Load under Module25.

Expected:

```text
loads successfully
new content simply not present in historical state
```

Then encounter/conquer one new girl, save/reload.

New ID persists normally under same schema.

---

# 110. FULL CONTENT WALKTHROUGH

Manual production F5/content pass.

No need to conquer all16 ordinary girls in one mandatory story route.

But tester should visit:

```text
city_hub
cafe
gym
appearance_space
```

and verify all new fixed situations.

Sample at least:

```text
4 new girls
2 new rivals
6 new common events
4 signature events
all flavor locations
late visual upgrade tiers
```

Then full main story still reaches ending.

---

# 111. TARGET GAMEPLAY RELATION TO ORDINARY CONTENT

Ordinary girls/rivals remain:

```text
optional systemic content
```

They provide:
- alternate XP;
- alternate Authority;
- different trait tests;
- replay variety;
- Media/Overload variety.

Main story must NOT suddenly require conquering all16.

MODULE26 will decide whether any gate pacing needs tuning.

---

# 112. NO CONTENT RANDOM SPAWN SYSTEM

All ordinary girls remain fixed staged situations.

All ordinary rivals fixed physical spots.

No procedural NPC pool.

---

# 113. DONOR USE

Cursor may audit/copy from:

```text
../date_factory_legacy
legacy-v1
```

for:
- clothing;
- props;
- scene decoration;
- text inspiration only if still fits new GDD.

Do NOT copy:
- old progression logic;
- old dating systems;
- old managers;
- old save system.

Donor READ-ONLY.

---

# 114. DEFINITION OF DONE

MODULE25 complete only if:

- [ ] production girls exact23;
- [ ] ordinary girls exact16;
- [ ] story/final girls remain7;
- [ ] all16 ordinary primary×secondary pairs are unique and complete 4×4 matrix;
- [ ] 9 specified new ordinary girls exist;
- [ ] each new girl has exact identity/traits/XP/discovery/appearance;
- [ ] all16 ordinary girls have valid fixed discovery situation;
- [ ] all16 ordinary girls have 3 clues + speech style;
- [ ] all16 ordinary girls have common cafe pool + personal signature pool;
- [ ] exactly16 ordinary signature events/pools;
- [ ] 7 existing ordinary girls receive specified signature events;
- [ ] 9 new girls receive specified signature events;
- [ ] exactly12 new cafe common events added;
- [ ] common category distribution new content 4/4/4;
- [ ] 4 new greetings added;
- [ ] 3 new ordinary farewell definitions added;
- [ ] ordinary farewells distributed across16 girls;
- [ ] every ordinary girl has a feasible +5 route;
- [ ] every ordinary girl has a non-positive route;
- [ ] all secondary positive/negative conditions feasible;
- [ ] repeat-date planner rules unchanged and tested;
- [ ] rivals exact19;
- [ ] ordinary rivals exact12;
- [ ] 5 specified new ordinary rivals exist;
- [ ] no new story rivals;
- [ ] each new rival has physical production placement;
- [ ] no new rival is story-required;
- [ ] Media candidate list preserves old7 prefix + appends new9 exact order;
- [ ] discovery situations exact22;
- [ ] new NPC appearance profiles exist;
- [ ] ordinary visual variation pass completed;
- [ ] no >3 ordinary girls share exact same visual combination;
- [ ] ordinary male visual variation pass completed;
- [ ] >=24 flavor interactions;
- [ ] exact minimum per-location flavor distribution;
- [ ] flavor interactions mutate no gameplay;
- [ ] >=12 scenic gags;
- [ ] all gags are presentation-only;
- [ ] local upgrade levels0..5 have authored visual tiers;
- [ ] global upgrade levels0..3 have authored visual tiers;
- [ ] no new upgrade tracks/formulas;
- [ ] story characters/copy audited but mechanics unchanged;
- [ ] player-facing TODO/debug/raw IDs removed;
- [ ] central dating event production total >=62;
- [ ] SAVE_SCHEMA_VERSION remains1;
- [ ] old Module24 save fixture loads;
- [ ] new content IDs save/load correctly;
- [ ] content inventory document complete;
- [ ] GDD/project docs updated;
- [ ] full main story still reaches ending;
- [ ] all MODULE02–24 regressions PASS;
- [ ] no MODULE26 balance tuning implemented ahead.

---

# 115. RECOMMENDED CURSOR ORDER

```text
1. Audit current catalog and generate machine-readable content inventory.
2. Add 9 girls + appearances + 9 fixed discovery situations.
3. Place all 9 physical GirlActors in existing locations.
4. Add 9 missing trait-matrix validation test.
5. Add 16 signature event resources + 16 one-event pools; wire existing7 + new9.
6. Add 12 cafe-common events and category coverage tests.
7. Add4 greetings +3 farewells; distribute ordinary girls.
8. Add5 ordinary rivals + appearances + physical placements.
9. Append new9 to Media candidate priority after old7.
10. Add24+ flavor interactions and12 scenic gags.
11. Add presentation-only local/global upgrade visual tiers.
12. Run story-girl/rival/copy placeholder audit.
13. Run all content feasibility/planner tests.
14. Validate Module24 schema-v1 old save + new-ID roundtrip.
15. Manual content walkthrough + full story F5.
16. Update MANUAL_CONTENT_COMPLETE/GDD/PROJECT_STRUCTURE.
17. All regressions.
```

---

# 116. CURSOR FINAL REPORT

## Catalog totals

Confirm exact:

```text
23 girls
16 ordinary = complete4×4 trait matrix
19 rivals
12 ordinary
22 discovery situations
>=62 central dating events
```

## New girls

List all9 with:
```text
traits
XP
location
appearance
discovery
signature event
```

## Existing ordinary girls

Confirm all7 received a signature event/pool.

## Dating content

Confirm:
```text
+12 common events
+4 greetings
+3 farewells
```

and demonstrate:
```text
+5 feasibility
negative routes
secondary coverage
repeat planner
```

## Rivals

List five new rivals, stats/competitions/location.

## World flavor

Inventory:
```text
24+ flavor interactions
12+ staged gags
visual NPC variation
```

## Late content

Show presentation tiers for:
```text
3 local upgrade tracks
3 global tracks
```

Prove formulas unchanged.

## Save compatibility

Show:
```text
schema v1 unchanged
old Module24 save loads
new content IDs roundtrip
```

## Full F5

Confirm main story still reaches ending without requiring new optional content.

## Regressions

All MODULE02–24 suites.

## Commit

SHA.

Then STOP. Do not begin MODULE26.
