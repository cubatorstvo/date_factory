extends CanvasLayer
## Clone Terminal modal UI (MODULE 18 + MODULE 22 §§53–56).
## Presentation over CloneIncrementalStatus / get_status. Simulation continues while open.


var _player: Node = null
var _on_closed: Callable = Callable()
@onready var _root: Control = %Root
@onready var _totals_label: Label = %TotalsLabel
@onready var _work_count_label: Label = %WorkCountLabel
@onready var _work_rate_label: Label = %WorkRateLabel
@onready var _dating_count_label: Label = %DatingCountLabel
@onready var _dating_rate_label: Label = %DatingRateLabel
@onready var _countdown_label: Label = %CountdownLabel
@onready var _work_minus: Button = %WorkMinus
@onready var _work_plus: Button = %WorkPlus
@onready var _work_all: Button = %WorkAll
@onready var _dating_minus: Button = %DatingMinus
@onready var _dating_plus: Button = %DatingPlus
@onready var _dating_all: Button = %DatingAll
@onready var _prod_btn: Button = %ProdButton
@onready var _work_btn: Button = %WorkButton
@onready var _dating_btn: Button = %DatingButton
@onready var _prod_label: Label = %ProdLabel
@onready var _work_label: Label = %WorkLabel
@onready var _dating_label: Label = %DatingLabel
@onready var _refresh_timer: Timer = %RefreshTimer
var _signals_connected: bool = false


func _ready() -> void:
	UiScaleHelper.apply_to_control(_root)
	_work_minus.pressed.connect(func() -> void: _ci_call("unassign_one_from_work"))
	_work_plus.pressed.connect(func() -> void: _ci_call("assign_one_to_work"))
	_work_all.pressed.connect(func() -> void: _ci_call("assign_all_free_to_work"))
	_dating_minus.pressed.connect(func() -> void: _ci_call("unassign_one_from_dating"))
	_dating_plus.pressed.connect(func() -> void: _ci_call("assign_one_to_dating"))
	_dating_all.pressed.connect(func() -> void: _ci_call("assign_all_free_to_dating"))
	_prod_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)
	)
	_work_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY)
	)
	_dating_btn.pressed.connect(func() -> void:
		_buy(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY)
	)
	%CloseButton.pressed.connect(close)
	_refresh_timer.timeout.connect(_refresh_countdown_only)
	_refresh_timer.start()


func open(player: Node, on_closed: Callable = Callable()) -> void:
	_player = player
	_on_closed = on_closed
	layer = 45
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
