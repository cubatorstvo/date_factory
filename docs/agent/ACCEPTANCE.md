# Current milestone acceptance

## Milestone
`CITY-PROXY-POI-001`

## Required player route
1. Spawn city → подойти к дому и кафе → prompts работают.
2. Flower/Gift (multi-tenant) и Jewelry/Clothing (multi-tenant) — отдельные входы/действия.
3. Остальные storefront/venue proxies — action_id как раньше.
4. WorldActivity (bench/duck/karaoke/bus) работают без здания.
5. Park/Agency gates блокируют/открывают как раньше.
6. Save/load с unlocked districts восстанавливает доступ.

## Functional criteria
- [ ] Каждый POI — PackedScene root или tenant внутри building PackedScene.
- [ ] В city.tscn нет отдельных дверей/вывесок/InteractionArea/коллизий/ламп конкретного POI вне экземпляров.
- [ ] Перенос корня здания переносит visual+collision+interact.
- [ ] Нет NodePath из POI prefab в узлы city.tscn.
- [ ] Все прежние action_id сохранены и reachable.
- [ ] Подходы к входам не заблокированы.
- [ ] DistrictGate — одна сцена из `poi/core`, 3 экземпляра.
- [ ] Маршруты/районы не перестроены.

## Visual criteria
- [ ] Proxy не один голый куб на все.
- [ ] Не одинаковый фасад с разными надписями.
- [ ] Нет двери поверх baked-двери.
- [ ] Каждый proxy отличается ≥3 признаками от соседей.
- [ ] LotBounds только editor/debug.

## Edge cases
- [ ] Multi-action tenants (InternetCafe×3, Gym×2, Arcade×2, Bus×2).
- [ ] Picnic marker `sit_park` без building.
- [ ] Cinema Large footprint не режет тротуар критично.

## Save/load
- [ ] District unlock blob продолжает работать.

## Evidence
- [ ] Git diff reviewed
- [ ] Engine logs
- [ ] Screenshots
- [ ] Independent QA report
- [ ] docs/city_proxy_poi/*

## Blocking failures
- TBD

## Final decision
`NOT READY`
