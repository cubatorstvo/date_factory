class_name DatingEventPlanner
extends RefCounted
## Content-aware category/event planner for one date (MODULE 09).


static func all_valid_category_sequences() -> Array:
	var cats: Array = [
		GameTypes.DatingEventCategory.CONVERSATION,
		GameTypes.DatingEventCategory.SPACE_EVENT,
		GameTypes.DatingEventCategory.GIRL_PROPOSAL,
	]
	var out: Array = []
	for a in cats:
		for b in cats:
			for c in cats:
				if int(a) == int(b) and int(b) == int(c):
					continue
				out.append([a, b, c])
	return out


static func marginal_category_counts(sequences: Array) -> Array:
	## Returns [slot0_counts_dict, slot1_counts_dict, slot2_counts_dict]
	var slots: Array = [{}, {}, {}]
	for seq in sequences:
		var triple: Array = seq as Array
		for i in range(3):
			var key: int = int(triple[i])
			var d: Dictionary = slots[i] as Dictionary
			d[key] = int(d.get(key, 0)) + 1
	return slots


static func collect_candidate_events(
	girl: GirlDefinition,
	db: Node,
) -> Array[DatingEventDefinition]:
	var out: Array[DatingEventDefinition] = []
	var seen: Dictionary = {}
	if girl == null or db == null:
		return out
	for pool_id in girl.dating_pool_ids:
		var pool: DatingEventPoolDefinition = db.call("get_dating_pool", pool_id) as DatingEventPoolDefinition
		if pool == null:
			continue
		for eid in pool.event_ids:
			if seen.has(eid):
				continue
			seen[eid] = true
			var ev: DatingEventDefinition = db.call("get_dating_event", eid) as DatingEventDefinition
			if ev != null:
				out.append(ev)
	return out


static func event_allowed_at_location(ev: DatingEventDefinition, location_id: StringName) -> bool:
	if ev == null:
		return false
	if ev.allowed_location_ids.is_empty():
		return true
	return ev.allowed_location_ids.has(location_id)


static func filter_events_for_slot(
	candidates: Array[DatingEventDefinition],
	category: GameTypes.DatingEventCategory,
	location_id: StringName,
	excluded: Dictionary,
	already_picked: Dictionary,
) -> Array[DatingEventDefinition]:
	var out: Array[DatingEventDefinition] = []
	for ev in candidates:
		if ev == null:
			continue
		if int(ev.category) != int(category):
			continue
		if already_picked.has(ev.id):
			continue
		if excluded.has(ev.id):
			continue
		if not event_allowed_at_location(ev, location_id):
			continue
		out.append(ev)
	return out


static func sequence_has_assignment(
	sequence: Array,
	candidates: Array[DatingEventDefinition],
	location_id: StringName,
	excluded: Dictionary,
) -> bool:
	var already: Dictionary = {}
	return _backtrack_assign(0, sequence, candidates, location_id, excluded, already)


static func _backtrack_assign(
	slot: int,
	sequence: Array,
	candidates: Array[DatingEventDefinition],
	location_id: StringName,
	excluded: Dictionary,
	already: Dictionary,
) -> bool:
	if slot >= 3:
		return true
	var cat: GameTypes.DatingEventCategory = sequence[slot] as GameTypes.DatingEventCategory
	var options: Array[DatingEventDefinition] = filter_events_for_slot(
		candidates, cat, location_id, excluded, already
	)
	for ev in options:
		already[ev.id] = true
		if _backtrack_assign(slot + 1, sequence, candidates, location_id, excluded, already):
			return true
		already.erase(ev.id)
	return false


static func try_assign_events_for_sequence(
	sequence: Array,
	candidates: Array[DatingEventDefinition],
	location_id: StringName,
	excluded: Dictionary,
	rng: RandomNumberGenerator,
) -> Array[StringName]:
	## Returns 3 event ids or empty on failure. Slot-by-slot uniform pick.
	var picked_ids: Array[StringName] = []
	var already: Dictionary = {}
	for i in range(3):
		var cat: GameTypes.DatingEventCategory = sequence[i] as GameTypes.DatingEventCategory
		var options: Array[DatingEventDefinition] = filter_events_for_slot(
			candidates, cat, location_id, excluded, already
		)
		if options.is_empty():
			var empty: Array[StringName] = []
			return empty
		var idx: int = rng.randi_range(0, options.size() - 1)
		var chosen: DatingEventDefinition = options[idx]
		picked_ids.append(chosen.id)
		already[chosen.id] = true
	return picked_ids


static func plan_central_events(
	girl: GirlDefinition,
	db: Node,
	location_id: StringName,
	excluded_event_ids: Array[StringName],
	rng: RandomNumberGenerator,
) -> Dictionary:
	## {ok:bool, event_ids:Array[StringName], categories:Array, error:StringName}
	var empty_ids: Array[StringName] = []
	if girl == null or db == null or rng == null:
		return {"ok": false, "event_ids": empty_ids, "categories": [], "error": DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT}
	var excluded: Dictionary = {}
	for eid in excluded_event_ids:
		excluded[eid] = true
	var candidates: Array[DatingEventDefinition] = collect_candidate_events(girl, db)
	var sequences: Array = all_valid_category_sequences()
	var feasible: Array = []
	for seq in sequences:
		if sequence_has_assignment(seq as Array, candidates, location_id, excluded):
			feasible.append(seq)
	if feasible.is_empty():
		return {"ok": false, "event_ids": empty_ids, "categories": [], "error": DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT}
	var pick_i: int = rng.randi_range(0, feasible.size() - 1)
	var chosen_seq: Array = feasible[pick_i] as Array
	var event_ids: Array[StringName] = try_assign_events_for_sequence(
		chosen_seq, candidates, location_id, excluded, rng
	)
	if event_ids.size() != 3:
		return {"ok": false, "event_ids": empty_ids, "categories": [], "error": DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT}
	return {"ok": true, "event_ids": event_ids, "categories": chosen_seq, "error": DatingTypes.ERR_OK}
