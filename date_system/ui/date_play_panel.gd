class_name DatePlayPanel
extends Control

signal status_message(text: String)
signal playthrough_finished

var catalog_service: DateCatalogService
var progress_store: DateProgressStore
var validator: ContentValidator = ContentValidator.new()

var _engine: DateEngine
var _girl_id: StringName = &"alina"
var _venue_id: StringName = &"cafe"
var _outfit_id: StringName = &"casual"
var _forced_situation_id: StringName = &""
var _seed: int = 1
var _grant_tv: bool = false

var _scroll: ScrollContainer
var _host: VBoxContainer
var _debug_body: VBoxContainer
var _debug_open: bool = false
var _rebuild_pending: bool = false
var _tally_lines: Array[Control] = []
var _tally_index: int = 0
var _tally_box: VBoxContainer
var _tally_footer: Control
var _result_tweens: Array[Tween] = []
var _playthrough: bool = false
var _open_source: int = -1


func setup(p_catalog: DateCatalogService, p_store: DateProgressStore) -> void:
	catalog_service = p_catalog
	progress_store = p_store
	if is_node_ready():
		rebuild()

func get_lab_outfit_id() -> StringName:
	return _outfit_id


func set_lab_outfit_id(outfit_id: StringName) -> void:
	_outfit_id = outfit_id
	rebuild()


func apply_lab_source_used(characteristic_used: bool, outfit_used: bool, venue_used: bool) -> void:
	if _engine == null:
		return
	var session: DateSession = _engine.get_session_state()
	if session == null:
		return
	session.characteristic_source_used = characteristic_used
	session.outfit_source_used = outfit_used
	session.venue_source_used = venue_used
	if venue_used:
		session.venue_source_uses = maxi(session.venue_source_limit, 1)
	else:
		session.venue_source_uses = 0
	_open_source = -1
	rebuild()


func attach_playthrough(engine: DateEngine, catalog: DateCatalogService) -> void:
	_playthrough = true
	_engine = engine
	catalog_service = catalog
	if engine != null and engine.get_session_state() != null:
		_girl_id = engine.get_session_state().girl_id
	if is_node_ready():
		rebuild()


func _persist() -> void:
	if _playthrough:
		return
	if progress_store == null:
		return
	progress_store.save_store()


func _session_progress(girl_id: StringName) -> GirlProgress:
	if _engine != null and _engine.girl_progress() != null:
		return _engine.girl_progress()
	var girl: GirlProfile = _catalog().find_girl(girl_id)
	if progress_store != null:
		return progress_store.get_girl_progress(girl_id, girl)
	var progress := GirlProgress.new()
	progress.reset_to_profile(girl)
	return progress


func _finish_playthrough() -> void:
	var run: DateRunResult = null
	if _engine != null:
		run = _engine.get_result()
	var result: DateResult = DateResult.from_run_result(run)
	if result.girl_id == &"" and _engine != null and _engine.get_session_state() != null:
		result.girl_id = _engine.get_session_state().girl_id
	var dating: Variant = _dating_service()
	if dating != null:
		dating.complete_date(result)
	playthrough_finished.emit()


func _dating_service() -> Variant:
	var node: Node = get_node_or_null("/root/DatingService")
	if not is_instance_valid(node):
		return null
	return node

func _maybe_request_playthrough_guidance(view: DateEpisodeView) -> void:
	if not _playthrough:
		return
	var guidance: Variant = _guidance_service()
	if guidance == null:
		return
	guidance.request_tutorial(GuidanceCatalog.ID_DATING_INTRO)
	if view == null:
		return
	var has_local: bool = false
	for source_view in view.source_views:
		if source_view.source == DateTypes.DateMoveSource.VENUE and not source_view.options.is_empty():
			has_local = true
			break
	if has_local:
		guidance.request_tutorial(GuidanceCatalog.ID_LOCAL_OBJECTS_INTRO)
	for source_view in view.source_views:
		if source_view.source != DateTypes.DateMoveSource.CHARACTERISTIC:
			continue
		for option in source_view.options:
			if option.availability == DateTypes.MoveAvailability.LOCKED:
				guidance.request_tutorial(GuidanceCatalog.ID_LOCKED_MOVES_INTRO)
				return


func _guidance_service() -> Variant:
	var node: Node = get_node_or_null("/root/GuidanceService")
	if not is_instance_valid(node):
		return null
	return node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = LabUi.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_host = VBoxContainer.new()
	_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host.add_theme_constant_override("separation", 10)
	_scroll.add_child(_host)
	if catalog_service != null:
		rebuild()


func rebuild() -> void:
	if _host == null:
		return
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_rebuild_impl")


func _rebuild_impl() -> void:
	_rebuild_pending = false
	if _host == null or not is_instance_valid(_host):
		return
	for child in _host.get_children():
		_host.remove_child(child)
		child.queue_free()
	for line in _tally_lines:
		if is_instance_valid(line) and line.get_parent() == null:
			line.queue_free()
	if _tally_footer != null and is_instance_valid(_tally_footer) and _tally_footer.get_parent() == null:
		_tally_footer.queue_free()
	_tally_lines.clear()
	_tally_index = 0
	_tally_box = null
	_tally_footer = null
	for tw in _result_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_result_tweens.clear()
	if _engine != null and _engine.get_session_state() != null:
		var stage: DateSession.Stage = _engine.get_session_state().stage
		if stage == DateSession.Stage.SHOWING_DATE_RESULT or stage == DateSession.Stage.COMPLETED:
			_build_result()
			return
		if stage != DateSession.Stage.IDLE and stage != DateSession.Stage.ABORTED:
			_build_runner()
			return
	if _playthrough:
		var missing := Label.new()
		missing.text = "Свидание не удалось запустить."
		missing.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_host.add_child(missing)
		return
	_build_launch()


func _catalog() -> DateContentCatalog:
	return catalog_service.catalog


func _game_state() -> Variant:
	var node: Node = get_node("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
	return node


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		push_error("TimeService autoload missing")
	return node


func _stage_service() -> Variant:
	var node: Node = get_node_or_null("/root/StageService")
	if not is_instance_valid(node):
		push_error("StageService autoload missing")
	return node


func _build_launch() -> void:
	_host.add_child(LabUi.heading("Запуск свидания"))
	var gs: Variant = _game_state()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var stage: int = gs.story.stage
	if stages != null:
		stage = int(stages.get_current_stage())
	var run := Label.new()
	if clock != null:
		run.text = "День %d · %02d:%02d · Stage %d · Деньги %d" % [
			clock.get_day(),
			clock.get_hour(),
			clock.get_minute(),
			stage,
			gs.player.money,
		]
	else:
		run.text = "Stage %d · Деньги %d" % [stage, gs.player.money]
	_host.add_child(run)
	_host.add_child(_girl_card())
	var girl_sel := OptionButton.new()
	LabUi.fill_selector(girl_sel, _catalog().girls, _girl_id)
	girl_sel.item_selected.connect(func(index: int) -> void:
		_girl_id = girl_sel.get_item_metadata(index)
		rebuild()
	)
	_host.add_child(LabUi.labeled_row("Девушка", girl_sel))
	var loc_sel := OptionButton.new()
	LabUi.fill_selector(loc_sel, _catalog().date_venues, _venue_id)
	loc_sel.item_selected.connect(func(index: int) -> void:
		_venue_id = loc_sel.get_item_metadata(index)
		rebuild()
	)
	_host.add_child(LabUi.labeled_row("Место", loc_sel))
	var outfit_sel := OptionButton.new()
	LabUi.fill_selector(outfit_sel, _catalog().outfits, _outfit_id)
	outfit_sel.item_selected.connect(func(index: int) -> void:
		_outfit_id = outfit_sel.get_item_metadata(index)
		rebuild()
	)
	_host.add_child(LabUi.labeled_row("Одежда", outfit_sel))
	var sit_sel := OptionButton.new()
	sit_sel.add_item("(авто)")
	sit_sel.set_item_metadata(0, &"")
	var sit_index: int = 0
	for situation in _catalog().situations:
		if situation == null:
			continue
		sit_sel.add_item("%s [%s]" % [situation.display_name, String(situation.id)])
		var item_index: int = sit_sel.item_count - 1
		sit_sel.set_item_metadata(item_index, situation.id)
		if situation.id == _forced_situation_id:
			sit_index = item_index
	sit_sel.select(sit_index)
	sit_sel.item_selected.connect(func(index: int) -> void:
		_forced_situation_id = sit_sel.get_item_metadata(index)
		rebuild()
	)
	_host.add_child(LabUi.labeled_row("Situation override", sit_sel))
	var eligible_names: PackedStringArray = PackedStringArray()
	var preview_phase: DateTypes.DatePhase = DateTypes.DatePhase.OPENING
	var forced_sit: DateSituation = _catalog().find_situation(_forced_situation_id)
	if forced_sit != null and not forced_sit.allowed_phases.is_empty():
		preview_phase = forced_sit.allowed_phases[0] as DateTypes.DatePhase
	for situation in _catalog().eligible_situations(preview_phase, _venue_id, _girl_id):
		eligible_names.append(String(situation.id))
	var eligible_label := Label.new()
	eligible_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eligible_label.text = "Eligible %s: %s" % [DateTypes.phase_name(preview_phase), ", ".join(eligible_names)]
	_host.add_child(eligible_label)
	var girl_progress: GirlProgress = progress_store.get_girl_progress(_girl_id, _catalog().find_girl(_girl_id)) if progress_store != null else null
	var last_ids: PackedStringArray = PackedStringArray()
	if girl_progress != null:
		for situation_id in girl_progress.last_date_situation_ids:
			last_ids.append(String(situation_id))
	var last_label := Label.new()
	last_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	last_label.text = "last_date_situation_ids: %s" % (", ".join(last_ids) if not last_ids.is_empty() else "(пусто)")
	_host.add_child(last_label)

	var location: DateVenue = _catalog().find_venue(_venue_id)
	if location != null and location.uses_apartment_preparation:
		var prepared := CheckBox.new()
		prepared.text = "Подготовлена"
		prepared.button_pressed = progress_store.player_snapshot.apartment_prepared
		prepared.toggled.connect(func(pressed: bool) -> void:
			progress_store.player_snapshot.apartment_prepared = pressed
			progress_store.save_store()
		)
		_host.add_child(LabUi.labeled_row("Подготовка квартиры", prepared))
		var tv := CheckBox.new()
		tv.text = "Телевизор"
		tv.button_pressed = _grant_tv
		tv.toggled.connect(func(pressed: bool) -> void:
			_grant_tv = pressed
		)
		_host.add_child(LabUi.labeled_row("Локальный объект", tv))

	for stat in _catalog().characteristics:
		var spin := SpinBox.new()
		spin.min_value = stat.min_level
		spin.max_value = stat.max_level
		spin.value = progress_store.player_snapshot.get_stat(stat.id)
		var captured_id: StringName = stat.id
		spin.value_changed.connect(func(value: float) -> void:
			progress_store.player_snapshot.set_stat(captured_id, int(value))
			progress_store.save_store()
			rebuild()
		)
		_host.add_child(LabUi.labeled_row(stat.display_name, spin))

	_host.add_child(_lab_prep_preview())

	var seed_box := SpinBox.new()
	seed_box.min_value = 0
	seed_box.max_value = 999999999
	seed_box.value = _seed
	seed_box.value_changed.connect(func(value: float) -> void:
		_seed = int(value)
	)
	_host.add_child(LabUi.labeled_row("RNG seed", seed_box))

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	var start_btn := LabUi.button("НАЧАТЬ НОВОЕ СВИДАНИЕ")
	start_btn.pressed.connect(_start_new)
	buttons.add_child(start_btn)
	var replay_btn := LabUi.button("ПОВТОРИТЬ ПОСЛЕДНИЙ SEED")
	replay_btn.pressed.connect(_replay)
	buttons.add_child(replay_btn)
	_host.add_child(buttons)
	var reset_row := HBoxContainer.new()
	reset_row.add_theme_constant_override("separation", 8)
	var reset_girl_btn := LabUi.button("СБРОСИТЬ ПРОГРЕСС ДЕВУШКИ")
	reset_girl_btn.pressed.connect(_reset_girl)
	reset_row.add_child(reset_girl_btn)
	var reset_all_btn := LabUi.button("СБРОСИТЬ ВЕСЬ ТЕСТОВЫЙ ПРОГРЕСС")
	reset_all_btn.pressed.connect(_reset_all)
	reset_row.add_child(reset_all_btn)
	_host.add_child(reset_row)

func _lab_prep_preview() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(LabUi.heading("Итоговые характеристики"))
	var catalog: DateContentCatalog = _catalog()
	var player: DatePlayerSnapshot = progress_store.player_snapshot if progress_store != null else null
	var outfit: Outfit = catalog.find_outfit(_outfit_id) if catalog != null else null
	if catalog == null or player == null:
		return box
	for stat in catalog.characteristics:
		if stat == null:
			continue
		var base_value: int = player.get_stat(stat.id)
		var effective: int = DateTypes.effective_stat(base_value, outfit, stat.id)
		var bonus: int = outfit.bonus_for(stat.id) if outfit != null else 0
		var line := Label.new()
		if bonus > 0:
			line.text = "%s: %d (%d + 1 от одежды)" % [stat.display_name, effective, base_value]
		else:
			line.text = "%s: %d" % [stat.display_name, effective]
		box.add_child(line)
	var opened := PackedStringArray()
	var newly_opened := PackedStringArray()
	for move in catalog.characteristic_moves():
		if move == null or move.unlock_requirement == null:
			continue
		var base_value: int = player.get_stat(move.unlock_requirement.stat_id)
		var with_outfit: int = DateTypes.effective_stat(base_value, outfit, move.unlock_requirement.stat_id)
		if with_outfit < move.unlock_requirement.required_level:
			continue
		var tag: DateTag = catalog.find_tag(move.fixed_tag_id)
		var tag_name: String = tag.display_name if tag != null else String(move.fixed_tag_id)
		var line_text: String = "[%s] %s" % [tag_name, move.display_name]
		opened.append(line_text)
		if base_value < move.unlock_requirement.required_level:
			newly_opened.append(line_text)
	if not opened.is_empty():
		box.add_child(LabUi.heading("Открытые Characteristic Moves"))
		for line_text in opened:
			var opened_line := Label.new()
			opened_line.text = line_text
			box.add_child(opened_line)
	if not newly_opened.is_empty():
		box.add_child(LabUi.heading("Открывается Characteristic Move"))
		for line_text in newly_opened:
			var new_line := Label.new()
			new_line.text = line_text
			box.add_child(new_line)
	if outfit != null and outfit.has_outfit_move():
		var outfit_move: DateMove = catalog.find_move(outfit.outfit_move_id)
		if outfit_move != null:
			box.add_child(LabUi.heading("Outfit Move"))
			var tag: DateTag = catalog.find_tag(outfit_move.fixed_tag_id)
			var tag_name: String = tag.display_name if tag != null else String(outfit_move.fixed_tag_id)
			var move_line := Label.new()
			move_line.text = "[%s] %s" % [tag_name, outfit_move.display_name]
			box.add_child(move_line)
	return box


func _girl_card() -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var girl: GirlProfile = _catalog().find_girl(_girl_id)
	if girl == null:
		box.add_child(Label.new())
		return panel
	var progress: GirlProgress = progress_store.get_girl_progress(girl.id, girl)
	box.add_child(LabUi.heading(girl.display_name))
	var preset: GirlDifficultyPreset = _catalog().find_girl_difficulty(girl.difficulty_preset_id)
	var difficulty := Label.new()
	difficulty.text = "Сложность:\n%s" % (preset.display_name if preset != null else String(girl.difficulty_preset_id))
	box.add_child(difficulty)
	var enabled_count: int = _catalog().enabled_tags().size()
	var positive_count := Label.new()
	positive_count.text = "Положительных тегов:\n%d / %d" % [girl.positive_tag_ids.size(), enabled_count]
	box.add_child(positive_count)
	var theory := Label.new()
	var chance: float = DateBalanceDiagnostics.new().theoretical_availability(_catalog(), girl)
	theory.text = "Теоретическая базовая доступность:\n%s" % DateBalanceMath.format_percent(chance)
	box.add_child(theory)
	var rel := Label.new()
	rel.text = "Отношения:\n%d / %d" % [progress.relationship, GirlCatalog.seed_relationship_max(girl.id)]
	box.add_child(rel)
	box.add_child(LabUi.trait_block(_catalog(), girl))
	box.add_child(LabUi.known_preference_block(_catalog(), progress, girl))
	return panel


func _start_new() -> void:
	_seed = randi()
	_begin_session(_seed, false)


func _replay() -> void:
	if not progress_store.restore_replay() or progress_store.last_replay == null:
		status_message.emit("Нет snapshot для повтора.")
		return
	var snap: DateReplaySnapshot = progress_store.last_replay
	_girl_id = snap.girl_id
	_venue_id = snap.venue_id
	_outfit_id = snap.outfit_id
	_seed = snap.seed
	_begin_session(_seed, true)


func _begin_session(seed: int, is_replay: bool) -> void:
	var session_venue: StringName = _venue_id
	var forced_sit: DateSituation = _catalog().find_situation(_forced_situation_id)
	if forced_sit != null and not forced_sit.allows_venue(session_venue) and not forced_sit.allowed_venue_ids.is_empty():
		session_venue = forced_sit.allowed_venue_ids[0]
	var girl: GirlProfile = _catalog().find_girl(_girl_id)
	var progress: GirlProgress = progress_store.get_girl_progress(_girl_id, girl)
	var local_object_ids: Array[StringName] = []
	if is_replay and progress_store.last_replay != null:
		local_object_ids = progress_store.last_replay.local_object_ids.duplicate()
	else:
		local_object_ids = _lab_local_object_ids()
		progress_store.capture_replay(seed, _girl_id, session_venue, _outfit_id, progress, local_object_ids)
	var config := DateSessionConfig.new()
	config.seed = seed
	config.girl_id = _girl_id
	config.venue_id = session_venue
	config.outfit_id = _outfit_id
	config.local_object_ids = local_object_ids
	config.catalog = _catalog()
	config.girl_progress = progress
	config.player_snapshot = progress_store.player_snapshot
	config.relationship_max = GirlCatalog.seed_relationship_max(_girl_id)
	config.forced_situation_id = _forced_situation_id
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	status_message.emit("Свидание запущено. Seed %d" % seed)
	rebuild()


func _lab_local_object_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var location: DateVenue = _catalog().find_venue(_venue_id)
	if location != null:
		for object_id in location.local_object_ids:
			if object_id != &"" and not result.has(object_id):
				result.append(object_id)
	if location != null and location.uses_apartment_preparation and _grant_tv and not result.has(&"tv"):
		result.append(&"tv")
	return result


func _reset_girl() -> void:
	progress_store.reset_girl(_catalog().find_girl(_girl_id))
	status_message.emit("Прогресс девушки сброшен.")
	rebuild()


func _reset_all() -> void:
	progress_store.reset_all(_catalog())
	_engine = null
	status_message.emit("Весь тестовый прогресс сброшен.")
	rebuild()


func _build_runner() -> void:
	var session: DateSession = _engine.get_session_state()
	var view: DateEpisodeView = _engine.get_current_episode()
	var girl: GirlProfile = _engine.catalog().find_girl(session.girl_id)
	if _playthrough:
		var location: DateVenue = _engine.catalog().find_venue(session.venue_id)
		var girl_name: String = girl.display_name if girl != null else String(session.girl_id)
		var location_name: String = location.display_name if location != null else String(session.venue_id)
		var active := Label.new()
		active.text = "Active girl: %s\nLocation: %s" % [girl_name, location_name]
		_host.add_child(active)
	_host.add_child(LabUi.heading("Свидание"))
	_host.add_child(_date_start_relationship_block(session))
	_host.add_child(LabUi.trait_block(_engine.catalog(), girl))
	var progress: GirlProgress = _engine.girl_progress() if _engine != null else null
	_host.add_child(LabUi.known_preference_block(_engine.catalog(), progress, girl))
	_host.add_child(_combo_status_label(session))
	var meta := Label.new()
	meta.text = "Фаза: %s    Эпизод: %d    Seed: %d" % [DateTypes.phase_name(session.current_phase), session.current_episode_index + 1, session.seed]
	_host.add_child(meta)
	if view != null and view.situation != null:
		var sit_title := Label.new()
		sit_title.text = view.situation.display_name
		sit_title.add_theme_font_size_override("font_size", 20)
		_host.add_child(sit_title)
		var sit_text := Label.new()
		sit_text.text = view.situation.situation_text
		sit_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_host.add_child(sit_text)

	if session.stage == DateSession.Stage.AWAITING_MOVE and view != null:
		if _open_source >= 0:
			_host.add_child(_build_source_list(view))
		else:
			_host.add_child(LabUi.heading("БАЗОВЫЕ ХОДЫ"))
			for option in view.base_options:
				_host.add_child(_move_button(option))
			var reroll_block: Control = _build_vika_reroll_button(session)
			if reroll_block != null:
				_host.add_child(reroll_block)
			var swap_block: Control = _build_nika_swap_checkbox(session)
			if swap_block != null:
				_host.add_child(swap_block)
			_host.add_child(_build_source_buttons(view))
	elif session.stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		_host.add_child(_episode_result_block(session))
		var cont := LabUi.button("ПРОДОЛЖИТЬ")
		cont.pressed.connect(func() -> void:
			_open_source = -1
			_engine.advance()
			_persist()
			rebuild()
		)
		_host.add_child(cont)
	if not _playthrough:
		_host.add_child(_debug_panel(session, view))
	_maybe_request_playthrough_guidance(view)


func _unavailable_modulate() -> Color:
	return Color(0.7, 0.7, 0.7)


func _build_vika_reroll_button(session: DateSession) -> Control:
	if session == null or not session.vika_reroll_available:
		return null
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var btn: Button = LabUi.button("$25 — Пересобрать ответы")
	if session.vika_reroll_used:
		btn.disabled = true
		box.add_child(btn)
		var used := Label.new()
		used.text = "Пересборка уже использована на этом свидании."
		box.add_child(used)
		return box
	btn.pressed.connect(func() -> void:
		var error_text := ""
		if _playthrough:
			var dating: Variant = _dating_service()
			if dating != null:
				error_text = str(dating.try_vika_reroll())
			else:
				error_text = "Других вариантов сейчас нет."
		else:
			error_text = _engine.reroll_base_moves()
		if not error_text.is_empty():
			status_message.emit(error_text)
			if error_text == "Недостаточно денег.":
				var money := Label.new()
				money.text = "Недостаточно денег."
				box.add_child(money)
		rebuild()
	)
	box.add_child(btn)
	return box


func _build_nika_swap_checkbox(session: DateSession) -> Control:
	if session == null or not _engine.can_queue_outfit_swap():
		return null
	var box := CheckBox.new()
	box.text = "Переодеться после эпизода"
	box.button_pressed = session.pending_outfit_swap
	box.toggled.connect(func(pressed: bool) -> void:
		_engine.set_pending_outfit_swap(pressed)
	)
	return box


func _build_source_buttons(view: DateEpisodeView) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for source_view in view.source_views:
		if not source_view.visible:
			continue
		var btn: Button = LabUi.button(source_view.display_name.to_upper())
		btn.modulate = _source_state_color(source_view.state)
		if source_view.used:
			btn.disabled = true
			btn.tooltip_text = "Уже использовано на этом свидании."
		elif source_view.source == DateTypes.DateMoveSource.VENUE and source_view.use_limit > 1 and source_view.remaining_uses == 1:
			btn.tooltip_text = "1 использование осталось"
		else:
			var source_value: int = int(source_view.source)
			btn.pressed.connect(func() -> void:
				_open_source = source_value
				rebuild()
			)
		row.add_child(btn)
	return row


func _build_source_list(view: DateEpisodeView) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var source_view: DateMoveSourceView = _find_open_source(view)
	var title: String = source_view.display_name if source_view != null else "Источник"
	box.add_child(LabUi.heading(title.to_upper()))
	if source_view == null or source_view.options.is_empty():
		var empty := Label.new()
		empty.text = "Нет ходов в этом источнике."
		box.add_child(empty)
	elif source_view.source == DateTypes.DateMoveSource.CHARACTERISTIC:
		_add_characteristic_groups(box, source_view)
	else:
		for option in source_view.options:
			box.add_child(_move_button(option))
	var back := LabUi.button("НАЗАД")
	back.pressed.connect(func() -> void:
		_open_source = -1
		rebuild()
	)
	box.add_child(back)
	return box


func _find_open_source(view: DateEpisodeView) -> DateMoveSourceView:
	for source_view in view.source_views:
		if int(source_view.source) == _open_source:
			return source_view
	return null


func _source_state_color(state: DateTypes.DateMoveSourceState) -> Color:
	match state:
		DateTypes.DateMoveSourceState.POSITIVE:
			return LabUi.POSITIVE
		DateTypes.DateMoveSourceState.UNKNOWN:
			return LabUi.MUTED
		DateTypes.DateMoveSourceState.NEGATIVE:
			return LabUi.NEGATIVE
		DateTypes.DateMoveSourceState.USED:
			return LabUi.LOCKED
		_:
			return LabUi.TEXT


func _date_start_relationship_block(session: DateSession) -> Control:
	var rel_max: int = session.relationship_max
	var box := VBoxContainer.new()
	var start: RichTextLabel = GameTermView.create("Отношения на начало свидания: %d / %d" % [session.relationship_before, rel_max])
	box.add_child(start)
	box.add_child(GameTermView.create("До максимума: %d" % maxi(0, rel_max - session.relationship_before)))
	return box


func _combo_status_label(session: DateSession) -> Control:
	return GameTermView.create(_combo_compact_text(session), _combo_tag_knowledge(session))


func _combo_tag_knowledge(session: DateSession) -> Dictionary:
	var knowledge: Dictionary = {}
	var progress: GirlProgress = _engine.girl_progress() if _engine != null else null
	for tag_id in session.combo_distinct_success_tag_ids:
		if progress != null:
			knowledge[tag_id] = progress.tag_knowledge(tag_id)
		else:
			knowledge[tag_id] = DateTypes.TagKnowledge.POSITIVE
	return knowledge


func _combo_compact_text(session: DateSession) -> String:
	var rules: DateRules = _engine.catalog().date_rules
	var required: int = rules.combo_required_distinct_success_tags if rules != null else 3
	if session.combo_achieved:
		return "КОМБО: ПОЛУЧЕНО +1"
	var parts := PackedStringArray()
	for tag_id in session.combo_distinct_success_tag_ids:
		var tag: DateTag = _engine.catalog().find_tag(tag_id)
		var tag_name: String = tag.display_name if tag != null else String(tag_id)
		parts.append("[%s]" % tag_name)
	var count: int = session.combo_distinct_success_tag_ids.size()
	if parts.is_empty():
		return "КОМБО: 0 / %d" % required
	return "КОМБО: %s %d / %d" % [" ".join(parts), count, required]


func _add_characteristic_groups(box: VBoxContainer, source_view: DateMoveSourceView) -> void:
	var girl: GirlProfile = null
	if _engine != null:
		girl = _engine.catalog().find_girl(_engine.get_session_state().girl_id)
	var girl_trait: GirlTrait = null
	if girl != null:
		girl_trait = _engine.catalog().find_trait(girl.trait_id)
	for stat_id in DateTypes.CHARACTERISTIC_STAT_ORDER:
		var group: Array[DateMoveOption] = []
		for option in source_view.options:
			if option.requirement_stat_id == stat_id:
				group.append(option)
		if group.is_empty():
			continue
		_sort_characteristic_group(group)
		var sample: DateMoveOption = group[0]
		box.add_child(_characteristic_group_header(stat_id, sample, girl_trait))
		for option in group:
			box.add_child(_move_button(option))


func _sort_characteristic_group(group: Array[DateMoveOption]) -> void:
	group.sort_custom(_characteristic_option_less)


func _characteristic_option_less(a: DateMoveOption, b: DateMoveOption) -> bool:
	return a.requirement_level < b.requirement_level


func _characteristic_group_header(stat_id: StringName, sample: DateMoveOption, girl_trait: GirlTrait) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var stat: CharacteristicDefinition = _catalog().find_characteristic(stat_id)
	var stat_name: String = stat.display_name.to_upper() if stat != null else String(stat_id).to_upper()
	var effective: int = mini(5, sample.current_stat_level)
	var header: String = "%s — ур. %d" % [stat_name, effective]
	var parts: PackedStringArray = []
	if sample.outfit_stat_bonus > 0 or sample.current_stat_level != sample.current_base_stat_level:
		parts.append(str(sample.current_base_stat_level))
		if sample.outfit_stat_bonus > 0:
			parts.append("%d одежда" % sample.outfit_stat_bonus)
		var extra: int = sample.current_stat_level - sample.current_base_stat_level - sample.outfit_stat_bonus
		if extra > 0:
			parts.append("%d стайлинг" % extra)
	if not parts.is_empty():
		header = "%s — ур. %d (%s)" % [stat_name, effective, " + ".join(parts)]
	box.add_child(LabUi.heading(header))
	if girl_trait != null and girl_trait.kind == GirlTrait.Kind.CHARACTERISTIC and girl_trait.characteristic_id == stat_id:
		var trait_line := Label.new()
		var nice: String = stat.display_name if stat != null else String(stat_id)
		trait_line.text = "Особенность девушки: +1 к результату ходов %s" % nice
		box.add_child(trait_line)
	return box


func _requirement_reason(option: DateMoveOption) -> String:
	var stat: CharacteristicDefinition = _catalog().find_characteristic(option.requirement_stat_id)
	var stat_name: String = stat.display_name if stat != null else String(option.requirement_stat_id)
	var now_text: String = "Сейчас: %s %d" % [stat_name, option.current_stat_level]
	if option.outfit_stat_bonus > 0:
		now_text = "Сейчас: %s %d (%d + 1 от одежды)" % [stat_name, option.current_stat_level, option.current_base_stat_level]
	return "Требуется: %s %d\n%s" % [stat_name, option.requirement_level, now_text]


func _move_button(option: DateMoveOption) -> Button:
	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_contents = true
	var unavailable: bool = not option.is_selectable()
	btn.disabled = unavailable
	var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN if unavailable else option.tag_knowledge
	var header: String = "[%s] %s" % [option.tag_display_name, option.display_name]
	if option.kind == DateTypes.DateMoveKind.CHARACTERISTIC:
		if option.availability == DateTypes.MoveAvailability.LOCKED:
			header = "🔒 [%s] %s · требуется ур. %d" % [option.tag_display_name, option.display_name, option.requirement_level]
		else:
			header = "[%s] %s · ур. %d" % [option.tag_display_name, option.display_name, option.requirement_level]
	if unavailable:
		btn.modulate = _unavailable_modulate()
	var lines := PackedStringArray([header])
	lines.append(option.option_text)
	if unavailable and option.kind != DateTypes.DateMoveKind.CHARACTERISTIC:
		if option.availability == DateTypes.MoveAvailability.LOCKED:
			lines.append(_requirement_reason(option))
		else:
			lines.append("Использовано")
	var knowledge_map: Dictionary = {}
	if option.tag_id != &"":
		knowledge_map[option.tag_id] = knowledge
	var rtl := RichTextLabel.new()
	GameTermView.apply(rtl, "\n".join(lines), knowledge_map)
	rtl.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.add_child(rtl)
	rtl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	btn.custom_minimum_size = Vector2(0, 72)
	btn.resized.connect(func() -> void:
		var height: float = float(rtl.get_content_height()) + 20.0
		if absf(btn.custom_minimum_size.y - height) > 1.0:
			btn.custom_minimum_size.y = height
	)
	var move_id: StringName = option.move_id
	var choose := func() -> void:
		if unavailable:
			return
		_open_source = -1
		_engine.choose_move(move_id)
		_persist()
		rebuild()
	btn.pressed.connect(choose)
	rtl.meta_clicked.connect(func(_meta: Variant) -> void:
		choose.call()
	)
	return btn


func _episode_result_block(session: DateSession) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var move: DateMove = _engine.catalog().find_move(session.current_selected_move_id)
	var tag: DateTag = _engine.catalog().find_tag(session.current_resolved_tag_id)
	var knowledge: DateTypes.TagKnowledge = _tag_knowledge(session.current_resolved_tag_id)
	var move_label := Label.new()
	move_label.text = "Выбранный Ход: %s" % (move.display_name if move != null else String(session.current_selected_move_id))
	box.add_child(move_label)
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 8)
	var tag_title := Label.new()
	tag_title.text = "Получившийся Tag:"
	tag_row.add_child(tag_title)
	var tag_name: String = tag.display_name if tag != null else String(session.current_resolved_tag_id)
	tag_row.add_child(LabUi.tag_label(tag_name, knowledge))
	box.add_child(tag_row)
	var reaction := Label.new()
	reaction.text = "Реакция девушки: %s" % session.current_result_text
	reaction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(reaction)
	var score := Label.new()
	score.text = "Score: %+d" % session.current_score_delta
	box.add_child(score)
	if session.episode_history.size() > 0:
		var last_episode: DateEpisodeResult = session.episode_history[session.episode_history.size() - 1]
		if last_episode.soften_applied:
			var soften := Label.new()
			soften.text = "Сгладить неловкость: -1 → 0"
			box.add_child(soften)
		if not last_episode.trait_bonus_text.is_empty():
			var trait_line := Label.new()
			trait_line.text = last_episode.trait_bonus_text
			box.add_child(trait_line)
	var revealed := Label.new()
	if session.episode_history.size() > 0 and session.episode_history[session.episode_history.size() - 1].revealed_tag:
		revealed.text = "Новое раскрытое знание: %s" % DateTypes.knowledge_label(knowledge)
	else:
		revealed.text = "Новое раскрытое знание: нет"
	box.add_child(revealed)
	if session.episode_history.size() > 0 and session.episode_history[session.episode_history.size() - 1].combo_granted:
		var required: int = 3
		if _engine.catalog().date_rules != null:
			required = _engine.catalog().date_rules.combo_required_distinct_success_tags
		var combo_title: RichTextLabel = GameTermView.create("КОМБО: %d разных успешных тега подряд" % required)
		box.add_child(combo_title)
		var combo_score := Label.new()
		combo_score.text = "+1"
		box.add_child(combo_score)
	return panel


func _tag_knowledge(tag_id: StringName) -> DateTypes.TagKnowledge:
	var session: DateSession = _engine.get_session_state()
	var girl: GirlProfile = _engine.catalog().find_girl(session.girl_id) if _engine != null else null
	return _session_progress(session.girl_id).tag_knowledge(tag_id, girl)


func _build_result() -> void:
	var result: DateRunResult = _engine.get_result()
	var session: DateSession = _engine.get_session_state()
	_host.add_child(LabUi.heading("Итог свидания"))
	if result == null:
		return
	var bd: DateScoreBreakdown = result.score_breakdown
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	_tally_box = VBoxContainer.new()
	_tally_box.add_theme_constant_override("separation", 8)
	panel.add_child(_tally_box)
	_host.add_child(panel)
	_tally_lines.clear()
	for episode in session.episode_history:
		if episode.score_delta == 0:
			continue
		var tag: DateTag = _engine.catalog().find_tag(episode.tag_id)
		var tag_name: String = tag.display_name if tag != null else String(episode.tag_id)
		_tally_lines.append(LabUi.tally_row("[%s]" % tag_name, episode.score_delta))
		if not episode.trait_bonus_text.is_empty():
			_tally_lines.append(GameTermView.create(episode.trait_bonus_text))
	if bd.combo_score != 0:
		_tally_lines.append(LabUi.tally_row("Комбо", bd.combo_score))
	if not bd.girl_trait_display_name.is_empty():
		_tally_lines.append(LabUi.tally_row("Особенность «%s»" % bd.girl_trait_display_name, bd.girl_trait_score))
	if bd.apartment_preparation_score != 0:
		_tally_lines.append(LabUi.tally_row("Неподготовленная квартира", bd.apartment_preparation_score))
	var total_row := LabUi.tally_row("Итог свидания", bd.total)
	for child in total_row.get_children():
		if child is Label:
			(child as Label).add_theme_font_size_override("font_size", 26)
		elif child is RichTextLabel:
			(child as RichTextLabel).add_theme_font_size_override("normal_font_size", 26)
	_tally_lines.append(total_row)
	var rel_max: int = session.relationship_max
	_tally_lines.append(LabUi.tally_row("Прогресс отношений", bd.relationship_gain))
	var rel_text: String = "Отношения: %d / %d" % [session.relationship_after, rel_max]
	if session.relationship_after >= rel_max and rel_max > 0:
		rel_text += " — МАКСИМУМ"
	var rel: RichTextLabel = GameTermView.create(rel_text)
	rel.add_theme_font_size_override("normal_font_size", 18)
	rel.add_theme_color_override("default_color", LabUi.MUTED)
	_tally_lines.append(rel)
	if result.relationship_max_reached:
		var rating: RichTextLabel = GameTermView.create("Рейтинг +1")
		rating.add_theme_font_size_override("normal_font_size", 18)
		_tally_lines.append(rating)
		var reward_block: Control = _max_reward_result_block(session.girl_id)
		if reward_block != null:
			_tally_lines.append(reward_block)
	var footer := VBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	if _playthrough:
		var done := LabUi.button("ГОТОВО")
		done.pressed.connect(_finish_playthrough)
		footer.add_child(done)
	else:
		var next := LabUi.button("НАЧАТЬ СЛЕДУЮЩЕЕ СВИДАНИЕ")
		next.pressed.connect(func() -> void:
			_engine = null
			rebuild()
		)
		footer.add_child(next)
	_tally_footer = footer
	var timer := Timer.new()
	timer.wait_time = 0.12
	timer.timeout.connect(_reveal_tally_line)
	_host.add_child(timer)
	_reveal_tally_line()
	timer.start()


func _max_reward_result_block(girl_id: StringName) -> Control:
	var girls: Variant = null
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		girls = tree.root.get_node_or_null("GirlsService")
	if girls == null or not girls.has_method("get_filler_reward_for_girl"):
		return null
	var reward: FillerRewardDefinition = girls.get_filler_reward_for_girl(girl_id)
	if reward == null:
		return null
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = "Новая награда:\n%s" % reward.display_name
	box.add_child(title)
	var body := Label.new()
	body.text = reward.granted_description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	return box


func _reveal_tally_line() -> void:
	if _tally_box == null or not is_instance_valid(_tally_box):
		return
	if _tally_index >= _tally_lines.size():
		if _tally_footer != null and is_instance_valid(_tally_footer) and _tally_footer.get_parent() == null:
			_host.add_child(_tally_footer)
		for child in _host.get_children():
			if child is Timer:
				(child as Timer).stop()
		return
	var line: Control = _tally_lines[_tally_index]
	_tally_index += 1
	line.modulate.a = 0.0
	_tally_box.add_child(line)
	var tw := create_tween()
	tw.tween_property(line, "modulate:a", 1.0, 0.08)
	_result_tweens.append(tw)


func _debug_panel(session: DateSession, view: DateEpisodeView) -> VBoxContainer:
	var box := VBoxContainer.new()
	var toggle := Button.new()
	toggle.text = "Debug-панель"
	toggle.toggle_mode = true
	toggle.button_pressed = _debug_open
	box.add_child(toggle)
	_debug_body = VBoxContainer.new()
	_debug_body.visible = _debug_open
	var label := RichTextLabel.new()
	label.fit_content = true
	label.scroll_active = false
	label.text = _debug_text(session, view)
	_debug_body.add_child(label)
	box.add_child(_debug_body)
	toggle.toggled.connect(func(pressed: bool) -> void:
		_debug_open = pressed
		_debug_body.visible = pressed
	)
	return box


func _debug_text(session: DateSession, view: DateEpisodeView) -> String:
	var situation_id: StringName = &""
	if view != null and view.situation != null:
		situation_id = view.situation.id
	var venue_filter := "(any)"
	var situation_text := ""
	if view != null and view.situation != null:
		situation_text = view.situation.situation_text
		if view.situation.allowed_venue_ids.is_empty():
			venue_filter = "(any)"
		else:
			var names: PackedStringArray = PackedStringArray()
			for venue_id in view.situation.allowed_venue_ids:
				names.append(String(venue_id))
			venue_filter = ", ".join(names)
	var lines := PackedStringArray([
		"seed: %d" % session.seed,
		"session_id: %s" % session.session_id,
		"girl_id: %s" % String(session.girl_id),
		"venue_id: %s" % String(session.venue_id),
		"outfit_id: %s" % String(session.outfit_id),
		"phase: %s" % DateTypes.phase_name(session.current_phase),
		"episode_index: %d" % session.current_episode_index,
		"situation_id: %s" % String(situation_id),
		"venue_filter: %s" % venue_filter,
		"situation_text: %s" % situation_text,
		"candidate_base_move_ids: %s" % str(session.current_candidate_base_move_ids),
		"selected_base_move_ids: %s" % str(session.current_selected_base_move_ids),
		"selected_move_id: %s" % String(session.current_selected_move_id),
		"resolved_tag_id: %s" % String(session.current_resolved_tag_id),
		"tag_preference: %d" % session.current_tag_preference,
		"score_delta: %d" % session.current_score_delta,
		"combo_chain: %s" % str(session.combo_distinct_success_tag_ids),
		"combo_achieved: %s" % str(session.combo_achieved),
		"combo_rewards_earned: %d" % session.combo_rewards_earned,
		"characteristic_source_used: %s" % str(session.characteristic_source_used),
		"outfit_source_used: %s" % str(session.outfit_source_used),
		"venue_source_used: %s" % str(session.venue_source_used),
		"score_breakdown: %s" % str(session.score_breakdown.to_dictionary() if session.score_breakdown != null else {}),
	])
	if view != null:
		for source_view in view.source_views:
			lines.append("source %s used=%s state=%s" % [DateTypes.source_name(source_view.source), str(source_view.used), DateTypes.source_state_name(source_view.state)])
			for option in source_view.options:
				lines.append("  move_id=%s tag_id=%s state=%s" % [String(option.move_id), String(option.tag_id), DateTypes.availability_name(option.availability)])
	lines.append_array(_debug_move_block("six_base_moves", session.current_candidate_base_move_ids, situation_id, session, true))
	lines.append_array(_debug_move_block("selected_base_moves", session.current_selected_base_move_ids, situation_id, session, false))
	lines.append_array(_debug_move_block("reroll_base_moves", session.current_reroll_base_move_ids, situation_id, session, false))
	lines.append("selected_base_tags")
	lines.append_array(_debug_id_lines(session.current_selected_base_tag_ids))
	return "\n".join(lines)


func _debug_move_block(
	title: String,
	move_ids: Array[StringName],
	situation_id: StringName,
	_session: DateSession,
	with_texts: bool
) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray([title])
	if move_ids.is_empty():
		lines.append("  (none)")
		return lines
	var catalog: DateContentCatalog = _engine.catalog() if _engine != null else _catalog()
	for move_id in move_ids:
		var move: DateMove = catalog.find_move(move_id)
		var tag_id: String = ""
		var state: String = DateTypes.availability_name(DateTypes.MoveAvailability.AVAILABLE)
		if move != null:
			tag_id = String(move.resolved_tag_id())
		lines.append("  move_id=%s tag_id=%s state=%s" % [String(move_id), tag_id, state])
		if with_texts and move != null:
			lines.append("    option: %s" % move.fixed_option_text)
			lines.append("    positive: %s" % move.fixed_positive_result_text)
			lines.append("    negative: %s" % move.fixed_negative_result_text)
	return lines


func _debug_id_lines(ids: Array[StringName]) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if ids.is_empty():
		lines.append("  (none)")
		return lines
	for item in ids:
		lines.append("  %s" % String(item))
	return lines
