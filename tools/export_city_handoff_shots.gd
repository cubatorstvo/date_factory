extends SceneTree
## Windowed (non-headless) screenshot export for city handoff.
## Dummy renderer under --headless returns null images; this must run with a real GPU backend.
## Usage: godot --path . -s res://tools/export_city_handoff_shots.gd


const OUT_DIR := "res://docs/city_handoff"
const SHOT_DIR := "res://docs/city_handoff/screenshots/current"
const ASSET_SHOT_DIR := "res://docs/city_handoff/screenshots"
const LIVE_CITY := "res://scenes/world/city/city.tscn"
const SLICE_CITY := "res://scenes/art/city/City_Street_Slice.tscn"
const MEGAKIT := "res://assets/environment/city/downtown_megakit/meshes"
const PLAYER_EYE_Y := 1.65
const PLAYER_FOV := 75.0

var _shot_index: Array = []
var _vp: SubViewport
var _world_host: Node3D
var _cam: Camera3D
var _key_light: DirectionalLight3D


func _initialize() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	_setup_capture_world()
	await _capture_all_screenshots()
	await _render_asset_sheets_from_catalog()
	_write_json("%s/screenshot_index_data.json" % OUT_DIR, {
		"count": _shot_index.size(),
		"shots": _shot_index,
		"note": "Captured with real renderer (non-headless minimized window)",
	})
	print("CITY_HANDOFF_SHOTS_PASS count=%d" % _shot_index.size())
	quit(0)


func _setup_capture_world() -> void:
	_vp = SubViewport.new()
	_vp.name = "HandoffVP"
	_vp.size = Vector2i(1600, 1000)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.transparent_bg = false
	_vp.world_3d = World3D.new()
	get_root().add_child(_vp)
	_world_host = Node3D.new()
	_world_host.name = "WorldHost"
	_vp.add_child(_world_host)
	_cam = Camera3D.new()
	_cam.name = "HandoffCam"
	_cam.current = true
	_cam.fov = PLAYER_FOV
	_world_host.add_child(_cam)
	_key_light = DirectionalLight3D.new()
	_key_light.rotation_degrees = Vector3(-55, 35, 0)
	_key_light.light_energy = 1.25
	_key_light.shadow_enabled = true
	_world_host.add_child(_key_light)


func _clear_world_children() -> void:
	for c: Node in _world_host.get_children():
		if c == _cam or c == _key_light:
			continue
		c.free()
	await process_frame


func _capture_all_screenshots() -> void:
	await _clear_world_children()
	var packed: PackedScene = load(LIVE_CITY) as PackedScene
	if packed == null:
		push_error("LIVE_CITY load fail")
		return
	var city: Node3D = packed.instantiate() as Node3D
	_world_host.add_child(city)
	for _i in 20:
		await process_frame

	var center := Vector3(-2.0, 0.0, 2.0)
	await _shot_ortho("01_topdown_full.png", Vector3(center.x, 55, center.z), Vector3(-90, 0, 0), 36.0,
		"Strict vertical top-down of entire live city footprint", "Establish overall occupied territory")
	await _shot_ortho("02_topdown_labeled.png", Vector3(center.x, 55, center.z), Vector3(-90, 0, 0), 36.0,
		"Top-down with in-scene Label3D POI names visible", "Identify main objects and POIs from above")

	_add_route_markers(city)
	for _r in 4:
		await process_frame
	await _shot_ortho("03_topdown_route.png", Vector3(center.x, 55, center.z), Vector3(-90, 0, 0), 36.0,
		"Top-down with temporary route markers Home→Commercial→Central→Park/Leisure/Agency",
		"Show current primary player circulation")

	var spawn_pos := _marker_pos(city, "HomeEntrance", Vector3(14.2, 0, 1.5))
	await _shot_eye("04_spawn_eye.png", spawn_pos + Vector3(0, PLAYER_EYE_Y, 0), Vector3(0, 90, 0),
		"Eye-level at HomeEntrance looking along +X then corrected via companion shot", "Player entry viewpoint")
	await _shot_eye("04b_spawn_toward_cafe.png", spawn_pos + Vector3(0, PLAYER_EYE_Y, 0),
		_look_rot(spawn_pos + Vector3(0, PLAYER_EYE_Y, 0), Vector3(10.5, PLAYER_EYE_Y, -4.35)),
		"Eye-level from HomeEntrance looking toward CafeTwoHearts", "Primary sightline home→cafe")

	var route: Array[Vector3] = [
		Vector3(14.2, 0, 1.5), Vector3(12.0, 0, 0.5), Vector3(10.5, 0, -1.0), Vector3(6.0, 0, 0.8),
		Vector3(2.0, 0, 0.5), Vector3(-2.0, 0, 1.0), Vector3(-2.0, 0, 4.0), Vector3(-6.0, 0, 6.0),
		Vector3(-8.0, 0, 8.0), Vector3(-6.0, 0, -2.0), Vector3(-11.0, 0, -2.0), Vector3(-15.0, 0, -2.0),
		Vector3(-19.0, 0, -2.0),
	]
	for i in route.size():
		var p: Vector3 = route[i]
		var look_target: Vector3 = route[mini(i + 1, route.size() - 1)]
		if look_target.is_equal_approx(p):
			look_target = p + Vector3(-1, 0, 0)
		await _shot_eye("05_route_%02d.png" % (i + 1), p + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(p + Vector3(0, PLAYER_EYE_Y, 0), look_target + Vector3(0, PLAYER_EYE_Y, 0)),
			"Route walk frame %d at %s" % [i + 1, str(p)], "Sequential player-eye frames along main loop")

	var junctions: Array = [
		{"name": "central_pocket", "pos": Vector3(-2, 0, 1), "look": Vector3(-8, 0, 1)},
		{"name": "park_gate", "pos": Vector3(0.5, 0, 2.5), "look": Vector3(-2, 0, 8)},
		{"name": "leisure_forecourt", "pos": Vector3(-8, 0, -1), "look": Vector3(-11, 0, -4)},
		{"name": "agency_lane", "pos": Vector3(-14, 0, -1.2), "look": Vector3(-19, 0, -4)},
		{"name": "commercial_l", "pos": Vector3(8, 0, 0), "look": Vector3(10.5, 0, -4)},
	]
	for j: Variant in junctions:
		var jd: Dictionary = j
		var jp: Vector3 = jd["pos"]
		var jl: Vector3 = jd["look"]
		await _shot_eye("06_junction_%s.png" % String(jd["name"]), jp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(jp + Vector3(0, PLAYER_EYE_Y, 0), jl + Vector3(0, PLAYER_EYE_Y, 0)),
			"Junction eye-level: %s" % String(jd["name"]), "Document current intersection readability")

	var pois: Array = [
		{"name": "home", "pos": Vector3(14.2, 0, 1.5), "look": Vector3(14.2, 0, -1)},
		{"name": "cafe", "pos": Vector3(10.5, 0, -2.5), "look": Vector3(10.5, 0, -4.35)},
		{"name": "flower", "pos": Vector3(8, 0, -3), "look": Vector3(7, 0, -5)},
		{"name": "central", "pos": Vector3(-1, 0, 1), "look": Vector3(-2, 0, 2)},
		{"name": "park_restaurant", "pos": Vector3(-6, 0, 7), "look": Vector3(-8, 0, 8)},
		{"name": "ducks", "pos": Vector3(-3, 0, 7), "look": Vector3(-2, 0, 8)},
		{"name": "gym", "pos": Vector3(-6, 0, -2), "look": Vector3(-6, 0, -3.9)},
		{"name": "cinema", "pos": Vector3(-11, 0, -2), "look": Vector3(-11, 0, -4.1)},
		{"name": "arcade", "pos": Vector3(-11.7, 0, 1), "look": Vector3(-11.7, 0, 2.9)},
		{"name": "photo", "pos": Vector3(-15.4, 0, -2.5), "look": Vector3(-15.4, 0, -4.6)},
		{"name": "agency", "pos": Vector3(-19.4, 0, -2.5), "look": Vector3(-19.4, 0, -4.6)},
		{"name": "bus", "pos": Vector3(-20, 0, 0), "look": Vector3(-22, 0, 0)},
	]
	for pv: Variant in pois:
		var pd: Dictionary = pv
		var pp: Vector3 = pd["pos"]
		var pl: Vector3 = pd["look"]
		await _shot_eye("07_poi_%s.png" % String(pd["name"]), pp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(pp + Vector3(0, PLAYER_EYE_Y, 0), pl + Vector3(0, PLAYER_EYE_Y, 0)),
			"POI eye-level: %s" % String(pd["name"]), "Document current POI presentation")

	var dense: Array = [
		{"name": "commercial_cluster", "pos": Vector3(9, 0, -1), "look": Vector3(8, 0, -4)},
		{"name": "leisure_cluster", "pos": Vector3(-9, 0, -1), "look": Vector3(-11, 0, -3)},
		{"name": "agency_cluster", "pos": Vector3(-16, 0, -1), "look": Vector3(-18, 0, -4)},
	]
	for dv: Variant in dense:
		var dd: Dictionary = dv
		var dp: Vector3 = dd["pos"]
		var dl: Vector3 = dd["look"]
		await _shot_eye("08_dense_%s.png" % String(dd["name"]), dp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(dp + Vector3(0, PLAYER_EYE_Y, 0), dl + Vector3(0, PLAYER_EYE_Y, 0)),
			"Dense area: %s" % String(dd["name"]), "Show crowding / visual noise for redesign")

	var edges: Array = [
		{"name": "east_to_center", "pos": Vector3(18, 0, 1), "look": Vector3(-2, 0, 1)},
		{"name": "west_to_center", "pos": Vector3(-21, 0, 0), "look": Vector3(-2, 0, 1)},
		{"name": "park_to_center", "pos": Vector3(-2, 0, 10), "look": Vector3(-2, 0, 1)},
	]
	for ev: Variant in edges:
		var ed: Dictionary = ev
		var ep: Vector3 = ed["pos"]
		var el: Vector3 = ed["look"]
		await _shot_eye("09_edge_%s.png" % String(ed["name"]), ep + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(ep + Vector3(0, PLAYER_EYE_Y, 0), el + Vector3(0, PLAYER_EYE_Y, 0)),
			"From edge toward center: %s" % String(ed["name"]), "Edge concealment and inbound readability")

	var centers: Array = [
		{"name": "to_home", "pos": Vector3(-2, 0, 1), "look": Vector3(14, 0, 1)},
		{"name": "to_park", "pos": Vector3(-2, 0, 1), "look": Vector3(-2, 0, 8)},
		{"name": "to_agency", "pos": Vector3(-2, 0, 1), "look": Vector3(-19, 0, -2)},
		{"name": "to_cinema", "pos": Vector3(-2, 0, 1), "look": Vector3(-11, 0, -4)},
	]
	for cv: Variant in centers:
		var cd: Dictionary = cv
		var cp: Vector3 = cd["pos"]
		var cl: Vector3 = cd["look"]
		await _shot_eye("10_center_%s.png" % String(cd["name"]), cp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(cp + Vector3(0, PLAYER_EYE_Y, 0), cl + Vector3(0, PLAYER_EYE_Y, 0)),
			"From center toward landmark: %s" % String(cd["name"]), "Landmark sightlines from central pocket")

	await _clear_world_children()
	var slice_ps: PackedScene = load(SLICE_CITY) as PackedScene
	if slice_ps != null:
		var slice: Node3D = slice_ps.instantiate() as Node3D
		_world_host.add_child(slice)
		for _j in 16:
			await process_frame
		await _shot_ortho("slice_01_topdown.png", Vector3(0, 20, 0), Vector3(-90, 0, 0), 18.0,
			"Top-down of City_Street_Slice art testbed", "Document named analysis scene (kit slice, not live city)")
		await _shot_eye("slice_02_spawn.png", Vector3(0, PLAYER_EYE_Y, 4), Vector3(0, 180, 0),
			"Eye-level at City_Street_Slice Spawn", "Show kit-slice player view")


func _render_asset_sheets_from_catalog() -> void:
	var catalog_path := ProjectSettings.globalize_path("%s/city_asset_catalog.json" % OUT_DIR)
	if not FileAccess.file_exists(catalog_path):
		push_error("catalog missing")
		return
	var txt: String = FileAccess.get_file_as_string(catalog_path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var assets: Array = (parsed as Dictionary).get("assets", [])
	var groups: Dictionary = {"buildings": [], "roads": [], "landmarks": [], "props": []}
	for e: Variant in assets:
		var d: Dictionary = e
		var cat: String = String(d.get("category", ""))
		var path: String = String(d.get("path", ""))
		if not (path.ends_with(".gltf") or path.ends_with(".glb")):
			continue
		if cat in ["buildings", "corner_buildings", "shops_commercial", "residential_facades"]:
			(groups["buildings"] as Array).append(d)
		elif cat in ["roads", "intersections", "sidewalks", "alleys"]:
			(groups["roads"] as Array).append(d)
		elif cat == "landmarks":
			(groups["landmarks"] as Array).append(d)
		elif cat in ["large_street_decor", "small_street_decor", "vegetation", "lighting", "signage", "transport", "date_objects", "walls_fences", "entrances_doors"]:
			(groups["props"] as Array).append(d)
	if (groups["landmarks"] as Array).is_empty():
		for e2: Variant in assets:
			var d2: Dictionary = e2
			var n2: String = String(d2.get("name", "")).to_lower()
			if n2.begins_with("building_"):
				(groups["landmarks"] as Array).append(d2)
	await _contact_sheet_series("assets_buildings", groups["buildings"])
	await _contact_sheet_series("assets_roads", groups["roads"])
	await _contact_sheet_series("assets_landmarks", groups["landmarks"])
	await _contact_sheet_series("assets_props", groups["props"])


func _contact_sheet_series(prefix: String, items: Array) -> void:
	var batch_size := 24
	var page := 1
	var i := 0
	while i < items.size():
		var batch: Array = items.slice(i, mini(i + batch_size, items.size()))
		await _render_contact_sheet("%s_%02d.png" % [prefix, page], batch)
		i += batch_size
		page += 1


func _render_contact_sheet(filename: String, batch: Array) -> void:
	await _clear_world_children()
	var cols := 6
	var spacing := 8.0
	var idx := 0
	for e: Variant in batch:
		var d: Dictionary = e
		var path: String = String(d.get("path", ""))
		var ps: PackedScene = load(path) as PackedScene
		var cell_x: float = float(idx % cols) * spacing
		var cell_z: float = float(int(idx / cols)) * spacing
		if ps != null:
			var inst: Node3D = ps.instantiate() as Node3D
			if inst != null:
				_world_host.add_child(inst)
				inst.position = Vector3(cell_x, 0, cell_z)
				var lbl := Label3D.new()
				lbl.text = String(d.get("name", ""))
				lbl.font_size = 28
				lbl.position = Vector3(0, 3.2, 0)
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				inst.add_child(lbl)
		idx += 1
	for _f in 18:
		await process_frame
	var rows: int = int(ceil(float(maxi(batch.size(), 1)) / float(cols)))
	var cam_x: float = (float(mini(cols, maxi(batch.size(), 1)) - 1) * spacing) * 0.5
	var cam_z: float = (float(maxi(rows, 1) - 1) * spacing) * 0.5
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = maxf(28.0, float(maxi(cols, rows)) * spacing * 0.85)
	_cam.position = Vector3(cam_x, 40, cam_z)
	_cam.rotation_degrees = Vector3(-90, 0, 0)
	for _g in 10:
		await process_frame
	var img: Image = _vp.get_texture().get_image()
	if img == null:
		push_error("CONTACT_NULL %s" % filename)
		return
	var out_path: String = "%s/%s" % [ASSET_SHOT_DIR, filename]
	var err: Error = img.save_png(ProjectSettings.globalize_path(out_path))
	print("CONTACT %s n=%d err=%s" % [filename, batch.size(), error_string(err)])
	_shot_index.append({
		"file": "screenshots/%s" % filename,
		"camera_position": _v3(_cam.position),
		"camera_rotation_degrees": [-90.0, 0.0, 0.0],
		"mode": "orthographic_contact_sheet",
		"what": "Contact sheet %s (%d assets)" % [filename, batch.size()],
		"why": "Visual inventory of available kit pieces",
	})


func _add_route_markers(city: Node3D) -> void:
	var pts: Array[Vector3] = [
		Vector3(14.2, 0.2, 1.5), Vector3(10.5, 0.2, -1.0), Vector3(6.0, 0.2, 0.8),
		Vector3(-2.0, 0.2, 1.0), Vector3(-2.0, 0.2, 8.0), Vector3(-8.0, 0.2, -2.0), Vector3(-19.0, 0.2, -2.0),
	]
	var labels: Array[String] = ["1 Home", "2 Cafe", "3 Mid", "4 Central", "5 Park", "6 Leisure", "7 Agency"]
	var holder := Node3D.new()
	holder.name = "HandoffRouteOverlay"
	city.add_child(holder)
	for i in pts.size():
		var lbl := Label3D.new()
		lbl.text = labels[i]
		lbl.font_size = 48
		lbl.modulate = Color(1.0, 0.85, 0.2)
		lbl.position = pts[i] + Vector3(0, 2.5, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		holder.add_child(lbl)
		var stem := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 2.2, 0.35)
		stem.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.75, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.1)
		stem.material_override = mat
		stem.position = pts[i] + Vector3(0, 1.1, 0)
		holder.add_child(stem)


func _marker_pos(city: Node3D, marker_name: String, fallback: Vector3) -> Vector3:
	var m: Node = city.find_child(marker_name, true, false)
	if m is Node3D:
		return (m as Node3D).global_position
	return fallback


func _look_rot(from: Vector3, to: Vector3) -> Vector3:
	var dir: Vector3 = to - from
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	var basis := Basis.looking_at(dir.normalized(), Vector3.UP)
	return basis.get_euler() * 180.0 / PI


func _shot_ortho(filename: String, pos: Vector3, rot_deg: Vector3, ortho_size: float, what: String, why: String) -> void:
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = ortho_size
	_cam.position = pos
	_cam.rotation_degrees = rot_deg
	_cam.current = true
	for _i in 8:
		await process_frame
	_save_shot(filename, pos, rot_deg, what, why, "orthographic", ortho_size)


func _shot_eye(filename: String, pos: Vector3, rot_deg: Vector3, what: String, why: String) -> void:
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = PLAYER_FOV
	_cam.position = pos
	_cam.rotation_degrees = rot_deg
	_cam.current = true
	for _i in 8:
		await process_frame
	_save_shot(filename, pos, rot_deg, what, why, "player_eye", PLAYER_FOV)


func _save_shot(filename: String, pos: Vector3, rot_deg: Vector3, what: String, why: String, mode: String, fov_or_size: float) -> void:
	var img: Image = _vp.get_texture().get_image()
	if img == null:
		push_error("SHOT_NULL %s" % filename)
		return
	var path: String = "%s/%s" % [SHOT_DIR, filename]
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	_shot_index.append({
		"file": "screenshots/current/%s" % filename,
		"camera_position": _v3(pos),
		"camera_rotation_degrees": _v3(rot_deg),
		"mode": mode,
		"fov_or_ortho": fov_or_size,
		"what": what,
		"why": why,
		"save_error": error_string(err),
	})
	print("SHOT %s err=%s" % [filename, error_string(err)])


func _write_json(res_path: String, data: Dictionary) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(res_path), FileAccess.WRITE)
	if f == null:
		push_error("WRITE_FAIL %s" % res_path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func _v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]
