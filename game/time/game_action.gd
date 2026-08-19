class_name GameAction
extends Resource

@export var id: StringName = &""
@export var time_cost_minutes: int = 0
@export var money_cost: int = 0
@export var requirements: Array[ActionRequirement] = []
@export var effects: Array[ActionEffect] = []
