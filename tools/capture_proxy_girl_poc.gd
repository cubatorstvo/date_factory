extends SceneTree
## Capture GirlProxyPOC testbed proofs to the Proxy work directory.
## Usage: Godot --path . -s res://tools/capture_proxy_girl_poc.gd
## Do NOT use --headless — viewport screenshots need a real window.

const OUT_DIR := "C:/Users/User/Downloads/date_factory_proxy_work/godot_screenshots"
const TESTBED := "res://scenes/art/testbeds/ProxyGirlPOC_Testbed.tscn"
const REST_SMOKE := "res://scenes/art/testbeds/ProxyGirlPOC_RestaurantSmoke.tscn"
const REST_OUT := "C:/Users/User/Downloads/date_factory_proxy_work/restaurant_screenshots"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(REST_OUT)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")


func _run() -> void:
	await _capture_testbed()
	await _capture_restaurant()
	quit(0)


func _wait_frames(n: int) -> void:
	for _i in n:
		await process_frame
		RenderingServer.force_draw()


func _save_viewport(path: String) -> void:
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("No viewport image for %s" % path)
		return
	var err := img.save_png(path)
	print("[PROXY_CAPTURE] saved %s err=%s size=%sx%s" % [path, err, img.get_width(), img.get_height()])


func _capture_testbed() -> void:
	var packed := load(TESTBED) as PackedScene
	if packed == null:
		push_error("Missing testbed")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var girl := scene.get_node_or_null("GirlProxyPOC")
	var front := scene.get_node_or_null("CamFront") as Camera3D
	var side := scene.get_node_or_null("CamSide") as Camera3D
	# Ensure readable lighting for QA captures.
	var key := DirectionalLight3D.new()
	key.light_energy = 1.35
	key.shadow_enabled = false
	key.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-20.0, -140.0, 0.0)
	scene.add_child(fill)
	# Hide tech chair during front proofs so it cannot occlude the body.
	var chair_seat := scene.get_node_or_null("ChairSeat") as Node3D
	var chair_back := scene.get_node_or_null("ChairBack") as Node3D
	if front:
		# Dual-front strategy: try -Z first; if needed rotate girl 180 for face.
		front.global_position = Vector3(0.0, 1.05, -2.4)
		front.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
		front.current = true
	if girl:
		# GLB visual forward can disagree with Node3D -Z; face the front camera.
		girl.rotation_degrees.y = 180.0
	if chair_seat:
		chair_seat.visible = false
	if chair_back:
		chair_back.visible = false
	var shots: Array[Dictionary] = [
		{"file": "godot_01_standing_front.png", "alias": "idle", "cam": "front"},
		{"file": "godot_02_walking.png", "alias": "walk", "cam": "side"},
		{"file": "godot_03_sit_enter_side.png", "alias": "sit_enter", "cam": "side"},
		{"file": "godot_04_sit_idle_side.png", "alias": "sit_idle", "cam": "side"},
		{"file": "godot_05_seated_gesture.png", "alias": "seated_gesture", "cam": "front"},
		{"file": "godot_06_sit_exit.png", "alias": "sit_exit", "cam": "side"},
	]
	for s in shots:
		if girl and girl.has_method("play_alias"):
			var ok: bool = girl.call("play_alias", String(s["alias"]))
			print("[PROXY_CAPTURE] play_alias %s -> %s" % [s["alias"], ok])
		if String(s["cam"]) == "front" and front:
			if chair_seat:
				chair_seat.visible = false
			if chair_back:
				chair_back.visible = false
			front.global_position = Vector3(0.0, 1.05, -2.4)
			front.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
			front.current = true
		elif side:
			if chair_seat:
				chair_seat.visible = true
			if chair_back:
				chair_back.visible = true
			side.global_position = Vector3(2.2, 1.05, 0.0)
			side.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
			side.current = true
		await _wait_frames(50)
		await _save_viewport("%s/%s" % [OUT_DIR, s["file"]])
	scene.queue_free()
	await _wait_frames(4)


func _capture_restaurant() -> void:
	var packed := load(REST_SMOKE) as PackedScene
	if packed == null:
		push_error("Missing restaurant smoke")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var girl := scene.get_node_or_null("GirlProxyPOC")
	var cam := scene.get_node_or_null("SmokeCam") as Camera3D
	if girl == null:
		push_error("No girl in restaurant smoke")
		return
	var aim: Vector3 = girl.global_position + Vector3(0.0, 1.0, 0.0)
	if cam:
		cam.current = true
	var shots: Array[Dictionary] = [
		{"file": "restaurant_01_approach.png", "alias": "idle", "pos": Vector3(3.8, 1.4, -1.2)},
		{"file": "restaurant_02_sit_enter_side.png", "alias": "sit_enter", "pos": Vector3(4.2, 1.25, -2.75)},
		{"file": "restaurant_03_sit_idle_full_body.png", "alias": "sit_idle", "pos": Vector3(4.4, 1.35, -2.75)},
		{"file": "restaurant_04_date_camera.png", "alias": "seated_gesture", "pos": Vector3(2.0, 1.45, -0.6)},
		{"file": "restaurant_05_exit.png", "alias": "sit_exit", "pos": Vector3(4.2, 1.25, -2.75)},
	]
	for s in shots:
		if girl.has_method("play_alias"):
			girl.call("play_alias", String(s["alias"]))
		if cam:
			cam.global_position = s["pos"]
			cam.look_at(aim, Vector3.UP)
		await _wait_frames(24)
		await _save_viewport("%s/%s" % [REST_OUT, s["file"]])
	scene.queue_free()
	await _wait_frames(2)
