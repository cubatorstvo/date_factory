class_name StageDefinition
extends Resource

@export var stage: int = 0
@export var display_name: String = ""
@export var filler_girl_ids: Array[StringName] = []
@export var story_girl_id: StringName = &""
@export var ordinary_rival_ids: Array[StringName] = []
@export var story_rival_id: StringName = &""
@export var required_filler_max_count: int = 0
@export var story_girl_required_rating: int = 0
@export var objective_title: String = ""
@export var objective_description: String = ""
@export var completion_requirement: StageRequirement
@export var on_enter_effects: Array[StageEnterEffect] = []
