extends CanvasLayer
## Clone Terminal modal UI (MODULE 18 + MODULE 22 §§53–56).
## Presentation over CloneIncrementalStatus / get_status. Simulation continues while open.


const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const TITLE_FONT_SIZE: int = 22
const HEADER_FONT_SIZE: int = 18
const BODY_FONT_SIZE: int = 16


var _player: Node = null
var _on_closed: Callable = Callable()
var _root: Control = null
var _totals_label: Label = null
var _work_count_label: Label = null
var _work_rate_label: Label = null
var _dating_count_label: Label = null
var _dating_rate_label: Label = null
var _countdown_label: Label = null
var _work_minus: Button = null
var _work_plus: Button = null
var _work_all: Button = null
var _dating_minus: Button = null
var _dating_plus: Button = null
var _dating_all: Button = null
var _prod_btn: Button = null
var _work_btn: Button = null
var _dating_btn: Button = null
var _prod_label: Label = null
var _work_label: Label = null
var _dating_label: Label = null
var _refresh_timer: Timer = null
var _signals_connected: bool = false


func open(player: Node, on_closed: Callable = Callable()) -> void:
	_player = player
	_on_closed = on_closed
	layer = 45
	_build_ui()
	_connect_game_signals()
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func close() -> void:
	var p: Node = _player
	var cb: Callable = _on_closed
	_disconnect_game_signals()
	_player = null
	_on_closed = Callable()
	if _refresh_timer != null and is_instance_valid(_refresh_timer):
		_refresh_timer.stop()
	if is_instance_valid(self):
		queue_free()
	if cb.is_valid():
		cb.call(p)
	elif p != null and p.has_method("enter_gameplay"):
		p.call("enter_gameplay")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var theme_res: Resource = null
	if ResourceLoader.exists(THEME_PATH):
		theme_res = load(THEME_PATH)
	if theme_res is Theme:
		_root.theme = theme_res as Theme

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.05, 0.68)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 620)
	_apply_panel_style(panel)
	_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = CloneIncrementalTypes.TERMINAL_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	vbox.add_child(title)

	_totals_label = Label.new()
	_totals_label.name = "TotalsLabel"
	_totals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_totals_label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	_totals_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.55))
	vbox.add_child(_totals_label)

	vbox.add_child(_make_section_header("РАБОТА"))
	_work_count_label = _make_body_label()
	vbox.add_child(_work_count_label)
	_work_rate_label = _make_body_label()
	vbox.add_child(_work_rate_label)
	vbox.add_child(_make_assign_row(true))

	vbox.add_child(_make_section_header("СВИДАНИЯ"))
	_dating_count_label = _make_body_label()
	vbox.add_child(_dating_count_label)
	_dating_rate_label = _make_body_label()
	vbox.add_child(_dating_rate_label)
	vbox.add_child(_make_assign_row(false))

	vbox.add_child(_make_section_header("NEXT CLONE"))
	_countdown_label = _make_body_label()
	_countdown_label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	vbox.add_child(_countdown_label)

	vbox.add_child(_make_section_header("UPGRADES"))
	_prod_label = _make_body_label()
	vbox.add_child(_prod_label)
	_prod_btn = Button.new()
	_prod_btn.custom_minimum_size = Vector2(0, 34)
	_prod_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_prod_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)
	)
	vbox.add_child(_prod_btn)

	_work_label = _make_body_label()
	vbox.add_child(_work_label)
	_work_btn = Button.new()
	_work_btn.custom_minimum_size = Vector2(0, 34)
	_work_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_work_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY)
	)
	vbox.add_child(_work_btn)

	_dating_label = _make_body_label()
	vbox.add_child(_dating_label)
	_dating_btn = Button.new()
	_dating_btn.custom_minimum_size = Vector2(0, 34)
	_dating_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_dating_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY)
	)
	vbox.add_child(_dating_btn)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)

	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 0.25
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_refresh_countdown_only)
	add_child(_refresh_timer)
	_refresh_timer.start()


func _make_section_header(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.9))
	return label


func _make_body_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9))
	return label


func _apply_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.94)
	style.border_color = Color(0.35, 0.4, 0.45, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)


func _make_assign_row(is_work: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var minus := Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(40, 32)
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(40, 32)
	var all_btn := Button.new()
	all_btn.text = "Все свободные"
	all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_work:
		_work_minus = minus
		_work_plus = plus
		_work_all = all_btn
		minus.pressed.connect(func() -> void:
			_ci_call("unassign_one_from_work")
		)
		plus.pressed.connect(func() -> void:
			_ci_call("assign_one_to_work")
		)
		all_btn.pressed.connect(func() -> void:
			_ci_call("assign_all_free_to_work")
		)
	else:
		_dating_minus = minus
		_dating_plus = plus
		_dating_all = all_btn
		minus.pressed.connect(func() -> void:
			_ci_call("unassign_one_from_dating")
		)
		plus.pressed.connect(func() -> void:
			_ci_call("assign_one_to_dating")
		)
		all_btn.pressed.connect(func() -> void:
			_ci_call("assign_all_free_to_dating")
		)
	row.add_child(minus)
	row.add_child(plus)
	row.add_child(all_btn)
	return row


func _ci_call(method: String) -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method(method):
		ci.call(method)
	_refresh()


func _buy(upgrade_type: int) -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci != null and ci.has_method("buy_upgrade"):
		ci.call("buy_upgrade", upgrade_type)
	_refresh()


func _connect_game_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_refresh_signal):
			gs.connect("clone_counts_changed", _on_refresh_signal)
		if gs.has_signal("late_rates_changed") and not gs.is_connected("late_rates_changed", _on_refresh_signal):
			gs.connect("late_rates_changed", _on_refresh_signal)
		if gs.has_signal("clone_upgrade_changed") and not gs.is_connected("clone_upgrade_changed", _on_refresh_signal):
			gs.connect("clone_upgrade_changed", _on_refresh_signal)
		if gs.has_signal("money_changed") and not gs.is_connected("money_changed", _on_refresh_signal):
			gs.connect("money_changed", _on_refresh_signal)
	_signals_connected = true


func _disconnect_game_signals() -> void:
	if not _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("clone_counts_changed") and gs.is_connected("clone_counts_changed", _on_refresh_signal):
			gs.disconnect("clone_counts_changed", _on_refresh_signal)
		if gs.has_signal("late_rates_changed") and gs.is_connected("late_rates_changed", _on_refresh_signal):
			gs.disconnect("late_rates_changed", _on_refresh_signal)
		if gs.has_signal("clone_upgrade_changed") and gs.is_connected("clone_upgrade_changed", _on_refresh_signal):
			gs.disconnect("clone_upgrade_changed", _on_refresh_signal)
		if gs.has_signal("money_changed") and gs.is_connected("money_changed", _on_refresh_signal):
			gs.disconnect("money_changed", _on_refresh_signal)
	_signals_connected = false


func _on_refresh_signal(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
	_refresh()


func _refresh_countdown_only() -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci == null or _countdown_label == null:
		return
	var secs: float = float(ci.call("get_seconds_to_next_clone"))
	_countdown_label.text = "%.1f сек" % secs


func _refresh() -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	if ci == null or _totals_label == null:
		return
	var status: CloneIncrementalStatus = ci.call("get_status") as CloneIncrementalStatus
	if status == null:
		return

	_totals_label.text = "ВСЕГО %s   /   СВОБОДНО %s" % [
		UiNumberFormat.format_compact(status.total),
		UiNumberFormat.format_compact(status.free),
	]
	_work_count_label.text = UiNumberFormat.format_compact(status.working)
	_work_rate_label.text = "%s / мин" % _format_rate_value(status.money_per_minute)
	_dating_count_label.text = UiNumberFormat.format_compact(status.dating)
	_dating_rate_label.text = "%s / мин" % _format_rate_value(status.dates_per_minute)
	_countdown_label.text = "%.1f сек" % status.seconds_to_next_clone

	if _work_minus != null:
		_work_minus.disabled = status.working <= 0
		_work_plus.disabled = status.free <= 0
		_work_all.disabled = status.free <= 0
	if _dating_minus != null:
		_dating_minus.disabled = status.dating <= 0
		_dating_plus.disabled = status.free <= 0
		_dating_all.disabled = status.free <= 0

	var cur_interval: float = CloneIncrementalTypes.production_interval(status.production_level)
	var next_interval: float = CloneIncrementalTypes.production_interval(
		mini(status.production_level + 1, CloneIncrementalTypes.MAX_LEVEL)
	)
	var prod_preview: String = "%.0f сек → %.0f сек" % [cur_interval, next_interval]
	if status.production_level >= CloneIncrementalTypes.MAX_LEVEL:
		prod_preview = "%.0f сек" % cur_interval
	_refresh_upgrade_block(
		_prod_label,
		_prod_btn,
		CloneIncrementalTypes.UPGRADE_PRODUCTION_TITLE,
		status.production_level,
		prod_preview,
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED),
	)

	var cur_work: float = CloneIncrementalTypes.money_per_minute_per_clone(status.work_level)
	var next_work: float = CloneIncrementalTypes.money_per_minute_per_clone(
		mini(status.work_level + 1, CloneIncrementalTypes.MAX_LEVEL)
	)
	var work_preview: String = "%s → %s $/мин за клона" % [
		_format_rate_value(cur_work),
		_format_rate_value(next_work),
	]
	if status.work_level >= CloneIncrementalTypes.MAX_LEVEL:
		work_preview = "%s $/мин за клона" % _format_rate_value(cur_work)
	_refresh_upgrade_block(
		_work_label,
		_work_btn,
		CloneIncrementalTypes.UPGRADE_WORK_TITLE,
		status.work_level,
		work_preview,
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY),
	)

	var cur_dating: float = CloneIncrementalTypes.dates_per_minute_per_clone(status.dating_level)
	var next_dating: float = CloneIncrementalTypes.dates_per_minute_per_clone(
		mini(status.dating_level + 1, CloneIncrementalTypes.MAX_LEVEL)
	)
	var dating_preview: String = "%s → %s свиданий/мин за клона" % [
		UiNumberFormat.format_rate(cur_dating, 2),
		UiNumberFormat.format_rate(next_dating, 2),
	]
	if status.dating_level >= CloneIncrementalTypes.MAX_LEVEL:
		dating_preview = "%s свиданий/мин за клона" % UiNumberFormat.format_rate(cur_dating, 2)
	_refresh_upgrade_block(
		_dating_label,
		_dating_btn,
		CloneIncrementalTypes.UPGRADE_DATING_TITLE,
		status.dating_level,
		dating_preview,
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY),
	)


func _refresh_upgrade_block(
	label: Label,
	button: Button,
	title: String,
	level: int,
	preview: String,
	upgrade_type: int,
) -> void:
	if label == null or button == null:
		return
	label.text = "%s\nУровень %d / %d\n%s" % [title, level, CloneIncrementalTypes.MAX_LEVEL, preview]
	if level >= CloneIncrementalTypes.MAX_LEVEL:
		button.text = "MAX"
		button.disabled = true
		return
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	var gs: Node = get_node_or_null("/root/GameState")
	var cost: int = -1
	if ci != null:
		cost = int(ci.call("get_upgrade_cost", upgrade_type))
	button.text = "Улучшить — $%s" % UiNumberFormat.format_compact(cost)
	var can: bool = gs != null and cost > 0 and bool(gs.call("can_afford", cost))
	button.disabled = not can


func _format_rate_value(value: float) -> String:
	if not is_finite(value):
		return "0"
	if absf(value) >= 10000.0:
		return UiNumberFormat.format_compact(int(roundf(value)))
	return UiNumberFormat.format_rate(value, 2)
