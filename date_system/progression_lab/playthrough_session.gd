class_name PlaythroughSession
extends RefCounted

const ISOLATED_DIR: String = "user://progression_lab"
const DEFAULT_SAVE_NAME: String = "isolated_run.json"

var _snapshot: Dictionary = {}
var _previous_save_path: String = ""
var _previous_real_time: bool = false
var _active: bool = false
var isolated_save_path: String = ""
var _stage_auto_complete_disconnected: bool = false


func begin(save_name: String = DEFAULT_SAVE_NAME) -> void:
	if _active:
		end()
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	if gs == null or sm == null:
		return
	_snapshot = gs.to_dict().duplicate(true)
	_previous_save_path = str(sm.save_path)
	var clock: Variant = _root_node("TimeService")
	if clock != null:
		_previous_real_time = bool(clock.real_time_progression_enabled)
		clock.real_time_progression_enabled = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ISOLATED_DIR))
	isolated_save_path = "%s/%s" % [ISOLATED_DIR, save_name]
	if isolated_save_path == "user://saves/game.json":
		isolated_save_path = "%s/isolated_run.json" % ISOLATED_DIR
	sm.save_path = isolated_save_path
	sm.new_game()
	var stages: Variant = _stage_service()
	if stages != null:
		stages.reconcile_stage_entry_state()
	_reset_service_runtime()
	_set_stage_relationship_auto_complete(false)
	_active = true


func end() -> void:
	if not _active:
		return
	var gs: Variant = _game_state()
	var sm: Variant = _save_manager()
	if gs != null:
		gs.from_dict(_snapshot)
	if sm != null:
		sm.save_path = _previous_save_path
	var clock_end: Variant = _root_node("TimeService")
	if clock_end != null:
		clock_end.real_time_progression_enabled = _previous_real_time
	_set_stage_relationship_auto_complete(true)
	var stages: Variant = _stage_service()
	if stages != null:
		stages.reconcile_stage_entry_state()
	_reset_service_runtime()
	_snapshot = {}
	_previous_save_path = ""
	_active = false
	_stage_auto_complete_disconnected = false


func run(work: Callable) -> Variant:
	begin()
	var result: Variant = work.call()
	end()
	return result


func is_active() -> bool:
	return _active


func _game_state() -> Variant:
	return _root_node("GameState")


func _save_manager() -> Variant:
	return _root_node("SaveManager")


func _stage_service() -> Variant:
	return _root_node("StageService")


func _root_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _reset_service_runtime() -> void:
	var dating: Variant = _root_node("DatingService")
	if dating != null and dating.has_method("reset_isolated_runtime"):
		dating.reset_isolated_runtime()
	var competitions: Variant = _root_node("CompetitionService")
	if competitions != null and competitions.has_method("set_forced_won"):
		competitions.set_forced_won(null)


func _set_stage_relationship_auto_complete(enabled: bool) -> void:
	var stages: Variant = _stage_service()
	if stages == null:
		return
	stages.auto_complete_enabled = enabled
	_toggle_auto_complete_callback(_root_node("GirlsService"), "girl_relationship_changed", stages, "_on_girl_relationship_changed", enabled)
	_toggle_auto_complete_callback(_root_node("AutomationService"), "expansion_changed", stages, "_on_expansion_changed", enabled)
	_stage_auto_complete_disconnected = not enabled


func _toggle_auto_complete_callback(source: Variant, signal_name: StringName, target: Variant, method_name: StringName, enabled: bool) -> void:
	if source == null or target == null:
		return
	if not source.has_signal(signal_name):
		return
	var callback: Callable = Callable(target, method_name)
	var connected: bool = source.is_connected(signal_name, callback)
	if enabled:
		if not connected:
			source.connect(signal_name, callback)
	elif connected:
		source.disconnect(signal_name, callback)
