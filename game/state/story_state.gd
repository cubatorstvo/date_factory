class_name StoryState
extends RefCounted

var stage: int = 1


func to_dict() -> Dictionary:
	return {
		"stage": stage,
	}


func from_dict(data: Dictionary) -> void:
	stage = int(data.get("stage", 1))
