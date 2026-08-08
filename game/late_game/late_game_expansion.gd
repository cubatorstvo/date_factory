extends Node
## Late Game Expansion owner (MODULE 20 PART B).
## Autoload name: LateGameExpansion. Reach + global multipliers; CloneIncremental remains economy owner.


signal global_modifiers_changed()
signal world_expansion_completed()
signal final_target_detected()
signal optional_event_completed(event: int)

var _signals_connected: bool = false
var _completion_emitted: bool = false


func _ready() -> void:
	_connect_signals()
	DfLog.info("MODULE_20", "LateGameExpansion ready")


func _connect_signals() -> void:
	if _signals_connected:
		return
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_signal("late_experience_granted"):
		if not ci.is_connected("late_experience_granted", _on_late_experience_granted):
			ci.connect("late_experience_granted", _on_late_experience_granted)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("world_reach_changed") and not gs.is_connected("world_reach_changed", _on_world_reach_changed):
			gs.connect("world_reach_changed", _on_world_reach_changed)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	_signals_connected = true


func _on_state_reset() -> void:
	_completion_emitted = false
	global_modifiers_changed.emit()
	_notify_clone_incremental()


## Save/Load: mark completion one-shots already done when canonical state says so.
func sync_after_load() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var reach: int = int(gs.call("get_world_reach"))
	var complete: bool = bool(gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE))
	var stage_i: int = int(gs.call("get_stage"))
	if (
		reach >= LateGameTypes.WORLD_REACH_MAX
		or complete
		or stage_i >= int(GameTypes.GameStage.FINALE)
	):
		_completion_emitted = true
	else:
		_completion_emitted = false
	global_modifiers_changed.emit()
	_notify_clone_incremental()


func _on_late_experience_granted(amount: int) -> void:
	if amount <= 0:
		return
	if not _is_stage_6():
		return
	add_reach(amount * LateGameTypes.REACH_PER_LATE_XP)


func _on_world_reach_changed(new_value: int, _delta: int) -> void:
	if new_value >= LateGameTypes.WORLD_REACH_MAX:
		_try_complete_world_expansion()


func is_active() -> bool:
	return _is_stage_at_least(GameTypes.GameStage.STAGE_6)


func is_purchases_unlocked() -> bool:
	return _is_stage_at_least(GameTypes.GameStage.STAGE_6)


func get_world_reach() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_world_reach"))


## STAGE_6 Reach grant path used by late XP and optional events.
func add_reach(amount: int) -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	if amount <= 0:
		return int(gs.call("get_world_reach"))
	if not _is_stage_6():
		return int(gs.call("get_world_reach"))
	var reach: int = int(gs.call("add_world_reach", amount))
	return reach


func get_production_multiplier() -> float:
	return LateGameTypes.multiplier_for_level(get_global_production_level())


func get_work_multiplier() -> float:
	return LateGameTypes.multiplier_for_level(get_global_work_level())


func get_dating_multiplier() -> float:
	return LateGameTypes.multiplier_for_level(get_global_dating_level())


func get_global_production_level() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_global_production_upgrade_level"))


func get_global_work_level() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_global_work_upgrade_level"))


func get_global_dating_level() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_global_dating_upgrade_level"))


func get_upgrade_cost(upgrade_type: int) -> int:
	var level: int = _get_upgrade_level(upgrade_type)
	if level < 0:
		return -1
	return LateGameTypes.upgrade_cost(level)


func buy_global_upgrade(upgrade_type: int) -> GlobalUpgradePurchaseResult:
	var result: GlobalUpgradePurchaseResult = GlobalUpgradePurchaseResult.new()
	result.upgrade_type = upgrade_type as LateGameTypes.GlobalUpgradeType
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		result.error = LateGameTypes.GlobalUpgradePurchaseError.INVALID_UPGRADE
		return result
	if not is_purchases_unlocked():
		result.error = LateGameTypes.GlobalUpgradePurchaseError.LOCKED
		return result
	if (
		upgrade_type != int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION)
		and upgrade_type != int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK)
		and upgrade_type != int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING)
	):
		result.error = LateGameTypes.GlobalUpgradePurchaseError.INVALID_UPGRADE
		return result
	var level: int = _get_upgrade_level(upgrade_type)
	if level >= LateGameTypes.MAX_LEVEL:
		result.error = LateGameTypes.GlobalUpgradePurchaseError.MAX_LEVEL
		result.new_level = level
		return result
	var cost: int = LateGameTypes.upgrade_cost(level)
	if cost < 0:
		result.error = LateGameTypes.GlobalUpgradePurchaseError.MAX_LEVEL
		result.new_level = level
		return result
	if not bool(gs.call("can_afford", cost)):
		result.error = LateGameTypes.GlobalUpgradePurchaseError.NOT_ENOUGH_MONEY
		result.new_level = level
		return result
	if not bool(gs.call("spend_money", cost)):
		result.error = LateGameTypes.GlobalUpgradePurchaseError.NOT_ENOUGH_MONEY
		result.new_level = level
		return result
	var next_level: int = level + 1
	if not bool(gs.call("set_global_upgrade_level", upgrade_type, next_level)):
		gs.call("add_money", cost)
		result.error = LateGameTypes.GlobalUpgradePurchaseError.INVALID_UPGRADE
		result.new_level = level
		return result
	result.ok = true
	result.error = LateGameTypes.GlobalUpgradePurchaseError.OK
	result.new_level = next_level
	result.money_spent = cost
	result.money_after = int(gs.call("get_money"))
	global_modifiers_changed.emit()
	_notify_clone_incremental()
	return result


func get_status() -> LateGameStatus:
	return snapshot()


func snapshot() -> LateGameStatus:
	var status: LateGameStatus = LateGameStatus.new()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return status
	status.active = is_active()
	status.world_reach = int(gs.call("get_world_reach"))
	status.production_level = int(gs.call("get_global_production_upgrade_level"))
	status.work_level = int(gs.call("get_global_work_upgrade_level"))
	status.dating_level = int(gs.call("get_global_dating_upgrade_level"))
	status.production_multiplier = LateGameTypes.multiplier_for_level(status.production_level)
	status.work_multiplier = LateGameTypes.multiplier_for_level(status.work_level)
	status.dating_multiplier = LateGameTypes.multiplier_for_level(status.dating_level)
	status.world_expansion_complete = bool(
		gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)
	)
	return status


func is_optional_event_available(event: int) -> bool:
	if not _is_stage_6():
		return false
	var flag: StringName = LateGameTypes.event_flag(event)
	if String(flag) == "":
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if bool(gs.call("get_story_flag", flag)):
		return false
	return int(gs.call("get_world_reach")) >= LateGameTypes.event_min_reach(event)


func is_optional_event_completed(event: int) -> bool:
	var flag: StringName = LateGameTypes.event_flag(event)
	if String(flag) == "":
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("get_story_flag", flag))


## One-time optional Stage6 events. Marks story flag + add_reach(10).
func complete_optional_event(event: int) -> bool:
	if not is_optional_event_available(event):
		return false
	var flag: StringName = LateGameTypes.event_flag(event)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	gs.call("set_story_flag", flag, true)
	add_reach(LateGameTypes.OPTIONAL_EVENT_REACH)
	optional_event_completed.emit(event)
	return true


func _try_complete_world_expansion() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if int(gs.call("get_world_reach")) < LateGameTypes.WORLD_REACH_MAX:
		return
	if bool(gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)):
		return
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("complete_world_expansion"):
		return
	var ok: bool = bool(story.call("complete_world_expansion"))
	if not ok:
		return
	if _completion_emitted:
		return
	_completion_emitted = true
	world_expansion_completed.emit()
	final_target_detected.emit()


func _notify_clone_incremental() -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("refresh_external_modifiers"):
		ci.call("refresh_external_modifiers")


func _get_upgrade_level(upgrade_type: int) -> int:
	match upgrade_type:
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION):
			return get_global_production_level()
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK):
			return get_global_work_level()
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING):
			return get_global_dating_level()
	return -1


func _is_stage_6() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return int(gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_6)


func _is_stage_at_least(stage: GameTypes.GameStage) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return int(gs.call("get_stage")) >= int(stage)
