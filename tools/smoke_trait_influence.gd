extends SceneTree
## Headless smoke: influence → branch → depth → synergy → doctrine → save keys + §26 caps.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var errors: PackedStringArray = PackedStringArray()
	var TI: Variant = load("res://modules/girls/trait_influence_api.gd")
	_assert(errors, TI != null, "load_TI")
	if TI == null:
		_finish(errors)
		return
	var ti: Object = TI.new()
	ti.reset()
	var thrift_ids: Array = []
	for i in range(300):
		thrift_ids.append("c_%d" % i)
	ti.contributors["thrift"] = thrift_ids
	ti.counts["thrift"] = 300
	var amb: Array = []
	for i in range(30):
		amb.append("a_%d" % i)
	ti.contributors["ambitious"] = amb
	ti.counts["ambitious"] = 30
	_assert(errors, ti.choose_branch("thrift", "A"), "choose_branch")
	_assert(errors, str(ti.get_branch("thrift")) == "A", "branch_A")
	_assert(errors, ti.choose_depth("thrift", "deepen"), "depth")
	if not ti.active_synergies.has("reinvest"):
		ti.active_synergies.append("reinvest")
	_assert(errors, ti.activate_doctrine("thrift"), "activate_doc")
	_assert(errors, str(ti.active_doctrine) == "thrift", "doc_active")
	var bag: Dictionary = ti.branch_passive_effects()
	_assert(errors, float(bag.get("money_mult", 1.0)) <= 1.45 + 0.001, "cap_money")
	var clamped: Dictionary = ti.clamp_effect_bag({
		"money_mult": 2.5,
		"gift_price_mult": 0.4,
		"scandal_penalty_mult": 0.1,
		"auto_conf_bonus": 0.9,
	})
	_assert(errors, absf(float(clamped["money_mult"]) - 1.45) < 0.001, "clamp_hi")
	_assert(errors, absf(float(clamped["gift_price_mult"]) - 0.7) < 0.001, "clamp_lo")
	_assert(errors, float(clamped["scandal_penalty_mult"]) >= 0.55 - 0.001, "clamp_scandal")
	_assert(errors, float(clamped["auto_conf_bonus"]) <= 0.25 + 0.001, "clamp_conf")
	var d: Dictionary = ti.to_dict()
	var ti2: Object = TI.new()
	ti2.from_dict(d)
	_assert(errors, str(ti2.get_branch("thrift")) == "A", "save_branch")
	_assert(errors, str(ti2.get_depth_choice("thrift")) == "deepen", "save_depth")
	_assert(errors, ti2.has_active_synergy("reinvest"), "save_syn")
	_assert(errors, str(ti2.active_doctrine) == "thrift", "save_doc")
	_assert(errors, not str(ti.culture_summary()).strip_edges().is_empty(), "culture")
	var game: Node = root.get_node_or_null("Game")
	if game != null:
		var girls: Variant = game.get("girls")
		if girls != null:
			_assert(errors, girls.has_method("allows_auto_date"), "allows_auto_date")
	_finish(errors)


func _assert(errors: PackedStringArray, cond: bool, label: String) -> void:
	if not cond:
		errors.append(label)


func _finish(errors: PackedStringArray) -> void:
	if errors.is_empty():
		print("TRAIT_INFLUENCE_SMOKE_OK")
		quit(0)
	else:
		for e in errors:
			push_error(e)
		print("TRAIT_INFLUENCE_SMOKE_FAIL ", errors)
		quit(1)
