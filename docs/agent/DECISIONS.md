# Product and architecture decisions

### DEC-001 — Минимальный интервал случайных событий

- Date: 2026-08-05
- Context: `EventsAPI` использовал wall-clock `delta`, а post-date путь мог обходить cooldown.
- Decision: все случайные catalog-events имеют единый минимум 10 игровых минут по `TimeAPI.absolute_minutes()`; отметка последнего показа хранится в существующем events save blob.
- Rejected alternatives: 10 реальных минут; frame-based cooldown; отдельная проверка только passive-roll.
- Consequences: пауза не расходует интервал, игровые time-skip/travel учитываются, save/load не сбрасывает защиту.
- Related files: `modules/events/events_api.gd`.
- Acceptance implications: passive и post-date trigger заблокированы до 10 минут; после 10 минут снова разрешены без изменения вероятностей.

### DEC-002 — Тот же интервал для runtime/deferred popup-событий

- Date: 2026-08-05
- Context: «Последствие пропуска» и другие `open_runtime_event` обходили 10-минутный catalog gate; clone `deferred_hits` спамили каждые ~5–19 wall-clock секунд.
- Decision: любой успешный popup event UI (catalog + runtime) ставит общий stamp; clone deferred firing ждёт тот же 10-минутный game-time gap и не тикает wall-clock due во время блокировки.
- Rejected alternatives: оставить runtime без лимита; отдельный короткий wall-clock cooldown для клонов.
- Consequences: latent clone consequences и прочие runtime popups не чаще раза в 10 игровых минут; очередь `deferred_hits` сохраняется, но не спамит.
- Related files: `modules/events/events_api.gd`, `modules/clones/clones_api.gd`.
- Acceptance implications: после любого event UI следующий catalog/runtime/deferred не раньше +10 game minutes.

### DEC-003 — Interactable как дочерний компонент мебели с AABB

- Date: 2026-08-05
- Context: Fridge и KitchenDrawers на расстоянии 0.7 м имели общие Area3D 1.2×1.2 → пересечение ~0.5 м; интеракты висели на room root, не на мебели.
- Decision: расширить существующий `Interactable` (не второй framework): для apartment furniture reparent под узел мебели, `fit_collision_to_meshes` по AABB мешей + padding; city fixed boxes пока не трогать.
- Rejected alternatives: только уменьшить shelf box; StaticBody interact layer; proximity без raycast.
- Consequences: области не пересекаются и следуют за мебелью; outline root = parent furniture.
- Related files: `modules/interaction/interactable.gd`, apartment path in `complex_world.gd`.
- Acceptance implications: fridge/drawers AABBs disjoint; prompts map to correct units.

### DEC-004 — City proxy POI architecture (temporary, replaceable)

- Date: 2026-08-06
- Context: Paid Downtown MegaKit unavailable; need architecturally correct temporary city POIs before pausing city visual work.
- Decision:
  1. Every venue/storefront is a `CityPOIBuilding` PackedScene with optional `CityPOITenant` slots; WorldActivity stays standalone PackedScene (tenant-like, no building shell).
  2. Landmark ready shells: PlayerHome=`Building_Small_1`, CafeTwoHearts=`Building_Medium_2_001`, Cinema=`Building_Large_2`. Others are differentiated BoxMesh/proxy façades using free kit windows/roofs/props.
  3. Multi-tenant only: `RetailPairFlowerGift` (Flower+Gift), `FashionPairJewelryClothing` (Jewelry+Clothing). No cross-district merges.
  4. Interactions live inside tenant `InteractionArea` (`Interactable`); `complex_world` discovers them. Keep Markers for spawn/return/picnic/camera only — do not recreate POI interacts from Markers.
  5. `DistrictGate` moves to `scenes/art/city/poi/core/`; keep current visual; expose width/height/alphas/locked_text/fade.
  6. Replace rule: later swap VisualRoot/CollisionRoot/EntranceAnchor local pose only — never building root in city, poi_id, action_id, district_id, save, or interaction routing.
- Rejected alternatives: wait for paid kit; one cube + different signs; keep POI doors/signs/interacts authored in `city.tscn`; Photo+Barber multi-tenant from older analysis.
- Consequences: city visual pause after this milestone; final assets drop into prefabs without city rewrite.
- Related files: `scenes/art/city/poi/**`, `scenes/world/city/city.tscn`, `scenes/world/complex_world.gd`, `docs/city_proxy_poi/*`.
- Acceptance implications: all existing action_ids work; districts unlock; no POI-specific children left loose in city root beyond PackedScene instances.

## Template

### DEC-000 — Название

- Date:
- Context:
- Decision:
- Rejected alternatives:
- Consequences:
- Related files:
- Acceptance implications:
