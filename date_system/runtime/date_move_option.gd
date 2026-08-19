class_name DateMoveOption
extends RefCounted

var move_id: StringName = &""
var display_name: String = ""
var kind: DateTypes.DateMoveKind = DateTypes.DateMoveKind.BASE
var option_text: String = ""
var tag_id: StringName = &""
var tag_display_name: String = ""
var tag_knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN
var availability: DateTypes.MoveAvailability = DateTypes.MoveAvailability.AVAILABLE
var requirement_stat_id: StringName = &""
var requirement_level: int = 0
var current_stat_level: int = 0
var uses_used: int = 0
var uses_max: int = 0


func is_selectable() -> bool:
	return availability == DateTypes.MoveAvailability.AVAILABLE
