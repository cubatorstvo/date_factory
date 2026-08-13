extends RefCounted
## Split PrototypeRoads/PrototypeBoundaries into per-piece PackedScenes
## and instance those pieces under city.tscn Roads/Boundaries groups.
## Does not touch other city nodes.

const ROADS_DIR := "res://world/locations/city_hub/prototype/roads"
const BOUNDS_DIR := "res://world/locations/city_hub/prototype/boundaries"
const CITY := "res://world/locations/city_hub/art/city.tscn"


func run() -> String:
	var ei: Object = Engine.get_singleton("EditorInterface")
	ei.open_scene_from_path(CITY)
	ei.save_scene()
	var dir := DirAccess.open("res://world/locations/city_hub/prototype")
	if dir == null:
		return "NO_PROTO_DIR"
	dir.make_dir_recursive("roads")
	dir.make_dir_recursive("boundaries")
	var saved: PackedStringArray = PackedStringArray()
	_pack_box("roads/PrototypeRoadCommercial.tscn", "RoadCommercial", Vector3(34, 0.08, 7), Color(0.18, 0.18, 0.21), false, saved)
	_pack_box("roads/PrototypeRoadResidential.tscn", "RoadResidential", Vector3(7, 0.08, 18), Color(0.18, 0.18, 0.21), false, saved)
	_pack_box("roads/PrototypeRoadAgencySouth.tscn", "RoadAgencySouth", Vector3(24, 0.08, 6), Color(0.16, 0.17, 0.21), false, saved)
	_pack_box("roads/PrototypeRoadAgencyWest.tscn", "RoadAgencyWest", Vector3(6, 0.08, 10), Color(0.16, 0.17, 0.21), false, saved)
	_pack_box("roads/PrototypeRoadAgencyNorth.tscn", "RoadAgencyNorth", Vector3(12, 0.08, 5.5), Color(0.16, 0.17, 0.21), false, saved)
	_pack_box("roads/PrototypeSidewalkNorth.tscn", "SidewalkNorth", Vector3(34, 0.1, 2.1), Color(0.36, 0.34, 0.37), false, saved)
	_pack_box("roads/PrototypeSidewalkSouth.tscn", "SidewalkSouth", Vector3(34, 0.1, 2.1), Color(0.36, 0.34, 0.37), false, saved)
	_pack_box("roads/PrototypeSidewalkResEast.tscn", "SidewalkResEast", Vector3(2, 0.1, 18), Color(0.36, 0.34, 0.37), false, saved)
	_pack_box("roads/PrototypeSidewalkResWest.tscn", "SidewalkResWest", Vector3(2, 0.1, 14), Color(0.36, 0.34, 0.37), false, saved)
	_pack_box("roads/PrototypeSidewalkAgencyN.tscn", "SidewalkAgencyN", Vector3(24, 0.1, 1.7), Color(0.32, 0.32, 0.36), false, saved)
	_pack_box("roads/PrototypeSidewalkAgencyS.tscn", "SidewalkAgencyS", Vector3(24, 0.1, 1.7), Color(0.32, 0.32, 0.36), false, saved)
	_pack_box("roads/PrototypeCurbNorth.tscn", "CurbNorth", Vector3(34, 0.14, 0.18), Color(0.48, 0.46, 0.5), false, saved)
	_pack_box("roads/PrototypeCurbSouth.tscn", "CurbSouth", Vector3(34, 0.14, 0.18), Color(0.48, 0.46, 0.5), false, saved)
	_pack_box("roads/PrototypeCrossingRes.tscn", "CrossingRes", Vector3(2.4, 0.09, 7), Color(0.72, 0.72, 0.74), false, saved)
	_pack_box("roads/PrototypeCrossingToPark.tscn", "CrossingToPark", Vector3(3.2, 0.09, 2.2), Color(0.5, 0.48, 0.52), false, saved)
	_pack_box("roads/PrototypePlazaPad.tscn", "PlazaPad", Vector3(10.5, 0.09, 10.5), Color(0.4, 0.36, 0.34), false, saved)
	_pack_box("roads/PrototypeGrassPad.tscn", "GrassPad", Vector3(20, 0.07, 18), Color(0.22, 0.36, 0.26), false, saved)
	_pack_box("roads/PrototypeForecourtPad.tscn", "ForecourtPad", Vector3(16.5, 0.09, 13), Color(0.28, 0.3, 0.36), false, saved)
	_pack_pond(saved)
	var path_lens: Array = [5.408327, 6.041523, 5.85235, 5.315073, 6.041523, 5.385165, 6.041523, 6.020797]
	for i in path_lens.size():
		_pack_box("roads/PrototypePath%02d.tscn" % i, "Path_%02d" % i, Vector3(3.4, 0.08, float(path_lens[i])), Color(0.42, 0.38, 0.32), false, saved)
	_pack_box("boundaries/PrototypeAlleyCloseSouth.tscn", "AlleyCloseSouth", Vector3(20, 3.2, 0.4), Color(0.32, 0.3, 0.28), true, saved)
	_pack_box("boundaries/PrototypeAlleyCloseWest.tscn", "AlleyCloseWest", Vector3(0.4, 3.5, 16), Color(0.3, 0.32, 0.36), true, saved)
	_pack_box("boundaries/PrototypeBusEndWall.tscn", "BusEndWall", Vector3(1.2, 3.6, 6), Color(0.28, 0.32, 0.38), true, saved)
	_pack_box("boundaries/PrototypeFillerN_9.tscn", "FillerN_9", Vector3(0.35, 2.8, 1.4), Color(0.5, 0.42, 0.36), true, saved)
	_pack_box("boundaries/PrototypeFillerN_15.tscn", "FillerN_15", Vector3(0.35, 2.8, 1.4), Color(0.5, 0.42, 0.36), true, saved)
	_pack_box("boundaries/PrototypeFillerS_9.tscn", "FillerS_9", Vector3(0.35, 2.8, 1.4), Color(0.42, 0.44, 0.48), true, saved)
	_pack_box("boundaries/PrototypeFillerS_15.tscn", "FillerS_15", Vector3(0.35, 2.8, 1.4), Color(0.42, 0.44, 0.48), true, saved)
	_pack_box("boundaries/PrototypeFillerAgency1.tscn", "FillerAgency1", Vector3(0.4, 3.2, 1.5), Color(0.36, 0.4, 0.48), true, saved)
	_pack_box("boundaries/PrototypeGroundBase.tscn", "GroundBase", Vector3(100, 0.06, 70), Color(0.22, 0.22, 0.24), false, saved)
	_pack_floor(saved)
	var fs: Object = ei.get_resource_filesystem()
	fs.scan()
	var city_root: Node = ei.get_edited_scene_root()
	if city_root == null or city_root.name != "City":
		return "CITY_NOT_OPEN packs=%d" % saved.size()
	_replace_roads(city_root)
	_replace_boundaries(city_root)
	ei.save_scene()
	return "PACKS=%d CITY_SAVED roads_scene='%s' bounds_scene='%s'" % [
		saved.size(),
		city_root.get_node("Roads").scene_file_path,
		city_root.get_node("Boundaries").scene_file_path,
	]


func _pack_box(rel: String, piece_name: String, size: Vector3, color: Color, with_body: bool, saved: PackedStringArray) -> void:
	var root := Node3D.new()
	root.name = piece_name
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh.mesh = box
	mesh.material_override = mat
	root.add_child(mesh)
	mesh.owner = root
	if with_body:
		var body := StaticBody3D.new()
		body.name = "Body"
		var col := CollisionShape3D.new()
		col.name = "Shape"
		var sh := BoxShape3D.new()
		sh.size = size
		col.shape = sh
		body.add_child(col)
		root.add_child(body)
		col.owner = root
		body.owner = root
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK:
		saved.append("FAIL_PACK %s %d" % [rel, err])
		return
	var path := "res://world/locations/city_hub/prototype/%s" % rel
	err = ResourceSaver.save(packed, path)
	saved.append("%s err=%d" % [rel, err])


func _pack_pond(saved: PackedStringArray) -> void:
	var root := Node3D.new()
	root.name = "Pond"
	_add_box_child(root, "Water", Vector3(7.5, 0.2, 5.5), Color(0.16, 0.28, 0.36), Vector3(0, -0.04, 0))
	_add_box_child(root, "Rim", Vector3(8.3, 0.12, 6.3), Color(0.38, 0.36, 0.32), Vector3.ZERO)
	var body := StaticBody3D.new()
	body.name = "Collision"
	body.position = Vector3(0, -0.05, 0)
	var col := CollisionShape3D.new()
	col.name = "Shape"
	col.position = Vector3(0, 0.4, 0)
	var sh := BoxShape3D.new()
	sh.size = Vector3(7.5, 1.2, 5.5)
	col.shape = sh
	body.add_child(col)
	root.add_child(body)
	col.owner = root
	body.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var err := ResourceSaver.save(packed, "res://world/locations/city_hub/prototype/roads/PrototypePond.tscn")
	saved.append("roads/PrototypePond.tscn err=%d" % err)


func _pack_floor(saved: PackedStringArray) -> void:
	var root := StaticBody3D.new()
	root.name = "FloorCollider"
	var col := CollisionShape3D.new()
	col.name = "Shape"
	var sh := BoxShape3D.new()
	sh.size = Vector3(100, 0.4, 70)
	col.shape = sh
	root.add_child(col)
	col.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var err := ResourceSaver.save(packed, "res://world/locations/city_hub/prototype/boundaries/PrototypeFloorCollider.tscn")
	saved.append("boundaries/PrototypeFloorCollider.tscn err=%d" % err)


func _add_box_child(root: Node, child_name: String, size: Vector3, color: Color, pos: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = child_name
	mesh.position = pos
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mesh.mesh = box
	mesh.material_override = mat
	root.add_child(mesh)
	mesh.owner = root


func _instance(parent: Node, city_root: Node, path: String, node_name: String, pos: Vector3, rot_y_deg: float = 0.0) -> void:
	var packed: PackedScene = load(path)
	var inst: Node3D = packed.instantiate()
	inst.name = node_name
	parent.add_child(inst)
	inst.owner = city_root
	inst.position = pos
	if rot_y_deg != 0.0:
		inst.rotation_degrees = Vector3(0, rot_y_deg, 0)


func _group(city_root: Node, parent: Node, group_name: String) -> Node3D:
	var g := Node3D.new()
	g.name = group_name
	parent.add_child(g)
	g.owner = city_root
	return g


func _replace_roads(city_root: Node) -> void:
	var old: Node = city_root.get_node("Roads")
	var idx: int = old.get_index()
	old.free()
	var roads := Node3D.new()
	roads.name = "Roads"
	city_root.add_child(roads)
	city_root.move_child(roads, idx)
	roads.owner = city_root
	var d := ROADS_DIR
	var surfaces := _group(city_root, roads, "RoadSurfaces")
	_instance(surfaces, city_root, d + "/PrototypeRoadCommercial.tscn", "RoadCommercial", Vector3(12, 0, 0))
	_instance(surfaces, city_root, d + "/PrototypeRoadResidential.tscn", "RoadResidential", Vector3(28, 0, 10))
	_instance(surfaces, city_root, d + "/PrototypeRoadAgencySouth.tscn", "RoadAgencySouth", Vector3(-19, 0, 0))
	_instance(surfaces, city_root, d + "/PrototypeRoadAgencyWest.tscn", "RoadAgencyWest", Vector3(-30.5, 0, 5))
	_instance(surfaces, city_root, d + "/PrototypeRoadAgencyNorth.tscn", "RoadAgencyNorth", Vector3(-25.5, 0, 9.5))
	var walks := _group(city_root, roads, "Sidewalks")
	_instance(walks, city_root, d + "/PrototypeSidewalkNorth.tscn", "SidewalkNorth", Vector3(12, 0.02, 4.55))
	_instance(walks, city_root, d + "/PrototypeSidewalkSouth.tscn", "SidewalkSouth", Vector3(12, 0.02, -4.55))
	_instance(walks, city_root, d + "/PrototypeSidewalkResEast.tscn", "SidewalkResEast", Vector3(32.2, 0.02, 10))
	_instance(walks, city_root, d + "/PrototypeSidewalkResWest.tscn", "SidewalkResWest", Vector3(23.8, 0.02, 10.5))
	_instance(walks, city_root, d + "/PrototypeSidewalkAgencyN.tscn", "SidewalkAgencyN", Vector3(-19, 0.02, 3.85))
	_instance(walks, city_root, d + "/PrototypeSidewalkAgencyS.tscn", "SidewalkAgencyS", Vector3(-19, 0.02, -3.85))
	var curbs := _group(city_root, roads, "Curbs")
	_instance(curbs, city_root, d + "/PrototypeCurbNorth.tscn", "CurbNorth", Vector3(12, 0.05, 3.5))
	_instance(curbs, city_root, d + "/PrototypeCurbSouth.tscn", "CurbSouth", Vector3(12, 0.05, -3.5))
	var crossings := _group(city_root, roads, "Crossings")
	_instance(crossings, city_root, d + "/PrototypeCrossingRes.tscn", "CrossingRes", Vector3(25.5, 0.01, 0))
	_instance(crossings, city_root, d + "/PrototypeCrossingToPark.tscn", "CrossingToPark", Vector3(0, 0.01, 5.2))
	var pads := _group(city_root, roads, "GroundPads")
	_instance(pads, city_root, d + "/PrototypePlazaPad.tscn", "PlazaPad", Vector3(0, -0.01, 0.2))
	_instance(pads, city_root, d + "/PrototypeGrassPad.tscn", "GrassPad", Vector3(1, -0.02, 17.5))
	_instance(pads, city_root, d + "/PrototypeForecourtPad.tscn", "ForecourtPad", Vector3(-17, -0.01, 20.5))
	_instance(pads, city_root, d + "/PrototypePond.tscn", "Pond", Vector3(1, 0, 17.5))
	var path_pos: Array = [
		[Vector3(2.25, 0.02, 9.5), 56.30993],
		[Vector3(5.75, 0.02, 13.75), 24.44395],
		[Vector3(6.0, 0.02, 19.25), -19.9831],
		[Vector3(3.0, 0.02, 23.75), -48.81407],
		[Vector3(-1.75, 0.02, 24.25), -114.44395],
		[Vector3(-5.5, 0.02, 20.5), -158.19858],
		[Vector3(-5.25, 0.02, 15.25), 155.55603],
		[Vector3(-2.0, 0.02, 10.25), 138.36646],
	]
	for i in path_pos.size():
		var item: Array = path_pos[i]
		_instance(pads, city_root, d + "/PrototypePath%02d.tscn" % i, "Path_%02d" % i, item[0], float(item[1]))


func _replace_boundaries(city_root: Node) -> void:
	var old: Node = city_root.get_node("Boundaries")
	var idx: int = old.get_index()
	old.free()
	var bounds := Node3D.new()
	bounds.name = "Boundaries"
	city_root.add_child(bounds)
	city_root.move_child(bounds, idx)
	bounds.owner = city_root
	var d := BOUNDS_DIR
	_instance(bounds, city_root, d + "/PrototypeAlleyCloseSouth.tscn", "AlleyCloseSouth", Vector3(10, 1.6, -10.5))
	_instance(bounds, city_root, d + "/PrototypeAlleyCloseWest.tscn", "AlleyCloseWest", Vector3(-36, 1.75, 14))
	_instance(bounds, city_root, d + "/PrototypeBusEndWall.tscn", "BusEndWall", Vector3(-33.5, 1.8, 5))
	_instance(bounds, city_root, d + "/PrototypeFillerN_9.tscn", "FillerN_9", Vector3(8.75, 1.4, 6.5))
	_instance(bounds, city_root, d + "/PrototypeFillerN_15.tscn", "FillerN_15", Vector3(15.45, 1.4, 6.5))
	_instance(bounds, city_root, d + "/PrototypeFillerS_9.tscn", "FillerS_9", Vector3(8.75, 1.4, -6.5))
	_instance(bounds, city_root, d + "/PrototypeFillerS_15.tscn", "FillerS_15", Vector3(15.45, 1.4, -6.5))
	_instance(bounds, city_root, d + "/PrototypeFillerAgency1.tscn", "FillerAgency1", Vector3(-15.85, 1.6, -6.5))
	_instance(bounds, city_root, d + "/PrototypeFloorCollider.tscn", "FloorCollider", Vector3(-2, -0.2, 8))
	_instance(bounds, city_root, d + "/PrototypeGroundBase.tscn", "GroundBase", Vector3(-2, -0.05, 8))
