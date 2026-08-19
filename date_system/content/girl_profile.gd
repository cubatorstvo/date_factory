class_name GirlProfile
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var relationship_min: int = -5
@export var relationship_start: int = 0
@export var relationship_max: int = 5
@export var difficulty_preset_id: StringName = &""
@export var positive_tag_ids: Array[StringName] = []
@export var negative_tag_ids: Array[StringName] = []
@export var secondary_rule_id: StringName = &""
@export var favorite_location_format_ids: Array[StringName] = []
@export var portrait: Texture2D
@export var future_character_scene: PackedScene


func prefers_tag(tag_id: StringName) -> int:
	if positive_tag_ids.has(tag_id):
		return 1
	return -1


func sync_negative_tags(all_tags: Array[DateTag]) -> void:
	negative_tag_ids.clear()
	for tag in all_tags:
		if tag == null:
			continue
		if not tag.enabled:
			continue
		if not positive_tag_ids.has(tag.id):
			negative_tag_ids.append(tag.id)
