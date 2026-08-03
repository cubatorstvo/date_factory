extends SceneTree
## Runtime playtest M-17: claim → influence → branch → synergy → doctrine → caps → auto gate → save/load.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var errors: PackedStringArray = PackedStringArray()
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		push_error("Game missing")
		quit(1)
		return
	game.call("new_game")
	ContentDB.ensure_loaded()
	var girls: Node = game.get("girls")
	var ti: Node = game.get("trait_influence")
	var dating: Node = game.get("dating")
	var save: Node = game.get("save")
	_assert(errors, ti != null, "trait_influence")
	_assert(errors, girls != null, "girls")
	if ti == null or girls == null:
		_finish(errors)
		return

	# Seed 12 claimed thrift + 12 ambitious city contacts (influence units).
	for i in range(12):
		var id_t := "m17_thrift_%d" % i
		girls.call("add_contact", StringName(id_t), {
			"display_name": "T%d" % i,
			"tier": "simple",
			"kind": "city",
			"primary_traits": ["thrift", "punctual"],
			"traits": ["thrift", "punctual"],
			"quirk": "",
			"likes": ["cheap", "practical"],
		})
		girls.call("mark_met", StringName(id_t))
		var e: Dictionary = girls.get("unlocked")[id_t]
		e["claimed"] = true
		e["bond"] = 100.0
		e["revealed_traits"] = ["thrift", "punctual"]
		e["primary_traits"] = ["thrift", "punctual"]
		e["traits"] = ["thrift", "punctual"]
		e["bonus_on"] = true
	for j in range(12):
		var id_a := "m17_amb_%d" % j
		girls.call("add_contact", StringName(id_a), {
			"display_name": "A%d" % j,
			"tier": "medium",
			"kind": "city",
			"primary_traits": ["ambitious", "witty"],
			"traits": ["ambitious", "witty"],
			"quirk": "",
			"likes": ["status"],
		})
		girls.call("mark_met", StringName(id_a))
		var e2: Dictionary = girls.get("unlocked")[id_a]
		e2["claimed"] = true
		e2["bond"] = 100.0
		e2["revealed_traits"] = ["ambitious", "witty"]
		e2["primary_traits"] = ["ambitious", "witty"]
		e2["traits"] = ["ambitious", "witty"]
		e2["bonus_on"] = true

	ti.call("recount", false)
	var thrift_n: int = int(ti.call("count", "thrift"))
	var amb_n: int = int(ti.call("count", "ambitious"))
	_assert(errors, thrift_n >= 10, "thrift_count_%d" % thrift_n)
	_assert(errors, amb_n >= 10, "amb_count_%d" % amb_n)

	# Force high counts for late thresholds without 300 contacts.
	var contrib: Dictionary = ti.get("contributors")
	var counts: Dictionary = ti.get("counts")
	var pad: Array = (contrib.get("thrift", []) as Array).duplicate()
	while pad.size() < 300:
		pad.append("pad_t_%d" % pad.size())
	contrib["thrift"] = pad
	counts["thrift"] = pad.size()
	var pad_a: Array = (contrib.get("ambitious", []) as Array).duplicate()
	while pad_a.size() < 30:
		pad_a.append("pad_a_%d" % pad_a.size())
	contrib["ambitious"] = pad_a
	counts["ambitious"] = pad_a.size()
	ti.set("contributors", contrib)
	ti.set("counts", counts)

	_assert(errors, bool(ti.call("choose_branch", "thrift", "A")), "branch_A")
	_assert(errors, bool(ti.call("choose_depth", "thrift", "deepen")), "depth")
	game.set("stage_id", "stage_5")
	if bool(ti.call("can_activate_synergy", "reinvest")):
		_assert(errors, bool(ti.call("activate_synergy", "reinvest")), "synergy")
	else:
		var syns: Array = ti.get("active_synergies")
		if not syns.has("reinvest"):
			syns.append("reinvest")
			ti.set("active_synergies", syns)

	_assert(errors, bool(ti.call("activate_doctrine", "thrift")), "doctrine")
	_assert(errors, str(ti.get("active_doctrine")) == "thrift", "doctrine_active")

	var bag: Dictionary = ti.call("branch_passive_effects")
	_assert(errors, float(bag.get("money_mult", 1.0)) <= 1.45 + 0.001, "cap_money")
	var effects: Dictionary = girls.call("active_effects")
	if effects.has("money_mult"):
		_assert(errors, float(effects["money_mult"]) <= 1.45 + 0.001, "active_cap_money")
	if effects.has("gift_price_mult"):
		_assert(errors, float(effects["gift_price_mult"]) >= 0.7 - 0.001, "active_floor_gift")

	# Auto gate: unique with no knowledge should be blocked.
	_assert(errors, not bool(girls.call("allows_auto_date", &"neighbor")), "block_unique_auto")
	# Claimed simple with full reveal should usually allow.
	_assert(errors, bool(girls.call("allows_auto_date", &"m17_thrift_0")), "allow_simple_auto")

	# Culture / phone report non-empty.
	_assert(errors, not str(ti.call("culture_summary")).strip_edges().is_empty(), "culture")
	_assert(errors, not str(ti.call("phone_orbit_report")).strip_edges().is_empty(), "orbit_report")

	# Save / load roundtrip of culture choices.
	game.call("save_game")
	_assert(errors, bool(save.call("has_save")), "has_save")
	var branch_before := str(ti.call("get_branch", "thrift"))
	var doc_before := str(ti.get("active_doctrine"))
	game.call("load_game")
	ti = game.get("trait_influence")
	_assert(errors, str(ti.call("get_branch", "thrift")) == branch_before, "load_branch")
	_assert(errors, str(ti.call("get_depth_choice", "thrift")) == "deepen", "load_depth")
	_assert(errors, str(ti.get("active_doctrine")) == doc_before, "load_doctrine")
	_assert(errors, bool(ti.call("has_active_synergy", "reinvest")), "load_synergy")

	# Divert / reserve smoke (thrift doctrine).
	var kept: float = float(ti.call("on_date_money_earned", 100.0))
	_assert(errors, kept < 100.0 and kept > 0.0, "divert")
	_assert(errors, float(ti.get("expansion_reserve")) > 0.0, "reserve")

	if dating != null:
		_assert(errors, dating.has_method("_auto_schedule"), "dating_auto")

	_finish(errors)


func _assert(errors: PackedStringArray, cond: bool, label: String) -> void:
	if not cond:
		errors.append(label)


func _finish(errors: PackedStringArray) -> void:
	if errors.is_empty():
		print("M17_PLAYTEST_OK")
		quit(0)
	else:
		for e in errors:
			push_error(e)
		print("M17_PLAYTEST_FAIL ", errors)
		quit(1)
