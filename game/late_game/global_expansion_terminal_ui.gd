extends CanvasLayer
## Global Expansion Terminal modal UI (MODULE 20 + MODULE 22 §§55–56).
## Presentation over LateGameStatus + CloneIncrementalStatus. No economy formula mutation.


var _player: Node = null
var _on_closed: Callable = Callable()
@onready var _root: Control = %Root
@onready var _reach_label: Label = %ReachLabel
@onready var _reach_bar: ProgressBar = %ReachBar
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
		_buy(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION)
	)
	_work_btn.pressed.connect(func() -> void:
		_buy(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK)
	)
	_dating_btn.pressed.connect(func() -> void:
		_buy(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING)
	)
	%CloseButton.pressed.connect(close)
	_refresh_timer.timeout.connect(_refresh_countdown_only)
	_refresh_timer.start()


func open(player: Node, on_closed: Callable = Callable()) -> void:
	_player = player
	_on_closed = on_closed
	layer = 46
	_connect_game_signals()
	_refresh()
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


func close() -> void:
	_audio_play_ui(AudioIds.UI_BACK)
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
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge != null and lge.has_method("buy_global_upgrade"):
		var result: Variant = lge.call("buy_global_upgrade", upgrade_type)
		var ok: bool = false
		if result != null and typeof(result) == TYPE_OBJECT and "ok" in result:
			ok = bool(result.ok)
		elif typeof(result) == TYPE_DICTIONARY:
			ok = bool((result as Dictionary).get("ok", false))
		if ok:
			_audio_play_sfx(AudioIds.LATE_UPGRADE)
			_audio_play_ui(AudioIds.UI_PURCHASE)
		else:
			_audio_play_ui(AudioIds.UI_DENIED)
	else:
		_audio_play_ui(AudioIds.UI_DENIED)
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
		if gs.has_signal("world_reach_changed") and not gs.is_connected("world_reach_changed", _on_refresh_signal):
			gs.connect("world_reach_changed", _on_refresh_signal)
		if gs.has_signal("global_upgrade_changed") and not gs.is_connected("global_upgrade_changed", _on_refresh_signal):
			gs.connect("global_upgrade_changed", _on_refresh_signal)
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
		if gs.has_signal("world_reach_changed") and gs.is_connected("world_reach_changed", _on_refresh_signal):
			gs.disconnect("world_reach_changed", _on_refresh_signal)
		if gs.has_signal("global_upgrade_changed") and gs.is_connected("global_upgrade_changed", _on_refresh_signal):
			gs.disconnect("global_upgrade_changed", _on_refresh_signal)
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
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if ci == null or _reach_label == null:
		return
	var clone_status: CloneIncrementalStatus = ci.call("get_status") as CloneIncrementalStatus
	if clone_status == null:
		return
	var late_status: LateGameStatus = null
	if lge != null:
		late_status = lge.call("get_status") as LateGameStatus

	var reach: int = 0
	if late_status != null:
		reach = late_status.world_reach
	_reach_label.text = "%d / %d" % [reach, LateGameTypes.WORLD_REACH_MAX]
	if _reach_bar != null:
		_reach_bar.value = float(reach)

	_totals_label.text = "ВСЕГО %s   /   СВОБОДНО %s" % [
		UiNumberFormat.format_compact(clone_status.total),
		UiNumberFormat.format_compact(clone_status.free),
	]
	_work_count_label.text = UiNumberFormat.format_compact(clone_status.working)
	_work_rate_label.text = "%s / мин" % _format_rate_value(clone_status.money_per_minute)
	_dating_count_label.text = UiNumberFormat.format_compact(clone_status.dating)
	_dating_rate_label.text = "%s / мин" % _format_rate_value(clone_status.dates_per_minute)
	_countdown_label.text = "%.1f сек" % clone_status.seconds_to_next_clone

	if _work_minus != null:
		_work_minus.disabled = clone_status.working <= 0
		_work_plus.disabled = clone_status.free <= 0
		_work_all.disabled = clone_status.free <= 0
	if _dating_minus != null:
		_dating_minus.disabled = clone_status.dating <= 0
		_dating_plus.disabled = clone_status.free <= 0
		_dating_all.disabled = clone_status.free <= 0

	var prod_level: int = 0
	var work_level: int = 0
	var dating_level: int = 0
	var prod_mult: float = 1.0
	var work_mult: float = 1.0
	var dating_mult: float = 1.0
	if late_status != null:
		prod_level = late_status.production_level
		work_level = late_status.work_level
		dating_level = late_status.dating_level
		prod_mult = late_status.production_multiplier
		work_mult = late_status.work_multiplier
		dating_mult = late_status.dating_multiplier

	_refresh_upgrade_block(
		_prod_label,
		_prod_btn,
		LateGameTypes.UPGRADE_PRODUCTION_TITLE,
		prod_level,
		_multiplier_preview(prod_level, prod_mult),
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION),
	)
	_refresh_upgrade_block(
		_work_label,
		_work_btn,
		LateGameTypes.UPGRADE_WORK_TITLE,
		work_level,
		_multiplier_preview(work_level, work_mult),
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK),
	)
	_refresh_upgrade_block(
		_dating_label,
		_dating_btn,
		LateGameTypes.UPGRADE_DATING_TITLE,
		dating_level,
		_multiplier_preview(dating_level, dating_mult),
		int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING),
	)


func _multiplier_preview(level: int, current_mult: float) -> String:
	var cur_text: String = "×%s" % LateGameTypes.format_multiplier(current_mult)
	if level >= LateGameTypes.MAX_LEVEL:
		return cur_text
	var next_mult: float = LateGameTypes.multiplier_for_level(level + 1)
	return "%s → ×%s" % [cur_text, LateGameTypes.format_multiplier(next_mult)]


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
	label.text = "%s\n%s" % [title, preview]
	if level >= LateGameTypes.MAX_LEVEL:
		button.text = "MAX"
		button.disabled = true
		return
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	var gs: Node = get_node_or_null("/root/GameState")
	var cost: int = -1
	if lge != null:
		cost = int(lge.call("get_upgrade_cost", upgrade_type))
	if cost < 0:
		button.text = "MAX"
		button.disabled = true
		return
	button.text = "Улучшить — $%s" % UiNumberFormat.format_compact(cost)
	var can: bool = gs != null and cost > 0 and bool(gs.call("can_afford", cost))
	var unlocked: bool = lge != null and bool(lge.call("is_purchases_unlocked"))
	button.disabled = not can or not unlocked


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _format_rate_value(value: float) -> String:
	if not is_finite(value):
		return "0"
	if absf(value) >= 10000.0:
		return UiNumberFormat.format_compact(int(roundf(value)))
	return UiNumberFormat.format_rate(value, 2)
