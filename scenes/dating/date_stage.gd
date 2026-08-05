extends Node3D
## Staged 3D date vignette: both sit at the table chairs.
## Arrival uses ArrivalPipeline (door → walk → seat); never spawn already sitting.
## Home dates use apartment art; park builds outdoor vignette; cafe/restaurant reuse restaurant art.

const STAGE_ORIGIN := Vector3(0.0, 40.0, 0.0)
const RESTAURANT_VISUAL_SCENE := "res://scenes/world/vertical_slice/restaurant.tscn"
const APARTMENT_VISUAL_SCENE := "res://scenes/world/vertical_slice/apartment.tscn"
const DATE_GIRL_SCENE := "res://assets/characters/hero_base/prefabs/DateGirl_UAL.tscn"
const HERO_BODY_SCENE := "res://assets/characters/hero_base/prefabs/Hero.tscn"
const DATE_PRESENTATION_CONTROLLER := "res://scenes/dating/date_presentation_controller.gd"
const RESTAURANT_ART_OFFSET := Vector3(-2.0, 0.0, 1.6)
## Centers dining table near vignette origin (table ~0.40,0,0.61 in apartment art).
const APARTMENT_ART_OFFSET := Vector3(-0.4, 0.0, -0.61)
const GIRL_DOOR_POSITION := Vector3(-2.0, 0.0, 6.4)
const GIRL_CHAIR_POSITION := Vector3(0.0, 0.0, -1.15)
const PLAYER_CHAIR_OFFSET := Vector3(0.0, 0.05, 1.15)
const GIRL_SEAT_Y_OFFSET := 0.0
## Sit clips keep root near floor; hips drop to seat (~0.45m on apartment chairs).
const HOME_SEAT_ROOT_BELOW_SURFACE := 0.45
const INTRO_SKIP_MIN_TIME := 2.4
## Uniform ~1.8m vignette characters (Hero prefab still bakes 0.55 root scale).
const DATE_CHARACTER_SCALE := 1.0


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
var _arrival_at_seat: bool = false
var _arrival_at_seat_at: float = -1.0
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
	if kind == &"date_fx" and message.begins_with("DATE_PLACE_HANDOFF:"):
		var new_place := message.trim_prefix("DATE_PLACE_HANDOFF:")
		_swap_backdrop_keep_cast(new_place)
		return
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
	# Home dates auto-finish intro → dialogue; skip is optional elsewhere only.
	if _place_id == "home":
		return
	if _sequence_time < INTRO_SKIP_MIN_TIME:
		return
	# Mouse skip on button_up so the press that opened/finished UI is not eaten.
	var mouse_up: bool = event is InputEventMouseButton and (not event.pressed) and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("ui_accept") or mouse_up:
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
				var wide_at: float = 0.9 if _place_id == "home" else 1.6
				var two_at: float = 1.8 if _place_id == "home" else 4.6
				if _camera_cue == 0 and _sequence_time >= wide_at:
					_presentation.call("move_to", &"wide", 0.7 if _place_id == "home" else 0.9)
					_camera_cue = 1
				elif _camera_cue == 1 and _sequence_time >= two_at:
					_presentation.call("move_to", &"two_shot", 0.65 if _place_id == "home" else 0.85)
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
			if bool(step.get("sitting", false)) or bool(step.get("done", false)):
				_girl.position = _girl_chair_position
				_lock_girl_physics()
			if bool(step.get("done", false)) and not _arrival_at_seat:
				_arrival_at_seat = true
				_arrival_at_seat_at = _sequence_time
			_face_toward_player()
			# After walk completes, wait for sit_enter (or a short fallback) then open dialogue.
			if _arrival_at_seat:
				if _sit_started:
					var sit_length: float = 1.0
					if _girl.has_method("get_alias_length"):
						sit_length = float(_girl.call("get_alias_length", &"sit_enter"))
					if _sequence_time - _sit_started_at >= maxf(0.55, minf(sit_length, 1.15)):
						_finish_intro()
				elif _sequence_time - _arrival_at_seat_at >= 0.75:
					# Missing sit alias / failed sit start — still open dialogue promptly.
					_hold_girl_seated(true)
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
	# date_ui_open is also used for mid-date UI refresh (phases_done / gift).
	# Rebuilding here re-plays the girl-arrival cutscene — skip if vignette is live.
	if _sequence in [&"intro", &"ready", &"outro"] and _root != null and is_instance_valid(_root):
		return
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
	_apply_date_character_scale(_girl)
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
	if _place_id == "home":
		# Stay inside the 5×5 apartment; look toward entrance / table.
		_date_cam.global_position = STAGE_ORIGIN + Vector3(0.35, 1.55, 1.05)
		_date_cam.look_at(STAGE_ORIGIN + Vector3(-2.1, 1.15, -0.1), Vector3.UP)
	else:
		# Over the player's shoulder, looking across the table at the girl.
		_date_cam.global_position = STAGE_ORIGIN + Vector3(0.15, 1.45, 1.35)
		_date_cam.look_at(STAGE_ORIGIN + Vector3(0.0, 1.35, -0.9), Vector3.UP)
	_date_cam.current = true
	var controller_script := load(DATE_PRESENTATION_CONTROLLER)
	if controller_script:
		_presentation = controller_script.new() as Node
		add_child(_presentation)
		_presentation.call("setup", _date_cam, STAGE_ORIGIN, _place_id)
		_presentation.call("move_to", &"arrival", 0.0)
	_spawn_hero_body()
	var intro_walk: float = 2.2 if _place_id == "home" else 6.5
	_arrival.begin_intro(_girl_door_position, _girl_chair_position, intro_walk)
	_sequence = &"intro"
	_sequence_time = 0.0
	_turn_started = false
	_turn_started_at = 0.0
	_sit_started = false
	_sit_started_at = 0.0
	_arrival_at_seat = false
	_arrival_at_seat_at = -1.0
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
		# Home: snappy push-in onto the girl, then dialogue opens immediately.
		var push_dur: float = 0.55 if _place_id == "home" else 0.85
		_presentation.call("move_to", &"girl_close", push_dur)
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
	var target := _root.to_global(_hero_chair_position + Vector3(0.0, 1.2, 0.0))
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
	if place_id == "park":
		_add_park_backdrop(parent)
		return
	if place_id == "cinema" or place_id == "arcade":
		_add_leisure_backdrop(parent, place_id)
		return
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
	_tone_backdrop_lights(visual)
	var preview_girl := visual.get_node_or_null("Characters/DateGirl") as Node3D
	if preview_girl:
		preview_girl.visible = false
		preview_girl.process_mode = Node.PROCESS_MODE_DISABLED
	var gift_shelf := visual.get_node_or_null("Furniture/GiftShelf") as Node3D
	if gift_shelf:
		gift_shelf.visible = false


func _tone_backdrop_lights(visual: Node3D) -> void:
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


func _add_park_backdrop(parent: Node3D) -> void:
	var visual := Node3D.new()
	visual.name = "ParkVisual"
	parent.add_child(visual)
	_girl_door_position = Vector3(-2.4, 0.0, 3.2)
	_girl_chair_position = Vector3(0.0, 0.0, -0.6)
	_hero_chair_position = Vector3(0.0, 0.05, 1.0)
	if _player and is_instance_valid(_player) and _root != null:
		_player.global_position = _root.to_global(_hero_chair_position)
		_player.rotation = Vector3(0.0, PI, 0.0)
	var ground := MeshInstance3D.new()
	var gmesh := BoxMesh.new()
	gmesh.size = Vector3(10, 0.08, 8)
	ground.mesh = gmesh
	ground.position = Vector3(0, -0.04, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.3, 0.52, 0.32)
	ground.material_override = gmat
	visual.add_child(ground)
	var pond := MeshInstance3D.new()
	var pmesh := CylinderMesh.new()
	pmesh.top_radius = 1.6
	pmesh.bottom_radius = 1.6
	pmesh.height = 0.1
	pond.mesh = pmesh
	pond.position = Vector3(-2.2, 0.0, -2.0)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.28, 0.48, 0.7)
	pond.material_override = pmat
	visual.add_child(pond)
	var bench := MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(1.8, 0.35, 0.5)
	bench.mesh = bmesh
	bench.position = Vector3(0.2, 0.2, 0.15)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.42, 0.3, 0.2)
	bench.material_override = bmat
	visual.add_child(bench)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.9, 0.75)
	light.light_energy = 0.7
	light.omni_range = 10.0
	light.position = Vector3(0.0, 3.0, 0.5)
	visual.add_child(light)


func _add_leisure_backdrop(parent: Node3D, place_id: String) -> void:
	var visual := Node3D.new()
	visual.name = "CinemaVisual" if place_id == "cinema" else "ArcadeVisual"
	parent.add_child(visual)
	_girl_door_position = Vector3(-2.0, 0.0, 2.8)
	_girl_chair_position = Vector3(0.55, 0.0, -0.4)
	_hero_chair_position = Vector3(-0.55, 0.05, -0.4)
	if _player and is_instance_valid(_player) and _root != null:
		_player.global_position = _root.to_global(_hero_chair_position)
		_player.rotation = Vector3(0.0, 0.0, 0.0)
	var floor_m := MeshInstance3D.new()
	var fmesh := BoxMesh.new()
	fmesh.size = Vector3(9, 0.08, 8)
	floor_m.mesh = fmesh
	floor_m.position = Vector3(0, -0.04, 0)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.12, 0.1, 0.16) if place_id == "cinema" else Color(0.15, 0.12, 0.22)
	floor_m.material_override = fmat
	visual.add_child(floor_m)
	var screen := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = Vector3(4.2, 2.2, 0.12) if place_id == "cinema" else Vector3(1.6, 1.4, 0.2)
	screen.mesh = smesh
	screen.position = Vector3(0.0, 1.4, -3.2) if place_id == "cinema" else Vector3(0.0, 1.1, -2.4)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.2, 0.35, 0.55) if place_id == "cinema" else Color(0.7, 0.25, 0.85)
	smat.emission_enabled = true
	smat.emission = smat.albedo_color * 0.5
	screen.material_override = smat
	visual.add_child(screen)
	var seat_a := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.7, 0.45, 0.7)
	seat_a.mesh = seat_mesh
	seat_a.position = Vector3(-0.55, 0.25, -0.35)
	var seat_mat := StandardMaterial3D.new()
	seat_mat.albedo_color = Color(0.35, 0.12, 0.14)
	seat_a.material_override = seat_mat
	visual.add_child(seat_a)
	var seat_b := seat_a.duplicate() as MeshInstance3D
	seat_b.position = Vector3(0.55, 0.25, -0.35)
	visual.add_child(seat_b)
	var light := OmniLight3D.new()
	light.light_color = Color(0.75, 0.85, 1.0) if place_id == "cinema" else Color(0.95, 0.55, 1.0)
	light.light_energy = 0.85
	light.omni_range = 9.0
	light.position = Vector3(0.0, 3.0, -1.0)
	visual.add_child(light)


func _swap_backdrop_keep_cast(new_place_id: String) -> void:
	## Rain handoff: swap vignette art without tearing down girl / phases.
	if _root == null or not is_instance_valid(_root):
		return
	_place_id = new_place_id
	for child in _root.get_children():
		var n := str(child.name)
		if n in ["ParkVisual", "RestaurantVisual", "ApartmentVisual"]:
			child.queue_free()
	_add_backdrop(_root, new_place_id)
	if _presentation and is_instance_valid(_presentation) and _date_cam and is_instance_valid(_date_cam):
		_presentation.call("setup", _date_cam, STAGE_ORIGIN, _place_id)
	if _girl and is_instance_valid(_girl):
		_girl.position = _girl_chair_position
		_hold_girl_seated(true)
	if _hero_body and is_instance_valid(_hero_body):
		_hero_body.position = _hero_chair_position
		_hold_hero_seated(true)
	if _sequence == &"intro":
		_finish_intro()
	else:
		_sequence = &"ready"


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
	if entrance:
		_girl_door_position = visual.position + entrance.position
	if is_home:
		_resolve_home_chairs(visual, markers)
		return
	if seat:
		_girl_chair_position = visual.position + seat.position + Vector3(0.0, GIRL_SEAT_Y_OFFSET, 0.0)
	if hero:
		_hero_chair_position = visual.position + hero.position + Vector3(0.0, 0.05, 0.0)
		if _player and is_instance_valid(_player) and _root != null:
			_player.global_position = _root.to_global(_hero_chair_position)
			_player.rotation = Vector3(0.0, PI, 0.0)


func _resolve_home_chairs(visual: Node3D, markers: Node3D) -> void:
	## Girl → chair closer to west entrance; hero → farther chair. Snap root to seat AABB.
	var chair_a := visual.get_node_or_null("Furniture/DiningChairNorth") as Node3D
	var chair_b := visual.get_node_or_null("Furniture/DiningChairSouth") as Node3D
	var exit_door := visual.get_node_or_null("Furniture/ExitDoor") as Node3D
	var table := visual.get_node_or_null("Furniture/DiningTable") as Node3D
	var girl_chair: Node3D = chair_a
	var hero_chair: Node3D = chair_b
	if chair_a != null and chair_b != null and exit_door != null:
		var door_xz := Vector2(exit_door.position.x, exit_door.position.z)
		var dist_a := Vector2(chair_a.position.x, chair_a.position.z).distance_to(door_xz)
		var dist_b := Vector2(chair_b.position.x, chair_b.position.z).distance_to(door_xz)
		if dist_a <= dist_b:
			girl_chair = chair_a
			hero_chair = chair_b
		else:
			girl_chair = chair_b
			hero_chair = chair_a
	var girl_local: Vector3 = _seat_root_from_chair(girl_chair, table)
	var hero_local: Vector3 = _seat_root_from_chair(hero_chair, table)
	# Prefer authored markers when they already sit on the chosen chair XZ.
	if markers != null:
		var girl_marker := markers.get_node_or_null("GirlSeat") as Node3D
		var hero_marker := markers.get_node_or_null("HeroSeat") as Node3D
		if girl_marker != null and girl_chair != null:
			var gm_xz := Vector2(girl_marker.position.x, girl_marker.position.z)
			var gc_xz := Vector2(girl_local.x, girl_local.z)
			if gm_xz.distance_to(gc_xz) < 0.35:
				girl_local = Vector3(girl_marker.position.x, girl_local.y, girl_marker.position.z)
		if hero_marker != null and hero_chair != null:
			var hm_xz := Vector2(hero_marker.position.x, hero_marker.position.z)
			var hc_xz := Vector2(hero_local.x, hero_local.z)
			if hm_xz.distance_to(hc_xz) < 0.35:
				hero_local = Vector3(hero_marker.position.x, hero_local.y, hero_marker.position.z)
	_girl_chair_position = visual.position + girl_local + Vector3(0.0, GIRL_SEAT_Y_OFFSET, 0.0)
	_hero_chair_position = visual.position + hero_local
	if _player and is_instance_valid(_player) and _root != null:
		_player.global_position = _root.to_global(_hero_chair_position)
		var face := _girl_chair_position - _hero_chair_position
		face.y = 0.0
		if face.length_squared() > 0.0001:
			_player.rotation = Vector3(0.0, atan2(-face.x, -face.z), 0.0)
		else:
			_player.rotation = Vector3(0.0, PI * 0.5, 0.0)


func _seat_root_from_chair(chair: Node3D, table: Node3D) -> Vector3:
	if chair == null:
		return Vector3.ZERO
	var aabb := _chair_mesh_aabb_local(chair)
	if aabb.size == Vector3.ZERO:
		return Vector3(chair.position.x, 0.0, chair.position.z)
	var seat_top_y: float = aabb.position.y + aabb.size.y * 0.48
	var seat := Vector3(aabb.get_center().x, seat_top_y - HOME_SEAT_ROOT_BELOW_SURFACE, aabb.get_center().z)
	if table != null:
		var toward := table.position - Vector3(seat.x, table.position.y, seat.z)
		toward.y = 0.0
		if toward.length_squared() > 0.0001:
			seat += toward.normalized() * 0.05
	return seat


func _chair_mesh_aabb_local(chair: Node3D) -> AABB:
	var aabb := AABB()
	var first := true
	for node in chair.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local_xf: Transform3D = chair.transform * mi.transform
		var ga: AABB = local_xf * mi.get_aabb()
		if first:
			aabb = ga
			first = false
		else:
			aabb = aabb.merge(ga)
	return aabb if not first else AABB()


func _lock_girl_physics() -> void:
	if _girl == null or not is_instance_valid(_girl):
		return
	if _girl is CharacterBody3D:
		var body := _girl as CharacterBody3D
		body.velocity = Vector3.ZERO
		body.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING


func _apply_date_character_scale(body: Node3D) -> void:
	if body == null or not is_instance_valid(body):
		return
	body.scale = Vector3.ONE * DATE_CHARACTER_SCALE


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
	_apply_date_character_scale(_hero_body)
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
	if _place_id == "park":
		zone = &"street"
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
