extends SceneTree
## Stage-5 FPS review package. Minimized GPU window (dummy headless cannot capture).
## Usage: godot --path . -s res://tools/capture_city_stage5_review.gd


const CITY := "res://scenes/world/city/city.tscn"
const OUT_DIR := "res://docs/city_stage4_review/"
const EYE_Y := 1.65
const FOV := 75.0


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var packed: PackedScene = load(CITY) as PackedScene
	if packed == null:
		push_error("CAPTURE5_FAIL load")
		quit(2)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 1000)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.world_3d = World3D.new()
	get_root().add_child(vp)
	var city: Node3D = packed.instantiate() as Node3D
	vp.add_child(city)
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = FOV
	city.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, 28, 0)
	key.light_color = Color(0.55, 0.62, 0.85)
	key.light_energy = 0.55
	city.add_child(key)

	for gname in ["ParkGate", "AgencyGate", "AgencyGateLeisure"]:
		var g := city.get_node_or_null("Decor/%s" % gname) as Node3D
		if g != null and g.has_method("set_unlocked"):
			g.call("set_unlocked", false)

	var shots: Array = [
		{"f": "01_topdown_locked.png", "pos": Vector3(1, 48, 8), "look": Vector3(1, 0, 8), "ortho": 56.0},
		{"f": "03_spawn_view.png", "pos": Vector3(29.2, EYE_Y, 9.0), "look": Vector3(24.9, 1.55, 14.2), "ortho": 0.0},
		{"f": "04_spawn_to_cafe_wide.png", "pos": Vector3(28.0, EYE_Y, 11.0), "look": Vector3(24.9, 1.5, 14.2), "ortho": 0.0},
		{"f": "05_commercial_street_both_directions.png", "pos": Vector3(14.0, EYE_Y, 0.2), "look": Vector3(6.0, 1.45, 0.2), "ortho": 0.0},
		{"f": "06_central_pocket_to_both_gates.png", "pos": Vector3(1.5, EYE_Y, -2.0), "look": Vector3(0.0, 1.5, 6.8), "ortho": 0.0},
		{"f": "07_park_gate_locked_restaurant_visible.png", "pos": Vector3(0.5, EYE_Y, 4.2), "look": Vector3(3.2, 1.8, 21.0), "ortho": 0.0},
		{"f": "08_park_loop_pond.png", "pos": Vector3(6.8, EYE_Y, 13.8), "look": Vector3(1.0, 1.1, 17.5), "ortho": 0.0},
		{"f": "09_leisure_forecourt_wide.png", "pos": Vector3(-12.5, EYE_Y, 19.5), "look": Vector3(-24.0, 1.8, 21.0), "ortho": 0.0},
		{"f": "10_agency_gate_central_side.png", "pos": Vector3(-4.0, EYE_Y, 0.8), "look": Vector3(-8.2, 1.5, 0.0), "ortho": 0.0},
		{"f": "11_agency_gate_leisure_side.png", "pos": Vector3(-18.5, EYE_Y, 18.5), "look": Vector3(-22.5, 1.5, 13.8), "ortho": 0.0},
		{"f": "12_agency_lane_wide.png", "pos": Vector3(-14.5, EYE_Y, 0.5), "look": Vector3(-28.5, 1.45, 1.0), "ortho": 0.0},
	]
	var ok := 0
	for s_v in shots:
		var s: Dictionary = s_v
		if await _capture(vp, cam, str(s["f"]), s["pos"] as Vector3, s["look"] as Vector3, float(s["ortho"])):
			ok += 1

	for gname2 in ["ParkGate", "AgencyGate", "AgencyGateLeisure"]:
		var g2 := city.get_node_or_null("Decor/%s" % gname2) as Node3D
		if g2 != null and g2.has_method("set_unlocked"):
			g2.call("set_unlocked", true)
		elif g2 != null:
			g2.visible = false
	if await _capture(vp, cam, "02_topdown_all_open.png", Vector3(1, 48, 8), Vector3(1, 0, 8), 56.0):
		ok += 1

	print("CAPTURE_CITY_STAGE5_PASS count=%d" % ok)
	quit(0 if ok >= 12 else 1)


func _capture(vp: SubViewport, cam: Camera3D, file_name: String, pos: Vector3, look: Vector3, ortho: float) -> bool:
	if ortho > 0.0:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = ortho
		cam.position = pos
		cam.rotation_degrees = Vector3(-90, 0, 0)
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.fov = FOV
		cam.position = pos
		cam.look_at(look, Vector3.UP)
	for _i in 14:
		await process_frame
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		return false
	var img: Image = tex.get_image()
	if img == null:
		return false
	var err: Error = img.save_png(ProjectSettings.globalize_path(OUT_DIR + file_name))
	print("CAPTURE5 %s err=%s" % [file_name, error_string(err)])
	return err == OK
