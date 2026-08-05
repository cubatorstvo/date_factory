extends SceneTree
## Stage-4 city rebuild from date_factory_city_stage4_build_manifest.json.
## Creates required prefabs, then rewrites city.tscn under GeneratedCity + managed POIs.


const MANIFEST_PATH := "res://tools/date_factory_city_stage4_build_manifest.json"
const CITY_OUT := "res://scenes/world/city/city.tscn"
const PREFAB_DIR := "res://scenes/art/city/prefabs/"
const GATE_SCRIPT := "res://scenes/art/city/prefabs/district_gate.gd"

const P_BUILDING_S := "res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf"
const P_BUILDING_M := "res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf"
const P_DOOR := "res://assets/environment/city/downtown_megakit/meshes/Door_1.gltf"
const P_WINDOW := "res://assets/environment/city/downtown_megakit/meshes/Brick_Window_Square_Single.gltf"
const P_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Prop_Planter_Single.gltf"
const P_SIGN := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_Sign.gltf"
const P_SHELF := "res://assets/environment/interior/house_interior/meshes/Shelf_1.fbx"
const P_BOOKSHELF := "res://assets/environment/interior/house_interior/meshes/Bookshelf.fbx"
const P_COUNTER := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Counter_Straight.gltf"
const P_TABLE := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Table.gltf"
const P_STOOL := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Stool.gltf"
const P_PLANT := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_Plant1.gltf"

var _created: PackedStringArray = PackedStringArray()
var _skipped: PackedStringArray = PackedStringArray()
var _fatal: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var manifest: Dictionary = _load_manifest()
	if manifest.is_empty():
		push_error("STAGE4_FAIL manifest empty")
		quit(2)
		return
	_validate_manifest(manifest)
	if not _fatal.is_empty():
		for f in _fatal:
			push_error("STAGE4_FAIL %s" % f)
		quit(3)
		return

	_ensure_required_prefabs(manifest)
	if not _fatal.is_empty():
		for f in _fatal:
			push_error("STAGE4_FAIL %s" % f)
		quit(4)
		return

	var root: Node3D = _build_city(manifest)
	if not _fatal.is_empty():
		for f in _fatal:
			push_error("STAGE4_FAIL %s" % f)
		root.free()
		quit(5)
		return
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		push_error("STAGE4_FAIL pack: %s" % error_string(err))
		quit(6)
		return
	err = ResourceSaver.save(packed, CITY_OUT)
	if err != OK:
		push_error("STAGE4_FAIL save: %s" % error_string(err))
		quit(7)
		return

	print("STAGE4_BUILD_OK path=%s" % CITY_OUT)
	print("STAGE4_CREATED count=%d" % _created.size())
	for c in _created:
		print("STAGE4_CREATED %s" % c)
	print("STAGE4_SKIPPED count=%d" % _skipped.size())
	for s in _skipped:
		print("STAGE4_SKIPPED %s" % s)
	root.free()
	quit(0)


func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_fatal.append("missing manifest %s" % MANIFEST_PATH)
		return {}
	var txt: String = FileAccess.get_file_as_string(MANIFEST_PATH)
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		_fatal.append("manifest is not a dictionary")
		return {}
	return data as Dictionary


func _validate_manifest(m: Dictionary) -> void:
	for key in ["poi_buildings", "non_building_pois", "gates", "roads", "markers", "required_new_prefabs"]:
		if not m.has(key):
			_fatal.append("missing field %s" % key)
	if m.has("roads"):
		var roads: Dictionary = m["roads"] as Dictionary
		for rk in ["corridors", "plazas", "park_path", "pond"]:
			if not roads.has(rk):
				_fatal.append("missing roads.%s" % rk)


func _require_asset(path: String) -> void:
	if path == "" or path.begins_with("procedural"):
		return
	if not ResourceLoader.exists(path):
		_fatal.append("missing asset %s" % path)


func _ensure_required_prefabs(m: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREFAB_DIR))
	var req: Array = m.get("required_new_prefabs", []) as Array
	for item_v in req:
		var item: Dictionary = item_v as Dictionary
		var path: String = str(item.get("path", ""))
		_require_asset_for_prefab(path)
		if path.ends_with("PlayerHomeFacade.tscn"):
			_save_prefab(_prefab_home())
		elif path.ends_with("CafeTwoHearts.tscn"):
			_save_prefab(_prefab_cafe())
		elif path.ends_with("BookstoreFacade.tscn"):
			_save_prefab(_prefab_bookstore())
		elif path.ends_with("DistrictGate.tscn"):
			_save_prefab(_prefab_district_gate())
		elif path.ends_with("StreetLampRomance.tscn"):
			_save_prefab(_prefab_street_lamp())
		else:
			_fatal.append("unknown required prefab %s" % path)


func _require_asset_for_prefab(path: String) -> void:
	if path.ends_with("PlayerHomeFacade.tscn") or path.ends_with("BookstoreFacade.tscn"):
		_require_asset(P_BUILDING_S)
	elif path.ends_with("CafeTwoHearts.tscn"):
		_require_asset(P_BUILDING_M)


func _save_prefab(root: Node3D) -> void:
	var path := PREFAB_DIR + root.name + ".tscn"
	# Manifest names differ for some roots.
	if root.name == "HomeFacade":
		path = "res://scenes/art/city/prefabs/PlayerHomeFacade.tscn"
	elif root.name == "BookstoreLeisure":
		path = "res://scenes/art/city/prefabs/BookstoreFacade.tscn"
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		_fatal.append("pack prefab %s: %s" % [path, error_string(err)])
		root.free()
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		_fatal.append("save prefab %s: %s" % [path, error_string(err)])
	else:
		_created.append(path)
	root.free()


func _build_city(m: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "City"

	var architecture := Node3D.new()
	architecture.name = "Architecture"
	root.add_child(architecture)
	_build_ground_pad(architecture)

	var buildings := Node3D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)

	var pois := Node3D.new()
	pois.name = "POIs"
	root.add_child(pois)

	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)

	var districts := Node3D.new()
	districts.name = "Districts"
	root.add_child(districts)

	var generated := Node3D.new()
	generated.name = "GeneratedCity"
	root.add_child(generated)

	_build_roads(generated, m.get("roads", {}) as Dictionary)
	_build_background(generated, m.get("background_buildings", []) as Array)
	_build_vegetation(generated, m.get("vegetation", {}) as Dictionary)
	_build_street_lamps(generated, m.get("street_lamps", {}) as Dictionary)
	_place_poi_buildings(buildings, pois, m.get("poi_buildings", []) as Array)
	_place_non_building_pois(pois, m.get("non_building_pois", []) as Array)
	_place_gates(decor, m.get("gates", []) as Array)
	_place_markers(markers, m.get("markers", {}) as Dictionary)
	_build_lighting(root)

	return root


func _build_ground_pad(architecture: Node3D) -> void:
	# Walkable authored floor under the stage-4 footprint.
	var body := StaticBody3D.new()
	body.name = "PerimeterCollision"
	architecture.add_child(body)
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorCollider"
	body.add_child(floor_body)
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(96.0, 0.4, 64.0)
	shape.shape = box
	shape.position = Vector3(0.5, -0.2, 9.0)
	floor_body.add_child(shape)
	var mesh := MeshInstance3D.new()
	mesh.name = "GroundVisual"
	var plane := BoxMesh.new()
	plane.size = Vector3(96.0, 0.08, 64.0)
	mesh.mesh = plane
	mesh.position = Vector3(0.5, -0.04, 9.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.16, 0.22)
	mat.roughness = 0.92
	mesh.material_override = mat
	architecture.add_child(mesh)


func _build_roads(generated: Node3D, roads: Dictionary) -> void:
	var roads_root := Node3D.new()
	roads_root.name = "Roads"
	generated.add_child(roads_root)

	var corridors: Array = roads.get("corridors", []) as Array
	for c_v in corridors:
		var c: Dictionary = c_v as Dictionary
		var asset: String = str(c.get("asset", ""))
		_require_asset(asset)
		var start_a: Array = c.get("start_xz", [0, 0]) as Array
		var end_a: Array = c.get("end_xz", [0, 0]) as Array
		var spacing: float = float(c.get("tile_spacing", 6.0))
		var rot_y: float = float(c.get("rotation_y_degrees", 0.0))
		var sx: float = float(start_a[0])
		var sz: float = float(start_a[1])
		var ex: float = float(end_a[0])
		var ez: float = float(end_a[1])
		var dx: float = ex - sx
		var dz: float = ez - sz
		var length: float = sqrt(dx * dx + dz * dz)
		var steps: int = maxi(1, int(round(length / maxf(spacing, 0.01))))
		var folder := Node3D.new()
		folder.name = str(c.get("id", "corridor"))
		roads_root.add_child(folder)
		for i in range(steps + 1):
			var t: float = 0.0 if steps == 0 else float(i) / float(steps)
			var px: float = lerpf(sx, ex, t)
			var pz: float = lerpf(sz, ez, t)
			_instance_asset(folder, asset, Vector3(px, 0.0, pz), rot_y, Vector3.ONE, "%s_%02d" % [folder.name, i])

	var plazas: Array = roads.get("plazas", []) as Array
	var plazas_root := Node3D.new()
	plazas_root.name = "Plazas"
	roads_root.add_child(plazas_root)
	for p_v in plazas:
		var p: Dictionary = p_v as Dictionary
		var asset: String = str(p.get("asset", ""))
		_require_asset(asset)
		var folder := Node3D.new()
		folder.name = str(p.get("id", "plaza"))
		plazas_root.add_child(folder)
		if p.has("instances"):
			var instances: Array = p["instances"] as Array
			var idx := 0
			for inst_v in instances:
				var inst: Dictionary = inst_v as Dictionary
				var pos_a: Array = inst.get("position", [0, 0, 0]) as Array
				var ry: float = float(inst.get("rotation_y_degrees", 0.0))
				_instance_asset(folder, asset, _vec3(pos_a), ry, Vector3.ONE, "%s_%02d" % [folder.name, idx])
				idx += 1
		elif p.has("grid"):
			var grid: Dictionary = p["grid"] as Dictionary
			var xs: Array = grid.get("x_values", []) as Array
			var zs: Array = grid.get("z_values", []) as Array
			var y: float = float(grid.get("y", -0.01))
			var idx2 := 0
			for xv in xs:
				for zv in zs:
					_instance_asset(folder, asset, Vector3(float(xv), y, float(zv)), 0.0, Vector3.ONE, "%s_%02d" % [folder.name, idx2])
					idx2 += 1

	var park_path: Dictionary = roads.get("park_path", {}) as Dictionary
	if not park_path.is_empty():
		var asset: String = str(park_path.get("asset", ""))
		_require_asset(asset)
		var spacing: float = float(park_path.get("tile_spacing", 2.7))
		var poly: Array = park_path.get("polyline_xz", []) as Array
		var folder := Node3D.new()
		folder.name = "ParkPath"
		roads_root.add_child(folder)
		var idx3 := 0
		for i in range(maxi(0, poly.size() - 1)):
			var a: Array = poly[i] as Array
			var b: Array = poly[i + 1] as Array
			var ax: float = float(a[0])
			var az: float = float(a[1])
			var bx: float = float(b[0])
			var bz: float = float(b[1])
			var seg_len: float = Vector2(bx - ax, bz - az).length()
			var steps: int = maxi(1, int(ceil(seg_len / maxf(spacing, 0.01))))
			var yaw: float = rad_to_deg(atan2(bx - ax, bz - az))
			for s in range(steps + 1):
				var t: float = 0.0 if steps == 0 else float(s) / float(steps)
				var px: float = lerpf(ax, bx, t)
				var pz: float = lerpf(az, bz, t)
				_instance_asset(folder, asset, Vector3(px, -0.005, pz), yaw, Vector3.ONE, "park_%02d" % idx3)
				idx3 += 1

	var pond: Dictionary = roads.get("pond", {}) as Dictionary
	if not pond.is_empty():
		var pond_root := Node3D.new()
		pond_root.name = "Pond"
		roads_root.add_child(pond_root)
		var center: Array = pond.get("center", [1, -0.05, 17.5]) as Array
		var size_a: Array = pond.get("size", [8, 0.25, 6]) as Array
		var pos := _vec3(center)
		var size := _vec3(size_a)
		var mesh := MeshInstance3D.new()
		mesh.name = "PondMesh"
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		mesh.position = pos
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.08, 0.14, 0.28, 0.92)
		mat.metallic = 0.55
		mat.roughness = 0.12
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		pond_root.add_child(mesh)
		if bool(pond.get("collision_required", true)):
			var body := StaticBody3D.new()
			body.name = "PondCollision"
			body.position = pos
			var cs := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(size.x, maxf(size.y, 1.2), size.z)
			cs.shape = shape
			cs.position = Vector3(0.0, 0.4, 0.0)
			body.add_child(cs)
			pond_root.add_child(body)
		_created.append("GeneratedCity/Roads/Pond")


func _build_background(generated: Node3D, items: Array) -> void:
	var folder := Node3D.new()
	folder.name = "BackgroundBuildings"
	generated.add_child(folder)
	for item_v in items:
		var item: Dictionary = item_v as Dictionary
		var asset: String = str(item.get("asset", ""))
		_require_asset(asset)
		var pos := _vec3(item.get("position", [0, 0, 0]) as Array)
		var ry: float = float(item.get("rotation_y_degrees", 0.0))
		var sc := _vec3(item.get("scale", [1, 1, 1]) as Array)
		_instance_asset(folder, asset, pos, ry, sc, str(item.get("id", "bg")))


func _build_vegetation(generated: Node3D, veg: Dictionary) -> void:
	if veg.is_empty():
		return
	var folder := Node3D.new()
	folder.name = "Vegetation"
	generated.add_child(folder)
	var asset: String = str(veg.get("asset", ""))
	var use_procedural := false
	if asset != "" and not ResourceLoader.exists(asset):
		use_procedural = true
		_skipped.append("vegetation asset missing, using procedural trees: %s" % asset)
	var instances: Array = veg.get("instances", []) as Array
	var idx := 0
	for inst_v in instances:
		var inst: Dictionary = inst_v as Dictionary
		var pos := _vec3(inst.get("position", [0, 0, 0]) as Array)
		var ry: float = float(inst.get("rotation_y_degrees", 0.0))
		var sc := _vec3(inst.get("scale", [1, 1, 1]) as Array)
		if use_procedural:
			_procedural_tree(folder, "Tree_%02d" % idx, pos, ry, sc)
		else:
			_instance_asset(folder, asset, pos, ry, sc, "Tree_%02d" % idx)
		idx += 1
	var planters: String = str(veg.get("planters_asset", ""))
	if planters != "" and ResourceLoader.exists(planters):
		# Soft edge planters near commercial street.
		for x in [4.0, 11.0, 18.0]:
			_instance_asset(folder, planters, Vector3(x, 0.0, 4.8), 0.0, Vector3.ONE, "PlanterN_%.0f" % x)
			_instance_asset(folder, planters, Vector3(x, 0.0, -4.8), 0.0, Vector3.ONE, "PlanterS_%.0f" % x)


func _procedural_tree(parent: Node3D, name: String, pos: Vector3, ry: float, sc: Vector3) -> void:
	var root := Node3D.new()
	root.name = name
	root.position = pos
	root.rotation_degrees.y = ry
	root.scale = sc
	parent.add_child(root)
	var trunk := CSGCylinder3D.new()
	trunk.name = "Trunk"
	trunk.radius = 0.12
	trunk.height = 1.8
	trunk.position = Vector3(0, 0.9, 0)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(0.35, 0.22, 0.18)
	trunk.material = tmat
	root.add_child(trunk)
	var crown := CSGSphere3D.new()
	crown.name = "Crown"
	crown.radius = 0.95
	crown.position = Vector3(0, 2.1, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.85, 0.45, 0.65)
	cmat.emission_enabled = true
	cmat.emission = Color(0.55, 0.2, 0.35)
	cmat.emission_energy_multiplier = 0.25
	crown.material = cmat
	root.add_child(crown)


func _build_street_lamps(generated: Node3D, lamps: Dictionary) -> void:
	if lamps.is_empty():
		return
	var folder := Node3D.new()
	folder.name = "StreetLamps"
	generated.add_child(folder)
	var prefab_path: String = str(lamps.get("prefab", PREFAB_DIR + "StreetLampRomance.tscn"))
	if not ResourceLoader.exists(prefab_path):
		_fatal.append("missing street lamp prefab %s" % prefab_path)
		return
	var packed: PackedScene = load(prefab_path) as PackedScene
	var instances: Array = lamps.get("instances", []) as Array
	var idx := 0
	for inst_v in instances:
		var inst: Dictionary = inst_v as Dictionary
		var n: Node3D = packed.instantiate() as Node3D
		n.name = "StreetLamp_%02d" % idx
		n.position = _vec3(inst.get("position", [0, 0, 0]) as Array)
		n.rotation_degrees.y = float(inst.get("rotation_y_degrees", 0.0))
		folder.add_child(n)
		_created.append("GeneratedCity/StreetLamps/%s" % n.name)
		idx += 1


func _place_poi_buildings(buildings: Node3D, pois: Node3D, items: Array) -> void:
	for item_v in items:
		var item: Dictionary = item_v as Dictionary
		var scene_path: String = str(item.get("scene_path", ""))
		var node_name: String = str(item.get("node_name", ""))
		var parent_name: String = str(item.get("target_parent", "POIs"))
		if not ResourceLoader.exists(scene_path):
			_fatal.append("missing POI prefab %s for %s" % [scene_path, node_name])
			continue
		var packed: PackedScene = load(scene_path) as PackedScene
		var n: Node3D = packed.instantiate() as Node3D
		n.name = node_name
		n.position = _vec3(item.get("root_position", [0, 0, 0]) as Array)
		n.rotation_degrees.y = float(item.get("rotation_y_degrees", 0.0))
		n.scale = _vec3(item.get("scale", [1, 1, 1]) as Array)
		n.set_meta("district_id", str(item.get("district_id", "")))
		n.set_meta("poi_id", str(item.get("id", "")))
		var parent: Node3D = buildings if parent_name == "Buildings" else pois
		# Replace existing managed node name if re-run packs into same tree.
		var existing := parent.get_node_or_null(node_name)
		if existing != null:
			existing.free()
		parent.add_child(n)
		_created.append("%s/%s" % [parent_name, node_name])


func _place_non_building_pois(pois: Node3D, items: Array) -> void:
	for item_v in items:
		var item: Dictionary = item_v as Dictionary
		var scene_path: String = str(item.get("scene_path", ""))
		var node_name: String = str(item.get("node_name", ""))
		if not ResourceLoader.exists(scene_path):
			_fatal.append("missing non-building prefab %s" % scene_path)
			continue
		var packed: PackedScene = load(scene_path) as PackedScene
		var n: Node3D = packed.instantiate() as Node3D
		n.name = node_name
		n.position = _vec3(item.get("position", [0, 0, 0]) as Array)
		n.rotation_degrees.y = float(item.get("rotation_y_degrees", 0.0))
		n.set_meta("district_id", str(item.get("district_id", "")))
		var existing := pois.get_node_or_null(node_name)
		if existing != null:
			existing.free()
		pois.add_child(n)
		_created.append("POIs/%s" % node_name)


func _place_gates(decor: Node3D, items: Array) -> void:
	var gate_path := "res://scenes/art/city/prefabs/DistrictGate.tscn"
	if not ResourceLoader.exists(gate_path):
		_fatal.append("missing DistrictGate prefab")
		return
	var packed: PackedScene = load(gate_path) as PackedScene
	for item_v in items:
		var item: Dictionary = item_v as Dictionary
		var node_name: String = str(item.get("node_name", ""))
		var n: Node3D = packed.instantiate() as Node3D
		n.name = node_name
		n.position = _vec3(item.get("position", [0, 0, 0]) as Array)
		n.rotation_degrees.y = float(item.get("rotation_y_degrees", 0.0))
		var district_id: String = str(item.get("district_id", ""))
		var display_name: String = str(item.get("display_name", node_name))
		var size := _vec3(item.get("barrier_size", [6, 3.2, 0.45]) as Array)
		n.set_meta("district_id", district_id)
		n.set("district_id", district_id)
		n.set("display_name", display_name)
		n.set("barrier_size", size)
		var existing := decor.get_node_or_null(node_name)
		if existing != null:
			existing.free()
		decor.add_child(n)
		n.add_to_group("district_gate", true)
		if n.has_method("configure"):
			n.call("configure", district_id, display_name, size)
		_created.append("Decor/%s" % node_name)


func _place_markers(markers: Node3D, data: Dictionary) -> void:
	for key_v in data.keys():
		var key: String = str(key_v)
		var entry: Dictionary = data[key] as Dictionary
		var m := Marker3D.new()
		m.name = key
		m.position = _vec3(entry.get("position", [0, 0, 0]) as Array)
		if entry.has("look_at"):
			var look := _vec3(entry["look_at"] as Array)
			var dir: Vector3 = look - m.position
			dir.y = 0.0
			if dir.length_squared() > 0.0001:
				m.rotation.y = atan2(dir.x, dir.z)
		var existing := markers.get_node_or_null(key)
		if existing != null:
			existing.free()
		markers.add_child(m)
		_created.append("Markers/%s" % key)


func _build_lighting(root: Node3D) -> void:
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.06, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.22, 0.24, 0.38)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.18
	env.environment = environment
	root.add_child(env)

	var moon := DirectionalLight3D.new()
	moon.name = "NightKey"
	moon.rotation_degrees = Vector3(-42.0, 28.0, 0.0)
	moon.light_color = Color(0.55, 0.62, 0.85)
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	root.add_child(moon)

	var fill := DirectionalLight3D.new()
	fill.name = "NightFill"
	fill.rotation_degrees = Vector3(-20.0, -120.0, 0.0)
	fill.light_color = Color(0.35, 0.28, 0.45)
	fill.light_energy = 0.22
	fill.shadow_enabled = false
	root.add_child(fill)


func _instance_asset(parent: Node, path: String, pos: Vector3, rot_y: float, scale: Vector3, name: String) -> Node3D:
	if not ResourceLoader.exists(path):
		_fatal.append("missing asset instance %s" % path)
		return null
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		_fatal.append("unloadable asset %s" % path)
		return null
	var n: Node = packed.instantiate()
	if n is Node3D:
		var n3: Node3D = n as Node3D
		n3.name = name
		n3.position = pos
		n3.rotation_degrees.y = rot_y
		n3.scale = scale
		parent.add_child(n3)
		_created.append("%s/%s" % [parent.name, name])
		return n3
	parent.add_child(n)
	return null


func _vec3(a: Array) -> Vector3:
	if a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	if a.size() == 2:
		return Vector3(float(a[0]), 0.0, float(a[1]))
	return Vector3.ZERO


func _set_owner_recursive(n: Node, owner: Node) -> void:
	## Own direct authored nodes, but never recurse into PackedScene instances.
	## Recursing marks nested GLTF/prefab internals as editable overrides and causes
	## "incoming node's name clashes" load errors (Building_Small_12/Building_Small_1, Visuals2, ...).
	for c in n.get_children():
		c.owner = owner
		if not c.scene_file_path.is_empty():
			continue
		_set_owner_recursive(c, owner)


# --- Prefabs -----------------------------------------------------------------

func _base_poi(name: String, collision_size: Vector3 = Vector3(3.6, 3.2, 2.4)) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var visuals := Node3D.new()
	visuals.name = "Visuals"
	root.add_child(visuals)
	var collision := StaticBody3D.new()
	collision.name = "Collision"
	root.add_child(collision)
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = collision_size
	shape.shape = box
	shape.position = Vector3(0.0, collision_size.y * 0.5, -0.2)
	collision.add_child(shape)
	var anchors := Node3D.new()
	anchors.name = "Anchors"
	root.add_child(anchors)
	_marker(anchors, "InteractAnchor", Vector3(0.0, 1.1, 1.1))
	_marker(anchors, "PromptAnchor", Vector3(0.0, 1.7, 1.1))
	_marker(anchors, "OutlineTarget", Vector3(0.0, 1.0, 0.0))
	return root


func _marker(parent: Node, name: String, pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = name
	m.position = pos
	parent.add_child(m)
	return m


func _mat(color: Color, roughness: float = 0.55) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = 0.05
	return m


func _csg_box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = name
	b.size = size
	b.position = pos
	b.material = _mat(color)
	parent.add_child(b)
	return b


func _instance_at(parent: Node, path: String, pos: Vector3, rot_y: float = 0.0, scale: Vector3 = Vector3.ONE) -> Node3D:
	if not ResourceLoader.exists(path):
		return _csg_box(parent, "Missing", pos, Vector3(0.4, 0.4, 0.4), Color(1, 0, 1))
	var packed: PackedScene = load(path) as PackedScene
	var n: Node = packed.instantiate()
	if n is Node3D:
		var n3: Node3D = n as Node3D
		## Unique sibling name under Visuals; keep nested GLTF root untouched inside the instance.
		n3.name = "%s_Inst" % path.get_file().get_basename()
		n3.position = pos
		n3.rotation_degrees.y = rot_y
		n3.scale = scale
		parent.add_child(n3)
		return n3
	parent.add_child(n)
	return _csg_box(parent, "Non3D", pos, Vector3(0.3, 0.3, 0.3), Color(1, 0, 1))


func _awning(visuals: Node, color: Color, y: float = 2.35) -> void:
	_csg_box(visuals, "Awning", Vector3(0, y, 0.95), Vector3(2.8, 0.08, 0.95), color)
	_csg_box(visuals, "AwningStripe", Vector3(0, y - 0.06, 0.95), Vector3(2.8, 0.04, 0.95), color.darkened(0.2))


func _facade_sign(visuals: Node, text: String, accent: Color, y: float = 2.55) -> void:
	_csg_box(visuals, "SignBoard", Vector3(0.0, y, 0.78), Vector3(2.0, 0.45, 0.08), accent.darkened(0.25))
	_csg_box(visuals, "SignAccent", Vector3(0.0, y, 0.84), Vector3(1.7, 0.12, 0.04), accent)
	var label := Label3D.new()
	label.name = "SignText"
	label.text = text
	label.position = Vector3(0.0, y, 0.9)
	label.font_size = 28
	label.modulate = Color(1, 0.95, 0.9, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.shaded = true
	visuals.add_child(label)


func _prefab_home() -> Node3D:
	var root := _base_poi("HomeFacade", Vector3(3.8, 3.4, 2.6))
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_DOOR, Vector3(0.55, 0, 0.55), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_WINDOW, Vector3(-0.55, 0.9, 0.65), 0.0, Vector3(0.8, 0.8, 0.8))
	_awning(v, Color(0.55, 0.45, 0.7))
	_facade_sign(v, "HOME", Color(0.75, 0.55, 0.95))
	_instance_at(v, P_PLANTER, Vector3(-1.15, 0, 1.0), 0.0, Vector3.ONE)
	return root


func _prefab_cafe() -> Node3D:
	var root := _base_poi("CafeTwoHearts", Vector3(4.4, 3.6, 3.0))
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.55), 0.0, Vector3(0.45, 0.45, 0.45))
	_instance_at(v, P_DOOR, Vector3(0.0, 0, 0.7), 0.0, Vector3(1, 1, 1))
	_awning(v, Color(0.95, 0.45, 0.55), 2.5)
	## Sushi-kit props are authored oversized vs ~1.8m player:
	## Table native H≈1.55 → scale 0.48 ≈ 0.74m top; stool H≈0.88 → 0.55 ≈ 0.48m seat.
	_instance_at(v, P_COUNTER, Vector3(-0.95, 0, 0.35), 90.0, Vector3(0.52, 0.52, 0.52))
	_instance_at(v, P_TABLE, Vector3(1.45, 0, 0.45), 10.0, Vector3(0.48, 0.48, 0.48))
	_instance_at(v, P_STOOL, Vector3(1.75, 0, 0.25), 0.0, Vector3(0.55, 0.55, 0.55))
	## Compact facade sign only — no giant sushi billboard.
	_csg_box(v, "SignBoard", Vector3(0.0, 2.55, 0.78), Vector3(1.7, 0.42, 0.08), Color(0.18, 0.1, 0.12))
	_csg_box(v, "SignAccent", Vector3(0.0, 2.55, 0.84), Vector3(1.45, 0.14, 0.04), Color(1.0, 0.55, 0.35))
	var label := Label3D.new()
	label.name = "SignText"
	label.text = "TWO HEARTS"
	label.position = Vector3(0.0, 2.55, 0.9)
	label.font_size = 26
	label.modulate = Color(1.0, 0.95, 0.88, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.shaded = true
	v.add_child(label)
	var warm := OmniLight3D.new()
	warm.name = "CafeWarmLight"
	warm.position = Vector3(0.0, 2.35, 1.0)
	warm.light_color = Color(1.0, 0.72, 0.45)
	warm.light_energy = 1.25
	warm.omni_range = 6.0
	v.add_child(warm)
	_marker(root.get_node("Anchors"), "DateSeatAnchor", Vector3(1.45, 0.45, 0.45))
	return root


func _prefab_bookstore() -> Node3D:
	var root := _base_poi("BookstoreLeisure", Vector3(3.6, 3.2, 2.4))
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.35), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_DOOR, Vector3(0.65, 0, 0.55), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_WINDOW, Vector3(-0.5, 0.9, 0.65), 0.0, Vector3(0.85, 0.85, 0.85))
	_awning(v, Color(0.45, 0.55, 0.75))
	_instance_at(v, P_BOOKSHELF, Vector3(-0.35, 0.15, 0.1), 180.0, Vector3(0.7, 0.7, 0.7))
	_instance_at(v, P_SHELF, Vector3(0.35, 0.2, 0.2), 180.0, Vector3(0.65, 0.65, 0.65))
	_facade_sign(v, "BOOKS", Color(0.55, 0.7, 0.95))
	return root


func _prefab_district_gate() -> Node3D:
	var root := Node3D.new()
	root.name = "DistrictGate"
	root.set_script(load(GATE_SCRIPT))
	root.set_meta("district_id", "park_leisure")
	root.add_to_group("district_gate")

	var mesh := MeshInstance3D.new()
	mesh.name = "BarrierMesh"
	var box := BoxMesh.new()
	box.size = Vector3(7.0, 2.6, 0.22)
	mesh.mesh = box
	mesh.position = Vector3(0.0, 1.3, 0.0)
	root.add_child(mesh)

	var body := StaticBody3D.new()
	body.name = "StaticBody3D"
	root.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = Vector3(7.0, 2.6, 0.22)
	cs.shape = shape
	cs.position = Vector3(0.0, 1.3, 0.0)
	body.add_child(cs)

	var area := Area3D.new()
	area.name = "InteractionArea"
	root.add_child(area)
	var acs := CollisionShape3D.new()
	acs.name = "CollisionShape3D"
	var ashape := BoxShape3D.new()
	ashape.size = Vector3(1.6, 2.2, 1.4)
	acs.shape = ashape
	acs.position = Vector3(0.0, 1.1, -1.2)
	area.add_child(acs)

	var label := Label3D.new()
	label.name = "ConditionLabel"
	label.text = "Барьер района"
	label.visible = false
	label.position = Vector3(0.0, 2.35, -0.35)
	label.font_size = 22
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.85, 0.92, 1.0, 0.95)
	root.add_child(label)

	_marker(root, "InteractAnchor", Vector3(0.0, 1.1, -1.2))
	_marker(root, "PromptAnchor", Vector3(0.0, 2.0, -1.2))
	return root


func _prefab_street_lamp() -> Node3D:
	var root := Node3D.new()
	root.name = "StreetLampRomance"
	var pole := CSGCylinder3D.new()
	pole.name = "Pole"
	pole.radius = 0.05
	pole.height = 2.6
	pole.position = Vector3(0.0, 1.3, 0.0)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.12, 0.12, 0.16)
	pmat.metallic = 0.4
	pmat.roughness = 0.45
	pole.material = pmat
	root.add_child(pole)
	var bulb := CSGSphere3D.new()
	bulb.name = "Bulb"
	bulb.radius = 0.18
	bulb.position = Vector3(0.0, 2.55, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.9, 0.65)
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.85, 0.55)
	bmat.emission_energy_multiplier = 1.4
	bulb.material = bmat
	root.add_child(bulb)
	var light := OmniLight3D.new()
	light.name = "LampLight"
	light.position = Vector3(0.0, 2.5, 0.0)
	light.light_color = Color(1.0, 0.86, 0.62)
	light.light_energy = 1.15
	light.omni_range = 6.5
	light.shadow_enabled = false
	root.add_child(light)
	return root
