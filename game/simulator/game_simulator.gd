class_name GameSimulator
extends Control

const SECTIONS: Array[Array] = [
	["home", "Главная"],
	["work", "Работа"],
	["city", "Город"],
	["girls", "Девушки"],
	["dates", "Свидания"],
	["apartment", "Квартира"],
	["progression", "Прокачка"],
]

var _section: String = "home"
var _last_result_text: String = ""
var _hud_time_label: Label
var _hud_money_label: Label
var _hud_stage_label: Label
var _finale_label: Label
var _result_label: Label
var _load_button: Button
var _delete_button: Button
var _section_host: VBoxContainer
var _nav_buttons: Dictionary = {}
var _action_buttons: Array[GameActionButton] = []
var _home_summary: Label
var _home_result: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	LabUi.apply_theme(self)
	var bg := ColorRect.new()
	bg.color = LabUi.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_shell()
	_connect_core_signals()
	show_section("home")


func refresh() -> void:
	_refresh_hud()
	_refresh_home()
	_refresh_save_buttons()
	for button in _action_buttons:
		if is_instance_valid(button):
			button.refresh()
	if _result_label != null:
		_result_label.text = _last_result_text


func show_section(section_id: String) -> void:
	_section = section_id
	_rebuild_section()
	_refresh_nav()
	refresh()


func get_current_section() -> String:
	return _section


func start_new_game() -> void:
	var sm: Variant = _save_manager()
	if sm == null:
		return
	sm.new_game()
	_last_result_text = ""
	refresh()


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


func complete_current_stage() -> void:
	var stages: Variant = _stage_service()
	if stages == null:
		return
	stages.complete_current_stage()
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


func get_hud_text() -> String:
	return _format_hud_text()


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
	_hud_stage_label = Label.new()
	stats.add_child(_hud_time_label)
	stats.add_child(_hud_money_label)
	stats.add_child(_hud_stage_label)
	box.add_child(stats)
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
	return nav


func _rebuild_section() -> void:
	_action_buttons.clear()
	_home_summary = null
	_home_result = null
	if _section_host == null:
		return
	for child in _section_host.get_children():
		_section_host.remove_child(child)
		child.queue_free()
	match _section:
		"home":
			_section_host.add_child(_build_home())
		"work":
			_section_host.add_child(_build_work())
		"city":
			_section_host.add_child(_build_city())
		"girls":
			_section_host.add_child(_build_placeholder("ДЕВУШКИ", "Доступные девушки появятся здесь."))
		"dates":
			_section_host.add_child(_build_placeholder("СВИДАНИЯ", "Доступные свидания появятся здесь."))
		"apartment":
			_section_host.add_child(_build_placeholder("КВАРТИРА", "Система квартиры появится здесь."))
		"progression":
			_section_host.add_child(_build_placeholder("ПРОКАЧКА", "Система прогрессии появится здесь."))


func _build_home() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("Главная"))
	_home_summary = Label.new()
	_home_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_home_summary)
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
	return box


func _build_work() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("РАБОТА"))
	var action: GameAction = _catalog_action(GameActionCatalog.ID_TEST_EARN_MONEY)
	var info := Label.new()
	info.text = "Заработок: %d\nВремя: %d минут" % [_money_effect_amount(action), _time_cost(action)]
	box.add_child(info)
	_add_action_button(box, action, GameActionLabels.LABEL_WORK)
	return box


func _build_city() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading("ГОРОД"))
	var wait_title := Label.new()
	wait_title.text = "Провести время"
	box.add_child(wait_title)
	var action: GameAction = _catalog_action(GameActionCatalog.ID_TEST_WAIT)
	var info := Label.new()
	info.text = "Время: %d минут" % _time_cost(action)
	box.add_child(info)
	_add_action_button(box, action, GameActionLabels.LABEL_WAIT)
	return box


func _build_placeholder(title: String, body: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(LabUi.heading(title))
	var label := Label.new()
	label.text = body
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	return box


func _add_action_button(host: Node, action: GameAction, label: String) -> void:
	var button := GameActionButton.new()
	host.add_child(button)
	button.action_resolved.connect(_on_action_resolved)
	button.setup(action, label)
	_action_buttons.append(button)


func _refresh_hud() -> void:
	var hud: String = _format_hud_text()
	var parts: PackedStringArray = hud.split("\n\n")
	if _hud_time_label != null and parts.size() >= 1:
		_hud_time_label.text = parts[0]
	if _hud_money_label != null and parts.size() >= 2:
		_hud_money_label.text = parts[1]
	if _hud_stage_label != null and parts.size() >= 3:
		_hud_stage_label.text = parts[2]
	if _finale_label != null:
		_finale_label.visible = is_finale_presented()


func _refresh_home() -> void:
	if _home_summary != null:
		_home_summary.text = _format_home_summary()
	if _home_result != null:
		_home_result.text = _last_result_text


func _refresh_save_buttons() -> void:
	var sm: Variant = _save_manager()
	var has_save: bool = sm != null and bool(sm.has_save())
	if _load_button != null:
		_load_button.disabled = not has_save
	if _delete_button != null:
		_delete_button.disabled = not has_save


func _refresh_nav() -> void:
	for section_id in _nav_buttons.keys():
		var btn: Button = _nav_buttons[section_id]
		if section_id == _section:
			btn.modulate = Color(1, 0.92, 0.65)
		else:
			btn.modulate = Color.WHITE


func _connect_core_signals() -> void:
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


func _on_time_advanced(_delta_minutes: int, _previous_game_time: int, _current_game_time: int) -> void:
	refresh()


func _on_stage_changed(_previous_stage: int, _current_stage: int) -> void:
	refresh()


func _on_finale_reached() -> void:
	refresh()


func _on_action_executed(_action_id: StringName, result: ActionResult) -> void:
	_on_action_resolved(result)


func _on_action_resolved(result: ActionResult) -> void:
	_last_result_text = format_action_result(result)
	refresh()


func _format_hud_text() -> String:
	var clock: Variant = _time_service()
	var gs: Variant = _game_state()
	var stages: Variant = _stage_service()
	var day: int = 1
	var hour: int = 0
	var minute: int = 0
	if clock != null:
		day = int(clock.get_day())
		hour = int(clock.get_hour())
		minute = int(clock.get_minute())
	var money: int = 0
	if gs != null:
		money = int(gs.player.money)
	var stage: int = 1
	var finale: bool = false
	if stages != null:
		stage = int(stages.get_current_stage())
		finale = bool(stages.is_finale_reached())
	var stage_text: String = "Stage: %d" % stage
	if finale:
		stage_text += "\nFinale"
	return "День %d\n%02d:%02d\n\nДеньги: %d\n\n%s" % [day, hour, minute, money, stage_text]


func _format_home_summary() -> String:
	var clock: Variant = _time_service()
	var gs: Variant = _game_state()
	var stages: Variant = _stage_service()
	var day: int = 1
	var hour: int = 0
	var minute: int = 0
	if clock != null:
		day = int(clock.get_day())
		hour = int(clock.get_hour())
		minute = int(clock.get_minute())
	var money: int = 0
	if gs != null:
		money = int(gs.player.money)
	var stage: int = 1
	if stages != null:
		stage = int(stages.get_current_stage())
	return "День %d, %02d:%02d\n\nStage %d\n\nДеньги: %d" % [day, hour, minute, stage, money]


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
