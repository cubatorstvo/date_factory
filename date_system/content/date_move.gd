class_name DateMove
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var kind: DateTypes.DateMoveKind = DateTypes.DateMoveKind.BASE
@export var enabled: bool = true
@export var unlock_requirement: UnlockRequirement
@export var max_uses_per_date: int = 0
@export var situation_mappings: Array[DateMoveSituationMapping] = []
@export var custom_action_scene: PackedScene
@export var custom_action_script: Script


func mapping_for(situation_id: StringName) -> DateMoveSituationMapping:
	for mapping in situation_mappings:
		if mapping != null and mapping.situation_id == situation_id:
			return mapping
	return null


func is_unlimited() -> bool:
	return max_uses_per_date <= 0
