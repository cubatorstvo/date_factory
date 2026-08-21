class_name DatePlayPanel
extends Control

signal status_message(text: String)
signal playthrough_finished

var catalog_service: DateCatalogService
var progress_store: DateProgressStore
var validator: ContentValidator = ContentValidator.new()

var _engine: DateEngine
var _girl_id: StringName = &"alina"
var _location_id: StringName = &"cafe"
var _outfit_id: StringName = &"casual"
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


func setup(p_catalog: DateCatalogService, p_store: DateProgressStore) -> void:
	catalog_service = p_catalog
	progress_store = p_store
	if is_node_ready():
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
	for local_view in view.local_object_views:
		if local_view != null and not local_view.options.is_empty():
			has_local = true
			break
	if has_local:
		guidance.request_tutorial(GuidanceCatalog.ID_LOCAL_OBJECTS_INTRO)
	for option in view.unlockable_options:
		if option.availability == DateTypes.MoveAvailability.LOCKED:
			guidance.request_tutorial(GuidanceCatalog.ID_LOCKED_MOVES_INTRO)
			break


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
	LabUi.fill_selector(loc_sel, _catalog().locations, _location_id)
	loc_sel.item_selected.connect(func(index: int) -> void:
		_location_id = loc_sel.get_item_metadata(index)
		rebuild()
	)
	_host.add_child(LabUi.labeled_row("Место", loc_sel))
	var outfit_sel := OptionButton.new()
	LabUi.fill_selector(outfit_sel, _catalog().outfits, _outfit_id)
	outfit_sel.item_selected.connect(func(index: int) -> void:
		_outfit_id = outfit_sel.get_item_metadata(index)
	)
	_host.add_child(LabUi.labeled_row("Одежда", outfit_sel))

	var location: DateLocation = _catalog().find_location(_location_id)
	if location != null and location.uses_apartment_preparation:
		var prepared := CheckBox.new()
		prepared.text = "Подготовлена"
		prepared.button_pressed = progress_store.player_state.apartment_prepared
		prepared.toggled.connect(func(pressed: bool) -> void:
			progress_store.player_state.apartment_prepared = pressed
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

	for stat in _catalog().progression_stats:
		var spin := SpinBox.new()
		spin.min_value = stat.min_level
		spin.max_value = stat.max_level
		spin.value = progress_store.player_state.get_stat(stat.id)
		var captured_id: StringName = stat.id
		spin.value_changed.connect(func(value: float) -> void:
			progress_store.player_state.set_stat(captured_id, int(value))
			progress_store.save_store()
		)
		_host.add_child(LabUi.labeled_row(stat.display_name, spin))

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
	var unknown := Label.new()
	unknown.text = "Неизвестно: %d" % progress.unknown_tag_count(girl, _catalog())
	box.add_child(unknown)
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
	_location_id = snap.location_id
	_outfit_id = snap.outfit_id
	_seed = snap.seed
	_begin_session(_seed, true)


func _begin_session(seed: int, is_replay: bool) -> void:
	var girl: GirlProfile = _catalog().find_girl(_girl_id)
	var progress: GirlProgress = progress_store.get_girl_progress(_girl_id, girl)
	var local_object_ids: Array[StringName] = []
	if is_replay and progress_store.last_replay != null:
		local_object_ids = progress_store.last_replay.local_object_ids.duplicate()
	else:
		local_object_ids = _lab_local_object_ids()
		progress_store.capture_replay(seed, _girl_id, _location_id, _outfit_id, progress, local_object_ids)
	var config := DateSessionConfig.new()
	config.seed = seed
	config.girl_id = _girl_id
	config.location_id = _location_id
	config.outfit_id = _outfit_id
	config.local_object_ids = local_object_ids
	config.catalog = _catalog()
	config.girl_progress = progress
	config.player_state = progress_store.player_state
	config.relationship_max = GirlCatalog.seed_relationship_max(_girl_id)
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	status_message.emit("Свидание запущено. Seed %d" % seed)
	rebuild()


func _lab_local_object_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	var location: DateLocation = _catalog().find_location(_location_id)
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
		var location: DateLocation = _engine.catalog().find_location(session.location_id)
		var girl_name: String = girl.display_name if girl != null else String(session.girl_id)
		var location_name: String = location.display_name if location != null else String(session.location_id)
		var active := Label.new()
		active.text = "Active girl: %s\nLocation: %s" % [girl_name, location_name]
		_host.add_child(active)
	_host.add_child(LabUi.heading("Свидание"))
	_host.add_child(_date_start_relationship_block(session))
	_host.add_child(LabUi.trait_block(_engine.catalog(), girl))
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
		_host.add_child(LabUi.heading("БАЗОВЫЕ ХОДЫ"))
		for option in view.base_options:
			_host.add_child(_move_button(option))
		_host.add_child(LabUi.heading("ОТКРЫВАЕМЫЕ ХОДЫ"))
		if view.unlockable_options.is_empty():
			var empty := Label.new()
			empty.text = "Нет применимых открываемых ходов."
			_host.add_child(empty)
		for option in view.unlockable_options:
			_host.add_child(_move_button(option))
		var location: DateLocation = _engine.catalog().find_location(session.location_id)
		var location_name: String = location.display_name if location != null else String(session.location_id)
		_host.add_child(LabUi.heading("ЛОКАЛЬНЫЕ ХОДЫ — %s" % location_name.to_upper()))
		if view.local_object_views.is_empty():
			var empty_local := Label.new()
			empty_local.text = "Нет локальных объектов."
			_host.add_child(empty_local)
		for local_view in view.local_object_views:
			var object_title: RichTextLabel = GameTermView.create(
				"%s — Использовано" % local_view.display_name if local_view.used else local_view.display_name
			)
			object_title.add_theme_font_size_override("normal_font_size", 18)
			if local_view.used:
				object_title.modulate = _unavailable_modulate()
			_host.add_child(object_title)
			for option in local_view.options:
				_host.add_child(_move_button(option))
	elif session.stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		_host.add_child(_episode_result_block(session))
		var cont := LabUi.button("ПРОДОЛЖИТЬ")
		cont.pressed.connect(func() -> void:
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


func _requirement_reason(option: DateMoveOption) -> String:
	var stat: ProgressionStat = _catalog().find_stat(option.requirement_stat_id)
	var stat_name: String = stat.display_name if stat != null else String(option.requirement_stat_id)
	return "Требуется: %s %d (сейчас %d)" % [stat_name, option.requirement_level, option.current_stat_level]


func _move_button(option: DateMoveOption) -> Button:
	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_contents = true
	var unavailable: bool = not option.is_selectable()
	btn.disabled = unavailable
	var knowledge: DateTypes.TagKnowledge = DateTypes.TagKnowledge.UNKNOWN if unavailable else option.tag_knowledge
	var header: String = "[%s] %s" % [option.tag_display_name, option.option_text if option.kind == DateTypes.DateMoveKind.LOCAL else option.display_name]
	if unavailable:
		btn.modulate = _unavailable_modulate()
	var lines := PackedStringArray([header])
	if option.kind != DateTypes.DateMoveKind.LOCAL:
		lines.append(option.option_text)
	if unavailable:
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
	var lines := PackedStringArray([
		"seed: %d" % session.seed,
		"session_id: %s" % session.session_id,
		"girl_id: %s" % String(session.girl_id),
		"location_id: %s" % String(session.location_id),
		"outfit_id: %s" % String(session.outfit_id),
		"phase: %s" % DateTypes.phase_name(session.current_phase),
		"episode_index: %d" % session.current_episode_index,
		"situation_id: %s" % String(situation_id),
		"candidate_base_move_ids: %s" % str(session.current_candidate_base_move_ids),
		"selected_base_move_ids: %s" % str(session.current_selected_base_move_ids),
		"applicable_unlockable_move_ids: %s" % str(session.current_applicable_unlockable_move_ids),
		"selected_move_id: %s" % String(session.current_selected_move_id),
		"resolved_tag_id: %s" % String(session.current_resolved_tag_id),
		"tag_preference: %d" % session.current_tag_preference,
		"score_delta: %d" % session.current_score_delta,
		"combo_chain: %s" % str(session.combo_distinct_success_tag_ids),
		"combo_achieved: %s" % str(session.combo_achieved),
		"combo_rewards_earned: %d" % session.combo_rewards_earned,
		"score_breakdown: %s" % str(session.score_breakdown.to_dictionary() if session.score_breakdown != null else {}),
	])
	lines.append_array(_debug_move_block("applicable_unlockable_moves", session.current_applicable_unlockable_move_ids, situation_id, session, true))
	lines.append_array(_debug_move_block("available_unlockable_moves", session.current_available_unlockable_move_ids, situation_id, session, true))
	lines.append_array(_debug_move_block("locked_unlockable_moves", session.current_locked_unlockable_move_ids, situation_id, session, true))
	lines.append_array(_debug_move_block("used_unlockable_moves", session.current_used_unlockable_move_ids, situation_id, session, true))
	lines.append("reserved_unlockable_tags")
	lines.append_array(_debug_id_lines(session.current_reserved_unlockable_tag_ids))
	lines.append_array(_debug_move_block("preferred_base_candidates", session.current_preferred_base_move_ids, situation_id, session, false))
	lines.append_array(_debug_move_block("fallback_base_candidates", session.current_fallback_base_move_ids, situation_id, session, false))
	lines.append_array(_debug_move_block("selected_base_moves", session.current_selected_base_move_ids, situation_id, session, false))
	lines.append("selected_base_tags")
	lines.append_array(_debug_id_lines(session.current_selected_base_tag_ids))
	return "\n".join(lines)


func _debug_move_block(
	title: String,
	move_ids: Array[StringName],
	situation_id: StringName,
	session: DateSession,
	unlockable: bool
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
			var mapping: DateMoveSituationMapping = move.mapping_for(situation_id)
			if mapping != null:
				tag_id = String(mapping.tag_id)
			if unlockable:
				state = _debug_unlockable_state(session, move_id)
		lines.append("  move_id=%s tag_id=%s state=%s" % [String(move_id), tag_id, state])
	return lines


func _debug_unlockable_state(session: DateSession, move_id: StringName) -> String:
	if session.current_available_unlockable_move_ids.has(move_id):
		return DateTypes.availability_name(DateTypes.MoveAvailability.AVAILABLE)
	if session.current_locked_unlockable_move_ids.has(move_id):
		return DateTypes.availability_name(DateTypes.MoveAvailability.LOCKED)
	if session.current_used_unlockable_move_ids.has(move_id):
		return DateTypes.availability_name(DateTypes.MoveAvailability.USED)
	return DateTypes.availability_name(DateTypes.MoveAvailability.AVAILABLE)


func _debug_id_lines(ids: Array[StringName]) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if ids.is_empty():
		lines.append("  (none)")
		return lines
	for item in ids:
		lines.append("  %s" % String(item))
	return lines
