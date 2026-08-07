# ACCEPTANCE — MODULE 13 Salary Mine & Money Loop

## Player-visible result

After STAGE_3 unlock: salary accrues by game day into the mine; player collects via a short no-skill dig at SalaryStation; optional Salary Advance (phone) and Financial Inertia (25% passive after first manual dig). Apartment has `[E] Завершить день`.

## PASS criteria (must all hold)

- GameDay autoload: day starts at 1; `advance_day()` only production day source; reset → 1 without fake `day_advanced`.
- GirlDiscovery + Relationships subscribe once; one advance → each cooldown −1 (no double).
- Apartment End Day works in GAMEPLAY only; blocked in Phone/modal.
- SalaryMine gated by StoryFeature.SALARY_MINE; level `1 + Authority/3`; gross `10 * level`.
- Initial period exactly once at unlock; +1 period per GameDay; pending accumulates; Authority affects future periods only.
- Manual station: 1.50s MODAL_UI, take_all pending → GameState.add_money; sets manual_cycle_seen only if amount > 0; empty claim no modal.
- Salary Advance: once per current period, all pending, no future money, does not set manual seen.
- Financial Inertia: perk + manual_seen → floor(25%) auto on new periods; remainder pending; no `_process` income; no clone fields touched.
- Phone section after unlock; Advance button per availability.
- F5 still boots apartment via World; MODULE 13 self-tests PASS; MODULE 05–12 + FPS regressions PASS.
- No MODULE 14 content.

## Evidence required

- Git diff
- Headless MODULE 13 test log + regression suite
- Runtime F5 smoke: STAGE3 → mine claim → End Day → next period / Advance
- Screenshots: apartment End Day, salary station, phone salary section
- Independent df-qa-worker report

## Verdict options

`READY` or `NOT READY` only (Orchestrator).
