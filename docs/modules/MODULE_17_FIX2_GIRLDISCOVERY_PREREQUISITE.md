# MODULE 17 FIX 2 — GIRLDISCOVERY SCIENTIST PREREQUISITE

Остался один блокер из `MODULE_17_FIX_SCIENTIST_PRODUCTION_WIRING_RU.md`.

## Уже принято

НЕ менять:
- `StageActorAnchor.requires_overload_recognized`;
- Scientist anchors в `city_hub`;
- live spawn по `DatingOverload.problem_recognized`;
- reset refresh;
- Scientist/Rival content;
- FirstClone;
- Laboratory;
- clone assignment/rates.

## Проблема

Сейчас `GirlDiscovery.begin_attempt()` вызывает `_story_gate_block(girl_id)`, а `_story_gate_block()` проверяет только `WRONG_STAGE` и `RIVAL_REQUIRED`.

Поэтому direct API можно обойти:

```text
STAGE_4
problem_recognized = false
rival_scientist вручную marked defeated
→ GirlDiscovery.begin_attempt(girl_scientist)
→ попытка начинается
```

Это нарушает MODULE17 prerequisite.

## Добавить result

В `game/girls/girl_discovery.gd` рядом с другими result IDs:

```gdscript
const RESULT_STORY_PREREQUISITE: StringName = &"STORY_PREREQUISITE"
```

## Добавить explicit Scientist gate

В `_story_gate_block(girl_id)` ДО `Story.get_story_girl_gate()`:

```gdscript
if girl_id == StoryIds.GIRL_SCIENTIST:
    var gs: Node = get_node_or_null("/root/GameState")
    if gs != null and int(gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4):
        var overload: Node = get_node_or_null("/root/DatingOverload")
        if overload == null or not overload.has_method("is_problem_recognized") or not bool(overload.call("is_problem_recognized")):
            return _result(false, RESULT_STORY_PREREQUISITE)
```

Техническую форму можно адаптировать под текущие типы/константы, semantic exact.

НЕ добавлять generic condition engine.

## Side effects

`STORY_PREREQUISITE` возвращается ДО создания attempt:
- no retry cooldown;
- no failure;
- no contact;
- no new clue из failure path;
- no relationship mutation.

## GirlActor feedback

Добавить presentation:

```text
STORY_PREREQUISITE
→ "Сначала нужно понять, зачем тебе вообще второй ты."
```

## Tests

### Before recognition

```text
STAGE4
problem=false
rival_scientist defeated
begin_attempt(girl_scientist)
```

Expected:

```text
ok=false
reason=STORY_PREREQUISITE
no retry cooldown
no contact
```

### After recognition, rival undefeated

Expected:

```text
STORY_RIVAL_REQUIRED
```

### After recognition + rival defeated + XP4

Expected normal successful attempt start.

## Stop

После этого STOP. MODULE18 не начинать.
