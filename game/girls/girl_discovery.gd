extends Node
## Girl discovery / acquaintance owner (MODULE 08).
## Autoload name: GirlDiscovery. Persistent state lives in GameState.
## Does not mutate relationship / experience / conquered on resolve.

signal girl_discovered(girl_id: StringName)
signal girl_contact_added(girl_id: StringName)
signal girl_clue_revealed(girl_id: StringName, clue_index: int)
signal girl_discovery_failed(girl_id: StringName, cooldown_days: int)
signal girl_available_again(girl_id: StringName)
signal primary_trait_revealed(girl_id: StringName)

const RESULT_SUCCESS: StringName = &"SUCCESS"
const RESULT_FAILURE: StringName = &"FAILURE"
const RESULT_LOCKED_EXPERIENCE: StringName = &"LOCKED_EXPERIENCE"
const RESULT_COOLDOWN: StringName = &"COOLDOWN"
const RESULT_ALREADY_CONTACT: StringName = &"ALREADY_CONTACT"
const RESULT_UNKNOWN_GIRL: StringName = &"UNKNOWN_GIRL"
const RESULT_INVALID_CONTENT: StringName = &"INVALID_CONTENT"
const RESULT_ALREADY_ACTIVE: StringName = &"ALREADY_ACTIVE"
const RESULT_REQUIREMENT_UNMET: StringName = &"REQUIREMENT_UNMET"
const RESULT_NO_ATTEMPT: StringName = &"NO_ATTEMPT"
const RESULT_ALREADY_FINISHED: StringName = &"ALREADY_FINISHED"
const RESULT_UNKNOWN_APPROACH: StringName = &"UNKNOWN_APPROACH"
const RESULT_STORY_WRONG_STAGE: StringName = &"STORY_WRONG_STAGE"
const RESULT_STORY_RIVAL_REQUIRED: StringName = &"STORY_RIVAL_REQUIRED"

var _girl_overrides: Dictionary = {}
var _situation_overrides: Dictionary = {}
var _active_attempt: GirlDiscoveryAttempt = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _gs_connected: bool = false


func _ready() -> void:
	_rng.randomize()
	_connect_gamestate_signals()
	_connect_gameday_signal()
	DfLog.info("MODULE_08", "GirlDiscovery ready")


func set_rng(rng: RandomNumberGenerator) -> void:
	if rng == null:
		push_error("[GirlDiscovery] set_rng null")
		return
	_rng = rng


func set_rng_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func register_girl_definition(def: GirlDefinition) -> void:
	if def == null or String(def.id) == "":
		push_error("[GirlDiscovery] register_girl_definition invalid")
		return
	_girl_overrides[def.id] = def


func register_discovery_situation(def: DiscoverySituationDefinition) -> void:
	if def == null or String(def.id) == "":
		push_error("[GirlDiscovery] register_discovery_situation invalid")
		return
	_situation_overrides[def.id] = def


func clear_content_overrides() -> void:
	_girl_overrides.clear()
	_situation_overrides.clear()


func get_girl_definition(girl_id: StringName) -> GirlDefinition:
	if String(girl_id) == "":
		return null
	if _girl_overrides.has(girl_id):
		return _girl_overrides[girl_id] as GirlDefinition
	var content_db: Node = get_node_or_null("/root/ContentDB")
	if content_db == null:
		return null
	if content_db.has_method("get_girl"):
		return content_db.call("get_girl", girl_id) as GirlDefinition
	return null


func get_discovery_situation(situation_id: StringName) -> DiscoverySituationDefinition:
	if String(situation_id) == "":
		return null
	if _situation_overrides.has(situation_id):
		return _situation_overrides[situation_id] as DiscoverySituationDefinition
	var content_db: Node = get_node_or_null("/root/ContentDB")
	if content_db == null:
		return null
	if content_db.has_method("get_discovery_situation"):
		return content_db.call("get_discovery_situation", situation_id) as DiscoverySituationDefinition
	return null


func find_discovery_approach(approach_id: StringName) -> DiscoveryApproachDefinition:
	if String(approach_id) == "":
		return null
	for sit_id in _situation_overrides.keys():
		var sit: DiscoverySituationDefinition = _situation_overrides[sit_id] as DiscoverySituationDefinition
		if sit == null:
			continue
		for approach in sit.approaches:
			if approach != null and approach.id == approach_id:
				return approach
	var content_db: Node = get_node_or_null("/root/ContentDB")
	if content_db != null and content_db.has_method("find_discovery_approach"):
		return content_db.call("find_discovery_approach", approach_id) as DiscoveryApproachDefinition
	return null


func has_active_attempt() -> bool:
	return _active_attempt != null and not _active_attempt.finished


func get_active_attempt() -> GirlDiscoveryAttempt:
	return _active_attempt


func force_clear_attempt() -> void:
	_active_attempt = null


## First sight / proximity discovery. Idempotent.
func discover_girl(girl_id: StringName) -> Dictionary:
	var def: GirlDefinition = get_girl_definition(girl_id)
	if def == null:
		return _result(false, RESULT_UNKNOWN_GIRL)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return _result(false, RESULT_UNKNOWN_GIRL)
	var first: bool = bool(gs.call("mark_girl_discovered", girl_id))
	if not first:
		return _result(true, RESULT_SUCCESS)
	# Clue 0 on first discovery if present.
	if def.clue_notes.size() >= 1:
		gs.call("reveal_girl_clue", girl_id, 0)
	# Good Profile: also clue 1 on first discovery only (not retroactive).
	if bool(gs.call("has_perk", PerkIds.APPEARANCE_GOOD_PROFILE)) and def.clue_notes.size() >= 2:
		gs.call("reveal_girl_clue", girl_id, 1)
	girl_discovered.emit(girl_id)
	return _result(true, RESULT_SUCCESS)


func begin_attempt(girl_id: StringName) -> Dictionary:
	if has_active_attempt():
		return _result(false, RESULT_ALREADY_ACTIVE)
	var def: GirlDefinition = get_girl_definition(girl_id)
	if def == null:
		return _result(false, RESULT_UNKNOWN_GIRL)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return _result(false, RESULT_UNKNOWN_GIRL)
	if not bool(gs.call("is_girl_discovered", girl_id)):
		# Auto-discover if interact somehow skipped proximity.
		discover_girl(girl_id)
	if bool(gs.call("has_girl_contact", girl_id)):
		return _result(false, RESULT_ALREADY_CONTACT)
	var remaining: int = int(gs.call("get_girl_retry_days_remaining", girl_id))
	if remaining > 0:
		var cool: Dictionary = _result(false, RESULT_COOLDOWN)
		cool["cooldown_days"] = remaining
		return cool
	var story_block: Dictionary = _story_gate_block(girl_id)
	if not story_block.is_empty():
		return story_block
	var exp_now: int = int(gs.call("get_experience"))
	if exp_now < def.required_experience:
		var locked: Dictionary = _result(false, RESULT_LOCKED_EXPERIENCE)
		locked["required_experience"] = def.required_experience
		locked["experience"] = exp_now
		return locked
	var situation: DiscoverySituationDefinition = get_discovery_situation(def.discovery_situation_id)
	if situation == null or situation.approaches.is_empty():
		return _result(false, RESULT_INVALID_CONTENT)
	var attempt: GirlDiscoveryAttempt = GirlDiscoveryAttempt.new()
	attempt.girl_id = girl_id
	attempt.situation_id = situation.id
	attempt.finished = false
	var approach_ids: Array[StringName] = []
	for approach in situation.approaches:
		if approach != null and String(approach.id) != "":
			approach_ids.append(approach.id)
	attempt.available_approach_ids = approach_ids
	_active_attempt = attempt
	var out: Dictionary = _result(true, RESULT_SUCCESS)
	out["girl_id"] = girl_id
	out["situation_id"] = situation.id
	out["setup_text"] = situation.setup_text
	out["approaches"] = _build_approach_states(situation, gs)
	out["attempt"] = attempt
	return out


func is_approach_available(approach: DiscoveryApproachDefinition, gs: Node = null) -> bool:
	if approach == null:
		return false
	if not approach.has_requirement:
		return true
	var state: Node = gs
	if state == null:
		state = get_node_or_null("/root/GameState")
	if state == null:
		return false
	var level: int = int(state.call("get_characteristic", approach.required_characteristic))
	return level >= approach.required_level


## Resolve authored approach. Exactly-once.
func select_approach(approach_id: StringName) -> Dictionary:
	if _active_attempt == null:
		return _result(false, RESULT_NO_ATTEMPT)
	if _active_attempt.finished:
		return _result(false, RESULT_ALREADY_FINISHED)
	var situation: DiscoverySituationDefinition = get_discovery_situation(_active_attempt.situation_id)
	if situation == null:
		return _result(false, RESULT_INVALID_CONTENT)
	var approach: DiscoveryApproachDefinition = null
	for a in situation.approaches:
		if a != null and a.id == approach_id:
			approach = a
			break
	if approach == null:
		return _result(false, RESULT_UNKNOWN_APPROACH)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return _result(false, RESULT_UNKNOWN_GIRL)
	if not is_approach_available(approach, gs):
		return _result(false, RESULT_REQUIREMENT_UNMET)
	# Finish exactly once before applying effects.
	_active_attempt.finished = true
	var girl_id: StringName = _active_attempt.girl_id
	if approach.outcome == DiscoveryApproachDefinition.DiscoveryApproachOutcome.SUCCESS:
		gs.call("add_girl_contact", girl_id)
		gs.call("set_girl_retry_days_remaining", girl_id, 0)
		girl_contact_added.emit(girl_id)
		var ok_out: Dictionary = _result(true, RESULT_SUCCESS)
		ok_out["girl_id"] = girl_id
		ok_out["result_text"] = approach.result_text
		ok_out["cooldown_days"] = 0
		_active_attempt = null
		return ok_out
	# FAILURE path
	var new_clue: int = _reveal_next_clue(gs, girl_id)
	var cooldown_days: int = _rng.randi_range(1, 3)
	gs.call("set_girl_retry_days_remaining", girl_id, cooldown_days)
	girl_discovery_failed.emit(girl_id, cooldown_days)
	var fail_out: Dictionary = _result(true, RESULT_FAILURE)
	fail_out["girl_id"] = girl_id
	fail_out["result_text"] = approach.result_text
	fail_out["cooldown_days"] = cooldown_days
	if new_clue >= 0:
		fail_out["new_clue_index"] = new_clue
	_active_attempt = null
	return fail_out


func notify_game_day_advanced() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ids: Array[StringName] = []
	# Snapshot keys — GameState does not expose full retry map; scan known girls.
	var discovered: Array = gs.call("get_discovered_girl_ids") as Array
	for entry in discovered:
		var gid: StringName = entry as StringName
		var rem: int = int(gs.call("get_girl_retry_days_remaining", gid))
		if rem > 0:
			ids.append(gid)
	# Also check overrides that may have cooldown without discovery edge cases.
	for key in _girl_overrides.keys():
		var ogid: StringName = key as StringName
		if not ids.has(ogid):
			var rem2: int = int(gs.call("get_girl_retry_days_remaining", ogid))
			if rem2 > 0:
				ids.append(ogid)
	for gid2 in ids:
		var before: int = int(gs.call("get_girl_retry_days_remaining", gid2))
		var after: int = maxi(0, before - 1)
		gs.call("set_girl_retry_days_remaining", gid2, after)
		if before == 1 and after == 0:
			girl_available_again.emit(gid2)


func _reveal_next_clue(gs: Node, girl_id: StringName) -> int:
	var def: GirlDefinition = get_girl_definition(girl_id)
	if def == null:
		return -1
	for i in range(def.clue_notes.size()):
		if not bool(gs.call("is_girl_clue_known", girl_id, i)):
			gs.call("reveal_girl_clue", girl_id, i)
			return i
	return -1


func _build_approach_states(situation: DiscoverySituationDefinition, gs: Node) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for approach in situation.approaches:
		if approach == null:
			continue
		var entry: Dictionary = {
			"id": approach.id,
			"label": approach.label,
			"has_requirement": approach.has_requirement,
			"required_characteristic": approach.required_characteristic,
			"required_level": approach.required_level,
			"available": is_approach_available(approach, gs),
			"result_text": approach.result_text,
			"outcome": approach.outcome,
		}
		out.append(entry)
	return out


func _connect_gamestate_signals() -> void:
	if _gs_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if gs.has_signal("girl_clue_revealed") and not gs.is_connected("girl_clue_revealed", _on_gs_clue):
		gs.connect("girl_clue_revealed", _on_gs_clue)
	if gs.has_signal("primary_trait_revealed") and not gs.is_connected("primary_trait_revealed", _on_gs_trait):
		gs.connect("primary_trait_revealed", _on_gs_trait)
	_gs_connected = true


func _connect_gameday_signal() -> void:
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null or not day.has_signal("day_advanced"):
		return
	if day.is_connected("day_advanced", _on_game_day_advanced):
		return
	day.connect("day_advanced", _on_game_day_advanced)


func _on_game_day_advanced(_new_day: int) -> void:
	notify_game_day_advanced()


func _on_gs_clue(girl_id: StringName, clue_index: int) -> void:
	girl_clue_revealed.emit(girl_id, clue_index)


func _on_gs_trait(girl_id: StringName) -> void:
	primary_trait_revealed.emit(girl_id)


## Story reserved-girl gate. Not FAILURE — no clue/cooldown side effects.
func _story_gate_block(girl_id: StringName) -> Dictionary:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("get_story_girl_gate"):
		return {}
	var gate: int = int(story.call("get_story_girl_gate", girl_id))
	if gate == int(StoryTypes.StoryGirlGate.WRONG_STAGE):
		return _result(false, RESULT_STORY_WRONG_STAGE)
	if gate == int(StoryTypes.StoryGirlGate.RIVAL_REQUIRED):
		return _result(false, RESULT_STORY_RIVAL_REQUIRED)
	return {}


func _result(ok: bool, reason: StringName) -> Dictionary:
	return {"ok": ok, "reason": reason}
