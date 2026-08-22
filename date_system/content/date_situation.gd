class_name DateSituation
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var situation_text: String = ""
@export var enabled: bool = true
@export var allowed_phases: Array[int] = []
@export var allowed_venue_ids: Array[StringName] = []
@export var allowed_girl_ids: Array[StringName] = []
@export var weight: float = 1.0
@export var base_move_ids: Array[StringName] = []
@export var custom_episode_scene: PackedScene
@export var custom_logic_script: Script


func allows_phase(phase: DateTypes.DatePhase) -> bool:
	return allowed_phases.has(int(phase))


func allows_venue(venue_id: StringName) -> bool:
	return allowed_venue_ids.is_empty() or allowed_venue_ids.has(venue_id)


func allows_girl(girl_id: StringName) -> bool:
	return allowed_girl_ids.is_empty() or allowed_girl_ids.has(girl_id)


func is_eligible(phase: DateTypes.DatePhase, venue_id: StringName, girl_id: StringName) -> bool:
	if not enabled:
		return false
	return allows_phase(phase) and allows_venue(venue_id) and allows_girl(girl_id)