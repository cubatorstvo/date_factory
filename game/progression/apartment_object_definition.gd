class_name ApartmentObjectDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 0
@export var level_granted: int = 1
@export var granted_local_object_ids: Array[StringName] = []
@export var min_story_stage: int = 2
@export var required_filler_reward_id: StringName = &""
@export var enabled: bool = true
@export var local_move_id: StringName = &""
@export var placement_id: StringName = &""


func local_object_id() -> StringName:
	if not granted_local_object_ids.is_empty():
		return granted_local_object_ids[0]
	return id
