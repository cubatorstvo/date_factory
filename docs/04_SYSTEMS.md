# 04 — Systems

Как системы обслуживают фантазию «один альфа». Колонка **Сейчас** = факт кода на момент дока; **Цель** = мастер-дизайн.

| Система | Роль | Сейчас | Цель |
|---------|------|--------|------|
| Player FPS | Ходьба, взаимодействие, ощущение масштаба | Движение/interact; на свидании Hero mesh за столом | Полный цикл подготовки + кризисы в пространстве |
| Game clock | Общий темп дня | `TimeAPI` + HUD; пауза на активном свидании | Тот же каркас на поздних стадиях |
| Dating schedule | Место + время до старта | Phone book place/time; reminders; grace ±5; home/restaurant | Reschedule UX; больше мест |
| Dating manual | Чтение характера + оценка вечера | 3 фазы + гипотезы; optional mid-date gift; Finish; 5 факторов | Наблюдение → гипотеза → подтверждение; знание ≠ bond (уже); глубже презентация факторов |
| Dating prep (home) | Физическая подготовка | Fridge/drinks → table, homeware, doorbell | Больше вариантов еды/комнат |
| Dating auto | Масштаб через дублей/персонал | Таймеры + `allows_auto_date` / soft penalty | Физически видимые линии; режимы осторожный/стандарт/риск |
| Observations journal | База знаний | Facts / hypotheses / confirmed в girls API + phone | История реакций / уверенность авто полнее в UI |
| Clones | Параллельный «ты» | `create_clone` + ошибки | Сцена + приёмка + дефекты + маршруты |
| Legend integrity | Противовес масштабу | Нет (есть только scandal) | Отдельный ресурс; кризисы при низкой легенде |
| Girls / City | Контакты, тиры, орбита | Bond → claimed; street talk NPCs | Claimed = постоянная орбита в мире + поздние события |
| Phone | Пульт империи | Кандидаты / отношения / schedule book+cancel / апгрейды | + журнал наблюдений, цели, инфраструктура |
| Shops / inventory | Подарки без полок в квартире | `ShopUI` + inventory gifts | Больше витрин/скинов |
| Facility / zones | Видимый рост | `travel_to` home↔city; rooms/venues unlock | Кварталы города; больше indoor-крыльев квартиры |
| Staff | Автоподготовка | Найм + эффекты | Физические точки, представление ролей |
| Events / crises | Инциденты легенды | Карточки с requires | Пространственные кризисы + гейтинг по легенде |
| Economy | Деньги / ⭐ / скандал / внимание | Есть; restaurant date cost | + легенда; скандал ≠ легенда |
| Quests | Направление | Stage 1: book / prep / finish | Стадийная цель + next step |
| Twitch names | Опциональные ники | Локальный пул | Имена на подарках/персонале/партиях в мире |
| Finale | Алгоритм Любви | Упрощённый гейт | Полная последовательность + постгейм |

Код: `autoload/game.gd` + `modules/*`, UI `scenes/ui/*`, мир `scenes/world/*`, контент `core/content_packs*.gd`, `traits_content.gd`.  
Факт по свиданиям/миру Stage 1: [DATING_AND_WORLD.md](DATING_AND_WORLD.md).

Связанные доки: [06](06_TRAITS_AND_BOND.md), [07](07_CLONES_AND_LEGEND.md), [08](08_FPS_AND_CRISES.md), [09](09_PRESENTATION_QA.md).
