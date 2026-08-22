class_name ProgressionLabTests
extends RefCounted

var _failures: PackedStringArray = PackedStringArray()
var _passed: int = 0


func run_all() -> PackedStringArray:
	_failures.clear()
	_passed = 0
	_test_seed_derivation()
	_test_profile_and_plan_determinism()
	_test_stage_plan_immutability()
	_test_population_weights()
	_test_fixed_goal_generation()
	_test_canonical_seed_fixtures()
	_test_full_campaign_determinism()
	_test_execution_rng_coverage()
	_test_repetition_penalty()
	_test_blocking_metrics()
	_test_badness_warnings()
	_test_integration_helper()
	_test_production_integration()
	_test_goal_isolation()
	_test_exports()
	return _failures


func summary() -> String:
	return "passed=%d failed=%d" % [_passed, _failures.size()]


func _ok(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		return
	var message: String = name
	if not detail.is_empty():
		message += " — " + detail
	_failures.append(message)


func _test_seed_derivation() -> void:
	var a: int = ProgressionRng.derive_seed(1, ProgressionRng.STREAM_PROFILE)
	var b: int = ProgressionRng.derive_seed(1, ProgressionRng.STREAM_PROFILE)
	var c: int = ProgressionRng.derive_seed(1, ProgressionRng.STREAM_DATE)
	_ok("sha256 derive stable", a == b)
	_ok("sha256 streams independent", a != c)
	var rng_a: RandomNumberGenerator = ProgressionRng.make(7, ProgressionRng.STREAM_PROFILE)
	var rng_b: RandomNumberGenerator = ProgressionRng.make(7, ProgressionRng.STREAM_PROFILE)
	_ok("rng stream repeat", is_equal_approx(rng_a.randf(), rng_b.randf()))


func _test_profile_and_plan_determinism() -> void:
	var session := PlaythroughSession.new()
	var first: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _capture_profile_and_plans(42, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	))
	var second: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _capture_profile_and_plans(42, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	))
	_ok("profile determinism", first.has("profile") and second.has("profile") and JSON.stringify(first["profile"]) == JSON.stringify(second["profile"]))
	_ok("stage plan determinism", first.has("plans") and second.has("plans") and JSON.stringify(first["plans"]) == JSON.stringify(second["plans"]))
	var probe := PlaythroughSession.new()
	probe.begin("lab_path_probe.json")
	_ok("isolated path under progression_lab", probe.isolated_save_path.begins_with("user://progression_lab/"))
	_ok("isolated path is not production save", probe.isolated_save_path != "user://saves/game.json")
	probe.end()
	var sm: Variant = _save_manager()
	_ok("save path restored after isolation", sm == null or str(sm.save_path) != "user://progression_lab/lab_path_probe.json")


func _test_stage_plan_immutability() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _capture_profile_and_plans(11, ProgressionLabConfig.ARCHETYPE_EXPLORER)
	))
	var hashes_match: bool = false
	var plans: Variant = captured.get("plans", [])
	if plans is Array and not (plans as Array).is_empty() and (plans as Array)[0] is Dictionary:
		var plan: Dictionary = (plans as Array)[0]
		hashes_match = str(plan.get("generation_hash", "")) == str(plan.get("content_hash", "")) and not str(plan.get("content_hash", "")).is_empty()
	_ok("stage plan hash frozen at generation", hashes_match)


func _test_population_weights() -> void:
	var config := ProgressionLabConfig.new()
	var counts: Dictionary = {
		"EFFICIENT": 0,
		"TYPICAL": 0,
		"EXPLORER": 0,
		"CHAOTIC": 0,
	}
	var sample_n: int = 10000
	for i in range(sample_n):
		var rng: RandomNumberGenerator = ProgressionRng.make(1 + i, ProgressionRng.STREAM_PROFILE)
		var archetype: StringName = PlayerProfile.pick_archetype(config, rng, ProgressionLabConfig.MODE_POPULATION)
		var key: String = String(archetype)
		counts[key] = int(counts.get(key, 0)) + 1
	var weights: Dictionary = config.population_weights()
	for key in counts.keys():
		var share: float = float(counts[key]) / float(sample_n)
		var expected: float = float(weights.get(key, 0.0))
		_ok("population weight %s" % key, absf(share - expected) <= 0.02, "share=%.4f expected=%.4f" % [share, expected])


func _test_fixed_goal_generation() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return {
			"typical": _capture_profile_and_plans(1, ProgressionLabConfig.ARCHETYPE_TYPICAL),
			"efficient": _capture_profile_and_plans(2, ProgressionLabConfig.ARCHETYPE_EFFICIENT),
		}
	))
	var typical: Dictionary = _as_dict(captured.get("typical", {}))
	var efficient: Dictionary = _as_dict(captured.get("efficient", {}))
	var typical_profile: Dictionary = _as_dict(typical.get("profile", {}))
	_ok("canonical seed 1 archetype", str(typical_profile.get("archetype", "")) == "TYPICAL")
	var typical_plans: Array = []
	var typical_plans_raw: Variant = typical.get("plans", [])
	if typical_plans_raw is Array:
		typical_plans = typical_plans_raw
	_ok("canonical seed 1 has stage 1 plan", typical_plans.size() >= 1)
	if typical_plans.size() >= 1 and typical_plans[0] is Dictionary:
		var plan: Dictionary = typical_plans[0]
		_ok("stage 1 outfit count 0", int(plan.get("target_outfit_count", -1)) == 0)
		_ok("stage 1 apartment count 0", int(plan.get("target_apartment_object_count", -1)) == 0)
		var fillers: Variant = plan.get("target_filler_girl_ids", [])
		_ok("stage 1 filler targets 2 or 3", fillers is Array and (fillers as Array).size() >= 2 and (fillers as Array).size() <= 3)
		_ok("stage 1 story girl set", not str(plan.get("story_girl_id", "")).is_empty())
	var efficient_profile: Dictionary = _as_dict(efficient.get("profile", {}))
	_ok("canonical seed 2 efficient", str(efficient_profile.get("archetype", "")) == "EFFICIENT")
	var again: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _capture_profile_and_plans(1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	))
	_ok("canonical seed 1 exact repeat", JSON.stringify(typical) == JSON.stringify(again))


func _test_full_campaign_determinism() -> void:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 80
	var runner_a := ProgressionLabRunner.new()
	runner_a.configure(config, 2, 3, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner_a.process_batch():
		pass
	var runner_b := ProgressionLabRunner.new()
	runner_b.configure(config, 2, 3, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner_b.process_batch():
		pass
	var result_a: ProgressionLabPopulationResult = runner_a.get_result()
	var result_b: ProgressionLabPopulationResult = runner_b.get_result()
	_ok("campaign N=2 completed", result_a.records.size() == 2 and result_b.records.size() == 2)
	if result_a.records.size() == 2 and result_b.records.size() == 2:
		var rec_a: ProgressionLabRunRecord = result_a.records[0]
		var rec_b: ProgressionLabRunRecord = result_b.records[0]
		_ok("campaign profile equal", JSON.stringify(rec_a.profile) == JSON.stringify(rec_b.profile))
		_ok("campaign interests equal", JSON.stringify(rec_a.interests) == JSON.stringify(rec_b.interests))
		_ok("campaign stage plans equal", JSON.stringify(rec_a.stage_plans) == JSON.stringify(rec_b.stage_plans))
		_ok("campaign compact actions equal", "|".join(rec_a.action_sequence) == "|".join(rec_b.action_sequence), _seq_diff(rec_a.action_sequence, rec_b.action_sequence))
		_ok("campaign summary metrics equal", _core_metrics_equal(rec_a.campaign_metrics, rec_b.campaign_metrics), _metric_diff(rec_a.campaign_metrics, rec_b.campaign_metrics))
		_ok("campaign stage metrics equal", JSON.stringify(rec_a.stage_metrics) == JSON.stringify(rec_b.stage_metrics))
		var detailed_a: ProgressionLabRunRecord = runner_a.replay_seed(3, true)
		var detailed_b: ProgressionLabRunRecord = runner_b.replay_seed(3, true)
		_ok("detailed action sequence equal", "|".join(detailed_a.action_sequence) == "|".join(detailed_b.action_sequence), _seq_diff(detailed_a.action_sequence, detailed_b.action_sequence))
		_ok("immutability hash survives campaign", _plans_keep_hash(rec_a))


func _test_integration_helper() -> void:
	_require_integration_flag("helper true", {"flag": true}, "flag", true)
	var failed_before: int = _failures.size()
	_require_integration_flag("helper false", {"flag": false}, "flag", true)
	_ok("helper false becomes FAIL", _failures.size() == failed_before + 1)
	if _failures.size() > failed_before:
		_failures.remove_at(_failures.size() - 1)
	failed_before = _failures.size()
	_require_integration_flag("helper missing", {}, "flag", false)
	_ok("helper missing content FAIL", _failures.size() == failed_before + 1)
	if _failures.size() > failed_before:
		var last: String = _failures[_failures.size() - 1]
		_ok("helper missing reason", last.find("content missing") >= 0, last)
		_failures.remove_at(_failures.size() - 1)


func _test_production_integration() -> void:
	var flags: Dictionary = {}
	var records: Array = []
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 180
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 3, 4, ProgressionLabConfig.ARCHETYPE_EXPLORER)
	while not runner.process_batch():
		pass
	_ok("production explorer campaign ran", runner.get_result().records.size() == 1)
	if not runner.get_result().records.is_empty():
		records.append(runner.get_result().records[0])
		_merge_flags(flags, runner.get_result().records[0])
	if not bool(flags.get("used_production_work", false)):
		var iso_runner := ProgressionLabRunner.new()
		var iso_result: ProgressionLabPopulationResult = iso_runner.run_goal_isolation(CharacteristicIds.APPEARANCE, 1, ProgressionLabConfig.ISOLATION_MINIMAL, 1, 5, 1)
		if not iso_result.records.is_empty():
			records.append(iso_result.records[0])
			_merge_flags(flags, iso_result.records[0])
	_ok("used production work", bool(flags.get("used_production_work", false)), JSON.stringify(flags))
	_ok("used production date", bool(flags.get("used_production_date", false)), "executor should call DatingService")
	var dress_record: ProgressionLabRunRecord = _record_with_flag(records, "stage2_dress_up")
	if dress_record == null and not records.is_empty():
		dress_record = records[0]
	var has_dress_goal: bool = _plan_has_stage2_dress(dress_record)
	_require_integration_flag("stage 2 dress-up gate", flags, "stage2_dress_up", has_dress_goal or _girl_exists(GirlCatalog.ID_MARINA))
	if dress_record != null:
		_ok("dress-up gate in stage 2 plan", has_dress_goal or int(dress_record.campaign_metrics.get("outfits_acquired", 0)) > 0)
	_require_integration_flag("marina free outfit", flags, "marina_free_outfit", _girl_exists(GirlCatalog.ID_MARINA))
	if bool(flags.get("marina_free_outfit", false)):
		var marina_record: ProgressionLabRunRecord = _record_with_flag(records, "marina_free_outfit")
		_ok("marina outfit acquisition recorded", marina_record != null and int(marina_record.campaign_metrics.get("outfits_acquired", 0)) > 0)
	_require_integration_flag("apartment purchase", flags, "apartment_purchase", _apartment_catalog_has_objects())
	if bool(flags.get("apartment_purchase", false)):
		var apt_record: ProgressionLabRunRecord = _record_with_flag(records, "apartment_purchase")
		_ok("apartment object owned after purchase", apt_record != null and int(apt_record.campaign_metrics.get("apartment_objects_acquired", 0)) > 0)
	_require_integration_flag("restaurant characteristic unlock", flags, "restaurant_characteristic_unlock", _venue_exists(&"restaurant"))
	_require_integration_flag("sonya venue x2", flags, "sonya_venue_x2", _girl_exists(GirlCatalog.ID_SONYA))
	_require_integration_flag("katya accent", flags, "katya_accent", _girl_exists(GirlCatalog.ID_KATYA))
	_require_integration_flag("rita taxi", flags, "rita_taxi", _girl_exists(GirlCatalog.ID_RITA))
	_require_integration_flag("nika backup", flags, "nika_backup", _girl_exists(GirlCatalog.ID_NIKA))
	_require_integration_flag("eva knowledge", flags, "eva_knowledge", _girl_exists(GirlCatalog.ID_EVA))


func _test_goal_isolation() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return {
			"minimal_1": _capture_isolation_plan(1, ProgressionLabConfig.ISOLATION_MINIMAL),
			"minimal_2": _capture_isolation_plan(2, ProgressionLabConfig.ISOLATION_MINIMAL),
			"full_1": _capture_isolation_plan(1, ProgressionLabConfig.ISOLATION_FULL),
			"full_2": _capture_isolation_plan(2, ProgressionLabConfig.ISOLATION_FULL),
		}
	))
	var minimal_1: Dictionary = _as_dict(captured.get("minimal_1", {}))
	var minimal_2: Dictionary = _as_dict(captured.get("minimal_2", {}))
	var full_1: Dictionary = _as_dict(captured.get("full_1", {}))
	var full_2: Dictionary = _as_dict(captured.get("full_2", {}))
	_assert_isolation_plan("MINIMAL stage 1", minimal_1, 2, 0, 0, 0, true)
	_assert_isolation_plan("MINIMAL stage 2", minimal_2, 2, 0, 1, 0, true)
	_assert_isolation_plan("FULL stage 1", full_1, 3, 2, 0, 0, true)
	_assert_isolation_plan("FULL stage 2", full_2, 3, 2, 2, 2, true)
	var runner := ProgressionLabRunner.new()
	runner.configure(ProgressionLabConfig.new(), 1, 8, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	var result: ProgressionLabPopulationResult = runner.run_goal_isolation(CharacteristicIds.APPEARANCE, 1, ProgressionLabConfig.ISOLATION_MINIMAL, 1, 8, 1)
	_ok("goal isolation returns result", result != null and result.records.size() == 1)
	if result.records.is_empty():
		return
	var record: ProgressionLabRunRecord = result.records[0]
	_ok("goal isolation typical", str(record.profile.get("archetype", "")) == "TYPICAL")
	var iso_flags: Dictionary = {}
	var iso_flags_raw: Variant = record.campaign_metrics.get("production_flags", {})
	if iso_flags_raw is Dictionary:
		iso_flags = iso_flags_raw
	_ok("isolation used production work", bool(iso_flags.get("used_production_work", false)), JSON.stringify(iso_flags))


func _test_exports() -> void:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 60
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 2, 9, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	var export_dir: String = "user://progression_lab_test_exports/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(export_dir))
	var full_path: String = runner.export_full_statistics(export_dir)
	_ok("full statistics export path", not full_path.is_empty())
	var bad_path: String = runner.export_bad_seeds_only(export_dir)
	_ok("bad seeds export path", not bad_path.is_empty())
	var seed_dir: String = "%sspecific/" % export_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(seed_dir))
	var specific_path: String = runner.export_specific_seed(9, seed_dir)
	_ok("specific seed export path", not specific_path.is_empty())
	var json_path: String = "%sseed_9.json" % seed_dir
	_ok("specific seed json exists", FileAccess.file_exists(json_path), json_path)
	if FileAccess.file_exists(json_path):
		var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
		_ok("specific json parses", parsed is Dictionary)
		if parsed is Dictionary:
			var data: Dictionary = parsed
			_ok("schema_version", int(data.get("schema_version", 0)) == 1)
			_ok("seed field", int(data.get("seed", 0)) == 9)
			_ok("config present", data.get("config", {}) is Dictionary)
			_ok("stage plans present", data.get("stage_plans", []) is Array)
			_ok("metrics present", data.get("metrics", {}) is Dictionary)
			_ok("warnings present", data.get("warnings", []) is Array)
	var md_path: String = "%sseed_9.md" % seed_dir
	_ok("specific seed markdown exists", FileAccess.file_exists(md_path))
	if FileAccess.file_exists(md_path):
		var md_file: FileAccess = FileAccess.open(md_path, FileAccess.READ)
		var md_text: String = md_file.get_as_text() if md_file != null else ""
		_ok("markdown Stage Plan", md_text.find("Stage Plan") >= 0)
		_ok("markdown Daily timeline", md_text.find("Daily timeline") >= 0)
		_ok("markdown Summary", md_text.find("Summary") >= 0)
	var share_candidates: PackedStringArray = _find_files(export_dir, "share_bundle.json")
	_ok("share_bundle json written", share_candidates.size() > 0)
	var executor := StageExecutor.new()
	executor.detailed = true
	executor._campaign = ProgressionLabMetrics.new()
	executor._current_stage_metrics = ProgressionLabMetrics.new()
	executor.apply_blocking_snapshot({
		"money": PackedStringArray(["goal_a"]),
		"daily_gate": PackedStringArray(["goal_b"]),
	})
	var block_log: String = "\n".join(executor._day_lines)
	_ok("detailed log money-blocked header", block_log.find("Money-blocked goals:") >= 0)
	_ok("detailed log money-blocked goal", block_log.find("- goal_a") >= 0)
	_ok("detailed log daily-gate header", block_log.find("Daily-gate-blocked goals:") >= 0)
	_ok("detailed log daily-gate goal", block_log.find("- goal_b") >= 0)


func _test_canonical_seed_fixtures() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return {
			"typical": _capture_profile_and_plans(1, ProgressionLabConfig.ARCHETYPE_TYPICAL),
			"efficient": _capture_profile_and_plans(2, ProgressionLabConfig.ARCHETYPE_EFFICIENT),
			"explorer": _capture_profile_and_plans(3, ProgressionLabConfig.ARCHETYPE_EXPLORER),
			"chaotic": _capture_profile_and_plans(4, ProgressionLabConfig.ARCHETYPE_CHAOTIC),
		}
	))
	_assert_seed_fixture("typical seed 1", captured.get("typical", {}), "TYPICAL", {
		"completionism": 0.477053336799145,
		"exploration": 0.548339056968689,
		"build_ambition": 0.522703230381012,
		"spending_impulsiveness": 0.486762772500515,
		"planning_skill": 0.631466922536492,
		"dating_skill": 0.632435251027346,
		"whimsy": 0.233299788832665,
	}, {
		"fillers": ["alina", "dasha"],
		"rivals": ["rival_gleb", "rival_max"],
		"chars": {"appearance": 3, "aura": 3, "muscle": 1},
		"outfits": [],
		"outfit_count": 0,
		"apt": [],
		"apt_count": 0,
		"venues": [],
		"story_girl": "girl_actress",
		"story_rival": "rival_boris",
	})
	_assert_seed_fixture("efficient seed 2", captured.get("efficient", {}), "EFFICIENT", {
		"completionism": 0.0671527615748346,
		"exploration": 0.229339477419853,
		"build_ambition": 0.548971846699715,
		"spending_impulsiveness": 0.282259020209312,
		"planning_skill": 1.0,
		"dating_skill": 0.804645703732967,
		"whimsy": 0.089643856883049,
	}, {
		"fillers": ["alina", "dasha"],
		"rivals": [],
		"chars": {"muscle": 1},
		"outfits": [],
		"outfit_count": 0,
		"apt": [],
		"apt_count": 0,
		"venues": [],
		"story_girl": "girl_actress",
		"story_rival": "rival_boris",
	})
	_assert_seed_fixture("explorer seed 3", captured.get("explorer", {}), "EXPLORER", {
		"completionism": 0.912647953629494,
		"exploration": 0.929766923934221,
		"build_ambition": 0.734400787949562,
		"spending_impulsiveness": 0.62637415677309,
		"planning_skill": 0.516020886600018,
		"dating_skill": 0.610465469956398,
		"whimsy": 0.35526502430439,
	}, {
		"fillers": ["dasha", "vika", "alina"],
		"rivals": ["rival_gleb", "rival_max"],
		"chars": {"aura": 3, "capital": 3, "muscle": 3},
		"outfits": [],
		"outfit_count": 0,
		"apt": [],
		"apt_count": 0,
		"venues": [],
		"story_girl": "girl_actress",
		"story_rival": "rival_boris",
	})
	_assert_seed_fixture("chaotic seed 4", captured.get("chaotic", {}), "CHAOTIC", {
		"completionism": 0.629015864431858,
		"exploration": 0.764255978912115,
		"build_ambition": 0.790964678302407,
		"spending_impulsiveness": 0.967686635255814,
		"planning_skill": 0.189347852300853,
		"dating_skill": 0.390007506031543,
		"whimsy": 0.678536637127399,
	}, {
		"fillers": ["dasha", "vika", "alina"],
		"rivals": ["rival_gleb", "rival_max"],
		"chars": {"aura": 1},
		"outfits": [],
		"outfit_count": 0,
		"apt": [],
		"apt_count": 0,
		"venues": [],
		"story_girl": "girl_actress",
		"story_rival": "rival_boris",
	})


func _test_execution_rng_coverage() -> void:
	var executor := StageExecutor.new()
	executor.config = ProgressionLabConfig.new()
	var first: String = _pick_with_execution_seed(executor, 1, 0.4)
	var second: String = _pick_with_execution_seed(executor, 2, 0.4)
	_ok("execution seed 1 picks date", first == "date:alina:apartment", first)
	_ok("execution seed 2 picks work", second == "work", second)
	_ok("execution seeds diverge", first != second, "%s vs %s" % [first, second])


func _test_repetition_penalty() -> void:
	var executor := StageExecutor.new()
	executor.config = ProgressionLabConfig.new()
	_ok("WORK consecutive 3 penalty 24", is_equal_approx(executor.repetition_penalty_for("WORK", "WORK", 3), 24.0))
	_ok("DATE consecutive 3 penalty 0", is_equal_approx(executor.repetition_penalty_for("DATE", "WORK", 3), 0.0))
	_ok("TRAINING consecutive 3 penalty 0", is_equal_approx(executor.repetition_penalty_for("TRAINING", "WORK", 3), 0.0))
	var work := StageExecutor.Candidate.new()
	work.category = "WORK"
	work.content_id = "work"
	work.score = 100.0
	var date := StageExecutor.Candidate.new()
	date.category = "DATE"
	date.content_id = "date:alina:apartment"
	date.score = 100.0
	executor.apply_execution_scores([work, date], "WORK", 3, null, 1.0)
	_ok("WORK score uses repetition penalty", is_equal_approx(work.score, 76.0), str(work.score))
	_ok("DATE score keeps base", is_equal_approx(date.score, 100.0), str(date.score))
	_ok("DATE beats WORK after penalty", date.score > work.score)


func _test_blocking_metrics() -> void:
	var metrics := ProgressionLabMetrics.new()
	var money_ids: Array = ["goal_m1", "goal_m2", "goal_m3"]
	var daily_ids: Array = ["goal_d1", "goal_d2"]
	metrics.record_blocking_decision_point(money_ids, daily_ids)
	_ok("one decision money count", metrics.money_blocked_decision_points == 1)
	_ok("one decision daily count", metrics.daily_gate_blocked_decision_points == 1)
	_ok("per-goal money 1", int(metrics.ensure_goal("goal_m1")["blocked_by_money_count"]) == 1)
	_ok("per-goal money 1 b", int(metrics.ensure_goal("goal_m2")["blocked_by_money_count"]) == 1)
	_ok("per-goal money 1 c", int(metrics.ensure_goal("goal_m3")["blocked_by_money_count"]) == 1)
	_ok("per-goal daily 1", int(metrics.ensure_goal("goal_d1")["blocked_by_daily_gate_count"]) == 1)
	_ok("per-goal daily 1 b", int(metrics.ensure_goal("goal_d2")["blocked_by_daily_gate_count"]) == 1)
	metrics.record_blocking_decision_point(money_ids, daily_ids)
	_ok("two decision money count", metrics.money_blocked_decision_points == 2)
	_ok("two decision daily count", metrics.daily_gate_blocked_decision_points == 2)
	_ok("per-goal money 2", int(metrics.ensure_goal("goal_m1")["blocked_by_money_count"]) == 2)
	_ok("per-goal daily 2", int(metrics.ensure_goal("goal_d1")["blocked_by_daily_gate_count"]) == 2)


func _test_badness_warnings() -> void:
	var analyzer := ProgressionLabAnalyzer.new()
	var config := ProgressionLabConfig.new()
	var record := ProgressionLabRunRecord.new()
	record.campaign_metrics = {"money_blocked_decision_points": 4}
	var warnings: PackedStringArray = analyzer.hard_warnings_for(record, config)
	_ok("money 4 no hard warning", warnings.find("MONEY_BLOCKED") < 0, ",".join(warnings))
	record.campaign_metrics["money_blocked_decision_points"] = 5
	warnings = analyzer.hard_warnings_for(record, config)
	_ok("money 5 hard warning", warnings.find("MONEY_BLOCKED") >= 0, ",".join(warnings))
	_ok("canonical money threshold 5", config.hard_money_blocked == 5)


func _require_integration_flag(label: String, flags: Dictionary, key: String, content_exists: bool) -> void:
	if not content_exists:
		_ok(label, false, "content missing")
		return
	_ok(label, bool(flags.get(key, false)), "expected production result absent")


func _plans_keep_hash(record: ProgressionLabRunRecord) -> bool:
	for plan in record.stage_plans:
		if not (plan is Dictionary):
			return false
		if str(plan.get("generation_hash", "")) != str(plan.get("content_hash", "")):
			return false
	return true


func _capture_profile_and_plans(base_seed: int, archetype_mode: StringName) -> Dictionary:
	var config := ProgressionLabConfig.new()
	var profile_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.STREAM_PROFILE)
	var profile: PlayerProfile = PlayerProfile.generate(config, profile_rng, archetype_mode)
	var interest_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.STREAM_CAMPAIGN_INTEREST)
	var interests: CampaignInterests = CampaignInterests.generate(interest_rng)
	var generator := StagePlanGenerator.new()
	generator.config = config
	generator.profile = profile
	generator.interests = interests
	var plans: Array = []
	var plan_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.stage_plan_stream(1))
	plans.append(generator.generate(1, plan_rng).to_dict())
	return {
		"profile": profile.to_dict(),
		"plans": plans,
	}


func _find_files(root: String, filename: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var abs_root: String = ProjectSettings.globalize_path(root)
	_scan_dir(abs_root, filename, found)
	return found


func _scan_dir(path: String, filename: String, found: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var child: String = "%s/%s" % [path, name]
		if dir.current_is_dir():
			_scan_dir(child, filename, found)
		elif name == filename:
			found.append(child)
		name = dir.get_next()
	dir.list_dir_end()


func _core_metrics_equal(left: Dictionary, right: Dictionary) -> bool:
	var keys: PackedStringArray = PackedStringArray([
		"calendar_days", "total_actions", "work_actions", "dates", "rival_attempts", "rival_wins",
		"money_end", "dates_by_girl", "dates_to_max_by_girl", "production_flags",
		"money_blocked_decision_points", "daily_gate_blocked_decision_points",
	])
	for key in keys:
		if JSON.stringify(left.get(key)) != JSON.stringify(right.get(key)):
			return false
	return true


func _seq_diff(left: PackedStringArray, right: PackedStringArray) -> String:
	var limit: int = mini(left.size(), right.size())
	for i in range(limit):
		if left[i] != right[i]:
			return "at %d %s vs %s (len %d/%d)" % [i, left[i], right[i], left.size(), right.size()]
	return "prefix equal len %d/%d" % [left.size(), right.size()]


func _metric_diff(left: Dictionary, right: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var keys: Dictionary = {}
	for key in left.keys():
		keys[str(key)] = true
	for key in right.keys():
		keys[str(key)] = true
	for key in keys.keys():
		var a: Variant = left.get(key)
		var b: Variant = right.get(key)
		if JSON.stringify(a) != JSON.stringify(b):
			parts.append("%s:%s!=%s" % [str(key), str(a), str(b)])
		if parts.size() >= 8:
			break
	return "; ".join(parts)


func _girl_exists(girl_id: StringName) -> bool:
	return GirlCatalog.create_seed().get_girl(girl_id) != null


func _venue_exists(venue_id: StringName) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var dating: Variant = tree.root.get_node_or_null("DatingService")
	if dating == null:
		return false
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null or catalog_service.catalog == null:
		return false
	return catalog_service.catalog.find_venue(venue_id) != null


func _apartment_catalog_has_objects() -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var apartment: Variant = tree.root.get_node_or_null("ApartmentService")
	if apartment == null:
		return false
	var catalog: Variant = apartment.get_catalog()
	if catalog == null:
		return false
	return catalog.all_objects().size() > 0


func _as_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _save_manager() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SaveManager")


func _assert_seed_fixture(label: String, captured_raw: Variant, archetype: String, traits: Dictionary, plan_expected: Dictionary) -> void:
	var captured: Dictionary = _as_dict(captured_raw)
	var profile: Dictionary = _as_dict(captured.get("profile", {}))
	_ok("%s archetype" % label, str(profile.get("archetype", "")) == archetype, str(profile.get("archetype", "")))
	for trait_name in traits.keys():
		var actual: float = float(profile.get(str(trait_name), -1.0))
		var expected: float = float(traits[trait_name])
		_ok("%s trait %s" % [label, str(trait_name)], absf(actual - expected) <= 0.000001, "actual=%s expected=%s" % [str(actual), str(expected)])
	var plans_raw: Variant = captured.get("plans", [])
	var plan: Dictionary = {}
	if plans_raw is Array and not (plans_raw as Array).is_empty() and (plans_raw as Array)[0] is Dictionary:
		plan = (plans_raw as Array)[0]
	_ok("%s fillers" % label, _string_array_equal(plan.get("target_filler_girl_ids", []), plan_expected["fillers"]), str(plan.get("target_filler_girl_ids", [])))
	_ok("%s rivals" % label, _string_array_equal(plan.get("target_ordinary_rival_ids", []), plan_expected["rivals"]), str(plan.get("target_ordinary_rival_ids", [])))
	_ok("%s characteristics" % label, _char_targets_equal(plan.get("characteristic_targets", {}), plan_expected["chars"]), str(plan.get("characteristic_targets", {})))
	_ok("%s outfits" % label, _string_array_equal(plan.get("target_outfit_ids", []), plan_expected["outfits"]))
	_ok("%s outfit count" % label, int(plan.get("target_outfit_count", -1)) == int(plan_expected["outfit_count"]))
	_ok("%s apartment ids" % label, _string_array_equal(plan.get("target_apartment_object_ids", []), plan_expected["apt"]))
	_ok("%s apartment count" % label, int(plan.get("target_apartment_object_count", -1)) == int(plan_expected["apt_count"]))
	_ok("%s venues" % label, _string_array_equal(plan.get("venue_visit_goals", []), plan_expected["venues"]), str(plan.get("venue_visit_goals", [])))
	_ok("%s story girl" % label, str(plan.get("story_girl_id", "")) == str(plan_expected["story_girl"]))
	_ok("%s story rival" % label, str(plan.get("story_rival_id", "")) == str(plan_expected["story_rival"]))


func _pick_with_execution_seed(executor: StageExecutor, base_seed: int, planning_skill: float) -> String:
	var rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.STREAM_EXECUTION_1)
	var work := StageExecutor.Candidate.new()
	work.category = "WORK"
	work.content_id = "work"
	work.score = 100.0
	var date := StageExecutor.Candidate.new()
	date.category = "DATE"
	date.content_id = "date:alina:apartment"
	date.score = 100.0
	var candidates: Array = [date, work]
	candidates.sort_custom(func(a: StageExecutor.Candidate, b: StageExecutor.Candidate) -> bool:
		return a.content_id < b.content_id
	)
	executor.apply_execution_scores(candidates, "OTHER", 0, rng, planning_skill)
	var chosen: StageExecutor.Candidate = executor.pick_scored_candidate(candidates)
	return chosen.content_id if chosen != null else ""


func _capture_isolation_plan(stage: int, isolation_mode: StringName) -> Dictionary:
	var config := ProgressionLabConfig.new()
	var profile: PlayerProfile = PlayerProfile.generate(config, ProgressionRng.make(1, ProgressionRng.STREAM_PROFILE), ProgressionLabConfig.ARCHETYPE_TYPICAL, 0.0)
	var interests: CampaignInterests = CampaignInterests.generate(ProgressionRng.make(1, ProgressionRng.STREAM_CAMPAIGN_INTEREST))
	var generator := StagePlanGenerator.new()
	generator.config = config
	generator.profile = profile
	generator.interests = interests
	generator.isolation_mode = isolation_mode
	generator.isolation_characteristic_id = CharacteristicIds.APPEARANCE
	generator.isolation_milestone = 1
	return generator.generate(stage, ProgressionRng.make(1, ProgressionRng.stage_plan_stream(stage))).to_dict()


func _assert_isolation_plan(label: String, plan: Dictionary, fillers: int, rivals: int, outfits: int, apt: int, has_appearance: bool) -> void:
	var filler_ids: Variant = plan.get("target_filler_girl_ids", [])
	var rival_ids: Variant = plan.get("target_ordinary_rival_ids", [])
	var venues: Variant = plan.get("venue_visit_goals", [])
	var chars: Variant = plan.get("characteristic_targets", {})
	_ok("%s filler count" % label, filler_ids is Array and (filler_ids as Array).size() == fillers, str(filler_ids))
	_ok("%s rival count" % label, rival_ids is Array and (rival_ids as Array).size() == rivals, str(rival_ids))
	_ok("%s outfit count" % label, int(plan.get("target_outfit_count", -1)) == outfits)
	_ok("%s apartment count" % label, int(plan.get("target_apartment_object_count", -1)) == apt)
	_ok("%s appearance target" % label, (not has_appearance) or (chars is Dictionary and chars.has("appearance")))
	_ok("%s story girl" % label, not str(plan.get("story_girl_id", "")).is_empty())
	_ok("%s story rival" % label, not str(plan.get("story_rival_id", "")).is_empty())
	_ok("%s no venue exploration" % label, venues is Array and (venues as Array).is_empty(), str(venues))


func _merge_flags(flags: Dictionary, record: ProgressionLabRunRecord) -> void:
	var raw: Variant = record.campaign_metrics.get("production_flags", {})
	if not (raw is Dictionary):
		return
	for key in raw.keys():
		if bool(raw[key]):
			flags[str(key)] = true


func _record_with_flag(records: Array, flag_name: String) -> ProgressionLabRunRecord:
	for item in records:
		if not (item is ProgressionLabRunRecord):
			continue
		var record: ProgressionLabRunRecord = item
		var raw: Variant = record.campaign_metrics.get("production_flags", {})
		if raw is Dictionary and bool(raw.get(flag_name, false)):
			return record
	return null


func _plan_has_stage2_dress(record: ProgressionLabRunRecord) -> bool:
	if record == null:
		return false
	for plan_raw in record.stage_plans:
		if not (plan_raw is Dictionary):
			continue
		var plan: Dictionary = plan_raw
		if int(plan.get("stage", 0)) == 2 and int(plan.get("target_outfit_count", 0)) >= 1:
			return true
	return false


func _char_targets_equal(actual_raw: Variant, expected_raw: Variant) -> bool:
	var actual: Dictionary = actual_raw if actual_raw is Dictionary else {}
	var expected: Dictionary = expected_raw if expected_raw is Dictionary else {}
	if actual.size() != expected.size():
		return false
	for key in expected.keys():
		if int(actual.get(str(key), -999)) != int(expected[key]):
			return false
	for key in actual.keys():
		if not expected.has(str(key)):
			return false
	return true


func _string_array_equal(actual_raw: Variant, expected_raw: Variant) -> bool:
	var actual: Array = actual_raw if actual_raw is Array else []
	var expected: Array = expected_raw if expected_raw is Array else []
	if actual.size() != expected.size():
		return false
	for i in range(actual.size()):
		if str(actual[i]) != str(expected[i]):
			return false
	return true
