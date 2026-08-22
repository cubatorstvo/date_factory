# Story Stage Progression — Stage 1–4

**Статус:** канонический roster и gameplay-ось первых четырёх Story Stages  
**Текущий продукт:** Date System Lab  
**Связанные документы:** [`DATE_SYSTEM_LAB.md`](DATE_SYSTEM_LAB.md), [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md)

Этот файл — source of truth для вопроса:

> Какие filler, Story Girl, ordinary rivals и Story Rival принадлежат каждому Story Stage 1–4, и чем Story Stage отличается от City Stage?

Обучающий контракт систем (DateVenue, Outfit, Apartment Tags) остаётся в [`PROGRESSION_STAGES.md`](PROGRESSION_STAGES.md). Runtime должен читать roster из `StageDefinition` / `StageCatalog`.

---

## 1. Каркас каждого Stage 1–4

```text
3 filler girls
→ MAX любых 2 из 3
→ Story Girl становится доступна по Stage + Rating + current-stage filler progress
→ знакомство со Story Girl
→ Story Rival становится активным
→ победа над Story Rival
→ свидания со Story Girl
→ Story Girl MAX
→ следующий Story Stage
```

Третья filler girl каждого Stage — optional content: даёт Rating и уникальную награду, но не заменяет current-stage `2 из 3`.

Story Stage — канонический источник gameplay progression.

City Stage — канонический источник физического раскрытия 3D-города.

---

## 2. Canonical Stage roster

### Stage 1 — Foundations

| Роль | Состав |
|---|---|
| Filler | Alina, Vika, Dasha |
| Story Girl | Actress |
| Ordinary Rivals | Gleb — Турник, Max — Фотомодель |
| Story Rival | Boris — каскадёр |
| Rating gate | `>= 2` |
| Current-stage filler | `2 / 3` MAX |
| Completion | Actress relationship = MAX |

### Stage 2 — Choice

| Роль | Состав |
|---|---|
| Filler | Marina, Katya, Lera |
| Story Girl | Mine Boss |
| Ordinary Rivals | Denis — Криптоэксперт, Roman — Ведущий |
| Story Rival | Foreman / Аркадий |
| Rating gate | `>= 5` |
| Current-stage filler | `2 / 3` MAX |
| Completion | Mine Boss relationship = MAX |

Stage 2 сохраняет onboarding-цель «Приоденься», пока нет Dressed Outfit.

### Stage 3 — Synergy

| Роль | Состав |
|---|---|
| Filler | Kira, Olya, Sonya |
| Story Girl | Magazine Editor |
| Ordinary Rivals | Lev — Уличный атлет, Timur — Магнат |
| Story Rival | Columnist / Герман |
| Rating gate | `>= 8` |
| Current-stage filler | `2 / 3` MAX |
| Completion | Magazine Editor relationship = MAX |

### Stage 4 — Mastery

| Роль | Состав |
|---|---|
| Filler | Nika, Rita, Eva |
| Story Girl | Scientist |
| Ordinary Rivals | empty |
| Story Rival | Academic / Академик Павел |
| Rating gate | `>= 11` |
| Current-stage filler | `2 / 3` MAX |
| Completion | Scientist relationship = MAX |

---

## 3. Story Girl access

Story Girl access проверяет два независимых значения:

```text
global Rating threshold
+
MAX count among the three filler girls assigned to this Story Stage
```

| Story Stage | Story Girl | Rating | Current-stage filler MAX |
|---|---|---:|---:|
| 1 | Actress | 2 | 2 / 3 |
| 2 | Mine Boss | 5 | 2 / 3 |
| 3 | Magazine Editor | 8 | 2 / 3 |
| 4 | Scientist | 11 | 2 / 3 |

Каждая Story Girl также требует minimum Story Stage. Outfit выше Casual остаётся Date requirement для Story Girls с Stage 2.

Optional MAX третьей filler прошлых Stage повышает Rating, но не закрывает current-stage `2 из 3`.

Player-facing unmet filler gate:

```text
Девушки этапа: N / 2
```

---

## 4. Rating baseline

Маршрут ровно двух filler на Stage:

```text
Stage 1: 2 filler MAX → Rating 2 → Actress MAX → Rating 3
Stage 2: 2 filler MAX → Rating 5 → Mine Boss MAX → Rating 6
Stage 3: 2 filler MAX → Rating 8 → Editor MAX → Rating 9
Stage 4: 2 filler MAX → Rating 11 → Scientist MAX → Rating 12
```

Stage 5 President сохраняет Rating `12`. После Scientist MAX baseline-маршрут уже даёт `12`; оставшиеся filler и Factory Rating остаются optional surplus.

---

## 5. Story Stage vs City Stage

Story Stage управляет:

```text
girl availability
Rival availability
Outfit availability
Apartment Object availability
DateVenue gameplay availability
Store inventory progression
Stage objectives
Story Girl access
Factory progression
```

City Stage управляет:

```text
3D city zones
building/world visibility
physical navigation availability
world presentation
```

City Stage не является gameplay-требованием для girls, rivals, Outfit, Apartment Objects или DateVenue.

Канонический mapping:

```text
Story Stage 1 → City Stage 1
Story Stage 2 → City Stage 2
Story Stage 3 → City Stage 2
Story Stage 4 → City Stage 3
Story Stage 5+ → City Stage 3
```

Stage 3 полностью работает при City Stage 2: Restaurant DateVenue, Stage 3 Outfit, Stage 3 Apartment Objects, Kira / Olya / Sonya, Lev / Timur.

---

## 6. Stage enter effects

### Stage 1

```text
City Stage 1
Apartment DateVenue
Casual Outfit
```

### Stage 2

```text
City Stage = 2
unlock Clothing Store, Furniture Store, Leisure Center, Restaurant building
unlock DateVenue Café, Leisure Center
unlock Stage 2 Outfit / Apartment Object inventory
activate «Приоденься»
```

Restaurant building существует физически со Stage 2. Restaurant как DateVenue открывается на Stage 3.

### Stage 3

```text
City Stage остаётся 2
unlock Restaurant DateVenue
unlock Stage 3 Outfit / Apartment Object inventory
```

### Stage 4

```text
City Stage = 3
unlock Stage 4 Outfit / Apartment Object inventory
```

---

## 7. Gameplay availability читает Story Stage

| Домен | Stage 1 | Stage 2 | Stage 3 | Stage 4 |
|---|---|---|---|---|
| DateVenue | Apartment | + Café, Leisure Center | + Restaurant | тот же набор |
| Outfit | Casual | four stat-only | first four thematic + Moves | late four thematic + Moves |
| Apartment Objects | 0 / 12 | first 4 | next 4 | final 4 |
| Filler | Alina, Vika, Dasha | Marina, Katya, Lera | Kira, Olya, Sonya | Nika, Rita, Eva |
| Ordinary Rivals | Gleb, Max | Denis, Roman | Lev, Timur | none |

Filler и ordinary rivals используют `minimum Story Stage`. Story Rival активен, когда `current Story Stage >= assigned Stage`, linked Story Girl discovered и rival ещё не побеждён.

---

## 8. StageDefinition roster fields

`StageDefinition` хранит:

```text
stage
display_name
filler_girl_ids
story_girl_id
ordinary_rival_ids
story_rival_id
required_filler_max_count
story_girl_required_rating
completion_requirement
on_enter_effects
objective_title
objective_description
```

Для Stage 1–4:

```text
exactly 3 filler_girl_ids
exactly 1 story_girl_id
required_filler_max_count = 2
exactly 1 story_rival_id
ordinary rivals: 2 / 2 / 2 / 0
```

12 filler girls принадлежат ровно одному Stage 1–4. Story Girls Stage 1–4: Actress, Mine Boss, Magazine Editor, Scientist. Story Rival links: Boris → Actress, Foreman → Mine Boss, Columnist → Magazine Editor, Academic → Scientist.

---

## 9. Objectives

Filler phase:

```text
Повышай Рейтинг
Заверши отношения с любыми 2 из 3 девушек этого этапа.
Девушки этапа: N / 2
Рейтинг: X / Y
```

Затем: `Познакомься с <Story Girl>.` → `Победи <Story Rival>.` → `Отношения с <Story Girl>: X / MAX`.

Stage 2 сохраняет «Приоденься» как текущую цель, пока нет Dressed Outfit.
