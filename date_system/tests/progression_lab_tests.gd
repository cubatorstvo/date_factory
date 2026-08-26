class_name ProgressionLabTests
extends RefCounted

var _failures: PackedStringArray = PackedStringArray()
var _passed: int = 0
var _current_group: String = ""
var _current_test: String = ""
var _tests_done: int = 0
var _tests_total: int = 0


func run_all() -> PackedStringArray:
	_failures.clear()
	_passed = 0
	_tests_done = 0
	var catalog: Array = test_catalog()
	_tests_total = catalog.size()
	for item in catalog:
		_current_group = str(item.get("group", ""))
		_current_test = str(item.get("name", ""))
		var callback: Callable = item["fn"]
		callback.call()
		_tests_done += 1
	return _failures

func test_catalog() -> Array:
	return [
		{"group": "core", "name": "seed derivation", "fn": _test_seed_derivation},
		{"group": "core", "name": "profile and plan determinism", "fn": _test_profile_and_plan_determinism},
		{"group": "core", "name": "stage plan immutability", "fn": _test_stage_plan_immutability},
		{"group": "core", "name": "population weights", "fn": _test_population_weights},
		{"group": "core", "name": "fixed goal generation", "fn": _test_fixed_goal_generation},
		{"group": "core", "name": "canonical seed fixtures", "fn": _test_canonical_seed_fixtures},
		{"group": "core", "name": "full campaign determinism", "fn": _test_full_campaign_determinism},
		{"group": "core", "name": "execution rng coverage", "fn": _test_execution_rng_coverage},
		{"group": "scoring", "name": "repetition penalty", "fn": _test_repetition_penalty},
		{"group": "scoring", "name": "build urgency priority", "fn": _test_build_urgency_priority},
		{"group": "metrics", "name": "blocking metrics", "fn": _test_blocking_metrics},
		{"group": "metrics", "name": "badness warnings", "fn": _test_badness_warnings},
		{"group": "metrics", "name": "stage calendar duration", "fn": _test_stage_calendar_duration},
		{"group": "metrics", "name": "stage dead progress", "fn": _test_stage_dead_progress},
		{"group": "metrics", "name": "metric consistency", "fn": _test_metric_consistency},
		{"group": "metrics", "name": "work attribution helper", "fn": _test_work_attribution_helper},
		{"group": "metrics", "name": "goal friction by type", "fn": _test_goal_friction_by_type},
		{"group": "integration", "name": "integration helper", "fn": _test_integration_helper},
		{"group": "integration", "name": "production integration", "fn": _test_production_integration},
		{"group": "integration", "name": "goal isolation", "fn": _test_goal_isolation},
		{"group": "exports", "name": "exports", "fn": _test_exports},
		{"group": "exports", "name": "share bundle pacing fields", "fn": _test_share_bundle_pacing_fields},
		{"group": "exports", "name": "item metrics csv apartment", "fn": _test_item_metrics_csv_apartment},
		{"group": "dates", "name": "date loadout before eligibility", "fn": _test_date_loadout_before_eligibility},
		{"group": "dates", "name": "date missing dressed outfit", "fn": _test_date_missing_dressed_outfit},
		{"group": "dates", "name": "story barrier and stall", "fn": _test_story_barrier_and_stall},
		{"group": "dates", "name": "predictive story barrier", "fn": _test_predictive_story_barrier},
		{"group": "dates", "name": "apartment source mapping", "fn": _test_apartment_source_mapping},
		{"group": "economy", "name": "stage money consistency", "fn": _test_stage_money_consistency},
		{"group": "regression", "name": "failed seed regression set", "fn": _test_failed_seed_regression_set},
		{"group": "regression", "name": "replay signature and isolation", "fn": _test_replay_signature_and_isolation},
		{"group": "regression", "name": "replay regression seeds", "fn": _test_replay_regression_seeds},
		{"group": "regression", "name": "story girl date cash support", "fn": _test_story_girl_date_cash_support},
		{"group": "regression", "name": "seed 23 cash and replay", "fn": _test_seed_23_cash_and_replay},
		{"group": "rivals", "name": "completed repeatable rival", "fn": _test_completed_repeatable_rival},
		{"group": "rivals", "name": "story rival goals and diagnostics", "fn": _test_story_rival_goals_and_diagnostics},
		{"group": "rivals", "name": "seed 94 story rival", "fn": _test_seed_94_story_rival},
		{"group": "rivals", "name": "story rival challenge money", "fn": _test_story_rival_challenge_money_creates_cash_dependency},
		{"group": "rivals", "name": "columnist money dependency", "fn": _test_columnist_money_dependency_resolves},
		{"group": "rivals", "name": "ordinary rival money dependency", "fn": _test_ordinary_rival_money_dependency_resolves},
		{"group": "rivals", "name": "rival required money from production", "fn": _test_rival_required_money_from_production},
		{"group": "rivals", "name": "rival insufficient money not empty", "fn": _test_rival_insufficient_money_not_empty_candidates},
		{"group": "rivals", "name": "rival cash regression seeds", "fn": _test_rival_cash_regression_seeds},
		{"group": "identity", "name": "build identity clean state", "fn": _test_build_identity_clean_state},
		{"group": "identity", "name": "build identity dirty state", "fn": _test_build_identity_dirty_state},
		{"group": "identity", "name": "build identity export schema", "fn": _test_build_identity_export_schema},
		{"group": "identity", "name": "bad seed count vs top k", "fn": _test_bad_seed_count_vs_top_k},
		{"group": "regression", "name": "seed 98 barrier pacing", "fn": _test_seed_98_barrier_pacing},
		{"group": "regression", "name": "seed 32 characteristic build", "fn": _test_seed_32_characteristic_build},
		{"group": "career", "name": "profitable career investment", "fn": _test_career_profitable_investment},
		{"group": "career", "name": "not profitable career investment", "fn": _test_career_not_profitable_investment},
		{"group": "career", "name": "rank 1 without connections", "fn": _test_career_rank_1_without_connections},
		{"group": "career", "name": "rank 2 connections lock", "fn": _test_career_rank_2_connections_lock},
		{"group": "career", "name": "career capital dependency", "fn": _test_career_capital_dependency},
		{"group": "career", "name": "career rank persists across stage", "fn": _test_career_persistence_across_stage},
		{"group": "career", "name": "career work attribution", "fn": _test_career_work_attribution},
		{"group": "career", "name": "career determinism", "fn": _test_career_determinism},
		{"group": "career", "name": "career rank progress beat", "fn": _test_career_progress_beat},
		{"group": "career", "name": "classify career supporting goal", "fn": _test_career_classify_supporting_goal},
		{"group": "career", "name": "rank 1 stage gate", "fn": _test_career_rank_1_stage_gate},
		{"group": "career", "name": "roi prerequisite at old salary", "fn": _test_career_roi_prerequisite_at_old_salary},
		{"group": "career", "name": "roi split phases", "fn": _test_career_roi_split_phases},
		{"group": "career", "name": "career cash reservation", "fn": _test_career_cash_reservation},
		{"group": "career", "name": "career reservation release", "fn": _test_career_reservation_release},
		{"group": "career", "name": "career reservation override", "fn": _test_career_reservation_override},
		{"group": "career", "name": "career reservation stage gate", "fn": _test_career_reservation_stage_gate},
		{"group": "career", "name": "seed 64 career support", "fn": _test_career_seed_64_support},
	]


func progress_line() -> String:
	return "%s · %s · %d / %d" % [_current_group, _current_test, _tests_done, _tests_total]

func run_all_async(host: Node) -> PackedStringArray:
	_failures.clear()
	_passed = 0
	_tests_done = 0
	var catalog: Array = test_catalog()
	_tests_total = catalog.size()
	var last_group: String = ""
	for item in catalog:
		_current_group = str(item.get("group", ""))
		_current_test = str(item.get("name", ""))
		if host != null and host.has_method("_show_test_progress"):
			host._show_test_progress(_current_group, _current_test, _tests_done, _tests_total)
		if host != null and host.get_tree() != null:
			if last_group != "" and last_group != _current_group:
				await host.get_tree().process_frame
			await host.get_tree().process_frame
		var callback: Callable = item["fn"]
		callback.call()
		_tests_done += 1
		last_group = _current_group
	if host != null and host.has_method("_show_test_progress"):
		host._show_test_progress(_current_group, "done", _tests_done, _tests_total)
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
		_ok("summary signature equals detailed", rec_a.execution_signature == detailed_a.execution_signature, "%s vs %s" % [rec_a.execution_signature, detailed_a.execution_signature])
		_ok("summary rng counts equal detailed", JSON.stringify(rec_a.rng_draw_counts) == JSON.stringify(detailed_a.rng_draw_counts), "%s vs %s" % [JSON.stringify(rec_a.rng_draw_counts), JSON.stringify(detailed_a.rng_draw_counts)])
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
			_ok("schema_version", int(data.get("schema_version", 0)) == ProgressionLabConfig.SCHEMA_VERSION)
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


func _test_date_loadout_before_eligibility() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _probe_date_loadout(true)
	))
	_ok("date probe ran", not captured.is_empty(), JSON.stringify(captured))
	_ok("owned dressed exists", bool(captured.get("owned_dressed", false)))
	_ok("equipped casual", str(captured.get("equipped", "")) == String(OutfitCatalog.START_OUTFIT_ID), str(captured.get("equipped", "")))
	_ok("eligibility with selected dressed", bool(captured.get("eligible", false)), str(captured.get("reason", "")))
	_ok("date candidate exists", bool(captured.get("has_date", false)), str(captured.get("kinds", [])))
	_ok("selected outfit is dressed", bool(captured.get("selected_dressed", false)), str(captured.get("outfit_id", "")))
	_ok("date execution succeeded", bool(captured.get("executed", false)), str(captured.get("failure", "")))
	_ok("relationship changed", int(captured.get("rel_after", -1)) == int(captured.get("expected_rel", -2)), "%s -> %s delta=%s expected=%s" % [str(captured.get("rel_before", 0)), str(captured.get("rel_after", 0)), str(captured.get("date_delta", 0)), str(captured.get("expected_rel", -1))])


func _test_date_missing_dressed_outfit() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		return _probe_date_loadout(false)
	))
	_ok("no-dressed probe ran", not captured.is_empty())
	_ok("date candidate absent without dressed", not bool(captured.get("has_date", true)), str(captured.get("kinds", [])))
	_ok("support or purchase remains", bool(captured.get("has_support", false)), str(captured.get("kinds", [])))


func _test_story_barrier_and_stall() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		_advance_to_stage(2)
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = 2
		plan.story_girl_id = GirlCatalog.ID_VIKA
		plan.characteristic_targets = {String(CharacteristicIds.APPEARANCE): 3}
		var girls: Variant = _root("GirlsService")
		if girls != null:
			girls.discover_girl(plan.story_girl_id)
			girls.give_contact(plan.story_girl_id)
			var rel_max: int = int(girls.get_relationship_max(plan.story_girl_id))
			girls.change_relationship(plan.story_girl_id, maxi(rel_max - 1 - int(girls.get_relationship(plan.story_girl_id)), 0))
			payload["rel"] = int(girls.get_relationship(plan.story_girl_id))
			payload["rel_max"] = rel_max
		var before_stage: int = _current_stage()
		var candidates: Array = executor._collect_candidates(plan)
		payload["has_story_date"] = _has_kind(candidates, "date", plan.story_girl_id)
		payload["has_train"] = _has_kind(candidates, "train")
		payload["has_work"] = _has_kind(candidates, "work") or _has_kind(candidates, "buy_outfit")
		payload["stage_before"] = before_stage
		payload["stage_after_collect"] = _current_stage()
		executor.detailed = true
		executor._campaign = ProgressionLabMetrics.new()
		executor._current_stage_metrics = ProgressionLabMetrics.new()
		var failed := StageExecutor.ExecutionResult.new()
		failed.failure_code = "DATE_ELIGIBILITY_CHANGED"
		failed.failure_reason = "test failure"
		var dummy := StageExecutor.Candidate.new()
		dummy.category = "DATE"
		dummy.kind = "date"
		dummy.goal_id = "filler:olya:max"
		dummy.girl_id = GirlCatalog.ID_OLYA
		dummy.outfit_id = &"wrestling"
		dummy.venue_id = &"cafe"
		executor._record_failed_candidate(dummy, failed, plan)
		payload["failed_log"] = "\n".join(executor._day_lines)
		payload["stall_before"] = executor._consecutive_stalled_days
		executor._day_had_successful_action = false
		for _i in range(8):
			executor._finish_stalled_decision_cycle(plan, 2, 0)
		payload["aborted"] = executor._aborted
		payload["stop"] = executor._stop_reason
		payload["snapshot"] = executor._diagnostic_snapshot.duplicate(true)
		payload["stall_not_reset_by_candidate"] = executor._consecutive_stalled_decisions > 0
		return payload
	))
	_ok("story date blocked at MAX-1", not bool(captured.get("has_story_date", true)), JSON.stringify(captured))
	_ok("optional goals remain", bool(captured.get("has_train", false)) or bool(captured.get("has_work", false)), JSON.stringify(captured))
	_ok("stage unchanged while barrier incomplete", int(captured.get("stage_before", -1)) == int(captured.get("stage_after_collect", -2)))
	_ok("failed candidate exports reason", str(captured.get("failed_log", "")).find("FAILED CANDIDATE") >= 0, str(captured.get("failed_log", "")))
	_ok("failed candidate code", str(captured.get("failed_log", "")).find("DATE_ELIGIBILITY_CHANGED") >= 0)
	_ok("NO_USEFUL after stalled-day threshold", bool(captured.get("aborted", false)) and str(captured.get("stop", "")).begins_with("NO_USEFUL_ACTIONS_STAGE_"), str(captured.get("stop", "")))
	_ok("NO_USEFUL has diagnostic snapshot", not _as_dict(captured.get("snapshot", {})).is_empty())
	_ok("candidate existence does not reset stall", bool(captured.get("stall_not_reset_by_candidate", false)))


func _test_stage_money_consistency() -> void:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 80
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 1, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	_ok("money consistency campaign ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var campaign: Dictionary = record.campaign_metrics
	var earned_sum: int = 0
	var spent_sum: int = 0
	var action_sum: int = 0
	for key in record.stage_metrics.keys():
		var stage_metrics: Dictionary = record.stage_metrics[key]
		earned_sum += int(stage_metrics.get("money_earned", 0))
		spent_sum += int(stage_metrics.get("money_spent", 0))
		action_sum += int(stage_metrics.get("total_actions", 0))
	_ok("stage money_earned sum equals campaign", earned_sum == int(campaign.get("money_earned", -1)), "%d vs %d" % [earned_sum, int(campaign.get("money_earned", 0))])
	_ok("stage money_spent sum equals campaign", spent_sum == int(campaign.get("money_spent", -1)), "%d vs %d" % [spent_sum, int(campaign.get("money_spent", 0))])
	_ok("stage total_actions sum equals campaign", action_sum == int(campaign.get("total_actions", -1)), "%d vs %d" % [action_sum, int(campaign.get("total_actions", 0))])
	var friction: Dictionary = _as_dict(campaign.get("goal_friction", {}))
	var stage_friction_ok: bool = true
	for key in record.stage_metrics.keys():
		var stage_entry: Dictionary = record.stage_metrics[key]
		var stage_friction: Dictionary = _as_dict(stage_entry.get("goal_friction", {}))
		for goal_id in stage_friction.keys():
			var stage_goal: Dictionary = _as_dict(stage_friction[goal_id])
			var campaign_goal: Dictionary = _as_dict(friction.get(str(goal_id), {}))
			if int(stage_goal.get("completed_day", -2)) >= 0 and int(campaign_goal.get("completed_day", -3)) < 0:
				stage_friction_ok = false
	_ok("stage Goal Friction completion matches campaign", stage_friction_ok)


func _test_failed_seed_regression_set() -> void:
	var seeds: PackedInt32Array = PackedInt32Array([7, 12, 22, 23, 24, 31, 47, 84, 90, 94])
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure_seed_list(config, seeds, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	var result: ProgressionLabPopulationResult = runner.get_result()
	_ok("regression seed count", result.records.size() == seeds.size(), str(result.records.size()))
	var seed_22: ProgressionLabRunRecord = null
	for record in result.records:
		if not (record is ProgressionLabRunRecord):
			continue
		var run: ProgressionLabRunRecord = record
		var days: int = int(run.campaign_metrics.get("calendar_days", 0))
		var warnings: PackedStringArray = run.hard_warnings
		_ok("seed %d no SAFETY_CAP_DAYS" % run.base_seed, warnings.find("SAFETY_CAP_DAYS") < 0, ",".join(warnings))
		_ok("seed %d finished before 400-day deadlock" % run.base_seed, days < 400 or run.stop_reason.begins_with("NO_USEFUL_ACTIONS_STAGE_"), "days=%d stop=%s" % [days, run.stop_reason])
		_ok("seed %d no stage invariant break" % run.base_seed, warnings.find("STAGE_TRANSITION_INVARIANT") < 0, ",".join(warnings))
		if run.stop_reason.begins_with("NO_USEFUL_ACTIONS_STAGE_"):
			_ok("seed %d NO_USEFUL snapshot" % run.base_seed, not run.diagnostic_snapshot.is_empty())
			_ok("seed %d NO_USEFUL not rival money" % run.base_seed, not _nouseful_from_rival_money(run), JSON.stringify(run.diagnostic_snapshot.get("cash_dependencies", [])))
		if run.base_seed == 22:
			seed_22 = run
	_ok("seed 22 present", seed_22 != null)
	if seed_22 != null:
		var dead: int = int(seed_22.campaign_metrics.get("max_consecutive_dead_progress_days", 0))
		_ok("seed 22 avoids hundreds of consecutive dead days", dead < 80, str(dead))
		_ok("seed 22 ran dates or aborted with snapshot", int(seed_22.campaign_metrics.get("dates", 0)) > 0 or not seed_22.diagnostic_snapshot.is_empty())

func _test_replay_signature_and_isolation() -> void:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 80
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 5, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	_ok("isolation campaign ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var first: ProgressionLabRunRecord = runner.get_result().records[0]
	var second: ProgressionLabRunRecord = runner.replay_seed(5, false)
	var third: ProgressionLabRunRecord = runner.replay_seed(6, false)
	var first_again: ProgressionLabRunRecord = runner.replay_seed(5, false)
	var detailed: ProgressionLabRunRecord = runner.replay_seed(5, true)
	_ok("sequential same seed signature", first.execution_signature == first_again.execution_signature, "%s vs %s" % [first.execution_signature, first_again.execution_signature])
	_ok("summary vs detailed signature", first.execution_signature == detailed.execution_signature, "%s vs %s" % [first.execution_signature, detailed.execution_signature])
	_ok("summary vs detailed rng counts", JSON.stringify(first.rng_draw_counts) == JSON.stringify(detailed.rng_draw_counts), "%s vs %s" % [JSON.stringify(first.rng_draw_counts), JSON.stringify(detailed.rng_draw_counts)])
	_ok("different seed not identical", first.execution_signature != third.execution_signature)


func _test_replay_regression_seeds() -> void:
	var seeds: PackedInt32Array = PackedInt32Array([23, 41, 48, 51, 71, 99])
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure_seed_list(config, seeds, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	var result: ProgressionLabPopulationResult = runner.get_result()
	_ok("replay regression seed count", result.records.size() == seeds.size(), str(result.records.size()))
	for record in result.records:
		if not (record is ProgressionLabRunRecord):
			continue
		var summary: ProgressionLabRunRecord = record
		var detailed: ProgressionLabRunRecord = runner.replay_seed(summary.base_seed, true)
		var diff: Dictionary = ProgressionLabRunRecord.first_difference(summary, detailed)
		_ok("seed %d signature" % summary.base_seed, summary.execution_signature == detailed.execution_signature, "%s %s vs %s" % [str(diff.get("field", "")), str(diff.get("summary_action", "")), str(diff.get("replay_action", ""))])
		_ok("seed %d rng counts" % summary.base_seed, JSON.stringify(summary.rng_draw_counts) == JSON.stringify(detailed.rng_draw_counts))
		_ok("seed %d stop" % summary.base_seed, summary.stop_reason == detailed.stop_reason, "%s vs %s" % [summary.stop_reason, detailed.stop_reason])
		_ok("seed %d days" % summary.base_seed, int(summary.campaign_metrics.get("calendar_days", -1)) == int(detailed.campaign_metrics.get("calendar_days", -2)))
		_ok("seed %d money" % summary.base_seed, summary.final_money == detailed.final_money, "%d vs %d" % [summary.final_money, detailed.final_money])
		_ok("seed %d stage" % summary.base_seed, summary.final_story_stage == detailed.final_story_stage)


func _test_story_girl_date_cash_support() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		var girl_id: StringName = GirlCatalog.ID_ALINA
		var gs: Variant = _root("GameState")
		if gs != null and gs.world != null:
			gs.world.unlocked_date_venue_ids.clear()
		var world: Variant = _root("WorldService")
		if world != null:
			world.unlock_date_venue(&"cafe")
		var girls: Variant = _root("GirlsService")
		if girls != null:
			girls.discover_girl(girl_id)
			girls.give_contact(girl_id)
		var economy: Variant = _root("EconomyService")
		if economy != null:
			economy.add_money(400)
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.story_girl_id = girl_id
		executor._date_policy.plan = plan
		var funded: Array = executor._collect_candidates(plan)
		var funded_date: StageExecutor.Candidate = _find_candidate(funded, "date", girl_id)
		payload["kinds"] = []
		for raw in funded:
			if raw != null:
				payload["kinds"].append((raw as StageExecutor.Candidate).kind)
		payload["funded_has_date"] = funded_date != null
		var eval_outfit: StringName = funded_date.outfit_id if funded_date != null else OutfitCatalog.START_OUTFIT_ID
		var eval_venue: StringName = funded_date.venue_id if funded_date != null else &"cafe"
		var eligibility: Dictionary = executor.evaluate_date_candidate(girl_id, eval_outfit, eval_venue, false, false)
		payload["eligible"] = bool(eligibility.get("eligible", false))
		payload["reason"] = str(eligibility.get("reason", ""))
		var required: int = funded_date.required_money if funded_date != null else int(eligibility.get("required_money", 20))
		payload["required_money"] = required
		if economy != null:
			var current: int = int(economy.get_money())
			if current > 0:
				economy.spend_money(current)
			if required > 1:
				economy.add_money(maxi(required - 15, 1))
			payload["money"] = int(economy.get_money())
		var blocked: Array = executor._collect_candidates(plan)
		payload["blocked_has_date"] = _find_candidate(blocked, "date", girl_id) != null
		var work: StageExecutor.Candidate = _find_candidate(blocked, "work")
		payload["has_work"] = work != null
		payload["work_goal"] = work.goal_id if work != null else ""
		payload["work_required"] = work.required_money if work != null else 0
		payload["work_action"] = work.supporting_action_id if work != null else ""
		var snapshot: Dictionary = executor.collect_blocking_snapshot(plan)
		payload["cash_goals"] = []
		for row in snapshot.get("cash_dependencies", []):
			if row is Dictionary:
				payload["cash_goals"].append(str(row.get("goal_id", "")))
				if str(row.get("goal_id", "")) == executor._girl_goal(girl_id, true):
					payload["cash_required"] = int(row.get("required_money", 0))
		payload["story_goal"] = executor._girl_goal(girl_id, true)
		payload["money_ids"] = Array(snapshot.get("money", PackedStringArray()))
		return payload
	))
	_ok("funded story date exists", bool(captured.get("funded_has_date", false)), JSON.stringify(captured))
	var story_goal: String = str(captured.get("story_goal", ""))
	_ok("story girl in cash dependencies", (captured.get("cash_goals", []) as Array).has(story_goal), JSON.stringify(captured))
	_ok("story girl in money snapshot", (captured.get("money_ids", []) as Array).has(story_goal), JSON.stringify(captured))
	_ok("WORK supports story girl", bool(captured.get("has_work", false)) and str(captured.get("work_goal", "")) == story_goal, JSON.stringify(captured))
	_ok("WORK uses concrete date cost", int(captured.get("work_required", 0)) == int(captured.get("required_money", -1)) or int(captured.get("cash_required", 0)) == int(captured.get("required_money", -1)), JSON.stringify(captured))

func _test_seed_23_cash_and_replay() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 23, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	_ok("seed 23 ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var summary: ProgressionLabRunRecord = runner.get_result().records[0]
	var money_fails: int = 0
	for item in summary.failed_candidate_sequence:
		if str(item).find("INSUFFICIENT_MONEY") >= 0 and str(item).begins_with("date"):
			money_fails += 1
	var work_actions: int = int(summary.campaign_metrics.get("work_actions", 0))
	_ok("seed 23 no date money fail without WORK", money_fails == 0 or work_actions > 0, "fails=%d work=%d" % [money_fails, work_actions])
	var detailed: ProgressionLabRunRecord = runner.replay_seed(23, true)
	_ok("seed 23 summary equals detailed", summary.execution_signature == detailed.execution_signature, JSON.stringify(ProgressionLabRunRecord.first_difference(summary, detailed)))


func _test_completed_repeatable_rival() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		var rival_id: StringName = RivalCatalog.ID_GLEB
		var rivals: Variant = _root("RivalsService")
		if rivals != null:
			rivals.discover_rival(rival_id)
			rivals.defeat_rival(rival_id)
			payload["repeatable"] = bool(rivals.is_repeatable_rival(rival_id))
			payload["defeated"] = bool(rivals.is_defeated(rival_id))
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.target_ordinary_rival_ids.append(rival_id)
		payload["complete"] = executor.is_rival_goal_complete(executor._rival_goal(rival_id), rival_id)
		payload["barrier"] = executor._barrier_complete(plan)
		var candidates: Array = executor._collect_candidates(plan)
		payload["has_meet"] = _has_kind(candidates, "rival_meet")
		payload["has_fight"] = _has_kind(candidates, "rival_fight")
		return payload
	))
	_ok("ordinary rival is production-repeatable", bool(captured.get("repeatable", false)), JSON.stringify(captured))
	_ok("defeated rival goal complete", bool(captured.get("complete", false)), JSON.stringify(captured))
	_ok("no rival candidate after StagePlan completion", not bool(captured.get("has_meet", true)) and not bool(captured.get("has_fight", true)), JSON.stringify(captured))
	_ok("barrier treats rival goal complete", bool(captured.get("barrier", false)), JSON.stringify(captured))


func _test_story_rival_goals_and_diagnostics() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.story_girl_id = GirlCatalog.ID_ACTRESS
		plan.story_rival_id = RivalCatalog.ID_BORIS
		var unmet: PackedStringArray = executor._unmet_goals(plan)
		payload["unmet"] = Array(unmet)
		payload["has_story_rival_goal"] = unmet.has(executor._story_rival_goal(RivalCatalog.ID_BORIS))
		payload["barrier"] = executor._barrier_complete(plan)
		var snapshot: Dictionary = executor._build_diagnostic_snapshot(plan)
		var rivals_diag: Dictionary = snapshot.get("rival_availability", {})
		payload["has_boris_diag"] = rivals_diag.has(String(RivalCatalog.ID_BORIS))
		if rivals_diag.has(String(RivalCatalog.ID_BORIS)):
			payload["boris"] = rivals_diag[String(RivalCatalog.ID_BORIS)]
		var girls: Variant = _root("GirlsService")
		if girls != null:
			girls.discover_girl(GirlCatalog.ID_ACTRESS)
			girls.give_contact(GirlCatalog.ID_ACTRESS)
		var after_discover: Array = executor._collect_candidates(plan)
		payload["meet_after_actress"] = _has_kind(_candidates_of_rival(after_discover, RivalCatalog.ID_BORIS), "rival_meet")
		payload["state_after_actress"] = executor._rival_simulation_state(RivalCatalog.ID_BORIS)
		return payload
	))
	_ok("story rival in unmet goals", bool(captured.get("has_story_rival_goal", false)), JSON.stringify(captured))
	_ok("story rival in diagnostics", bool(captured.get("has_boris_diag", false)), JSON.stringify(captured))
	_ok("barrier incomplete before story rival defeat", not bool(captured.get("barrier", true)), JSON.stringify(captured))
	_ok("Boris meet uses production availability after Actress discovered", str(captured.get("state_after_actress", "")) == "AVAILABLE_TO_MEET" or bool(captured.get("meet_after_actress", false)), JSON.stringify(captured))


func _test_seed_94_story_rival() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 94, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	_ok("seed 94 ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var unmet: Array = record.diagnostic_snapshot.get("unmet_goals", []) if record.aborted else []
	var rivals_diag: Dictionary = record.diagnostic_snapshot.get("rival_availability", {}) if not record.diagnostic_snapshot.is_empty() else {}
	var saw_boris: bool = false
	for item in record.action_sequence:
		if str(item).find("rival_boris") >= 0:
			saw_boris = true
			break
	if rivals_diag.has("rival_boris"):
		saw_boris = true
	for goal in unmet:
		if str(goal).find("rival_boris") >= 0:
			saw_boris = true
	_ok("seed 94 exposes Boris", saw_boris or not record.aborted, JSON.stringify({"stop": record.stop_reason, "unmet": unmet, "diag": rivals_diag}))
	var detailed: ProgressionLabRunRecord = runner.replay_seed(94, true)
	_ok("seed 94 replay", record.execution_signature == detailed.execution_signature, JSON.stringify(ProgressionLabRunRecord.first_difference(record, detailed)))

func _test_story_rival_challenge_money_creates_cash_dependency() -> void:
	var captured: Dictionary = _run_rival_cash_probe(RivalCatalog.ID_BORIS, GirlCatalog.ID_ACTRESS, true, 1)
	_ok("Story Rival remains unmet", bool(captured.get("unmet", false)), JSON.stringify(captured))
	_ok("Story Rival challenge money creates cash dependency", bool(captured.get("has_cash", false)), JSON.stringify(captured))
	_ok("Story Rival challenge money creates WORK support", bool(captured.get("has_work", false)), JSON.stringify(captured))
	_ok("WORK supporting_goal_id references Boris", str(captured.get("work_goal", "")).find("rival_boris") >= 0, JSON.stringify(captured))
	_ok("WORK supporting_action_id references Boris challenge", str(captured.get("work_action", "")).find("rival_challenge:rival_boris") >= 0, JSON.stringify(captured))
	_ok("Rival cash dependency uses canonical dependency snapshot", bool(captured.get("cash_matches_intent", false)), JSON.stringify(captured))
	_ok("Rival challenge succeeds after sufficient WORK", bool(captured.get("fight_ok", false)), JSON.stringify(captured))
	_ok("completed Rival goal creates no additional direct candidate", bool(captured.get("no_after", false)), JSON.stringify(captured))


func _test_columnist_money_dependency_resolves() -> void:
	var captured: Dictionary = _run_rival_cash_probe(RivalCatalog.ID_COLUMNIST, GirlCatalog.ID_MAGAZINE_EDITOR, true, 3)
	_ok("Columnist money dependency resolves", bool(captured.get("has_cash", false)) and bool(captured.get("has_work", false)) and bool(captured.get("fight_ok", false)), JSON.stringify(captured))
	_ok("Columnist goal complete", bool(captured.get("complete_after", false)), JSON.stringify(captured))


func _test_ordinary_rival_money_dependency_resolves() -> void:
	var captured: Dictionary = _run_rival_cash_probe(RivalCatalog.ID_MAX, &"", false, 1)
	_ok("ordinary Rival money dependency resolves", bool(captured.get("has_cash", false)) and bool(captured.get("has_work", false)) and bool(captured.get("fight_ok", false)), JSON.stringify(captured))
	_ok("ordinary Rival goal complete", bool(captured.get("complete_after", false)), JSON.stringify(captured))
	_ok("no additional ordinary Rival candidate after planned completion", bool(captured.get("no_after", false)), JSON.stringify(captured))


func _test_rival_required_money_from_production() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		_discover_rival_for_challenge(RivalCatalog.ID_BORIS, GirlCatalog.ID_ACTRESS, 1)
		var executor: StageExecutor = _fresh_executor()
		var intent: Dictionary = executor.evaluate_rival_intent(RivalCatalog.ID_BORIS, true)
		payload["intent_cost"] = int(intent.get("required_money", -1))
		var competitions: Variant = _root("CompetitionService")
		if competitions != null:
			var list: Array = competitions.get_competitions_for_rival(RivalCatalog.ID_BORIS)
			if not list.is_empty():
				var action: GameAction = competitions.create_competition_action(list[0].id)
				payload["production_cost"] = int(action.money_cost)
		return payload
	, 1))
	_ok("Rival required_money comes from production action", int(captured.get("intent_cost", -1)) == int(captured.get("production_cost", -2)) and int(captured.get("production_cost", 0)) > 0, JSON.stringify(captured))


func _test_rival_insufficient_money_not_empty_candidates() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		_discover_rival_for_challenge(RivalCatalog.ID_BORIS, GirlCatalog.ID_ACTRESS, 1)
		_set_money(0)
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.story_girl_id = GirlCatalog.ID_ACTRESS
		plan.story_rival_id = RivalCatalog.ID_BORIS
		var candidates: Array = executor._collect_candidates(plan)
		payload["count"] = candidates.size()
		payload["has_work"] = _has_kind(candidates, "work")
		payload["has_fight"] = _has_kind(candidates, "rival_fight")
		payload["state"] = executor._rival_simulation_state(RivalCatalog.ID_BORIS)
		return payload
	, 1))
	_ok("Rival insufficient-money state cannot produce empty candidate set", int(captured.get("count", 0)) > 0 and bool(captured.get("has_work", false)), JSON.stringify(captured))
	_ok("no direct challenge while cash_gap", not bool(captured.get("has_fight", true)), JSON.stringify(captured))


func _test_rival_cash_regression_seeds() -> void:
	var seeds: PackedInt32Array = PackedInt32Array([12, 15, 23, 80, 86, 94])
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure_seed_list(config, seeds, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	var result: ProgressionLabPopulationResult = runner.get_result()
	_ok("rival cash regression seed count", result.records.size() == seeds.size(), str(result.records.size()))
	for record in result.records:
		if not (record is ProgressionLabRunRecord):
			continue
		var run: ProgressionLabRunRecord = record
		_ok("seed %d no rival-money NO_USEFUL" % run.base_seed, not _nouseful_from_rival_money(run), "%s unmet=%s failure=%s" % [run.stop_reason, str(run.diagnostic_snapshot.get("unmet_goals", [])), str(run.diagnostic_snapshot.get("last_rival_action_failure", ""))])


func _test_build_identity_clean_state() -> void:
	var result := ProgressionLabPopulationResult.new()
	result.simulation_version = "abc1234"
	result.git_dirty = false
	result.worktree_fingerprint = ""
	var exporter := ProgressionLabExporter.new()
	var payload: Dictionary = exporter.share_bundle_json(result)
	_ok("build identity clean git_dirty", bool(payload.get("git_dirty", true)) == false)
	_ok("build identity clean fingerprint", str(payload.get("worktree_fingerprint", "x")) == "")


func _test_build_identity_dirty_state() -> void:
	var result := ProgressionLabPopulationResult.new()
	result.simulation_version = "abc1234"
	result.git_dirty = true
	result.worktree_fingerprint = ProgressionRng.sha256_hex("dirty-source")
	var exporter := ProgressionLabExporter.new()
	var payload: Dictionary = exporter.share_bundle_json(result)
	_ok("build identity dirty git_dirty", bool(payload.get("git_dirty", false)) == true)
	var fingerprint: String = str(payload.get("worktree_fingerprint", ""))
	_ok("build identity dirty fingerprint sha256", fingerprint.length() == 64 and fingerprint.find(" ") < 0, fingerprint)


func _test_build_identity_export_schema() -> void:
	var result := ProgressionLabPopulationResult.new()
	result.simulation_version = "deadbee"
	result.git_dirty = true
	result.worktree_fingerprint = ProgressionRng.sha256_hex("schema")
	result.config = {}
	var record := ProgressionLabRunRecord.new()
	record.base_seed = 1
	var exporter := ProgressionLabExporter.new()
	var share: Dictionary = exporter.share_bundle_json(result)
	var config_payload: Dictionary = exporter._config_payload(result)
	var seed_payload: Dictionary = exporter.specific_seed_json(record, result)
	for payload in [share, config_payload, seed_payload]:
		_ok("identity schema simulation_version", payload.has("simulation_version"))
		_ok("identity schema git_dirty", payload.has("git_dirty"))
		_ok("identity schema worktree_fingerprint", payload.has("worktree_fingerprint"))
	var markdown: String = exporter.share_bundle_markdown(result)
	_ok("identity markdown simulation version", markdown.find("Simulation version:") >= 0)
	_ok("identity markdown git dirty", markdown.find("Git dirty:") >= 0)


func _test_bad_seed_count_vs_top_k() -> void:
	var config := ProgressionLabConfig.new()
	config.bad_seed_count_display = 25
	var result := ProgressionLabPopulationResult.new()
	result.n = 100
	for i in range(100):
		var record := ProgressionLabRunRecord.new()
		record.base_seed = i + 1
		record.campaign_metrics = {"money_blocked_decision_points": 5, "calendar_days": 20}
		result.records.append(record)
	var analyzer := ProgressionLabAnalyzer.new()
	analyzer.analyze(result, config)
	_ok("all bad count 100", result.bad_seed_count == 100, str(result.bad_seed_count))
	_ok("all bad percentage 1", is_equal_approx(result.bad_seed_percentage, 1.0), str(result.bad_seed_percentage))
	_ok("all_bad_seeds size 100", result.all_bad_seeds.size() == 100, str(result.all_bad_seeds.size()))
	_ok("top_bad_seeds size 25", result.top_bad_seeds.size() == 25, str(result.top_bad_seeds.size()))
	var exporter := ProgressionLabExporter.new()
	var csv: String = exporter._bad_csv(result.all_bad_seeds)
	var csv_lines: PackedStringArray = csv.split("\n")
	_ok("bad_seeds.csv has all rows", csv_lines.size() >= 101, str(csv_lines.size()))

func _test_build_urgency_priority() -> void:
	var captured: Dictionary = _as_dict(PlaythroughSession.new().run(func() -> Dictionary:
		var executor := StageExecutor.new()
		executor.config = ProgressionLabConfig.new()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.target_filler_girl_ids = [GirlCatalog.ID_ALINA, GirlCatalog.ID_OLYA] as Array[StringName]
		var goal_id: String = executor._char_goal(CharacteristicIds.APPEARANCE, 3)
		var payload: Dictionary = {}
		payload["base"] = executor._apply_build_priority(75.0, plan, goal_id, 95.0)
		plan.target_filler_girl_ids = [GirlCatalog.ID_ALINA] as Array[StringName]
		payload["char"] = executor._apply_build_priority(75.0, plan, goal_id, 95.0)
		payload["outfit"] = executor._apply_build_priority(70.0, plan, executor._outfit_goal(&"sport"), 95.0)
		payload["apt"] = executor._apply_build_priority(65.0, plan, executor._apartment_goal(&"apartment__plaid"), 90.0)
		var train := StageExecutor.Candidate.new()
		train.category = "TRAINING"
		train.score = float(payload["char"])
		executor.apply_execution_scores([train], "DATE", 1, null, 1.0)
		payload["after_noise"] = train.score
		return payload
	))
	_ok("build priority at least base", float(captured.get("base", 0.0)) >= 75.0, str(captured.get("base", 0.0)))
	_ok("urgent characteristic floor 95", float(captured.get("char", 0.0)) >= 95.0, str(captured.get("char", 0.0)))
	_ok("urgent outfit floor 95", float(captured.get("outfit", 0.0)) >= 95.0, str(captured.get("outfit", 0.0)))
	_ok("urgent apartment floor 90", float(captured.get("apt", 0.0)) >= 90.0, str(captured.get("apt", 0.0)))
	_ok("build priority applied before noise", is_equal_approx(float(captured.get("after_noise", 0.0)), float(captured.get("char", -1.0))), str(captured.get("after_noise", 0.0)))

func _test_stage_calendar_duration() -> void:
	var stage1 := ProgressionLabMetrics.new()
	stage1.begin_stage_window(0)
	stage1.finalize_days(6, 0, 0, 0)
	_ok("stage 1 start day 1", stage1.stage_start_calendar_day == 1, str(stage1.stage_start_calendar_day))
	_ok("stage 1 end day 7", stage1.stage_end_calendar_day == 7, str(stage1.stage_end_calendar_day))
	_ok("stage 1 calendar_days 7", stage1.calendar_days == 7, str(stage1.calendar_days))
	var stage2 := ProgressionLabMetrics.new()
	stage2.begin_stage_window(6)
	stage2.finalize_days(19, 0, 0, 6)
	_ok("stage 2 start day 7", stage2.stage_start_calendar_day == 7, str(stage2.stage_start_calendar_day))
	_ok("stage 2 end day 20", stage2.stage_end_calendar_day == 20, str(stage2.stage_end_calendar_day))
	_ok("stage 2 calendar_days 14", stage2.calendar_days == 14, str(stage2.calendar_days))
	var campaign := ProgressionLabMetrics.new()
	campaign.finalize_days(19, 0, 0, 0)
	_ok("campaign calendar_days 20", campaign.calendar_days == 20, str(campaign.calendar_days))


func _test_stage_dead_progress() -> void:
	var metrics := ProgressionLabMetrics.new()
	metrics.begin_stage_window(9)
	metrics.record_primary("DATE", 9, 1)
	metrics.record_primary("DATE", 12, 1)
	metrics.finalize_days(13, 0, 0, 9)
	_ok("dead-progress calendar_days 5", metrics.calendar_days == 5, str(metrics.calendar_days))
	_ok("dead-progress days 3", metrics.dead_progress_days == 3, str(metrics.dead_progress_days))
	_ok("max consecutive dead 2", metrics.max_consecutive_dead_progress_days == 2, str(metrics.max_consecutive_dead_progress_days))
	var before := ProgressionLabMetrics.new()
	before.begin_stage_window(9)
	before.record_primary("WORK", 8, 1)
	before.finalize_days(13, 0, 0, 9)
	_ok("days before stage start ignored", before.dead_progress_days == 5, str(before.dead_progress_days))


func _test_metric_consistency() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 1, 2, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	_ok("consistency run present", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var campaign: Dictionary = record.campaign_metrics
	var sums: Dictionary = {
		"total_actions": 0,
		"work_actions": 0,
		"training_actions": 0,
		"dates": 0,
		"rival_attempts": 0,
		"purchases": 0,
		"money_earned": 0,
		"money_spent": 0,
		"progress_beats": 0,
		"career_advancement_actions": 0,
		"work_actions_at_rank_0": 0,
		"work_actions_at_rank_1": 0,
		"work_actions_at_rank_2": 0,
		"work_actions_at_rank_3": 0,
		"career_investment_capital_training_actions": 0,
		"work_actions_supporting_career": 0,
		"career_negative_or_zero_roi_investments": 0,
		"career_positive_roi_investments": 0,
		"career_reservation_started_count": 0,
		"career_reservation_completed_count": 0,
		"career_reservation_override_count": 0,
		"career_support_work_before_target_rank": 0,
		"career_support_work_wasted": 0,
		"money_earned_from_work": 0,
	}
	for stage_key in record.stage_metrics.keys():
		var stage: Dictionary = record.stage_metrics[stage_key]
		for key in sums.keys():
			sums[key] = int(sums[key]) + int(stage.get(key, 0))
	for key in sums.keys():
		_ok("sum stage %s == campaign" % key, int(sums[key]) == int(campaign.get(key, -1)), "%s vs %s" % [str(sums[key]), str(campaign.get(key, -1))])


func _test_work_attribution_helper() -> void:
	_ok("classify characteristic", ProgressionLabMetrics.classify_supporting_goal("characteristic:appearance:3") == "CHARACTERISTIC")
	_ok("classify outfit", ProgressionLabMetrics.classify_supporting_goal("outfit:acquire:sport") == "OUTFIT")
	_ok("classify apartment", ProgressionLabMetrics.classify_supporting_goal("apartment:acquire:apartment__plaid") == "APARTMENT")
	_ok("classify date", ProgressionLabMetrics.classify_supporting_goal("filler:max:alina") == "DATE")
	_ok("classify story date", ProgressionLabMetrics.classify_supporting_goal("story:max:vika") == "DATE")
	_ok("classify rival", ProgressionLabMetrics.classify_supporting_goal("rival:columnist") == "RIVAL")
	_ok("classify other", ProgressionLabMetrics.classify_supporting_goal("venue:visit:cafe") == "OTHER")
	_ok("classify career", ProgressionLabMetrics.classify_supporting_goal("career:rank_2") == "CAREER")
	var metrics := ProgressionLabMetrics.new()
	metrics.record_work_support("characteristic:appearance:3")
	metrics.record_work_support("outfit:acquire:sport")
	metrics.record_work_support("apartment:acquire:apartment__plaid")
	metrics.record_work_support("filler:max:alina")
	metrics.record_work_support("rival:columnist")
	metrics.record_work_support("venue:visit:cafe")
	metrics.record_work_support("career:rank_2")
	_ok("work char 1", metrics.work_actions_for_characteristics == 1)
	_ok("work outfit 1", metrics.work_actions_for_outfits == 1)
	_ok("work apt 1", metrics.work_actions_for_apartment == 1)
	_ok("work dates 1", metrics.work_actions_for_dates == 1)
	_ok("work rivals 1", metrics.work_actions_for_rivals == 1)
	_ok("work other 1", metrics.work_actions_for_other == 1)
	_ok("work career 1", metrics.work_actions_for_career == 1)
	_ok("work supporting career 1", metrics.work_actions_supporting_career == 1)


func _test_career_classify_supporting_goal() -> void:
	_ok("classify career rank 2", ProgressionLabMetrics.classify_supporting_goal("career:rank_2") == "CAREER")
	_ok("career work kind", ProgressionLabMetrics.work_goal_kind("career:rank_2") == "career")


func _test_career_rank_1_stage_gate() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 1, 1)
		_set_money(0)
		var stage1_executor: StageExecutor = _career_executor()
		var stage1_plan: StagePlan = _career_cash_plan(true, 1)
		stage1_executor._date_policy.plan = stage1_plan
		var stage1_candidates: Array = stage1_executor._collect_candidates(stage1_plan)
		var stage1: Dictionary = {
			"can_advance": WorkService.can_advance_career(),
			"decision": str(stage1_executor._last_career_roi.get("decision", "")),
			"commitment": stage1_executor._target_career_rank,
			"has_advancement": _find_candidate(stage1_candidates, "career_advancement") != null,
		}
		_setup_career_state(false, 0, 1, 2)
		var stage2_executor: StageExecutor = _career_executor()
		var stage2_plan: StagePlan = _career_cash_plan(true, 2)
		stage2_executor._date_policy.plan = stage2_plan
		var stage2_candidates: Array = stage2_executor._collect_candidates(stage2_plan)
		return {
			"stage1": stage1,
			"can_advance": WorkService.can_advance_career(),
			"decision": str(stage2_executor._last_career_roi.get("decision", "")),
			"commitment": stage2_executor._target_career_rank,
			"has_advancement": _find_candidate(stage2_candidates, "career_advancement") != null,
		}
	))
	var stage1: Dictionary = _as_dict(captured.get("stage1", {}))
	_ok("stage 1 rank 1 unavailable", not bool(stage1.get("can_advance", true)) and int(stage1.get("commitment", 1)) <= 0 and not bool(stage1.get("has_advancement", true)), JSON.stringify(stage1))
	_ok("stage 2 rank 1 available", bool(captured.get("can_advance", false)), JSON.stringify(captured))


func _test_career_roi_prerequisite_at_old_salary() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		return executor._evaluate_career_roi(plan, false)
	))
	_ok("capital work uses current salary", int(captured.get("capital_work_actions", 0)) == 3, JSON.stringify(captured))
	_ok("capital training is 1", int(captured.get("capital_training_actions", 0)) == 1, JSON.stringify(captured))


func _test_career_roi_split_phases() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var plan := StagePlan.new()
		plan.stage = 1
		plan.characteristic_targets[String(CharacteristicIds.APPEARANCE)] = 1
		plan.characteristic_targets[String(CharacteristicIds.AURA)] = 1
		return executor._evaluate_career_roi(plan, false)
	))
	_ok("split capital work 3", int(captured.get("capital_work_actions", 0)) == 3, JSON.stringify(captured))
	_ok("split training 1", int(captured.get("capital_training_actions", 0)) == 1, JSON.stringify(captured))
	_ok("split post-promotion work 3", int(captured.get("post_promotion_work_actions", 0)) == 3, JSON.stringify(captured))
	_ok("split actions with upgrade 8", int(captured.get("economic_support_actions_with_upgrade", 0)) == 8, JSON.stringify(captured))
	_ok("split remaining stage cash 600", int(captured.get("remaining_stage_cash_need", 0)) == 600, JSON.stringify(captured))


func _test_career_cash_reservation() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(200)
		var executor: StageExecutor = _career_executor()
		executor._campaign = ProgressionLabMetrics.new()
		executor._current_stage_metrics = ProgressionLabMetrics.new()
		executor._target_career_rank = 1
		executor._recalculate_career_reservation()
		var plan: StagePlan = _career_cash_plan(false, 2)
		executor._date_policy.plan = plan
		var candidates: Array = executor._collect_candidates(plan)
		var apartment: StageExecutor.Candidate = _find_candidate(candidates, "buy_apartment")
		var career_work: StageExecutor.Candidate = null
		for raw in candidates:
			var candidate: StageExecutor.Candidate = raw
			if candidate != null and candidate.kind == "work" and candidate.goal_id.begins_with("career:"):
				career_work = candidate
				break
		return {
			"reserved": executor._career_reserved_money,
			"free": executor._free_money(),
			"money": executor._current_money(),
			"has_apartment": apartment != null,
			"has_career_work": career_work != null,
			"kinds": _candidate_kinds(candidates),
		}
	))
	_ok("reservation uses current money", int(captured.get("reserved", 0)) == 200, JSON.stringify(captured))
	_ok("free money is zero", int(captured.get("free", -1)) == 0, JSON.stringify(captured))
	_ok("optional apartment blocked", not bool(captured.get("has_apartment", true)), JSON.stringify(captured))
	_ok("career support continues", bool(captured.get("has_career_work", false)), JSON.stringify(captured))


func _test_career_reservation_release() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(300)
		var executor: StageExecutor = _career_executor()
		executor._campaign = ProgressionLabMetrics.new()
		executor._current_stage_metrics = ProgressionLabMetrics.new()
		executor._target_career_rank = 1
		executor._recalculate_career_reservation()
		var before_capital: int = executor._career_reserved_money
		var gs: Variant = _root("GameState")
		if gs != null and gs.player != null:
			gs.player.capital = 1
		executor._recalculate_career_reservation()
		var after_capital: int = executor._career_reserved_money
		var completed: int = executor._campaign.career_reservation_completed_count
		gs.player.career_rank = 1
		executor._sync_career_commitment()
		return {
			"before_capital": before_capital,
			"after_capital": after_capital,
			"completed": completed,
			"target": executor._target_career_rank,
			"reserved": executor._career_reserved_money,
		}
	))
	_ok("reservation held before capital", int(captured.get("before_capital", 0)) == 300, JSON.stringify(captured))
	_ok("reservation released after capital", int(captured.get("after_capital", -1)) == 0, JSON.stringify(captured))
	_ok("reservation completed telemetry", int(captured.get("completed", 0)) >= 1, JSON.stringify(captured))
	_ok("advancement clears commitment", int(captured.get("target", 1)) <= 0 and int(captured.get("reserved", -1)) == 0, JSON.stringify(captured))


func _test_career_reservation_override() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(200)
		var executor: StageExecutor = _career_executor()
		executor._campaign = ProgressionLabMetrics.new()
		executor._current_stage_metrics = ProgressionLabMetrics.new()
		executor._target_career_rank = 1
		executor._recalculate_career_reservation()
		var optional := StageExecutor.Candidate.new()
		optional.category = "PURCHASE"
		optional.kind = "buy_apartment"
		optional.goal_id = "apartment:acquire:apartment__plaid"
		optional.required_money = 150
		var story := StageExecutor.Candidate.new()
		story.category = "STORY"
		story.kind = "date"
		story.goal_id = "story:max:girl_actress"
		story.required_money = 100
		var candidates: Array = [optional, story]
		executor._apply_career_reservation_to_candidates(candidates)
		var kept_story: StageExecutor.Candidate = null
		for raw in candidates:
			var candidate: StageExecutor.Candidate = raw
			if candidate != null and candidate.category == "STORY":
				kept_story = candidate
		if kept_story != null and kept_story.reservation_override:
			executor._log_career_reservation_override(kept_story)
		return {
			"count": candidates.size(),
			"has_optional": _find_candidate(candidates, "buy_apartment") != null,
			"story_override": kept_story != null and kept_story.reservation_override,
			"overrides": executor._campaign.career_reservation_override_count,
		}
	))
	_ok("optional spend filtered", not bool(captured.get("has_optional", true)), JSON.stringify(captured))
	_ok("mandatory override path kept", bool(captured.get("story_override", false)), JSON.stringify(captured))
	_ok("override telemetry", int(captured.get("overrides", 0)) == 1, JSON.stringify(captured))

func _test_career_reservation_stage_gate() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 0, 2)
		_set_money(300)
		var executor: StageExecutor = _career_executor()
		executor._campaign = ProgressionLabMetrics.new()
		executor._current_stage_metrics = ProgressionLabMetrics.new()
		executor._target_career_rank = 1
		var plan := StagePlan.new()
		plan.stage = 2
		plan.characteristic_targets[CharacteristicIds.CAPITAL] = 3
		plan.target_apartment_object_ids.append(&"apartment__plaid")
		executor._date_policy.plan = plan
		var candidates: Array = executor._collect_candidates(plan)
		var dress_up: StageExecutor.Candidate = null
		var capital_train: StageExecutor.Candidate = null
		for raw in candidates:
			var candidate: StageExecutor.Candidate = raw
			if candidate == null:
				continue
			if candidate.goal_id == "outfit:dressup":
				dress_up = candidate
			if candidate.kind == "train" and String(candidate.content_id).contains("capital"):
				capital_train = candidate
		return {
			"reserved": executor._career_reserved_money,
			"has_dressup": dress_up != null,
			"dressup_override": dress_up != null and dress_up.reservation_override,
			"has_capital_train": capital_train != null,
			"has_apartment": _find_candidate(candidates, "buy_apartment") != null,
			"kinds": _candidate_kinds(candidates),
		}
	))
	_ok("reservation active at $300", int(captured.get("reserved", 0)) == 300, JSON.stringify(captured))
	_ok("stage dress-up kept", bool(captured.get("has_dressup", false)), JSON.stringify(captured))
	_ok("stage dress-up overrides reservation", bool(captured.get("dressup_override", false)), JSON.stringify(captured))
	_ok("plan capital train spends reserved cash", bool(captured.get("has_capital_train", false)), JSON.stringify(captured))
	_ok("optional apartment still blocked", not bool(captured.get("has_apartment", true)), JSON.stringify(captured))


func _test_career_seed_64_support() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 64, 4, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	_ok("seed 64 ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var metrics: Dictionary = record.campaign_metrics
	var career_work: int = int(metrics.get("work_actions_supporting_career", 99))
	_ok("seed 64 completed", not record.aborted, record.stop_reason)
	_ok("seed 64 rank target", int(metrics.get("career_rank_end", 0)) >= 1 or career_work == 0, JSON.stringify(metrics))
	_ok("seed 64 career-support WORK bounded", career_work <= 15, str(career_work))
	var replay: ProgressionLabRunRecord = runner.replay_seed(64, false)
	_ok("seed 64 replay matches", replay != null and replay.execution_signature == record.execution_signature, "%s vs %s" % [record.execution_signature, replay.execution_signature if replay != null else ""])


func _setup_career_state(connections: bool, rank: int, capital: int, story_stage: int = -1) -> void:
	var gs: Variant = _root("GameState")
	if gs == null or gs.player == null:
		return
	gs.player.career_connections_unlocked = connections
	gs.player.career_rank = clampi(rank, 0, 3)
	gs.player.capital = capital
	if story_stage >= 1 and gs.story != null:
		gs.story.stage = story_stage


func _career_cash_plan(expensive: bool, stage: int = 1) -> StagePlan:
	var plan := StagePlan.new()
	plan.stage = stage
	if expensive:
		plan.target_apartment_object_ids.append(&"apartment__chess_table")
		plan.target_apartment_object_ids.append(&"apartment__darts")
		plan.target_apartment_object_ids.append(&"apartment__game_console")
		plan.target_apartment_object_ids.append(&"apartment__karaoke")
		plan.target_apartment_object_ids.append(&"apartment__collection_display")
		plan.target_apartment_object_ids.append(&"apartment__large_mirror")
		plan.target_apartment_object_ids.append(&"apartment__mini_fridge")
		plan.target_apartment_object_ids.append(&"apartment__tea_set")
	else:
		plan.target_apartment_object_ids.append(&"apartment__plaid")
	return plan


func _career_executor() -> StageExecutor:
	var executor: StageExecutor = _fresh_executor()
	executor.profile.planning_skill = 1.0
	return executor


func _test_career_profitable_investment() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 1, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var plan: StagePlan = _career_cash_plan(true, 2)
		executor._date_policy.plan = plan
		var candidates: Array = executor._collect_candidates(plan)
		var advancement: StageExecutor.Candidate = _find_candidate(candidates, "career_advancement")
		var roi: Dictionary = executor._last_career_roi
		return {
			"connections": WorkService.has_career_connections(),
			"rank": WorkService.get_career_rank(),
			"capital": int(_root("GameState").player.capital) if _root("GameState") != null else -1,
			"has_advancement": advancement != null,
			"commitment": executor._target_career_rank,
			"saved": int(roi.get("saved_support_actions", 0)),
			"decision": str(roi.get("decision", "")),
			"remaining": int(roi.get("remaining_cash_need", 0)),
			"kinds": _candidate_kinds(candidates),
		}
	))
	_ok("rank 1 ROI does not require connections", not bool(captured.get("connections", true)), JSON.stringify(captured))
	_ok("career advancement candidate exists", bool(captured.get("has_advancement", false)), JSON.stringify(captured))
	_ok("career ROI saves support actions", int(captured.get("saved", 0)) > 0, JSON.stringify(captured))
	_ok("career decision INVEST", str(captured.get("decision", "")) == "INVEST", JSON.stringify(captured))

func _test_career_not_profitable_investment() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 1, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var plan: StagePlan = _career_cash_plan(false, 1)
		executor._date_policy.plan = plan
		var candidates: Array = executor._collect_candidates(plan)
		var advancement: StageExecutor.Candidate = _find_candidate(candidates, "career_advancement")
		var roi: Dictionary = executor._last_career_roi
		return {
			"has_advancement": advancement != null,
			"commitment": executor._target_career_rank,
			"saved": int(roi.get("saved_support_actions", 0)),
			"decision": str(roi.get("decision", "")),
			"has_work": _find_candidate(candidates, "work") != null,
			"kinds": _candidate_kinds(candidates),
		}
	))
	_ok("unprofitable career path absent", not bool(captured.get("has_advancement", true)) and int(captured.get("commitment", 1)) <= 0, JSON.stringify(captured))
	_ok("unprofitable decision SKIP_FOR_NOW", str(captured.get("decision", "")) == "SKIP_FOR_NOW", JSON.stringify(captured))
	_ok("stage plan still has work", bool(captured.get("has_work", false)), JSON.stringify(captured))


func _test_career_capital_dependency() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(true, 1, 1)
		_set_money(600)
		var executor: StageExecutor = _career_executor()
		var plan: StagePlan = _career_cash_plan(true)
		executor._date_policy.plan = plan
		var saw_train: bool = false
		var saw_advance: bool = false
		var commitment: int = 0
		for step in range(24):
			if WorkService.get_career_rank() >= 2:
				break
			var candidates: Array = executor._collect_candidates(plan)
			commitment = executor._target_career_rank
			var chosen: StageExecutor.Candidate = _find_candidate(candidates, "career_advancement")
			if chosen == null:
				chosen = _find_career_train(candidates)
			if chosen == null:
				var work: StageExecutor.Candidate = _find_candidate(candidates, "work")
				if work != null and work.goal_id.begins_with("career:"):
					chosen = work
			if chosen == null:
				executor._skip_day()
				executor._career_roi_day = -1
				continue
			if chosen.kind == "train":
				saw_train = true
			elif chosen.kind == "career_advancement":
				saw_advance = true
			var executed: StageExecutor.ExecutionResult = executor._execute_candidate(chosen, plan)
			if not executed.success:
				executor._skip_day()
				executor._career_roi_day = -1
		return {
			"rank": WorkService.get_career_rank(),
			"capital": int(_root("GameState").player.capital) if _root("GameState") != null else -1,
			"saw_train": saw_train,
			"saw_advance": saw_advance,
			"commitment": commitment,
			"advancement_actions": executor._campaign.career_advancement_actions,
			"career_training": executor._campaign.career_investment_capital_training_actions,
		}
	))
	_ok("career commitment rank 2", int(captured.get("commitment", 0)) == 2 or int(captured.get("rank", 0)) >= 2, JSON.stringify(captured))
	_ok("career capital training happened", bool(captured.get("saw_train", false)), JSON.stringify(captured))
	_ok("career reached rank 2", int(captured.get("rank", 0)) >= 2, JSON.stringify(captured))
	_ok("career advancement executed", bool(captured.get("saw_advance", false)) and int(captured.get("advancement_actions", 0)) >= 1, JSON.stringify(captured))


func _test_career_persistence_across_stage() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 1, 1)
		var executor: StageExecutor = _career_executor()
		var record: ProgressionLabRunRecord = executor.execute_run(7, 2)
		var stage_1: Dictionary = record.stage_metrics.get("1", {})
		var stage_2: Dictionary = record.stage_metrics.get("2", {})
		return {
			"start_1": int(stage_1.get("career_rank_start", -1)),
			"end_1": int(stage_1.get("career_rank_end", -1)),
			"start_2": int(stage_2.get("career_rank_start", -1)),
			"end_rank": WorkService.get_career_rank(),
			"campaign_end": int(record.campaign_metrics.get("career_rank_end", -1)),
			"has_stage_2": not stage_2.is_empty(),
		}
	))
	_ok("stage 1 starts at rank 1", int(captured.get("start_1", -1)) == 1, JSON.stringify(captured))
	if bool(captured.get("has_stage_2", false)):
		_ok("stage 2 keeps previous rank", int(captured.get("start_2", -1)) == int(captured.get("end_1", -2)), JSON.stringify(captured))
	else:
		_ok("rank survives campaign without reset", int(captured.get("end_rank", -1)) >= 1, JSON.stringify(captured))
	_ok("campaign end rank matches live state", int(captured.get("campaign_end", -1)) == int(captured.get("end_rank", -2)), JSON.stringify(captured))


func _test_career_work_attribution() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		_setup_career_state(true, 1, 1)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var career_plan: StagePlan = _career_cash_plan(true)
		executor._date_policy.plan = career_plan
		var career_candidates: Array = executor._collect_candidates(career_plan)
		var career_work: StageExecutor.Candidate = null
		for raw in career_candidates:
			var candidate: StageExecutor.Candidate = raw
			if candidate != null and candidate.kind == "work" and candidate.goal_id.begins_with("career:"):
				career_work = candidate
				break
		payload["career_work_goal"] = career_work.goal_id if career_work != null else ""
		payload["career_class"] = ProgressionLabMetrics.classify_supporting_goal(payload["career_work_goal"])
		_setup_career_state(false, 0, 0)
		_set_money(0)
		var plan_exec: StageExecutor = _career_executor()
		var char_plan := StagePlan.new()
		char_plan.stage = 1
		char_plan.characteristic_targets[String(CharacteristicIds.CAPITAL)] = 3
		plan_exec._date_policy.plan = char_plan
		var char_candidates: Array = plan_exec._collect_candidates(char_plan)
		var char_work: StageExecutor.Candidate = _find_candidate(char_candidates, "work")
		payload["plan_work_goal"] = char_work.goal_id if char_work != null else ""
		payload["plan_class"] = ProgressionLabMetrics.classify_supporting_goal(payload["plan_work_goal"])
		return payload
	))
	_ok("career-created capital work is CAREER", str(captured.get("career_class", "")) == "CAREER", JSON.stringify(captured))
	_ok("stageplan capital work is CHARACTERISTIC", str(captured.get("plan_class", "")) == "CHARACTERISTIC", JSON.stringify(captured))


func _test_career_determinism() -> void:
	var first: Dictionary = _run_career_determinism_seed(11)
	var second: Dictionary = _run_career_determinism_seed(11)
	_ok("career determinism completed", bool(first.get("ok", false)) and bool(second.get("ok", false)), JSON.stringify(first))
	_ok("career decisions match", str(first.get("sequence", "")) == str(second.get("sequence", "")), _seq_diff(first.get("sequence_arr", PackedStringArray()), second.get("sequence_arr", PackedStringArray())))
	_ok("career rank timeline matches", str(first.get("career", "")) == str(second.get("career", "")), "%s vs %s" % [str(first.get("career", "")), str(second.get("career", ""))])
	_ok("career metrics match", str(first.get("metrics", "")) == str(second.get("metrics", "")), "%s vs %s" % [str(first.get("metrics", "")), str(second.get("metrics", ""))])
	_ok("career signature matches", str(first.get("signature", "")) == str(second.get("signature", "")), "%s vs %s" % [str(first.get("signature", "")), str(second.get("signature", ""))])
	_ok("detailed replay matches summary", str(first.get("signature", "")) == str(first.get("detailed_signature", "x")), "%s vs %s" % [str(first.get("signature", "")), str(first.get("detailed_signature", ""))])


func _run_career_determinism_seed(base_seed: int) -> Dictionary:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 50
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, base_seed, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	if runner.get_result().records.is_empty():
		return {"ok": false}
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var detailed: ProgressionLabRunRecord = runner.replay_seed(base_seed, true)
	var metrics: Dictionary = record.campaign_metrics
	var career: Dictionary = {
		"rank_start": metrics.get("career_rank_start", 0),
		"rank_end": metrics.get("career_rank_end", 0),
		"advancement": metrics.get("career_advancement_actions", 0),
		"rank_1_day": metrics.get("career_rank_1_day", -1),
		"rank_2_day": metrics.get("career_rank_2_day", -1),
		"rank_3_day": metrics.get("career_rank_3_day", -1),
		"connections_day": metrics.get("career_connections_unlock_day", -1),
		"connections_stage": metrics.get("career_connections_unlock_stage", -1),
		"rank_1_before_connections": metrics.get("rank_1_before_connections", false),
	}
	return {
		"ok": true,
		"sequence": "|".join(record.action_sequence),
		"sequence_arr": record.action_sequence,
		"career": JSON.stringify(career),
		"metrics": JSON.stringify({
			"advancement": metrics.get("career_advancement_actions", 0),
			"work_at_0": metrics.get("work_actions_at_rank_0", 0),
			"money_work": metrics.get("money_earned_from_work", 0),
		}),
		"signature": record.execution_signature,
		"detailed_signature": detailed.execution_signature if detailed != null else "",
	}


func _test_career_progress_beat() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 1, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var candidate := StageExecutor.Candidate.new()
		candidate.category = "CAREER"
		candidate.kind = "career_advancement"
		candidate.goal_id = "career:rank_1"
		candidate.content_id = "career_advancement:1"
		var before: Dictionary = executor._capture_world()
		var ok: bool = executor._exec_career_advancement(candidate)
		var beats: int = executor._apply_world_diff(before, candidate)
		return {
			"ok": ok,
			"beats": beats,
			"rank_before": int(before.get("career_rank", -1)),
			"rank_after": WorkService.get_career_rank(),
			"can_advance": WorkService.can_advance_career(),
		}
	))
	_ok("career advancement executed for beat", bool(captured.get("ok", false)), JSON.stringify(captured))
	_ok("career rank increased", int(captured.get("rank_after", 0)) == int(captured.get("rank_before", 0)) + 1, JSON.stringify(captured))
	_ok("career rank increase is a progress beat", int(captured.get("beats", 0)) >= 1, JSON.stringify(captured))

func _test_career_rank_1_without_connections() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 0, 1, 2)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		var plan: StagePlan = _career_cash_plan(true, 2)
		executor._date_policy.plan = plan
		var candidates: Array = executor._collect_candidates(plan)
		var advancement: StageExecutor.Candidate = _find_candidate(candidates, "career_advancement")
		var roi: Dictionary = executor._last_career_roi
		return {
			"connections": WorkService.has_career_connections(),
			"has_advancement": advancement != null,
			"commitment": executor._target_career_rank,
			"decision": str(roi.get("decision", "")),
			"saved": int(roi.get("saved_support_actions", 0)),
			"remaining": int(roi.get("remaining_cash_need", 0)),
			"plan_stage": plan.stage,
			"can_advance": WorkService.can_advance_career(),
		}
	))
	_ok("stage 2 rank 1 connections false", not bool(captured.get("connections", true)), JSON.stringify(captured))
	_ok("stage 2 rank 1 ROI evaluated", str(captured.get("decision", "")) != "", JSON.stringify(captured))
	_ok("stage 2 rank 1 INVEST or choosable", str(captured.get("decision", "")) == "INVEST" and bool(captured.get("has_advancement", false)), JSON.stringify(captured))
	_ok("stage 2 rank 1 can_advance without connections", bool(captured.get("can_advance", false)), JSON.stringify(captured))


func _test_career_rank_2_connections_lock() -> void:
	var session := PlaythroughSession.new()
	var captured: Dictionary = _as_dict(session.run(func() -> Dictionary:
		_setup_career_state(false, 1, 3)
		_set_money(0)
		var executor: StageExecutor = _career_executor()
		executor.detailed = true
		var plan: StagePlan = _career_cash_plan(true, 2)
		plan.target_filler_girl_ids.append(&"girl_mine_boss")
		executor._date_policy.plan = plan
		var locked_candidates: Array = executor._collect_candidates(plan)
		var locked_advance: StageExecutor.Candidate = _find_candidate(locked_candidates, "career_advancement")
		var locked_commitment: int = executor._target_career_rank
		var locked_can_advance: bool = WorkService.can_advance_career()
		var snapshot: Dictionary = executor._build_diagnostic_snapshot(plan)
		var lock: Dictionary = executor._last_career_lock_diagnostics
		var lock_blob: String = "%s\n%s\n%s" % [JSON.stringify(lock), JSON.stringify(snapshot), "\n".join(executor._timeline)]
		var gs: Variant = _root("GameState")
		if gs != null and gs.player != null:
			gs.player.career_connections_unlocked = true
		executor._career_roi_day = -1
		var open_candidates: Array = executor._collect_candidates(plan)
		var open_advance: StageExecutor.Candidate = _find_candidate(open_candidates, "career_advancement")
		return {
			"locked_advance": locked_advance != null,
			"locked_commitment": locked_commitment,
			"locked_can_advance": locked_can_advance,
			"lock_target": int(lock.get("target_rank", -1)),
			"lock_mentions_connections": lock_blob.find("Connections") >= 0 or bool(lock.get("connections_requirement", false)),
			"open_advance": open_advance != null,
			"open_decision": str(executor._last_career_roi.get("decision", "")),
			"open_commitment": executor._target_career_rank,
			"open_can_advance": WorkService.can_advance_career(),
		}
	))
	_ok("rank 2 advancement unavailable without connections", not bool(captured.get("locked_advance", true)) and int(captured.get("locked_commitment", 1)) <= 0, JSON.stringify(captured))
	_ok("rank 2 production locked without connections", not bool(captured.get("locked_can_advance", true)), JSON.stringify(captured))
	_ok("rank 2 diagnostics mention Connections", bool(captured.get("lock_mentions_connections", false)) and int(captured.get("lock_target", -1)) == 2, JSON.stringify(captured))
	_ok("rank 2 available after connections", bool(captured.get("open_can_advance", false)) and (bool(captured.get("open_advance", false)) or str(captured.get("open_decision", "")) == "INVEST"), JSON.stringify(captured))


func _candidate_kinds(candidates: Array) -> PackedStringArray:
	var kinds: PackedStringArray = PackedStringArray()
	for raw in candidates:
		if raw != null:
			kinds.append((raw as StageExecutor.Candidate).kind)
	return kinds


func _find_career_train(candidates: Array) -> StageExecutor.Candidate:
	for raw in candidates:
		if raw == null:
			continue
		var candidate: StageExecutor.Candidate = raw
		if candidate.kind == "train" and candidate.goal_id.begins_with("career:"):
			return candidate
	return null


func _test_goal_friction_by_type() -> void:
	var record := ProgressionLabRunRecord.new()
	record.campaign_metrics = {
		"goal_friction": {
			"characteristic:appearance:3": {"direct_actions": 2, "support_actions": 4, "calendar_days_from_first_attempt_to_completion": 3},
			"outfit:acquire:sport": {"direct_actions": 1, "support_actions": 1, "calendar_days_from_first_attempt_to_completion": 2},
			"filler:max:alina": {"direct_actions": 3, "support_actions": 0, "calendar_days_from_first_attempt_to_completion": 4},
		},
	}
	var analyzer := ProgressionLabAnalyzer.new()
	var by_type: Dictionary = analyzer._goal_friction_by_type([record])
	_ok("friction has characteristic", by_type.has("Characteristic"))
	_ok("characteristic goal count", int(by_type["Characteristic"].get("goal_count", 0)) == 1)
	_ok("characteristic mean ratio 2", is_equal_approx(float(by_type["Characteristic"].get("mean_friction_ratio", 0.0)), 2.0))


func _test_share_bundle_pacing_fields() -> void:
	var result := ProgressionLabPopulationResult.new()
	result.schema_version = ProgressionLabConfig.SCHEMA_VERSION
	result.post_date_tail = {"days": {"P50": 1.0}}
	result.build_timing = {"outfit_remaining_dates": {"P50": 2.0}}
	result.work_attribution = {"characteristics": {"mean": 3.0}}
	result.goal_friction_by_type = {"Characteristic": {"goal_count": 1}}
	result.stale_planned_goals = {"count": {"max": 0.0}}
	var exporter := ProgressionLabExporter.new()
	var json: Dictionary = exporter.share_bundle_json(result)
	for key in ["post_date_tail", "build_timing", "work_attribution", "goal_friction_by_type", "stale_planned_goals", "career_progression"]:
		_ok("share json has %s" % key, json.has(key))
	var markdown: String = exporter.share_bundle_markdown(result)
	_ok("markdown post-date tail", markdown.find("## Post-Date Tail") >= 0)
	_ok("markdown build timing", markdown.find("## Build Timing") >= 0)
	_ok("markdown work attribution", markdown.find("## Work Attribution") >= 0)
	_ok("markdown career progression", markdown.find("## Career Progression") >= 0)
	_ok("markdown friction by type", markdown.find("## Goal Friction by Type") >= 0)
	_ok("markdown apartment item utility", markdown.find("## Apartment Item Utility") >= 0)


func _test_item_metrics_csv_apartment() -> void:
	var result := ProgressionLabPopulationResult.new()
	result.item_metrics = {
		"apartment__plaid": {
			"eligible_runs": 1,
			"acquired_runs": 1,
			"acquisition_rate": 1.0,
			"considered_after_purchase": 2,
			"used_after_purchase": 3,
			"positive_effect_count": 2,
			"requirement_unlock_count": 1,
			"use_per_acquisition": 3.0,
			"positive_effect_per_acquisition": 2.0,
			"unlock_per_acquisition": 1.0,
		},
	}
	var csv: String = ProgressionLabExporter.new()._item_csv(result.item_metrics)
	_ok("item csv has times_selected", csv.find("times_selected") >= 0)
	_ok("item csv apartment row", csv.find("apartment__plaid") >= 0)
	var lines: PackedStringArray = csv.split("\n")
	var header: PackedStringArray = lines[0].split(",")
	var selected_idx: int = -1
	for i in range(header.size()):
		if header[i] == "times_selected":
			selected_idx = i
	_ok("times_selected column", selected_idx >= 0)
	if lines.size() > 1 and selected_idx >= 0:
		var cols: PackedStringArray = lines[1].split(",")
		_ok("apartment selected non-zero", int(cols[selected_idx]) > 0, lines[1])


func _test_predictive_story_barrier() -> void:
	var executor := StageExecutor.new()
	_ok("9+5 allowed", not executor.is_predictive_story_barrier_blocked(9, 15, 5, false))
	_ok("10+5 blocked", executor.is_predictive_story_barrier_blocked(10, 15, 5, false))
	_ok("10+5 allowed after barrier", not executor.is_predictive_story_barrier_blocked(10, 15, 5, true))
	var captured: Dictionary = _as_dict(PlaythroughSession.new().run(func() -> Dictionary:
		var payload: Dictionary = {}
		_advance_to_stage(2)
		var local: StageExecutor = _fresh_executor()
		local.test_max_possible_relationship_gain = 5
		var plan := StagePlan.new()
		plan.stage = 2
		plan.story_girl_id = GirlCatalog.ID_VIKA
		var girls: Variant = _root("GirlsService")
		if girls != null:
			girls.discover_girl(plan.story_girl_id)
			girls.give_contact(plan.story_girl_id)
			var rel_max: int = int(girls.get_relationship_max(plan.story_girl_id))
			var target: int = maxi(rel_max - 5, 0)
			girls.change_relationship(plan.story_girl_id, target - int(girls.get_relationship(plan.story_girl_id)))
			payload["rel"] = int(girls.get_relationship(plan.story_girl_id))
			payload["rel_max"] = rel_max
		payload["blocked"] = local._story_date_blocked_by_barrier(plan, plan.story_girl_id, "STORY", &"casual", &"cafe")
		payload["gain"] = local.get_max_possible_relationship_gain({"girl_id": plan.story_girl_id, "outfit_id": &"casual", "venue_id": &"cafe"})
		return payload
	))
	_ok("forced gain is 5", int(captured.get("gain", 0)) == 5, str(captured.get("gain", 0)))
	_ok("story date blocked by predictive helper", bool(captured.get("blocked", false)), JSON.stringify(captured))

func _test_apartment_source_mapping() -> void:
	var captured: Dictionary = _as_dict(PlaythroughSession.new().run(func() -> Dictionary:
		var payload: Dictionary = {"error_text": "", "count": 0}
		var executor: StageExecutor = _fresh_executor()
		var dating: Variant = _root("DatingService")
		if dating == null:
			payload["error_text"] = "DatingService missing"
			return payload
		var catalog: DateContentCatalog = dating.get_catalog_service().catalog
		var errors: PackedStringArray = PackedStringArray()
		for item in catalog.local_objects:
			if item == null or not String(item.id).begins_with("apartment__"):
				continue
			var object_id: StringName = item.id
			var local_object: DateLocalObject = catalog.find_local_object(object_id)
			if local_object == null:
				errors.append("missing object %s" % String(object_id))
				continue
			for move_id in local_object.move_ids:
				payload["count"] = int(payload["count"]) + 1
				var source: Dictionary = executor.resolve_item_source_from_move(move_id)
				var error: String = str(source.get("error", ""))
				if not error.is_empty():
					errors.append("%s %s" % [String(move_id), error])
				elif str(source.get("source_type", "")) != "APARTMENT_OBJECT":
					errors.append("%s type %s" % [String(move_id), str(source.get("source_type", ""))])
				elif str(source.get("source_id", "")) != String(object_id):
					errors.append("%s wrong object %s" % [String(move_id), str(source.get("source_id", ""))])
		payload["error_text"] = "\n".join(errors)
		return payload
	))
	_ok("apartment moves mapped", int(captured.get("count", 0)) > 0, JSON.stringify(captured))
	_ok("apartment mapping clean", str(captured.get("error_text", "x")).is_empty(), str(captured.get("error_text", "")))


func _test_seed_98_barrier_pacing() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 98, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	_ok("seed 98 ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var summary: ProgressionLabRunRecord = runner.get_result().records[0]
	_ok("seed 98 no premature stage", summary.hard_warnings.find("STAGE_TRANSITION_INVARIANT") < 0, ",".join(summary.hard_warnings))
	var tail_days: int = int(summary.campaign_metrics.get("days_after_last_date_before_stage_completion", 99))
	_ok("seed 98 no long post-date tail", tail_days <= 9, str(tail_days))
	var stale: int = int(summary.campaign_metrics.get("stale_planned_goal_count", 99))
	_ok("seed 98 stale exported", summary.campaign_metrics.has("stale_planned_goal_count"), str(stale))
	var acquisitions: Variant = summary.campaign_metrics.get("build_acquisitions", [])
	var useful: bool = false
	if acquisitions is Array:
		for row in acquisitions:
			if row is Dictionary and int(row.get("remaining_stage_dates_at_acquisition", 0)) > 0:
				useful = true
	_ok("seed 98 build while dates remain or none", useful or (acquisitions is Array and (acquisitions as Array).is_empty()), JSON.stringify(acquisitions))


func _test_seed_32_characteristic_build() -> void:
	var config := ProgressionLabConfig.new()
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 32, 4, ProgressionLabConfig.MODE_POPULATION)
	while not runner.process_batch():
		pass
	_ok("seed 32 ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var summary: ProgressionLabRunRecord = runner.get_result().records[0]
	var metrics: Dictionary = summary.campaign_metrics
	for key in ["work_actions_for_characteristics", "work_actions_for_outfits", "work_actions_for_apartment", "work_actions_for_dates", "work_actions_for_rivals"]:
		_ok("seed 32 has %s" % key, metrics.has(key))
	var attributed: int = int(metrics.get("work_actions_for_characteristics", 0))
	attributed += int(metrics.get("work_actions_for_outfits", 0))
	attributed += int(metrics.get("work_actions_for_apartment", 0))
	attributed += int(metrics.get("work_actions_for_dates", 0))
	attributed += int(metrics.get("work_actions_for_rivals", 0))
	attributed += int(metrics.get("work_actions_for_other", 0))
	_ok("seed 32 work fully attributed", attributed == int(metrics.get("work_actions", -1)), "%d vs %d" % [attributed, int(metrics.get("work_actions", -1))])
	_ok("seed 32 build acquisitions present", metrics.get("build_acquisitions", []) is Array)
	_ok("seed 32 post-date tail present", metrics.has("days_after_last_date_before_stage_completion"))


func _find_candidate(candidates: Array, kind: String, girl_id: StringName = &"") -> StageExecutor.Candidate:
	for raw in candidates:
		if raw == null:
			continue
		var candidate: StageExecutor.Candidate = raw
		if candidate.kind != kind:
			continue
		if girl_id != &"" and candidate.girl_id != girl_id:
			continue
		return candidate
	return null

func _run_rival_cash_probe(rival_id: StringName, linked_girl_id: StringName, is_story: bool, stage: int) -> Dictionary:
	var session := PlaythroughSession.new()
	return _as_dict(session.run(func() -> Dictionary:
		var payload: Dictionary = {}
		_discover_rival_for_challenge(rival_id, linked_girl_id, stage)
		var executor: StageExecutor = _fresh_executor()
		var plan := StagePlan.new()
		plan.stage = stage
		if is_story:
			plan.story_girl_id = linked_girl_id
			plan.story_rival_id = rival_id
		else:
			plan.target_ordinary_rival_ids.append(rival_id)
		var intent: Dictionary = executor.evaluate_rival_intent(rival_id, is_story)
		payload["intent"] = intent
		payload["unmet"] = executor._unmet_goals(plan).has(str(intent.get("goal_id", "")))
		var required: int = int(intent.get("required_money", 100))
		_set_money(maxi(required - 40, 0))
		var blocked: Array = executor._collect_candidates(plan)
		var snapshot: Dictionary = executor.collect_blocking_snapshot(plan)
		var work: StageExecutor.Candidate = _find_candidate(blocked, "work")
		payload["has_work"] = work != null
		payload["work_goal"] = work.goal_id if work != null else ""
		payload["work_action"] = work.supporting_action_id if work != null else ""
		payload["has_fight_blocked"] = _has_kind(blocked, "rival_fight")
		payload["has_cash"] = false
		payload["cash_matches_intent"] = false
		for row in snapshot.get("cash_dependencies", []):
			if not (row is Dictionary):
				continue
			if str(row.get("goal_id", "")) != str(intent.get("goal_id", "")):
				continue
			payload["has_cash"] = true
			payload["cash_matches_intent"] = int(row.get("required_money", -1)) == required and str(row.get("action_id", "")) == str(intent.get("production_action_id", ""))
		_set_money(required)
		var funded: Array = executor._collect_candidates(plan)
		var fight: StageExecutor.Candidate = null
		for raw in funded:
			if raw == null:
				continue
			var candidate: StageExecutor.Candidate = raw
			if candidate.kind == "rival_fight" and candidate.rival_id == rival_id:
				fight = candidate
				break
		payload["has_fight"] = fight != null
		var competitions: Variant = _root("CompetitionService")
		if competitions != null:
			competitions.set_forced_won(true)
		var fight_ok: bool = false
		if fight != null:
			var executed: StageExecutor.ExecutionResult = executor._execute_candidate(fight, plan)
			fight_ok = executed != null and executed.success
		payload["fight_ok"] = fight_ok
		payload["complete_after"] = executor.is_rival_goal_complete(str(intent.get("goal_id", "")), rival_id)
		var after: Array = executor._collect_candidates(plan)
		var has_direct: bool = false
		for raw_after in after:
			if raw_after == null:
				continue
			var later: StageExecutor.Candidate = raw_after
			if later.rival_id == rival_id and (later.kind == "rival_fight" or later.kind == "rival_meet"):
				has_direct = true
		payload["no_after"] = not has_direct
		return payload
	, 1))


func _discover_rival_for_challenge(rival_id: StringName, linked_girl_id: StringName, stage: int) -> void:
	_advance_to_stage(stage)
	var girls: Variant = _root("GirlsService")
	if girls != null and linked_girl_id != &"":
		girls.discover_girl(linked_girl_id)
		girls.give_contact(linked_girl_id)
	var rivals: Variant = _root("RivalsService")
	if rivals != null:
		rivals.discover_rival(rival_id)
	var world: Variant = _root("WorldService")
	var definition: RivalDefinition = rivals.get_definition(rival_id) if rivals != null else null
	if world != null and definition != null:
		world.enter_location(definition.location_id)
	if stage >= 2:
		var equipment: Variant = _root("EquipmentService")
		if equipment != null:
			equipment.add_owned_outfit(OutfitCatalog.ID_BUSINESS)


func _set_money(amount: int) -> void:
	var economy: Variant = _root("EconomyService")
	if economy == null:
		return
	var current: int = int(economy.get_money())
	if current > amount:
		economy.spend_money(current - amount)
	elif current < amount:
		economy.add_money(amount - current)


func _nouseful_from_rival_money(record: ProgressionLabRunRecord) -> bool:
	if record == null or not record.stop_reason.begins_with("NO_USEFUL_ACTIONS_STAGE_"):
		return false
	for row in record.diagnostic_snapshot.get("cash_dependencies", []):
		if not (row is Dictionary):
			continue
		var action_type: String = str(row.get("action_type", ""))
		if action_type == "RIVAL_CHALLENGE" or action_type == "RIVAL_MEET":
			return int(row.get("cash_gap", 0)) > 0
	return str(record.diagnostic_snapshot.get("last_rival_action_failure", "")) == "INSUFFICIENT_MONEY"


func _candidates_of_rival(candidates: Array, rival_id: StringName) -> Array:
	var filtered: Array = []
	for raw in candidates:
		if raw == null:
			continue
		var candidate: StageExecutor.Candidate = raw
		if candidate.rival_id == rival_id:
			filtered.append(candidate)
	return filtered


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


func _root(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _current_stage() -> int:
	var stages: Variant = _root("StageService")
	if stages == null:
		return 0
	return int(stages.get_current_stage())


func _advance_to_stage(target: int) -> void:
	var stages: Variant = _root("StageService")
	if stages == null:
		return
	while int(stages.get_current_stage()) < target:
		if not bool(stages.force_complete_current_stage_for_dev()):
			break


func _first_dressed_id() -> StringName:
	var equipment: Variant = _root("EquipmentService")
	if equipment == null:
		return &""
	var catalog: Variant = equipment.get_catalog()
	if catalog == null:
		return &""
	for outfit in catalog.get_all_outfits():
		if outfit != null and int(outfit.tier) >= 1:
			return outfit.id
	return &""


func _fresh_executor() -> StageExecutor:
	var executor := StageExecutor.new()
	executor.config = ProgressionLabConfig.new()
	executor.profile = PlayerProfile.generate(executor.config, ProgressionRng.make(1, ProgressionRng.STREAM_PROFILE), ProgressionLabConfig.ARCHETYPE_TYPICAL, 0.0)
	executor.interests = CampaignInterests.generate(ProgressionRng.make(1, ProgressionRng.STREAM_CAMPAIGN_INTEREST))
	executor._campaign = ProgressionLabMetrics.new()
	executor._current_stage_metrics = ProgressionLabMetrics.new()
	executor._execution_rng = RandomNumberGenerator.new()
	executor._execution_rng.seed = 1
	executor._date_rng = RandomNumberGenerator.new()
	executor._date_rng.seed = 1
	executor._run_base_seed = 1
	executor._date_policy = DateDecisionPolicy.new()
	executor._date_policy.config = executor.config
	executor._date_policy.profile = executor.profile
	executor._date_policy.interests = executor.interests
	executor._date_policy.rng = executor._date_rng
	executor._date_policy.consume_rng = false
	executor.detailed = true
	return executor


func _has_kind(candidates: Array, kind: String, girl_id: StringName = &"") -> bool:
	for raw in candidates:
		if raw == null:
			continue
		var candidate: StageExecutor.Candidate = raw
		if candidate.kind != kind:
			continue
		if girl_id != &"" and candidate.girl_id != girl_id:
			continue
		return true
	return false


func _probe_date_loadout(grant_dressed: bool) -> Dictionary:
	_advance_to_stage(2)
	var dressed_id: StringName = _first_dressed_id()
	var equipment: Variant = _root("EquipmentService")
	if grant_dressed and equipment != null and dressed_id != &"":
		equipment.add_owned_outfit(dressed_id)
	if equipment != null:
		equipment.equip_outfit(OutfitCatalog.START_OUTFIT_ID)
	var equipped_before: String = String(equipment.get_current_outfit_id()) if equipment != null else ""
	var economy: Variant = _root("EconomyService")
	if economy != null:
		economy.add_money(500)
	var world: Variant = _root("WorldService")
	if world != null:
		world.unlock_date_venue(&"apartment")
		world.unlock_date_venue(&"cafe")
	var girl_id: StringName = GirlCatalog.ID_KATYA
	var girls: Variant = _root("GirlsService")
	if girls != null:
		girls.discover_girl(girl_id)
		girls.give_contact(girl_id)
	var executor: StageExecutor = _fresh_executor()
	var plan := StagePlan.new()
	plan.stage = 2
	plan.target_filler_girl_ids.append(girl_id)
	if not grant_dressed:
		plan.target_outfit_count = 1
		if dressed_id != &"":
			plan.target_outfit_ids.append(dressed_id)
	var eval_outfit: StringName = dressed_id if grant_dressed else OutfitCatalog.START_OUTFIT_ID
	var eligibility: Dictionary = executor.evaluate_date_candidate(girl_id, eval_outfit, &"cafe")
	var candidates: Array = executor._collect_candidates(plan)
	var kinds: PackedStringArray = PackedStringArray()
	var date_candidate: StageExecutor.Candidate = null
	for raw in candidates:
		if raw == null:
			continue
		var candidate: StageExecutor.Candidate = raw
		kinds.append(candidate.kind)
		if candidate.kind == "date" and candidate.girl_id == girl_id:
			date_candidate = candidate
	var executed: bool = false
	var failure: String = ""
	var rel_before: int = int(girls.get_relationship(girl_id)) if girls != null else 0
	var rel_after: int = rel_before
	var date_delta: int = 0
	var rel_max: int = int(girls.get_relationship_max(girl_id)) if girls != null else 0
	if date_candidate != null:
		var result: StageExecutor.ExecutionResult = executor._execute_candidate(date_candidate, plan)
		executed = result.success
		failure = result.failure_reason
		rel_after = int(girls.get_relationship(girl_id)) if girls != null else rel_before
		if not executor._date_summaries.is_empty() and executor._date_summaries[0] is Dictionary:
			date_delta = int(executor._date_summaries[0].get("score", 0))
	var selected_dressed: bool = false
	if date_candidate != null and equipment != null:
		selected_dressed = int(equipment.get_outfit_tier(equipment.get_catalog().get_outfit(date_candidate.outfit_id))) >= 1
	return {
		"owned_dressed": grant_dressed and dressed_id != &"",
		"equipped": equipped_before,
		"eligible": bool(eligibility.get("eligible", false)),
		"reason": str(eligibility.get("reason", "")),
		"has_date": date_candidate != null,
		"selected_dressed": selected_dressed,
		"outfit_id": String(date_candidate.outfit_id) if date_candidate != null else "",
		"executed": executed,
		"failure": failure,
		"rel_before": rel_before,
		"rel_after": rel_after,
		"rel_changed": rel_after != rel_before,
		"date_delta": date_delta,
		"expected_rel": mini(rel_before + date_delta, rel_max) if rel_max > 0 else rel_before + date_delta,
		"kinds": Array(kinds),
		"has_support": _has_kind(candidates, "work") or _has_kind(candidates, "buy_outfit"),
	}
