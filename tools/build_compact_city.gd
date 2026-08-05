extends SceneTree
## Headless rebuild of live city.tscn into compact neighborhood (CITY_MASTERPLAN).
## Backs up previous scene; does not touch complex_world / city_builder / save.


const CITY_OUT := "res://scenes/world/city/city.tscn"
const CITY_BACKUP := "res://scenes/art/city/City_Street_Legacy_Corridor.tscn"
const PREFAB_DIR := "res://scenes/art/city/prefabs/"
const CAPTURE_SVG := "res://docs/release/research/city_compact_layout_topdown.svg"
const CAPTURE_META := "res://docs/release/research/city_compact_layout_capture.md"

const P_BUILDING := "res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf"
const P_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Prop_Planter_Single.gltf"
const P_BOLLARD := "res://assets/environment/city/downtown_megakit/meshes/Prop_Bollard.gltf"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	_backup_legacy_city()
	var root := _build_city_root()
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		push_error("pack city failed: %s" % error_string(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, CITY_OUT)
	if err != OK:
		push_error("save city failed: %s" % error_string(err))
		quit(1)
		return
	_write_capture_docs()
	print("COMPACT_CITY_BUILT path=%s" % CITY_OUT)
	print("COMPACT_CITY_BACKUP path=%s" % CITY_BACKUP)
	print("COMPACT_CITY_CAPTURE svg=%s meta=%s" % [CAPTURE_SVG, CAPTURE_META])
	root.free()
	quit(0)


func _backup_legacy_city() -> void:
	var abs_out := ProjectSettings.globalize_path(CITY_OUT)
	var abs_bak := ProjectSettings.globalize_path(CITY_BACKUP)
	if not FileAccess.file_exists(abs_out):
		return
	# Skip overwrite if backup already looks like a prior corridor dump this session.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/art/city/"))
	if FileAccess.file_exists(abs_bak):
		var bak_size: int = FileAccess.get_file_as_bytes(abs_bak).size()
		if bak_size > 1_000_000:
			print("COMPACT_CITY_BACKUP_KEEP existing=%s bytes=%d" % [CITY_BACKUP, bak_size])
			return
	var da := DirAccess.open("res://")
	if da == null:
		push_warning("backup: cannot open res://")
		return
	var copy_err: Error = da.copy(CITY_OUT, CITY_BACKUP)
	print("COMPACT_CITY_BACKUP_COPY err=%s" % error_string(copy_err))


func _build_city_root() -> Node3D:
	var root := Node3D.new()
	root.name = "City"

	var architecture := Node3D.new()
	architecture.name = "Architecture"
	root.add_child(architecture)
	_build_ground(architecture)
	_build_roads(architecture)
	_build_edge_fillers(architecture)
	_build_perimeter_collision(architecture)

	var buildings := Node3D.new()
	buildings.name = "Buildings"
	root.add_child(buildings)
	_build_home_block(buildings)
	_build_cafe_block(buildings)
	_build_bookstore_block(buildings)
	_build_edge_buildings(buildings)

	var pois := Node3D.new()
	pois.name = "POIs"
	root.add_child(pois)
	_instance_prefabs(pois)

	var decor := Node3D.new()
	decor.name = "Decor"
	root.add_child(decor)
	_build_central_pocket(decor)
	_build_gates(decor)
	_build_zone_labels(decor)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	_build_markers(markers)

	var districts := Node3D.new()
	districts.name = "Districts"
	root.add_child(districts)
	_build_district_anchors(districts)

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.55, 0.62, 0.7)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.52, 0.48)
	environment.ambient_light_energy = 0.65
	env.environment = environment
	root.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.name = "NightKey"
	sun.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	root.add_child(sun)

	return root


func _mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _csg_box(parent: Node3D, name: String, size: Vector3, pos: Vector3, color: Color) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = name
	box.size = size
	box.position = pos
	box.material = _mat(color)
	parent.add_child(box)
	return box


func _csg_cyl(parent: Node3D, name: String, radius: float, height: float, pos: Vector3, color: Color) -> CSGCylinder3D:
	var cyl := CSGCylinder3D.new()
	cyl.name = name
	cyl.radius = radius
	cyl.height = height
	cyl.position = pos
	cyl.material = _mat(color)
	parent.add_child(cyl)
	return cyl


func _static_box(parent: Node3D, name: String, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(shape)
	parent.add_child(body)
	return body


func _label3d(parent: Node3D, name: String, text: String, pos: Vector3, size: int = 36) -> Label3D:
	var lab := Label3D.new()
	lab.name = name
	lab.text = text
	lab.position = pos
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = size
	lab.modulate = Color(1, 1, 1, 0.95)
	parent.add_child(lab)
	return lab


func _build_ground(architecture: Node3D) -> void:
	# Compact pad ~42x24 — not a mega city.
	_csg_box(architecture, "GroundPad", Vector3(42.0, 0.12, 24.0), Vector3(-1.0, -0.06, 2.0), Color(0.42, 0.4, 0.38))
	_csg_box(architecture, "ParkGrass", Vector3(16.0, 0.08, 10.0), Vector3(-3.0, -0.02, 8.5), Color(0.28, 0.48, 0.3))
	_csg_box(architecture, "CentralPaving", Vector3(8.0, 0.1, 8.0), Vector3(1.0, -0.01, 0.5), Color(0.55, 0.52, 0.48))
	_csg_box(architecture, "LeisurePaving", Vector3(12.0, 0.1, 10.0), Vector3(-8.0, -0.01, -1.5), Color(0.5, 0.48, 0.46))
	_csg_box(architecture, "AgencyLanePad", Vector3(10.0, 0.1, 9.0), Vector3(-18.0, -0.01, -1.0), Color(0.48, 0.47, 0.5))
	_csg_box(architecture, "ResidentialCourt", Vector3(8.0, 0.1, 10.0), Vector3(16.5, -0.01, 2.0), Color(0.5, 0.47, 0.42))
	_csg_cyl(architecture, "Pond", 2.2, 0.12, Vector3(-5.0, -0.04, 10.0), Color(0.25, 0.45, 0.55))


func _build_roads(architecture: Node3D) -> void:
	# Commercial L: east-west arm + south cafe arm.
	_csg_box(architecture, "RoadCommercialEW", Vector3(18.0, 0.08, 4.2), Vector3(6.0, 0.01, 0.8), Color(0.22, 0.22, 0.24))
	_csg_box(architecture, "RoadCafeS", Vector3(10.0, 0.08, 3.6), Vector3(10.5, 0.01, -3.2), Color(0.22, 0.22, 0.24))
	# Park loop path (ring segments).
	_csg_box(architecture, "PathParkEntry", Vector3(3.2, 0.07, 4.5), Vector3(0.5, 0.02, 5.0), Color(0.45, 0.42, 0.35))
	_csg_box(architecture, "PathParkNorth", Vector3(12.0, 0.07, 2.4), Vector3(-3.0, 0.02, 11.5), Color(0.45, 0.42, 0.35))
	_csg_box(architecture, "PathParkWest", Vector3(2.4, 0.07, 8.0), Vector3(-9.5, 0.02, 7.0), Color(0.45, 0.42, 0.35))
	_csg_box(architecture, "PathParkReturn", Vector3(8.0, 0.07, 2.2), Vector3(-6.0, 0.02, 3.8), Color(0.45, 0.42, 0.35))
	# Agency side lane.
	_csg_box(architecture, "RoadAgency", Vector3(9.0, 0.08, 3.4), Vector3(-17.5, 0.01, -1.2), Color(0.2, 0.2, 0.23))
	# Sidewalk strips.
	_csg_box(architecture, "SidewalkN", Vector3(20.0, 0.06, 1.6), Vector3(5.0, 0.03, 3.4), Color(0.48, 0.47, 0.44))
	_csg_box(architecture, "SidewalkS", Vector3(14.0, 0.06, 1.6), Vector3(8.0, 0.03, -5.4), Color(0.48, 0.47, 0.44))


func _build_edge_fillers(architecture: Node3D) -> void:
	_csg_box(architecture, "EdgeEastMass", Vector3(3.0, 4.0, 14.0), Vector3(21.0, 2.0, 2.0), Color(0.4, 0.38, 0.36))
	_csg_box(architecture, "EdgeWestMass", Vector3(3.0, 4.0, 12.0), Vector3(-23.0, 2.0, 0.0), Color(0.35, 0.36, 0.4))
	_csg_box(architecture, "EdgeNorthTrees", Vector3(28.0, 3.2, 2.5), Vector3(-2.0, 1.6, 14.5), Color(0.22, 0.38, 0.24))
	_csg_box(architecture, "EdgeSouthMass", Vector3(30.0, 3.5, 2.2), Vector3(-2.0, 1.7, -9.5), Color(0.38, 0.36, 0.34))
	_instance_scaled(architecture, P_PLANTER, "PlanterEastA", Vector3(19.5, 0.0, 5.5), 12.0)
	_instance_scaled(architecture, P_PLANTER, "PlanterEastB", Vector3(19.5, 0.0, -1.5), 12.0)
	_instance_scaled(architecture, P_PLANTER, "PlanterParkA", Vector3(-1.0, 0.0, 12.5), 10.0)
	_instance_scaled(architecture, P_PLANTER, "PlanterParkB", Vector3(-7.0, 0.0, 12.2), 10.0)
	_instance_scaled(architecture, P_BOLLARD, "BollardCentralA", Vector3(-1.5, 0.0, 2.2), 8.0)
	_instance_scaled(architecture, P_BOLLARD, "BollardCentralB", Vector3(3.5, 0.0, 2.2), 8.0)


func _build_perimeter_collision(architecture: Node3D) -> void:
	var walls := Node3D.new()
	walls.name = "PerimeterCollision"
	architecture.add_child(walls)
	# Keep player inside dressed pad.
	_static_box(walls, "WallEast", Vector3(1.2, 4.0, 26.0), Vector3(21.5, 0.0, 2.0))
	_static_box(walls, "WallWest", Vector3(1.2, 4.0, 24.0), Vector3(-23.5, 0.0, 1.0))
	_static_box(walls, "WallNorth", Vector3(46.0, 4.0, 1.2), Vector3(-1.0, 0.0, 15.0))
	_static_box(walls, "WallSouth", Vector3(46.0, 4.0, 1.2), Vector3(-1.0, 0.0, -10.2))
	# Ground collider so player does not fall through thin CSG visuals.
	_static_box(walls, "FloorCollider", Vector3(44.0, 0.4, 26.0), Vector3(-1.0, -0.35, 2.0))


func _build_home_block(buildings: Node3D) -> void:
	var home := Node3D.new()
	home.name = "HomeFacade"
	home.position = Vector3(18.0, 0.0, 1.5)
	buildings.add_child(home)
	_csg_box(home, "Shell", Vector3(5.5, 4.2, 6.5), Vector3(0.0, 2.1, 0.0), Color(0.62, 0.55, 0.48))
	_csg_box(home, "Door", Vector3(1.2, 2.2, 0.2), Vector3(-2.6, 1.1, 0.0), Color(0.35, 0.22, 0.15))
	_csg_box(home, "Awning", Vector3(2.2, 0.15, 1.0), Vector3(-2.8, 2.4, 0.0), Color(0.75, 0.35, 0.3))
	_static_box(home, "Collision", Vector3(5.5, 4.2, 6.5), Vector3(0.0, 0.0, 0.0))
	_label3d(home, "HomeLabel", "Дом", Vector3(-2.8, 3.4, 0.0), 40)
	var halo := OmniLight3D.new()
	halo.name = "HomeHalo"
	halo.position = Vector3(-2.5, 2.8, 0.0)
	halo.light_color = Color(1.0, 0.85, 0.65)
	halo.light_energy = 0.7
	halo.omni_range = 5.0
	home.add_child(halo)


func _build_cafe_block(buildings: Node3D) -> void:
	var cafe := Node3D.new()
	cafe.name = "CafeTwoHearts"
	cafe.position = Vector3(10.5, 0.0, -6.2)
	buildings.add_child(cafe)
	_csg_box(cafe, "Shell", Vector3(6.5, 3.6, 4.0), Vector3(0.0, 1.8, 0.0), Color(0.72, 0.45, 0.4))
	_csg_box(cafe, "Awning", Vector3(6.2, 0.18, 1.4), Vector3(0.0, 2.7, 1.8), Color(0.85, 0.25, 0.3))
	_csg_box(cafe, "Door", Vector3(1.4, 2.3, 0.18), Vector3(0.0, 1.15, 2.05), Color(0.3, 0.18, 0.12))
	_static_box(cafe, "Collision", Vector3(6.5, 3.6, 4.0), Vector3(0.0, 0.0, 0.0))
	_label3d(cafe, "CafeSignLabel", "Кафе Two Hearts", Vector3(0.0, 3.55, 2.2), 48)
	var halo := OmniLight3D.new()
	halo.name = "CafeHalo"
	halo.position = Vector3(0.0, 2.6, 2.0)
	halo.light_color = Color(1.0, 0.75, 0.55)
	halo.light_energy = 0.75
	halo.omni_range = 4.5
	cafe.add_child(halo)


func _build_bookstore_block(buildings: Node3D) -> void:
	var book := Node3D.new()
	book.name = "BookstoreLeisure"
	book.position = Vector3(-3.5, 0.0, -4.0)
	buildings.add_child(book)
	_csg_box(book, "Shell", Vector3(4.2, 3.2, 3.6), Vector3(0.0, 1.6, 0.0), Color(0.45, 0.38, 0.32))
	_csg_box(book, "Door", Vector3(1.1, 2.1, 0.16), Vector3(0.0, 1.05, 1.85), Color(0.25, 0.15, 0.1))
	_static_box(book, "Collision", Vector3(4.2, 3.2, 3.6), Vector3(0.0, 0.0, 0.0))
	_label3d(book, "BookLabel", "Книжный Leisure", Vector3(0.0, 3.2, 1.9), 34)


func _build_edge_buildings(buildings: Node3D) -> void:
	_instance_scaled(buildings, P_BUILDING, "EdgeBldNorthA", Vector3(4.0, 0.0, 13.5), 1.0, Vector3(0.0, 180.0, 0.0))
	_instance_scaled(buildings, P_BUILDING, "EdgeBldNorthB", Vector3(-8.0, 0.0, 13.8), 1.0, Vector3(0.0, 180.0, 0.0))
	_instance_scaled(buildings, P_BUILDING, "EdgeBldSouthA", Vector3(2.0, 0.0, -8.8), 1.0)
	_instance_scaled(buildings, P_BUILDING, "EdgeBldSouthB", Vector3(-14.0, 0.0, -8.5), 1.0)
	_instance_scaled(buildings, P_BUILDING, "EdgeBldWestA", Vector3(-22.0, 0.0, 3.5), 1.0, Vector3(0.0, 90.0, 0.0))


func _instance_prefabs(pois: Node3D) -> void:
	# Commercial — positions aligned to complex_world hardcoded city_root interacts (art = root + 30).
	_add_prefab(pois, "FlowerShop", Vector3(6.0, 0.0, 2.0), Vector3(0.0, 180.0, 0.0))
	_add_prefab(pois, "JewelryShop", Vector3(3.5, 0.0, 2.4), Vector3(0.0, 180.0, 0.0))
	_add_prefab(pois, "GiftShop", Vector3(8.0, 0.0, 3.0), Vector3(0.0, 180.0, 0.0))
	_add_prefab(pois, "ClothingShop", Vector3(6.8, 0.0, 3.6), Vector3(0.0, 180.0, 0.0))
	_add_prefab(pois, "HomewareShop", Vector3(8.8, 0.0, 3.6), Vector3(0.0, 180.0, 0.0))
	_add_prefab(pois, "InternetCafe", Vector3(8.0, 0.0, 6.2), Vector3(0.0, 180.0, 0.0))
	# Central / park.
	_add_prefab(pois, "MainBench", Vector3(2.6, 0.0, -2.9), Vector3.ZERO)
	_add_prefab(pois, "DuckFeeding", Vector3(-5.0, 0.0, 10.0), Vector3.ZERO)
	_add_prefab(pois, "ParkBench", Vector3(-1.5, 0.0, 13.3), Vector3(0.0, 90.0, 0.0))
	_add_prefab(pois, "ParkRestaurant", Vector3(-9.0, 0.0, 7.5), Vector3(0.0, 90.0, 0.0))
	# Leisure forecourt.
	_add_prefab(pois, "GymFacade", Vector3(-6.0, 0.0, -5.0), Vector3.ZERO)
	_add_prefab(pois, "CinemaFacade", Vector3(-11.0, 0.0, -5.2), Vector3.ZERO)
	_add_prefab(pois, "ArcadeFacade", Vector3(-12.8, 0.0, 2.9), Vector3(0.0, 90.0, 0.0))
	_add_prefab(pois, "KaraokeStand", Vector3(-10.0, 0.0, 2.2), Vector3.ZERO)
	_add_prefab(pois, "BarFacade", Vector3(-12.2, 0.0, 2.8), Vector3(0.0, 90.0, 0.0))
	# Agency lane — facades stay on its edges so the through-route remains clear.
	_add_prefab(pois, "PhotoStudio", Vector3(-16.5, 0.0, -4.6), Vector3(0.0, 90.0, 0.0))
	_add_prefab(pois, "BarberShop", Vector3(-18.5, 0.0, 1.6), Vector3(0.0, 90.0, 0.0))
	_add_prefab(pois, "AgencyOffice", Vector3(-20.5, 0.0, -4.6), Vector3(0.0, 90.0, 0.0))
	_add_prefab(pois, "BusStopCandy", Vector3(-21.0, 0.0, 3.2), Vector3(0.0, 90.0, 0.0))


func _add_prefab(parent: Node3D, prefab_name: String, pos: Vector3, rot_deg: Vector3) -> void:
	var path := PREFAB_DIR + prefab_name + ".tscn"
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Missing prefab: %s" % path)
		return
	var inst := packed.instantiate() as Node3D
	if inst == null:
		push_warning("Prefab root not Node3D: %s" % path)
		return
	inst.name = prefab_name
	inst.position = pos
	inst.rotation_degrees = rot_deg
	parent.add_child(inst)


func _instance_scaled(parent: Node3D, path: String, name: String, pos: Vector3, scale: float = 1.0, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Missing mesh scene: %s" % path)
		return
	var inst := packed.instantiate() as Node3D
	if inst == null:
		return
	inst.name = name
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.scale = Vector3.ONE * scale
	parent.add_child(inst)


func _build_central_pocket(decor: Node3D) -> void:
	var pocket := Node3D.new()
	pocket.name = "CentralPocket"
	pocket.position = Vector3(1.0, 0.0, 0.5)
	decor.add_child(pocket)
	_csg_cyl(pocket, "FountainBasin", 1.4, 0.35, Vector3(0.0, 0.18, 0.0), Color(0.55, 0.58, 0.62))
	_csg_cyl(pocket, "FountainStem", 0.35, 1.1, Vector3(0.0, 0.75, 0.0), Color(0.65, 0.68, 0.7))
	_csg_box(pocket, "PlanterRing", Vector3(3.2, 0.35, 3.2), Vector3(0.0, 0.15, 0.0), Color(0.4, 0.35, 0.28))
	_label3d(pocket, "CentralSign", "Центр", Vector3(0.0, 2.4, -2.5), 32).visible = false
	_instance_scaled(pocket, P_PLANTER, "CentralPlanterA", Vector3(-2.2, 0.0, 1.8), 10.0)
	_instance_scaled(pocket, P_PLANTER, "CentralPlanterB", Vector3(2.2, 0.0, 1.8), 10.0)


func _build_gates(decor: Node3D) -> void:
	# ParkGate: side passage NORTH from central pocket (barrier spans X).
	var park_gate := StaticBody3D.new()
	park_gate.name = "ParkGate"
	park_gate.position = Vector3(0.5, 0.0, 3.4)
	decor.add_child(park_gate)
	var park_barrier := CSGBox3D.new()
	park_barrier.name = "Barrier"
	park_barrier.size = Vector3(6.5, 2.8, 0.45)
	park_barrier.position = Vector3(0.0, 1.4, 0.0)
	park_barrier.material = _mat(Color(0.35, 0.55, 0.35, 0.55))
	(park_barrier.material as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	park_gate.add_child(park_barrier)
	var park_cs := CollisionShape3D.new()
	park_cs.name = "Collision"
	var park_shape := BoxShape3D.new()
	park_shape.size = Vector3(6.5, 2.8, 0.45)
	park_cs.shape = park_shape
	park_cs.position = Vector3(0.0, 1.4, 0.0)
	park_gate.add_child(park_cs)
	_label3d(park_gate, "SoonLabel", "Скоро: парк", Vector3(0.0, 3.1, 0.0), 42).visible = false

	# AgencyGate: side passage WEST into agency lane (barrier spans Z).
	var agency_gate := StaticBody3D.new()
	agency_gate.name = "AgencyGate"
	agency_gate.position = Vector3(-14.2, 0.0, -1.2)
	decor.add_child(agency_gate)
	var ag_barrier := CSGBox3D.new()
	ag_barrier.name = "Barrier"
	ag_barrier.size = Vector3(0.45, 2.8, 7.0)
	ag_barrier.position = Vector3(0.0, 1.4, 0.0)
	ag_barrier.material = _mat(Color(0.55, 0.45, 0.25, 0.55))
	(ag_barrier.material as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agency_gate.add_child(ag_barrier)
	var ag_cs := CollisionShape3D.new()
	ag_cs.name = "Collision"
	var ag_shape := BoxShape3D.new()
	ag_shape.size = Vector3(0.45, 2.8, 7.0)
	ag_cs.shape = ag_shape
	ag_cs.position = Vector3(0.0, 1.4, 0.0)
	agency_gate.add_child(ag_cs)
	_label3d(agency_gate, "SoonLabel", "Агентство — скоро", Vector3(0.4, 2.8, 0.0), 36).visible = false


func _build_zone_labels(decor: Node3D) -> void:
	var labels := Node3D.new()
	labels.name = "ZoneLabels"
	decor.add_child(labels)
	_label3d(labels, "Z_Residential", "Residential", Vector3(16.5, 6.0, 2.0), 28).visible = false
	_label3d(labels, "Z_Commercial", "Commercial L", Vector3(7.0, 6.0, 0.5), 28).visible = false
	_label3d(labels, "Z_Central", "Central", Vector3(1.0, 6.0, 0.5), 28).visible = false
	_label3d(labels, "Z_Park", "Park loop", Vector3(-3.0, 6.0, 9.0), 28).visible = false
	_label3d(labels, "Z_Leisure", "Leisure", Vector3(-8.0, 6.0, -2.0), 28).visible = false
	_label3d(labels, "Z_Agency", "Agency lane", Vector3(-18.0, 6.0, -1.0), 28).visible = false


func _marker(parent: Node3D, name: String, pos: Vector3, yaw_deg: float = 0.0) -> Marker3D:
	var m := Marker3D.new()
	m.name = name
	m.position = pos
	m.rotation_degrees = Vector3(0.0, yaw_deg, 0.0)
	parent.add_child(m)
	return m


func _build_markers(markers: Node3D) -> void:
	# Spawn / home — city_root ≈ art + (-30,0,0); HomeEntrance → ~(-13, 4.7).
	_marker(markers, "PlayerSpawn", Vector3(14.2, 0.0, 1.5), 90.0)
	_marker(markers, "ApartmentReturn", Vector3(14.2, 0.0, 1.5), -90.0)
	_marker(markers, "HomeEntrance", Vector3(14.2, 0.0, 1.5), 180.0)
	_marker(markers, "StreetMid", Vector3(6.0, 0.0, 0.8), 90.0)
	_marker(markers, "CrosswalkEntry", Vector3(12.0, 0.0, 0.5), 180.0)
	_marker(markers, "CafeEntrance", Vector3(10.5, 0.0, -4.35), 180.0)
	_marker(markers, "OverviewCamera", Vector3(-2.0, 28.0, 2.0))
	_marker(markers, "WestBoundary", Vector3(-22.0, 0.0, 0.0))
	_marker(markers, "EastBoundary", Vector3(20.0, 0.0, 0.0))
	# Park loop (marker-driven interacts).
	_marker(markers, "ParkPicnicSpot", Vector3(-2.0, 0.0, 8.0))
	_marker(markers, "ParkRestaurantEntrance", Vector3(-8.0, 0.0, 8.0))
	_marker(markers, "ParkGateWest", Vector3(0.5, 0.0, 4.2))
	# Leisure.
	_marker(markers, "GymEntrance", Vector3(-6.0, 0.0, -3.9))
	_marker(markers, "BookstoreEntrance", Vector3(-3.5, 0.0, -2.0))
	_marker(markers, "CinemaEntrance", Vector3(-11.0, 0.0, -4.1))
	_marker(markers, "ArcadeEntrance", Vector3(-11.7, 0.0, 2.9))
	# Agency.
	_marker(markers, "PhotoStudioEntrance", Vector3(-15.4, 0.0, -4.6))
	_marker(markers, "BarberEntrance", Vector3(-17.4, 0.0, 1.6))
	_marker(markers, "AgencyOfficeEntrance", Vector3(-19.4, 0.0, -4.6))
	_marker(markers, "PhotoMark", Vector3(-15.4, 0.0, -4.0))
	_marker(markers, "AgencyGateWest", Vector3(-13.6, 0.0, -1.2))


func _build_district_anchors(districts: Node3D) -> void:
	var park := Node3D.new()
	park.name = "ParkLeisure"
	park.position = Vector3(-3.0, 0.0, 8.5)
	districts.add_child(park)
	# Non-zero shell so zero-size ParkRestaurant regression cannot return via district CSG.
	_csg_box(park, "ParkGround", Vector3(14.0, 0.08, 9.0), Vector3(0.0, -0.02, 0.0), Color(0.28, 0.48, 0.3))
	_csg_box(park, "ParkPath", Vector3(10.0, 0.06, 2.0), Vector3(0.0, 0.02, 0.0), Color(0.45, 0.42, 0.35))
	_csg_cyl(park, "Pond", 2.2, 0.12, Vector3(-2.0, -0.04, 1.5), Color(0.25, 0.45, 0.55))
	_label3d(park, "ParkLabel", "Парк Leisure", Vector3(0.0, 2.6, -4.0), 42).visible = false
	# Intentionally no zero-size ParkRestaurant CSG — live facade is POIs/ParkRestaurant prefab.

	var leisure := Node3D.new()
	leisure.name = "LeisureStrip"
	leisure.position = Vector3(-8.0, 0.0, -1.5)
	districts.add_child(leisure)
	_label3d(leisure, "LeisureLabel", "Leisure forecourt", Vector3(0.0, 3.0, 0.0), 34).visible = false

	var agency := Node3D.new()
	agency.name = "AgencyRow"
	agency.position = Vector3(-18.0, 0.0, -1.0)
	districts.add_child(agency)
	_label3d(agency, "AgencyLabel", "Agency lane", Vector3(0.0, 3.0, 0.0), 34).visible = false


func _set_owner_recursive(n: Node, owner: Node) -> void:
	for c in n.get_children():
		c.owner = owner
		if not String(c.scene_file_path).is_empty():
			continue
		_set_owner_recursive(c, owner)


func _write_capture_docs() -> void:
	# Technical top-down (SVG) — windowed screenshot pending user permission.
	var svg := """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"960\" height=\"640\" viewBox=\"-24 -12 48 28\">
  <rect x=\"-24\" y=\"-12\" width=\"48\" height=\"28\" fill=\"#1a1d22\"/>
  <!-- Zones -->
  <rect x=\"13\" y=\"-3\" width=\"8\" height=\"10\" fill=\"#6b5344\" opacity=\"0.55\" stroke=\"#d4a574\" stroke-width=\"0.15\"/>
  <text x=\"17\" y=\"2\" fill=\"#f0e6d8\" font-size=\"1.1\" text-anchor=\"middle\">Residential</text>
  <path d=\"M 2,-6 L 14,-6 L 14,4 L 2,4 Z\" fill=\"#5a4a3a\" opacity=\"0.45\" stroke=\"#e0b080\" stroke-width=\"0.12\"/>
  <text x=\"8\" y=\"-4\" fill=\"#f0e6d8\" font-size=\"1.0\" text-anchor=\"middle\">Commercial L</text>
  <rect x=\"-3\" y=\"-3\" width=\"8\" height=\"8\" fill=\"#4a4a50\" opacity=\"0.5\" stroke=\"#c0c0d0\" stroke-width=\"0.12\"/>
  <text x=\"1\" y=\"0.5\" fill=\"#eee\" font-size=\"1.0\" text-anchor=\"middle\">Central</text>
  <rect x=\"-11\" y=\"3.5\" width=\"16\" height=\"10\" fill=\"#2f5a38\" opacity=\"0.5\" stroke=\"#7dca8a\" stroke-width=\"0.12\"/>
  <text x=\"-3\" y=\"9\" fill=\"#d8ffe0\" font-size=\"1.0\" text-anchor=\"middle\">Park loop</text>
  <rect x=\"-14\" y=\"-7\" width=\"12\" height=\"10\" fill=\"#3a3a55\" opacity=\"0.45\" stroke=\"#9aa0e0\" stroke-width=\"0.12\"/>
  <text x=\"-8\" y=\"-2\" fill=\"#dde0ff\" font-size=\"1.0\" text-anchor=\"middle\">Leisure</text>
  <rect x=\"-23\" y=\"-6\" width=\"10\" height=\"10\" fill=\"#4a4030\" opacity=\"0.5\" stroke=\"#e0c070\" stroke-width=\"0.12\"/>
  <text x=\"-18\" y=\"-1\" fill=\"#ffe8b0\" font-size=\"1.0\" text-anchor=\"middle\">Agency</text>
  <!-- Loops -->
  <polyline points=\"1,0.5 0.5,3.4 -2,8 -5,10 -9,7.5 -9.5,3.8 -8,-1 1,0.5\" fill=\"none\" stroke=\"#7dca8a\" stroke-width=\"0.25\" stroke-dasharray=\"0.6 0.35\"/>
  <text x=\"-4\" y=\"12.5\" fill=\"#7dca8a\" font-size=\"0.9\">Park loop</text>
  <polyline points=\"-8,-1.2 -13.6,-1.2 -17.5,-1.2 -20.5,-1.2 -20.5,0 -13,0 -8,-1.2\" fill=\"none\" stroke=\"#e0c070\" stroke-width=\"0.25\" stroke-dasharray=\"0.6 0.35\"/>
  <text x=\"-18\" y=\"5\" fill=\"#e0c070\" font-size=\"0.9\">Agency loop</text>
  <!-- Gates -->
  <rect x=\"-2.75\" y=\"3.15\" width=\"6.5\" height=\"0.5\" fill=\"#55aa55\" stroke=\"#fff\" stroke-width=\"0.08\"/>
  <text x=\"0.5\" y=\"2.7\" fill=\"#aaffaa\" font-size=\"0.75\" text-anchor=\"middle\">ParkGate (N side)</text>
  <rect x=\"-14.45\" y=\"-4.7\" width=\"0.5\" height=\"7\" fill=\"#ccaa44\" stroke=\"#fff\" stroke-width=\"0.08\"/>
  <text x=\"-14\" y=\"-5.2\" fill=\"#ffe08a\" font-size=\"0.75\" text-anchor=\"middle\">AgencyGate (W side)</text>
  <!-- POI dots -->
  <circle cx=\"14.2\" cy=\"1.5\" r=\"0.35\" fill=\"#ff6688\"/><text x=\"14.2\" y=\"2.4\" fill=\"#ff6688\" font-size=\"0.65\" text-anchor=\"middle\">spawn/home</text>
  <circle cx=\"10.5\" cy=\"-4.35\" r=\"0.3\" fill=\"#ff8866\"/><text x=\"10.5\" y=\"-5.1\" fill=\"#ff8866\" font-size=\"0.6\" text-anchor=\"middle\">cafe</text>
  <circle cx=\"6\" cy=\"2\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"6\" y=\"2.7\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">flower</text>
  <circle cx=\"3.5\" cy=\"2.4\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"3.5\" y=\"3.2\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">jewelry</text>
  <circle cx=\"8\" cy=\"3\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"8\" y=\"3.7\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">gift</text>
  <circle cx=\"6.8\" cy=\"3.6\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"6.8\" y=\"4.4\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">clothing</text>
  <circle cx=\"8.8\" cy=\"3.6\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"8.8\" y=\"4.4\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">homeware</text>
  <circle cx=\"8\" cy=\"6.2\" r=\"0.25\" fill=\"#88ff88\"/><text x=\"8\" y=\"7\" fill=\"#88ff88\" font-size=\"0.5\" text-anchor=\"middle\">internet cafe</text>
  <circle cx=\"1\" cy=\"0.5\" r=\"0.3\" fill=\"#ffffff\"/><text x=\"1\" y=\"-0.5\" fill=\"#fff\" font-size=\"0.6\" text-anchor=\"middle\">fountain</text>
  <circle cx=\"2.6\" cy=\"-2.9\" r=\"0.25\" fill=\"#ccccff\"/><text x=\"2.6\" y=\"-3.5\" fill=\"#ccccff\" font-size=\"0.5\" text-anchor=\"middle\">main bench</text>
  <circle cx=\"-2\" cy=\"8\" r=\"0.25\" fill=\"#aaffcc\"/><text x=\"-2\" y=\"7.2\" fill=\"#aaffcc\" font-size=\"0.55\" text-anchor=\"middle\">picnic</text>
  <circle cx=\"-5\" cy=\"10\" r=\"0.25\" fill=\"#66ccff\"/><text x=\"-5\" y=\"10.9\" fill=\"#66ccff\" font-size=\"0.55\" text-anchor=\"middle\">ducks</text>
  <circle cx=\"-1.5\" cy=\"13.3\" r=\"0.25\" fill=\"#ccccff\"/><text x=\"-1.5\" y=\"14\" fill=\"#ccccff\" font-size=\"0.5\" text-anchor=\"middle\">park bench</text>
  <circle cx=\"-9\" cy=\"7.5\" r=\"0.25\" fill=\"#ffcc66\"/><text x=\"-9\" y=\"6.7\" fill=\"#ffcc66\" font-size=\"0.55\" text-anchor=\"middle\">restaurant</text>
  <circle cx=\"-6\" cy=\"-4\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-6\" y=\"-4.8\" fill=\"#aaaaff\" font-size=\"0.55\" text-anchor=\"middle\">gym</text>
  <circle cx=\"-3.5\" cy=\"-4\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-3.5\" y=\"-4.7\" fill=\"#aaaaff\" font-size=\"0.5\" text-anchor=\"middle\">bookstore</text>
  <circle cx=\"-11\" cy=\"-4.2\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-11\" y=\"-5\" fill=\"#aaaaff\" font-size=\"0.55\" text-anchor=\"middle\">cinema</text>
  <circle cx=\"-12.8\" cy=\"2.9\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-12.8\" y=\"3.6\" fill=\"#aaaaff\" font-size=\"0.55\" text-anchor=\"middle\">arcade</text>
  <circle cx=\"-10\" cy=\"2.2\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-10\" y=\"2.9\" fill=\"#aaaaff\" font-size=\"0.5\" text-anchor=\"middle\">karaoke</text>
  <circle cx=\"-12.2\" cy=\"2.8\" r=\"0.25\" fill=\"#aaaaff\"/><text x=\"-12.2\" y=\"2.1\" fill=\"#aaaaff\" font-size=\"0.5\" text-anchor=\"middle\">bar</text>
  <circle cx=\"-16.5\" cy=\"-4.6\" r=\"0.25\" fill=\"#ffdd88\"/><text x=\"-16.5\" y=\"-5.3\" fill=\"#ffdd88\" font-size=\"0.55\" text-anchor=\"middle\">photo</text>
  <circle cx=\"-18.5\" cy=\"1.6\" r=\"0.25\" fill=\"#ffdd88\"/><text x=\"-18.5\" y=\"2.3\" fill=\"#ffdd88\" font-size=\"0.5\" text-anchor=\"middle\">barber</text>
  <circle cx=\"-20.5\" cy=\"-4.6\" r=\"0.25\" fill=\"#ffdd88\"/><text x=\"-20.5\" y=\"-5.3\" fill=\"#ffdd88\" font-size=\"0.55\" text-anchor=\"middle\">agency</text>
  <circle cx=\"-21\" cy=\"3.2\" r=\"0.25\" fill=\"#ffdd88\"/><text x=\"-21\" y=\"4\" fill=\"#ffdd88\" font-size=\"0.55\" text-anchor=\"middle\">bus</text>
  <text x=\"0\" y=\"-10.5\" fill=\"#8899aa\" font-size=\"0.85\" text-anchor=\"middle\">DATE FACTORY compact city — art local X/Z (CityVisual). Visual FPS review PENDING.</text>
</svg>
"""
	var f := FileAccess.open(CAPTURE_SVG, FileAccess.WRITE)
	if f:
		f.store_string(svg)
		f.close()
	var meta := """# Compact city layout — technical capture

Status: **annotated technical SVG ready** + **rendered top-down PNG ready**; **FPS / manual walkthrough still required**.

## Files
- Live scene: `scenes/world/city/city.tscn`
- Legacy corridor backup: `scenes/art/city/City_Street_Legacy_Corridor.tscn`
- Technical top-down SVG: `docs/release/research/city_compact_layout_topdown.svg`
- Rendered top-down PNG: `docs/release/research/city_compact_layout_topdown.png`
- Builder: `tools/build_compact_city.gd`

## Capture route (when windowed allowed)
1. Open `res://scenes/world/city/city.tscn` in editor (or mount via complex city).
2. Place temporary Orthogonal Camera3D at `Markers/OverviewCamera` (~(-2, 28, 2)), look down (−Y), size ~28.
3. Screenshot showing ZoneLabels, ParkGate, AgencyGate, POIs, spawn.
4. Optional FPS walk: HomeEntrance → cafe → central fountain → ParkGate → picnic/pond/restaurant → leisure → AgencyGate → photo/bus.

## Coordinate notes
- Art local; `CityVisual` mount offset (−30, 0, 0); city scale ×1.5 in `complex_world`.
- Hardcoded shop/cafe interacts still at fixed city_root positions; facades placed to match.
- Marker-driven park/leisure/agency interacts follow Markers/*.
- Amenity interacts from `city_builder` remain at legacy corridor offsets until binding block.
"""
	var mf := FileAccess.open(CAPTURE_META, FileAccess.WRITE)
	if mf:
		mf.store_string(meta)
		mf.close()
