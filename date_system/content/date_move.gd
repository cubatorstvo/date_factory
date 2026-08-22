class_name DateMove
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var kind: DateTypes.DateMoveKind = DateTypes.DateMoveKind.BASE
@export var enabled: bool = true
@export var unlock_requirement: UnlockRequirement
@export var max_uses_per_date: int = 0
@export var fixed_tag_id: StringName = &""
@export var fixed_option_text: String = ""
@export var fixed_positive_result_text: String = ""
@export var fixed_negative_result_text: String = ""
@export var custom_action_scene: PackedScene
@export var custom_action_script: Script


func is_unlimited() -> bool:
	return max_uses_per_date <= 0


func is_base() -> bool:
	return kind == DateTypes.DateMoveKind.BASE


func is_local() -> bool:
	return kind == DateTypes.DateMoveKind.LOCAL


func is_characteristic() -> bool:
	return kind == DateTypes.DateMoveKind.CHARACTERISTIC


func is_outfit() -> bool:
	return kind == DateTypes.DateMoveKind.OUTFIT


func has_fixed_presentation() -> bool:
	return is_base() or is_local() or is_characteristic() or is_outfit()


func resolved_tag_id() -> StringName:
	return fixed_tag_id


func resolved_option_text() -> String:
	return fixed_option_text


func resolved_positive_result_text() -> String:
	return fixed_positive_result_text


func resolved_negative_result_text() -> String:
	return fixed_negative_result_text


func resolved_result_text(positive: bool) -> String:
	return resolved_positive_result_text() if positive else resolved_negative_result_text()
