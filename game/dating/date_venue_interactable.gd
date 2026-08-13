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
const HERO_SEAT_NAME: String = "HeroSeat"
const GIRL_SEAT_NAME: String = "GirlSeat"
const DATE_GIRL_NODE_NAME: String = "DateOccupantGirl"

@export var prompt_text: String = "Стол для свидания"

var _ui: CanvasLayer = null
var _dating_ui: CanvasLayer = null
var _active_player: Node = null
var _placed_servings: Dictionary = {}
var _tutorial_in_progress: bool = false
var _tutorial_player_transform: Transform3D = Transform3D.IDENTITY
var _tutorial_camera_pivot_transform: Transform3D = Transform3D.IDENTITY
var _tutorial_player_pose_saved: bool = false
var _date_girl_spawned: CharacterActor = null
var _date_girl_reused: Node3D = null
var _date_girl_saved_transform: Transform3D = Transform3D.IDENTITY
var _date_girl_saved_visible: bool = true
var _date_girl_saved_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT


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
	var pending_prompt: String = _pending_appointment_prompt()
	if pending_prompt != "":
		return pending_prompt
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
	if _try_pending_appointment(player):
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
	_sync_apartment_prepared_flag()
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
	_occupy_date_seats(player, StoryIds.GIRL_NEIGHBOR)
	_advance_arrival_to_greeting()
	_open_active_date_session(player)


func _seat_tutorial_player(player: Node) -> void:
	var controller: PlayerController = player as PlayerController
	var seat: Marker3D = _find_seat_marker(HERO_SEAT_NAME)
	if controller == null or seat == null:
		push_error("[DateVenue] HeroSeat missing")
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
		var seat: Marker3D = _find_seat_marker(GIRL_SEAT_NAME)
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


func _occupy_date_seats(player: Node, girl_id: StringName) -> void:
	_seat_tutorial_player(player)
	_present_date_girl(girl_id)


func _advance_arrival_to_greeting() -> void:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null or not dc.has_method("continue_arrival"):
		return
	if not bool(dc.call("is_date_active")):
		return
	var session: Variant = dc.call("get_session")
	if session is DatingSession and (session as DatingSession).phase == DatingTypes.Phase.ARRIVAL:
		dc.call("continue_arrival")


func _open_active_date_session(player: Node) -> void:
	var ui: CanvasLayer = _ensure_dating_ui()
	if ui != null and ui.has_method("open_for_active_date"):
		ui.call("open_for_active_date")
	_enter_dialogue(player)
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_signal("date_finished"):
		if not dc.is_connected("date_finished", _on_date_finished):
			dc.connect("date_finished", _on_date_finished)


func _active_session_girl_id() -> StringName:
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc == null or not dc.has_method("get_session"):
		return &""
	var session: Variant = dc.call("get_session")
	if session is DatingSession:
		return (session as DatingSession).girl_id
	return &""


func _location_root() -> Node:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_current_location"):
		var loc: Node = world.call("get_current_location") as Node
		if loc != null:
			return loc
	return self


func _find_seat_marker(seat_name: String) -> Marker3D:
	var relative: NodePath = TUTORIAL_HERO_SEAT_PATH
	if seat_name == GIRL_SEAT_NAME:
		relative = TUTORIAL_GIRL_SEAT_PATH
	var local: Marker3D = get_node_or_null(relative) as Marker3D
	if local != null:
		return local
	var root: Node = _location_root()
	if root == null:
		return null
	return root.find_child(seat_name, true, false) as Marker3D


func _find_existing_date_girl(girl_id: StringName) -> Node3D:
	var root: Node = _location_root()
	if root == null:
		return null
	if girl_id == StoryIds.GIRL_NEIGHBOR:
		var neighbor: Node = root.find_child("TutorialNeighbor", true, false)
		if neighbor == null:
			var tree: SceneTree = get_tree()
			if tree != null:
				neighbor = tree.root.find_child("TutorialNeighbor", true, false)
		if neighbor is CharacterActor:
			return neighbor as CharacterActor
	var girls: Array[Node] = root.find_children("*", "GirlActor", true, false)
	for node in girls:
		var girl: GirlActor = node as GirlActor
		if girl != null and girl.girl_id == girl_id:
			return girl
	return null


func _present_date_girl(girl_id: StringName) -> void:
	_clear_presented_date_girl()
	var seat: Marker3D = _find_seat_marker(GIRL_SEAT_NAME)
	if seat == null:
		push_warning("[DateVenue] GirlSeat missing; date continues without girl occupancy")
		return
	var existing: Node3D = _find_existing_date_girl(girl_id)
	if existing != null:
		_date_girl_reused = existing
		_date_girl_saved_transform = existing.global_transform
		_date_girl_saved_visible = existing.visible
		_date_girl_saved_process_mode = existing.process_mode
		if existing.name == "TutorialNeighbor":
			_set_tutorial_neighbor_visible(true)
			return
		existing.visible = true
		existing.process_mode = Node.PROCESS_MODE_INHERIT
		existing.global_transform = seat.global_transform
		existing.rotate_y(PI)
		_play_sit_idle(existing)
		return
	var profile_id: StringName = &"appearance_female_base"
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null and db.has_method("get_girl"):
		var def: GirlDefinition = db.call("get_girl", girl_id) as GirlDefinition
		if def != null and String(def.appearance_profile_id) != "":
			profile_id = def.appearance_profile_id
	var parent: Node = seat.get_parent()
	if parent == null:
		parent = _location_root()
	var spawned: CharacterActor = CharacterFactory.create(profile_id, girl_id, parent)
	if spawned == null:
		push_error("[DateVenue] failed to spawn date girl")
		return
	spawned.name = DATE_GIRL_NODE_NAME
	spawned.global_transform = seat.global_transform
	spawned.rotate_y(PI)
	_play_sit_idle(spawned)
	_date_girl_spawned = spawned


func _play_sit_idle(host: Node) -> void:
	var girl: GirlActor = host as GirlActor
	if girl != null:
		if girl.has_animation(&"sit_idle"):
			girl.play_semantic(&"sit_idle")
			return
		host = girl.get_character_actor()
	var actor: CharacterActor = host as CharacterActor
	if actor == null:
		return
	var animation: CharacterAnimationController = actor.get_animation_controller()
	if animation == null:
		return
	if animation.has_animation(&"sit_idle"):
		animation.play_loop(&"sit_idle")
	else:
		animation.play_semantic(&"idle")


func _clear_presented_date_girl() -> void:
	if _date_girl_spawned != null and is_instance_valid(_date_girl_spawned):
		_date_girl_spawned.queue_free()
	_date_girl_spawned = null
	if _date_girl_reused != null and is_instance_valid(_date_girl_reused):
		if _date_girl_reused.name == "TutorialNeighbor":
			_set_tutorial_neighbor_visible(false)
		else:
			_date_girl_reused.global_transform = _date_girl_saved_transform
			_date_girl_reused.visible = _date_girl_saved_visible
			_date_girl_reused.process_mode = _date_girl_saved_process_mode
	_date_girl_reused = null


func _restore_date_occupancy(player: Node) -> void:
	_restore_tutorial_player(player)
	_clear_presented_date_girl()


func _pending_appointment_prompt() -> String:
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel == null or not rel.has_method("peek_pending_date_status"):
		return ""
	var status: Dictionary = rel.call("peek_pending_date_status", _current_location_id()) as Dictionary
	if not bool(status.get("here", false)):
		return ""
	if bool(status.get("too_early", false)):
		if _can_skip_to_pending_home_date():
			return "[E] Промотать до начала свидания"
		return "[E] %s" % str(status.get("message", "Приходи позже."))
	if bool(status.get("ready", false)):
		return "[E] Начать свидание"
	return ""


func _has_food_and_drink_on_table() -> bool:
	var food: Node3D = _placed_servings.get(&"food") as Node3D
	var drink: Node3D = _placed_servings.get(&"drink") as Node3D
	return food != null and is_instance_valid(food) and drink != null and is_instance_valid(drink)


func _is_home_table_prepared() -> bool:
	if _current_location_id() != &"apartment":
		return false
	if _has_food_and_drink_on_table():
		return true
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_story_flag"):
		return bool(gs.call("get_story_flag", DateVenueCatalog.PREPARED_FLAG))
	return false


func _sync_apartment_prepared_flag() -> void:
	if _current_location_id() != &"apartment":
		return
	if not _has_food_and_drink_on_table():
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("set_story_flag"):
		gs.call("set_story_flag", DateVenueCatalog.PREPARED_FLAG, true)


func _can_skip_to_pending_home_date() -> bool:
	return _current_location_id() == &"apartment" and _is_home_table_prepared()


func _skip_clock_to_pending(peek: Dictionary) -> void:
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null:
		return
	var appt_day: int = int(peek.get("day", 0))
	var appt_hour: int = int(peek.get("hour", 0))
	if appt_day < 1 or not Relationships.DATE_INVITE_HOURS.has(appt_hour):
		return
	if day.has_method("get_current_day") and day.has_method("advance_day"):
		while int(day.call("get_current_day")) < appt_day:
			day.call("advance_day")
	var now_hour: int = 0
	if day.has_method("get_current_hour"):
		now_hour = int(day.call("get_current_hour"))
	if now_hour >= appt_hour:
		return
	if day.has_method("wait_until_hour"):
		day.call("wait_until_hour", appt_hour)


func _try_pending_appointment(player: Node) -> bool:
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel == null or not rel.has_method("try_start_pending_date_at"):
		return false
	var peek: Dictionary = {}
	if rel.has_method("peek_pending_date_status"):
		peek = rel.call("peek_pending_date_status", _current_location_id()) as Dictionary
		if not bool(peek.get("has", false)):
			return false
		if not bool(peek.get("here", false)):
			return false
		if bool(peek.get("too_early", false)):
			if _can_skip_to_pending_home_date():
				_skip_clock_to_pending(peek)
			else:
				var wait_msg: String = str(peek.get("message", "")).strip_edges()
				if wait_msg == "":
					wait_msg = "Приходи позже."
				_show_error(wait_msg, player)
				return true
	var start: Dictionary = rel.call("try_start_pending_date_at", _current_location_id()) as Dictionary
	if not bool(start.get("ok", false)):
		var msg: String = str(start.get("message", "")).strip_edges()
		if msg == "":
			var err: StringName = start.get("error", &"") as StringName
			msg = DatingTypes.user_message(err)
		if msg == "":
			msg = "Не удалось начать свидание."
		_show_error(msg, player)
		return true
	_close_ui(player)
	_occupy_date_seats(player, _active_session_girl_id())
	_advance_arrival_to_greeting()
	_open_active_date_session(player)
	return true


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
	_occupy_date_seats(player, girl_id)
	_advance_arrival_to_greeting()
	_open_active_date_session(player)

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
	_restore_date_occupancy(_active_player)
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
