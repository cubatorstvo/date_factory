extends Node

const KEY_WORK: String = "work"
const KEY_CHARACTERISTIC_TRAINING: String = "characteristic_training"
const DATE_PREFIX: String = "date:"
const RIVAL_PREFIX: String = "rival:"
const STORY_EVENT_PREFIX: String = "story_event:"


func current_day_index() -> int:
	var clock: Variant = get_node_or_null("/root/TimeService")
	if clock != null and clock.has_method("get_calendar_day_index"):
		return int(clock.get_calendar_day_index())
	var gs: Variant = _game_state()
	if gs != null and gs.flow != null:
		return int(int(gs.flow.game_time_minutes) / 1440)
	return 0


func usage_today(activity_key: String) -> int:
	var key: String = str(activity_key)
	if key.is_empty():
		return 0
	var state: DailyActivityState = _state()
	if state == null:
		return 0
	var entry: Variant = state.usages.get(key, {})
	if not (entry is Dictionary):
		return 0
	if int(entry.get("last_used_day_index", -1)) != current_day_index():
		return 0
	return maxi(0, int(entry.get("usage_count_on_that_day", 0)))


func is_available(activity_key: String, daily_limit: int = 1) -> bool:
	return remaining(activity_key, daily_limit) > 0


func remaining(activity_key: String, daily_limit: int = 1) -> int:
	return maxi(0, daily_limit - usage_today(activity_key))


func register_usage(activity_key: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	set_usage_today(activity_key, usage_today(activity_key) + amount)


func date_key(girl_id: StringName) -> String:
	return "%s%s" % [DATE_PREFIX, String(girl_id)]


func rival_key(rival_id: StringName) -> String:
	return "%s%s" % [RIVAL_PREFIX, String(rival_id)]


func story_event_key(event_id: StringName) -> String:
	return "%s%s" % [STORY_EVENT_PREFIX, String(event_id)]


func work_daily_limit() -> int:
	var girls: Variant = get_node_or_null("/root/GirlsService")
	if girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_OLYA_OVERTIME)):
		return 2
	return 1


func set_usage_today(activity_key: String, count: int) -> void:
	var key: String = str(activity_key)
	if key.is_empty():
		return
	var state: DailyActivityState = _state()
	if state == null:
		return
	var clamped: int = maxi(0, count)
	if clamped <= 0:
		state.usages.erase(key)
		return
	state.usages[key] = {
		"last_used_day_index": current_day_index(),
		"usage_count_on_that_day": clamped,
	}


func get_all_usage_today() -> Dictionary:
	var result: Dictionary = {}
	var state: DailyActivityState = _state()
	if state == null:
		return result
	var day_index: int = current_day_index()
	for key in state.usages.keys():
		var entry: Variant = state.usages[key]
		if not (entry is Dictionary):
			continue
		if int(entry.get("last_used_day_index", -1)) != day_index:
			continue
		result[str(key)] = int(entry.get("usage_count_on_that_day", 0))
	return result


func _state():
	var gs: Variant = _game_state()
	if gs == null:
		return null
	return gs.daily_activity


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		return null
	return node
