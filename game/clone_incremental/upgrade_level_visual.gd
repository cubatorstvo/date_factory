class_name UpgradeLevelVisual
extends Node3D
## Presentation-only upgrade tier visibility (MODULE 25).
## Shows/hides self (or a target node) when GameState upgrade level >= minimum.
## Never mutates GameState / save / formulas.


enum UpgradeScope {
	LOCAL_CLONE = 0,
	GLOBAL = 1,
}


@export var scope: UpgradeScope = UpgradeScope.LOCAL_CLONE
## Local: CloneIncrementalTypes.UpgradeType (0..2). Global: LateGameTypes.GlobalUpgradeType (0..2).
@export var upgrade_type: int = 0
@export var minimum_level: int = 1
## Empty path = this node. Otherwise show/hide the resolved Node3D / CanvasItem.
@export var target_path: NodePath = NodePath("")

var _signals_connected: bool = false


func _enter_tree() -> void:
	# World may reparent locations (exit_tree then enter_tree without _ready).
	_connect_signals()
	_refresh()


func _ready() -> void:
	_connect_signals()
	_refresh()


func _exit_tree() -> void:
	_disconnect_signals()


func _connect_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if gs.has_signal("clone_upgrade_changed"):
		if not gs.is_connected("clone_upgrade_changed", _on_clone_upgrade_changed):
			gs.connect("clone_upgrade_changed", _on_clone_upgrade_changed)
	if gs.has_signal("global_upgrade_changed"):
		if not gs.is_connected("global_upgrade_changed", _on_global_upgrade_changed):
			gs.connect("global_upgrade_changed", _on_global_upgrade_changed)
	if gs.has_signal("state_restored"):
		if not gs.is_connected("state_restored", _on_state_restored):
			gs.connect("state_restored", _on_state_restored)
	if gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	_signals_connected = true


func _disconnect_signals() -> void:
	if not _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("clone_upgrade_changed") and gs.is_connected("clone_upgrade_changed", _on_clone_upgrade_changed):
			gs.disconnect("clone_upgrade_changed", _on_clone_upgrade_changed)
		if gs.has_signal("global_upgrade_changed") and gs.is_connected("global_upgrade_changed", _on_global_upgrade_changed):
			gs.disconnect("global_upgrade_changed", _on_global_upgrade_changed)
		if gs.has_signal("state_restored") and gs.is_connected("state_restored", _on_state_restored):
			gs.disconnect("state_restored", _on_state_restored)
		if gs.has_signal("state_reset") and gs.is_connected("state_reset", _on_state_reset):
			gs.disconnect("state_reset", _on_state_reset)
	_signals_connected = false


func _on_clone_upgrade_changed(changed_type: int, _new_level: int, _previous_level: int) -> void:
	if scope != UpgradeScope.LOCAL_CLONE:
		return
	if changed_type != upgrade_type:
		return
	_refresh()


func _on_global_upgrade_changed(changed_type: int, _new_level: int, _previous_level: int) -> void:
	if scope != UpgradeScope.GLOBAL:
		return
	if changed_type != upgrade_type:
		return
	_refresh()


func _on_state_restored() -> void:
	_refresh()


func _on_state_reset() -> void:
	_refresh()


func _refresh() -> void:
	var level: int = _current_level()
	var should_show: bool = level >= minimum_level
	_apply_visibility(should_show)


func _current_level() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	if scope == UpgradeScope.GLOBAL:
		match upgrade_type:
			int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION):
				return int(gs.call("get_global_production_upgrade_level"))
			int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK):
				return int(gs.call("get_global_work_upgrade_level"))
			int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING):
				return int(gs.call("get_global_dating_upgrade_level"))
			_:
				return 0
	match upgrade_type:
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED):
			return int(gs.call("get_clone_production_upgrade_level"))
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY):
			return int(gs.call("get_clone_work_upgrade_level"))
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY):
			return int(gs.call("get_clone_dating_upgrade_level"))
		_:
			return 0


func _apply_visibility(should_show: bool) -> void:
	var target: Node = _resolve_target()
	if target == null or not is_instance_valid(target):
		return
	if target is CanvasItem:
		(target as CanvasItem).visible = should_show
	elif target is Node3D:
		(target as Node3D).visible = should_show
	elif target.has_method("set"):
		target.set("visible", should_show)


func _resolve_target() -> Node:
	if target_path.is_empty() or String(target_path) == "." or String(target_path) == "":
		return self
	var node: Node = get_node_or_null(target_path)
	if node != null:
		return node
	return self
