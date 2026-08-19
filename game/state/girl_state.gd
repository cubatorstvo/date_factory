class_name GirlState
extends RefCounted

var discovered: bool = false
var has_contact: bool = false
var relationship: int = 0


func to_dict() -> Dictionary:
	return {
		"discovered": discovered,
		"has_contact": has_contact,
		"relationship": relationship,
	}


func from_dict(data: Dictionary) -> void:
	discovered = bool(data.get("discovered", false))
	has_contact = bool(data.get("has_contact", false))
	relationship = int(data.get("relationship", 0))
