class_name StoryState
extends RefCounted

var stage: int = 1
var finale_reached: bool = false


func to_dict() -> Dictionary:
	return {
		"stage": stage,
		"finale_reached": finale_reached,
	}


func from_dict(data: Dictionary) -> void:
	stage = int(data.get("stage", 1))
	finale_reached = bool(data.get("finale_reached", false))
