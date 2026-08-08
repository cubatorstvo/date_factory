class_name CloneVisualizationController
extends Node3D
## Lab-local aggregate clone visualization (MODULE 19).
## Presentation only: reads GameState / CloneIncremental signals, never mutates economy.

var _rooms: Array[DatingRoomVisual] = []
var _work_actors: Array[CloneVisualActor] = []
var _free_actors: Array[CloneVisualActor] = []
var _mass_actors: Array[CloneVisualActor] = []
var _work_markers: Array[Marker3D] = []
var _free_markers: Array[Marker3D] = []
var _work_exit: Marker3D = null
var _mass_spawn: Marker3D = null
var _mass_exit: Marker3D = null
var _external_label: Label3D = null
var _production_label: Label3D = null
var _machine_pulse: MeshInstance3D = null

var _visible_dating: int = 0
var _visible_work: int = 0
var _visible_free: int = 0
var _external_dating: int = 0
var _external_work: int = 0
var _external_free: int = 0
var _external_total: int = 0

var _global_scene_cycle: int = 0
var _work_rr_index: int = 0
var _signals_connected: bool = false
var _production_feedback_active: bool = false
var _fixtures_ready: bool = false

var _date_timer: Timer = null
var _work_timer: Timer = null
var _mass_timer: Timer = null


func _enter_tree() -> void:
	# World may reparent laboratory (exit_tree then enter_tree without _ready).
	add_to_group(String(CloneVisualizationTypes.GROUP_CONTROLLER))
	_connect_signals()
	if _fixtures_ready:
		refresh_from_counts()


func _ready() -> void:
	_ensure_fixtures()
	_ensure_timers()
	_connect_signals()
	refresh_from_counts()


func _exit_tree() -> void:
	_disconnect_signals()
	if is_in_group(String(CloneVisualizationTypes.GROUP_CONTROLLER)):
		remove_from_group(String(CloneVisualizationTypes.GROUP_CONTROLLER))


func ensure_active() -> void:
	add_to_group(String(CloneVisualizationTypes.GROUP_CONTROLLER))
	_ensure_fixtures()
	_ensure_timers()
	_connect_signals()
	refresh_from_counts()


func get_visible_dating() -> int:
	return _visible_dating


func get_visible_work() -> int:
	return _visible_work


func get_visible_free() -> int:
	return _visible_free


func get_external_dating() -> int:
	return _external_dating


func get_external_work() -> int:
	return _external_work


func get_external_free() -> int:
	return _external_free


func get_external_total() -> int:
	return _external_total


func get_global_scene_cycle() -> int:
	return _global_scene_cycle


func get_room(slot_index: int) -> DatingRoomVisual:
	if slot_index < 1 or slot_index > _rooms.size():
		return null
	return _rooms[slot_index - 1]


func is_room_active(slot_index: int) -> bool:
	var room: DatingRoomVisual = get_room(slot_index)
	return room != null and room.is_active()


func get_room_scene_index(slot_index: int) -> int:
	var room: DatingRoomVisual = get_room(slot_index)
	if room == null:
		return -1
	return room.get_scene_index()


func get_external_label_text() -> String:
	if _external_label == null:
		return ""
	return _external_label.text


func is_production_feedback_active() -> bool:
	return _production_feedback_active


func get_production_feedback_text() -> String:
	if _production_label == null:
		return ""
	return _production_label.text


func count_presentation_character_actors() -> int:
	var n: int = 0
	for room in _rooms:
		if room != null and is_instance_valid(room):
			n += room.count_character_actors()
	for actor in _work_actors:
		if actor != null and is_instance_valid(actor) and actor.get_character_actor() != null:
			n += 1
	for actor in _free_actors:
		if actor != null and is_instance_valid(actor) and actor.get_character_actor() != null:
			n += 1
	for actor in _mass_actors:
		if actor != null and is_instance_valid(actor) and actor.get_character_actor() != null:
			n += 1
	return n


func refresh_from_counts() -> void:
	_ensure_fixtures()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		_apply_counts(0, 0, 0, 0)
		return
	var dating: int = int(gs.call("get_clones_dating"))
	var working: int = int(gs.call("get_clones_working"))
	var free_count: int = int(gs.call("get_free_clones"))
	var total: int = int(gs.call("get_total_clones"))
	_apply_counts(total, working, dating, free_count)


func advance_date_scenes_for_test(ticks: int = 1) -> void:
	for _i in range(maxi(ticks, 0)):
		_on_date_scene_tick()


func advance_work_departure_for_test() -> void:
	_on_work_departure_tick()


func advance_mass_flow_for_test() -> void:
	_on_mass_flow_tick()


func get_mass_interval() -> float:
	if _mass_timer == null:
		return CloneVisualizationTypes.mass_interval_for_external(_external_total)
	return _mass_timer.wait_time


func _apply_counts(_total: int, working: int, dating: int, free_count: int) -> void:
	_visible_dating = mini(dating, CloneVisualizationTypes.MAX_LOCAL_DATE_SLOTS)
	_visible_work = mini(working, CloneVisualizationTypes.MAX_LOCAL_WORK_VISUALS)
	_visible_free = mini(free_count, CloneVisualizationTypes.MAX_LOCAL_FREE_VISUALS)
	_external_dating = maxi(0, dating - CloneVisualizationTypes.MAX_LOCAL_DATE_SLOTS)
	_external_work = maxi(0, working - CloneVisualizationTypes.MAX_LOCAL_WORK_VISUALS)
	_external_free = maxi(0, free_count - CloneVisualizationTypes.MAX_LOCAL_FREE_VISUALS)
	_external_total = _external_dating + _external_work + _external_free
	_sync_dating_rooms()
	_sync_work_actors()
	_sync_free_actors()
	_update_external_label()
	_update_mass_timer()
	_sync_mass_actors_capacity()


func _sync_dating_rooms() -> void:
	for i in range(_rooms.size()):
		var slot: int = i + 1
		var room: DatingRoomVisual = _rooms[i]
		if room == null or not is_instance_valid(room):
			continue
		var should_active: bool = slot <= _visible_dating
		if room.is_active() != should_active:
			room.set_active(should_active)
		elif should_active:
			room.apply_scene((_global_scene_cycle + slot) % 4)


func _sync_work_actors() -> void:
	while _work_actors.size() < _visible_work:
		var idx: int = _work_actors.size()
		var marker: Marker3D = _work_markers[idx] if idx < _work_markers.size() else null
		if marker == null:
			break
		var actor: CloneVisualActor = CloneVisualActor.new()
		actor.name = "WorkClone_%02d" % (idx + 1)
		marker.add_child(actor)
		actor.ensure_character(
			CloneVisualizationTypes.resolve_clone_appearance_id(),
			&"clone_viz_work"
		)
		actor.set_visible_presence(true)
		actor.remember_home()
		_work_actors.append(actor)
	while _work_actors.size() > _visible_work:
		var last: CloneVisualActor = _work_actors.pop_back()
		if last != null and is_instance_valid(last):
			last.queue_free()
	if _work_timer != null:
		_work_timer.paused = _visible_work <= 0


func _sync_free_actors() -> void:
	while _free_actors.size() < _visible_free:
		var idx: int = _free_actors.size()
		var marker: Marker3D = _free_markers[idx] if idx < _free_markers.size() else null
		if marker == null:
			break
		var actor: CloneVisualActor = CloneVisualActor.new()
		actor.name = "FreeClone_%02d" % (idx + 1)
		marker.add_child(actor)
		actor.ensure_character(
			CloneVisualizationTypes.resolve_clone_appearance_id(),
			&"clone_viz_free"
		)
		actor.set_visible_presence(true)
		_free_actors.append(actor)
	while _free_actors.size() > _visible_free:
		var last: CloneVisualActor = _free_actors.pop_back()
		if last != null and is_instance_valid(last):
			last.queue_free()


func _sync_mass_actors_capacity() -> void:
	if _external_total <= 0:
		_clear_mass_actors()
		if _mass_timer != null:
			_mass_timer.paused = true
		return
	if _mass_timer != null:
		_mass_timer.paused = false


func _update_external_label() -> void:
	if _external_label == null:
		return
	if _external_total <= 0:
		_external_label.visible = false
		_external_label.text = "%s0" % CloneVisualizationTypes.LABEL_EXTERNAL_PREFIX
		return
	_external_label.visible = true
	_external_label.text = "%s%d" % [CloneVisualizationTypes.LABEL_EXTERNAL_PREFIX, _external_total]


func _update_mass_timer() -> void:
	if _mass_timer == null:
		return
	var interval: float = CloneVisualizationTypes.mass_interval_for_external(_external_total)
	if not is_equal_approx(_mass_timer.wait_time, interval):
		_mass_timer.wait_time = interval


func _on_date_scene_tick() -> void:
	_global_scene_cycle += 1
	for i in range(_rooms.size()):
		var room: DatingRoomVisual = _rooms[i]
		if room == null or not is_instance_valid(room) or not room.is_active():
			continue
		var slot: int = i + 1
		room.apply_scene((_global_scene_cycle + slot) % 4)


func _on_work_departure_tick() -> void:
	if _visible_work <= 0 or _work_actors.is_empty() or _work_exit == null:
		return
	var start_idx: int = _work_rr_index % _work_actors.size()
	var chosen: CloneVisualActor = null
	for offset in range(_work_actors.size()):
		var idx: int = (start_idx + offset) % _work_actors.size()
		var candidate: CloneVisualActor = _work_actors[idx]
		if candidate != null and is_instance_valid(candidate) and not candidate.is_busy():
			chosen = candidate
			_work_rr_index = idx + 1
			break
	if chosen == null:
		return
	chosen.tween_to_and_restore(_work_exit.global_position, CloneVisualizationTypes.WORK_TWEEN_SEC)


func _on_mass_flow_tick() -> void:
	if _external_total <= 0:
		return
	if _mass_spawn == null or _mass_exit == null:
		return
	_prune_mass_actors()
	if _mass_actors.size() >= CloneVisualizationTypes.MAX_MASS_FLOW_VISUALS:
		return
	var actor: CloneVisualActor = CloneVisualActor.new()
	actor.name = "MassClone_%d" % Time.get_ticks_msec()
	_mass_spawn.add_child(actor)
	actor.global_position = _mass_spawn.global_position
	actor.ensure_character(
		CloneVisualizationTypes.resolve_clone_appearance_id(),
		&"clone_viz_mass"
	)
	actor.set_visible_presence(true)
	_mass_actors.append(actor)
	_run_mass_trip(actor)


func _run_mass_trip(actor: CloneVisualActor) -> void:
	if actor == null or not is_instance_valid(actor) or _mass_exit == null:
		return
	await actor.tween_to_exit_and_free(_mass_exit.global_position, CloneVisualizationTypes.MASS_TWEEN_SEC)
	_mass_actors.erase(actor)


func _on_clone_counts_changed(_total: int, _working: int, _dating: int, _free: int) -> void:
	refresh_from_counts()


func _on_state_reset() -> void:
	_global_scene_cycle = 0
	_work_rr_index = 0
	_production_feedback_active = false
	if _production_label != null:
		_production_label.visible = false
		_production_label.text = ""
	if _machine_pulse != null:
		_machine_pulse.visible = false
	refresh_from_counts()


func _on_clone_produced(_new_total: int) -> void:
	_show_production_feedback()
	refresh_from_counts()


func _show_production_feedback() -> void:
	_production_feedback_active = true
	if _production_label != null:
		_production_label.text = CloneVisualizationTypes.LABEL_PRODUCTION_READY
		_production_label.visible = true
	if _machine_pulse != null:
		_machine_pulse.visible = true
	var token: int = Time.get_ticks_msec()
	if _machine_pulse != null:
		_machine_pulse.set_meta("pulse_token", token)
	await get_tree().create_timer(CloneVisualizationTypes.PRODUCTION_PULSE_SEC).timeout
	if _machine_pulse != null and int(_machine_pulse.get_meta("pulse_token", 0)) == token:
		_machine_pulse.visible = false
	await get_tree().create_timer(
		maxf(0.0, CloneVisualizationTypes.PRODUCTION_LABEL_SEC - CloneVisualizationTypes.PRODUCTION_PULSE_SEC)
	).timeout
	if _production_label != null:
		_production_label.visible = false
	_production_feedback_active = false


func _connect_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.connect("clone_counts_changed", _on_clone_counts_changed)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_signal("clone_produced") and not ci.is_connected("clone_produced", _on_clone_produced):
		ci.connect("clone_produced", _on_clone_produced)
	_signals_connected = true


func _disconnect_signals() -> void:
	if not _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("clone_counts_changed") and gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.disconnect("clone_counts_changed", _on_clone_counts_changed)
		if gs.has_signal("state_reset") and gs.is_connected("state_reset", _on_state_reset):
			gs.disconnect("state_reset", _on_state_reset)
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_signal("clone_produced") and ci.is_connected("clone_produced", _on_clone_produced):
		ci.disconnect("clone_produced", _on_clone_produced)
	_signals_connected = false


func _ensure_timers() -> void:
	if _date_timer == null:
		_date_timer = Timer.new()
		_date_timer.name = "DateSceneTimer"
		_date_timer.wait_time = CloneVisualizationTypes.DATE_SCENE_INTERVAL
		_date_timer.autostart = true
		_date_timer.one_shot = false
		add_child(_date_timer)
		_date_timer.timeout.connect(_on_date_scene_tick)
	if _work_timer == null:
		_work_timer = Timer.new()
		_work_timer.name = "WorkDepartureTimer"
		_work_timer.wait_time = CloneVisualizationTypes.WORK_DEPARTURE_INTERVAL
		_work_timer.autostart = true
		_work_timer.one_shot = false
		add_child(_work_timer)
		_work_timer.timeout.connect(_on_work_departure_tick)
	if _mass_timer == null:
		_mass_timer = Timer.new()
		_mass_timer.name = "MassFlowTimer"
		_mass_timer.wait_time = CloneVisualizationTypes.MASS_INTERVAL_BASE
		_mass_timer.autostart = true
		_mass_timer.one_shot = false
		add_child(_mass_timer)
		_mass_timer.timeout.connect(_on_mass_flow_tick)


func _ensure_fixtures() -> void:
	if _fixtures_ready and not _rooms.is_empty():
		return
	_rooms.clear()
	_work_markers.clear()
	_free_markers.clear()
	var search_roots: Array[Node] = _marker_search_roots()
	for slot in range(1, CloneVisualizationTypes.MAX_LOCAL_DATE_SLOTS + 1):
		var room_name: String = CloneVisualizationTypes.slot_node_name(slot)
		var found: Node = _find_in_roots(search_roots, room_name)
		var room: DatingRoomVisual = _adopt_dating_room(found, slot)
		if room == null:
			room = DatingRoomVisual.new()
			room.name = room_name
			room.slot_index = slot
			room.position = Vector3(float((slot - 1) % 5) * 2.8 - 5.6, 0.0, float(slot - 1) / 5.0 * -3.2 - 2.0)
			add_child(room)
		room.slot_index = slot
		room.ensure_fixture_markers()
		_rooms.append(room)
	for i in range(1, CloneVisualizationTypes.MAX_LOCAL_WORK_VISUALS + 1):
		var marker: Marker3D = _find_in_roots(search_roots, CloneVisualizationTypes.work_marker_name(i)) as Marker3D
		if marker == null:
			marker = Marker3D.new()
			marker.name = CloneVisualizationTypes.work_marker_name(i)
			marker.position = Vector3(float(i) * 1.2 - 2.0, 0.0, 4.0)
			add_child(marker)
		_work_markers.append(marker)
	_work_exit = _find_in_roots(search_roots, CloneVisualizationTypes.WORK_EXIT_NAME) as Marker3D
	if _work_exit == null:
		_work_exit = Marker3D.new()
		_work_exit.name = CloneVisualizationTypes.WORK_EXIT_NAME
		_work_exit.position = Vector3(0.0, 0.0, 8.0)
		add_child(_work_exit)
	for i in range(1, CloneVisualizationTypes.MAX_LOCAL_FREE_VISUALS + 1):
		var marker: Marker3D = _find_in_roots(search_roots, CloneVisualizationTypes.free_marker_name(i)) as Marker3D
		if marker == null:
			marker = Marker3D.new()
			marker.name = CloneVisualizationTypes.free_marker_name(i)
			marker.position = Vector3(float(i) * 1.0 - 1.5, 0.0, 1.5)
			add_child(marker)
		_free_markers.append(marker)
	_mass_spawn = _find_in_roots(search_roots, CloneVisualizationTypes.MASS_SPAWN_NAME) as Marker3D
	if _mass_spawn == null:
		_mass_spawn = Marker3D.new()
		_mass_spawn.name = CloneVisualizationTypes.MASS_SPAWN_NAME
		_mass_spawn.position = Vector3(6.0, 0.0, 2.0)
		add_child(_mass_spawn)
	_mass_exit = _find_in_roots(search_roots, CloneVisualizationTypes.MASS_EXIT_NAME) as Marker3D
	if _mass_exit == null:
		_mass_exit = Marker3D.new()
		_mass_exit.name = CloneVisualizationTypes.MASS_EXIT_NAME
		_mass_exit.position = Vector3(10.0, 0.0, 2.0)
		add_child(_mass_exit)
	_external_label = _find_in_roots(search_roots, CloneVisualizationTypes.EXTERNAL_LABEL_NAME) as Label3D
	if _external_label == null:
		_external_label = _find_in_roots(search_roots, "SignExternalFlow") as Label3D
	if _external_label == null:
		_external_label = Label3D.new()
		_external_label.name = CloneVisualizationTypes.EXTERNAL_LABEL_NAME
		_external_label.position = Vector3(8.0, 2.5, 2.0)
		_external_label.font_size = 32
		add_child(_external_label)
	_production_label = _find_in_roots(search_roots, CloneVisualizationTypes.PRODUCTION_LABEL_NAME) as Label3D
	if _production_label == null:
		_production_label = Label3D.new()
		_production_label.name = CloneVisualizationTypes.PRODUCTION_LABEL_NAME
		_production_label.position = Vector3(0.0, 2.8, 0.0)
		_production_label.font_size = 36
		_production_label.visible = false
		add_child(_production_label)
	_machine_pulse = _find_in_roots(search_roots, CloneVisualizationTypes.MACHINE_PULSE_NAME) as MeshInstance3D
	if _machine_pulse == null:
		_machine_pulse = MeshInstance3D.new()
		_machine_pulse.name = CloneVisualizationTypes.MACHINE_PULSE_NAME
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		_machine_pulse.mesh = sphere
		_machine_pulse.position = Vector3(0.0, 1.5, -0.5)
		_machine_pulse.visible = false
		add_child(_machine_pulse)
	_fixtures_ready = true


func _marker_search_roots() -> Array[Node]:
	var roots: Array[Node] = [self]
	var parent_n: Node = get_parent()
	if parent_n != null:
		roots.append(parent_n)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_current_location"):
		var loc: Node = world.call("get_current_location") as Node
		if loc != null:
			roots.append(loc)
	var tree: SceneTree = get_tree()
	if tree != null and tree.current_scene != null:
		roots.append(tree.current_scene)
	return roots


func _adopt_dating_room(found: Node, slot: int) -> DatingRoomVisual:
	if found == null:
		return null
	var as_room: DatingRoomVisual = found as DatingRoomVisual
	if as_room != null:
		return as_room
	if not (found is Node3D):
		return null
	var script_res: Script = load("res://game/clone_visualization/dating_room_visual.gd") as Script
	if script_res == null:
		return null
	found.set_script(script_res)
	as_room = found as DatingRoomVisual
	if as_room == null:
		return null
	as_room.slot_index = slot
	if found.get_node_or_null("clone_stand") != null:
		as_room.clone_marker_path = NodePath("clone_stand")
	if found.get_node_or_null("girl_stand") != null:
		as_room.girl_marker_path = NodePath("girl_stand")
	if found.get_node_or_null("Shutter") != null:
		as_room.shutter_path = NodePath("Shutter")
	if found.get_node_or_null("RoomLight") != null:
		as_room.room_light_path = NodePath("RoomLight")
	if found.get_node_or_null("LabelCaption") != null:
		as_room.status_label_path = NodePath("LabelCaption")
	elif found.get_node_or_null("StatusLabel") != null:
		as_room.status_label_path = NodePath("StatusLabel")
	return as_room


func _find_in_roots(roots: Array[Node], node_name: String) -> Node:
	for root in roots:
		if root == null or not is_instance_valid(root):
			continue
		if root.name == node_name:
			return root
		var found: Node = root.find_child(node_name, true, false)
		if found != null:
			return found
	return null


func _clear_mass_actors() -> void:
	for actor in _mass_actors:
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	_mass_actors.clear()


func _prune_mass_actors() -> void:
	var kept: Array[CloneVisualActor] = []
	for actor in _mass_actors:
		if actor != null and is_instance_valid(actor):
			kept.append(actor)
	_mass_actors = kept
