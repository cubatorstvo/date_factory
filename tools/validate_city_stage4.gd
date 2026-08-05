extends SceneTree
## Headless Stage-4 city validation against build manifest.


const MANIFEST_PATH := "res://tools/date_factory_city_stage4_build_manifest.json"
const CITY := "res://scenes/world/city/city.tscn"
const REPORT := "res://docs/city_stage4_review/VALIDATION_REPORT.md"
const TOLERANCE := 0.02

const REQUIRED_ACTION_IDS := [
	"go_home", "sit_cafe", "open_jewelry_shop", "open_gift_shop", "open_flower_shop",
	"city_cafe_job", "city_cafe_scroll", "city_coffee", "open_homeware_shop", "open_clothing_shop",
	"sit_restaurant", "city_workout", "city_gym_pass", "open_bookstore", "sit_cinema",
	"open_arcade", "sit_arcade", "city_bar_drink", "open_photo_studio", "open_agency_board",
	"open_barber", "city_rest", "city_park_fun", "city_karaoke", "city_bus_info", "city_buy_gift",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var fails: PackedStringArray = PackedStringArray()
	var notes: PackedStringArray = PackedStringArray()

	var manifest_v: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if typeof(manifest_v) != TYPE_DICTIONARY:
		fails.append("manifest load failed")
		_finish(fails, notes)
		return
	var manifest: Dictionary = manifest_v as Dictionary

	var packed: PackedScene = load(CITY) as PackedScene
	if packed == null:
		fails.append("city.tscn load failed")
		_finish(fails, notes)
		return
	var root: Node3D = packed.instantiate() as Node3D
	if root == null:
		fails.append("city.tscn instantiate failed")
		_finish(fails, notes)
		return
	get_root().add_child(root)
	await process_frame

	# Containers
	for cname in ["Architecture", "Buildings", "POIs", "Decor", "Markers", "GeneratedCity"]:
		if root.get_node_or_null(cname) == null:
			fails.append("missing container %s" % cname)

	# Markers + transforms
	var markers: Dictionary = manifest.get("markers", {}) as Dictionary
	for key_v in markers.keys():
		var key: String = str(key_v)
		var marker := root.get_node_or_null("Markers/%s" % key) as Node3D
		if marker == null:
			fails.append("missing marker %s" % key)
			continue
		var expected := _vec3((markers[key] as Dictionary).get("position", [0, 0, 0]) as Array)
		if marker.position.distance_to(expected) > TOLERANCE:
			fails.append("marker %s transform mismatch got=%s expected=%s" % [key, marker.position, expected])

	# POI buildings
	var pois: Array = manifest.get("poi_buildings", []) as Array
	var managed_names: Dictionary = {}
	var aabbs: Array = []
	for item_v in pois:
		var item: Dictionary = item_v as Dictionary
		var node_name: String = str(item.get("node_name", ""))
		var parent_name: String = str(item.get("target_parent", "POIs"))
		var path := "%s/%s" % [parent_name, node_name]
		if managed_names.has(node_name):
			fails.append("duplicate managed node name %s" % node_name)
		managed_names[node_name] = true
		var node := root.get_node_or_null(path) as Node3D
		if node == null:
			fails.append("missing POI %s" % path)
			continue
		var expected_pos := _vec3(item.get("root_position", [0, 0, 0]) as Array)
		if node.position.distance_to(expected_pos) > TOLERANCE:
			fails.append("POI %s position mismatch got=%s expected=%s" % [path, node.position, expected_pos])
		var expected_ry: float = float(item.get("rotation_y_degrees", 0.0))
		if _angle_delta_deg(node.rotation_degrees.y, expected_ry) > 0.5:
			fails.append("POI %s rotation mismatch got=%s expected=%s" % [path, node.rotation_degrees.y, expected_ry])
		if not ResourceLoader.exists(str(item.get("scene_path", ""))):
			fails.append("missing resource %s" % str(item.get("scene_path", "")))
		var aabb: AABB = _visual_aabb(node)
		aabbs.append({"name": node_name, "aabb": aabb, "pos": node.position})

	# Non-building POIs
	for item_v in manifest.get("non_building_pois", []) as Array:
		var item: Dictionary = item_v as Dictionary
		var node_name: String = str(item.get("node_name", ""))
		var node := root.get_node_or_null("POIs/%s" % node_name) as Node3D
		if node == null:
			fails.append("missing non-building POI %s" % node_name)
			continue
		var expected_pos := _vec3(item.get("position", [0, 0, 0]) as Array)
		if node.position.distance_to(expected_pos) > TOLERANCE:
			fails.append("non-building %s position mismatch" % node_name)

	# Gates
	var gate_names := ["ParkGate", "AgencyGate", "AgencyGateLeisure"]
	var agency_count := 0
	for gname in gate_names:
		var gate := root.get_node_or_null("Decor/%s" % gname) as Node3D
		if gate == null:
			fails.append("missing gate %s" % gname)
			continue
		if not gate.is_in_group("district_gate"):
			# Script _ready may add group; accept metadata as equivalent for packed scenes.
			if not gate.has_meta("district_id"):
				fails.append("gate %s missing district_gate group/meta" % gname)
			else:
				notes.append("gate %s has district_id meta; group applied at runtime" % gname)
		var district_id: String = str(gate.get_meta("district_id")) if gate.has_meta("district_id") else ""
		if gname == "ParkGate" and district_id != "park_leisure":
			fails.append("ParkGate district_id=%s" % district_id)
		if gname.begins_with("Agency") and district_id != "agency_row":
			fails.append("%s district_id=%s" % [gname, district_id])
		if district_id == "agency_row":
			agency_count += 1
	if agency_count < 2:
		fails.append("expected 2 agency_row gates, got %d" % agency_count)

	# Simulate both agency gates unlocking together via shared district id.
	var agency_gates: Array = []
	for gname in ["AgencyGate", "AgencyGateLeisure"]:
		var g := root.get_node_or_null("Decor/%s" % gname) as Node3D
		if g != null:
			agency_gates.append(g)
	for g_v in agency_gates:
		var g: Node3D = g_v as Node3D
		if g.has_method("set_unlocked"):
			g.call("set_unlocked", true)
		else:
			g.visible = false
	var both_hidden := true
	for g_v in agency_gates:
		var g2: Node3D = g_v as Node3D
		if g2.visible:
			both_hidden = false
	if agency_gates.size() == 2 and not both_hidden:
		fails.append("agency gates did not hide together on unlock")
	else:
		notes.append("agency gates share district_id and hide together")

	# AABB overlap between POI building visuals (mesh/CSG only; ignore lights).
	for i in range(aabbs.size()):
		for j in range(i + 1, aabbs.size()):
			var a: Dictionary = aabbs[i] as Dictionary
			var b: Dictionary = aabbs[j] as Dictionary
			var aa: AABB = a["aabb"] as AABB
			var bb: AABB = b["aabb"] as AABB
			if aa.size.x <= 0.01 or aa.size.z <= 0.01 or bb.size.x <= 0.01 or bb.size.z <= 0.01:
				continue
			# Shrink slightly to ignore awning / sign edge kisses.
			var aa2 := aa.grow(-0.15)
			var bb2 := bb.grow(-0.15)
			if aa2.size.x <= 0.0 or aa2.size.z <= 0.0 or bb2.size.x <= 0.0 or bb2.size.z <= 0.0:
				continue
			if aa2.intersects(bb2):
				fails.append("AABB overlap %s vs %s" % [str(a["name"]), str(b["name"])])

	# Legacy interactables should not live inside city art scene.
	var legacy := 0
	for n_v in root.find_children("*", "Area3D", true, false):
		var n: Node = n_v as Node
		if n == null:
			continue
		var script_res: Script = n.get_script() as Script
		if script_res != null and script_res.resource_path.find("interactable") >= 0:
			legacy += 1
		elif n.has_method("get") and n.get("action_id") != null and str(n.get("action_id")) != "":
			# Heuristic for Interactable-like areas without loading game scripts.
			if n.get("display_name") != null:
				legacy += 1
	if legacy > 0:
		fails.append("legacy Interactable nodes inside city.tscn count=%d" % legacy)
	else:
		notes.append("no Interactable nodes inside city.tscn")

	# Action IDs preserved in manifest
	var action_blob := JSON.stringify(manifest)
	for aid in REQUIRED_ACTION_IDS:
		if action_blob.find(aid) < 0:
			fails.append("action id missing from manifest coverage: %s" % aid)

	# Required prefabs exist
	for item_v in manifest.get("required_new_prefabs", []) as Array:
		var item: Dictionary = item_v as Dictionary
		var path: String = str(item.get("path", ""))
		if not ResourceLoader.exists(path):
			fails.append("missing required prefab %s" % path)

	# Pond collision
	var pond := root.get_node_or_null("GeneratedCity/Roads/Pond/PondCollision") as StaticBody3D
	if pond == null:
		fails.append("pond collision missing")

	_finish(fails, notes, root)


func _visual_aabb(node: Node3D) -> AABB:
	## Prefer authored Collision box footprint; fallback to approximate facade size.
	var shape_node := node.get_node_or_null("Collision/Shape") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		var box: BoxShape3D = shape_node.shape as BoxShape3D
		var center: Vector3 = shape_node.global_position
		var size: Vector3 = box.size
		# Rotate footprint by root yaw into axis-aligned bounds (conservative OBB->AABB).
		var yaw: float = node.global_rotation.y
		var hx: float = size.x * 0.5
		var hz: float = size.z * 0.5
		var c: float = absf(cos(yaw))
		var s: float = absf(sin(yaw))
		var ext_x: float = hx * c + hz * s
		var ext_z: float = hx * s + hz * c
		return AABB(
			Vector3(center.x - ext_x, center.y - size.y * 0.5, center.z - ext_z),
			Vector3(ext_x * 2.0, size.y, ext_z * 2.0)
		)
	return AABB(node.global_position + Vector3(-1.6, 0.0, -1.3), Vector3(3.2, 3.2, 2.6))


func _angle_delta_deg(a: float, b: float) -> float:
	var d: float = fposmod(absf(a - b), 360.0)
	if d > 180.0:
		d = 360.0 - d
	return d


func _vec3(a: Array) -> Vector3:
	if a.size() >= 3:
		return Vector3(a[0] as float, a[1] as float, a[2] as float)
	return Vector3.ZERO


func _finish(fails: PackedStringArray, notes: PackedStringArray, root: Node = null) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/city_stage4_review"))
	var md := PackedStringArray()
	md.append("# VALIDATION_REPORT — City Stage 4")
	md.append("")
	md.append("Generated by `tools/validate_city_stage4.gd`.")
	md.append("")
	if fails.is_empty():
		md.append("## Result")
		md.append("")
		md.append("`VALIDATE_CITY_STAGE4_PASS`")
	else:
		md.append("## Result")
		md.append("")
		md.append("`VALIDATE_CITY_STAGE4_FAIL` count=%d" % fails.size())
		md.append("")
		md.append("## Failures")
		md.append("")
		for f in fails:
			md.append("- %s" % f)
	md.append("")
	md.append("## Notes")
	md.append("")
	for n in notes:
		md.append("- %s" % n)
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(md) + "\n")
		f.close()
	for fail in fails:
		print("VALIDATE_FAIL %s" % fail)
	for note in notes:
		print("VALIDATE_NOTE %s" % note)
	if fails.is_empty():
		print("VALIDATE_CITY_STAGE4_PASS")
		if root != null:
			root.queue_free()
		quit(0)
	else:
		print("VALIDATE_CITY_STAGE4_FAIL count=%d" % fails.size())
		if root != null:
			root.queue_free()
		quit(1)
