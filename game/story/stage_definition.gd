class_name StageDefinition
extends Resource

@export var stage: int = 0
@export var display_name: String = ""
@export var completion_requirement: StageRequirement
@export var on_enter_effects: Array[StageEnterEffect] = []
