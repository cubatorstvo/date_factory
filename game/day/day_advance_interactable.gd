class_name DayAdvanceInteractable
extends Interactable
## Apartment functional end-day interactable (MODULE 13).
## Not sleep/bed RPG — calls GameDay.advance_day() with a short overlay.

const _FADE_IN_SEC: float = 0.15
const _DAY_LABEL_SEC: float = 0.75
const _FADE_OUT_SEC: float = 0.15

var _busy: bool = false


func _ready() -> void:
	prompt_action = "Завершить день"
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
	return "[E] Завершить день"


func _on_interact(player: Node) -> void:
	if _busy:
		return
	if not can_interact(player):
		return
	_busy = true
	call_deferred("_run_advance", player)


func _run_advance(player: Node) -> void:
	if player != null and is_instance_valid(player) and player.has_method("enter_modal_ui"):
		player.call("enter_modal_ui")
	var overlay: CanvasLayer = _make_overlay()
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_finish_advance(player, overlay)
		return
	tree.root.add_child(overlay)
	var fade: ColorRect = overlay.get_node("Root/Fade") as ColorRect
	var label: Label = overlay.get_node("Root/DayLabel") as Label
	if fade != null:
		fade.modulate.a = 0.0
		await _wait(_FADE_IN_SEC)
		if is_instance_valid(fade):
			fade.modulate.a = 1.0
	else:
		await _wait(_FADE_IN_SEC)
	var day_svc: Node = get_node_or_null("/root/GameDay")
	var new_day: int = 1
	if day_svc != null and day_svc.has_method("advance_day"):
		new_day = int(day_svc.call("advance_day"))
	elif day_svc != null and day_svc.has_method("get_current_day"):
		new_day = int(day_svc.call("get_current_day"))
	if label != null and is_instance_valid(label):
		label.text = "День %d" % new_day
		label.visible = true
	await _wait(_DAY_LABEL_SEC)
	if fade != null and is_instance_valid(fade):
		fade.modulate.a = 0.0
	await _wait(_FADE_OUT_SEC)
	_finish_advance(player, overlay)


func _finish_advance(player: Node, overlay: CanvasLayer) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	if player != null and is_instance_valid(player) and player.has_method("enter_gameplay"):
		player.call("enter_gameplay")
	_busy = false


func _wait(seconds: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	await tree.create_timer(seconds, true, false, true).timeout


func _make_overlay() -> CanvasLayer:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 80
	layer.name = "DayAdvanceOverlay"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.add_child(root)
	var fade: ColorRect = ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.02, 0.02, 0.03, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(fade)
	var label: Label = Label.new()
	label.name = "DayLabel"
	label.visible = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return layer
