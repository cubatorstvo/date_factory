# Current milestone

## ID
`EVENT-COOLDOWN-011`

## Product goal
Не допускать спама любых автоматических event-popup, включая последствия клонов.

## Player-visible result
После любого показанного event UI (catalog или runtime) следующий автоматический popup не раньше 10 игровых минут. Очередь deferred clone consequences сохраняется и срабатывает позже. Игрок-инициированные окна (запись свидания в телефоне) открываются сразу.

## Status
`READY`

## In scope
- Shared 10 game-minute stamp for catalog + auto runtime opens.
- Clone `deferred_hits` pause due while gated.
- Player-initiated phone booking still immediate, but stamps.
- Save/load of stamp + deferred queue.

## Out of scope
- Event content/probabilities.
- TimeAPI redesign.
- Homeware apartment interact (separate task APT-HOMEWARE-SHOP-001).

## Dependencies
- EVENT-COOLDOWN-010 shared stamp pattern.
- Clones deferred_hits.

## Active tasks

| Task | Agent | Status | Evidence |
|---|---|---|---|
| EVENT-COOLDOWN-011 | df-gameplay-worker | COMPLETED | code diff + 9/10 deferred probes |
| EVENT-COOLDOWN-011-QA | df-qa-worker | COMPLETED | `docs/agent/qa/EVENT-COOLDOWN-011_QA.md` — PASS/READY |
| APT-HOMEWARE-SHOP-001 | df-gameplay-worker | COMPLETED | apartment «Посуда» removed; street shop remains |

## Blocking issues
- Нет.

## Next acceptance action
- Milestone принят. Невидимая квартирная «Посуда» убрана.
