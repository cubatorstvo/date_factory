extends SceneTree


func _init() -> void:
	var service := DateCatalogService.new()
	var catalog: DateContentCatalog = service.load_catalog()
	if catalog == null:
		printerr("PLAYTEST: catalog load failed")
		quit(1)
		return
	var issues: Array[ContentValidationIssue] = ContentValidator.new().validate(catalog)
	print("CONTENT VALIDATION: %d issues" % issues.size())
	var has_error: bool = false
	for issue in issues:
		var data: Dictionary = issue.to_dictionary()
		printerr("%s | %s | %s | %s | %s | %s" % [
			data["severity"],
			data["code"],
			issue.resource_type,
			issue.resource_id,
			issue.field,
			issue.message,
		])
		if issue.severity == DateTypes.ValidationSeverity.ERROR:
			has_error = true
	if has_error:
		quit(1)
		return
	var store := DateProgressStore.new()
	store.reset_all(catalog)
	_play_girl(catalog, store, &"alina", "Алина 1")
	_play_girl(catalog, store, &"alina", "Алина 2")
	_ok("Alina secondary revealed after first date", store.get_girl_progress(&"alina", catalog.find_girl(&"alina")).secondary_revealed)
	_play_girl(catalog, store, &"vika", "Вика 1")
	_play_girl(catalog, store, &"vika", "Вика 2")
	var locked: TestPlayerState = store.player_state
	locked.muscle = 0
	var unlocked: TestPlayerState = TestPlayerState.from_dictionary(locked.to_dictionary())
	unlocked.muscle = 4
	_ok("locked punch", not _punch_available(catalog, locked))
	_ok("unlocked punch", _punch_available(catalog, unlocked))
	store.reset_girl(catalog.find_girl(&"alina"))
	var reset: GirlProgress = store.get_girl_progress(&"alina", catalog.find_girl(&"alina"))
	_ok("reset girl", reset.completed_dates == 0 and reset.relationship == 0)
	store.reset_all(catalog)
	print("PLAYTEST LOOP OK")
	quit(0)


func _play_girl(catalog: DateContentCatalog, store: DateProgressStore, girl_id: StringName, title: String) -> void:
	var progress: GirlProgress = store.get_girl_progress(girl_id, catalog.find_girl(girl_id))
	var engine := DateEngine.new()
	var config := DateSessionConfig.new()
	config.catalog = catalog
	config.girl_id = girl_id
	config.location_id = &"park"
	config.outfit_id = &"business"
	config.seed = Time.get_ticks_msec()
	config.girl_progress = progress
	config.player_state = store.player_state
	store.capture_replay(config.seed, girl_id, config.location_id, config.outfit_id, progress)
	engine.create_date_session(config)
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		var move_id: StringName = &""
		for option in engine.get_available_moves():
			if option.is_selectable():
				move_id = option.move_id
				print("%s / %s / [%s] %s" % [
					title,
					DateTypes.phase_name(engine.get_session_state().current_phase),
					option.tag_display_name,
					DateTypes.knowledge_label(option.tag_knowledge),
				])
				break
		engine.choose_move(move_id)
		engine.advance()
	var result: DateRunResult = engine.get_result()
	print("%s RESULT total=%d rel=%d→%d secondary=%s" % [
		title,
		result.score_breakdown.total,
		engine.get_session_state().relationship_before,
		engine.get_session_state().relationship_after,
		result.secondary_live_text,
	])
	store.save_store()


func _punch_available(catalog: DateContentCatalog, player: TestPlayerState) -> bool:
	var engine := DateEngine.new()
	var config := DateSessionConfig.new()
	config.catalog = catalog
	config.girl_id = &"alina"
	config.location_id = &"cafe"
	config.outfit_id = &"casual"
	config.seed = 8
	config.girl_progress = GirlProgress.new()
	config.girl_progress.reset_to_profile(catalog.find_girl(&"alina"))
	config.player_state = player
	engine.create_date_session(config)
	while engine.get_session_state().stage != DateSession.Stage.SHOWING_DATE_RESULT:
		if engine.get_session_state().stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
			engine.advance()
			continue
		var view: DateEpisodeView = engine.get_current_episode()
		if view != null and view.situation != null and view.situation.id == &"rival_provocation":
			for option in view.unlockable_options:
				if option.move_id == &"punch":
					return option.availability == DateTypes.MoveAvailability.AVAILABLE
		for option in engine.get_available_moves():
			if option.is_selectable():
				engine.choose_move(option.move_id)
				engine.advance()
				break
	return false


func _ok(title: String, condition: bool) -> void:
	if condition:
		print("PLAYTEST OK: %s" % title)
		return
	printerr("PLAYTEST FAIL: %s" % title)
	quit(1)
