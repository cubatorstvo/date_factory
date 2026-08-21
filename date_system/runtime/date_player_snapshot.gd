class_name DatePlayerSnapshot
extends Resource

@export var muscle: int = 0
@export var appearance: int = 0
@export var capital: int = 0
@export var aura: int = 0
@export var apartment_quality: int = 0
@export var apartment_prepared: bool = true
@export var express_styling_bonus: int = 0


func get_stat(stat_id: StringName) -> int:
	match String(stat_id):
		"muscle":
			return muscle
		"appearance":
			return appearance
		"capital":
			return capital
		"aura":
			return aura
		_:
			return 0


func set_stat(stat_id: StringName, value: int) -> void:
	match String(stat_id):
		"muscle":
			muscle = value
		"appearance":
			appearance = value
		"capital":
			capital = value
		"aura":
			aura = value


func to_dictionary() -> Dictionary:
	return {
		"muscle": muscle,
		"appearance": appearance,
		"capital": capital,
		"aura": aura,
		"apartment_quality": apartment_quality,
		"apartment_prepared": apartment_prepared,
		"express_styling_bonus": express_styling_bonus,
	}


static func from_dictionary(data: Dictionary) -> DatePlayerSnapshot:
	var state := DatePlayerSnapshot.new()
	state.muscle = int(data.get("muscle", 0))
	state.appearance = int(data.get("appearance", 0))
	state.capital = int(data.get("capital", 0))
	state.aura = int(data.get("aura", 0))
	state.apartment_quality = int(data.get("apartment_quality", 0))
	state.apartment_prepared = bool(data.get("apartment_prepared", true))
	state.express_styling_bonus = int(data.get("express_styling_bonus", 0))
	return state
