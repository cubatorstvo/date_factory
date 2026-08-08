class_name DatingRoomVisual
extends Node3D
## One physical date-room presentation slot (MODULE 19). No DatingCore / GirlActor.

@export var slot_index: int = 1
@export var clone_marker_path: NodePath = NodePath("CloneMarker")
@export var girl_marker_path: NodePath = NodePath("GirlMarker")
@export var shutter_path: NodePath = NodePath("Shutter")
@export var room_light_path: NodePath = NodePath("RoomLight")
@export var status_label_path: NodePath = NodePath("StatusLabel")

var _active: bool = false
var _scene_index: int = 0
var _clone_actor: CloneVisualActor = null
var _girl_actor: CloneVisualActor = null


func is_active() -> bool:
	return _active


func get_scene_index() -> int:
	return _scene_index


func get_status_text() -> String:
	var label: Label3D = _status_label()
	if label == null:
		return ""
	return label.text


func get_clone_actor() -> CloneVisualActor:
	return _clone_actor


func get_girl_actor() -> CloneVisualActor:
	return _girl_actor


func ensure_fixture_markers() -> void:
	if _clone_marker() == null:
		var m: Marker3D = Marker3D.new()
		m.name = "CloneMarker"
		m.position = Vector3(-0.45, 0.0, 0.0)
		add_child(m)
		clone_marker_path = NodePath("CloneMarker")
	if _girl_marker() == null:
		var g: Marker3D = Marker3D.new()
		g.name = "GirlMarker"
		g.position = Vector3(0.45, 0.0, 0.0)
		add_child(g)
		girl_marker_path = NodePath("GirlMarker")
	if _shutter() == null:
		var shutter: MeshInstance3D = MeshInstance3D.new()
		shutter.name = "Shutter"
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(2.2, 2.2, 0.05)
		shutter.mesh = box
		shutter.position = Vector3(0.0, 1.1, 1.2)
		add_child(shutter)
		shutter_path = NodePath("Shutter")
	if _room_light() == null:
		var light: OmniLight3D = OmniLight3D.new()
		light.name = "RoomLight"
		light.light_energy = 0.0
		light.omni_range = 3.0
		light.position = Vector3(0.0, 2.2, 0.0)
		add_child(light)
		room_light_path = NodePath("RoomLight")
	if _status_label() == null:
		var label: Label3D = Label3D.new()
		label.name = "StatusLabel"
		label.position = Vector3(0.0, 2.4, 0.8)
		label.font_size = 28
		label.modulate = Color(1, 1, 1, 1)
		label.text = CloneVisualizationTypes.LABEL_ROOM_FREE
		add_child(label)
		status_label_path = NodePath("StatusLabel")


func set_active(active: bool) -> void:
	ensure_fixture_markers()
	_active = active
	if active:
		_open_room()
		_ensure_actors()
		apply_scene(_scene_index)
	else:
		_close_room()


func apply_scene(scene_index: int) -> void:
	_scene_index = posmod(scene_index, 4)
	if not _active:
		return
	var label: Label3D = _status_label()
	if label != null:
		label.text = CloneVisualizationTypes.date_scene_label(_scene_index)
	match _scene_index:
		int(CloneVisualizationTypes.DateScene.CALM):
			_play_both(&"sit_idle", &"sit_idle")
		int(CloneVisualizationTypes.DateScene.OVER_EXPLAINING):
			_play_both(&"seated_gesture", &"gesture_short")
		int(CloneVisualizationTypes.DateScene.SILENT_SUCCESS):
			_play_both(&"sit_idle", &"sit_idle")
		int(CloneVisualizationTypes.DateScene.MUTUAL_CONFUSION):
			_play_both(&"react_confused", &"react_confused")
		_:
			_play_both(&"sit_idle", &"sit_idle")


func clear_actors() -> void:
	if _clone_actor != null and is_instance_valid(_clone_actor):
		_clone_actor.queue_free()
	_clone_actor = null
	if _girl_actor != null and is_instance_valid(_girl_actor):
		_girl_actor.queue_free()
	_girl_actor = null


func count_character_actors() -> int:
	var n: int = 0
	if _clone_actor != null and is_instance_valid(_clone_actor) and _clone_actor.get_character_actor() != null:
		n += 1
	if _girl_actor != null and is_instance_valid(_girl_actor) and _girl_actor.get_character_actor() != null:
		n += 1
	return n


func _open_room() -> void:
	var shutter: Node3D = _shutter()
	if shutter != null:
		shutter.visible = false
	var light: OmniLight3D = _room_light()
	if light != null:
		light.light_energy = 1.2
		light.visible = true


func _close_room() -> void:
	var shutter: Node3D = _shutter()
	if shutter != null:
		shutter.visible = true
	var light: OmniLight3D = _room_light()
	if light != null:
		light.light_energy = 0.0
	var label: Label3D = _status_label()
	if label != null:
		label.text = CloneVisualizationTypes.LABEL_ROOM_FREE
	clear_actors()


func _ensure_actors() -> void:
	var clone_marker: Node3D = _clone_marker()
	var girl_marker: Node3D = _girl_marker()
	if clone_marker == null or girl_marker == null:
		return
	if _clone_actor == null or not is_instance_valid(_clone_actor):
		_clone_actor = CloneVisualActor.new()
		_clone_actor.name = "RoomClone"
		clone_marker.add_child(_clone_actor)
		_clone_actor.ensure_character(
			CloneVisualizationTypes.resolve_clone_appearance_id(),
			&"clone_viz_date"
		)
		_clone_actor.set_visible_presence(true)
	if _girl_actor == null or not is_instance_valid(_girl_actor):
		_girl_actor = CloneVisualActor.new()
		_girl_actor.name = "RoomGirl"
		girl_marker.add_child(_girl_actor)
		_girl_actor.ensure_character(
			CloneVisualizationTypes.girl_appearance_for_slot(slot_index),
			&"clone_viz_anon_female"
		)
		_girl_actor.set_visible_presence(true)


func _play_both(clone_alias: StringName, girl_alias: StringName) -> void:
	if _clone_actor != null and is_instance_valid(_clone_actor):
		_clone_actor.try_play_alias(clone_alias)
	if _girl_actor != null and is_instance_valid(_girl_actor):
		_girl_actor.try_play_alias(girl_alias)


func _clone_marker() -> Node3D:
	return get_node_or_null(clone_marker_path) as Node3D


func _girl_marker() -> Node3D:
	return get_node_or_null(girl_marker_path) as Node3D


func _shutter() -> Node3D:
	return get_node_or_null(shutter_path) as Node3D


func _room_light() -> OmniLight3D:
	return get_node_or_null(room_light_path) as OmniLight3D


func _status_label() -> Label3D:
	return get_node_or_null(status_label_path) as Label3D
