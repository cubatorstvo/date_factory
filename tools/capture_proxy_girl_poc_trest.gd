extends SceneTree
## Capture GirlProxyPOC_TRest proofs. Do NOT use --headless.
## Usage: Godot --path . -s res://tools/capture_proxy_girl_poc_trest.gd

const OUT_DIR := "C:/Users/User/Downloads/date_factory_proxy_work/trest_fix"
const TESTBED := "res://scenes/art/testbeds/ProxyGirlPOC_TRest_Testbed.tscn"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	call_deferred("_run")


func _run() -> void:
	await _capture()
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
	print("[PROXY_TREST_CAPTURE] saved %s err=%s" % [path, err])


func _capture() -> void:
	var packed := load(TESTBED) as PackedScene
	if packed == null:
		push_error("Missing TRest testbed")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await _wait_frames(20)
	var girl := scene.get_node_or_null("GirlProxyPOC")
	var front := scene.get_node_or_null("CamFront") as Camera3D
	var side := scene.get_node_or_null("CamSide") as Camera3D
	var chair_seat := scene.get_node_or_null("ChairSeat") as Node3D
	var chair_back := scene.get_node_or_null("ChairBack") as Node3D
	if girl:
		girl.rotation_degrees.y = 180.0
	var shots: Array[Dictionary] = [
		{"file": "godot_fixed_01_rest_or_idle_front.png", "alias": "idle", "cam": "front"},
		{"file": "godot_fixed_02_walk.png", "alias": "walk", "cam": "side"},
		{"file": "godot_fixed_03_sit_idle_side.png", "alias": "sit_idle", "cam": "side"},
		{"file": "godot_fixed_04_seated_gesture.png", "alias": "seated_gesture", "cam": "front"},
	]
	for s in shots:
		if girl and girl.has_method("play_alias"):
			var ok: bool = girl.call("play_alias", String(s["alias"]))
			print("[PROXY_TREST_CAPTURE] play_alias %s -> %s" % [s["alias"], ok])
		if String(s["cam"]) == "front" and front:
			if chair_seat:
				chair_seat.visible = false
			if chair_back:
				chair_back.visible = false
			front.current = true
		elif side:
			if chair_seat:
				chair_seat.visible = true
			if chair_back:
				chair_back.visible = true
			side.current = true
		await _wait_frames(50)
		await _save_viewport("%s/%s" % [OUT_DIR, s["file"]])
	scene.queue_free()
