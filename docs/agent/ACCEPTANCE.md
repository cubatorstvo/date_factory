# ACCEPTANCE — MODULE 26 Balance / Anti-Grind

## Player-visible result
Story rival loss no longer drains Authority (no ordinary-rival farm to retry). Clean ladder 0→2→4→7→10→15. RC balance constants locked.

## Production changes
Only: Earth story rival loss Authority **−1 → 0** (+ UI stakes copy). No Types retune.

## Evidence
- rival_encounter ALL PASS (183)
- balance_test ALL PASS (30): Pres 269/359/329; Stage6 436/344; Combined 795
- SAVE_SCHEMA v1
- Independent QA: `docs/agent/qa/M26_QA.md` PASS
- Report: `docs/balance/BALANCE_REPORT.md`

## Verdict
**READY**

STOP — do not begin MODULE 27.
