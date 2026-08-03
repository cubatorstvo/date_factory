extends Node3D
## Staged 3D date vignette: both sit at the table chairs.
## Arrival uses ArrivalPipeline (door → walk → seat); never spawn already sitting.

const STAGE_ORIGIN := Vector3(0.0, 40.0, 0.0)
const GIRL_DOOR_POSITION := Vector3(2.2, 0.0, -1.6)
const GIRL_CHAIR_POSITION := Vector3(0.0, 0.0, -0.9)
const PLAYER_CHAIR_OFFSET := Vector3(0.0, 0.05, 0.9)


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
var _arrival: ArrivalPipeline = ArrivalPipeline.new()


func _ready() -> void:
	Game.dating.date_ui_open.connect(_on_open)
	Game.dating.date_ui_close.connect(_on_close)
	EventBus.notify.connect(_on_notify)


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"date_fx" and message.begins_with("DATE_EMOTION:"):
		var emotion := StringName(message.trim_prefix("DATE_EMOTION:"))
		if _girl != null and _girl.has_method("set_emotion"):
			_girl.call("set_emotion", emotion)
		else:
			PropFactory.apply_emotion(_girl_parts, emotion)


func _input(event: InputEvent) -> void:
	if _sequence != &"intro":
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		_finish_intro()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _girl == null or not is_instance_valid(_girl):
		return
	_sequence_time += delta
	match _sequence:
		&"intro":
			var step: Dictionary = _arrival.tick(delta)
			_girl.position = step.get("position", GIRL_DOOR_POSITION)
			_face_toward_player()
			if bool(step.get("sitting", false)):
				if _girl.has_method("set_sitting"):
					_girl.call("set_sitting", true)
				else:
					_girl.scale.y = lerpf(1.0, 0.92, float(step.get("sit_blend", 0.0)))
			if bool(step.get("done", false)):
				_finish_intro()
		&"outro":
			var leave: Dictionary = _arrival.tick(delta)
			_girl.position = leave.get("position", GIRL_DOOR_POSITION)
			if _girl.has_method("set_sitting"):
				_girl.call("set_sitting", bool(leave.get("sitting", false)))
			else:
				_girl.scale.y = lerpf(0.92, 1.0, 1.0 - float(leave.get("sit_blend", 0.0)))
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

	_root = Node3D.new()
	_root.name = "DateVignette"
	_root.position = STAGE_ORIGIN
	add_child(_root)
	_add_backdrop(_root)
	PropFactory.build_table_set(_root)
	_add_gift(payload)

	var packed := load("res://scenes/characters/girl.tscn") as PackedScene
	_girl = packed.instantiate() as Node3D if packed else Node3D.new()
	_girl.name = "DateGirl"
	_girl.position = GIRL_DOOR_POSITION
	_root.add_child(_girl)
	assert(ArrivalPipeline.assert_starts_at_door(_girl.position, GIRL_DOOR_POSITION, GIRL_CHAIR_POSITION))
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
	_arrival.begin_intro(GIRL_DOOR_POSITION, GIRL_CHAIR_POSITION, 2.0)
	_sequence = &"intro"
	_sequence_time = 0.0


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
	PropFactory.attach(gift, &"gift_box", Color(color_values[0], color_values[1], color_values[2]))
	_root.add_child(gift)


func _finish_intro() -> void:
	if _sequence != &"intro":
		return
	_arrival.skip_intro_to_ready()
	_sequence = &"ready"
	_sequence_time = 0.0
	if _girl and is_instance_valid(_girl):
		_girl.position = GIRL_CHAIR_POSITION
		if _girl.has_method("set_sitting"):
			_girl.call("set_sitting", true)
		_face_toward_player()
	if _date_ui and is_instance_valid(_date_ui):
		if _date_ui.has_method("show_after_intro"):
			_date_ui.show_after_intro()
		else:
			_date_ui.visible = true
	EventBus.notify.emit("DATE_INTRO_FINISHED", &"date_fx")


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


func _add_backdrop(parent: Node3D) -> void:
	var floor_mi := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(5.0, 0.08, 5.0)
	floor_mi.mesh = floor_mesh
	floor_mi.position = Vector3(0, -0.04, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.36, 0.3)
	floor_mi.material_override = floor_mat
	parent.add_child(floor_mi)

	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(4.5, 3.0, 0.12)
	wall.mesh = wall_mesh
	wall.position = Vector3(0, 1.4, -1.85)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.62, 0.56, 0.52)
	wall.material_override = wall_mat
	parent.add_child(wall)

	var side_l := MeshInstance3D.new()
	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(0.12, 3.0, 4.0)
	side_l.mesh = side_mesh
	side_l.position = Vector3(-2.2, 1.4, -0.2)
	side_l.material_override = wall_mat
	parent.add_child(side_l)

	var side_r := side_l.duplicate() as MeshInstance3D
	side_r.position = Vector3(2.2, 1.4, -0.2)
	parent.add_child(side_r)

	var lamp := OmniLight3D.new()
	lamp.light_energy = 2.0
	lamp.omni_range = 8.0
	lamp.position = Vector3(0, 2.6, 0.2)
	parent.add_child(lamp)

	var fill := OmniLight3D.new()
	fill.light_energy = 0.7
	fill.omni_range = 6.0
	fill.position = Vector3(0.8, 1.8, 1.0)
	parent.add_child(fill)


func _on_close() -> void:
	if _sequence == &"outro":
		return
	_arrival.begin_outro(GIRL_CHAIR_POSITION, GIRL_DOOR_POSITION, 1.2)
	_sequence = &"outro"
	_sequence_time = 0.0
	if _date_ui and is_instance_valid(_date_ui):
		_date_ui.visible = false


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
	_clear()


func _clear() -> void:
	_sequence = &""
	if _date_cam and is_instance_valid(_date_cam):
		_date_cam.current = false
		_date_cam.queue_free()
	_date_cam = null
	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_girl = null
	_girl_parts.clear()
