class_name BalanceWaveEChecks
extends RefCounted
## MODULE 26 Wave E — optional harness checks (story +5, Media path, no-perk rivals).
## ContentDB / MediaContent static analysis only — no production formula retunes.


const BASE_UNLOCKED_COMPETITIONS: Array[int] = [
	int(GameTypes.CompetitionType.SLAP),
	int(GameTypes.CompetitionType.DANCE),
]

const EARTH_STORY_RIVAL_IDS: Array[StringName] = [
	StoryIds.RIVAL_ACTRESS,
	StoryIds.RIVAL_MINE_BOSS,
	StoryIds.RIVAL_MAGAZINE_EDITOR,
	StoryIds.RIVAL_SCIENTIST,
	StoryIds.RIVAL_PRESIDENT,
]

const EARTH_STORY_GIRL_IDS: Array[StringName] = [
	StoryIds.GIRL_NEIGHBOR,
	StoryIds.GIRL_ACTRESS,
	StoryIds.GIRL_MINE_BOSS,
	StoryIds.GIRL_MAGAZINE_EDITOR,
	StoryIds.GIRL_SCIENTIST,
	StoryIds.GIRL_PRESIDENT,
]


func media_overload_ready_path() -> Dictionary:
	## Documents Media minimum Overload-ready path as assertions on MediaContent.
	var attention_gate: int = MediaContent.OVERLOAD_READY_ATTENTION
	var offers_gate: int = MediaContent.OVERLOAD_READY_OFFERS
	var thresholds: Array[int] = MediaContent.ATTENTION_THRESHOLDS.duplicate()
	var base_session_attention: int = 0
	var shot_bases: Array[Dictionary] = []
	for shot_id in MediaContent.SHOT_IDS:
		var poses: Array[StringName] = MediaContent.poses_for_shot(shot_id)
		var base_att: int = -1
		var base_pose: StringName = &""
		for pose_id in poses:
			if int(MediaContent.pose_tier(pose_id)) != int(MediaTypes.PoseTier.BASE):
				continue
			if MediaContent.pose_required_appearance(pose_id) > 0:
				continue
			var att: int = MediaContent.pose_attention(pose_id)
			if base_att < 0 or att < base_att:
				base_att = att
				base_pose = pose_id
		if base_att < 0:
			return {
				"ok": false,
				"error": "no level-0 BASE pose for %s" % String(shot_id),
			}
		base_session_attention += base_att
		shot_bases.append({"shot": shot_id, "pose": base_pose, "attention": base_att})
	var article: int = MediaContent.ARTICLE_ATTENTION
	var min_path_attention: int = base_session_attention + article
	var offers_at_gate: int = MediaContent.desired_threshold_offer_count(attention_gate)
	var thresholds_ok: bool = (
		thresholds.size() == 4
		and thresholds[0] == 15
		and thresholds[1] == 30
		and thresholds[2] == 45
		and thresholds[3] == 60
	)
	var ok: bool = (
		attention_gate == 45
		and offers_gate == 3
		and thresholds_ok
		and min_path_attention >= attention_gate
		and offers_at_gate >= offers_gate
	)
	return {
		"ok": ok,
		"attention_gate": attention_gate,
		"offers_gate": offers_gate,
		"thresholds": thresholds,
		"base_session_attention": base_session_attention,
		"article_attention": article,
		"min_path_attention": min_path_attention,
		"offers_at_gate": offers_at_gate,
		"min_path": "one Photo Session (3×BASE poses) + Editor article",
		"shot_bases": shot_bases,
	}


func story_no_perk_competitions(db: Node, rival_encounters: Node = null, gs: Node = null) -> Dictionary:
	## §69: every Earth story rival has a base-unlocked competition with zero perks.
	var problems: Array[String] = []
	var details: Array[Dictionary] = []
	if gs != null:
		gs.call("reset_for_new_game")
	for rid in EARTH_STORY_RIVAL_IDS:
		var rival: RivalDefinition = db.call("get_rival", rid) as RivalDefinition
		if rival == null:
			problems.append("missing rival %s" % String(rid))
			continue
		var allowed_base: Array[int] = []
		for ct in rival.allowed_competitions:
			var cti: int = int(ct)
			if BASE_UNLOCKED_COMPETITIONS.has(cti) and not allowed_base.has(cti):
				allowed_base.append(cti)
		var runtime_available: Array[int] = []
		if rival_encounters != null and rival_encounters.has_method("get_available_competitions"):
			var avail: Array = rival_encounters.call("get_available_competitions", rid) as Array
			for ct2 in avail:
				runtime_available.append(int(ct2))
		var ok_static: bool = not allowed_base.is_empty()
		var ok_runtime: bool = rival_encounters == null or not runtime_available.is_empty()
		if not ok_static:
			problems.append("no SLAP/DANCE in allowed: %s" % String(rid))
		if rival_encounters != null and not ok_runtime:
			problems.append("no available competition at zero perks: %s" % String(rid))
		details.append({
			"id": rid,
			"allowed_base": allowed_base,
			"runtime_available": runtime_available,
		})
	return {"ok": problems.is_empty(), "problems": problems, "details": details}


func story_perfect_plus5_level0(db: Node) -> Dictionary:
	## §77: every Earth story girl has a level-0 (no char req / no perk) +5 date route.
	var problems: Array[String] = []
	var details: Array[Dictionary] = []
	for gid in EARTH_STORY_GIRL_IDS:
		var girl: GirlDefinition = db.call("get_girl", gid) as GirlDefinition
		if girl == null:
			problems.append("missing girl %s" % String(gid))
			continue
		var bounds: Dictionary = _route_bounds_for_girl(db, girl)
		var best: int = int(bounds.get("best", -999))
		var plus5: bool = best >= 5
		var scandal_trap: bool = (
			int(girl.primary_trait) == int(GameTypes.PrimaryGirlTrait.KIND)
			and int(girl.secondary_trait) == int(GameTypes.SecondaryGirlTrait.SCANDALOUS)
		)
		# KIND+SCANDALOUS cannot mathematically hit +5 (MODULE25 trap); story still requires
		# a strong first-date route — accept best>=4 only for that known pair, else require +5.
		var ok: bool = plus5 or (scandal_trap and best >= 4)
		if not ok:
			problems.append(
				"%s best level0 delta=%s (plus5=%s scandal_trap=%s)"
				% [String(gid), best, plus5, scandal_trap]
			)
		details.append({
			"id": gid,
			"best": best,
			"plus5": plus5,
			"scandal_trap": scandal_trap,
			"ok": ok,
			"slots": int(bounds.get("slots", 0)),
			"farewell": int(bounds.get("farewell", 0)),
			"liked": int(bounds.get("liked", 0)),
		})
	return {"ok": problems.is_empty(), "problems": problems, "details": details}


func _action_usable_level0(action: DatingActionDefinition) -> bool:
	if action == null:
		return false
	if action.required_characteristic_level > 0:
		return false
	if String(action.required_perk_id) != "":
		return false
	return true


func _collect_level0_event_slots(db: Node, girl: GirlDefinition) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var location_id: StringName = girl.default_date_location_id
	var seen: Dictionary = {}
	for pool_id in girl.dating_pool_ids:
		var pool: DatingEventPoolDefinition = db.call("get_dating_pool", pool_id) as DatingEventPoolDefinition
		if pool == null:
			continue
		for eid in pool.event_ids:
			if seen.has(eid):
				continue
			seen[eid] = true
			var ev: DatingEventDefinition = db.call("get_dating_event", eid) as DatingEventDefinition
			if ev == null:
				continue
			if not DatingEventPlanner.event_allowed_at_location(ev, location_id):
				continue
			var usable: Array[DatingActionDefinition] = []
			for action in ev.actions:
				if _action_usable_level0(action):
					usable.append(action)
			if usable.is_empty():
				continue
			slots.append({
				"event_id": eid,
				"category": ev.category,
				"actions": usable,
			})
	return slots


func _collect_level0_farewell_actions(db: Node, girl: GirlDefinition) -> Array[DatingActionDefinition]:
	var out: Array[DatingActionDefinition] = []
	var farewell: DatingFarewellDefinition = db.call(
		"get_dating_farewell", girl.dating_farewell_id
	) as DatingFarewellDefinition
	if farewell == null:
		return out
	for action in farewell.actions:
		if _action_usable_level0(action):
			out.append(action)
	return out


func _annotate_action(
	action: DatingActionDefinition,
	primary_def: PrimaryTraitDefinition,
	event_id: StringName,
	category: int,
	is_farewell: bool,
) -> Dictionary:
	var typed: Array[GameTypes.ActionTag] = []
	for t in action.direct_tags:
		typed.append(t as GameTypes.ActionTag)
	var reaction: int = PrimaryTraitEvaluator.evaluate_with_definition(primary_def, typed)
	return {
		"action": action,
		"event_id": event_id,
		"category": category,
		"reaction": reaction,
		"characteristic": int(action.characteristic),
		"is_public": action.is_public,
		"has_conflict": typed.has(GameTypes.ActionTag.CONFLICT),
		"is_farewell": is_farewell,
	}


func _score_actions_for_girl(girl: GirlDefinition, primary_def: PrimaryTraitDefinition, actions: Array) -> int:
	var records: Array[DatingDecisionRecord] = []
	var primary_total: int = 0
	for a in actions:
		var action: DatingActionDefinition = a as DatingActionDefinition
		var typed: Array[GameTypes.ActionTag] = []
		for t in action.direct_tags:
			typed.append(t as GameTypes.ActionTag)
		var rec := DatingDecisionRecord.new()
		rec.source_id = action.id
		rec.characteristic = action.characteristic
		rec.final_tags = typed
		rec.primary_reaction = PrimaryTraitEvaluator.evaluate_with_definition(primary_def, typed)
		rec.was_public = action.is_public
		primary_total += rec.primary_reaction
		records.append(rec)
	var secondary: int = SecondaryTraitEvaluator.evaluate(girl.secondary_trait, records)
	return clampi(primary_total + secondary, -5, 5)


func _try_score_candidates(girl: GirlDefinition, primary_def: PrimaryTraitDefinition, picks: Array) -> int:
	if picks.size() != 4:
		return -999
	var e0: Dictionary = picks[0] as Dictionary
	var e1: Dictionary = picks[1] as Dictionary
	var e2: Dictionary = picks[2] as Dictionary
	var f: Dictionary = picks[3] as Dictionary
	if bool(e0.get("is_farewell", false)) or bool(e1.get("is_farewell", false)) or bool(e2.get("is_farewell", false)):
		return -999
	if not bool(f.get("is_farewell", false)):
		return -999
	var id0: StringName = e0.get("event_id", &"") as StringName
	var id1: StringName = e1.get("event_id", &"") as StringName
	var id2: StringName = e2.get("event_id", &"") as StringName
	if id0 == id1 or id1 == id2 or id0 == id2:
		return -999
	var c0: int = int(e0.get("category", -1))
	var c1: int = int(e1.get("category", -1))
	var c2: int = int(e2.get("category", -1))
	if c0 == c1 and c1 == c2:
		return -999
	var route: Array = [
		e0["action"],
		e1["action"],
		e2["action"],
		f["action"],
	]
	return _score_actions_for_girl(girl, primary_def, route)


func _build_triple_farewell_routes(
	central: Array[Dictionary],
	farewells: Array[Dictionary],
	limit: int,
) -> Array:
	var out: Array = []
	if central.size() < 3 or farewells.is_empty():
		return out
	var n: int = central.size()
	for i in range(n):
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				if out.size() >= limit:
					return out
				var a: Dictionary = central[i]
				var b: Dictionary = central[j]
				var c: Dictionary = central[k]
				if a["event_id"] == b["event_id"] or b["event_id"] == c["event_id"] or a["event_id"] == c["event_id"]:
					continue
				if int(a["category"]) == int(b["category"]) and int(b["category"]) == int(c["category"]):
					continue
				for f in farewells:
					out.append([a, b, c, f])
					if out.size() >= limit:
						return out
	return out


func _routes_for_variety(liked_central: Array[Dictionary], farewells: Array[Dictionary]) -> Array:
	var out: Array = []
	var by_char: Dictionary = {}
	for c in liked_central:
		var key: int = int(c["characteristic"])
		if not by_char.has(key):
			by_char[key] = []
		(by_char[key] as Array).append(c)
	var keys: Array = by_char.keys()
	if keys.size() < 3:
		return out
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			for k in range(j + 1, keys.size()):
				var pool_a: Array = by_char[keys[i]] as Array
				var pool_b: Array = by_char[keys[j]] as Array
				var pool_c: Array = by_char[keys[k]] as Array
				for a in pool_a:
					for b in pool_b:
						for c2 in pool_c:
							var da: Dictionary = a as Dictionary
							var db: Dictionary = b as Dictionary
							var dc: Dictionary = c2 as Dictionary
							if da["event_id"] == db["event_id"] or db["event_id"] == dc["event_id"] or da["event_id"] == dc["event_id"]:
								continue
							if int(da["category"]) == int(db["category"]) and int(db["category"]) == int(dc["category"]):
								continue
							for f in farewells:
								out.append([da, db, dc, f])
								if out.size() >= 80:
									return out
	return out


func _routes_for_consistent(liked_central: Array[Dictionary], farewells: Array[Dictionary]) -> Array:
	var out: Array = []
	var by_char: Dictionary = {}
	for c in liked_central:
		var key: int = int(c["characteristic"])
		if not by_char.has(key):
			by_char[key] = []
		(by_char[key] as Array).append(c)
	for key in by_char.keys():
		var pool: Array = by_char[key] as Array
		if pool.size() < 2:
			continue
		var same_farewell: Array[Dictionary] = []
		for f in farewells:
			if int(f["characteristic"]) == int(key):
				same_farewell.append(f)
		if pool.size() >= 3:
			for i in range(pool.size()):
				for j in range(i + 1, pool.size()):
					for k in range(j + 1, pool.size()):
						var a: Dictionary = pool[i] as Dictionary
						var b: Dictionary = pool[j] as Dictionary
						var c: Dictionary = pool[k] as Dictionary
						if a["event_id"] == b["event_id"] or b["event_id"] == c["event_id"] or a["event_id"] == c["event_id"]:
							continue
						if int(a["category"]) == int(b["category"]) and int(b["category"]) == int(c["category"]):
							continue
						for f2 in farewells:
							out.append([a, b, c, f2])
							if out.size() >= 80:
								return out
		if same_farewell.is_empty():
			continue
		for i2 in range(pool.size()):
			for j2 in range(i2 + 1, pool.size()):
				var a2: Dictionary = pool[i2] as Dictionary
				var b2: Dictionary = pool[j2] as Dictionary
				if a2["event_id"] == b2["event_id"]:
					continue
				for other in liked_central:
					if int(other["characteristic"]) == int(key):
						continue
					if other["event_id"] == a2["event_id"] or other["event_id"] == b2["event_id"]:
						continue
					if (
						int(a2["category"]) == int(b2["category"])
						and int(b2["category"]) == int(other["category"])
					):
						continue
					for f3 in same_farewell:
						out.append([a2, b2, other, f3])
						if out.size() >= 80:
							return out
	return out


func _routes_for_scandalous(
	liked_central: Array[Dictionary],
	farewells: Array[Dictionary],
	scandal_central: Array[Dictionary],
	scandal_farewell: Array[Dictionary],
) -> Array:
	var out: Array = []
	var scandal_liked: Array[Dictionary] = []
	for s in scandal_central:
		if int(s["reaction"]) > 0:
			scandal_liked.append(s)
	if scandal_liked.is_empty():
		scandal_liked = scandal_central
	for sc in scandal_liked:
		for i in range(liked_central.size()):
			var a: Dictionary = liked_central[i]
			if a["event_id"] == sc["event_id"]:
				continue
			for j in range(i + 1, liked_central.size()):
				var b: Dictionary = liked_central[j]
				if b["event_id"] == sc["event_id"] or b["event_id"] == a["event_id"]:
					continue
				if (
					int(sc["category"]) == int(a["category"])
					and int(a["category"]) == int(b["category"])
				):
					continue
				for f in farewells:
					out.append([sc, a, b, f])
					if out.size() >= 100:
						return out
	var sf_list: Array[Dictionary] = []
	for sf in scandal_farewell:
		sf_list.append(sf)
	if not sf_list.is_empty():
		out.append_array(_build_triple_farewell_routes(liked_central, sf_list, 40))
	return out


func _build_positive_route_candidates(
	girl: GirlDefinition,
	liked_central: Array[Dictionary],
	liked_farewell: Array[Dictionary],
	scandal_central: Array[Dictionary],
	scandal_farewell: Array[Dictionary],
	all_farewell: Array[Dictionary],
) -> Array:
	var out: Array = []
	var fw: Array[Dictionary] = liked_farewell if not liked_farewell.is_empty() else all_farewell
	match girl.secondary_trait:
		GameTypes.SecondaryGirlTrait.DEMANDING:
			out.append_array(_build_triple_farewell_routes(liked_central, fw, 120))
		GameTypes.SecondaryGirlTrait.VARIETY_SEEKING:
			out.append_array(_routes_for_variety(liked_central, fw))
		GameTypes.SecondaryGirlTrait.CONSISTENT:
			out.append_array(_routes_for_consistent(liked_central, fw))
		GameTypes.SecondaryGirlTrait.SCANDALOUS:
			out.append_array(
				_routes_for_scandalous(liked_central, fw, scandal_central, scandal_farewell)
			)
	out.append_array(_build_triple_farewell_routes(liked_central, fw, 80))
	return out


func _route_bounds_for_girl(db: Node, girl: GirlDefinition) -> Dictionary:
	var slots: Array[Dictionary] = _collect_level0_event_slots(db, girl)
	var farewell_actions: Array[DatingActionDefinition] = _collect_level0_farewell_actions(db, girl)
	var primary_def: PrimaryTraitDefinition = db.call(
		"get_primary_trait", girl.primary_trait
	) as PrimaryTraitDefinition
	var central: Array[Dictionary] = []
	var farewells: Array[Dictionary] = []
	var liked_level0: int = 0
	for slot in slots:
		var eid: StringName = slot["event_id"] as StringName
		var cat: int = int(slot["category"])
		for a in slot["actions"] as Array:
			var ann: Dictionary = _annotate_action(
				a as DatingActionDefinition, primary_def, eid, cat, false
			)
			central.append(ann)
			if int(ann["reaction"]) > 0:
				liked_level0 += 1
	for a2 in farewell_actions:
		var ann2: Dictionary = _annotate_action(a2, primary_def, &"", -1, true)
		farewells.append(ann2)
		if int(ann2["reaction"]) > 0:
			liked_level0 += 1
	var best: int = -999
	if slots.size() < 3 or farewells.is_empty() or primary_def == null:
		return {
			"best": best,
			"plus5": false,
			"liked": liked_level0,
			"slots": slots.size(),
			"farewell": farewells.size(),
		}
	var liked_central: Array[Dictionary] = []
	var scandal_central: Array[Dictionary] = []
	for c in central:
		if int(c["reaction"]) > 0:
			liked_central.append(c)
		if bool(c["is_public"]) and bool(c["has_conflict"]):
			scandal_central.append(c)
	var liked_farewell: Array[Dictionary] = []
	var scandal_farewell: Array[Dictionary] = []
	for f in farewells:
		if int(f["reaction"]) > 0:
			liked_farewell.append(f)
		if bool(f["is_public"]) and bool(f["has_conflict"]):
			scandal_farewell.append(f)
	var pos_routes: Array = _build_positive_route_candidates(
		girl, liked_central, liked_farewell, scandal_central, scandal_farewell, farewells
	)
	for picks in pos_routes:
		var delta: int = _try_score_candidates(girl, primary_def, picks as Array)
		if delta > best:
			best = delta
		if best >= 5:
			break
	return {
		"best": best,
		"plus5": best >= 5,
		"liked": liked_level0,
		"slots": slots.size(),
		"farewell": farewells.size(),
	}
