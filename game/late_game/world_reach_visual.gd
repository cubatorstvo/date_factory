class_name WorldReachVisual
extends Node3D
## Presentation-only Reach display for Production Area (MODULE 20).
## Never mutates GameState.

@export var reach_label_path: NodePath = NodePath("ReachDisplay")

var _label: Label3D = null
var _signals_connected: bool = false


func _enter_tree() -> void:
	# World may reparent production_area (exit_tree then enter_tree without _ready).
	_connect_signals()
	if _label != null:
		_refresh()


func _ready() -> void:
	_label = get_node_or_null(reach_label_path) as Label3D
	if _label == null:
		_label = find_child("ReachDisplay", true, false) as Label3D
	_connect_signals()
	_refresh()


func _exit_tree() -> void:
	_disconnect_signals()


func _connect_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("world_reach_changed"):
		if not gs.is_connected("world_reach_changed", _on_world_reach_changed):
			gs.connect("world_reach_changed", _on_world_reach_changed)
		_signals_connected = true


func _disconnect_signals() -> void:
	if not _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("world_reach_changed"):
		if gs.is_connected("world_reach_changed", _on_world_reach_changed):
			gs.disconnect("world_reach_changed", _on_world_reach_changed)
	_signals_connected = false


func _on_world_reach_changed(_new_reach: int, _delta: int) -> void:
	_refresh()


func _refresh() -> void:
	if _label == null or not is_instance_valid(_label):
		_label = get_node_or_null(reach_label_path) as Label3D
		if _label == null:
			_label = find_child("ReachDisplay", true, false) as Label3D
	if _label == null or not is_instance_valid(_label):
		return
	var gs: Node = get_node_or_null("/root/GameState")
	var reach: int = 0
	if gs != null and gs.has_method("get_world_reach"):
		reach = int(gs.call("get_world_reach"))
	_label.text = "Охват Земли: %d" % reach
	_update_threshold_placeholders(reach)


func _update_threshold_placeholders(reach: int) -> void:
	for threshold in [0, 25, 50, 75, 100]:
		var node: Node = find_child("ReachPlaceholder_%d" % threshold, true, false)
		if node is CanvasItem:
			(node as CanvasItem).visible = reach >= threshold
		elif node is Node3D:
			(node as Node3D).visible = reach >= threshold
