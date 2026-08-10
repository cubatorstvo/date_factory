class_name DateVenueInteractable
extends Interactable
## Physical date venue entry (MODULE 14A). Builds DatingStartRequest from GirlDefinition.

const LAYER_INTERACTABLE: int = 4
const DATING_UI_SCENE: String = "res://ui/dating/dating_ui.tscn"

@export var prompt_text: String = "Стол для свидания"

var _ui: CanvasLayer = null
var _dating_ui: CanvasLayer = null
var _active_player: Node = null
var _placed_meal: Node3D = null


func _ready() -> void:
	prompt_action = prompt_text
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_ensure_collision()


func get_interaction_prompt(player: Node) -> String:
	var carrier: Node = _get_meal_carrier(player)
	if (
		_current_location_id() == &"apartment"
		and carrier != null
		and carrier.has_method("has_meal")
		and bool(carrier.call("has_meal"))
	):
		var dish_name: String = str(carrier.call("get_meal_name"))
		return "[E] Поставить на стол: %s" % dish_name
	prompt_action = prompt_text
	return super.get_interaction_prompt(player)


func _on_interact(player: Node) -> void:
	_active_player = player
	if _try_place_carried_meal(player):
		return
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_method("can_start_personal_date"):
		if bool(overload.call("is_started")) and not bool(overload.call("can_start_personal_date")):
			_show_error(DatingOverloadTypes.DATE_VENUE_CAPACITY_MESSAGE, player)
			return
	_show_girl_picker(player)


func _try_place_carried_meal(player: Node) -> bool:
	if _current_location_id() != &"apartment":
		return false
	var carrier: Node = _get_meal_carrier(player)
	if carrier == null or not carrier.has_method("has_meal"):
		return false
	if not bool(carrier.call("has_meal")):
		return false
	var meal: Dictionary = carrier.call("take_meal")
	if meal.is_empty():
		return false
	var scene_path: String = str(meal.get("scene", ""))
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("[DateVenue] meal scene missing: %s" % scene_path)
		return true
	var instance: Node = packed.instantiate()
	if not (instance is Node3D):
		instance.free()
		return true
	var anchor: Node3D = get_node_or_null("MealAnchor") as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = "MealAnchor"
		add_child(anchor)
	if _placed_meal != null and is_instance_valid(_placed_meal):
		_placed_meal.queue_free()
	_placed_meal = instance as Node3D
	anchor.add_child(_placed_meal)
	_placed_meal.position = Vector3.ZERO
	_placed_meal.rotation_degrees = Vector3.ZERO
	_placed_meal.scale = Vector3.ONE
	_notify_meal_placed("На столе: %s" % str(meal.get("name", "блюдо")))
	return true


func _get_meal_carrier(player: Node) -> Node:
	if player == null or not player.has_method("get_camera"):
		return null
	var camera: Camera3D = player.call("get_camera") as Camera3D
	if camera == null:
		return null
	return camera.get_node_or_null("ApartmentMealCarrier")


func _notify_meal_placed(message: String) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var hud: Node = tree.get_first_node_in_group("game_hud")
	if hud == null:
		var world: Node = get_node_or_null("/root/World")
		if world != null and world.has_method("get_game_hud"):
			hud = world.call("get_game_hud") as Node
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)

func _ensure_collision() -> void:
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		return
	shape_node = CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 1.0, 1.2)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape_node)


func _current_location_id() -> StringName:
	var world: Node = get_node_or_null("/root/World")
	if world != null:
		var loc: Variant = world.get("current_location_id")
		if loc is StringName:
			return loc as StringName
		return StringName(str(loc))
	return &""


func _show_girl_picker(player: Node) -> void:
	_close_ui(player)
	var location_id: StringName = _current_location_id()
	var rows: Array[Dictionary] = _build_rows(location_id)
	var layer := CanvasLayer.new()
	layer.name = "DateVenueUI"
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 280)
	var vbox := VBoxContainer.new()
	var title := Label.new()
	title.text = prompt_text
	vbox.add_child(title)
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "Нет доступных свиданий здесь."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(empty)
	else:
		for row in rows:
			var btn := Button.new()
			var available: bool = bool(row.get("available", false))
			btn.text = str(row.get("label", ""))
			btn.disabled = not available
			var gid: StringName = row.get("girl_id", &"") as StringName
			if available:
				btn.pressed.connect(func() -> void:
					_start_date(gid, player)
				)
			vbox.add_child(btn)
	var cancel := Button.new()
	cancel.text = "Закрыть"
	cancel.pressed.connect(func() -> void:
		_close_ui(player)
	)
	vbox.add_child(cancel)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_ui = layer
	_enter_modal(player)


func _build_rows(location_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gs: Node = get_node_or_null("/root/GameState")
	var db: Node = get_node_or_null("/root/ContentDB")
	var rel: Node = get_node_or_null("/root/Relationships")
	if gs == null or db == null or rel == null:
		return out
	var contacts: Array = gs.call("get_girl_contact_ids") as Array
	for entry in contacts:
		var girl_id: StringName = entry as StringName
		var def: GirlDefinition = db.call("get_girl", girl_id) as GirlDefinition
		if def == null:
			continue
		if def.default_date_location_id != location_id:
			continue
		var avail: Dictionary = rel.call("get_date_availability", girl_id) as Dictionary
		var status: StringName = avail.get("status", RelationshipTypes.AVAIL_UNKNOWN_GIRL) as StringName
		var label: String = def.display_name
		var available: bool = status == RelationshipTypes.AVAIL_AVAILABLE
		var demand_count: int = 0
		var overload: Node = get_node_or_null("/root/DatingOverload")
		if overload != null and overload.has_method("get_demand_count_for_girl"):
			demand_count = int(overload.call("get_demand_count_for_girl", girl_id))
		if status == RelationshipTypes.AVAIL_COOLDOWN:
			var days: int = int(avail.get("cooldown_days", 0))
			label = "%s — пауза %d дн." % [def.display_name, days]
		elif status == DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED:
			label = "%s — лимит тела" % def.display_name
		elif status == RelationshipTypes.AVAIL_AVAILABLE:
			label = "%s — доступна" % def.display_name
		else:
			label = "%s — недоступна" % def.display_name
		if demand_count > 0:
			label = "%s — спрос: %d" % [label, demand_count]
		out.append({
			"girl_id": girl_id,
			"label": label,
			"available": available,
			"status": status,
		})
	return out


func _start_date(girl_id: StringName, player: Node) -> void:
	var db: Node = get_node_or_null("/root/ContentDB")
	var rel: Node = get_node_or_null("/root/Relationships")
	if db == null or rel == null:
		return
	var def: GirlDefinition = db.call("get_girl", girl_id) as GirlDefinition
	if def == null:
		return
	var req := DatingStartRequest.new()
	req.girl_id = girl_id
	req.location_id = def.default_date_location_id
	var greetings: Array[StringName] = []
	for gid in def.dating_greeting_ids:
		greetings.append(gid)
	req.greeting_ids = greetings
	req.farewell_id = def.dating_farewell_id
	var start: Dictionary = rel.call("start_date_with_history", req) as Dictionary
	if not bool(start.get("ok", false)):
		_close_ui(player)
		var err: StringName = start.get("error", &"") as StringName
		var msg: String = "Не удалось начать свидание."
		if err == DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED:
			msg = DatingOverloadTypes.BODY_CAPACITY_USED_MESSAGE
		elif start.has("message"):
			msg = str(start.get("message", msg))
		_show_error(msg, player)
		return
	_close_ui(player)
	var ui: CanvasLayer = _ensure_dating_ui()
	if ui != null and ui.has_method("open_for_active_date"):
		ui.call("open_for_active_date")
	_enter_modal(player)
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_signal("date_finished"):
		if not dc.is_connected("date_finished", _on_date_finished):
			dc.connect("date_finished", _on_date_finished)


func _on_date_finished(_result: DatingResult) -> void:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_signal("date_finished"):
		if dc.is_connected("date_finished", _on_date_finished):
			dc.disconnect("date_finished", _on_date_finished)
	# DatingUI close button restores gameplay via player if still modal; ensure restore.
	if _active_player != null and is_instance_valid(_active_player):
		# Keep modal until player closes DatingUI result; hook close via visibility.
		if _dating_ui != null and is_instance_valid(_dating_ui):
			if not _dating_ui.visibility_changed.is_connected(_on_dating_ui_visibility):
				_dating_ui.visibility_changed.connect(_on_dating_ui_visibility)


func _on_dating_ui_visibility() -> void:
	if _dating_ui == null or not is_instance_valid(_dating_ui):
		return
	if _dating_ui.visible:
		return
	if _dating_ui.visibility_changed.is_connected(_on_dating_ui_visibility):
		_dating_ui.visibility_changed.disconnect(_on_dating_ui_visibility)
	_exit_modal(_active_player)
	_active_player = null


func _ensure_dating_ui() -> CanvasLayer:
	if _dating_ui != null and is_instance_valid(_dating_ui):
		return _dating_ui
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	var existing: Node = tree.root.find_child("DatingUI", true, false)
	if existing is CanvasLayer:
		_dating_ui = existing as CanvasLayer
		return _dating_ui
	var host: Node = tree.root.get_node_or_null("WorldHost/PersistentUI")
	if host == null:
		host = tree.root
	var packed: PackedScene = load(DATING_UI_SCENE) as PackedScene
	if packed == null:
		push_error("[DateVenue] dating_ui scene missing")
		return null
	var inst: Node = packed.instantiate()
	if not (inst is CanvasLayer):
		inst.free()
		return null
	inst.name = "DatingUI"
	host.add_child(inst)
	_dating_ui = inst as CanvasLayer
	return _dating_ui


func _show_error(text: String, player: Node) -> void:
	var layer := CanvasLayer.new()
	layer.name = "DateVenueErrorUI"
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	var vbox := VBoxContainer.new()
	var label := Label.new()
	label.text = text
	var btn := Button.new()
	btn.text = "OK"
	btn.pressed.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
		_exit_modal(player)
	)
	vbox.add_child(label)
	vbox.add_child(btn)
	panel.add_child(vbox)
	layer.add_child(panel)
	add_child(layer)
	_enter_modal(player)


func _close_ui(player: Node) -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
	_ui = null
	_exit_modal(player)


func _enter_modal(player: Node) -> void:
	if player != null and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")


func _exit_modal(player: Node) -> void:
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
