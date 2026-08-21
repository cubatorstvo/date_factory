class_name Outfit
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var price: int = 0
@export var stat_id: StringName = &""
@export var stat_bonus: int = 0
@export var min_story_stage: int = 1
@export var outfit_move_id: StringName = &""
@export var future_visual_resource: Resource


func bonus_for(target_stat_id: StringName) -> int:
	if target_stat_id == &"" or stat_id != target_stat_id:
		return 0
	return 1 if stat_bonus > 0 else 0


func has_outfit_move() -> bool:
	return outfit_move_id != &""
