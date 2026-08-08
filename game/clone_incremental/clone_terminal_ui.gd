extends CanvasLayer
## Clone Terminal modal UI (MODULE 18). Simulation continues while open.


var _player: Node = null
var _on_closed: Callable = Callable()
var _root: Control = null
var _info_label: Label = null
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


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.05, 0.62)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 560)
	_root.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	var title := Label.new()
	title.text = CloneIncrementalTypes.TERMINAL_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_info_label)
	_countdown_label = Label.new()
	vbox.add_child(_countdown_label)
	vbox.add_child(_make_assign_row("На работе", true))
	vbox.add_child(_make_assign_row("На свиданиях", false))
	_prod_label = Label.new()
	_prod_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_prod_label)
	_prod_btn = Button.new()
	_prod_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)
	)
	vbox.add_child(_prod_btn)
	_work_label = Label.new()
	_work_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_work_label)
	_work_btn = Button.new()
	_work_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY)
	)
	vbox.add_child(_work_btn)
	_dating_label = Label.new()
	_dating_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_dating_label)
	_dating_btn = Button.new()
	_dating_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY)
	)
	vbox.add_child(_dating_btn)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 0.25
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_refresh_countdown_only)
	add_child(_refresh_timer)
	_refresh_timer.start()


func _make_assign_row(title: String, is_work: bool) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var minus := Button.new()
	minus.text = "-1"
	var plus := Button.new()
	plus.text = "+1"
	var all_btn := Button.new()
	all_btn.text = "Все свободные"
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
	_countdown_label.text = "Следующий клон: %.1f с" % secs


func _refresh() -> void:
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	var gs: Node = get_node_or_null("/root/GameState")
	if ci == null or gs == null or _info_label == null:
		return
	var status: CloneIncrementalStatus = ci.call("get_status") as CloneIncrementalStatus
	if status == null:
		return
	_info_label.text = (
		"Всего клонов: %d\nСвободно: %d\n\nНа работе: %d\nДенег в минуту: %s\n\nНа свиданиях: %d\nСвиданий в минуту: %s"
		% [
			status.total,
			status.free,
			status.working,
			CloneIncrementalTypes.format_money_rate(status.money_per_minute),
			status.dating,
			CloneIncrementalTypes.format_date_rate(status.dates_per_minute),
		]
	)
	_countdown_label.text = "Следующий клон: %.1f с" % status.seconds_to_next_clone
	if _work_minus != null:
		_work_minus.disabled = status.working <= 0
		_work_plus.disabled = status.free <= 0
		_work_all.disabled = status.free <= 0
	if _dating_minus != null:
		_dating_minus.disabled = status.dating <= 0
		_dating_plus.disabled = status.free <= 0
		_dating_all.disabled = status.free <= 0
	_refresh_upgrade_block(
		_prod_label,
		_prod_btn,
		CloneIncrementalTypes.UPGRADE_PRODUCTION_TITLE,
		status.production_level,
		"Новый клон каждые %s с" % CloneIncrementalTypes.format_money_rate(status.production_interval),
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED),
	)
	var work_rate: float = CloneIncrementalTypes.money_per_minute_per_clone(status.work_level)
	_refresh_upgrade_block(
		_work_label,
		_work_btn,
		CloneIncrementalTypes.UPGRADE_WORK_TITLE,
		status.work_level,
		"Доход одного рабочего: %s/мин" % CloneIncrementalTypes.format_money_rate(work_rate),
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY),
	)
	var dating_rate: float = CloneIncrementalTypes.dates_per_minute_per_clone(status.dating_level)
	_refresh_upgrade_block(
		_dating_label,
		_dating_btn,
		CloneIncrementalTypes.UPGRADE_DATING_TITLE,
		status.dating_level,
		"Скорость одного клона: %s свиданий/мин" % CloneIncrementalTypes.format_date_rate(dating_rate),
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY),
	)


func _refresh_upgrade_block(
	label: Label,
	button: Button,
	title: String,
	level: int,
	detail: String,
	upgrade_type: int,
) -> void:
	if label == null or button == null:
		return
	label.text = "%s\nУровень %d/%d\n%s" % [title, level, CloneIncrementalTypes.MAX_LEVEL, detail]
	if level >= CloneIncrementalTypes.MAX_LEVEL:
		button.text = "MAX"
		button.disabled = true
		return
	var ci: Node = get_node_or_null("/root/CloneIncremental")
	var gs: Node = get_node_or_null("/root/GameState")
	var cost: int = -1
	if ci != null:
		cost = int(ci.call("get_upgrade_cost", upgrade_type))
	button.text = "Улучшить — %d" % cost
	var can: bool = gs != null and cost > 0 and bool(gs.call("can_afford", cost))
	button.disabled = not can
