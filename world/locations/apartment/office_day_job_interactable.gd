extends Interactable
class_name OfficeDayJobInteractable
## City office day-job: walk up to the agency building, claim today's wage, leave.
## Unlocked with StoryFeature.DAY_JOB at STAGE_1. One claim per GameDay.
## Independent from SalaryMine / SALARY_MINE.
## CityPOITenant writes these fields onto InteractionArea at ready.

const FLAT_DAY_WAGE: int = 10

@export var action_id: StringName = &""
@export var display_name: String = ""
@export var action_label: String = ""
@export var payload: Dictionary = {}


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0
	prompt_action = "Сходить на работу"
	add_to_group("day_job_desk")
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("stage_changed"):
		if not gs.is_connected("stage_changed", _on_stage_changed):
			gs.connect("stage_changed", _on_stage_changed)
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_signal("day_advanced"):
		if not day.is_connected("day_advanced", _on_day_advanced):
			day.connect("day_advanced", _on_day_advanced)
	_refresh_prompt()


func can_interact(_player: Node) -> bool:
	return interaction_enabled and is_inside_tree() and not is_queued_for_deletion()


func get_interaction_prompt(_player: Node) -> String:
	_refresh_prompt()
	if not _is_day_job_unlocked():
		return "[E] Недоступно — Пока недоступно по сюжету"
	if _already_claimed_today():
		return "[E] Зарплата уже получена сегодня"
	return "[E] Сходить на работу (+$%d)" % _wage_amount()


func _on_interact(_player: Node) -> void:
	if not _is_day_job_unlocked():
		_notify("Офис пока закрыт. Сначала закончи обучение.")
		return
	if _already_claimed_today():
		_notify("Сегодняшняя зарплата уже получена.")
		return
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		push_error("[OfficeDayJob] GameState/GameDay missing")
		return
	var amount: int = _wage_amount()
	var current_day: int = int(day.call("get_current_day"))
	gs.call("add_money", amount)
	gs.call("set_day_job_last_claim_day", current_day)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_method("get_current_progress"):
		if story.has_signal("stage_objective_changed"):
			story.emit_signal("stage_objective_changed", story.call("get_current_progress"))
	_refresh_prompt()
	_notify("Смена в офисе закрыта. Зарплата +$%d." % amount)
	var hud: Node = _find_hud()
	if hud != null and hud.has_method("notify_major_money"):
		hud.call("notify_major_money", amount, "Зарплата")


func _is_day_job_unlocked() -> bool:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("is_feature_unlocked"):
		return false
	return bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.DAY_JOB))


func _already_claimed_today() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return false
	if not gs.has_method("get_day_job_last_claim_day"):
		return false
	var current_day: int = int(day.call("get_current_day"))
	return int(gs.call("get_day_job_last_claim_day")) == current_day


func _wage_amount() -> int:
	var mine: Node = get_node_or_null("/root/SalaryMine")
	if mine != null and mine.has_method("get_gross_salary"):
		# Level formula at authority 0 (early job, not the mine unlock).
		return int(mine.call("get_gross_salary", 0))
	return FLAT_DAY_WAGE


func _refresh_prompt() -> void:
	if not _is_day_job_unlocked():
		prompt_action = "Офис недоступен"
	elif _already_claimed_today():
		prompt_action = "Зарплата получена"
	else:
		prompt_action = "Сходить на работу"


func _on_feature_unlocked(feature: StoryTypes.StoryFeature) -> void:
	if feature == StoryTypes.StoryFeature.DAY_JOB:
		_refresh_prompt()


func _on_stage_changed(_new_stage: GameTypes.GameStage, _prev: GameTypes.GameStage) -> void:
	_refresh_prompt()


func _on_day_advanced(_new_day: int) -> void:
	_refresh_prompt()


func _notify(message: String) -> void:
	var hud: Node = _find_hud()
	if hud != null and hud.has_method("show_notification"):
		hud.call("show_notification", message)


func _find_hud() -> Node:
	var tree: SceneTree = get_tree()
	if tree != null:
		var hud: Node = tree.get_first_node_in_group("game_hud")
		if hud != null:
			return hud
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_game_hud"):
		return world.call("get_game_hud") as Node
	return null
