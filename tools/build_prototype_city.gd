extends RefCounted
## Builds primitive prototype city PackedScenes and rewires city.tscn / city_hub.tscn.
## Run from GodotIQ editor exec: load this script, call run().


const OUT_ROOT := "res://world/locations/city_hub/prototype/"
const OUT_BUILDINGS := "res://world/locations/city_hub/prototype/buildings/"
const OUT_ACTIVITIES := "res://world/locations/city_hub/prototype/activities/"
const OUT_BG := "res://world/locations/city_hub/prototype/background/"
const CITY_PATH := "res://world/locations/city_hub/art/city.tscn"
const HUB_PATH := "res://world/locations/city_hub/city_hub.tscn"
const SCRIPT_BUILDING := "res://world/locations/city_hub/art/poi/core/CityPOIBuilding.gd"
const SCRIPT_TENANT := "res://world/locations/city_hub/art/poi/core/CityPOITenant.gd"
const SCRIPT_STUB := "res://world/locations/city_hub/art/donor_interactable_stub.gd"
const SCRIPT_DAY_JOB := "res://world/locations/apartment/office_day_job_interactable.gd"
const SCRIPT_SYNC := "res://world/locations/city_hub/prototype/district_gate_sync.gd"
const GATE_SCENE := "res://world/locations/city_hub/art/poi/core/DistrictGate.tscn"
const ENTRANCE_Z := 1.05

var _log: PackedStringArray = PackedStringArray()


func run() -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_BUILDINGS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_ACTIVITIES))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_BG))
	var built: PackedStringArray = PackedStringArray()
	built.append(_save(_b_player_home(), OUT_BUILDINGS))
	built.append(_save(_b_cafe(), OUT_BUILDINGS))
	built.append(_save(_b_retail(), OUT_BUILDINGS))
	built.append(_save(_b_fashion(), OUT_BUILDINGS))
	built.append(_save(_b_homeware(), OUT_BUILDINGS))
	built.append(_save(_b_internet(), OUT_BUILDINGS))
	built.append(_save(_b_bookstore(), OUT_BUILDINGS))
	built.append(_save(_b_gym(), OUT_BUILDINGS))
	built.append(_save(_b_cinema(), OUT_BUILDINGS))
	built.append(_save(_b_arcade(), OUT_BUILDINGS))
	built.append(_save(_b_bar(), OUT_BUILDINGS))
	built.append(_save(_b_park_restaurant(), OUT_BUILDINGS))
	built.append(_save(_b_photo(), OUT_BUILDINGS))
	built.append(_save(_b_barber(), OUT_BUILDINGS))
	built.append(_save(_b_agency(), OUT_BUILDINGS))
	built.append(_save(_a_main_bench(), OUT_ACTIVITIES))
	built.append(_save(_a_park_bench(), OUT_ACTIVITIES))
	built.append(_save(_a_duck(), OUT_ACTIVITIES))
	built.append(_save(_a_karaoke(), OUT_ACTIVITIES))
	built.append(_save(_a_bus(), OUT_ACTIVITIES))
	for i in range(16):
		built.append(_save(_b_background(i), OUT_BG))
	built.append(_save(_build_roads(), OUT_ROOT))
	built.append(_save(_build_boundaries(), OUT_ROOT))
	var city_ok: String = _build_city_scene()
	var hub_ok: String = _patch_city_hub()
	_log.append("BUILT %d scenes" % built.size())
	_log.append(city_ok)
	_log.append(hub_ok)
	return "\n".join(_log)


func _save(root: Node3D, dir: String) -> String:
	var path: String = dir + root.name + ".tscn"
	_set_owner_recursive(root, root)
	var packed := PackedScene.new()
	var err: Error = packed.pack(root)
	if err != OK:
		_log.append("PACK_FAIL %s %s" % [path, error_string(err)])
		root.free()
		return path
	err = ResourceSaver.save(packed, path)
	if err != OK:
		_log.append("SAVE_FAIL %s %s" % [path, error_string(err)])
	else:
		_log.append("SAVE %s" % path)
	root.free()
	return path


func _set_owner_recursive(n: Node, scene_owner: Node) -> void:
	for c in n.get_children():
		c.owner = scene_owner
		if not c.scene_file_path.is_empty():
			continue
		_set_owner_recursive(c, scene_owner)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	m.metallic = 0.04
	return m


func _mesh_box(parent: Node, node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _mesh_cyl(parent: Node, node_name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _mesh_prism(parent: Node, node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := PrismMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _mat(color)
	mi.position = pos
	parent.add_child(mi)
	return mi


func _static_box(collision_root: Node, node_name: String, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	collision_root.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)


func _new_building(bname: String, building_id: String, district: String, mode: String, lot: Vector2) -> Node3D:
	var root := Node3D.new()
	root.name = bname
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
	lot_n.visible = false
	root.add_child(lot_n)
	var lights := Node3D.new()
	lights.name = "SharedLighting"
	root.add_child(lights)
	var slots := Node3D.new()
	slots.name = "TenantSlots"
	root.add_child(slots)
	return root


func _add_tenant(
	parent: Node,
	tname: String,
	poi_id: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	functional_type: String,
	stage: int,
	entrance_local: Vector3,
	interact_script: Script = null
) -> Node3D:
	var tenant := Node3D.new()
	tenant.name = tname
	tenant.set_script(load(SCRIPT_TENANT))
	tenant.set("poi_id", poi_id)
	tenant.set("action_id", action_id)
	tenant.set("display_name", display_name)
	tenant.set("action_label", action_label)
	tenant.set("prompt_text", action_label)
	tenant.set("functional_type", functional_type)
	tenant.set("progression_stage", stage)
	tenant.set("payload", {"art_backed": true})
	parent.add_child(tenant)
	var ent := Marker3D.new()
	ent.name = "EntranceAnchor"
	ent.position = entrance_local
	tenant.add_child(ent)
	var ia := Area3D.new()
	ia.name = "InteractionArea"
	if interact_script != null:
		ia.set_script(interact_script)
	else:
		ia.set_script(load(SCRIPT_STUB))
	ia.set("action_id", action_id)
	ia.set("display_name", display_name)
	ia.set("action_label", action_label)
	ia.set("payload", {"art_backed": true})
	ia.position = entrance_local
	tenant.add_child(ia)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.2, 1.2)
	cs.shape = box
	cs.position = Vector3(0.0, 1.1, 0.0)
	ia.add_child(cs)
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


func _add_sibling_interact(
	tenant: Node3D,
	iname: String,
	action_id: StringName,
	display_name: String,
	action_label: String,
	pos: Vector3
) -> void:
	var ia := Area3D.new()
	ia.name = iname
	ia.set_script(load(SCRIPT_STUB))
	ia.set("action_id", action_id)
	ia.set("display_name", display_name)
	ia.set("action_label", action_label)
	ia.set("payload", {"art_backed": true})
	ia.position = pos
	tenant.add_child(ia)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.2, 1.2)
	cs.shape = box
	cs.position = Vector3(0.0, 1.1, 0.0)
	ia.add_child(cs)


func _signage(tenant: Node3D, text: String, board: Color, accent: Color) -> void:
	var signage: Node = tenant.get_node("Signage")
	var x: float = (tenant.get_node("EntranceAnchor") as Node3D).position.x
	_mesh_box(signage, "SignBoard", Vector3(1.45, 0.38, 0.06), Vector3(x, 2.45, 0.78), board)
	_mesh_box(signage, "SignAccent", Vector3(1.15, 0.1, 0.04), Vector3(x, 2.45, 0.82), accent)
	var label := Label3D.new()
	label.name = "SignLabel"
	label.text = text
	label.font_size = 22
	label.shaded = true
	label.modulate = Color(1.0, 0.96, 0.9)
	label.position = Vector3(x, 2.45, 0.88)
	signage.add_child(label)


func _omni(parent: Node, lname: String, pos: Vector3, color: Color, energy: float = 1.1) -> void:
	var l := OmniLight3D.new()
	l.name = lname
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = 6.0
	parent.add_child(l)


func _portal(visual: Node, color: Color, x: float = 0.0, z: float = 1.55, w: float = 1.15, h: float = 2.15) -> void:
	_mesh_box(visual, "Portal", Vector3(w, h, 0.18), Vector3(x, h * 0.5, z), color)


func _window_row(visual: Node, prefix: String, color: Color, y: float, z: float, xs: Array, w: float = 1.1, h: float = 1.15) -> void:
	var i := 0
	for xv in xs:
		_mesh_box(visual, "%s_%d" % [prefix, i], Vector3(w, h, 0.08), Vector3(float(xv), y, z), color)
		i += 1


func _b_player_home() -> Node3D:
	var root: Node3D = _new_building("PrototypePlayerHome", "player_home", "main_street", "VenueEntrance", Vector2(8, 8))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(6.2, 4.4, 5.2), Vector3(0.0, 2.2, -0.4), Color(0.74, 0.62, 0.5))
	_mesh_prism(v, "Roof", Vector3(6.6, 1.6, 5.6), Vector3(0.0, 5.2, -0.4), Color(0.55, 0.32, 0.24))
	_mesh_box(v, "Stoop", Vector3(2.2, 0.28, 1.4), Vector3(0.0, 0.14, 1.7), Color(0.62, 0.52, 0.42))
	_portal(v, Color(0.28, 0.16, 0.12), 0.0, 2.15, 1.2, 2.3)
	_window_row(v, "Win", Color(0.55, 0.72, 0.82), 2.6, 2.15, [-1.85, 1.85], 1.0, 1.05)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(6.2, 4.4, 5.2), Vector3(0.0, 2.2, -0.4))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Home", "player_home", &"go_home", "Дом", "Войти домой", "VenueEntrancePOI", 1, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "ДОМ", Color(0.35, 0.22, 0.16), Color(0.9, 0.72, 0.45))
	_omni(root.get_node("SharedLighting"), "Warm", Vector3(0, 2.6, 1.2), Color(1.0, 0.82, 0.55), 1.15)
	return root


func _b_cafe() -> Node3D:
	var root: Node3D = _new_building("PrototypeCafe", "cafe_two_hearts", "main_street", "VenueEntrance", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.4, 3.4, 4.2), Vector3(0.0, 1.7, -0.35), Color(0.82, 0.48, 0.4))
	_mesh_box(v, "Upper", Vector3(4.6, 1.5, 3.6), Vector3(0.0, 4.05, -0.5), Color(0.78, 0.42, 0.36))
	_mesh_box(v, "Awning", Vector3(4.2, 0.12, 1.15), Vector3(0.0, 2.55, 1.55), Color(0.92, 0.55, 0.38))
	_portal(v, Color(0.22, 0.1, 0.08), 0.0, 1.75, 1.35, 2.2)
	_window_row(v, "Win", Color(0.45, 0.78, 0.82), 1.55, 1.72, [-1.7, 1.7], 1.35, 1.45)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.4, 4.8, 4.2), Vector3(0.0, 2.4, -0.35))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Cafe", "cafe_two_hearts", &"sit_cafe", "Кафе Two Hearts", "Сесть и ждать свидание", "VenueEntrancePOI", 1, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "КАФЕ", Color(0.45, 0.18, 0.16), Color(1.0, 0.55, 0.35))
	_omni(root.get_node("SharedLighting"), "CafeWarm", Vector3(0, 2.35, 1.0), Color(1.0, 0.72, 0.45), 1.25)
	return root


func _b_retail() -> Node3D:
	var root: Node3D = _new_building("PrototypeRetailPairFlowerGift", "retail_pair_flower_gift", "main_street", "MultiTenant", Vector2(12, 7.5))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "FlowerBody", Vector3(5.2, 3.1, 4.4), Vector3(-1.85, 1.55, -0.3), Color(0.42, 0.62, 0.4))
	_mesh_box(v, "FlowerAwning", Vector3(4.6, 0.1, 0.95), Vector3(-1.85, 2.45, 1.7), Color(0.85, 0.45, 0.55))
	_mesh_box(v, "FlowerWindow", Vector3(3.6, 1.7, 0.1), Vector3(-1.85, 1.35, 1.85), Color(0.55, 0.85, 0.6))
	_mesh_box(v, "GiftBody", Vector3(5.0, 3.8, 4.6), Vector3(1.9, 1.9, -0.35), Color(0.72, 0.38, 0.42))
	_mesh_box(v, "GiftCanopy", Vector3(3.2, 0.22, 1.2), Vector3(1.9, 2.85, 1.65), Color(0.9, 0.7, 0.35))
	_mesh_box(v, "GiftWindow", Vector3(2.2, 1.4, 0.1), Vector3(1.9, 1.5, 1.9), Color(0.75, 0.55, 0.7))
	_portal(v, Color(0.18, 0.32, 0.16), -1.85, 1.85, 1.05, 2.05)
	_portal(v, Color(0.32, 0.12, 0.16), 1.9, 1.9, 1.1, 2.15)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(9.2, 3.8, 4.6), Vector3(0.0, 1.9, -0.35))
	var flower: Node3D = _add_tenant(root.get_node("TenantSlots"), "Flower", "flower_shop", &"open_flower_shop", "Цветочный", "Купить цветы", "StorefrontPOI", 1, Vector3(-1.8, 0, ENTRANCE_Z))
	_signage(flower, "ЦВЕТЫ", Color(0.15, 0.28, 0.15), Color(0.7, 0.95, 0.55))
	var gift: Node3D = _add_tenant(root.get_node("TenantSlots"), "Gift", "gift_shop", &"open_gift_shop", "Подарки", "Купить подарок", "StorefrontPOI", 1, Vector3(1.8, 0, ENTRANCE_Z))
	_signage(gift, "ПОДАРКИ", Color(0.28, 0.12, 0.18), Color(0.95, 0.55, 0.45))
	return root


func _b_fashion() -> Node3D:
	var root: Node3D = _new_building("PrototypeFashionPairJewelryClothing", "fashion_pair_jewelry_clothing", "main_street", "MultiTenant", Vector2(12, 7.5))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "JewelryBody", Vector3(4.6, 4.6, 4.2), Vector3(-1.5, 2.3, -0.35), Color(0.78, 0.68, 0.42))
	_mesh_box(v, "JewelryWindow", Vector3(2.4, 2.2, 0.1), Vector3(-1.5, 1.6, 1.75), Color(0.9, 0.82, 0.45))
	_mesh_box(v, "ClothingBody", Vector3(5.4, 3.5, 4.8), Vector3(1.6, 1.75, -0.4), Color(0.4, 0.48, 0.72))
	_mesh_box(v, "ClothingAwning", Vector3(4.4, 0.14, 1.05), Vector3(1.6, 2.7, 1.7), Color(0.55, 0.4, 0.7))
	_window_row(v, "ClothWin", Color(0.55, 0.7, 0.9), 1.55, 1.95, [0.55, 2.55], 1.3, 1.5)
	_portal(v, Color(0.22, 0.18, 0.08), -1.4, 1.75, 0.95, 2.1)
	_portal(v, Color(0.12, 0.14, 0.28), 1.4, 1.95, 1.25, 2.2)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(9.6, 4.6, 4.8), Vector3(0.05, 2.3, -0.4))
	var jew: Node3D = _add_tenant(root.get_node("TenantSlots"), "Jewelry", "jewelry_shop", &"open_jewelry_shop", "Ювелирный", "Открыть витрину", "StorefrontPOI", 1, Vector3(-1.4, 0, ENTRANCE_Z))
	_signage(jew, "ЗОЛОТО", Color(0.15, 0.15, 0.22), Color(0.85, 0.75, 0.35))
	var cloth: Node3D = _add_tenant(root.get_node("TenantSlots"), "Clothing", "clothing_shop", &"open_clothing_shop", "Одежда", "Примерить", "StorefrontPOI", 1, Vector3(1.4, 0, ENTRANCE_Z))
	_signage(cloth, "ОДЕЖДА", Color(0.18, 0.2, 0.35), Color(0.45, 0.55, 0.85))
	return root


func _b_homeware() -> Node3D:
	var root: Node3D = _new_building("PrototypeHomewareShop", "homeware_shop", "main_street", "Storefront", Vector2(8, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.6, 3.6, 4.4), Vector3(0.0, 1.8, -0.35), Color(0.7, 0.58, 0.46))
	_mesh_box(v, "Setback", Vector3(3.4, 1.2, 3.2), Vector3(0.8, 4.2, -0.55), Color(0.62, 0.5, 0.4))
	_mesh_box(v, "Awning", Vector3(3.8, 0.1, 0.9), Vector3(0.0, 2.6, 1.6), Color(0.55, 0.42, 0.32))
	_portal(v, Color(0.28, 0.2, 0.14), 0.0, 1.8, 1.15, 2.15)
	_window_row(v, "Win", Color(0.7, 0.78, 0.82), 1.6, 1.8, [-1.65, 1.65], 1.2, 1.25)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.6, 4.8, 4.4), Vector3(0.0, 2.4, -0.35))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Shop", "homeware_shop", &"open_homeware_shop", "Товары для дома", "Зайти в магазин", "StorefrontPOI", 1, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "ДОМ", Color(0.32, 0.24, 0.18), Color(0.85, 0.7, 0.5))
	return root


func _b_internet() -> Node3D:
	var root: Node3D = _new_building("PrototypeInternetCafe", "internet_cafe", "main_street", "Storefront", Vector2(8, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.8, 3.2, 4.6), Vector3(0.0, 1.6, -0.4), Color(0.28, 0.34, 0.42))
	_mesh_box(v, "ScreenBand", Vector3(5.2, 0.7, 0.12), Vector3(0.0, 2.85, 1.85), Color(0.25, 0.75, 0.85))
	_portal(v, Color(0.08, 0.1, 0.14), 0.0, 1.85, 1.05, 2.05)
	_window_row(v, "Win", Color(0.2, 0.85, 0.9), 1.5, 1.85, [-1.8, 1.8], 1.25, 1.2)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.8, 3.2, 4.6), Vector3(0.0, 1.6, -0.4))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "NetCafe", "internet_cafe", &"city_cafe_job", "ПК №1", "Поработать онлайн", "StorefrontPOI", 1, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "СЕТЬ", Color(0.12, 0.16, 0.22), Color(0.35, 0.9, 1.0))
	_add_sibling_interact(t, "InteractScroll", &"city_cafe_scroll", "ПК №2", "Скроллить (+популярность)", Vector3(1.2, 0, ENTRANCE_Z))
	_add_sibling_interact(t, "InteractCoffee", &"city_coffee", "Кофейня", "Купить кофе (+внимание)", Vector3(0, 0, 2.05))
	_omni(t.get_node("LocalLights"), "CyanOmni", Vector3(0, 2.1, 0.9), Color(0.35, 0.9, 1.0), 1.3)
	return root


func _b_bookstore() -> Node3D:
	var root: Node3D = _new_building("PrototypeBookstore", "bookstore", "park_leisure", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.0, 4.2, 4.0), Vector3(0.0, 2.1, -0.35), Color(0.48, 0.42, 0.34))
	_mesh_prism(v, "Roof", Vector3(5.4, 1.4, 4.4), Vector3(0.0, 4.9, -0.35), Color(0.28, 0.38, 0.3))
	_mesh_box(v, "Bay", Vector3(2.6, 2.4, 0.7), Vector3(0.0, 1.4, 1.7), Color(0.4, 0.36, 0.28))
	_portal(v, Color(0.22, 0.14, 0.1), 0.0, 1.95, 1.1, 2.2)
	_window_row(v, "Win", Color(0.55, 0.7, 0.55), 2.8, 1.6, [-1.45, 1.45], 1.0, 0.95)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.0, 5.4, 4.4), Vector3(0.0, 2.7, -0.2))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Books", "bookstore", &"open_bookstore", "Книжный", "Посмотреть книги", "StorefrontPOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "КНИГИ", Color(0.22, 0.28, 0.2), Color(0.7, 0.82, 0.55))
	return root


func _b_gym() -> Node3D:
	var root: Node3D = _new_building("PrototypeGym", "gym", "park_leisure", "Storefront", Vector2(9, 8))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(7.2, 3.0, 5.2), Vector3(0.0, 1.5, -0.4), Color(0.38, 0.52, 0.44))
	_mesh_box(v, "Hall", Vector3(7.6, 2.2, 5.6), Vector3(0.0, 4.1, -0.4), Color(0.32, 0.46, 0.4))
	_mesh_box(v, "Awning", Vector3(4.0, 0.16, 1.3), Vector3(0.0, 2.7, 1.85), Color(0.22, 0.28, 0.24))
	_portal(v, Color(0.1, 0.12, 0.12), 0.0, 2.15, 1.8, 2.4)
	_window_row(v, "Win", Color(0.35, 0.7, 0.75), 1.7, 2.15, [-2.4, 2.4], 1.6, 1.35)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(7.6, 5.2, 5.6), Vector3(0.0, 2.6, -0.4))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Gym", "gym", &"city_workout", "Зал", "Потренироваться", "StorefrontPOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "ЗАЛ", Color(0.16, 0.22, 0.18), Color(0.45, 0.85, 0.55))
	_add_sibling_interact(t, "InteractPass", &"city_gym_pass", "Абонемент", "Купить абонемент", Vector3(1.6, 0, ENTRANCE_Z))
	return root


func _b_cinema() -> Node3D:
	var root: Node3D = _new_building("PrototypeCinema", "cinema", "park_leisure", "Landmark", Vector2(14, 11))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Base", Vector3(10.5, 2.4, 6.4), Vector3(0.0, 1.2, -0.6), Color(0.22, 0.18, 0.28))
	_mesh_box(v, "Hall", Vector3(8.6, 4.2, 5.6), Vector3(0.0, 4.5, -0.8), Color(0.18, 0.14, 0.24))
	_mesh_box(v, "Marquee", Vector3(7.2, 0.7, 1.6), Vector3(0.0, 3.15, 2.15), Color(0.12, 0.08, 0.18))
	_portal(v, Color(0.08, 0.06, 0.1), 0.0, 2.5, 2.6, 2.5)
	_window_row(v, "Win", Color(0.95, 0.35, 0.85), 1.55, 2.55, [-3.4, 3.4], 1.8, 1.2)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(10.5, 6.6, 6.4), Vector3(0.0, 3.3, -0.6))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Cinema", "cinema", &"sit_cinema", "Кинотеатр", "Купить билет", "VenueEntrancePOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "КИНО", Color(0.08, 0.05, 0.12), Color(0.95, 0.35, 0.85))
	_omni(root.get_node("SharedLighting"), "Neon", Vector3(0, 3.2, 1.4), Color(0.95, 0.4, 0.85), 1.2)
	return root


func _b_arcade() -> Node3D:
	var root: Node3D = _new_building("PrototypeArcade", "arcade", "park_leisure", "Storefront", Vector2(8, 8))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(6.4, 3.3, 5.0), Vector3(0.0, 1.65, -0.4), Color(0.32, 0.22, 0.42))
	_mesh_box(v, "Canopy", Vector3(6.8, 0.28, 1.5), Vector3(0.0, 3.35, 1.7), Color(0.95, 0.45, 0.25))
	_mesh_cyl(v, "Tower", 0.45, 2.2, Vector3(2.4, 4.4, -0.2), Color(0.45, 0.85, 0.95))
	_portal(v, Color(0.12, 0.06, 0.16), 0.0, 2.05, 1.5, 2.25)
	_window_row(v, "Win", Color(0.35, 0.9, 1.0), 1.6, 2.05, [-2.0, 2.0], 1.15, 1.2)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(6.8, 4.4, 5.0), Vector3(0.0, 2.2, -0.4))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Arcade", "arcade", &"open_arcade", "Аркада", "Играть", "StorefrontPOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "АРКАДА", Color(0.16, 0.08, 0.22), Color(0.95, 0.45, 0.25))
	_add_sibling_interact(t, "InteractSit", &"sit_arcade", "Автомат", "Сесть за автомат", Vector3(1.4, 0, ENTRANCE_Z))
	return root


func _b_bar() -> Node3D:
	var root: Node3D = _new_building("PrototypeBar", "bar", "park_leisure", "Storefront", Vector2(7, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.4, 3.5, 4.4), Vector3(0.0, 1.75, -0.35), Color(0.42, 0.22, 0.24))
	_mesh_box(v, "RoofCap", Vector3(5.8, 0.35, 4.8), Vector3(0.0, 3.7, -0.35), Color(0.22, 0.12, 0.12))
	_mesh_box(v, "Awning", Vector3(3.6, 0.12, 1.1), Vector3(0.0, 2.55, 1.6), Color(0.7, 0.28, 0.28))
	_portal(v, Color(0.12, 0.06, 0.06), 0.0, 1.8, 1.2, 2.2)
	_window_row(v, "Win", Color(0.85, 0.45, 0.25), 1.7, 1.8, [-1.7, 1.7], 1.15, 1.1)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.4, 3.8, 4.4), Vector3(0.0, 1.9, -0.35))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Bar", "bar", &"city_bar_drink", "Бар", "Заказать напиток", "StorefrontPOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "БАР", Color(0.18, 0.08, 0.08), Color(0.9, 0.4, 0.3))
	return root


func _b_park_restaurant() -> Node3D:
	var root: Node3D = _new_building("PrototypeParkRestaurant", "park_restaurant", "park_leisure", "VenueEntrance", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(7.2, 3.2, 5.2), Vector3(0.0, 1.6, -0.4), Color(0.55, 0.48, 0.36))
	_mesh_prism(v, "Roof", Vector3(7.8, 1.8, 5.8), Vector3(0.0, 4.1, -0.4), Color(0.32, 0.42, 0.3))
	_mesh_box(v, "Terrace", Vector3(4.4, 0.18, 2.0), Vector3(0.0, 0.09, 2.2), Color(0.45, 0.5, 0.38))
	_portal(v, Color(0.22, 0.16, 0.1), 0.0, 2.15, 1.5, 2.25)
	_window_row(v, "Win", Color(0.7, 0.82, 0.55), 1.7, 2.15, [-2.2, 2.2], 1.5, 1.35)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(7.2, 4.8, 5.2), Vector3(0.0, 2.4, -0.4))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Restaurant", "park_restaurant", &"sit_restaurant", "Ресторан в парке", "Забронировать стол", "VenueEntrancePOI", 2, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "РЕСТОРАН", Color(0.22, 0.28, 0.18), Color(0.7, 0.85, 0.45))
	return root


func _b_photo() -> Node3D:
	var root: Node3D = _new_building("PrototypePhotoStudio", "photo_studio", "agency_row", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(5.2, 4.0, 4.2), Vector3(0.0, 2.0, -0.35), Color(0.42, 0.46, 0.55))
	_mesh_box(v, "StudioBox", Vector3(3.2, 2.4, 3.0), Vector3(1.2, 3.2, -0.6), Color(0.5, 0.54, 0.62))
	_mesh_box(v, "Awning", Vector3(3.0, 0.1, 0.85), Vector3(0.0, 2.7, 1.55), Color(0.7, 0.75, 0.82))
	_portal(v, Color(0.16, 0.18, 0.24), 0.0, 1.7, 1.05, 2.15)
	_window_row(v, "Win", Color(0.85, 0.9, 0.95), 1.7, 1.7, [-1.55, 1.55], 1.15, 1.3)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(5.2, 4.4, 4.2), Vector3(0.0, 2.2, -0.35))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Studio", "photo_studio", &"open_photo_studio", "Фотостудия", "Сделать снимок", "StorefrontPOI", 3, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "ФОТО", Color(0.22, 0.24, 0.32), Color(0.75, 0.82, 0.95))
	return root


func _b_barber() -> Node3D:
	var root: Node3D = _new_building("PrototypeBarberShop", "barber_shop", "agency_row", "Storefront", Vector2(6, 7))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(4.8, 3.6, 4.0), Vector3(0.0, 1.8, -0.3), Color(0.5, 0.52, 0.58))
	_mesh_cyl(v, "Pole", 0.12, 1.6, Vector3(1.7, 2.6, 1.7), Color(0.85, 0.25, 0.28))
	_mesh_box(v, "Awning", Vector3(3.4, 0.1, 0.8), Vector3(0.0, 2.55, 1.55), Color(0.75, 0.78, 0.85))
	_portal(v, Color(0.18, 0.18, 0.22), 0.0, 1.65, 1.0, 2.1)
	_window_row(v, "Win", Color(0.7, 0.82, 0.9), 1.55, 1.65, [-1.4, 1.4], 1.05, 1.2)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(4.8, 3.6, 4.0), Vector3(0.0, 1.8, -0.3))
	var t: Node3D = _add_tenant(root.get_node("TenantSlots"), "Barber", "barber_shop", &"open_barber", "Барбершоп", "Подстричься", "StorefrontPOI", 3, Vector3(0, 0, ENTRANCE_Z))
	_signage(t, "БАРБЕР", Color(0.2, 0.22, 0.28), Color(0.85, 0.3, 0.32))
	return root


func _b_agency() -> Node3D:
	var root: Node3D = _new_building("PrototypeAgencyOffice", "agency_office", "agency_row", "Storefront", Vector2(10, 9))
	var v: Node = root.get_node("VisualRoot")
	_mesh_box(v, "Body", Vector3(6.4, 6.4, 4.6), Vector3(0.0, 3.2, -0.5), Color(0.38, 0.44, 0.55))
	_mesh_box(v, "FinL", Vector3(0.45, 6.8, 4.8), Vector3(-3.0, 3.4, -0.5), Color(0.32, 0.38, 0.5))
	_mesh_box(v, "FinR", Vector3(0.45, 6.8, 4.8), Vector3(3.0, 3.4, -0.5), Color(0.32, 0.38, 0.5))
	_portal(v, Color(0.12, 0.14, 0.2), 0.0, 1.75, 0.95, 2.4)
	_window_row(v, "WinA", Color(0.55, 0.7, 0.9), 2.4, 1.75, [-1.5, 1.5], 0.9, 1.1)
	_window_row(v, "WinB", Color(0.55, 0.7, 0.9), 4.2, 1.75, [-1.5, 1.5], 0.9, 1.1)
	_static_box(root.get_node("CollisionRoot"), "Body", Vector3(6.9, 6.8, 4.8), Vector3(0.0, 3.4, -0.5))
	var t: Node3D = _add_tenant(
		root.get_node("TenantSlots"),
		"Agency",
		"agency_office",
		&"claim_day_job",
		"Офис",
		"Сходить на работу",
		"StorefrontPOI",
		3,
		Vector3(0, 0, ENTRANCE_Z),
		load(SCRIPT_DAY_JOB) as Script
	)
	_signage(t, "ОФИС", Color(0.2, 0.22, 0.28), Color(0.55, 0.7, 0.9))
	_omni(t.get_node("LocalLights"), "Office", Vector3(0, 2.5, 0.9), Color(0.7, 0.82, 1.0), 1.0)
	return root


func _a_main_bench() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeMainBench"
	root.set_script(load(SCRIPT_TENANT))
	root.set("poi_id", "main_bench")
	root.set("action_id", &"city_rest")
	root.set("display_name", "Скамейка")
	root.set("action_label", "Отдохнуть")
	root.set("prompt_text", "Отдохнуть")
	root.set("functional_type", "WorldActivityPOI")
	root.set("progression_stage", 1)
	root.set("payload", {"art_backed": true})
	_finish_activity_visual(root, Color(0.55, 0.42, 0.32), false)
	var t: Node3D = root
	_add_activity_interact(t, &"city_rest", "Скамейка", "Отдохнуть")
	_signage(t, "ОТДЫХ", Color(0.32, 0.24, 0.18), Color(0.85, 0.7, 0.5))
	return root


func _a_park_bench() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeParkBench"
	root.set_script(load(SCRIPT_TENANT))
	root.set("poi_id", "park_bench")
	root.set("action_id", &"city_rest")
	root.set("display_name", "Парковая скамейка")
	root.set("action_label", "Отдохнуть")
	root.set("prompt_text", "Отдохнуть")
	root.set("functional_type", "WorldActivityPOI")
	root.set("progression_stage", 2)
	root.set("payload", {"art_backed": true})
	_finish_activity_visual(root, Color(0.35, 0.48, 0.36), true)
	_add_activity_interact(root, &"city_rest", "Парковая скамейка", "Отдохнуть")
	_signage(root, "ПАРК", Color(0.18, 0.28, 0.18), Color(0.55, 0.78, 0.45))
	return root


func _finish_activity_visual(root: Node3D, color: Color, long_seat: bool) -> void:
	var vis := Node3D.new()
	vis.name = "IdentityProps"
	root.add_child(vis)
	var w: float = 2.4 if long_seat else 1.8
	_mesh_box(vis, "Seat", Vector3(w, 0.12, 0.55), Vector3(0.0, 0.48, 0.0), color)
	_mesh_box(vis, "Back", Vector3(w, 0.55, 0.1), Vector3(0.0, 0.82, -0.28), color.darkened(0.15))
	_mesh_box(vis, "LegL", Vector3(0.12, 0.44, 0.5), Vector3(-w * 0.4, 0.22, 0.0), color.darkened(0.25))
	_mesh_box(vis, "LegR", Vector3(0.12, 0.44, 0.5), Vector3(w * 0.4, 0.22, 0.0), color.darkened(0.25))
	var body := StaticBody3D.new()
	body.name = "Collision"
	vis.add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, 0.9, 0.7)
	cs.shape = shape
	cs.position = Vector3(0.0, 0.45, 0.0)
	body.add_child(cs)
	for n in ["EntranceAnchor", "PromptAnchor", "SignAnchor", "Signage", "LocalLights"]:
		var m := Marker3D.new() if n.ends_with("Anchor") else Node3D.new()
		m.name = n
		root.add_child(m)
	(root.get_node("EntranceAnchor") as Node3D).position = Vector3(0, 0, 0.7)
	(root.get_node("PromptAnchor") as Node3D).position = Vector3(0, 0.7, 0.7)
	(root.get_node("SignAnchor") as Node3D).position = Vector3(0, 1.4, 0.2)


func _add_activity_interact(root: Node3D, action_id: StringName, display_name: String, action_label: String) -> void:
	var ia := Area3D.new()
	ia.name = "InteractionArea"
	ia.set_script(load(SCRIPT_STUB))
	ia.set("action_id", action_id)
	ia.set("display_name", display_name)
	ia.set("action_label", action_label)
	ia.set("payload", {"art_backed": true})
	ia.position = Vector3(0, 0, 0.7)
	root.add_child(ia)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.6, 1.2)
	cs.shape = box
	cs.position = Vector3(0.0, 0.8, 0.0)
	ia.add_child(cs)


func _a_duck() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeDuckFeeding"
	root.set_script(load(SCRIPT_TENANT))
	root.set("poi_id", "duck_feeding")
	root.set("action_id", &"city_park_fun")
	root.set("display_name", "Утки")
	root.set("action_label", "Покормить уток")
	root.set("prompt_text", "Покормить уток")
	root.set("functional_type", "WorldActivityPOI")
	root.set("progression_stage", 2)
	root.set("payload", {"art_backed": true})
	for n in ["EntranceAnchor", "PromptAnchor", "SignAnchor", "Signage", "LocalLights", "IdentityProps"]:
		var node := Node3D.new()
		node.name = n
		root.add_child(node)
	(root.get_node("EntranceAnchor") as Node3D).position = Vector3(0, 0, 0.8)
	(root.get_node("PromptAnchor") as Node3D).position = Vector3(0, 0.7, 0.8)
	_mesh_box(root.get_node("IdentityProps"), "Trough", Vector3(1.6, 0.35, 0.7), Vector3(0.0, 0.35, 0.0), Color(0.4, 0.32, 0.22))
	_mesh_box(root.get_node("IdentityProps"), "Post", Vector3(0.12, 1.1, 0.12), Vector3(0.0, 0.9, -0.4), Color(0.32, 0.28, 0.2))
	_add_activity_interact(root, &"city_park_fun", "Утки", "Покормить уток")
	_signage(root, "УТКИ", Color(0.18, 0.28, 0.2), Color(0.55, 0.75, 0.4))
	return root


func _a_karaoke() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeKaraokeStand"
	root.set_script(load(SCRIPT_TENANT))
	root.set("poi_id", "karaoke")
	root.set("action_id", &"city_karaoke")
	root.set("display_name", "Караоке")
	root.set("action_label", "Спеть")
	root.set("prompt_text", "Спеть")
	root.set("functional_type", "WorldActivityPOI")
	root.set("progression_stage", 2)
	root.set("payload", {"art_backed": true})
	for n in ["EntranceAnchor", "PromptAnchor", "SignAnchor", "Signage", "LocalLights", "IdentityProps"]:
		var node := Node3D.new()
		node.name = n
		root.add_child(node)
	(root.get_node("EntranceAnchor") as Node3D).position = Vector3(0, 0, 0.9)
	(root.get_node("PromptAnchor") as Node3D).position = Vector3(0, 0.8, 0.9)
	_mesh_box(root.get_node("IdentityProps"), "Stage", Vector3(2.2, 0.22, 1.6), Vector3(0.0, 0.11, 0.0), Color(0.45, 0.28, 0.4))
	_mesh_box(root.get_node("IdentityProps"), "Kiosk", Vector3(1.1, 1.6, 0.7), Vector3(0.0, 1.0, -0.35), Color(0.32, 0.22, 0.38))
	_add_activity_interact(root, &"city_karaoke", "Караоке", "Спеть")
	_signage(root, "КАРАОКЕ", Color(0.22, 0.12, 0.22), Color(0.9, 0.45, 0.7))
	return root


func _a_bus() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeBusStopCandy"
	root.set_script(load(SCRIPT_TENANT))
	root.set("poi_id", "bus_stop_candy")
	root.set("action_id", &"city_bus_info")
	root.set("display_name", "Остановка")
	root.set("action_label", "Посмотреть расписание")
	root.set("prompt_text", "Посмотреть расписание")
	root.set("functional_type", "WorldActivityPOI")
	root.set("progression_stage", 3)
	root.set("payload", {"art_backed": true})
	for n in ["EntranceAnchor", "PromptAnchor", "SignAnchor", "Signage", "LocalLights", "IdentityProps"]:
		var node := Node3D.new()
		node.name = n
		root.add_child(node)
	(root.get_node("EntranceAnchor") as Node3D).position = Vector3(0, 0, 0.9)
	(root.get_node("PromptAnchor") as Node3D).position = Vector3(0, 0.8, 0.9)
	var vis: Node = root.get_node("IdentityProps")
	_mesh_box(vis, "Roof", Vector3(3.2, 0.12, 1.6), Vector3(0.0, 2.35, 0.0), Color(0.4, 0.48, 0.55))
	_mesh_box(vis, "PostL", Vector3(0.12, 2.3, 0.12), Vector3(-1.45, 1.15, -0.65), Color(0.3, 0.34, 0.4))
	_mesh_box(vis, "PostR", Vector3(0.12, 2.3, 0.12), Vector3(1.45, 1.15, -0.65), Color(0.3, 0.34, 0.4))
	_mesh_box(vis, "Back", Vector3(3.0, 1.4, 0.08), Vector3(0.0, 1.2, -0.72), Color(0.45, 0.5, 0.58))
	_mesh_box(vis, "Candy", Vector3(0.7, 1.4, 0.7), Vector3(1.1, 0.7, 0.35), Color(0.85, 0.28, 0.4))
	_add_activity_interact(root, &"city_bus_info", "Остановка", "Посмотреть расписание")
	_add_sibling_interact(root, "InteractCandy", &"city_buy_gift", "Автомат", "Купить сладкий подарок", Vector3(1.1, 0, 0.9))
	_signage(root, "АВТОБУС", Color(0.2, 0.22, 0.28), Color(0.55, 0.7, 0.9))
	return root


func _b_background(idx: int) -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeBackgroundHouse%02d" % idx
	var vis := Node3D.new()
	vis.name = "VisualRoot"
	root.add_child(vis)
	var collision := Node3D.new()
	collision.name = "CollisionRoot"
	root.add_child(collision)
	var palettes: Array = [
		Color(0.62, 0.54, 0.46),
		Color(0.58, 0.5, 0.42),
		Color(0.5, 0.48, 0.44),
		Color(0.48, 0.52, 0.48),
		Color(0.46, 0.5, 0.52),
		Color(0.44, 0.48, 0.54),
	]
	var body_c: Color = palettes[idx % palettes.size()]
	var w: float = 7.5 + float(idx % 3) * 1.4
	var d: float = 6.0 + float((idx / 2) % 3) * 1.1
	var h: float = 6.5 + float(idx % 4) * 1.8
	_mesh_box(vis, "Body", Vector3(w, h, d), Vector3(0.0, h * 0.5, 0.0), body_c)
	_static_box(collision, "Body", Vector3(w, h, d), Vector3(0.0, h * 0.5, 0.0))
	match idx % 4:
		0:
			_mesh_prism(vis, "Roof", Vector3(w + 0.4, 1.8, d + 0.4), Vector3(0.0, h + 0.9, 0.0), body_c.darkened(0.18))
		1:
			_mesh_box(vis, "Roof", Vector3(w + 0.2, 0.4, d + 0.2), Vector3(0.0, h + 0.2, 0.0), body_c.darkened(0.22))
		2:
			_mesh_box(vis, "Setback", Vector3(w * 0.62, 2.2, d * 0.7), Vector3(w * 0.12, h + 1.1, 0.0), body_c.lightened(0.05))
		_:
			_mesh_cyl(vis, "Turret", 1.1, 2.8, Vector3(w * 0.28, h + 1.2, d * 0.1), body_c.darkened(0.1))
	_window_row(vis, "W1", Color(0.45, 0.55, 0.62), h * 0.38, d * 0.5 + 0.02, [-w * 0.28, w * 0.28], 1.1, 1.2)
	_window_row(vis, "W2", Color(0.45, 0.55, 0.62), h * 0.68, d * 0.5 + 0.02, [-w * 0.22, 0.0, w * 0.22], 0.9, 1.0)
	return root


func _road_box(parent: Node, nname: String, size: Vector3, pos: Vector3, color: Color) -> void:
	_mesh_box(parent, nname, size, pos, color)
	_static_box(parent, nname + "Body", Vector3(size.x, maxf(size.y, 0.2), size.z), pos)


func _build_roads() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeRoads"
	var surfaces := Node3D.new()
	surfaces.name = "RoadSurfaces"
	root.add_child(surfaces)
	var walks := Node3D.new()
	walks.name = "Sidewalks"
	root.add_child(walks)
	var curbs := Node3D.new()
	curbs.name = "Curbs"
	root.add_child(curbs)
	var crossings := Node3D.new()
	crossings.name = "Crossings"
	root.add_child(crossings)
	var asphalt := Color(0.18, 0.18, 0.21)
	var asphalt_c := Color(0.16, 0.17, 0.21)
	var walk := Color(0.36, 0.34, 0.37)
	var walk_c := Color(0.32, 0.32, 0.36)
	var curb := Color(0.48, 0.46, 0.5)
	var stripe := Color(0.72, 0.72, 0.74)
	_mesh_box(surfaces, "RoadCommercial", Vector3(34, 0.08, 7), Vector3(12, 0, 0), asphalt)
	_mesh_box(surfaces, "RoadResidential", Vector3(7, 0.08, 18), Vector3(28, 0, 10), asphalt)
	_mesh_box(surfaces, "RoadAgencySouth", Vector3(24, 0.08, 6), Vector3(-19, 0, 0), asphalt_c)
	_mesh_box(surfaces, "RoadAgencyWest", Vector3(6, 0.08, 10), Vector3(-30.5, 0, 5), asphalt_c)
	_mesh_box(surfaces, "RoadAgencyNorth", Vector3(12, 0.08, 5.5), Vector3(-25.5, 0, 9.5), asphalt_c)
	_mesh_box(walks, "SidewalkNorth", Vector3(34, 0.1, 2.1), Vector3(12, 0.02, 4.55), walk)
	_mesh_box(walks, "SidewalkSouth", Vector3(34, 0.1, 2.1), Vector3(12, 0.02, -4.55), walk)
	_mesh_box(walks, "SidewalkResEast", Vector3(2, 0.1, 18), Vector3(32.2, 0.02, 10), walk)
	_mesh_box(walks, "SidewalkResWest", Vector3(2, 0.1, 14), Vector3(23.8, 0.02, 10.5), walk)
	_mesh_box(walks, "SidewalkAgencyN", Vector3(24, 0.1, 1.7), Vector3(-19, 0.02, 3.85), walk_c)
	_mesh_box(walks, "SidewalkAgencyS", Vector3(24, 0.1, 1.7), Vector3(-19, 0.02, -3.85), walk_c)
	_mesh_box(curbs, "CurbNorth", Vector3(34, 0.14, 0.18), Vector3(12, 0.05, 3.5), curb)
	_mesh_box(curbs, "CurbSouth", Vector3(34, 0.14, 0.18), Vector3(12, 0.05, -3.5), curb)
	_mesh_box(crossings, "CrossingRes", Vector3(2.4, 0.09, 7), Vector3(25.5, 0.01, 0), stripe)
	_mesh_box(crossings, "CrossingToPark", Vector3(3.2, 0.09, 2.2), Vector3(0, 0.01, 5.2), Color(0.5, 0.48, 0.52))
	var ground := Node3D.new()
	ground.name = "GroundPads"
	root.add_child(ground)
	_mesh_box(ground, "PlazaPad", Vector3(10.5, 0.09, 10.5), Vector3(0, -0.01, 0.2), Color(0.4, 0.36, 0.34))
	_mesh_box(ground, "GrassPad", Vector3(20, 0.07, 18), Vector3(1, -0.02, 17.5), Color(0.22, 0.36, 0.26))
	_mesh_box(ground, "ForecourtPad", Vector3(16.5, 0.09, 13), Vector3(-17, -0.01, 20.5), Color(0.28, 0.3, 0.36))
	_mesh_box(ground, "PondWater", Vector3(7.5, 0.2, 5.5), Vector3(1, -0.04, 17.5), Color(0.16, 0.28, 0.36))
	_mesh_box(ground, "PondRim", Vector3(8.3, 0.12, 6.3), Vector3(1, 0, 17.5), Color(0.38, 0.36, 0.32))
	var path_pts: Array = [
		Vector3(0.0, 0.02, 8.0), Vector3(4.5, 0.02, 11.0), Vector3(7.0, 0.02, 16.5),
		Vector3(5.0, 0.02, 22.0), Vector3(1.0, 0.02, 25.5), Vector3(-4.5, 0.02, 23.0),
		Vector3(-6.5, 0.02, 18.0), Vector3(-4.0, 0.02, 12.5), Vector3(0.0, 0.02, 8.0),
	]
	for i in range(path_pts.size() - 1):
		var a: Vector3 = path_pts[i]
		var b: Vector3 = path_pts[i + 1]
		var mid: Vector3 = (a + b) * 0.5
		var len: float = a.distance_to(b)
		var yaw: float = atan2(b.x - a.x, b.z - a.z)
		var seg: MeshInstance3D = _mesh_box(ground, "Path_%02d" % i, Vector3(3.4, 0.08, maxf(len, 1.2)), mid, Color(0.42, 0.38, 0.32))
		seg.rotation.y = yaw
	var pond := StaticBody3D.new()
	pond.name = "PondCollision"
	pond.position = Vector3(1, -0.05, 17.5)
	ground.add_child(pond)
	var pcs := CollisionShape3D.new()
	var pshape := BoxShape3D.new()
	pshape.size = Vector3(7.5, 1.2, 5.5)
	pcs.shape = pshape
	pcs.position = Vector3(0, 0.4, 0)
	pond.add_child(pcs)
	return root


func _build_boundaries() -> Node3D:
	var root := Node3D.new()
	root.name = "PrototypeBoundaries"
	_mesh_box(root, "AlleyCloseSouth", Vector3(20, 3.2, 0.4), Vector3(10, 1.6, -10.5), Color(0.32, 0.3, 0.28))
	_static_box(root, "AlleyCloseSouthBody", Vector3(20, 3.2, 0.4), Vector3(10, 1.6, -10.5))
	_mesh_box(root, "AlleyCloseWest", Vector3(0.4, 3.5, 16), Vector3(-36, 1.75, 14), Color(0.3, 0.32, 0.36))
	_static_box(root, "AlleyCloseWestBody", Vector3(0.4, 3.5, 16), Vector3(-36, 1.75, 14))
	_mesh_box(root, "BusEndWall", Vector3(1.2, 3.6, 6), Vector3(-33.5, 1.8, 5), Color(0.28, 0.32, 0.38))
	_static_box(root, "BusEndWallBody", Vector3(1.2, 3.6, 6), Vector3(-33.5, 1.8, 5))
	_mesh_box(root, "FillerN_9", Vector3(0.35, 2.8, 1.4), Vector3(8.75, 1.4, 6.5), Color(0.5, 0.42, 0.36))
	_static_box(root, "FillerN_9Body", Vector3(0.35, 2.8, 1.4), Vector3(8.75, 1.4, 6.5))
	_mesh_box(root, "FillerN_15", Vector3(0.35, 2.8, 1.4), Vector3(15.45, 1.4, 6.5), Color(0.5, 0.42, 0.36))
	_static_box(root, "FillerN_15Body", Vector3(0.35, 2.8, 1.4), Vector3(15.45, 1.4, 6.5))
	_mesh_box(root, "FillerS_9", Vector3(0.35, 2.8, 1.4), Vector3(8.75, 1.4, -6.5), Color(0.42, 0.44, 0.48))
	_static_box(root, "FillerS_9Body", Vector3(0.35, 2.8, 1.4), Vector3(8.75, 1.4, -6.5))
	_mesh_box(root, "FillerS_15", Vector3(0.35, 2.8, 1.4), Vector3(15.45, 1.4, -6.5), Color(0.42, 0.44, 0.48))
	_static_box(root, "FillerS_15Body", Vector3(0.35, 2.8, 1.4), Vector3(15.45, 1.4, -6.5))
	_mesh_box(root, "FillerAgency1", Vector3(0.4, 3.2, 1.5), Vector3(-15.85, 1.6, -6.5), Color(0.36, 0.4, 0.48))
	_static_box(root, "FillerAgency1Body", Vector3(0.4, 3.2, 1.5), Vector3(-15.85, 1.6, -6.5))
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorCollider"
	root.add_child(floor_body)
	var fs := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(100, 0.4, 70)
	fs.shape = fshape
	fs.position = Vector3(-2, -0.2, 8)
	floor_body.add_child(fs)
	_mesh_box(root, "GroundBase", Vector3(100, 0.06, 70), Vector3(-2, -0.05, 8), Color(0.22, 0.22, 0.24))
	return root


func _yaw(x: float, z: float, deg: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(deg)), Vector3(x, 0.0, z))


func _inst(parent: Node, path: String, nname: String, xf: Transform3D) -> Node3D:
	var ps: PackedScene = load(path) as PackedScene
	var n: Node3D = ps.instantiate() as Node3D
	n.name = nname
	n.transform = xf
	parent.add_child(n)
	return n


func _stage_root(parent: Node, nname: String, district_id: String, stage: int) -> Node3D:
	var n := Node3D.new()
	n.name = nname
	n.set_meta("district_id", district_id)
	n.set_meta("progression_stage", stage)
	parent.add_child(n)
	for folder in ["Buildings", "POIs", "WorldActivities"]:
		var f := Node3D.new()
		f.name = folder
		n.add_child(f)
	return n


func _marker(parent: Node, nname: String, x: float, z: float) -> void:
	var m := Marker3D.new()
	m.name = nname
	m.position = Vector3(x, 0.0, z)
	parent.add_child(m)


func _build_city_scene() -> String:
	var city := Node3D.new()
	city.name = "City"
	city.set_script(load(SCRIPT_SYNC))
	var s1: Node3D = _stage_root(city, "Stage1_MainStreet", "main_street", 1)
	var s2: Node3D = _stage_root(city, "Stage2_ParkLeisure", "park_leisure", 2)
	var s3: Node3D = _stage_root(city, "Stage3_AgencyRow", "agency_row", 3)
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypePlayerHome.tscn", "PlayerHome", _yaw(32.6, 16.5, -90))
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypeCafe.tscn", "CafeTwoHearts", _yaw(23.8, 14.2, 90))
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypeRetailPairFlowerGift.tscn", "RetailPairFlowerGift", _yaw(15.45, 6.35, 180))
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypeFashionPairJewelryClothing.tscn", "FashionPairJewelryClothing", _yaw(5.4, 6.35, 180))
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypeHomewareShop.tscn", "HomewareShop", _yaw(12.1, -6.35, 0))
	_inst(s1.get_node("POIs"), OUT_BUILDINGS + "PrototypeInternetCafe.tscn", "InternetCafe", _yaw(5.4, -6.35, 0))
	_inst(s1.get_node("WorldActivities"), OUT_ACTIVITIES + "PrototypeMainBench.tscn", "MainBench", Transform3D(Basis(Vector3.UP, deg_to_rad(40)), Vector3(-3.6, 0, 3.4)))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeBookstore.tscn", "Bookstore", _yaw(-14.2, 12.0, 0))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeGym.tscn", "Gym", _yaw(-7.5, 12.0, 0))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeCinema.tscn", "Cinema", _yaw(-27.2, 17.5, 90))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeArcade.tscn", "Arcade", _yaw(-27.2, 24.2, 90))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeBar.tscn", "Bar", _yaw(-16.5, 29.8, 180))
	_inst(s2.get_node("POIs"), OUT_BUILDINGS + "PrototypeParkRestaurant.tscn", "ParkRestaurant", _yaw(3.2, 21.2, 180))
	_inst(s2.get_node("WorldActivities"), OUT_ACTIVITIES + "PrototypeParkBench.tscn", "ParkBench", Transform3D(Basis(Vector3.UP, deg_to_rad(140)), Vector3(-3.8, 0, 22.8)))
	_inst(s2.get_node("WorldActivities"), OUT_ACTIVITIES + "PrototypeDuckFeeding.tscn", "DuckFeeding", _yaw(6.2, 16.8, -90))
	_inst(s2.get_node("WorldActivities"), OUT_ACTIVITIES + "PrototypeKaraokeStand.tscn", "KaraokeStand", Transform3D(Basis(Vector3.UP, deg_to_rad(30)), Vector3(-10.5, 0, 26.5)))
	_inst(s3.get_node("POIs"), OUT_BUILDINGS + "PrototypePhotoStudio.tscn", "PhotoStudio", _yaw(-12.5, -6.35, 0))
	_inst(s3.get_node("POIs"), OUT_BUILDINGS + "PrototypeBarberShop.tscn", "BarberShop", _yaw(-24.5, 11.8, 180))
	_inst(s3.get_node("POIs"), OUT_BUILDINGS + "PrototypeAgencyOffice.tscn", "AgencyOffice", _yaw(-19.2, -6.35, 0))
	_inst(s3.get_node("WorldActivities"), OUT_ACTIVITIES + "PrototypeBusStopCandy.tscn", "BusStopCandy", _yaw(-30.5, 5.0, 90))
	var bg_rows: Array = [
		{"p": Vector3(36.5, 0, 16.0), "ry": -90.0, "st": s1},
		{"p": Vector3(36.5, 0, 8.0), "ry": -90.0, "st": s1},
		{"p": Vector3(34.5, 0, 22.0), "ry": -90.0, "st": s1},
		{"p": Vector3(30.0, 0, 24.5), "ry": 180.0, "st": s1},
		{"p": Vector3(8.0, 0, -12.5), "ry": 0.0, "st": s1},
		{"p": Vector3(16.0, 0, -12.5), "ry": 0.0, "st": s1},
		{"p": Vector3(-1.0, 0, -13.5), "ry": 0.0, "st": s3},
		{"p": Vector3(-12.0, 0, -13.5), "ry": 0.0, "st": s3},
		{"p": Vector3(-22.0, 0, -13.5), "ry": 0.0, "st": s3},
		{"p": Vector3(-34.5, 0, 2.0), "ry": 90.0, "st": s3},
		{"p": Vector3(-34.5, 0, 10.0), "ry": 90.0, "st": s3},
		{"p": Vector3(-34.5, 0, 20.0), "ry": 90.0, "st": s2},
		{"p": Vector3(-34.5, 0, 28.0), "ry": 90.0, "st": s2},
		{"p": Vector3(-10.0, 0, 33.5), "ry": 180.0, "st": s2},
		{"p": Vector3(-20.0, 0, 33.5), "ry": 180.0, "st": s2},
		{"p": Vector3(6.0, 0, 30.5), "ry": 180.0, "st": s2},
	]
	for i in range(bg_rows.size()):
		var row: Dictionary = bg_rows[i]
		var st: Node3D = row["st"] as Node3D
		var p: Vector3 = row["p"] as Vector3
		var n: Node3D = _inst(st.get_node("Buildings"), OUT_BG + "PrototypeBackgroundHouse%02d.tscn" % i, "BG_%02d" % i, _yaw(p.x, p.z, float(row["ry"])))
		n.scale = Vector3.ONE
	_inst(city, OUT_ROOT + "PrototypeRoads.tscn", "Roads", Transform3D.IDENTITY)
	_inst(city, OUT_ROOT + "PrototypeBoundaries.tscn", "Boundaries", Transform3D.IDENTITY)
	var gates := Node3D.new()
	gates.name = "DistrictGates"
	city.add_child(gates)
	var gate_ps: PackedScene = load(GATE_SCENE) as PackedScene
	var park: Node3D = gate_ps.instantiate() as Node3D
	park.name = "ParkGate"
	park.transform = _yaw(0.0, 7.2, 0.0)
	park.set("district_id", "park_leisure")
	park.set("display_name", "Парковый барьер")
	park.set("locked_text", "Парковый барьер")
	park.set("barrier_size", Vector3(7, 2.6, 0.28))
	park.set_meta("district_id", "park_leisure")
	gates.add_child(park)
	var ag: Node3D = gate_ps.instantiate() as Node3D
	ag.name = "AgencyGate"
	ag.transform = _yaw(-7.2, 0.0, 90.0)
	ag.set("district_id", "agency_row")
	ag.set("display_name", "Барьер агентства")
	ag.set("locked_text", "Барьер агентства")
	ag.set("barrier_size", Vector3(6.8, 2.6, 0.28))
	ag.set_meta("district_id", "agency_row")
	gates.add_child(ag)
	var agl: Node3D = gate_ps.instantiate() as Node3D
	agl.name = "AgencyGateLeisure"
	agl.transform = _yaw(-21.8, 13.6, 0.0)
	agl.set("district_id", "agency_row")
	agl.set("display_name", "Барьер агентства со стороны Leisure")
	agl.set("locked_text", "Барьер агентства со стороны Leisure")
	agl.set("barrier_size", Vector3(5.4, 2.6, 0.28))
	agl.set_meta("district_id", "agency_row")
	gates.add_child(agl)
	var markers := Node3D.new()
	markers.name = "GlobalMarkers"
	city.add_child(markers)
	_marker(markers, "HomeEntrance", 31.55, 16.5)
	_marker(markers, "CafeEntrance", 24.85, 14.2)
	_marker(markers, "JewelryEntrance", 4.0, 5.3)
	_marker(markers, "GiftEntrance", 13.65, 5.3)
	_marker(markers, "FlowerEntrance", 17.25, 5.3)
	_marker(markers, "InternetCafeEntrance", 5.4, -5.3)
	_marker(markers, "HomewareEntrance", 12.1, -5.3)
	_marker(markers, "ClothingEntrance", 6.8, 5.3)
	_marker(markers, "ParkRestaurantEntrance", 3.2, 20.15)
	_marker(markers, "GymEntrance", -7.5, 13.05)
	_marker(markers, "BookstoreEntrance", -14.2, 13.05)
	_marker(markers, "CinemaEntrance", -26.0, 17.5)
	_marker(markers, "ArcadeEntrance", -26.15, 24.2)
	_marker(markers, "BarEntrance", -16.5, 28.75)
	_marker(markers, "PhotoStudioEntrance", -12.5, -5.3)
	_marker(markers, "AgencyOfficeEntrance", -19.2, -5.3)
	_marker(markers, "BarberEntrance", -24.5, 10.75)
	_marker(markers, "PlayerSpawn", 29.2, 9.0)
	_marker(markers, "ApartmentReturn", 30.8, 16.5)
	_marker(markers, "ParkPicnicSpot", 5.5, 12.0)
	_marker(markers, "BusStop", -30.5, 5.0)
	_marker(markers, "PhotoMark", -12.5, -4.4)
	_marker(markers, "OverviewCamera", 1.0, 8.0)
	(markers.get_node("OverviewCamera") as Node3D).position.y = 48.0
	_marker(markers, "WestBoundary", -38.0, 8.0)
	_marker(markers, "EastBoundary", 38.0, 14.0)
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.22, 0.24, 0.28)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.52, 0.48)
	environment.ambient_light_energy = 0.55
	env.environment = environment
	city.add_child(env)
	var key := DirectionalLight3D.new()
	key.name = "DayKey"
	key.light_energy = 0.85
	key.light_color = Color(1.0, 0.94, 0.86)
	key.rotation_degrees = Vector3(-42, 35, 0)
	city.add_child(key)
	_set_owner_recursive(city, city)
	var packed := PackedScene.new()
	var err: Error = packed.pack(city)
	if err != OK:
		city.free()
		return "CITY_PACK_FAIL %s" % error_string(err)
	err = ResourceSaver.save(packed, CITY_PATH)
	city.free()
	if err != OK:
		return "CITY_SAVE_FAIL %s" % error_string(err)
	return "CITY_SAVED %s" % CITY_PATH


func _hide_node(n: Node) -> void:
	if n == null:
		return
	if n is Node3D:
		(n as Node3D).visible = false
	if n is CollisionObject3D:
		var co: CollisionObject3D = n as CollisionObject3D
		co.collision_layer = 0
		co.collision_mask = 0


func _editor_edited_root() -> Node:
	if not Engine.has_singleton("EditorInterface"):
		return null
	var ei: Object = Engine.get_singleton("EditorInterface")
	if ei != null and ei.has_method("get_edited_scene_root"):
		return ei.call("get_edited_scene_root") as Node
	return null


func _editor_save() -> void:
	if not Engine.has_singleton("EditorInterface"):
		return
	var ei: Object = Engine.get_singleton("EditorInterface")
	if ei != null and ei.has_method("save_scene"):
		ei.call("save_scene")


func _apply_hub_patch(hub: Node) -> void:
	var geom: Node = hub.get_node_or_null("Geometry")
	if geom != null:
		for child in geom.get_children():
			var cname: String = String(child.name)
			if cname == "DonorCity":
				continue
			if cname == "PublicSegment":
				_hide_node(child.get_node_or_null("PublicFloor"))
				_hide_node(child.get_node_or_null("PublicSign"))
				continue
			_hide_node(child)
			for sub in child.get_children():
				_hide_node(sub)
	var spawn: Node3D = hub.get_node_or_null("PlayerSpawns/spawn_default") as Node3D
	if spawn != null:
		spawn.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-20)), Vector3(29.2, 0.05, 9.0))
	var office: Node3D = hub.get_node_or_null("PlayerSpawns/spawn_office") as Node3D
	if office != null:
		office.position = Vector3(-19.2, 0.05, -4.5)
	_move_if(hub, "NpcSpawns/NeighborMentor", Vector3(31.2, 0.05, 15.2))
	_move_if(hub, "NpcSpawns/npc_girl_city_lanyard", Vector3(30.0, 0.05, 12.2))
	_move_if(hub, "NpcSpawns/npc_girl_city_bicycle", Vector3(24.2, 0.05, 12.0))
	_move_if(hub, "NpcSpawns/npc_girl_city_umbrella", Vector3(22.5, 0.05, 11.2))
	_move_if(hub, "NpcSpawns/npc_girl_city_crosswalk", Vector3(25.8, 0.05, 1.5))
	_move_if(hub, "NpcSpawns/npc_rival_city_silent", Vector3(18.0, 0.05, 1.2))
	_move_if(hub, "NpcSpawns/npc_rival_city_tracksuit", Vector3(12.0, 0.05, 2.0))
	_move_if(hub, "NpcSpawns/npc_rival_city_headphones", Vector3(16.0, 0.05, -2.0))
	_move_if(hub, "NpcSpawns/npc_rival_city_thermos", Vector3(-5.0, 0.05, -2.0))
	_move_if(hub, "NpcSpawns/npc_girl_public_sculpture", Vector3(1.5, 0.05, 2.2))
	_move_if(hub, "NpcSpawns/npc_rival_public_coat", Vector3(0.2, 0.05, 2.8))
	_move_if(hub, "NpcSpawns/npc_rival_public_watch", Vector3(-1.0, 0.05, 3.4))
	_move_if(hub, "NpcSpawns/npc_story_scientist", Vector3(-12.5, 0.05, -3.6))
	_move_if(hub, "NpcSpawns/npc_story_scientist_rival", Vector3(-11.2, 0.05, -3.2))
	_move_if(hub, "NpcSpawns/npc_story_president", Vector3(-18.8, 0.05, -3.4))
	_move_if(hub, "NpcSpawns/npc_story_president_rival", Vector3(-20.5, 0.05, -3.2))
	_move_if(hub, "NpcSpawns/npc_rival_mine_boss", Vector3(-17.5, 0.05, -2.4))
	_move_if(hub, "NpcSpawns/npc_girl_mine_boss", Vector3(-18.5, 0.05, -1.8))
	_move_if(hub, "StoryEventPoints/story_point_city_01", Vector3(20.0, 0.05, 8.0))
	_move_if(hub, "StoryEventPoints/story_point_city_public_01", Vector3(0.0, 0.05, 4.2))
	_move_if(hub, "FeatureGates/PublicCityGate", Vector3(0.0, 0.0, 7.2))
	var bollards: Node = hub.get_node_or_null("FeatureGates/PublicCityGate/BarrierBollards")
	if bollards != null:
		_hide_node(bollards)
		for b in bollards.get_children():
			_hide_node(b)
	_move_if(hub, "Transitions/ToApartment", Vector3(31.55, 1.1, 16.5))
	_move_if(hub, "Transitions/ToCafe", Vector3(24.85, 1.1, 14.2))
	_move_if(hub, "Transitions/ToGym", Vector3(-7.5, 1.1, 13.05))
	_move_if(hub, "Transitions/ToAppearance", Vector3(-12.5, 1.1, -5.3))
	_move_if(hub, "Transitions/ToMine", Vector3(-19.2, 1.1, -5.3))
	_move_if(hub, "Transitions/ToLab", Vector3(-15.5, 1.1, -5.05))
	_move_if(hub, "Transitions/ToProduction", Vector3(-21.0, 1.1, -4.05))
	_move_if(hub, "Transitions/ToFinal", Vector3(-30.5, 1.1, 5.0))
	for door_path in [
		"Transitions/ToLab/DoorVisual",
		"Transitions/ToProduction/DoorVisual",
		"Interactables/FlavorPublicSign/PropVisual",
		"Interactables/FlavorTrashBin/PropVisual",
		"Interactables/FlavorMap/PropVisual",
	]:
		var door: Node = hub.get_node_or_null(door_path)
		if door != null:
			door.queue_free()
	_move_if(hub, "Interactables/FlavorBench", Vector3(0.0, 0.45, 1.2))
	_move_if(hub, "Interactables/FlavorPublicSign", Vector3(2.2, 1.2, 3.4))
	_move_if(hub, "Interactables/FlavorTrashBin", Vector3(27.5, 0.5, 7.5))
	_move_if(hub, "Interactables/FlavorSideDoor", Vector3(-15.8, 1.2, -4.4))
	_move_if(hub, "Interactables/FlavorMap", Vector3(30.5, 1.2, 12.5))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightHome", Vector3(32.6, 3.2, 16.5))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightCafe", Vector3(23.8, 3.2, 14.2))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightHall", Vector3(-8.0, 3.2, 12.0))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightAppearance", Vector3(-12.5, 3.2, -4.8))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightOffice", Vector3(-19.2, 3.2, -4.8))
	_move_if(hub, "Geometry/DonorCity/DistrictLights/LightStreet", Vector3(0.0, 3.5, 1.0))
	var media: Node3D = hub.get_node_or_null("Geometry/PublicSegment/MediaAttentionVisuals") as Node3D
	if media != null:
		media.position = Vector3(2.0, 0.0, 8.5)


func _patch_city_hub() -> String:
	var edited: Node = _editor_edited_root()
	if edited != null and String(edited.scene_file_path).ends_with("city_hub.tscn"):
		_apply_hub_patch(edited)
		_editor_save()
		return "HUB_PATCHED_IN_EDITOR"
	var ps: PackedScene = load(HUB_PATH) as PackedScene
	if ps == null:
		return "HUB_LOAD_FAIL"
	var hub: Node3D = ps.instantiate() as Node3D
	_apply_hub_patch(hub)
	_set_owner_recursive(hub, hub)
	var packed := PackedScene.new()
	var err: Error = packed.pack(hub)
	if err != OK:
		hub.free()
		return "HUB_PACK_FAIL %s" % error_string(err)
	err = ResourceSaver.save(packed, HUB_PATH)
	hub.free()
	if err != OK:
		return "HUB_SAVE_FAIL %s" % error_string(err)
	return "HUB_SAVED %s" % HUB_PATH


func _move_if(root: Node, path: String, pos: Vector3) -> void:
	var n: Node3D = root.get_node_or_null(path) as Node3D
	if n != null:
		n.position = pos


