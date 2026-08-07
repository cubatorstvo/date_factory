Проведи независимую приёмку текущего DATE FACTORY v2 milestone.

1. Прочитай `docs/README.md` и, если есть, `docs/agent/ACCEPTANCE.md` / `docs/MASTER_GDD.md`.
2. Получи Git diff.
3. Определи normal player route.
4. Вызови `df-qa-worker`.
5. Проверь real Godot stdout/stderr.
6. Открой evidence screenshots.
7. Проверь save/load, если меняется state.
8. Перечисли Blocking FAIL, WARNING и proven PASS.
9. Финальный статус только READY или NOT READY.

Не использовать `READY WITH LIMITATIONS` при critical FAIL.
Не считать наличие legacy-кода в donor доказательством готовности v2.
