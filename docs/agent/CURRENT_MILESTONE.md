# Current milestone

## ID
`APT-INTERACT-COMPONENT-001`

## Product goal
Убрать пересечения областей интеракции на кухне и сделать Interactable дочерним компонентом мебели с объёмом по AABB.

## Player-visible result
Холодильник и кухонные ящики имеют отдельные непересекающиеся зоны; подсказка и действие соответствуют тому объекту, на который смотрит игрок.

## Status
`READY`

## In scope
- `Interactable.fit_collision_to_meshes` + parenting under apartment furniture.
- Apartment furniture interacts sized to mesh AABB.
- Keep title/action exports and InteractionRouter.

## Out of scope
- City interact size redesign.
- New parallel interaction framework.
- Dating/save changes.

## Dependencies
- Existing Interactable + player RayCast3D.

## Active tasks

| Task | Agent | Status | Evidence |
|---|---|---|---|
| APT-INTERACT-COMPONENT-001-RESEARCH | df-researcher | COMPLETED | parent+AABB recommended |
| APT-INTERACT-COMPONENT-001 | df-gameplay-worker | COMPLETED | AABB reparent + gap ~1 cm |
| APT-INTERACT-COMPONENT-001-QA | df-qa-worker | COMPLETED | `docs/agent/qa/APT-INTERACT-COMPONENT-001_QA.md` — PASS/READY |

## Blocking issues
- Нет. Не блокирует: screenshot timeout; city smoke не завершён.

## Next acceptance action
- Milestone принят.
