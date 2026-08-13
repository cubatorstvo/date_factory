extends Node
## Dating Core autoload — one active date session (MODULE 09).
## Returns DatingResult.date_delta only; does NOT apply relationship / XP / conquer.

signal arrival_presentation_requested(girl_id: StringName)
signal second_outfit_requested(girl_id: StringName)
signal encore_presentation_requested(girl_id: StringName, action_id: StringName)
signal action_execution_requested(request: DatingActionExecutionRequest)
signal phase_changed(phase: DatingTypes.Phase)
signal date_finished(result: DatingResult)
signal reaction_presented(reaction: int, result_text: String)
signal tutorial_correction_presented(explanation: String)

var _session: DatingSession = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _external_resolver: Callable = Callable()
var _control_owner: Node = null
var _control_restore_mode: int = -1
var _next_date_id: int = 1


func _ready() -> void:
	_rng.randomize()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	DfLog.info("MODULE_09", "DatingCore ready")


func _on_state_reset() -> void:
	force_clear_session()


func set_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_rng = rng


func set_external_resolver(cb: Callable) -> void:
	_external_resolver = cb


func clear_external_resolver() -> void:
	_external_resolver = Callable()


func is_date_active() -> bool:
	return _session != null and not _session.finished


func get_session() -> DatingSession:
	return _session


func force_clear_session() -> void:
	_session = null
	_release_control()


func start_date(request: DatingStartRequest) -> Dictionary:
	if request == null:
		return _fail(DatingTypes.ERR_NO_GIRL)
	if is_date_active():
		return _fail(DatingTypes.ERR_DATE_ALREADY_ACTIVE)
	var db: Node = get_node("/root/ContentDB")
	var gs: Node = get_node("/root/GameState")
	var girl: GirlDefinition = db.call("get_girl", request.girl_id) as GirlDefinition
	if girl == null:
		return _fail(DatingTypes.ERR_NO_GIRL)
	if not girl.romance_available and not request.tutorial_mode:
		return _fail(DatingTypes.ERR_NO_CONTACT)
	var has_contact: bool = bool(gs.call("has_girl_contact", request.girl_id))
	if not has_contact and not request.tutorial_mode:
		return _fail(DatingTypes.ERR_NO_CONTACT)
	if request.greeting_ids.is_empty():
		return _fail(DatingTypes.ERR_MISSING_GREETING)
	for gid in request.greeting_ids:
		var gdef: DatingGreetingDefinition = db.call("get_dating_greeting", gid) as DatingGreetingDefinition
		if gdef == null:
			return _fail(DatingTypes.ERR_MISSING_GREETING)
	var farewell: DatingFarewellDefinition = db.call("get_dating_farewell", request.farewell_id) as DatingFarewellDefinition
	if farewell == null:
		return _fail(DatingTypes.ERR_MISSING_FAREWELL)
	if request.rng_seed >= 0:
		_rng.seed = request.rng_seed
		_rng.state = 0
	var plan: Dictionary = _build_event_plan(request, girl, db)
	if not bool(plan.get("ok", false)):
		return _fail(DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT)
	var session := DatingSession.new()
	session.date_id = _next_date_id
	_next_date_id += 1
	session.girl_id = request.girl_id
	session.location_id = request.location_id
	session.tutorial_mode = request.tutorial_mode
	session.greeting_ids = request.greeting_ids.duplicate()
	session.farewell_id = request.farewell_id
	if request.location_id == &"apartment" and not request.tutorial_mode:
		var prepared: bool = false
		if gs.has_method("get_story_flag"):
			prepared = bool(gs.call("get_story_flag", DateVenueCatalog.PREPARED_FLAG))
		session.apartment_was_prepared = prepared
		if prepared and gs.has_method("set_story_flag"):
			gs.call("set_story_flag", DateVenueCatalog.PREPARED_FLAG, false)
	var planned_ids: Array = plan.get("event_ids", []) as Array
	var ids: Array[StringName] = []
	for eid in planned_ids:
		ids.append(eid as StringName)
	session.central_event_ids = ids
	session.central_categories = plan.get("categories", []) as Array
	session.phase = DatingTypes.Phase.ARRIVAL
	_session = session
	_enter_modal_control()
	arrival_presentation_requested.emit(session.girl_id)
	phase_changed.emit(session.phase)
	return {"ok": true, "error": DatingTypes.ERR_OK, "session": session}


func _build_event_plan(
	request: DatingStartRequest,
	girl: GirlDefinition,
	db: Node,
) -> Dictionary:
	if request.forced_event_ids.is_empty():
		return DatingEventPlanner.plan_central_events(
			girl,
			db,
			request.location_id,
			request.excluded_event_ids,
			_rng,
		)
	var ids: Array[StringName] = request.forced_event_ids.duplicate()
	var categories: Array = []
	if ids.size() != 3:
		return {"ok": false}
	for event_id in ids:
		var event: DatingEventDefinition = db.call(
			"get_dating_event",
			event_id,
		) as DatingEventDefinition
		if event == null:
			return {"ok": false}
		if not DatingEventPlanner.event_allowed_at_location(
			event,
			request.location_id,
		):
			return {"ok": false}
		categories.append(event.category)
	return {
		"ok": true,
		"event_ids": ids,
		"categories": categories,
		"error": DatingTypes.ERR_OK,
	}


func continue_arrival() -> Dictionary:
	if _session == null or _session.finished:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if _session.phase != DatingTypes.Phase.ARRIVAL:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	_set_phase(DatingTypes.Phase.GREETING)
	return {"ok": true, "error": DatingTypes.ERR_OK}


func can_use_second_outfit() -> bool:
	if _session == null or _session.finished:
		return false
	if _session.used_second_outfit or _session.first_evaluated_started:
		return false
	if (
		_session.phase != DatingTypes.Phase.ARRIVAL
		and _session.phase != DatingTypes.Phase.GREETING
	):
		return false
	var gs: Node = get_node("/root/GameState")
	return bool(gs.call("has_perk", PerkIds.APPEARANCE_SECOND_OUTFIT))


func use_second_outfit() -> Dictionary:
	if not can_use_second_outfit():
		return _fail(DatingTypes.ERR_INVALID_CHOICE)
	_session.used_second_outfit = true
	second_outfit_requested.emit(_session.girl_id)
	return {"ok": true, "error": DatingTypes.ERR_OK}


func list_greeting_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _session == null or _session.phase != DatingTypes.Phase.GREETING:
		return out
	var db: Node = get_node("/root/ContentDB")
	var gs: Node = get_node("/root/GameState")
	for gid in _session.greeting_ids:
		var def: DatingGreetingDefinition = db.call("get_dating_greeting", gid) as DatingGreetingDefinition
		if def == null:
			continue
		var available: bool = true
		var reason: String = ""
		if def.has_requirement:
			var level: int = int(gs.call("get_characteristic", def.required_characteristic))
			if level < def.required_level:
				available = false
				reason = "%s %s" % [_char_label(def.required_characteristic), def.required_level]
		out.append({
			"id": def.id,
			"label": def.label,
			"available": available,
			"reason": reason,
			"silence": false,
		})
	if bool(gs.call("has_perk", PerkIds.AURA_RIGHT_TO_SAY_NOTHING)):
		out.append({
			"id": DatingTypes.SILENCE_GREETING_ID,
			"label": "Ничего не говорить",
			"available": true,
			"reason": "",
			"silence": true,
		})
	return out


func select_greeting(greeting_id: StringName) -> Dictionary:
	if _session == null or _session.finished:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if _session.phase != DatingTypes.Phase.GREETING:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	if greeting_id == DatingTypes.SILENCE_GREETING_ID:
		return _select_silence()
	var db: Node = get_node("/root/ContentDB")
	var gs: Node = get_node("/root/GameState")
	if not _session.greeting_ids.has(greeting_id):
		return _fail(DatingTypes.ERR_INVALID_CHOICE)
	var def: DatingGreetingDefinition = db.call("get_dating_greeting", greeting_id) as DatingGreetingDefinition
	if def == null:
		return _fail(DatingTypes.ERR_MISSING_GREETING)
	if def.has_requirement:
		var level: int = int(gs.call("get_characteristic", def.required_characteristic))
		if level < def.required_level:
			return _fail(DatingTypes.ERR_ACTION_UNAVAILABLE)
	if def.direct_tags.size() > 2:
		return _fail(DatingTypes.ERR_INVALID_ACTION_RESULT)
	var girl: GirlDefinition = db.call("get_girl", _session.girl_id) as GirlDefinition
	var reaction: int = PrimaryTraitEvaluator.evaluate(girl.primary_trait, def.direct_tags)
	_session.selected_greeting_id = greeting_id
	_session.greeting_reaction = reaction
	_session.last_primary_reaction = reaction
	_session.last_result_text = def.result_text
	gs.call("record_girl_known_reaction", _session.girl_id, greeting_id, reaction)
	reaction_presented.emit(reaction, def.result_text)
	_begin_central(0)
	return {"ok": true, "error": DatingTypes.ERR_OK, "reaction": reaction}


func _select_silence() -> Dictionary:
	var gs: Node = get_node("/root/GameState")
	if not bool(gs.call("has_perk", PerkIds.AURA_RIGHT_TO_SAY_NOTHING)):
		return _fail(DatingTypes.ERR_INVALID_CHOICE)
	_session.selected_greeting_id = DatingTypes.SILENCE_GREETING_ID
	_session.greeting_reaction = 0
	_session.used_right_to_say_nothing = true
	_session.last_primary_reaction = 0
	_session.last_result_text = ""
	gs.call("record_girl_known_reaction", _session.girl_id, DatingTypes.SILENCE_GREETING_ID, 0)
	_reveal_next_unknown_clues(1)
	if bool(gs.call("has_perk", PerkIds.AURA_SHE_ALREADY_STARTED)):
		_reveal_next_unknown_clues(1)
	reaction_presented.emit(0, "")
	_begin_central(0)
	return {"ok": true, "error": DatingTypes.ERR_OK, "reaction": 0}


func _reveal_next_unknown_clues(count: int) -> void:
	var db: Node = get_node("/root/ContentDB")
	var gs: Node = get_node("/root/GameState")
	var girl: GirlDefinition = db.call("get_girl", _session.girl_id) as GirlDefinition
	if girl == null:
		return
	var revealed: int = 0
	for i in range(girl.clue_notes.size()):
		if revealed >= count:
			break
		var known: bool = bool(gs.call("is_girl_clue_known", _session.girl_id, i))
		if known:
			continue
		gs.call("reveal_girl_clue", _session.girl_id, i)
		revealed += 1


func _begin_central(index: int) -> void:
	_session.current_event_index = index
	if index <= 2:
		_set_phase(DatingTypes.Phase.CENTRAL_EVENT)
	else:
		_set_phase(DatingTypes.Phase.FAREWELL)


func get_current_event() -> DatingEventDefinition:
	if _session == null:
		return null
	if _session.phase != DatingTypes.Phase.CENTRAL_EVENT:
		return null
	if _session.current_event_index < 0 or _session.current_event_index > 2:
		return null
	var db: Node = get_node("/root/ContentDB")
	var eid: StringName = _session.central_event_ids[_session.current_event_index]
	return db.call("get_dating_event", eid) as DatingEventDefinition


func get_current_farewell() -> DatingFarewellDefinition:
	if _session == null or _session.phase != DatingTypes.Phase.FAREWELL:
		return null
	var db: Node = get_node("/root/ContentDB")
	return db.call("get_dating_farewell", _session.farewell_id) as DatingFarewellDefinition


func list_action_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _session == null:
		return out
	var actions: Array[DatingActionDefinition] = _current_actions()
	for action in actions:
		out.append(_action_availability(action))
	return out


func _current_actions() -> Array[DatingActionDefinition]:
	var empty: Array[DatingActionDefinition] = []
	if _session == null:
		return empty
	if _session.phase == DatingTypes.Phase.CENTRAL_EVENT:
		var ev: DatingEventDefinition = get_current_event()
		if ev == null:
			return empty
		return ev.actions
	if _session.phase == DatingTypes.Phase.FAREWELL:
		var fw: DatingFarewellDefinition = get_current_farewell()
		if fw == null:
			return empty
		return fw.actions
	return empty


func _action_availability(action: DatingActionDefinition) -> Dictionary:
	var gs: Node = get_node("/root/GameState")
	if _session != null and _session.tutorial_mode:
		return {
			"id": action.id,
			"label": action.label,
			"available": true,
			"reason": "",
			"money_cost": action.money_cost,
			"effective_cost": 0,
			"free_via_representation": false,
			"uses_public_significance": false,
			"required_perk_id": action.required_perk_id,
			"characteristic": action.characteristic,
			"required_level": action.required_characteristic_level,
		}
	var available: bool = true
	var reasons: PackedStringArray = PackedStringArray()
	var uses_public_sig: bool = false
	var free_via_rep: bool = false
	var level: int = int(gs.call("get_characteristic", action.characteristic))
	var need: int = action.required_characteristic_level
	if level < need:
		var can_public: bool = (
			int(action.characteristic) == int(GameTypes.PlayerCharacteristic.APPEARANCE)
			and need == level + 1
			and (not _session.used_public_significance)
			and bool(gs.call("has_perk", PerkIds.APPEARANCE_PUBLIC_SIGNIFICANCE))
		)
		if can_public:
			uses_public_sig = true
		else:
			available = false
			reasons.append("%s %s" % [_char_label(action.characteristic), need])
	if String(action.required_perk_id) != "":
		if not bool(gs.call("has_perk", action.required_perk_id)):
			available = false
			reasons.append("Нужен перк: %s" % _perk_label(action.required_perk_id))
	var effective_cost: int = action.money_cost
	if action.money_cost > 0:
		var can_rep: bool = (
			(not action.is_major_expense)
			and (not _session.used_representation_expenses)
			and bool(gs.call("has_perk", PerkIds.CAPITAL_REPRESENTATION_EXPENSES))
		)
		if can_rep:
			free_via_rep = true
			effective_cost = 0
		elif not bool(gs.call("can_afford", action.money_cost)):
			available = false
			reasons.append("Деньги: %s" % action.money_cost)
	return {
		"id": action.id,
		"label": action.label,
		"available": available,
		"reason": ", ".join(reasons),
		"money_cost": action.money_cost,
		"effective_cost": effective_cost,
		"free_via_representation": free_via_rep,
		"uses_public_significance": uses_public_sig,
		"required_perk_id": action.required_perk_id,
		"characteristic": action.characteristic,
		"required_level": need,
	}


func select_action(action_id: StringName) -> Dictionary:
	if _session == null or _session.finished:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if (
		_session.phase != DatingTypes.Phase.CENTRAL_EVENT
		and _session.phase != DatingTypes.Phase.FAREWELL
	):
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	var action: DatingActionDefinition = _find_action(action_id)
	if action == null:
		return _fail(DatingTypes.ERR_INVALID_CHOICE)
	var event_id: StringName = _current_event_id()
	if (
		_session.tutorial_mode
		and not NeighborTutorialCatalog.is_correct(event_id, action_id)
	):
		var explanation: String = NeighborTutorialCatalog.explanation_for(action_id)
		tutorial_correction_presented.emit(explanation)
		return {
			"ok": true,
			"error": DatingTypes.ERR_OK,
			"tutorial_retry": true,
		}
	var avail: Dictionary = _action_availability(action)
	if not bool(avail.get("available", false)):
		return _fail(DatingTypes.ERR_ACTION_UNAVAILABLE)
	_session.first_evaluated_started = true
	var uses_ps: bool = bool(avail.get("uses_public_significance", false))
	if uses_ps:
		_session.used_public_significance = true
	var money_cost: int = action.money_cost
	var money_spent: int = 0
	var gs: Node = get_node("/root/GameState")
	if money_cost > 0:
		var free_rep: bool = bool(avail.get("free_via_representation", false))
		if free_rep:
			_session.used_representation_expenses = true
			money_spent = 0
		else:
			if not bool(gs.call("spend_money", money_cost)):
				return _fail(DatingTypes.ERR_ACTION_UNAVAILABLE)
			money_spent = money_cost
			_session.money_spent_total += money_spent
	_session.pending_action = action
	_session.pending_event_id = event_id
	_session.pending_money_cost = money_cost
	_session.pending_money_spent = money_spent
	_session.pending_used_public_significance = uses_ps
	_session.pending_money_refunded = false
	if action.resolver_id == &"direct" or String(action.resolver_id) == "" or action.resolver_id == &"":
		var direct := DatingActionExecutionResult.new()
		direct.outcome = DatingTypes.ExecutionOutcome.SUCCESS
		direct.has_tag_override = false
		direct.tags = action.direct_tags.duplicate()
		direct.was_public = action.is_public
		direct.result_text = action.result_text
		return _apply_execution_result(direct)
	var req := DatingActionExecutionRequest.new()
	req.girl_id = _session.girl_id
	req.event_id = event_id
	req.action_id = action.id
	req.resolver_id = action.resolver_id
	req.characteristic = action.characteristic
	req.base_tags = action.direct_tags.duplicate()
	req.is_public = action.is_public
	_session.pending_execution_request = req
	if _external_resolver.is_valid():
		var resolved: Variant = _external_resolver.call(req)
		if resolved is DatingActionExecutionResult:
			return _apply_execution_result(resolved as DatingActionExecutionResult)
	_set_phase(DatingTypes.Phase.RESOLVING_ACTION)
	action_execution_requested.emit(req)
	return {"ok": true, "error": DatingTypes.ERR_OK, "waiting": true}


func submit_action_execution_result(result: DatingActionExecutionResult) -> Dictionary:
	if _session == null or _session.finished:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if _session.phase != DatingTypes.Phase.RESOLVING_ACTION:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	if result == null:
		return _fail(DatingTypes.ERR_INVALID_ACTION_RESULT)
	if result.tags.size() > 2:
		return _fail(DatingTypes.ERR_INVALID_ACTION_RESULT)
	return _apply_execution_result(result)


func _apply_execution_result(result: DatingActionExecutionResult) -> Dictionary:
	var action: DatingActionDefinition = _session.pending_action
	if action == null:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	var tags: Array[GameTypes.ActionTag] = []
	if result.has_tag_override:
		tags = result.tags.duplicate()
	else:
		tags = action.direct_tags.duplicate()
	if tags.size() > 2:
		return _fail(DatingTypes.ERR_INVALID_ACTION_RESULT)
	var was_public: bool = result.was_public
	var gs: Node = get_node("/root/GameState")
	var refunded: bool = false
	if (
		int(result.outcome) == int(DatingTypes.ExecutionOutcome.FAILURE)
		and _session.pending_money_spent > 0
		and bool(gs.call("has_perk", PerkIds.CAPITAL_DIGNITY_REFUND))
	):
		gs.call("add_money", _session.pending_money_spent)
		_session.money_spent_total = maxi(0, _session.money_spent_total - _session.pending_money_spent)
		_session.pending_money_spent = 0
		refunded = true
	var db: Node = get_node("/root/ContentDB")
	var girl: GirlDefinition = db.call("get_girl", _session.girl_id) as GirlDefinition
	var primary: int = PrimaryTraitEvaluator.evaluate(girl.primary_trait, tags)
	_session.pending_execution = result
	_session.pending_tags = tags
	_session.pending_was_public = was_public
	_session.pending_primary = primary
	_session.pending_money_refunded = refunded
	_session.pending_result_text = result.result_text if result.result_text != "" else action.result_text
	var can_encore: bool = (
		int(action.characteristic) == int(GameTypes.PlayerCharacteristic.APPEARANCE)
		and primary == 0
		and (not _session.used_encore)
		and bool(gs.call("has_perk", PerkIds.APPEARANCE_ENCORE))
	)
	if can_encore:
		_set_phase(DatingTypes.Phase.ENCORE_DECISION)
		return {"ok": true, "error": DatingTypes.ERR_OK, "encore": true, "reaction": primary}
	return _commit_pending(false)


func resolve_encore(use_encore: bool) -> Dictionary:
	if _session == null or _session.finished:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if _session.phase != DatingTypes.Phase.ENCORE_DECISION:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	if use_encore:
		_session.used_encore = true
		_session.pending_tags = _transform_encore_tags(_session.pending_tags)
		var db: Node = get_node("/root/ContentDB")
		var girl: GirlDefinition = db.call("get_girl", _session.girl_id) as GirlDefinition
		_session.pending_primary = PrimaryTraitEvaluator.evaluate(girl.primary_trait, _session.pending_tags)
		encore_presentation_requested.emit(_session.girl_id, _session.pending_action.id)
		return _commit_pending(true)
	return _commit_pending(false)


func _transform_encore_tags(tags: Array[GameTypes.ActionTag]) -> Array[GameTypes.ActionTag]:
	var out: Array[GameTypes.ActionTag] = tags.duplicate()
	if out.has(GameTypes.ActionTag.ORIGINALITY):
		return out
	if out.is_empty():
		out.append(GameTypes.ActionTag.ORIGINALITY)
	elif out.size() == 1:
		out.append(GameTypes.ActionTag.ORIGINALITY)
	else:
		out[1] = GameTypes.ActionTag.ORIGINALITY
	return out


func _commit_pending(used_encore_flag: bool) -> Dictionary:
	var action: DatingActionDefinition = _session.pending_action
	var rec := DatingDecisionRecord.new()
	rec.source_id = action.id
	rec.event_id = _session.pending_event_id
	rec.characteristic = action.characteristic
	rec.final_tags = _session.pending_tags.duplicate()
	rec.primary_reaction = _session.pending_primary
	rec.execution_outcome = _session.pending_execution.outcome
	rec.was_public = _session.pending_was_public
	rec.money_cost = _session.pending_money_cost
	rec.money_spent = _session.pending_money_spent
	rec.used_public_significance = _session.pending_used_public_significance
	rec.used_encore = used_encore_flag
	rec.money_paid_then_refunded = _session.pending_money_refunded
	_session.decision_records.append(rec)
	var gs: Node = get_node("/root/GameState")
	gs.call(
		"record_girl_known_reaction",
		_session.girl_id,
		action.id,
		rec.primary_reaction,
	)
	_session.last_primary_reaction = rec.primary_reaction
	_session.last_result_text = _session.pending_result_text
	reaction_presented.emit(rec.primary_reaction, _session.pending_result_text)
	_clear_pending()
	if _session.decision_records.size() < 3:
		_begin_central(_session.decision_records.size())
	elif _session.decision_records.size() == 3:
		_set_phase(DatingTypes.Phase.FAREWELL)
	elif _session.decision_records.size() == 4:
		return _finish_secondary_and_close()
	else:
		push_error("[DatingCore] unexpected decision_records size")
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	return {"ok": true, "error": DatingTypes.ERR_OK, "reaction": rec.primary_reaction, "record": rec}


func _finish_secondary_and_close() -> Dictionary:
	_set_phase(DatingTypes.Phase.SECONDARY_EVALUATION)
	if _session.decision_records.size() != 4:
		push_error("[DatingCore] secondary without 4 records")
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	var db: Node = get_node("/root/ContentDB")
	var girl: GirlDefinition = db.call("get_girl", _session.girl_id) as GirlDefinition
	var primary_total: int = 0
	for rec in _session.decision_records:
		primary_total += rec.primary_reaction
	var secondary: int = SecondaryTraitEvaluator.evaluate(girl.secondary_trait, _session.decision_records)
	var trait_delta: int = clampi(primary_total + secondary, -5, 5)
	var venue_quality: int = 0
	var leisure_bonus: int = 0
	var apartment_penalty: int = 0
	var outfit_bonus: int = 0
	if not _session.tutorial_mode:
		venue_quality = DateVenueCatalog.quality_bonus(_session.location_id)
		leisure_bonus = DateVenueCatalog.leisure_preference_bonus(
			_session.location_id, girl.leisure_format_ids
		)
		if _session.location_id == &"apartment" and not _session.apartment_was_prepared:
			apartment_penalty = -1
		var gs: Node = get_node_or_null("/root/GameState")
		var equipped: StringName = ApartmentWardrobeCatalog.get_equipped(gs)
		outfit_bonus = DateVenueCatalog.outfit_bonus(equipped)
	var delta: int = (
		trait_delta + venue_quality + leisure_bonus + apartment_penalty + outfit_bonus
	)
	_session.primary_total = primary_total
	_session.secondary_reaction = secondary
	_session.date_delta = delta
	var result := DatingResult.new()
	result.date_id = _session.date_id
	result.girl_id = _session.girl_id
	result.location_id = _session.location_id
	result.tutorial_mode = _session.tutorial_mode
	result.greeting_id = _session.selected_greeting_id
	result.greeting_reaction = _session.greeting_reaction
	result.central_event_ids = _session.central_event_ids.duplicate()
	result.decision_records = _session.decision_records.duplicate()
	result.primary_total = primary_total
	result.secondary_reaction = secondary
	result.trait_delta = trait_delta
	result.venue_quality_bonus = venue_quality
	result.leisure_preference_bonus = leisure_bonus
	result.apartment_prep_penalty = apartment_penalty
	result.outfit_bonus = outfit_bonus
	result.date_delta = delta
	result.money_spent_total = _session.money_spent_total
	result.used_right_to_say_nothing = _session.used_right_to_say_nothing
	result.used_second_outfit = _session.used_second_outfit
	_session.result = result
	_session.finished = true
	_set_phase(DatingTypes.Phase.FINISHED)
	if not _session.date_finished_emitted:
		_session.date_finished_emitted = true
		date_finished.emit(result)
	return {"ok": true, "error": DatingTypes.ERR_OK, "result": result}


func close_finished_date() -> Dictionary:
	if _session == null:
		return _fail(DatingTypes.ERR_SESSION_FINISHED)
	if not _session.finished:
		return _fail(DatingTypes.ERR_INVALID_PHASE)
	var result: DatingResult = _session.result
	_session = null
	_release_control()
	return {"ok": true, "error": DatingTypes.ERR_OK, "result": result}


func find_dating_action(action_id: StringName) -> DatingActionDefinition:
	var db: Node = get_node("/root/ContentDB")
	if db.has_method("find_dating_action"):
		return db.call("find_dating_action", action_id) as DatingActionDefinition
	return null


func _find_action(action_id: StringName) -> DatingActionDefinition:
	for action in _current_actions():
		if action != null and action.id == action_id:
			return action
	return null


func _current_event_id() -> StringName:
	if _session.phase == DatingTypes.Phase.FAREWELL:
		return _session.farewell_id
	if _session.current_event_index >= 0 and _session.current_event_index <= 2:
		return _session.central_event_ids[_session.current_event_index]
	return &""


func _clear_pending() -> void:
	_session.pending_action = null
	_session.pending_event_id = &""
	_session.pending_execution = null
	_session.pending_tags.clear()
	_session.pending_was_public = false
	_session.pending_primary = 0
	_session.pending_money_cost = 0
	_session.pending_money_spent = 0
	_session.pending_used_public_significance = false
	_session.pending_money_refunded = false
	_session.pending_result_text = ""
	_session.pending_execution_request = null


func _set_phase(phase: DatingTypes.Phase) -> void:
	_session.phase = phase
	phase_changed.emit(phase)


func _fail(code: StringName) -> Dictionary:
	return {"ok": false, "error": code, "message": DatingTypes.user_message(code)}


func _enter_modal_control() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return
	if player.has_method("get_control_mode") and player.has_method("enter_modal_ui"):
		_control_owner = player
		_control_restore_mode = int(player.call("get_control_mode"))
		player.call("enter_modal_ui")


func _release_control() -> void:
	if _control_owner != null and is_instance_valid(_control_owner):
		if _control_restore_mode >= 0 and _control_owner.has_method("set_control_mode"):
			_control_owner.call("set_control_mode", _control_restore_mode)
		elif _control_owner.has_method("enter_gameplay"):
			_control_owner.call("enter_gameplay")
	_control_owner = null
	_control_restore_mode = -1


func _char_label(c: GameTypes.PlayerCharacteristic) -> String:
	match c:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "Мышца"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "Внешность"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "Капитал"
		GameTypes.PlayerCharacteristic.AURA:
			return "Аура"
	return "Характеристика"


func _perk_label(perk_id: StringName) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null:
		var def: PerkDefinition = db.call("get_perk", perk_id) as PerkDefinition
		if def != null and def.display_name.strip_edges() != "":
			return def.display_name
	return String(perk_id)
