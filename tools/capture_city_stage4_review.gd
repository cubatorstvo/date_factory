extends SceneTree
## Stage-4 review captures into docs/city_stage4_review/.
## Must run with a real GPU backend (minimized window). Dummy --headless returns null images.
## Usage: godot --path . -s res://tools/capture_city_stage4_review.gd


const CITY := "res://scenes/world/city/city.tscn"
const OUT_DIR := "res://docs/city_stage4_review/"


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(CITY) as PackedScene
	if packed == null:
		push_error("CAPTURE_FAIL load city")
		quit(2)
		return

	var vp := SubViewport.new()
	vp.name = "CaptureVP"
	vp.size = Vector2i(1600, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	vp.world_3d = World3D.new()
	get_root().add_child(vp)

	var city: Node3D = packed.instantiate() as Node3D
	vp.add_child(city)

	var cam := Camera3D.new()
	cam.name = "ReviewCam"
	cam.current = true
	city.add_child(cam)

	var key := DirectionalLight3D.new()
	key.name = "CaptureKey"
	key.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	key.light_color = Color(0.7, 0.75, 0.95)
	key.light_energy = 0.9
	city.add_child(key)

	# Ensure gates start locked visually.
	for gname in ["ParkGate", "AgencyGate", "AgencyGateLeisure"]:
		var g := city.get_node_or_null("Decor/%s" % gname) as Node3D
		if g != null and g.has_method("set_unlocked"):
			g.call("set_unlocked", false)
		elif g != null:
			g.visible = true

	var shots: Array = [
		{"file": "01_topdown_locked.png", "pos": Vector3(1.0, 45.0, 7.0), "look": Vector3(1.0, 0.0, 7.0), "ortho": 52.0},
		{"file": "03_spawn_view.png", "pos": Vector3(30.0, 1.7, 17.0), "look": Vector3(24.5, 1.6, 15.0), "ortho": 0.0},
		{"file": "04_route_home_to_cafe.png", "pos": Vector3(28.0, 1.7, 16.0), "look": Vector3(24.5, 1.4, 15.0), "ortho": 0.0},
		{"file": "05_route_commercial.png", "pos": Vector3(16.0, 1.7, 0.0), "look": Vector3(6.0, 1.4, 0.0), "ortho": 0.0},
		{"file": "06_route_central.png", "pos": Vector3(1.0, 1.8, -1.0), "look": Vector3(0.0, 1.4, 4.0), "ortho": 0.0},
		{"file": "07_park_gate.png", "pos": Vector3(0.0, 1.8, 4.5), "look": Vector3(0.0, 1.6, 8.5), "ortho": 0.0},
		{"file": "08_through_park_gate_restaurant.png", "pos": Vector3(0.5, 1.8, 9.0), "look": Vector3(11.5, 1.6, 22.0), "ortho": 0.0},
		{"file": "09_agency_gate.png", "pos": Vector3(-4.5, 1.8, 0.0), "look": Vector3(-8.5, 1.6, 0.0), "ortho": 0.0},
		{"file": "10_agency_gate_leisure.png", "pos": Vector3(-21.5, 1.8, 15.0), "look": Vector3(-21.5, 1.6, 12.0), "ortho": 0.0},
		{"file": "11_route_leisure.png", "pos": Vector3(-18.0, 1.8, 20.0), "look": Vector3(-27.0, 1.5, 20.0), "ortho": 0.0},
		{"file": "12_route_agency_lane.png", "pos": Vector3(-18.0, 1.8, 0.0), "look": Vector3(-28.0, 1.5, 0.0), "ortho": 0.0},
	]

	var ok_count := 0
	for shot_v in shots:
		var shot: Dictionary = shot_v as Dictionary
		if await _capture(vp, cam, str(shot["file"]), shot["pos"] as Vector3, shot["look"] as Vector3, float(shot["ortho"])):
			ok_count += 1

	for gname in ["ParkGate", "AgencyGate", "AgencyGateLeisure"]:
		var g2 := city.get_node_or_null("Decor/%s" % gname) as Node3D
		if g2 != null and g2.has_method("set_unlocked"):
			g2.call("set_unlocked", true)
		elif g2 != null:
			g2.visible = false
	if await _capture(vp, cam, "02_topdown_all_open.png", Vector3(1.0, 45.0, 7.0), Vector3(1.0, 0.0, 7.0), 52.0):
		ok_count += 1

	print("CAPTURE_CITY_STAGE4_PASS count=%d dir=%s" % [ok_count, OUT_DIR])
	if ok_count < 12:
		quit(1)
		return
	quit(0)


func _capture(vp: SubViewport, cam: Camera3D, file_name: String, pos: Vector3, look: Vector3, ortho_size: float) -> bool:
	if ortho_size > 0.0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho_size
		cam.position = pos
		cam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = 70.0
		cam.position = pos
		cam.look_at(look, Vector3.UP)
	for _i in 16:
		await process_frame
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		push_error("CAPTURE_FAIL texture null %s" % file_name)
		return false
	var img: Image = tex.get_image()
	if img == null:
		push_error("CAPTURE_FAIL image null %s" % file_name)
		return false
	var path := OUT_DIR + file_name
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE %s err=%s %dx%d" % [path, error_string(err), img.get_width(), img.get_height()])
	return err == OK
