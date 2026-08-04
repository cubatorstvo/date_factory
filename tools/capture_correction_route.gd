extends SceneTree
## Drives the real Main gameplay route and saves correction-pass evidence screenshots.
## Usage: Godot --path . -s res://tools/capture_correction_route.gd

const ABS_OUT := "C:/Users/User/Documents/GodotProjects/date_factory/docs/vertical_slice/correction"
const MAIN_SCENE := "res://scenes/boot/main.tscn"
const LOG_PATH := "C:/Users/User/Documents/GodotProjects/date_factory/docs/vertical_slice/correction/GODOT_RAW.log"

var _log_file: FileAccess
var _player: CharacterBody3D
var _shot_index: int = 0
var _errors: PackedStringArray = []
var _game: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ABS_OUT)
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	_log("CAPTURE START")
	call_deferred("_boot")


func _boot() -> void:
	_game = root.get_node_or_null("Game")
	if _game == null:
		_fail("Game autoload missing")
		return
	var packed := load(MAIN_SCENE) as PackedScene
	if packed == null:
		_fail("Missing main scene")
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	_player = get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		_fail("Player missing")
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_player.set("_date_lock", false)
	await _capture("01_apartment_spawn.png", "apartment spawn")
	await _run_apartment_prep()
	await _capture("02_apartment_date_preparation.png", "prep table")
	await _goto_interact(&"go_outside")
	await _wait_seconds(1.1)
	await _capture("03_apartment_exit.png", "after outside teleport")
	_face_world(Vector3(-19.5, 1.4, -4.35))
	_player.global_position = Vector3(-28.0, 0.05, 1.5)
	await process_frame
	await _capture("04_street_route.png", "street route")
	_player.global_position = Vector3(-21.0, 0.05, -2.5)
	_face_world(Vector3(-19.5, 1.6, -4.35))
	await process_frame
	await _capture("05_restaurant_destination.png", "restaurant landmark")
	_player.global_position = Vector3(-19.5, 0.05, -3.2)
	await process_frame
	await _capture("06_restaurant_entrance.png", "restaurant entrance")
	await _goto_interact(&"enter_restaurant")
	await _wait_seconds(1.2)
	var stage := _find_date_stage()
	if stage == null:
		_fail("DateStage missing after enter_restaurant")
		return
	await _wait_seconds(0.35)
	await _capture("07_date_table_empty.png", "date table early")
	await _wait_seconds(1.4)
	await _capture("08_girl_enters.png", "girl enters")
	await _wait_seconds(2.2)
	await _capture("09_girl_approaches.png", "girl approaches")
	await _wait_seconds(2.0)
	await _capture("10_girl_sit_enter_side.png", "sit enter")
	if stage.has_method("_finish_intro") and str(stage.get("_sequence")) == "intro":
		stage.call("_finish_intro")
	await _wait_seconds(1.0)
	var girl: Variant = stage.get("_girl")
	if girl != null and girl is Node3D:
		var g := girl as Node3D
		var alias := str(g.call("get_current_alias")) if g.has_method("get_current_alias") else "?"
		var seated := str(g.call("is_seated")) if g.has_method("is_seated") else "?"
		_log("GIRL pos=%s alias=%s seated=%s" % [str(g.position), alias, seated])
	await _capture("11_girl_sit_idle.png", "sit idle")
	await _wait_seconds(0.4)
	await _capture("12_date_ui_three_answers.png", "three answers")
	await _drive_date_answers()
	await _wait_seconds(0.6)
	await _capture("17_date_result.png", "result")
	var dating: Node = _game.get("dating")
	if dating != null:
		var active: Dictionary = dating.get("active_manual")
		if active != null and not active.is_empty():
			if dating.has_signal("date_ui_close"):
				dating.emit_signal("date_ui_close")
	await _wait_seconds(1.0)
	await _capture("18_girl_leaves.png", "girl leaves")
	await _wait_seconds(2.0)
	await _capture("19_player_control_restored.png", "control restored")
	var quests: Node = _game.get("quests")
	_log("CAPTURE DONE shots=%d errors=%d" % [_shot_index, _errors.size()])
	if quests:
		_log("QUEST completed=%s" % str(quests.get("completed")))
	_log("PLAYER lock=%s pos=%s" % [str(_player.get("_date_lock")), str(_player.global_position)])
	if _log_file:
		_log_file.close()
	quit(0 if _errors.is_empty() else 1)


func _run_apartment_prep() -> void:
	var quests: Node = _game.get("quests")
	var economy: Node = _game.get("economy")
	var inventory: Node = _game.get("inventory")
	var dating: Node = _game.get("dating")
	if quests and quests.has_method("on_profile_seen"):
		quests.call("on_profile_seen")
	await _goto_interact(&"job")
	await _goto_interact(&"buy_gift")
	await _goto_interact(&"take_gift")
	await _goto_interact(&"wardrobe")
	_player.global_position = Vector3(1.5, 0.05, 2.2)
	_face_world(Vector3(1.5, 1.2, 1.5))
	await process_frame
	await _goto_interact(&"prepare_and_start")
	_player.global_position = Vector3(-3.0, 0.05, 0.0)
	_face_world(Vector3(-3.5, 1.4, 0.0))
	await process_frame
	_log("PREP dating=%s" % str(dating.get("prepared") if dating else {}))


func _drive_date_answers() -> void:
	var ui := get_first_node_in_group("date_ui")
	if ui == null:
		_errors.append("date_ui missing")
		_log("ERROR date_ui missing")
		return
	var dating: Node = _game.get("dating")
	var shot_names: Array[String] = [
		"13_positive_reaction.png",
		"14_negative_reaction.png",
		"15_trait_hypothesis.png",
		"16_trait_confirmed.png",
	]
	var notes: Array[String] = ["positive", "negative", "hypothesis", "confirmed"]
	for i in range(shot_names.size()):
		var active: Dictionary = dating.get("active_manual") if dating else {}
		if active.is_empty():
			_log("DATE already closed before %s" % shot_names[i])
			break
		var buttons: Array[Button] = _visible_date_buttons(ui)
		if buttons.is_empty():
			await _wait_seconds(0.35)
			buttons = _visible_date_buttons(ui)
		if buttons.is_empty():
			_log("ERROR no buttons for %s" % shot_names[i])
			continue
		var idx := mini(i, buttons.size() - 1)
		if not is_instance_valid(buttons[idx]):
			continue
		buttons[idx].emit_signal("pressed")
		await _wait_seconds(0.65)
		await _capture(shot_names[i], notes[i])
		if i == 2:
			await _wait_seconds(0.25)
			await _capture("16_trait_confirmed.png", "confirmed")
	for _i in range(12):
		var active2: Dictionary = dating.get("active_manual") if dating else {}
		if active2.is_empty():
			break
		var more: Array[Button] = _visible_date_buttons(ui)
		if more.is_empty():
			await _wait_seconds(0.35)
			continue
		if is_instance_valid(more[0]):
			more[0].emit_signal("pressed")
		await _wait_seconds(0.45)


func _visible_date_buttons(ui: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for n in ui.find_children("*", "Button", true, false):
		if n is Button and is_instance_valid(n) and (n as Button).visible and not (n as Button).disabled:
			buttons.append(n as Button)
	return buttons


func _goto_interact(action: StringName) -> void:
	var target: Area3D = null
	for n in current_scene.find_children("*", "Area3D", true, false):
		if "action_id" in n and n.get("action_id") == action:
			target = n as Area3D
			break
	if target == null:
		_errors.append("missing interactable %s" % action)
		_log("ERROR missing interactable %s" % action)
		return
	_player.global_position = Vector3(target.global_position.x, 0.05, target.global_position.z + 0.85)
	if target.has_method("on_interact"):
		target.call("on_interact", _player)
		_log("INTERACT %s" % action)
	else:
		_errors.append("no on_interact %s" % action)
		_log("ERROR no on_interact %s" % action)
	await process_frame


func _find_date_stage() -> Node:
	return current_scene.find_child("DateStage", true, false)


func _face_world(target: Vector3) -> void:
	if _player == null:
		return
	var look := target
	look.y = _player.global_position.y
	if _player.global_position.distance_to(look) > 0.05:
		_player.look_at(look, Vector3.UP)
		_player.rotation.x = 0.0
		_player.rotation.z = 0.0
	var head := _player.get_node_or_null("Head") as Node3D
	if head:
		head.rotation.x = 0.0


func _capture(filename: String, note: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		_errors.append("null image %s" % filename)
		_log("ERROR null image %s (%s)" % [filename, note])
		return
	var path := "%s/%s" % [ABS_OUT, filename]
	var err := img.save_png(path)
	_shot_index += 1
	_log("SHOT %s err=%s note=%s" % [filename, str(err), note])


func _wait_seconds(seconds: float) -> void:
	var frames := maxi(1, int(seconds * 60.0))
	for _i in range(frames):
		await process_frame


func _log(message: String) -> void:
	print("[CORRECTION] %s" % message)
	if _log_file:
		_log_file.store_line(message)
		_log_file.flush()


func _fail(message: String) -> void:
	_errors.append(message)
	_log("FAIL %s" % message)
	if _log_file:
		_log_file.close()
	quit(1)
