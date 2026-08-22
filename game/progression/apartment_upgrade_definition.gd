class_name ApartmentUpgradeDefinition
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 0
@export var level_granted: int = 1
@export var granted_local_object_ids: Array[StringName] = []
@export var min_story_stage: int = 2
@export var required_filler_reward_id: StringName = &""