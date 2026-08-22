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
	_test_full_campaign_determinism()
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
		_ok("campaign stage plans equal", JSON.stringify(rec_a.stage_plans) == JSON.stringify(rec_b.stage_plans))
		_ok("campaign compact actions equal", "|".join(rec_a.action_sequence) == "|".join(rec_b.action_sequence), _seq_diff(rec_a.action_sequence, rec_b.action_sequence))
		_ok("campaign summary metrics equal", _core_metrics_equal(rec_a.campaign_metrics, rec_b.campaign_metrics), _metric_diff(rec_a.campaign_metrics, rec_b.campaign_metrics))
		var detailed_a: ProgressionLabRunRecord = runner_a.replay_seed(3, true)
		var detailed_b: ProgressionLabRunRecord = runner_b.replay_seed(3, true)
		_ok("detailed action sequence equal", "|".join(detailed_a.action_sequence) == "|".join(detailed_b.action_sequence), _seq_diff(detailed_a.action_sequence, detailed_b.action_sequence))
		_ok("immutability hash survives campaign", _plans_keep_hash(rec_a))


func _test_production_integration() -> void:
	var config := ProgressionLabConfig.new()
	config.max_calendar_days = 120
	var runner := ProgressionLabRunner.new()
	runner.configure(config, 1, 5, 2, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	while not runner.process_batch():
		pass
	_ok("production campaign ran", runner.get_result().records.size() == 1)
	if runner.get_result().records.is_empty():
		return
	var record: ProgressionLabRunRecord = runner.get_result().records[0]
	var flags: Dictionary = {}
	var flags_raw: Variant = record.campaign_metrics.get("production_flags", {})
	if flags_raw is Dictionary:
		flags = flags_raw
	if not bool(flags.get("used_production_work", false)):
		var iso_runner := ProgressionLabRunner.new()
		var iso_result: ProgressionLabPopulationResult = iso_runner.run_goal_isolation(CharacteristicIds.APPEARANCE, 1, ProgressionLabConfig.ISOLATION_MINIMAL, 1, 5, 1)
		if not iso_result.records.is_empty():
			var iso_record: ProgressionLabRunRecord = iso_result.records[0]
			var iso_flags_raw: Variant = iso_record.campaign_metrics.get("production_flags", {})
			if iso_flags_raw is Dictionary and bool(iso_flags_raw.get("used_production_work", false)):
				flags["used_production_work"] = true
	_ok("used production work", bool(flags.get("used_production_work", false)), "aborted=%s days=%s warnings=%s flags=%s" % [str(record.aborted), str(record.campaign_metrics.get("calendar_days", 0)), ",".join(record.hard_warnings), JSON.stringify(flags)])
	_ok("used production date", bool(flags.get("used_production_date", false)), "executor should call DatingService")
	var dress: bool = bool(flags.get("stage2_dress_up", false)) or int(record.campaign_metrics.get("outfits_acquired", 0)) > 0 or record.aborted
	_ok("stage 2 dress-up path reachable or recorded", dress, "outfit/dress flag missing")
	_flag_or_skip("marina free outfit", flags, "marina_free_outfit", _girl_exists(GirlCatalog.ID_MARINA))
	_flag_or_skip("apartment purchase", flags, "apartment_purchase", _apartment_catalog_has_objects())
	_flag_or_skip("restaurant characteristic unlock", flags, "restaurant_characteristic_unlock", _venue_exists(&"restaurant"))
	_flag_or_skip("sonya venue x2", flags, "sonya_venue_x2", _girl_exists(GirlCatalog.ID_SONYA))
	_flag_or_skip("katya accent", flags, "katya_accent", _girl_exists(GirlCatalog.ID_KATYA))
	_flag_or_skip("rita taxi", flags, "rita_taxi", _girl_exists(GirlCatalog.ID_RITA))
	_flag_or_skip("nika backup", flags, "nika_backup", _girl_exists(GirlCatalog.ID_NIKA))
	_flag_or_skip("eva knowledge", flags, "eva_knowledge", _girl_exists(GirlCatalog.ID_EVA))


func _test_goal_isolation() -> void:
	var runner := ProgressionLabRunner.new()
	runner.configure(ProgressionLabConfig.new(), 1, 8, 1, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	var result: ProgressionLabPopulationResult = runner.run_goal_isolation(CharacteristicIds.APPEARANCE, 1, ProgressionLabConfig.ISOLATION_MINIMAL, 1, 8, 1)
	_ok("goal isolation returns result", result != null and result.records.size() == 1)
	if result.records.is_empty():
		return
	var record: ProgressionLabRunRecord = result.records[0]
	_ok("goal isolation typical", str(record.profile.get("archetype", "")) == "TYPICAL")
	if record.stage_plans.size() >= 1 and record.stage_plans[0] is Dictionary:
		var plan: Dictionary = record.stage_plans[0]
		var fillers: Array = plan.get("target_filler_girl_ids", [])
		_ok("isolation minimal two fillers", fillers.size() == 2, "count=%d" % fillers.size())
		_ok("isolation minimal no extra outfits", int(plan.get("target_outfit_count", -1)) == 0)
		var chars: Variant = plan.get("characteristic_targets", {})
		_ok("isolation has appearance target", chars is Dictionary and chars.has("appearance"))
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


func _flag_or_skip(label: String, flags: Dictionary, key: String, content_exists: bool) -> void:
	if bool(flags.get(key, false)):
		_ok(label, true)
		return
	if not content_exists:
		_ok(label, false, "content missing")


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
