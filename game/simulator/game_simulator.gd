class_name GameSimulator
extends Control

const SECTIONS: Array[Array] = [
	["home", "Главная"],
	["work", "Работа"],
	["city", "Город"],
	["girls", "Девушки"],
	["rivals", "Соперники"],
	["dates", "Свидания"],
	["apartment", "Квартира"],
	["clothing", "Одежда"],
	["furniture_store", "Мебель"],
	["progression", "Прокачка"],
]

var _section: String = "home"
var _last_result_text: String = ""
var _hud_time_label: Label
var _hud_money_label: Label
var _hud_rating_label: RichTextLabel
var _hud_stage_label: RichTextLabel
var _finale_label: Label
var _result_label: Label
var _load_button: Button
var _delete_button: Button
var _section_host: VBoxContainer
var _nav_buttons: Dictionary = {}
var _action_buttons: Array[GameActionButton] = []
var _home_summary: Label
var _home_goal: Label
var _home_result: Label
var _upgrade_status_label: Label
var _upgrade_price_label: Label
var _city_current_label: Label
var _world_dev_option: OptionButton
var _refreshing: bool = false
var _refresh_queued: bool = false
var _rebuilding_section: bool = false
var _date_overlay: DatePlayPanel
var _date_overlay_layer: CanvasLayer
var _invite_girl_id: StringName = &""
var _selected_date_venue_id: StringName = &""
var _selected_outfit_id: StringName = &""
var _selected_backup_outfit_id: StringName = &""
var _express_styling: bool = false
var _work_include_overtime: bool = false
var _hud_characteristics_label: RichTextLabel
var _factory_status: Label
var _factory_slider: HSlider
var _objective_panel: ObjectivePanel
var _guidance_layer: CanvasLayer
var _guidance_popup: GuidancePopup


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	LabUi.apply_theme(self)
	var bg := ColorRect.new()
	bg.color = LabUi.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_shell()
	_connect_core_signals()
	_ensure_guidance_popup()
	show_section("home")
	_request_objectives_intro()


func refresh() -> void:
	if not is_inside_tree() or _refreshing:
		return
	_refreshing = true
	if _section == "factory" and not _is_factory_unlocked():
		_section = "home"
	if _section == "city" or _section == "girls" or _section == "dates" or _section == "rivals" or _section == "progression" or _section == "apartment" or _section == "clothing" or _section == "furniture_store" or _section == "factory":
		_rebuild_section()
	_refresh_hud()
	_refresh_objective_panel()
	_refresh_home()
	_refresh_progression()
	_refresh_save_buttons()
	_refresh_nav()
	for button in _action_buttons:
		if is_instance_valid(button):
			button.refresh()
	if _result_label != null:
		_result_label.text = _last_result_text
	_refreshing = false


func _request_refresh() -> void:
	if not is_inside_tree() or _refreshing or _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_flush_refresh")


func _flush_refresh() -> void:
	_refresh_queued = false
	if is_inside_tree():
		refresh()


func show_section(section_id: String) -> void:
	if section_id == "factory" and not _is_factory_unlocked():
		return
	_section = section_id
	_rebuild_section()
	_refresh_nav()
	refresh()


func get_current_section() -> String:
	return _section


func start_new_game() -> void:
	_close_date_overlay()
	_clear_date_invite()
	var sm: Variant = _save_manager()
	if sm == null:
		return
	sm.new_game()
	_last_result_text = ""
	refresh()
	_request_objectives_intro()


func save_playthrough() -> void:
	var sm: Variant = _save_manager()
	if sm == null:
		return
	sm.save_game()
	_last_result_text = "Игра сохранена."
	refresh()


func load_playthrough() -> void:
	var sm: Variant = _save_manager()
	if sm == null:
		return
	if not sm.has_save():
		_last_result_text = "Нет сохранения."
		refresh()
		return
	if sm.load_game():
		_last_result_text = ""
		_close_date_overlay()
		_clear_date_invite()
		_restore_active_date_overlay()
		refresh()
		return
	_last_result_text = "Не удалось загрузить сохранение."
	refresh()


func delete_playthrough() -> void:
	var sm: Variant = _save_manager()
	if sm == null:
		return
	sm.delete_save()
	refresh()


func advance_factory_hour() -> void:
	var clock: Variant = _time_service()
	if clock == null:
		return
	clock.advance_time(60)


func complete_current_stage() -> void:
	var stages: Variant = _stage_service()
	if stages == null:
		return
	stages.force_complete_current_stage_for_dev()
	refresh()

func execute_catalog_action(action_id: StringName) -> ActionResult:
	var actions: Variant = _action_service()
	var result := ActionResult.new()
	if actions == null:
		result.success = false
		result.failure_reason = "ActionService autoload missing"
		_on_action_resolved(result)
		return result
	var action: GameAction = actions.get_action(action_id)
	result = actions.execute(action)
	_on_action_resolved(result)
	return result


func enter_world_location(location_id: StringName) -> bool:
	var world: Variant = _world_service()
	if world == null:
		return false
	var ok: bool = bool(world.enter_location(location_id))
	refresh()
	return ok


func exit_world_interior() -> bool:
	var world: Variant = _world_service()
	if world == null:
		return false
	var location: LocationDefinition = world.get_current_location()
	if location == null or location.parent_location_id == &"":
		return false
	return enter_world_location(location.parent_location_id)


func meet_girl(girl_id: StringName) -> ActionResult:
	var girls: Variant = _girls_service()
	var actions: Variant = _action_service()
	var result := ActionResult.new()
	if girls == null or actions == null:
		result.success = false
		result.failure_reason = "GirlsService autoload missing"
		_on_action_resolved(result)
		return result
	var action: GameAction = girls.create_meet_girl_action(girl_id)
	result = actions.execute(action)
	_on_action_resolved(result)
	return result


func invite_girl(girl_id: StringName) -> void:
	_invite_girl_id = girl_id
	_selected_date_venue_id = &""
	var equipment: Variant = _equipment_service()
	if equipment != null:
		_selected_outfit_id = equipment.get_current_outfit_id()
	else:
		_selected_outfit_id = OutfitCatalog.START_OUTFIT_ID
	show_section("dates")


func select_date_venue(date_venue_id: StringName) -> void:
	_selected_date_venue_id = date_venue_id
	refresh()


func select_date_outfit(outfit_id: StringName) -> void:
	_selected_outfit_id = outfit_id
	if _selected_backup_outfit_id == outfit_id:
		_selected_backup_outfit_id = &""
	refresh()


func wear_owned_outfit(outfit_id: StringName) -> void:
	var equipment: Variant = _equipment_service()
	if equipment != null:
		equipment.equip_outfit(outfit_id)
	refresh()


func start_selected_date() -> ActionResult:
	var dating: Variant = _dating_service()
	var actions: Variant = _action_service()
	var result := ActionResult.new()
	if dating == null or actions == null:
		result.success = false
		result.failure_reason = "DatingService autoload missing"
		_on_action_resolved(result)
		return result
	if _invite_girl_id == &"" or _selected_date_venue_id == &"":
		result.success = false
		result.failure_reason = "Это место сейчас недоступно"
		_on_action_resolved(result)
		return result
	var girls: Variant = _girls_service()
	var on_cooldown: bool = dating != null and not bool(dating.is_free_date_available_today(_invite_girl_id))
	var urgent_taxi: bool = on_cooldown and girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI))
	var action: GameAction = dating.create_start_date_action(_invite_girl_id, _selected_date_venue_id, _selected_outfit_id, {
		"backup_outfit_id": _selected_backup_outfit_id,
		"express_styling": _express_styling,
		"urgent_taxi": urgent_taxi,
	})
	result = actions.execute(action)
	if result.success:
		_clear_date_invite()
	_on_action_resolved(result)
	return result


func cancel_date_invite() -> void:
	_clear_date_invite()
	refresh()


func meet_rival(rival_id: StringName) -> ActionResult:
	var rivals: Variant = _rivals_service()
	var actions: Variant = _action_service()
	var result := ActionResult.new()
	if rivals == null or actions == null:
		result.success = false
		result.failure_reason = "RivalsService autoload missing"
		_on_action_resolved(result)
		return result
	var action: GameAction = rivals.create_meet_rival_action(rival_id)
	result = actions.execute(action)
	_on_action_resolved(result)
	return result


func start_competition(competition_id: StringName) -> ActionResult:
	var competitions: Variant = _competition_service()
	var actions: Variant = _action_service()
	var result := ActionResult.new()
	if competitions == null or actions == null:
		result.success = false
		result.failure_reason = "CompetitionService autoload missing"
		_on_action_resolved(result)
		return result
	var action: GameAction = competitions.create_competition_action(competition_id)
	result = actions.execute(action)
	_on_action_resolved(result)
	return result


func unlock_selected_world_location() -> bool:
	var world: Variant = _world_service()
	if world == null or _world_dev_option == null:
		return false
	if _world_dev_option.item_count <= 0:
		return false
	var selected: int = _world_dev_option.selected
	if selected < 0:
		return false
	var location_id: StringName = StringName(str(_world_dev_option.get_item_metadata(selected)))
	var ok: bool = bool(world.unlock_location(location_id))
	refresh()
	return ok


func get_city_current_location_name() -> String:
	if _city_current_label != null:
		return _city_current_label.text
	var world: Variant = _world_service()
	if world == null:
		return ""
	var location: LocationDefinition = world.get_current_location()
	if location == null:
		return String(world.get_current_location_id())
	return location.display_name


func get_city_body_text() -> String:
	if _section_host == null:
		return ""
	var lines := PackedStringArray()
	_collect_label_text(_section_host, lines)
	return "\n".join(lines)


func _collect_label_text(node: Node, lines: PackedStringArray) -> void:
	if node is Label:
		var label: Label = node
		if not label.text.is_empty():
			lines.append(label.text)
	elif node is RichTextLabel:
		var rtl: RichTextLabel = node
		var body: String = rtl.get_parsed_text() if rtl.bbcode_enabled else rtl.text
		if body.is_empty():
			body = rtl.text
		if not body.is_empty():
			lines.append(body)
	elif node is Button:
		var button: Button = node
		if not button.text.is_empty():
			lines.append(button.text)
	for child in node.get_children():
		_collect_label_text(child, lines)


func get_hud_text() -> String:
	return _format_hud_text()

func get_objective_text() -> String:
	if _objective_panel != null:
		return _objective_panel.collect_text()
	var view: ObjectiveView = get_current_objective()
	if view == null or view.title.is_empty():
		return ""
	var lines := PackedStringArray()
	lines.append(view.title)
	var subgoal: ObjectiveSubgoalView = view.current_subgoal()
	if subgoal != null and not subgoal.label.is_empty() and subgoal.label != view.title:
		lines.append(subgoal.label)
		if not subgoal.progress_text.is_empty():
			lines.append(subgoal.progress_text)
	return "\n".join(lines)
func get_current_objective() -> ObjectiveView:
	var objectives: Variant = _objective_service()
	if objectives == null:
		return null
	return objectives.get_current() as ObjectiveView


func get_result_text() -> String:
	return _last_result_text


func is_finale_presented() -> bool:
	var stages: Variant = _stage_service()
	return stages != null and bool(stages.is_finale_reached())


func format_action_result(result: ActionResult) -> String:
	if result == null or not result.success:
		var reason: String = ""
		if result != null:
			reason = result.failure_reason
		return "Действие недоступно.\n%s" % reason
	if String(result.action_id).begins_with("meet_"):
		var meet_lines := PackedStringArray()
		for description in result.applied_effects:
			for line in description.split("\n"):
				if not line.is_empty():
					meet_lines.append(line)
		if result.time_spent_minutes > 0:
			meet_lines.append("Прошло времени: %d минут." % result.time_spent_minutes)
		return "\n".join(meet_lines)
	if String(result.action_id).begins_with("competition_"):
		var competition_lines := PackedStringArray()
		for description in result.applied_effects:
			for line in description.split("\n"):
				if not line.is_empty():
					competition_lines.append(line)
		if result.time_spent_minutes > 0:
			competition_lines.append("Прошло времени: %d минут." % result.time_spent_minutes)
		return "\n".join(competition_lines)
	var lines := PackedStringArray(["Успешно."])
	for description in result.applied_effects:
		lines.append(_format_effect(description))
	if result.money_spent > 0:
		lines.append("Потрачено: %d денег" % result.money_spent)
	if result.time_spent_minutes > 0:
		lines.append("Прошло времени: %d мин." % result.time_spent_minutes)
	return "\n".join(lines)


func _build_shell() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	root.add_child(_build_hud())
	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_nav())
	var section_scroll := ScrollContainer.new()
	section_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(section_scroll)
	_section_host = VBoxContainer.new()
	_section_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_host.add_theme_constant_override("separation", 10)
	section_scroll.add_child(_section_host)
	var log_panel := PanelContainer.new()
	var log_box := VBoxContainer.new()
	log_panel.add_child(log_box)
	log_box.add_child(LabUi.heading("Результат"))
	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_color_override("font_color", LabUi.TEXT)
	log_box.add_child(_result_label)
	root.add_child(log_panel)


func _build_hud() -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.add_child(LabUi.heading("DATE FACTORY"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	_finale_label = Label.new()
	_finale_label.text = "FINALE REACHED"
	_finale_label.add_theme_color_override("font_color", LabUi.ACCENT)
	_finale_label.add_theme_font_size_override("font_size", 20)
	_finale_label.visible = false
	title_row.add_child(_finale_label)
	box.add_child(title_row)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 32)
	_hud_time_label = Label.new()
	_hud_money_label = Label.new()
	_hud_rating_label = GameTermView.create("")
	_hud_stage_label = GameTermView.create("")
	stats.add_child(_hud_time_label)
	stats.add_child(_hud_money_label)
	stats.add_child(_hud_rating_label)
	stats.add_child(_hud_stage_label)
	box.add_child(stats)
	_hud_characteristics_label = GameTermView.create("")
	box.add_child(_hud_characteristics_label)
	_objective_panel = ObjectivePanel.new()
	box.add_child(_objective_panel)
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 8)
	var new_btn := LabUi.button("НОВАЯ ИГРА")
	new_btn.pressed.connect(start_new_game)
	save_row.add_child(new_btn)
	var save_btn := LabUi.button("СОХРАНИТЬ")
	save_btn.pressed.connect(save_playthrough)
	save_row.add_child(save_btn)
	_load_button = LabUi.button("ЗАГРУЗИТЬ")
	_load_button.pressed.connect(load_playthrough)
	save_row.add_child(_load_button)
	_delete_button = LabUi.button("УДАЛИТЬ СОХРАНЕНИЕ")
	_delete_button.pressed.connect(delete_playthrough)
	save_row.add_child(_delete_button)
	box.add_child(save_row)
	var dev_row := HBoxContainer.new()
	dev_row.add_theme_constant_override("separation", 8)
	var dev_mark := Label.new()
	dev_mark.text = "DEV"
	dev_mark.add_theme_color_override("font_color", LabUi.LOCKED)
	dev_row.add_child(dev_mark)
	var stage_btn := LabUi.button("ЗАВЕРШИТЬ ТЕКУЩИЙ STAGE")
	stage_btn.modulate = Color(0.75, 0.7, 0.6)
	stage_btn.pressed.connect(complete_current_stage)
	dev_row.add_child(stage_btn)
	box.add_child(dev_row)
	return panel


func _build_nav() -> Control:
	var nav := VBoxContainer.new()
	nav.custom_minimum_size = Vector2(220, 0)
	nav.add_theme_constant_override("separation", 6)
	nav.add_child(LabUi.heading("Навигация"))
	for pair in SECTIONS:
		var section_id: String = str(pair[0])
		var btn := LabUi.button(str(pair[1]))
		btn.pressed.connect(show_section.bind(section_id))
		nav.add_child(btn)
		_nav_buttons[section_id] = btn
		if section_id == "work":
			var factory_btn := LabUi.button("Фабрика")
			factory_btn.pressed.connect(show_section.bind("factory"))
			factory_btn.visible = false
			nav.add_child(factory_btn)
			_nav_buttons["factory"] = factory_btn
	return nav


func _rebuild_section() -> void:
	if _rebuilding_section:
		return
	_rebuilding_section = true
	_action_buttons.clear()
	_home_summary = null
	_home_result = null
	_upgrade_status_label = null
	_upgrade_price_label = null
	_city_current_label = null
	_world_dev_option = null
	_factory_status = null
	_factory_slider = null
	if _section_host == null:
		_rebuilding_section = false
		return
	for child in _section_host.get_children():
		_section_host.remove_child(child)
		child.queue_free()
	match _section:
		"home":
			_section_host.add_child(_build_home())
		"work":
			_section_host.add_child(_build_work())
		"factory":
			_section_host.add_child(_build_factory())
		"city":
			_section_host.add_child(_build_city())
		"girls":
			_section_host.add_child(_build_girls())
		"rivals":
			_section_host.add_child(_build_rivals())
		"dates":
			_section_host.add_child(_build_dates())
		"apartment":
			_section_host.add_child(_build_apartment())
		"clothing":
			_section_host.add_child(_build_clothing())
		"furniture_store":
			_section_host.add_child(_build_furniture_store())
		"progression":
			_section_host.add_child(_build_progression())
	_rebuilding_section = false


func _build_home() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("Главная"))
	_home_summary = Label.new()
	_home_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_home_summary)
	_home_goal = Label.new()
	_home_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_home_goal)
	var save_btn := LabUi.button("СОХРАНИТЬ")
	save_btn.pressed.connect(save_playthrough)
	box.add_child(save_btn)
	var last_title := Label.new()
	last_title.text = "Последний результат"
	last_title.add_theme_color_override("font_color", LabUi.MUTED)
	box.add_child(last_title)
	_home_result = Label.new()
	_home_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_home_result)
	box.add_child(_build_filler_rewards_dev())
	return box

func _build_work() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("РАБОТА"))
	var current_income: int = WorkService.get_current_shift_income()
	var income_line := Label.new()
	income_line.text = "Доход за смену: $%d" % current_income
	box.add_child(income_line)
	var rank: int = WorkService.get_career_rank()
	var rank_line := Label.new()
	rank_line.text = "Карьера: %d / %d" % [rank, WorkService.MAX_CAREER_RANK]
	box.add_child(rank_line)
	if rank < WorkService.MAX_CAREER_RANK:
		var next_income: int = WorkService.get_next_career_income()
		var next_line := Label.new()
		next_line.text = "Следующее повышение: $%d" % next_income
		box.add_child(next_line)
		var required_capital: int = WorkService.get_next_career_capital_requirement()
		var req_line := Label.new()
		req_line.text = "Требование: Capital %d" % required_capital
		box.add_child(req_line)
		if WorkService.next_rank_requires_connections() and not WorkService.has_career_connections():
			var connections_line := Label.new()
			connections_line.text = "Требование: Карьерные связи"
			box.add_child(connections_line)
		if rank == 1 and not WorkService.has_career_connections():
			var hint := Label.new()
			hint.text = "Дальше одним старанием уже не пробиться.\nГоворят, всем здесь заправляет Начальница шахты."
			box.add_child(hint)
		if WorkService.can_advance_career():
			var advance: GameAction = WorkService.create_career_advancement_action()
			var hours: int = maxi(1, int(advance.time_cost_minutes / 60))
			_add_action_button(box, advance, "Добиться повышения — %d ч — $%d → $%d" % [hours, current_income, next_income], false, false)
	var work: WorkDefinition = WorkService.make_current_work()
	if WorkService.is_work_available_today():
		if WorkService.has_olya_overtime():
			var overtime := CheckBox.new()
			overtime.text = "Остаться на подработку\n+50% к выплате, ×2 времени"
			overtime.button_pressed = _work_include_overtime
			overtime.toggled.connect(func(pressed: bool) -> void:
				_work_include_overtime = pressed
				refresh()
			)
			box.add_child(overtime)
		var action: GameAction = WorkService.create_work_with_overtime_action() if _work_include_overtime and WorkService.has_olya_overtime() else WorkService.create_work_action(work)
		var work_hours: int = maxi(1, int(action.time_cost_minutes / 60))
		var pay: int = 0
		for effect in action.effects:
			if effect is MoneyEffect:
				pay += int((effect as MoneyEffect).amount)
		_add_action_button(box, action, "Работать — %d ч — +%d" % [work_hours, pay], false, false)
	elif WorkService.is_overtime_available_today():
		var done := Label.new()
		done.text = "Обычная смена выполнена"
		box.add_child(done)
		var overtime_work: WorkDefinition = WorkService.make_overtime_work()
		var overtime_action: GameAction = WorkService.create_overtime_action()
		_add_action_button(box, overtime_action, "Выйти на подработку — 1 ч — +%d" % overtime_work.income, false, false)
	else:
		var done := Label.new()
		done.text = "Сегодня уже работали."
		box.add_child(done)
		var again := Label.new()
		again.text = "Следующая смена: завтра."
		box.add_child(again)
	return box

func _build_factory() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("DATE FACTORY"))
	var automation: Variant = _automation_service()
	if automation == null:
		return box
	_factory_status = Label.new()
	_factory_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_factory_status)
	box.add_child(LabUi.heading("РАСПРЕДЕЛЕНИЕ"))
	_factory_slider = HSlider.new()
	_factory_slider.min_value = 0
	_factory_slider.max_value = 100
	_factory_slider.step = 1
	_factory_slider.value = int(automation.get_work_allocation_percent())
	_factory_slider.value_changed.connect(_on_factory_slider_changed)
	box.add_child(_factory_slider)
	if bool(automation.can_expand()):
		var next_scope: StringName = StringName(automation.get_next_expansion_scope())
		var expand_action: GameAction = automation.create_expansion_action(next_scope)
		_add_action_button(box, expand_action, String(automation.get_expansion_action_label(next_scope)), false, false)
	box.add_child(LabUi.heading("УЛУЧШЕНИЯ"))
	var catalog: AutomationCatalog = automation.get_catalog()
	for upgrade in catalog.get_all_upgrades():
		box.add_child(_build_factory_upgrade_card(upgrade, automation))
	var dev := VBoxContainer.new()
	dev.add_theme_constant_override("separation", 6)
	dev.add_child(LabUi.heading("FACTORY DEV"))
	var hour_btn: Button = LabUi.button("+1 ИГРОВОЙ ЧАС")
	hour_btn.modulate = Color(0.75, 0.7, 0.6)
	hour_btn.pressed.connect(advance_factory_hour)
	dev.add_child(hour_btn)
	box.add_child(dev)
	_refresh_factory_status()
	return box

func _build_factory_upgrade_card(upgrade: AutomationUpgradeDefinition, automation: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "%s — %d" % [upgrade.display_name, upgrade.price]
	box.add_child(title)
	if bool(automation.is_upgrade_purchased(upgrade.id)):
		var done := Label.new()
		done.text = "Куплено"
		box.add_child(done)
	else:
		var action: GameAction = automation.create_upgrade_action(upgrade.id)
		_add_action_button(box, action, GameActionLabels.LABEL_BUY, false, false)
	return box


func _build_city() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ГОРОД"))
	box.add_child(LabUi.heading("ТЕКУЩАЯ ЛОКАЦИЯ"))
	var world: Variant = _world_service()
	var location: LocationDefinition = null
	if world != null:
		location = world.get_current_location()
	_city_current_label = Label.new()
	_city_current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if location != null:
		_city_current_label.text = location.display_name
	elif world != null:
		_city_current_label.text = String(world.get_current_location_id())
	else:
		_city_current_label.text = ""
	box.add_child(_city_current_label)
	if location != null and location.location_type == LocationDefinition.LocationType.INTERIOR:
		var exit_btn: Button = LabUi.button("ВЫЙТИ")
		exit_btn.pressed.connect(exit_world_interior)
		box.add_child(exit_btn)
	else:
		box.add_child(LabUi.heading("ДОСТУПНЫЕ МЕСТА"))
		var catalog: LocationCatalog = null
		if world != null:
			catalog = world.get_catalog()
		var zone_id: StringName = LocationCatalog.START_LOCATION_ID
		if location != null:
			zone_id = location.id
		var interiors: Array[LocationDefinition] = []
		if catalog != null:
			interiors = catalog.get_interiors_for_zone(zone_id)
		for interior in interiors:
			box.add_child(_build_city_place_row(interior, world))
	if location != null and location.id == &"furniture_store":
		box.add_child(_build_furniture_store())
	elif location != null and location.id == &"clothing_store":
		box.add_child(_build_clothing())
	elif location != null and location.id == &"apartment":
		box.add_child(_build_apartment())
	box.add_child(_build_city_people())
	box.add_child(_build_world_dev(world))
	return box

func _build_city_place_row(interior: LocationDefinition, world: Variant) -> Control:
	var unlocked: bool = world != null and bool(world.is_location_unlocked(interior.id))
	var title: String = interior.display_name if unlocked else "%s 🔒" % interior.display_name
	title += _objective_marker_suffix(&"", &"", interior.id)
	var row: Button = LabUi.button(title)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.disabled = not unlocked
	row.pressed.connect(enter_world_location.bind(interior.id))
	return row


func _build_city_people() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var girls: Variant = _girls_service()
	var rivals: Variant = _rivals_service()
	var present_girls: Array[GirlDefinition] = []
	var present_rivals: Array[RivalDefinition] = []
	if girls != null:
		present_girls = girls.get_girls_at_current_location()
	if rivals != null:
		present_rivals = rivals.get_rivals_at_current_location()
	if present_girls.is_empty() and present_rivals.is_empty():
		return box
	box.add_child(LabUi.heading("ЛЮДИ"))
	for definition in present_girls:
		box.add_child(_build_city_girl_row(definition, girls))
	for definition in present_rivals:
		box.add_child(_build_city_rival_row(definition, rivals))
	return box


func _build_city_rival_row(definition: RivalDefinition, rivals: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = definition.display_name + _objective_marker_suffix(ObjectiveView.TARGET_RIVAL, definition.id, definition.location_id)
	box.add_child(name_label)
	var discovered: bool = rivals != null and bool(rivals.is_discovered(definition.id))
	if not discovered:
		if rivals != null:
			var action: GameAction = rivals.create_meet_rival_action(definition.id)
			_add_action_button(box, action, "ВСТРЕТИТЬ", false, false)
		return box
	var defeated: bool = bool(rivals.is_defeated(definition.id))
	var status := Label.new()
	status.text = "Статус: %s" % ("Побеждён" if defeated else "Не побеждён")
	box.add_child(status)
	var competitions: Variant = _competition_service()
	if competitions == null:
		return box
	for competition in competitions.get_competitions_for_rival(definition.id):
		box.add_child(_build_rival_competition_row(competition, defeated, competitions, rivals))
	return box

func _build_city_girl_row(definition: GirlDefinition, girls: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = definition.display_name + _objective_marker_suffix(ObjectiveView.TARGET_GIRL, definition.id, definition.location_id)
	box.add_child(name_label)
	var discovered: bool = girls != null and bool(girls.is_discovered(definition.id))
	if discovered:
		var status := Label.new()
		var has_contact: bool = bool(girls.has_contact(definition.id))
		status.text = "Контакт: %s" % ("Да" if has_contact else "Нет")
		box.add_child(status)
		return box
	var meet_statuses: Array[RequirementStatus] = []
	if girls != null:
		meet_statuses = girls.get_meet_requirements_status(definition.id)
	if meet_statuses.is_empty():
		var unknown := Label.new()
		unknown.text = "Вы ещё не знакомы."
		box.add_child(unknown)
	else:
		_add_requirement_lines(box, meet_statuses, "Требования для знакомства:")
	if girls != null:
		var action: GameAction = girls.create_meet_girl_action(definition.id)
		_add_action_button(box, action, "ПОЗНАКОМИТЬСЯ", false, false)
	return box

func _build_world_dev(world: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(LabUi.heading("WORLD DEV"))
	_world_dev_option = OptionButton.new()
	var catalog: LocationCatalog = null
	if world != null:
		catalog = world.get_catalog()
	var has_locked: bool = false
	if catalog != null:
		for location in catalog.get_all_locations():
			if world != null and bool(world.is_location_unlocked(location.id)):
				continue
			has_locked = true
			var index: int = _world_dev_option.item_count
			_world_dev_option.add_item(location.display_name)
			_world_dev_option.set_item_metadata(index, String(location.id))
	var unlock_btn: Button = LabUi.button("UNLOCK LOCATION")
	unlock_btn.disabled = not has_locked
	unlock_btn.pressed.connect(unlock_selected_world_location)
	box.add_child(_world_dev_option)
	box.add_child(unlock_btn)
	return box


func _build_progression() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ПРОКАЧКА"))
	box.add_child(LabUi.heading("ХАРАКТЕРИСТИКИ"))
	var daily: Variant = _daily_activity()
	if daily != null and not bool(daily.is_available(daily.KEY_CHARACTERISTIC_TRAINING, 1)):
		var used := Label.new()
		used.text = "Сегодня уже тренировались.\nСледующая тренировка: завтра."
		used.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(used)
	var characteristics: Variant = _characteristic_service()
	if characteristics == null:
		return box
	var catalog: CharacteristicCatalog = characteristics.get_catalog()
	var seen: Dictionary = {}
	for upgrade in catalog.get_all_upgrades():
		if upgrade == null or not bool(characteristics.is_upgrade_visible(upgrade)):
			continue
		var key: String = String(upgrade.characteristic_id)
		if seen.has(key):
			continue
		seen[key] = true
		box.add_child(_build_characteristic_group(upgrade.characteristic_id, characteristics))
	return box


func _build_characteristic_group(characteristic_id: StringName, characteristics: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var current_value: int = int(characteristics.get_value(characteristic_id))
	var max_level: int = int(characteristics.get_max_level(characteristic_id))
	box.add_child(GameTermView.create("%s: %d/%d" % [CharacteristicIds.display_name(characteristic_id), current_value, max_level]))
	var catalog: CharacteristicCatalog = characteristics.get_catalog()
	var visible: Array[CharacteristicUpgradeDefinition] = []
	for upgrade in catalog.get_upgrades_for_characteristic(characteristic_id):
		if upgrade != null and bool(characteristics.is_upgrade_visible(upgrade)):
			visible.append(upgrade)
	if current_value >= max_level:
		var done := Label.new()
		done.text = "Максимум"
		box.add_child(done)
		return box
	for upgrade in visible:
		var action: GameAction = characteristics.create_upgrade_action(upgrade.id)
		var minutes: int = upgrade.time_cost_minutes
		var label: String = "%s — %d" % [upgrade.display_name, upgrade.price]
		if minutes > 0:
			label += " — %d мин" % minutes
		_add_action_button(box, action, label, false, false)
	return box


func _build_characteristic_upgrade_card(
	upgrade: CharacteristicUpgradeDefinition,
	characteristics: Variant
) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var current_value: int = int(characteristics.get_value(upgrade.characteristic_id))
	var max_level: int = int(characteristics.get_max_level(upgrade.characteristic_id))
	var value_label: RichTextLabel = GameTermView.create(
		"%s: %d/%d" % [CharacteristicIds.display_name(upgrade.characteristic_id), current_value, max_level]
	)
	box.add_child(value_label)
	if bool(characteristics.can_upgrade(upgrade.characteristic_id)):
		var action: GameAction = characteristics.create_upgrade_action(upgrade.id)
		var cost: int = int(characteristics.get_cost_per_level(upgrade.characteristic_id))
		_add_action_button(box, action, "Прокачать до %d — %d" % [current_value + 1, cost], false, false)
	else:
		var done: Label = Label.new()
		done.text = "Максимум"
		box.add_child(done)
	return box


func _build_girls() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ДЕВУШКИ"))
	var girls: Variant = _girls_service()
	var discovered: Array[GirlDefinition] = []
	if girls != null:
		discovered = girls.get_discovered_girls()
	if discovered.is_empty():
		var empty := Label.new()
		empty.text = "Пока нет знакомых девушек."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
		return box
	for definition in discovered:
		box.add_child(_build_discovered_girl_card(definition, girls))
	return box


func _build_discovered_girl_card(definition: GirlDefinition, girls: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = definition.display_name.to_upper() + _objective_marker_suffix(ObjectiveView.TARGET_GIRL, definition.id, definition.location_id)
	box.add_child(name_label)
	var relationship_value: int = 0
	var has_contact: bool = false
	if girls != null:
		relationship_value = int(girls.get_relationship(definition.id))
		has_contact = bool(girls.has_contact(definition.id))
	var relationship_max: int = 0
	if girls != null:
		relationship_max = int(girls.get_relationship_max(definition.id))
	var completed_line: bool = girls != null and bool(girls.is_relationship_completed(definition.id))
	var relationship_text: String = "Отношения: %d / %d — МАКСИМУМ" % [relationship_value, relationship_max] if completed_line else "Отношения: %d / %d" % [relationship_value, relationship_max]
	box.add_child(GameTermView.create(relationship_text))
	var contact_label := Label.new()
	contact_label.text = "Контакт: %s" % ("Да" if has_contact else "Нет")
	box.add_child(contact_label)
	var reward_block: Control = _filler_reward_block(definition.id, girls)
	if reward_block != null:
		box.add_child(reward_block)
	var dating: Variant = _dating_service()
	var date_statuses: Array[RequirementStatus] = []
	if dating != null:
		date_statuses = dating.get_date_requirements_status(definition.id)
	_add_requirement_lines(box, date_statuses, "Требования для свидания:")
	if completed_line:
		return box
	if dating != null and bool(dating.can_start_date(definition.id)):
		var available := Label.new()
		available.text = "Свидание доступно"
		box.add_child(available)
	elif dating != null:
		var wait := Label.new()
		wait.text = "Сегодня уже встречались.\nСледующая встреча: завтра."
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(wait)
	return box


func _build_rivals() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("СОПЕРНИКИ"))
	var rivals: Variant = _rivals_service()
	var competitions: Variant = _competition_service()
	var discovered: Array[RivalDefinition] = []
	if rivals != null:
		discovered = rivals.get_discovered_rivals()
	if discovered.is_empty():
		var empty := Label.new()
		empty.text = "Пока нет знакомых соперников."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
		return box
	for definition in discovered:
		box.add_child(_build_discovered_rival_card(definition, rivals, competitions))
	return box


func _build_discovered_rival_card(definition: RivalDefinition, rivals: Variant, competitions: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = definition.display_name.to_upper() + _objective_marker_suffix(ObjectiveView.TARGET_RIVAL, definition.id, definition.location_id)
	box.add_child(name_label)
	var location_label := Label.new()
	location_label.text = "Локация: %s" % _location_display_name(definition.location_id)
	box.add_child(location_label)
	var defeated: bool = rivals != null and bool(rivals.is_defeated(definition.id))
	var status := Label.new()
	status.text = "Статус: %s" % ("Побеждён" if defeated else "Не побеждён")
	box.add_child(status)
	var rival_competitions: Array[CompetitionDefinition] = []
	if competitions != null:
		rival_competitions = competitions.get_competitions_for_rival(definition.id)
	if rival_competitions.is_empty():
		return box
	box.add_child(LabUi.heading("СОРЕВНОВАНИЯ"))
	for competition in rival_competitions:
		box.add_child(_build_rival_competition_row(competition, defeated, competitions, rivals))
	return box


func _build_rival_competition_row(
	competition: CompetitionDefinition,
	defeated: bool,
	competitions: Variant,
	rivals: Variant = null
) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title: Label = Label.new()
	title.text = competition.display_name
	box.add_child(title)
	var time_label: Label = Label.new()
	time_label.text = "Время: %d минут" % competition.time_cost_minutes
	box.add_child(time_label)
	var wager: Label = Label.new()
	wager.text = "Взнос %d -> Победа %d" % [competition.entry_fee, competition.entry_fee * 2]
	box.add_child(wager)
	var characteristic_label: RichTextLabel = GameTermView.create(
		"Характеристика: %s" % CharacteristicIds.display_name(competition.primary_characteristic_id)
	)
	box.add_child(characteristic_label)
	if competitions != null:
		var chance_label: Label = Label.new()
		var chance: float = float(competitions.get_win_chance(competition.id))
		chance_label.text = "Шанс победы: %d%%" % int(round(chance * 100.0))
		box.add_child(chance_label)
	if rivals != null and bool(rivals.is_story_rival(competition.rival_id)) and defeated:
		var done: Label = Label.new()
		done.text = "Побеждён"
		box.add_child(done)
		return box
	if rivals != null and not bool(rivals.can_challenge_now(competition.rival_id)):
		var wait: Label = Label.new()
		wait.text = "Сегодня уже была попытка.\nСледующая попытка: завтра."
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(wait)
		return box
	if competitions != null:
		var guidance: Variant = _guidance_service()
		if guidance != null:
			guidance.request_tutorial(GuidanceCatalog.ID_RIVAL_INTRO)
		var action: GameAction = competitions.create_competition_action(competition.id)
		var label: String = ("Реванш — взнос %d" % competition.entry_fee) if defeated else ("Вызвать — взнос %d" % competition.entry_fee)
		_add_action_button(box, action, label, false, false)
	return box


func _location_display_name(location_id: StringName) -> String:
	var world: Variant = _world_service()
	if world != null:
		var catalog: LocationCatalog = world.get_catalog()
		if catalog != null:
			var location: LocationDefinition = catalog.get_location(location_id)
			if location != null:
				return location.display_name
	return String(location_id)


func _build_dates() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("СВИДАНИЯ"))
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	if dating != null and bool(dating.has_active_date()):
		box.add_child(_build_active_date_dev(girls, dating))
	if _invite_girl_id != &"":
		box.add_child(_build_date_prep(girls, dating))
		return box
	var contacted: Array[GirlDefinition] = []
	if girls != null:
		contacted = girls.get_contacted_girls()
	if contacted.is_empty():
		var empty := Label.new()
		empty.text = "Сначала получите контакт девушки."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
		return box
	for definition in contacted:
		box.add_child(_build_date_girl_card(definition, girls, dating))
	return box


func _build_date_girl_card(definition: GirlDefinition, girls: Variant, dating: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var name_label := Label.new()
	name_label.text = definition.display_name.to_upper() + _objective_marker_suffix(ObjectiveView.TARGET_DATING, definition.id)
	box.add_child(name_label)
	var relationship_value: int = 0
	var relationship_max: int = 0
	if girls != null:
		relationship_value = int(girls.get_relationship(definition.id))
		relationship_max = int(girls.get_relationship_max(definition.id))
	var relationship_label := Label.new()
	var completed: bool = girls != null and bool(girls.is_relationship_completed(definition.id))
	if completed:
		relationship_label.text = "Отношения: %d / %d — МАКСИМУМ" % [relationship_value, relationship_max]
	else:
		relationship_label.text = "Отношения: %d / %d" % [relationship_value, relationship_max]
	box.add_child(relationship_label)
	var catalog: DateContentCatalog = _date_catalog()
	var profile: GirlProfile = catalog.find_girl(definition.id) if catalog != null else null
	box.add_child(LabUi.trait_block(catalog, profile))
	var progress: GirlProgress = _girl_date_progress(girls, definition.id)
	box.add_child(LabUi.known_preference_block(catalog, progress, profile))
	var reward_block: Control = _filler_reward_block(definition.id, girls)
	if reward_block != null:
		box.add_child(reward_block)
	var date_statuses: Array[RequirementStatus] = []
	if dating != null:
		date_statuses = dating.get_date_requirements_status(definition.id)
	_add_requirement_lines(box, date_statuses, "Требования:", true)
	if completed:
		return box
	var can_start: bool = dating != null and bool(dating.can_start_date(definition.id))
	var can_taxi: bool = dating != null and girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)) and bool(dating.can_start_date(definition.id, true)) and not can_start
	var equipment: Variant = _equipment_service()
	var current_outfit: Outfit = equipment.get_current_outfit() if equipment != null else null
	var required_tier: int = LabUi.required_outfit_tier(definition)
	var current_tier: int = current_outfit.tier if current_outfit != null else LabUi.OUTFIT_TIER_CASUAL
	var casual_blocks: bool = current_tier < required_tier
	if can_start:
		var available := Label.new()
		available.text = "Свидание доступно"
		box.add_child(available)
	var invite_btn: Button = LabUi.button("ПРИГЛАСИТЬ")
	invite_btn.disabled = not can_start and not can_taxi
	if can_start or can_taxi:
		invite_btn.pressed.connect(invite_girl.bind(definition.id))
	box.add_child(invite_btn)
	if casual_blocks:
		box.add_child(GameTermView.create(LabUi.CASUAL_DATE_OUTFIT_MESSAGE))
		box.add_child(GameTermView.create(LabUi.CASUAL_DATE_OUTFIT_REQUIREMENT))
	elif not can_start:
		var wait := Label.new()
		var reason: String = ""
		if dating != null:
			reason = String(dating.get_start_date_failure_reason(definition.id, can_taxi))
		wait.text = reason if not reason.is_empty() else "Сегодня уже встречались.\nСледующая встреча: завтра."
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(wait)
		if can_taxi:
			var taxi := Label.new()
			taxi.text = "Срочное такси — $75\nВстретиться ещё раз сегодня."
			taxi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(taxi)
	return box

func _add_requirement_lines(
	host: Node,
	statuses: Array[RequirementStatus],
	heading: String,
	compact_when_all_met: bool = false
) -> void:
	if statuses.is_empty():
		return
	var all_met: bool = true
	for status in statuses:
		if status == null or not status.is_met:
			all_met = false
			break
	if compact_when_all_met and all_met:
		for status in statuses:
			if status == null:
				continue
			var met_text: String = "✓ %s" % status.description if status.progress_text.is_empty() else "✓ %s — %s" % [status.description, status.progress_text]
			host.add_child(GameTermView.create(met_text))
		return
	if not heading.is_empty():
		var heading_label: Label = Label.new()
		heading_label.text = heading
		host.add_child(heading_label)
	for status in statuses:
		if status == null:
			continue
		var line_text: String = "✓ %s — %s" % [status.description, status.progress_text] if status.is_met else "✗ %s — %s" % [status.description, status.progress_text]
		host.add_child(GameTermView.create(line_text))


func _format_cooldown(minutes: int) -> String:
	var clock: Variant = _time_service()
	if clock != null and clock.has_method("format_duration"):
		return str(clock.format_duration(minutes))
	var safe_minutes: int = maxi(0, minutes)
	var days: int = int(safe_minutes / 1440)
	var hours: int = int((safe_minutes % 1440) / 60)
	if days > 0 and hours > 0:
		return "%d д. %d ч." % [days, hours]
	if days > 0:
		return "%d д." % days
	if hours > 0:
		return "%d ч." % hours
	return "1 ч."


func _build_placeholder(title: String, body: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading(title))
	var label := Label.new()
	label.text = body
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return box


func _build_clothing() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var heading: RichTextLabel = GameTermView.create("ОДЕЖДА" + _objective_marker_suffix(&"", &"", &"clothing_store"))
	heading.add_theme_font_size_override("normal_font_size", 22)
	box.add_child(heading)
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return box
	var current: Outfit = equipment.get_current_outfit()
	if current != null:
		box.add_child(GameTermView.create("Сейчас: %s · %s" % [current.display_name, LabUi.outfit_tier_label(current.tier)]))
	for item in equipment.get_owned_outfits():
		var owned: Outfit = item as Outfit
		if owned == null or owned.id == equipment.get_current_outfit_id():
			continue
		var wear_btn: Button = LabUi.button("Надеть: %s" % owned.display_name)
		wear_btn.pressed.connect(wear_owned_outfit.bind(owned.id))
		box.add_child(wear_btn)
	var stages: Variant = _stage_service()
	var story_stage: int = 1
	if stages != null:
		story_stage = int(stages.get_current_stage())
	for shop_item in equipment.get_shop_outfits():
		var shop_outfit: Outfit = shop_item as Outfit
		if shop_outfit == null:
			continue
		box.add_child(_build_clothing_item_card(shop_outfit, equipment, story_stage))
	return box
func _build_clothing_item_card(outfit: Outfit, equipment: Variant, story_stage: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var catalog: DateContentCatalog = _date_catalog()
	var price: int = int(equipment.get_effective_outfit_price(outfit.id))
	var title := Label.new()
	title.text = "%s — $%d" % [outfit.display_name, price]
	box.add_child(title)
	var bonus_text: String = _outfit_bonus_label(outfit)
	if not bonus_text.is_empty():
		box.add_child(GameTermView.create(bonus_text))
	if outfit.has_outfit_move() and catalog != null:
		var outfit_move: DateMove = catalog.find_move(outfit.outfit_move_id)
		if outfit_move != null:
			var tag: DateTag = catalog.find_tag(outfit_move.fixed_tag_id)
			var tag_name: String = tag.display_name if tag != null else String(outfit_move.fixed_tag_id)
			box.add_child(GameTermView.create("Outfit Move: [%s] %s" % [tag_name, outfit_move.display_name]))
	var stage_line := Label.new()
	stage_line.text = "Требуется Story Stage %d" % outfit.min_story_stage
	stage_line.add_theme_color_override("font_color", LabUi.MUTED)
	box.add_child(stage_line)
	var owned: bool = bool(equipment.owns_outfit(outfit.id))
	if owned:
		var done := Label.new()
		done.text = "Куплено"
		box.add_child(done)
	elif outfit.min_story_stage > story_stage:
		var locked := Label.new()
		locked.text = "Закрыто"
		locked.add_theme_color_override("font_color", LabUi.LOCKED)
		box.add_child(locked)
	else:
		var action: GameAction = equipment.create_buy_outfit_action(outfit.id)
		var label: String = "Купить %s — $%d" % [outfit.display_name, price]
		if price == 0 and bool(equipment.is_marina_gift_price(outfit.id)):
			label = "Купить %s — $0 · Подарок Марины" % outfit.display_name
		_add_action_button(box, action, label, false, false)
	return box

func _outfit_bonus_label(outfit: Outfit) -> String:
	if outfit == null or outfit.stat_id == &"":
		return ""
	var catalog: DateContentCatalog = _date_catalog()
	var stat: CharacteristicDefinition = catalog.find_characteristic(outfit.stat_id) if catalog != null else null
	var stat_name: String = stat.display_name if stat != null else String(outfit.stat_id)
	return "%s +1" % stat_name


func _outfit_status_adjective(outfit_id: StringName) -> String:
	match String(outfit_id):
		"casual":
			return "Повседневная"
		"business":
			return "Деловая"
		"luxury":
			return "Роскошная"
		_:
			return String(outfit_id)


func _outfit_upgrade_adjective(outfit_id: StringName) -> String:
	match String(outfit_id):
		"casual":
			return "Повседневной"
		"business":
			return "Деловой"
		"luxury":
			return "Роскошной"
		_:
			return String(outfit_id)


func _build_apartment() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var apartment: Variant = _apartment_service()
	if apartment == null:
		box.add_child(LabUi.heading("Квартира"))
		return box
	var owned_ids: Array[StringName] = _owned_local_object_ids(apartment)
	var summary := Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = LabUi.apartment_summary_text(
		owned_ids.size(),
		bool(apartment.is_prepared()),
		_accent_object_display_name()
	)
	box.add_child(summary)
	var girls: Variant = _girls_service()
	if girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_LERA_APARTMENT_CLEANING)):
		var cleaning := Label.new()
		cleaning.text = "Клининг Леры: квартира будет подготовлена автоматически."
		cleaning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(cleaning)
	elif not bool(apartment.is_prepared()):
		var clean_action: GameAction = apartment.create_clean_action()
		_add_action_button(box, clean_action, "Убраться в квартире — 30 мин", false, false)
	var objects_heading := Label.new()
	objects_heading.text = "Купленные предметы"
	box.add_child(objects_heading)
	var dating: Variant = _dating_service()
	var catalog: DateContentCatalog = _date_catalog()
	var object_ids: Array[StringName] = owned_ids.duplicate()
	if object_ids.is_empty() and dating != null:
		object_ids = dating.resolve_date_local_object_ids(&"apartment")
	if object_ids.is_empty():
		var empty := Label.new()
		empty.text = "Нет купленных объектов. Мебель покупается в магазине мебели."
		empty.add_theme_color_override("font_color", LabUi.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(empty)
	else:
		for object_id in object_ids:
			box.add_child(LabUi.bbcode_block(_local_object_toolkit_line(catalog, object_id)))
	var store_btn: Button = LabUi.button("МАГАЗИН МЕБЕЛИ")
	store_btn.pressed.connect(show_section.bind("furniture_store"))
	box.add_child(store_btn)
	_add_action_button(box, GameActionCatalog.make_skip_to_08_00(), GameActionLabels.for_id(GameActionCatalog.ID_SKIP_TO_08_00), false, true)
	return box


func _build_furniture_store() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("МАГАЗИН МЕБЕЛИ"))
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return box
	var accent_name: String = _accent_object_display_name()
	var accent_label := Label.new()
	accent_label.text = "Акцент интерьера: %s" % LabUi.apartment_accent_label(accent_name)
	box.add_child(accent_label)
	var catalog: DateContentCatalog = _date_catalog()
	for object_def in _available_apartment_objects(apartment):
		if object_def == null:
			continue
		box.add_child(_build_furniture_item_card(object_def, apartment, catalog))
	if _has_interior_accent_reward():
		box.add_child(_build_accent_assign_block(apartment, catalog))
	return box


func _build_furniture_item_card(object_def: ApartmentObjectDefinition, apartment: Variant, catalog: DateContentCatalog) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var object_id: StringName = object_def.id
	var local_id: StringName = _apartment_object_id(object_def)
	var title := Label.new()
	title.text = "%s — $%d" % [object_def.display_name, object_def.price]
	box.add_child(title)
	var move: DateMove = _object_local_move(object_def, catalog)
	var tag_name: String = "—"
	var move_text: String = ""
	if move != null and catalog != null:
		var tag: DateTag = catalog.find_tag(move.fixed_tag_id)
		tag_name = tag.display_name if tag != null else String(move.fixed_tag_id)
		move_text = move.fixed_option_text.strip_edges()
		if move_text.is_empty():
			move_text = move.display_name
	box.add_child(LabUi.bbcode_block("[%s]" % tag_name))
	var move_line := Label.new()
	move_line.text = move_text if not move_text.is_empty() else "—"
	move_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(move_line)
	var stage_line := Label.new()
	stage_line.text = "Требуется Story Stage %d" % object_def.min_story_stage
	stage_line.add_theme_color_override("font_color", LabUi.MUTED)
	box.add_child(stage_line)
	var owned: bool = bool(apartment.is_object_owned(object_id))
	var owned_line := Label.new()
	owned_line.text = "Куплено" if owned else "Не куплено"
	box.add_child(owned_line)
	var is_accent: bool = local_id == _accent_object_id() or object_id == _accent_object_id()
	var accent := Label.new()
	accent.text = "Акцент: %s" % LabUi.apartment_yes_no(is_accent)
	box.add_child(accent)
	if not owned:
		var action: GameAction = apartment.create_buy_apartment_object_action(object_id)
		_add_action_button(box, action, "Купить %s — $%d" % [object_def.display_name, object_def.price], false, false)
	return box


func _build_accent_assign_block(apartment: Variant, catalog: DateContentCatalog) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(LabUi.heading("АКЦЕНТ ИНТЕРЬЕРА"))
	var current_name: String = _accent_object_display_name()
	var current := Label.new()
	current.text = "Акцент интерьера: %s" % LabUi.apartment_accent_label(current_name)
	box.add_child(current)
	var first_assign: bool = bool(apartment.is_first_accent_assignment())
	var price: int = int(apartment.get_accent_reassignment_price())
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if first_assign:
		hint.text = "Первое назначение бесплатно."
	else:
		hint.text = "Смена акцента: $%d" % price
	box.add_child(hint)
	var owned_ids: Array[StringName] = _owned_local_object_ids(apartment)
	if owned_ids.is_empty():
		var empty := Label.new()
		empty.text = "Сначала купите хотя бы один предмет."
		empty.add_theme_color_override("font_color", LabUi.MUTED)
		box.add_child(empty)
		return box
	for object_id in owned_ids:
		if object_id == _accent_object_id():
			continue
		var local_object: DateLocalObject = catalog.find_local_object(object_id) if catalog != null else null
		var object_name: String = local_object.display_name if local_object != null else String(object_id)
		var action: GameAction = apartment.create_assign_accent_action(object_id)
		var label: String = "Назначить: %s" % object_name
		if first_assign:
			label += " — $0"
		else:
			label += " — $%d" % price
		_add_action_button(box, action, label, false, false)
	return box

func _apartment_object_id(object_def: ApartmentObjectDefinition) -> StringName:
	return LabUi.apartment_object_local_id(object_def)


func _accent_object_id() -> StringName:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return &""
	return apartment.get_accent_object_id()

func _accent_object_display_name() -> String:
	var object_id: StringName = _accent_object_id()
	if object_id == &"":
		return ""
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		return String(object_id)
	var local_object: DateLocalObject = catalog.find_local_object(object_id)
	return local_object.display_name if local_object != null else String(object_id)


func _has_interior_accent_reward() -> bool:
	var apartment: Variant = _apartment_service()
	if apartment == null:
		return false
	return bool(apartment.has_interior_accent_reward())

func _owned_local_object_ids(apartment: Variant = null) -> Array[StringName]:
	var service: Variant = apartment if apartment != null else _apartment_service()
	var empty: Array[StringName] = []
	if service == null:
		return empty
	if service.has_method("get_owned_object_ids"):
		return service.get_owned_object_ids()
	if service.has_method("get_owned_local_object_ids"):
		return service.get_owned_local_object_ids()
	var gs: Variant = _game_state()
	if gs != null and gs.progression != null and gs.progression.apartment != null:
		return gs.progression.apartment.owned_local_object_ids.duplicate()
	return empty


func _available_apartment_objects(apartment: Variant) -> Array:
	var empty: Array = []
	if apartment == null:
		return empty
	if apartment.has_method("get_available_objects"):
		return apartment.get_available_objects()
	var catalog: ApartmentCatalog = apartment.get_catalog()
	if catalog == null:
		return empty
	var result: Array = []
	for object_def in catalog.all_objects():
		if object_def == null:
			continue
		if apartment.has_method("is_object_visible") and not bool(apartment.is_object_visible(object_def)):
			continue
		result.append(object_def)
	return result


func _object_local_move(object_def: ApartmentObjectDefinition, catalog: DateContentCatalog) -> DateMove:
	if object_def == null or catalog == null:
		return null
	var move_id: StringName = &""
	var raw_move: Variant = object_def.get("local_move_id")
	if typeof(raw_move) == TYPE_STRING_NAME:
		move_id = raw_move
	elif typeof(raw_move) == TYPE_STRING:
		move_id = StringName(raw_move)
	if move_id == &"":
		var local_id: StringName = _apartment_object_id(object_def)
		var local_object: DateLocalObject = catalog.find_local_object(local_id)
		if local_object != null and not local_object.move_ids.is_empty():
			move_id = local_object.move_ids[0]
	if move_id == &"":
		return null
	return catalog.find_move(move_id)


func _active_local_move_ids(apartment: Variant) -> Array[StringName]:
	var empty: Array[StringName] = []
	if apartment == null:
		return empty
	if apartment.has_method("get_active_local_move_ids"):
		return apartment.get_active_local_move_ids()
	var catalog: DateContentCatalog = _date_catalog()
	var result: Array[StringName] = []
	for object_id in _owned_local_object_ids(apartment):
		var object_def: ApartmentObjectDefinition = null
		var apartment_catalog: ApartmentCatalog = apartment.get_catalog() if apartment.has_method("get_catalog") else null
		if apartment_catalog != null:
			for item in apartment_catalog.all_objects():
				if item != null and (item.id == object_id or LabUi.apartment_object_local_id(item) == object_id):
					object_def = item
					break
		var move: DateMove = _object_local_move(object_def, catalog)
		if move != null and not result.has(move.id):
			result.append(move.id)
	return result
func _build_active_date_dev(girls: Variant, dating: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var girl_id: StringName = dating.get_active_girl_id()
	var location_id: StringName = dating.get_active_venue_id()
	var girl_name: String = String(girl_id)
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null:
			girl_name = definition.display_name
	var location_name: String = String(location_id)
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service != null and catalog_service.catalog != null:
		var location: DateVenue = catalog_service.catalog.find_venue(location_id)
		if location != null:
			location_name = location.display_name
	var girl_label := Label.new()
	girl_label.text = "Active girl: %s" % girl_name
	box.add_child(girl_label)
	var location_label := Label.new()
	location_label.text = "Location: %s" % location_name
	box.add_child(location_label)
	var outfit_id: StringName = dating.get_active_outfit_id()
	var outfit_name: String = String(outfit_id)
	if catalog_service != null and catalog_service.catalog != null:
		var outfit: Outfit = catalog_service.catalog.find_outfit(outfit_id)
		if outfit != null:
			outfit_name = outfit.display_name
	var outfit_label := Label.new()
	outfit_label.text = "Outfit: %s" % outfit_name
	box.add_child(outfit_label)
	return box


func _build_date_prep(girls: Variant, dating: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var girl_name: String = String(_invite_girl_id)
	var relationship_text := "Отношения: 0 / 0"
	var girl_definition: GirlDefinition = null
	if girls != null:
		girl_definition = girls.get_definition(_invite_girl_id)
		if girl_definition != null:
			girl_name = girl_definition.display_name
		relationship_text = "Отношения: %d / %d" % [int(girls.get_relationship(_invite_girl_id)), int(girls.get_relationship_max(_invite_girl_id))]
	var name_label := Label.new()
	name_label.text = girl_name.to_upper()
	box.add_child(name_label)
	var rel := Label.new()
	rel.text = relationship_text
	box.add_child(rel)
	var progress: GirlProgress = _girl_date_progress(girls, _invite_girl_id)
	var catalog: DateContentCatalog = _date_catalog()
	var profile: GirlProfile = catalog.find_girl(_invite_girl_id) if catalog != null else null
	box.add_child(LabUi.trait_block(catalog, profile))
	box.add_child(LabUi.known_preference_block(catalog, progress, profile))
	box.add_child(_build_date_venue_picker(girls, dating))
	box.add_child(_build_date_outfit_picker(girls, dating))
	box.add_child(_build_backup_outfit_picker(girls, dating))
	box.add_child(_build_prep_stat_block(catalog))
	var selected_outfit: Outfit = catalog.find_outfit(_selected_outfit_id) if catalog != null else null
	var required_tier: int = LabUi.required_outfit_tier(girl_definition)
	var selected_tier: int = selected_outfit.tier if selected_outfit != null else LabUi.OUTFIT_TIER_CASUAL
	var casual_blocks: bool = selected_tier < required_tier
	if casual_blocks:
		box.add_child(GameTermView.create(LabUi.CASUAL_DATE_OUTFIT_MESSAGE))
		box.add_child(GameTermView.create("Требования:"))
		box.add_child(GameTermView.create(LabUi.CASUAL_DATE_OUTFIT_REQUIREMENT))
	elif dating != null:
		_add_requirement_lines(box, dating.get_date_requirements_status(_invite_girl_id), "Требования:", true)
	if dating != null:
		var failure_reason: String = String(dating.get_start_date_failure_reason(_invite_girl_id))
		if not failure_reason.is_empty() and failure_reason != LabUi.CASUAL_DATE_OUTFIT_MESSAGE:
			var reason_label := Label.new()
			reason_label.text = failure_reason
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(reason_label)
	if _selected_date_venue_id != &"" and catalog != null:
		box.add_child(_build_date_start_summary(girls, dating, catalog.find_venue(_selected_date_venue_id)))
	if girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_KIRA_EXPRESS_STYLING)):
		var styling := CheckBox.new()
		styling.text = "Экспресс-стайлинг — $40\nВнешность +1 на это свидание"
		styling.button_pressed = _express_styling
		styling.toggled.connect(func(pressed: bool) -> void:
			_express_styling = pressed
			refresh()
		)
		box.add_child(styling)
	var remaining: int = int(dating.get_date_cooldown_remaining_minutes(_invite_girl_id)) if dating != null else 0
	if remaining > 0 and girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_RITA_URGENT_TAXI)):
		var taxi := Label.new()
		taxi.text = "Срочное такси — $75\nВстретиться ещё раз сегодня."
		taxi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(taxi)
	var confirm := LabUi.button("НАЧАТЬ СВИДАНИЕ")
	confirm.disabled = _selected_date_venue_id == &"" or _selected_outfit_id == &"" or casual_blocks
	confirm.pressed.connect(func() -> void:
		start_selected_date()
	)
	box.add_child(confirm)
	var back_btn: Button = LabUi.button("НАЗАД")
	back_btn.pressed.connect(cancel_date_invite)
	box.add_child(back_btn)
	return box

func _build_date_venue_picker(girls: Variant, dating: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ВЫБЕРИТЕ МЕСТО СВИДАНИЯ"))
	var progress: GirlProgress = _girl_date_progress(girls, _invite_girl_id)
	var catalog: DateContentCatalog = _date_catalog()
	var locations: Array[DateVenue] = LabUi.canonical_date_venues(catalog)
	var available_ids: Dictionary = {}
	if dating != null:
		for item in dating.get_available_date_venues(_invite_girl_id):
			var available_venue: DateVenue = item as DateVenue
			if available_venue != null:
				available_ids[available_venue.id] = true
	for location in locations:
		if location == null:
			continue
		var available: bool = available_ids.has(location.id)
		if dating != null:
			available = bool(dating.is_date_venue_available(_invite_girl_id, location.id))
		box.add_child(_build_date_venue_card(location, dating, available, progress))
	return box

func _build_date_venue_card(location: DateVenue, dating: Variant, available: bool, progress: GirlProgress) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title := Label.new()
	if available:
		title.text = location.display_name
	else:
		title.text = "%s 🔒" % location.display_name
	box.add_child(title)
	box.add_child(LabUi.bbcode_block(_date_venue_details(location, dating, progress), LabUi.MUTED, LabUi.tag_knowledge_map(progress, _date_catalog().find_girl(_invite_girl_id) if _date_catalog() != null else null)))
	var choose_btn: Button = LabUi.button(location.display_name)
	choose_btn.disabled = not available
	if available:
		choose_btn.pressed.connect(select_date_venue.bind(location.id))
	box.add_child(choose_btn)
	return panel


func _date_venue_details(location: DateVenue, dating: Variant, progress: GirlProgress) -> String:
	var catalog: DateContentCatalog = _date_catalog()
	var object_ids: Array[StringName] = []
	if dating != null:
		object_ids = dating.resolve_date_local_object_ids(location.id)
	elif location != null:
		object_ids = location.local_object_ids.duplicate()
	var girl: GirlProfile = catalog.find_girl(_invite_girl_id) if catalog != null else null
	var apartment: Variant = _apartment_service()
	var owned_count: int = -1
	var prepared_state: int = -1
	if apartment != null and (location.id == &"apartment" or location.uses_apartment_preparation):
		owned_count = _owned_local_object_ids(apartment).size()
		prepared_state = 1 if bool(apartment.is_prepared()) else 0
	var girls: Variant = _girls_service()
	var sonya_bonus: bool = girls != null and bool(girls.has_filler_reward(FillerRewardCatalog.ID_SONYA_RESTAURANT_SECOND_VENUE))
	var source_uses: int = 2 if sonya_bonus and location.id == &"restaurant" else 1
	return LabUi.venue_card_bbcode(
		catalog,
		location,
		object_ids,
		progress,
		_date_player_snapshot(),
		girl,
		source_uses,
		owned_count,
		LabUi.APARTMENT_OBJECT_MAX,
		_accent_object_id(),
		sonya_bonus,
		prepared_state
	)


func _date_catalog() -> DateContentCatalog:
	var dating: Variant = _dating_service()
	if dating == null:
		return null
	var catalog_service: Variant = dating.get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog as DateContentCatalog


func _girl_date_progress(girls: Variant, girl_id: StringName) -> GirlProgress:
	var progress := GirlProgress.new()
	progress.girl_id = girl_id
	if girls != null:
		girls.fill_date_progress(girl_id, progress)
	return progress


func _date_player_snapshot() -> DatePlayerSnapshot:
	var player := DatePlayerSnapshot.new()
	var characteristics: Variant = _characteristic_service()
	var catalog: DateContentCatalog = _date_catalog()
	var outfit: Outfit = catalog.find_outfit(_selected_outfit_id) if catalog != null else null
	if characteristics != null:
		for stat_id in DateTypes.CHARACTERISTIC_STAT_ORDER:
			var base_value: int = int(characteristics.get_value(stat_id))
			var extra: int = 1 if _express_styling and stat_id == CharacteristicIds.APPEARANCE else 0
			player.set_stat(stat_id, DateTypes.effective_stat(base_value, outfit, stat_id, extra))
	return player
func _local_object_toolkit_line(catalog: DateContentCatalog, object_id: StringName, progress: GirlProgress = null) -> String:
	return LabUi.local_object_toolkit_bbcode(catalog, object_id, progress, _date_player_snapshot())


func _build_backup_outfit_picker(_girls: Variant, _dating: Variant) -> Control:
	var box := VBoxContainer.new()
	var girls: Variant = _girls_service()
	if girls == null or not bool(girls.has_filler_reward(FillerRewardCatalog.ID_NIKA_BACKUP_OUTFIT)):
		return box
	box.add_theme_constant_override("separation", 8)
	var main_name: String = String(_selected_outfit_id)
	var backup_name: String = "не выбран"
	var catalog: DateContentCatalog = _date_catalog()
	if catalog != null:
		var main_outfit: Outfit = catalog.find_outfit(_selected_outfit_id)
		if main_outfit != null:
			main_name = main_outfit.display_name
		var backup_outfit: Outfit = catalog.find_outfit(_selected_backup_outfit_id)
		if backup_outfit != null:
			backup_name = backup_outfit.display_name
	var main_label := Label.new()
	main_label.text = "Основной наряд: %s" % main_name
	box.add_child(main_label)
	var equipment: Variant = _equipment_service()
	var owned_count: int = 0
	if equipment != null:
		owned_count = equipment.get_owned_outfits().size()
	if owned_count <= 1:
		var wait := Label.new()
		wait.text = "Запасной наряд появится после покупки второго комплекта."
		wait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(wait)
		return box
	var backup_label := Label.new()
	backup_label.text = "Запасной наряд: %s" % backup_name
	box.add_child(backup_label)
	box.add_child(LabUi.heading("ЗАПАСНОЙ НАРЯД"))
	for item in equipment.get_owned_outfits():
		var outfit: Outfit = item as Outfit
		if outfit == null or outfit.id == _selected_outfit_id:
			continue
		var btn: Button = LabUi.button(outfit.display_name if outfit.id != _selected_backup_outfit_id else "%s — выбрано" % outfit.display_name)
		btn.disabled = outfit.id == _selected_backup_outfit_id
		btn.pressed.connect(func() -> void:
			_selected_backup_outfit_id = outfit.id
			refresh()
		)
		box.add_child(btn)
	return box


func _build_date_outfit_picker(_girls: Variant, dating: Variant) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ВЫБЕРИТЕ ОДЕЖДУ"))
	var equipment: Variant = _equipment_service()
	if equipment == null:
		return box
	for item in equipment.get_owned_outfits():
		var outfit: Outfit = item as Outfit
		if outfit == null:
			continue
		box.add_child(_build_date_outfit_card(outfit, dating))
	return box


func _build_date_outfit_card(outfit: Outfit, dating: Variant) -> Control:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var selected: bool = outfit.id == _selected_outfit_id
	var title := Label.new()
	title.text = outfit.display_name if not selected else "%s — выбрано" % outfit.display_name
	box.add_child(title)
	var details := Label.new()
	details.text = _outfit_prep_details(outfit)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(details)
	var choose_btn: Button = LabUi.button(outfit.display_name)
	choose_btn.disabled = selected
	choose_btn.pressed.connect(select_date_outfit.bind(outfit.id))
	box.add_child(choose_btn)
	return panel


func _outfit_prep_details(outfit: Outfit) -> String:
	var catalog: DateContentCatalog = _date_catalog()
	var lines := PackedStringArray()
	var bonus: String = _outfit_bonus_label(outfit)
	if not bonus.is_empty():
		lines.append(bonus)
	var characteristics: Variant = _characteristic_service()
	if characteristics != null and catalog != null:
		for stat in catalog.characteristics:
			var base_value: int = int(characteristics.get_value(stat.id))
			var effective: int = DateTypes.effective_stat(base_value, outfit, stat.id)
			var outfit_bonus: int = outfit.bonus_for(stat.id) if outfit != null else 0
			if outfit_bonus > 0:
				lines.append("%s: %d (%d + 1 от одежды)" % [stat.display_name, effective, base_value])
			else:
				lines.append("%s: %d" % [stat.display_name, effective])
		for move in catalog.characteristic_moves():
			if move.unlock_requirement == null:
				continue
			var without_outfit: int = int(characteristics.get_value(move.unlock_requirement.stat_id))
			var with_outfit: int = DateTypes.effective_stat(without_outfit, outfit, move.unlock_requirement.stat_id)
			if without_outfit < move.unlock_requirement.required_level and with_outfit >= move.unlock_requirement.required_level:
				var tag: DateTag = catalog.find_tag(move.fixed_tag_id)
				var tag_name: String = tag.display_name if tag != null else String(move.fixed_tag_id)
				lines.append("Открывается Characteristic Move:\n[%s] %s" % [tag_name, move.display_name])
	if outfit != null and outfit.has_outfit_move() and catalog != null:
		var outfit_move: DateMove = catalog.find_move(outfit.outfit_move_id)
		if outfit_move != null:
			var tag: DateTag = catalog.find_tag(outfit_move.fixed_tag_id)
			var tag_name: String = tag.display_name if tag != null else String(outfit_move.fixed_tag_id)
			lines.append("Outfit Move:\n[%s] %s" % [tag_name, outfit_move.display_name])
	return "\n".join(lines)


func _build_prep_stat_block(catalog: DateContentCatalog) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(LabUi.heading("ХАРАКТЕРИСТИКИ"))
	var outfit: Outfit = catalog.find_outfit(_selected_outfit_id) if catalog != null else null
	var characteristics: Variant = _characteristic_service()
	if characteristics == null or catalog == null:
		return box
	for stat in catalog.characteristics:
		var base_value: int = int(characteristics.get_value(stat.id))
		var outfit_bonus: int = outfit.bonus_for(stat.id) if outfit != null else 0
		var styling_bonus: int = 1 if _express_styling and String(stat.id) == "appearance" else 0
		var effective: int = DateTypes.effective_stat(base_value, outfit, stat.id, styling_bonus)
		var line := Label.new()
		if outfit_bonus > 0 and styling_bonus > 0:
			line.text = "%s: %d (%d + 1 от одежды + 1 от стайлинга)" % [stat.display_name, effective, base_value]
		elif styling_bonus > 0:
			line.text = "%s: %d (%d + 1 от стайлинга)" % [stat.display_name, effective, base_value]
		elif outfit_bonus > 0:
			line.text = "%s: %d (%d + 1 от одежды)" % [stat.display_name, effective, base_value]
		else:
			line.text = "%s: %d" % [stat.display_name, effective]
		box.add_child(line)
	return box


func _build_date_start_summary(girls: Variant, dating: Variant, selected_venue: DateVenue) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var girl_name: String = String(_invite_girl_id)
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(_invite_girl_id)
		if definition != null:
			girl_name = definition.display_name
	var location_name: String = String(_selected_date_venue_id)
	if selected_venue != null:
		location_name = selected_venue.display_name
	var outfit_name: String = String(_selected_outfit_id)
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null and catalog_service.catalog != null:
			var outfit: Outfit = catalog_service.catalog.find_outfit(_selected_outfit_id)
			if outfit != null:
				outfit_name = outfit.display_name
	var girl_label := Label.new()
	girl_label.text = "Девушка: %s" % girl_name
	box.add_child(girl_label)
	var location_label := Label.new()
	location_label.text = "Место: %s" % location_name
	box.add_child(location_label)
	box.add_child(GameTermView.create("Одежда: %s" % outfit_name))
	return box


func _clear_date_invite() -> void:
	_invite_girl_id = &""
	_selected_date_venue_id = &""
	_selected_outfit_id = &""
	_selected_backup_outfit_id = &""
	_express_styling = false


func _filler_reward_block(girl_id: StringName, girls: Variant) -> Control:
	if girls == null or not girls.has_method("get_filler_reward_for_girl"):
		return null
	var reward: FillerRewardDefinition = girls.get_filler_reward_for_girl(girl_id)
	if reward == null:
		return null
	var box := VBoxContainer.new()
	var title := Label.new()
	if bool(girls.has_filler_reward(reward.id)):
		title.text = "Награда получена:\n%s" % reward.display_name
		box.add_child(title)
		return box
	title.text = "Награда за MAX:\n%s" % reward.display_name
	box.add_child(title)
	var body := Label.new()
	body.text = reward.preview_description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	return box


func _build_filler_rewards_dev() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(LabUi.heading("FILLER REWARDS DEV"))
	var girls: Variant = _girls_service()
	var economy: Variant = _economy_service()
	var characteristics: Variant = _characteristic_service()
	var apartment: Variant = _apartment_service()
	if girls == null:
		return box
	var money_row := HBoxContainer.new()
	for amount in [100, 500, 1000]:
		var btn: Button = LabUi.button("+%d$" % amount)
		btn.modulate = Color(0.75, 0.7, 0.6)
		btn.pressed.connect(func() -> void:
			if economy != null:
				economy.add_money(amount)
			refresh()
		)
		money_row.add_child(btn)
	box.add_child(money_row)
	if characteristics != null:
		var stat_row := HBoxContainer.new()
		for stat_id in [CharacteristicIds.MUSCLE, CharacteristicIds.APPEARANCE, CharacteristicIds.CAPITAL, CharacteristicIds.AURA]:
			var btn: Button = LabUi.button("%s +1" % CharacteristicIds.display_name(stat_id))
			btn.modulate = Color(0.75, 0.7, 0.6)
			btn.pressed.connect(func() -> void:
				characteristics.add_value(stat_id, 1)
				refresh()
			)
			stat_row.add_child(btn)
		box.add_child(stat_row)
	if apartment != null:
		var prep_btn: Button = LabUi.button("Квартира prepared: %s" % ("да" if bool(apartment.is_prepared()) else "нет"))
		prep_btn.modulate = Color(0.75, 0.7, 0.6)
		prep_btn.pressed.connect(func() -> void:
			apartment.set_prepared(not bool(apartment.is_prepared()))
			refresh()
		)
		box.add_child(prep_btn)
	var catalog: FillerRewardCatalog = girls.get_filler_reward_catalog()
	for reward in catalog.get_all_rewards():
		if reward == null:
			continue
		var row := VBoxContainer.new()
		var status: String = "получена" if bool(girls.has_filler_reward(reward.id)) else "не получена"
		var label := Label.new()
		label.text = "%s — %s — %s" % [reward.display_name, String(reward.girl_id), status]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var buttons := HBoxContainer.new()
		var max_btn: Button = LabUi.button("MAX")
		max_btn.modulate = Color(0.75, 0.7, 0.6)
		max_btn.pressed.connect(func() -> void:
			girls.force_complete_filler_for_dev(reward.girl_id)
			refresh()
		)
		buttons.add_child(max_btn)
		var reset_btn: Button = LabUi.button("Сброс")
		reset_btn.modulate = Color(0.75, 0.7, 0.6)
		reset_btn.pressed.connect(func() -> void:
			girls.reset_filler_reward_for_dev(reward.girl_id)
			refresh()
		)
		buttons.add_child(reset_btn)
		var cd_btn: Button = LabUi.button("Cooldown")
		cd_btn.modulate = Color(0.75, 0.7, 0.6)
		cd_btn.pressed.connect(func() -> void:
			var daily: Variant = get_node_or_null("/root/DailyActivityService")
			if daily != null:
				daily.register_usage(daily.date_key(reward.girl_id), 1)
			refresh()
		)
		buttons.add_child(cd_btn)
		row.add_child(buttons)
		box.add_child(row)
	box.add_child(_build_daily_activity_dev())
	return box


func _build_daily_activity_dev() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(LabUi.heading("DAILY ACTIVITY DEV"))
	var daily: Variant = _daily_activity()
	var clock: Variant = _time_service()
	var girls: Variant = _girls_service()
	if daily == null:
		return box
	var status := Label.new()
	status.text = "day_index=%d  work=%d/%d  train=%d  usages=%s" % [
		int(daily.current_day_index()),
		int(daily.usage_today(daily.KEY_WORK)),
		int(daily.work_daily_limit()),
		int(daily.usage_today(daily.KEY_CHARACTERISTIC_TRAINING)),
		str(daily.get_all_usage_today()),
	]
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)
	var row := HBoxContainer.new()
	for count in [0, 1, 2]:
		var btn: Button = LabUi.button("work %d" % count)
		btn.modulate = Color(0.75, 0.7, 0.6)
		btn.pressed.connect(func() -> void:
			daily.set_usage_today(daily.KEY_WORK, count)
			refresh()
		)
		row.add_child(btn)
	box.add_child(row)
	var train_row := HBoxContainer.new()
	var train_off: Button = LabUi.button("train 0")
	train_off.modulate = Color(0.75, 0.7, 0.6)
	train_off.pressed.connect(func() -> void:
		daily.set_usage_today(daily.KEY_CHARACTERISTIC_TRAINING, 0)
		refresh()
	)
	var train_on: Button = LabUi.button("train 1")
	train_on.modulate = Color(0.75, 0.7, 0.6)
	train_on.pressed.connect(func() -> void:
		daily.set_usage_today(daily.KEY_CHARACTERISTIC_TRAINING, 1)
		refresh()
	)
	train_row.add_child(train_off)
	train_row.add_child(train_on)
	box.add_child(train_row)
	var date_row := HBoxContainer.new()
	var date_off: Button = LabUi.button("date alina 0")
	date_off.modulate = Color(0.75, 0.7, 0.6)
	date_off.pressed.connect(func() -> void:
		daily.set_usage_today(daily.date_key(GirlCatalog.ID_ALINA), 0)
		refresh()
	)
	var date_on: Button = LabUi.button("date alina 1")
	date_on.modulate = Color(0.75, 0.7, 0.6)
	date_on.pressed.connect(func() -> void:
		daily.set_usage_today(daily.date_key(GirlCatalog.ID_ALINA), 1)
		refresh()
	)
	date_row.add_child(date_off)
	date_row.add_child(date_on)
	box.add_child(date_row)
	var next_day: Button = LabUi.button("+1 DAY")
	next_day.modulate = Color(0.75, 0.7, 0.6)
	next_day.pressed.connect(func() -> void:
		if clock != null:
			clock.advance_time(1440)
		refresh()
	)
	box.add_child(next_day)
	if girls != null:
		var marina_btn: Button = LabUi.button("marina gift pending")
		marina_btn.modulate = Color(0.75, 0.7, 0.6)
		marina_btn.pressed.connect(func() -> void:
			girls.force_complete_filler_for_dev(GirlCatalog.ID_MARINA)
			refresh()
		)
		box.add_child(marina_btn)
		var rita_btn: Button = LabUi.button("rita taxi")
		rita_btn.modulate = Color(0.75, 0.7, 0.6)
		rita_btn.pressed.connect(func() -> void:
			girls.force_complete_filler_for_dev(GirlCatalog.ID_RITA)
			refresh()
		)
		box.add_child(rita_btn)
	return box


func _add_action_button(host: Node, action: GameAction, label: String, show_title: bool = true, show_meta: bool = true) -> void:
	var button := GameActionButton.new()
	host.add_child(button)
	button.action_resolved.connect(_on_action_resolved)
	button.setup(action, label, show_title, show_meta)
	_action_buttons.append(button)


func _refresh_hud() -> void:
	GameTermTooltipLayer.ensure(self)
	var hud: String = _format_hud_text()
	var parts: PackedStringArray = hud.split("\n\n")
	if _hud_time_label != null and parts.size() >= 1:
		_hud_time_label.text = parts[0]
	if _hud_money_label != null and parts.size() >= 2:
		_hud_money_label.text = parts[1]
	if _hud_rating_label != null and parts.size() >= 3:
		GameTermView.apply(_hud_rating_label, parts[2])
	if _hud_stage_label != null and parts.size() >= 4:
		GameTermView.apply(_hud_stage_label, parts[3])
	if _hud_characteristics_label != null and parts.size() >= 5:
		GameTermView.apply(_hud_characteristics_label, parts[4])
	if _finale_label != null:
		_finale_label.visible = is_finale_presented()


func _refresh_home() -> void:
	if _home_summary != null:
		_home_summary.text = _format_home_summary()
	if _home_goal != null:
		_home_goal.visible = false
	if _home_result != null:
		_home_result.text = _last_result_text
func _refresh_progression() -> void:
	pass


func _refresh_save_buttons() -> void:
	var sm: Variant = _save_manager()
	var has_save: bool = sm != null and bool(sm.has_save())
	if _load_button != null:
		_load_button.disabled = not has_save
	if _delete_button != null:
		_delete_button.disabled = not has_save


func _refresh_nav() -> void:
	var factory_unlocked: bool = _is_factory_unlocked()
	for section_id in _nav_buttons.keys():
		var btn: Button = _nav_buttons[section_id]
		if section_id == "factory":
			btn.visible = factory_unlocked
			btn.text = "Фабрика" + _objective_marker_suffix(ObjectiveView.TARGET_FACTORY)
		elif section_id == "clothing":
			btn.text = "Одежда" + _objective_marker_suffix(&"", &"", &"clothing_store")
		if section_id == _section:
			btn.modulate = Color(1, 0.92, 0.65)
		else:
			btn.modulate = Color.WHITE
func _connect_core_signals() -> void:
	var clock: Variant = _time_service()
	if clock != null and not clock.time_advanced.is_connected(_on_time_advanced):
		clock.time_advanced.connect(_on_time_advanced)
	var stages: Variant = _stage_service()
	if stages != null and not stages.stage_progress_changed.is_connected(_on_stage_progress_changed):
		stages.stage_progress_changed.connect(_on_stage_progress_changed)
	if stages != null and not stages.stage_completed.is_connected(_on_stage_completed):
		stages.stage_completed.connect(_on_stage_completed)
	if stages != null and not stages.stage_changed.is_connected(_on_stage_changed):
		stages.stage_changed.connect(_on_stage_changed)
	if stages != null and not stages.finale_reached.is_connected(_on_finale_reached):
		stages.finale_reached.connect(_on_finale_reached)
	var actions: Variant = _action_service()
	if actions != null and not actions.action_executed.is_connected(_on_action_executed):
		actions.action_executed.connect(_on_action_executed)
	var economy: Variant = _economy_service()
	if economy != null and not economy.money_changed.is_connected(_on_money_changed):
		economy.money_changed.connect(_on_money_changed)
	var purchases: Variant = _purchase_service()
	if purchases != null and not purchases.purchase_completed.is_connected(_on_purchase_completed):
		purchases.purchase_completed.connect(_on_purchase_completed)
	var world: Variant = _world_service()
	if world != null and not world.location_changed.is_connected(_on_location_changed):
		world.location_changed.connect(_on_location_changed)
	if world != null and not world.location_unlocked.is_connected(_on_location_unlocked):
		world.location_unlocked.connect(_on_location_unlocked)
	if world != null and world.has_signal("city_stage_changed") and not world.city_stage_changed.is_connected(_on_city_stage_changed):
		world.city_stage_changed.connect(_on_city_stage_changed)
	var girls: Variant = _girls_service()
	if girls != null and not girls.girl_discovered.is_connected(_on_girl_discovered):
		girls.girl_discovered.connect(_on_girl_discovered)
	if girls != null and not girls.girl_contact_received.is_connected(_on_girl_contact_received):
		girls.girl_contact_received.connect(_on_girl_contact_received)
	if girls != null and not girls.girl_relationship_changed.is_connected(_on_girl_relationship_changed):
		girls.girl_relationship_changed.connect(_on_girl_relationship_changed)
	if girls != null and not girls.girl_relationship_completed.is_connected(_on_girl_relationship_completed):
		girls.girl_relationship_completed.connect(_on_girl_relationship_completed)
	if girls != null and not girls.girl_access_changed.is_connected(_on_girl_access_changed):
		girls.girl_access_changed.connect(_on_girl_access_changed)
	var rating: Variant = _rating_service()
	if rating != null and not rating.rating_changed.is_connected(_on_rating_changed):
		rating.rating_changed.connect(_on_rating_changed)
	var dating: Variant = _dating_service()
	if dating != null and not dating.date_started.is_connected(_on_date_started):
		dating.date_started.connect(_on_date_started)
	if dating != null and not dating.date_completed.is_connected(_on_date_completed):
		dating.date_completed.connect(_on_date_completed)
	var rivals: Variant = _rivals_service()
	if rivals != null and not rivals.rival_discovered.is_connected(_on_rival_discovered):
		rivals.rival_discovered.connect(_on_rival_discovered)
	if rivals != null and not rivals.rival_defeated.is_connected(_on_rival_defeated):
		rivals.rival_defeated.connect(_on_rival_defeated)
	var competitions: Variant = _competition_service()
	if competitions != null and not competitions.competition_completed.is_connected(_on_competition_completed):
		competitions.competition_completed.connect(_on_competition_completed)
	var characteristics: Variant = _characteristic_service()
	if characteristics != null and not characteristics.characteristic_changed.is_connected(_on_characteristic_changed):
		characteristics.characteristic_changed.connect(_on_characteristic_changed)
	var equipment: Variant = _equipment_service()
	if equipment != null and not equipment.outfit_equipped.is_connected(_on_outfit_equipped):
		equipment.outfit_equipped.connect(_on_outfit_equipped)
	var automation: Variant = _automation_service()
	if automation != null and not automation.automation_unlocked.is_connected(_on_automation_unlocked):
		automation.automation_unlocked.connect(_on_automation_unlocked)
	if automation != null and not automation.clones_changed.is_connected(_on_automation_clones_changed):
		automation.clones_changed.connect(_on_automation_clones_changed)
	if automation != null and not automation.allocation_changed.is_connected(_on_automation_allocation_changed):
		automation.allocation_changed.connect(_on_automation_allocation_changed)
	if automation != null and not automation.production_changed.is_connected(_on_automation_production_changed):
		automation.production_changed.connect(_on_automation_production_changed)
	if automation != null and not automation.upgrade_purchased.is_connected(_on_automation_upgrade_purchased):
		automation.upgrade_purchased.connect(_on_automation_upgrade_purchased)
	if automation != null and not automation.expansion_changed.is_connected(_on_automation_expansion_changed):
		automation.expansion_changed.connect(_on_automation_expansion_changed)
	var objectives: Variant = _objective_service()
	if objectives != null and not objectives.objective_changed.is_connected(_on_objective_changed):
		objectives.objective_changed.connect(_on_objective_changed)
	var guidance: Variant = _guidance_service()
	if guidance != null and not guidance.tutorial_requested.is_connected(_on_tutorial_requested):
		guidance.tutorial_requested.connect(_on_tutorial_requested)
	if guidance != null and not guidance.milestone_requested.is_connected(_on_milestone_requested):
		guidance.milestone_requested.connect(_on_milestone_requested)
	if guidance != null and not guidance.message_closed.is_connected(_on_guidance_closed):
		guidance.message_closed.connect(_on_guidance_closed)


func _exit_tree() -> void:
	_disconnect_core_signals()


func _disconnect_signal(host: Variant, signal_name: String, callback: Callable) -> void:
	if host != null and host.has_signal(signal_name) and host.is_connected(signal_name, callback):
		host.disconnect(signal_name, callback)


func _disconnect_core_signals() -> void:
	_disconnect_signal(_time_service(), "time_advanced", _on_time_advanced)
	_disconnect_signal(_stage_service(), "stage_progress_changed", _on_stage_progress_changed)
	_disconnect_signal(_stage_service(), "stage_completed", _on_stage_completed)
	_disconnect_signal(_stage_service(), "stage_changed", _on_stage_changed)
	_disconnect_signal(_stage_service(), "finale_reached", _on_finale_reached)
	_disconnect_signal(_action_service(), "action_executed", _on_action_executed)
	_disconnect_signal(_economy_service(), "money_changed", _on_money_changed)
	_disconnect_signal(_purchase_service(), "purchase_completed", _on_purchase_completed)
	_disconnect_signal(_world_service(), "location_changed", _on_location_changed)
	_disconnect_signal(_world_service(), "location_unlocked", _on_location_unlocked)
	var world: Variant = _world_service()
	if world != null and world.has_signal("city_stage_changed"):
		_disconnect_signal(world, "city_stage_changed", _on_city_stage_changed)
	_disconnect_signal(_girls_service(), "girl_discovered", _on_girl_discovered)
	_disconnect_signal(_girls_service(), "girl_contact_received", _on_girl_contact_received)
	_disconnect_signal(_girls_service(), "girl_relationship_changed", _on_girl_relationship_changed)
	_disconnect_signal(_girls_service(), "girl_relationship_completed", _on_girl_relationship_completed)
	_disconnect_signal(_girls_service(), "girl_access_changed", _on_girl_access_changed)
	_disconnect_signal(_rating_service(), "rating_changed", _on_rating_changed)
	_disconnect_signal(_dating_service(), "date_started", _on_date_started)
	_disconnect_signal(_dating_service(), "date_completed", _on_date_completed)
	_disconnect_signal(_rivals_service(), "rival_discovered", _on_rival_discovered)
	_disconnect_signal(_rivals_service(), "rival_defeated", _on_rival_defeated)
	_disconnect_signal(_competition_service(), "competition_completed", _on_competition_completed)
	_disconnect_signal(_characteristic_service(), "characteristic_changed", _on_characteristic_changed)
	_disconnect_signal(_equipment_service(), "outfit_equipped", _on_outfit_equipped)
	_disconnect_signal(_automation_service(), "automation_unlocked", _on_automation_unlocked)
	_disconnect_signal(_automation_service(), "clones_changed", _on_automation_clones_changed)
	_disconnect_signal(_automation_service(), "allocation_changed", _on_automation_allocation_changed)
	_disconnect_signal(_automation_service(), "production_changed", _on_automation_production_changed)
	_disconnect_signal(_automation_service(), "upgrade_purchased", _on_automation_upgrade_purchased)
	_disconnect_signal(_automation_service(), "expansion_changed", _on_automation_expansion_changed)
	_disconnect_signal(_objective_service(), "objective_changed", _on_objective_changed)
	_disconnect_signal(_guidance_service(), "tutorial_requested", _on_tutorial_requested)
	_disconnect_signal(_guidance_service(), "milestone_requested", _on_milestone_requested)
	_disconnect_signal(_guidance_service(), "message_closed", _on_guidance_closed)


func _on_objective_changed() -> void:
	_refresh_objective_panel()


func _refresh_objective_panel() -> void:
	if _objective_panel == null:
		return
	var view: ObjectiveView = get_current_objective()
	var stages: Variant = _stage_service()
	if stages != null and bool(stages.is_finale_reached()) and view != null and view.completed:
		_objective_panel.bind(view)
		return
	_objective_panel.bind(view)

func _objective_marker_suffix(target_type: StringName, target_id: StringName = &"", location_id: StringName = &"") -> String:
	var objectives: Variant = _objective_service()
	if objectives == null:
		return ""
	return str(objectives.marker_suffix(target_type, target_id, location_id))


func _ensure_guidance_popup() -> void:
	if _guidance_popup != null and is_instance_valid(_guidance_popup):
		return
	_guidance_layer = CanvasLayer.new()
	_guidance_layer.layer = 30
	add_child(_guidance_layer)
	_guidance_popup = GuidancePopup.new()
	_guidance_layer.add_child(_guidance_popup)
	_guidance_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_guidance_popup.dismissed.connect(_on_guidance_popup_dismissed)


func _request_objectives_intro() -> void:
	var guidance: Variant = _guidance_service()
	if guidance == null:
		return
	guidance.request_tutorial(GuidanceCatalog.ID_OBJECTIVES_INTRO)


func _on_tutorial_requested(definition: TutorialDefinition) -> void:
	_ensure_guidance_popup()
	_guidance_popup.present_tutorial(definition)


func _on_milestone_requested(definition: MilestoneDefinition) -> void:
	_ensure_guidance_popup()
	_guidance_popup.present_milestone(definition)


func _on_guidance_popup_dismissed() -> void:
	var guidance: Variant = _guidance_service()
	if guidance != null:
		guidance.dismiss_current()


func _on_guidance_closed() -> void:
	_request_refresh()


func _on_time_advanced(_delta_minutes: int, _previous_game_time: int, _current_game_time: int) -> void:
	_request_refresh()


func _on_money_changed(_previous_money: int, _current_money: int, _delta: int) -> void:
	_request_refresh()


func _on_purchase_completed(_purchase_id: StringName) -> void:
	_request_refresh()


func _on_location_changed(_previous_location_id: StringName, _current_location_id: StringName) -> void:
	_request_refresh()


func _on_location_unlocked(_location_id: StringName) -> void:
	_request_refresh()


func _on_city_stage_changed(_previous_city_stage: int, _current_city_stage: int) -> void:
	_request_refresh()


func _on_girl_discovered(_girl_id: StringName) -> void:
	_request_refresh()


func _on_girl_contact_received(_girl_id: StringName) -> void:
	_request_refresh()


func _on_girl_relationship_changed(_girl_id: StringName, _previous_value: int, _current_value: int, _delta: int) -> void:
	_request_refresh()


func _on_girl_relationship_completed(girl_id: StringName) -> void:
	var girls: Variant = _girls_service()
	var display_name: String = String(girl_id)
	if girls != null:
		var definition: GirlDefinition = girls.get_definition(girl_id)
		if definition != null:
			display_name = definition.display_name
	var text: String = "ОТНОШЕНИЯ MAX\n\nRating +1"
	if girls != null and girls.has_method("get_filler_reward_for_girl"):
		var reward: FillerRewardDefinition = girls.get_filler_reward_for_girl(girl_id)
		if reward != null:
			text += "\n\nНовая награда:\n%s\n\n%s" % [reward.display_name, reward.granted_description]
	_last_result_text = "Отношения с %s достигли максимума.\n\n%s" % [display_name, text]
	_request_refresh()


func _on_girl_access_changed(_girl_id: StringName) -> void:
	_request_refresh()


func _on_rating_changed(_previous_rating: int, _current_rating: int, _delta: int) -> void:
	_request_refresh()


func _on_date_started(_girl_id: StringName) -> void:
	_open_date_overlay()


func _on_date_completed(_girl_id: StringName, _relationship_delta: int, _current_relationship: int) -> void:
	_request_refresh()


func _on_rival_discovered(_rival_id: StringName) -> void:
	_request_refresh()


func _on_rival_defeated(_rival_id: StringName) -> void:
	_request_refresh()


func _on_competition_completed(_competition_id: StringName, _rival_id: StringName, _won: bool) -> void:
	_request_refresh()


func _on_characteristic_changed(_characteristic_id: StringName, _previous_value: int, _current_value: int, _delta: int) -> void:
	_request_refresh()


func _on_outfit_equipped(_previous_outfit_id: StringName, _current_outfit_id: StringName) -> void:
	_request_refresh()


func _on_automation_unlocked() -> void:
	_request_refresh()


func _on_automation_clones_changed(_total_clones: int) -> void:
	_request_refresh()


func _on_automation_allocation_changed(_work_allocation_percent: int) -> void:
	_refresh_factory_status()


func _on_automation_production_changed() -> void:
	_refresh_factory_status()
	_refresh_hud()


func _on_automation_upgrade_purchased(_upgrade_id: StringName) -> void:
	_request_refresh()

func _on_automation_expansion_changed() -> void:
	_request_refresh()


func _on_factory_slider_changed(value: float) -> void:
	if _refreshing:
		return
	var automation: Variant = _automation_service()
	if automation == null:
		return
	automation.set_work_allocation_percent(int(round(value)))
	_refresh_factory_status()


func _is_factory_unlocked() -> bool:
	var automation: Variant = _automation_service()
	return automation != null and bool(automation.is_unlocked())


func _refresh_factory_status() -> void:
	if _factory_status == null:
		return
	var automation: Variant = _automation_service()
	if automation == null:
		_factory_status.text = ""
		return
	var work_percent: int = int(automation.get_work_allocation_percent())
	var dating_percent: int = int(automation.get_dating_allocation_percent())
	var scope: StringName = StringName(automation.get_current_expansion_scope())
	var required: float = float(automation.get_required_expansion_progress())
	var progress: float = float(automation.get_expansion_progress())
	var percent: float = float(automation.get_expansion_percent())
	var complete: bool = bool(automation.is_current_expansion_complete())
	var coverage_name: String = String(automation.get_scope_display_name(scope))
	if scope == AutomationService.SCOPE_WORLD:
		coverage_name = "Мировой охват"
	var coverage_lines: PackedStringArray = PackedStringArray([
		"ЭКСПАНСИЯ",
		"МАСШТАБ:",
		String(automation.get_scope_display_name(scope)),
		"%s:" % coverage_name,
	])
	if complete:
		coverage_lines.append("100% ✓")
		coverage_lines.append("%s / %s" % [_format_factory_amount(progress), _format_factory_amount(required)])
		var next_scope: StringName = StringName(automation.get_next_expansion_scope())
		if next_scope != &"":
			coverage_lines.append("Следующий масштаб:")
			coverage_lines.append(String(automation.get_scope_display_name(next_scope)))
			coverage_lines.append("Стоимость расширения:")
			coverage_lines.append(_format_grouped_int(int(automation.get_expansion_cost(next_scope))))
	else:
		coverage_lines.append("%.1f%%" % percent)
		coverage_lines.append("%s / %s" % [_format_factory_amount(progress), _format_factory_amount(required)])
	coverage_lines.append("Охват:")
	coverage_lines.append("+%s / игровой час" % _format_factory_amount(float(automation.get_expansion_rate_per_hour())))
	coverage_lines.append("+%.1f%% / игровой час" % float(automation.get_expansion_percent_per_hour()))
	var lines: PackedStringArray = PackedStringArray([
		"Фабрика:",
		"другой город",
		"Клоны: %d" % int(automation.get_total_clones()),
		"Работа: %d%%" % work_percent,
		"Свидания: %d%%" % dating_percent,
		"Рабочий эквивалент:",
		"%.1f" % float(automation.get_work_clones()),
		"Dating-эквивалент:",
		"%.1f" % float(automation.get_dating_clones()),
		"ПРОИЗВОДСТВО",
		"Доход:",
		"%s / игровой час" % _format_factory_amount(float(automation.get_work_income_per_hour())),
		"Rating:",
		"+%s / игровой час" % _format_factory_amount(float(automation.get_dating_production_per_hour())),
	])
	lines.append_array(coverage_lines)
	_factory_status.text = "\n".join(lines)

func _format_factory_amount(value: float) -> String:
	var rounded: int = int(round(value))
	if is_equal_approx(value, float(rounded)):
		return _format_grouped_int(rounded)
	return "%.1f" % value


func _format_grouped_int(value: int) -> String:
	var digits: String = str(absi(value))
	var grouped: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = " " + grouped
		grouped = digits.substr(i, 1) + grouped
		count += 1
	if value < 0:
		return "-" + grouped
	return grouped


func _open_date_overlay() -> void:
	var dating: Variant = _dating_service()
	if dating == null:
		return
	var engine: DateEngine = dating.get_date_engine() as DateEngine
	if engine == null and bool(dating.has_active_date()):
		dating.restore_active_date()
		engine = dating.get_date_engine() as DateEngine
	if engine == null:
		return
	if _date_overlay != null and is_instance_valid(_date_overlay):
		_date_overlay.attach_playthrough(engine, dating.get_catalog_service())
		return
	_date_overlay_layer = CanvasLayer.new()
	_date_overlay_layer.layer = 20
	add_child(_date_overlay_layer)
	_date_overlay = DatePlayPanel.new()
	_date_overlay_layer.add_child(_date_overlay)
	_date_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_date_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_date_overlay.attach_playthrough(engine, dating.get_catalog_service())
	if not _date_overlay.playthrough_finished.is_connected(_on_playthrough_finished):
		_date_overlay.playthrough_finished.connect(_on_playthrough_finished)


func _close_date_overlay() -> void:
	if _date_overlay != null and is_instance_valid(_date_overlay):
		_date_overlay.queue_free()
	_date_overlay = null
	if _date_overlay_layer != null and is_instance_valid(_date_overlay_layer):
		_date_overlay_layer.queue_free()
	_date_overlay_layer = null


func _restore_active_date_overlay() -> void:
	var dating: Variant = _dating_service()
	if dating == null:
		return
	if not bool(dating.has_active_date()):
		return
	dating.restore_active_date()
	_open_date_overlay()


func _on_playthrough_finished() -> void:
	_close_date_overlay()
	show_section("dates")
	refresh()


func _on_stage_changed(_previous_stage: int, current_stage: int) -> void:
	var started: String = "Начат Stage %d." % current_stage
	if _last_result_text == "Stage завершён.":
		_last_result_text = "%s\n%s" % [_last_result_text, started]
	else:
		_last_result_text = started
	_request_refresh()

func _on_stage_progress_changed(_stage: int) -> void:
	_request_refresh()


func _on_stage_completed(stage: int) -> void:
	var lines: PackedStringArray = PackedStringArray(["Stage завершён."])
	if stage == 1:
		lines.append("Город: этап 2/3")
		lines.append("Новые девушки и соперники. Повторные встречи — на следующий календарный день.")
	elif stage == 2:
		lines.append("Новая должность: оплата за работу увеличена до 200/ч")
	elif stage == 3:
		lines.append("Город: этап 3/3")
		lines.append("Новые девушки и соперники. Повторные встречи — на следующий календарный день.")
	_last_result_text = "\n".join(lines)

func _on_finale_reached() -> void:
	_request_refresh()


func _on_action_executed(_action_id: StringName, result: ActionResult) -> void:
	_on_action_resolved(result)


func _on_action_resolved(result: ActionResult) -> void:
	_last_result_text = format_action_result(result)
	if result != null and result.success and String(result.action_id).begins_with("start_date_"):
		_clear_date_invite()
		_open_date_overlay()
	refresh()


func _format_hud_text() -> String:
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var day: int = 1
	var hour: int = 0
	var minute: int = 0
	if clock != null:
		day = int(clock.get_day())
		hour = int(clock.get_hour())
		minute = int(clock.get_minute())
	var money: int = _current_money()
	var rating: int = _current_rating()
	var stage: int = 1
	var finale: bool = false
	if stages != null:
		stage = int(stages.get_current_stage())
		finale = bool(stages.is_finale_reached())
	var stage_text: String = "Stage: %d" % stage
	if finale:
		stage_text += "\nFinale"
	var city_stage: int = 1
	var world: Variant = _world_service()
	if world != null:
		city_stage = int(world.get_city_stage())
	stage_text += "\nЭтап города: %d/3" % city_stage
	if stages != null:
		var definition: StageDefinition = stages.get_current_definition() as StageDefinition
		if definition != null and definition.required_filler_max_count > 0:
			stage_text += "\nДевушки этапа: %d / %d" % [int(stages.count_stage_filler_max()), definition.required_filler_max_count]
	var characteristics: Variant = _characteristic_service()
	var muscle: int = 0
	var appearance: int = 0
	var capital: int = 0
	var aura: int = 0
	if characteristics != null:
		muscle = int(characteristics.get_value(CharacteristicIds.MUSCLE))
		appearance = int(characteristics.get_value(CharacteristicIds.APPEARANCE))
		capital = int(characteristics.get_value(CharacteristicIds.CAPITAL))
		aura = int(characteristics.get_value(CharacteristicIds.AURA))
	var stats_text: String = "Мышца: %d/5  Внешность: %d/5  Капитал: %d/5  Аура: %d/5" % [muscle, appearance, capital, aura]
	return "День %d\n%02d:%02d\n\nДеньги: %d\n\nRating: %d\n\n%s\n\n%s" % [day, hour, minute, money, rating, stage_text, stats_text]


func _format_home_summary() -> String:
	var clock: Variant = _time_service()
	var stages: Variant = _stage_service()
	var girls: Variant = _girls_service()
	var automation: Variant = _automation_service()
	var day: int = 1
	var hour: int = 0
	var minute: int = 0
	if clock != null:
		day = int(clock.get_day())
		hour = int(clock.get_hour())
		minute = int(clock.get_minute())
	var money: int = _current_money()
	var rating: int = _current_rating()
	var stage: int = 1
	if stages != null:
		stage = int(stages.get_current_stage())
	var lines: PackedStringArray = PackedStringArray([
		"День %d, %02d:%02d" % [day, hour, minute],
		"",
		"Stage %d" % stage,
		"Город: этап %d/3" % CityProgressionService.get_city_stage(),
	])
	if stages != null:
		var summary: String = String(stages.format_current_stage_summary())
		if not summary.is_empty():
			lines.append("")
			lines.append(summary)
	lines.append_array(PackedStringArray([
		"",
		"Деньги: %d" % money,
		"Rating: %d" % rating,
	]))
	if girls != null:
		var completed: int = int(girls.get_home_city_completed_count())
		var total: int = int(girls.get_home_city_girl_count())
		var percent: float = float(girls.get_home_city_coverage_percent())
		lines.append("Родной город:")
		lines.append("%d / %d — %.1f%%" % [completed, total, percent])
	if automation != null and bool(automation.is_unlocked()):
		lines.append("Фабрика:")
		lines.append("%s — %.1f%%" % [String(automation.get_scope_display_name()), float(automation.get_expansion_percent())])
	return "\n".join(lines)


func _format_stage_goal() -> String:
	return get_objective_text()


func _stage_goal_display_name(requirement: Variant) -> String:
	var description: String = String(requirement.get_description())
	var prefix: String = "Отношения с "
	if description.begins_with(prefix):
		var girl_name: String = description.substr(prefix.length())
		if girl_name.ends_with(":"):
			girl_name = girl_name.substr(0, girl_name.length() - 1)
		return girl_name
	if not description.is_empty():
		return description
	return ""


func _format_effect(description: String) -> String:
	var text: String = description.replace(" money", " денег")
	if text.begins_with("+"):
		return "Получено: %s" % text
	if text.begins_with("-"):
		return "Потрачено: %s" % text.substr(1)
	return text


func _catalog_action(action_id: StringName) -> GameAction:
	var actions: Variant = _action_service()
	if actions == null:
		return null
	return actions.get_action(action_id)


func _money_effect_amount(action: GameAction) -> int:
	if action == null:
		return 0
	for effect in action.effects:
		if effect is MoneyEffect:
			return (effect as MoneyEffect).amount
	return 0


func _time_cost(action: GameAction) -> int:
	if action == null:
		return 0
	return action.time_cost_minutes


func _game_state() -> Variant:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		return null
	return node


func _current_money() -> int:
	var economy: Variant = _economy_service()
	if economy != null:
		return int(economy.get_money())
	var gs: Variant = _game_state()
	if gs == null:
		return 0
	return int(gs.player.money)


func _current_rating() -> int:
	var rating: Variant = _rating_service()
	if rating != null:
		return int(rating.get_rating())
	var gs: Variant = _game_state()
	if gs == null:
		return 0
	return int(gs.player.rating)


func _save_manager() -> Variant:
	var node: Node = get_node_or_null("/root/SaveManager")
	if not is_instance_valid(node):
		return null
	return node


func _time_service() -> Variant:
	var node: Node = get_node_or_null("/root/TimeService")
	if not is_instance_valid(node):
		return null
	return node


func _stage_service() -> Variant:
	var node: Node = get_node_or_null("/root/StageService")
	if not is_instance_valid(node):
		return null
	return node


func _action_service() -> Variant:
	var node: Node = get_node_or_null("/root/ActionService")
	if not is_instance_valid(node):
		return null
	return node


func _economy_service() -> Variant:
	var node: Node = get_node_or_null("/root/EconomyService")
	if not is_instance_valid(node):
		return null
	return node


func _purchase_service() -> Variant:
	var node: Node = get_node_or_null("/root/PurchaseService")
	if not is_instance_valid(node):
		return null
	return node


func _world_service() -> Variant:
	var node: Node = get_node_or_null("/root/WorldService")
	if not is_instance_valid(node):
		return null
	return node


func _girls_service() -> Variant:
	var node: Node = get_node_or_null("/root/GirlsService")
	if not is_instance_valid(node):
		return null
	return node


func _daily_activity() -> Variant:
	return get_node_or_null("/root/DailyActivityService")


func _rating_service() -> Variant:
	var node: Node = get_node_or_null("/root/RatingService")
	if not is_instance_valid(node):
		return null
	return node


func _dating_service() -> Variant:
	var node: Node = get_node_or_null("/root/DatingService")
	if not is_instance_valid(node):
		return null
	return node


func _rivals_service() -> Variant:
	var node: Node = get_node_or_null("/root/RivalsService")
	if not is_instance_valid(node):
		return null
	return node


func _competition_service() -> Variant:
	var node: Node = get_node_or_null("/root/CompetitionService")
	if not is_instance_valid(node):
		return null
	return node


func _characteristic_service() -> Variant:
	var node: Node = get_node_or_null("/root/CharacteristicService")
	if not is_instance_valid(node):
		return null
	return node


func _equipment_service() -> Variant:
	var node: Node = get_node_or_null("/root/EquipmentService")
	if not is_instance_valid(node):
		return null
	return node


func _apartment_service() -> Variant:
	var node: Node = get_node_or_null("/root/ApartmentService")
	if not is_instance_valid(node):
		return null
	return node


func _automation_service() -> Variant:
	var node: Node = get_node_or_null("/root/AutomationService")
	if not is_instance_valid(node):
		return null
	return node

func _objective_service() -> Variant:
	var node: Node = get_node_or_null("/root/ObjectiveService")
	if not is_instance_valid(node):
		return null
	return node


func _guidance_service() -> Variant:
	var node: Node = get_node_or_null("/root/GuidanceService")
	if not is_instance_valid(node):
		return null
	return node
