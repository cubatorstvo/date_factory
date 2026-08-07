# ACCEPTANCE — MODULE 14A Early Vertical Slice

## Player-visible result

Clean F5 (no debug setters): apartment Neighbor → contact → apartment date → +5 → STAGE_1 → Appearance Space rival_actress win → Actress contact → cafe date → +5 → STAGE_2 → city mine entrance rival_mine_boss → Mine Boss → cafe date → +5 → STAGE_3 → Salary Mine → claim first salary.

## PASS criteria

- 7 girls, 6 rivals, appearances, 7 discovery situations, apartment≥6 + cafe≥12 dating events, 4 greetings, 1 farewell
- RivalActor shows CharacterActor; defeated leave and stay gone
- StageActorAnchor stage-gated, no `_process`
- Story lock / low Authority feedback visible
- GirlDefinition date binding validated
- DateVenue in apartment + cafe; ProgressionInteractable in apartment; Phone day/money/authority/XP/UP + Story section
- ContentDB.validate_all() PASS
- Story +5 routes feasible; Money=0 softlock-safe
- MODULE 02–13 regressions PASS; no 14B/15 ahead

## Verdict

`READY` or `NOT READY` only.
