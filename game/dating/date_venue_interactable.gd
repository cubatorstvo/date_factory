class_name DateVenueInteractable
extends Interactable
## Physical date venue entry (MODULE 14A). Builds DatingStartRequest from GirlDefinition.

const LAYER_INTERACTABLE: int = 4
const DATING_UI_SCENE: String = "res://ui/dating/dating_ui.tscn"
const VENUE_PICKER_SCENE: String = "res://game/dating/date_venue_picker.tscn"
const ACTION_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"
const MESSAGE_DIALOG_SCENE: String = "res://ui/common/message_dialog.tscn"
const APARTMENT_SERVING_SCENE: String = (
	"res://world/locations/apartment/apartment_serving_pair.tscn"
)
const APARTMENT_CATALOG_SCRIPT: String = (
	"res://world/locations/apartment/apartment_fridge_catalog.gd"
)
const TUTORIAL_HERO_SEAT_PATH: NodePath = ^"../../../Markers/HeroSeat"
const TUTORIAL_GIRL_SEAT_PATH: NodePath = ^"../../../Markers/GirlSeat"
const TUTORIAL_SEATED_EYE_HEIGHT: float = 1.20

@export var prompt_text: String = "Стол для свидания"

var _ui: CanvasLayer = null
var _dating_ui: CanvasLayer = null
var _active_player: Node = null
var _placed_servings: Dictionary = {}
var _tutorial_in_progress: bool = false
var _tutorial_player_transform: Transform3D = Transform3D.IDENTITY
var _tutorial_camera_pivot_transform: Transform3D = Transform3D.IDENTITY
var _tutorial_player_pose_saved: bool = false


func _ready() -> void:
	prompt_action = prompt_text
	collision_layer = LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	_ensure_collision()
	call_deferred("_restore_tutorial_servings")


func get_interaction_prompt(player: Node) -> String:
	var carrier: Node = _get_meal_carrier(player)
	if (
		_current_location_id() == &"apartment"
		and carrier != null
		and carrier.has_method("has_serving")
		and bool(carrier.call("has_serving"))
	):
		var serving_name: String = str(carrier.call("get_serving_name"))
		var category: StringName = carrier.call("get_serving_category")
		var noun: String = "два напитка" if category == &"drink" else "две порции"
		return "[E] Поставить %s на стол: %s" % [noun, serving_name]
	if _is_tutorial_preparation_active():
		var missing: PackedStringArray = _tutorial_missing_items()
		if missing.is_empty():
			return "[E] Начать обучающее свидание"
		return "[E] Подготовка: не хватает — %s" % ", ".join(missing)
	prompt_action = prompt_text
	return super.get_interaction_prompt(player)


func _on_interact(player: Node) -> void:
	_active_player = player
	if _try_place_carried_meal(player):
		return
	if _is_tutorial_preparation_active():
		var missing: PackedStringArray = _tutorial_missing_items()
		if not missing.is_empty():
			_show_error("Сначала подготовь: %s." % ", ".join(missing), player)
			return
		_start_tutorial_date(player)
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
	if carrier == null or not carrier.has_method("has_serving"):
		return false
	if not bool(carrier.call("has_serving")):
		return false
	var serving: Dictionary = carrier.call("take_serving")
	if serving.is_empty():
		return false
	var pair: Node3D = serving.get("visual") as Node3D
	if pair == null or not is_instance_valid(pair):
		push_error("[DateVenue] carried serving visual missing")
		return true
	var anchor: Node3D = get_node_or_null("MealAnchor") as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = "MealAnchor"
		add_child(anchor)
	var category: StringName = serving.get("category", &"food")
	var previous: Node3D = _placed_servings.get(category) as Node3D
	if previous != null and is_instance_valid(previous):
		previous.queue_free()
	pair.name = "PlacedDrinkPair" if category == &"drink" else "PlacedFoodPair"
	anchor.add_child(pair)
	pair.position = _serving_offset(category)
	pair.rotation_degrees = Vector3.ZERO
	if not pair.has_method("set_carried") or not bool(pair.call("set_carried", false)):
		pair.queue_free()
		return true
	_placed_servings[category] = pair
	_mark_tutorial_serving_ready(category)
	if category == &"food":
		_set_apartment_cutlery_visible(true)
	var noun: String = "два напитка" if category == &"drink" else "две порции"
	_notify_meal_placed(
		"На столе: %s — %s" % [noun, str(serving.get("name", "угощение"))]
	)
	return true


func _serving_offset(category: StringName) -> Vector3:
	return Vector3(0.0, 0.0, 0.20) if category == &"drink" else Vector3(0.0, 0.0, -0.16)


func _restore_tutorial_servings() -> void:
	if _current_location_id() != &"apartment":
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_FOOD_READY)):
		_restore_tutorial_serving(&"fried_egg", &"food")
	if bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_DRINK_READY)):
		_restore_tutorial_serving(&"water", &"drink")


func _restore_tutorial_serving(item_id: StringName, category: StringName) -> void:
	var existing: Node3D = _placed_servings.get(category) as Node3D
	if existing != null and is_instance_valid(existing):
		return
	var catalog: GDScript = load(APARTMENT_CATALOG_SCRIPT) as GDScript
	var packed: PackedScene = load(APARTMENT_SERVING_SCENE) as PackedScene
	if catalog == null or packed == null:
		return
	var definition: Dictionary = catalog.call("get_definition", item_id) as Dictionary
	var pair: Node3D = packed.instantiate() as Node3D
	if pair == null or definition.is_empty():
		if pair != null:
			pair.free()
		return
	if not pair.has_method("configure") or not bool(pair.call("configure", definition, false)):
		pair.free()
		return
	var anchor: Node3D = get_node_or_null("MealAnchor") as Node3D
	if anchor == null:
		anchor = Node3D.new()
		anchor.name = "MealAnchor"
		add_child(anchor)
	pair.name = "PlacedDrinkPair" if category == &"drink" else "PlacedFoodPair"
	anchor.add_child(pair)
	pair.position = _serving_offset(category)
	_placed_servings[category] = pair
	if category == &"food":
		_set_apartment_cutlery_visible(true)


func _mark_tutorial_serving_ready(category: StringName) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if int(gs.call("get_stage")) != int(GameTypes.GameStage.PROLOGUE):
		return
	if not bool(
		gs.call("get_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE)
	):
		return
	var flag_id: StringName = StoryIds.FLAG_TUTORIAL_FOOD_READY
	if category == &"drink":
		flag_id = StoryIds.FLAG_TUTORIAL_DRINK_READY
	elif category != &"food":
		return
	gs.call("set_story_flag", flag_id, true)


func _set_apartment_cutlery_visible(show: bool) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var place_setting: Node = tree.get_first_node_in_group("apartment_place_setting")
	if place_setting != null and place_setting.has_method("set_cutlery_for_food"):
		place_setting.call("set_cutlery_for_food", show)



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
	var packed: PackedScene = load(VENUE_PICKER_SCENE) as PackedScene
	if packed == null:
		return
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return
	layer.name = "DateVenueUI"
	var root: Control = layer.get_node_or_null("Root") as Control
	if root != null:
		UiScaleHelper.apply_to_control(root)
	var title: Label = layer.find_child("Title", true, false) as Label
	var empty: Label = layer.find_child("EmptyMessage", true, false) as Label
	var choices: VBoxContainer = layer.find_child("Choices", true, false) as VBoxContainer
	var cancel: Button = layer.find_child("CloseButton", true, false) as Button
	if title == null or empty == null or choices == null or cancel == null:
		return
	title.text = prompt_text
	if rows.is_empty():
		empty.text = "Нет доступных свиданий здесь."
		empty.visible = true
	else:
		var action_scene: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
		for row in rows:
			if action_scene == null:
				continue
			var btn: Button = action_scene.instantiate() as Button
			if btn == null:
				continue
			var available: bool = bool(row.get("available", false))
			btn.text = str(row.get("label", ""))
			btn.disabled = not available
			var gid: StringName = row.get("girl_id", &"") as StringName
			if available:
				btn.pressed.connect(func() -> void:
					_start_date(gid, player)
				)
			choices.add_child(btn)
	cancel.pressed.connect(func() -> void:
		_close_ui(player)
	)
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


func _is_tutorial_preparation_active() -> bool:
	if _current_location_id() != &"apartment":
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or int(gs.call("get_stage")) != int(GameTypes.GameStage.PROLOGUE):
		return false
	return (
		bool(gs.call("get_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE))
		and not bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE))
	)


func _tutorial_missing_items() -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return missing
	if not bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_FOOD_READY)):
		missing.append("еда")
	if not bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_DRINK_READY)):
		missing.append("напитки")
	if not bool(gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_OUTFIT_READY)):
		missing.append("одежда")
	return missing


func _start_tutorial_date(player: Node) -> void:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null:
		_show_error("Обучение сейчас недоступно.", player)
		return
	var request := DatingStartRequest.new()
	request.girl_id = StoryIds.GIRL_NEIGHBOR
	request.location_id = &"apartment"
	request.greeting_ids = [&"dating_greeting_simple"]
	request.farewell_id = &"dating_farewell_early_common"
	request.forced_event_ids = NeighborTutorialCatalog.FORCED_EVENT_IDS.duplicate()
	request.tutorial_mode = true
	var start: Dictionary = dc.call("start_date", request) as Dictionary
	if not bool(start.get("ok", false)):
		_show_error("Не удалось начать обучающее свидание.", player)
		return
	_tutorial_in_progress = true
	_seat_tutorial_player(player)
	_set_tutorial_neighbor_visible(true)
	var ui: CanvasLayer = _ensure_dating_ui()
	if ui != null and ui.has_method("open_for_active_date"):
		ui.call("open_for_active_date")
	_enter_dialogue(player)
	if dc.has_signal("date_finished"):
		if not dc.is_connected("date_finished", _on_date_finished):
			dc.connect("date_finished", _on_date_finished)


func _seat_tutorial_player(player: Node) -> void:
	var controller: PlayerController = player as PlayerController
	var seat: Marker3D = get_node_or_null(TUTORIAL_HERO_SEAT_PATH) as Marker3D
	if controller == null or seat == null:
		push_error("[DateVenue] tutorial HeroSeat missing")
		return
	var camera_pivot: Node3D = controller.get_node_or_null("CameraPivot") as Node3D
	_tutorial_player_transform = controller.global_transform
	if camera_pivot != null:
		_tutorial_camera_pivot_transform = camera_pivot.transform
	_tutorial_player_pose_saved = true
	controller.velocity = Vector3.ZERO
	controller.global_transform = seat.global_transform
	if camera_pivot != null:
		camera_pivot.position.y = TUTORIAL_SEATED_EYE_HEIGHT
		camera_pivot.rotation = Vector3.ZERO


func _restore_tutorial_player(player: Node) -> void:
	if not _tutorial_player_pose_saved:
		return
	var controller: PlayerController = player as PlayerController
	if controller != null:
		controller.velocity = Vector3.ZERO
		controller.global_transform = _tutorial_player_transform
		var camera_pivot: Node3D = controller.get_node_or_null("CameraPivot") as Node3D
		if camera_pivot != null:
			camera_pivot.transform = _tutorial_camera_pivot_transform
	_tutorial_player_pose_saved = false


func _set_tutorial_neighbor_visible(show: bool) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var actor: CharacterActor = tree.root.find_child(
		"TutorialNeighbor",
		true,
		false,
	) as CharacterActor
	if actor == null:
		return
	actor.visible = show
	actor.process_mode = Node.PROCESS_MODE_INHERIT if show else Node.PROCESS_MODE_DISABLED
	if show:
		var seat: Marker3D = get_node_or_null(TUTORIAL_GIRL_SEAT_PATH) as Marker3D
		if seat != null:
			actor.global_transform = seat.global_transform
			actor.rotate_y(PI)
		actor.apply_appearance(&"appearance_female_neighbor")
		var animation: CharacterAnimationController = actor.get_animation_controller()
		if animation != null:
			if animation.has_animation(&"sit_idle"):
				animation.play_loop(&"sit_idle")
			else:
				animation.play_semantic(&"idle")


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
	_enter_dialogue(player)
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
	if _tutorial_in_progress:
		_restore_tutorial_player(_active_player)
		_set_tutorial_neighbor_visible(false)
		_tutorial_in_progress = false
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
	var packed: PackedScene = load(MESSAGE_DIALOG_SCENE) as PackedScene
	if packed == null:
		return
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return
	layer.name = "DateVenueErrorUI"
	var root: Control = layer.get_node_or_null("Root") as Control
	if root != null:
		UiScaleHelper.apply_to_control(root)
	var label: Label = layer.find_child("Message", true, false) as Label
	var btn: Button = layer.find_child("CloseButton", true, false) as Button
	if label == null or btn == null:
		return
	label.text = text
	btn.text = "OK"
	btn.pressed.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
		_exit_modal(player)
	)
	add_child(layer)
	_enter_modal(player)


func _close_ui(player: Node) -> void:
	if _ui != null and is_instance_valid(_ui):
		_ui.queue_free()
	_ui = null
	_exit_modal(player)


func _enter_dialogue(player: Node) -> void:
	if player != null and player.has_method("enter_dialogue"):
		player.call("enter_dialogue")
		return
	_enter_modal(player)


func _enter_modal(player: Node) -> void:
	if player != null and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")


func _exit_modal(player: Node) -> void:
	if player != null and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
