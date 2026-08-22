class_name ProgressionLabRunner
extends RefCounted

signal batch_progress(completed: int, total: int, runs_per_second: float, elapsed_sec: float, remaining_sec: float)

var config: ProgressionLabConfig
var n: int = 1000
var base_seed_start: int = 1
var end_story_stage: int = 4
var archetype_mode: StringName = ProgressionLabConfig.MODE_POPULATION

var _cancelled: bool = false
var _completed: int = 0
var _started_usec: int = 0
var _result: ProgressionLabPopulationResult
var _session: PlaythroughSession
var _analyzer: ProgressionLabAnalyzer
var _exporter: ProgressionLabExporter
var _configured: bool = false


func configure(p_config: ProgressionLabConfig, p_n: int, p_base_seed_start: int, p_end_story_stage: int, p_archetype_mode: StringName) -> void:
	config = p_config if p_config != null else ProgressionLabConfig.new()
	n = maxi(1, p_n)
	base_seed_start = p_base_seed_start
	end_story_stage = clampi(p_end_story_stage, 1, 4)
	archetype_mode = p_archetype_mode
	_cancelled = false
	_completed = 0
	_started_usec = Time.get_ticks_usec()
	_result = ProgressionLabPopulationResult.new()
	_result.schema_version = config.schema_version
	_result.simulation_version = simulation_version()
	_result.config = config.to_dict()
	_result.n = n
	_result.base_seed_start = base_seed_start
	_result.end_story_stage = end_story_stage
	_result.archetype_mode = archetype_mode
	_session = PlaythroughSession.new()
	_analyzer = ProgressionLabAnalyzer.new()
	_exporter = ProgressionLabExporter.new()
	_configured = true


func process_batch() -> bool:
	if not _configured:
		configure(ProgressionLabConfig.new(), n, base_seed_start, end_story_stage, archetype_mode)
	if _cancelled or _completed >= n:
		_finish_if_needed()
		return true
	var batch: int = mini(config.batch_size, n - _completed)
	for _i in range(batch):
		if _cancelled:
			break
		var seed: int = base_seed_start + _completed
		var record: ProgressionLabRunRecord = _run_seed(seed, false)
		_result.records.append(record)
		_completed += 1
		_emit_progress()
	if _completed >= n or _cancelled:
		_finish_if_needed()
		return true
	return false


func cancel() -> void:
	_cancelled = true


func get_result() -> ProgressionLabPopulationResult:
	return _result


func replay_seed(base_seed: int, detailed: bool) -> ProgressionLabRunRecord:
	if config == null:
		config = ProgressionLabConfig.new()
	if _session == null:
		_session = PlaythroughSession.new()
	return _run_seed(base_seed, detailed)


func begin_goal_isolation(
	characteristic_id: StringName,
	milestone: int,
	isolation_mode: StringName,
	p_n: int = 1000,
	p_base_seed_start: int = 1,
	p_end_story_stage: int = 4
) -> void:
	var isolation_config: ProgressionLabConfig = config if config != null else ProgressionLabConfig.new()
	configure(isolation_config, p_n, p_base_seed_start, p_end_story_stage, ProgressionLabConfig.ARCHETYPE_TYPICAL)
	_result.isolation = {
		"characteristic_id": String(characteristic_id),
		"milestone": milestone,
		"mode": String(isolation_mode),
	}


func run_goal_isolation(
	characteristic_id: StringName,
	milestone: int,
	isolation_mode: StringName,
	p_n: int = 1000,
	p_base_seed_start: int = 1,
	p_end_story_stage: int = 4
) -> ProgressionLabPopulationResult:
	begin_goal_isolation(characteristic_id, milestone, isolation_mode, p_n, p_base_seed_start, p_end_story_stage)
	while not process_batch():
		pass
	return _result


func export_full_statistics(directory: String = "") -> String:
	var detailed: Dictionary = _replay_export_seeds()
	return _exporter.export_full_statistics(_result, directory, detailed)


func export_bad_seeds_only(directory: String = "") -> String:
	var detailed: Dictionary = _replay_export_seeds()
	return _exporter.export_bad_seeds_only(_result, directory, detailed)


func export_specific_seed(base_seed: int, directory: String = "") -> String:
	var record: ProgressionLabRunRecord = replay_seed(base_seed, true)
	if _result == null:
		_result = ProgressionLabPopulationResult.new()
		_result.schema_version = 1
		_result.simulation_version = simulation_version()
		_result.config = config.to_dict() if config != null else {}
	return _exporter.export_specific_seed(record, _result, directory)


func simulation_version() -> String:
	var output: Array = []
	var code: int = OS.execute("git", PackedStringArray(["rev-parse", "--short", "HEAD"]), output, true, false)
	if code != 0 or output.is_empty():
		return ""
	return str(output[0]).strip_edges()


func _run_seed(base_seed: int, p_detailed: bool) -> ProgressionLabRunRecord:
	var captured: Array = []
	_session.run(func() -> void:
		var jitter: float = config.trait_jitter
		if not _result.isolation.is_empty():
			jitter = 0.0
		var profile_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.STREAM_PROFILE)
		var mode: StringName = archetype_mode
		if not _result.isolation.is_empty():
			mode = ProgressionLabConfig.ARCHETYPE_TYPICAL
		var profile: PlayerProfile = PlayerProfile.generate(config, profile_rng, mode, jitter)
		var interest_rng: RandomNumberGenerator = ProgressionRng.make(base_seed, ProgressionRng.STREAM_CAMPAIGN_INTEREST)
		var interests: CampaignInterests = CampaignInterests.generate(interest_rng)
		var executor := StageExecutor.new()
		executor.config = config
		executor.profile = profile
		executor.interests = interests
		executor.detailed = p_detailed
		if not _result.isolation.is_empty():
			executor.isolation_mode = StringName(str(_result.isolation.get("mode", "")))
			executor.isolation_characteristic_id = StringName(str(_result.isolation.get("characteristic_id", "")))
			executor.isolation_milestone = int(_result.isolation.get("milestone", 0))
		captured.append(executor.execute_run(base_seed, end_story_stage))
	)
	if captured.is_empty():
		var empty := ProgressionLabRunRecord.new()
		empty.base_seed = base_seed
		empty.aborted = true
		empty.hard_warnings.append("ISOLATION_FAILED")
		return empty
	return captured[0]


func _replay_export_seeds() -> Dictionary:
	var detailed: Dictionary = {}
	for row in _result.bad_seeds:
		var seed: int = int(row.get("seed", 0))
		detailed[seed] = replay_seed(seed, true)
	for key in _result.representative_seeds.keys():
		var row: Variant = _result.representative_seeds[key]
		if row is Dictionary:
			var seed: int = int(row.get("seed", 0))
			if not detailed.has(seed):
				detailed[seed] = replay_seed(seed, true)
	return detailed


func _finish_if_needed() -> void:
	if _result == null:
		return
	_analyzer.analyze(_result, config)
	var elapsed: float = float(Time.get_ticks_usec() - _started_usec) / 1000000.0
	_result.performance = {
		"runs_per_second": float(_completed) / maxf(elapsed, 0.001),
		"mean_ms_per_run": (elapsed * 1000.0) / float(maxi(_completed, 1)),
		"total_elapsed": elapsed,
	}
	_emit_progress()


func _emit_progress() -> void:
	var elapsed: float = float(Time.get_ticks_usec() - _started_usec) / 1000000.0
	var rate: float = float(_completed) / maxf(elapsed, 0.001)
	var remaining: float = 0.0
	if rate > 0.0:
		remaining = float(n - _completed) / rate
	batch_progress.emit(_completed, n, rate, elapsed, remaining)
