class_name GirlTrait
extends Resource

enum Kind {
	CHARACTERISTIC,
	VENUE,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var kind: Kind = Kind.CHARACTERISTIC
@export var characteristic_id: StringName = &""
@export var date_venue_id: StringName = &""


func result_line(score: int) -> String:
	return "Особенность «%s»: %+d" % [display_name, score]
