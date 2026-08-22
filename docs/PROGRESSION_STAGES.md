# Stage 1–4 Progression Contract

**Статус:** канон high-level progression первых четырёх Stages  
**Текущий продукт:** Date System Lab  
**Связанные документы:** [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md), [`MASTER_GDD.md`](MASTER_GDD.md)

Этот файл — source of truth для вопроса:

> Что игрок изучает, получает и осваивает на каждом из Stage 1–4?

Runtime, seed-контент и UI должны следовать этой модели. Точные объекты мест, тексты Local Moves и цены Apartment Objects задаёт отдельный design block `Venues & Local Objects`; до его появления детали ниже помечены как отложенные.

---

## 1. Общий принцип progression

Обучающая дуга первых четырёх Stages:

| Stage | Роль | Главный вопрос игрока |
|---|---|---|
| Stage 1 — Foundations | освоить основной цикл | «Что вообще можно делать в этой игре?» |
| Stage 2 — Choice | получить первые meaningful choices подготовки | «Как подготовиться именно к этой девушке?» |
| Stage 3 — Synergy | начать сочетать освоенные системы | «Как собрать несколько преимуществ вместе?» |
| Stage 4 — Mastery | использовать полный ручной инструментарий | «Как максимально эффективно использовать всё, что я уже освоил?» |

Pacing:

```text
Stage 1 = fundamentals
Stage 2 = horizontal choice
Stage 3 = system synergy
Stage 4 = mastery
Stage 5 = Factory introduction
```

Каждый следующий Stage опирается на уже понятные игроку системы предыдущего.

Каноническая модель в одну строку:

```text
Stage 1 = Apartment / fundamentals
Stage 2 = Apartment + Café + Leisure / Local + basic Outfit
Stage 3 = + Restaurant / Outfit Moves / synergy
Stage 4 = mastery / 12-Tag Apartment
```

Story Stage 1–6 и City Stage 1–3 остаются runtime-слоями кампании из [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md). Этот документ задаёт **обучающий и системный** контракт Stage 1–4: какие Date systems, DateVenues, Outfit-слой и Apartment Local coverage открываются игроку.

---

## 2. Stage 1 — Foundations

### Цель Stage

Игрок осваивает фундаментальный ручной gameplay loop.

Основные системы Stage 1:

```text
day / time
work / salary
money
girls
dating
BASE Moves
Characteristic Moves
Tags / preference discovery
Relationship
Rating
characteristics
Daily Activity
Rivals
Apartment preparation
first Story Girl
```

Stage 1 обучает базовым правилам игры и базовым видам активности.

### DateVenue

На Stage 1 используется один DateVenue:

```text
Apartment
```

Apartment выполняет сразу две функции:

1. является первым местом свиданий;
2. знакомит игрока с бытовой simulator-частью подготовки свидания.

Перед свиданием Apartment требует подготовки.

В будущей 3D presentation эта подготовка выражается через простые физические действия героя в квартире: привести пространство в порядок, подготовить стол и выполнить другие короткие бытовые действия.

Кафе как **мировая** локация знакомства (Вика, Даша) может быть открыто на Stage 1. Кафе как **DateVenue** открывается только на Stage 2.

### Date build

На Stage 1 активный набор инструментов:

```text
BASE Moves
Characteristic Source
```

Apartment на Stage 1 имеет:

```text
0 Local Moves
```

Local Source появляется позже вместе с Stage 2.

### Outfit

Stage 1 использует базовый образ:

```text
Casual / Повседневный
```

Outfit как отдельный build-layer появляется на Stage 2.

### Characters

Марина относится к Stage 2.

Stage 1 filler pool строится вокруг наград, которые усиливают уже понятные фундаментальные системы:

```text
Алина
Вика
Даша
```

Первая Story Girl:

```text
Actress
```

---

## 3. Stage 2 — Choice

### Цель Stage

Stage 2 расширяет город и впервые вводит лёгкий buildcraft.

Игрок уже понимает основной цикл и начинает выбирать:

```text
куда пригласить девушку
какой Outfit использовать
какие Apartment Tags купить
какие известные предпочтения девушки использовать
```

Главное ощущение:

> Теперь несколько подготовок могут привести к одному и тому же свиданию, и игрок выбирает подходящую.

### DateVenue

На Stage 2 доступны:

```text
Apartment
Café
Leisure Center
```

Именно на Stage 2 появляется:

```text
Venue / Local Source
```

### Outfit

Stage 2 вводит Clothing Store и Outfit system.

Первые Stage 2 Outfits дают простой понятный эффект:

```text
+1 к одной характеристике
```

Outfit Moves становятся следующим уровнем системы и появляются на Stage 3.

### Secondary objective — «Приоденься»

В начале Stage 2 появляется secondary objective:

## Приоденься

```text
Купи любой образ выше «Повседневного» в магазине одежды.
```

Hint:

```text
Марина работает в магазине одежды. Хорошие отношения с ней могут оказаться полезны.
```

При попытке начать свидание с Stage 2 girl в Casual используется короткое понятное объяснение по смыслу:

```text
Для этого свидания нужен образ интереснее повседневного.
```

Конкретная реплика девушки может быть персонализирована её характером.

### Social gate

Для девушек, которые становятся доступны начиная со Stage 2, Date eligibility включает требование:

```text
Outfit выше Casual
```

Player-facing смысл:

> повседневный образ героя кажется им слишком скучным для свидания.

Марина является onboarding exception этого правила.

С Мариной можно развивать отношения, оставаясь в Casual.

---

## 4. Stage 3 — Synergy

### Цель Stage

Игрок уже умеет отдельно пользоваться Venue, Outfit, Characteristics и preference knowledge.

Stage 3 учит сочетать эти системы.

Основной gameplay question:

> Какая комбинация уже известных мне инструментов лучше подходит этой девушке?

### DateVenue

На Stage 3 открывается четвёртый и последний основной DateVenue:

```text
Restaurant
```

Полный набор основных DateVenues становится:

```text
Apartment
Café
Leisure Center
Restaurant
```

Restaurant имеет собственную interaction identity, связанную с formal / service / status context.

Точный набор Restaurant Local Objects определяется в `Venues & Local Objects` block.

### Outfit

На Stage 3 появляется следующий слой Outfit system:

```text
Outfit stat bonus
+
Outfit Move
```

Outfit Source становится отдельным инструментом Date build.

### Apartment

К концу Stage 3 Apartment может иметь:

```text
8 / 12 Local Tags
```

Квартира становится полноценным конкурентом фиксированных public Venues по конкретному matchup.

### Gameplay identity

Stage 3 создаёт комбинации вида:

```text
Outfit bonus
→ Characteristic threshold

known positive Tag
→ Venue choice

Girl Trait
→ preferred Characteristic / Venue

Apartment purchases
→ alternative Local coverage
```

Stage 3 строится вокруг synergy уже знакомых правил.

---

## 5. Stage 4 — Mastery

### Цель Stage

Stage 4 завершает развитие ручного Date gameplay.

Игрок получает возможность использовать освоенные системы с высокой эффективностью.

Основной gameplay question:

> Как максимально выгодно использовать полный набор уже знакомых инструментов?

### DateVenues

Используется полный набор:

```text
Apartment
Café
Leisure Center
Restaurant
```

Stage 4 развивает глубину существующего выбора.

### Apartment

К концу Stage 4:

```text
12 / 12 Apartment Local Tags
```

Apartment становится самым универсальным DateVenue по Tag coverage.

### Late rewards

На Stage 4 особенно заметно начинают работать поздние filler rewards и комбинации, которые модифицируют уже известные игроку правила.

Примеры canonical identity:

```text
Katya → one chosen Apartment Local Tag can score +2
Sonya → Restaurant Venue Source can be used twice
Nika → Backup Outfit
Rita → additional same-day Date for $75
Eva → +1 initial known Tag
```

Их роль:

> усиление mastery и вариативности освоенного ручного gameplay.

---

## 6. DateVenue progression

`DateVenue` — место свидания. `LocationDefinition` — физическая локация мира. Одинаковый fiction-place может открываться для визита раньше, чем станет доступным DateVenue.

### Stage availability

| DateVenue | Stage | Роль |
|---|---|---|
| Apartment | 1 | единственное место свиданий; 0 Local Moves; подготовка квартиры |
| Café | 2 | casual public date; low-cost; social / everyday identity; фиксированный Local Object set |
| Leisure Center | 2 | active public date; physical / competitive identity; фиксированный Local Object set; естественный будущий host коротких 3D activities / mini-games |
| Restaurant | 3 | formal / service / status identity; четвёртый и последний основной DateVenue |

Café и Leisure Center дают игроку первый настоящий Venue matchup choice.

### Роли Venue

### Apartment

```text
free
player-developed
starts with no Local coverage
grows through purchased interior objects
```

### Café

```text
casual public date
low-cost
social / everyday interaction identity
fixed Local Object set
```

### Leisure Center

```text
active public date
physical / competitive interaction identity
fixed Local Object set
natural future host for short 3D activities / mini-games
```

### Restaurant

```text
formal / service / status context
fixed Local Object set
late-game matchup with Sonya: Venue Source uses = 2
```

### Late-game Venue asymmetry

Два сильных late-game варианта остаются meaningful choices.

## Apartment

```text
coverage = 12 / 12
Venue Source uses = 1
Katya Accent = selected positive Local Move scores +2
```

Identity:

> универсальность и заранее выбранный усиленный Tag.

## Restaurant + Sonya

```text
fixed Restaurant Tag coverage
Venue Source uses = 2
```

Identity:

> более узкий matchup с возможностью сыграть два разных Local Moves.

Точные Local Objects, Characteristic requirements, цены и authored Situations мест задаёт `Venues & Local Objects` block.

---

## 7. Outfit progression

```text
Stage 1 = Casual / Повседневный
Stage 2 = Clothing Store + stat-only Outfit (+1 к одной характеристике)
Stage 3 = Outfit Moves / Outfit Source
Stage 4 = mastery коллекции и rule-modifying rewards (Ника: Backup Outfit)
```

Универсального `Outfit.score_bonus` нет. `EffectiveStat = min(BaseStat + OutfitStatBonus, 5)`.

Stage 2 предлагает два равноправных пути выполнить objective «Приоденься»:

### Money path

```text
work
→ earn money
→ buy Outfit
```

### Marina path

```text
build relationship with Marina
→ reach MAX
→ choose one eligible Outfit for $0
```

---

## 8. Apartment progression

Apartment является единственным DateVenue, Local coverage которого строит сам игрок.

Каноническая модель:

```text
12 purchasable Apartment Local Objects
12 canonical Tags
1 Object = 1 unique Tag
1 Object = 1 Local Move
```

Все купленные Apartment Objects одновременно участвуют в Local Source.

Каждый из 12 Tags представлен в финально развитой квартире ровно одним объектом.

Apartment Local coverage progression:

```text
Stage 1: 0 / 12
Stage 2: up to 4 / 12
Stage 3: up to 8 / 12
Stage 4: up to 12 / 12
```

Итоговый late-game Apartment:

```text
12 / 12 Tags
Venue Source uses = 1
```

Его основная сила:

> максимальная универсальность Local Source.

Цена предметов растёт параллельно общей экономической progression героя.

Tags остаются механически равноценными; цена отражает Stage экономики, на котором предмет становится доступен.

Подготовка квартиры остаётся отдельным правилом Date Engine: подготовленная квартира `0`, неподготовленная `-1`. Это не Local coverage.

Точный список 12 объектов, их Tags, цены и тексты Local Moves определяется в отдельном `Venues & Local Objects` design block.

---

## 9. Character onboarding tied to progression

### Марина — soft onboarding path одежды

Марина относится к Stage 2.

Марина физически работает в Clothing Store.

В будущей 3D presentation:

```text
player enters clothing store
→ browses outfits
→ Marina is present at the checkout / store interaction point
```

Марина доступна для знакомства и отношений в Casual.

Её MAX reward:

```text
one currently progression-available unowned Outfit from the ordinary store for $0
```

Reward используется через обычный Outfit Store purchase flow.

Марина ускоряет освоение системы одежды и остаётся optional progression path.

### Катя — reward «Акцент интерьера»

Катя связана с Apartment / furniture progression.

После MAX Кати открывается:

```text
Акцент интерьера
```

Игрок назначает один уже купленный Apartment Local Object акцентным.

Для Local Move акцентного объекта:

```text
positive result = +2
negative result = -1
```

Обычный Apartment Local Move:

```text
positive result = +1
negative result = -1
```

## Выбор Accent

Первое назначение Accent входит в reward Кати.

Последующее изменение Accent выполняется через Катю / Furniture Store за заметную денежную стоимость.

Эта стоимость создаёт осмысленное постоянное решение и одновременно позволяет игроку позднее перестроить квартиру.

Точная цена смены Accent определяется вместе с economy balancing.

## Дизайнерская роль reward

Катя улучшает уже купленную игроком квартиру независимо от порядка приобретения предметов.

Late-game identity:

```text
Apartment + Katya
= universal 12-Tag coverage
+ one chosen Local Tag with +2 positive result
```

### Stage 1 filler identity

Алина, Вика и Даша усиливают фундаментальные системы Stage 1 (тренировка, BASE reroll, смягчение первого отрицательного результата). Они не вводят Outfit system и не требуют образа выше Casual.

---

## 10. Transition to Stage 5 / Factory

Stage 4 является пиком ручной половины игры.

К его завершению игрок:

```text
понимает Dating Core
развил характеристики
развил Apartment
имеет Outfit collection
использует Venue matchups
использует Characteristic / Outfit / Venue Sources
понимает Tags девушек
получил несколько rule-modifying filler rewards
```

Следующий high-level progression block:

```text
Stage 5 — Factory Introduction
```

Narrative/gameplay transition:

> игрок уже умеет эффективно выполнять ручной цикл и получает новый слой, который начинает масштабировать и автоматизировать освоенные процессы.

Подробная Factory progression определяется отдельным design block. Runtime-правила фабрики по-прежнему живут в [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md).

---

## Learning-budget contract

Распределение систем по Stage — high-level contract для будущих feature-placement решений.

| System | Stage |
|---|---|
| BASE Moves | 1 |
| Characteristic Source | 1 |
| Work / money / characteristics | 1 |
| Rivals fundamentals | 1 |
| Apartment preparation | 1 |
| Venue choice | 2 |
| Local Source | 2 |
| Apartment Local Objects | 2 |
| Basic stat-only Outfit | 2 |
| Outfit social gate / Marina onboarding | 2 |
| Restaurant | 3 |
| Outfit Moves / Outfit Source | 3 |
| Multi-system synergy | 3 |
| Full 12-Tag Apartment | 4 |
| Late rule-modifying rewards / mastery | 4 |
| Factory | 5+ |

---

## Documentation boundaries

В этом документе зафиксированы high-level progression contracts.

Следующие детали получают отдельную спецификацию в `Venues & Local Objects` block:

```text
точные 12 Apartment Objects
точный Tag каждого Apartment Object
точные Apartment Local Move texts
точные Café Local Objects
точные Leisure Center Local Objects
точные Restaurant Local Objects
Characteristic requirements конкретных Local Moves
конкретные Venue prices
конкретные Apartment object prices
точная цена изменения Interior Accent
Venue-specific authored Situations
```
