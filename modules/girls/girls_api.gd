class_name GirlsAPI
extends Node
## Unique girls + procedural candidates.

signal girls_changed

var unlocked: Dictionary = {} ## girl_id -> {name, relation_points, relation_level, met, in_harem, bonus_on, last_visit, contact}
var candidates: Array[Dictionary] = []
var discovered_unique: Array[StringName] = []
var contacts: Array[String] = [] ## phone contact ids


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	unlocked.clear()
	candidates.clear()
	discovered_unique.clear()
	contacts.clear()
	# Neighbor always known and contactable from day one.
	_unlock_entry(&"neighbor", false, false)
	unlocked["neighbor"]["contact"] = true
	if not contacts.has("neighbor"):
		contacts.append("neighbor")
	_refresh_candidates()
	girls_changed.emit()


func _ensure_available_uniques() -> void:
	# Uniques are discovered via city talk (add_contact), not auto-phone dump.
	# Neighbor handled in reset().
	pass


func _stage_reached(need: String) -> bool:
	var order := {
		"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6
	}
	return int(order.get(str(Game.stage_id), 1)) >= int(order.get(need, 1))


func _unlock_entry(id: StringName, announce: bool, emit_change: bool = true) -> void:
	var def: Dictionary = ContentDB.girl(id)
	var display: String = Game.names.next_name()
	unlocked[str(id)] = {
		"id": str(id),
		"name": display,
		"relation_points": 0.0,
		"relation_level": 0,
		"met": false,
		"in_harem": false,
		"bonus_on": true,
		"contact": false,
		"last_visit": Time.get_unix_time_from_system(),
		"dates": 0,
	}
	if announce:
		EventBus.girl_unlocked.emit(id)
		EventBus.toast("%s теперь доступна для свиданий" % display, &"girl")
	if emit_change:
		girls_changed.emit()


func try_unlock_by_progress() -> void:
	# City discovery path owns unique introductions now.
	pass


func has_contact(id: StringName) -> bool:
	return contacts.has(str(id)) or (unlocked.has(str(id)) and bool(unlocked[str(id)].get("contact", false)))


func add_contact(id: StringName, profile: Dictionary = {}) -> void:
	var sid := str(id)
	if ContentDB.girls.has(sid):
		if not unlocked.has(sid):
			_unlock_entry(id, true, false)
		unlocked[sid]["contact"] = true
		if profile.has("name"):
			unlocked[sid]["name"] = str(profile.get("name"))
	else:
		# Procedural / city-only girl.
		if not unlocked.has(sid):
			unlocked[sid] = {
				"id": sid,
				"name": str(profile.get("name", Game.names.next_name())),
				"relation_points": 0.0,
				"relation_level": 0,
				"met": false,
				"in_harem": false,
				"bonus_on": true,
				"contact": true,
				"last_visit": Time.get_unix_time_from_system(),
				"dates": 0,
				"kind": "city",
				"likes": profile.get("likes", ["sincere"]),
				"dislikes": profile.get("dislikes", []),
				"archetype": str(profile.get("archetype", "Городская")),
				"color": profile.get("color", [0.95, 0.75, 0.7]),
			}
		else:
			unlocked[sid]["contact"] = true
	if not contacts.has(sid):
		contacts.append(sid)
	_refresh_candidates()
	girls_changed.emit()


func unlock_algorithm_if_ready() -> bool:
	if unlocked.has("algorithm") and bool(unlocked["algorithm"].get("met", false)):
		return true
	if not _finale_gates_ok():
		return false
	if not unlocked.has("algorithm"):
		_unlock_entry(&"algorithm", true)
	return true


func _finale_gates_ok() -> bool:
	var need_dates := int(ContentDB.balance.get("finale_need_dates", 40))
	var need_pop := float(ContentDB.balance.get("finale_need_popularity", 300))
	if Game.total_successful_dates < need_dates:
		return false
	if Game.economy.get_value(&"popularity") < need_pop:
		return false
	for id in ContentDB.girls.keys():
		if id == "algorithm":
			continue
		if not unlocked.has(id) or not bool(unlocked[id].get("met", false)):
			return false
	if not Game.facility.has_flag("megamachine_ready"):
		return false
	return true


func get_entry(id: StringName) -> Dictionary:
	return unlocked.get(str(id), {}).duplicate(true)


func get_def(id: StringName) -> Dictionary:
	return ContentDB.girl(id)


func display_name(id: StringName) -> String:
	var e := get_entry(id)
	if e.is_empty():
		return str(ContentDB.girl(id).get("archetype", id))
	var arch := str(e.get("archetype", ""))
	if arch.is_empty() and ContentDB.girls.has(str(id)):
		arch = str(ContentDB.girl(id).get("archetype", id))
	if arch.is_empty():
		arch = "Контакт"
	return "%s — %s" % [str(e.get("name", "?")), arch]


func mark_met(id: StringName) -> void:
	if not unlocked.has(str(id)):
		_unlock_entry(id, true)
	unlocked[str(id)]["met"] = true
	if not discovered_unique.has(id):
		discovered_unique.append(id)
	girls_changed.emit()


func add_relation(id: StringName, points: float) -> void:
	if not unlocked.has(str(id)):
		return
	var e: Dictionary = unlocked[str(id)]
	e["relation_points"] = float(e.get("relation_points", 0)) + points
	e["dates"] = int(e.get("dates", 0)) + 1
	var thresholds: Array = ContentDB.balance.get("relation_thresholds", [0, 10, 25, 50, 90])
	var lvl := 0
	for i in range(thresholds.size()):
		if float(e["relation_points"]) >= float(thresholds[i]):
			lvl = i
	var prev := int(e.get("relation_level", 0))
	e["relation_level"] = lvl
	if lvl >= 3 and not bool(e.get("in_harem", false)):
		e["in_harem"] = true
		EventBus.toast("%s переехала в жилую часть" % display_name(id), &"girl")
	unlocked[str(id)] = e
	EventBus.relation_changed.emit(id, lvl, float(e["relation_points"]))
	if lvl > prev:
		EventBus.toast("Отношения с %s: уровень %d" % [display_name(id), lvl + 1], &"girl")
	girls_changed.emit()


func visit_harem(id: StringName) -> void:
	if unlocked.has(str(id)):
		unlocked[str(id)]["last_visit"] = Time.get_unix_time_from_system()


func active_effects() -> Dictionary:
	var acc := {}
	for id in unlocked.keys():
		var e: Dictionary = unlocked[id]
		if not bool(e.get("met", false)) or not bool(e.get("bonus_on", true)):
			continue
		if int(e.get("relation_level", 0)) < 1:
			continue
		var def := ContentDB.girl(StringName(id))
		var effects: Dictionary = def.get("effects", {})
		for k in effects.keys():
			var v = effects[k]
			if typeof(v) == TYPE_BOOL:
				acc[k] = bool(acc.get(k, false)) or bool(v)
			else:
				acc[k] = float(acc.get(k, 0.0)) + float(v)
	if Game.upgrades.has_effect("synergies"):
		_apply_synergies(acc)
	return acc


func _apply_synergies(acc: Dictionary) -> void:
	if _met("streamer") and _met("star"):
		acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) + 0.25
	if _met("business") and _met("lawyer"):
		acc["staff_cost_mult"] = float(acc.get("staff_cost_mult", 1.0)) * 0.9
		acc["fine_mult"] = float(acc.get("fine_mult", 1.0)) * 0.9
	if _met("scientist") and _met("alien"):
		acc["line_mult"] = float(acc.get("line_mult", 1.0)) + 0.2
	if _met("fashionista") and _met("streamer"):
		acc["outfit_mult"] = float(acc.get("outfit_mult", 1.0)) + 0.15
	if _met("neighbor") and _met("fitness"):
		acc["attention_regen"] = float(acc.get("attention_regen", 0.0)) + 0.1


func is_met(id: StringName) -> bool:
	return unlocked.has(str(id)) and bool(unlocked[str(id)].get("met", false))


func _met(id: String) -> bool:
	return is_met(StringName(id))


func _refresh_candidates() -> void:
	candidates.clear()
	for id in contacts:
		var e: Dictionary = unlocked.get(id, {})
		if e.is_empty():
			continue
		var kind := "unique" if ContentDB.girls.has(id) else "city"
		if str(e.get("kind", "")) == "city":
			kind = "city"
		candidates.append({
			"kind": kind,
			"id": id,
			"name": str(e.get("name", "?")),
			"archetype": str(e.get("archetype", ContentDB.girl(StringName(id)).get("archetype", "Контакт"))),
			"likes": e.get("likes", ContentDB.girl(StringName(id)).get("likes", [])),
			"dislikes": e.get("dislikes", ContentDB.girl(StringName(id)).get("dislikes", [])),
		})
	# Extra procedural mass candidates if stage >= 2 (factory filler).
	var slots := 2 + int(Game.upgrades.effect_value("candidate_slots"))
	if _stage_reached("stage_2"):
		for i in range(slots):
			candidates.append(_make_procedural())


func _make_procedural() -> Dictionary:
	var tag_pool := ["calm", "sport", "fashion", "media", "cheap", "luxury", "tech", "weird"]
	var likes: Array = []
	likes.append(tag_pool[randi() % tag_pool.size()])
	likes.append(tag_pool[randi() % tag_pool.size()])
	return {
		"kind": "proc",
		"id": "proc_%d" % randi(),
		"name": Game.names.next_name(),
		"archetype": "Кандидатка",
		"likes": likes,
		"dislikes": [tag_pool[randi() % tag_pool.size()]],
	}


func refresh_candidates(emit_change: bool = true) -> void:
	try_unlock_by_progress()
	_refresh_candidates()
	if emit_change:
		girls_changed.emit()


func list_harem() -> Array:
	var out: Array = []
	for id in unlocked.keys():
		if bool(unlocked[id].get("in_harem", false)):
			out.append(unlocked[id].duplicate(true))
	return out


func to_dict() -> Dictionary:
	var disc: Array = []
	for d in discovered_unique:
		disc.append(str(d))
	return {"unlocked": unlocked.duplicate(true), "discovered_unique": disc, "contacts": contacts.duplicate()}


func from_dict(data: Dictionary) -> void:
	unlocked = data.get("unlocked", {})
	discovered_unique.clear()
	for d in data.get("discovered_unique", []):
		discovered_unique.append(StringName(str(d)))
	contacts.clear()
	for c in data.get("contacts", []):
		contacts.append(str(c))
	# Migrate old saves: unlocked neighbor without contacts list.
	if contacts.is_empty() and unlocked.has("neighbor"):
		contacts.append("neighbor")
		unlocked["neighbor"]["contact"] = true
	for id in unlocked.keys():
		if bool(unlocked[id].get("contact", false)) and not contacts.has(id):
			contacts.append(id)
	refresh_candidates()
