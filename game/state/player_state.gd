class_name PlayerState
extends RefCounted

var money: int = 0


func to_dict() -> Dictionary:
	return {
		"money": money,
	}


func from_dict(data: Dictionary) -> void:
	money = int(data.get("money", 0))
