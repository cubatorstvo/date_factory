class_name GirlProfile
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var difficulty_preset_id: StringName = &""
@export var trait_id: StringName = &""
@export var positive_tag_ids: Array[StringName] = []
@export var initial_known_tag_ids: Array[StringName] = []
@export var portrait: Texture2D
@export var future_character_scene: PackedScene


func prefers_tag(tag_id: StringName) -> int:
	if positive_tag_ids.has(tag_id):
		return 1
	return -1
