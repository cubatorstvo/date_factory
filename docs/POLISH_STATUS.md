# DATE FACTORY — Polish status

Status reflects the current playable build, not a claim of final production readiness.

1. **DONE** — Consistent UI theme foundation (`ThemeFactory` / `UiStyle`) is present.
2. **DONE** — Settings service persists and exposes user-facing settings.
3. **DONE** — Procedural UI and world SFX cover primary interactions.
4. **DONE** — Boot menu establishes a clear entry point.
5. **DONE** — Pause, settings, reveal, and finale overlays exist.
6. **DONE** — Player movement and interaction feel have received a polish pass.
7. **DONE** — Date staging includes a walk-in / presentation beat; home/restaurant backdrops; Finish + 5-factor result panel.
8. **DONE** — World wanderers add ambient movement to the complex.
9. **DONE** — Phone UI: booking place/time, schedule tab/cancel, dimming, Russian empty states.
10. **DONE** — Event UI opens and closes with transition and event SFX.
11. **DONE** — Escape respects date and phone overlays; pause owns the correct mouse mode.
12. **DONE** — Complex lighting warms early apartment progression and cools at high factory stages.
13. **DONE** — Money and success toasts create lightweight floating HUD feedback.
14. **DONE** — Current smoke test reaches `SMOKE_OK`.
15. **PARTIAL** — UI has a coherent baseline, but final typography, spacing, and accessibility review remain.
16. **PARTIAL** — City/home exclusive loads + home facade door work; art polish and future districts remain.
17. **PARTIAL** — Stage 1 dating loop (schedule → prep/restaurant → date → finish) is playable; late-game economy still needs a balance pass.
18. **TODO** — Finish city/apartment location split; replace remaining placeholders; full regression QA.

## Highest-priority gaps

- Finish city ↔ apartment mutually exclusive loading and spawn at `HomeEntrance` / apartment door (see [DATING_AND_WORLD.md](DATING_AND_WORLD.md)).
- Manual visual QA: Hero sit pose, home doorbell route, restaurant unlock path.
- Validate long Russian strings at common window sizes and at non-default UI scales.
- Balance late-stage factory/orbital rewards and costs with real playtime data.
