extends SceneTree
## Focused polish: capture exactly six final frames from the real main route.
## Usage: Godot --path . --rendering-method gl_compatibility -s res://tools/capture_focused_polish.gd

const ABS_OUT := "C:/Users/User/Documents/GodotProjects/date_factory/docs/vertical_slice/focused_final"
const MAIN_SCENE := "res://scenes/boot/main.tscn"
const LOG_PATH := "C:/Users/User/Documents/GodotProjects/date_factory/docs/vertical_slice/focused_final/GODOT_RAW.log"

var _log_file: FileAccess
var _player: CharacterBody3D
var _errors: PackedStringArray = []
var _game: Node
var _shot_count: int = 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ABS_OUT)
	_log_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	_log("FOCUSED POLISH CAPTURE START")
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
	await _capture("apartment_final.png", "apartment")
	await _prepare_route()
	await _goto_interact(&"go_outside")
	await _wait_seconds(1.1)
	var bus := root.get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("interaction_hint"):
		bus.emit_signal("interaction_hint", "")
	_player.global_position = Vector3(-26.5, 0.05, 2.8)
	_face_world(Vector3(-19.8, 1.6, -4.2))
	# Keep distance from any leftover apartment interact volumes.
	await _wait_seconds(0.25)
	await _capture("street_final.png", "street")
	_player.global_position = Vector3(-21.0, 0.05, -2.4)
	_face_world(Vector3(-19.5, 1.7, -4.5))
	if bus and bus.has_signal("interaction_hint"):
		bus.emit_signal("interaction_hint", "")
	await _wait_seconds(0.2)
	await _capture("restaurant_final.png", "restaurant landmark")
	await _goto_interact(&"enter_restaurant")
	await _wait_seconds(5.2)
	var stage := current_scene.find_child("DateStage", true, false)
	if stage == null:
		_fail("DateStage missing")
		return
	if str(stage.get("_sequence")) == "intro" and stage.has_method("_finish_intro"):
		stage.call("_finish_intro")
	await _wait_seconds(0.55)
	var girl := stage.get("_girl") as Node3D
	var camera := stage.get("_date_cam") as Camera3D
	if girl == null or camera == null:
		_fail("girl/camera missing")
		return
	var ui := get_first_node_in_group("date_ui") as CanvasItem
	if ui:
		ui.visible = false
	# Full-body side proof: pelvis, chair, knees, feet.
	var gp := girl.global_position
	camera.global_position = Vector3(gp.x + 2.35, gp.y + 1.05, gp.z + 0.15)
	camera.look_at(Vector3(gp.x, gp.y + 0.72, gp.z - 0.05), Vector3.UP)
	camera.fov = 36.0
	camera.current = true
	await _wait_seconds(0.2)
	await _capture("girl_sitting_full_body_side.png", "sit side")
	if ui:
		ui.visible = true
	# Restore a readable date camera framing for UI/result shots.
	if stage.has_method("_aim_camera") or camera:
		camera.global_position = Vector3(gp.x + 0.2, gp.y + 1.55, gp.z + 2.4)
		camera.look_at(Vector3(gp.x, gp.y + 1.15, gp.z - 0.4), Vector3.UP)
		camera.fov = 42.0
	await _wait_seconds(0.25)
	await _capture("date_ui_final.png", "date ui")
	await _drive_date_to_result()
	# Result toast appears while girl is still held in sit_idle for ~1s.
	await _wait_seconds(0.35)
	if camera and girl:
		var gp2 := girl.global_position
		camera.global_position = Vector3(gp2.x + 0.15, gp2.y + 1.5, gp2.z + 2.2)
		camera.look_at(Vector3(gp2.x, gp2.y + 1.1, gp2.z - 0.35), Vector3.UP)
		camera.current = true
	await _capture("date_result_final.png", "date result")
	_log("CAPTURE DONE shots=%d errors=%d" % [_shot_count, _errors.size()])
	_log("GIRL alias=%s seated=%s pos=%s" % [
		str(girl.call("get_current_alias") if girl.has_method("get_current_alias") else "?"),
		str(girl.call("is_seated") if girl.has_method("is_seated") else "?"),
		str(girl.global_position),
	])
	if _log_file:
		_log_file.close()
	quit(0 if _errors.is_empty() else 1)


func _prepare_route() -> void:
	var quests: Node = _game.get("quests")
	var dating: Node = _game.get("dating")
	if quests and quests.has_method("on_profile_seen"):
		quests.call("on_profile_seen")
	await _goto_interact(&"job")
	await _goto_interact(&"buy_gift")
	await _goto_interact(&"take_gift")
	await _goto_interact(&"wardrobe")
	await _goto_interact(&"prepare_and_start")
	_log("PREP dating=%s" % str(dating.get("prepared") if dating else {}))


func _drive_date_to_result() -> void:
	var ui := get_first_node_in_group("date_ui")
	var dating: Node = _game.get("dating")
	if ui == null or dating == null:
		_errors.append("date ui/dating missing")
		return
	for _i in range(16):
		var active: Dictionary = dating.get("active_manual")
		if active.is_empty():
			break
		var buttons: Array[Button] = []
		for n in ui.find_children("*", "Button", true, false):
			if n is Button and (n as Button).visible and not (n as Button).disabled:
				buttons.append(n as Button)
		if buttons.is_empty():
			await _wait_seconds(0.3)
			continue
		buttons[0].emit_signal("pressed")
		await _wait_seconds(0.45)


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
	await process_frame


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
	_shot_count += 1
	_log("SHOT %s err=%s note=%s" % [filename, str(err), note])


func _wait_seconds(seconds: float) -> void:
	var frames := maxi(1, int(seconds * 60.0))
	for _i in range(frames):
		await process_frame


func _log(message: String) -> void:
	print("[FOCUSED] %s" % message)
	if _log_file:
		_log_file.store_line(message)
		_log_file.flush()


func _fail(message: String) -> void:
	_errors.append(message)
	_log("FAIL %s" % message)
	if _log_file:
		_log_file.close()
	quit(1)
