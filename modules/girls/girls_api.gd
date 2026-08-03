class_name GirlsAPI
extends Node
## Unique girls + procedural candidates. Traits, bond, claimed list.

signal girls_changed

var unlocked: Dictionary = {} ## girl_id -> runtime entry
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
	pass


func _stage_reached(need: String) -> bool:
	var order: Dictionary = {
		"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6
	}
	return int(order.get(str(Game.stage_id), 1)) >= int(order.get(need, 1))


func _stage_num() -> int:
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1))


func insight_level() -> int:
	## How many traits are visible by default before dating reveals.
	var n: int = 1
	var st: int = _stage_num()
	if st >= 3:
		n += 1
	if st >= 5:
		n += 1
	if st >= 6:
		n += 1
	n += int(list_claimed().size() / 2)
	return n


func _pack_for(profile: Dictionary, unique_id: String = "") -> Dictionary:
	if ContentDB.girls.has(unique_id):
		var def: Dictionary = ContentDB.girl(StringName(unique_id))
		var primaries: Array = TraitsContent.sanitize_primaries(def.get("primary_traits", []))
		if primaries.is_empty():
			primaries = TraitsContent.sanitize_primaries(def.get("traits", []))
		return {
			"primary_traits": primaries,
			"traits": TraitsContent.dialogue_traits_from_primaries(primaries),
			"quirk": str(def.get("quirk", TraitsContent.pick_quirk())),
		}
	var base: Dictionary = profile.duplicate(true)
	if base.get("primary_traits", []).is_empty() and base.has("traits"):
		base["primary_traits"] = TraitsContent.sanitize_primaries(base.get("traits", []))
	return TraitsContent.pack_for_profile(base)


func _default_traits_for(profile: Dictionary, unique_id: String = "") -> Array:
	return _pack_for(profile, unique_id).get("traits", []).duplicate()


func _default_tier_for(profile: Dictionary, unique_id: String = "") -> String:
	if ContentDB.girls.has(unique_id):
		return str(ContentDB.girl(StringName(unique_id)).get("tier", "simple"))
	return str(profile.get("tier", "simple"))


func _seed_revealed(traits: Array) -> Array:
	## No free confirms: traits become confirmed only via hypotheses (stage 2+).
	# Soft tutorial naming is stage 3 presentation, not pre-confirmed knowledge.
	return []


func _unlock_entry(id: StringName, announce: bool, emit_change: bool = true) -> void:
	var def: Dictionary = ContentDB.girl(id)
	var display: String = Game.names.next_name()
	var pack: Dictionary = _pack_for(def, str(id))
	var traits: Array = pack.get("traits", [])
	var tier: String = str(def.get("tier", "simple"))
	unlocked[str(id)] = {
		"id": str(id),
		"name": display,
		"relation_points": 0.0,
		"relation_level": 0,
		"bond": 0.0,
		"met": false,
		"in_harem": false,
		"claimed": false,
		"bonus_on": true,
		"contact": false,
		"last_visit": Time.get_unix_time_from_system(),
		"dates": 0,
		"tier": tier,
		"traits": traits.duplicate(),
		"primary_traits": pack.get("primary_traits", []).duplicate(),
		"quirk": str(pack.get("quirk", "")),
		"revealed_traits": _seed_revealed(traits),
		"observations": [],
		"hypotheses": [],
		"reaction_log": [],
	}
	if announce:
		EventBus.girl_unlocked.emit(id)
		EventBus.toast("%s теперь доступна для свиданий" % display, &"girl")
	if emit_change:
		girls_changed.emit()


func try_unlock_by_progress() -> void:
	pass


func has_contact(id: StringName) -> bool:
	return contacts.has(str(id)) or (unlocked.has(str(id)) and bool(unlocked[str(id)].get("contact", false)))


func is_claimed(id: StringName) -> bool:
	return unlocked.has(str(id)) and bool(unlocked[str(id)].get("claimed", false))


func add_contact(id: StringName, profile: Dictionary = {}) -> void:
	var sid := str(id)
	if ContentDB.girls.has(sid):
		if not unlocked.has(sid):
			_unlock_entry(id, true, false)
		unlocked[sid]["contact"] = true
		if profile.has("name"):
			unlocked[sid]["name"] = str(profile.get("name"))
		_ensure_trait_fields(sid)
	else:
		# Procedural / city-only girl.
		if not unlocked.has(sid):
			var tier: String = _default_tier_for(profile, sid)
			var pack: Dictionary = _pack_for(profile, sid)
			var traits: Array = pack.get("traits", [])
			unlocked[sid] = {
				"id": sid,
				"name": str(profile.get("name", Game.names.next_name())),
				"relation_points": 0.0,
				"relation_level": 0,
				"bond": 0.0,
				"met": false,
				"in_harem": false,
				"claimed": false,
				"bonus_on": true,
				"contact": true,
				"last_visit": Time.get_unix_time_from_system(),
				"dates": 0,
				"kind": "city",
				"likes": profile.get("likes", ["sincere"]),
				"dislikes": profile.get("dislikes", []),
				"archetype": str(profile.get("archetype", "Городская")),
				"color": profile.get("color", [0.95, 0.75, 0.7]),
				"tier": tier,
				"traits": traits,
				"primary_traits": pack.get("primary_traits", []).duplicate(),
				"quirk": str(pack.get("quirk", "")),
				"revealed_traits": _seed_revealed(traits),
				"observations": [],
				"hypotheses": [],
				"reaction_log": [],
			}
		else:
			unlocked[sid]["contact"] = true
			_ensure_trait_fields(sid)
	if not contacts.has(sid):
		contacts.append(sid)
	_refresh_candidates()
	girls_changed.emit()


func _ensure_trait_fields(sid: String) -> void:
	if not unlocked.has(sid):
		return
	var e: Dictionary = unlocked[sid]
	if not e.has("tier"):
		e["tier"] = _default_tier_for(e, sid)
	var need_pack: bool = (not e.has("primary_traits")) or e.get("primary_traits", []).is_empty()
	if need_pack or not e.has("traits") or e.get("traits", []).is_empty():
		var pack: Dictionary = _pack_for(e, sid)
		e["primary_traits"] = pack.get("primary_traits", []).duplicate()
		e["traits"] = pack.get("traits", []).duplicate()
		if str(e.get("quirk", "")).is_empty():
			e["quirk"] = str(pack.get("quirk", ""))
	else:
		e["primary_traits"] = TraitsContent.sanitize_primaries(e.get("primary_traits", []))
		e["traits"] = TraitsContent.dialogue_traits_from_primaries(e["primary_traits"])
	if not e.has("quirk") or str(e.get("quirk", "")).is_empty():
		e["quirk"] = TraitsContent.pick_quirk()
	if not e.has("revealed_traits"):
		e["revealed_traits"] = _seed_revealed(e.get("traits", []))
	if not e.has("observations"):
		e["observations"] = []
	if not e.has("hypotheses"):
		e["hypotheses"] = []
	if not e.has("reaction_log"):
		e["reaction_log"] = []
	if not e.has("bond"):
		e["bond"] = float(e.get("relation_points", 0))
	if not e.has("claimed"):
		e["claimed"] = bool(e.get("in_harem", false)) and float(e.get("bond", 0)) >= 99.0
	unlocked[sid] = e


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
	var need_legend := float(ContentDB.balance.get("finale_need_legend", 40.0))
	if Game.total_successful_dates < need_dates:
		return false
	if Game.economy.get_value(&"popularity") < need_pop:
		return false
	if Game.economy.get_value(&"legend") < need_legend:
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
	var e: Dictionary = get_entry(id)
	if e.is_empty():
		return str(ContentDB.girl(id).get("archetype", id))
	var arch := str(e.get("archetype", ""))
	if arch.is_empty() and ContentDB.girls.has(str(id)):
		arch = str(ContentDB.girl(id).get("archetype", id))
	if arch.is_empty():
		arch = "Контакт"
	return "%s — %s" % [str(e.get("name", "?")), arch]


func girl_traits(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	var e: Dictionary = get_entry(id)
	if e.has("traits") and not e.get("traits", []).is_empty():
		return e.get("traits", []).duplicate()
	if ContentDB.girls.has(str(id)):
		return ContentDB.girl(id).get("traits", []).duplicate()
	return []


func girl_primary_traits(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	var e: Dictionary = get_entry(id)
	var primaries: Array = e.get("primary_traits", [])
	if not primaries.is_empty():
		return TraitsContent.sanitize_primaries(primaries)
	if ContentDB.girls.has(str(id)):
		return TraitsContent.sanitize_primaries(ContentDB.girl(id).get("primary_traits", []))
	return []


func girl_quirk(id: StringName) -> String:
	_ensure_trait_fields(str(id))
	return str(get_entry(id).get("quirk", ""))


func girl_tier(id: StringName) -> String:
	var e: Dictionary = get_entry(id)
	if e.has("tier"):
		return str(e.get("tier", "simple"))
	if ContentDB.girls.has(str(id)):
		return str(ContentDB.girl(id).get("tier", "simple"))
	return "simple"


func reward_mult(id: StringName) -> float:
	return TraitsContent.reward_mult(girl_tier(id))


func revealed_traits(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	return unlocked.get(str(id), {}).get("revealed_traits", []).duplicate()


func is_trait_revealed(id: StringName, trait_id: String) -> bool:
	return revealed_traits(id).has(trait_id)


func reveal_trait(id: StringName, trait_id: String, announce: bool = true) -> bool:
	## Confirms a trait (legacy name kept). Prefer apply_interpretation() for dating.
	if not unlocked.has(str(id)):
		return false
	_ensure_trait_fields(str(id))
	var e: Dictionary = unlocked[str(id)]
	var revealed: Array = e.get("revealed_traits", []).duplicate()
	if revealed.has(trait_id):
		return false
	if not e.get("traits", []).has(trait_id):
		return false
	revealed.append(trait_id)
	e["revealed_traits"] = revealed
	unlocked[str(id)] = e
	if announce:
		EventBus.toast("Подтверждена черта: %s — %s" % [display_name(id), Loc.trait_name(trait_id)], &"girl")
		var popup := RevealPopup.ui()
		if popup:
			popup.present_trait(Loc.trait_name(trait_id), display_name(id))
	girls_changed.emit()
	if Game.trait_influence != null and is_claimed(id):
		Game.trait_influence.recount(true)
	return true


func observations(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	return unlocked.get(str(id), {}).get("observations", []).duplicate(true)


func hypotheses(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	return unlocked.get(str(id), {}).get("hypotheses", []).duplicate(true)


func reaction_log(id: StringName) -> Array:
	_ensure_trait_fields(str(id))
	return unlocked.get(str(id), {}).get("reaction_log", []).duplicate(true)


func add_observation(id: StringName, obs_id: String, text: String, hidden_trait: String, source: String = "date") -> Dictionary:
	if not unlocked.has(str(id)):
		return {}
	_ensure_trait_fields(str(id))
	var e: Dictionary = unlocked[str(id)]
	var list: Array = e.get("observations", []).duplicate(true)
	for o in list:
		if str(o.get("id", "")) == obs_id:
			return o
	var row: Dictionary = {
		"id": obs_id,
		"text": text,
		"hidden_trait": hidden_trait,
		"source": source,
		"time": Time.get_unix_time_from_system(),
	}
	list.append(row)
	e["observations"] = list
	unlocked[str(id)] = e
	girls_changed.emit()
	return row


func apply_interpretation(id: StringName, observation_id: String, interpret_trait: String, actual_trait: String, quality: String = "ok") -> Dictionary:
	## Player reply = hypothesis. Confirm trait only after 2 correct interpretations of different observations.
	var result: Dictionary = {
		"matched": false,
		"confirmed": false,
		"rejected": false,
		"hypothesis": false,
		"hypothesis_status": "",
		"status": "",
		"bond_hint": quality,
	}
	if not unlocked.has(str(id)):
		return result
	_ensure_trait_fields(str(id))
	var e: Dictionary = unlocked[str(id)]
	var hyps: Array = e.get("hypotheses", []).duplicate(true)
	# Neutral / empty interpret: reaction only, no hypothesis commit.
	if quality == "ok" or interpret_trait.is_empty():
		result["hypothesis_status"] = "neutral"
		result["status"] = "neutral"
		var log_n: Array = e.get("reaction_log", []).duplicate(true)
		log_n.append({
			"observation_id": observation_id,
			"interpret": interpret_trait,
			"actual": actual_trait,
			"quality": quality,
			"status": "neutral",
		})
		if log_n.size() > 40:
			log_n = log_n.slice(log_n.size() - 40, log_n.size())
		e["reaction_log"] = log_n
		unlocked[str(id)] = e
		girls_changed.emit()
		return result
	var matched: bool = interpret_trait == actual_trait
	var status: String = "rejected"
	if matched:
		status = "active"
		result["matched"] = true
		result["hypothesis"] = true
	else:
		result["rejected"] = true
	var hyp_id: String = "%s_%s_%d" % [observation_id, interpret_trait, hyps.size()]
	var hyp: Dictionary = {
		"id": hyp_id,
		"observation_id": observation_id,
		"trait_id": interpret_trait,
		"actual_trait": actual_trait,
		"status": status,
		"quality": quality,
		"time": Time.get_unix_time_from_system(),
	}
	if matched:
		var prior_obs: Dictionary = {}
		for h in hyps:
			if str(h.get("trait_id", "")) != actual_trait:
				continue
			if str(h.get("status", "")) != "active" and str(h.get("status", "")) != "confirmed":
				continue
			var oid: String = str(h.get("observation_id", ""))
			if oid != "" and oid != observation_id:
				prior_obs[oid] = true
		if prior_obs.size() >= 1 and not is_trait_revealed(id, actual_trait):
			hyp["status"] = "confirmed"
			result["confirmed"] = true
			result["hypothesis"] = false
			result["hypothesis_status"] = "confirmed"
			result["status"] = "confirmed"
			# Close prior active hyps for this trait.
			for i in range(hyps.size()):
				var ph: Dictionary = hyps[i]
				if str(ph.get("trait_id", "")) == actual_trait and str(ph.get("status", "")) == "active":
					ph["status"] = "confirmed"
					hyps[i] = ph
			reveal_trait(id, actual_trait, true)
			e = unlocked[str(id)]
			hyps = e.get("hypotheses", []).duplicate(true)
		else:
			result["hypothesis_status"] = "active"
			result["status"] = "active"
			if not is_trait_revealed(id, actual_trait):
				EventBus.toast("Гипотеза: похоже, для неё важно — %s" % Loc.trait_name(actual_trait), &"girl")
	else:
		result["hypothesis_status"] = "rejected"
		result["status"] = "rejected"
	hyps.append(hyp)
	e["hypotheses"] = hyps
	var log: Array = e.get("reaction_log", []).duplicate(true)
	log.append({
		"observation_id": observation_id,
		"interpret": interpret_trait,
		"actual": actual_trait,
		"quality": quality,
		"status": result["hypothesis_status"],
	})
	if log.size() > 40:
		log = log.slice(log.size() - 40, log.size())
	e["reaction_log"] = log
	unlocked[str(id)] = e
	girls_changed.emit()
	return result


func automation_confidence(id: StringName) -> float:
	## 0..1 how reliable auto-dates can be for this girl.
	var traits: Array = girl_traits(id)
	if traits.is_empty():
		return 0.25
	var confirmed: float = float(revealed_traits(id).size())
	var active_hyps: float = 0.0
	for h in hypotheses(id):
		if str(h.get("status", "")) == "active":
			active_hyps += 1.0
	var base: float = confirmed / float(maxi(traits.size(), 1))
	base += mini(0.15, active_hyps * 0.05)
	## §27 — high/unique harder to fully automate from thin knowledge.
	var tier: String = girl_tier(id)
	if tier == "high":
		base *= 0.75
	elif tier == "medium":
		base *= 0.9
	if ContentDB.girls.has(str(id)):
		base *= 0.85
	return clampf(base, 0.05, 1.0)


func allows_auto_date(id: StringName) -> bool:
	## Soft gate: high/unique need stronger knowledge before auto queues them.
	var conf: float = automation_confidence(id)
	if Game.trait_influence != null:
		conf = clampf(conf + Game.trait_influence.auto_confidence_bonus(id), 0.05, 1.0)
	if ContentDB.girls.has(str(id)) and not is_claimed(id):
		return conf >= 0.85
	match girl_tier(id):
		"high":
			return conf >= 0.7
		"medium":
			return conf >= 0.45
		_:
			return conf >= 0.3


func knowledge_band(id: StringName) -> String:
	var c: float = automation_confidence(id)
	if c >= 0.95:
		return "full"
	if c >= 0.65:
		return "high"
	if c >= 0.35:
		return "medium"
	return "low"


func known_traits_summary(id: StringName) -> String:
	var traits: Array = girl_traits(id)
	var revealed: Array = revealed_traits(id)
	var parts: PackedStringArray = PackedStringArray()
	for t in traits:
		if revealed.has(str(t)):
			parts.append(Loc.trait_name(t))
		else:
			parts.append("???")
	return ", ".join(parts)


func mark_met(id: StringName) -> void:
	if not unlocked.has(str(id)):
		if ContentDB.girls.has(str(id)):
			_unlock_entry(id, true)
		else:
			return
	unlocked[str(id)]["met"] = true
	_ensure_trait_fields(str(id))
	if ContentDB.girls.has(str(id)) and not discovered_unique.has(id):
		discovered_unique.append(id)
	girls_changed.emit()


func add_bond(id: StringName, delta: float) -> void:
	if not unlocked.has(str(id)):
		return
	if is_claimed(id):
		return
	_ensure_trait_fields(str(id))
	var e: Dictionary = unlocked[str(id)]
	var claim_at := float(ContentDB.balance.get("bond_claim", 100.0))
	var bond := clampf(float(e.get("bond", 0.0)) + delta, 0.0, claim_at)
	e["bond"] = bond
	e["dates"] = int(e.get("dates", 0)) + 1
	# Keep legacy fields roughly in sync for old UI/quests.
	e["relation_points"] = bond
	var thresholds: Array = ContentDB.balance.get("relation_thresholds", [0, 10, 25, 50, 90])
	var lvl := 0
	for i in range(thresholds.size()):
		if bond >= float(thresholds[i]):
			lvl = i
	var prev := int(e.get("relation_level", 0))
	e["relation_level"] = lvl
	var just_claimed := false
	if bond >= claim_at and not bool(e.get("claimed", false)):
		e["claimed"] = true
		e["in_harem"] = true
		just_claimed = true
		EventBus.toast("%s теперь в орбите. Подтверждённые черты усиливают культуру комплекса." % display_name(id), &"girl")
	elif lvl > prev:
		EventBus.toast("Связь с %s: %.0f%%" % [display_name(id), bond], &"girl")
	unlocked[str(id)] = e
	EventBus.relation_changed.emit(id, lvl, bond)
	girls_changed.emit()
	if just_claimed and Game.trait_influence != null:
		Game.trait_influence.recount(true)


func add_relation(id: StringName, points: float) -> void:
	## Legacy wrapper: relation points map into bond.
	add_bond(id, points)


func visit_harem(id: StringName) -> void:
	if not unlocked.has(str(id)):
		return
	var e: Dictionary = unlocked[str(id)]
	e["last_visit"] = Time.get_unix_time_from_system()
	e["orbit_visits"] = int(e.get("orbit_visits", 0)) + 1
	unlocked[str(id)] = e
	if not bool(e.get("claimed", false)):
		return
	# Permanent orbit presence: visiting her space gives soft support, not a date.
	Game.economy.add(&"attention", 0.35, &"orbit_visit")
	Game.economy.repair_legend(0.4, &"orbit_presence")
	EventBus.toast("%s: я здесь, если система снова пойдёт вразнос." % display_name(id), &"girl")
	# Rare late personal beat (hook for events / crises).
	if int(e["orbit_visits"]) % 3 == 0 and Game.events.active.is_empty():
		Game.events.open_runtime_event({
			"id": "orbit_late_%s" % str(id),
			"name": "Личное: %s" % display_name(id),
			"blurb": "%s просит коротко побыть рядом — не как на свидании, а как дома." % display_name(id),
			"choices": [
				{"id": "stay", "label": "Остаться рядом", "scandal": 0.0, "legend": 1.0, "money": 0.0},
				{"id": "later", "label": "Позже — сейчас фабрика", "scandal": 0.0, "legend": 0.0, "money": 0.0},
			],
		})
	# Don't emit girls_changed here — avoids mansion NPC rebuild on every visit.


func orbit_helper_for_crisis(cat: String) -> StringName:
	## Claimed orbit who can physically help in a crisis (stage 12).
	for row in list_claimed():
		var gid := StringName(str(row.get("id", "")))
		if gid == &"":
			continue
		# Prefer scientist for tech/clones; otherwise any claimed.
		if cat in ["tech", "clones"] and str(gid) == "scientist":
			return gid
		if cat in ["public", "girls"] and str(gid) in ["streamer", "lawyer", "neighbor"]:
			return gid
	if not list_claimed().is_empty():
		return StringName(str(list_claimed()[0].get("id", "")))
	return &""


func active_effects() -> Dictionary:
	var acc: Dictionary = {}
	for id in unlocked.keys():
		var e: Dictionary = unlocked[id]
		if not bool(e.get("met", false)) or not bool(e.get("bonus_on", true)):
			continue
		# Full passive bonuses only when claimed ("становится твоей").
		if not bool(e.get("claimed", false)):
			continue
		# Mass/city girls feed trait influence trees, not per-girl ContentDB effects.
		if str(e.get("kind", "")) == "city" or not ContentDB.girls.has(str(id)):
			continue
		var def: Dictionary = ContentDB.girl(StringName(id))
		var effects: Dictionary = def.get("effects", {})
		for k in effects.keys():
			var v: Variant = effects[k]
			if typeof(v) == TYPE_BOOL:
				acc[k] = bool(acc.get(k, false)) or bool(v)
			else:
				acc[k] = float(acc.get(k, 0.0)) + float(v)
	if Game.upgrades.has_effect("synergies"):
		_apply_synergies(acc)
	if Game.trait_influence != null:
		var be: Dictionary = Game.trait_influence.branch_passive_effects()
		for k in be.keys():
			var v: Variant = be[k]
			if typeof(v) == TYPE_BOOL:
				acc[k] = bool(acc.get(k, false)) or bool(v)
			elif str(k).ends_with("_mult") or k in ["money_mult", "event_pop_mult", "staff_cost_mult", "scandal_penalty_mult", "clone_error_mult", "gift_price_mult"]:
				var base_m: float = float(acc.get(k, 1.0))
				if not acc.has(k):
					base_m = 1.0
				acc[k] = base_m * float(v)
			else:
				acc[k] = float(acc.get(k, 0.0)) + float(v)
		acc = Game.trait_influence.clamp_effect_bag(acc)
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
	return is_met(StringName(id)) and is_claimed(StringName(id))


func _refresh_candidates() -> void:
	candidates.clear()
	for id in contacts:
		var e: Dictionary = unlocked.get(id, {})
		if e.is_empty():
			continue
		if bool(e.get("claimed", false)):
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
			"tier": str(e.get("tier", girl_tier(StringName(id)))),
			"bond": float(e.get("bond", 0.0)),
		})
	# Extra procedural mass candidates if stage >= 2 (factory filler).
	var slots: int = 2 + int(Game.upgrades.effect_value("candidate_slots"))
	if _stage_reached("stage_2"):
		for i in range(slots):
			candidates.append(_make_procedural())


func _make_procedural() -> Dictionary:
	var tier: String = "simple"
	if randf() < 0.35:
		tier = "medium"
	if randf() < 0.08:
		tier = "high"
	var pack: Dictionary = {}
	if Game.trait_influence != null and not Game.trait_influence.get_search_targets().is_empty():
		pack = Game.trait_influence.roll_search_profile([])
	else:
		pack = TraitsContent.pack_for_profile({"tier": tier})
	var traits: Array = pack.get("traits", [])
	var likes: Array = []
	for tid in traits:
		for tag in TraitsContent.TRAIT_PREP_TAGS.get(str(tid), []):
			if not likes.has(tag):
				likes.append(tag)
				break
	var soft := str(pack.get("soft_signal", ""))
	return {
		"kind": "proc",
		"id": "proc_%d" % randi(),
		"name": Game.names.next_name(),
		"archetype": "Кандидатка",
		"likes": likes,
		"dislikes": [],
		"tier": tier,
		"traits": traits,
		"primary_traits": pack.get("primary_traits", []).duplicate(),
		"quirk": str(pack.get("quirk", "")),
		"soft_signal": soft,
		"false_positive": bool(pack.get("false_positive", false)),
		"bond": 0.0,
	}


func refresh_candidates(emit_change: bool = true) -> void:
	try_unlock_by_progress()
	_refresh_candidates()
	if emit_change:
		girls_changed.emit()


func list_harem() -> Array:
	return list_claimed()


func list_claimed() -> Array:
	var out: Array = []
	for id in unlocked.keys():
		if bool(unlocked[id].get("claimed", false)):
			out.append(unlocked[id].duplicate(true))
	return out


func list_dating() -> Array:
	var out: Array = []
	for id in unlocked.keys():
		var e: Dictionary = unlocked[id]
		if not bool(e.get("met", false)):
			continue
		if bool(e.get("claimed", false)):
			continue
		out.append(e.duplicate(true))
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
		_migrate_entry(id)
	refresh_candidates()


func _migrate_entry(id: String) -> void:
	var e: Dictionary = unlocked[id]
	_ensure_trait_fields(id)
	e = unlocked[id]
	if not e.has("bond"):
		var pts := float(e.get("relation_points", 0.0))
		if bool(e.get("in_harem", false)):
			e["bond"] = 100.0
			e["claimed"] = true
		else:
			e["bond"] = minf(99.0, pts)
			e["claimed"] = false
	elif bool(e.get("in_harem", false)) and not bool(e.get("claimed", false)) and float(e.get("bond", 0)) >= 99.0:
		e["claimed"] = true
		e["bond"] = 100.0
	unlocked[id] = e
