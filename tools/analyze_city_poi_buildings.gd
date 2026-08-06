extends SceneTree
## Headless POI/building analysis for docs/city_poi_refactor (no city edits).


const OUT_DIR := "res://docs/city_poi_refactor/"
const SHOT_DIR := "res://docs/city_poi_refactor/hollow_shots/"
const CONTACT_DIR := "res://docs/city_poi_refactor/contact_sheets/"
const JSON_OUT := "res://docs/city_poi_refactor/_analysis_raw.json"

const BUILDINGS := [
	"res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf",
]

const DOORS := [
	"res://assets/environment/city/downtown_megakit/meshes/Door_1.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/Door_2.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/Door_3.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Wooden.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Metal_Single.gltf",
	"res://assets/environment/city/downtown_megakit/meshes/DoorFrame_Trim.gltf",
]

const PREFABS := [
	"res://scenes/art/city/prefabs/PlayerHomeFacade.tscn",
	"res://scenes/art/city/prefabs/CafeTwoHearts.tscn",
	"res://scenes/art/city/prefabs/FlowerShop.tscn",
	"res://scenes/art/city/prefabs/JewelryShop.tscn",
	"res://scenes/art/city/prefabs/GiftShop.tscn",
	"res://scenes/art/city/prefabs/ClothingShop.tscn",
	"res://scenes/art/city/prefabs/HomewareShop.tscn",
	"res://scenes/art/city/prefabs/InternetCafe.tscn",
	"res://scenes/art/city/prefabs/ParkRestaurant.tscn",
	"res://scenes/art/city/prefabs/GymFacade.tscn",
	"res://scenes/art/city/prefabs/BookstoreFacade.tscn",
	"res://scenes/art/city/prefabs/CinemaFacade.tscn",
	"res://scenes/art/city/prefabs/ArcadeFacade.tscn",
	"res://scenes/art/city/prefabs/BarFacade.tscn",
	"res://scenes/art/city/prefabs/PhotoStudio.tscn",
	"res://scenes/art/city/prefabs/AgencyOffice.tscn",
	"res://scenes/art/city/prefabs/BarberShop.tscn",
	"res://scenes/art/city/prefabs/MainBench.tscn",
	"res://scenes/art/city/prefabs/ParkBench.tscn",
	"res://scenes/art/city/prefabs/DuckFeeding.tscn",
	"res://scenes/art/city/prefabs/KaraokeStand.tscn",
	"res://scenes/art/city/prefabs/BusStopCandy.tscn",
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONTACT_DIR))
	var report: Dictionary = {
		"buildings": [],
		"doors": [],
		"prefabs": [],
		"notes": [],
	}
	for path in BUILDINGS:
		report["buildings"].append(await _analyze_building(str(path)))
	for path in DOORS:
		report["doors"].append(await _analyze_simple_mesh(str(path)))
	for path in PREFABS:
		report["prefabs"].append(_analyze_prefab(str(path)))
	var f := FileAccess.open(JSON_OUT, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()
		print("POI_ANALYSIS_OK ", JSON_OUT)
	else:
		push_error("POI_ANALYSIS_FAIL write json")
	quit(0)


func _analyze_simple_mesh(path: String) -> Dictionary:
	var out := {"path": path, "exists": ResourceLoader.exists(path)}
	if not out["exists"]:
		return out
	var packed := load(path) as PackedScene
	if packed == null:
		out["error"] = "load_failed"
		return out
	var root := packed.instantiate() as Node3D
	root_window_safe_add(root)
	await process_frame
	var aabb := _world_aabb(root)
	out["aabb_size"] = _v3(aabb.size)
	out["aabb_position"] = _v3(aabb.position)
	root.queue_free()
	await process_frame
	return out


func _analyze_building(path: String) -> Dictionary:
	var out := {
		"path": path,
		"exists": ResourceLoader.exists(path),
		"name": path.get_file().get_basename(),
	}
	if not out["exists"]:
		return out
	var packed := load(path) as PackedScene
	if packed == null:
		out["error"] = "load_failed"
		return out
	var root := packed.instantiate() as Node3D
	root_window_safe_add(root)
	await process_frame
	var aabb := _world_aabb(root)
	out["aabb_size"] = _v3(aabb.size)
	out["aabb_position"] = _v3(aabb.position)
	out["visual_floors_estimate"] = int(maxf(1.0, round(aabb.size.y / 3.2)))
	## Hollow probes: sample points inside footprint at mid-height.
	var center := aabb.get_center()
	var probes: Array = []
	var offsets: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(aabb.size.x * 0.2, 0, 0),
		Vector3(-aabb.size.x * 0.2, 0, 0),
		Vector3(0, 0, aabb.size.z * 0.2),
		Vector3(0, 0, -aabb.size.z * 0.2),
	]
	var space := root.get_world_3d().direct_space_state
	var interior_hits := 0
	var exterior_sky := 0
	for o in offsets:
		var p: Vector3 = center + o
		p.y = aabb.position.y + aabb.size.y * 0.35
		## Cast upward: if hit ceiling soon, interior present.
		var q_up := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, aabb.size.y, 0))
		q_up.collide_with_areas = false
		var hit_up: Dictionary = space.intersect_ray(q_up) if space != null else {}
		## Cast downward for floor
		var q_dn := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p + Vector3(0, -aabb.size.y, 0))
		var hit_dn: Dictionary = space.intersect_ray(q_dn) if space != null else {}
		## Cast to +Z and -Z for back walls
		var q_f := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, 0, aabb.size.z))
		var q_b := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, 0, -aabb.size.z))
		var hit_f: Dictionary = space.intersect_ray(q_f) if space != null else {}
		var hit_b: Dictionary = space.intersect_ray(q_b) if space != null else {}
		var probe := {
			"pos": _v3(p),
			"ceiling": not hit_up.is_empty(),
			"floor": not hit_dn.is_empty(),
			"forward_wall": not hit_f.is_empty(),
			"back_wall": not hit_b.is_empty(),
		}
		probes.append(probe)
		if probe["ceiling"] and probe["floor"]:
			interior_hits += 1
		if hit_up.is_empty():
			exterior_sky += 1
	out["hollow_probes"] = probes
	out["interior_probe_hits"] = interior_hits
	out["open_sky_probes"] = exterior_sky
	## Mesh-based hollowness: many city kit buildings are solid/shell facades without collision.
	## Fall back to mesh AABB volume vs triangle density isn't available; use visual mesh AABB
	## and whether MeshInstance surfaces enclose a cavity via inverted normal heuristic skipped.
	## Instead: sample mesh AABB and report collision presence.
	out["has_collision_shapes"] = _count_collisions(root) > 0
	out["mesh_instance_count"] = _count_meshes(root)
	out["likely_shell_or_solid"] = interior_hits == 0
	out["dedicated_ok"] = true
	out["multi_tenant_ok"] = aabb.size.y >= 8.0 and aabb.size.x >= 8.0
	out["walk_in_candidate"] = interior_hits >= 2 and out["has_collision_shapes"]
	## Capture exterior / interior-ish / topdown screenshots.
	var base := str(out["name"])
	await _shot_building(root, aabb, SHOT_DIR + base + "_exterior.png", "exterior")
	await _shot_building(root, aabb, SHOT_DIR + base + "_interior.png", "interior")
	await _shot_building(root, aabb, SHOT_DIR + base + "_topdown.png", "topdown")
	out["shots"] = [
		SHOT_DIR + base + "_exterior.png",
		SHOT_DIR + base + "_interior.png",
		SHOT_DIR + base + "_topdown.png",
	]
	## Rough door positions: search child names / lowest front mesh protrusion on +Z face.
	out["door_guess"] = _guess_door(root, aabb)
	root.queue_free()
	await process_frame
	return out


func _analyze_prefab(path: String) -> Dictionary:
	var out := {"path": path, "exists": ResourceLoader.exists(path), "name": path.get_file().get_basename()}
	if not out["exists"]:
		return out
	var packed := load(path) as PackedScene
	if packed == null:
		out["error"] = "load_failed"
		return out
	var root := packed.instantiate() as Node3D
	## Don't need in tree for structure scan
	out["children"] = _list_children(root, 0, 3)
	out["mesh_instances"] = []
	out["lights"] = []
	out["labels"] = []
	out["collision"] = []
	out["areas"] = []
	out["anchors"] = []
	out["external_instances"] = []
	for n in root.find_children("*", "MeshInstance3D", true, false):
		out["mesh_instances"].append(str(root.get_path_to(n)))
	for n in root.find_children("*", "Light3D", true, false):
		out["lights"].append(str(root.get_path_to(n)))
	for n in root.find_children("*", "Label3D", true, false):
		var lab := n as Label3D
		out["labels"].append({"path": str(root.get_path_to(n)), "text": lab.text})
	for n in root.find_children("*", "CollisionShape3D", true, false):
		out["collision"].append(str(root.get_path_to(n)))
	for n in root.find_children("*", "Area3D", true, false):
		out["areas"].append(str(root.get_path_to(n)))
	for n in root.find_children("*", "Marker3D", true, false):
		out["anchors"].append(str(root.get_path_to(n)))
	_collect_instances(root, root, out["external_instances"])
	var aabb := AABB()
	## Approx from mesh without adding to tree: use local mesh aabbs
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var local := mi.get_aabb()
		var xf: Transform3D = mi.transform
		## climb to root
		var p: Node = mi.get_parent()
		while p != null and p != root:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var corners: Array[Vector3] = [
			xf * local.position,
			xf * (local.position + local.size),
		]
		for c in corners:
			if first:
				aabb = AABB(c, Vector3.ZERO)
				first = false
			else:
				aabb = aabb.expand(c)
	out["approx_aabb_size"] = _v3(aabb.size)
	root.free()
	return out


func _collect_instances(root: Node, n: Node, acc: Array) -> void:
	if n != root and n.scene_file_path != "":
		acc.append({"path": str(root.get_path_to(n)), "scene": n.scene_file_path})
		return
	for c in n.get_children():
		_collect_instances(root, c, acc)


func _list_children(n: Node, depth: int, max_depth: int) -> Array:
	var arr: Array = []
	if depth > max_depth:
		return arr
	for c in n.get_children():
		arr.append({
			"name": str(c.name),
			"type": c.get_class(),
			"children": _list_children(c, depth + 1, max_depth),
		})
	return arr


func _guess_door(root: Node3D, aabb: AABB) -> Dictionary:
	var doors: Array = []
	for n in root.find_children("*", "Node3D", true, false):
		var nm := str(n.name).to_lower()
		if "door" in nm or "arch" in nm or "entrance" in nm:
			doors.append({"name": str(n.name), "pos": _v3((n as Node3D).global_position)})
	## Front face assumed +Z of AABB (kit convention varies); report center of front wall.
	var front := Vector3(aabb.get_center().x, aabb.position.y + 1.0, aabb.position.z + aabb.size.z)
	return {
		"named_doors": doors,
		"front_face_center_guess": _v3(front),
		"note": "Door is baked into facade mesh for downtown Building_*; use Door_* props or DoorAnchor in front of visual opening.",
	}


func _shot_building(building: Node3D, aabb: AABB, path: String, mode: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 800)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root_window_safe_add(vp)
	var world_parent := Node3D.new()
	vp.add_child(world_parent)
	var holder := building.get_parent()
	building.reparent(world_parent)
	var cam := Camera3D.new()
	world_parent.add_child(cam)
	cam.current = true
	var light := DirectionalLight3D.new()
	world_parent.add_child(light)
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_energy = 1.2
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.7, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.75, 0.8)
	e.ambient_light_energy = 0.55
	env.environment = e
	world_parent.add_child(env)
	var c := aabb.get_center()
	var ext: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	match mode:
		"exterior":
			cam.position = c + Vector3(ext * 0.9, ext * 0.45, ext * 1.1)
			cam.look_at(c + Vector3(0, aabb.size.y * 0.15, 0), Vector3.UP)
		"interior":
			cam.position = Vector3(c.x, aabb.position.y + minf(1.6, aabb.size.y * 0.35), aabb.position.z + aabb.size.z * 0.85)
			cam.look_at(Vector3(c.x, cam.position.y, c.z), Vector3.UP)
			cam.fov = 80.0
		"topdown":
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = ext * 1.25
			cam.position = c + Vector3(0, ext * 1.5, 0.01)
			cam.look_at(c, Vector3.FORWARD)
	await process_frame
	await process_frame
	await process_frame
	var img: Image = vp.get_texture().get_image()
	if img != null:
		img.save_png(path)
		print("SHOT ", path)
	building.reparent(holder if holder != null else self.root)
	vp.queue_free()
	await process_frame


func root_window_safe_add(n: Node) -> void:
	root.add_child(n)


func _world_aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi_v in n.find_children("*", "MeshInstance3D", true, false):
		var mi := mi_v as MeshInstance3D
		if mi.mesh == null:
			continue
		var local := mi.get_aabb()
		var xf: Transform3D = mi.global_transform
		var pts: Array[Vector3] = [
			xf * local.position,
			xf * (local.position + Vector3(local.size.x, 0, 0)),
			xf * (local.position + Vector3(0, local.size.y, 0)),
			xf * (local.position + Vector3(0, 0, local.size.z)),
			xf * (local.position + Vector3(local.size.x, local.size.y, 0)),
			xf * (local.position + Vector3(local.size.x, 0, local.size.z)),
			xf * (local.position + Vector3(0, local.size.y, local.size.z)),
			xf * (local.position + local.size),
		]
		for p in pts:
			if first:
				out = AABB(p, Vector3.ZERO)
				first = false
			else:
				out = out.expand(p)
	return out


func _count_collisions(n: Node) -> int:
	return n.find_children("*", "CollisionShape3D", true, false).size()


func _count_meshes(n: Node) -> int:
	return n.find_children("*", "MeshInstance3D", true, false).size()


func _v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]
