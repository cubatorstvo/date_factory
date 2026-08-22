class_name DateSystemLab
extends Control

const SECTIONS: Array[Array] = [
	["date", "СВИДАНИЕ"],
	["girls", "ДЕВУШКИ"],
	["girl_difficulty", "СЛОЖНОСТЬ ДЕВУШЕК"],
	["tags", "ТЕГИ"],
	["base_moves", "БАЗОВЫЕ ХОДЫ"],
	["characteristic_moves", "ХОДЫ ХАРАКТЕРИСТИК"],
	["outfit_moves", "ХОДЫ ОДЕЖДЫ"],
	["situations", "СИТУАЦИИ"],
	["venues", "МЕСТА СВИДАНИЯ"],
	["local_objects", "ЛОКАЛЬНЫЕ ОБЪЕКТЫ"],
	["local_moves", "ЛОКАЛЬНЫЕ ХОДЫ"],
	["outfits", "НАРЯДЫ"],
	["characteristics", "ХАРАКТЕРИСТИКИ"],
	["rules", "ПРАВИЛА СВИДАНИЯ"],
	["balance", "БАЛАНС"],
	["test_state", "ТЕСТОВОЕ СОСТОЯНИЕ"],
	["validation", "ВАЛИДАЦИЯ"],
]

var catalog_service: DateCatalogService = DateCatalogService.new()
var progress_store: DateProgressStore = DateProgressStore.new()
var validator: ContentValidator = ContentValidator.new()

var _section: String = "date"
var _status: Label
var _content_host: Control
var _play_panel: DatePlayPanel
var _search: LineEdit
var _list: ItemList
var _form_host: VBoxContainer
var _draft: Resource
var _selected_index: int = -1
var _dirty: bool = false
var _editor_root: Control
var _save_bar: HBoxContainer
var _run_label: Label
var _game_time_label: Label
var _campaign_label: Label
var _action_result_label: Label
var _action_status_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	LabUi.apply_theme(self)
	var bg := ColorRect.new()
	bg.color = LabUi.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	catalog_service.load_catalog()
	if catalog_service.catalog == null:
		var factory := SeedContentFactory.new()
		catalog_service.catalog = factory.build_catalog()
		factory.export_to_disk()
		catalog_service.load_catalog()
	progress_store.load_store(catalog_service.catalog)
	if _save_manager().has_save():
		_save_manager().load_game()
	else:
		_save_manager().new_game()
	randomize()
	_build_shell()


func _build_shell() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var header := VBoxContainer.new()
	var top := HBoxContainer.new()
	top.add_child(LabUi.heading("DATE SYSTEM LAB"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	_run_label = Label.new()
	_run_label.add_theme_color_override("font_color", LabUi.MUTED)
	top.add_child(_run_label)
	var new_btn := LabUi.button("Новая игра")
	new_btn.pressed.connect(_new_playthrough)
	top.add_child(new_btn)
	var save_btn := LabUi.button("Сохранить")
	save_btn.pressed.connect(_save_playthrough)
	top.add_child(save_btn)
	var load_btn := LabUi.button("Загрузить")
	load_btn.pressed.connect(_load_playthrough)
	top.add_child(load_btn)
	_status = Label.new()
	_status.text = "Готово"
	_status.add_theme_color_override("font_color", LabUi.MUTED)
	top.add_child(_status)
	header.add_child(top)
	var time_row := HBoxContainer.new()
	time_row.add_theme_constant_override("separation", 8)
	_game_time_label = Label.new()
	_game_time_label.add_theme_color_override("font_color", LabUi.TEXT)
	time_row.add_child(_game_time_label)
	for pair in [[30, "+30 MIN"], [120, "+120 MIN"], [1440, "+1 DAY"]]:
		var minutes: int = int(pair[0])
		var btn := LabUi.button(str(pair[1]))
		btn.pressed.connect(_apply_test_action.bind(minutes))
		time_row.add_child(btn)
	_campaign_label = Label.new()
	_campaign_label.add_theme_color_override("font_color", LabUi.TEXT)
	time_row.add_child(_campaign_label)
	var complete_btn := LabUi.button("COMPLETE CURRENT STAGE")
	complete_btn.pressed.connect(_complete_current_stage)
	time_row.add_child(complete_btn)
	header.add_child(time_row)
	var actions_row := HBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 8)
	var actions_title := Label.new()
	actions_title.text = "GAME ACTIONS"
	actions_title.add_theme_color_override("font_color", LabUi.TEXT)
	actions_row.add_child(actions_title)
	_action_status_label = Label.new()
	_action_status_label.add_theme_color_override("font_color", LabUi.TEXT)
	actions_row.add_child(_action_status_label)
	for pair in [[GameActionCatalog.ID_TEST_WAIT, "WAIT +120 MIN"], [GameActionCatalog.ID_TEST_EARN_MONEY, "EARN 100"], [GameActionCatalog.ID_TEST_SPEND_MONEY, "SPEND 50"], [GameActionCatalog.ID_TEST_REQUIRE_MONEY, "REQUIRE 100"]]:
		var action_id: StringName = pair[0]
		var action_btn := LabUi.button(str(pair[1]))
		action_btn.pressed.connect(_execute_catalog_action.bind(action_id))
		actions_row.add_child(action_btn)
	_action_result_label = Label.new()
	_action_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_result_label.add_theme_color_override("font_color", LabUi.MUTED)
	actions_row.add_child(_action_result_label)
	header.add_child(actions_row)
	var clock: Variant = _time_service()
	if clock != null and not clock.time_advanced.is_connected(_on_time_advanced):
		clock.time_advanced.connect(_on_time_advanced)
	var stages: Variant = _stage_service()
	if stages != null and not stages.stage_changed.is_connected(_on_stage_changed):
		stages.stage_changed.connect(_on_stage_changed)
	if stages != null and not stages.finale_reached.is_connected(_on_finale_reached):
		stages.finale_reached.connect(_on_finale_reached)
	var actions: Variant = _action_service()
	if actions != null and not actions.action_executed.is_connected(_on_action_executed):
		actions.action_executed.connect(_on_action_executed)
	_refresh_run_label()
	root.add_child(header)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(split)
	var nav := ItemList.new()
	nav.custom_minimum_size = Vector2(240, 0)
	for section in SECTIONS:
		nav.add_item(str(section[1]))
	nav.item_selected.connect(func(index: int) -> void:
		_show_section(str(SECTIONS[index][0]))
	)
	split.add_child(nav)
	_content_host = Control.new()
	_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(_content_host)
	nav.select(0)


func _show_section(section: String) -> void:
	_section = section
	for child in _content_host.get_children():
		_content_host.remove_child(child)
		child.queue_free()
	_play_panel = null
	_editor_root = null
	match section:
		"date":
			_play_panel = DatePlayPanel.new()
			_play_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
			_play_panel.setup(catalog_service, progress_store)
			_content_host.add_child(_play_panel)
			_play_panel.status_message.connect(_set_status)
		"validation":
			_content_host.add_child(_build_validation())
		"balance":
			_content_host.add_child(_build_balance())
		"test_state":
			_content_host.add_child(_build_test_state())
		_:
			_content_host.add_child(_build_editor())


func _set_status(text: String) -> void:
	_status.text = text


func _game_state() -> Variant:
	var node: Node = get_node("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
	return node


func _save_manager() -> Variant:
	var node: Node = get_node("/root/SaveManager")
	if not is_instance_valid(node):
		push_error("SaveManager autoload missing")
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


func _action_service() -> Variant:
	var node: Node = get_node_or_null("/root/ActionService")
	if not is_instance_valid(node):
		push_error("ActionService autoload missing")
	return node


func _execute_catalog_action(action_id: StringName) -> void:
	var actions: Variant = _action_service()
	if actions == null:
		return
	var action: GameAction = actions.get_action(action_id)
	var result: ActionResult = actions.execute(action)
	_show_action_result(result)
	_refresh_run_label()
	if _section == "test_state" or _section == "date":
		_show_section(_section)


func _show_action_result(result: ActionResult) -> void:
	var text: String = _format_action_result(result)
	if _action_result_label != null:
		_action_result_label.text = text
	_set_status(text.replace("\n", " · "))


func _format_action_result(result: ActionResult) -> String:
	if result == null:
		return "FAILED"
	if not result.success:
		return "FAILED\n%s" % result.failure_reason
	var effects_text: String = "—"
	if not result.applied_effects.is_empty():
		effects_text = ", ".join(PackedStringArray(result.applied_effects))
	return "SUCCESS\nAction: %s\nEffects: %s\nTime: %d min" % [
		String(result.action_id),
		effects_text,
		result.time_spent_minutes,
	]


func _refresh_run_label() -> void:
	var gs: Variant = _game_state()
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	if _game_time_label != null and clock != null:
		_game_time_label.text = "GAME TIME\nDay: %d\nTime: %02d:%02d\nAbsolute: %d min" % [
			clock.get_day(),
			clock.get_hour(),
			clock.get_minute(),
			clock.get_game_time_minutes(),
		]
	if _action_status_label != null and clock != null and gs != null:
		_action_status_label.text = "Money: %d\nTime: Day %d %02d:%02d" % [
			gs.player.money,
			clock.get_day(),
			clock.get_hour(),
			clock.get_minute(),
		]
	if _campaign_label != null and stages != null:
		_campaign_label.text = "CAMPAIGN\nStage: %d\nFinale: %s" % [
			stages.get_current_stage(),
			str(stages.is_finale_reached()),
		]
	if _run_label == null:
		return
	var stage: int = gs.story.stage
	if stages != null:
		stage = int(stages.get_current_stage())
	_run_label.text = "Stage %d · Деньги %d" % [stage, gs.player.money]


func _on_time_advanced(_delta_minutes: int, _previous_game_time: int, _current_game_time: int) -> void:
	_refresh_run_label()


func _on_action_executed(_action_id: StringName, result: ActionResult) -> void:
	_show_action_result(result)
	_refresh_run_label()


func _on_stage_changed(_previous_stage: int, _current_stage: int) -> void:
	_refresh_campaign_view()


func _on_finale_reached() -> void:
	_refresh_campaign_view()


func _refresh_campaign_view() -> void:
	_refresh_run_label()
	if _section == "test_state" or _section == "date":
		call_deferred("_show_section", _section)


func _complete_current_stage() -> void:
	var stages: Variant = _stage_service()
	if stages == null:
		return
	stages.force_complete_current_stage_for_dev()


func _apply_test_action(minutes: int) -> void:
	var clock: Variant = _time_service()
	if clock == null:
		return
	var action := GameAction.new()
	action.time_cost_minutes = minutes
	clock.apply_action(action)
	if _section == "test_state":
		_show_section(_section)


func _new_playthrough() -> void:
	_save_manager().new_game()
	_refresh_run_label()
	_set_status("Новое прохождение")
	if _section == "date" or _section == "test_state":
		_show_section(_section)


func _save_playthrough() -> void:
	_save_manager().save_game()
	_set_status("Прохождение сохранено")


func _load_playthrough() -> void:
	var sm: Variant = _save_manager()
	if not sm.has_save():
		_set_status("Нет сохранения")
		return
	if sm.load_game():
		_refresh_run_label()
		_set_status("Прохождение загружено")
		if _section == "date" or _section == "test_state":
			_show_section(_section)
		return
	_set_status("Не удалось загрузить сохранение")


func _build_validation() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(LabUi.heading("Валидация"))
	var btn := LabUi.button("ПРОВЕРИТЬ ВЕСЬ КОНТЕНТ")
	root.add_child(btn)
	var table := RichTextLabel.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.scroll_active = true
	root.add_child(table)
	btn.pressed.connect(func() -> void:
		var issues: Array[ContentValidationIssue] = validator.validate(catalog_service.catalog)
		if issues.is_empty():
			table.text = "Ошибок нет."
			_set_status("Валидация: OK")
			return
		var lines := PackedStringArray(["severity | code | resource_type | resource_id | field | message"])
		for issue in issues:
			var data: Dictionary = issue.to_dictionary()
			lines.append("%s | %s | %s | %s | %s | %s" % [data["severity"], data["code"], issue.resource_type, issue.resource_id, issue.field, issue.message])
		table.text = "\n".join(lines)
		_set_status("Валидация: %d проблем" % issues.size())
	)
	return root


func _build_balance() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.add_child(LabUi.heading("Баланс"))
	var overview := RichTextLabel.new()
	overview.fit_content = true
	overview.scroll_active = false
	overview.bbcode_enabled = false
	overview.text = _balance_overview_text()
	root.add_child(overview)
	var tools := HBoxContainer.new()
	var seeds := SpinBox.new()
	seeds.min_value = 1
	seeds.max_value = 100000
	seeds.value = 10000
	tools.add_child(LabUi.labeled_row("Seeds", seeds))
	var btn := LabUi.button("СИМУЛИРОВАТЬ BASE")
	tools.add_child(btn)
	root.add_child(tools)
	var results := RichTextLabel.new()
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results.scroll_active = true
	root.add_child(results)
	btn.pressed.connect(func() -> void:
		_set_status("Симуляция BASE...")
		results.text = _run_balance_simulation(int(seeds.value))
		_set_status("Симуляция BASE завершена")
	)
	return root


func _balance_overview_text() -> String:
	var catalog: DateContentCatalog = catalog_service.catalog
	var lines := PackedStringArray(["Girl | Difficulty | Positive Tags / 12 | Relationship Max | Trait | Initial Known Tags | Theoretical positive BASE availability"])
	var diagnostics := DateBalanceDiagnostics.new()
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var preset: GirlDifficultyPreset = catalog.find_girl_difficulty(girl.difficulty_preset_id)
		var difficulty_name: String = preset.display_name if preset != null else String(girl.difficulty_preset_id)
		var enabled_count: int = catalog.enabled_tags().size()
		var positive_count: int = girl.positive_tag_ids.size()
		var theory: String = DateBalanceMath.format_percent(diagnostics.theoretical_availability(catalog, girl))
		var girl_trait: GirlTrait = catalog.find_trait(girl.trait_id)
		var trait_name: String = girl_trait.display_name if girl_trait != null else String(girl.trait_id)
		lines.append("%s | %s | %d / %d | %d | %s | %d | %s" % [
			girl.display_name,
			difficulty_name,
			positive_count,
			enabled_count,
			GirlCatalog.seed_relationship_max(girl.id),
			trait_name,
			girl.initial_known_tag_count,
			theory,
		])
	return "\n".join(lines)


func _run_balance_simulation(seed_count: int) -> String:
	var catalog: DateContentCatalog = catalog_service.catalog
	var diagnostics := DateBalanceDiagnostics.new()
	var lines := PackedStringArray()
	for girl in catalog.girls:
		if girl == null or not girl.enabled:
			continue
		var result: Dictionary = diagnostics.simulate_girl(catalog, girl, seed_count)
		lines.append(girl.display_name)
		for row in result["situations"]:
			lines.append("%s | episodes %d | at least one positive BASE %s | all negative BASE %s | average positive BASE %.2f" % [
				str(row["situation_name"]),
				int(row["episodes"]),
				DateBalanceMath.format_percent(float(row["at_least_one"])),
				DateBalanceMath.format_percent(float(row["all_negative"])),
				float(row["average_positive"]),
			])
		lines.append("aggregate | episodes %d | at least one positive BASE %s | all negative BASE %s | average positive BASE %.2f" % [
			int(result["episodes"]),
			DateBalanceMath.format_percent(float(result["at_least_one"])),
			DateBalanceMath.format_percent(float(result["all_negative"])),
			float(result["average_positive"]),
		])
		lines.append("")
	return "\n".join(lines)


func _build_test_state() -> Control:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(LabUi.heading("Тестовое состояние"))
	root.add_child(LabUi.heading("Прохождение"))
	var gs: Variant = _game_state()
	var clock: Variant = _time_service()
	var time_view := Label.new()
	if clock != null:
		time_view.text = "GAME TIME\nDay: %d\nTime: %02d:%02d\nAbsolute: %d min" % [
			clock.get_day(),
			clock.get_hour(),
			clock.get_minute(),
			clock.get_game_time_minutes(),
		]
	root.add_child(time_view)
	var stages: Variant = _stage_service()
	var campaign_view := Label.new()
	if stages != null:
		campaign_view.text = "CAMPAIGN\nStage: %d\nFinale: %s" % [
			stages.get_current_stage(),
			str(stages.is_finale_reached()),
		]
	root.add_child(campaign_view)
	var complete_btn := LabUi.button("COMPLETE CURRENT STAGE")
	complete_btn.pressed.connect(_complete_current_stage)
	root.add_child(complete_btn)
	var money := SpinBox.new()
	money.min_value = 0
	money.max_value = 999999
	money.allow_greater = true
	money.value = gs.player.money
	money.value_changed.connect(func(value: float) -> void:
		_game_state().player.money = int(value)
		_refresh_run_label()
	)
	root.add_child(LabUi.labeled_row("Деньги", money))
	var player: DatePlayerSnapshot = progress_store.player_snapshot
	for stat in catalog_service.catalog.characteristics:
		var spin := SpinBox.new()
		spin.min_value = stat.min_level
		spin.max_value = stat.max_level
		spin.value = player.get_stat(stat.id)
		var stat_id: StringName = stat.id
		spin.value_changed.connect(func(value: float) -> void:
			player.set_stat(stat_id, int(value))
			progress_store.save_store()
			_show_section("test_state")
		)
		root.add_child(LabUi.labeled_row("BaseStat: %s" % stat.display_name, spin))
	var prepared := CheckBox.new()
	prepared.text = "Подготовлена"
	prepared.button_pressed = player.apartment_prepared
	prepared.toggled.connect(func(pressed: bool) -> void:
		player.apartment_prepared = pressed
		progress_store.save_store()
	)
	root.add_child(LabUi.labeled_row("Подготовка квартиры", prepared))
	var current_outfit_id: StringName = _play_panel.get_lab_outfit_id() if _play_panel != null else &"casual"
	var outfit_sel := OptionButton.new()
	LabUi.fill_selector(outfit_sel, catalog_service.catalog.outfits, current_outfit_id)
	outfit_sel.item_selected.connect(func(index: int) -> void:
		if _play_panel != null:
			_play_panel.set_lab_outfit_id(outfit_sel.get_item_metadata(index))
		_show_section("test_state")
	)
	root.add_child(LabUi.labeled_row("Outfit", outfit_sel))
	var outfit: Outfit = catalog_service.catalog.find_outfit(current_outfit_id)
	var bonus_line := Label.new()
	if outfit != null and outfit.stat_bonus > 0:
		var bonus_stat: CharacteristicDefinition = catalog_service.catalog.find_characteristic(outfit.stat_id)
		var bonus_name: String = bonus_stat.display_name if bonus_stat != null else String(outfit.stat_id)
		bonus_line.text = "Outfit bonus: %s +%d" % [bonus_name, outfit.stat_bonus]
	else:
		bonus_line.text = "Outfit bonus: нет"
	root.add_child(bonus_line)
	root.add_child(LabUi.heading("EffectiveStat"))
	for stat in catalog_service.catalog.characteristics:
		var base_value: int = player.get_stat(stat.id)
		var effective: int = DateTypes.effective_stat(base_value, outfit, stat.id)
		var bonus: int = outfit.bonus_for(stat.id) if outfit != null else 0
		var line := Label.new()
		if bonus > 0:
			line.text = "%s: %d (%d + 1 от одежды)" % [stat.display_name, effective, base_value]
		else:
			line.text = "%s: %d" % [stat.display_name, effective]
		root.add_child(line)
	root.add_child(LabUi.heading("Открытые Characteristic Moves"))
	for move in catalog_service.catalog.characteristic_moves():
		if move == null or move.unlock_requirement == null:
			continue
		var current: int = DateTypes.effective_stat(player.get_stat(move.unlock_requirement.stat_id), outfit, move.unlock_requirement.stat_id)
		var unlocked: bool = current >= move.unlock_requirement.required_level
		var row := Label.new()
		var stat: CharacteristicDefinition = catalog_service.catalog.find_characteristic(move.unlock_requirement.stat_id)
		row.text = "%s | %s %d | Effective %d | %s" % [
			move.display_name,
			stat.display_name if stat != null else String(move.unlock_requirement.stat_id),
			move.unlock_requirement.required_level,
			current,
			"Unlocked" if unlocked else "Locked",
		]
		root.add_child(row)
	var outfit_move_line := Label.new()
	if outfit != null and outfit.has_outfit_move():
		var outfit_move: DateMove = catalog_service.catalog.find_move(outfit.outfit_move_id)
		if outfit_move != null:
			var tag: DateTag = catalog_service.catalog.find_tag(outfit_move.fixed_tag_id)
			var tag_name: String = tag.display_name if tag != null else String(outfit_move.fixed_tag_id)
			outfit_move_line.text = "Outfit Move: [%s] %s" % [tag_name, outfit_move.display_name]
		else:
			outfit_move_line.text = "Outfit Move: нет"
	else:
		outfit_move_line.text = "Outfit Move: нет"
	root.add_child(outfit_move_line)
	root.add_child(LabUi.heading("Source use"))
	var session: DateSession = _play_panel._engine.get_session_state() if _play_panel != null and _play_panel._engine != null else null
	var char_used := CheckBox.new()
	char_used.text = "Characteristic used"
	char_used.button_pressed = session != null and session.characteristic_source_used
	char_used.disabled = session == null
	var outfit_used := CheckBox.new()
	outfit_used.text = "Outfit used"
	outfit_used.button_pressed = session != null and session.outfit_source_used
	outfit_used.disabled = session == null
	var venue_used := CheckBox.new()
	venue_used.text = "Venue used"
	venue_used.button_pressed = session != null and session.venue_source_used
	venue_used.disabled = session == null
	var apply_sources := LabUi.button("ПРИМЕНИТЬ SOURCE USE")
	apply_sources.disabled = session == null
	apply_sources.pressed.connect(func() -> void:
		if _play_panel != null:
			_play_panel.apply_lab_source_used(char_used.button_pressed, outfit_used.button_pressed, venue_used.button_pressed)
		_show_section("test_state")
	)
	root.add_child(char_used)
	root.add_child(outfit_used)
	root.add_child(venue_used)
	root.add_child(apply_sources)
	return root

func _build_editor() -> Control:
	_editor_root = VBoxContainer.new()
	_editor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var tools := HBoxContainer.new()
	_search = LineEdit.new()
	_search.placeholder_text = "Поиск"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.text_changed.connect(func(_t: String) -> void:
		_refresh_list()
	)
	tools.add_child(_search)
	for pair in [["Создать", _create_item], ["Дублировать", _duplicate_item], ["Удалить", _delete_item]]:
		var btn := LabUi.button(str(pair[0]))
		btn.pressed.connect(pair[1])
		tools.add_child(btn)
	_editor_root.add_child(tools)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor_root.add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(280, 0)
	_list.item_selected.connect(func(index: int) -> void:
		_select_index(index)
	)
	split.add_child(_list)
	var form_scroll := ScrollContainer.new()
	split.add_child(form_scroll)
	_form_host = VBoxContainer.new()
	_form_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_scroll.add_child(_form_host)
	_save_bar = HBoxContainer.new()
	var save_btn := LabUi.button("Сохранить")
	save_btn.pressed.connect(_save_item)
	var cancel_btn := LabUi.button("Отменить изменения")
	cancel_btn.pressed.connect(_cancel_item)
	_save_bar.add_child(save_btn)
	_save_bar.add_child(cancel_btn)
	_editor_root.add_child(_save_bar)
	_refresh_list()
	if _list.item_count > 0:
		_list.select(0)
		_select_index(0)
	return _editor_root


func _items() -> Array:
	var catalog: DateContentCatalog = catalog_service.catalog
	match _section:
		"girls":
			return catalog.girls
		"girl_difficulty":
			return catalog.girl_difficulty_presets
		"tags":
			return catalog.tags
		"base_moves":
			return _moves_of(DateTypes.DateMoveKind.BASE)
		"characteristic_moves":
			return _moves_of(DateTypes.DateMoveKind.CHARACTERISTIC)
		"outfit_moves":
			return _moves_of(DateTypes.DateMoveKind.OUTFIT)
		"situations":
			return catalog.situations
		"venues":
			return catalog.date_venues
		"local_objects":
			return catalog.local_objects
		"local_moves":
			return _moves_of(DateTypes.DateMoveKind.LOCAL)
		"outfits":
			return catalog.outfits
		"characteristics":
			return catalog.characteristics
		"rules":
			return [catalog.date_rules]
		_:
			return []


func _moves_of(kind: DateTypes.DateMoveKind) -> Array:
	var result: Array = []
	for move in catalog_service.catalog.moves:
		if move.kind == kind:
			result.append(move)
	return result


func _refresh_list() -> void:
	if _list == null:
		return
	_list.clear()
	var query: String = _search.text.to_lower() if _search != null else ""
	var enabled_count: int = catalog_service.catalog.enabled_tags().size() if catalog_service.catalog != null else 0
	for item in _items():
		if item == null:
			continue
		var label: String = "DateRules"
		if _section == "girl_difficulty":
			var positive_count: int = int(item.positive_tag_count)
			label = "%s | %d | %d" % [str(item.display_name), positive_count, maxi(0, enabled_count - positive_count)]
		elif _section == "girls":
			var girl_trait: GirlTrait = catalog_service.catalog.find_trait(item.trait_id) if catalog_service.catalog != null else null
			var trait_name: String = girl_trait.display_name if girl_trait != null else String(item.trait_id)
			label = "%s | %s  [%s]" % [str(item.display_name), trait_name, String(item.id)]
		elif "display_name" in item:
			label = str(item.display_name)
			if "id" in item:
				label = "%s  [%s]" % [label, String(item.id)]
		if query.is_empty() or query in label.to_lower():
			_list.add_item(label)
			_list.set_item_metadata(_list.item_count - 1, item)


func _select_index(index: int) -> void:
	_selected_index = index
	var item: Resource = _list.get_item_metadata(index)
	_draft = item.duplicate(true)
	_dirty = false
	_rebuild_form()


func _rebuild_form() -> void:
	for child in _form_host.get_children():
		_form_host.remove_child(child)
		child.queue_free()
	if _draft == null:
		return
	match _section:
		"tags":
			_add_common_identity(_draft)
		"characteristics":
			_add_common_identity(_draft)
			_add_int(_draft, "min_level", "min_level")
			_add_int(_draft, "max_level", "max_level")
		"outfits":
			_add_common_identity(_draft)
			_add_int(_draft, "price", "price")
			_add_id_selector(_draft, "stat_id", "stat", catalog_service.catalog.characteristics)
			_add_int(_draft, "stat_bonus", "stat_bonus")
			_add_int(_draft, "min_story_stage", "min_story_stage")
			_add_id_selector(_draft, "outfit_move_id", "outfit move", _moves_of(DateTypes.DateMoveKind.OUTFIT))
		"venues":
			_add_common_identity(_draft)
			_add_bool(_draft, "uses_apartment_preparation", "uses_apartment_preparation")
			_add_local_object_id_checks(_draft as DateVenue)
		"local_objects":
			_add_local_object_form()
		"local_moves":
			_add_move_form()
		"situations":
			_add_common_identity(_draft)
			_add_text(_draft, "situation_text", "situation_text")
			_add_phases()
			_add_situation_id_checks("allowed_venue_ids", "Allowed Venue IDs", catalog_service.catalog.date_venues)
			_add_situation_id_checks("allowed_girl_ids", "Allowed Girl IDs", catalog_service.catalog.girls)
			_add_float(_draft, "weight", "weight")
			_add_situation_base_editor()
		"girls":
			_add_girl_form()
		"girl_difficulty":
			_add_difficulty_form()
		"base_moves", "characteristic_moves", "outfit_moves":
			_add_move_form()
		"rules":
			_add_rules_form()


func _add_common_identity(res: Resource) -> void:
	_add_string(res, "id", "id")
	_add_string(res, "display_name", "display_name")
	_add_text(res, "description", "description")
	if "enabled" in res:
		_add_bool(res, "enabled", "enabled")


func _add_string(res: Resource, property: String, title: String) -> void:
	var edit := LineEdit.new()
	edit.text = str(res.get(property))
	edit.text_changed.connect(func(value: String) -> void:
		if property == "id":
			res.set(property, StringName(value))
		else:
			res.set(property, value)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, edit))


func _add_text(res: Resource, property: String, title: String) -> void:
	var edit := TextEdit.new()
	edit.custom_minimum_size = Vector2(0, 90)
	edit.text = str(res.get(property))
	edit.text_changed.connect(func() -> void:
		res.set(property, edit.text)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, edit))


func _add_bool(res: Resource, property: String, title: String) -> void:
	var box := CheckBox.new()
	box.button_pressed = bool(res.get(property))
	box.toggled.connect(func(pressed: bool) -> void:
		res.set(property, pressed)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, box))


func _add_int(res: Resource, property: String, title: String) -> void:
	_add_bounded_int(res, property, title, -99, 99, true)


func _add_bounded_int(res: Resource, property: String, title: String, min_value: int, max_value: int, unbounded: bool = false) -> void:
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.allow_greater = unbounded
	spin.allow_lesser = unbounded
	spin.value = int(res.get(property))
	spin.value_changed.connect(func(value: float) -> void:
		res.set(property, int(value))
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, spin))


func _add_float(res: Resource, property: String, title: String) -> void:
	var spin := SpinBox.new()
	spin.step = 0.1
	spin.min_value = 0
	spin.max_value = 99
	spin.value = float(res.get(property))
	spin.value_changed.connect(func(value: float) -> void:
		res.set(property, value)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, spin))


func _add_enum(res: Resource, property: String, title: String, names: Array) -> void:
	var button := OptionButton.new()
	for i in names.size():
		button.add_item(str(names[i]), i)
	button.select(int(res.get(property)))
	button.item_selected.connect(func(index: int) -> void:
		res.set(property, index)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, button))


func _add_id_selector(res: Resource, property: String, title: String, items: Array) -> void:
	var button := OptionButton.new()
	button.add_item("—", 0)
	button.set_item_metadata(0, StringName())
	var selected: int = 0
	for i in items.size():
		button.add_item(str(items[i].display_name), i + 1)
		button.set_item_metadata(i + 1, items[i].id)
		if items[i].id == res.get(property):
			selected = i + 1
	button.select(selected)
	button.item_selected.connect(func(index: int) -> void:
		res.set(property, button.get_item_metadata(index))
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row(title, button))


func _add_phases() -> void:
	var situation: DateSituation = _draft as DateSituation
	var row := HBoxContainer.new()
	for pair in [[DateTypes.DatePhase.OPENING, "OPENING"], [DateTypes.DatePhase.CORE, "CORE"], [DateTypes.DatePhase.CLOSING, "CLOSING"]]:
		var box := CheckBox.new()
		box.text = str(pair[1])
		box.button_pressed = situation.allowed_phases.has(int(pair[0]))
		var phase_value: int = int(pair[0])
		box.toggled.connect(func(pressed: bool) -> void:
			if pressed and not situation.allowed_phases.has(phase_value):
				situation.allowed_phases.append(phase_value)
			elif not pressed:
				situation.allowed_phases.erase(phase_value)
			_dirty = true
		)
		row.add_child(box)
	_form_host.add_child(LabUi.labeled_row("allowed_phases", row))


func _add_situation_id_checks(property: String, title: String, items: Array) -> void:
	var situation: DateSituation = _draft as DateSituation
	_form_host.add_child(LabUi.heading(title))
	var current: Array = situation.get(property)
	for item in items:
		if item == null:
			continue
		var box := CheckBox.new()
		box.text = "%s [%s]" % [item.display_name, String(item.id)]
		box.button_pressed = current.has(item.id)
		var item_id: StringName = item.id
		box.toggled.connect(func(pressed: bool) -> void:
			var ids: Array = situation.get(property)
			if pressed and not ids.has(item_id):
				ids.append(item_id)
			elif not pressed:
				ids.erase(item_id)
			situation.set(property, ids)
			_dirty = true
		)
		_form_host.add_child(box)


func _add_situation_base_editor() -> void:
	var situation: DateSituation = _draft as DateSituation
	while situation.base_move_ids.size() < 6:
		situation.base_move_ids.append(&"")
	if situation.base_move_ids.size() > 6:
		situation.base_move_ids.resize(6)
	_form_host.add_child(LabUi.heading("BASE Moves: 6"))
	var base_moves: Array = _moves_of(DateTypes.DateMoveKind.BASE)
	for slot in 6:
		var move_id: StringName = situation.base_move_ids[slot]
		var move: DateMove = catalog_service.catalog.find_move(move_id)
		_form_host.add_child(LabUi.heading("BASE %d" % (slot + 1)))
		var selector := OptionButton.new()
		selector.add_item("(не выбран)")
		selector.set_item_metadata(0, &"")
		var selected_index: int = 0
		for i in base_moves.size():
			var candidate: DateMove = base_moves[i]
			if candidate == null:
				continue
			selector.add_item("%s [%s]" % [candidate.display_name, String(candidate.id)])
			var item_index: int = selector.item_count - 1
			selector.set_item_metadata(item_index, candidate.id)
			if candidate.id == move_id:
				selected_index = item_index
		selector.select(selected_index)
		var slot_index: int = slot
		selector.item_selected.connect(func(index: int) -> void:
			situation.base_move_ids[slot_index] = selector.get_item_metadata(index)
			_dirty = true
			_rebuild_form()
		)
		_form_host.add_child(LabUi.labeled_row("Move ID", selector))
		if move == null:
			var missing := Label.new()
			missing.text = "Move не найден."
			_form_host.add_child(missing)
			continue
		var tag_label := Label.new()
		tag_label.text = "Tag: %s" % String(move.fixed_tag_id)
		_form_host.add_child(tag_label)
		_add_text(move, "fixed_option_text", "Option Text")
		_add_text(move, "fixed_positive_result_text", "Positive Result Text")
		_add_text(move, "fixed_negative_result_text", "Negative Result Text")


func _add_situation_move_lists() -> void:
	_add_situation_base_editor()



func _add_girl_form() -> void:
	var girl: GirlProfile = _draft as GirlProfile
	_add_common_identity(girl)
	var rel_max := Label.new()
	rel_max.text = "Relationship Max: %d" % GirlCatalog.seed_relationship_max(girl.id)
	_form_host.add_child(rel_max)
	_add_girl_trait_selector(girl)
	_add_girl_difficulty_selector(girl)
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	var required: int = _positive_tag_required(girl)
	var positive_count: int = girl.positive_tag_ids.size()
	var required_label := Label.new()
	required_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	required_label.text = "Положительных тегов требуется: %d" % required
	_form_host.add_child(required_label)
	var negative_label := Label.new()
	negative_label.text = "Отрицательных тегов: %d" % maxi(0, enabled_count - required)
	_form_host.add_child(negative_label)
	var theory := Label.new()
	theory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var draws: int = 3
	if catalog_service.catalog.date_rules != null:
		draws = catalog_service.catalog.date_rules.base_moves_per_episode
	var chance: float = DateBalanceMath.at_least_one_positive_probability(enabled_count, required, draws)
	theory.text = "Теоретическая базовая доступность положительного тега: %s" % DateBalanceMath.format_percent(chance)
	_form_host.add_child(theory)
	var counter := Label.new()
	counter.text = "Положительные теги: %d / %d" % [positive_count, required]
	_form_host.add_child(counter)
	var grid := GridContainer.new()
	grid.columns = 3
	for header in ["TAG", "НРАВИТСЯ", "НЕ НРАВИТСЯ"]:
		var title := Label.new()
		title.text = header
		grid.add_child(title)
	for tag in catalog_service.catalog.tags:
		if tag == null or not tag.enabled:
			continue
		var name_label := Label.new()
		name_label.text = tag.display_name
		grid.add_child(name_label)
		var selected: bool = girl.positive_tag_ids.has(tag.id)
		var like := CheckBox.new()
		like.button_pressed = selected
		var dislike := Label.new()
		dislike.text = "да" if not selected else "—"
		var tag_id: StringName = tag.id
		like.toggled.connect(func(pressed: bool) -> void:
			_set_girl_liked_tag(girl, tag_id, pressed)
			_dirty = true
			_rebuild_form.call_deferred()
		)
		grid.add_child(like)
		grid.add_child(dislike)
	_form_host.add_child(grid)
	_add_bounded_int(girl, "initial_known_tag_count", "Начально известных Tags", 0, 12)



func _add_girl_trait_selector(girl: GirlProfile) -> void:
	var button := OptionButton.new()
	var selected: int = 0
	for i in catalog_service.catalog.traits.size():
		var girl_trait: GirlTrait = catalog_service.catalog.traits[i]
		if girl_trait == null or not girl_trait.enabled:
			continue
		var index: int = button.item_count
		button.add_item(girl_trait.display_name, index)
		button.set_item_metadata(index, girl_trait.id)
		if girl_trait.id == girl.trait_id:
			selected = index
	if button.item_count == 0:
		button.add_item("—", 0)
		button.set_item_metadata(0, StringName())
	else:
		button.select(selected)
	button.item_selected.connect(func(index: int) -> void:
		girl.trait_id = button.get_item_metadata(index)
		_dirty = true
	)
	_form_host.add_child(LabUi.labeled_row("Trait", button))


func _add_girl_difficulty_selector(girl: GirlProfile) -> void:
	var button := OptionButton.new()
	var selected: int = 0
	var presets: Array[GirlDifficultyPreset] = catalog_service.catalog.enabled_girl_difficulty_presets()
	var current: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(girl.difficulty_preset_id)
	if current != null and not current.enabled:
		presets.append(current)
	for i in presets.size():
		var preset: GirlDifficultyPreset = presets[i]
		button.add_item(preset.display_name, i)
		button.set_item_metadata(i, preset.id)
		if preset.id == girl.difficulty_preset_id:
			selected = i
	if presets.is_empty():
		button.add_item("—", 0)
		button.set_item_metadata(0, StringName())
	else:
		button.select(selected)
	button.item_selected.connect(func(index: int) -> void:
		girl.difficulty_preset_id = button.get_item_metadata(index)
		_dirty = true
		_rebuild_form.call_deferred()
	)
	_form_host.add_child(LabUi.labeled_row("Сложность", button))


func _add_difficulty_form() -> void:
	var preset: GirlDifficultyPreset = _draft as GirlDifficultyPreset
	_add_string(preset, "id", "ID")
	_add_string(preset, "display_name", "Название")
	_add_text(preset, "description", "Описание")
	_add_bool(preset, "enabled", "Enabled")
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	_add_bounded_int(preset, "positive_tag_count", "Количество положительных тегов", 1, maxi(1, enabled_count - 1))
	_add_int(preset, "sort_order", "Порядок")


func _positive_tag_required(girl: GirlProfile) -> int:
	if girl == null or catalog_service.catalog == null:
		return 0
	var preset: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(girl.difficulty_preset_id)
	if preset == null:
		return 0
	return preset.positive_tag_count


func _set_girl_liked_tag(girl: GirlProfile, tag_id: StringName, liked: bool) -> void:
	girl.positive_tag_ids.erase(tag_id)
	if liked:
		girl.positive_tag_ids.append(tag_id)


func _add_move_form() -> void:
	var move: DateMove = _draft as DateMove
	_add_common_identity(move)
	if move.kind == DateTypes.DateMoveKind.LOCAL or move.kind == DateTypes.DateMoveKind.OUTFIT or move.kind == DateTypes.DateMoveKind.CHARACTERISTIC or move.kind == DateTypes.DateMoveKind.BASE:
		_add_id_selector(move, "fixed_tag_id", "tag", catalog_service.catalog.tags)
		_add_text(move, "fixed_option_text", "fixed_option_text")
		_add_text(move, "fixed_positive_result_text", "fixed_positive_result_text")
		_add_text(move, "fixed_negative_result_text", "fixed_negative_result_text")
		if move.kind == DateTypes.DateMoveKind.CHARACTERISTIC or move.kind == DateTypes.DateMoveKind.LOCAL:
			if move.unlock_requirement == null:
				move.unlock_requirement = UnlockRequirement.new()
			_add_id_selector(move.unlock_requirement, "stat_id", "unlock stat", catalog_service.catalog.characteristics)
			_add_int(move.unlock_requirement, "required_level", "required_level")
		return
	_form_host.add_child(LabUi.heading("Mappings"))
	var add_btn := LabUi.button("Добавить mapping")
	add_btn.pressed.connect(func() -> void:
		var mapping := DateMoveSituationMapping.new()
		move.situation_mappings.append(mapping)
		_dirty = true
		_rebuild_form()
	)
	_form_host.add_child(add_btn)
	for i in move.situation_mappings.size():
		_form_host.add_child(_mapping_editor(move, i))

func _add_local_object_form() -> void:
	var local_object: DateLocalObject = _draft as DateLocalObject
	_add_common_identity(local_object)
	_form_host.add_child(LabUi.heading("LOCAL Moves"))
	for move in _moves_of(DateTypes.DateMoveKind.LOCAL):
		var box := CheckBox.new()
		box.text = move.display_name
		box.button_pressed = local_object.move_ids.has(move.id)
		var move_id: StringName = move.id
		box.toggled.connect(func(pressed: bool) -> void:
			if pressed and not local_object.move_ids.has(move_id):
				local_object.move_ids.append(move_id)
			elif not pressed:
				local_object.move_ids.erase(move_id)
			_dirty = true
		)
		_form_host.add_child(box)


func _add_local_object_id_checks(location: DateVenue) -> void:
	_form_host.add_child(LabUi.heading("Local Objects"))
	for local_object in catalog_service.catalog.local_objects:
		if local_object == null:
			continue
		var box := CheckBox.new()
		box.text = local_object.display_name
		box.button_pressed = location.local_object_ids.has(local_object.id)
		var object_id: StringName = local_object.id
		box.toggled.connect(func(pressed: bool) -> void:
			if pressed and not location.local_object_ids.has(object_id):
				location.local_object_ids.append(object_id)
			elif not pressed:
				location.local_object_ids.erase(object_id)
			_dirty = true
		)
		_form_host.add_child(box)


func _mapping_editor(move: DateMove, index: int) -> PanelContainer:
	var mapping: DateMoveSituationMapping = move.situation_mappings[index]
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	var sit := OptionButton.new()
	LabUi.fill_selector(sit, catalog_service.catalog.situations, mapping.situation_id)
	sit.item_selected.connect(func(selected: int) -> void:
		mapping.situation_id = sit.get_item_metadata(selected)
		_dirty = true
	)
	box.add_child(LabUi.labeled_row("Situation", sit))
	var tag := OptionButton.new()
	LabUi.fill_selector(tag, catalog_service.catalog.tags, mapping.tag_id)
	tag.item_selected.connect(func(selected: int) -> void:
		mapping.tag_id = tag.get_item_metadata(selected)
		_dirty = true
	)
	box.add_child(LabUi.labeled_row("Tag", tag))
	for pair in [["option_text", mapping.option_text], ["positive_result_text", mapping.positive_result_text], ["negative_result_text", mapping.negative_result_text]]:
		var edit := TextEdit.new()
		edit.custom_minimum_size = Vector2(0, 60)
		edit.text = str(pair[1])
		var field: String = str(pair[0])
		edit.text_changed.connect(func() -> void:
			mapping.set(field, edit.text)
			_dirty = true
		)
		box.add_child(LabUi.labeled_row(field, edit))
	var remove := Button.new()
	remove.text = "Удалить mapping"
	remove.pressed.connect(func() -> void:
		move.situation_mappings.remove_at(index)
		_dirty = true
		_rebuild_form()
	)
	box.add_child(remove)
	return panel


func _add_rules_form() -> void:
	var rules: DateRules = _draft as DateRules
	for prop in [
		"opening_episode_count", "core_episode_count", "closing_episode_count", "base_moves_per_episode",
		"positive_move_score", "negative_move_score",
		"apartment_unprepared_penalty",
	]:
		_add_int(rules, prop, prop)
	var enabled_count: int = catalog_service.catalog.enabled_tags().size()
	_add_bounded_int(rules, "min_distinct_base_tags_per_situation", "Минимум разных базовых тегов в ситуации", 1, maxi(1, enabled_count))
	_add_bool(rules, "allow_situation_repeats", "allow_situation_repeats")
	_add_bool(rules, "reveal_tag_after_use", "reveal_tag_after_use")
	_add_int(rules, "combo_required_distinct_success_tags", "combo_required_distinct_success_tags")
	_add_int(rules, "combo_bonus_score", "combo_bonus_score")
	_add_int(rules, "combo_max_rewards_per_date", "combo_max_rewards_per_date")


func _kind_name() -> String:
	match _section:
		"girls":
			return "GirlProfile"
		"girl_difficulty":
			return "GirlDifficultyPreset"
		"tags":
			return "DateTag"
		"base_moves", "characteristic_moves", "outfit_moves", "local_moves":
			return "DateMove"
		"situations":
			return "DateSituation"
		"venues":
			return "DateVenue"
		"local_objects":
			return "DateLocalObject"
		"outfits":
			return "Outfit"
		"characteristics":
			return "CharacteristicDefinition"
		"rules":
			return "DateRules"
		_:
			return ""


func _create_item() -> void:
	if _section == "rules":
		return
	var created: Resource = _new_resource()
	catalog_service.add_to_catalog(created)
	_draft = created
	_dirty = true
	_refresh_list()
	_rebuild_form()
	_set_status("Создан черновик. Сохраните, чтобы записать .tres.")


func _new_resource() -> Resource:
	var suffix: String = str(Time.get_ticks_msec())
	match _section:
		"girls":
			var girl := GirlProfile.new()
			girl.id = StringName("girl_%s" % suffix)
			girl.display_name = "Новая девушка"
			var starter: GirlDifficultyPreset = catalog_service.catalog.find_girl_difficulty(&"starter")
			if starter != null:
				girl.difficulty_preset_id = starter.id
			var homebody: GirlTrait = catalog_service.catalog.find_trait(&"homebody") if catalog_service.catalog != null else null
			if homebody != null:
				girl.trait_id = homebody.id
			elif catalog_service.catalog != null and not catalog_service.catalog.traits.is_empty():
				girl.trait_id = catalog_service.catalog.traits[0].id
			return girl
		"girl_difficulty":
			var preset := GirlDifficultyPreset.new()
			preset.id = StringName("difficulty_%s" % suffix)
			preset.display_name = "Новая сложность"
			preset.enabled = true
			preset.positive_tag_count = 4
			preset.sort_order = catalog_service.catalog.girl_difficulty_presets.size()
			return preset
		"tags":
			var tag := DateTag.new()
			tag.id = StringName("tag_%s" % suffix)
			tag.display_name = "Новый тег"
			return tag
		"base_moves", "characteristic_moves", "outfit_moves", "local_moves":
			var move := DateMove.new()
			move.id = StringName("move_%s" % suffix)
			move.display_name = "Новый ход"
			if _section == "characteristic_moves":
				move.kind = DateTypes.DateMoveKind.CHARACTERISTIC
				move.max_uses_per_date = 1
				move.unlock_requirement = UnlockRequirement.new()
			elif _section == "outfit_moves":
				move.kind = DateTypes.DateMoveKind.OUTFIT
			elif _section == "local_moves":
				move.kind = DateTypes.DateMoveKind.LOCAL
			else:
				move.kind = DateTypes.DateMoveKind.BASE
				move.max_uses_per_date = 0
			return move
		"situations":
			var situation := DateSituation.new()
			situation.id = StringName("situation_%s" % suffix)
			situation.display_name = "Новая ситуация"
			situation.allowed_phases = [int(DateTypes.DatePhase.CORE)]
			return situation
		"venues":
			var location := DateVenue.new()
			location.id = StringName("location_%s" % suffix)
			location.display_name = "Новое место"
			return location
		"local_objects":
			var local_object := DateLocalObject.new()
			local_object.id = StringName("local_object_%s" % suffix)
			local_object.display_name = "Новый объект"
			return local_object
		"outfits":
			var outfit := Outfit.new()
			outfit.id = StringName("outfit_%s" % suffix)
			outfit.display_name = "Новый наряд"
			return outfit
		"characteristics":
			var stat := CharacteristicDefinition.new()
			stat.id = StringName("stat_%s" % suffix)
			stat.display_name = "Новая характеристика"
			return stat
		_:
			return Resource.new()


func _duplicate_item() -> void:
	if _draft == null or _section == "rules":
		return
	var copy: Resource = _draft.duplicate(true)
	copy.id = StringName("%s_copy" % String(copy.id))
	copy.display_name = "%s (копия)" % str(copy.display_name)
	catalog_service.add_to_catalog(copy)
	_draft = copy
	_dirty = true
	_refresh_list()
	_rebuild_form()


func _delete_item() -> void:
	if _draft == null or _section == "rules":
		return
	var original: Resource = _list.get_item_metadata(_selected_index)
	var deps: Array[Dictionary] = catalog_service.find_dependents(original.id, _kind_name())
	var dialog := ConfirmationDialog.new()
	if deps.is_empty():
		dialog.dialog_text = "Удалить %s?" % String(original.id)
	else:
		var lines := PackedStringArray(["Объект используется:"])
		for dep in deps:
			lines.append("%s %s (%s)" % [dep["type"], dep["id"], dep["field"]])
		dialog.dialog_text = "\n".join(lines)
	add_child(dialog)
	dialog.confirmed.connect(func() -> void:
		var path: String = catalog_service.path_for(original)
		catalog_service.remove_from_catalog(original)
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		catalog_service.save_catalog()
		_draft = null
		_refresh_list()
		_rebuild_form()
		_set_status("Удалено.")
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)
	dialog.popup_centered()


func _save_item() -> void:
	if _draft == null:
		return
	var temp_catalog: DateContentCatalog = catalog_service.catalog.snapshot()
	_swap_into(temp_catalog, _draft)
	var issues: Array[ContentValidationIssue] = validator.validate(temp_catalog)
	var blocking: Array[ContentValidationIssue] = []
	for issue in issues:
		if issue.severity != DateTypes.ValidationSeverity.ERROR:
			continue
		if issue.resource_id == String(_draft.get("id")) or _section == "rules":
			blocking.append(issue)
	if not blocking.is_empty() and _section != "rules":
		_set_status("Сохранение отклонено: %s" % blocking[0].message)
		return
	var original: Resource = _list.get_item_metadata(_selected_index) if _selected_index >= 0 and _selected_index < _list.item_count else null
	var path: String = catalog_service.path_for(original) if original != null else ""
	if path.is_empty():
		path = catalog_service.default_path_for(_kind_name(), String(_draft.get("id")))
	_draft.resource_path = path
	var err: Error = catalog_service.save_resource(_draft, path)
	if err != OK:
		_set_status("Ошибка ResourceSaver: %d" % err)
		return
	_replace_original(_draft)
	catalog_service.save_catalog()
	catalog_service.reload()
	progress_store.load_store(catalog_service.catalog)
	_set_status("Сохранено: %s" % path)
	_dirty = false
	_refresh_list()


func _cancel_item() -> void:
	if _selected_index >= 0:
		_select_index(_selected_index)
		_set_status("Изменения отменены.")


func _swap_into(catalog: DateContentCatalog, draft: Resource) -> void:
	if draft is DateRules:
		catalog.date_rules = draft
		return
	var arrays: Array = [catalog.tags, catalog.moves, catalog.situations, catalog.girls, catalog.girl_difficulty_presets, catalog.local_objects, catalog.date_venues, catalog.outfits, catalog.characteristics]
	for arr in arrays:
		for i in arr.size():
			if arr[i] != null and arr[i].id == draft.get("id"):
				arr[i] = draft
				return
	if draft is DateTag:
		catalog.tags.append(draft)
	elif draft is DateMove:
		catalog.moves.append(draft)
	elif draft is DateSituation:
		catalog.situations.append(draft)
	elif draft is GirlProfile:
		catalog.girls.append(draft)
	elif draft is GirlDifficultyPreset:
		catalog.girl_difficulty_presets.append(draft)
	elif draft is DateLocalObject:
		catalog.local_objects.append(draft)
	elif draft is DateVenue:
		catalog.date_venues.append(draft)
	elif draft is Outfit:
		catalog.outfits.append(draft)
	elif draft is CharacteristicDefinition:
		catalog.characteristics.append(draft)


func _replace_original(draft: Resource) -> void:
	if draft is DateRules:
		catalog_service.catalog.date_rules = draft
		return
	var found: bool = false
	var arrays: Array = [
		catalog_service.catalog.tags, catalog_service.catalog.moves, catalog_service.catalog.situations,
		catalog_service.catalog.girls, catalog_service.catalog.girl_difficulty_presets, catalog_service.catalog.local_objects,
		catalog_service.catalog.date_venues, catalog_service.catalog.outfits, catalog_service.catalog.characteristics,
	]
	for arr in arrays:
		for i in arr.size():
			if arr[i] != null and arr[i].id == draft.get("id"):
				arr[i] = draft
				found = true
	if not found:
		catalog_service.add_to_catalog(draft)
