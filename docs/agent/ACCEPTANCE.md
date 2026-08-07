# Current milestone acceptance

## Milestone
`CITY-PROXY-POI-001`

## Required player route
1. Spawn → city → PlayerHome / Cafe prompts.
2. Multi-tenant Flower/Gift and Jewelry/Clothing actions present.
3. Storefront/venue proxies keep action_ids.
4. WorldActivity without building shell.
5. District gates present; park locked by default.
6. Save/load district unlock round-trip (headless).

## Functional criteria
- [x] Each POI — PackedScene root or tenant inside building PackedScene.
- [x] city.tscn — only root instances under POIs (no loose POI doors/signs/areas).
- [x] Root move carries visual+collision+interact (structure).
- [x] No NodePath from POI prefab into city.tscn.
- [x] action_ids preserved (27 tenant interacts; live FOUND all key actions).
- [x] Live prompts: `go_home`, `sit_cafe` verified in screenshots.
- [x] DistrictGate — `poi/core`, 3 instances, transforms kept.
- [x] Routes/districts not rebuilt.

## Visual criteria
- [x] Proxies not one naked cube for all (distinct colors/awnings/lights/props).
- [x] Ready landmarks use Building_* without Door over baked opening.
- [x] LotBounds hidden in normal play (editor / meta opt-in only).
- [ ] Full façade beauty — out of scope (proxy pause).

## Edge cases
- [x] Multi-action tenants present (Net×3, Gym×2, Arcade×2, Bus×2).
- [x] Picnic `sit_park` remains Marker-only.
- [x] Fashion pair consolidates Clothing into Jewelry lot (intentional).

## Save/load
- [x] District unlock blob unchanged; headless round-trip OK.

## Evidence
- [x] Git-ready change set (core + poi scenes + city + docs)
- [x] Engine logs: `docs/city_proxy_poi/qa/capture_stdout.log`, CAPTURE_RAW.log
- [x] Screenshots: `docs/city_proxy_poi/qa/01–12_*.png` (reviewed)
- [x] Independent QA: `docs/agent/qa/CITY-PROXY-POI-001_QA.md` + Orchestrator live capture follow-up
- [x] docs/city_proxy_poi/*

## Blocking failures
- Нет критических. Visual city work intentionally paused on proxy quality.

## Final decision
`READY`
