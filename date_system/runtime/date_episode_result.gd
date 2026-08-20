class_name DateEpisodeResult
extends Resource

@export var phase: DateTypes.DatePhase = DateTypes.DatePhase.CORE
@export var episode_index: int = 0
@export var situation_id: StringName = &""
@export var move_id: StringName = &""
@export var tag_id: StringName = &""
@export var tag_preference: int = 0
@export var score_delta: int = 0
@export var result_text: String = ""
@export var revealed_tag: bool = false
@export var combo_granted: bool = false
