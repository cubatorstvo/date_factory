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
- `model` — последняя доступная Cursor Grok, не более старая версия;
- agent не меняет файлы;
- agent не запускает subagents.

Если runtime metadata показывает другую или более старую модель:

- не начинать milestone;
- записать mismatch;
- попросить пользователя открыть `.cursor/agents/<agent>.md` в subagent editor и выбрать последнюю Cursor Grok;
- повторить smoke-test.

Текстовое заявление worker не заменяет runtime metadata Cursor.
