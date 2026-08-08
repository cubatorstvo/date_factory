# File ownership — MODULE 24 FIX prevalidate runtime

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M24_FIX_RUNTIME | orchestrator | `game/clone_incremental/clone_incremental.gd`, `persistence/save_system.gd`, `persistence/test/save_system_self_test.gd`, docs | MODULE25 | done |
| M24_FIX_QA | df-qa-worker | `docs/agent/qa/M24_FIX_QA.md`, `tmp/m24_fix_qa/**` | product code | done |

## Product decision
Prevalidate CloneIncremental runtime (pure normalize) inside SaveSystem `_read_validate_payload` before any GameState mutation. No transactional rollback engine.
