class_name SalaryStation
extends Interactable
## Physical salary claim station in the mine (MODULE 13).
## Manual cycle: 1.5s MODAL_UI progress, then SalaryMine.claim_manual_pending().

const CYCLE_OVERLAY_SCENE: String = "res://game/salary/salary_cycle_overlay.tscn"
const _CYCLE_SEC: float = 1.50
const _RESULT_SEC: float = 0.85
const _EMPTY_FEEDBACK_SEC: float = 0.7

var _busy: bool = false
var _feedback_until_msec: int = 0
var _feedback_text: String = ""
var _cycle_player: Node = null
var _cycle_snapshot: int = 0


func _ready() -> void:
	prompt_action = "Получить зарплату"
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0


func can_interact(player: Node) -> bool:
	if not super.can_interact(player):
		return false
	if _busy:
		return false
	if player == null or not player.has_method("get_control_mode"):
		return false
	var mode: Variant = player.call("get_control_mode")
	return int(mode) == int(PlayerController.ControlMode.GAMEPLAY)


func get_interaction_prompt(_player: Node) -> String:
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _feedback_until_msec and not _feedback_text.is_empty():
		return "[E] %s" % _feedback_text
	var pending: int = _get_pending()
	if pending > 0:
		return "[E] Получить зарплату — $%s" % UiNumberFormat.format_compact(pending)
	if _has_seen_manual_cycle():
		return "[E] Выплата уже получена"
	return "[E] Зарплата ещё не выросла"


func _on_interact(player: Node) -> void:
	if _busy:
		return
	if not can_interact(player):
		return
	var pending: int = _get_pending()
	if pending <= 0:
		if _has_seen_manual_cycle():
			_show_empty_feedback("Выплата уже получена")
		else:
			_show_empty_feedback("Зарплата ещё не выросла")
		return
	_busy = true
	_cycle_player = player
	_cycle_snapshot = pending
	_audio_play_sfx(AudioIds.SALARY_HOLD_START)
	call_deferred("_run_manual_cycle")


func _run_manual_cycle() -> void:
	var player: Node = _cycle_player
	var snapshot_amount: int = _cycle_snapshot
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player != null and is_instance_valid(player) and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")
	var overlay: CanvasLayer = _make_cycle_overlay(snapshot_amount)
	if overlay == null:
		_finish_cycle(player, null, false, 0)
		return
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_finish_cycle(player, overlay, false, 0)
		return
	tree.root.add_child(overlay)
	var bar: ProgressBar = overlay.get_node_or_null("Root/Progress") as ProgressBar
	var elapsed: float = 0.0
	var step: float = 0.1
	while elapsed < _CYCLE_SEC:
		elapsed += step
		if bar != null and is_instance_valid(bar):
			bar.value = clampf((elapsed / _CYCLE_SEC) * 100.0, 0.0, 100.0)
		await _wait(step)
	var mine: Node = get_node_or_null("/root/SalaryMine")
	var claimed: int = 0
	var ok: bool = false
	if mine != null and mine.has_method("claim_manual_pending"):
		var result: Variant = mine.call("claim_manual_pending")
		if result is SalaryClaimResult:
			var claim: SalaryClaimResult = result as SalaryClaimResult
			ok = claim.ok
			claimed = claim.amount
		elif typeof(result) == TYPE_DICTIONARY:
			var d: Dictionary = result as Dictionary
			ok = bool(d.get("ok", false))
			claimed = int(d.get("amount", 0))
	var result_label: Label = overlay.get_node_or_null("Root/Result") as Label if overlay != null and is_instance_valid(overlay) else null
	if result_label != null:
		if ok and claimed > 0:
			result_label.text = "ЗАРПЛАТА ПОЛУЧЕНА: +$%s" % UiNumberFormat.format_compact(claimed)
			_audio_play_sfx(AudioIds.SALARY_PAYOUT)
		elif ok:
			result_label.text = "ЗАРПЛАТА ПОЛУЧЕНА: +$0"
			_audio_play_sfx(AudioIds.SALARY_PAYOUT)
		else:
			result_label.text = "Выплата недоступна"
			_audio_play_ui(AudioIds.UI_DENIED)
		result_label.visible = true
	if bar != null and is_instance_valid(bar):
		bar.visible = false
	_play_envelope_pop()
	await _wait(_RESULT_SEC)
	_finish_cycle(player, overlay, ok, claimed)


func _finish_cycle(player: Node, overlay: CanvasLayer, _ok: bool, _claimed: int) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	if player != null and is_instance_valid(player) and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
	process_mode = Node.PROCESS_MODE_INHERIT
	_cycle_player = null
	_cycle_snapshot = 0
	_busy = false


func _show_empty_feedback(text: String) -> void:
	_feedback_text = text
	_feedback_until_msec = Time.get_ticks_msec() + int(_EMPTY_FEEDBACK_SEC * 1000.0)


func _get_pending() -> int:
	var mine: Node = get_node_or_null("/root/SalaryMine")
	if mine != null and mine.has_method("get_status"):
		var status: Variant = mine.call("get_status")
		if status is SalaryStatus:
			return (status as SalaryStatus).pending_salary
		if typeof(status) == TYPE_DICTIONARY:
			return int((status as Dictionary).get("pending_salary", 0))
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_pending_salary"):
		return int(gs.call("get_pending_salary"))
	return 0


func _has_seen_manual_cycle() -> bool:
	var mine: Node = get_node_or_null("/root/SalaryMine")
	if mine != null and mine.has_method("get_status"):
		var status: Variant = mine.call("get_status")
		if status is SalaryStatus:
			return (status as SalaryStatus).manual_cycle_seen
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("has_seen_manual_salary_cycle"):
		return bool(gs.call("has_seen_manual_salary_cycle"))
	return false


func _play_envelope_pop() -> void:
	var envelope: Node3D = get_node_or_null("Visuals/Envelope") as Node3D
	if envelope == null or not is_instance_valid(envelope):
		return
	envelope.visible = true
	var start_y: float = envelope.position.y
	envelope.position.y = start_y - 0.15
	var tw: Tween = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(envelope, "position:y", start_y + 0.25, 0.35)
	tw.tween_property(envelope, "position:y", start_y, 0.25)


func _wait(seconds: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	await tree.create_timer(seconds, true, false, true).timeout


func _make_cycle_overlay(snapshot_amount: int) -> CanvasLayer:
	var packed: PackedScene = load(CYCLE_OVERLAY_SCENE) as PackedScene
	if packed == null:
		return null
	var layer: CanvasLayer = packed.instantiate() as CanvasLayer
	if layer == null:
		return null
	var root: Control = layer.get_node_or_null("Root") as Control
	if root != null:
		UiScaleHelper.apply_to_control(root)
	var amount: Label = layer.get_node_or_null("Root/AmountHint") as Label
	if amount == null:
		return layer
	amount.text = "$%s" % UiNumberFormat.format_compact(snapshot_amount)
	return layer


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
