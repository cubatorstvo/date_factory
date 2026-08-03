extends Node3D
## Presents milestone reveals over the gameplay scene.


func _ready() -> void:
	EventBus.stage_changed.connect(_on_stage)
	EventBus.girl_unlocked.connect(_on_girl_unlocked)
	EventBus.finale_completed.connect(_on_finale_completed)


func _on_stage(stage_id: StringName) -> void:
	if stage_id == &"stage_1":
		return
	# Defer past world rebuild from stage_changed so reveal tweens aren't killed mid-open.
	call_deferred("_present_stage_reveal", stage_id)


func _present_stage_reveal(stage_id: StringName) -> void:
	var reveal := RevealPopup.ui(get_tree())
	if reveal == null:
		return
	var st: Dictionary = ContentDB.stage(stage_id)
	var status_name := str(st.get("name", stage_id))
	var goal := str(st.get("goal", ""))
	var room_hint: String = _new_rooms_hint(stage_id)
	var body := "%s\n\n%s" % [room_hint, goal]
	reveal.present_stage(status_name, body)


func _on_girl_unlocked(girl_id: StringName) -> void:
	var reveal := RevealPopup.ui(get_tree())
	if reveal == null:
		return
	var title_name: String = Loc.girl_title(girl_id)
	var def: Dictionary = ContentDB.girl(girl_id)
	var bonus := str(def.get("bonus_desc", ""))
	var likes := Loc.tags_list(def.get("likes", []))
	var body := "Любит: %s\n\n%s" % [likes if likes != "" else "—", bonus]
	reveal.present_girl(title_name, body)


func _on_finale_completed() -> void:
	var finale: Node = get_tree().get_first_node_in_group("finale_ui")
	if finale != null and finale.has_method("open"):
		finale.open()


func _new_rooms_hint(stage_id: StringName) -> String:
	match str(stage_id):
		"stage_2":
			return "Открыто: рабочий уголок справа (+X). Жёлтая дверь вела сюда."
		"stage_3":
			return "Открыто: операционный штаб дальше по коридору (+X)."
		"stage_4":
			return "Открыто: особняк и лаборатория (+X)."
		"stage_5":
			return "Открыто: фабрика и конвейер свиданий (+X)."
		"stage_6":
			return "Открыто: орбитальный сектор. Финальный этап."
		_:
			return "Новые комнаты открыты справа (+X)."
