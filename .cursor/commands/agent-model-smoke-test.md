Проверь custom subagents DATE FACTORY.

Последовательно вызови:

- df-researcher;
- df-gameplay-worker;
- df-scene-worker;
- df-asset-worker;
- df-content-worker;
- df-qa-worker.

Безопасная задача каждому:

`Не изменяй файлы. Верни своё имя, назначение, конфигурационное значение model и MODEL_SMOKE_TEST_OK.`

Проверить:

- agent обнаруживается;
- YAML корректен;
- `model` настроен на Cursor Grok 4.5;
- agent не меняет файлы;
- agent не запускает subagents.

Если runtime metadata показывает другую модель:

- не начинать milestone;
- записать mismatch;
- попросить пользователя открыть `.cursor/agents/<agent>.md` в subagent editor и выбрать Cursor Grok 4.5;
- повторить smoke-test.

Текстовое заявление worker не заменяет runtime metadata Cursor.
