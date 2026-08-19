class_name SecondaryRule
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var enabled: bool = true
@export var condition_type: DateTypes.SecondaryConditionType = DateTypes.SecondaryConditionType.DISTINCT_SUCCESS_TAGS
@export var condition_parameters: Dictionary = {}
@export var success_score: int = 0
@export var failure_score: int = 0
