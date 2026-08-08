# File ownership — MODULE 16 Dating Overload

| Task | Agent | Writable | Forbidden | Status |
|------|-------|----------|-----------|--------|
| M16_A_CORE | gameplay-worker | GameState overload, dating_overload/**, Relationships gate, DateVenue, project.godot, tests | Phone, MODULE 17 | done |
| M16_B_PHONE_DOCS | gameplay-worker | phone_journal Overload + docs | DatingOverload math, MODULE 17 | done |
| M16_C_QA | qa-worker | evidence only | product sources | done |

## Product decisions
1. DatingOverload after Media; no _process.
2. Capacity gate in Relationships.start_date_with_history.
3. Consume on completed date only.
4. Demand from Media offers cycle; 19:00/20:00 presentation only.
5. Recognition: day>=start+2, generated>=7, backlog>=4, personal_dates>=1.
6. STOP — no MODULE 17.
