class_name DateEpisodeController
extends Control

signal move_selected(move_id: StringName)
signal episode_presentation_finished

var date_context: Dictionary = {}
var situation: DateSituation


func setup(p_date_context: Dictionary, p_situation: DateSituation) -> void:
	date_context = p_date_context
	situation = p_situation


func start_episode() -> void:
	episode_presentation_finished.emit()


func emit_move_selected(move_id: StringName) -> void:
	move_selected.emit(move_id)
