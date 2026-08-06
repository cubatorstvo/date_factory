extends SceneTree
## CITY-PROXY-POI-001-SCENES — generate proxy POI PackedScenes + rewire city.tscn.
## Run:
##   Godot_v4.7.*_console.exe --headless --path <project> --script res://tools/build_city_proxy_poi.gd


const OUT_BUILDINGS := "res://scenes/art/city/poi/buildings/"
const OUT_ACTIVITIES := "res://scenes/art/city/poi/activities/"
const CITY_PATH := "res://scenes/world/city/city.tscn"
const SCRIPT_BUILDING := "res://scenes/art/city/poi/core/CityPOIBuilding.gd"
const SCRIPT_TENANT := "res://scenes/art/city/poi/core/CityPOITenant.gd"
const SCRIPT_INTERACTABLE := "res://modules/interaction/interactable.gd"
const GATE_SCENE := "res://scenes/art/city/poi/core/DistrictGate.tscn"

const P_BUILDING_S := "res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf"
const P_BUILDING_M := "res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf"
const P_BUILDING_L := "res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf"
const P_WINDOW := "res://assets/environment/city/downtown_megakit/meshes/Brick_Window_Square_Single.gltf"
const P_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Prop_Planter_Single.gltf"
const P_SIDEWALK_PLANTER := "res://assets/environment/city/downtown_megakit/meshes/Sidewalk_Planter.gltf"
const P_BOLLARD := "res://assets/environment/city/downtown_megakit/meshes/Prop_Bollard.gltf"
const P_BENCH := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Bench.gltf"
const P_COUNTER := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Counter_Straight.gltf"
const P_TABLE := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Table.gltf"
const P_STOOL := "res://assets/environment/restaurant/sushi_restaurant/meshes/Environment/Environment_Stool.gltf"
const P_SAKURA := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_SakuraFlower.gltf"
const P_PLANT := "res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_Plant1.gltf"
const P_CHAIR := "res://assets/environment/interior/house_interior/meshes/Chair_1.fbx"
const P_MIRROR := "res://assets/environment/interior/house_interior/meshes/Bathroom_Mirror1.fbx"
const P_SHELF := "res://assets/environment/interior/house_interior/meshes/Shelf_1.fbx"
const P_BOOKSHELF := "res://assets/environment/interior/house_interior/meshes/Bookshelf.fbx"
const P_HOUSEPLANT := "res://assets/environment/interior/house_interior/meshes/Houseplant_1.fbx"
const P_LIGHT_STAND := "res://assets/environment/interior/house_interior/meshes/Light_Stand1.fbx"
const P_TRASH := "res://assets/environment/interior/house_interior/meshes/Trashcan_Cylindric.fbx"
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

## Local entrance on +Z façade; InteractionArea centered there.
const ENTRANCE_Z := 1.05


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_BUILDINGS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_ACTIVITIES))

	var built: PackedStringArray = PackedStringArray()
	built.append(_save_building(_b_player_home()))
	built.append(_save_building(_b_cafe()))
	built.append(_save_building(_b_cinema()))
	built.append(_save_building(_b_retail_flower_gift()))
	built.append(_save_building(_b_fashion_jewelry_clothing()))
	built.append(_save_building(_b_proxy_homeware()))
	built.append(_save_building(_b_proxy_internet()))
	built.append(_save_building(_b_proxy_bookstore()))
	built.append(_save_building(_b_proxy_gym()))
	built.append(_save_building(_b_proxy_photo()))
	built.append(_save_building(_b_proxy_barber()))
	built.append(_save_building(_b_proxy_agency()))
	built.append(_save_building(_b_proxy_arcade()))
	built.append(_save_building(_b_proxy_bar()))
	built.append(_save_building(_b_park_restaurant()))
	built.append(_save_activity(_a_main_bench()))
	built.append(_save_activity(_a_park_bench()))
	built.append(_save_activity(_a_duck()))
	built.append(_save_activity(_a_karaoke()))
	built.append(_save_activity(_a_bus()))

	print("CITY_PROXY_POI_BUILT count=%d" % built.size())
	for p in built:
		print("POI %s" % p)

	var ok: bool = _rewrite_city_tscn()
	if not ok:
		push_error("CITY_PROXY_POI city.tscn rewrite FAILED")
		quit(1)
		return
	print("CITY_PROXY_POI city.tscn REWIRED")
	_validate_instantiates(built)
	quit(0)


func _validate_instantiates(paths: PackedStringArray) -> void:
	var fails: int = 0
	for p in paths:
		if not ResourceLoader.exists(p):
			push_error("MISSING %s" % p)
			fails += 1
			continue
		var ps: PackedScene = load(p) as PackedScene
		if ps == null:
			push_error("UNLOADABLE %s" % p)
			fails += 1
			continue
		var n: Node = ps.instantiate()
		if n == null:
			push_error("INSTANTIATE_FAIL %s" % p)
			fails += 1
			continue
		var interacts: int = _count_interactables(n)
		print("VALIDATE %s interacts=%d" % [p, interacts])
		n.free()
	var city_ps: PackedScene = load(CITY_PATH) as PackedScene
	if city_ps == null:
		push_error("CITY unloadable")
		fails += 1
	else:
		var city: Node = city_ps.instantiate()
		var pois: Node = city.get_node_or_null("POIs")
		var n_pois: int = 0 if pois == null else pois.get_child_count()
		print("VALIDATE city POIs children=%d" % n_pois)
		city.free()
	print("CITY_PROXY_POI_VALIDATE fails=%d" % fails)


func _count_interactables(n: Node) -> int:
	var c: int = 0
	if n is Interactable:
		c += 1
	for ch in n.get_children():
		c += _count_interactables(ch)
	return c


# ─── save helpers ─────────────────────────────────────────────────────────────

func _save_building(root: Node3D) -> String:
	return _save(root, OUT_BUILDINGS)


func _save_activity(root: Node3D) -> String:
	return _save(root, OUT_ACTIVITIES)


func _save(root: Node3D, dir: String) -> String:
	var path: String = dir + root.name + ".tscn"
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
	for c in n.get_children():
		c.owner = owner
		if not c.scene_file_path.is_empty():
			continue
		_set_owner_recursive(c, owner)


# ─── building / tenant scaffolding ────────────────────────────────────────────

func _new_building(name: String, building_id: String, district: String, mode: String, lot: Vector2) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.set_script(load(SCRIPT_BUILDING))
	root.set("building_id", building_id)
	root.set("district_id", district)
	root.set("building_mode", mode)
	root.set("reserved_lot_size", lot)

	var visual := Node3D.new()
	visual.name = "VisualRoot"
	root.add_child(visual)

	var collision := Node3D.new()
	collision.name = "CollisionRoot"
	root.add_child(collision)

	var lot_n := MeshInstance3D.new()
	lot_n.name = "LotBounds"
	var box := BoxMesh.new()
	box.size = Vector3(lot.x, 0.08, lot.y)
	lot_n.mesh = box
	lot_n.position = Vector3(0.0, 0.04, 0.0)
	var lot_mat := StandardMaterial3D.new()
	lot_mat.albedo_color = Color(0.2, 0.7, 1.0, 0.18)
	lot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lot_n.material_override = lot_mat
	root.add_child(lot_n)

	var lights := Node3D.new()
	lights.name = "SharedLighting"
	root.add_child(lights)

	var slots := Node3D.new()
	slots.name = "TenantSlots"
	root.add_child(slots)
	return root


func _add_static_box(collision_root: Node, name: String, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = name
	collision_root.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)


func _new_tenant(
	parent: Node,
	name: String,
	poi_id: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	functional_type: String,
	stage: int,
	entrance_local: Vector3,
	payload: Dictionary = {}
) -> Node3D:
	var tenant := Node3D.new()
	tenant.name = name
	tenant.set_script(load(SCRIPT_TENANT))
	tenant.set("poi_id", poi_id)
	tenant.set("action_id", action_id)
	tenant.set("display_name", display_name)
	tenant.set("action_label", action_label)
	tenant.set("prompt_text", action_label)
	tenant.set("functional_type", functional_type)
	tenant.set("progression_stage", stage)
	var pl: Dictionary = payload.duplicate()
	if not pl.has("art_backed"):
		pl["art_backed"] = true
	tenant.set("payload", pl)
	parent.add_child(tenant)

	var ent := Marker3D.new()
	ent.name = "EntranceAnchor"
	ent.position = entrance_local
	tenant.add_child(ent)

	_add_interactable(tenant, "InteractionArea", action_id, display_name, action_label, entrance_local, pl)

	var prompt := Marker3D.new()
	prompt.name = "PromptAnchor"
	prompt.position = entrance_local + Vector3(0.0, 0.7, 0.0)
	tenant.add_child(prompt)

	var sign_a := Marker3D.new()
	sign_a.name = "SignAnchor"
	sign_a.position = Vector3(entrance_local.x, 2.4, 0.75)
	tenant.add_child(sign_a)

	var signage := Node3D.new()
	signage.name = "Signage"
	tenant.add_child(signage)

	var local_lights := Node3D.new()
	local_lights.name = "LocalLights"
	tenant.add_child(local_lights)

	var props := Node3D.new()
	props.name = "IdentityProps"
	tenant.add_child(props)
	return tenant


func _add_interactable(
	parent: Node,
	name: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	pos: Vector3,
	payload: Dictionary
) -> Interactable:
	var ia := Interactable.new()
	ia.name = name
	ia.action_id = action_id
	ia.display_name = display_name
	ia.action_label = action_label
	ia.payload = payload.duplicate()
	ia.position = pos
	parent.add_child(ia)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.2, 1.2)
	cs.shape = box
	cs.position = Vector3(0.0, 1.1, 0.0)
	ia.add_child(cs)
	return ia


func _add_sibling_interact(
	tenant: Node3D,
	name: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	pos: Vector3,
	payload: Dictionary
) -> void:
	_add_interactable(tenant, name, action_id, display_name, action_label, pos, payload)


func _signage(tenant: Node3D, text: String, board_color: Color, accent: Color) -> void:
	var signage: Node = tenant.get_node("Signage")
	var board := _csg_box(signage, "SignBoard", Vector3(0.0, 2.45, 0.78), Vector3(1.35, 0.36, 0.06), board_color)
	board.position.x = tenant.get_node("EntranceAnchor").position.x
	var accent_b := _csg_box(signage, "SignAccent", Vector3(0.0, 2.45, 0.82), Vector3(1.1, 0.1, 0.04), accent)
	accent_b.position.x = board.position.x
	var label := Label3D.new()
	label.name = "SignLabel"
	label.text = text
	label.font_size = 22
	label.shaded = true
	label.modulate = Color(1.0, 0.96, 0.9)
	label.position = Vector3(board.position.x, 2.45, 0.88)
	signage.add_child(label)


func _omni(parent: Node, name: String, pos: Vector3, color: Color, energy: float = 1.2, rng: float = 5.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = name
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	return l


# ─── mesh / csg helpers ───────────────────────────────────────────────────────

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


func _instance_at(parent: Node, path: String, pos: Vector3, rot_y: float = 0.0, scale: Vector3 = Vector3.ONE) -> Node3D:
	if not ResourceLoader.exists(path):
		push_warning("missing mesh %s" % path)
		return _csg_box(parent, "Missing_%s" % path.get_file().get_basename(), pos, Vector3(0.4, 0.4, 0.4), Color(1, 0, 1))
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
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


func _proxy_shell(
	visual: Node,
	size: Vector3,
	gf_color: Color,
	roof_color: Color,
	portal_w: float = 1.1,
	portal_h: float = 2.15,
	portal_x: float = 0.0
) -> void:
	## BoxMesh façade facing +Z; front face near z≈0.7, entrance ~1.05 in front.
	var front_face: float = 0.70
	var body := MeshInstance3D.new()
	body.name = "ProxyBody"
	var box := BoxMesh.new()
	box.size = size
	body.mesh = box
	body.position = Vector3(0.0, size.y * 0.5, front_face - size.z * 0.5)
	body.material_override = _mat(gf_color)
	visual.add_child(body)

	_csg_box(
		visual, "Roof",
		Vector3(0.0, size.y + 0.12, front_face - size.z * 0.5),
		Vector3(size.x + 0.25, 0.22, size.z + 0.15),
		roof_color
	)

	var portal_depth: float = 0.38
	## Dark inset portal on front face (not a glued door mesh).
	_csg_box(
		visual, "PortalInset",
		Vector3(portal_x, portal_h * 0.5, front_face - portal_depth * 0.5),
		Vector3(portal_w, portal_h, portal_depth),
		Color(0.08, 0.07, 0.09)
	)
	_csg_box(
		visual, "PortalFrame",
		Vector3(portal_x, portal_h * 0.5, front_face - 0.02),
		Vector3(portal_w + 0.16, portal_h + 0.16, 0.08),
		gf_color.darkened(0.25)
	)


func _awning(visual: Node, color: Color, y: float, width: float, z: float = 0.95) -> void:
	_csg_box(visual, "Awning", Vector3(0, y, z), Vector3(width, 0.08, 0.85), color)
	_csg_box(visual, "AwningStripe", Vector3(0, y - 0.06, z), Vector3(width, 0.04, 0.85), color.darkened(0.22))


# ─── landmark / ready buildings ───────────────────────────────────────────────

func _b_player_home() -> Node3D:
	var root: Node3D = _new_building("PlayerHome", "player_home", "main_street", "Landmark", Vector2(9, 8))
	var v: Node = root.get_node("VisualRoot")
	_instance_at(v, P_BUILDING_S, Vector3(0, 0, -0.45), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_WINDOW, Vector3(-0.55, 0.9, 0.65), 0.0, Vector3(0.8, 0.8, 0.8))
	_awning(v, Color(0.55, 0.45, 0.7), 2.35, 2.8)
	_instance_at(v, P_PLANTER, Vector3(-1.15, 0, 1.0), 0.0, Vector3(0.9, 0.9, 0.9))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.7, -0.3), Vector3(3.8, 3.4, 2.6))
	_omni(root.get_node("SharedLighting"), "WarmPorch", Vector3(0, 2.2, 1.0), Color(1.0, 0.85, 0.65), 1.0, 5.0)
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Home", "player_home", &"go_home",
		"Мой дом", "Войти домой", "VenueEntrancePOI", 1, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "HOME", Color(0.25, 0.18, 0.35), Color(0.75, 0.55, 0.95))
	_instance_at(t.get_node("IdentityProps"), P_HOUSEPLANT, Vector3(0.9, 0, 0.85), 0.0, Vector3(0.85, 0.85, 0.85))
	return root


func _b_cafe() -> Node3D:
	var root: Node3D = _new_building("CafeTwoHearts", "cafe_two_hearts", "main_street", "VenueEntrance", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	## Ready building — NO Door_1 mesh; EntranceAnchor in front of baked opening.
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.55), 0.0, Vector3(0.45, 0.45, 0.45))
	_awning(v, Color(0.95, 0.45, 0.55), 2.5, 2.8)
	_instance_at(v, P_TABLE, Vector3(1.45, 0, 0.45), 10.0, Vector3(0.48, 0.48, 0.48))
	_instance_at(v, P_STOOL, Vector3(1.75, 0, 0.25), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_COUNTER, Vector3(-0.95, 0, 0.35), 90.0, Vector3(0.52, 0.52, 0.52))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.8, -0.2), Vector3(4.4, 3.6, 3.0))
	_omni(root.get_node("SharedLighting"), "CafeWarm", Vector3(0, 2.35, 1.0), Color(1.0, 0.72, 0.45), 1.25, 6.0)
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Cafe", "cafe_two_hearts", &"sit_cafe",
		"Кафе Two Hearts", "Сесть и ждать свидание", "VenueEntrancePOI", 1, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "TWO HEARTS", Color(0.18, 0.1, 0.12), Color(1.0, 0.55, 0.35))
	_omni(t.get_node("LocalLights"), "PinkGlow", Vector3(0, 2.0, 0.9), Color(1.0, 0.55, 0.65), 0.7, 4.0)
	return root


func _b_cinema() -> Node3D:
	var root: Node3D = _new_building("Cinema", "cinema", "park_leisure", "Landmark", Vector2(14, 11))
	var v: Node = root.get_node("VisualRoot")
	## Scale carefully for lot 14×11.
	_instance_at(v, P_BUILDING_L, Vector3(0, 0, -1.0), 0.0, Vector3(0.32, 0.32, 0.32))
	_csg_box(v, "Marquee", Vector3(0, 3.2, 0.55), Vector3(5.5, 0.55, 0.9), Color(0.12, 0.08, 0.18))
	_csg_box(v, "MarqueeNeon", Vector3(0, 3.2, 0.95), Vector3(5.0, 0.18, 0.08), Color(0.95, 0.35, 0.85))
	_csg_box(v, "NeonCyan", Vector3(0, 2.85, 0.95), Vector3(4.6, 0.1, 0.06), Color(0.35, 0.9, 1.0))
	_instance_at(v, P_SCREEN_W, Vector3(0, 2.2, 0.4), 0.0, Vector3(1.4, 1.0, 1.0))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 2.4, -0.6), Vector3(6.5, 4.8, 4.5))
	_omni(root.get_node("SharedLighting"), "MarqueeLight", Vector3(0, 3.4, 1.2), Color(1.0, 0.45, 0.9), 1.6, 8.0)
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Cinema", "cinema", &"sit_cinema",
		"Кинотеатр Leisure", "Сесть и ждать сеанс", "VenueEntrancePOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z + 0.15)
	)
	_signage(t, "CINEMA", Color(0.08, 0.05, 0.12), Color(0.95, 0.35, 0.85))
	return root


func _b_retail_flower_gift() -> Node3D:
	var root: Node3D = _new_building("RetailPairFlowerGift", "retail_flower_gift", "main_street", "MultiTenant", Vector2(12, 7.5))
	var v: Node = root.get_node("VisualRoot")
	## Combined proxy shell — two portals ~3.6m apart on +Z façade (front≈0.7).
	_proxy_shell(v, Vector3(10.5, 3.2, 4.2), Color(0.72, 0.78, 0.68), Color(0.45, 0.5, 0.42), 1.05, 2.15, -1.8)
	_csg_box(v, "PortalInsetB", Vector3(1.8, 1.075, 0.51), Vector3(1.05, 2.15, 0.38), Color(0.08, 0.07, 0.09))
	_csg_box(v, "PortalFrameB", Vector3(1.8, 1.075, 0.68), Vector3(1.21, 2.31, 0.08), Color(0.55, 0.4, 0.45))
	_csg_box(v, "SplitBand", Vector3(0, 2.6, 0.72), Vector3(10.2, 0.14, 0.1), Color(0.55, 0.35, 0.45))
	## Flower side (local -X → world +X when yaw 180).
	_csg_box(v, "FlowerAwning", Vector3(-1.8, 2.35, 1.05), Vector3(3.2, 0.08, 0.8), Color(0.55, 0.78, 0.45))
	_csg_box(v, "GiftAwning", Vector3(1.8, 2.35, 1.05), Vector3(3.2, 0.08, 0.8), Color(0.85, 0.45, 0.55))
	_csg_box(v, "WinFlower", Vector3(-3.2, 1.4, 0.72), Vector3(1.2, 1.0, 0.06), Color(0.75, 0.95, 0.7))
	_csg_box(v, "WinGift", Vector3(3.2, 1.4, 0.72), Vector3(1.2, 1.0, 0.06), Color(0.95, 0.75, 0.8))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.6, -1.4), Vector3(10.5, 3.2, 4.2))

	var flower: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "FlowerShop", "flower_shop", &"open_flower_shop",
		"Цветочный", "Открыть витрину", "StorefrontPOI", 1, Vector3(-1.8, 0.0, ENTRANCE_Z)
	)
	_signage(flower, "FLOWERS", Color(0.15, 0.28, 0.15), Color(0.7, 0.95, 0.55))
	_instance_at(flower.get_node("IdentityProps"), P_SAKURA, Vector3(-0.4, 0.95, 0.2), 20.0, Vector3(1.1, 1.1, 1.1))
	_instance_at(flower.get_node("IdentityProps"), P_PLANTER, Vector3(0.55, 0, 0.35), 0.0, Vector3(0.85, 0.85, 0.85))
	_omni(flower.get_node("LocalLights"), "PlantGlow", Vector3(0, 1.8, 0.4), Color(0.65, 1.0, 0.55), 0.8, 3.5)

	var gift: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "GiftShop", "gift_shop", &"open_gift_shop",
		"Магазин подарков", "Открыть", "StorefrontPOI", 1, Vector3(1.8, 0.0, ENTRANCE_Z)
	)
	_signage(gift, "GIFTS", Color(0.28, 0.12, 0.18), Color(0.95, 0.55, 0.65))
	_instance_at(gift.get_node("IdentityProps"), P_CUPCAKE, Vector3(0.2, 1.05, 0.25), 0.0, Vector3(1.4, 1.4, 1.4))
	_instance_at(gift.get_node("IdentityProps"), P_SHELF, Vector3(-0.2, 0.15, -0.1), 180.0, Vector3(0.55, 0.55, 0.55))
	_omni(gift.get_node("LocalLights"), "WarmGift", Vector3(0, 1.8, 0.4), Color(1.0, 0.7, 0.55), 0.9, 3.5)
	return root


func _b_fashion_jewelry_clothing() -> Node3D:
	var root: Node3D = _new_building("FashionPairJewelryClothing", "fashion_jewelry_clothing", "main_street", "MultiTenant", Vector2(12, 7.5))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(10.5, 3.4, 4.2), Color(0.62, 0.66, 0.78), Color(0.35, 0.38, 0.48), 1.05, 2.15, 1.4)
	_csg_box(v, "PortalInsetB", Vector3(-1.4, 1.075, 0.51), Vector3(1.05, 2.15, 0.38), Color(0.08, 0.07, 0.09))
	_csg_box(v, "PortalFrameB", Vector3(-1.4, 1.075, 0.68), Vector3(1.21, 2.31, 0.08), Color(0.45, 0.5, 0.7))
	_csg_box(v, "CoolBand", Vector3(0, 2.75, 0.72), Vector3(10.2, 0.16, 0.1), Color(0.45, 0.55, 0.85))
	_csg_box(v, "JewelryAwning", Vector3(1.4, 2.4, 1.05), Vector3(3.0, 0.07, 0.7), Color(0.85, 0.75, 0.35))
	## Clothing: different awning shape (thicker).
	_csg_box(v, "ClothingAwning", Vector3(-1.4, 2.5, 1.1), Vector3(3.4, 0.14, 1.0), Color(0.45, 0.55, 0.85))
	_csg_box(v, "WinJew", Vector3(3.0, 1.45, 0.72), Vector3(1.0, 1.15, 0.06), Color(0.75, 0.85, 0.95))
	_csg_box(v, "WinCloth", Vector3(-3.0, 1.45, 0.72), Vector3(1.4, 1.0, 0.06), Color(0.55, 0.65, 0.9))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.7, -1.4), Vector3(10.5, 3.4, 4.2))

	var jew: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "JewelryShop", "jewelry_shop", &"open_jewelry_shop",
		"Ювелирный", "Открыть витрину", "StorefrontPOI", 1, Vector3(1.4, 0.0, ENTRANCE_Z)
	)
	_signage(jew, "JEWELS", Color(0.15, 0.15, 0.22), Color(0.9, 0.8, 0.4))
	_instance_at(jew.get_node("IdentityProps"), P_BOTTLE, Vector3(0.25, 1.05, 0.2), 0.0, Vector3(1.3, 1.3, 1.3))
	_instance_at(jew.get_node("IdentityProps"), P_SHELF, Vector3(-0.15, 0.15, -0.1), 180.0, Vector3(0.5, 0.5, 0.5))
	_omni(jew.get_node("LocalLights"), "CoolSparkle", Vector3(0, 1.9, 0.35), Color(0.75, 0.85, 1.0), 1.0, 3.5)

	var cloth: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "ClothingShop", "clothing_shop", &"open_clothing_shop",
		"Одежда", "Открыть магазин", "StorefrontPOI", 1, Vector3(-1.4, 0.0, ENTRANCE_Z)
	)
	_signage(cloth, "FASHION", Color(0.12, 0.15, 0.28), Color(0.55, 0.65, 0.95))
	_instance_at(cloth.get_node("IdentityProps"), P_BOOKSHELF, Vector3(0.1, 0.1, -0.15), 180.0, Vector3(0.55, 0.7, 0.55))
	_instance_at(cloth.get_node("IdentityProps"), P_HOUSEPLANT, Vector3(0.55, 0, 0.3), 0.0, Vector3(0.8, 0.8, 0.8))
	_omni(cloth.get_node("LocalLights"), "Boutique", Vector3(0, 1.9, 0.35), Color(0.85, 0.8, 1.0), 0.85, 3.5)
	return root


# ─── distinct proxies ─────────────────────────────────────────────────────────

func _b_proxy_homeware() -> Node3D:
	## warm beige, flat canopy, square windows, bowl/shelf
	var root: Node3D = _new_building("HomewareShop", "homeware_shop", "main_street", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(4.6, 3.0, 3.6), Color(0.82, 0.74, 0.58), Color(0.55, 0.48, 0.38), 1.0, 2.1)
	_csg_box(v, "FlatCanopy", Vector3(0, 2.55, 1.05), Vector3(4.4, 0.06, 0.95), Color(0.75, 0.68, 0.52))
	_csg_box(v, "SqWinL", Vector3(-1.35, 1.45, 0.72), Vector3(0.85, 0.85, 0.06), Color(0.9, 0.88, 0.8))
	_csg_box(v, "SqWinR", Vector3(1.35, 1.45, 0.72), Vector3(0.85, 0.85, 0.06), Color(0.9, 0.88, 0.8))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.5, -1.1), Vector3(4.6, 3.0, 3.6))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Homeware", "homeware_shop", &"open_homeware_shop",
		"Дом и посуда", "Открыть магазин", "StorefrontPOI", 1, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "HOMEWARE", Color(0.35, 0.28, 0.18), Color(0.9, 0.75, 0.45))
	_instance_at(t.get_node("IdentityProps"), P_SHELF, Vector3(-0.35, 0.15, 0.1), 180.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(t.get_node("IdentityProps"), P_APPLE, Vector3(0.35, 1.0, 0.45), 0.0, Vector3(1.5, 1.5, 1.5))
	_csg_cyl(t.get_node("IdentityProps"), "Bowl", Vector3(0.55, 0.95, 0.55), 0.18, 0.1, Color(0.85, 0.8, 0.7))
	_omni(t.get_node("LocalLights"), "WarmBeige", Vector3(0, 2.0, 0.8), Color(1.0, 0.88, 0.65), 1.0, 4.0)
	return root


func _b_proxy_internet() -> Node3D:
	## cool blue/grey, recessed dark portal, screen, cyan omni — 3 interacts
	var root: Node3D = _new_building("InternetCafe", "internet_cafe", "main_street", "Storefront", Vector2(7, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(5.2, 3.1, 3.8), Color(0.42, 0.5, 0.6), Color(0.28, 0.32, 0.4), 1.2, 2.2)
	_csg_box(v, "RecessLip", Vector3(0, 1.1, 0.42), Vector3(1.6, 2.3, 0.55), Color(0.15, 0.18, 0.22))
	_csg_box(v, "CyanStrip", Vector3(0, 2.7, 0.78), Vector3(4.8, 0.1, 0.08), Color(0.25, 0.9, 1.0))
	_csg_box(v, "TallWin", Vector3(-1.7, 1.5, 0.72), Vector3(0.7, 1.6, 0.05), Color(0.55, 0.75, 0.9))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.55, -1.2), Vector3(5.2, 3.1, 3.8))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "NetCafe", "internet_cafe", &"city_cafe_job",
		"ПК №1", "Поработать онлайн", "StorefrontPOI", 1, Vector3(0.0, 0.0, ENTRANCE_Z),
		{"art_backed": true}
	)
	_signage(t, "NET CAFE", Color(0.1, 0.15, 0.22), Color(0.3, 0.9, 1.0))
	_instance_at(t.get_node("IdentityProps"), P_SCIFI_DESK, Vector3(-0.4, 0, 0.15), 180.0, Vector3(0.75, 0.75, 0.75))
	_instance_at(t.get_node("IdentityProps"), P_SCREEN_P, Vector3(-0.4, 0.95, 0.05), 0.0, Vector3(1, 1, 1))
	_omni(t.get_node("LocalLights"), "CyanOmni", Vector3(0, 2.1, 0.9), Color(0.35, 0.9, 1.0), 1.3, 5.0)
	_add_sibling_interact(t, "InteractScroll", &"city_cafe_scroll", "ПК №2", "Скроллить (+популярность)", Vector3(1.2, 0.0, ENTRANCE_Z), {"art_backed": true})
	_add_sibling_interact(t, "InteractCoffee", &"city_coffee", "Кофейня", "Купить кофе (+внимание)", Vector3(0.0, 0.0, ENTRANCE_Z + 1.0), {"art_backed": true})
	return root


func _b_proxy_bookstore() -> Node3D:
	## taller thin, green awning, arched window CSG, books
	var root: Node3D = _new_building("Bookstore", "bookstore", "park_leisure", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(3.8, 4.0, 3.4), Color(0.55, 0.48, 0.4), Color(0.35, 0.42, 0.32), 0.95, 2.15)
	_awning(v, Color(0.3, 0.55, 0.35), 2.65, 3.4, 1.05)
	_csg_box(v, "ArchWin", Vector3(-1.15, 1.7, 0.72), Vector3(0.9, 1.4, 0.06), Color(0.7, 0.85, 0.7))
	_csg_cyl(v, "ArchTop", Vector3(-1.15, 2.45, 0.72), 0.45, 0.08, Color(0.7, 0.85, 0.7))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 2.0, -1.0), Vector3(3.8, 4.0, 3.4))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Books", "bookstore", &"open_bookstore",
		"Книжный Leisure", "Открыть витрину", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "BOOKS", Color(0.18, 0.25, 0.15), Color(0.45, 0.75, 0.4))
	_instance_at(t.get_node("IdentityProps"), P_BOOKSHELF, Vector3(0.15, 0.1, 0.05), 180.0, Vector3(0.6, 0.7, 0.55))
	_omni(t.get_node("LocalLights"), "Reading", Vector3(0, 2.2, 0.8), Color(1.0, 0.9, 0.7), 0.9, 4.0)
	return root


func _b_proxy_gym() -> Node3D:
	## wide low, orange band, open bay, machine
	var root: Node3D = _new_building("Gym", "gym", "park_leisure", "Storefront", Vector2(9, 8))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(7.2, 2.6, 4.0), Color(0.55, 0.55, 0.58), Color(0.4, 0.4, 0.42), 2.4, 2.2)
	_csg_box(v, "OrangeBand", Vector3(0, 2.15, 0.78), Vector3(7.0, 0.28, 0.12), Color(0.95, 0.45, 0.15))
	_csg_box(v, "OpenBay", Vector3(0, 1.1, 0.45), Vector3(2.6, 2.2, 0.5), Color(0.12, 0.12, 0.14))
	_csg_box(v, "BayLintel", Vector3(0, 2.25, 0.72), Vector3(2.9, 0.15, 0.2), Color(0.95, 0.45, 0.15))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.3, -1.3), Vector3(7.2, 2.6, 4.0))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Gym", "gym", &"city_workout",
		"Фитнес Leisure", "Тренировка (UI)", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "GYM", Color(0.2, 0.15, 0.1), Color(0.95, 0.45, 0.15))
	_instance_at(t.get_node("IdentityProps"), P_MACHINE, Vector3(1.2, 0, 0.2), -30.0, Vector3(0.9, 0.9, 0.9))
	_csg_box(t.get_node("IdentityProps"), "Mat", Vector3(-1.0, 0.03, 0.4), Vector3(1.2, 0.05, 0.7), Color(0.2, 0.2, 0.22))
	_omni(t.get_node("LocalLights"), "GymOrange", Vector3(0, 2.0, 0.9), Color(1.0, 0.55, 0.25), 1.1, 5.0)
	_add_sibling_interact(t, "InteractPass", &"city_gym_pass", "Абонемент Leisure", "Купить (+макс. внимание)", Vector3(-1.2, 0.0, ENTRANCE_Z + 0.8), {"art_backed": true})
	return root


func _b_proxy_photo() -> Node3D:
	## white/black, flat modern, softbox, backdrop
	var root: Node3D = _new_building("PhotoStudio", "photo_studio", "agency_row", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(4.4, 3.2, 3.5), Color(0.92, 0.92, 0.94), Color(0.12, 0.12, 0.14), 1.1, 2.2)
	_csg_box(v, "BlackBand", Vector3(0, 2.7, 0.72), Vector3(4.2, 0.2, 0.1), Color(0.08, 0.08, 0.1))
	_csg_box(v, "FlatModern", Vector3(0, 3.25, -1.05), Vector3(4.6, 0.12, 3.7), Color(0.15, 0.15, 0.18))
	_csg_box(v, "GlassWin", Vector3(-1.4, 1.5, 0.72), Vector3(1.3, 1.4, 0.05), Color(0.85, 0.9, 0.95))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.6, -1.05), Vector3(4.4, 3.2, 3.5))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Photo", "photo_studio", &"open_photo_studio",
		"Фотостудия Agency", "Сессия / публикация", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z),
		{"art_backed": true, "venue_id": "photo_studio"}
	)
	_signage(t, "PHOTO", Color(0.08, 0.08, 0.1), Color(0.95, 0.95, 0.98))
	_csg_box(t.get_node("IdentityProps"), "Backdrop", Vector3(0.6, 1.2, -0.2), Vector3(1.4, 2.2, 0.05), Color(0.95, 0.55, 0.65))
	_csg_box(t.get_node("IdentityProps"), "Softbox", Vector3(-0.7, 1.8, 0.3), Vector3(0.55, 0.55, 0.12), Color(1, 1, 1))
	_omni(t.get_node("LocalLights"), "SoftKey", Vector3(-0.5, 2.0, 0.7), Color(1.0, 0.98, 0.95), 1.4, 4.5)
	return root


func _b_proxy_barber() -> Node3D:
	## red/white pole, narrow, warm interior glow
	var root: Node3D = _new_building("BarberShop", "barber_shop", "agency_row", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(3.6, 3.3, 3.4), Color(0.78, 0.72, 0.65), Color(0.45, 0.35, 0.3), 0.95, 2.15)
	_csg_cyl(v, "PoleWhite", Vector3(1.55, 1.2, 0.85), 0.08, 1.6, Color(0.95, 0.95, 0.95))
	_csg_cyl(v, "PoleRed", Vector3(1.55, 1.55, 0.85), 0.085, 0.35, Color(0.85, 0.15, 0.15))
	_csg_cyl(v, "PoleBlue", Vector3(1.55, 0.95, 0.85), 0.085, 0.35, Color(0.15, 0.25, 0.75))
	_csg_box(v, "NarrowWin", Vector3(-1.1, 1.5, 0.72), Vector3(0.7, 1.5, 0.05), Color(0.95, 0.85, 0.7))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.65, -1.0), Vector3(3.6, 3.3, 3.4))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Barber", "barber_shop", &"open_barber",
		"Барбер Agency", "Стрижка / стиль", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "BARBER", Color(0.25, 0.1, 0.1), Color(0.9, 0.3, 0.3))
	_instance_at(t.get_node("IdentityProps"), P_CHAIR, Vector3(0.2, 0, 0.15), 160.0, Vector3(0.7, 0.7, 0.7))
	_instance_at(t.get_node("IdentityProps"), P_MIRROR, Vector3(-0.3, 1.2, -0.1), 0.0, Vector3(0.6, 0.6, 0.6))
	_omni(t.get_node("LocalLights"), "WarmShop", Vector3(0, 2.0, 0.7), Color(1.0, 0.75, 0.5), 1.15, 4.0)
	return root


func _b_proxy_agency() -> Node3D:
	## taller medium grey, glassier windows, screen-wide
	var root: Node3D = _new_building("AgencyOffice", "agency_office", "agency_row", "Storefront", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(7.0, 4.2, 4.5), Color(0.55, 0.58, 0.62), Color(0.4, 0.42, 0.46), 1.3, 2.3)
	_csg_box(v, "GlassA", Vector3(-2.2, 2.2, 0.72), Vector3(1.8, 2.4, 0.06), Color(0.7, 0.82, 0.92))
	_csg_box(v, "GlassB", Vector3(2.2, 2.2, 0.72), Vector3(1.8, 2.4, 0.06), Color(0.7, 0.82, 0.92))
	_csg_box(v, "GlassMid", Vector3(0, 3.2, 0.72), Vector3(2.4, 1.2, 0.06), Color(0.65, 0.78, 0.9))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 2.1, -1.55), Vector3(7.0, 4.2, 4.5))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Agency", "agency_office", &"open_agency_board",
		"Офис агентства", "Доска расписания", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "AGENCY", Color(0.2, 0.22, 0.28), Color(0.55, 0.7, 0.9))
	_instance_at(t.get_node("IdentityProps"), P_SCIFI_DESK, Vector3(-0.5, 0, 0.1), 180.0, Vector3(0.8, 0.8, 0.8))
	_instance_at(t.get_node("IdentityProps"), P_SCREEN_W, Vector3(0.6, 1.4, 0.0), 0.0, Vector3(1.1, 1.0, 1.0))
	_instance_at(t.get_node("IdentityProps"), P_SCIFI_CHAIR, Vector3(-0.5, 0, 0.7), 0.0, Vector3(0.8, 0.8, 0.8))
	_omni(t.get_node("LocalLights"), "Office", Vector3(0, 2.5, 0.9), Color(0.85, 0.9, 1.0), 1.1, 6.0)
	return root


func _b_proxy_arcade() -> Node3D:
	## neon magenta/cyan, screen cabinets, canopy
	var root: Node3D = _new_building("Arcade", "arcade", "park_leisure", "Storefront", Vector2(8, 8))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(5.8, 3.0, 4.0), Color(0.25, 0.18, 0.35), Color(0.15, 0.1, 0.22), 1.4, 2.2)
	_csg_box(v, "NeonCanopy", Vector3(0, 2.7, 1.1), Vector3(5.6, 0.12, 1.1), Color(0.9, 0.2, 0.75))
	_csg_box(v, "CyanEdge", Vector3(0, 2.55, 1.35), Vector3(5.4, 0.06, 0.08), Color(0.2, 0.95, 1.0))
	_csg_box(v, "MagWin", Vector3(-1.8, 1.5, 0.72), Vector3(1.2, 1.2, 0.05), Color(0.85, 0.35, 0.9))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.5, -1.3), Vector3(5.8, 3.0, 4.0))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Arcade", "arcade", &"open_arcade",
		"Аркада Перегруз", "Сыграть / свидание", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "ARCADE", Color(0.1, 0.05, 0.15), Color(0.95, 0.25, 0.8))
	_csg_box(t.get_node("IdentityProps"), "CabA", Vector3(-0.7, 0.9, 0.2), Vector3(0.7, 1.7, 0.65), Color(0.15, 0.12, 0.2))
	_instance_at(t.get_node("IdentityProps"), P_SCREEN_S, Vector3(-0.7, 1.35, 0.5), 0.0, Vector3(0.9, 0.9, 0.9))
	_csg_box(t.get_node("IdentityProps"), "CabB", Vector3(0.7, 0.9, 0.2), Vector3(0.7, 1.7, 0.65), Color(0.12, 0.15, 0.22))
	_instance_at(t.get_node("IdentityProps"), P_SCREEN_P, Vector3(0.7, 1.35, 0.5), 0.0, Vector3(0.9, 0.9, 0.9))
	_omni(t.get_node("LocalLights"), "NeonMag", Vector3(0, 2.2, 1.0), Color(1.0, 0.3, 0.85), 1.4, 5.0)
	_add_sibling_interact(t, "InteractDate", &"sit_arcade", "Аркада (свидание)", "Сесть к автомату", Vector3(1.0, 0.0, ENTRANCE_Z), {"art_backed": true})
	return root


func _b_proxy_bar() -> Node3D:
	## dark wood, deep portal, bottle props, warm low light
	var root: Node3D = _new_building("Bar", "bar", "park_leisure", "Storefront", Vector2(7, 7))
	var v: Node = root.get_node("VisualRoot")
	_proxy_shell(v, Vector3(5.0, 3.2, 3.8), Color(0.28, 0.18, 0.12), Color(0.15, 0.1, 0.08), 1.15, 2.2)
	_csg_box(v, "DeepPortal", Vector3(0, 1.1, 0.35), Vector3(1.4, 2.25, 0.7), Color(0.06, 0.04, 0.03))
	_csg_box(v, "WoodTrim", Vector3(0, 2.55, 0.78), Vector3(4.8, 0.18, 0.1), Color(0.4, 0.25, 0.15))
	_csg_box(v, "WarmWin", Vector3(-1.6, 1.5, 0.72), Vector3(1.0, 1.1, 0.05), Color(0.95, 0.7, 0.4))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.6, -1.2), Vector3(5.0, 3.2, 3.8))
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Bar", "bar", &"city_bar_drink",
		"Ночной бар", "Выпить (−$ +скандал/⭐)", "StorefrontPOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "BAR", Color(0.12, 0.06, 0.04), Color(0.85, 0.45, 0.25))
	_instance_at(t.get_node("IdentityProps"), P_COUNTER, Vector3(0.3, 0, 0.1), 90.0, Vector3(0.45, 0.45, 0.45))
	_instance_at(t.get_node("IdentityProps"), P_BOTTLE, Vector3(-0.4, 1.05, 0.45), 0.0, Vector3(1.4, 1.4, 1.4))
	_instance_at(t.get_node("IdentityProps"), P_STOOL, Vector3(0.7, 0, 0.55), 0.0, Vector3(0.5, 0.5, 0.5))
	_omni(t.get_node("LocalLights"), "LowWarm", Vector3(0, 1.6, 0.7), Color(1.0, 0.55, 0.3), 0.85, 4.0)
	return root


func _b_park_restaurant() -> Node3D:
	## Differ from Cafe: different roof/awning/color; Medium OK with strong prop diff.
	var root: Node3D = _new_building("ParkRestaurant", "park_restaurant", "park_leisure", "VenueEntrance", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	_instance_at(v, P_BUILDING_M, Vector3(0, 0, -0.55), 0.0, Vector3(0.45, 0.45, 0.45))
	## Deep red awning + pitched roof accent (vs cafe pink).
	_awning(v, Color(0.75, 0.28, 0.22), 2.55, 3.2, 1.0)
	_csg_box(v, "PitchedRoof", Vector3(0, 3.5, -0.3), Vector3(4.8, 0.35, 3.2), Color(0.35, 0.2, 0.15))
	_instance_at(v, P_TABLE, Vector3(-1.4, 0, 0.55), -20.0, Vector3(0.5, 0.5, 0.5))
	_instance_at(v, P_STOOL, Vector3(-1.7, 0, 0.35), 0.0, Vector3(0.55, 0.55, 0.55))
	_instance_at(v, P_PLANT, Vector3(1.5, 0, 0.9), 0.0, Vector3(1.1, 1.1, 1.1))
	_add_static_box(root.get_node("CollisionRoot"), "Body", Vector3(0, 1.8, -0.2), Vector3(4.6, 3.6, 3.2))
	_omni(root.get_node("SharedLighting"), "BistroWarm", Vector3(0, 2.4, 1.1), Color(1.0, 0.65, 0.4), 1.35, 7.0)
	var t: Node3D = _new_tenant(
		root.get_node("TenantSlots"), "Restaurant", "park_restaurant", &"sit_restaurant",
		"Ресторан у парка", "Сесть и ждать свидание", "VenueEntrancePOI", 2, Vector3(0.0, 0.0, ENTRANCE_Z)
	)
	_signage(t, "PARK BISTRO", Color(0.18, 0.08, 0.08), Color(1.0, 0.5, 0.3))
	return root


# ─── world activities ─────────────────────────────────────────────────────────

func _activity_root(name: String) -> Node3D:
	var root := Node3D.new()
	root.name = name
	return root


func _finish_activity_as_tenant(
	root: Node3D,
	poi_id: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	stage: int,
	entrance: Vector3,
	payload: Dictionary = {}
) -> Node3D:
	## Re-root: CityPOITenant is the scene root for WorldActivity.
	var tenant := Node3D.new()
	tenant.name = name_from_root(root)
	## Move visual children under IdentityProps after scaffolding.
	tenant.set_script(load(SCRIPT_TENANT))
	tenant.set("poi_id", poi_id)
	tenant.set("action_id", action_id)
	tenant.set("display_name", display_name)
	tenant.set("action_label", action_label)
	tenant.set("prompt_text", action_label)
	tenant.set("functional_type", "WorldActivityPOI")
	tenant.set("progression_stage", stage)
	var pl: Dictionary = payload.duplicate()
	if not pl.has("art_backed"):
		pl["art_backed"] = true
	tenant.set("payload", pl)

	var ent := Marker3D.new()
	ent.name = "EntranceAnchor"
	ent.position = entrance
	tenant.add_child(ent)
	_add_interactable(tenant, "InteractionArea", action_id, display_name, action_label, entrance, pl)

	var prompt := Marker3D.new()
	prompt.name = "PromptAnchor"
	prompt.position = entrance + Vector3(0, 0.7, 0)
	tenant.add_child(prompt)

	var sign_a := Marker3D.new()
	sign_a.name = "SignAnchor"
	sign_a.position = Vector3(0, 1.6, 0.5)
	tenant.add_child(sign_a)

	var signage := Node3D.new()
	signage.name = "Signage"
	tenant.add_child(signage)

	var lights := Node3D.new()
	lights.name = "LocalLights"
	tenant.add_child(lights)

	var props := Node3D.new()
	props.name = "IdentityProps"
	tenant.add_child(props)

	## Move visual root into IdentityProps.
	for ch in root.get_children():
		root.remove_child(ch)
		props.add_child(ch)
	root.free()
	tenant.name = name_from_payload(poi_id, display_name)
	return tenant


func name_from_root(root: Node3D) -> String:
	return root.name


func name_from_payload(poi_id: String, _dn: String) -> String:
	match poi_id:
		"main_bench":
			return "MainBench"
		"park_bench":
			return "ParkBench"
		"duck_feeding":
			return "DuckFeeding"
		"karaoke":
			return "KaraokeStand"
		"bus_stop_candy":
			return "BusStopCandy"
		_:
			return poi_id


func _a_main_bench() -> Node3D:
	var hold := _activity_root("MainBench")
	var visuals := Node3D.new()
	visuals.name = "VisualRoot"
	hold.add_child(visuals)
	_instance_at(visuals, P_BENCH, Vector3.ZERO, 0.0, Vector3(1.1, 1.1, 1.1))
	_instance_at(visuals, P_PLANTER, Vector3(-1.2, 0, 0.2), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(visuals, P_BOLLARD, Vector3(1.15, 0, 0.35), 0.0, Vector3.ONE)
	var coll := StaticBody3D.new()
	coll.name = "Collision"
	hold.add_child(coll)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.9, 0.8)
	cs.shape = box
	cs.position = Vector3(0, 0.45, 0)
	coll.add_child(cs)
	var t: Node3D = _finish_activity_as_tenant(
		hold, "main_bench", &"city_rest", "Скамейка", "Отдохнуть (+внимание)", 1, Vector3(0, 0, 0.85)
	)
	return t


func _a_park_bench() -> Node3D:
	var hold := _activity_root("ParkBench")
	var visuals := Node3D.new()
	visuals.name = "VisualRoot"
	hold.add_child(visuals)
	_instance_at(visuals, P_BENCH, Vector3.ZERO, 0.0, Vector3(1.1, 1.1, 1.1))
	_instance_at(visuals, P_SIDEWALK_PLANTER, Vector3(-1.1, 0, -0.2), 0.0, Vector3(0.8, 0.8, 0.8))
	var coll := StaticBody3D.new()
	coll.name = "Collision"
	hold.add_child(coll)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.9, 0.8)
	cs.shape = box
	cs.position = Vector3(0, 0.45, 0)
	coll.add_child(cs)
	return _finish_activity_as_tenant(
		hold, "park_bench", &"city_rest", "Скамейка в парке", "Посидеть", 2, Vector3(0, 0, 0.85),
		{"bonus": 1.5, "art_backed": true}
	)


func _a_duck() -> Node3D:
	var hold := _activity_root("DuckFeeding")
	var visuals := Node3D.new()
	visuals.name = "VisualRoot"
	hold.add_child(visuals)
	_csg_cyl(visuals, "PondRim", Vector3(0, 0.05, 0), 1.1, 0.12, Color(0.35, 0.45, 0.4))
	_csg_cyl(visuals, "Water", Vector3(0, 0.08, 0), 0.95, 0.06, Color(0.35, 0.55, 0.7))
	_instance_at(visuals, P_PLANTER, Vector3(-1.2, 0, 0.9), 0.0, Vector3(0.8, 0.8, 0.8))
	_authored_duck(visuals, "DuckA", Vector3(0.35, 0.18, 0.15), 30.0)
	_authored_duck(visuals, "DuckB", Vector3(-0.25, 0.18, -0.2), -40.0)
	_csg_box(visuals, "FeederBag", Vector3(0.9, 0.35, 0.85), Vector3(0.25, 0.7, 0.25), Color(0.45, 0.35, 0.25))
	_csg_box(visuals, "FeederTray", Vector3(0.9, 0.7, 0.85), Vector3(0.45, 0.08, 0.35), Color(0.55, 0.45, 0.3))
	var coll := StaticBody3D.new()
	coll.name = "Collision"
	hold.add_child(coll)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.2, 2.2)
	cs.shape = box
	cs.position = Vector3(0, 0.4, 0)
	coll.add_child(cs)
	return _finish_activity_as_tenant(
		hold, "duck_feeding", &"city_park_fun", "Кормушка", "Покормить уток (+⭐)", 2, Vector3(0.9, 0, 0.85)
	)


func _authored_duck(parent: Node, name: String, pos: Vector3, yaw: float) -> void:
	var g := Node3D.new()
	g.name = name
	g.position = pos
	g.rotation_degrees.y = yaw
	parent.add_child(g)
	_csg_sphere(g, "Body", Vector3(0, 0.08, 0), 0.12, Color(0.92, 0.78, 0.25))
	_csg_sphere(g, "Head", Vector3(0.1, 0.16, 0.02), 0.07, Color(0.2, 0.35, 0.55))
	_csg_box(g, "Beak", Vector3(0.17, 0.15, 0.02), Vector3(0.08, 0.03, 0.04), Color(0.95, 0.55, 0.2))


func _a_karaoke() -> Node3D:
	var hold := _activity_root("KaraokeStand")
	var visuals := Node3D.new()
	visuals.name = "VisualRoot"
	hold.add_child(visuals)
	_csg_box(visuals, "StageDeck", Vector3(0, 0.08, 0), Vector3(2.2, 0.16, 1.4), Color(0.35, 0.2, 0.35))
	_csg_cyl(visuals, "MicPole", Vector3(0.35, 0.85, 0.25), 0.03, 1.4, Color(0.25, 0.25, 0.28))
	_csg_sphere(visuals, "MicHead", Vector3(0.35, 1.55, 0.25), 0.07, Color(0.15, 0.15, 0.18))
	_csg_box(visuals, "SpeakerL", Vector3(-0.85, 0.55, 0.1), Vector3(0.35, 0.9, 0.3), Color(0.2, 0.2, 0.22))
	_csg_box(visuals, "SpeakerR", Vector3(0.85, 0.55, 0.1), Vector3(0.35, 0.9, 0.3), Color(0.2, 0.2, 0.22))
	_instance_at(visuals, P_SCREEN_S, Vector3(0, 1.35, -0.25), 0.0, Vector3(1.2, 1.2, 1.2))
	_instance_at(visuals, P_LIGHT_STAND, Vector3(-1.15, 0, -0.2), 0.0, Vector3(0.9, 0.9, 0.9))
	var coll := StaticBody3D.new()
	coll.name = "Collision"
	hold.add_child(coll)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 1.8, 1.6)
	cs.shape = box
	cs.position = Vector3(0, 0.9, 0)
	coll.add_child(cs)
	return _finish_activity_as_tenant(
		hold, "karaoke", &"city_karaoke", "Караоке", "Спеть (+⭐ +скандал)", 2, Vector3(0.35, 0, 0.7)
	)


func _a_bus() -> Node3D:
	var hold := _activity_root("BusStopCandy")
	var visuals := Node3D.new()
	visuals.name = "VisualRoot"
	hold.add_child(visuals)
	_csg_box(visuals, "ShelterRoof", Vector3(0, 2.4, 0), Vector3(2.8, 0.08, 1.4), Color(0.35, 0.4, 0.48))
	_csg_box(visuals, "ShelterPostL", Vector3(-1.2, 1.15, -0.5), Vector3(0.1, 2.3, 0.1), Color(0.3, 0.35, 0.4))
	_csg_box(visuals, "ShelterPostR", Vector3(1.2, 1.15, -0.5), Vector3(0.1, 2.3, 0.1), Color(0.3, 0.35, 0.4))
	_csg_box(visuals, "BackPanel", Vector3(0, 1.2, -0.65), Vector3(2.6, 2.0, 0.06), Color(0.45, 0.5, 0.55))
	_instance_at(visuals, P_BENCH, Vector3(0, 0, 0.15), 0.0, Vector3(0.9, 0.9, 0.9))
	_instance_at(visuals, P_TRASH, Vector3(-1.35, 0, 0.4), 0.0, Vector3(0.8, 0.8, 0.8))
	_csg_box(visuals, "CandyMachine", Vector3(1.35, 0.85, 0.35), Vector3(0.55, 1.6, 0.45), Color(0.85, 0.25, 0.35))
	_instance_at(visuals, P_CHOCO, Vector3(1.35, 1.5, 0.55), 0.0, Vector3(1.5, 1.5, 1.5))
	var coll := StaticBody3D.new()
	coll.name = "Collision"
	hold.add_child(coll)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 2.4, 1.4)
	cs.shape = box
	cs.position = Vector3(0, 1.2, 0)
	coll.add_child(cs)
	var t: Node3D = _finish_activity_as_tenant(
		hold, "bus_stop_candy", &"city_bus_info", "Расписание", "Посмотреть маршруты", 1, Vector3(0, 0, 0.7)
	)
	_add_sibling_interact(
		t, "InteractCandy", &"city_buy_gift", "Автомат", "Купить сувенир-конфеты",
		Vector3(1.2, 0, 0.7), {"gift_id": "candy", "discount": 1.0, "art_backed": true}
	)
	return t


# ─── city.tscn rewrite ────────────────────────────────────────────────────────

func _tf_yaw180(x: float, z: float) -> String:
	## Facing -Z (street).
	return "Transform3D(-1, 0, -8.742278e-08, 0, 1, 0, 8.742278e-08, 0, -1, %s, 0, %s)" % [_f(x), _f(z)]


func _tf_ident(x: float, z: float) -> String:
	return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % [_f(x), _f(z)]


func _tf_yaw_neg90(x: float, z: float) -> String:
	## Home: was (-Z look via R from +X) — keep HomeFacade yaw.
	return "Transform3D(-4.371139e-08, 0, -1, 0, 1, 0, 1, 0, -4.371139e-08, %s, 0, %s)" % [_f(x), _f(z)]


func _tf_yaw_pos90(x: float, z: float) -> String:
	## Cafe / Cinema / Arcade / Bus: local +Z → world +X or -X depending.
	return "Transform3D(-4.371139e-08, 0, 1, 0, 1, 0, -1, 0, -4.371139e-08, %s, 0, %s)" % [_f(x), _f(z)]


func _f(v: float) -> String:
	return "%.4f" % v if absf(v - roundf(v)) > 0.001 else str(int(roundf(v))) if absf(v - roundf(v)) < 0.0001 and absf(v) >= 1.0 else ("%.2f" % v)


func _marker_line(name: String, x: float, y: float, z: float) -> String:
	return (
		'[node name="%s" type="Marker3D" parent="Markers"]\n' % name
		+ "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n" % [_f(x), _f(y), _f(z)]
	)


func _inst_line(name: String, parent: String, ext_id: String, transform: String) -> String:
	return (
		'[node name="%s" type="Node3D" parent="%s" instance=ExtResource("%s")]\n' % [name, parent, ext_id]
		+ "transform = %s\n" % transform
	)


func _rewrite_city_tscn() -> bool:
	var abs_path: String = ProjectSettings.globalize_path(CITY_PATH)
	var f := FileAccess.open(CITY_PATH, FileAccess.READ)
	if f == null:
		push_error("cannot read city.tscn")
		return false
	var text: String = f.get_as_text()
	f.close()

	## Strip old POI/building/gate ExtResources (ids 1..24) and rewrite header block.
	var header := """[gd_scene format=3]

[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/PlayerHome.tscn" id="1_phome"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/CafeTwoHearts.tscn" id="2_cafe"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/Bookstore.tscn" id="3_book"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/RetailPairFlowerGift.tscn" id="4_retail"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/FashionPairJewelryClothing.tscn" id="5_fashion"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/InternetCafe.tscn" id="6_net"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/HomewareShop.tscn" id="7_homeware"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/ParkRestaurant.tscn" id="8_rest"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/Gym.tscn" id="9_gym"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/Cinema.tscn" id="10_cine"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/Arcade.tscn" id="11_arcade"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/Bar.tscn" id="12_bar"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/PhotoStudio.tscn" id="13_photo"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/AgencyOffice.tscn" id="14_agency"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/buildings/BarberShop.tscn" id="15_barber"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/activities/MainBench.tscn" id="16_mbench"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/activities/ParkBench.tscn" id="17_pbench"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/activities/DuckFeeding.tscn" id="18_duck"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/activities/KaraokeStand.tscn" id="19_karaoke"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/activities/BusStopCandy.tscn" id="20_bus"]
[ext_resource type="PackedScene" path="res://scenes/art/city/poi/core/DistrictGate.tscn" id="21_gate"]
[ext_resource type="PackedScene" path="res://assets/environment/city/downtown_megakit/meshes/Prop_Planter_Single.gltf" id="25_u426w"]
[ext_resource type="PackedScene" path="res://assets/environment/restaurant/sushi_restaurant/meshes/Decoration/Decoration_SakuraTree.gltf" id="26_oblms"]
[ext_resource type="PackedScene" path="res://assets/environment/city/downtown_megakit/meshes/Building_Large_2.gltf" id="27_nkn8c"]
[ext_resource type="PackedScene" path="res://assets/environment/city/downtown_megakit/meshes/Building_Medium_2_001.gltf" id="28_lfdsf"]
[ext_resource type="PackedScene" path="res://assets/environment/city/downtown_megakit/meshes/Building_Small_1.gltf" id="29_kmp1w"]
[ext_resource type="PackedScene" path="res://scenes/art/city/prefabs/StreetLampRomance.tscn" id="30_gbm14"]
"""

	## Keep non-POI ext_resources that were after id 25 (materials etc.). Find first [sub_resource] or [node.
	var sub_idx: int = text.find("[sub_resource")
	var node_idx: int = text.find("\n[node name=")
	var keep_from: int = -1
	if sub_idx >= 0:
		keep_from = sub_idx
	elif node_idx >= 0:
		keep_from = node_idx + 1
	if keep_from < 0:
		push_error("city.tscn structure unexpected")
		return false

	## Collect remaining ext_resources that are NOT old prefab/gate (lamps already in header as 30).
	## We keep sub_resources + everything from Architecture onward, but replace Buildings/POIs/Decor/Markers.

	var rest: String = text.substr(keep_from)
	## Remove any leftover Prefab ExtResource lines if they appear in rest (shouldn't).
	## Replace Buildings → Markers sections.

	var buildings_start: int = rest.find('[node name="Buildings"')
	var districts_start: int = rest.find('[node name="Districts"')
	if buildings_start < 0 or districts_start < 0:
		push_error("cannot find Buildings/Districts in city.tscn")
		return false

	var before: String = rest.substr(0, buildings_start)
	var after: String = rest.substr(districts_start)

	## Midpoint flower+gift.
	var retail_x: float = 15.45
	var retail_z: float = 6.35
	## Multi-tenant door world positions (yaw 180): local (dx,0,ez) → world (-dx, 0, -ez)
	var flower_ex: float = retail_x - (-1.8) ## = 17.25
	var flower_ez: float = retail_z - ENTRANCE_Z
	var gift_ex: float = retail_x - 1.8
	var gift_ez: float = flower_ez
	var fashion_x: float = 5.4
	var fashion_z: float = 6.35
	var jew_ex: float = fashion_x - 1.4
	var jew_ez: float = fashion_z - ENTRANCE_Z
	var cloth_ex: float = fashion_x - (-1.4)
	var cloth_ez: float = jew_ez

	## Entrance offsets for facing+Z (identity): origin + (0,0,+ez)
	## facing -Z (yaw180): origin + (0,0,-ez)
	## facing ±90: need approx from previous markers.

	var mid := ""
	mid += '[node name="Buildings" type="Node3D" parent="."]\n\n'
	mid += '[node name="POIs" type="Node3D" parent="."]\n\n'
	mid += _inst_line("PlayerHome", "POIs", "1_phome", _tf_yaw_neg90(32.6, 16.5))
	mid += "\n"
	mid += _inst_line("CafeTwoHearts", "POIs", "2_cafe", _tf_yaw_pos90(23.8, 14.2))
	mid += "\n"
	mid += _inst_line("RetailPairFlowerGift", "POIs", "4_retail", _tf_yaw180(retail_x, retail_z))
	mid += "\n"
	mid += _inst_line("FashionPairJewelryClothing", "POIs", "5_fashion", _tf_yaw180(fashion_x, fashion_z))
	mid += "\n"
	mid += _inst_line("HomewareShop", "POIs", "7_homeware", _tf_ident(12.1, -6.35))
	mid += "\n"
	mid += _inst_line("InternetCafe", "POIs", "6_net", _tf_ident(5.4, -6.35))
	mid += "\n"
	mid += _inst_line("Bookstore", "POIs", "3_book", _tf_ident(-14.2, 12))
	mid += "\n"
	mid += _inst_line("Gym", "POIs", "9_gym", _tf_ident(-7.5, 12))
	mid += "\n"
	mid += _inst_line("Cinema", "POIs", "10_cine", _tf_yaw_pos90(-27.2, 17.5))
	mid += "\n"
	mid += _inst_line("Arcade", "POIs", "11_arcade", _tf_yaw_pos90(-27.2, 24.2))
	mid += "\n"
	mid += _inst_line("Bar", "POIs", "12_bar", _tf_yaw180(-16.5, 29.8))
	mid += "\n"
	mid += _inst_line("ParkRestaurant", "POIs", "8_rest", _tf_yaw180(3.2, 21.2))
	mid += "\n"
	mid += _inst_line("PhotoStudio", "POIs", "13_photo", _tf_ident(-12.5, -6.35))
	mid += "\n"
	mid += _inst_line("BarberShop", "POIs", "15_barber", _tf_yaw180(-24.5, 11.8))
	mid += "\n"
	mid += _inst_line("AgencyOffice", "POIs", "14_agency", _tf_ident(-19.2, -6.35))
	mid += "\n"
	## Activities — keep prior transforms.
	mid += _inst_line("MainBench", "POIs", "16_mbench", "Transform3D(0.76604444, 0, -0.6427876, 0, 1, 0, 0.6427876, 0, 0.76604444, -3.6, 0, 3.4)")
	mid += "\n"
	mid += _inst_line("ParkBench", "POIs", "17_pbench", "Transform3D(-0.76604444, 0, 0.64278764, 0, 1, 0, -0.64278764, 0, -0.76604444, -3.8, 0, 22.8)")
	mid += "\n"
	mid += _inst_line("DuckFeeding", "POIs", "18_duck", "Transform3D(-4.371139e-08, 0, -1, 0, 1, 0, 1, 0, -4.371139e-08, 6.2, 0, 16.8)")
	mid += "\n"
	mid += _inst_line("KaraokeStand", "POIs", "19_karaoke", "Transform3D(0.8660254, 0, -0.5, 0, 1, 0, 0.5, 0, 0.8660254, -10.5, 0, 26.5)")
	mid += "\n"
	mid += _inst_line("BusStopCandy", "POIs", "20_bus", "Transform3D(-4.371139e-08, 0, 1, 0, 1, 0, -1, 0, -4.371139e-08, -30.5, 0, 5)")
	mid += "\n"

	mid += '[node name="Decor" type="Node3D" parent="."]\n\n'
	mid += '[node name="ParkGate" type="Node3D" parent="Decor" groups=["district_gate"] instance=ExtResource("21_gate")]\n'
	mid += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 7.2)\n"
	mid += 'district_id = "park_leisure"\n'
	mid += 'display_name = "Парковый барьер"\n'
	mid += 'locked_text = "Парковый барьер"\n'
	mid += "gate_width = 7.0\n"
	mid += "gate_height = 2.6\n"
	mid += "barrier_size = Vector3(7, 2.6, 0.28)\n"
	mid += 'metadata/district_id = "park_leisure"\n\n'

	mid += '[node name="AgencyGate" type="Node3D" parent="Decor" groups=["district_gate"] instance=ExtResource("21_gate")]\n'
	mid += "transform = Transform3D(-4.371139e-08, 0, 1, 0, 1, 0, -1, 0, -4.371139e-08, -7.2, 0, 0)\n"
	mid += 'district_id = "agency_row"\n'
	mid += 'display_name = "Барьер агентства"\n'
	mid += 'locked_text = "Барьер агентства"\n'
	mid += "gate_width = 6.8\n"
	mid += "gate_height = 2.6\n"
	mid += "barrier_size = Vector3(6.8, 2.6, 0.28)\n"
	mid += 'metadata/district_id = "agency_row"\n\n'

	mid += '[node name="AgencyGateLeisure" type="Node3D" parent="Decor" groups=["district_gate"] instance=ExtResource("21_gate")]\n'
	mid += "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -21.8, 0, 13.6)\n"
	mid += 'district_id = "agency_row"\n'
	mid += 'display_name = "Барьер агентства со стороны Leisure"\n'
	mid += 'locked_text = "Барьер агентства со стороны Leisure"\n'
	mid += "gate_width = 5.4\n"
	mid += "gate_height = 2.6\n"
	mid += "barrier_size = Vector3(5.4, 2.6, 0.28)\n"
	mid += 'metadata/district_id = "agency_row"\n\n'

	## Markers — sync entrances; keep spawn/picnic/etc.
	## Home: yaw -90, local +Z → world -X → entrance ≈ (32.6 - ez, 0, 16.5)
	var home_ez: float = ENTRANCE_Z
	var cafe_ez: float = ENTRANCE_Z
	mid += '[node name="Markers" type="Node3D" parent="."]\n\n'
	mid += _marker_line("HomeEntrance", 32.6 - home_ez, 0, 16.5)
	mid += "\n"
	## Cafe yaw +90: local +Z → world +X
	mid += _marker_line("CafeEntrance", 23.8 + cafe_ez, 0, 14.2)
	mid += "\n"
	mid += _marker_line("JewelryEntrance", jew_ex, 0, jew_ez)
	mid += "\n"
	mid += _marker_line("GiftEntrance", gift_ex, 0, gift_ez)
	mid += "\n"
	mid += _marker_line("FlowerEntrance", flower_ex, 0, flower_ez)
	mid += "\n"
	mid += _marker_line("InternetCafeEntrance", 5.4, 0, -6.35 + ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("HomewareEntrance", 12.1, 0, -6.35 + ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("ClothingEntrance", cloth_ex, 0, cloth_ez)
	mid += "\n"
	mid += _marker_line("ParkRestaurantEntrance", 3.2, 0, 21.2 - ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("GymEntrance", -7.5, 0, 12.0 + ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("BookstoreEntrance", -14.2, 0, 12.0 + ENTRANCE_Z)
	mid += "\n"
	## Cinema/Arcade yaw +90
	mid += _marker_line("CinemaEntrance", -27.2 + ENTRANCE_Z + 0.15, 0, 17.5)
	mid += "\n"
	mid += _marker_line("ArcadeEntrance", -27.2 + ENTRANCE_Z, 0, 24.2)
	mid += "\n"
	mid += _marker_line("BarEntrance", -16.5, 0, 29.8 - ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("PhotoStudioEntrance", -12.5, 0, -6.35 + ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("AgencyOfficeEntrance", -19.2, 0, -6.35 + ENTRANCE_Z)
	mid += "\n"
	mid += _marker_line("BarberEntrance", -24.5, 0, 11.8 - ENTRANCE_Z)
	mid += "\n"
	## Unchanged markers
	mid += _marker_line("PlayerSpawn", 29.2, 0, 9)
	mid += "\n"
	mid += _marker_line("ApartmentReturn", 30.8, 0, 16.5)
	mid += "\n"
	mid += _marker_line("ParkPicnicSpot", 5.5, 0, 12)
	mid += "\n"
	mid += _marker_line("BusStop", -30.5, 0, 5)
	mid += "\n"
	mid += _marker_line("PhotoMark", -12.5, 0, -4.4)
	mid += "\n"
	mid += _marker_line("OverviewCamera", 1, 48, 8)
	mid += "\n"
	mid += _marker_line("WestBoundary", -38, 0, 8)
	mid += "\n"
	mid += _marker_line("EastBoundary", 38, 0, 14)
	mid += "\n"

	## Also keep StreetLampRomance instances that lived under Decor — extract from original.
	var lamp_block: String = _extract_lamp_nodes(text)
	if lamp_block != "":
		## Insert lamps before Markers end — actually under Decor before Markers.
		mid = mid.replace(
			'[node name="Markers" type="Node3D" parent="."]\n\n',
			lamp_block + '[node name="Markers" type="Node3D" parent="."]\n\n'
		)

	var out: String = header + "\n" + before + mid + after
	## Ensure StreetLamp ext_resource isn't duplicated if before still has one — strip duplicate id=30.
	out = _dedupe_ext_resource(out, "30_gbm14")

	var wf := FileAccess.open(CITY_PATH, FileAccess.WRITE)
	if wf == null:
		push_error("cannot write city.tscn")
		return false
	wf.store_string(out)
	wf.close()
	print("Wrote %s bytes=%d" % [abs_path, out.length()])
	return true


func _extract_lamp_nodes(text: String) -> String:
	var out := ""
	var search_from: int = 0
	while true:
		var idx: int = text.find('instance=ExtResource("30_gbm14")', search_from)
		if idx < 0:
			break
		var node_start: int = text.rfind("[node name=", idx)
		if node_start < 0:
			break
		var node_end: int = text.find("\n[node name=", idx + 1)
		if node_end < 0:
			node_end = text.find("\n[node name=\"Markers\"", idx)
		if node_end < 0:
			break
		var block: String = text.substr(node_start, node_end - node_start)
		## Ensure parent is Decor
		if block.find('parent="Decor"') >= 0:
			out += block
			if not out.ends_with("\n"):
				out += "\n"
			out += "\n"
		search_from = node_end
	return out


func _dedupe_ext_resource(text: String, id: String) -> String:
	var needle: String = 'id="%s"' % id
	var first: int = text.find(needle)
	if first < 0:
		return text
	var second: int = text.find(needle, first + 1)
	while second >= 0:
		var line_start: int = text.rfind("\n", second)
		var line_end: int = text.find("\n", second)
		if line_start < 0 or line_end < 0:
			break
		text = text.substr(0, line_start) + text.substr(line_end)
		second = text.find(needle, first + 1)
	return text
