extends SceneTree
## Capture technical validation screenshots with auto-framed camera + probe light.


const OUT_DIR := "res://docs/asset_validation/screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))

	var shots: Array[Dictionary] = [
		{"file": "01_apartment.png", "scene": "res://scenes/art/rooms/Apartment_Blockout_Finalized.tscn"},
		{"file": "02_city_street.png", "scene": "res://scenes/art/city/City_Street_Slice.tscn"},
		{"file": "03_sushi_restaurant.png", "scene": "res://scenes/art/restaurant/Sushi_Date_Restaurant.tscn"},
		{"file": "04_clone_lab.png", "scene": "res://scenes/art/lab/Clone_Lab_Base.tscn"},
		{"file": "05_date_factory.png", "scene": "res://scenes/art/factory/Date_Factory_Base.tscn"},
		{"file": "06_character_testbed_idle.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "idle"},
		{"file": "07_character_testbed_walk.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "walk"},
		{"file": "08_character_testbed_sit.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "sit"},
		{"file": "09_character_testbed_gesture.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "gesture"},
	]
	for spec in shots:
		await _capture(spec)
	print("SHOTS_DONE ", shots.size())
	quit(0)


func _capture(spec: Dictionary) -> void:
	var path := str(spec["scene"])
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("scene missing " + path)
		return
	var scene := ps.instantiate()
	get_root().add_child(scene)

	var ui := scene.get_node_or_null("TechUI")
	if ui != null:
		ui.visible = false
	# Hide floating name labels that dominate empty-looking shots
	_hide_labels(scene)

	if not _has_light(scene):
		var sun := DirectionalLight3D.new()
		sun.name = "_CaptureSun"
		sun.light_energy = 1.25
		scene.add_child(sun)
		sun.look_at_from_position(Vector3(6, 10, 8), Vector3.ZERO, Vector3.UP)

	if not _has_world_env(scene):
		var we := WorldEnvironment.new()
		we.name = "_CaptureEnv"
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.22, 0.24, 0.28)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.7, 0.72, 0.78)
		env.ambient_light_energy = 0.9
		we.environment = env
		scene.add_child(we)

	var aabb := _world_aabb(scene)
	var center := aabb.get_center()
	if aabb.size.length() < 0.01:
		center = Vector3(0, 1, 0)
		aabb = AABB(Vector3(-4, 0, -4), Vector3(8, 3, 8))

	var cam := _find_camera(scene)
	if cam == null:
		cam = Camera3D.new()
		cam.name = "_CaptureCamera"
		scene.add_child(cam)
	cam.current = true
	var eye: Vector3
	var look: Vector3
	if spec.has("alias"):
		# Character lineup: eye-level framing
		eye = Vector3(0.0, 1.55, 8.2)
		look = Vector3(0.0, 1.0, 0.0)
	else:
		var radius: float = maxf(aabb.size.length() * 0.42, 5.0)
		eye = center + Vector3(radius * 0.7, maxf(radius * 0.35, 2.2), radius * 0.85)
		look = center + Vector3(0, 0.6, 0)
	cam.look_at_from_position(eye, look, Vector3.UP)

	if spec.has("alias"):
		_force_alias(scene, str(spec["alias"]))

	for i in 18:
		await process_frame

	var img: Image = get_root().get_texture().get_image()
	var out_path := OUT_DIR + str(spec["file"])
	if img != null:
		var err := img.save_png(out_path)
		print("SHOT ", out_path, " err=", err, " aabb=", aabb, " eye=", eye)
	else:
		push_error("null image " + out_path)
	scene.queue_free()
	await process_frame
	await process_frame


func _force_alias(scene: Node, alias: String) -> void:
	if scene.has_method("_manual"):
		scene.call("_manual", alias)
		return
	var chars := scene.get_node_or_null("Characters")
	if chars == null:
		return
	if "_auto_demo" in scene:
		scene.set("_auto_demo", false)
	for c in chars.get_children():
		if c.has_method("play_alias"):
			c.call("play_alias", alias)


func _hide_labels(n: Node) -> void:
	if n is Label3D or n is Label:
		(n as CanvasItem).visible = false if n is CanvasItem else false
		if n is Label3D:
			(n as Label3D).visible = false
	for c in n.get_children():
		_hide_labels(c)


func _has_light(n: Node) -> bool:
	if n is Light3D:
		return true
	for c in n.get_children():
		if _has_light(c):
			return true
	return false


func _has_world_env(n: Node) -> bool:
	if n is WorldEnvironment:
		return true
	for c in n.get_children():
		if _has_world_env(c):
			return true
	return false


func _find_camera(n: Node) -> Camera3D:
	if n is Camera3D:
		return n as Camera3D
	for c in n.get_children():
		var r := _find_camera(c)
		if r != null:
			return r
	return null


func _world_aabb(n: Node) -> AABB:
	var has := false
	var aabb := AABB()
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi := n as MeshInstance3D
		var a := mi.global_transform * mi.get_aabb()
		if a.size.length() > 0.0001:
			aabb = a
			has = true
	for c in n.get_children():
		var ca := _world_aabb(c)
		if ca.size.length() > 0.0001:
			if not has:
				aabb = ca
				has = true
			else:
				aabb = aabb.merge(ca)
	return aabb if has else AABB()
