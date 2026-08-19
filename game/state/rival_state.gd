class_name RivalState
extends RefCounted

var discovered: bool = false
var defeated: bool = false


func to_dict() -> Dictionary:
	return {
		"discovered": discovered,
		"defeated": defeated,
	}


func from_dict(data: Dictionary) -> void:
	discovered = bool(data.get("discovered", false))
	defeated = bool(data.get("defeated", false))
