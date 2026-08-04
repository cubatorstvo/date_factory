extends Node3D
## Presents milestone reveals over the gameplay scene.


func _ready() -> void:
	var theme_service := load("res://scenes/ui/chrome/date_factory_theme.gd")
	if theme_service:
		theme_service.apply(self)
	Sfx.set_zone(&"apartment")
	EventBus.stage_changed.connect(_on_stage)
	EventBus.girl_unlocked.connect(_on_girl_unlocked)
	EventBus.finale_completed.connect(_on_finale_completed)
	if get_tree().get_first_node_in_group("shop_ui") == null:
		var shop_script: Script = load("res://scenes/ui/shop_ui.gd") as Script
		if shop_script:
			var shop := shop_script.new() as CanvasLayer
			shop.name = "ShopUI"
			add_child(shop)
	if get_tree().get_first_node_in_group("gym_ui") == null:
		var gym_script: Script = load("res://scenes/ui/gym_ui.gd") as Script
		if gym_script:
			var gym := gym_script.new() as CanvasLayer
			gym.name = "GymUI"
			add_child(gym)
	if get_tree().get_first_node_in_group("arcade_minigame") == null:
		var arcade_script: Script = load("res://scenes/minigames/pair_overload_minigame.gd") as Script
		if arcade_script:
			var arcade := arcade_script.new() as CanvasLayer
			arcade.name = "PairOverloadMinigame"
			add_child(arcade)
	if get_tree().get_first_node_in_group("photo_studio_ui") == null:
		var photo_script: Script = load("res://scenes/ui/photo_studio_ui.gd") as Script
		if photo_script:
			var photo := photo_script.new() as CanvasLayer
			photo.name = "PhotoStudioUI"
			add_child(photo)
	if get_tree().get_first_node_in_group("barber_ui") == null:
		var barber_script: Script = load("res://scenes/ui/barber_ui.gd") as Script
		if barber_script:
			var barber := barber_script.new() as CanvasLayer
			barber.name = "BarberUI"
			add_child(barber)
	if get_tree().get_first_node_in_group("agency_board_ui") == null:
		var board_script: Script = load("res://scenes/ui/agency_board_ui.gd") as Script
		if board_script:
			var board := board_script.new() as CanvasLayer
			board.name = "AgencyBoardUI"
			add_child(board)
	if get_tree().get_first_node_in_group("elevator_ui") == null:
		var elev_script: Script = load("res://scenes/ui/elevator_ui.gd") as Script
		if elev_script:
			var elev := elev_script.new() as CanvasLayer
			elev.name = "ElevatorUI"
			add_child(elev)
	if get_tree().get_first_node_in_group("district_gate_ui") == null:
		var gate_script: Script = load("res://scenes/ui/district_gate_ui.gd") as Script
		if gate_script:
			var gate_ui := gate_script.new() as CanvasLayer
			gate_ui.name = "DistrictGateUI"
			add_child(gate_ui)
	if not EventBus.notify.is_connected(_on_leisure_notify):
		EventBus.notify.connect(_on_leisure_notify)


func _on_leisure_notify(message: String, kind: StringName) -> void:
	if kind != &"ui":
		return
	if message.begins_with("ARCADE_OPEN_DATE:"):
		var gid := message.trim_prefix("ARCADE_OPEN_DATE:")
		InteractionRouter._open_arcade_minigame(true, gid)


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
