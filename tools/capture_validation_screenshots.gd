extends SceneTree
## Capture technical validation screenshots with auto-framed camera + probe light.


const OUT_DIR := "res://docs/vertical_slice/screenshots/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	if DisplayServer.get_name().to_lower() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))

	var shots: Array[Dictionary] = [
		{"file": "01_vertical_apartment.png", "scene": "res://scenes/world/vertical_slice/apartment.tscn", "eye": Vector3(4.8, 2.4, 4.2), "look": Vector3(0.0, 1.0, -0.6), "fov": 58.0},
		{"file": "02_vertical_street.png", "scene": "res://scenes/world/vertical_slice/street.tscn", "eye": Vector3(-17.0, 2.8, 5.5), "look": Vector3(8.0, 1.0, -3.5), "fov": 65.0},
		{"file": "03_vertical_restaurant.png", "scene": "res://scenes/world/vertical_slice/restaurant.tscn", "eye": Vector3(5.2, 2.6, 4.4), "look": Vector3(0.0, 1.0, 0.0), "fov": 56.0},
		{"file": "04_character_idle.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "idle"},
		{"file": "05_character_approach.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "approach"},
		{"file": "06_character_sit_enter.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "sit_enter"},
		{"file": "07_character_sit_idle.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "sit_idle"},
		{"file": "08_character_seated_gesture.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "seated_gesture"},
		{"file": "09_character_sit_exit.png", "scene": "res://scenes/art/testbeds/Character_Testbed.tscn", "alias": "sit_exit"},
	]
	for spec in shots:
		await _capture(spec)
	print("SHOTS_DONE ", shots.size())
	for _cleanup_frame: int in range(4):
		await process_frame
	RenderingServer.force_sync()
	quit(0)


func _capture(spec: Dictionary) -> void:
	var path := str(spec["scene"])
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("scene missing " + path)
		return
	var scene := ps.instantiate() as Node
	if scene == null:
		push_error("scene instantiate failed " + path)
		return
	get_root().add_child(scene)
	await process_frame
	await process_frame

	var ui := scene.get_node_or_null("TechUI")
	if ui != null:
		ui.visible = false
	# Hide floating name labels and authoring-only preview actors.
	_hide_labels(scene)
	var preview_girl := scene.get_node_or_null("Characters/DateGirl") as Node3D
	if preview_girl:
		preview_girl.visible = false
		preview_girl.process_mode = Node.PROCESS_MODE_DISABLED

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
	cam.fov = float(spec.get("fov", 50.0 if spec.has("alias") else 55.0))
	var eye: Vector3
	var look: Vector3
	if spec.has("eye") and spec.has("look"):
		eye = spec["eye"]
		look = spec["look"]
	elif spec.has("alias"):
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

	for _frame: int in range(18):
		await process_frame

	var img: Image = get_root().get_texture().get_image()
	var out_path := OUT_DIR + str(spec["file"])
	if img != null:
		var err := img.save_png(out_path)
		print("SHOT ", out_path, " err=", err, " aabb=", aabb, " eye=", eye)
	else:
		push_error("null image " + out_path)
	scene.free()
	for _cleanup_frame: int in range(3):
		await process_frame


func _force_alias(scene: Node, alias: String) -> void:
	if scene.has_method("_manual"):
		scene.call("_manual", alias)
		return
	var chars := scene.get_node_or_null("Characters")
	if chars == null:
		return
	if _has_property(scene, &"_auto_demo"):
		scene.set("_auto_demo", false)
	for c in chars.get_children():
		if c.has_method("play_alias"):
			c.call("play_alias", alias)


func _hide_labels(n: Node) -> void:
	if n is Label3D:
		(n as Label3D).visible = false
	elif n is Label:
		(n as Label).visible = false
	for c: Node in n.get_children():
		_hide_labels(c)


func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


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
