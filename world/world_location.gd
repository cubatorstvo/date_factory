class_name WorldLocation
extends Node3D
## Scene-root contract for a canonical world location (MODULE 12).

@export var location_id: StringName = &""

var _player_spawns: Dictionary = {}
var _npc_spawns: Dictionary = {}
var _story_points: Dictionary = {}
var _marker_errors: Array[String] = []


func _ready() -> void:
	_rebuild_marker_index()
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("register_location"):
		world.call("register_location", self)
	refresh_feature_gates()


func _rebuild_marker_index() -> void:
	_player_spawns.clear()
	_npc_spawns.clear()
	_story_points.clear()
	_marker_errors.clear()
	_collect_markers(self)


func _collect_markers(node: Node) -> void:
	if node is PlayerSpawnPoint:
		var ps: PlayerSpawnPoint = node as PlayerSpawnPoint
		if String(ps.spawn_id) == "":
			_marker_errors.append("empty PlayerSpawnPoint.spawn_id at %s" % ps.get_path())
		elif _player_spawns.has(ps.spawn_id):
			_marker_errors.append("duplicate PlayerSpawnPoint id %s" % String(ps.spawn_id))
		else:
			_player_spawns[ps.spawn_id] = ps
	elif node is NpcSpawnPoint:
		var ns: NpcSpawnPoint = node as NpcSpawnPoint
		if String(ns.spawn_id) == "":
			_marker_errors.append("empty NpcSpawnPoint.spawn_id at %s" % ns.get_path())
		elif _npc_spawns.has(ns.spawn_id):
			_marker_errors.append("duplicate NpcSpawnPoint id %s" % String(ns.spawn_id))
		else:
			_npc_spawns[ns.spawn_id] = ns
	elif node is StoryEventPoint:
		var sp: StoryEventPoint = node as StoryEventPoint
		if String(sp.event_point_id) == "":
			_marker_errors.append("empty StoryEventPoint.event_point_id at %s" % sp.get_path())
		elif _story_points.has(sp.event_point_id):
			_marker_errors.append("duplicate StoryEventPoint id %s" % String(sp.event_point_id))
		else:
			_story_points[sp.event_point_id] = sp
	for child in node.get_children():
		_collect_markers(child)


func get_player_spawn(spawn_id: StringName) -> PlayerSpawnPoint:
	if _player_spawns.is_empty() and _npc_spawns.is_empty() and _story_points.is_empty():
		_rebuild_marker_index()
	return _player_spawns.get(spawn_id) as PlayerSpawnPoint


func get_npc_spawn(spawn_id: StringName) -> NpcSpawnPoint:
	if _player_spawns.is_empty() and _npc_spawns.is_empty() and _story_points.is_empty():
		_rebuild_marker_index()
	return _npc_spawns.get(spawn_id) as NpcSpawnPoint


func get_story_event_point(point_id: StringName) -> StoryEventPoint:
	if _player_spawns.is_empty() and _npc_spawns.is_empty() and _story_points.is_empty():
		_rebuild_marker_index()
	return _story_points.get(point_id) as StoryEventPoint


func validate_markers() -> Array[String]:
	_rebuild_marker_index()
	var errors: Array[String] = []
	for e in _marker_errors:
		errors.append(e)
	if not _player_spawns.has(&"spawn_default"):
		errors.append("missing spawn_default")
	return errors


func refresh_feature_gates() -> void:
	_refresh_gates(self)


func _refresh_gates(node: Node) -> void:
	if node is WorldFeatureGate:
		var gate: WorldFeatureGate = node as WorldFeatureGate
		gate.refresh()
	elif node is WorldTransition:
		var tr: WorldTransition = node as WorldTransition
		tr.refresh_access_prompt()
	for child in node.get_children():
		_refresh_gates(child)


func find_feature_gate(feature: StoryTypes.StoryFeature) -> WorldFeatureGate:
	return _find_gate(self, feature)


func _find_gate(node: Node, feature: StoryTypes.StoryFeature) -> WorldFeatureGate:
	if node is WorldFeatureGate:
		var gate: WorldFeatureGate = node as WorldFeatureGate
		if gate.required_feature == feature:
			return gate
	for child in node.get_children():
		var found: WorldFeatureGate = _find_gate(child, feature)
		if found != null:
			return found
	return null
