# Acceptance — MODULE 10 Relationships & Girl Completion

## Player-visible result
Date ends → relationship clamped [-5,+5] → cooldown 1–3 days → event history → first +5 grants conquered + Experience/UP once → Phone shows relationship/availability/completion.

## Product decisions (locked)
- Autoload `Relationships` after `DatingCore`; auto-apply on `date_finished`
- Clamp relationship in `set_girl_relationship` / `add_girl_relationship` to [-5,+5]
- Add `DatingResult.date_id` for exactly-once
- Date cooldown separate from discovery retry; each has own `notify_game_day_advanced`
- Secondary reveal API exists; no auto reveal at +5
- No MODULE 11

## PASS evidence
- `MODULE_10_TEST: ALL PASS (138)`
- Regressions: MODULE 09 (163), 08 (113), 05 (212), 02 (96), 06 (93), 07A (108), 07B (90), 07C (100), 07D (129), FPS exit 0
- Verdict: **PASS** — MODULE 11 not started
