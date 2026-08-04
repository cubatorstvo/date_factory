extends Node3D
## Staged 3D date vignette: both sit at the table chairs.
## Arrival uses ArrivalPipeline (door → walk → seat); never spawn already sitting.
## Home dates use apartment art; restaurant dates keep restaurant art.

const STAGE_ORIGIN := Vector3(0.0, 40.0, 0.0)
const RESTAURANT_VISUAL_SCENE := "res://scenes/world/vertical_slice/restaurant.tscn"
const APARTMENT_VISUAL_SCENE := "res://scenes/world/vertical_slice/apartment.tscn"
const DATE_GIRL_SCENE := "res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn"
const HERO_BODY_SCENE := "res://assets/characters/hero_base/prefabs/Hero.tscn"
const DATE_PRESENTATION_CONTROLLER := "res://scenes/dating/date_presentation_controller.gd"
const RESTAURANT_ART_OFFSET := Vector3(-2.0, 0.0, 1.6)
## Centers dining table near vignette origin (table at 0.65,0,0.55 in apartment art).
const APARTMENT_ART_OFFSET := Vector3(-0.65, 0.0, -0.55)
const GIRL_DOOR_POSITION := Vector3(-2.0, 0.0, 6.4)
const GIRL_CHAIR_POSITION := Vector3(0.0, 0.0, -1.15)
const PLAYER_CHAIR_OFFSET := Vector3(0.0, 0.05, 1.15)
const GIRL_SEAT_Y_OFFSET := 0.0
const INTRO_SKIP_MIN_TIME := 2.4


var _root: Node3D
var _girl: Node3D
var _girl_parts: Dictionary = {}
var _saved_player_xform: Transform3D
var _saved_pitch: float = 0.0
var _player: Node3D
var _player_cam: Camera3D
var _date_cam: Camera3D
var _date_ui: CanvasItem
var _sequence: StringName = &""
var _sequence_time: float = 0.0
var _turn_started: bool = false
var _turn_started_at: float = 0.0
var _sit_started: bool = false
var _sit_started_at: float = 0.0
var _outro_started: bool = false
var _camera_cue: int = 0
var _presentation: Node
var _arrival: ArrivalPipeline = ArrivalPipeline.new()
var _girl_door_position: Vector3 = GIRL_DOOR_POSITION
var _girl_chair_position: Vector3 = GIRL_CHAIR_POSITION
var _hero_chair_position: Vector3 = PLAYER_CHAIR_OFFSET
var _hero_body: Node3D
var _place_id: String = "restaurant"
var _hero_sit_retries: int = 0
var _hero_sit_armed: bool = false


func _ready() -> void:
	Game.dating.date_ui_open.connect(_on_open)
	Game.dating.date_ui_close.connect(_on_close)
	EventBus.notify.connect(_on_notify)


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"date_fx" and message.begins_with("DATE_EMOTION:"):
		var emotion := StringName(message.trim_prefix("DATE_EMOTION:"))
		if _girl != null and _girl.has_method("play_alias"):
			_girl.call("play_alias", &"seated_gesture")
		elif _girl != null and _girl.has_method("set_emotion"):
			_girl.call("set_emotion", emotion)
		else:
			PropFactory.apply_emotion(_girl_parts, emotion)
		if _presentation and is_instance_valid(_presentation):
			_presentation.call("react", emotion)


func _input(event: InputEvent) -> void:
	if _sequence != &"intro":
		return
	if _sequence_time < INTRO_SKIP_MIN_TIME:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_finish_intro()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _hero_sit_armed and _hero_body != null and is_instance_valid(_hero_body):
		var seated := _hero_is_seated_alias()
		if not seated and _hero_sit_retries < 12:
			_hero_sit_retries += 1
			_hold_hero_seated(true)
		elif seated:
			_hero_sit_armed = false
	if _girl == null or not is_instance_valid(_girl):
		return
	_sequence_time += delta
	match _sequence:
		&"intro":
			if _presentation and is_instance_valid(_presentation):
				if _camera_cue == 0 and _sequence_time >= 1.6:
					_presentation.call("move_to", &"wide", 0.9)
					_camera_cue = 1
				elif _camera_cue == 1 and _sequence_time >= 4.6:
					_presentation.call("move_to", &"two_shot", 0.85)
					_camera_cue = 2
			var step: Dictionary = _arrival.tick(delta)
			_girl.position = step.get("position", _girl_door_position)
			_lock_girl_physics()
			var near_seat := float((_girl.position as Vector3).distance_to(_girl_chair_position)) < 0.35
			if near_seat and not _turn_started:
				_play_girl_alias(&"turn", &"idle")
				_turn_started = true
				_turn_started_at = _sequence_time
			if near_seat and _turn_started and not _sit_started and _sequence_time - _turn_started_at >= 0.35:
				_play_girl_alias(&"sit_enter", &"sit")
				_sit_started = true
				_sit_started_at = _sequence_time
			if bool(step.get("sitting", false)):
				_girl.position = _girl_chair_position
				_lock_girl_physics()
			_face_toward_player()
			if bool(step.get("done", false)) and _sit_started:
				var sit_length := float(_girl.call("get_alias_length", &"sit_enter")) if _girl.has_method("get_alias_length") else 1.0
				if _sequence_time - _sit_started_at >= maxf(0.85, minf(sit_length, 1.3)):
					_finish_intro()
		&"ready":
			_hold_girl_seated()
			_hold_hero_seated()
		&"outro":
			if _sequence_time < 1.05:
				_hold_girl_seated()
				_hold_hero_seated()
				return
			if not _outro_started:
				var current := str(_girl.call("get_current_alias")) if _girl.has_method("get_current_alias") else ""
				if current != "sit_exit":
					_play_girl_alias(&"sit_exit", &"stand")
				var exit_length := float(_girl.call("get_alias_length", &"sit_exit")) if _girl.has_method("get_alias_length") else 1.0
				if _sequence_time >= 1.05 + maxf(0.75, minf(exit_length, 1.15)):
					_arrival.begin_outro(_girl_chair_position, _girl_door_position, 2.4)
					_play_girl_alias(&"walk", &"approach")
					_outro_started = true
				return
			var leave: Dictionary = _arrival.tick(delta)
			_girl.position = leave.get("position", _girl_door_position)
			_lock_girl_physics()
			_face_toward(_girl_door_position)
			if bool(leave.get("done", false)):
				_teardown()


func _on_open(payload: Dictionary) -> void:
	_clear()
	_date_ui = get_tree().get_first_node_in_group("date_ui") as CanvasItem
	if _date_ui:
		_date_ui.visible = false
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null and get_tree().current_scene:
		_player = get_tree().current_scene.find_child("Player", true, false) as Node3D
	if _player:
		_saved_player_xform = _player.global_transform
		var pitch_value: Variant = _player.get("_pitch")
		_saved_pitch = float(pitch_value) if pitch_value != null else 0.0
		# Seat player on the +Z chair, facing the table/girl (-Z).
		_player.global_position = STAGE_ORIGIN + PLAYER_CHAIR_OFFSET
		_player.rotation = Vector3(0.0, PI, 0.0)
		_player.set("_pitch", 0.0)
		var head := _player.get_node_or_null("Head") as Node3D
		if head:
			head.rotation.x = 0.0
		_player_cam = _player.get_node_or_null("Head/Camera3D") as Camera3D
		var carry := _player.get_node_or_null("Head/CarryAnchor") as Node3D
		if carry:
			carry.visible = false

	_place_id = str(payload.get("place_id", ""))
	if _place_id.is_empty():
		var prep: Dictionary = payload.get("prep", {})
		_place_id = str(prep.get("place_id", "restaurant"))
	if _place_id.is_empty():
		_place_id = "restaurant"
	_girl_door_position = GIRL_DOOR_POSITION
	_girl_chair_position = GIRL_CHAIR_POSITION
	_hero_chair_position = PLAYER_CHAIR_OFFSET

	_root = Node3D.new()
	_root.name = "DateVignette"
	_root.position = STAGE_ORIGIN
	add_child(_root)
	_add_backdrop(_root, _place_id)
	_add_gift(payload)

	var packed := load(DATE_GIRL_SCENE) as PackedScene
	_girl = packed.instantiate() as Node3D if packed else Node3D.new()
	_girl.name = "DateGirl"
	_girl.position = _girl_door_position
	_root.add_child(_girl)
	_lock_girl_physics()
	_play_girl_alias(&"approach", &"walk")
	assert(ArrivalPipeline.assert_starts_at_door(_girl.position, _girl_door_position, _girl_chair_position))
	var target_id := str(payload.get("target_id", "neighbor"))
	var display := ""
	if bool(payload.get("unique", true)) or ContentDB.girls.has(target_id):
		display = Game.girls.display_name(StringName(target_id))
		if _girl.has_method("apply_from_content"):
			_girl.call("apply_from_content", StringName(target_id), display)
	elif _girl.has_method("apply_profile"):
		_girl.call("apply_profile", {
			"id": target_id,
			"display_name": str(payload.get("title", "Кандидатка")),
			"skin": Color(0.95, 0.75, 0.7),
			"hair_style": "bob",
		})
	if _girl.has_method("set_emotion"):
		_girl.call("set_emotion", &"neutral")
	if _girl.has_method("get_parts"):
		_girl_parts = _girl.call("get_parts")

	_date_cam = Camera3D.new()
	_date_cam.name = "DateCam"
	_date_cam.fov = 50.0
	add_child(_date_cam)
	# Over the player's shoulder, looking across the table at the girl.
	_date_cam.global_position = STAGE_ORIGIN + Vector3(0.15, 1.45, 1.35)
	_date_cam.look_at(STAGE_ORIGIN + Vector3(0.0, 1.35, -0.9), Vector3.UP)
	_date_cam.current = true
	var controller_script := load(DATE_PRESENTATION_CONTROLLER)
	if controller_script:
		_presentation = controller_script.new() as Node
		add_child(_presentation)
		_presentation.call("setup", _date_cam, STAGE_ORIGIN)
		_presentation.call("move_to", &"arrival", 0.0)
	_spawn_hero_body()
	_arrival.begin_intro(_girl_door_position, _girl_chair_position, 6.5)
	_sequence = &"intro"
	_sequence_time = 0.0
	_turn_started = false
	_turn_started_at = 0.0
	_sit_started = false
	_sit_started_at = 0.0
	_outro_started = false
	_camera_cue = 0


func _add_gift(payload: Dictionary) -> void:
	var gift_id := StringName(str(payload.get("gift_id", Game.inventory.carried_item)))
	if gift_id == &"":
		var prep: Dictionary = payload.get("prep", {})
		gift_id = StringName(str(prep.get("gift_id", "")))
	if gift_id == &"":
		return
	var gift := Node3D.new()
	gift.name = "DateGift_%s" % gift_id
	gift.position = Vector3(0.15, 0.82, 0.0)
	var gift_data: Dictionary = ContentDB.gift(gift_id)
	var color_values: Array = gift_data.get("color", [0.95, 0.35, 0.5])
	PropFactory.attach(gift, &"gift_box", Color(0.62, 0.42, 0.28))
	_root.add_child(gift)


func _finish_intro() -> void:
	if _sequence != &"intro":
		return
	_arrival.skip_intro_to_ready()
	_sequence = &"ready"
	_sequence_time = 0.0
	if _girl and is_instance_valid(_girl):
		_hold_girl_seated(true)
	if _presentation and is_instance_valid(_presentation):
		_presentation.call("move_to", &"girl_close", 0.85)
	if _date_ui and is_instance_valid(_date_ui):
		if _date_ui.has_method("show_after_intro"):
			_date_ui.show_after_intro()
		else:
			_date_ui.visible = true
	EventBus.notify.emit("DATE_INTRO_FINISHED", &"date_fx")


func _play_girl_alias(preferred: StringName, fallback: StringName = &"") -> bool:
	if _girl == null or not is_instance_valid(_girl) or not _girl.has_method("play_alias"):
		return false
	if _girl.has_method("has_alias") and bool(_girl.call("has_alias", String(preferred))):
		return bool(_girl.call("play_alias", preferred))
	if fallback != &"" and (not _girl.has_method("has_alias") or bool(_girl.call("has_alias", String(fallback)))):
		return bool(_girl.call("play_alias", fallback))
	return false


func _face_toward_player() -> void:
	if _girl == null or _root == null:
		return
	if not _girl.is_inside_tree() or not _root.is_inside_tree():
		return
	var target := _root.to_global(Vector3(0.0, 1.2, 0.9))
	if _girl.has_method("face_toward"):
		_girl.call("face_toward", target)
	else:
		target.y = _girl.global_position.y
		if _girl.global_position.distance_to(target) > 0.05:
			_girl.look_at(target, Vector3.UP)
			if _girl.has_method("play_alias"):
				_girl.rotate_y(PI)


func _face_toward(local_target: Vector3) -> void:
	if _girl == null or _root == null:
		return
	var target := _root.to_global(local_target)
	if _girl.has_method("face_toward"):
		_girl.call("face_toward", target)
		return
	target.y = _girl.global_position.y
	if _girl.global_position.distance_to(target) > 0.05:
		_girl.look_at(target, Vector3.UP)
		if _girl.has_method("play_alias"):
			_girl.rotate_y(PI)


func _add_backdrop(parent: Node3D, place_id: String) -> void:
	var is_home := place_id == "home"
	var scene_path := APARTMENT_VISUAL_SCENE if is_home else RESTAURANT_VISUAL_SCENE
	var art_offset := APARTMENT_ART_OFFSET if is_home else RESTAURANT_ART_OFFSET
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("Date visual scene missing: %s" % scene_path)
		return
	var visual := packed.instantiate() as Node3D
	if visual == null:
		push_warning("Date visual scene root must be Node3D: %s" % scene_path)
		return
	visual.name = "ApartmentVisual" if is_home else "RestaurantVisual"
	visual.position = art_offset
	parent.add_child(visual)
	_resolve_date_markers(visual, is_home)
	for node: Node in visual.find_children("*", "WorldEnvironment", true, false):
		var world := node as WorldEnvironment
		if world:
			world.environment = null
	for node: Node in visual.find_children("*", "DirectionalLight3D", true, false):
		var light := node as DirectionalLight3D
		if light:
			light.visible = false
	for node2: Node in visual.find_children("*", "OmniLight3D", true, false):
		var omni := node2 as OmniLight3D
		if omni == null:
			continue
		var c := omni.light_color
		if c.r > 0.75 and c.b > 0.45 and c.g < 0.55:
			omni.light_color = Color(1.0, 0.82, 0.64)
			omni.light_energy = minf(omni.light_energy, 0.9)
		else:
			omni.light_energy = minf(omni.light_energy, 1.15)
	var preview_girl := visual.get_node_or_null("Characters/DateGirl") as Node3D
	if preview_girl:
		preview_girl.visible = false
		preview_girl.process_mode = Node.PROCESS_MODE_DISABLED
	var gift_shelf := visual.get_node_or_null("Furniture/GiftShelf") as Node3D
	if gift_shelf:
		gift_shelf.visible = false


func _resolve_date_markers(visual: Node3D, is_home: bool) -> void:
	var markers := visual.get_node_or_null("Markers") as Node3D
	var entrance: Node3D = null
	var seat: Node3D = null
	var hero: Node3D = null
	if markers != null:
		entrance = markers.get_node_or_null("GirlEntrance") as Node3D
		seat = markers.get_node_or_null("GirlSeat") as Node3D
		hero = markers.get_node_or_null("HeroSeat") as Node3D
		if is_home and entrance == null:
			entrance = markers.get_node_or_null("ApartmentExit") as Node3D
	if is_home:
		if seat == null:
			seat = visual.get_node_or_null("Furniture/DiningChairNorth") as Node3D
		if hero == null:
			hero = visual.get_node_or_null("Furniture/DiningChairSouth") as Node3D
	if entrance:
		_girl_door_position = visual.position + entrance.position
	if seat:
		_girl_chair_position = visual.position + seat.position + Vector3(0.0, GIRL_SEAT_Y_OFFSET, 0.0)
	if hero:
		_hero_chair_position = visual.position + hero.position + Vector3(0.0, 0.05, 0.0)
		if _player and is_instance_valid(_player) and _root != null:
			_player.global_position = _root.to_global(_hero_chair_position)
			_player.rotation = Vector3(0.0, PI, 0.0)


func _lock_girl_physics() -> void:
	if _girl == null or not is_instance_valid(_girl):
		return
	if _girl is CharacterBody3D:
		var body := _girl as CharacterBody3D
		body.velocity = Vector3.ZERO
		body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func _spawn_hero_body() -> void:
	if _root == null:
		return
	if _hero_body != null and is_instance_valid(_hero_body):
		_hero_body.queue_free()
		_hero_body = null
	var packed := load(HERO_BODY_SCENE) as PackedScene
	if packed == null:
		push_warning("Hero body scene missing: %s" % HERO_BODY_SCENE)
		return
	_hero_body = packed.instantiate() as Node3D
	if _hero_body == null:
		return
	_hero_body.name = "DateHeroBody"
	_hero_body.position = _hero_chair_position
	_root.add_child(_hero_body)
	if _hero_body is CharacterBody3D:
		var body := _hero_body as CharacterBody3D
		body.collision_layer = 0
		body.collision_mask = 0
		body.velocity = Vector3.ZERO
		body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	for node: Node in _hero_body.find_children("*", "Camera3D", true, false):
		var cam := node as Camera3D
		if cam:
			cam.current = false
			cam.visible = false
	# CharacterAnimController is not ready yet — deferred sit avoids T-pose.
	_hero_sit_retries = 0
	_hero_sit_armed = true
	call_deferred("_begin_hero_sit")


func _begin_hero_sit() -> void:
	if _hero_body == null or not is_instance_valid(_hero_body):
		return
	# Match girl flow: sit_enter then chain/hold to sit_idle.
	if _hero_body.has_method("play_alias"):
		if _hero_body.has_method("has_alias") and bool(_hero_body.call("has_alias", "sit_enter")):
			_hero_body.call("play_alias", &"sit_enter")
			get_tree().create_timer(0.55).timeout.connect(func() -> void:
				if is_instance_valid(self):
					_hold_hero_seated(true)
			)
		else:
			_hold_hero_seated(true)
	else:
		_hold_hero_seated(true)


func _hero_is_seated_alias() -> bool:
	if _hero_body == null or not is_instance_valid(_hero_body):
		return false
	if not _hero_body.has_method("get_current_alias"):
		return true
	var current := str(_hero_body.call("get_current_alias"))
	return current in ["sit_idle", "seated_gesture", "sit_enter", "gesture", "sit"]


func _hold_hero_seated(force_alias: bool = false) -> void:
	if _hero_body == null or not is_instance_valid(_hero_body):
		return
	_hero_body.position = _hero_chair_position
	if _hero_body is CharacterBody3D:
		(_hero_body as CharacterBody3D).velocity = Vector3.ZERO
	var need_alias := force_alias
	if _hero_body.has_method("get_current_alias"):
		var current := str(_hero_body.call("get_current_alias"))
		if current not in ["sit_idle", "seated_gesture", "sit_enter", "gesture", "sit"]:
			need_alias = true
	if need_alias and _hero_body.has_method("play_alias"):
		if _hero_body.has_method("has_alias") and bool(_hero_body.call("has_alias", "sit_idle")):
			_hero_body.call("play_alias", &"sit_idle")
		elif _hero_body.has_method("has_alias") and bool(_hero_body.call("has_alias", "sit_enter")):
			_hero_body.call("play_alias", &"sit_enter")
		elif _hero_body.has_method("has_alias") and bool(_hero_body.call("has_alias", "sit")):
			_hero_body.call("play_alias", &"sit")
		else:
			_hero_body.call("play_alias", &"idle")
	# Face the girl across the table.
	if _root != null and _root.is_inside_tree() and _hero_body.is_inside_tree():
		var look_at_pos := _root.to_global(_girl_chair_position + Vector3(0.0, 1.2, 0.0))
		if _hero_body.has_method("face_toward"):
			_hero_body.call("face_toward", look_at_pos)
		else:
			_hero_body.rotation = Vector3(0.0, PI, 0.0)


func _hold_girl_seated(force_alias: bool = false) -> void:
	if _girl == null or not is_instance_valid(_girl):
		return
	_girl.position = _girl_chair_position
	_lock_girl_physics()
	var need_alias := force_alias
	if _girl.has_method("get_current_alias"):
		var current := str(_girl.call("get_current_alias"))
		if current not in ["sit_idle", "seated_gesture", "sit_enter", "gesture"]:
			need_alias = true
	if need_alias and _girl.has_method("play_alias"):
		_girl.call("play_alias", &"sit_idle")
		_sit_started = true
	elif _girl.has_method("set_sitting"):
		_girl.call("set_sitting", true)
	_face_toward_player()


func _on_close() -> void:
	if _sequence == &"outro":
		return
	var grade := int(Game.dating.last_result.get("grade", 0))
	Sfx.play(&"result_success" if grade >= 2 else &"result_fail")
	if _presentation and is_instance_valid(_presentation):
		_presentation.call("move_to", &"result", 0.75)
	# Keep seated briefly so the result toast is readable over a valid sit pose.
	if _girl and is_instance_valid(_girl):
		_hold_girl_seated(true)
	_sequence = &"outro"
	_sequence_time = 0.0
	_outro_started = false
	# DateUI manages its own hide / result panel; do not force-hide here.


func _teardown() -> void:
	if _date_cam and is_instance_valid(_date_cam):
		_date_cam.current = false
		_date_cam.queue_free()
	_date_cam = null
	if _player_cam and is_instance_valid(_player_cam):
		_player_cam.current = true
	_player_cam = null
	if _player and is_instance_valid(_player):
		_player.global_transform = _saved_player_xform
		_player.set("_pitch", _saved_pitch)
		var head := _player.get_node_or_null("Head") as Node3D
		if head:
			head.rotation.x = _saved_pitch
		var carry := _player.get_node_or_null("Head/CarryAnchor") as Node3D
		if carry:
			carry.visible = true
	_player = null
	var zone := &"apartment" if _place_id == "home" else &"street"
	Sfx.set_zone(zone)
	_clear()


func _clear() -> void:
	_sequence = &""
	_turn_started = false
	_turn_started_at = 0.0
	_sit_started = false
	_sit_started_at = 0.0
	_outro_started = false
	_camera_cue = 0
	if _presentation and is_instance_valid(_presentation):
		_presentation.queue_free()
	_presentation = null
	if _date_cam and is_instance_valid(_date_cam):
		_date_cam.current = false
		_date_cam.queue_free()
	_date_cam = null
	if _hero_body and is_instance_valid(_hero_body):
		_hero_body.queue_free()
	_hero_body = null
	_hero_sit_armed = false
	_hero_sit_retries = 0
	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_girl = null
	_girl_parts.clear()
