extends Node
## Rival Encounter Framework owner (MODULE 06).
## Autoload name: RivalEncounters. Persistent defeat/authority live in GameState.

signal encounter_started(session: RivalEncounterSession)
signal rival_refused(rival_id: StringName, reason: StringName)
signal competition_selected(competition_type: GameTypes.CompetitionType)
signal competition_requested(request: RivalCompetitionRequest)
signal encounter_won(result: RivalEncounterResult)
signal encounter_lost(result: RivalEncounterResult)
signal encounter_finished(result: RivalEncounterResult)

const REASON_OK: StringName = &"OK"
const REASON_RIVAL_NOT_FOUND: StringName = &"RIVAL_NOT_FOUND"
const REASON_ALREADY_DEFEATED: StringName = &"ALREADY_DEFEATED"
const REASON_RIVAL_REFUSED_LOW_AUTHORITY: StringName = &"RIVAL_REFUSED_LOW_AUTHORITY"
const REASON_NO_AVAILABLE_COMPETITION: StringName = &"NO_AVAILABLE_COMPETITION"
const REASON_COMPETITION_LOCKED: StringName = &"COMPETITION_LOCKED"
const REASON_ENCOUNTER_ALREADY_ACTIVE: StringName = &"ENCOUNTER_ALREADY_ACTIVE"
const REASON_INVALID_PHASE: StringName = &"INVALID_PHASE"
const REASON_INVALID_COMPETITION: StringName = &"INVALID_COMPETITION"
const REASON_NO_SESSION: StringName = &"NO_SESSION"
const REASON_ALREADY_FINISHED: StringName = &"ALREADY_FINISHED"
const REASON_MALFORMED_RESULT: StringName = &"MALFORMED_RESULT"
const REASON_OVERRIDE_UNAVAILABLE: StringName = &"OVERRIDE_UNAVAILABLE"
const REASON_CONCESSION_UNAVAILABLE: StringName = &"CONCESSION_UNAVAILABLE"

var _session: RivalEncounterSession = null
var _rival_overrides: Dictionary = {}
var _competition_runner: Callable = Callable()
var _last_result: RivalEncounterResult = null
var _finish_emit_count: int = 0


func _ready() -> void:
	DfLog.info("MODULE_06", "RivalEncounters ready")


func register_rival_definition(def: RivalDefinition) -> void:
	if def == null or String(def.id) == "":
		push_error("[RivalEncounters] register_rival_definition invalid")
		return
	_rival_overrides[def.id] = def


func clear_rival_overrides() -> void:
	_rival_overrides.clear()


func get_rival_definition(rival_id: StringName) -> RivalDefinition:
	if String(rival_id) == "":
		return null
	if _rival_overrides.has(rival_id):
		return _rival_overrides[rival_id] as RivalDefinition
	var content_db: Node = get_node_or_null("/root/ContentDB")
	if content_db == null:
		return null
	if content_db.has_method("get_rival"):
		return content_db.call("get_rival", rival_id) as RivalDefinition
	return null


func set_competition_runner(runner: Callable) -> void:
	_competition_runner = runner


func clear_competition_runner() -> void:
	_competition_runner = Callable()


func get_active_session() -> RivalEncounterSession:
	return _session


func get_last_result() -> RivalEncounterResult:
	return _last_result


func has_active_encounter() -> bool:
	return _session != null and _session.phase != GameTypes.RivalEncounterPhase.FINISHED


func get_finish_emit_count() -> int:
	return _finish_emit_count


## Test/helper: drop active session without resolving (between self-tests).
func force_clear_session() -> void:
	_session = null


func get_unlocked_competitions() -> Array[GameTypes.CompetitionType]:
	var out: Array[GameTypes.CompetitionType] = [
		GameTypes.CompetitionType.SLAP,
		GameTypes.CompetitionType.DANCE,
	]
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and bool(gs.call("has_perk", PerkIds.CAPITAL_PAYABLE_INTENT)):
		out.append(GameTypes.CompetitionType.MONEY)
	if gs != null and bool(gs.call("has_perk", PerkIds.AURA_PRESENCE_REGISTERED)):
		out.append(GameTypes.CompetitionType.SIGMA)
	return out


func get_available_competitions(rival_id: StringName) -> Array[GameTypes.CompetitionType]:
	var def: RivalDefinition = get_rival_definition(rival_id)
	var out: Array[GameTypes.CompetitionType] = []
	if def == null:
		return out
	var unlocked: Array[GameTypes.CompetitionType] = get_unlocked_competitions()
	for ctype in def.allowed_competitions:
		if unlocked.has(ctype) and not out.has(ctype):
			out.append(ctype)
	return out


func can_challenge(rival_id: StringName) -> Dictionary:
	var def: RivalDefinition = get_rival_definition(rival_id)
	if def == null:
		return _result(false, REASON_RIVAL_NOT_FOUND)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return _result(false, REASON_RIVAL_NOT_FOUND)
	if bool(gs.call("is_rival_defeated", rival_id)):
		return _result(false, REASON_ALREADY_DEFEATED)
	if int(gs.call("get_authority")) < def.required_authority:
		return _result(false, REASON_RIVAL_REFUSED_LOW_AUTHORITY)
	if get_available_competitions(rival_id).is_empty():
		return _result(false, REASON_NO_AVAILABLE_COMPETITION)
	return _result(true, REASON_OK)


func start_encounter(
	rival_id: StringName,
	initiator: GameTypes.RivalEncounterInitiator,
	context: GameTypes.RivalEncounterContext = GameTypes.RivalEncounterContext.WORLD,
	return_control_mode: int = -1,
) -> Dictionary:
	if has_active_encounter():
		return _result(false, REASON_ENCOUNTER_ALREADY_ACTIVE)
	var def: RivalDefinition = get_rival_definition(rival_id)
	if def == null:
		rival_refused.emit(rival_id, REASON_RIVAL_NOT_FOUND)
		return _result(false, REASON_RIVAL_NOT_FOUND)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return _result(false, REASON_RIVAL_NOT_FOUND)
	if bool(gs.call("is_rival_defeated", rival_id)):
		rival_refused.emit(rival_id, REASON_ALREADY_DEFEATED)
		return _result(false, REASON_ALREADY_DEFEATED)

	var available: Array[GameTypes.CompetitionType] = get_available_competitions(rival_id)
	if initiator == GameTypes.RivalEncounterInitiator.PLAYER:
		if int(gs.call("get_authority")) < def.required_authority:
			rival_refused.emit(rival_id, REASON_RIVAL_REFUSED_LOW_AUTHORITY)
			return _result(false, REASON_RIVAL_REFUSED_LOW_AUTHORITY)
		if available.is_empty():
			rival_refused.emit(rival_id, REASON_NO_AVAILABLE_COMPETITION)
			return _result(false, REASON_NO_AVAILABLE_COMPETITION)
	else:
		# RIVAL initiator: required_authority does not block.
		if not available.has(def.preferred_competition):
			rival_refused.emit(rival_id, REASON_COMPETITION_LOCKED)
			return _result(false, REASON_COMPETITION_LOCKED)

	var session: RivalEncounterSession = RivalEncounterSession.new()
	session.rival_id = rival_id
	session.rival_definition = def
	session.initiator = initiator
	session.context = context
	session.return_control_mode = return_control_mode
	session.phase = GameTypes.RivalEncounterPhase.CHOOSING
	if initiator == GameTypes.RivalEncounterInitiator.RIVAL:
		session.chosen_competition = def.preferred_competition
		session.has_chosen_competition = true
	_session = session
	_last_result = null
	encounter_started.emit(session)
	var out: Dictionary = _result(true, REASON_OK)
	out["session"] = session
	return out


func choose_competition(competition_type: GameTypes.CompetitionType) -> Dictionary:
	if _session == null:
		return _result(false, REASON_NO_SESSION)
	if _session.phase != GameTypes.RivalEncounterPhase.CHOOSING:
		return _result(false, REASON_INVALID_PHASE)
	if _session.initiator != GameTypes.RivalEncounterInitiator.PLAYER:
		return _result(false, REASON_INVALID_PHASE)
	var available: Array[GameTypes.CompetitionType] = get_available_competitions(_session.rival_id)
	if not available.has(competition_type):
		return _result(false, REASON_INVALID_COMPETITION)
	_session.chosen_competition = competition_type
	_session.has_chosen_competition = true
	competition_selected.emit(competition_type)
	return begin_competition()


func can_override_competition() -> bool:
	if _session == null:
		return false
	if _session.phase != GameTypes.RivalEncounterPhase.CHOOSING:
		return false
	if _session.initiator != GameTypes.RivalEncounterInitiator.RIVAL:
		return false
	if _session.override_used:
		return false
	if not _session.has_chosen_competition:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("has_perk", PerkIds.AURA_RIGHT_TO_SAY_NOTHING))


func override_competition(competition_type: GameTypes.CompetitionType) -> Dictionary:
	if not can_override_competition():
		return _result(false, REASON_OVERRIDE_UNAVAILABLE)
	var available: Array[GameTypes.CompetitionType] = get_available_competitions(_session.rival_id)
	if not available.has(competition_type):
		return _result(false, REASON_INVALID_COMPETITION)
	var auth_before: int = int(get_node("/root/GameState").call("get_authority"))
	_session.chosen_competition = competition_type
	_session.has_chosen_competition = true
	_session.override_used = true
	var auth_after: int = int(get_node("/root/GameState").call("get_authority"))
	if auth_after != auth_before:
		push_error("[RivalEncounters] override must not change authority")
	competition_selected.emit(competition_type)
	return _result(true, REASON_OK)


func can_use_local_significance() -> bool:
	if _session == null:
		return false
	if _session.phase != GameTypes.RivalEncounterPhase.CHOOSING:
		return false
	var def: RivalDefinition = _session.rival_definition
	if def == null or def.is_story:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if not bool(gs.call("has_perk", PerkIds.AURA_LOCAL_SIGNIFICANCE)):
		return false
	return int(gs.call("get_authority")) >= def.required_authority + 3


func use_local_significance() -> Dictionary:
	if not can_use_local_significance():
		return _result(false, REASON_CONCESSION_UNAVAILABLE)
	if not _session.has_chosen_competition:
		var available: Array[GameTypes.CompetitionType] = get_available_competitions(_session.rival_id)
		if available.is_empty():
			return _result(false, REASON_NO_AVAILABLE_COMPETITION)
		_session.chosen_competition = available[0]
		_session.has_chosen_competition = true
	_session.concession_used = true
	_snapshot_characteristics()
	_session.phase = GameTypes.RivalEncounterPhase.RESOLVING
	var result: RivalCompetitionResult = RivalCompetitionResult.new()
	result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	result.victory_grade = GameTypes.VictoryGrade.CRUSHING
	return _resolve_competition_result(result, false)


func begin_competition() -> Dictionary:
	if _session == null:
		return _result(false, REASON_NO_SESSION)
	if _session.phase != GameTypes.RivalEncounterPhase.CHOOSING and _session.phase != GameTypes.RivalEncounterPhase.READY:
		return _result(false, REASON_INVALID_PHASE)
	if not _session.has_chosen_competition:
		return _result(false, REASON_INVALID_COMPETITION)
	_snapshot_characteristics()
	_session.phase = GameTypes.RivalEncounterPhase.RUNNING
	var request: RivalCompetitionRequest = RivalCompetitionRequest.new()
	request.rival_id = _session.rival_id
	request.competition_type = _session.chosen_competition
	request.player_level = _session.player_characteristic_level
	request.rival_level = _session.rival_characteristic_level
	request.initiator = _session.initiator
	request.context = _session.context
	competition_requested.emit(request)
	if _competition_runner.is_valid():
		_competition_runner.call(request)
	var out: Dictionary = _result(true, REASON_OK)
	out["request"] = request
	return out


func submit_competition_result(result: RivalCompetitionResult) -> Dictionary:
	if _session == null:
		return _result(false, REASON_NO_SESSION)
	if _session.phase == GameTypes.RivalEncounterPhase.FINISHED:
		return _result(false, REASON_ALREADY_FINISHED)
	if _session.phase != GameTypes.RivalEncounterPhase.RUNNING:
		return _result(false, REASON_INVALID_PHASE)
	if result == null:
		push_error("[RivalEncounters] malformed null competition result")
		return _result(false, REASON_MALFORMED_RESULT)
	var outcome_i: int = int(result.outcome)
	if outcome_i != int(GameTypes.RivalCompetitionOutcome.PLAYER_WIN) and outcome_i != int(GameTypes.RivalCompetitionOutcome.PLAYER_LOSS):
		push_error("[RivalEncounters] malformed competition outcome")
		return _result(false, REASON_MALFORMED_RESULT)
	_session.phase = GameTypes.RivalEncounterPhase.RESOLVING
	return _resolve_competition_result(result, true)


func _resolve_competition_result(result: RivalCompetitionResult, from_minigame: bool) -> Dictionary:
	if _session == null:
		return _result(false, REASON_NO_SESSION)
	if _session.phase == GameTypes.RivalEncounterPhase.FINISHED:
		return _result(false, REASON_ALREADY_FINISHED)
	var gs: Node = get_node("/root/GameState")
	var def: RivalDefinition = _session.rival_definition
	var authority_before: int = int(gs.call("get_authority"))
	var authority_delta: int = 0
	var heroic: bool = false

	if result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		var first_defeat: bool = bool(gs.call("mark_rival_defeated", _session.rival_id))
		if first_defeat and def != null:
			var reward: int = def.authority_reward
			if reward > 0:
				gs.call("add_authority", reward)
			authority_delta = int(gs.call("get_authority")) - authority_before
		elif first_defeat:
			authority_delta = 0
		else:
			authority_delta = 0
	else:
		# MODULE 26: story rival PLAYER_LOSS never changes Authority (anti-grind).
		if def != null and def.is_story:
			authority_delta = 0
		else:
			heroic = _qualifies_heroic_defeat()
			if heroic:
				authority_delta = 0
			else:
				var lost: int = int(gs.call("lose_authority", 1))
				authority_delta = -lost

	_session.outcome = result.outcome
	_session.has_outcome = true
	_session.victory_grade = result.victory_grade
	_session.authority_delta = authority_delta
	_session.heroic_defeat_triggered = heroic
	_session.phase = GameTypes.RivalEncounterPhase.FINISHED

	var final_result: RivalEncounterResult = RivalEncounterResult.new()
	final_result.rival_id = _session.rival_id
	final_result.outcome = result.outcome
	final_result.victory_grade = result.victory_grade
	final_result.competition_type = _session.chosen_competition
	final_result.authority_delta = authority_delta
	final_result.heroic_defeat_triggered = heroic
	final_result.concession_used = _session.concession_used
	final_result.competition_override_used = _session.override_used
	_last_result = final_result
	_finish_emit_count += 1
	if result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		encounter_won.emit(final_result)
	else:
		encounter_lost.emit(final_result)
	encounter_finished.emit(final_result)
	var out: Dictionary = _result(true, REASON_OK)
	out["result"] = final_result
	out["from_minigame"] = from_minigame
	return out


func _qualifies_heroic_defeat() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or _session == null:
		return false
	if not bool(gs.call("has_perk", PerkIds.MUSCLE_HEROIC_DEFEAT)):
		return false
	return _session.rival_characteristic_level >= _session.player_characteristic_level + 2


func _snapshot_characteristics() -> void:
	if _session == null or _session.rival_definition == null:
		return
	var characteristic: GameTypes.PlayerCharacteristic = _characteristic_for_competition(_session.chosen_competition)
	var gs: Node = get_node("/root/GameState")
	_session.player_characteristic_level = int(gs.call("get_characteristic", characteristic))
	_session.rival_characteristic_level = _rival_characteristic_level(_session.rival_definition, characteristic)


func _characteristic_for_competition(competition_type: GameTypes.CompetitionType) -> GameTypes.PlayerCharacteristic:
	var content_db: Node = get_node_or_null("/root/ContentDB")
	if content_db != null and content_db.has_method("get_competition"):
		var cdef: CompetitionDefinition = content_db.call("get_competition", competition_type) as CompetitionDefinition
		if cdef != null:
			return cdef.characteristic
	match competition_type:
		GameTypes.CompetitionType.SLAP:
			return GameTypes.PlayerCharacteristic.MUSCLE
		GameTypes.CompetitionType.DANCE:
			return GameTypes.PlayerCharacteristic.APPEARANCE
		GameTypes.CompetitionType.MONEY:
			return GameTypes.PlayerCharacteristic.CAPITAL
		GameTypes.CompetitionType.SIGMA:
			return GameTypes.PlayerCharacteristic.AURA
	return GameTypes.PlayerCharacteristic.MUSCLE


func _rival_characteristic_level(def: RivalDefinition, characteristic: GameTypes.PlayerCharacteristic) -> int:
	match characteristic:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return def.muscle
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return def.appearance
		GameTypes.PlayerCharacteristic.CAPITAL:
			return def.capital
		GameTypes.PlayerCharacteristic.AURA:
			return def.aura
	return 0


func _result(ok: bool, reason: StringName) -> Dictionary:
	return {"ok": ok, "reason": reason}
