extends SceneTree
## Temporary real-main-route side-view capture for validating the date character on the restaurant chair.

const OUT_DIR := "C:/Users/User/Documents/GodotProjects/date_factory/docs/vertical_slice/focused_polish_work"
const MAIN_SCENE := "res://scenes/boot/main.tscn"

var _game: Node
var _player: CharacterBody3D


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	call_deferred("_boot")


func _boot() -> void:
	_game = root.get_node_or_null("Game")
	var packed := load(MAIN_SCENE) as PackedScene
	if _game == null or packed == null:
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	_player = get_first_node_in_group("player") as CharacterBody3D
	if _player == null:
		quit(2)
		return
	_player.set("_date_lock", false)
	await _prepare_route()
	await _goto_interact(&"go_outside")
	await _wait_seconds(1.0)
	await _goto_interact(&"enter_restaurant")
	await _wait_seconds(4.8)
	var stage := current_scene.find_child("DateStage", true, false)
	if stage == null:
		quit(3)
		return
	var girl := stage.get("_girl") as Node3D
	var camera := stage.get("_date_cam") as Camera3D
	if girl == null or camera == null:
		quit(4)
		return
	print("[FOCUSED] approach alias=%s pos=%s" % [str(girl.call("get_current_alias")), str(girl.position)])
	await _wait_seconds(1.25)
	print("[FOCUSED] turn alias=%s pos=%s" % [str(girl.call("get_current_alias")), str(girl.position)])
	await _wait_seconds(0.5)
	print("[FOCUSED] sit_enter alias=%s pos=%s" % [str(girl.call("get_current_alias")), str(girl.position)])
	await _wait_seconds(1.1)
	if str(stage.get("_sequence")) == "intro" and stage.has_method("_finish_intro"):
		stage.call("_finish_intro")
	await _wait_seconds(0.5)
	var ui := get_first_node_in_group("date_ui") as CanvasItem
	if ui:
		ui.visible = false
	camera.global_position = Vector3(2.1, 40.95, -1.05)
	camera.look_at(Vector3(0.0, 40.78, -1.12), Vector3.UP)
	camera.fov = 38.0
	camera.current = true
	await _wait_seconds(0.25)
	RenderingServer.force_draw()
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("%s/candidate_sit_side.png" % OUT_DIR)
	print("[FOCUSED] sit_idle capture=%s girl=%s alias=%s seated=%s" % [str(error), str(girl.global_position), str(girl.call("get_current_alias")), str(girl.call("is_seated"))])
	girl.call("play_alias", &"seated_gesture")
	await _wait_seconds(0.45)
	print("[FOCUSED] seated_gesture alias=%s" % str(girl.call("get_current_alias")))
	stage.call("_on_close")
	await _wait_seconds(0.45)
	print("[FOCUSED] sit_exit alias=%s pos=%s" % [str(girl.call("get_current_alias")), str(girl.position)])
	await _wait_seconds(0.9)
	print("[FOCUSED] leave alias=%s pos=%s" % [str(girl.call("get_current_alias")), str(girl.position)])
	await _wait_seconds(2.5)
	print("[FOCUSED] outro sequence=%s" % str(stage.get("_sequence")))
	quit(0 if error == OK else 5)


func _prepare_route() -> void:
	var quests: Node = _game.get("quests")
	if quests and quests.has_method("on_profile_seen"):
		quests.call("on_profile_seen")
	await _goto_interact(&"job")
	await _goto_interact(&"buy_gift")
	await _goto_interact(&"take_gift")
	await _goto_interact(&"wardrobe")
	await _goto_interact(&"prepare_and_start")


func _goto_interact(action: StringName) -> void:
	var target: Area3D
	for node in current_scene.find_children("*", "Area3D", true, false):
		if "action_id" in node and node.get("action_id") == action:
			target = node as Area3D
			break
	if target == null:
		return
	_player.global_position = Vector3(target.global_position.x, 0.05, target.global_position.z + 0.85)
	if target.has_method("on_interact"):
		target.call("on_interact", _player)
	await process_frame


func _wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
