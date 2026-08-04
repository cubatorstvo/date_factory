extends Node3D
## Builds the expandable complex + city district (−X) + neighbor apt (−Z).

const APARTMENT_VISUAL_SCENE := "res://scenes/world/vertical_slice/apartment.tscn"
const STREET_VISUAL_SCENE := "res://scenes/world/vertical_slice/street.tscn"

@onready var rooms_root: Node3D = $Rooms
@onready var props_root: Node3D = $Props
@onready var npcs_root: Node3D = $Npcs

var _built_rooms: Dictionary = {}
var _wanderers: Array[Dictionary] = []
var _city_girls: Array[Dictionary] = []
var _city_data: Dictionary = {}
var _ambient_time: float = 0.0
var _neighbor_girl: Node3D


func _ready() -> void:
	add_to_group("world_root")
	Game.facility.facility_changed.connect(_rebuild)
	Game.girls.girls_changed.connect(_refresh_harem_npcs)
	Game.city.city_changed.connect(_refresh_tutorial_markers)
	EventBus.stage_changed.connect(func(_s): _rebuild())
	_add_world_ground()
	_rebuild()


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
	add_child(ground)


func _rebuild() -> void:
	for c in rooms_root.get_children():
		c.queue_free()
	for c in props_root.get_children():
		c.queue_free()
	for c in npcs_root.get_children():
		c.queue_free()
	_wanderers.clear()
	_city_girls.clear()
	_city_data.clear()
	_neighbor_girl = null
	_built_rooms.clear()
	_update_stage_lighting()
	for rid in Game.facility.unlocked_rooms:
		_build_room(rid)
	_build_city()
	_spawn_city_npcs()
	_refresh_harem_npcs()
	_refresh_tutorial_markers()


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
		_mount_visual_scene(city_root, STREET_VISUAL_SCENE, "StreetVisual", Vector3(-30.0, 0.0, 0.0))
		_add_interact(city_root, Vector3(-48.0, 0.0, 4.7), "Подъезд DATE FACTORY", "Вернуться домой", &"go_home", {"art_backed": true}, &"door")
		_add_interact(city_root, Vector3(-19.5, 0.0, -4.35), "Ресторан Two Hearts", "Войти на свидание", &"enter_restaurant", {"art_backed": true}, &"door")


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
	return instance


func _hide_generated_visuals(parent: Node3D) -> void:
	for child: Node in parent.get_children():
		if child is MeshInstance3D or child is Label3D:
			(child as Node3D).visible = false


func _update_stage_lighting() -> void:
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if sun == null:
		return
	var stage_number := int(str(Game.stage_id).trim_prefix("stage_"))
	if stage_number >= 5:
		sun.light_color = Color(0.62, 0.74, 1.0)
		sun.light_energy = 0.55
	else:
		sun.light_color = Color(1.0, 0.72, 0.62)
		sun.light_energy = 0.38


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
	# Decorative male wanderers
	for i in range(5):
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
	var spawn := Vector3(-12, 0, 0)
	if prefer_plaza and id == "city_cashier":
		spawn = Vector3(-12.5, 0, 1.2)
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
	shape.size = Vector3(0.9, 1.8, 0.9)
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
			_mount_visual_scene(root, APARTMENT_VISUAL_SCENE, "ApartmentVisual")
			_add_interact(root, Vector3(-2.5, 0, -2.5), "Кровать / Работа", "Поработать", &"job", {}, &"bed")
			_add_interact(root, Vector3(2.5, 0, -2.5), "Шкаф", "Сменить одежду", &"wardrobe", {}, &"wardrobe")
			_add_interact(root, Vector3(-2.5, 0, 2.2), "Полка подарков", "Купить цветок", &"buy_gift", {"gift_id": "flower"}, &"shelf")
			_add_interact(root, Vector3(-1.2, 0, 2.2), "Взять подарок", "Взять", &"take_gift", {"gift_id": "flower"}, &"gift_box")
			_add_interact(root, Vector3(1.5, 0, 1.5), "Кухонный стол", "Подготовить стол и начать свидание", &"prepare_and_start", {}, &"table_set")
			_add_interact(root, Vector3(0, 0, -1), "Телефон на тумбе", "Открыть", &"phone", {}, &"phone_stand")
			_add_interact(root, Vector3(3.2, 0, 0), "Дверь расширения", "Расширить", &"expand", {}, &"door")
			_add_interact(root, Vector3(-3.5, 0, 0), "На улицу", "Выйти в город", &"go_outside", {}, &"door")
			_add_interact(root, Vector3(0, 0, -3.6), "К соседке", "Постучать", &"go_neighbor", {}, &"door")
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
	shape.size = Vector3(0.9, 1.8, 0.9)
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
		shape.size = Vector3(1.0, 1.8, 1.0)
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


func _add_interact(parent: Node3D, pos: Vector3, title: String, action: String, action_id: StringName, payload: Dictionary = {}, prop_kind: StringName = &"") -> void:
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
	var art_backed := bool(payload.get("art_backed", false)) or parent.has_node("ApartmentVisual")
	if not art_backed:
		if prop_kind != &"":
			PropFactory.attach(visuals, prop_kind)
		else:
			PropFactory.attach(visuals, &"desk")
	parent.add_child(area)
