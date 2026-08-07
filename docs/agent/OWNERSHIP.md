# Active file ownership

| Task ID | Agent | Writable paths | Read-only dependencies | Forbidden paths | Status |
|---|---|---|---|---|---|
| CITY-PROXY-POI-001-CORE | df-gameplay-worker | poi/core scripts + DistrictGate; complex_world bind | Interactable; city_api | city layout; save | COMPLETED |
| CITY-PROXY-POI-001-SCENES | df-scene-worker | poi/buildings; poi/activities; city.tscn POIs; build_city_proxy_poi.gd | core scripts | GeneratedCity; complex_world | COMPLETED |
| CITY-PROXY-POI-001-DOCS | Orchestrator | docs/city_proxy_poi/**; milestone docs | implementation | — | COMPLETED |
| CITY-PROXY-POI-001-QA | df-qa-worker | docs/agent/qa/CITY-PROXY-POI-001_QA.md; docs/city_proxy_poi/qa/ | city route | gameplay writes | COMPLETED |

## Rules

- Один файл — один active writer.
- Ownership freed after milestone READY.
