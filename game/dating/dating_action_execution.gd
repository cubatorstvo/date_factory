class_name DatingActionExecutionRequest
extends RefCounted
## Opaque external action execution request (MODULE 09).

var girl_id: StringName = &""
var event_id: StringName = &""
var action_id: StringName = &""
var resolver_id: StringName = &""
var characteristic: GameTypes.PlayerCharacteristic = GameTypes.PlayerCharacteristic.MUSCLE
var base_tags: Array[GameTypes.ActionTag] = []
var is_public: bool = false
var context_token: StringName = &""
