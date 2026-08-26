extends Node

const SAVE_VERSION: int = 20
const DEFAULT_SAVE_PATH: String = "user://saves/game.json"
const MINUTES_PER_DAY: int = 1440

var save_path: String = DEFAULT_SAVE_PATH


func _playthrough() -> Node:
	var node: Node = get_node("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
	return node


func _time_service() -> Node:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
	return node


func _stage_service() -> Node:
	var node: Node = get_node_or_null("/root/StageService")
	if not is_instance_valid(node):
		push_error("StageService autoload missing")
	return node

func _notify_playthrough_rebuilt(reset_guidance: bool) -> void:
	var guidance: Variant = get_node_or_null("/root/GuidanceService")
	if guidance != null:
		if reset_guidance and guidance.has_method("on_playthrough_reset"):
			guidance.on_playthrough_reset()
	var objectives: Variant = get_node_or_null("/root/ObjectiveService")
	if objectives != null and objectives.has_method("rebuild"):
		objectives.rebuild()


func new_game() -> void:
	_playthrough().apply_new_game()
	var clock: Variant = _time_service()
	if clock != null:
		clock.on_playthrough_reset()
	var stages: Variant = _stage_service()
	if stages != null:
		stages.reconcile_stage_entry_state()
	_notify_playthrough_rebuilt(true)

func save_game() -> void:
	var folder: String = save_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"game_state": _playthrough().to_dict(),
	}
	file.store_string(JSON.stringify(payload, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return false
	var root: Dictionary = parsed
	var version: int = int(root.get("save_version", 1))
	if version < 1:
		return false
	var state_data: Variant = root.get("game_state", {})
	if not (state_data is Dictionary):
		return false
	var migrated: Dictionary = _migrate_game_state(state_data, version)
	_playthrough().from_dict(migrated)
	var clock: Variant = _time_service()
	if clock != null:
		clock.on_playthrough_reset()
	var stages: Variant = _stage_service()
	if stages != null:
		stages.reconcile_stage_entry_state()
	_notify_playthrough_rebuilt(false)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if not has_save():
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _migrate_game_state(state_data: Dictionary, from_version: int) -> Dictionary:
	var migrated: Dictionary = state_data.duplicate(true)
	if from_version >= SAVE_VERSION:
		return migrated
	if from_version < 2:
		migrated = _migrate_v1_flow(migrated)
	if from_version < 3:
		migrated = _migrate_v2_story(migrated)
	if from_version < 4:
		migrated = _migrate_v3_progression(migrated)
	if from_version < 5:
		migrated = _migrate_v4_world(migrated)
	if from_version < 6:
		migrated = _migrate_v5_girls(migrated)
	if from_version < 7:
		migrated = _migrate_v6_rating(migrated)
	if from_version < 8:
		migrated = _migrate_v7_date_knowledge(migrated)
	if from_version < 9:
		migrated = _migrate_v8_rivals(migrated)
	if from_version < 10:
		migrated = _migrate_v9_progression(migrated)
	if from_version < 11:
		migrated = _migrate_v10_automation(migrated)
	if from_version < 12:
		migrated = _migrate_v11_factory_rating(migrated)
	if from_version < 13:
		migrated = _migrate_v12_apartment_prepared(migrated)
	if from_version < 14:
		migrated = _migrate_v13_city_density(migrated)
	if from_version < 15:
		migrated = _migrate_v14_game_core(migrated)
	if from_version < 16:
		migrated = _migrate_v15_guidance(migrated)
	if from_version < 17:
		migrated = _migrate_v16_filler_rewards(migrated)
	if from_version < 18:
		migrated = _migrate_v17_daily_activity(migrated)
	if from_version < 19:
		migrated = _migrate_v18_career(migrated)
	if from_version < 20:
		migrated = _migrate_v19_career_connections(migrated)
	return migrated


func _migrate_v1_flow(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var flow_value: Variant = migrated.get("flow", {})
	if not (flow_value is Dictionary):
		return migrated
	var flow: Dictionary = flow_value
	if not flow.has("game_time_minutes"):
		var old_day: int = int(flow.get("day", 1))
		flow["game_time_minutes"] = maxi(0, old_day - 1) * MINUTES_PER_DAY
	flow.erase("day")
	migrated["flow"] = flow
	return migrated


func _migrate_v2_story(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var story_value: Variant = migrated.get("story", {})
	if not (story_value is Dictionary):
		return migrated
	var story: Dictionary = story_value
	if not story.has("finale_reached"):
		story["finale_reached"] = false
	migrated["story"] = story
	return migrated


func _migrate_v3_progression(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	if not progression.has("purchased_ids"):
		progression["purchased_ids"] = []
	migrated["progression"] = progression
	return migrated


func _migrate_v4_world(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var world_value: Variant = migrated.get("world", {})
	var world: Dictionary = {}
	if world_value is Dictionary:
		world = world_value
	if not world.has("current_location_id") or str(world.get("current_location_id", "")).is_empty():
		world["current_location_id"] = String(LocationCatalog.START_LOCATION_ID)
	if not world.has("unlocked_location_ids"):
		var ids: Array = []
		for location_id in LocationCatalog.START_UNLOCKED_LOCATION_IDS:
			ids.append(String(location_id))
		world["unlocked_location_ids"] = ids
	migrated["world"] = world
	return migrated


func _migrate_v5_girls(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var girls_value: Variant = migrated.get("girls", {})
	var girls: Dictionary = {}
	if girls_value is Dictionary:
		girls = girls_value
	if not girls.has("girls_by_id"):
		girls["girls_by_id"] = {}
	migrated["girls"] = girls
	return migrated


func _migrate_v6_rating(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("rating"):
		player["rating"] = 0
	migrated["player"] = player
	var dating_value: Variant = migrated.get("dating", {})
	var dating: Dictionary = {}
	if dating_value is Dictionary:
		dating = dating_value
	if not dating.has("active_date"):
		dating["active_date"] = {}
	migrated["dating"] = dating
	return migrated


func _migrate_v7_date_knowledge(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var girls_value: Variant = migrated.get("girls", {})
	var girls: Dictionary = {}
	if girls_value is Dictionary:
		girls = girls_value
	var by_id_value: Variant = girls.get("girls_by_id", {})
	var by_id: Dictionary = {}
	if by_id_value is Dictionary:
		by_id = by_id_value
	for girl_key in by_id.keys():
		var girl_value: Variant = by_id[girl_key]
		if not (girl_value is Dictionary):
			continue
		var girl: Dictionary = girl_value
		if not girl.has("revealed_positive_tag_ids"):
			girl["revealed_positive_tag_ids"] = []
		if not girl.has("revealed_negative_tag_ids"):
			girl["revealed_negative_tag_ids"] = []
		if not girl.has("secondary_revealed"):
			girl["secondary_revealed"] = false
		if not girl.has("completed_dates"):
			girl["completed_dates"] = 0
		by_id[girl_key] = girl
	girls["girls_by_id"] = by_id
	migrated["girls"] = girls
	return migrated


func _migrate_v8_rivals(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var rivals_value: Variant = migrated.get("rivals", {})
	var rivals: Dictionary = {}
	if rivals_value is Dictionary:
		rivals = rivals_value
	if not rivals.has("rivals_by_id"):
		rivals["rivals_by_id"] = {}
	migrated["rivals"] = rivals
	return migrated


func _migrate_v9_progression(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("muscle"):
		player["muscle"] = 0
	if not player.has("appearance"):
		player["appearance"] = 0
	if not player.has("capital"):
		player["capital"] = 0
	if not player.has("aura"):
		player["aura"] = 0
	migrated["player"] = player
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	if not progression.has("owned_outfit_ids"):
		progression["owned_outfit_ids"] = [String(OutfitCatalog.START_OUTFIT_ID)]
	if not progression.has("equipped_outfit_id") or str(progression.get("equipped_outfit_id", "")).is_empty():
		progression["equipped_outfit_id"] = String(OutfitCatalog.START_OUTFIT_ID)
	if not progression.has("apartment"):
		progression["apartment"] = {
			"level": 1,
			"owned_local_object_ids": [],
			"accent_object_id": "",
		}
	migrated["progression"] = progression
	var dating_value: Variant = migrated.get("dating", {})
	var dating: Dictionary = {}
	if dating_value is Dictionary:
		dating = dating_value
	var active_value: Variant = dating.get("active_date", {})
	if active_value is Dictionary:
		var active: Dictionary = active_value
		if not str(active.get("girl_id", "")).is_empty() and (not active.has("outfit_id") or str(active.get("outfit_id", "")).is_empty()):
			active["outfit_id"] = String(OutfitCatalog.START_OUTFIT_ID)
			dating["active_date"] = active
	migrated["dating"] = dating
	return migrated


func _migrate_v10_automation(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var automation_value: Variant = migrated.get("automation", {})
	var automation: Dictionary = {}
	if automation_value is Dictionary:
		automation = automation_value
	if not automation.has("unlocked"):
		automation["unlocked"] = false
	if not automation.has("initial_clones_granted"):
		automation["initial_clones_granted"] = false
	if not automation.has("total_clones"):
		automation["total_clones"] = 0
	if not automation.has("work_allocation_percent"):
		automation["work_allocation_percent"] = 50
	if not automation.has("work_income_fraction"):
		automation["work_income_fraction"] = 0
	if not automation.has("dating_progress_fraction"):
		automation["dating_progress_fraction"] = 0
	if not automation.has("completed_auto_dates"):
		automation["completed_auto_dates"] = 0
	if not automation.has("purchased_upgrade_ids"):
		automation["purchased_upgrade_ids"] = []
	migrated["automation"] = automation
	return migrated

func _migrate_v11_factory_rating(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var automation_value: Variant = migrated.get("automation", {})
	var automation: Dictionary = {}
	if automation_value is Dictionary:
		automation = automation_value
	var completed_auto_dates: int = maxi(0, int(automation.get("completed_auto_dates", 0)))
	var dating_fraction: float = maxf(0.0, float(automation.get("dating_progress_fraction", 0.0)))
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	player["rating"] = maxi(0, int(player.get("rating", 0))) + completed_auto_dates
	migrated["player"] = player
	if not automation.has("current_expansion_scope"):
		automation["current_expansion_scope"] = "city"
	if not automation.has("expansion_progress"):
		automation["expansion_progress"] = minf(float(completed_auto_dates) + dating_fraction, 100.0)
	automation.erase("completed_auto_dates")
	migrated["automation"] = automation
	return migrated


func _migrate_v12_apartment_prepared(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	var apartment_value: Variant = progression.get("apartment", {})
	var apartment: Dictionary = {}
	if apartment_value is Dictionary:
		apartment = apartment_value
	if not apartment.has("prepared"):
		apartment["prepared"] = true
	progression["apartment"] = apartment
	migrated["progression"] = progression
	return migrated


func _migrate_v13_city_density(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var story_value: Variant = migrated.get("story", {})
	var story_stage: int = 1
	if story_value is Dictionary:
		story_stage = int(story_value.get("stage", 1))
	var world_value: Variant = migrated.get("world", {})
	var world: Dictionary = {}
	if world_value is Dictionary:
		world = world_value
	if not world.has("city_stage"):
		world["city_stage"] = CityProgressionService.city_stage_from_story_stage(story_stage)
	migrated["world"] = world
	var rivals_value: Variant = migrated.get("rivals", {})
	var rivals: Dictionary = {}
	if rivals_value is Dictionary:
		rivals = rivals_value
	var by_id_value: Variant = rivals.get("rivals_by_id", {})
	var by_id: Dictionary = {}
	if by_id_value is Dictionary:
		by_id = by_id_value
	for rival_key in by_id.keys():
		var rival_value: Variant = by_id[rival_key]
		if not (rival_value is Dictionary):
			continue
		var rival: Dictionary = rival_value
		if not rival.has("last_challenge_completed_at"):
			rival["last_challenge_completed_at"] = 0
		by_id[rival_key] = rival
	rivals["rivals_by_id"] = by_id
	migrated["rivals"] = rivals
	return migrated


func _migrate_v14_game_core(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("last_work_day_index"):
		player["last_work_day_index"] = -1
	migrated["player"] = player
	var girls_value: Variant = migrated.get("girls", {})
	var girls: Dictionary = {}
	if girls_value is Dictionary:
		girls = girls_value
	var girls_by_id_value: Variant = girls.get("girls_by_id", {})
	var girls_by_id: Dictionary = {}
	if girls_by_id_value is Dictionary:
		girls_by_id = girls_by_id_value
	for girl_key in girls_by_id.keys():
		var girl_value: Variant = girls_by_id[girl_key]
		if not (girl_value is Dictionary):
			continue
		var girl: Dictionary = girl_value
		girl["relationship"] = maxi(0, int(girl.get("relationship", 0)))
		girl.erase("secondary_revealed")
		girls_by_id[girl_key] = girl
	girls["girls_by_id"] = girls_by_id
	migrated["girls"] = girls
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	if not progression.has("current_outfit_id") or str(progression.get("current_outfit_id", "")).is_empty():
		var equipped_text: String = str(progression.get("equipped_outfit_id", ""))
		if equipped_text.is_empty():
			equipped_text = String(OutfitCatalog.START_OUTFIT_ID)
		progression["current_outfit_id"] = equipped_text
	progression.erase("equipped_outfit_id")
	migrated["progression"] = progression
	return migrated

func _migrate_v15_guidance(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var guidance_value: Variant = migrated.get("guidance", {})
	var guidance: Dictionary = {}
	if guidance_value is Dictionary:
		guidance = guidance_value
	if not guidance.has("shown_tutorial_ids"):
		guidance["shown_tutorial_ids"] = []
	if not guidance.has("shown_milestone_ids"):
		guidance["shown_milestone_ids"] = []
	migrated["guidance"] = guidance
	return migrated


func _migrate_v16_filler_rewards(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("last_overtime_day_index"):
		player["last_overtime_day_index"] = -1
	migrated["player"] = player
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	if not progression.has("unlocked_filler_reward_ids"):
		progression["unlocked_filler_reward_ids"] = []
	if not progression.has("marina_free_outfit_pending"):
		progression["marina_free_outfit_pending"] = false
	migrated["progression"] = progression
	return migrated


func _migrate_v17_daily_activity(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var daily_value: Variant = migrated.get("daily_activity", {})
	var daily: Dictionary = {}
	if daily_value is Dictionary:
		daily = daily_value
	var usages: Dictionary = {}
	var packed: Variant = daily.get("usages", {})
	if packed is Dictionary:
		usages = packed
	var flow_value: Variant = migrated.get("flow", {})
	var minutes: int = 0
	if flow_value is Dictionary:
		minutes = int(flow_value.get("game_time_minutes", 0))
	var current_day: int = int(minutes / MINUTES_PER_DAY)
	var player_value: Variant = migrated.get("player", {})
	var work_usage: int = 0
	if player_value is Dictionary:
		if int(player_value.get("last_work_day_index", -1)) == current_day:
			work_usage = 1
		if int(player_value.get("last_overtime_day_index", -1)) == current_day:
			work_usage = 2
	if work_usage > 0:
		usages["work"] = {
			"last_used_day_index": current_day,
			"usage_count_on_that_day": work_usage,
		}
	daily["usages"] = usages
	migrated["daily_activity"] = daily
	return migrated


func _migrate_v18_career(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("career_progression_unlocked"):
		player["career_progression_unlocked"] = false
	if not player.has("career_rank"):
		player["career_rank"] = 0
	player["career_rank"] = clampi(int(player.get("career_rank", 0)), 0, 3)
	migrated["player"] = player
	return migrated

func _migrate_v19_career_connections(state_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = state_data
	var player_value: Variant = migrated.get("player", {})
	var player: Dictionary = {}
	if player_value is Dictionary:
		player = player_value
	if not player.has("career_connections_unlocked"):
		player["career_connections_unlocked"] = bool(player.get("career_progression_unlocked", false))
	if player.has("career_progression_unlocked"):
		player.erase("career_progression_unlocked")
	if not player.has("career_rank"):
		player["career_rank"] = 0
	player["career_rank"] = clampi(int(player.get("career_rank", 0)), 0, 3)
	migrated["player"] = player
	var progression_value: Variant = migrated.get("progression", {})
	var progression: Dictionary = {}
	if progression_value is Dictionary:
		progression = progression_value
	var ids_value: Variant = progression.get("unlocked_filler_reward_ids", [])
	var rewritten: Array = []
	if ids_value is Array:
		for item in ids_value:
			var id_text: String = str(item)
			if id_text == "career_progression_unlock":
				id_text = "career_connections"
			if not rewritten.has(id_text):
				rewritten.append(id_text)
		progression["unlocked_filler_reward_ids"] = rewritten
	migrated["progression"] = progression
	return migrated
