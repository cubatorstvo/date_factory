extends SceneTree
## Headless builder: reusable city POI prefabs (does not touch city.tscn).
## Uses already-imported pack meshes + multi-part authored temporaries where packs lack objects.


const OUT_DIR := "res://scenes/art/city/prefabs/"

const P_BUILDING_S := "res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf"
const P_BUILDING_M := "res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf"
const P_DOOR := "res://assets/environment/city/downtown_megakit/meshes/Door_1.gltf"
const P_WINDOW := "res://assets/environment/city/downtown_megakit/meshes/Brick_Window_Square_Single.gltf"
const P_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Prop_Planter_Single.gltf"
const P_SIDEWALK_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Sidewalk_Planter.gltf"
const P_BOLLARD := "res://assets/environment/city/downtown_megakit/meshes/Prop_Bollard.gltf"
const P_BENCH := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Bench.gltf"
const P_COUNTER := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Counter_Straight.gltf"
const P_TABLE := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Table.gltf"
const P_STOOL := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Stool.gltf"
const P_SIGN := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_Sign.gltf"
const P_SAKURA := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_SakuraFlower.gltf"
const P_PLANT := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_Plant1.gltf"
const P_CHAIR := "res://assets/environment/interior/house_interior/meshes/Chair_1.fbx"
const P_MIRROR := "res://assets/environment/interior/house_interior/meshes/Bathroom_Mirror1.fbx"
const P_SHELF := "res://assets/environment/interior/house_interior/meshes/Shelf_1.fbx"
const P_BOOKSHELF := "res://assets/environment/interior/house_interior/meshes/Bookshelf.fbx"
const P_DESK_LAMP := "res://assets/environment/interior/house_interior/meshes/Light_Desk.fbx"
const P_LIGHT_STAND := "res://assets/environment/interior/house_interior/meshes/Light_Stand1.fbx"
const P_TRASH := "res://assets/environment/interior/house_interior/meshes/Trashcan_Cylindric.fbx"
const P_HOUSEPLANT := "res://assets/environment/interior/house_interior/meshes/Houseplant_1.fbx"
const P_SCIFI_DESK := "res://assets/environment/lab/scifi_essentials/meshes/Prop_Desk_Small.gltf"
const P_SCIFI_SHELF := "res://assets/environment/lab/scifi_essentials/meshes/Prop_Shelves_ThinTall.gltf"
const P_SCIFI_CHAIR := "res://assets/environment/lab/scifi_essentials/meshes/Prop_Chair.gltf"
const P_SCREEN_S := "res://assets/environment/factory/kenney_factory/meshes/screen-small.glb"
const P_SCREEN_W := "res://assets/environment/factory/kenney_factory/meshes/screen-wide.glb"
const P_SCREEN_P := "res://assets/environment/factory/kenney_factory/meshes/screen-panel-small.glb"
const P_MACHINE := "res://assets/environment/factory/kenney_factory/meshes/machine.glb"
const P_CHOCO := "res://assets/props/food/meshes/ChocolateBar.fbx"
const P_BOTTLE := "res://assets/props/food/meshes/Bottle1.fbx"
const P_CUPCAKE := "res://assets/props/food/meshes/Cupcake.fbx"
const P_APPLE := "res://assets/props/food/meshes/Apple.fbx"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var built: PackedStringArray = PackedStringArray()
	built.append(_save(_prefab_flower_shop()))
	built.append(_save(_prefab_storefront("JewelryShop", Color(0.85, 0.75, 0.35), P_SHELF, P_BOTTLE, "jewelry")))
	built.append(_save(_prefab_storefront("GiftShop", Color(0.85, 0.45, 0.55), P_SHELF, P_CUPCAKE, "gift")))
	built.append(_save(_prefab_storefront("ClothingShop", Color(0.45, 0.55, 0.85), P_BOOKSHELF, P_HOUSEPLANT, "clothing")))
	built.append(_save(_prefab_storefront("HomewareShop", Color(0.55, 0.7, 0.55), P_SHELF, P_APPLE, "homeware")))
	built.append(_save(_prefab_park_restaurant()))
	built.append(_save(_prefab_bench("MainBench", true)))
	built.append(_save(_prefab_bench("ParkBench", false)))
	built.append(_save(_prefab_duck_feeding()))
	built.append(_save(_prefab_karaoke()))
	built.append(_save(_prefab_internet_cafe()))
	built.append(_save(_prefab_bar()))
	built.append(_save(_prefab_bus_candy()))
	built.append(_save(_prefab_gym()))
	built.append(_save(_prefab_cinema()))
	built.append(_save(_prefab_arcade()))
	built.append(_save(_prefab_photo_studio()))
	built.append(_save(_prefab_barber()))
	built.append(_save(_prefab_agency()))
	built.append(_save(_prefab_index(built)))
	print("CITY_POI_PREFABS_BUILT count=%d" % built.size())
	for p in built:
		print("PREFAB %s" % p)
	quit(0)


func _save(root: Node3D) -> String:
	var path := OUT_DIR + root.name + ".tscn"
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		push_error("pack failed %s err=%s" % [path, error_string(err)])
		root.free()
		return path
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("save failed %s err=%s" % [path, error_string(err)])
	root.free()
	return path


func _set_owner_recursive(n: Node, owner: Node) -> void:
	## Do not recurse into PackedScene instances — that bakes editable overrides and
	## causes Godot "incoming node's name clashes" load errors.
	for c in n.get_children():
		c.owner = owner
		if not c.scene_file_path.is_empty():
			continue
		_set_owner_recursive(c, owner)


func _base(name: String) -> Node3D:
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
	box.size = Vector3(2.4, 2.4, 1.6)
	shape.shape = box
	shape.position = Vector3(0, 1.2, 0)
	collision.add_child(shape)
	var anchors := Node3D.new()
	anchors.name = "Anchors"
	root.add_child(anchors)
	_marker(anchors, "InteractAnchor", Vector3(0, 1.1, 1.1))
	_marker(anchors, "PromptAnchor", Vector3(0, 1.7, 1.1))
	_marker(anchors, "OutlineTarget", Vector3(0, 1.0, 0))
	return root


func _marker(parent: Node, name: String, pos: Vector3) -> Marker3D:
	var m := Marker3D.new()
	m.name = name
	m.position = pos
	parent.add_child(m)
	return m


func _instance_at(parent: Node, path: String, pos: Vector3, rot_y: float = 0.0, scale: Vector3 = Vector3.ONE) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("missing mesh %s" % path)
		return _csg_box(parent, "Missing_%s" % path.get_file().get_basename(), pos, Vector3(0.4, 0.4, 0.4), Color(1, 0, 1))
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_warning("unloadable %s" % path)
		return _csg_box(parent, "Bad_%s" % path.get_file().get_basename(), pos, Vector3(0.4, 0.4, 0.4), Color(1, 0, 1))
	var n: Node = packed.instantiate()
	if n is Node3D:
		var n3: Node3D = n as Node3D
		n3.name = "%s_Inst" % path.get_file().get_basename()
		n3.position = pos
		n3.rotation_degrees.y = rot_y
		n3.scale = scale
		parent.add_child(n3)
		return n3
	parent.add_child(n)
	return _csg_box(parent, "Non3D", pos, Vector3(0.3, 0.3, 0.3), Color(1, 0, 1))


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


func _csg_cyl(parent: Node, name: String, pos: Vector3, r: float, h: float, color: Color) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.name = name
	c.radius = r
	c.height = h
	c.position = pos
	c.material = _mat(color)
	parent.add_child(c)
	return c


func _csg_sphere(parent: Node, name: String, pos: Vector3, r: float, color: Color) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.name = name
	s.radius = r
	s.position = pos
	s.material = _mat(color)
	parent.add_child(s)
	return s


func _awning(visuals: Node, color: Color, y: float = 2.35) -> void:
	_csg_box(visuals, "Awning", Vector3(0, y, 0.95), Vector3(2.6, 0.08, 0.9), color)
	_csg_box(visuals, "AwningStripe", Vector3(0, y - 0.06, 0.95), Vector3(2.6, 0.04, 0.9), color.darkened(0.2))


func _window_glow(visuals: Node, color: Color) -> void:
	_csg_box(visuals, "WindowPane", Vector3(0, 1.35, 0.72), Vector3(1.6, 1.1, 0.05), color.lightened(0.35))


func _prefab_flower_shop() -> Node3D:
	var root := _base("FlowerShop")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_DOOR, Vector3(0.7, 0, 0.55), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_WINDOW, Vector3(-0.55, 0.9, 0.65), 0.0, Vector3(0.8, 0.8, 0.8))
	_awning(v, Color(0.55, 0.78, 0.45))
	_window_glow(v, Color(0.75, 0.95, 0.7))
	_instance_at(v, P_SAKURA, Vector3(-0.7, 0.95, 0.9), 20.0, Vector3(1.2, 1.2, 1.2))
	_instance_at(v, P_PLANT, Vector3(0.55, 0.95, 0.85), -15.0, Vector3(1.1, 1.1, 1.1))
	_instance_at(v, P_PLANTER, Vector3(-1.1, 0, 1.0), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_HOUSEPLANT, Vector3(1.05, 0, 0.95), 0.0, Vector3(0.9, 0.9, 0.9))
	root.set_meta("source_pack", "Downtown MegaKit + Sushi Decoration + House plants")
	root.set_meta("license", "CC0 Quaternius / pack licenses in assets/")
	root.set_meta("temp_parts", "awning/window CSG accent only")
	return root


func _prefab_storefront(name: String, accent: Color, shelf_path: String, prop_path: String, kind: String) -> Node3D:
	var root := _base(name)
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.35), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_DOOR, Vector3(0.65, 0, 0.55), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_WINDOW, Vector3(-0.5, 0.9, 0.65), 0.0, Vector3(0.85, 0.85, 0.85))
	_awning(v, accent)
	_window_glow(v, accent.lightened(0.25))
	_instance_at(v, shelf_path, Vector3(-0.35, 0.2, 0.15), 180.0, Vector3(0.7, 0.7, 0.7))
	_instance_at(v, prop_path, Vector3(0.2, 1.05, 0.8), 0.0, Vector3(1.3, 1.3, 1.3))
	_instance_at(v, P_SIGN, Vector3(0, 2.55, 0.7), 0.0, Vector3(0.8, 0.8, 0.8))
	_csg_box(v, "IdentityBand", Vector3(0, 2.15, 0.7), Vector3(2.2, 0.12, 0.08), accent)
	root.set_meta("store_kind", kind)
	root.set_meta("source_pack", "Downtown + House/Food/Sushi props")
	root.set_meta("temp_parts", "awning/identity band CSG")
	return root


func _prefab_park_restaurant() -> Node3D:
	var root := _base("ParkRestaurant")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.6), 0.0, Vector3(0.45, 0.45, 0.45))
	_instance_at(v, P_DOOR, Vector3(0, 0, 0.7), 0.0, Vector3(1, 1, 1))
	_awning(v, Color(0.75, 0.35, 0.3), 2.5)
	_instance_at(v, P_COUNTER, Vector3(-0.8, 0, 0.9), 90.0, Vector3(0.8, 0.8, 0.8))
	_instance_at(v, P_TABLE, Vector3(1.1, 0, 1.3), 15.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_STOOL, Vector3(1.5, 0, 1.1), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_SIGN, Vector3(0, 2.7, 0.75), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_PLANT, Vector3(-1.4, 0, 1.2), 0.0, Vector3(1.2, 1.2, 1.2))
	_marker(root.get_node("Anchors"), "DateSeatAnchor", Vector3(1.1, 0.55, 1.3))
	root.set_meta("source_pack", "Downtown facade + Sushi Restaurant Kit interior cues")
	root.set_meta("license_note", "Sushi kit: project-side license record incomplete — see ASSET_LICENSE_REGISTRY")
	return root


func _prefab_bench(name: String, central: bool) -> Node3D:
	var root := _base(name)
	var v: Node = root.get_node("Visuals")
	var shape: CollisionShape3D = root.get_node("Collision/Shape")
	(shape.shape as BoxShape3D).size = Vector3(1.8, 0.9, 0.8)
	shape.position = Vector3(0, 0.45, 0)
	_instance_at(v, P_BENCH, Vector3(0, 0, 0), 0.0, Vector3(1.1, 1.1, 1.1))
	if central:
		_instance_at(v, P_PLANTER, Vector3(-1.2, 0, 0.2), 0.0, Vector3(0.9, 0.9, 0.9))
		_instance_at(v, P_BOLLARD, Vector3(1.15, 0, 0.35), 0.0, Vector3(1, 1, 1))
	else:
		_instance_at(v, P_SIDEWALK_PLANTER, Vector3(-1.1, 0, -0.2), 0.0, Vector3(0.8, 0.8, 0.8))
	_marker(root.get_node("Anchors"), "SitAnchor", Vector3(0, 0.5, 0.15))
	_marker(root.get_node("Anchors"), "StandAnchor", Vector3(0, 0, 0.85))
	root.set_meta("source_pack", "Sushi Environment_Bench + Downtown planters")
	return root


func _prefab_duck_feeding() -> Node3D:
	var root := _base("DuckFeeding")
	var v: Node = root.get_node("Visuals")
	var shape: CollisionShape3D = root.get_node("Collision/Shape")
	(shape.shape as BoxShape3D).size = Vector3(2.2, 1.2, 2.2)
	shape.position = Vector3(0, 0.4, 0)
	_csg_cyl(v, "PondRim", Vector3(0, 0.05, 0), 1.1, 0.12, Color(0.35, 0.45, 0.4))
	_csg_cyl(v, "Water", Vector3(0, 0.08, 0), 0.95, 0.06, Color(0.35, 0.55, 0.7))
	_instance_at(v, P_PLANTER, Vector3(-1.2, 0, 0.9), 0.0, Vector3(0.8, 0.8, 0.8))
	_authored_duck(v, "DuckA", Vector3(0.35, 0.18, 0.15), 30.0)
	_authored_duck(v, "DuckB", Vector3(-0.25, 0.18, -0.2), -40.0)
	_csg_box(v, "FeederBag", Vector3(0.9, 0.35, 0.85), Vector3(0.25, 0.7, 0.25), Color(0.45, 0.35, 0.25))
	_csg_box(v, "FeederTray", Vector3(0.9, 0.7, 0.85), Vector3(0.45, 0.08, 0.35), Color(0.55, 0.45, 0.3))
	_marker(root.get_node("Anchors"), "FoodAnchor", Vector3(0.9, 0.75, 0.85))
	_marker(root.get_node("Anchors"), "DuckReactionArea", Vector3(0, 0.2, 0))
	root.set_meta("temp_parts", "authored stylized ducks + pond rim/water/feeder")
	root.set_meta("future_replacement", "compact low-poly duck 0.35-0.5m + real pond prop")
	root.set_meta("packs_checked", "Downtown/House/Food/Sushi/Factory/Sci-Fi + Downloads zips — no duck mesh")
	return root


func _authored_duck(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var g := Node3D.new()
	g.name = name
	g.position = pos
	g.rotation_degrees.y = yaw
	parent.add_child(g)
	_csg_sphere(g, "Body", Vector3(0, 0.08, 0), 0.12, Color(0.92, 0.78, 0.25))
	_csg_sphere(g, "Head", Vector3(0.1, 0.16, 0.02), 0.07, Color(0.2, 0.35, 0.55))
	_csg_box(g, "Beak", Vector3(0.17, 0.15, 0.02), Vector3(0.08, 0.03, 0.04), Color(0.95, 0.55, 0.2))
	_csg_box(g, "WingL", Vector3(0.0, 0.1, 0.1), Vector3(0.12, 0.03, 0.08), Color(0.85, 0.7, 0.2))
	_csg_box(g, "WingR", Vector3(0.0, 0.1, -0.1), Vector3(0.12, 0.03, 0.08), Color(0.85, 0.7, 0.2))


func _prefab_karaoke() -> Node3D:
	var root := _base("KaraokeStand")
	var v: Node = root.get_node("Visuals")
	_csg_box(v, "StageDeck", Vector3(0, 0.08, 0), Vector3(2.2, 0.16, 1.4), Color(0.35, 0.2, 0.35))
	_csg_cyl(v, "MicPole", Vector3(0.35, 0.85, 0.25), 0.03, 1.4, Color(0.25, 0.25, 0.28))
	_csg_sphere(v, "MicHead", Vector3(0.35, 1.55, 0.25), 0.07, Color(0.15, 0.15, 0.18))
	_csg_box(v, "MicGrill", Vector3(0.35, 1.55, 0.32), Vector3(0.06, 0.06, 0.04), Color(0.55, 0.55, 0.6))
	_csg_box(v, "SpeakerL", Vector3(-0.85, 0.55, 0.1), Vector3(0.35, 0.9, 0.3), Color(0.2, 0.2, 0.22))
	_csg_box(v, "SpeakerR", Vector3(0.85, 0.55, 0.1), Vector3(0.35, 0.9, 0.3), Color(0.2, 0.2, 0.22))
	_instance_at(v, P_SCREEN_S, Vector3(0, 1.35, -0.25), 0.0, Vector3(1.2, 1.2, 1.2))
	_instance_at(v, P_LIGHT_STAND, Vector3(-1.15, 0, -0.2), 0.0, Vector3(0.9, 0.9, 0.9))
	_csg_box(v, "AccentLight", Vector3(0, 2.0, 0.1), Vector3(0.3, 0.12, 0.3), Color(0.95, 0.4, 0.7))
	root.set_meta("temp_parts", "mic/stand/speakers/stage deck CSG; screen+light from packs")
	root.set_meta("source_pack", "Kenney Factory screens + House Light_Stand")
	root.set_meta("future_replacement", "low-poly wired mic + adjustable stand")
	return root


func _prefab_internet_cafe() -> Node3D:
	var root := _base("InternetCafe")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.4, 0.65, 0.85))
	_window_glow(v, Color(0.55, 0.8, 0.95))
	_instance_at(v, P_SCIFI_DESK, Vector3(-0.35, 0, 0.2), 180.0, Vector3(0.85, 0.85, 0.85))
	_instance_at(v, P_SCREEN_P, Vector3(-0.35, 0.95, 0.05), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_SCIFI_CHAIR, Vector3(-0.35, 0, 0.85), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_BOTTLE, Vector3(0.35, 0.95, 0.7), 0.0, Vector3(1.2, 1.2, 1.2))
	root.set_meta("source_pack", "Downtown + Sci-Fi desk/chair + Kenney screen + Food bottle")
	return root


func _prefab_bar() -> Node3D:
	var root := _base("BarFacade")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.55, 0.25, 0.3))
	_instance_at(v, P_COUNTER, Vector3(0, 0, 0.75), 0.0, Vector3(0.85, 0.85, 0.85))
	_instance_at(v, P_STOOL, Vector3(-0.55, 0, 1.15), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_STOOL, Vector3(0.55, 0, 1.15), 0.0, Vector3(1, 1, 1))
	_instance_at(v, P_BOTTLE, Vector3(-0.2, 1.05, 0.7), 0.0, Vector3(1.3, 1.3, 1.3))
	_instance_at(v, P_BOTTLE, Vector3(0.15, 1.05, 0.7), 10.0, Vector3(1.3, 1.3, 1.3))
	_csg_box(v, "NeonBand", Vector3(0, 2.2, 0.7), Vector3(2.0, 0.1, 0.06), Color(0.9, 0.25, 0.45))
	root.set_meta("source_pack", "Downtown + Sushi counter/stools + Food bottles")
	return root


func _prefab_bus_candy() -> Node3D:
	var root := _base("BusStopCandy")
	var v: Node = root.get_node("Visuals")
	_csg_box(v, "ShelterRoof", Vector3(0, 2.3, 0), Vector3(2.8, 0.1, 1.4), Color(0.3, 0.35, 0.4))
	_csg_cyl(v, "PoleL", Vector3(-1.2, 1.15, -0.5), 0.05, 2.3, Color(0.4, 0.4, 0.45))
	_csg_cyl(v, "PoleR", Vector3(1.2, 1.15, -0.5), 0.05, 2.3, Color(0.4, 0.4, 0.45))
	_csg_box(v, "GlassBack", Vector3(0, 1.2, -0.55), Vector3(2.4, 1.8, 0.05), Color(0.6, 0.75, 0.85, 0.55))
	_instance_at(v, P_BENCH, Vector3(0, 0, 0.1), 0.0, Vector3(1, 1, 1))
	_csg_box(v, "InfoSign", Vector3(1.35, 1.5, 0.35), Vector3(0.08, 1.0, 0.55), Color(0.2, 0.35, 0.55))
	_csg_box(v, "CandyMachineBody", Vector3(-1.35, 0.75, 0.45), Vector3(0.55, 1.5, 0.45), Color(0.85, 0.25, 0.35))
	_csg_box(v, "CandyGlass", Vector3(-1.35, 1.0, 0.7), Vector3(0.4, 0.7, 0.05), Color(0.7, 0.9, 1.0))
	_instance_at(v, P_CHOCO, Vector3(-1.35, 1.35, 0.55), 0.0, Vector3(1.5, 1.5, 1.5))
	_instance_at(v, P_TRASH, Vector3(1.55, 0, 0.7), 0.0, Vector3(0.8, 0.8, 0.8))
	_marker(root.get_node("Anchors"), "SitAnchor", Vector3(0, 0.5, 0.15))
	root.set_meta("temp_parts", "bus shelter + candy machine CSG; bench/trash/chocolate from packs")
	root.set_meta("packs_checked", "Downtown Standard subset has no bus shelter mesh")
	root.set_meta("future_replacement", "urban bus shelter + vending machine prop")
	return root


func _prefab_gym() -> Node3D:
	var root := _base("GymFacade")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.45), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.3, 0.7, 0.45))
	_instance_at(v, P_MACHINE, Vector3(-0.55, 0, 0.55), 0.0, Vector3(0.9, 0.9, 0.9))
	_csg_box(v, "RackUprightL", Vector3(0.55, 0.85, 0.55), Vector3(0.08, 1.7, 0.08), Color(0.25, 0.25, 0.28))
	_csg_box(v, "RackUprightR", Vector3(1.05, 0.85, 0.55), Vector3(0.08, 1.7, 0.08), Color(0.25, 0.25, 0.28))
	_csg_cyl(v, "Barbell", Vector3(0.8, 1.15, 0.55), 0.04, 0.7, Color(0.35, 0.35, 0.38))
	_csg_cyl(v, "PlateL", Vector3(0.5, 1.15, 0.55), 0.14, 0.06, Color(0.2, 0.2, 0.22))
	_csg_cyl(v, "PlateR", Vector3(1.1, 1.15, 0.55), 0.14, 0.06, Color(0.2, 0.2, 0.22))
	_csg_box(v, "Mat", Vector3(0.2, 0.03, 1.15), Vector3(1.4, 0.05, 0.7), Color(0.2, 0.45, 0.3))
	root.set_meta("temp_parts", "rack/barbell/mat CSG; Kenney machine as cardio silhouette")
	root.set_meta("future_replacement", "dedicated gym bench/rack/cardio props")
	return root


func _prefab_cinema() -> Node3D:
	var root := _base("CinemaFacade")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.55), 0.0, Vector3(0.5, 0.5, 0.5))
	_csg_box(v, "Marquee", Vector3(0, 2.55, 0.85), Vector3(3.2, 0.45, 0.7), Color(0.15, 0.15, 0.18))
	_csg_box(v, "MarqueeLights", Vector3(0, 2.55, 1.15), Vector3(3.0, 0.12, 0.08), Color(0.95, 0.85, 0.35))
	_instance_at(v, P_SCREEN_W, Vector3(0, 1.4, 0.55), 0.0, Vector3(1.4, 1.2, 1.0))
	_instance_at(v, P_CHAIR, Vector3(-0.7, 0, 1.2), 180.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_CHAIR, Vector3(0.7, 0, 1.2), 180.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_DOOR, Vector3(0, 0, 0.75), 0.0, Vector3(1, 1, 1))
	_marker(root.get_node("Anchors"), "SitAnchor", Vector3(0, 0.5, 1.2))
	root.set_meta("temp_parts", "marquee CSG; seats/screen/door/building from packs")
	root.set_meta("source_pack", "Downtown + Kenney screen-wide + House chairs")
	return root


func _prefab_arcade() -> Node3D:
	var root := _base("ArcadeFacade")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.45), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.55, 0.25, 0.75))
	_authored_cabinet(v, "CabA", Vector3(-0.55, 0, 0.7), Color(0.25, 0.45, 0.9))
	_authored_cabinet(v, "CabB", Vector3(0.45, 0, 0.7), Color(0.85, 0.3, 0.45))
	_instance_at(v, P_SCREEN_S, Vector3(-0.55, 1.25, 0.95), 0.0, Vector3(0.85, 0.85, 0.85))
	_instance_at(v, P_SCREEN_S, Vector3(0.45, 1.25, 0.95), 0.0, Vector3(0.85, 0.85, 0.85))
	root.set_meta("temp_parts", "cabinet housings CSG around Kenney screens")
	root.set_meta("future_replacement", "stylized arcade cabinet 1.6-1.9m")
	return root


func _authored_cabinet(parent: Node, name: String, pos: Vector3, color: Color) -> void:
	var g := Node3D.new()
	g.name = name
	g.position = pos
	parent.add_child(g)
	_csg_box(g, "Body", Vector3(0, 0.85, 0), Vector3(0.7, 1.7, 0.55), color)
	_csg_box(g, "ControlDeck", Vector3(0, 0.95, 0.28), Vector3(0.65, 0.12, 0.25), color.darkened(0.15))
	_csg_cyl(g, "Joystick", Vector3(-0.12, 1.08, 0.3), 0.03, 0.18, Color(0.1, 0.1, 0.1))
	_csg_sphere(g, "ButtonA", Vector3(0.12, 1.02, 0.32), 0.035, Color(0.95, 0.2, 0.2))
	_csg_sphere(g, "ButtonB", Vector3(0.22, 1.02, 0.32), 0.035, Color(0.95, 0.85, 0.2))


func _prefab_photo_studio() -> Node3D:
	var root := _base("PhotoStudio")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.9, 0.9, 0.92))
	_instance_at(v, P_LIGHT_STAND, Vector3(-0.85, 0, 0.85), 25.0, Vector3(1, 1, 1))
	_instance_at(v, P_DESK_LAMP, Vector3(0.7, 0.9, 0.55), -20.0, Vector3(1.1, 1.1, 1.1))
	_csg_box(v, "Backdrop", Vector3(0, 1.2, -0.05), Vector3(1.8, 2.0, 0.06), Color(0.95, 0.92, 0.88))
	_csg_cyl(v, "TripodLegA", Vector3(0.35, 0.55, 0.95), 0.025, 1.1, Color(0.2, 0.2, 0.22))
	_csg_cyl(v, "TripodLegB", Vector3(0.55, 0.55, 0.8), 0.025, 1.1, Color(0.2, 0.2, 0.22))
	_csg_box(v, "CameraBody", Vector3(0.45, 1.2, 0.9), Vector3(0.22, 0.14, 0.18), Color(0.12, 0.12, 0.14))
	_csg_cyl(v, "Lens", Vector3(0.45, 1.2, 1.05), 0.06, 0.1, Color(0.1, 0.1, 0.12))
	_instance_at(v, P_SCREEN_P, Vector3(-0.2, 1.1, 0.2), 0.0, Vector3(0.8, 0.8, 0.8))
	root.set_meta("temp_parts", "tripod/camera/backdrop CSG; lights/screen from packs")
	root.set_meta("future_replacement", "camera + tripod + softbox set")
	return root


func _prefab_barber() -> Node3D:
	var root := _base("BarberShop")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.4), 0.0, Vector3(0.55, 0.55, 0.55))
	_awning(v, Color(0.85, 0.85, 0.9))
	_csg_cyl(v, "PoleStripe", Vector3(-1.05, 1.2, 0.9), 0.07, 1.6, Color(0.9, 0.2, 0.25))
	_csg_cyl(v, "PoleStripeWhite", Vector3(-1.05, 1.2, 0.9), 0.075, 0.4, Color(0.95, 0.95, 0.95))
	_instance_at(v, P_CHAIR, Vector3(0.15, 0, 0.75), 180.0, Vector3(1, 1, 1))
	_instance_at(v, P_MIRROR, Vector3(0.15, 1.2, 0.15), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_SHELF, Vector3(-0.55, 0.2, 0.1), 180.0, Vector3(0.6, 0.6, 0.6))
	root.set_meta("source_pack", "Downtown + House chair/mirror/shelf")
	root.set_meta("temp_parts", "barber pole CSG accent")
	return root


func _prefab_agency() -> Node3D:
	var root := _base("AgencyOffice")
	var v: Node = root.get_node("Visuals")
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.55), 0.0, Vector3(0.45, 0.45, 0.45))
	_awning(v, Color(0.35, 0.4, 0.5), 2.5)
	_instance_at(v, P_SCIFI_DESK, Vector3(0, 0, 0.35), 180.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(v, P_SCIFI_SHELF, Vector3(-0.9, 0, 0.1), 90.0, Vector3(0.85, 0.85, 0.85))
	_instance_at(v, P_SCREEN_W, Vector3(0.2, 1.2, 0.15), 0.0, Vector3(1.1, 1.0, 1.0))
	_instance_at(v, P_SCIFI_CHAIR, Vector3(0, 0, 0.95), 0.0, Vector3(0.9, 0.9, 0.9))
	_csg_box(v, "BoardSign", Vector3(0, 2.45, 0.8), Vector3(1.8, 0.35, 0.08), Color(0.2, 0.25, 0.35))
	root.set_meta("source_pack", "Downtown + Sci-Fi desk/shelf/chair + Kenney screen")
	return root


func _prefab_index(paths: PackedStringArray) -> Node3D:
	var root := Node3D.new()
	root.name = "City_POI_Prefab_Index"
	var note := Label3D.new()
	note.name = "Note"
	note.text = "City POI prefabs (open children). city.tscn not modified."
	note.position = Vector3(0, 3.2, 0)
	note.font_size = 28
	root.add_child(note)
	var x := 0.0
	for p in paths:
		if p.ends_with("City_POI_Prefab_Index.tscn"):
			continue
		if not ResourceLoader.exists(p):
			continue
		var packed: PackedScene = load(p) as PackedScene
		if packed == null:
			continue
		var inst: Node = packed.instantiate()
		if inst is Node3D:
			(inst as Node3D).position = Vector3(x, 0, 0)
			root.add_child(inst)
			x += 4.5
	return root
