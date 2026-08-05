extends SceneTree
## Headless export for city LD handoff package. Does not modify city scenes.
## Usage: godot --headless --path . -s res://tools/export_city_handoff.gd


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
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_ensure_dirs()
	await _export_scene_nodes(LIVE_CITY, "current_city_nodes.json", "live_city")
	await _export_scene_nodes(SLICE_CITY, "city_street_slice_nodes.json", "street_slice")
	await _export_asset_catalog()
	await _capture_all_screenshots()
	_write_shot_index_stub()
	print("CITY_HANDOFF_EXPORT_PASS")
	quit(0)


func _ensure_dirs() -> void:
	var da := DirAccess.open("res://docs")
	if da == null:
		push_error("No docs/")
		quit(2)
		return
	for p: String in [
		"city_handoff",
		"city_handoff/screenshots",
		"city_handoff/screenshots/current",
		"city_handoff/copies",
	]:
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("res://docs/%s" % p)):
			da.make_dir_recursive(p)


func _export_scene_nodes(scene_path: String, out_name: String, tag: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("LOAD_FAIL %s" % scene_path)
		return
	var root: Node = packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var nodes: Array = []
	var bounds_min := Vector3(INF, INF, INF)
	var bounds_max := Vector3(-INF, -INF, -INF)
	_collect_meaningful(root, root, nodes, bounds_min, bounds_max)
	# Recompute bounds properly
	bounds_min = Vector3(INF, INF, INF)
	bounds_max = Vector3(-INF, -INF, -INF)
	for item: Variant in nodes:
		var d: Dictionary = item
		var aabb_min: Array = d.get("aabb_min", [0, 0, 0])
		var aabb_max: Array = d.get("aabb_max", [0, 0, 0])
		for i in 3:
			bounds_min[i] = minf(bounds_min[i], float(aabb_min[i]))
			bounds_max[i] = maxf(bounds_max[i], float(aabb_max[i]))
	var payload: Dictionary = {
		"scene": scene_path,
		"tag": tag,
		"exported_at": Time.get_datetime_string_from_system(true),
		"root_name": root.name,
		"node_count": nodes.size(),
		"bounds_min": _v3(bounds_min),
		"bounds_max": _v3(bounds_max),
		"bounds_size": _v3(bounds_max - bounds_min),
		"nodes": nodes,
	}
	_write_json("%s/%s" % [OUT_DIR, out_name], payload)
	print("EXPORTED_NODES %s count=%d size=%s" % [out_name, nodes.size(), str(bounds_max - bounds_min)])
	root.queue_free()
	await process_frame


func _collect_meaningful(root: Node, n: Node, out: Array, _bmin: Vector3, _bmax: Vector3) -> void:
	if _should_skip_node(n, root):
		for c: Node in n.get_children():
			_collect_meaningful(root, c, out, _bmin, _bmax)
		return
	var n3: Node3D = n as Node3D
	if n3 == null:
		for c2: Node in n.get_children():
			_collect_meaningful(root, c2, out, _bmin, _bmax)
		return
	var path: String = str(root.get_path_to(n))
	if path == ".":
		path = str(n.name)
	var src: String = _source_path(n)
	var aabb: AABB = _approx_aabb(n3)
	var groups: Array = []
	for g: StringName in n.get_groups():
		groups.append(String(g))
	var meta: Dictionary = {}
	for mk: StringName in n.get_meta_list():
		meta[String(mk)] = str(n.get_meta(mk))
	var district: String = _district_container(path)
	var gr: Vector3 = n3.global_rotation
	var rot_deg := Vector3(rad_to_deg(gr.x), rad_to_deg(gr.y), rad_to_deg(gr.z))
	var gscale: Vector3 = n3.global_transform.basis.get_scale()
	var item: Dictionary = {
		"node_path": path,
		"name": String(n.name),
		"type": n.get_class(),
		"source": src,
		"global_position": _v3(n3.global_position),
		"global_rotation_degrees": _v3(rot_deg),
		"global_scale": _v3(gscale),
		"aabb_min": _v3(aabb.position),
		"aabb_max": _v3(aabb.position + aabb.size),
		"aabb_size": _v3(aabb.size),
		"groups": groups,
		"metadata": meta,
		"has_collision": _has_collision(n),
		"has_interaction": _has_interaction(n),
		"parent_district_or_container": district,
		"visible": n3.visible,
	}
	out.append(item)
	# Do not recurse into imported packed scene internals if we already recorded the instance root
	if n.scene_file_path != "" and n != root:
		return
	for c3: Node in n.get_children():
		_collect_meaningful(root, c3, out, _bmin, _bmax)


func _should_skip_node(n: Node, root: Node) -> bool:
	if n == root:
		return false
	var cls: String = n.get_class()
	# Skip deep mesh guts of imported assets — handled by early return on scene_file_path
	if cls == "ImporterMeshInstance3D":
		return true
	return false


func _source_path(n: Node) -> String:
	if n.scene_file_path != "":
		return n.scene_file_path
	var mi: MeshInstance3D = n as MeshInstance3D
	if mi != null and mi.mesh != null:
		var mp: String = mi.mesh.resource_path
		if mp != "":
			return mp
		return "builtin:%s" % mi.mesh.get_class()
	return ""


func _approx_aabb(n3: Node3D) -> AABB:
	var aabb := AABB(n3.global_position, Vector3.ZERO)
	var mi: MeshInstance3D = n3 as MeshInstance3D
	if mi != null and mi.mesh != null:
		var la: AABB = mi.get_aabb()
		var xf: Transform3D = mi.global_transform
		aabb = _xform_aabb(xf, la)
		return aabb
	var csg: CSGShape3D = n3 as CSGShape3D
	if csg != null:
		# approximate from known size props when possible
		var box: CSGBox3D = csg as CSGBox3D
		if box != null:
			var half: Vector3 = box.size * 0.5
			aabb = _xform_aabb(box.global_transform, AABB(-half, box.size))
			return aabb
		var cyl: CSGCylinder3D = csg as CSGCylinder3D
		if cyl != null:
			var d: float = cyl.radius * 2.0
			var hs: Vector3 = Vector3(d, cyl.height, d) * 0.5
			aabb = _xform_aabb(cyl.global_transform, AABB(-hs, hs * 2.0))
			return aabb
	# union children meshes one level
	var has := false
	for c: Node in n3.get_children():
		var c3: Node3D = c as Node3D
		if c3 == null:
			continue
		var ca: AABB = _approx_aabb(c3)
		if not has:
			aabb = ca
			has = true
		else:
			aabb = aabb.merge(ca)
	if not has:
		aabb = AABB(n3.global_position - Vector3(0.25, 0.25, 0.25), Vector3(0.5, 0.5, 0.5))
	return aabb


func _xform_aabb(xf: Transform3D, local: AABB) -> AABB:
	var pts: Array[Vector3] = []
	for i in 8:
		var p := local.position
		if i & 1:
			p.x += local.size.x
		if i & 2:
			p.y += local.size.y
		if i & 4:
			p.z += local.size.z
		pts.append(xf * p)
	var out := AABB(pts[0], Vector3.ZERO)
	for j in range(1, pts.size()):
		out = out.expand(pts[j])
	return out


func _has_collision(n: Node) -> bool:
	if n is CollisionObject3D:
		return true
	if n is CollisionShape3D:
		return true
	if n is CSGShape3D and (n as CSGShape3D).use_collision:
		return true
	for c: Node in n.get_children():
		if c is CollisionObject3D or c is CollisionShape3D:
			return true
		if c is CSGShape3D and (c as CSGShape3D).use_collision:
			return true
	return false


func _has_interaction(n: Node) -> bool:
	if n.get_class() == "Area3D":
		var scr: Script = n.get_script() as Script
		if scr != null and scr.resource_path.find("interactable") >= 0:
			return true
	if String(n.name).begins_with("Interact") or String(n.name).find("Interact") >= 0:
		return true
	for c: Node in n.get_children():
		if _has_interaction(c):
			return true
	return false


func _district_container(path: String) -> String:
	var parts: PackedStringArray = path.split("/")
	if parts.is_empty():
		return ""
	if parts.size() >= 1:
		var top: String = parts[0]
		if top in ["Architecture", "Buildings", "POIs", "Decor", "Markers", "Districts"]:
			if parts.size() >= 2:
				return "%s/%s" % [top, parts[1]]
			return top
	return parts[0]


func _export_asset_catalog() -> void:
	var entries: Array = []
	_scan_gltf_dir(MEGAKIT, entries)
	# Prefabs
	_scan_scene_dir("res://scenes/art/city/prefabs", entries, "poi_prefab")
	# Categorize
	for e: Variant in entries:
		var d: Dictionary = e
		d["category"] = _categorize_asset(String(d.get("path", "")), String(d.get("name", "")))
	var payload: Dictionary = {
		"exported_at": Time.get_datetime_string_from_system(true),
		"sources": [MEGAKIT, "res://scenes/art/city/prefabs"],
		"count": entries.size(),
		"assets": entries,
	}
	_write_json("%s/city_asset_catalog.json" % OUT_DIR, payload)
	print("EXPORTED_ASSETS count=%d" % entries.size())
	await _render_asset_contact_sheets(entries)


func _scan_gltf_dir(dir_path: String, out: Array) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var fn: String = da.get_next()
	while fn != "":
		if not da.current_is_dir() and (fn.ends_with(".gltf") or fn.ends_with(".glb")):
			var full: String = "%s/%s" % [dir_path, fn]
			var size_est: Dictionary = _estimate_asset_size(full)
			out.append({
				"path": full,
				"name": fn.get_basename(),
				"resource_type": "PackedScene/gltf",
				"approx_size": size_est,
				"face_orientation_hint": _face_hint(fn),
				"has_collision": false,
				"standalone_ok": _is_standalone(fn),
				"recommended_role": _role_hint(fn),
				"import_issues": [],
				"variant_of": _variant_of(fn),
				"category": "",
			})
		fn = da.get_next()
	da.list_dir_end()


func _scan_scene_dir(dir_path: String, out: Array, role: String) -> void:
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var fn: String = da.get_next()
	while fn != "":
		if not da.current_is_dir() and fn.ends_with(".tscn"):
			var full: String = "%s/%s" % [dir_path, fn]
			out.append({
				"path": full,
				"name": fn.get_basename(),
				"resource_type": "PackedScene",
				"approx_size": {"note": "prefab root; open scene for AABB"},
				"face_orientation_hint": "prefab-authored",
				"has_collision": true,
				"standalone_ok": true,
				"recommended_role": role,
				"import_issues": [],
				"variant_of": "",
				"category": "poi_prefab",
			})
		fn = da.get_next()
	da.list_dir_end()


func _estimate_asset_size(path: String) -> Dictionary:
	# Try load packed and read AABB of first MeshInstance
	var packed: Resource = load(path)
	if packed == null:
		return {"error": "load_failed"}
	if packed is PackedScene:
		var inst: Node = (packed as PackedScene).instantiate()
		var aabb := AABB()
		var found := false
		var stack: Array = [inst]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			var mi: MeshInstance3D = n as MeshInstance3D
			if mi != null and mi.mesh != null:
				var a: AABB = _xform_aabb(mi.transform, mi.get_aabb())
				if not found:
					aabb = a
					found = true
				else:
					aabb = aabb.merge(a)
			for c: Node in n.get_children():
				stack.append(c)
		inst.free()
		if found:
			return {
				"size": _v3(aabb.size),
				"center": _v3(aabb.get_center()),
			}
	return {"note": "no_mesh_aabb"}


func _categorize_asset(path: String, name: String) -> String:
	var n: String = name.to_lower()
	var p: String = path.to_lower()
	if p.find("/prefabs/") >= 0:
		return "interaction_objects"
	if n.begins_with("building_large") or n.find("skyscraper") >= 0:
		return "landmarks"
	if n.begins_with("building_"):
		if n.find("corner") >= 0:
			return "corner_buildings"
		return "buildings"
	if n.find("shop") >= 0 or n.find("store") >= 0 or n.find("awning") >= 0:
		return "shops_commercial"
	if n.find("brick") >= 0 or n.find("apartment") >= 0 or n.find("residential") >= 0:
		return "residential_facades"
	if n.begins_with("street_") or n.find("asphalt") >= 0 or n.find("road") >= 0:
		if n.find("intersection") >= 0 or n.find("cross") >= 0:
			return "intersections"
		return "roads"
	if n.find("sidewalk") >= 0 or n.find("curb") >= 0:
		return "sidewalks"
	if n.find("alley") >= 0:
		return "alleys"
	if n.find("fence") >= 0 or n.find("wall") >= 0 or n.find("bollard") >= 0 or n.find("barrier") >= 0:
		return "walls_fences"
	if n.find("door") >= 0 or n.find("entrance") >= 0:
		return "entrances_doors"
	if n.find("roof") >= 0 or n.find("cornice") >= 0:
		return "roofs"
	if n.find("sign") >= 0 or n.find("decal") >= 0 or n.find("billboard") >= 0:
		return "signage"
	if n.find("tree") >= 0 or n.find("bush") >= 0 or n.find("plant") >= 0 or n.find("planter") >= 0:
		return "vegetation"
	if n.find("lamp") >= 0 or n.find("light") >= 0 or n.find("streetlight") >= 0:
		return "lighting"
	if n.find("car") >= 0 or n.find("bus") >= 0 or n.find("vehicle") >= 0:
		return "transport"
	if n.find("bench") >= 0 or n.find("fountain") >= 0 or n.find("picnic") >= 0:
		return "date_objects"
	if n.find("prop_") >= 0:
		if n.find("trash") >= 0 or n.find("hydrant") >= 0 or n.find("drain") >= 0:
			return "small_street_decor"
		return "large_street_decor"
	if n.find("trim_") >= 0 or n.find("metal_") >= 0 or n.find("floor_") >= 0 or n.find("stairs_") >= 0:
		return "background_objects"
	return "background_objects"


func _face_hint(fn: String) -> String:
	var n: String = fn.to_lower()
	if n.find("_l.") >= 0 or n.find("_left") >= 0:
		return "left variant; check +Z/-Z in editor"
	if n.find("_r.") >= 0 or n.find("_right") >= 0:
		return "right variant; check +Z/-Z in editor"
	if n.find("corner") >= 0:
		return "corner piece; two street faces"
	return "assume kit forward +Z unless scene shows otherwise; verify in Godot"


func _is_standalone(fn: String) -> bool:
	var n: String = fn.to_lower()
	if n.begins_with("building_"):
		return true
	if n.begins_with("prop_"):
		return true
	if n.begins_with("street_") or n.begins_with("sidewalk_"):
		return true
	if n.begins_with("door") or n.begins_with("entrance_"):
		return true
	return false


func _role_hint(fn: String) -> String:
	return _categorize_asset(fn, fn.get_basename())


func _variant_of(fn: String) -> String:
	var base: String = fn.get_basename()
	# strip trailing _001 style and L/R
	var cleaned: String = base
	var re_num := RegEx.new()
	re_num.compile("_\\d+$")
	cleaned = re_num.sub(cleaned, "", true)
	if cleaned.ends_with("_L") or cleaned.ends_with("_R"):
		cleaned = cleaned.substr(0, cleaned.length() - 2)
	if cleaned != base:
		return cleaned
	return ""


func _setup_capture_world() -> void:
	if _vp != null:
		return
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
	if _world_host == null:
		return
	for c: Node in _world_host.get_children():
		if c == _cam or c == _key_light:
			continue
		c.queue_free()
	await process_frame


func _capture_all_screenshots() -> void:
	_setup_capture_world()
	await _clear_world_children()
	var packed: PackedScene = load(LIVE_CITY) as PackedScene
	if packed == null:
		push_error("LIVE_CITY load fail")
		return
	var city: Node3D = packed.instantiate() as Node3D
	_world_host.add_child(city)
	for _i in 16:
		await process_frame

	var center := Vector3(-2.0, 0.0, 2.0)
	# 1 top-down full
	await _shot_ortho(
		"01_topdown_full.png",
		Vector3(center.x, 55, center.z),
		Vector3(-90, 0, 0),
		36.0,
		"Strict vertical top-down of entire live city footprint",
		"Establish overall occupied territory"
	)
	# 2 labeled — same view (labels are Label3D in scene)
	await _shot_ortho(
		"02_topdown_labeled.png",
		Vector3(center.x, 55, center.z),
		Vector3(-90, 0, 0),
		36.0,
		"Top-down with in-scene Label3D POI names visible",
		"Identify main objects and POIs from above"
	)
	# 3 route overlay via extra labels
	_add_route_markers(city)
	await process_frame
	await process_frame
	await _shot_ortho(
		"03_topdown_route.png",
		Vector3(center.x, 55, center.z),
		Vector3(-90, 0, 0),
		36.0,
		"Top-down with temporary route markers Home→Commercial→Central→Park/Leisure/Agency",
		"Show current primary player circulation"
	)

	# 4 spawn eye
	var spawn_pos := _marker_pos(city, "HomeEntrance", Vector3(14.2, 0, 1.5))
	await _shot_eye(
		"04_spawn_eye.png",
		spawn_pos + Vector3(0, PLAYER_EYE_Y, 0),
		Vector3(0, 180, 0),
		"Eye-level from HomeEntrance spawn looking toward street (-Z/west-ish after rotation)",
		"Player first impression at city entry"
	)
	# Fix look: toward cafe / commercial (negative X from home at +14)
	await _shot_eye(
		"04b_spawn_toward_cafe.png",
		spawn_pos + Vector3(0, PLAYER_EYE_Y, 0),
		_look_rot(spawn_pos + Vector3(0, PLAYER_EYE_Y, 0), Vector3(10.5, PLAYER_EYE_Y, -4.35)),
		"Eye-level from HomeEntrance looking toward CafeTwoHearts",
		"Primary sightline home→cafe"
	)

	# 5 walk sequence along primary route
	var route: Array[Vector3] = [
		Vector3(14.2, 0, 1.5),
		Vector3(12.0, 0, 0.5),
		Vector3(10.5, 0, -1.0),
		Vector3(6.0, 0, 0.8),
		Vector3(2.0, 0, 0.5),
		Vector3(-2.0, 0, 1.0),
		Vector3(-2.0, 0, 4.0),
		Vector3(-6.0, 0, 6.0),
		Vector3(-8.0, 0, 8.0),
		Vector3(-6.0, 0, -2.0),
		Vector3(-11.0, 0, -2.0),
		Vector3(-15.0, 0, -2.0),
		Vector3(-19.0, 0, -2.0),
	]
	for i in route.size():
		var p: Vector3 = route[i]
		var look_target: Vector3 = route[mini(i + 1, route.size() - 1)]
		if look_target.is_equal_approx(p):
			look_target = p + Vector3(-1, 0, 0)
		await _shot_eye(
			"05_route_%02d.png" % (i + 1),
			p + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(p + Vector3(0, PLAYER_EYE_Y, 0), look_target + Vector3(0, PLAYER_EYE_Y, 0)),
			"Route walk frame %d at %s" % [i + 1, str(p)],
			"Sequential player-eye frames ~along main loop"
		)

	# 6 intersections / junctions eye
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
		await _shot_eye(
			"06_junction_%s.png" % String(jd["name"]),
			jp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(jp + Vector3(0, PLAYER_EYE_Y, 0), jl + Vector3(0, PLAYER_EYE_Y, 0)),
			"Junction/crossroads eye-level: %s" % String(jd["name"]),
			"Document current intersection readability"
		)

	# 7 POI eye shots
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
		await _shot_eye(
			"07_poi_%s.png" % String(pd["name"]),
			pp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(pp + Vector3(0, PLAYER_EYE_Y, 0), pl + Vector3(0, PLAYER_EYE_Y, 0)),
			"POI eye-level: %s" % String(pd["name"]),
			"Document current POI presentation"
		)

	# 8 dense/chaotic
	var dense: Array = [
		{"name": "commercial_cluster", "pos": Vector3(9, 0, -1), "look": Vector3(8, 0, -4)},
		{"name": "leisure_cluster", "pos": Vector3(-9, 0, -1), "look": Vector3(-11, 0, -3)},
		{"name": "agency_cluster", "pos": Vector3(-16, 0, -1), "look": Vector3(-18, 0, -4)},
	]
	for dv: Variant in dense:
		var dd: Dictionary = dv
		var dp: Vector3 = dd["pos"]
		var dl: Vector3 = dd["look"]
		await _shot_eye(
			"08_dense_%s.png" % String(dd["name"]),
			dp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(dp + Vector3(0, PLAYER_EYE_Y, 0), dl + Vector3(0, PLAYER_EYE_Y, 0)),
			"Dense/chaotic area: %s" % String(dd["name"]),
			"Show crowding / visual noise for redesign"
		)

	# 9 edge toward center
	var edges: Array = [
		{"name": "east_to_center", "pos": Vector3(18, 0, 1), "look": Vector3(-2, 0, 1)},
		{"name": "west_to_center", "pos": Vector3(-21, 0, 0), "look": Vector3(-2, 0, 1)},
		{"name": "park_to_center", "pos": Vector3(-2, 0, 10), "look": Vector3(-2, 0, 1)},
	]
	for ev: Variant in edges:
		var ed: Dictionary = ev
		var ep: Vector3 = ed["pos"]
		var el: Vector3 = ed["look"]
		await _shot_eye(
			"09_edge_%s.png" % String(ed["name"]),
			ep + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(ep + Vector3(0, PLAYER_EYE_Y, 0), el + Vector3(0, PLAYER_EYE_Y, 0)),
			"From edge toward center: %s" % String(ed["name"]),
			"Edge concealment and inbound readability"
		)

	# 10 center toward landmarks
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
		await _shot_eye(
			"10_center_%s.png" % String(cd["name"]),
			cp + Vector3(0, PLAYER_EYE_Y, 0),
			_look_rot(cp + Vector3(0, PLAYER_EYE_Y, 0), cl + Vector3(0, PLAYER_EYE_Y, 0)),
			"From center toward landmark: %s" % String(cd["name"]),
			"Landmark sightlines from central pocket"
		)

	# Also capture Street Slice for completeness
	await _clear_world_children()
	var slice_ps: PackedScene = load(SLICE_CITY) as PackedScene
	if slice_ps != null:
		var slice: Node3D = slice_ps.instantiate() as Node3D
		_world_host.add_child(slice)
		for _j in 12:
			await process_frame
		await _shot_ortho(
			"slice_01_topdown.png",
			Vector3(0, 20, 0),
			Vector3(-90, 0, 0),
			18.0,
			"Top-down of City_Street_Slice art testbed",
			"Document named analysis scene (kit slice, not live city)"
		)
		await _shot_eye(
			"slice_02_spawn.png",
			Vector3(0, PLAYER_EYE_Y, 4),
			Vector3(0, 180, 0),
			"Eye-level at City_Street_Slice Spawn",
			"Show kit-slice player view"
		)

	print("SCREENSHOTS_DONE count=%d" % _shot_index.size())


func _add_route_markers(city: Node3D) -> void:
	var pts: Array[Vector3] = [
		Vector3(14.2, 0.2, 1.5),
		Vector3(10.5, 0.2, -1.0),
		Vector3(6.0, 0.2, 0.8),
		Vector3(-2.0, 0.2, 1.0),
		Vector3(-2.0, 0.2, 8.0),
		Vector3(-8.0, 0.2, -2.0),
		Vector3(-19.0, 0.2, -2.0),
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
	var xf := Transform3D()
	xf = xf.looking_at(to - from, Vector3.UP)
	# looking_at on basis: Camera looks down -Z of its transform
	var basis := Basis.looking_at((to - from).normalized(), Vector3.UP)
	return basis.get_euler() * 180.0 / PI


func _shot_ortho(filename: String, pos: Vector3, rot_deg: Vector3, ortho_size: float, what: String, why: String) -> void:
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = ortho_size
	_cam.fov = PLAYER_FOV
	_cam.global_position = pos
	_cam.rotation_degrees = rot_deg
	_cam.current = true
	for _i in 6:
		await process_frame
	_save_shot(filename, pos, rot_deg, what, why, "orthographic")


func _shot_eye(filename: String, pos: Vector3, rot_deg: Vector3, what: String, why: String) -> void:
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.fov = PLAYER_FOV
	_cam.global_position = pos
	_cam.rotation_degrees = rot_deg
	_cam.current = true
	for _i in 6:
		await process_frame
	_save_shot(filename, pos, rot_deg, what, why, "player_eye_fov_%s" % str(PLAYER_FOV))


func _save_shot(filename: String, pos: Vector3, rot_deg: Vector3, what: String, why: String, mode: String) -> void:
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
		"fov_or_ortho": PLAYER_FOV if mode.begins_with("player") else _cam.size,
		"what": what,
		"why": why,
		"save_error": error_string(err),
	})
	print("SHOT %s err=%s" % [filename, error_string(err)])


func _render_asset_contact_sheets(entries: Array) -> void:
	_setup_capture_world()
	var groups: Dictionary = {
		"buildings": [],
		"roads": [],
		"landmarks": [],
		"props": [],
	}
	for e: Variant in entries:
		var d: Dictionary = e
		var cat: String = String(d.get("category", ""))
		var path: String = String(d.get("path", ""))
		if not path.ends_with(".gltf") and not path.ends_with(".glb"):
			continue
		if cat in ["buildings", "corner_buildings", "shops_commercial", "residential_facades"]:
			groups["buildings"].append(d)
		elif cat in ["roads", "intersections", "sidewalks", "alleys"]:
			groups["roads"].append(d)
		elif cat in ["landmarks"]:
			groups["landmarks"].append(d)
		elif cat in ["large_street_decor", "small_street_decor", "vegetation", "lighting", "signage", "transport", "date_objects", "walls_fences", "entrances_doors"]:
			groups["props"].append(d)
	# If landmarks empty, promote largest buildings
	if (groups["landmarks"] as Array).is_empty():
		for e2: Variant in entries:
			var d2: Dictionary = e2
			var n2: String = String(d2.get("name", "")).to_lower()
			if n2.begins_with("building_medium") or n2.begins_with("building_large") or n2.begins_with("building_small"):
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
	if items.is_empty():
		# still write empty note via tiny blank
		print("CONTACT_EMPTY %s" % prefix)


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
		var cell_z: float = float(idx / cols) * spacing
		if ps != null:
			var inst: Node3D = ps.instantiate() as Node3D
			if inst != null:
				_world_host.add_child(inst)
				inst.global_position = Vector3(cell_x, 0, cell_z)
				var lbl := Label3D.new()
				lbl.text = String(d.get("name", ""))
				lbl.font_size = 28
				lbl.position = Vector3(0, 3.2, 0)
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				inst.add_child(lbl)
		idx += 1
	for _f in 14:
		await process_frame
	var rows: int = int(ceil(float(batch.size()) / float(cols)))
	var cam_x: float = (float(mini(cols, batch.size()) - 1) * spacing) * 0.5
	var cam_z: float = (float(maxi(rows, 1) - 1) * spacing) * 0.5
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = maxf(28.0, float(maxi(cols, rows)) * spacing * 0.85)
	_cam.global_position = Vector3(cam_x, 40, cam_z)
	_cam.rotation_degrees = Vector3(-90, 0, 0)
	for _g in 8:
		await process_frame
	var img: Image = _vp.get_texture().get_image()
	if img == null:
		return
	var out_path: String = "%s/%s" % [ASSET_SHOT_DIR, filename]
	var err: Error = img.save_png(ProjectSettings.globalize_path(out_path))
	print("CONTACT %s n=%d err=%s" % [filename, batch.size(), error_string(err)])
	_shot_index.append({
		"file": "screenshots/%s" % filename,
		"camera_position": _v3(_cam.global_position),
		"camera_rotation_degrees": _v3(_cam.rotation_degrees),
		"mode": "orthographic_contact_sheet",
		"what": "Contact sheet %s (%d assets)" % [filename, batch.size()],
		"why": "Visual inventory of available kit pieces",
	})


func _write_shot_index_stub() -> void:
	_write_json("%s/screenshot_index_data.json" % OUT_DIR, {
		"count": _shot_index.size(),
		"shots": _shot_index,
	})


func _write_json(res_path: String, data: Dictionary) -> void:
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		push_error("WRITE_FAIL %s" % res_path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func _v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]
