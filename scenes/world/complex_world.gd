extends Node3D
## Builds mutually exclusive locations: home (apartment + unlocked indoor rooms) OR city.
## City scene is flat for now; future districts can nest under City/Districts/MainStreet.

const APARTMENT_SCENE := "res://scenes/world/vertical_slice/apartment.tscn"
const CITY_SCENE := "res://scenes/world/city/city.tscn"
const LAB_SCENE := "res://scenes/art/lab/Clone_Lab_Base.tscn"
## Uniform outdoor scale so ~1.8m characters stop looking giant on street art.
## Applied to the city root only — apartment/home interiors stay unscaled.
const CITY_WORLD_SCALE := 1.5

@onready var rooms_root: Node3D = $Rooms
@onready var props_root: Node3D = $Props
@onready var npcs_root: Node3D = $Npcs

var _built_rooms: Dictionary = {}
var _wanderers: Array[Dictionary] = []
var _city_girls: Array[Dictionary] = []
var _city_data: Dictionary = {}
var _city_nav_source: Dictionary = {}
var _ambient_time: float = 0.0
var _neighbor_girl: Node3D
var _current_location: StringName = &"home"
var _home_zone: StringName = &"apartment" ## apartment | lab | apt_*
var _traveling: bool = false


func _ready() -> void:
	add_to_group("world_root")
	Game.facility.facility_changed.connect(_rebuild)
	Game.girls.girls_changed.connect(_refresh_harem_npcs)
	Game.city.city_changed.connect(_refresh_tutorial_markers)
	Game.city.city_changed.connect(_on_city_districts_changed)
	EventBus.stage_changed.connect(func(_s): _rebuild())
	_add_world_ground()
	# Boot always into the apartment FPS cluster — never lab/city overview.
	_current_location = &"home"
	_home_zone = &"apartment"
	_rebuild()
	call_deferred("_place_player_at_spawn", &"PlayerSpawn")


func _add_world_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "WorldGround"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(220, 1, 120)
	col.shape = shape
	col.position = Vector3(10, -0.6, -5)
	ground.add_child(col)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(220, 1, 120)
	mesh.mesh = box
	mesh.position = Vector3(10, -0.6, -5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.35, 0.28)
	mesh.material_override = mat
	ground.add_child(mesh)
	mesh.visible = false
	add_child(ground)


func _rebuild() -> void:
	_clear_children(rooms_root)
	_clear_children(props_root)
	_clear_children(npcs_root)
	_wanderers.clear()
	_city_girls.clear()
	_city_data.clear()
	_city_nav_source.clear()
	_neighbor_girl = null
	_built_rooms.clear()
	_update_stage_lighting()
	# Mutually exclusive: only home OR city is in the tree/physics at once.
	if _current_location == &"city":
		_build_city()
		_spawn_city_npcs()
		_refresh_tutorial_markers()
	else:
		# Home zones: apartment cluster stays walkable; lab / themed apts load exclusively via travel_to.
		for rid in _home_rooms_for_active_zone():
			_build_room(rid)
		_refresh_harem_npcs()
	# Keep talk-girl meshes visible; only hide true greybox placeholders.
	_hide_placeholder_meshes(npcs_root)


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for c in parent.get_children():
		parent.remove_child(c)
		c.free()


func get_current_location() -> StringName:
	return _current_location


func get_home_zone() -> StringName:
	return _home_zone


func _home_rooms_for_active_zone() -> Array[StringName]:
	## Which unlocked rooms to instantiate for the current home zone.
	var zone := _home_zone
	if zone == &"" or zone == &"home":
		zone = &"apartment"
	var exclusive_zones: Array[StringName] = [&"lab", &"apt_cozy", &"apt_modern", &"apt_creative"]
	var out: Array[StringName] = []
	if exclusive_zones.has(zone):
		if Game.facility.room_unlocked(zone) or zone == &"lab":
			out.append(zone)
		return out
	# Apartment FPS cluster: player apartment + neighbor teleport target + walkable expansions.
	# Lab / themed apartments stay out of the starting overview and load via elevator/travel_to.
	for rid in Game.facility.unlocked_rooms:
		if exclusive_zones.has(rid):
			continue
		out.append(rid)
	if out.is_empty():
		out.append(&"apartment")
	return out


func travel_to(location_id: StringName, spawn_marker: StringName = &"") -> void:
	if _traveling:
		return
	var target := StringName(str(location_id))
	var home_zones: Array[StringName] = [&"home", &"apartment", &"lab", &"apt_cozy", &"apt_modern", &"apt_creative"]
	var is_home_zone := home_zones.has(target)
	if not is_home_zone and target != &"city":
		push_warning("ComplexWorld.travel_to: unknown location '%s'" % location_id)
		return
	if target.begins_with("apt_") and Game.city != null and Game.city.has_method("is_apartment_unlocked"):
		if not bool(Game.city.call("is_apartment_unlocked", target)):
			EventBus.toast("Квартира ещё закрыта", &"warn")
			return
	_traveling = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.set("_date_lock", true)
	var transition: TransitionOverlay = null
	var scene := get_tree().current_scene
	if scene:
		transition = scene.find_child("TransitionOverlay", true, false) as TransitionOverlay
	var mid := func() -> void:
		if target == &"city":
			_current_location = &"city"
			_rebuild()
			_place_player_at_spawn(spawn_marker)
			Sfx.set_zone(&"street")
			Sfx.play(&"door")
		else:
			var zone := target
			if zone == &"home":
				zone = &"apartment"
			var need_rebuild := _current_location != &"home" or not _built_rooms.has(str(zone))
			_current_location = &"home"
			_home_zone = zone
			if need_rebuild:
				_rebuild()
			var marker := spawn_marker
			if str(marker).is_empty():
				marker = &"PlayerSpawn"
			_place_player_at_spawn(marker)
			Sfx.set_zone(&"apartment")
			Sfx.play(&"elevator" if zone != &"apartment" else &"door")
	var unlock := func() -> void:
		_traveling = false
		if is_instance_valid(player):
			player.set("_date_lock", false)
	if transition == null:
		mid.call()
		unlock.call()
		return
	transition.run_blackout(0.32, mid, 0.42, unlock)


func _place_player_at_spawn(spawn_marker: StringName = &"") -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return
	var pos := _resolve_spawn_position(spawn_marker)
	player.global_position = Vector3(pos.x, 0.05, pos.z)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	_ensure_player_camera(player)


func _resolve_spawn_position(spawn_marker: StringName = &"") -> Vector3:
	var marker_name := str(spawn_marker)
	if marker_name.is_empty():
		marker_name = "PlayerSpawn" if _current_location == &"home" else "HomeEntrance"
	if _current_location == &"home":
		var zone_key := str(_home_zone)
		if zone_key == "" or zone_key == "home":
			zone_key = "apartment"
		var zone_root := _built_rooms.get(zone_key) as Node3D
		if zone_root:
			var visual := zone_root.get_node_or_null("ApartmentVisual") as Node3D
			if visual == null:
				visual = zone_root.get_node_or_null("LabVisual") as Node3D
			if visual:
				var m := visual.get_node_or_null("Markers/%s" % marker_name) as Node3D
				if m:
					return m.global_position
			var spawn_n := zone_root.get_node_or_null("PlayerSpawn") as Node3D
			if spawn_n:
				return spawn_n.global_position
			return zone_root.global_position + Vector3(0.0, 0.0, 2.0)
		var apt := _built_rooms.get("apartment") as Node3D
		if apt:
			var av := apt.get_node_or_null("ApartmentVisual") as Node3D
			if av:
				var m2 := av.get_node_or_null("Markers/%s" % marker_name) as Node3D
				if m2:
					return m2.global_position
		return Vector3(-3.6, 0.0, 3.6)
	var city_visual := props_root.find_child("CityVisual", true, false) as Node3D
	if city_visual:
		var m2 := city_visual.get_node_or_null("Markers/%s" % marker_name) as Node3D
		if m2:
			return m2.global_position
	# HomeEntrance street-local (17,0,4.7) under CityVisual offset (-30,0,0), then CITY_WORLD_SCALE.
	return Vector3(-13.0, 0.0, 4.7) * CITY_WORLD_SCALE


func _build_city() -> void:
	var builder: Resource = load("res://scenes/world/city_builder.gd")
	_city_data = builder.build(
		props_root,
		func(parent, pos, title, action, action_id, payload={}, prop_kind=&""):
			_add_interact(parent, pos, title, action, action_id, payload, prop_kind),
		func(parent, size, pos, color):
			_box(parent, size, pos, color),
		func(parent, pos, text):
			_label(parent, pos, text),
	)
	var city_root := _city_data.get("root") as Node3D
	if city_root:
		_hide_generated_visuals(city_root)
		var city_visual := _mount_visual_scene(city_root, CITY_SCENE, "CityVisual", Vector3(-30.0, 0.0, 0.0))
		_hide_placeholder_meshes(city_root)
		_hide_placeholder_meshes(props_root)
		_bind_city_art_interactions(city_root, city_visual)
		_wire_all_district_gates(city_root, city_visual)
		_sync_district_gates(city_visual)
		if Game.city != null and Game.city.has_method("try_unlock_park_from_progress"):
			Game.city.try_unlock_park_from_progress()
		if Game.city != null and Game.city.has_method("try_unlock_agency_row_from_progress"):
			Game.city.try_unlock_agency_row_from_progress()
		_sync_district_gates(city_visual)
		# One coherent outdoor factor: art + interacts + gates under city_root.
		# Nav data from CityBuilder is already in city_root local (manifest + mount offset).
		city_root.scale = Vector3.ONE * CITY_WORLD_SCALE
		_scale_city_nav_data(CITY_WORLD_SCALE)
		_city_nav_source = {
			"waypoints": (_city_data.get("waypoints", []) as Array).duplicate(),
			"waypoint_districts": (_city_data.get("waypoint_districts", []) as Array).duplicate(),
			"spots": (_city_data.get("spots", {}) as Dictionary).duplicate(true),
			"spot_districts": (_city_data.get("spot_districts", {}) as Dictionary).duplicate(true),
		}
		_filter_city_nav_by_districts()


func _bind_city_art_interactions(city_root: Node3D, city_visual: Node3D) -> void:
	## All art-backed city interacts resolve through Marker3D / node anchors.
	var home_p := _marker_local(city_root, city_visual, "Markers/HomeEntrance", Vector3(3.0, 0.0, 17.0))
	_add_interact(city_root, home_p, "Мой дом", "Войти домой", &"go_home", {"art_backed": true}, &"door")
	var cafe_p := _marker_local(city_root, city_visual, "Markers/CafeEntrance", Vector3(-5.5, 0.0, 15.0))
	_add_interact(city_root, cafe_p, "Кафе Two Hearts", "Сесть и ждать свидание", &"sit_cafe", {"art_backed": true}, &"door")
	var flower_p := _marker_local(city_root, city_visual, "Markers/FlowerEntrance", Vector3(-10.0, 0.0, 5.5))
	_add_interact(city_root, flower_p, "Цветочный", "Открыть витрину", &"open_flower_shop", {"art_backed": true}, &"shelf")
	var jewelry_p := _marker_local(city_root, city_visual, "Markers/JewelryEntrance", Vector3(-24.0, 0.0, 5.5))
	_add_interact(city_root, jewelry_p, "Ювелирный", "Открыть витрину", &"open_jewelry_shop", {"art_backed": true}, &"shelf")
	var gift_p := _marker_local(city_root, city_visual, "Markers/GiftEntrance", Vector3(-17.0, 0.0, 5.5))
	_add_interact(city_root, gift_p, "Магазин подарков", "Открыть", &"open_gift_shop", {"art_backed": true}, &"shelf")
	var clothing_p := _marker_local(city_root, city_visual, "Markers/ClothingEntrance", Vector3(-10.0, 0.0, -5.5))
	_add_interact(city_root, clothing_p, "Одежда", "Открыть магазин", &"open_clothing_shop", {"art_backed": true}, &"wardrobe")
	var homeware_p := _marker_local(city_root, city_visual, "Markers/HomewareEntrance", Vector3(-17.0, 0.0, -5.5))
	_add_interact(city_root, homeware_p, "Дом и посуда", "Открыть магазин", &"open_homeware_shop", {"art_backed": true}, &"shelf")
	var net_p := _marker_local(city_root, city_visual, "Markers/InternetCafeEntrance", Vector3(-24.0, 0.0, -5.5))
	_add_interact(city_root, net_p + Vector3(-1.2, 0.0, 0.0), "ПК №1", "Поработать онлайн", &"city_cafe_job", {"art_backed": true}, &"console")
	_add_interact(city_root, net_p + Vector3(1.2, 0.0, 0.0), "ПК №2", "Скроллить (+популярность)", &"city_cafe_scroll", {"art_backed": true}, &"console")
	_add_interact(city_root, net_p + Vector3(0.0, 0.0, 1.0), "Кофейня", "Купить кофе (+внимание)", &"city_coffee", {"art_backed": true}, &"desk")
	var picnic_p := _marker_local(city_root, city_visual, "Markers/ParkPicnicSpot", Vector3(-23.5, 0.0, 11.5))
	var rest_p := _marker_local(city_root, city_visual, "Markers/ParkRestaurantEntrance", Vector3(-18.5, 0.0, 22.0))
	_add_interact(city_root, picnic_p, "Пикник в парке", "Сесть и ждать свидание", &"sit_park", {"art_backed": true}, &"desk")
	_add_interact(city_root, rest_p, "Ресторан у парка", "Сесть и ждать свидание", &"sit_restaurant", {"art_backed": true}, &"door")
	var gym_p := _marker_local(city_root, city_visual, "Markers/GymEntrance", Vector3(-36.0, 0.0, 12.5))
	var book_p := _marker_local(city_root, city_visual, "Markers/BookstoreEntrance", Vector3(-43.5, 0.0, 12.5))
	var cine_p := _marker_local(city_root, city_visual, "Markers/CinemaEntrance", Vector3(-57.0, 0.0, 17.0))
	var arcade_p := _marker_local(city_root, city_visual, "Markers/ArcadeEntrance", Vector3(-57.0, 0.0, 24.5))
	_add_interact(city_root, gym_p, "Фитнес Leisure", "Тренировка (UI)", &"city_workout", {"art_backed": true}, &"machine")
	_add_interact(city_root, gym_p + Vector3(-1.2, 0.0, 0.8), "Абонемент Leisure", "Купить (+макс. внимание)", &"city_gym_pass", {"art_backed": true}, &"poster")
	_add_interact(city_root, book_p, "Книжный Leisure", "Открыть витрину", &"open_bookstore", {"art_backed": true}, &"shelf")
	_add_interact(city_root, cine_p, "Кинотеатр Leisure", "Сесть и ждать сеанс", &"sit_cinema", {"art_backed": true}, &"door")
	_add_interact(city_root, arcade_p, "Аркада Перегруз", "Сыграть / свидание", &"open_arcade", {"art_backed": true}, &"console")
	_add_interact(city_root, arcade_p + Vector3(1.0, 0.0, 0.0), "Аркада (свидание)", "Сесть к автомату", &"sit_arcade", {"art_backed": true}, &"console")
	var bar_p := _marker_local(city_root, city_visual, "Markers/BarEntrance", Vector3(-46.0, 0.0, 29.5))
	_add_interact(city_root, bar_p, "Ночной бар", "Выпить (−$ +скандал/⭐)", &"city_bar_drink", {"art_backed": true}, &"desk")
	var photo_p := _marker_local(city_root, city_visual, "Markers/PhotoStudioEntrance", Vector3(-43.0, 0.0, -5.5))
	var barber_p := _marker_local(city_root, city_visual, "Markers/BarberEntrance", Vector3(-55.0, 0.0, 11.5))
	var agency_p := _marker_local(city_root, city_visual, "Markers/AgencyOfficeEntrance", Vector3(-51.0, 0.0, -5.5))
	_add_interact(city_root, photo_p, "Фотостудия Agency", "Сессия / публикация", &"open_photo_studio", {"art_backed": true, "venue_id": "photo_studio"}, &"poster")
	_add_interact(city_root, barber_p, "Барбер Agency", "Стрижка / стиль", &"open_barber", {"art_backed": true}, &"desk")
	_add_interact(city_root, agency_p, "Офис агентства", "Доска расписания", &"open_agency_board", {"art_backed": true}, &"console")
	var bus_p := _marker_local(city_root, city_visual, "Markers/BusStop", Vector3(-61.0, 0.0, 5.0))
	_add_interact(city_root, bus_p, "Расписание", "Посмотреть маршруты", &"city_bus_info", {"art_backed": true}, &"poster")
	_add_interact(city_root, bus_p + Vector3(1.2, 0.0, 0.0), "Автомат", "Купить сувенир-конфеты", &"city_buy_gift", {"gift_id": "candy", "discount": 1.0, "art_backed": true}, &"machine")
	var main_bench_p := _node_local(city_root, city_visual, "POIs/MainBench", Vector3(-28.2, 0.0, 1.5))
	_add_interact(city_root, main_bench_p, "Скамейка", "Отдохнуть (+внимание)", &"city_rest", {"art_backed": true}, &"desk")
	var park_bench_p := _node_local(city_root, city_visual, "POIs/ParkBench", Vector3(-34.5, 0.0, 22.5))
	_add_interact(city_root, park_bench_p, "Скамейка в парке", "Посидеть", &"city_rest", {"bonus": 1.5, "art_backed": true}, &"desk")
	var duck_p := _node_local(city_root, city_visual, "POIs/DuckFeeding", Vector3(-23.5, 0.0, 17.0))
	_add_interact(city_root, duck_p, "Кормушка", "Покормить уток (+⭐)", &"city_park_fun", {"art_backed": true}, &"shelf")
	var karaoke_p := _node_local(city_root, city_visual, "POIs/KaraokeStand", Vector3(-38.5, 0.0, 25.0))
	_add_interact(city_root, karaoke_p, "Караоке", "Спеть (+⭐ +скандал)", &"city_karaoke", {"art_backed": true}, &"console")


func _node_local(parent: Node3D, visual: Node3D, rel_path: String, fallback: Vector3) -> Vector3:
	if parent == null or visual == null:
		return fallback
	var node := visual.get_node_or_null(rel_path) as Node3D
	if node == null:
		return fallback
	return parent.to_local(node.global_position)


func _sync_district_gates(city_visual: Node3D) -> void:
	if city_visual == null:
		return
	var park_open: bool = Game.city != null and Game.city.is_district_unlocked(CityDistricts.PARK_LEISURE)
	var agency_open: bool = Game.city != null and Game.city.is_district_unlocked(CityDistricts.AGENCY_ROW)
	var gates: Array = city_visual.get_tree().get_nodes_in_group("district_gate")
	for gate_v in gates:
		var gate: Node3D = gate_v as Node3D
		if gate == null or not city_visual.is_ancestor_of(gate):
			continue
		var district_id: String = ""
		if gate.has_meta("district_id"):
			district_id = str(gate.get_meta("district_id"))
		else:
			var prop_v: Variant = gate.get("district_id")
			if typeof(prop_v) == TYPE_STRING or typeof(prop_v) == TYPE_STRING_NAME:
				district_id = str(prop_v)
		var open: bool = false
		if district_id == String(CityDistricts.PARK_LEISURE) or district_id == "park_leisure":
			open = park_open
		elif district_id == String(CityDistricts.AGENCY_ROW) or district_id == "agency_row":
			open = agency_open
		_apply_district_gate(gate, open)


func _apply_district_gate(gate: Node3D, open: bool) -> void:
	if gate.has_method("set_unlocked"):
		gate.call("set_unlocked", open)
	else:
		gate.visible = not open
		_style_district_barrier(gate)
		for child in gate.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = open
			elif child is CollisionObject3D:
				(child as CollisionObject3D).set_collision_layer_value(1, not open)
				for cs in child.get_children():
					if cs is CollisionShape3D:
						(cs as CollisionShape3D).disabled = open
		if gate is CollisionObject3D:
			(gate as CollisionObject3D).set_collision_layer_value(1, not open)
	_style_district_barrier(gate)
	var probe: Node = gate.get_meta("gate_interact", null) as Node
	if probe != null and is_instance_valid(probe):
		probe.visible = not open
		var probe_cs := probe.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if probe_cs == null:
			for c in probe.get_children():
				if c is CollisionShape3D:
					probe_cs = c as CollisionShape3D
					break
		if probe_cs != null:
			probe_cs.disabled = open
		if probe is CollisionObject3D:
			(probe as CollisionObject3D).monitoring = not open
			(probe as CollisionObject3D).monitorable = not open


func _style_district_barrier(gate: Node3D) -> void:
	## Prefer DistrictGate script styling (Stage 5 low-opacity + focus label).
	if gate.has_method("_style_locked"):
		gate.call("_style_locked")
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.62, 0.98, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.30, 0.55, 1.0)
	mat.emission_energy_multiplier = 0.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var barrier := gate.get_node_or_null("BarrierMesh") as MeshInstance3D
	if barrier != null:
		barrier.material_override = mat
	for child in gate.get_children():
		if child is CSGShape3D:
			(child as CSGShape3D).material = mat
		elif child is MeshInstance3D and child.name.begins_with("Barrier"):
			(child as MeshInstance3D).material_override = mat
	var label := gate.get_node_or_null("ConditionLabel") as Label3D
	if label == null:
		label = gate.get_node_or_null("SoonLabel") as Label3D
	if label != null:
		label.visible = false


func _wire_all_district_gates(city_root: Node3D, city_visual: Node3D) -> void:
	if city_root == null or city_visual == null:
		return
	var gates: Array = city_visual.get_tree().get_nodes_in_group("district_gate")
	# Fallback for packed instances that have not entered group yet.
	if gates.is_empty():
		for path in ["Decor/ParkGate", "Decor/AgencyGate", "Decor/AgencyGateLeisure"]:
			var g := city_visual.get_node_or_null(path) as Node3D
			if g != null:
				g.add_to_group("district_gate")
				gates.append(g)
	for gate_v in gates:
		var gate: Node3D = gate_v as Node3D
		if gate == null or not city_visual.is_ancestor_of(gate):
			continue
		var district_id: String = "park_leisure"
		if gate.has_meta("district_id"):
			district_id = str(gate.get_meta("district_id"))
		var title: String = gate.name
		var cond := gate.get_node_or_null("ConditionLabel") as Label3D
		if cond != null and cond.text != "":
			title = cond.text
		_wire_district_gate_interact_node(city_root, gate, StringName(district_id), title)


func _wire_district_gate_interact_node(city_root: Node3D, gate: Node3D, district_id: StringName, title: String) -> void:
	if city_root == null or gate == null:
		return
	if gate.has_meta("gate_interact") and is_instance_valid(gate.get_meta("gate_interact")):
		return
	var local_pos: Vector3 = city_root.to_local(gate.global_position)
	var anchor := gate.get_node_or_null("InteractAnchor") as Node3D
	if anchor != null:
		local_pos = city_root.to_local(anchor.global_position)
	else:
		## Approach from local -Z (street side of prefab).
		var offset: Vector3 = gate.global_transform.basis * Vector3(0.0, 0.0, -1.4)
		local_pos = city_root.to_local(gate.global_position + offset)
	var area: Interactable = Interactable.new()
	area.name = "GateProbe_%s_%s" % [str(district_id), gate.name]
	area.display_name = title
	area.action_label = "Осмотреть район"
	area.action_id = &"inspect_district_gate"
	area.payload = {"district_id": str(district_id), "art_backed": true}
	area.position = Vector3(local_pos.x, 0.0, local_pos.z)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 2.2, 2.4)
	cs.shape = shape
	cs.position = Vector3(0, 1.1, 0)
	area.add_child(cs)
	city_root.add_child(area)
	gate.set_meta("gate_interact", area)


func _filter_city_nav_by_districts() -> void:
	## NPCs only use waypoints/spots in currently unlocked districts.
	if _city_nav_source.is_empty():
		return
	var park_open: bool = Game.city != null and Game.city.is_district_unlocked(CityDistricts.PARK_LEISURE)
	var agency_open: bool = Game.city != null and Game.city.is_district_unlocked(CityDistricts.AGENCY_ROW)
	var wp_districts: Array = _city_nav_source.get("waypoint_districts", []) as Array
	var waypoints: Array = _city_nav_source.get("waypoints", []) as Array
	var filtered_wp: Array = []
	var filtered_wp_d: Array = []
	for i in range(waypoints.size()):
		var district: String = "main_street"
		if i < wp_districts.size():
			district = str(wp_districts[i])
		if district == "park_leisure" and not park_open:
			continue
		if district == "agency_row" and not agency_open:
			continue
		filtered_wp.append(waypoints[i])
		filtered_wp_d.append(district)
	if not filtered_wp.is_empty():
		_city_data["waypoints"] = filtered_wp
		_city_data["waypoint_districts"] = filtered_wp_d

	var spots: Dictionary = _city_nav_source.get("spots", {}) as Dictionary
	var spot_districts: Dictionary = _city_nav_source.get("spot_districts", {}) as Dictionary
	var filtered_spots: Dictionary = {}
	for key_v in spots.keys():
		var key: String = str(key_v)
		var district: String = str(spot_districts.get(key, "main_street"))
		if district == "park_leisure" and not park_open:
			continue
		if district == "agency_row" and not agency_open:
			continue
		filtered_spots[key] = spots[key]
	_city_data["spots"] = filtered_spots


func _marker_pos(visual: Node3D, rel_path: String, fallback: Vector3) -> Vector3:
	if visual == null:
		return fallback
	var marker := visual.get_node_or_null(rel_path) as Node3D
	if marker == null:
		return fallback
	return marker.position


func _marker_local(parent: Node3D, visual: Node3D, rel_path: String, fallback: Vector3) -> Vector3:
	if parent == null or visual == null:
		return fallback
	var marker := visual.get_node_or_null(rel_path) as Node3D
	if marker == null:
		return fallback
	return parent.to_local(marker.global_position)


func _scale_city_nav_data(factor: float) -> void:
	## NPCs live under npcs_root (not city_root), so waypoints/spots must match city scale.
	if is_equal_approx(factor, 1.0):
		return
	var waypoints: Array = _city_data.get("waypoints", [])
	for i in range(waypoints.size()):
		var wp: Vector3 = waypoints[i]
		waypoints[i] = wp * factor
	_city_data["waypoints"] = waypoints
	var spots: Dictionary = _city_data.get("spots", {})
	for key in spots.keys():
		var arr: Array = spots[key]
		for i in range(arr.size()):
			var p: Vector3 = arr[i]
			arr[i] = p * factor
		spots[key] = arr
	_city_data["spots"] = spots


func _mount_visual_scene(parent: Node3D, scene_path: String, node_name: String, local_position: Vector3 = Vector3.ZERO) -> Node3D:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("Visual scene missing: %s" % scene_path)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("Visual scene root must be Node3D: %s" % scene_path)
		return null
	instance.name = node_name
	instance.position = local_position
	parent.add_child(instance)
	for node: Node in instance.find_children("*", "WorldEnvironment", true, false):
		var world := node as WorldEnvironment
		if world:
			world.environment = null
	for node: Node in instance.find_children("*", "DirectionalLight3D", true, false):
		var light := node as DirectionalLight3D
		if light:
			light.visible = false
	# Art TechCameras ship current=true (elevated overview). Never steal the player FPS camera.
	for node: Node in instance.find_children("*", "Camera3D", true, false):
		var cam := node as Camera3D
		if cam:
			cam.current = false
			cam.set_process(false)
			cam.set_physics_process(false)
	_tone_down_slice_lights(instance)
	return instance


func _ensure_player_camera(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	var cam := player.get_node_or_null("Head/Camera3D") as Camera3D
	if cam == null:
		cam = player.find_child("Camera3D", true, false) as Camera3D
	if cam:
		cam.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _tone_down_slice_lights(root: Node = null) -> void:
	var scope: Node = root if root != null else self
	for node: Node in scope.find_children("*", "OmniLight3D", true, false):
		var omni := node as OmniLight3D
		if omni == null:
			continue
		var c := omni.light_color
		if c.r > 0.75 and c.b > 0.45 and c.g < 0.55:
			omni.light_color = Color(1.0, 0.82, 0.64)
			omni.light_energy = minf(omni.light_energy, 0.85)
		else:
			omni.light_energy = minf(omni.light_energy, 1.15)
	for node2: Node in scope.find_children("*", "SpotLight3D", true, false):
		var spot := node2 as SpotLight3D
		if spot:
			spot.light_energy = minf(spot.light_energy, 2.4)


func _hide_generated_visuals(parent: Node3D) -> void:
	var stack: Array[Node] = [parent]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node.name == "CityVisual" or node.name == "StreetVisual" or node.name == "ApartmentVisual":
			continue
		if node is MeshInstance3D or node is Label3D or node is CSGShape3D:
			(node as Node3D).visible = false
		for child in node.get_children():
			stack.append(child)


func _hide_placeholder_meshes(parent: Node3D) -> void:
	for node: Node in parent.find_children("*", "MeshInstance3D", true, false):
		if not is_instance_valid(node) or not node.is_inside_tree():
			continue
		var path_s := String(node.get_path())
		if path_s.contains("CityVisual") or path_s.contains("StreetVisual") or path_s.contains("ApartmentVisual"):
			continue
		# Procedural city/harem girls use Capsule/Sphere meshes — keep them visible.
		if _is_girl_actor_mesh(node):
			continue
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		var mesh := mi.mesh
		if mesh is CapsuleMesh or mesh is BoxMesh or mesh is SphereMesh:
			mi.visible = false
			continue
		var mat := mi.material_override as StandardMaterial3D
		if mat != null and mat.albedo_color.r > 0.85 and mat.albedo_color.b > 0.55 and mat.albedo_color.g < 0.55:
			mi.visible = false
	for label: Node in parent.find_children("*", "Label3D", true, false):
		if not is_instance_valid(label) or not label.is_inside_tree():
			continue
		var lpath := String(label.get_path())
		if lpath.contains("CityVisual") or lpath.contains("StreetVisual") or lpath.contains("ApartmentVisual"):
			continue
		if _is_girl_actor_mesh(label):
			continue
		(label as Label3D).visible = false


func _is_girl_actor_mesh(node: Node) -> bool:
	var cur: Node = node
	while cur != null:
		if cur is GirlCharacter:
			return true
		var n := String(cur.name)
		if n.begins_with("Girl_") or n == "NeighborNPC":
			return true
		cur = cur.get_parent()
	return false


func _update_stage_lighting() -> void:
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun == null:
		return
	var stage_number := int(str(Game.stage_id).trim_prefix("stage_"))
	if stage_number >= 5:
		sun.light_color = Color(0.62, 0.74, 1.0)
		sun.light_energy = 0.42
	else:
		# Warm evening without magenta wash.
		sun.light_color = Color(1.0, 0.82, 0.68)
		sun.light_energy = 0.28
	_tone_down_slice_lights()


func _process(delta: float) -> void:
	_ambient_time += delta
	for machine in get_tree().get_nodes_in_group("ambient_machine"):
		if machine is Node3D and is_instance_valid(machine):
			var visuals := (machine as Node3D).get_node_or_null("Visuals") as Node3D
			if visuals:
				visuals.rotation.y += delta * 0.55
	_move_agents(delta, _wanderers, 0.85)
	_move_city_girls(delta)


func _move_agents(delta: float, list: Array, speed: float) -> void:
	for i in range(list.size()):
		var entry: Dictionary = list[i]
		var node := entry.get("node") as Node3D
		var waypoints: Array = entry.get("waypoints", [])
		if node == null or not is_instance_valid(node) or waypoints.is_empty():
			continue
		var pause: float = float(entry.get("pause", 0))
		if pause > 0.0:
			entry["pause"] = pause - delta
			list[i] = entry
			continue
		var target: Vector3 = waypoints[int(entry.get("index", 0))]
		var next := node.global_position.move_toward(target, delta * speed)
		node.global_position = next
		if node.has_method("face_toward"):
			node.call("face_toward", target)
		elif node is Interactable:
			var g: Node = null
			for c in node.get_children():
				if c.has_method("face_toward"):
					g = c
					break
			if g:
				var dir := (target - node.global_position).normalized()
				g.call("face_toward", node.global_position + dir)
		if node.global_position.distance_to(target) < 0.1:
			entry["index"] = (int(entry.get("index", 0)) + 1) % waypoints.size()
			entry["pause"] = randf_range(0.4, 2.2)
			list[i] = entry


func _move_city_girls(delta: float) -> void:
	_move_agents(delta, _city_girls, 1.1)


func _spawn_city_npcs() -> void:
	var spots: Dictionary = _city_data.get("spots", {})
	var waypoints: Array = _city_data.get("waypoints", [])
	if waypoints.is_empty():
		return
	# Decorative male wanderers are hidden for the vertical slice presentation.
	for i in range(0):
		var w := MeshInstance3D.new()
		w.name = "Citizen_%d" % (i + 1)
		var cap := CapsuleMesh.new()
		cap.radius = 0.2
		cap.height = 1.3
		w.mesh = cap
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.35 + 0.08 * i, 0.55)
		w.material_override = mat
		var path: Array = []
		for j in range(3):
			path.append(waypoints[(i * 3 + j) % waypoints.size()])
		# Attach before assigning global transforms to avoid invalid scene-tree access.
		npcs_root.add_child(w)
		w.global_position = path[0] + Vector3(0, 0.65, 0)
		# Raise visual: store floor waypoints but offset mesh
		var raised: Array = []
		for p in path:
			raised.append(Vector3(p.x, 0.65, p.z))
		_wanderers.append({"node": w, "waypoints": raised, "index": 1, "pause": 0.0})

	var profiles: Array = Game.city.profiles_for_spawn()
	var count := mini(12, profiles.size())
	for i in range(count):
		var profile: Dictionary = profiles[i]
		_spawn_talk_girl(profile, spots, waypoints, i == 0)


func _spawn_talk_girl(profile: Dictionary, spots: Dictionary, waypoints: Array, prefer_plaza: bool) -> void:
	var id := str(profile.get("id", ""))
	var home := str(profile.get("home_spot", "street_plaza"))
	var spawn := Vector3(-12, 0, 0) * CITY_WORLD_SCALE
	if prefer_plaza and id == "city_cashier":
		spawn = Vector3(-12.5, 0, 1.2) * CITY_WORLD_SCALE
	elif spots.has(home) and not (spots[home] as Array).is_empty():
		var arr: Array = spots[home]
		spawn = arr[randi() % arr.size()]
	elif not waypoints.is_empty():
		spawn = waypoints[randi() % waypoints.size()]

	var area := Interactable.new()
	area.name = "Girl_%s" % id
	area.display_name = str(profile.get("name", id))
	area.action_label = "Заговорить"
	area.action_id = &"talk_girl"
	area.payload = {"girl_id": id}
	area.position = Vector3(spawn.x, 0.0, spawn.z)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.55, 1.8, 0.55)
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	area.add_child(cs)

	var girl := _make_girl()
	area.add_child(girl)
	npcs_root.add_child(area)
	var skin_a: Array = profile.get("color", [0.95, 0.75, 0.7])
	var hair_a: Array = profile.get("hair_color", [0.2, 0.1, 0.08])
	if bool(profile.get("unique", false)):
		if girl.has_method("apply_from_content"):
			girl.call("apply_from_content", StringName(id), str(profile.get("name", "")))
	elif girl.has_method("apply_profile"):
		girl.call("apply_profile", {
			"id": id,
			"display_name": str(profile.get("name", id)),
			"skin": Color(float(skin_a[0]), float(skin_a[1]), float(skin_a[2])),
			"outfit_tint": Color(float(skin_a[0]), float(skin_a[1]), float(skin_a[2])).darkened(0.2),
			"hair_style": str(profile.get("hair_style", "bob")),
			"hair_color": Color(float(hair_a[0]), float(hair_a[1]), float(hair_a[2])) if hair_a.size() >= 3 else Color(0.2, 0.1, 0.08),
		})



	var path: Array = [Vector3(spawn.x, 0, spawn.z)]
	if spots.has(home):
		for p in spots[home]:
			path.append(Vector3(p.x, 0, p.z))
	for j in range(2):
		if not waypoints.is_empty():
			var wp: Vector3 = waypoints[randi() % waypoints.size()]
			path.append(Vector3(wp.x, 0, wp.z))
	_city_girls.append({"node": area, "girl": girl, "waypoints": path, "index": 1, "pause": randf() * 1.5, "id": id})


func _on_city_districts_changed() -> void:
	if _current_location != &"city":
		return
	var city_visual := props_root.find_child("CityVisual", true, false) as Node3D
	_sync_district_gates(city_visual)
	_filter_city_nav_by_districts()


func _refresh_tutorial_markers() -> void:
	var tid := str(Game.city.tutorial_target_id)
	for entry in _city_girls:
		var g: Node = entry.get("girl") as Node
		if g == null:
			continue
		if g != null and g.has_method("set_tutorial_marker"):
			g.call("set_tutorial_marker", tid != "" and str(entry.get("id", "")) == tid)


func _build_room(room_id: StringName) -> void:
	var def: Dictionary = ContentDB.room(room_id)
	var pos_a: Array = def.get("pos", [0, 0, 0])
	var origin := Vector3(float(pos_a[0]), float(pos_a[1]), float(pos_a[2]))
	var root := Node3D.new()
	root.name = str(room_id)
	root.position = origin
	rooms_root.add_child(root)
	_built_rooms[str(room_id)] = root
	match str(room_id):
		"apartment":
			var apt_visual := _mount_visual_scene(root, APARTMENT_SCENE, "ApartmentVisual")
			# Leftover gift shelf mesh from old prep flow — hide without rewriting apartment.tscn.
			if apt_visual:
				var gift_shelf := apt_visual.get_node_or_null("Furniture/GiftShelf") as Node3D
				if gift_shelf:
					gift_shelf.visible = false
			# Snap interact volumes to real furniture nodes (markers can lag behind art moves).
			var bed_p: Vector3 = _marker_pos(apt_visual, "Furniture/Bed", Vector3(4.15, 0, -3.65))
			var wardrobe_p: Vector3 = _marker_pos(apt_visual, "Furniture/Wardrobe", Vector3(5.05, 0, 0.95))
			var fridge_p: Vector3 = _marker_pos(apt_visual, "Furniture/Fridge", Vector3(-2.05, 0, -2.15))
			var drawers_p: Vector3 = _marker_pos(apt_visual, "Furniture/KitchenDrawers", Vector3(-1.35, 0, -2.15))
			var table_p: Vector3 = _marker_pos(apt_visual, "Furniture/DiningTable", Vector3(0.65, 0, 0.55))
			var exit_p: Vector3 = _marker_pos(apt_visual, "Markers/ApartmentExit", Vector3(-1.9, 0, 0.25))
			var night_p: Vector3 = _marker_pos(apt_visual, "Furniture/NightStand", Vector3(5.15, 0, -2.7))
			var neighbor_p: Vector3 = _marker_pos(apt_visual, "Markers/NeighborDoorAnchor", Vector3(-1.5, 0, 1.95))
			var bed_i: Interactable = _add_interact(root, bed_p, "Кровать / Работа", "Поработать", &"job", {}, &"bed")
			var wardrobe_i: Interactable = _add_interact(root, wardrobe_p, "Шкаф", "Сменить одежду", &"wardrobe", {}, &"wardrobe")
			# Fridge = food menu only; KitchenDrawers = drink menu only (no separate water/wine/snack points).
			# Homeware upgrades: city shop «Дом и посуда» (open_homeware_shop) — not an apartment interact.
			var fridge_i: Interactable = _add_interact(root, fridge_p, "Холодильник", "Выбрать еду", &"take_food", {}, &"shelf")
			var drawers_i: Interactable = _add_interact(root, drawers_p, "Кухонные ящики", "Выбрать напиток", &"take_drink", {}, &"shelf")
			var table_i: Interactable = _add_interact(root, table_p, "Кухонный стол", "Положить / сесть / начать", &"prepare_and_start", {}, &"table_set")
			# Doorbell removed: home dates start at the table after sit/wait.
			var phone_i: Interactable = _add_interact(root, night_p, "Телефон на тумбе", "Открыть", &"phone", {}, &"phone_stand")
			_add_interact(root, wardrobe_p + Vector3(0.7, 0, -0.8), "Дверь расширения", "Расширить", &"expand", {}, &"door")
			var exit_i: Interactable = _add_interact(root, exit_p, "На улицу", "Выйти в город", &"go_outside", {}, &"door")
			var neighbor_i: Interactable = _add_interact(root, neighbor_p, "К соседке", "Постучать", &"go_neighbor", {}, &"door")
			var elev_p: Vector3 = exit_p + Vector3(0.15, 0, 1.15)
			_add_interact(root, elev_p, "Лифт", "Выбрать этаж", &"open_elevator", {}, &"door")
			var basement_p: Vector3 = fridge_p + Vector3(-1.2, 0, 1.0)
			_add_interact(root, basement_p, "Подвал / лаборатория", "Спуститься в лаб", &"go_lab", {}, &"door")
			_bind_interact_outline(bed_i, apt_visual, "Furniture/Bed")
			_bind_interact_outline(wardrobe_i, apt_visual, "Furniture/Wardrobe")
			_bind_interact_outline(fridge_i, apt_visual, "Furniture/Fridge")
			_bind_interact_outline(drawers_i, apt_visual, "Furniture/KitchenDrawers")
			_bind_interact_outline(table_i, apt_visual, "Furniture/DiningTable")
			_bind_interact_outline(phone_i, apt_visual, "Furniture/NightStand")
			_bind_interact_outline(exit_i, apt_visual, "Furniture/ExitDoor")
			_bind_interact_outline(neighbor_i, apt_visual, "Furniture/NeighborDoor")
			_assert_apartment_kitchen_interact_clearance(fridge_i, drawers_i)
		"neighbor_apt":
			_box(root, Vector3(7, 0.2, 7), Vector3(0, -0.1, 0), Color(0.6, 0.52, 0.55))
			_wall_room(root, 7, 7, 2.6)
			_label(root, Vector3(0, 2.4, -3.0), "Квартира соседки")
			_add_interact(root, Vector3(-2.0, 0, -2.0), "Кровать соседки", "Посмотреть", &"neighbor_look", {}, &"bed")
			_add_interact(root, Vector3(2.0, 0, 1.5), "Столик", "Осмотреть", &"neighbor_look", {}, &"desk")
			_add_interact(root, Vector3(0, 0, 3.2), "К себе домой", "Вернуться", &"go_home_from_neighbor", {}, &"door")
			_spawn_neighbor_npc(root)
		"office_nook":
			_box(root, Vector3(6, 0.2, 6), Vector3(0, -0.1, 0), Color(0.45, 0.5, 0.55))
			_wall_room(root, 6, 6, 2.6)
			_label(root, Vector3(0, 2.4, -2.5), "Рабочий уголок")
			_add_interact(root, Vector3(0, 1, 0), "Стол переписки", "Нанять менеджера", &"hire", {"role_id": "messenger"}, &"desk")
			_add_interact(root, Vector3(2, 1, 1), "Афиша кафе", "Открыть кафе", &"open_venue_upgrade", {"venue_id": "cheap_cafe"}, &"poster")
			_add_interact(root, Vector3(-2, 1, 1), "Карта парка", "Открыть парк", &"open_venue_upgrade", {"venue_id": "park"}, &"poster")
		"agency":
			_box(root, Vector3(12, 0.2, 10), Vector3(0, -0.1, 0), Color(0.4, 0.45, 0.5))
			_wall_room(root, 12, 10, 3.0)
			_label(root, Vector3(0, 2.8, -4.5), "Агентство")
			_add_interact(root, Vector3(-4, 1, -2), "Гардеробная", "Сменить одежду", &"wardrobe", {}, &"wardrobe")
			_add_interact(root, Vector3(-4, 1, 2), "Склад", "Купить конфеты", &"buy_gift", {"gift_id": "candy"}, &"shelf")
			_add_interact(root, Vector3(0, 0, 0), "Зал свиданий", "Подготовить стол и начать свидание", &"prepare_and_start", {}, &"table_set")
			_add_interact(root, Vector3(4, 1, -2), "Найм стилиста", "Нанять", &"hire", {"role_id": "stylist"}, &"desk")
			_add_interact(root, Vector3(4, 1, 2), "Лаб. подготовка", "Улучшение науки", &"buy_upgrade", {"upgrade_id": "ward_style_science"}, &"machine")
			_add_interact(root, Vector3(0, 1, 3), "К штабу+", "Расширить", &"expand", {}, &"door")
			_orbit_culture_props(root, Vector3(0, 1.6, -3.8))
		"lab":
			_build_lab_room(root)
		"apt_cozy":
			_build_themed_apartment(root, "Уют", Color(0.72, 0.55, 0.42), Color(0.85, 0.7, 0.55))
		"apt_modern":
			_build_themed_apartment(root, "Модерн", Color(0.35, 0.38, 0.42), Color(0.55, 0.6, 0.65))
		"apt_creative":
			_build_themed_apartment(root, "Креатив", Color(0.55, 0.35, 0.65), Color(0.9, 0.45, 0.55))
		"mansion":
			_box(root, Vector3(14, 0.2, 12), Vector3(0, -0.1, 0), Color(0.55, 0.45, 0.4))
			_wall_room(root, 14, 12, 3.2)
			_label(root, Vector3(0, 3.0, -5.5), "Особняк")
			_add_interact(root, Vector3(-5, 1, -3), "Лаборатория клонов", "Создать клона", &"create_clone", {}, &"machine")
			_add_interact(root, Vector3(-5, 1, 0), "Техник", "Нанять техника", &"hire", {"role_id": "tech"}, &"desk")
			_add_interact(root, Vector3(-5, 1, 3), "Координатор", "Нанять", &"hire", {"role_id": "coordinator"}, &"desk")
			_add_interact(root, Vector3(0, 1, 0), "Автолинии", "Включить авто", &"toggle_auto", {}, &"console")
			_add_interact(root, Vector3(5, 1, -3), "Закупщик", "Нанять", &"hire", {"role_id": "buyer"}, &"shelf")
			_add_interact(root, Vector3(5, 1, 0), "Фотостудия", "Открыть", &"open_venue_upgrade", {"venue_id": "photo_studio"}, &"poster")
			_add_interact(root, Vector3(5, 1, 3), "Капсула", "Открыть", &"open_venue_upgrade", {"venue_id": "lab_capsule"}, &"machine")
			_add_interact(root, Vector3(0, 1, 4.5), "К фабрике", "Расширить", &"expand", {}, &"door")
			_spawn_harem_slots(root)
			_orbit_culture_props(root, Vector3(-2, 1.8, -4.5))
		"factory":
			_box(root, Vector3(18, 0.2, 14), Vector3(0, -0.1, 0), Color(0.35, 0.35, 0.4))
			_wall_room(root, 18, 14, 4.0)
			_label(root, Vector3(0, 3.6, -6.5), "Фабрика свиданий")
			_add_interact(root, Vector3(-6, 1, 0), "Фабрика подарков", "Крафт+", &"buy_upgrade", {"upgrade_id": "gift_craft"}, &"machine")
			_add_interact(root, Vector3(-3, 1, 0), "Конвейер", "Открыть", &"buy_upgrade", {"upgrade_id": "venue_conveyor"}, &"console")
			_add_interact(root, Vector3(0, 1, 0), "PR-отдел", "Нанять PR", &"hire", {"role_id": "pr"}, &"desk")
			_add_interact(root, Vector3(3, 1, 0), "Центр управления", "Авто+", &"toggle_auto", {}, &"console")
			_add_interact(root, Vector3(6, 1, 0), "Сбой линии", "Устранить", &"fix_device", {}, &"machine")
			_add_interact(root, Vector3(0, 1, 5), "К орбите", "Расширить", &"expand", {}, &"door")
			for i in range(8):
				_mannequin(root, Vector3(-7 + i * 2.0, 1, 4), Color(0.6, 0.6, 0.7, 0.7), "Поток")
		"orbital":
			_box(root, Vector3(16, 0.2, 16), Vector3(0, -0.1, 0), Color(0.15, 0.2, 0.45))
			_wall_room(root, 16, 16, 5.0)
			_label(root, Vector3(0, 4.2, -7), "Орбитальный сектор")
			_add_interact(root, Vector3(-5, 1, -4), "Станция: переписка", "Активировать", &"finale_station", {"station": "messages"}, &"console")
			_add_interact(root, Vector3(-2.5, 1, -4), "Станция: одежда", "Активировать", &"finale_station", {"station": "outfit"}, &"wardrobe")
			_add_interact(root, Vector3(0, 1, -4), "Станция: подарок", "Активировать", &"finale_station", {"station": "gift"}, &"shelf")
			_add_interact(root, Vector3(2.5, 1, -4), "Станция: доставка", "Активировать", &"finale_station", {"station": "delivery"}, &"machine")
			_add_interact(root, Vector3(5, 1, -4), "Станция: линии", "Активировать", &"finale_station", {"station": "parallel"}, &"console")
			_add_interact(root, Vector3(-3, 1, 0), "Станция: скандал", "Активировать", &"finale_station", {"station": "scandal"}, &"desk")
			_add_interact(root, Vector3(3, 1, 0), "Станция: ядро", "Активировать", &"finale_station", {"station": "core"}, &"machine")
			_add_interact(root, Vector3(0, 1.5, 3), "Мегамашина", "ФИНАЛ", &"start_finale", {}, &"console")
			_add_interact(root, Vector3(-5, 1, 4), "Мегамашина ч.1", "Купить", &"buy_upgrade", {"upgrade_id": "final_megamachine_1"}, &"machine")
			_add_interact(root, Vector3(0, 1, 4), "Мегамашина ч.2", "Купить", &"buy_upgrade", {"upgrade_id": "final_megamachine_2"}, &"machine")
			_add_interact(root, Vector3(5, 1, 4), "Мегамашина ч.3", "Купить", &"buy_upgrade", {"upgrade_id": "final_megamachine_3"}, &"machine")
			_mannequin(root, Vector3(0, 1.2, 6), Color(1, 0.2, 0.9), "Алгоритм")


func _build_lab_room(root: Node3D) -> void:
	## Cold metal contrast vs warm apartment. Prefer Clone_Lab_Base art.
	var lab_visual := _mount_visual_scene(root, LAB_SCENE, "LabVisual")
	if lab_visual == null:
		_box(root, Vector3(10, 0.2, 10), Vector3(0, -0.1, 0), Color(0.28, 0.34, 0.4))
		_wall_room(root, 10, 10, 3.0)
		_label(root, Vector3(0, 2.6, -4.2), "Лаборатория")
	else:
		_label(root, Vector3(0, 2.8, -4.5), "Лаборатория клонов")
	var light := OmniLight3D.new()
	light.name = "ColdLight"
	light.light_color = Color(0.55, 0.75, 0.95)
	light.light_energy = 1.4
	light.omni_range = 12.0
	light.position = Vector3(0, 2.8, 0)
	root.add_child(light)
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0, 0, 3.2)
	root.add_child(spawn)
	_add_interact(root, Vector3(-2.5, 0, -1.5), "Капсула клона", "Создать клона", &"create_clone", {}, &"machine")
	_add_interact(root, Vector3(2.5, 0, -1.0), "Терминал приёмки", "Создать клона", &"create_clone", {}, &"console")
	_add_interact(root, Vector3(0, 0, 3.5), "Лифт", "Выбрать этаж", &"open_elevator", {}, &"door")
	_add_interact(root, Vector3(2.0, 0, 3.5), "В квартиру", "Подняться", &"elevator_travel", {"dest": "apartment"}, &"door")


func _build_themed_apartment(root: Node3D, theme_name: String, floor_c: Color, wall_c: Color) -> void:
	_box(root, Vector3(9, 0.2, 9), Vector3(0, -0.1, 0), floor_c)
	_wall_room_colored(root, 9, 9, 2.8, wall_c)
	_label(root, Vector3(0, 2.5, -3.8), "Квартира «%s»" % theme_name)
	var spawn := Marker3D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector3(0, 0, 3.0)
	root.add_child(spawn)
	_add_interact(root, Vector3(-2.2, 0, -1.5), "Диван", "Осмотреть", &"neighbor_look", {}, &"bed")
	_add_interact(root, Vector3(1.8, 0, -0.5), "Стол", "Положить / сесть / начать", &"prepare_and_start", {}, &"table_set")
	_add_interact(root, Vector3(2.5, 0, 1.5), "Шкаф", "Сменить одежду", &"wardrobe", {}, &"wardrobe")
	_add_interact(root, Vector3(0, 0, 3.4), "Лифт", "Выбрать этаж", &"open_elevator", {}, &"door")
	match theme_name:
		"Уют":
			_box(root, Vector3(1.2, 0.6, 0.8), Vector3(-1.5, 0.4, 1.2), Color(0.65, 0.4, 0.25))
		"Модерн":
			_box(root, Vector3(2.0, 0.15, 0.6), Vector3(0, 1.2, -2.5), Color(0.75, 0.78, 0.82))
		"Креатив":
			_box(root, Vector3(1.4, 1.2, 0.1), Vector3(-2.5, 1.2, -1.0), Color(0.95, 0.35, 0.55))
			_box(root, Vector3(1.0, 1.0, 0.1), Vector3(2.2, 1.1, -2.0), Color(0.35, 0.75, 0.95))


func _wall_room_colored(parent: Node3D, w: float, d: float, h: float, color: Color) -> void:
	var t := 0.2
	_box(parent, Vector3(w, h, t), Vector3(0, h * 0.5, -d * 0.5), color)
	_box(parent, Vector3(w, h, t), Vector3(0, h * 0.5, d * 0.5), color)
	_box(parent, Vector3(t, h, d), Vector3(-w * 0.5, h * 0.5, 0), color.darkened(0.08))
	_box(parent, Vector3(t, h, d), Vector3(w * 0.5, h * 0.5, 0), color.darkened(0.08))


func _spawn_neighbor_npc(root: Node3D) -> void:
	var area := Interactable.new()
	area.name = "NeighborNPC"
	area.display_name = Game.girls.display_name(&"neighbor")
	area.action_label = "Заговорить"
	area.action_id = &"talk_girl"
	area.payload = {"girl_id": "neighbor"}
	area.position = Vector3(0.8, 0, -0.5)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.55, 1.8, 0.55)
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	area.add_child(cs)
	_neighbor_girl = _make_girl()
	area.add_child(_neighbor_girl)
	root.add_child(area)
	if _neighbor_girl.has_method("apply_from_content"):
		_neighbor_girl.call("apply_from_content", &"neighbor", Game.girls.display_name(&"neighbor"))
	if _neighbor_girl.has_method("face_toward"):
		_neighbor_girl.call("face_toward", root.to_global(Vector3(0, 0, 3)))


func _spawn_harem_slots(root: Node3D) -> void:
	var girls: Array = Game.girls.list_harem()
	var door := Vector3(0.0, 0.0, 3.0)
	for i in range(mini(6, girls.size())):
		var g: Dictionary = girls[i]
		var id := str(g.get("id", ""))
		var slot := Vector3(-5 + i * 2.0, 0, -4.5)
		var area := Interactable.new()
		area.display_name = Game.girls.display_name(StringName(id))
		area.action_label = "Поговорить"
		if bool(g.get("claimed", false)):
			area.display_name = "Орбита: " + area.display_name
			area.action_label = "Навестить"
		area.action_id = &"visit_harem"
		area.payload = {"girl_id": id}
		# Spawn at door, walk to slot — never teleport-already-there.
		area.position = door
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.55, 1.8, 0.55)
		cs.shape = shape
		cs.position = Vector3(0, 0.9, 0)
		area.add_child(cs)
		var girl := _make_girl()
		area.add_child(girl)
		root.add_child(area)
		if girl.has_method("apply_from_content"):
			girl.call("apply_from_content", StringName(id), Game.girls.display_name(StringName(id)))
		var tw := create_tween()
		tw.tween_property(area, "position", slot, 1.4 + float(i) * 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _refresh_harem_npcs() -> void:
	if not (str(Game.stage_id) in ["stage_4", "stage_5", "stage_6"]):
		return
	if not _built_rooms.has("mansion"):
		return
	var mansion: Node3D = _built_rooms["mansion"]
	for c in mansion.get_children():
		if c is Interactable and str(c.action_id) == "visit_harem":
			c.queue_free()
	_spawn_harem_slots(mansion)



func _make_girl() -> Node3D:
	var packed := load("res://scenes/characters/girl.tscn") as PackedScene
	if packed:
		return packed.instantiate() as Node3D
	return Node3D.new()


func _wall_room(parent: Node3D, w: float, d: float, h: float) -> void:
	var t := 0.2
	_box(parent, Vector3(w, h, t), Vector3(0, h * 0.5, -d * 0.5), Color(0.7, 0.7, 0.75))
	_box(parent, Vector3(w, h, t), Vector3(0, h * 0.5, d * 0.5), Color(0.7, 0.7, 0.75))
	_box(parent, Vector3(t, h, d), Vector3(-w * 0.5, h * 0.5, 0), Color(0.65, 0.65, 0.7))
	_box(parent, Vector3(t, h, d), Vector3(w * 0.5, h * 0.5, 0), Color(0.65, 0.65, 0.7))


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	parent.add_child(mi)
	if size.y <= 0.3:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.position = pos
		body.add_child(col)
		parent.add_child(body)
	return mi


func _label(parent: Node3D, pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 48
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)


func _orbit_culture_props(parent: Node3D, pos: Vector3) -> void:
	## Physical manifestation of trait culture (§24) — labels/props from facility flags.
	if Game.facility == null or not Game.facility.has_flag("orbit_culture_active"):
		return
	var title := "Культура орбиты"
	if Game.trait_influence != null and Game.trait_influence.active_doctrine != "":
		var dd: Dictionary = Game.trait_influence.doctrine_def(Game.trait_influence.active_doctrine)
		title = str(dd.get("name", title))
	elif Game.facility.has_flag("orbit_institution_thrift"):
		title = "Институт экономности"
	elif Game.facility.has_flag("orbit_institution_punctual"):
		title = "Институт ритма"
	_box(parent, Vector3(1.2, 1.6, 0.2), pos, Color(0.75, 0.7, 0.55))
	_label(parent, pos + Vector3(0, 1.1, 0.15), title)


func _mannequin(parent: Node3D, pos: Vector3, color: Color, title: String) -> void:
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.25
	cap.height = 1.4
	body.mesh = cap
	body.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	body.material_override = mat
	parent.add_child(body)
	_label(parent, pos + Vector3(0, 1.1, 0), title)


func _add_interact(parent: Node3D, pos: Vector3, title: String, action: String, action_id: StringName, payload: Dictionary = {}, prop_kind: StringName = &"") -> Interactable:
	var area := Interactable.new()
	area.display_name = title
	area.action_label = action
	area.action_id = action_id
	area.payload = payload
	area.position = Vector3(pos.x, 0.0, pos.z)
	if prop_kind == &"machine":
		area.name = "Machine_%s" % title
		area.add_to_group("ambient_machine")
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.8, 1.2)
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	area.add_child(cs)
	var visuals := Node3D.new()
	visuals.name = "Visuals"
	area.add_child(visuals)
	# Apartment furniture outlines bind real meshes via bind_outline_root — no FocusProxy boxes.
	var apartment_art: bool = parent.has_node("ApartmentVisual")
	var art_backed: bool = bool(payload.get("art_backed", false))
	if apartment_art:
		pass
	elif art_backed:
		# City venues without bound meshes still need a sole fallback outline target.
		_attach_focus_proxy(visuals)
	elif prop_kind != &"":
		PropFactory.attach(visuals, prop_kind)
	else:
		PropFactory.attach(visuals, &"desk")
	parent.add_child(area)
	return area


func _bind_interact_outline(area: Interactable, visual: Node, path: String) -> void:
	if area == null or visual == null or path.is_empty():
		return
	var n: Node = visual.get_node_or_null(path)
	if n == null:
		return
	# Apartment furniture owns the interact: reparent under art node, fit AABB, outline meshes.
	if n is Node3D:
		var host: Node3D = n as Node3D
		area.attach_to_host(host, Vector3.ZERO)
		area.fit_collision_to_meshes(host)
	area.bind_outline_root(n)
	# Drop any leftover proxy/plane so only screen-space next_pass remains.
	var visuals_node: Node = area.get_node_or_null("Visuals")
	if visuals_node:
		for child in visuals_node.get_children():
			var cn: String = str(child.name)
			if cn == "FocusProxy" or cn.begins_with("FocusMarker") or cn.begins_with("OutlinePlane") or cn.begins_with("OutlineExtrude"):
				child.free()


func _assert_apartment_kitchen_interact_clearance(fridge: Interactable, drawers: Interactable) -> void:
	if fridge == null or drawers == null:
		return
	var fridge_aabb: AABB = fridge.get_collision_world_aabb()
	var drawers_aabb: AABB = drawers.get_collision_world_aabb()
	if fridge_aabb.size.length() < 0.001 or drawers_aabb.size.length() < 0.001:
		push_warning("APT kitchen interact AABB empty (fridge=%s drawers=%s)" % [fridge_aabb.size, drawers_aabb.size])
		return
	if fridge_aabb.intersects(drawers_aabb):
		push_error(
			"APT kitchen interact AABB overlap: Fridge %s @%s vs Drawers %s @%s"
			% [fridge_aabb.size, fridge_aabb.position, drawers_aabb.size, drawers_aabb.position]
		)
	else:
		print(
			"APT kitchen interact AABB OK (no overlap): Fridge size=%s Drawers size=%s"
			% [fridge_aabb.size, drawers_aabb.size]
		)


func _attach_focus_proxy(parent: Node3D) -> void:
	## Sole fallback outline target for city art-backed spots without bound meshes.
	var proxy := MeshInstance3D.new()
	proxy.name = "FocusProxy"
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 1.7, 0.9)
	proxy.mesh = box
	proxy.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	proxy.material_override = mat
	parent.add_child(proxy)
