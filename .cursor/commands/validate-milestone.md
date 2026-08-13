Проведи приёмку текущего DATE FACTORY v2 milestone по коду и diff. Пользователь сам проверяет игру.

1. Прочитай `docs/README.md` и, если есть, `docs/agent/ACCEPTANCE.md` / `docs/MASTER_GDD.md`.
2. Получи Git diff.
3. Определи normal player route.
4. Не вызывай `df-qa-worker`, не запускай игру, не открывай screenshots.
5. Перечисли Blocking risks, WARNING и что должно работать.
6. Финальный статус только READY или NOT READY по коду, не по playtest.

Не использовать `READY WITH LIMITATIONS` при critical FAIL.
Не считать наличие legacy-кода в donor доказательством готовности v2.
