extends Node3D
class_name StoryAnchorHighlight
## Lights the current story objective only — not every NPC.

const MARKER_NAME: String = "_StoryAnchorMarker"

var _marker: Node3D = null


func _ready() -> void:
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("stage_objective_changed"):
		if not story.is_connected("stage_objective_changed", _on_objective_changed):
			story.connect("stage_objective_changed", _on_objective_changed)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_signal("location_changed"):
		if not world.is_connected("location_changed", _on_location_changed):
			world.connect("location_changed", _on_location_changed)
	call_deferred("refresh")


func _on_objective_changed(_progress: StoryStageProgress) -> void:
	refresh()


func _on_location_changed(_new_id: StringName, _prev: StringName) -> void:
	call_deferred("refresh")


func refresh() -> void:
	_clear_marker()
	var target: Node3D = _resolve_target()
	if target == null or not is_instance_valid(target):
		return
	_attach_marker(target)


func _clear_marker() -> void:
	if _marker != null and is_instance_valid(_marker):
		var parent: Node = _marker.get_parent()
		if parent != null:
			parent.remove_child(_marker)
		_marker.free()
	_marker = null


func _attach_marker(target: Node3D) -> void:
	var marker: Node3D = Node3D.new()
	marker.name = MARKER_NAME
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(1.0, 0.82, 0.35, 1.0)
	light.light_energy = 2.4
	light.omni_range = 3.2
	light.position = Vector3(0.0, 2.1, 0.0)
	marker.add_child(light)
	var label: Label3D = Label3D.new()
	label.text = "ЦЕЛЬ"
	label.font_size = 32
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.92, 0.55, 1.0)
	label.outline_modulate = Color(0.12, 0.08, 0.04, 1.0)
	label.outline_size = 8
	label.position = Vector3(0.0, 2.45, 0.0)
	marker.add_child(label)
	target.add_child(marker)
	_marker = marker


func _resolve_target() -> Node3D:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_current_location"):
		return null
	var loc_v: Variant = world.call("get_current_location")
	var loc: Node = loc_v as Node
	if loc == null:
		return null
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("get_current_progress"):
		return null
	var progress: StoryStageProgress = story.call("get_current_progress") as StoryStageProgress
	if progress == null:
		return null
	var oid: StringName = progress.objective_id
	match oid:
		&"pick_up_card":
			return _find_named(loc, "MorningHeartCard")
		&"find_neighbor":
			var mentor: Node3D = _find_named(loc, "NeighborMentor")
			if mentor != null and mentor.visible:
				return mentor
			return _find_named(loc, "TutorialNeighbor")
		&"prepare_food":
			return _find_named(loc, "Fridge")
		&"prepare_drink":
			return _find_named(loc, "Window")
		&"prepare_outfit":
			return _find_named(loc, "Wardrobe")
		&"start_tutorial_date":
			return _find_named(loc, "DiningTable")
		&"earn_hearts_for_actress":
			return _resolve_hearts_or_work(loc)
		&"find_actress":
			return _resolve_story_girl(loc, StoryIds.GIRL_ACTRESS, &"appearance_space")
		&"defeat_actress_rival":
			return _resolve_rival_or_girl(loc, progress, &"appearance_space")
		&"defeat_mine_rival", &"find_mine_boss":
			return _resolve_rival_or_girl(loc, progress, &"salary_mine")
		&"defeat_editor_rival", &"find_editor":
			return _resolve_rival_or_girl(loc, progress, &"city_hub")
		_:
			pass
	if _should_mention_work():
		var desk: Node3D = _find_day_job(loc)
		if desk != null:
			return desk
	if String(progress.story_rival_id) != "" and not progress.rival_defeated:
		var rival: Node3D = _find_rival(loc, progress.story_rival_id)
		if rival != null:
			return rival
	if String(progress.story_girl_id) != "":
		var girl: Node3D = _find_girl(loc, progress.story_girl_id)
		if girl != null:
			return girl
	return null


func _resolve_hearts_or_work(loc: Node) -> Node3D:
	if _should_mention_work():
		var desk: Node3D = _find_day_job(loc)
		if desk != null:
			return desk
	var city_door: Node3D = _find_transition(loc, &"city_hub")
	if city_door != null:
		return city_door
	return _find_transition(loc, &"appearance_space")


func _resolve_story_girl(loc: Node, girl_id: StringName, fallback_location: StringName) -> Node3D:
	var girl: Node3D = _find_girl(loc, girl_id)
	if girl != null:
		return girl
	return _find_transition(loc, fallback_location)


func _resolve_rival_or_girl(
	loc: Node,
	progress: StoryStageProgress,
	fallback_location: StringName,
) -> Node3D:
	if String(progress.story_rival_id) != "" and not progress.rival_defeated:
		var rival: Node3D = _find_rival(loc, progress.story_rival_id)
		if rival != null:
			return rival
		return _find_transition(loc, fallback_location)
	return _resolve_story_girl(loc, progress.story_girl_id, fallback_location)


func _should_mention_work() -> bool:
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("should_mention_day_job"):
		return bool(story.call("should_mention_day_job"))
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("get_day_job_last_claim_day"):
		return false
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null or not day.has_method("get_current_day"):
		return false
	return int(gs.call("get_day_job_last_claim_day")) != int(day.call("get_current_day"))


func _find_named(root: Node, node_name: String) -> Node3D:
	var found: Node = root.find_child(node_name, true, false)
	if found is Node3D:
		return found as Node3D
	return null


func _find_day_job(root: Node) -> Node3D:
	var grouped: Array[Node] = root.get_tree().get_nodes_in_group("day_job_desk")
	for n in grouped:
		if n is Node3D and root.is_ancestor_of(n):
			return n as Node3D
	return _find_named(root, "AgencyOffice")


func _find_transition(root: Node, location_id: StringName) -> Node3D:
	var nodes: Array[Node] = root.find_children("*", "WorldTransition", true, false)
	for n in nodes:
		var tr: WorldTransition = n as WorldTransition
		if tr != null and tr.target_location_id == location_id:
			return tr
	return null


func _find_girl(root: Node, girl_id: StringName) -> Node3D:
	if String(girl_id) == "":
		return null
	var nodes: Array[Node] = root.find_children("*", "GirlActor", true, false)
	for n in nodes:
		var actor: GirlActor = n as GirlActor
		if actor != null and actor.girl_id == girl_id and actor.visible:
			return actor
	return null


func _find_rival(root: Node, rival_id: StringName) -> Node3D:
	if String(rival_id) == "":
		return null
	var nodes: Array[Node] = root.find_children("*", "RivalActor", true, false)
	for n in nodes:
		if n == null:
			continue
		if n.get("rival_id") == rival_id:
			return n as Node3D
	return null
