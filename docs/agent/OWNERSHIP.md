# Active file ownership

| Task ID | Agent | Writable paths | Read-only dependencies | Forbidden paths | Status |
|---|---|---|---|---|---|
| CITY-PROXY-POI-001-CORE | df-gameplay-worker | `scenes/art/city/poi/core/CityPOIBuilding.gd`; `scenes/art/city/poi/core/CityPOITenant.gd`; `scenes/art/city/poi/core/district_gate.gd`; `scenes/art/city/poi/core/DistrictGate.tscn`; `scenes/world/complex_world.gd` (bind only); move/update refs from `scenes/art/city/prefabs/DistrictGate.tscn` + `district_gate.gd` | Interactable; city_api; CityDistricts; existing Markers spawn paths | `city.tscn` POI layout; save schema; dating SM; GeneratedCity; paid assets | COMPLETED |
| CITY-PROXY-POI-001-SCENES | df-scene-worker | `scenes/art/city/poi/buildings/**`; `scenes/art/city/poi/activities/**`; `scenes/world/city/city.tscn` (POIs/Buildings/Decor gate ExtResource+instances only); `tools/build_city_proxy_poi.gd` (optional builder) | core scripts COMPLETED; free Downtown meshes; old prefabs as reference; Interactable | GeneratedCity; district gate world positions; save; complex_world; apartment; paid assets | ACTIVE |
| CITY-PROXY-POI-001-DOCS | Orchestrator | `docs/city_proxy_poi/**`; milestone docs | implementation | gameplay scenes | QUEUED |
| CITY-PROXY-POI-001-QA | df-qa-worker | `docs/agent/qa/CITY-PROXY-POI-001_QA.md` only | city route; logs; screenshots | all gameplay/code/scenes/assets | QUEUED |

## Rules

- Один файл — один active writer.
- `.tscn` нельзя объединять вслепую.
- CORE завершается до SCENES (scenes зависят от core scripts + DistrictGate path).
- После task ownership освобождается.
