extends Node
## Global signal bus. Modules emit here; UI and other modules listen.

signal notify(message: String, kind: StringName)
signal resource_changed(resource_id: StringName, value: float)
signal stage_changed(stage_id: StringName)
signal quest_updated(quest_id: StringName)
signal date_finished(result: Dictionary)
signal girl_unlocked(girl_id: StringName)
signal relation_changed(girl_id: StringName, level: int, points: float)
signal bottleneck(kind: StringName, detail: String)
signal event_raised(event_id: StringName)
signal interaction_hint(text: String)
signal carry_changed(item_id: StringName)
signal time_changed(day: int, minutes: int)
signal date_reminder(payload: Dictionary)
signal date_scheduled(payload: Dictionary)
signal date_cancelled(payload: Dictionary)
signal table_prep_changed(state: Dictionary)
signal finale_completed
signal postgame_started


func toast(message: String, kind: StringName = &"info") -> void:
	notify.emit(message, kind)
	Sfx.play(kind)
