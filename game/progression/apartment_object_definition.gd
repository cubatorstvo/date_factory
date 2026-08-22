class_name ApartmentObjectDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 0
@export var min_story_stage: int = 2
@export var _local_object_id: StringName = &""
@export var placement_id: StringName = &""
@export var enabled: bool = true


func local_object_id() -> StringName:
	return _local_object_id if _local_object_id != &"" else id