class_name DatePlayPanel
extends Control

signal status_message(text: String)

var catalog_service: DateCatalogService
var progress_store: DateProgressStore
var validator: ContentValidator = ContentValidator.new()

var _engine: DateEngine
var _girl_id: StringName = &"alina"
var _location_id: StringName = &"cafe"
var _outfit_id: StringName = &"casual"
var _seed: int = 1

var _scroll: ScrollContainer
var _host: VBoxContainer
var _debug_body: VBoxContainer
var _debug_open: bool = false


func setup(p_catalog: DateCatalogService, p_store: DateProgressStore) -> void:
	catalog_service = p_catalog
	progress_store = p_store
	if is_node_ready():
		rebuild()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	for child in _host.get_children():
		_host.remove_child(child)
		child.free()
	if _engine != null and _engine.get_session_state() != null:
		var stage: DateSession.Stage = _engine.get_session_state().stage
		if stage == DateSession.Stage.SHOWING_DATE_RESULT or stage == DateSession.Stage.COMPLETED:
			_build_result()
			return
		if stage != DateSession.Stage.IDLE and stage != DateSession.Stage.ABORTED:
			_build_runner()
			return
	_build_launch()


func _catalog() -> DateContentCatalog:
	return catalog_service.catalog


func _build_launch() -> void:
	_host.add_child(LabUi.heading("Запуск свидания"))
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
	_host.add_child(LabUi.labeled_row("Наряд", outfit_sel))

	var location: DateLocation = _catalog().find_location(_location_id)
	if location != null and (location.uses_apartment_quality or location.uses_apartment_preparation):
		var quality := SpinBox.new()
		quality.min_value = _catalog().date_rules.apartment_quality_min
		quality.max_value = _catalog().date_rules.apartment_quality_max
		quality.value = progress_store.player_state.apartment_quality
		quality.value_changed.connect(func(value: float) -> void:
			progress_store.player_state.apartment_quality = int(value)
			progress_store.save_store()
		)
		_host.add_child(LabUi.labeled_row("Качество квартиры", quality))
		var prepared := CheckBox.new()
		prepared.text = "Подготовлена"
		prepared.button_pressed = progress_store.player_state.apartment_prepared
		prepared.toggled.connect(func(pressed: bool) -> void:
			progress_store.player_state.apartment_prepared = pressed
			progress_store.save_store()
		)
		_host.add_child(LabUi.labeled_row("Подготовка квартиры", prepared))

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
	var rel := Label.new()
	rel.text = "Отношения: %d  (min %d / max %d)" % [progress.relationship, girl.relationship_min, girl.relationship_max]
	box.add_child(rel)
	box.add_child(_tag_list("Нравится:", progress.revealed_positive_tag_ids, DateTypes.TagKnowledge.POSITIVE))
	box.add_child(_tag_list("Не нравится:", progress.revealed_negative_tag_ids, DateTypes.TagKnowledge.NEGATIVE))
	var unknown := Label.new()
	unknown.text = "Неизвестно: %d" % progress.unknown_tag_count(girl)
	box.add_child(unknown)
	var secondary := Label.new()
	var rule: SecondaryRule = _catalog().find_secondary(girl.secondary_rule_id)
	if progress.secondary_revealed and rule != null:
		secondary.text = "Secondary: %s" % rule.display_name
	else:
		secondary.text = "Secondary: ???"
	box.add_child(secondary)
	var formats: PackedStringArray = PackedStringArray()
	for format_id in girl.favorite_location_format_ids:
		var format: LocationFormat = _catalog().find_location_format(format_id)
		formats.append(format.display_name if format != null else String(format_id))
	var fav := Label.new()
	fav.text = "Любимые форматы мест: %s" % ", ".join(formats)
	fav.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(fav)
	return panel


func _tag_list(title: String, ids: Array[StringName], knowledge: DateTypes.TagKnowledge) -> Label:
	var names: PackedStringArray = PackedStringArray()
	for tag_id in ids:
		var tag: DateTag = _catalog().find_tag(tag_id)
		names.append("%s %s" % [DateTypes.knowledge_glyph(knowledge), tag.display_name if tag != null else String(tag_id)])
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s %s" % [title, ", ".join(names) if names.size() > 0 else "—"]
	return label


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
	if not is_replay:
		progress_store.capture_replay(seed, _girl_id, _location_id, _outfit_id, progress)
	var config := DateSessionConfig.new()
	config.seed = seed
	config.girl_id = _girl_id
	config.location_id = _location_id
	config.outfit_id = _outfit_id
	config.catalog = _catalog()
	config.girl_progress = progress
	config.player_state = progress_store.player_state
	_engine = DateEngine.new()
	_engine.create_date_session(config)
	status_message.emit("Свидание запущено. Seed %d" % seed)
	rebuild()


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
	_host.add_child(LabUi.heading("Свидание"))
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
	var girl: GirlProfile = _catalog().find_girl(session.girl_id)
	var progress: GirlProgress = progress_store.get_girl_progress(session.girl_id, girl)
	if progress.secondary_revealed:
		var live := Label.new()
		live.text = "Secondary: %s" % _engine.secondary_live_text()
		_host.add_child(live)
	else:
		var hidden := Label.new()
		hidden.text = "SECONDARY: ???"
		_host.add_child(hidden)

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
	elif session.stage == DateSession.Stage.SHOWING_EPISODE_RESULT:
		_host.add_child(_episode_result_block(session))
		var cont := LabUi.button("ПРОДОЛЖИТЬ")
		cont.pressed.connect(func() -> void:
			_engine.advance()
			progress_store.save_store()
			rebuild()
		)
		_host.add_child(cont)
	_host.add_child(_debug_panel(session, view))


func _move_button(option: DateMoveOption) -> Button:
	var btn := Button.new()
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var state: String = "ДОСТУПЕН"
	match option.availability:
		DateTypes.MoveAvailability.LOCKED:
			state = "ЗАБЛОКИРОВАН"
			btn.modulate = Color(0.55, 0.55, 0.55)
		DateTypes.MoveAvailability.USED:
			state = "Уже использован"
			btn.modulate = Color(0.7, 0.7, 0.7)
	var req: String = ""
	if option.kind == DateTypes.DateMoveKind.UNLOCKABLE:
		var stat: ProgressionStat = _catalog().find_stat(option.requirement_stat_id)
		var stat_name: String = stat.display_name if stat != null else String(option.requirement_stat_id)
		req = "Requirement: %s %d (сейчас %d)\nUses: %d/%d" % [stat_name, option.requirement_level, option.current_stat_level, option.uses_used, option.uses_max]
	btn.text = "%s  %s [%s] %s\n%s\n%s" % [
		state,
		DateTypes.knowledge_glyph(option.tag_knowledge),
		option.tag_display_name,
		option.display_name,
		option.option_text,
		req,
	]
	btn.disabled = not option.is_selectable()
	var move_id: StringName = option.move_id
	btn.pressed.connect(func() -> void:
		_engine.choose_move(move_id)
		progress_store.save_store()
		rebuild()
	)
	return btn


func _episode_result_block(session: DateSession) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var move: DateMove = _engine.catalog().find_move(session.current_selected_move_id)
	var tag: DateTag = _engine.catalog().find_tag(session.current_resolved_tag_id)
	var lines := PackedStringArray([
		"Выбранный Ход: %s" % (move.display_name if move != null else String(session.current_selected_move_id)),
		"Получившийся Tag: %s [%s]" % [tag.display_name if tag != null else String(session.current_resolved_tag_id), DateTypes.knowledge_label(_tag_knowledge(session.current_resolved_tag_id))],
		"Реакция девушки: %s" % session.current_result_text,
		"Score: %+d" % session.current_score_delta,
	])
	if session.episode_history.size() > 0 and session.episode_history[session.episode_history.size() - 1].revealed_tag:
		lines.append("Новое раскрытое знание: %s" % DateTypes.knowledge_label(_tag_knowledge(session.current_resolved_tag_id)))
	else:
		lines.append("Новое раскрытое знание: нет")
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "\n".join(lines)
	box.add_child(label)
	return panel


func _tag_knowledge(tag_id: StringName) -> DateTypes.TagKnowledge:
	var session: DateSession = _engine.get_session_state()
	var girl: GirlProfile = _catalog().find_girl(session.girl_id)
	return progress_store.get_girl_progress(session.girl_id, girl).tag_knowledge(tag_id)


func _build_result() -> void:
	var result: DateRunResult = _engine.get_result()
	var session: DateSession = _engine.get_session_state()
	_host.add_child(LabUi.heading("RESULT"))
	if result == null:
		return
	for episode in session.episode_history:
		_host.add_child(_history_line(episode))
	var bd: DateScoreBreakdown = result.score_breakdown
	var rule_name: String = result.secondary_rule.display_name if result.secondary_rule != null else "?"
	var lines := PackedStringArray([
		"SECONDARY  %s  %s  %s  %+d" % [rule_name, result.secondary_live_text, "Success" if bd.secondary_success else "Failure", bd.secondary_score],
		"LOCATION QUALITY  %+d" % bd.location_quality_score,
		"LOCATION PREFERENCE  %+d" % bd.location_preference_score,
		"OUTFIT  %+d" % bd.outfit_score,
		"Качество квартиры: %+d" % bd.apartment_quality_score,
		"Подготовка квартиры: %+d" % bd.apartment_preparation_score,
		"TOTAL  %+d" % bd.total,
		"RELATIONSHIP  %d → %d" % [session.relationship_before, session.relationship_after],
	])
	if result.relationship_max_reached:
		lines.append("relationship_max_reached")
	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = "\n".join(lines)
	_host.add_child(summary)
	var next := LabUi.button("НАЧАТЬ СЛЕДУЮЩЕЕ СВИДАНИЕ")
	next.pressed.connect(func() -> void:
		_engine = null
		rebuild()
	)
	_host.add_child(next)
	_host.add_child(_debug_panel(session, null))


func _history_line(episode: DateEpisodeResult) -> Label:
	var situation: DateSituation = _engine.catalog().find_situation(episode.situation_id)
	var move: DateMove = _engine.catalog().find_move(episode.move_id)
	var tag: DateTag = _engine.catalog().find_tag(episode.tag_id)
	var phase_label: String = DateTypes.phase_name(episode.phase)
	if episode.phase == DateTypes.DatePhase.CORE:
		phase_label = "CORE %d" % (episode.episode_index)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s\nSituation: %s\nMove: %s\nTag: %s\nScore: %+d" % [
		phase_label,
		situation.display_name if situation != null else String(episode.situation_id),
		move.display_name if move != null else String(episode.move_id),
		tag.display_name if tag != null else String(episode.tag_id),
		episode.score_delta,
	]
	return label


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
	var situation_id: String = ""
	if view != null and view.situation != null:
		situation_id = String(view.situation.id)
	return "\n".join(PackedStringArray([
		"seed: %d" % session.seed,
		"session_id: %s" % session.session_id,
		"girl_id: %s" % String(session.girl_id),
		"location_id: %s" % String(session.location_id),
		"outfit_id: %s" % String(session.outfit_id),
		"phase: %s" % DateTypes.phase_name(session.current_phase),
		"episode_index: %d" % session.current_episode_index,
		"situation_id: %s" % situation_id,
		"candidate_base_move_ids: %s" % str(session.current_candidate_base_move_ids),
		"selected_base_move_ids: %s" % str(session.current_selected_base_move_ids),
		"applicable_unlockable_move_ids: %s" % str(session.current_applicable_unlockable_move_ids),
		"selected_move_id: %s" % String(session.current_selected_move_id),
		"resolved_tag_id: %s" % String(session.current_resolved_tag_id),
		"tag_preference: %d" % session.current_tag_preference,
		"score_delta: %d" % session.current_score_delta,
		"secondary_internal_state: %s" % str(session.secondary_runtime_state),
		"score_breakdown: %s" % str(session.score_breakdown.to_dictionary() if session.score_breakdown != null else {}),
	]))
